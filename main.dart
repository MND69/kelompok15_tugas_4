import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const RenewableEnergyApp());
}

class RenewableEnergyApp extends StatelessWidget {
  const RenewableEnergyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard Energi Hijau',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const EnergyDashboard(),
    );
  }
}

class EnergyDashboard extends StatefulWidget {
  const EnergyDashboard({super.key});

  @override
  State<EnergyDashboard> createState() => _EnergyDashboardState();
}

class _EnergyDashboardState extends State<EnergyDashboard> {
  // --- STATE MANAGEMENT ---
  Offset sunPosition = const Offset(150, 80);
  bool isSolarActive = true;
  bool isWindBoosted = false;
  bool isWeeklyChart = false;
  double summaryScale = 1.0;
  double _baseSummaryScale = 1.0;
  
  // Data real-time untuk grafik
  List<FlSpot> _realTimeData = [];
  int _timeCounter = 0;

  // Notifikasi dinamis (akan di-generate otomatis)
  List<Map<String, dynamic>> systemAlerts = [];

  // Data historis untuk referensi
  final List<FlSpot> _weeklyData = const [
    FlSpot(0, 40), FlSpot(1, 45), FlSpot(2, 38), FlSpot(3, 50),
    FlSpot(4, 55), FlSpot(5, 48), FlSpot(6, 60),
  ];

  @override
  void initState() {
    super.initState();
    _initializeRealTimeData();
    _generateDynamicAlerts(); // Generate notifikasi awal
  }

  void _initializeRealTimeData() {
    _realTimeData = [FlSpot(0, totalEnergyOutput)];
  }

  void _addRealTimeDataPoint() {
    setState(() {
      _timeCounter++;
      _realTimeData.add(FlSpot(_timeCounter.toDouble(), totalEnergyOutput));
      if (_realTimeData.length > 20) {
        _realTimeData.removeAt(0);
      }
    });
  }

  // ==========================================
  // FUNGSI UTAMA: GENERATE NOTIFIKASI DINAMIS
  // ==========================================
  void _generateDynamicAlerts() {
    final List<Map<String, dynamic>> newAlerts = [];
    int idCounter = 1;

    // 1. Cek kondisi matahari (posisi Y)
    if (sunPosition.dy >= 160) {
      // Malam hari
      newAlerts.add({
        'id': idCounter++,
        'title': '🌙 Efisiensi Surya Rendah',
        'desc': 'Matahari di posisi rendah. Output panel surya minimal.',
        'icon': Icons.nightlight_round,
        'color': Colors.indigo,
        'severity': 'warning',
      });
    } else if (sunPosition.dy < 80) {
      // Siang terik
      newAlerts.add({
        'id': idCounter++,
        'title': '️ Peringatan Suhu Panel',
        'desc': 'Intensitas cahaya tinggi. Pantau suhu panel surya.',
        'icon': Icons.thermostat,
        'color': Colors.red,
        'severity': 'danger',
      });
    } else {
      // Sore/pagi
      newAlerts.add({
        'id': idCounter++,
        'title': '️ Waktu Optimal Produksi',
        'desc': 'Kondisi cahaya ideal untuk produksi energi surya.',
        'icon': Icons.wb_sunny,
        'color': Colors.orange,
        'severity': 'info',
      });
    }

    // 2. Cek status Panel Surya
    if (!isSolarActive) {
      newAlerts.add({
        'id': idCounter++,
        'title': '⚫ Panel Surya Nonaktif',
        'desc': 'Sistem panel surya sedang dimatikan. Output 0 kW.',
        'icon': Icons.power_off,
        'color': Colors.grey,
        'severity': 'warning',
      });
    } else {
      newAlerts.add({
        'id': idCounter++,
        'title': '🟢 Panel Surya Beroperasi',
        'desc': 'Output surya: ${(solarEfficiency * 5.0).toStringAsFixed(1)} kW',
        'icon': Icons.solar_power,
        'color': Colors.green,
        'severity': 'success',
      });
    }

    // 3. Cek status Turbin Angin
    if (isWindBoosted) {
      newAlerts.add({
        'id': idCounter++,
        'title': '🚀 Mode Boost Turbin Aktif',
        'desc': 'Turbin berputar maksimal (8 kW). Konsumsi pendingin meningkat.',
        'icon': Icons.rocket_launch,
        'color': Colors.blue,
        'severity': 'info',
      });
    } else {
      newAlerts.add({
        'id': idCounter++,
        'title': '💨 Turbin Beroperasi Normal',
        'desc': 'Output angin stabil di 4.0 kW.',
        'icon': Icons.wind_power,
        'color': Colors.teal,
        'severity': 'success',
      });
    }

    // 4. Cek total output energi
    if (totalEnergyOutput >= 10.0) {
      newAlerts.add({
        'id': idCounter++,
        'title': '⚡ Produksi Energi Optimal!',
        'desc': 'Total output ${totalEnergyOutput.toStringAsFixed(1)} kW. Performa maksimal.',
        'icon': Icons.bolt,
        'color': Colors.amber,
        'severity': 'success',
      });
    } else if (totalEnergyOutput < 3.0) {
      newAlerts.add({
        'id': idCounter++,
        'title': ' Produksi Energi Rendah',
        'desc': 'Total output hanya ${totalEnergyOutput.toStringAsFixed(1)} kW. Periksa sistem.',
        'icon': Icons.battery_alert,
        'color': Colors.red,
        'severity': 'danger',
      });
    } else {
      newAlerts.add({
        'id': idCounter++,
        'title': '📊 Output Energi Stabil',
        'desc': 'Total output ${totalEnergyOutput.toStringAsFixed(1)} kW dalam batas normal.',
        'icon': Icons.show_chart,
        'color': Colors.green,
        'severity': 'info',
      });
    }

    // Update state dengan notifikasi baru
    setState(() {
      systemAlerts = newAlerts;
    });
  }

