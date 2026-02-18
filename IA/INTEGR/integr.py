import cv2
from ultralytics import YOLO
from collections import defaultdict
import time

# Charger les modèles
model_plante = YOLO(r"Models\train13\weights\last.pt")
model_maladie = YOLO(r"Models\train\weights\best.pt")

# Initialiser la webcam
cap = cv2.VideoCapture(0)

# Paramètres
SEUIL_CONF_PLANTE = 0.5
SEUIL_DETECTION_MALADIE = 0.5
STABILISATION_THRESHOLD = 10

# Variables
historique_maladies = set()
compteur_maladies = defaultdict(int)
maladie_stable = None
compteur_frames_sans_plante = 0
derniere_detection_maladie_time = 0
historique_maladies_precedent = set()
temps_sans_detection = 0  # Temps sans détection de plante ni maladie

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    # Détection de la plante
    results_plante = model_plante(frame, verbose=False)
    plante_detectee = False

    for result in results_plante:
        for box in result.boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            if box.conf[0].item() > SEUIL_CONF_PLANTE:
                plante_detectee = True
                plante_roi = frame[y1:y2, x1:x2]
                plante_roi_rgb = cv2.cvtColor(plante_roi, cv2.COLOR_BGR2RGB)

                # Détection de la maladie
                results_maladie = model_maladie(plante_roi_rgb, verbose=False)
                for maladie in results_maladie:
                    for box in maladie.boxes:
                        if box.conf[0].item() > SEUIL_DETECTION_MALADIE:
                            maladie_detectee = model_maladie.names[int(box.cls[0])]
                            compteur_maladies[maladie_detectee] += 1
                            if compteur_maladies[maladie_detectee] >= STABILISATION_THRESHOLD:
                                maladie_stable = maladie_detectee
                                if maladie_stable not in historique_maladies:
                                    historique_maladies.add(maladie_stable)
                                    print(f"🔍 Nouvelle maladie détectée : {maladie_stable}")
                                    derniere_detection_maladie_time = time.time()

                                    # Dessiner le rectangle autour de la détection de la maladie
                                cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)  # Rectangle vert

                                # Afficher le nom de la maladie et les coordonnées
                                text = f"{maladie_detectee} ({x1},{y1})"
                                cv2.putText(frame, text, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

                                # Afficher les coordonnées du rectangle
                                coord_text = f"({x1},{y1}) to ({x2},{y2})"
                                cv2.putText(frame, coord_text, (x1, y2 + 20), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

    # Vérifier l'absence de plante et réinitialiser si nécessaire
    if not plante_detectee:
        compteur_frames_sans_plante += 1
        temps_sans_detection += 1
        if compteur_frames_sans_plante > 10:  # Si aucune plante n'est détectée pendant 10 frames
            compteur_maladies.clear()
            historique_maladies.clear()
    else:
        compteur_frames_sans_plante = 0

    # Si aucune détection de maladie n'a eu lieu depuis 5 secondes, réinitialiser
    if maladie_stable and time.time() - derniere_detection_maladie_time > 5:
        # Si aucune maladie n'a été détectée pendant 5 secondes, ne rien afficher
        if temps_sans_detection > 5:
            historique_maladies.clear()
          #  print("Aucune détection récente, aucune maladie à afficher.")
        else:
            historique_maladies.clear()
            historique_maladies.add(maladie_stable)
            print(f"🔄 Nouvelle maladie remplacée dans l'historique : {maladie_stable}")
        derniere_detection_maladie_time = time.time()

    # Afficher l'historique des maladies uniquement si la détection a changé
    if historique_maladies != historique_maladies_precedent:
        if historique_maladies:  # Vérifier si l'historique n'est pas vide
            print(f"📜 Historique des maladies détectées : {', '.join(historique_maladies)}")
        historique_maladies_precedent = historique_maladies.copy()

    # Afficher l'image avec le rectangle autour de la détection de la maladie
    cv2.imshow("Detection Maladie", frame)

    # Quitter avec 'q'
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()





