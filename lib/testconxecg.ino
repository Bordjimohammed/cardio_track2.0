#include <WiFi.h>

#define ADC_VREF_mV 3300.0 // en millivolts
#define ADC_RESOLUTION 4096.0 //la résolution est de 4096 niveaux (de 0 à 4095)
#define cap 36 // Broche GPIO36 (ADC0) de l'ESP32 connectée au LM35

const char* ssid = "OPPO F19"; //votre ssid wifi
const char* password = "g7hpcpnu"; // Votre mot de passe WiFi

WiFiServer server(80); // Serveur web fonctionnant sur le port 80

void setup() {
  Serial.begin(9600);  // Démarre la communication série pour le débogage
pinMode(22, INPUT); // Setup for leads off detection LO +22
pinMode(23, INPUT); // Setup for leads off detection LO -23
  // Connexion au WiFi
  Serial.print("Connecting to ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);

  // Attente de la connexion
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected.");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

  server.begin();  // Démarre le serveur web
}

void loop() {
  // Vérifie si un client s'est connecté
  WiFiClient client = server.available();
  
  if (client) {
   //// Serial.println("New Client connected.");
    String request = "";

    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        request += c;
        Serial.write(c);
        
         // Fin de la requête du client
        if (c == '\n') {
          // Répond au client
          client.println("HTTP/1.1 200 OK");
          client.println("Content-Type: application/json");
          client.println("Connection: close");
          client.println();

          // Lire la valeur ADC du capteur et la convertir en millivolts
             if((digitalRead(22) == 1)||(digitalRead(23) == 1)){
          Serial.println('!');
                }
          else{ 
          int adcVal = analogRead(cap); // lire la valeur numerique  du PPG
          float milliVolt = adcVal * (ADC_VREF_mV / ADC_RESOLUTION);// conversion de la valeur  numerique en voltage 
  
         // Serial.println(milliVolt);// envoyer la valeur numeriue vers le port USB 
// Créer la réponse JSON
          String jsonResponse = "{\"milliVolt\": " + String(milliVolt, 2) + "}";

          // Envoyer la réponse JSON
          client.println(jsonResponse);
          Serial.println(milliVolt);
}
          delay(4);
          // Quitter la boucle après la réponse
          break;
        }
      }
    }

    // Fermer la connexion
    client.stop();
    Serial.println("Client disconnected.");
  }
}