import cv2
from ultralytics import YOLO
from collections import defaultdict
import time
import os
from datetime import datetime

# Charger les modèles
model_plante = YOLO(r"Models\train13\weights\last.pt")
model_maladie = YOLO(r"Models\train\weights\best.pt")

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
}
feuilles_saines = {
    "Apple leaf", "Bell_pepper leaf", "Blueberry leaf", "Cherry leaf", "Peach leaf", "Potato leaf", 
    "Raspberry leaf", "Soyabean leaf", "Soybean leaf", "Strawberry leaf", "Tomato leaf", "grape leaf"
}

# Paramètres
SEUIL_CONF_PLANTE = 0.6
SEUIL_DETECTION_MALADIE = 0.6
STABILISATION_THRESHOLD = 8
INTERVALLE_CAPTURE = 5  # Capture toutes les 5 secondes

# Dossier historique
dossier_historique = "historique"
os.makedirs(dossier_historique, exist_ok=True)
fichier_historique = os.path.join(dossier_historique, "historique.txt")

# Variables
historique_maladies = set()
compteur_maladies = defaultdict(int)

maladie_stable = None
compteur_frames_sans_plante = 0
dernier_enregistrement = time.time()  # Initialisation correcte

# Initialiser la webcam
cap = cv2.VideoCapture(0)

def sauvegarder_image(frame, maladie_detectee):
    """ Capture et enregistre l'image dans un dossier spécifique pour chaque maladie, avec solution. """
    global dernier_enregistrement
    
    now = time.time()
    if now - dernier_enregistrement < INTERVALLE_CAPTURE:
        return  # Ne sauvegarde que toutes les 5 secondes
    
    dernier_enregistrement = now
    date_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # 🗂️ Créer un sous-dossier pour chaque maladie détectée
    dossier_maladie = os.path.join(dossier_historique, maladie_detectee)
    os.makedirs(dossier_maladie, exist_ok=True)
    
    # 📸 Nom du fichier avec la date
    nom_fichier = f"{maladie_detectee}_{datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.jpg"
    chemin_fichier = os.path.join(dossier_maladie, nom_fichier)

    # Ajouter la date sous l'image
    text_position = (10, frame.shape[0] - 10)  # En bas à gauche de l'image
    cv2.putText(frame, date_str, text_position, cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

    # Sauvegarde de l'image
    cv2.imwrite(chemin_fichier, frame)

    # Obtenir la solution de la maladie
    solution = solutions_maladies.get(maladie_detectee, "Feuille saine, pas de solution nécessaire.")
    
    # Ajouter le nom de l'image et la solution dans le fichier historique
    with open(fichier_historique, "a") as f:
        f.write(f"{date_str} - {maladie_detectee}/{nom_fichier}\nSolution: {solution}\n\n")

    print(f"📸 Image enregistrée dans {dossier_maladie} : {nom_fichier}")
    print(f"💡 Solution recommandée : {solution}")

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    # Détection de la plante
    results_plante = model_plante(frame, verbose=False)
    plante_detectee = False
    plante_roi = None  

    for result in results_plante:
        for box in result.boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            if box.conf[0].item() > SEUIL_CONF_PLANTE:
                plante_detectee = True
                plante_roi = frame[y1:y2, x1:x2]
                plante_roi_rgb = cv2.cvtColor(plante_roi, cv2.COLOR_BGR2RGB)

                # Détection de la maladie
                if plante_roi is not None:

                    plante_roi_rgb = cv2.cvtColor(plante_roi, cv2.COLOR_BGR2RGB)
                    results_maladie = model_maladie(plante_roi_rgb, verbose=False)
                    for maladie in results_maladie:
                        for box in maladie.boxes:
                         
                         if box.conf[0].item() > SEUIL_DETECTION_MALADIE:
                            maladie_detectee = model_maladie.names[int(box.cls[0])]

                            # Vérifier si la feuille est saine
                            if maladie_detectee not in feuilles_saines:
                                compteur_maladies[maladie_detectee] += 1
                                if compteur_maladies[maladie_detectee] >= STABILISATION_THRESHOLD:
                                    maladie_stable = maladie_detectee
                                    if maladie_stable not in historique_maladies:
                                        historique_maladies.add(maladie_stable)
                                        print(f"🔍 Nouvelle maladie détectée : {maladie_stable}")

                                    # 🔳 Dessiner un rectangle vert autour de la maladie détectée
                                    cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
                                    text = f"{maladie_detectee}"
                                    cv2.putText(frame, text, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
                                    sauvegarder_image(frame, maladie_stable)
                            else:
                                print(f"✅ Feuille saine détectée : {maladie_detectee}, aucune solution nécessaire.")

    # Afficher l'image avec les rectangles et labels
    cv2.imshow("Detection Maladie", frame)

    # Quitter avec 'q'
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
