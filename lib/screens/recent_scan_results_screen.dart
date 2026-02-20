import 'package:flutter/material.dart';
import 'package:fridge_app/models/receipt.dart';
import 'package:fridge_app/routes.dart';
import 'package:fridge_app/services/fridge_service.dart';
import 'package:fridge_app/services/receipt_service.dart';

class RecentScanResultsScreen extends StatefulWidget {
  const RecentScanResultsScreen({super.key});

  @override
  State<RecentScanResultsScreen> createState() =>
      _RecentScanResultsScreenState();
}

class _RecentScanResultsScreenState extends State<RecentScanResultsScreen> {
  bool _isImporting = false;

  Future<void> _importItemsToFridge(Receipt receipt) async {
    if (_isImporting) return;

    setState(() {
      _isImporting = true;
    });

    try {
      final imported = ReceiptService.instance.addReceiptItemsToFridge(
        receipt.id,
      );
      await FridgeService.instance.refreshFromCloud();
      await ReceiptService.instance.refreshFromCloud();

      if (!mounted) return;

      if (imported.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No new recognized items were available to import.'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${imported.length} item${imported.length == 1 ? '' : 's'} to your fridge.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Navigator.pushNamed(context, AppRoutes.insideFridge);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not import scanned items: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ReceiptService.instance;
    final receipts = service.getAllReceipts();
    final receiptId = ModalRoute.of(context)?.settings.arguments as String?;

    // Show the most recent receipt (or first available)
    if (receipts.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8F6),
        appBar: AppBar(title: const Text('Scan Results')),
        body: const Center(child: Text('No receipts found')),
      );
    }

    final receipt = receiptId != null
        ? (service.getReceiptById(receiptId) ?? receipts.first)
        : receipts.first;
    final recognizedItems = receipt.items.where((i) => !i.isUnknown).toList();
    final unknownItems = receipt.unknownItems;

    // Format date
    final months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final d = receipt.scanDate;
    final hour = d.hour > 12 ? d.hour - 12 : d.hour;
    final amPm = d.hour >= 12 ? 'PM' : 'AM';
    final dateStr =
        '${months[d.month - 1]} ${d.day}, ${d.year} • ${hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $amPm';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text(
          'Scan Results',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFAFB2AF).withValues(alpha: 0.1),
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
                      color: Colors.black.withValues(alpha: 0.05),
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
                              color: const Color(
                                0xFF13EC13,
                              ).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.storefront,
                              color: Color(0xFF13EC13),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            receipt.storeName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
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
                    ),
                    // Recognized items
                    ...recognizedItems.asMap().entries.expand((entry) {
                      final item = entry.value;
                      return [
                        _buildItemRow(item, hasControls: item.quantity > 1),
                        if (entry.key < recognizedItems.length - 1 ||
                            unknownItems.isNotEmpty)
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFFAFAFA),
                          ),
                      ];
                    }),
                    // Unknown items
                    ...unknownItems.map((item) => _buildUnknownItemRow(item)),

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
                          _buildSummaryRow(
                            'Subtotal',
                            '\$${receipt.subtotal.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Tax (est)',
                            '\$${receipt.tax.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${receipt.total.toStringAsFixed(2)}',
                                style: const TextStyle(
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
                  colors: [Colors.white, Colors.white.withValues(alpha: 0)],
                  stops: const [0.8, 1.0],
                ),
              ),
              child: ElevatedButton(
                onPressed: _isImporting
                    ? null
                    : () => _importItemsToFridge(receipt),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13EC13),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: const Color(0xFF13EC13).withValues(alpha: 0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isImporting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.kitchen),
                    const SizedBox(width: 12),
                    Text(
                      _isImporting
                          ? 'Adding to Fridge...'
                          : 'Add ${receipt.recognizedCount} Items to Fridge',
                      style: const TextStyle(
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

  Widget _buildItemRow(ReceiptItem item, {bool hasControls = false}) {
    final categoryEmoji = item.suggestedCategory?.emoji ?? '📦';
    final categoryColor =
        item.suggestedCategory?.color ?? const Color(0xFF9E9E9E);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 17, right: 8),
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(categoryEmoji, style: const TextStyle(fontSize: 16)),
            ),
          ),
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
                    item.name,
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
                          children: [
                            const Icon(
                              Icons.remove,
                              size: 14,
                              color: Color(0xFF13EC13),
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(
                              Icons.add,
                              size: 14,
                              color: Color(0xFF13EC13),
                            ),
                          ],
                        )
                      : Center(
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                  '\$${item.totalPrice.toStringAsFixed(2)}',
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

  Widget _buildUnknownItemRow(ReceiptItem item) {
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
                const Row(
                  children: [
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
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                item.totalPrice > 0
                    ? '\$${item.totalPrice.toStringAsFixed(2)}'
                    : '\$??.??',
                style: const TextStyle(
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
