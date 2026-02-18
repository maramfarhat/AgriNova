from flask import Flask, request, jsonify, Response
from flask_cors import CORS
import cv2
import numpy as np
from ultralytics import YOLO
import os
from datetime import datetime
import threading
import time

app = Flask(__name__)
CORS(app)

# Variables globales pour le flux vidéo
camera = None
is_detection_active = False
current_detection = None
detection_lock = threading.Lock()

# Charger les modèles
model_plante = YOLO("Models/train13/weights/last.pt")
model_maladie = YOLO("Models/train/weights/best.pt")

# Fonction pour sauvegarder l'image
def sauvegarder_image(image, nom_maladie):
    # Créer le dossier 'images' s'il n'existe pas
    if not os.path.exists('images'):
        os.makedirs('images')
    
    # Générer un nom de fichier unique avec la date et l'heure
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    nom_fichier = f"images/{nom_maladie}_{timestamp}.jpg"
    
    # Ajouter la date en bas de l'image
    date_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    text_position = (10, image.shape[0] - 10)  # En bas à gauche de l'image
    cv2.putText(image, date_str, text_position, cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
    
    # Sauvegarder l'image
    cv2.imwrite(nom_fichier, image)
    print(f"Image sauvegardée : {nom_fichier}")

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
    "Apple leaf": "Feuille saine, pas de traitement nécessaire.",
    "Bell_pepper leaf": "Feuille saine, pas de traitement nécessaire.",
    "Blueberry leaf": "Feuille saine, pas de traitement nécessaire.",
    "Cherry leaf": "Feuille saine, pas de traitement nécessaire.",
    "Peach leaf": "Feuille saine, pas de traitement nécessaire.",
    "Potato leaf": "Feuille saine, pas de traitement nécessaire.",
    "Raspberry leaf": "Feuille saine, pas de traitement nécessaire.",
    "Soyabean leaf": "Feuille saine, pas de traitement nécessaire.",
    "Soybean leaf": "Feuille saine, pas de traitement nécessaire.",
    "Strawberry leaf": "Feuille saine, pas de traitement nécessaire.",
    "Tomato leaf": "Feuille saine, pas de traitement nécessaire.",
    "grape leaf": "Feuille saine, pas de traitement nécessaire."
}

feuilles_saines = {
    "Apple leaf", "Bell_pepper leaf", "Blueberry leaf", "Cherry leaf", 
    "Peach leaf", "Potato leaf", "Raspberry leaf", "Soyabean leaf", 
    "Soybean leaf", "Strawberry leaf", "Tomato leaf", "grape leaf", "Corn leaf"
}

SEUIL_CONF_PLANTE = 0.3
SEUIL_DETECTION_MALADIE = 0.3

