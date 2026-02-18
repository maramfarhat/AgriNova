from flask import Flask, Response, jsonify, send_file, request
import cv2
import time
import os
from datetime import datetime
from flask_cors import CORS
import threading
import numpy as np
from ultralytics import YOLO
from collections import defaultdict
import queue

app = Flask(__name__)
CORS(app)

# Variables globales
camera = None
frame_thread = None
last_frame = None
is_running = False
is_detecting = True  # Activer la détection par défaut
current_detection = None
model_plante = None
model_maladie = None
last_detection_time = 0
dernier_enregistrement = 0  # Ajout de la variable manquante
detection_interval = 2  # Intervalle minimum entre les détections (en secondes)
frame_queue = queue.Queue(maxsize=2)  # File d'attente pour les frames
detection_thread = None  # Thread séparé pour la détection

# Liste des feuilles saines
feuilles_saines = [
    "Apple leaf", "Bell_pepper leaf", "Blueberry leaf", "Cherry leaf",
    "Peach leaf", "Potato leaf", "Raspberry leaf", "Soyabean leaf",
    "Soybean leaf", "Strawberry leaf", "Tomato leaf", "grape leaf",
    "peach leaf"  # Ajout de la version en minuscules
]

# Dictionnaire des solutions pour chaque maladie
solutions_maladies = {
    "Apple Scab Leaf": "Utiliser un fongicide à base de cuivre et enlever les feuilles infectées.",
    "Apple Rust Leaf": "Appliquer du fongicide soufre et éviter l'humidité excessive.",
    "Bell_pepper leaf spot": "Utiliser un fongicide bio et arroser à la base de la plante.",
    "Corn Gray leaf spot": "Alterner les cultures et appliquer un fongicide foliaire.",
    "Corn leaf blight": "Éliminer les résidus de culture et traiter avec un fongicide.",
    "Potato leaf early blight": "Utiliser du fongicide à base de chlorothalonil.",
    "Potato leaf late blight": "Appliquer du fongicide systémique et éviter l'humidité prolongée.",
    "Tomato Early blight leaf": "Supprimer les feuilles malades et utiliser un fongicide préventif.",
    "Tomato Septoria leaf spot": "Pulvériser du cuivre et maintenir une bonne circulation d'air.",
    "Tomato leaf bacterial spot": "Désinfecter les outils et éviter l'arrosage par aspersion.",
    "Tomato leaf late blight": "Appliquer du fongicide et ne pas mouiller les feuilles.",
    "Grape leaf black rot": "Retirer les feuilles infectées et traiter avec un fongicide.",
    "PLANTE SAINE": "Aucun traitement nécessaire. La plante est en bonne santé."  # Ajout de la solution pour les plantes saines
}

# Paramètres
SEUIL_CONF_PLANTE = 0.6
SEUIL_DETECTION_MALADIE = 0.6
STABILISATION_THRESHOLD = 6
INTERVALLE_CAPTURE = 5  # Capture toutes les 5 secondes
RESOLUTION_WIDTH = 640  # Résolution optimisée pour le Raspberry Pi
RESOLUTION_HEIGHT = 480
JPEG_QUALITY = 70  # Qualité JPEG réduite pour améliorer les performances
SKIP_FRAMES = 2  # Traiter une image sur SKIP_FRAMES+1
DETECTION_INTERVAL = 1.0  # Intervalle entre les détections (en secondes)
MAX_QUEUE_SIZE = 1  # Taille maximale de la file d'attente pour les frames
PROCESSING_RESIZE = 320  # Taille de redimensionnement pour le traitement

# Dossier historique
dossier_historique = os.path.join(os.path.dirname(os.path.abspath(__file__)), "historique")
os.makedirs(dossier_historique, exist_ok=True)
print(f"📁 Dossier historique créé: {dossier_historique}")

# Vérifier les permissions du dossier
try:
    test_file = os.path.join(dossier_historique, "test.txt")
    with open(test_file, 'w') as f:
        f.write("test")
    os.remove(test_file)
    print("✅ Permissions du dossier historique OK")
except Exception as e:
    print(f"❌ Erreur de permissions sur le dossier historique: {e}")

# Charger les modèles YOLO
def load_models():
    global model_plante, model_maladie
    try:
        print("🔄 Chargement des modèles YOLO...")
        model_plante = YOLO(r"Models/plant.pt")
        model_maladie = YOLO(r"Models/maladie.pt")
        print("✅ Modèles YOLO chargés avec succès")
        return True
    except Exception as e:
        print(f"❌ Erreur lors du chargement des modèles YOLO: {e}")
        return False

