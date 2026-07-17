import 'package:flutter/material.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Mock Data - Your backend friend will replace these with API calls
  final List<String> _parkingSlots = ['A1', 'A2', 'A3', 'A4', 'B1', 'B2', 'B3', 'B4', 'C1', 'C2', 'C3', 'C4'];
  final List<String> _occupiedSlots = ['A2', 'B1', 'C3']; // Hardcoded taken slots
  
  String? _selectedSlot;
  int _bookingDurationHours = 1;
  const int _ratePerHour = 50; // Rate in Rs.

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color(0xFF1E1E1E);
    const Color backgroundColor = Color(0xFF060A16);
    const Color accentColor = Color(0xFF00E5FF); // Cyber cyan

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Book a Slot',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                // --- SECTION 1: VEHICLE PREVIEW ---
                const Text(
                  'Selected Vehicle',
                  style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.motorcycle, color: accentColor, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Yamaha FZS V3 (BA 3 PA 9081)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      TextButton(
                        onPressed: () {}, // Trigger vehicle selection
                        child: const Text('Change', style: TextStyle(color: accentColor, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // --- SECTION 2: SLOT SELECTOR GRID ---
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Parking Slot',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        _LegendItem(color: Colors.grey, label: 'Taken'),
                        SizedBox(width: 12),
                        _LegendItem(color: accentColor, label: 'Selected'),
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
                    Color textColor = Colors.white;
                    BorderSide border = BorderSide(color: Colors.white.withOpacity(0.05));

                    if (isOccupied) {
                      tileColor = Colors.grey[900]!;
                      textColor = Colors.grey[700]!;
                    } else if (isSelected) {
                      tileColor = accentColor.withOpacity(0.15);
                      textColor = accentColor;
                      border = const BorderSide(color: accentColor, width: 1.5);
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
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),

                // --- SECTION 3: DURATION SELECTOR ---
                const Text(
                  'Booking Duration',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Hours',
                        style: TextStyle(color: Colors.white, fontSize: 14),
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
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

                // --- SECTION 4: BILLING & PAYMENT SUMMARY ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131A2E), // Subtle blue tint
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.15)),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Rate', 'Rs. $_ratePerHour / hr'),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Duration', '$_bookingDurationHours Hours'),
                      const Divider(height: 20, color: Colors.white10),
                      _buildSummaryRow(
                        'Total Amount', 
                        'Rs. ${_bookingDurationHours * _ratePerHour}', 
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // --- SECTION 5: CONFIRM BUTTON ---
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _selectedSlot == null
                        ? null // Disables button if no slot is selected
                        : () {
                            // Booking Confirmation Logic
                            _showBookingSuccessDialog(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey[800],
                      disabledForegroundColor: Colors.grey[500],
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

  // --- HELPER COMPONENT: ROUND BUTTON ---
  Widget _buildRoundButton({required IconData icon, required VoidCallback? onPressed}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onPressed,
      ),
    );
  }

  // --- HELPER COMPONENT: BILLING ROW ---
  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.white : Colors.grey[400],
            fontSize: isTotal ? 16 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? const Color(0xFF00E5FF) : Colors.white,
            fontSize: isTotal ? 20 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // --- SUCCESS MODAL TRIGGER ---
  void _showBookingSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF39FFC1), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Slot Reserved!',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your parking slot $_selectedSlot has been successfully locked for $_bookingDurationHours hours.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close modal
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
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

// --- HELPER COMPONENT: LEGEND ---
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
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}