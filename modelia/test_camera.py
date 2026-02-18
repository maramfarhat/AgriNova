import cv2
import time
import os

def test_camera():
    print("Test de la caméra...")
    
    # Vérifier les périphériques vidéo disponibles
    print("Périphériques vidéo disponibles:")
    os.system("ls -l /dev/video*")
    
    # Essayer différentes méthodes d'accès
    camera_methods = [
        (0, "Default"),
        (0 + cv2.CAP_V4L2, "V4L2"),
        (0 + cv2.CAP_DSHOW, "DirectShow"),
        (1, "Alternative")
    ]
    
    for index, method_name in camera_methods:
        print(f"\nEssai avec {method_name}...")
        camera = cv2.VideoCapture(index)
        
        if not camera.isOpened():
            print(f"❌ Impossible d'ouvrir la caméra via {method_name}")
            camera.release()
            continue
            
        print(f"✅ Caméra ouverte via {method_name}")
        
        # Configurer la caméra
        camera.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        camera.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        camera.set(cv2.CAP_PROP_FPS, 30)
        
        # Essayer de lire quelques frames
        success_count = 0
        for i in range(10):
            ret, frame = camera.read()
            if ret and frame is not None:
                success_count += 1
                print(f"Frame {i+1}: OK - Taille: {frame.shape}")
            else:
                print(f"Frame {i+1}: Échec")
                
        if success_count > 0:
            print(f"\n✅ Test réussi avec {method_name} ({success_count}/10 frames lues)")
            # Afficher une frame de test
            cv2.imshow(f'Test Camera - {method_name}', frame)
            cv2.waitKey(2000)  # Afficher pendant 2 secondes
            cv2.destroyAllWindows()
        else:
            print(f"\n❌ Aucune frame lue avec {method_name}")
            
        camera.release()
        
    print("\n✅ Test terminé")

if __name__ == "__main__":
    test_camera() 