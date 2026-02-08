#include <WiFi.h>
#include <WebServer.h>
#include <ESP32Servo.h>

// const char* ssid = "yfho";
// const char* password = "yfho7080";
const char* ssid = "Tellmewhyyouwannausethis";
const char* password = "nopaSs4you";

// ===== SERVO CONFIG =====
Servo barrier;
const int SERVO_PIN = 13;   // Use D13 (GPIO13)
const int CLOSED_ANGLE = 90;
const int OPEN_ANGLE = 0;

// ===== TIMER VARIABLES =====
unsigned long openStartTime = 0; 
bool isTimerActive = false;       
const long interval = 5000;

// ===== WEB SERVER =====
WebServer server(80);

// ===== HANDLERS =====
void handleReserve() {
  isTimerActive = false;
  barrier.write(CLOSED_ANGLE);
  Serial.println("RESERVE → Barrier CLOSED (90°)");
  server.send(200, "text/plain", "Barrier closed");
}

void handleArrive() {
  barrier.write(OPEN_ANGLE); 
  Serial.println("ARRIVE → Barrier OPEN (0°)");

  openStartTime = millis();
  isTimerActive = true;

  server.send(200, "text/plain", "Barrier opened - closing in 5s");
}

void handleLeave() {
  isTimerActive = false;
  barrier.write(OPEN_ANGLE);
  Serial.println("LEAVE → Barrier OPEN (0°)");
  server.send(200, "text/plain", "Barrier opened");
}

void setup() {
  Serial.begin(115200);

  // Attach servo
  barrier.attach(SERVO_PIN);
  barrier.write(CLOSED_ANGLE); // default closed

  // Connect WiFi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    Serial.print(" Status: "); 
    Serial.println(WiFi.status());
  }

  Serial.println("\nWiFi connected!");
  Serial.print("ESP32 IP: ");
  Serial.println(WiFi.localIP());

  // Routes
  server.on("/reserve", handleReserve);
  server.on("/arrive", handleArrive);
  server.on("/leave", handleLeave);

  server.begin();
  Serial.println("ESP32 server started");
}

void loop() {
  server.handleClient();

  if (isTimerActive) {
    unsigned long currentMillis = millis();
    
    // Check if 5 seconds have passed
    if (currentMillis - openStartTime >= interval) {
      barrier.write(CLOSED_ANGLE);
      isTimerActive = false; // Reset timer
      Serial.println("TIMER → 5s elapsed, Barrier CLOSED (90°)");
    }
  }
}