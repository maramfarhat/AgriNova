#include <WiFi.h>
#include <WebSocketsClient.h>

// === Paramètres Wi-Fi ===
const char* ssid = "Redmi 14C";
const char* password = "maram2711";

// === WebSocket ===
WebSocketsClient webSocket;
const char* serverIp = "192.168.220.189"; // IP de ton PC
const int serverPort = 3000;

// === Broches moteur ===
#define ENA 13
#define IN1 12
#define IN2 14
#define IN3 27
#define IN4 26
#define ENB 25

void setup() {
  Serial.begin(115200);

  // Broches moteur en sortie
  pinMode(ENA, OUTPUT);
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);
  pinMode(ENB, OUTPUT);

  // Connexion Wi-Fi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n✅ Connecté au WiFi");

  // Connexion WebSocket
  webSocket.begin(serverIp, serverPort, "/");
  webSocket.onEvent(webSocketEvent);
}

void loop() {
  webSocket.loop();
}

// === Réception des données du joystick ===
void webSocketEvent(WStype_t type, uint8_t* payload, size_t length) {
  if (type == WStype_TEXT) {
    String data = String((char*)payload);
    Serial.println("Reçu : " + data);

    int xIndex = data.indexOf("x:");
    int yIndex = data.indexOf("y:");

    if (xIndex != -1 && yIndex != -1) {
      int x = data.substring(xIndex + 2, yIndex).toInt();
      int y = data.substring(yIndex + 2).toInt();

      int seuil = 20;

      // Diagonales
      if (y > seuil && x > seuil) {
        moveForwardRight();   // ↗️
      } else if (y > seuil && x < -seuil) {
        moveForwardLeft();    // ↖️
      } else if (y < -seuil && x > seuil) {
        moveBackwardRight();  // ↘️
      } else if (y < -seuil && x < -seuil) {
        moveBackwardLeft();   // ↙️

      // Lignes droites
      } else if (y > seuil) {
        moveForward();        // ↑
      } else if (y < -seuil) {
        moveBackward();       // ↓
      } else if (x > seuil) {
        turnRightForward();   // →
      } else if (x < -seuil) {
        turnLeftForward();    // ←
      } else {
        stopMotors();         // 🛑
      }
    }
  }
}

// === Fonctions de mouvement ===

void moveForward() {
  digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW);
}

void moveBackward() {
  digitalWrite(IN1, LOW); digitalWrite(IN2, HIGH);
  digitalWrite(IN3, LOW); digitalWrite(IN4, HIGH);
}

void turnLeftForward() {
  digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);  digitalWrite(IN4, LOW);
}

void turnRightForward() {
  digitalWrite(IN1, LOW);  digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW);
}

void moveForwardRight() {
  digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW);
  delay(10);
}

void moveForwardLeft() {
  digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW);
  delay(10);
}

void moveBackwardRight() {
  digitalWrite(IN1, LOW); digitalWrite(IN2, HIGH);
  digitalWrite(IN3, LOW); digitalWrite(IN4, HIGH);
  delay(10);
}

void moveBackwardLeft() {
  digitalWrite(IN1, LOW); digitalWrite(IN2, HIGH);
  digitalWrite(IN3, LOW); digitalWrite(IN4, HIGH);
  delay(10);
}

void stopMotors() {
  digitalWrite(IN1, LOW); digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW); digitalWrite(IN4, LOW);
}
