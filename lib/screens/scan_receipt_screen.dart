import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fridge_app/routes.dart';
import 'package:fridge_app/services/receipt_scan_service.dart';
import 'package:fridge_app/services/receipt_service.dart';
import 'package:image_picker/image_picker.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  FlashMode _flashMode = FlashMode.auto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _controller.dispose();
    ReceiptScanService.instance.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _pickImageAndPreview(ImageSource source) async {
    if (_isProcessing) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 95,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile == null || !mounted) return;

      final shouldProcess = await _showReceiptPreview(
        imagePath: pickedFile.path,
        source: source,
      );

      if (shouldProcess == true) {
        await _processSelectedReceiptImage(pickedFile.path);
      }
    } catch (e) {
      _showFailureSnackBar('Could not open image picker: $e');
    }
  }

  Future<void> _takePictureAndPreview() async {
    if (_isProcessing ||
        !_isCameraInitialized ||
        _cameraController == null ||
        _cameraController!.value.isTakingPicture) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final xFile = await _cameraController!.takePicture();
      if (!mounted) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final shouldProcess = await _showReceiptPreview(
        imagePath: xFile.path,
        source: ImageSource.camera,
      );

      if (shouldProcess == true) {
        await _processSelectedReceiptImage(xFile.path);
      } else {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showFailureSnackBar('Failed to take picture: $e');
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _toggleFlash() {
    if (_cameraController == null) return;

    setState(() {
      if (_flashMode == FlashMode.off) {
        _flashMode = FlashMode.always;
      } else if (_flashMode == FlashMode.always) {
        _flashMode = FlashMode.auto;
      } else {
        _flashMode = FlashMode.off;
      }
    });

    _cameraController!.setFlashMode(_flashMode);
  }

  Future<void> _processSelectedReceiptImage(String imagePath) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final receipt = await ReceiptScanService.instance
          .processAndStoreImagePath(imagePath);
      if (!mounted) return;

      await Navigator.pushNamed(
        context,
        AppRoutes.recentScanResults,
        arguments: receipt.id,
      );
    } on ReceiptScanCancelledException {
      // User canceled before processing.
    } catch (e) {
      _showFailureSnackBar('Scan failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<bool?> _showReceiptPreview({
    required String imagePath,
    required ImageSource source,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final mediaSize = MediaQuery.sizeOf(sheetContext);

        return SafeArea(
          child: Container(
            constraints: BoxConstraints(maxHeight: mediaSize.height * 0.88),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Receipt Preview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(imagePath),
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFFF3F3F3),
                          child: const Center(
                            child: Text(
                              'Preview unavailable',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext, false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: Text(
                            source == ImageSource.camera
                                ? 'Retake'
                                : 'Choose Another',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(sheetContext, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF13EC13),
                            foregroundColor: const Color(0xFF102210),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('Use Photo'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFailureSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final receiptCount = ReceiptService.instance.getAllReceipts().length;
    final receiptBadgeText = receiptCount > 99 ? '99+' : '$receiptCount';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Feed Background
          Positioned.fill(
            child: _isCameraInitialized && _cameraController != null
                ? CameraPreview(_cameraController!)
                : Container(color: Colors.black),
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
                    _buildIconButton(
                      _flashMode == FlashMode.off
                          ? Icons.flash_off
                          : _flashMode == FlashMode.always
                          ? Icons.flash_on
                          : Icons.flash_auto,
                      _toggleFlash,
                    ),
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
                      GestureDetector(
                        onTap: _isProcessing
                            ? null
                            : () => _pickImageAndPreview(ImageSource.gallery),
                        child: Container(
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
                      ),
                      // Shutter
                      GestureDetector(
                        onTap: _isProcessing ? null : _takePictureAndPreview,
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
                              child: _isProcessing
                                  ? const Padding(
                                      padding: EdgeInsets.all(18.0),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Color(0xFF102210),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      color: Color(0xFF102210),
                                      size: 32,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      // Recent Scans
                      GestureDetector(
                        onTap: _isProcessing
                            ? null
                            : () => Navigator.pushNamed(
                                context,
                                AppRoutes.recentScanResults,
                              ),
                        child: Stack(
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
                            if (receiptCount > 0)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF13EC13),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    receiptBadgeText,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF13EC13)),
                      SizedBox(height: 12),
                      Text(
                        'Processing receipt...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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
