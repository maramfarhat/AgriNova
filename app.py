from flask import Flask, Response, jsonify, request, send_file
import cv2
import numpy as np
from ultralytics import YOLO
import threading
import queue
import time
from datetime import datetime
import os
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Configuration
CAMERA_ID = 0
RESOLUTION = (640, 480)
FPS = 30
JPEG_QUALITY = 80
DETECTION_INTERVAL = 0.1  # Intervalle entre les détections (en secondes)

# Variables globales
camera = None
frame_queue = queue.Queue(maxsize=2)  # Queue pour les frames
detection_queue = queue.Queue(maxsize=1)  # Queue pour les résultats de détection
is_running = False
current_detection = None
last_frame = None

# Liste des feuilles saines
feuilles_saines = [
    "Apple leaf", "Bell_pepper leaf", "Blueberry leaf", "Cherry leaf",
    "Peach leaf", "Potato leaf", "Raspberry leaf", "Soyabean leaf",
    "Soybean leaf", "Strawberry leaf", "Tomato leaf", "grape leaf",
    "Corn leaf"  # Ajout de Corn leaf
]

# Dictionnaire des solutions pour chaque maladie
solutions_maladies = {
    "Apple Scab Leaf": "Utiliser un fongicide à base de cuivre et enlever les feuilles infectées.",
    "Apple Rust Leaf": "Appliquer du fongicide soufre et éviter l'humidité excessive.",
    "Bell_pepper leaf spot": "Utiliser un fongicide bio et arroser à la base de la plante.",
    "Corn Gray leaf spot": "Alterner les cultures et appliquer un fongicide foliaire.",
    "Corn leaf blight": "Éliminer les résidus de culture et traiter avec un fongicide.",
    "Corn rust leaf": "Appliquer un fongicide à base de triazole et éviter l'humidité excessive.",
    "Corn leaf": "Feuille saine, pas de traitement nécessaire.",
    "Potato leaf early blight": "Utiliser du fongicide à base de chlorothalonil.",
    "Potato leaf late blight": "Appliquer du fongicide systémique et éviter l'humidité prolongée.",
    "Tomato Early blight leaf": "Supprimer les feuilles malades et utiliser un fongicide préventif.",
    "Tomato Septoria leaf spot": "Pulvériser du cuivre et maintenir une bonne circulation d'air.",
    "Tomato leaf bacterial spot": "Désinfecter les outils et éviter l'arrosage par aspersion.",
    "Tomato leaf late blight": "Appliquer du fongicide et ne pas mouiller les feuilles.",
    "Grape leaf black rot": "Retirer les feuilles infectées et traiter avec un fongicide.",
    "PLANTE SAINE": "Aucun traitement nécessaire. La plante est en bonne santé."
}

# Ajouter les solutions pour les plantes saines
for plante in feuilles_saines:
    solutions_maladies[plante] = "Feuille saine, pas de traitement nécessaire."

# Chargement des modèles
print("Chargement des modèles YOLO...")
model_plante = YOLO(r"Models\train13\weights\last.pt")
model_maladie = YOLO(r"Models\train\weights\best.pt")
print("Modèles chargés avec succès")

# Seuils de confiance
PLANT_CONFIDENCE_THRESHOLD = 0.5
DISEASE_CONFIDENCE_THRESHOLD = 0.6

def init_camera():
    global camera
    try:
        print("Tentative d'ouverture de la caméra...")
        camera = cv2.VideoCapture(CAMERA_ID, cv2.CAP_DSHOW)
        if not camera.isOpened():
            print("❌ Impossible d'ouvrir la caméra avec l'ID", CAMERA_ID)
            return False
        camera.set(cv2.CAP_PROP_FRAME_WIDTH, RESOLUTION[0])
        camera.set(cv2.CAP_PROP_FRAME_HEIGHT, RESOLUTION[1])
        camera.set(cv2.CAP_PROP_FPS, FPS)
        camera.set(cv2.CAP_PROP_BUFFERSIZE, 1)
        print("✅ Caméra initialisée avec succès")
        return True
    except Exception as e:
        print(f"Erreur d'initialisation de la caméra: {e}")
        return False

def release_camera():
    global camera
    if camera is not None:
        camera.release()
        camera = None

def process_frame():
    global is_running, last_frame
    while is_running:
        ret, frame = camera.read()
        if not ret:
            continue

        # Redimensionner l'image pour de meilleures performances
        frame = cv2.resize(frame, RESOLUTION)
        
        # Mettre à jour la dernière frame
        try:
            ret, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, JPEG_QUALITY])
            if ret:
                last_frame = buffer.tobytes()
        except Exception as e:
            print(f"Erreur d'encodage: {e}")

        # Ajouter la frame à la queue de détection
        if not frame_queue.full():
            frame_queue.put(frame)

