from flask import Flask, Response
import cv2
import time
import threading
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Variables globales
camera = None
frame_thread = None
last_frame = None
is_running = False

# Paramètres
RESOLUTION_WIDTH = 640
RESOLUTION_HEIGHT = 480
JPEG_QUALITY = 70
SKIP_FRAMES = 2

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
            camera.set(cv2.CAP_PROP_BUFFERSIZE, 1)
            camera.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc('M', 'J', 'P', 'G'))
            
            # Désactiver l'auto-exposition et l'auto-focus
            camera.set(cv2.CAP_PROP_AUTO_EXPOSURE, 0)
            camera.set(cv2.CAP_PROP_EXPOSURE, -5)
            
            # Test de lecture
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

def process_frame():
    global last_frame, is_running

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
            time.sleep(0.01)
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
            try:
                ret, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, JPEG_QUALITY])
                if ret:
                    last_frame = buffer.tobytes()
            except Exception as e:
                print(f"❌ Erreur lors de l'encodage de la frame: {e}")
            continue

        frame_skip_counter = 0

        # Encoder la frame en JPEG
        try:
            ret, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, JPEG_QUALITY])
            if ret:
                last_frame = buffer.tobytes()
            else:
                print("❌ Erreur d'encodage de la frame en JPEG")
        except Exception as e:
            print(f"❌ Erreur lors de l'encodage de la frame: {e}")
            continue

        time.sleep(0.01)

@app.route('/video_feed')
def video_feed():
    def generate():
        while True:
            if last_frame is not None:
                yield (b'--frame\r\n'
                       b'Content-Type: image/jpeg\r\n\r\n' + last_frame + b'\r\n')
            else:
                time.sleep(0.01)

    return Response(generate(),
                   mimetype='multipart/x-mixed-replace; boundary=frame')

@app.route('/start_capture')
def start_capture():
    global is_running, frame_thread
    try:
        if not is_running:
            if not init_camera():
                return {'status': 'error', 'message': 'Impossible d\'initialiser la caméra'}, 500

            is_running = True
            
            # Démarrer le thread de capture vidéo
            frame_thread = threading.Thread(target=process_frame)
            frame_thread.daemon = True
            frame_thread.start()
            
            print("✅ Capture démarrée")
            return {'status': 'success', 'message': 'Capture démarrée'}
        else:
            print("✅ Capture déjà en cours")
            return {'status': 'success', 'message': 'Capture déjà en cours'}
    except Exception as e:
        print(f"❌ Erreur lors du démarrage de la capture: {e}")
        return {'status': 'error', 'message': str(e)}, 500

@app.route('/stop_capture')
def stop_capture():
    global is_running, frame_thread
    try:
        is_running = False
        if frame_thread:
            frame_thread.join(timeout=2.0)
        release_camera()
        print("✅ Capture arrêtée")
        return {'status': 'success', 'message': 'Capture arrêtée'}
    except Exception as e:
        print(f"❌ Erreur lors de l'arrêt de la capture: {e}")
        return {'status': 'error', 'message': str(e)}, 500

@app.route('/check_camera')
def check_camera():
    try:
        if init_camera():
            release_camera()
            return {'status': 'success', 'message': 'Caméra disponible'}
        else:
            return {'status': 'error', 'message': 'Caméra non disponible'}, 500
    except Exception as e:
        return {'status': 'error', 'message': str(e)}, 500

if __name__ == '__main__':
    print("🚀 Démarrage du serveur Flask sur Raspberry Pi...")
    try:
        app.run(host='0.0.0.0', port=5000, threaded=True, debug=False)
    except Exception as e:
        print(f"❌ Erreur lors du démarrage du serveur: {e}")
        if camera is not None:
            camera.release() 