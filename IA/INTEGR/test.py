


from ultralytics import YOLO  
import cv2  

# Corriger le chemin du modèle (mettre chemin absolu si nécessaire)
model_path = r"c:\Users\maram\OneDrive\Desktop\PlantDiseaseV1.v3i.yolov8\runs\detect\train\weights\best.pt"
image_path = r"C:\Users\maram\OneDrive\Desktop\INTEGR\testp.jpg"

# Vérification des fichiers
import os
if not os.path.exists(model_path):
    raise FileNotFoundError(f"❌ Le modèle n'existe pas : {model_path}")
if not os.path.exists(image_path):
    raise FileNotFoundError(f"❌ L'image n'existe pas : {image_path}")

# Charger le modèle
model = YOLO(model_path)  

# Charger l'image et détecter
results = model(image_path, show=True)  

# Sauvegarder l’image avec les détections
results[0].save("resultat.jpg")

# Attendre une touche pour fermer
cv2.waitKey(0)
cv2.destroyAllWindows()

