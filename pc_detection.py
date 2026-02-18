from flask import Flask, Response, jsonify, request
import cv2
import time
import os
from datetime import datetime
from flask_cors import CORS
import numpy as np
from ultralytics import YOLO
import requests
from PIL import Image
import io

app = Flask(__name__)
CORS(app)

# Variables globales
model_plante = None
model_maladie = None
current_detection = None
last_detection_time = 0
dernier_enregistrement = 0

# Liste des feuilles saines
feuilles_saines = [
    "Apple leaf", "Bell_pepper leaf", "Blueberry leaf", "Cherry leaf",
    "Peach leaf", "Potato leaf", "Raspberry leaf", "Soyabean leaf",
    "Soybean leaf", "Strawberry leaf", "Tomato leaf", "grape leaf",
    "peach leaf"
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
    "PLANTE SAINE": "Aucun traitement nécessaire. La plante est en bonne santé."
}

# Paramètres
SEUIL_CONF_PLANTE = 0.6
SEUIL_DETECTION_MALADIE = 0.6
DETECTION_INTERVAL = 1.0
PROCESSING_RESIZE = 320

# Dossier historique
dossier_historique = os.path.join(os.path.dirname(os.path.abspath(__file__)), "historique")
os.makedirs(dossier_historique, exist_ok=True)
print(f"📁 Dossier historique créé: {dossier_historique}")

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

