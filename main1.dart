import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const SmartParkingApp());
}

class SmartParkingApp extends StatelessWidget {
  const SmartParkingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartPark Nepal',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF060A16),
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
  // --- UI State Variables ---
  String selectedFacility = 'civil'; // Matches 'civil', 'bir', or 'passport'
  int walletBalance = 1240;
  String activeVehicle = 'BA 2 PA';
  bool isScannerOpen = false;
  
  // Timer State
  int mins = 42;
  int secs = 18;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (secs > 0) {
            secs--;
          } else {
            if (mins > 0) {
              mins--;
              secs = 59;
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Interaction Handlers ---
  void selectFacility(String id) {
    setState(() {
      selectedFacility = id;
    });
  }

  void toggleVehicle() {
    setState(() {
      if (activeVehicle == 'BA 2 PA') {
        activeVehicle = 'BA 3 CHA';
      } else {
        activeVehicle = 'BA 2 PA';
      }
    });
  }

  void topUpWallet() {
    setState(() {
      walletBalance += 500;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚡ Rs. 500 added to cyber-wallet balance!'),
        backgroundColor: Color(0xFF00E5FF),
      ),
    );
  }

  void extendSession() {
    setState(() {
      mins += 15;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚡ Baseline session extended by 15 mins!'),
        backgroundColor: Color(0xFF39FFC1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // MAIN SCROLLABLE APP BODY
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 110), // Padding to clear the custom nav bar
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    _buildHeader(),
                    const SizedBox(height: 15),
                    _buildRadarCard(),
                    const SizedBox(height: 12),
                    _buildHudStrip(),
                    const SizedBox(height: 12),
                    _buildSearchCta(),
                    const SizedBox(height: 15),
                    _buildSectionHeader(),
                    const SizedBox(height: 8),
                    _buildFacilitiesList(),
                  ],
                ),
              ),
            ),
          ),