# Charger les modèles au démarrage
if not load_models():
    print("⚠️ Le serveur démarre sans les modèles YOLO. La détection sera désactivée.")
    is_detecting = False

def init_camera():
    global camera
    if camera is not None:
        try:
            camera.release()
        except:
            pass
        camera = None

    print("Tentative d'initialisation de la caméra...")

    try:
        # Utiliser libcamera pour la caméra Raspberry Pi
        camera = cv2.VideoCapture(0, cv2.CAP_V4L2)

        if camera.isOpened():
            # Configurer la caméra avec des paramètres optimisés
            camera.set(cv2.CAP_PROP_FRAME_WIDTH, RESOLUTION_WIDTH)
            camera.set(cv2.CAP_PROP_FRAME_HEIGHT, RESOLUTION_HEIGHT)
            camera.set(cv2.CAP_PROP_FPS, 30)
            camera.set(cv2.CAP_PROP_BUFFERSIZE, 1)  # Réduire la taille du buffer
            camera.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc('M', 'J', 'P', 'G'))  # Utiliser MJPG pour de meilleures performances
            
            # Désactiver l'auto-exposition et l'auto-focus pour améliorer les performances
            camera.set(cv2.CAP_PROP_AUTO_EXPOSURE, 0)  # Mode manuel
            camera.set(cv2.CAP_PROP_EXPOSURE, -5)  # Exposition réduite pour des images plus claires et rapides
            
            # Essayer de lire une image test
            ret, test_frame = camera.read()
            if ret and test_frame is not None:
                print("✅ Caméra initialisée avec succès")
                print(f"Résolution: {test_frame.shape}")
                return True
            else:
                print("❌ La caméra ne peut pas lire d'images")
                camera.release()
                camera = None
        else:
            print("❌ Impossible d'ouvrir la caméra")

    except Exception as e:
        print(f"❌ Erreur lors de l'initialisation de la caméra: {str(e)}")
        if camera is not None:
            try:
                camera.release()
            except:
                pass
            camera = None

    print("❌ Aucune méthode n'a réussi à initialiser la caméra")
    return False

def release_camera():
    global camera, is_running
    if camera is not None:
        print("Fermeture de la caméra...")
        is_running = False
        try:
            camera.release()
            print("✅ Caméra fermée avec succès")
        except Exception as e:
            print(f"❌ Erreur lors de la fermeture de la caméra: {e}")
        finally:
            camera = None

