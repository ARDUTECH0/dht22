
# ESP32 DHT22 Monitor 🌡️💧
## 🌐 Connect with Ardu Tech
---
<div align="center">

[![YouTube](https://img.shields.io/badge/YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/@ArduTechs)
[![TikTok](https://img.shields.io/badge/TikTok-000000?style=for-the-badge&logo=tiktok&logoColor=white)](https://www.tiktok.com/@ardutechse)
[![Email](https://img.shields.io/badge/Contact-Email-orange?style=for-the-badge&logo=gmail&logoColor=white)](mailto:seifemadat@gmail.com)

</div>
---
A beautiful, real-time Flutter application for monitoring temperature and humidity from an ESP32 with DHT22 sensor via WebSocket connection. Features stunning neon-themed UI with animated gauges, configurable threshold alerts, and live data visualization.

## ✨ Features

* **Real-time Monitoring**: Live temperature and humidity readings via WebSocket
* **Sleek Circular Gauges**: Beautiful animated gauges with neon glow effects
* **Configurable Thresholds**: Set custom alert limits for temperature and humidity
* **Smart Alerts**: Instant popup notifications when thresholds are exceeded
* **Pulsing Alert Badges**: Eye-catching animated badges for active alerts
* **Dark Neon Theme**: Modern, futuristic UI with gradient backgrounds
* **Responsive Design**: Works seamlessly on mobile and desktop platforms

## 📸 Screenshots

The app features:

* Dual circular gauges for temperature (°C) and humidity (%)
* Neon blue and yellow color scheme
* Animated alert badges with pulsing effects
* Gradient backgrounds and shadow effects
* Easy-to-use threshold configuration panel

## 🔧 Requirements

### Flutter Application

* Flutter SDK 3.0+
* Dart 3.0+

### ESP32 Hardware

* ESP32 development board
* DHT22 (AM2302) temperature and humidity sensor
* Connecting wires
* Power supply (USB or external)

### Dependencies

yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  web_socket_channel: ^2.4.0
  sleek_circular_slider: ^2.0.1
```

## 🚀 Installation

### 1. Clone the Repository

bash

```bash
git clone git@github.com:ARDUTECH0/dht22.git
cd esp32-dht22-monitor
```

### 2. Install Flutter Dependencies

bash

```bash
flutter pub get
```

### 3. Configure WebSocket Connection

Open `lib/main.dart` and update the WebSocket URL with your ESP32's IP address:

dart

```dart
channel = WebSocketChannel.connect(
  Uri.parse("ws://YOUR_ESP32_IP:81"),  // Change to your ESP32 IP
);
```

### 4. Run the Application

bash

```bash
# For mobile/emulator
flutter run

# For desktop
flutter run -d windows  # or macos/linux

# For web
flutter run -d chrome
```

## 🔌 ESP32 Setup

### Hardware Connections

Connect the DHT22 sensor to your ESP32:

```
DHT22 Pin 1 (VCC)  →  ESP32 3.3V
DHT22 Pin 2 (Data) →  ESP32 GPIO 4 (or your chosen pin)
DHT22 Pin 4 (GND)  →  ESP32 GND
Relay Module:
  VCC           →  ESP32 5V (or VIN)
  GND           →  ESP32 GND
  IN            →  ESP32 GPIO 14
```

**Note**: Add a 10kΩ pull-up resistor between VCC and Data pin for stable readings.

### ESP32 Code Example

Here's a basic Arduino sketch for the ESP32:

cpp

```cpp
#include <WiFi.h>
#include <WebSocketsServer.h>
#include <ArduinoJson.h>
#include "DHT.h"


#define DHTPIN 4
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

#define RELAY_PIN 14
bool relayState = false; 

const char* ssid     = "YOUR_WIFI";
const char* password = "YOUR_PASSWORD";


WebSocketsServer webSocket = WebSocketsServer(81);

float maxTemp = 30.0;
float maxHum  = 70.0;

bool tempAlert = false;
bool humAlert  = false;


void handleWebSocketEvent(uint8_t client, WStype_t type, uint8_t *payload, size_t length)
{
  if (type == WStype_TEXT)
  {
    StaticJsonDocument<256> doc;

    if (deserializeJson(doc, payload) == DeserializationError::Ok)
    {
      if (doc.containsKey("maxTemp")) maxTemp = doc["maxTemp"];
      if (doc.containsKey("maxHum"))  maxHum  = doc["maxHum"];

      if (doc.containsKey("relay"))  
      {
        relayState = doc["relay"];
        digitalWrite(RELAY_PIN, relayState ? HIGH : LOW);
      }

      Serial.println("Received Control JSON.");
    }
  }
}


void setup()
{
  Serial.begin(115200);
  dht.begin();

  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW); 

  WiFi.begin(ssid, password);
  Serial.println("Connecting...");
  while (WiFi.status() != WL_CONNECTED) 
  {
    delay(400);
    Serial.print(".");
  }

  Serial.println("\nConnected!");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());

  webSocket.begin();
  webSocket.onEvent(handleWebSocketEvent);
}


void loop()
{
  webSocket.loop();

  float t = dht.readTemperature();
  float  h = dht.readHumidity();

  if (isnan(t) || isnan(h))
    return;

  tempAlert = (t > maxTemp);
  humAlert  = (h > maxHum);

  if (tempAlert || humAlert)
  {
    relayState = true;  
    digitalWrite(RELAY_PIN, HIGH);
  }
  else
  {
    relayState = false;  
    digitalWrite(RELAY_PIN, LOW);
  }

  StaticJsonDocument<256> doc;

  doc["temp"] = t;
  doc["hum"]  = h;

  doc["temp_alert"] = tempAlert;
  doc["hum_alert"]  = humAlert;

  doc["relay"] = relayState;

  if (tempAlert) doc["temp_msg"] = "Temperature High!";
  if (humAlert)  doc["hum_msg"]  = "Humidity High!";

  String jsonString;
  serializeJson(doc, jsonString);

  webSocket.broadcastTXT(jsonString);

  Serial.println(jsonString);

  delay(1000);
}

```

### Required Arduino Libraries

* DHT sensor library by Adafruit
* WebSockets by Markus Sattler
* ArduinoJson by Benoit Blanchon

Install via Arduino Library Manager or PlatformIO.

## 📡 WebSocket Protocol

### Data Format

**From ESP32 to App** (every 2 seconds):

json

```json
{
  "temp": 25.4,
  "hum": 65.2,
  "temp_alert": false,
  "hum_alert": true
}
```

**From App to ESP32** (when updating thresholds):

json

```json
{
  "maxTemp": 30.0,
  "maxHum": 70.0
}
```

## 🎨 Customization

### Change Color Theme

Modify the color constants in `lib/main.dart`:

dart

```dart
const neonBlue = Color(0xFF00E5FF);     // Temperature gauge
const neonYellow = Color(0xFFFFD54F);   // Humidity gauge
```

### Adjust Gauge Ranges

Update the `max` parameter in `_buildGauge()`:

dart

```dart
_buildGauge(
  max: 60,  // Maximum temperature (°C)
  // ...
)
```

### Change Update Frequency

Modify the ESP32 code loop delay and Flutter's WebSocket listener will automatically sync.

## 🐛 Troubleshooting

### Connection Issues

* **Can't connect to ESP32**:
  * Verify ESP32 is on the same WiFi network
  * Check the IP address matches in the Flutter code
  * Ensure WebSocket server is running on port 81
  * Check firewall settings

### Sensor Reading Issues

* **Getting NaN values**:
  * Verify DHT22 wiring (especially the pull-up resistor)
  * Check power supply (DHT22 requires stable 3.3V-5V)
  * Ensure correct GPIO pin in ESP32 code

### App Issues

* **Gauges not updating**:
  * Check WebSocket connection in debug console
  * Verify JSON format from ESP32
  * Ensure Flutter app has network permissions

### Alert Not Triggering

* Verify threshold values are sent successfully
* Check ESP32 serial monitor for received thresholds
* Ensure `temp_alert` and `hum_alert` are being sent in JSON

## 📱 Platform Support

* ✅ Android
* ✅ iOS
* ✅ Windows
* ✅ macOS
* ✅ Linux
* ✅ Web

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 🙏 Acknowledgments

* [sleek\_circular\_slider](https://pub.dev/packages/sleek_circular_slider) for beautiful gauge widgets
* [web\_socket\_channel](https://pub.dev/packages/web_socket_channel) for WebSocket functionality
* DHT22 sensor and ESP32 community for hardware support

## 📧 Contact

For questions or suggestions, please open an issue on GitHub.

---

**Made with ❤️ using Flutter and ESP32**
