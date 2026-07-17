import 'package:flutter/material.dart';

class ParkingHistoryScreen extends StatelessWidget {
  const ParkingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFF060A16);
    const Color accentColor = Color(0xFF00E5FF);

    final List<Map<String, String>> activeBookings = [
      {
        "id": "SPK-9081-XYZ",
        "location": "Thamel Parking Hub, Space A3",
        "vehicle": "Yamaha FZS V3 (BA 3 PA 9081)",
        "date": "Today, 17 July 2026",
        "time": "06:00 PM - 08:00 PM",
        "price": "Rs. 100.00",
        "status": "Active Now"
      }
    ];

    final List<Map<String, String>> pastBookings = [
      {
        "id": "SPK-8421-ABC",
        "location": "Durbar Marg Station, Space B2",
        "vehicle": "Yamaha FZS V3 (BA 3 PA 9081)",
        "date": "14 July 2026",
        "time": "02:00 PM - 03:30 PM",
        "price": "Rs. 75.00",
        "status": "Completed"
      },
      {
        "id": "SPK-7110-LMN",
        "location": "New Road Parking, Space C1",
        "vehicle": "Yamaha FZS V3 (BA 3 PA 9081)",
        "date": "08 July 2026",
        "time": "11:00 AM - 01:00 PM",
        "price": "Rs. 100.00",
        "status": "Completed"
      },
      {
        "id": "SPK-6544-QRS",
        "location": "Thamel Parking Hub, Space A5",
        "vehicle": "Yamaha FZS V3 (BA 3 PA 9081)",
        "date": "01 July 2026",
        "time": "04:00 PM - 07:00 PM",
        "price": "Rs. 150.00",
        "status": "Completed"
      }
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Parking History',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: accentColor,
            labelColor: accentColor,
            unselectedLabelColor: Colors.grey,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: 'Active Options'),
              Tab(text: 'Past Sessions'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            physics: const BouncingScrollPhysics(),
            children: [
              _buildHistoryList(activeBookings, isActiveList: true),
              _buildHistoryList(pastBookings, isActiveList: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<Map<String, String>> bookings, {required bool isActiveList}) {
    if (bookings.isEmpty) {
      return const Center(
        child: Text(
          'No parking records found.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        const Color cardColor = Color(0xFF1E1E1E);
        const Color accentColor = Color(0xFF00E5FF);

        return Container(
          margin: const EdgeInsets.bottom(16.0),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.04), // Fixed spelling here!
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      booking['id'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActiveList 
                            ? Colors.greenAccent.withOpacity(0.15) 
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        booking['status'] ?? '',
                        style: TextStyle(
                          color: isActiveList ? Colors.greenAccent : Colors.grey[400],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Colors.white10),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, color: accentColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        booking['location'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(Icons.motorcycle, color: Colors.grey[400], size: 18),
                    const SizedBox(width: 14),
                    Text(
                      booking['vehicle'] ?? '',
                      style: TextStyle(color: Colors.grey[300], fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: Colors.grey[400], size: 18),
                    const SizedBox(width: 14),
                    Text(
                      "${booking['date']} | ${booking['time']}",
                      style: TextStyle(color: Colors.grey[300], fontSize: 13),
                    ),
                  ],
                ),
                const Divider(height: 28, color: Colors.white10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isActiveList ? 'Estimated Cost' : 'Amount Paid',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    Text(
                      booking['price'] ?? '',
                      style: const TextStyle(
                        color: accentColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}