def sauvegarder_image(frame, maladie_detectee):
    """ Capture et enregistre l'image dans un dossier spécifique pour chaque maladie, avec solution. """
    global dernier_enregistrement, current_detection

    now = time.time()
    if now - dernier_enregistrement < INTERVALLE_CAPTURE:
        return None  # Ne sauvegarde que toutes les 5 secondes

    dernier_enregistrement = now
    date_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    try:
        # Créer un sous-dossier pour chaque maladie détectée
        dossier_maladie = os.path.join(dossier_historique, maladie_detectee)
        os.makedirs(dossier_maladie, exist_ok=True)
        print(f"📁 Dossier créé: {dossier_maladie}")

        # Nom du fichier avec la date
        nom_fichier = f"{maladie_detectee}_{datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.jpg"
        chemin_fichier = os.path.join(dossier_maladie, nom_fichier)
        chemin_relatif = os.path.join("historique", maladie_detectee, nom_fichier).replace("\\", "/")

        # Ajouter la date sous l'image
        text_position = (10, frame.shape[0] - 10)  # En bas à gauche de l'image
        cv2.putText(frame, date_str, text_position, cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

        # Sauvegarde de l'image
        success = cv2.imwrite(chemin_fichier, frame)
        if not success:
            print(f"❌ Échec de la sauvegarde de l'image: {chemin_fichier}")
            return None

        print(f"📸 Image enregistrée: {chemin_fichier}")
        print(f"🔗 Chemin relatif: {chemin_relatif}")

        # Vérifier que l'image a bien été sauvegardée
        if not os.path.exists(chemin_fichier):
            print(f"❌ L'image n'existe pas après la sauvegarde: {chemin_fichier}")
            return None

        if os.path.getsize(chemin_fichier) == 0:
            print(f"❌ L'image est vide: {chemin_fichier}")
            os.remove(chemin_fichier)
            return None

        return chemin_relatif

    except Exception as e:
        print(f"❌ Erreur lors de la sauvegarde de l'image: {str(e)}")
        return None

def process_frame():
    global last_frame, is_running, current_detection, last_detection_time, dernier_enregistrement

    if not camera:
        print("❌ Caméra non initialisée")
        return

    fps_start_time = time.time()
    frame_count = 0
    frame_skip_counter = 0

    while is_running:
        ret, frame = camera.read()
        if not ret or frame is None:
            print("❌ Erreur de lecture de la frame")
            time.sleep(0.01)  # Réduire le délai d'attente
            continue

        frame_count += 1
        current_time = time.time()

        # Calculer et afficher le FPS toutes les secondes
        if current_time - fps_start_time >= 1:
            fps = frame_count / (current_time - fps_start_time)
            print(f"📊 FPS: {fps:.2f}")
            frame_count = 0
            fps_start_time = current_time

        # Ignorer certaines frames pour améliorer les performances
        frame_skip_counter += 1
        if frame_skip_counter <= SKIP_FRAMES:
            # Encoder la frame en JPEG sans traitement supplémentaire
            try:
                ret, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, JPEG_QUALITY])
                if ret:
                    last_frame = buffer.tobytes()
            except Exception as e:
                print(f"❌ Erreur lors de l'encodage de la frame: {e}")
            continue

        frame_skip_counter = 0

        # Copie de la frame pour l'affichage
        frame_display = frame.copy()

        # Mettre la frame dans la file d'attente pour la détection
        if is_detecting and model_plante and model_maladie and (current_time - last_detection_time) >= DETECTION_INTERVAL:
            try:
                # Vider la file d'attente si elle est pleine
                if frame_queue.full():
                    try:
                        frame_queue.get_nowait()
                    except queue.Empty:
                        pass
                
                # Ajouter la frame à la file d'attente
                frame_queue.put(frame_display)
            except Exception as e:
                print(f"❌ Erreur lors de l'ajout de la frame à la file d'attente: {e}")

        # Encoder la frame en JPEG
        try:
            ret, buffer = cv2.imencode('.jpg', frame_display, [cv2.IMWRITE_JPEG_QUALITY, JPEG_QUALITY])
            if ret:
                last_frame = buffer.tobytes()
            else:
                print("❌ Erreur d'encodage de la frame en JPEG")
        except Exception as e:
            print(f"❌ Erreur lors de l'encodage de la frame: {e}")
            continue

        # Réduire le délai pour augmenter le FPS
        time.sleep(0.01)  # ~100 FPS potentiel

