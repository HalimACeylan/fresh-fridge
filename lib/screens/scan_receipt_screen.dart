import 'package:flutter/material.dart';
import 'package:fridge_app/routes.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Feed Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/camera_feed.png',
              fit: BoxFit.cover,
            ),
          ),
          // Dark Overlay
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),
          // Top Controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIconButton(Icons.close, () => Navigator.pop(context)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Scan Receipt',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildIconButton(Icons.flash_off, () {}),
                  ],
                ),
              ),
            ),
          ),
          // Center Guide Frame
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 300,
                    maxHeight: 400,
                  ),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Stack(
                      children: [
                        // Corners
                        _buildCorner(Alignment.topLeft),
                        _buildCorner(Alignment.topRight),
                        _buildCorner(Alignment.bottomLeft),
                        _buildCorner(Alignment.bottomRight),
                        // Scan Line
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Align(
                              alignment: Alignment(
                                0,
                                -1 + 2 * _controller.value,
                              ),
                              child: Container(
                                height: 2,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF13EC13),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF13EC13,
                                      ).withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Grid
                        GridView.count(
                          crossAxisCount: 3,
                          physics: const NeverScrollableScrollPhysics(),
                          children: List.generate(9, (index) {
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 0.5,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF13EC13),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Align edges with the frame',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildModeText('Barcode', false),
                      const SizedBox(width: 24),
                      Container(
                        padding: const EdgeInsets.only(bottom: 2),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFF13EC13),
                              width: 2,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Receipt',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      _buildModeText('Manual', false),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Gallery
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: const DecorationImage(
                            image: AssetImage(
                              'assets/images/gallery_thumb.png',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          color: Colors.black26,
                          child: const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      // Shutter
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.recentScanResults,
                          );
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 4,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: Color(0xFF13EC13),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Color(0xFF102210),
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Recent Scans
                      Stack(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.receipt_long,
                              size: 32,
                              color: Colors.grey,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF13EC13),
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                '3',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border(
            top: alignment.y == -1
                ? const BorderSide(color: Color(0xFF13EC13), width: 4)
                : BorderSide.none,
            bottom: alignment.y == 1
                ? const BorderSide(color: Color(0xFF13EC13), width: 4)
                : BorderSide.none,
            left: alignment.x == -1
                ? const BorderSide(color: Color(0xFF13EC13), width: 4)
                : BorderSide.none,
            right: alignment.x == 1
                ? const BorderSide(color: Color(0xFF13EC13), width: 4)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: alignment == Alignment.topLeft
                ? const Radius.circular(8)
                : Radius.zero,
            topRight: alignment == Alignment.topRight
                ? const Radius.circular(8)
                : Radius.zero,
            bottomLeft: alignment == Alignment.bottomLeft
                ? const Radius.circular(8)
                : Radius.zero,
            bottomRight: alignment == Alignment.bottomRight
                ? const Radius.circular(8)
                : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildModeText(String text, bool isActive) {
    return Text(
      text,
      style: TextStyle(
        color: isActive ? Colors.black : Colors.grey,
        fontWeight: FontWeight.bold,
        fontSize: 12,
        letterSpacing: 0.5,
      ),
    );
  }
}
