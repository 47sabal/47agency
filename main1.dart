import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        primaryColor: const Color(0xFF0066FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066FF),
          brightness: Brightness.light,
        ),
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
  final String baseUrl = 'http://localhost:2001/api/parking';

  // State-level MapController so it persists across rebuilds
  final MapController _expandedMapController = MapController();

  int _currentNavIndex = 0;
  String selectedFacility = 'civil';
  int walletBalance = 1240;
  String activeVehicle = 'BA 2 PA';
  
  // Search query state
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Map<String, Map<String, dynamic>> facilitiesSummary = {
    'civil': {'name': 'Civil Mall', 'available': 0, 'total': 8, 'rate': 60, 'distance': '0.4 km'},
    'labim': {'name': 'Labim Mall', 'available': 0, 'total': 6, 'rate': 80, 'distance': '1.8 km'},
    'ranipokhari': {'name': 'Rani Pokhari', 'available': 0, 'total': 12, 'rate': 40, 'distance': '0.8 km'},
    'dharahara': {'name': 'Dharahara Tower', 'available': 0, 'total': 10, 'rate': 50, 'distance': '0.5 km'},
  };

  final Map<String, LatLng> locations = const {
    'civil': LatLng(27.700769, 85.315383),
    'labim': LatLng(27.678400, 85.316800),
    'ranipokhari': LatLng(27.708000, 85.314900),
    'dharahara': LatLng(27.700500, 85.312200),
  };

  bool isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchAllFacilities();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchAllFacilities());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pollingTimer?.cancel();
    _expandedMapController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllFacilities() async {
    for (String key in facilitiesSummary.keys) {
      try {
        final response = await http.get(Uri.parse('$baseUrl/$key'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (mounted) {
            setState(() {
              facilitiesSummary[key]!['name'] = data['facilityName'];
              facilitiesSummary[key]!['available'] = data['availableSpots'];
              facilitiesSummary[key]!['total'] = data['totalSpots'];
              facilitiesSummary[key]!['rate'] = data['ratePerHour'];
            });
          }
        }
      } catch (e) {
        debugPrint('Error fetching $key data: $e');
      }
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _bookFirstAvailableSpot(String facilityId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$facilityId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final spots = data['spots'] as List;

        int firstFreeIndex = spots.indexWhere((spot) => spot['isFree'] == true);

        if (firstFreeIndex == -1) {
          _showSnackBar('No available spots at this location!', Colors.redAccent);
          return;
        }

        final bookResponse = await http.post(
          Uri.parse('$baseUrl/$facilityId/book'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'index': firstFreeIndex,
            'durationInMinutes': 60,
            'vehicleNo': activeVehicle,
          }),
        );

        if (bookResponse.statusCode == 200) {
          _showSnackBar('Reserved Spot #$firstFreeIndex successfully!', const Color(0xFF10B981));
          _fetchAllFacilities();
        } else {
          final err = json.decode(bookResponse.body);
          _showSnackBar(err['message'] ?? 'Booking failed', Colors.redAccent);
        }
      }
    } catch (e) {
      _showSnackBar('Network error connecting to Express server.', Colors.redAccent);
    }
  }

  void _showSnackBar(String text, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: bg, duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: IndexedStack(
          index: _currentNavIndex,
          children: [
            _buildDashboardView(), // Index 0: Dashboard
            _buildExpandedMapModule(), // Index 1: Map
            const Center(child: Text('Scan Module Coming Soon')), // Index 2: Scan
            const ProfileScreen(), // Index 3: Profile
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- DASHBOARD VIEW ---
  Widget _buildDashboardView() {
    return RefreshIndicator(
      onRefresh: _fetchAllFacilities,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildSearchEngineCard(),
            const SizedBox(height: 18),
            _buildMapPreviewCard(),
            const SizedBox(height: 22),
            _buildFacilitiesSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _currentNavIndex = 3;
            });
          },
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE6F0FF),
                  border: Border.all(color: const Color(0xFF0066FF), width: 1.5),
                ),
                child: const Icon(Icons.person, color: Color(0xFF0066FF)),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SMARTPARK NEPAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                  Text(
                    'Aarav Sharma',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFCCE0FF)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0066FF).withOpacity(0.06),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Color(0xFF0066FF), size: 16),
              const SizedBox(width: 6),
              Text(
                'Rs. $walletBalance',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF0066FF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchEngineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCCE0FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066FF).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FIND PARKING LOCATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0066FF),
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F0FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  activeVehicle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0066FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search Kathmandu parking spots...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0066FF)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Color(0xFF64748B)),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- EXPANDED MAP MODULE VIEW (FIXED: Uses persistent class-level mapController) ---
  Widget _buildExpandedMapModule() {
    final LatLng initialCenter = locations[selectedFacility] ?? const LatLng(27.700769, 85.315383);

    return Stack(
      children: [
        FlutterMap(
          mapController: _expandedMapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 14.5,
            minZoom: 10.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.smartpark.nepal',
              keepBuffer: 3,
              panBuffer: 1,
              tileDisplay: const TileDisplay.fadeIn(
                duration: Duration(milliseconds: 150),
              ),
            ),
            MarkerLayer(
              markers: locations.entries.map((entry) {
                final isSelected = selectedFacility == entry.key;
                final facData = facilitiesSummary[entry.key];
                final avail = facData?['available'] ?? 0;

                return Marker(
                  point: entry.value,
                  width: isSelected ? 90 : 42,
                  height: isSelected ? 50 : 42,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFacility = entry.key;
                      });
                      _expandedMapController.move(entry.value, 15.0);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0066FF) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0066FF), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  facData?['name'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '$avail Free',
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Icon(
                              Icons.local_parking,
                              color: Color(0xFF0066FF),
                              size: 22,
                            ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.map_rounded, color: Color(0xFF0066FF)),
                    SizedBox(width: 8),
                    Text(
                      'Kathmandu Parking Map',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.my_location, color: Color(0xFF0066FF)),
                  onPressed: () {
                    final target = locations[selectedFacility] ?? const LatLng(27.700769, 85.315383);
                    _expandedMapController.move(target, 15.0);
                  },
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: facilitiesSummary.length,
              itemBuilder: (context, index) {
                final key = facilitiesSummary.keys.elementAt(index);
                final fac = facilitiesSummary[key]!;
                final isSelected = selectedFacility == key;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedFacility = key;
                    });
                    if (locations.containsKey(key)) {
                      _expandedMapController.move(locations[key]!, 15.0);
                    }
                  },
                  child: Container(
                    width: 220,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0066FF) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              fac['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isSelected ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              fac['distance'],
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${fac['available']}/${fac['total']} Spots Free',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isSelected ? const Color(0xFF6EE7B7) : const Color(0xFF10B981),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _bookFirstAvailableSpot(key),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? Colors.white : const Color(0xFF0066FF),
                                foregroundColor: isSelected ? const Color(0xFF0066FF) : Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Book', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFCCE0FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066FF).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'KATHMANDU MAP PREVIEW',
                style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF64748B)),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _currentNavIndex = 1; // Switch to Map Tab
                  });
                },
                child: const Text(
                  'EXPAND MAP →',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF0066FF), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: locations[selectedFacility] ?? const LatLng(27.700769, 85.315383),
                  initialZoom: 14.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.smartpark.nepal',
                  ),
                  MarkerLayer(
                    markers: locations.entries.map((entry) {
                      final isSelected = selectedFacility == entry.key;
                      return Marker(
                        point: entry.value,
                        width: 32,
                        height: 32,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedFacility = entry.key;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF0066FF) : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF0066FF),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.local_parking,
                              color: isSelected ? Colors.white : const Color(0xFF0066FF),
                              size: 18,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesSection() {
    final filteredEntries = facilitiesSummary.entries.where((entry) {
      final name = entry.value['name'].toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PARKING LOCATIONS (LIVE API)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF0066FF)),
              onPressed: _fetchAllFacilities,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (filteredEntries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Text(
                'No parking locations found matching search.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
          ...filteredEntries.map((entry) {
            final id = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _buildFacilityCard(
                id: id,
                name: item['name'],
                available: item['available'],
                total: item['total'],
                rate: 'Rs. ${item['rate']}/hr',
                distance: item['distance'],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildFacilityCard({
    required String id,
    required String name,
    required int available,
    required int total,
    required String rate,
    required String distance,
  }) {
    final bool isSelected = selectedFacility == id;

    return InkWell(
      onTap: () {
        setState(() {
          selectedFacility = id;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0066FF) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0066FF) : const Color(0xFFE6F0FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_parking,
                color: isSelected ? Colors.white : const Color(0xFF0066FF),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    distance,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$available / $total open',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: available > 0 ? const Color(0xFF10B981) : Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rate,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (index) {
        setState(() {
          _currentNavIndex = index;
        });
      },
      selectedItemColor: const Color(0xFF0066FF),
      unselectedItemColor: const Color(0xFF94A3B8),
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_rounded),
          label: 'Map',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner_rounded),
          label: 'Scan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}

// --- PROFILE SCREEN MODULE (WHITE & BLUE THEME) ---
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Colors.white;
    const Color backgroundColor = Color(0xFFF0F4F8);
    const Color primaryBlue = Color(0xFF0066FF);
    const Color textColor = Color(0xFF1E293B);
    const Color subtitleColor = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: const Color(0xFFE6F0FF),
                          child: const Icon(Icons.person, size: 40, color: primaryBlue),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aarav Sharma',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'aarav.sharma@example.com',
                          style: TextStyle(
                            fontSize: 13,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F0FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFCCE0FF)),
                          ),
                          child: const Text(
                            'Verified Driver',
                            style: TextStyle(
                              color: primaryBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // DIGITAL WALLET CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0066FF), Color(0xFF0044B3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SmartPark Wallet',
                            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          Icon(Icons.account_balance_wallet_rounded, color: Colors.white.withOpacity(0.9)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Rs. 1,240.00',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.add_circle_outline, size: 18),
                              label: const Text('Top Up', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: primaryBlue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.history, size: 18, color: Colors.white),
                              label: const Text('Transactions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withOpacity(0.6)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // MY GARAGE
                const Text(
                  'My Garage',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFCCE0FF)),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F0FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.two_wheeler_rounded, color: primaryBlue, size: 26),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Vehicle',
                              style: TextStyle(color: subtitleColor, fontSize: 11),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'BA 2 PA',
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.edit_rounded, color: primaryBlue, size: 20),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFCCE0FF)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: primaryBlue, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Add New Vehicle',
                          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // MENU ITEMS
                const Text(
                  'Account Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFCCE0FF)),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.history_rounded,
                        title: 'Parking History',
                        trailingText: '12 bookings',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.card_membership_rounded,
                        title: 'Subscriptions & Passes',
                        trailingText: '1 Active',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.security_rounded,
                        title: 'Privacy & Security',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // LOGOUT
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF0066FF), size: 22),
      title: Text(
        title,
        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 14),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      color: Color(0xFFE2E8F0),
      indent: 16,
      endIndent: 16,
    );
  }
}
