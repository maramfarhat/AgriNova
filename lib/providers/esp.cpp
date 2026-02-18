#include <WiFi.h>
#include "DHT.h"
#include <ArduinoJson.h>

// === Définition des broches ===
#define DHTPIN 14
#define DHTTYPE DHT22

#define SOIL_MOISTURE_AO 32
#define SOIL_MOISTURE_DO 33
#define FLAME_SENSOR_PIN 27
#define PH_SENSOR_PIN 34
#define POMPE_PIN 26

const char* ssid = "Redmi 14C";
const char* password = "maram2711";

DHT dht(DHTPIN, DHTTYPE);
WiFiServer server(80);

// === Seuils généraux ===
const int HUMIDITE_SOL_MIN = 50;
const int TEMP_MIN = 10;
const int TEMP_MAX = 30;
const int HUMIDITE_AIR_MIN = 40;
const int HUMIDITE_AIR_MAX = 80;
const float PH_MIN = 5.5;
const float PH_MAX = 7.0;

// Variables de contrôle
bool manualControl = false;  // true = mode manuel actif
bool pumpState = false;      // état actuel de la pompe
bool willRain = false;       // prévision de pluie

void setup() {
  Serial.begin(115200);
  dht.begin();

  pinMode(SOIL_MOISTURE_DO, INPUT);
  pinMode(FLAME_SENSOR_PIN, INPUT);
  pinMode(PH_SENSOR_PIN, INPUT);
  pinMode(POMPE_PIN, OUTPUT);
  digitalWrite(POMPE_PIN, LOW);  // Pompe désactivée au démarrage

  WiFi.begin(ssid, password);
  Serial.print("Connexion WiFi");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\n✅ Connecté au Wi-Fi !");
  Serial.print("📡 Adresse IP: ");
  Serial.println(WiFi.localIP());

  server.begin();
}

void controlPump(bool activate) {
  pumpState = activate;
  digitalWrite(POMPE_PIN, activate ? HIGH : LOW);
  Serial.print("🚿 Pompe ");
  Serial.println(activate ? "activée" : "désactivée");
}

