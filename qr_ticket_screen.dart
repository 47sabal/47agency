import 'package:flutter/material.dart';

class QRTicketScreen extends StatelessWidget {
  const QRTicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color(0xFF1E1E1E);
    const Color backgroundColor = Color(0xFF060A16);
    const Color accentColor = Color(0xFF00E5FF); 

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Active Ticket',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
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
                                color: accentColor, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 13, 
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hold the QR code near the scanner window.',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                            const SizedBox(height: 24),
                            
                            // Standalone Built-in QR Art Generator (No external package dependencies!)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: SizedBox(
                                width: 180,
                                height: 180,
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
                            const SizedBox(height: 20),
                            Text(
                              ticketData['bookingId'] ?? '',
                              style: const TextStyle(
                                color: Colors.white70, 
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
                            const Divider(height: 30, color: Colors.white10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Paid Amount',
                                  style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  ticketData['price'] ?? '',
                                  style: const TextStyle(
                                    color: accentColor, 
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
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[850]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Close Ticket',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
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
            color: Color(0xFF060A16), 
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
                  (index) => SizedBox(
                    width: 5,
                    height: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1), // Fixed spelling of withOpacity
                      ),
                    ),
                  ),
                ), // Fixed: Semicolon replaced with proper closing parenthesis
              );
            },
          ),
        ),
        Container(
          height: 20,
          width: 10,
          decoration: const BoxDecoration(
            color: Color(0xFF060A16), 
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
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
        ),
        padding: const EdgeInsets.all(6),
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
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
        ),
        padding: const EdgeInsets.all(4),
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
      width: 48,
      height: 48,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          4,
          (y) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              4,
              (x) => Container(
                width: 8,
                height: 8,
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
      width: 180,
      height: 48,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          4,
          (y) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              16,
              (x) => Container(
                width: 8,
                height: 8,
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