def detection_worker():
    """Thread séparé pour la détection des maladies"""
    global current_detection, last_detection_time, last_frame
    
    while is_running and is_detecting:
        try:
            # Récupérer une frame de la file d'attente
            frame = frame_queue.get(timeout=1.0)
            
            if frame is None:
                continue
                
            current_time = time.time()
            
            # Redimensionner la frame pour accélérer la détection
            small_frame = cv2.resize(frame, (PROCESSING_RESIZE, int(PROCESSING_RESIZE * frame.shape[0] / frame.shape[1])))
            
            # Détection de la plante
            results_plante = model_plante(small_frame, verbose=False)

            if len(results_plante) > 0 and len(results_plante[0].boxes) > 0:
                # Prendre la détection de plante avec la plus haute confiance
                box_plante = results_plante[0].boxes[0]
                conf_plante = float(box_plante.conf[0].item())
                classe_plante = results_plante[0].names[int(box_plante.cls[0])]

                print(f"🔍 Plante détectée: {classe_plante} (Confiance: {conf_plante:.2f})")

                if conf_plante > SEUIL_CONF_PLANTE:
                    # Vérifier si c'est une feuille saine (en ignorant la casse)
                    if classe_plante.lower() in [f.lower() for f in feuilles_saines]:
                        # Calculer le facteur d'échelle pour redimensionner les coordonnées
                        scale_x = frame.shape[1] / small_frame.shape[1]
                        scale_y = frame.shape[0] / small_frame.shape[0]
                        
                        # Dessiner la boîte de la plante saine
                        for box in results_plante[0].boxes:
                            x1, y1, x2, y2 = map(int, box.xyxy[0])
                            # Redimensionner les coordonnées
                            x1, x2 = int(x1 * scale_x), int(x2 * scale_x)
                            y1, y2 = int(y1 * scale_y), int(y2 * scale_y)
                            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
                            cv2.putText(frame, "PLANTE SAINE", (x1, y1-10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

                        # Sauvegarder l'image
                        image_path = sauvegarder_image(frame, "PLANTE SAINE")

                        if image_path:
                            # Mettre à jour la détection courante
                            current_detection = {
                                'status': 'detection',
                                'name': 'PLANTE SAINE',
                                'confidence': conf_plante,
                                'solution': solutions_maladies["PLANTE SAINE"],
                                'image': image_path,
                                'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                            }

                            print(f"🔍 Détection automatique: PLANTE SAINE (Confiance: {conf_plante:.2f})")
                            last_detection_time = current_time
                            
                            # Mettre à jour le flux vidéo avec les détections
                            try:
                                ret, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, JPEG_QUALITY])
                                if ret:
                                    last_frame = buffer.tobytes()
                            except Exception as e:
                                print(f"❌ Erreur lors de l'encodage de la frame avec détection: {e}")
                    else:
                        # Détection de maladie
                        results_maladie = model_maladie(small_frame, verbose=False)

                        if len(results_maladie) > 0 and len(results_maladie[0].boxes) > 0:
                            # Prendre la détection de maladie avec la plus haute confiance
                            box_maladie = results_maladie[0].boxes[0]
                            conf_maladie = float(box_maladie.conf[0].item())
                            classe_maladie = results_maladie[0].names[int(box_maladie.cls[0])]

                            if conf_maladie > SEUIL_DETECTION_MALADIE:
                                # Calculer le facteur d'échelle pour redimensionner les coordonnées
                                scale_x = frame.shape[1] / small_frame.shape[1]
                                scale_y = frame.shape[0] / small_frame.shape[0]
                                
                                # Dessiner les boîtes de détection
                                for box in results_plante[0].boxes:
                                    x1, y1, x2, y2 = map(int, box.xyxy[0])
                                    # Redimensionner les coordonnées
                                    x1, x2 = int(x1 * scale_x), int(x2 * scale_x)
                                    y1, y2 = int(y1 * scale_y), int(y2 * scale_y)
                                    cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
                                    cv2.putText(frame, "Plante", (x1, y1-10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

                                for box in results_maladie[0].boxes:
                                    x1, y1, x2, y2 = map(int, box.xyxy[0])
                                    # Redimensionner les coordonnées
                                    x1, x2 = int(x1 * scale_x), int(x2 * scale_x)
                                    y1, y2 = int(y1 * scale_y), int(y2 * scale_y)
                                    cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 0, 255), 2)
                                    cv2.putText(frame, f"{classe_maladie} ({conf_maladie:.2f})", (x1, y1-10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 2)
                                
                                # Ajouter le nom de la maladie et la confiance en haut de l'image
                                cv2.putText(frame, f"Maladie: {classe_maladie}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
                                cv2.putText(frame, f"Confiance: {conf_maladie:.2f}", (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)

                                # Sauvegarder l'image
                                image_path = sauvegarder_image(frame, classe_maladie)

                                if image_path:
                                    # Mettre à jour la détection courante
                                    current_detection = {
                                        'status': 'detection',
                                        'name': classe_maladie,
                                        'confidence': conf_maladie,
                                        'solution': solutions_maladies.get(classe_maladie, "Pas de solution disponible"),
                                        'image': image_path,
                                        'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                                    }

                                    print(f"🔍 Détection automatique: {classe_maladie} (Confiance: {conf_maladie:.2f})")
                                    last_detection_time = current_time
                                    
                                    # Mettre à jour le flux vidéo avec les détections
                                    try:
                                        ret, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, JPEG_QUALITY])
                                        if ret:
                                            last_frame = buffer.tobytes()
                                    except Exception as e:
                                        print(f"❌ Erreur lors de l'encodage de la frame avec détection: {e}")

        except queue.Empty:
            # File d'attente vide, continuer
            pass
        except Exception as e:
            print(f"❌ Erreur lors de la détection: {e}")
            time.sleep(0.1)

@app.route('/current_detection')
def get_current_detection():
    if current_detection:
        # Vérifier si l'image existe
        if 'image' in current_detection and os.path.exists(current_detection['image']):
            # Ajouter l'URL complète de l'image
            current_detection['image_url'] = f"http://192.168.100.21:5000/{current_detection['image']}"
        return jsonify(current_detection)
    return jsonify({'status': 'no_detection'})

@app.route('/historique/<path:filename>')
def serve_image(filename):
    try:
        print(f"📸 Demande d'image: {filename}")
        # Nettoyer le chemin pour éviter les problèmes de sécurité
        filename = filename.replace('\\', '/').lstrip('/')
        image_path = os.path.join(dossier_historique, filename)
        image_path = os.path.abspath(image_path)

        if not image_path.startswith(os.path.abspath(dossier_historique)):
            print("❌ Tentative d'accès non autorisé")
            return "Accès non autorisé", 403

        if os.path.exists(image_path):
            print(f"✅ Image trouvée: {image_path}")
            response = send_file(image_path, mimetype='image/jpeg')
            response.headers['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0'
            return response
        else:
            print(f"❌ Image non trouvée: {image_path}")
            return "Image non trouvée", 404
    except Exception as e:
        print(f"❌ Erreur lors de l'envoi de l'image: {str(e)}")
        return str(e), 500

@app.route('/start_detection')
def start_detection():
    global is_detecting, is_running, frame_thread, detection_thread
    try:
        if not is_running:
            if not init_camera():
                return jsonify({'status': 'error', 'message': 'Impossible d\'initialiser la caméra'}), 500

            is_running = True
            is_detecting = True
            
            # Démarrer le thread de capture vidéo
            frame_thread = threading.Thread(target=process_frame)
            frame_thread.daemon = True
            frame_thread.start()
            
            # Démarrer le thread de détection
            detection_thread = threading.Thread(target=detection_worker)
            detection_thread.daemon = True
            detection_thread.start()
            
            print("✅ Détection démarrée")
            return jsonify({'status': 'success', 'message': 'Détection démarrée'})
        else:
            is_detecting = True
            print("✅ Détection réactivée")
            return jsonify({'status': 'success', 'message': 'Détection réactivée'})
    except Exception as e:
        print(f"❌ Erreur lors du démarrage de la détection: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/stop_detection')
def stop_detection():
    global is_detecting, is_running, frame_thread, detection_thread
    try:
        is_detecting = False
        if is_running:
            is_running = False
            if frame_thread:
                frame_thread.join(timeout=2.0)
            if detection_thread:
                detection_thread.join(timeout=2.0)
            release_camera()
        print("✅ Détection arrêtée")
        return jsonify({'status': 'success', 'message': 'Détection arrêtée'})
    except Exception as e:
        print(f"❌ Erreur lors de l'arrêt de la détection: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/video_feed')
def video_feed():
    def generate():
        while True:
            if last_frame is not None:
                yield (b'--frame\r\n'
                       b'Content-Type: image/jpeg\r\n\r\n' + last_frame + b'\r\n')
            else:
                time.sleep(0.01)  # Réduire le délai d'attente

    return Response(generate(),
                   mimetype='multipart/x-mixed-replace; boundary=frame')

@app.route('/check_camera')
def check_camera():
    try:
        if init_camera():
            release_camera()
            return jsonify({'status': 'success', 'message': 'Caméra disponible'})
        else:
            return jsonify({'status': 'error', 'message': 'Caméra non disponible'}), 500
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/analyze_image', methods=['POST'])
def analyze_image():
    try:
        if 'image' not in request.files:
            return jsonify({'status': 'error', 'message': 'Aucune image fournie'}), 400

        file = request.files['image']
        if file.filename == '':
            return jsonify({'status': 'error', 'message': 'Aucun fichier sélectionné'}), 400

        # Lire l'image
        img_bytes = file.read()
        nparr = np.frombuffer(img_bytes, np.uint8)
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if frame is None:
            return jsonify({'status': 'error', 'message': 'Impossible de lire l\'image'}), 400

        # Copie de la frame pour l'affichage
        frame_display = frame.copy()
        
        # Redimensionner l'image pour accélérer la détection
        small_frame = cv2.resize(frame, (PROCESSING_RESIZE, int(PROCESSING_RESIZE * frame.shape[0] / frame.shape[1])))

        # Détecter la plante
        results_plante = model_plante(small_frame, verbose=False)
        if len(results_plante) > 0 and len(results_plante[0].boxes) > 0:
            box_plante = results_plante[0].boxes[0]
            conf_plante = float(box_plante.conf[0].item())
            classe_plante = results_plante[0].names[int(box_plante.cls[0])]

            if conf_plante > SEUIL_CONF_PLANTE:
                # Vérifier si c'est une feuille saine
                if classe_plante in feuilles_saines:
                    # Calculer le facteur d'échelle pour redimensionner les coordonnées
                    scale_x = frame.shape[1] / small_frame.shape[1]
                    scale_y = frame.shape[0] / small_frame.shape[0]
                    
                    # Dessiner la boîte de la plante saine
                    for box in results_plante[0].boxes:
                        x1, y1, x2, y2 = map(int, box.xyxy[0])
                        # Redimensionner les coordonnées
                        x1, x2 = int(x1 * scale_x), int(x2 * scale_x)
                        y1, y2 = int(y1 * scale_y), int(y2 * scale_y)
                        cv2.rectangle(frame_display, (x1, y1), (x2, y2), (0, 255, 0), 2)
                        cv2.putText(frame_display, "PLANTE SAINE", (x1, y1-10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

                    # Sauvegarder l'image
                    image_path = sauvegarder_image(frame_display, "PLANTE SAINE")

                    if image_path:
                        # Mettre à jour la détection courante
                        current_detection = {
                            'status': 'detection',
                            'name': 'PLANTE SAINE',
                            'confidence': conf_plante,
                            'solution': solutions_maladies["PLANTE SAINE"],
                            'image': image_path,
                            'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                        }

                        print(f"🔍 Détection manuelle: PLANTE SAINE (Confiance: {conf_plante:.2f})")
                        return jsonify(current_detection)
                else:
                    # Détecter la maladie
                    results_maladie = model_maladie(small_frame, verbose=False)
                    if len(results_maladie) > 0 and len(results_maladie[0].boxes) > 0:
                        box_maladie = results_maladie[0].boxes[0]
                        conf_maladie = float(box_maladie.conf[0].item())
                        classe_maladie = results_maladie[0].names[int(box_maladie.cls[0])]

                        if conf_maladie > SEUIL_DETECTION_MALADIE:
                            # Calculer le facteur d'échelle pour redimensionner les coordonnées
                            scale_x = frame.shape[1] / small_frame.shape[1]
                            scale_y = frame.shape[0] / small_frame.shape[0]
                            
                            # Dessiner la boîte de la maladie
                            for box in results_maladie[0].boxes:
                                x1, y1, x2, y2 = map(int, box.xyxy[0])
                                # Redimensionner les coordonnées
                                x1, x2 = int(x1 * scale_x), int(x2 * scale_x)
                                y1, y2 = int(y1 * scale_y), int(y2 * scale_y)
                                cv2.rectangle(frame_display, (x1, y1), (x2, y2), (0, 0, 255), 2)
                                cv2.putText(frame_display, f"{classe_maladie} ({conf_maladie:.2f})", (x1, y1-10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 2)
                            
                            # Ajouter le nom de la maladie et la confiance en haut de l'image
                            cv2.putText(frame_display, f"Maladie: {classe_maladie}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
                            cv2.putText(frame_display, f"Confiance: {conf_maladie:.2f}", (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)

                            # Sauvegarder l'image avec les rectangles
                            image_path = sauvegarder_image(frame_display, classe_maladie)

                            if image_path:
                                # Mettre à jour la détection courante
                                current_detection = {
                                    'status': 'detection',
                                    'name': classe_maladie,
                                    'confidence': conf_maladie,
                                    'solution': solutions_maladies.get(classe_maladie, "Pas de solution disponible"),
                                    'image': image_path,
                                    'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                                }

                                print(f"🔍 Détection manuelle: {classe_maladie} (Confiance: {conf_maladie:.2f})")
                                return jsonify(current_detection)

        return jsonify({'status': 'no_detection', 'message': 'Aucune maladie détectée'})

    except Exception as e:
        print(f"❌ Erreur lors de l'analyse de l'image: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500

if __name__ == '__main__':
    print("🚀 Démarrage du serveur Flask...")
    try:
        # Désactiver le mode debug pour éviter les problèmes de thread
        app.run(host='0.0.0.0', port=5000, threaded=True, debug=False)
    except Exception as e:
        print(f"❌ Erreur lors du démarrage du serveur: {e}")
        if camera is not None:
            camera.release()
