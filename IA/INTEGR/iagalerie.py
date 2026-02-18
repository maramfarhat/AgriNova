import cv2
from ultralytics import YOLO
import os
from datetime import datetime
from tkinter import Tk, filedialog

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
SEUIL_CONF_PLANTE = 0.5  # Seuil abaissé pour augmenter les chances de détection
SEUIL_DETECTION_MALADIE = 0.5

# Dossier historique
dossier_historique = "historique"
os.makedirs(dossier_historique, exist_ok=True)
fichier_historique = os.path.join(dossier_historique, "historique.txt")

def sauvegarder_image(frame, maladie_detectee):
    """ Capture et enregistre l'image avec la détection. """
    date_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    dossier_maladie = os.path.join(dossier_historique, maladie_detectee)
    os.makedirs(dossier_maladie, exist_ok=True)
    nom_fichier = f"{maladie_detectee}_{datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.jpg"
    chemin_fichier = os.path.join(dossier_maladie, nom_fichier)
    cv2.imwrite(chemin_fichier, frame)
    solution = solutions_maladies.get(maladie_detectee, "Feuille saine, pas de solution nécessaire.")
    with open(fichier_historique, "a") as f:
        f.write(f"{date_str} - {maladie_detectee}/{nom_fichier}\nSolution: {solution}\n\n")
    print(f"Image enregistrée : {chemin_fichier}")
    print(f"Solution : {solution}")

# Ouvrir une boîte de dialogue pour sélectionner une image
Tk().withdraw()
file_path = filedialog.askopenfilename(title="Sélectionner une image", filetypes=[("Images", "*.jpg;*.png;*.jpeg")])
if not file_path:
    print("Aucune image sélectionnée.")
    exit()

# Charger l'image
frame = cv2.imread(file_path)
if frame is None:
    print("Erreur lors du chargement de l'image.")
    exit()

# Détection de la plante
results_plante = model_plante(frame, verbose=False)
plante_detectee = False
for result in results_plante:
    for box in result.boxes:
        if box.conf[0].item() > SEUIL_CONF_PLANTE:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            plante_detectee = True
            plante_roi = frame[y1:y2, x1:x2]
            
            # Afficher la classe détectée
            print(f"Plante détectée avec confiance {box.conf[0].item():.2f}")
            
            results_maladie = model_maladie(plante_roi, verbose=False)
            maladie_trouvee = False
            for maladie in results_maladie:
                for box in maladie.boxes:
                    if box.conf[0].item() > SEUIL_DETECTION_MALADIE:
                        maladie_detectee = model_maladie.names[int(box.cls[0])]
                        print(f"Maladie détectée : {maladie_detectee}")  # Afficher la maladie détectée
                        maladie_trouvee = True
                        if maladie_detectee not in feuilles_saines:
                            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 0, 255), 3)
                            cv2.putText(frame, maladie_detectee, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
                            sauvegarder_image(frame, maladie_detectee)
                        else:
                            print(f"Feuille saine détectée : {maladie_detectee}")
                            
            if not maladie_trouvee:
                print("Aucune maladie détectée sur la plante.")
                
if not plante_detectee:
    print("Aucune plante détectée dans l'image.")

# Afficher l'image avec les détections
cv2.imshow("Detection Maladie", frame)
cv2.waitKey(0)
cv2.destroyAllWindows()
