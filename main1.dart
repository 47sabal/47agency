import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'login.dart';


void main() async{
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

  final MapController _expandedMapController = MapController();

  int _currentNavIndex = 0;
  String selectedFacility = 'civil';
  int walletBalance = 1240;
  String activeVehicle = 'BA 2 PA';

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Map<String, Map<String, dynamic>> facilitiesSummary = {
    'civil': {'name': 'Civil Mall', 'available': 0, 'total': 8, 'rate': 60, 'distance': '0.4 km'},
    'labim': {'name': 'Labim Mall', 'available': 0, 'total': 6, 'rate': 80, 'distance': '1.8 km'},
    'ranipokhari': {'name': 'Rani Pokhari', 'available': 0, 'total': 12, 'rate': 40, 'distance': '0.8 km'},
    'dharahara': {'name': 'Dharahara Tower Plaza Parking', 'available': 0, 'total': 10, 'rate': 50, 'distance': '0.5 km'},
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

  void _navigateToBooking(String facilityId) {
    final facility = facilitiesSummary[facilityId];
    final facilityName = facility?['name'] ?? 'Parking Facility';
    final ratePerHour = facility?['rate'] ?? 50;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          facilityId: facilityId,
          facilityName: facilityName,
          ratePerHour: ratePerHour,
          activeVehicle: activeVehicle,
          onBookingSuccess: _fetchAllFacilities,
        ),
      ),
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
            _buildDashboardView(),
            _buildExpandedMapModule(),
            const QRTicketScreen(),
            const ProfileScreen(),
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
                color: const Color(0xFF0066FF).withValues(alpha: 0.06),
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
            color: const Color(0xFF0066FF).withValues(alpha: 0.06),
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

  // --- EXPANDED MAP MODULE VIEW ---
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
                  width: isSelected ? 110 : 42,
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
                            color: Colors.black.withValues(alpha: 0.15),
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
          right: 16,
          child: FloatingActionButton.small(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0066FF),
            elevation: 4,
            onPressed: () {
              final target = locations[selectedFacility] ?? const LatLng(27.700769, 85.315383);
              _expandedMapController.move(target, 15.0);
            },
            child: const Icon(Icons.my_location),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 115,
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
                    width: 250,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0066FF) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
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
                          children: [
                            Expanded(
                              child: Text(
                                fac['name'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              fac['distance'],
                              style: TextStyle(
                                fontSize: 11,
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
                              onPressed: () => _navigateToBooking(key),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? Colors.white : const Color(0xFF0066FF),
                                foregroundColor: isSelected ? const Color(0xFF0066FF) : Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
            color: const Color(0xFF0066FF).withValues(alpha: 0.06),
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
                    _currentNavIndex = 1;
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
                const SizedBox(height: 6),
                ElevatedButton(
                  onPressed: () => _navigateToBooking(id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
          label: 'Ticket',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}

// --- BOOKING SCREEN MODULE ---
class BookingScreen extends StatefulWidget {
  final String facilityId;
  final String facilityName;
  final int ratePerHour;
  final String activeVehicle;
  final VoidCallback? onBookingSuccess;

  const BookingScreen({
    super.key,
    required this.facilityId,
    required this.facilityName,
    required this.ratePerHour,
    required this.activeVehicle,
    this.onBookingSuccess,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final List<String> _parkingSlots = ['A1', 'A2', 'A3', 'A4', 'B1', 'B2', 'B3', 'B4', 'C1', 'C2', 'C3', 'C4'];
  final List<String> _occupiedSlots = ['A2', 'B1', 'C3'];

  String? _selectedSlot;
  int _bookingDurationHours = 1;

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Colors.white;
    const Color backgroundColor = Color(0xFFF0F4F8);
    const Color primaryBlue = Color(0xFF0066FF);
    const Color textColor = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Book at ${widget.facilityName}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Vehicle',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFCCE0FF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.two_wheeler, color: primaryBlue, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bike (${widget.activeVehicle})',
                          style: const TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Change', style: TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Parking Slot',
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        _LegendItem(color: Color(0xFFCBD5E1), label: 'Taken'),
                        SizedBox(width: 12),
                        _LegendItem(color: primaryBlue, label: 'Selected'),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: _parkingSlots.length,
                  itemBuilder: (context, index) {
                    final slot = _parkingSlots[index];
                    final isOccupied = _occupiedSlots.contains(slot);
                    final isSelected = _selectedSlot == slot;

                    Color tileColor = cardColor;
                    Color slotTextColor = textColor;
                    BorderSide border = const BorderSide(color: Color(0xFFE2E8F0));

                    if (isOccupied) {
                      tileColor = const Color(0xFFE2E8F0);
                      slotTextColor = const Color(0xFF94A3B8);
                    } else if (isSelected) {
                      tileColor = const Color(0xFFE6F0FF);
                      slotTextColor = primaryBlue;
                      border = const BorderSide(color: primaryBlue, width: 2);
                    }

                    return InkWell(
                      onTap: isOccupied
                          ? null
                          : () {
                              setState(() {
                                _selectedSlot = slot;
                              });
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: tileColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.fromBorderSide(border),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          slot,
                          style: TextStyle(
                            color: slotTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                const Text(
                  'Booking Duration',
                  style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFCCE0FF)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Hours',
                        style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      Row(
                        children: [
                          _buildRoundButton(
                            icon: Icons.remove,
                            onPressed: _bookingDurationHours > 1
                                ? () => setState(() => _bookingDurationHours--)
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              '$_bookingDurationHours hr',
                              style: const TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          _buildRoundButton(
                            icon: Icons.add,
                            onPressed: () => setState(() => _bookingDurationHours++),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F0FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFCCE0FF)),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Rate', 'Rs. ${widget.ratePerHour} / hr'),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Duration', '$_bookingDurationHours Hours'),
                      const Divider(height: 20, color: Color(0xFFCBD5E1)),
                      _buildSummaryRow(
                        'Total Amount',
                        'Rs. ${_bookingDurationHours * widget.ratePerHour}',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _selectedSlot == null
                        ? null
                        : () {
                            _showBookingSuccessDialog(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                      disabledForegroundColor: const Color(0xFF64748B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _selectedSlot == null ? 'Select a Slot to Continue' : 'Confirm & Reserve Slot',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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

  Widget _buildRoundButton({required IconData icon, required VoidCallback? onPressed}) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFFF0F4F8),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: const Color(0xFF0066FF), size: 18),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? const Color(0xFF1E293B) : const Color(0xFF64748B),
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF0066FF),
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showBookingSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Slot Reserved!',
              style: TextStyle(color: Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your parking slot $_selectedSlot at ${widget.facilityName} has been successfully locked for $_bookingDurationHours hours.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onBookingSuccess?.call();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Great!', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
      ],
    );
  }
}

// --- QR TICKET SCREEN MODULE ---
class QRTicketScreen extends StatelessWidget {
  const QRTicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Colors.white;
    const Color backgroundColor = Color(0xFFF0F4F8);
    const Color primaryBlue = Color(0xFF0066FF);

    final Map<String, dynamic> ticketData = {
      "bookingId": "SPK-9081-XYZ",
      "gatePassCode": "GATE-PASS-2026-ACTIVE",
      "location": "Thamel Parking Hub, Space A3",
      "vehicleNo": "BA 3 PA 9081",
      "duration": "2 Hours",
      "price": "Rs. 100.00",
      "paymentStatus": "Paid via Wallet",
    };

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E293B), size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'My Active Ticket',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFCCE0FF)),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Text(
                              'SCAN AT ENTRY GATE',
                              style: TextStyle(
                                color: primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Hold the QR code near the scanner window.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: primaryBlue,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryBlue.withValues(alpha: 0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SizedBox(
                                  width: 170,
                                  height: 170,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildQREye(),
                                          _buildQRNoiseRow(),
                                          _buildQREye(),
                                        ],
                                      ),
                                      _buildQRNoiseMiddlePattern(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildQREye(),
                                          _buildQRNoiseRow(invert: true),
                                          _buildQRMiniEye(),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              ticketData['bookingId'] ?? '',
                              style: const TextStyle(
                                color: primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildTicketDivider(),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            _buildTicketDetailRow('Parking Hub', ticketData['location'] ?? ''),
                            const SizedBox(height: 12),
                            _buildTicketDetailRow('Vehicle No.', ticketData['vehicleNo'] ?? ''),
                            const SizedBox(height: 12),
                            _buildTicketDetailRow('Duration', ticketData['duration'] ?? ''),
                            const SizedBox(height: 12),
                            _buildTicketDetailRow('Payment Details', ticketData['paymentStatus'] ?? ''),
                            const Divider(height: 30, color: Color(0xFFE2E8F0)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Paid Amount',
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  ticketData['price'] ?? '',
                                  style: const TextStyle(
                                    color: primaryBlue,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCCE0FF)),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Close Ticket',
                      style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 14),
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

  Widget _buildTicketDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketDivider() {
    return Row(
      children: [
        Container(
          height: 20,
          width: 10,
          decoration: const BoxDecoration(
            color: Color(0xFFF0F4F8),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Flex(
                direction: Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  (constraints.constrainWidth() / 10).floor(),
                  (index) => const SizedBox(
                    width: 5,
                    height: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          height: 20,
          width: 10,
          decoration: const BoxDecoration(
            color: Color(0xFFF0F4F8),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQREye() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
        ),
        padding: const EdgeInsets.all(5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildQRMiniEye() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  Widget _buildQRNoiseRow({bool invert = false}) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          4,
          (y) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              4,
              (x) => Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: ((x + y) % (invert ? 3 : 2) == 0) ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQRNoiseMiddlePattern() {
    return SizedBox(
      width: 170,
      height: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          4,
          (y) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              16,
              (x) => Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: ((x * 3 + y * 2) % 5 < 3) ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- PROFILE SCREEN MODULE ---
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Colors.white;
    const Color backgroundColor = Color(0xFFF0F4F8);
    const Color primaryBlue = Color(0xFF0066FF);
    const Color textColor = Color(0xFF1E293B);
    const Color subtitleColor = Color(0xFF64748B);

    // Function to show contact info
    void showSupportDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Help & Support'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: support.smartpark@gmail.com'),
              SizedBox(height: 10),
              Text('Phone: +9779762111254'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

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
        const CircleAvatar(
          radius: 38,
          backgroundColor: Color(0xFFE6F0FF),
          child: Icon(Icons.person, size: 40, color: Color(0xFF0066FF)),
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
            child: const Icon(Icons.check, size: 14, color: Colors.white),
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
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'aarav.sharma@example.com',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
              color: Color(0xFF0066FF),
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

                // HELP & SUPPORT (Standalone Item)
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFCCE0FF)),
                  ),
                  child: _buildMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () => showSupportDialog(),
                  ),
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
        color: const Color(0xFF0066FF).withValues(alpha: 0.25),
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
          Icon(Icons.account_balance_wallet_rounded, color: Colors.white.withValues(alpha: 0.9)),
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
        ],
      )
    ],
  ),
),

// MY GARAGE
const Text(
  'My Garage',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
),
const SizedBox(height: 10),
Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFCCE0FF)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0066FF).withValues(alpha: 0.04),
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
        child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF0066FF), size: 26),
      ),
      const SizedBox(width: 14),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Vehicle', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
            SizedBox(height: 2),
            Text('BA 2 PA', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
      IconButton(
        onPressed: () {},
        icon: const Icon(Icons.edit_rounded, color: Color(0xFF0066FF), size: 20),
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
        Icon(Icons.add_rounded, color: Color(0xFF0066FF), size: 20),
        SizedBox(width: 6),
        Text(
          'Add New Vehicle',
          style: TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    ),
  ),
),
                
                // ACCOUNT SETTINGS HEADER
const Text(
  'Account Settings',
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1E293B), // textColor
  ),
),
const SizedBox(height: 10),

// SETTINGS LIST CONTAINER
Container(
  decoration: BoxDecoration(
    color: Colors.white, // cardColor
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFCCE0FF)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0066FF).withValues(alpha: 0.04), // primaryBlue
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ParkingHistoryScreen(),
            ),
          );
        },
      ),
      _buildDivider(),
      _buildMenuItem(
        icon: Icons.card_membership_rounded,
        title: 'Subscriptions & Passes',
        trailingText: '1 Active',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SubscriptionsPassesScreen(),
            ),
          );
        },
      ),
      _buildDivider(),
      _buildMenuItem(
        icon: Icons.notifications_none_rounded,
        title: 'Notifications',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationSettingsScreen(),
            ),
          );
        },
      ),
      _buildDivider(),
      _buildMenuItem(
        icon: Icons.security_rounded,
        title: 'Privacy & Security',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PrivacySecurityScreen(),
            ),
          );
        },
      ),
      _buildDivider(),
      _buildMenuItem(
        icon: Icons.help_outline_rounded,
        title: 'Help & Support',
        onTap: () {}, // This is where you would place your contact logic
      ),
    ],
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

  // HELPER: BUILD MENU ITEM
