import 'package:flutter/material.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedMethod = 'eSewa'; // Default gateway

  final List<int> _quickAmounts = [100, 200, 500, 1000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFF060A16);
    const Color cardColor = Color(0xFF1E1E1E);
    const Color accentColor = Color(0xFF00E5FF);

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
          'Top Up Wallet',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- CURRENT BALANCE DISPLAY ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current SmartPark Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Rs. 1,240.00',
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // --- AMOUNT INPUT FIELD ---
                const Text(
                  'Enter Top Up Amount (Rs.)',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: cardColor,
                    hintText: 'Minimum Rs. 10',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.normal),
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.grey, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: accentColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- QUICK CHIP SELECTION ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _quickAmounts.map((amount) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _amountController.text = amount.toString();
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.04)),
                        ),
                        child: Text(
                          '+$amount',
                          style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // --- PAYMENT GATEWAYS ---
                const Text(
                  'Select Payment Source',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 12),
                _buildPaymentMethodRow('eSewa Wallet', 'Instant digital checkout', cardColor, accentColor),
                const SizedBox(height: 12),
                _buildPaymentMethodRow('Khalti Wallet', 'Pay using Khalti balance', cardColor, accentColor),
                const SizedBox(height: 12),
                _buildPaymentMethodRow('Mobile Banking', 'Connect local Nepali banks', cardColor, accentColor),
                const SizedBox(height: 40),

                // --- SUBMIT ACTION ---
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        final enteredAmount = _amountController.text.trim();
                        if (enteredAmount.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please specify a load amount.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Loading Rs. $enteredAmount via $_selectedMethod...'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Proceed to Pay',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER COMPONENT: PAYMENT OPTION SELECTOR ---
  Widget _buildPaymentMethodRow(String title, String subtitle, Color cardColor, Color accentColor) {
    final bool isSelected = _selectedMethod == title;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = title;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white.withOpacity(0.04),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor.withOpacity(0.1) : Colors.white.withOpacity(0.02),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_rounded,
                    color: isSelected ? accentColor : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            Radio<String>(
              value: title,
              groupValue: _selectedMethod,
              activeColor: accentColor,
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _selectedMethod = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}