void loop() {
  WiFiClient client = server.available();

  if (client) {
    Serial.println("🌐 Client connecté");
    String request = client.readStringUntil('\r');
    Serial.println("📥 Requête : " + request);
    client.flush();

    // === Lecture capteurs ===
    float humidity = dht.readHumidity();
    float temperature = dht.readTemperature();

    int soilMoistureAnalog = analogRead(SOIL_MOISTURE_AO);
    int soilMoistureDigital = digitalRead(SOIL_MOISTURE_DO);
    int soilMoisturePercentage = map(soilMoistureAnalog, 0, 4095, 100, 0);

    int flameDetected = digitalRead(FLAME_SENSOR_PIN);

    int phRaw = analogRead(PH_SENSOR_PIN);
    float pHValue = map(phRaw, 0, 4095, 0, 1400) / 100.0;

    // === Vérification des seuils en mode automatique ===
    bool shouldActivate = false;
    String alertes = "";

    if (!manualControl) {  // Ne vérifier les seuils qu'en mode automatique
      if (willRain) {
        alertes += "☔ Pluie prévue - Irrigation reportée\n";
        shouldActivate = false;  // Ne pas activer si pluie prévue
      } else {
        // Vérifier les conditions seulement si pas de pluie prévue
        if (soilMoisturePercentage < HUMIDITE_SOL_MIN) {
          shouldActivate = true;
          alertes += "💧 Humidité du sol faible (" + String(soilMoisturePercentage) + "%)\n";
        }

        if (temperature < TEMP_MIN || temperature > TEMP_MAX) {
          shouldActivate = true;
          alertes += "🌡️ Température hors limites (" + String(temperature) + "°C)\n";
        }

        if (humidity < HUMIDITE_AIR_MIN || humidity > HUMIDITE_AIR_MAX) {
          shouldActivate = true;
          alertes += "💦 Humidité de l'air hors limites (" + String(humidity) + "%)\n";
        }

        if (pHValue < PH_MIN || pHValue > PH_MAX) {
          shouldActivate = true;
          alertes += "🧪 pH hors limites (" + String(pHValue, 2) + ")\n";
        }

        // Contrôle automatique de la pompe
        if (shouldActivate != pumpState) {
          controlPump(shouldActivate);
        }
      }
    }

    // === Affichage série ===
    Serial.println("----- Données capteurs -----");
    Serial.print("🌡️ Température: "); Serial.println(temperature);
    Serial.print("💧 Humidité Air: "); Serial.println(humidity);
    Serial.print("🌱 Humidité Sol (analogique): "); Serial.println(soilMoistureAnalog);
    Serial.print("🌱 Humidité Sol (%): "); Serial.println(soilMoisturePercentage);
    Serial.print("🌱 Humidité Sol (digital): "); Serial.println(soilMoistureDigital);
    Serial.print("🧪 pH brut (analogique): "); Serial.println(phRaw);
    Serial.print("🧪 pH estimé: "); Serial.println(pHValue, 2);
    Serial.print("🔥 Flamme détectée ? "); Serial.println(flameDetected == 0 ? "OUI" : "NON");
    Serial.print("🚿 Pompe activée ? "); Serial.println(pumpState ? "OUI" : "NON");
    Serial.print("🎮 Mode manuel ? "); Serial.println(manualControl ? "OUI" : "NON");
    Serial.println("📢 Alertes :\n" + alertes);

    // === Réponse HTTP ===
    if (request.indexOf("GET /data") >= 0) {
      String json = "{";
      json += "\"temperature\": " + String(temperature, 1) + ",";
      json += "\"humidity\": " + String(humidity, 1) + ",";
      json += "\"soil_moisture_raw\": " + String(soilMoistureAnalog) + ",";
      json += "\"soil_moisture_percent\": " + String(soilMoisturePercentage) + ",";
      json += "\"soil_moisture_detected\": " + String(soilMoistureDigital) + ",";
      json += "\"ph_raw\": " + String(phRaw) + ",";
      json += "\"ph_value\": " + String(pHValue, 2) + ",";
      json += "\"flame_detected\": " + String(flameDetected == 0 ? "true" : "false") + ",";
      json += "\"pompe_active\": " + String(pumpState ? "true" : "false") + ",";
      json += "\"manual_control\": " + String(manualControl ? "true" : "false");
      json += "}";

      client.println("HTTP/1.1 200 OK");
      client.println("Content-Type: application/json");
      client.println();
      client.println(json);
    } 
    else if (request.indexOf("POST /control") >= 0) {
      // Lire le corps de la requête
      String body = "";
      while (client.available()) {
        body += (char)client.read();
      }

      // Parser le JSON
      StaticJsonDocument<200> doc;
      DeserializationError error = deserializeJson(doc, body);

      if (!error) {
        bool activate = doc["activate"];
        manualControl = true;  // Passer en mode manuel quand une commande directe est reçue
        
        Serial.println("📝 Commande reçue:");
        Serial.print("  - Activation: "); Serial.println(activate ? "OUI" : "NON");
        Serial.println("  - Mode manuel activé");

        controlPump(activate);

        client.println("HTTP/1.1 200 OK");
        client.println("Content-Type: application/json");
        client.println();
        client.println("{\"status\":\"success\"}");
      } else {
        client.println("HTTP/1.1 400 Bad Request");
        client.println("Content-Type: application/json");
        client.println();
        client.println("{\"error\":\"Invalid JSON\"}");
      }
    }
    else if (request.indexOf("POST /weather") >= 0) {
      // Lire le corps de la requête
      String body = "";
      while (client.available()) {
        body += (char)client.read();
      }

      // Parser le JSON
      StaticJsonDocument<200> doc;
      DeserializationError error = deserializeJson(doc, body);

      if (!error) {
        willRain = doc["will_rain"];
        
        Serial.println("🌧️ Prévisions météo reçues:");
        Serial.print("  - Pluie prévue: "); Serial.println(willRain ? "OUI" : "NON");

        client.println("HTTP/1.1 200 OK");
        client.println("Content-Type: application/json");
        client.println();
        client.println("{\"status\":\"success\"}");
      } else {
        client.println("HTTP/1.1 400 Bad Request");
        client.println("Content-Type: application/json");
        client.println();
        client.println("{\"error\":\"Invalid JSON\"}");
      }
    }
    else {
      client.println("HTTP/1.1 404 Not Found");
      client.println("Content-Type: text/plain");
      client.println();
      client.println("Endpoint not found.");
    }

    client.stop();
    Serial.println("❌ Client déconnecté");
  }
}