def generate_frames():
    global camera, is_detection_active, current_detection
    
    if camera is None:
        camera = cv2.VideoCapture(0)
    
    while True:
        success, frame = camera.read()
        if not success:
            break
        else:
            if is_detection_active:
                # Faire une copie de l'image pour les annotations
                frame_annotated = frame.copy()
                
                # Détection de la plante
                results_plante = model_plante(frame, verbose=False)
                
                for result in results_plante:
                    for box in result.boxes:
                        if box.conf[0].item() > SEUIL_CONF_PLANTE:
                            x1, y1, x2, y2 = map(int, box.xyxy[0])
                            plante_roi = frame[y1:y2, x1:x2]
                            
                            results_maladie = model_maladie(plante_roi, verbose=False)
                            for maladie in results_maladie:
                                for box in maladie.boxes:
                                    if box.conf[0].item() > SEUIL_DETECTION_MALADIE:
                                        maladie_detectee = model_maladie.names[int(box.cls[0])]
                                        
                                        # Convertir les coordonnées
                                        box_x1, box_y1, box_x2, box_y2 = map(int, box.xyxy[0])
                                        x1_disease = x1 + box_x1
                                        y1_disease = y1 + box_y1
                                        x2_disease = x1 + box_x2
                                        y2_disease = y1 + box_y2
                                        
                                        # Dessiner le rectangle et le texte
                                        cv2.rectangle(frame_annotated, (x1_disease, y1_disease), (x2_disease, y2_disease), (0, 255, 0), 2)
                                        text = f"{maladie_detectee}"
                                        cv2.putText(frame_annotated, text, (x1_disease, y1_disease - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
                                        
                                        # Mettre à jour la détection courante
                                        with detection_lock:
                                            current_detection = {
                                                'status': 'detection',
                                                'name': maladie_detectee,
                                                'confidence': float(box.conf[0].item()),
                                                'timestamp': datetime.now().isoformat()
                                            }
                
                frame = frame_annotated
            
            ret, buffer = cv2.imencode('.jpg', frame)
            frame = buffer.tobytes()
            yield (b'--frame\r\n'
                   b'Content-Type: image/jpeg\r\n\r\n' + frame + b'\r\n')
        
        time.sleep(0.1)  # Limiter le taux de rafraîchissement

@app.route('/video_feed')
def video_feed():
    return Response(generate_frames(),
                    mimetype='multipart/x-mixed-replace; boundary=frame')

@app.route('/start_detection')
def start_detection():
    global is_detection_active
    is_detection_active = True
    return jsonify({'status': 'success', 'message': 'Détection démarrée'})

@app.route('/stop_detection')
def stop_detection():
    global is_detection_active
    is_detection_active = False
    return jsonify({'status': 'success', 'message': 'Détection arrêtée'})

@app.route('/current_detection')
def get_current_detection():
    with detection_lock:
        if current_detection:
            return jsonify(current_detection)
        return jsonify({'status': 'no_detection'})

@app.route('/check_camera')
def check_camera():
    global camera
    if camera is None:
        camera = cv2.VideoCapture(0)
    if camera.isOpened():
        return jsonify({'status': 'success', 'message': 'Caméra disponible'})
    return jsonify({'status': 'error', 'message': 'Caméra non disponible'}), 500

@app.route('/analyze', methods=['POST'])
def analyze_image():
    if 'image' not in request.files:
        return jsonify({'error': 'Aucune image fournie'}), 400

    file = request.files['image']
    if file.filename == '':
        return jsonify({'error': 'Aucun fichier sélectionné'}), 400

    # Lire l'image
    img_bytes = file.read()
    nparr = np.frombuffer(img_bytes, np.uint8)
    frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    # Faire une copie de l'image originale pour les annotations
    frame_annotated = frame.copy()

    if frame is None:
        return jsonify({'error': 'Erreur lors du chargement de l\'image'}), 400

    # Détection de la plante
    results_plante = model_plante(frame, verbose=False)
    plante_detectee = False
    resultat = {}
    image_path = None

    for result in results_plante:
        for box in result.boxes:
            if box.conf[0].item() > SEUIL_CONF_PLANTE:
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                plante_detectee = True
                plante_roi = frame[y1:y2, x1:x2]
                
                results_maladie = model_maladie(plante_roi, verbose=False)
                for maladie in results_maladie:
                    for box in maladie.boxes:
                        if box.conf[0].item() > SEUIL_DETECTION_MALADIE:
                            maladie_detectee = model_maladie.names[int(box.cls[0])]
                            print(f"Maladie détectée: {maladie_detectee}")  # Debug print
                            
                            # Obtenir les coordonnées de la maladie dans l'image ROI
                            box_x1, box_y1, box_x2, box_y2 = map(int, box.xyxy[0])
                            
                            # Convertir les coordonnées de la ROI vers l'image originale
                            x1_disease = x1 + box_x1
                            y1_disease = y1 + box_y1
                            x2_disease = x1 + box_x2
                            y2_disease = y1 + box_y2
                            
                            # Normaliser le nom de la maladie (enlever les espaces et convertir en minuscules)
                            maladie_detectee_normalized = maladie_detectee.lower().replace(" ", "")
                            
                            # Trouver la clé correspondante dans le dictionnaire
                            cle_correspondante = None
                            for k in solutions_maladies.keys():
                                k_normalized = k.lower().replace(" ", "")
                                if k_normalized == maladie_detectee_normalized:
                                    cle_correspondante = k
                                    break
                            
                            print(f"Maladie dans solutions_maladies: {cle_correspondante is not None}")  # Debug print
                            print(f"Toutes les clés disponibles: {list(solutions_maladies.keys())}")  # Debug print
                            
                            if cle_correspondante not in feuilles_saines:
                                solution = solutions_maladies.get(cle_correspondante)
                                print(f"Solution trouvée: {solution}")  # Debug print
                                
                                # 🔳 Dessiner un rectangle vert autour de la maladie détectée
                                cv2.rectangle(frame_annotated, (x1_disease, y1_disease), (x2_disease, y2_disease), (0, 255, 0), 2)
                                
                                # Ajouter le texte avec le nom de la maladie
                                text = f"{maladie_detectee}"
                                # Calculer la taille du texte pour centrer le fond
                                (text_width, text_height), _ = cv2.getTextSize(text, cv2.FONT_HERSHEY_SIMPLEX, 0.7, 2)
                                # Dessiner un fond noir pour le texte
                                cv2.rectangle(frame_annotated, (x1_disease, y1_disease - text_height - 10), (x1_disease + text_width, y1_disease), (0, 0, 0), -1)
                                # Ajouter le texte en blanc
                                cv2.putText(frame_annotated, text, (x1_disease, y1_disease - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
                                
                                # Ajouter la date en bas de l'image
                                date_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                                text_position = (10, frame_annotated.shape[0] - 10)  # En bas à gauche de l'image
                                cv2.putText(frame_annotated, date_str, text_position, cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
                                
                                # Sauvegarder l'image avec les annotations
                                if not os.path.exists('images'):
                                    os.makedirs('images')
                                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                                nom_fichier = f"images/{cle_correspondante}_{timestamp}.jpg"
                                cv2.imwrite(nom_fichier, frame_annotated)
                                print(f"Image sauvegardée : {nom_fichier}")
                                
                                # Convertir l'image annotée en bytes pour la réponse
                                _, img_encoded = cv2.imencode('.jpg', frame_annotated)
                                img_bytes = img_encoded.tobytes()
                                
                                resultat = {
                                    'disease_name': cle_correspondante,
                                    'plant_type': model_plante.names[int(result.boxes.cls[0])],
                                    'description': f'Maladie détectée sur la plante',
                                    'solution': solution if solution else 'Solution non disponible',
                                    'confidence': float(box.conf[0].item()),
                                    'image_bytes': img_bytes.hex()  # Convertir en hexadécimal pour le JSON
                                }
                                break
                            else:
                                print(f"✅ Feuille saine détectée : {maladie_detectee}, aucune solution nécessaire.")
                                resultat = {
                                    'disease_name': cle_correspondante,
                                    'plant_type': model_plante.names[int(result.boxes.cls[0])],
                                    'description': f'Feuille saine',
                                    'solution': solutions_maladies.get(cle_correspondante, 'Solution non disponible'),
                                    'confidence': float(box.conf[0].item())
                                }
                                break

    if not plante_detectee:
        return jsonify({'error': 'Aucune plante détectée dans l\'image'}), 400

    if not resultat:
        return jsonify({'error': 'Aucune maladie détectée'}), 400

    return jsonify(resultat)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000) 