Widget _buildMenuItem({
  required IconData icon,
  required String title,
  String? trailingText,
  required VoidCallback onTap,
}) {
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F0FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: const Color(0xFF0066FF), size: 20),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E293B),
      ),
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (trailingText != null)
          Text(
            trailingText,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
      ],
    ),
    onTap: onTap,
  );
}

// HELPER: BUILD DIVIDER
Widget _buildDivider() {
  return const Divider(
    height: 1,
    thickness: 1,
    color: Color(0xFFF1F5F9), // Very light grey, subtle
    indent: 68, // Aligns with the title text
    endIndent: 20,
  );
}
}
// --- PARKING HISTORY SCREEN MODULE ---
class ParkingHistoryScreen extends StatefulWidget {
  const ParkingHistoryScreen({super.key});

  @override
  State<ParkingHistoryScreen> createState() => _ParkingHistoryScreenState();
}

class _ParkingHistoryScreenState extends State<ParkingHistoryScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All', 'Completed', 'Active', 'Cancelled'];

  final List<Map<String, dynamic>> _historyData = [
    {
      "id": "SPK-9081-XYZ",
      "facility": "Civil Mall",
      "slot": "A3",
      "vehicle": "BA 2 PA",
      "date": "Jul 17, 2026",
      "time": "02:30 PM - 04:30 PM",
      "duration": "2 Hours",
      "amount": "Rs. 120",
      "status": "Active",
    },
    {
      "id": "SPK-8812-ABC",
      "facility": "Labim Mall",
      "slot": "B1",
      "vehicle": "BA 2 PA",
      "date": "Jul 15, 2026",
      "time": "11:00 AM - 01:00 PM",
      "duration": "2 Hours",
      "amount": "Rs. 160",
      "status": "Completed",
    },
    {
      "id": "SPK-7721-LMN",
      "facility": "Rani Pokhari",
      "slot": "C4",
      "vehicle": "BA 3 PA 9081",
      "date": "Jul 10, 2026",
      "time": "09:00 AM - 10:00 AM",
      "duration": "1 Hour",
      "amount": "Rs. 40",
      "status": "Completed",
    },
    {
      "id": "SPK-6543-OPQ",
      "facility": "Dharahara Tower Plaza",
      "slot": "A1",
      "vehicle": "BA 2 PA",
      "date": "Jul 05, 2026",
      "time": "05:00 PM - 07:00 PM",
      "duration": "2 Hours",
      "amount": "Rs. 100",
      "status": "Cancelled",
    },
    {
      "id": "SPK-5432-RST",
      "facility": "Civil Mall",
      "slot": "B3",
      "vehicle": "BA 2 PA",
      "date": "Jun 28, 2026",
      "time": "01:00 PM - 04:00 PM",
      "duration": "3 Hours",
      "amount": "Rs. 180",
      "status": "Completed",
    },
  ];

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0066FF);
    const Color textColor = Color(0xFF1E293B);

    final filteredList = _historyData.where((item) {
      if (_selectedFilterIndex == 0) return true;
      return item['status'] == _filters[_selectedFilterIndex];
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Parking History',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // FILTER CHIPS
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedFilterIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(_filters[index]),
                      selected: isSelected,
                      selectedColor: primaryBlue,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? primaryBlue : const Color(0xFFCCE0FF),
                        ),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedFilterIndex = index;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // HISTORY LIST
            Expanded(
              child: filteredList.isEmpty
                  ? const Center(
                      child: Text(
                        'No parking records found.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        return _buildHistoryCard(item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    const Color primaryBlue = Color(0xFF0066FF);
    const Color textColor = Color(0xFF1E293B);
    const Color subtitleColor = Color(0xFF64748B);

    Color statusColor;
    Color statusBg;

    switch (item['status']) {
      case 'Active':
        statusColor = primaryBlue;
        statusBg = const Color(0xFFE6F0FF);
        break;
      case 'Completed':
        statusColor = const Color(0xFF10B981);
        statusBg = const Color(0xFFD1FAE5);
        break;
      case 'Cancelled':
      default:
        statusColor = Colors.redAccent;
        statusBg = const Color(0xFFFEE2E2);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCCE0FF)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['facility'] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['status'] ?? '',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${item['date']} • ${item['time']}',
            style: const TextStyle(fontSize: 12, color: subtitleColor),
          ),
          const Divider(height: 20, color: Color(0xFFE2E8F0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_parking_rounded, size: 16, color: primaryBlue),
                  const SizedBox(width: 4),
                  Text(
                    'Slot ${item['slot']}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.two_wheeler_rounded, size: 16, color: primaryBlue),
                  const SizedBox(width: 4),
                  Text(
                    item['vehicle'] ?? '',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                  ),
                ],
              ),
              Text(
                item['amount'] ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- NOTIFICATION SETTINGS SCREEN MODULE ---
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _slotAvailabilityAlerts = true;
  bool _bookingReminders = true;
  bool _emailReceipts = true;
  bool _promotionsAndOffers = false;
  bool _soundAndVibration = true;

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0066FF);
    const Color textColor = Color(0xFF1E293B);
    const Color subtitleColor = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Push Alerts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Control what real-time updates you receive on your phone.',
                style: TextStyle(fontSize: 12, color: subtitleColor),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFCCE0FF)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: primaryBlue,
                      secondary: const Icon(Icons.notifications_active_outlined, color: primaryBlue),
                      title: const Text('Slot Availability Alerts', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Get notified when spaces open up at saved locations', style: TextStyle(color: subtitleColor, fontSize: 12)),
                      value: _slotAvailabilityAlerts,
                      onChanged: (val) => setState(() => _slotAvailabilityAlerts = val),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE2E8F0)),
                    SwitchListTile(
                      activeThumbColor: primaryBlue,
                      secondary: const Icon(Icons.timer_outlined, color: primaryBlue),
                      title: const Text('Booking Expiry Reminders', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Alert 15 mins before your parking time runs out', style: TextStyle(color: subtitleColor, fontSize: 12)),
                      value: _bookingReminders,
                      onChanged: (val) => setState(() => _bookingReminders = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Email & Messages',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFCCE0FF)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: primaryBlue,
                      secondary: const Icon(Icons.receipt_long_outlined, color: primaryBlue),
                      title: const Text('Email Booking Receipts', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Automatically send invoices & payment proofs', style: TextStyle(color: subtitleColor, fontSize: 12)),
                      value: _emailReceipts,
                      onChanged: (val) => setState(() => _emailReceipts = val),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE2E8F0)),
                    SwitchListTile(
                      activeThumbColor: primaryBlue,
                      secondary: const Icon(Icons.local_offer_outlined, color: primaryBlue),
                      title: const Text('Promotions & Special Deals', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Discounts on monthly passes and wallet cashbacks', style: TextStyle(color: subtitleColor, fontSize: 12)),
                      value: _promotionsAndOffers,
                      onChanged: (val) => setState(() => _promotionsAndOffers = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Sound & Behavior',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFCCE0FF)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SwitchListTile(
                  activeThumbColor: primaryBlue,
                  secondary: const Icon(Icons.volume_up_outlined, color: primaryBlue),
                  title: const Text('In-App Sound & Vibration', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Play subtle sound when reserving or scanning QR passes', style: TextStyle(color: subtitleColor, fontSize: 12)),
                  value: _soundAndVibration,
                  onChanged: (val) => setState(() => _soundAndVibration = val),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SUBSCRIPTIONS & PASSES SCREEN MODULE ---
class SubscriptionsPassesScreen extends StatelessWidget {
  const SubscriptionsPassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0066FF);
    const Color textColor = Color(0xFF1E293B);
    const Color subtitleColor = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Subscriptions & Passes',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Active Subscriptions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0066FF), Color(0xFF0242A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(Icons.stars_rounded, color: Colors.amber, size: 26),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Monthly Commuter Pass',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Unlimited Entry: Civil Mall & Rani Pokhari',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Expires on', style: TextStyle(color: Colors.white60, fontSize: 11)),
                            SizedBox(height: 2),
                            Text('June 30, 2026', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const QRTicketScreen()),
                            );
                          },
                          icon: const Icon(Icons.qr_code_rounded, size: 16),
                          label: const Text('Show Pass QR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primaryBlue,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Available Pass Plans',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 4),
              const Text(
                'Save up to 40% on daily parking rates with unlimited passes.',
                style: TextStyle(fontSize: 12, color: subtitleColor),
              ),
              const SizedBox(height: 14),

              _buildPlanCard(
                context,
                title: 'Weekly All-Access Pass',
                price: 'Rs. 999',
                duration: '/ 7 days',
                description: 'Ideal for short business trips. Full access to all registered SmartPark hubs.',
                isPopular: false,
              ),
              const SizedBox(height: 12),
              _buildPlanCard(
                context,
                title: 'Monthly Premium VIP Pass',
                price: 'Rs. 3,200',
                duration: '/ 30 days',
                description: 'Priority slot reservation + unlimited parking at Civil Mall, Labim Mall & Dharahara.',
                isPopular: true,
              ),
              const SizedBox(height: 12),
              _buildPlanCard(
                context,
                title: 'Quarterly Corporate Pass',
                price: 'Rs. 8,500',
                duration: '/ 90 days',
                description: 'Designed for daily commuters. Multiple vehicle link support + dedicated support line.',
                isPopular: false,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required String duration,
    required String description,
    required bool isPopular,
  }) {
    const Color primaryBlue = Color(0xFF0066FF);
    const Color textColor = Color(0xFF1E293B);
    const Color subtitleColor = Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular ? primaryBlue : const Color(0xFFCCE0FF),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'MOST POPULAR',
                  style: TextStyle(color: primaryBlue, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue),
                  ),
                  Text(
                    duration,
                    style: const TextStyle(fontSize: 11, color: subtitleColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: subtitleColor, height: 1.3),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Purchased $title successfully!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular ? primaryBlue : const Color(0xFFE6F0FF),
                foregroundColor: isPopular ? Colors.white : primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Subscribe Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// --- PRIVACY & SECURITY SCREEN MODULE ---
class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleChangePassword() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0066FF);
    const Color textColor = Color(0xFF1E293B);
    const Color subtitleColor = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy & Security',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFCCE0FF)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, color: primaryBlue, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Your Privacy Matters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'We take data protection seriously. Your personal information, activity history, and authentication details are encrypted and secure.',
                      style: TextStyle(
                        height: 1.4,
                        fontSize: 13,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Update your password regularly to keep your account safe.',
                style: TextStyle(
                  fontSize: 12,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFCCE0FF)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrent,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          labelStyle: const TextStyle(color: subtitleColor, fontSize: 13),
                          prefixIcon: const Icon(Icons.lock_outline, color: primaryBlue, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: subtitleColor,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                            borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your current password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNew,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          labelStyle: const TextStyle(color: subtitleColor, fontSize: 13),
                          prefixIcon: const Icon(Icons.lock_reset_outlined, color: primaryBlue, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: subtitleColor,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                            borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters long';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          labelStyle: const TextStyle(color: subtitleColor, fontSize: 13),
                          prefixIcon: const Icon(Icons.lock_reset_outlined, color: primaryBlue, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: subtitleColor,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                            borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your new password';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleChangePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Update Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ExpansionTile(
            title: Text('How do I book a parking slot?'),
            children: [Padding(padding: EdgeInsets.all(16), child: Text('Select a location on the map, choose your duration, and click confirm.'))],
          ),
          const ExpansionTile(
            title: Text('How to cancel a booking?'),
            children: [Padding(padding: EdgeInsets.all(16), child: Text('Navigate to your History tab and click on the active booking to cancel.'))],
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('Contact Us', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.phone, color: Colors.blue),
            title: const Text('Call Support'),
            subtitle: const Text('+977-9800000000'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.email, color: Colors.blue),
            title: const Text('Email Us'),
            subtitle: const Text('support@smartpark.np'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
