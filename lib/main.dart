import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E27),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFFFFD54F),
        ),
      ),
      home: const SensorPage(),
    );
  }
}

class SensorPage extends StatefulWidget {
  const SensorPage({super.key});

  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> with SingleTickerProviderStateMixin {
  late WebSocketChannel channel;
  late AnimationController _pulseController;
  double temp = 0;
  double hum = 0;
  bool tempAlert = false;
  bool humAlert = false;
  bool prevTempAlert = false;
  bool prevHumAlert = false;
  TextEditingController tempCtrl = TextEditingController(text: "30");
  TextEditingController humCtrl = TextEditingController(text: "70");

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    channel = WebSocketChannel.connect(
      Uri.parse("ws://192.168.1.32:81"),
    );
    channel.stream.listen((msg) {
      try {
        final data = jsonDecode(msg);
        final double newTemp = (data["temp"] as num?)?.toDouble() ?? temp;
        final double newHum = (data["hum"] as num?)?.toDouble() ?? hum;
        final bool newTempAlert = data["temp_alert"] ?? false;
        final bool newHumAlert = data["hum_alert"] ?? false;

        bool showPopup = (!tempAlert && newTempAlert) || (!humAlert && newHumAlert);

        setState(() {
          temp = newTemp;
          hum = newHum;
          prevTempAlert = tempAlert;
          prevHumAlert = humAlert;
          tempAlert = newTempAlert;
          humAlert = newHumAlert;
        });

        if (showPopup) _showAlertPopup();
      } catch (_) {}
    });
  }

  void sendThresholds() {
    final json = jsonEncode({
      "maxTemp": double.tryParse(tempCtrl.text) ?? 30,
      "maxHum": double.tryParse(humCtrl.text) ?? 70,
    });
    channel.sink.add(json);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✓ Thresholds updated successfully'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAlertPopup() {
    String msg = "";
    if (tempAlert && !prevTempAlert) msg += "🔥 الحرارة أعلى من الحد!\n";
    if (humAlert && !prevHumAlert) msg += "💧 الرطوبة أعلى من الحد!";
    if (msg.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF1A1F3A),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 28),
            ),
            const SizedBox(width: 12),
            const Text("Alert", style: TextStyle(color: Colors.white, fontSize: 22)),
          ],
        ),
        content: Text(msg, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF).withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("OK", style: TextStyle(color: Color(0xFF00E5FF), fontSize: 16)),
          )
        ],
      ),
    );
  }

  Widget _buildGauge({
    required String label,
    required double value,
    required String unit,
    required double max,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1F3A),
            const Color(0xFF0F1424),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SleekCircularSlider(
            min: 0,
            max: max,
            initialValue: value.clamp(0, max),
            appearance: CircularSliderAppearance(
              size: 140,
              startAngle: 210,
              angleRange: 300,
              customWidths: CustomSliderWidths(trackWidth: 6, progressBarWidth: 12),
              customColors: CustomSliderColors(
                trackColor: Colors.white.withOpacity(0.08),
                progressBarColors: [color.withOpacity(0.5), color],
                dotColor: Colors.white,
                shadowColor: color,
                shadowMaxOpacity: 0.3,
              ),
              infoProperties: InfoProperties(
                mainLabelStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: color.withOpacity(0.5), blurRadius: 10),
                  ],
                ),
                modifier: (d) => "${d.toStringAsFixed(1)}",
                bottomLabelText: unit,
                bottomLabelStyle: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBadge(String text, Color color, IconData icon) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.2 + _pulseController.value * 0.1),
                color.withOpacity(0.1 + _pulseController.value * 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: color.withOpacity(0.5 + _pulseController.value * 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    channel.sink.close();
    tempCtrl.dispose();
    humCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const neonBlue = Color(0xFF00E5FF);
    const neonYellow = Color(0xFFFFD54F);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ESP32 DHT22 Monitor",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F1424),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0F1424),
                const Color(0xFF1A1F3A),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F1424),
              const Color(0xFF0A0E27),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Gauges
              Row(
                children: [
                  Expanded(
                    child: _buildGauge(
                      label: "Temperature",
                      value: temp,
                      unit: "°C",
                      max: 60,
                      color: neonBlue,
                      icon: Icons.thermostat_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildGauge(
                      label: "Humidity",
                      value: hum,
                      unit: "%",
                      max: 100,
                      color: neonYellow,
                      icon: Icons.water_drop_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Alert Badges
              if (tempAlert || humAlert)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      if (tempAlert)
                        _buildAlertBadge("Temperature Alert", Colors.redAccent, Icons.local_fire_department_rounded),
                      if (humAlert)
                        _buildAlertBadge("Humidity Alert", Colors.lightBlueAccent, Icons.water_drop_rounded),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              // Threshold Controls
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A1F3A),
                      const Color(0xFF0F1424),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: neonBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.settings_rounded, color: neonBlue, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Threshold Settings",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Max Temperature",
                                style: TextStyle(
                                  color: neonBlue.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: tempCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  suffixText: "°C",
                                  suffixStyle: TextStyle(color: neonBlue.withOpacity(0.6)),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: neonBlue.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: neonBlue, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Max Humidity",
                                style: TextStyle(
                                  color: neonYellow.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: humCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  suffixText: "%",
                                  suffixStyle: TextStyle(color: neonYellow.withOpacity(0.6)),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: neonYellow.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: neonYellow, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: sendThresholds,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: neonBlue,
                          foregroundColor: const Color(0xFF0A0E27),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 8,
                          shadowColor: neonBlue.withOpacity(0.5),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 22),
                            SizedBox(width: 8),
                            Text(
                              "Update Thresholds",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}