def sauvegarder_image(frame, maladie_detectee):
    """ Capture et enregistre l'image dans un dossier spécifique pour chaque maladie, avec solution. """
    global dernier_enregistrement

    now = time.time()
    if now - dernier_enregistrement < 5:  # Intervalle de 5 secondes
        return None

    dernier_enregistrement = now
    date_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    try:
        # Créer un sous-dossier pour chaque maladie détectée
        dossier_maladie = os.path.join(dossier_historique, maladie_detectee)
        os.makedirs(dossier_maladie, exist_ok=True)

        # Nom du fichier avec la date
        nom_fichier = f"{maladie_detectee}_{datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.jpg"
        chemin_fichier = os.path.join(dossier_maladie, nom_fichier)
        chemin_relatif = os.path.join("historique", maladie_detectee, nom_fichier).replace("\\", "/")

        # Ajouter la date sous l'image
        text_position = (10, frame.shape[0] - 10)
        cv2.putText(frame, date_str, text_position, cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

        # Sauvegarde de l'image
        success = cv2.imwrite(chemin_fichier, frame)
        if not success:
            print(f"❌ Échec de la sauvegarde de l'image: {chemin_fichier}")
            return None

        return chemin_relatif

    except Exception as e:
        print(f"❌ Erreur lors de la sauvegarde de l'image: {str(e)}")
        return None

def detecter_maladie(frame):
    """ Fonction pour détecter les maladies dans une image """
    global current_detection, last_detection_time

    current_time = time.time()
    if current_time - last_detection_time < DETECTION_INTERVAL:
        return current_detection

    # Redimensionner l'image pour accélérer la détection
    small_frame = cv2.resize(frame, (PROCESSING_RESIZE, int(PROCESSING_RESIZE * frame.shape[0] / frame.shape[1])))

    # Détection de la plante
    results_plante = model_plante(small_frame, verbose=False)
    if len(results_plante) > 0 and len(results_plante[0].boxes) > 0:
        box_plante = results_plante[0].boxes[0]
        conf_plante = float(box_plante.conf[0].item())
        classe_plante = results_plante[0].names[int(box_plante.cls[0])]

        if conf_plante > SEUIL_CONF_PLANTE:
            # Vérifier si c'est une feuille saine
            if classe_plante.lower() in [f.lower() for f in feuilles_saines]:
                # Calculer le facteur d'échelle
                scale_x = frame.shape[1] / small_frame.shape[1]
                scale_y = frame.shape[0] / small_frame.shape[0]
                
                # Dessiner la boîte de la plante saine
                for box in results_plante[0].boxes:
                    x1, y1, x2, y2 = map(int, box.xyxy[0])
                    x1, x2 = int(x1 * scale_x), int(x2 * scale_x)
                    y1, y2 = int(y1 * scale_y), int(y2 * scale_y)
                    cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
                    cv2.putText(frame, "PLANTE SAINE", (x1, y1-10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

                # Sauvegarder l'image
                image_path = sauvegarder_image(frame, "PLANTE SAINE")

                if image_path:
                    current_detection = {
                        'status': 'detection',
                        'name': 'PLANTE SAINE',
                        'confidence': conf_plante,
                        'solution': solutions_maladies["PLANTE SAINE"],
                        'image': image_path,
                        'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                    }
                    last_detection_time = current_time
                    return current_detection
            else:
                # Détection de maladie
                results_maladie = model_maladie(small_frame, verbose=False)
                if len(results_maladie) > 0 and len(results_maladie[0].boxes) > 0:
                    box_maladie = results_maladie[0].boxes[0]
                    conf_maladie = float(box_maladie.conf[0].item())
                    classe_maladie = results_maladie[0].names[int(box_maladie.cls[0])]

                    if conf_maladie > SEUIL_DETECTION_MALADIE:
                        # Calculer le facteur d'échelle
                        scale_x = frame.shape[1] / small_frame.shape[1]
                        scale_y = frame.shape[0] / small_frame.shape[0]
                        
                        # Dessiner les boîtes de détection
                        for box in results_maladie[0].boxes:
                            x1, y1, x2, y2 = map(int, box.xyxy[0])
                            x1, x2 = int(x1 * scale_x), int(x2 * scale_x)
                            y1, y2 = int(y1 * scale_y), int(y2 * scale_y)
                            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 0, 255), 2)
                            cv2.putText(frame, f"{classe_maladie} ({conf_maladie:.2f})", (x1, y1-10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 2)
                        
                        # Ajouter le nom de la maladie et la confiance
                        cv2.putText(frame, f"Maladie: {classe_maladie}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
                        cv2.putText(frame, f"Confiance: {conf_maladie:.2f}", (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)

                        # Sauvegarder l'image
                        image_path = sauvegarder_image(frame, classe_maladie)

                        if image_path:
                            current_detection = {
                                'status': 'detection',
                                'name': classe_maladie,
                                'confidence': conf_maladie,
                                'solution': solutions_maladies.get(classe_maladie, "Pas de solution disponible"),
                                'image': image_path,
                                'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                            }
                            last_detection_time = current_time
                            return current_detection

    return None

@app.route('/current_detection')
def get_current_detection():
    if current_detection:
        if 'image' in current_detection and os.path.exists(current_detection['image']):
            current_detection['image_url'] = f"http://localhost:5001/{current_detection['image']}"
        return jsonify(current_detection)
    return jsonify({'status': 'no_detection'})

@app.route('/historique/<path:filename>')
def serve_image(filename):
    try:
        filename = filename.replace('\\', '/').lstrip('/')
        image_path = os.path.join(dossier_historique, filename)
        image_path = os.path.abspath(image_path)

        if not image_path.startswith(os.path.abspath(dossier_historique)):
            return "Accès non autorisé", 403

        if os.path.exists(image_path):
            response = send_file(image_path, mimetype='image/jpeg')
            response.headers['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0'
            return response
        else:
            return "Image non trouvée", 404
    except Exception as e:
        return str(e), 500

@app.route('/analyze_frame', methods=['POST'])
def analyze_frame():
    try:
        # Récupérer l'image depuis le Raspberry Pi
        raspberry_url = "http://192.168.199.187:5000/video_feed"  # Adresse IP du Raspberry Pi
        response = requests.get(raspberry_url)
        
        if response.status_code != 200:
            return jsonify({'status': 'error', 'message': 'Impossible de récupérer l\'image du Raspberry Pi'}), 500

        # Convertir l'image en format OpenCV
        image_bytes = response.content
        nparr = np.frombuffer(image_bytes, np.uint8)
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if frame is None:
            return jsonify({'status': 'error', 'message': 'Impossible de décoder l\'image'}), 500

        # Détecter les maladies
        detection = detecter_maladie(frame)
        
        if detection:
            return jsonify(detection)
        else:
            return jsonify({'status': 'no_detection', 'message': 'Aucune maladie détectée'})

    except Exception as e:
        print(f"❌ Erreur lors de l'analyse de l'image: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500

if __name__ == '__main__':
    print("🚀 Démarrage du serveur Flask sur PC...")
    try:
        # Charger les modèles au démarrage
        if not load_models():
            print("⚠️ Le serveur démarre sans les modèles YOLO. La détection sera désactivée.")
        
        # Démarrer le serveur sur un port différent du Raspberry Pi
        app.run(host='0.0.0.0', port=5001, threaded=True, debug=False)
    except Exception as e:
        print(f"❌ Erreur lors du démarrage du serveur: {e}") 