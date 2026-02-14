import 'package:flutter/material.dart';
import 'package:fridge_app/routes.dart';

class RecentScanResultsScreen extends StatelessWidget {
  const RecentScanResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text(
          'Scan Results',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: const Color(
          0xFFAFB2AF,
        ).withOpacity(0.1), // Approximate color based on HTML backdrop
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Retake',
              style: TextStyle(
                color: Color(0xFF13EC13),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              const Text(
                'Verify items before adding to your inventory.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              // Receipt Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Store Info
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF13EC13).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.storefront,
                              color: Color(0xFF13EC13),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Whole Foods Market',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'OCT 24, 2023 • 10:43 AM',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFEEEEEE),
                    ), // Dashed preferred but Divider is ok
                    // Items
                    _buildItemRow('Whole Milk (1 Gal)', '1', '\$4.50'),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFFAFAFA),
                    ),
                    _buildItemRow(
                      'Organic Baby Spinach',
                      '2',
                      '\$7.98',
                      hasControls: true,
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFFAFAFA),
                    ),
                    _buildItemRow('Large Brown Eggs (12ct)', '1', '\$5.29'),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFFAFAFA),
                    ),
                    _buildUnknownItemRow(),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Missing Item'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: BorderSide(
                            color: Colors.grey[300]!,
                            style: BorderStyle.solid,
                          ),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    // Summary
                    Container(
                      color: const Color(0xFFFAFAFA),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildSummaryRow('Subtotal', '\$17.77'),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Tax (est)', '\$1.42'),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$19.19',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF13EC13),
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
              // Zig Zag
              CustomPaint(
                painter: ZigZagPainter(),
                size: const Size(double.infinity, 12),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.white, Colors.white.withOpacity(0)],
                  stops: const [0.8, 1.0],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.createFamilyGroup);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13EC13),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: const Color(0xFF13EC13).withOpacity(0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.kitchen),
                    SizedBox(width: 12),
                    Text(
                      'Add 4 Items to Fridge',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

  Widget _buildItemRow(
    String name,
    String qty,
    String price, {
    bool hasControls = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Item Name',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70, // Fixed width for Qty
            child: Column(
              children: [
                const Text(
                  'Qty',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: hasControls
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Icon(
                              Icons.remove,
                              size: 14,
                              color: Color(0xFF13EC13),
                            ),
                            Text(
                              '2',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Icon(Icons.add, size: 14, color: Color(0xFF13EC13)),
                          ],
                        )
                      : const Center(
                          child: Text(
                            '1',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Price',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Text(
                  price,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey, size: 18),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildUnknownItemRow() {
    return Container(
      color: const Color(0xFFFEFCE8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text(
                      'Please Verify',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.warning, size: 12, color: Colors.orange),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: const Text(
                    'Unkwn Item #44',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ... similar structure for qty/price but simplistic for now
          SizedBox(
            width: 40,
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text('1', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                '\$??.??',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const Icon(Icons.close, color: Colors.grey, size: 18),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class ZigZagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFAFAFA);
    final path = Path();

    // Start from top-left
    path.moveTo(0, 0);

    // Draw zig-zag bottom
    double x = 0;
    const double toothWidth = 8; // Half tooth width
    const double toothHeight = 8;

    while (x < size.width) {
      path.lineTo(x + toothWidth, toothHeight);
      path.lineTo(x + 2 * toothWidth, 0);
      x += 2 * toothWidth;
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