  double get solarEfficiency => (1.0 - (sunPosition.dy / 250.0)).clamp(0.0, 1.0);
  
  double get totalEnergyOutput {
    double solarPower = isSolarActive ? (solarEfficiency * 5.0) : 0.0;
    double windPower = isWindBoosted ? 8.0 : 4.0;
    return solarPower + windPower;
  }

  Color get skyColor {
    if (sunPosition.dy < 80) return Colors.lightBlueAccent;
    if (sunPosition.dy < 160) return Colors.orangeAccent;
    return Colors.indigo.shade900;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Dashboard Energi Hijau'),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSkyArea(),
            _buildEnergySummary(),
            _buildEnergyChart(),
            _buildGeneratorCards(),
            _buildSystemAlerts(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. AREA LANGIT (DRAG/PAN) - UPDATE NOTIFIKASI
  // ==========================================
  Widget _buildSkyArea() {
    return Container(
      height: 250, width: double.infinity, color: skyColor,
      child: Stack(
        children: [
          Positioned(top: 30, left: 20, child: Icon(Icons.cloud, color: Colors.white.withOpacity(0.6), size: 50)),
          Positioned(top: 60, right: 40, child: Icon(Icons.cloud, color: Colors.white.withOpacity(0.4), size: 40)),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut,
            left: sunPosition.dx, top: sunPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  final screenWidth = MediaQuery.sizeOf(context).width;
                  sunPosition = Offset(
                    (sunPosition.dx + details.delta.dx).clamp(0.0, screenWidth - 60),
                    (sunPosition.dy + details.delta.dy).clamp(0.0, 190.0),
                  );
                });
                _addRealTimeDataPoint();
                _generateDynamicAlerts(); // ← Update notifikasi saat matahari digeser
              },
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.yellow, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.6), blurRadius: 20, spreadRadius: 5)],
                ),
                child: const Icon(Icons.wb_sunny, color: Colors.deepOrange, size: 30),
              ),
            ),
          ),
          Positioned(
            bottom: 10, left: 0, right: 0,
            child: Text("Geser Matahari | Cubit Kartu | Ketuk 2x Grafik | Geser Notifikasi",
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  // ==========================================
  // 2. RINGKASAN ENERGI (SCALE/PINCH)
  // ==========================================
  Widget _buildEnergySummary() {
    return GestureDetector(
      onScaleStart: (details) => _baseSummaryScale = summaryScale,
      onScaleUpdate: (details) {
        setState(() {
          summaryScale = (_baseSummaryScale * details.scale).clamp(0.8, 1.5);
        });
      },
      child: AnimatedScale(
        scale: summaryScale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(16), margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Total Output", "${totalEnergyOutput.toStringAsFixed(1)} kW", Icons.bolt, Colors.amber),
              _buildStatItem("Efisiensi Surya", "${(solarEfficiency * 100).toStringAsFixed(0)}%", Icons.solar_power, Colors.orange),
              _buildStatItem("Daya Angin", "${isWindBoosted ? 8.0 : 4.0} kW", Icons.wind_power, Colors.cyan),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 30),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]);
  }

  // ==========================================
  // 3. GRAFIK ENERGI REAL-TIME (DOUBLE TAP)
  // ==========================================
  Widget _buildEnergyChart() {
    return Container(
      height: 220, margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isWeeklyChart ? "Riwayat Mingguan (kWh)" : "Output Real-Time (kW)", 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const Text("Ketuk 2x untuk ubah", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GestureDetector(
              onDoubleTap: () {
                setState(() => isWeeklyChart = !isWeeklyChart);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isWeeklyChart ? "Tampilan: Mingguan" : "Tampilan: Real-Time"), duration: const Duration(seconds: 1))
                );
              },
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, reservedSize: 22, interval: isWeeklyChart ? 1 : 4,
                        getTitlesWidget: (value, meta) {
                          return Text(isWeeklyChart ? 'S${value.toInt()}' : 'T${value.toInt()}', 
                            style: const TextStyle(fontSize: 10, color: Colors.grey));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: isWeeklyChart ? _weeklyData : _realTimeData,
                      isCurved: true,
                      color: isWeeklyChart ? Colors.purple.shade600 : Colors.green.shade600,
                      barWidth: 3, isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: !isWeeklyChart,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.green.shade600,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: (isWeeklyChart ? Colors.purple.shade200 : Colors.green.shade200).withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. KARTU GENERATOR (TAP & LONG PRESS) - UPDATE NOTIFIKASI
  // ==========================================
  Widget _buildGeneratorCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(children: [_buildSolarCard(), const SizedBox(height: 16), _buildWindCard()]),
    );
  }

  Widget _buildSolarCard() {
    return Card(
      elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          setState(() => isSolarActive = !isSolarActive);
          _addRealTimeDataPoint();
          _generateDynamicAlerts(); // ← Update notifikasi saat panel di-toggle
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(colors: isSolarActive 
              ? [Colors.orange.shade300, Colors.deepOrange.shade400] 
              : [Colors.grey.shade400, Colors.grey.shade600]),
          ),
          child: Row(children: [
            Icon(Icons.solar_power, size: 50, color: isSolarActive ? Colors.white : Colors.grey[200]),
            const SizedBox(width: 20),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Panel Surya", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(isSolarActive ? "Status: AKTIF" : "Status: NONAKTIF", style: TextStyle(color: Colors.white.withOpacity(0.9))),
              Text("Output: ${isSolarActive ? (solarEfficiency * 5.0).toStringAsFixed(1) : 0.0} kW", 
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
            ])),
            Icon(isSolarActive ? Icons.toggle_on : Icons.toggle_off, size: 40, color: Colors.white)
          ]),
        ),
      ),
    );
  }

  Widget _buildWindCard() {
    return Card(
      elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.heavyImpact();
          _showBoostDialog();
          setState(() => isWindBoosted = !isWindBoosted);
          _addRealTimeDataPoint();
          _generateDynamicAlerts(); // ← Update notifikasi saat turbin di-boost
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300), padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(colors: isWindBoosted 
              ? [Colors.cyan.shade400, Colors.blue.shade700] 
              : [Colors.teal.shade300, Colors.teal.shade600]),
          ),
          child: Row(children: [
            AnimatedScale(scale: isWindBoosted ? 1.2 : 1.0, duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.wind_power, size: 50, color: Colors.white)),
            const SizedBox(width: 20),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Turbin Angin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(isWindBoosted ? "Mode: BOOST AKTIF" : "Mode: NORMAL", style: TextStyle(color: Colors.white.withOpacity(0.9))),
              Text("Output: ${isWindBoosted ? 8.0 : 4.0} kW", 
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
            ])),
            if (isWindBoosted) const Icon(Icons.rocket_launch, size: 30, color: Colors.yellowAccent)
          ]),
        ),
      ),
    );
  }

  // ==========================================
  // 5. NOTIFIKASI DINAMIS (SWIPE/DISMISS)
  // ==========================================
  Widget _buildSystemAlerts() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Notifikasi & Peringatan Sistem", 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: _generateDynamicAlerts, // Tombol refresh manual
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Refresh"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (systemAlerts.isEmpty)
            Container(
              padding: const EdgeInsets.all(20), width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
              child: const Text("Tidak ada notifikasi.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            )
          else
            ListView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemCount: systemAlerts.length,
              itemBuilder: (context, index) {
                final alert = systemAlerts[index];
                final alertColor = alert['color'] as Color;
                final alertIcon = alert['icon'] as IconData;
                final severity = alert['severity'] as String;

                // Warna border berdasarkan severity
                Color borderColor;
                switch (severity) {
                  case 'danger': borderColor = Colors.red.shade300; break;
                  case 'warning': borderColor = Colors.orange.shade300; break;
                  case 'success': borderColor = Colors.green.shade300; break;
                  default: borderColor = Colors.blue.shade300;
                }

                return Dismissible(
                  key: Key(alert['id'].toString()),
                  direction: DismissDirection.horizontal,
                  background: Container(
                    alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    setState(() => systemAlerts.removeAt(index));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text("Notifikasi dihapus"), backgroundColor: Colors.red[400], duration: const Duration(seconds: 1))
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: borderColor, width: 2), // Border berwarna
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: alertColor.withOpacity(0.2), 
                        child: Icon(alertIcon, color: alertColor)
                      ),
                      title: Text(alert['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(alert['desc'], style: const TextStyle(fontSize: 12)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: alertColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          severity.toUpperCase(),
                          style: TextStyle(color: alertColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showBoostDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isWindBoosted ? "Nonaktifkan Boost?" : "Aktifkan Boost Mode?"),
          content: Text(isWindBoosted 
            ? "Turbin akan kembali ke output normal (4 kW)."
            : "Turbin akan dipaksa berputar maksimal (8 kW)."),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Batal")),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Konfirmasi")),
          ],
        );
      },
    );
  }
}