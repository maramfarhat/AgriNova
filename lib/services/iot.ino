#include <WiFi.h>
#include "DHT.h"
#include <ArduinoJson.h>

// === Définition des broches ===
#define DHTPIN 33
#define DHTTYPE DHT22

#define SOIL_MOISTURE_AO 26

#define SOIL_MOISTURE_DO 33
#define FLAME_SENSOR_PIN 27
#define PH_SENSOR_PIN 13
#define POMPE_PIN 32
#define WATER_LEVEL_SENSOR_PIN 14 // Nouveau capteur

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

bool manualControl = false;
bool pumpState = false;
bool willRain = false;

void setup() {
  Serial.begin(115200);
  dht.begin();

  pinMode(SOIL_MOISTURE_DO, INPUT);
  pinMode(FLAME_SENSOR_PIN, INPUT);
  pinMode(PH_SENSOR_PIN, INPUT);
  pinMode(POMPE_PIN, OUTPUT);
  pinMode(WATER_LEVEL_SENSOR_PIN, INPUT);  // Nouveau capteur
  digitalWrite(POMPE_PIN, LOW);

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
    client.flush();

    float humidity = dht.readHumidity();
    float temperature = dht.readTemperature();

    // === Calibration humidité du sol ===
    int soilMoistureAnalog = analogRead(SOIL_MOISTURE_AO);
    const int SOIL_WET = 1200;  // à ajuster selon ton capteur
    const int SOIL_DRY = 3500;

    int soilMoisturePercentage = map(soilMoistureAnalog, SOIL_DRY, SOIL_WET, 0, 100);
    soilMoisturePercentage = constrain(soilMoisturePercentage, 0, 100);

    int soilMoistureDigital = digitalRead(SOIL_MOISTURE_DO);
    int flameDetected = digitalRead(FLAME_SENSOR_PIN);

    int phRaw = analogRead(PH_SENSOR_PIN);
    float pHValue = map(phRaw, 0, 4095, 0, 1400) / 100.0;

    // === Niveau d’eau en pourcentage ===
    int waterLevelRaw = analogRead(WATER_LEVEL_SENSOR_PIN);
    const int WATER_EMPTY = 500;   // valeur brute quand vide
    const int WATER_FULL = 3000;   // valeur brute quand plein

    int waterLevelPercent = map(waterLevelRaw, WATER_EMPTY, WATER_FULL, 0, 100);
    waterLevelPercent = constrain(waterLevelPercent, 0, 100);

    // === Contrôle pompe automatique ===
    bool shouldActivate = false;
    String alertes = "";

    if (!manualControl) {
      if (willRain) {
        alertes += "☔ Pluie prévue - Irrigation reportée\n";
        shouldActivate = false;
      } else {
        if (soilMoisturePercentage < HUMIDITE_SOL_MIN) {
          shouldActivate = true;
          alertes += "💧 Sol sec (" + String(soilMoisturePercentage) + "%)\n";
        }

        if (temperature < TEMP_MIN || temperature > TEMP_MAX) {
          shouldActivate = true;
          alertes += "🌡️ Température hors limites (" + String(temperature) + "°C)\n";
        }

        if (humidity < HUMIDITE_AIR_MIN || humidity > HUMIDITE_AIR_MAX) {
          shouldActivate = true;
          alertes += "💦 Humidité air hors limites (" + String(humidity) + "%)\n";
        }

        if (pHValue < PH_MIN || pHValue > PH_MAX) {
          shouldActivate = true;
          alertes += "🧪 pH hors limites (" + String(pHValue, 2) + ")\n";
        }

        if (shouldActivate != pumpState) {
          controlPump(shouldActivate);
        }
      }
    }

    // === AFFICHAGE SEULEMENT : humidité sol (%) et niveau d’eau (%) ===
    Serial.print("🌱 Humidité du sol (%): ");
    Serial.println(soilMoisturePercentage);

    Serial.print("💧 Niveau d'eau (%): ");
    Serial.println(waterLevelPercent);

    // === Réponse API JSON ===
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
      json += "\"manual_control\": " + String(manualControl ? "true" : "false") + ",";
      json += "\"water_level_raw\": " + String(waterLevelRaw) + ",";
      json += "\"water_level_percent\": " + String(waterLevelPercent);
      json += "}";

      client.println("HTTP/1.1 200 OK");
      client.println("Content-Type: application/json");
      client.println();
      client.println(json);
    }
    else if (request.indexOf("POST /control") >= 0) {
      String body = "";
      while (client.available()) {
        body += (char)client.read();
      }

      StaticJsonDocument<200> doc;
      DeserializationError error = deserializeJson(doc, body);

      if (!error) {
        bool activate = doc["activate"];
        manualControl = true;
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
      String body = "";
      while (client.available()) {
        body += (char)client.read();
      }

      StaticJsonDocument<200> doc;
      DeserializationError error = deserializeJson(doc, body);

      if (!error) {
        willRain = doc["will_rain"];
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
  }
}