def detection_worker():
    global current_detection
    last_detection_time = 0

    while is_running:
        try:
            # Vérifier si une nouvelle détection est nécessaire
            current_time = time.time()
            if current_time - last_detection_time < DETECTION_INTERVAL:
                time.sleep(0.01)
                continue

            # Récupérer une frame de la queue
            if frame_queue.empty():
                time.sleep(0.01)
                continue

            frame = frame_queue.get()
            
            # Détection de la plante
            results_plante = model_plante(frame, verbose=False)
            
            if len(results_plante) > 0 and len(results_plante[0].boxes) > 0:
                box_plante = results_plante[0].boxes[0]
                conf_plante = float(box_plante.conf[0].item())
                classe_plante = results_plante[0].names[int(box_plante.cls[0])]
                
                if conf_plante > PLANT_CONFIDENCE_THRESHOLD:
                    # Vérifier si c'est une feuille saine
                    if classe_plante in feuilles_saines:
                        current_detection = {
                            'status': 'detection',
                            'name': 'PLANTE SAINE',
                            'confidence': conf_plante,
                            'solution': solutions_maladies["PLANTE SAINE"],
                            'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                        }
                        save_detection_image(frame, "PLANTE SAINE")
                    else:
                        # Détection de la maladie
                        results_maladie = model_maladie(frame, verbose=False)
                        
                        if len(results_maladie) > 0 and len(results_maladie[0].boxes) > 0:
                            box_maladie = results_maladie[0].boxes[0]
                            conf_maladie = float(box_maladie.conf[0].item())
                            classe_maladie = results_maladie[0].names[int(box_maladie.cls[0])]
                            
                            if conf_maladie > DISEASE_CONFIDENCE_THRESHOLD:
                                # Mettre à jour la détection courante
                                current_detection = {
                                    'status': 'detection',
                                    'name': classe_maladie,
                                    'confidence': conf_maladie,
                                    'solution': solutions_maladies.get(classe_maladie, "Pas de solution disponible"),
                                    'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                                }
                                
                                # Sauvegarder l'image
                                save_detection_image(frame, classe_maladie)
                                
                                last_detection_time = current_time

        except Exception as e:
            print(f"Erreur dans le worker de détection: {e}")
            time.sleep(0.01)

def save_detection_image(frame, disease_name):
    try:
        # Créer le dossier s'il n'existe pas
        os.makedirs('detections', exist_ok=True)
        
        # Nom du fichier avec timestamp
        filename = f"detections/{disease_name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
        
        # Sauvegarder l'image
        cv2.imwrite(filename, frame)
        
        # Mettre à jour le chemin de l'image dans la détection
        if current_detection:
            current_detection['image'] = filename
            
    except Exception as e:
        print(f"Erreur lors de la sauvegarde de l'image: {e}")

@app.route('/video_feed')
def video_feed():
    def generate():
        while True:
            if last_frame is not None:
                yield (b'--frame\r\n'
                       b'Content-Type: image/jpeg\r\n\r\n' + last_frame + b'\r\n')
            time.sleep(0.01)
    
    return Response(generate(),
                   mimetype='multipart/x-mixed-replace; boundary=frame')

@app.route('/current_detection')
def get_current_detection():
    if current_detection:
        return jsonify(current_detection)
    return jsonify({'status': 'no_detection'})

@app.route('/start_detection')
def start_detection():
    global is_running
    
    if not is_running:
        if not init_camera():
            return jsonify({'status': 'error', 'message': 'Impossible d\'initialiser la caméra'}), 500
        
        is_running = True
        
        # Démarrer les threads
        threading.Thread(target=process_frame, daemon=True).start()
        threading.Thread(target=detection_worker, daemon=True).start()
        
        return jsonify({'status': 'success', 'message': 'Détection démarrée'})
    
    return jsonify({'status': 'success', 'message': 'Détection déjà en cours'})

@app.route('/stop_detection')
def stop_detection():
    global is_running
    is_running = False
    release_camera()
    return jsonify({'status': 'success', 'message': 'Détection arrêtée'})

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
        
        # Détection de la plante
        results_plante = model_plante(frame, verbose=False)
        
        if len(results_plante) > 0 and len(results_plante[0].boxes) > 0:
            box_plante = results_plante[0].boxes[0]
            conf_plante = float(box_plante.conf[0].item())
            classe_plante = results_plante[0].names[int(box_plante.cls[0])]
            
            if conf_plante > PLANT_CONFIDENCE_THRESHOLD:
                # Vérifier si c'est une feuille saine
                if classe_plante in feuilles_saines:
                    save_detection_image(frame, "PLANTE SAINE")
                    return jsonify({
                        'status': 'detection',
                        'name': 'PLANTE SAINE',
                        'confidence': conf_plante,
                        'solution': solutions_maladies["PLANTE SAINE"],
                        'image': current_detection.get('image', ''),
                        'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                    })
                else:
                    # Détection de la maladie
                    results_maladie = model_maladie(frame, verbose=False)
                    
                    if len(results_maladie) > 0 and len(results_maladie[0].boxes) > 0:
                        box_maladie = results_maladie[0].boxes[0]
                        conf_maladie = float(box_maladie.conf[0].item())
                        classe_maladie = results_maladie[0].names[int(box_maladie.cls[0])]
                        
                        if conf_maladie > DISEASE_CONFIDENCE_THRESHOLD:
                            # Sauvegarder l'image
                            save_detection_image(frame, classe_maladie)
                            
                            return jsonify({
                                'status': 'detection',
                                'name': classe_maladie,
                                'confidence': conf_maladie,
                                'solution': solutions_maladies.get(classe_maladie, "Pas de solution disponible"),
                                'image': current_detection.get('image', ''),
                                'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                            })
        
        return jsonify({'status': 'no_detection', 'message': 'Aucune maladie détectée'})
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, threaded=True, debug=False) 