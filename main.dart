import 'package:flutter/material.dart';

void main() {
  runApp(const SmartParkingApp());
}

class SmartParkingApp extends StatelessWidget {
  const SmartParkingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SpotFinder Dashboard',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const ParkingDashboard(),
    );
  }
}

class ParkingDashboard extends StatefulWidget {
  const ParkingDashboard({super.key});

  @override
  State<ParkingDashboard> createState() => _ParkingDashboardState();
}

class _ParkingDashboardState extends State<ParkingDashboard> {
  // 8 slots (true = free/green, false = occupied/red)
  List<bool> spotsFree = [true, false, true, true, false, true, false, true];

  @override
  Widget build(BuildContext context) {
    int totalSpots = spotsFree.length;
    int availableSpots = spotsFree.where((spot) => spot).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🅿️ SpotFinder Smart Control'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP STATISTICS CARD ---
            Card(
              color: Colors.blueGrey[800],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Available Spots', style: TextStyle(color: Colors.grey)),
                        Text('$availableSpots / $totalSpots', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Occupancy Rate', style: TextStyle(color: Colors.grey)),
                        Text(
                          '${((totalSpots - availableSpots) / totalSpots * 100).toStringAsFixed(0)}%', 
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Live Parking Lot Grid Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('💡 Click a spot to mock a car parking or leaving', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),

            // --- INTERACTIVE GRID MAP ---
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 4 columns of parking spaces
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: totalSpots,
                itemBuilder: (context, index) {
                  bool isFree = spotsFree[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        spotsFree[index] = !spotsFree[index]; // Toggle status when clicked
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isFree ? Colors.green[700] : Colors.red[700],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isFree ? Icons.local_parking : Icons.directions_car,
                            size: 32,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Spot ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            isFree ? 'FREE' : 'OCCUPIED',
                            style: const TextStyle(fontSize: 10, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}