          // FLOATING NEON NAVIGATION BAR
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: _buildBottomNavigationBar(),
          ),

          // FULLSCREEN HOLOGRAPHIC SCANNER MODAL
          if (isScannerOpen) _buildScannerModal(),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF39FFC1),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Color(0xFF39FFC1), blurRadius: 8)],
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'SYSTEM ONLINE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    letterSpacing: 2,
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Good evening, Sabal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF8C5CFF), Color(0xFF00E5FF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8C5CFF).withOpacity(0.4),
                blurRadius: 10,
              )
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            'SG',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF060A16)),
          ),
        ),
      ],
    );
  }

  Widget _buildRadarCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1526).withOpacity(0.9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.08),
            blurRadius: 25,
          )
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KATHMANDU VALLEY GRID',
                style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF8FA3C4)),
              ),
              Text(
                'LIVE SCAN',
                style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF39FFC1)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Spinning Radar Screen
          SizedBox(
            height: 140,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Radar Grid Lines (Circles)
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.15)),
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.1)),
                  ),
                ),
                // Crosshairs
                Container(width: 140, height: 1, color: const Color(0xFF00E5FF).withOpacity(0.1)),
                Container(width: 1, height: 140, color: const Color(0xFF00E5FF).withOpacity(0.1)),
                
                // Continuous Radar Sweep Line
                const RadarSweep(),

                // Center Pin Node
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.white, blurRadius: 10, spreadRadius: 2),
                    ],
                  ),
                ),

                // Map Blips
                Positioned(
                  top: 20,
                  left: 100,
                  child: RadarBlip(
                    color: const Color(0xFF39FFC1),
                    isActive: selectedFacility == 'civil',
                    onTap: () => selectFacility('civil'),
                  ),
                ),
                Positioned(
                  top: 80,
                  left: 45,
                  child: RadarBlip(
                    color: const Color(0xFF39FFC1),
                    isActive: selectedFacility == 'bir',
                    onTap: () => selectFacility('bir'),
                  ),
                ),
                Positioned(
                  top: 110,
                  left: 165,
                  child: RadarBlip(
                    color: const Color(0xFFFFB347),
                    isActive: selectedFacility == 'passport',
                    onTap: () => selectFacility('passport'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '12 spots detected within 2km',
                style: TextStyle(fontFamily: 'monospace', fontSize: 10.5, color: Color(0xFF39FFC1)),
              ),
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withOpacity(0.06),
                    border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Expand Map',
                    style: TextStyle(fontSize: 10, color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHudStrip() {
    return Row(
      children: [
        // Countdown Chip
        Expanded(
          child: _buildHudChip(
            label: 'ACTIVE SESSION',
            value: '$mins:${secs < 10 ? '0$secs' : secs}',
            isActive: true,
            onTap: extendSession,
          ),
        ),
        const SizedBox(width: 8),
        // Wallet Chip
        Expanded(
          child: _buildHudChip(
            label: 'WALLET',
            value: '₨$walletBalance',
            onTap: topUpWallet,
          ),
        ),
        const SizedBox(width: 8),
        // Vehicle Chip
        Expanded(
          child: _buildHudChip(
            label: 'VEHICLE',
            value: activeVehicle,
            onTap: toggleVehicle,
          ),
        ),
      ],
    );
  }

  Widget _buildHudChip({
    required String label,
    required String value,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1526),
          border: Border.all(
            color: isActive ? const Color(0xFF39FFC1) : const Color(0xFF00E5FF).withOpacity(0.16),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 8.5,
                letterSpacing: 1,
                color: Color(0xFF4D6082),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isActive ? const Color(0xFF39FFC1) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCta() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00E5FF).withOpacity(0.12),
            const Color(0xFF8C5CFF).withOpacity(0.12),
          ],
        ),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF8C5CFF)],
              ),
            ),
            child: const Icon(Icons.search, color: Color(0xFF060A16), size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Where are you parking?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 2),
                Text(
                  'TAP TO SEARCH · BOOK · SCAN',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF8FA3C4)),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF00E5FF)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'NEARBY FACILITIES',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11.5,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          'VIEW ALL',
          style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF00E5FF)),
        ),
      ],
    );
  }

  Widget _buildFacilitiesList() {
    return Column(
      children: [
        _buildFacilityCard(
          id: 'civil',
          name: 'Civil Mall Parking',
          meta: 'SUNDHARA · 0.6 KM',
          price: 'Rs. 60/hr',
          slots: '18 OPEN',
          isLow: false,
        ),
        const SizedBox(height: 8),
        _buildFacilityCard(
          id: 'bir',
          name: 'Bir Hospital Lot B',
          meta: 'MAHABOUDHA · 1.1 KM',
          price: 'Rs. 40/hr',
          slots: '9 OPEN',
          isLow: false,
        ),
        const SizedBox(height: 8),
        _buildFacilityCard(
          id: 'passport',
          name: 'Department of Passports',
          meta: 'TRIPURESHWOR · 1.4 KM',
          price: 'Rs. 50/hr',
          slots: '2 LEFT',
          isLow: true,
        ),
      ],
    );
  }

  Widget _buildFacilityCard({
    required String id,
    required String name,
    required String meta,
    required String price,
    required String slots,
    required bool isLow,
  }) {
    final isSelected = selectedFacility == id;

    return InkWell(
      onTap: () => selectFacility(id),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF121C33) : const Color(0xFF0D1526),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.12), blurRadius: 10)]
              : [],
        ),
        child: Row(
          children: [
            // Colored Status Bar
            Container(
              width: 3.5,
              height: 38,
              decoration: BoxDecoration(
                color: isLow ? const Color(0xFFFFB347) : const Color(0xFF39FFC1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, color: Color(0xFF8FA3C4)),
                  ),
                ],
              ),
            ),
            // Price / Slots
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  slots,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9.5,
                    color: isLow ? const Color(0xFFFFB347) : const Color(0xFF39FFC1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF0A1020).withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'HOME', true),
          _buildNavItem(Icons.map, 'MAP', false, onTap: () {}),
          
          // Action scanner Center Button
          GestureDetector(
            onTap: () => setState(() => isScannerOpen = true),
            child: Transform.translate(
              offset: const Offset(0, -10),
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF8C5CFF)],
                  ),
                  boxShadow: [
                    BoxShadow(color: Color(0xFF00E5FF), blurRadius: 15),
                  ],
                ),
                child: const Icon(Icons.qr_code_scanner, color: Color(0xFF060A16), size: 22),
              ),
            ),
          ),
          
          _buildNavItem(Icons.wallet, 'WALLET', false, onTap: topUpWallet),
          _buildNavItem(Icons.person, 'PROFILE', false, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? const Color(0xFF00E5FF) : const Color(0xFF4D6082), size: 20),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8.5,
              color: isActive ? const Color(0xFF00E5FF) : const Color(0xFF4D6082),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerModal() {
    return Container(
      color: const Color(0xFF04070F).withOpacity(0.96),
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Holographic Scanning Box
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF00E5FF), width: 2),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.3),
                  blurRadius: 20,
                )
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const LaserScanLine(),
                Icon(Icons.qr_code, color: const Color(0xFF00E5FF).withOpacity(0.4), size: 100),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'SCANNING PASS',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ALIGN THE GATE QR BARCODE WITHIN THE FRAME',
            style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF8FA3C4)),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => setState(() => isScannerOpen = false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00E5FF)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text(
              'ABORT SCAN',
              style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// --- HELPER ANIMATION WIDGETS ---

class RadarSweep extends StatefulWidget {
  const RadarSweep({super.key});

  @override
  State<RadarSweep> createState() => _RadarSweepState();
}

class _RadarSweepState extends State<RadarSweep> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: 140,
        height: 140,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              Color(0x8C00E5FF),
              Color(0x0000E5FF),
            ],
            stops: [0.15, 1.0],
          ),
        ),
      ),
    );
  }
}

class RadarBlip extends StatefulWidget {
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const RadarBlip({
    super.key,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<RadarBlip> createState() => _RadarBlipState();
}

class _RadarBlipState extends State<RadarBlip> with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _rippleController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Ripple ring animation
              Container(
                width: 20 * (1.0 + _rippleController.value * 0.8),
                height: 20 * (1.0 + _rippleController.value * 0.8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withOpacity(1.0 - _rippleController.value),
                    width: 1.5,
                  ),
                ),
              ),
              // Center solid node
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: widget.isActive ? 14 : 9,
                height: widget.isActive ? 14 : 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color,
                      blurRadius: widget.isActive ? 12 : 4,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class LaserScanLine extends StatefulWidget {
  const LaserScanLine({super.key});

  @override
  State<LaserScanLine> createState() => _LaserScanLineState();
}

class _LaserScanLineState extends State<LaserScanLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _animation = Tween<double>(begin: 4, end: 194).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: _animation.value,
          left: 4,
          right: 4,
          child: Container(
            height: 3,
            decoration: const BoxDecoration(
              color: Color(0xFF00E5FF),
              boxShadow: [
                BoxShadow(color: Color(0xFF00E5FF), blurRadius: 10, spreadRadius: 1),
              ],
            ),
          ),
        );
      },
    );
  }
}