import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:fridge_app/models/receipt.dart';
import 'package:fridge_app/services/receipt_service.dart';

class ReceiptScanCancelledException implements Exception {
  const ReceiptScanCancelledException();

  @override
  String toString() => 'Receipt scan was cancelled.';
}

/// Cross-platform receipt scan + OCR + parse pipeline.
class ReceiptScanService {
  ReceiptScanService._();
  static final ReceiptScanService instance = ReceiptScanService._();

  TextRecognizer? _textRecognizer;

  TextRecognizer get _recognizer =>
      _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

  Future<Receipt> scanAndStoreReceipt() async {
    final imagePaths = await _scanDocumentImages();
    return processAndStoreImagePaths(imagePaths);
  }

  Future<Receipt> processAndStoreImagePath(String imagePath) {
    return processAndStoreImagePaths([imagePath]);
  }

  Future<Receipt> processAndStoreImagePaths(List<String>? imagePaths) async {
    if (imagePaths == null || imagePaths.isEmpty) {
      throw const ReceiptScanCancelledException();
    }

    final rawText = await _extractTextFromImages(imagePaths);
    final receipt = parseRecognizedText(
      rawText: rawText,
      imagePath: imagePaths.first,
    );

    ReceiptService.instance.addReceipt(receipt);
    return receipt;
  }

  Receipt parseRecognizedText({required String rawText, String? imagePath}) {
    final lines = rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final storeName = _inferStoreName(lines) ?? 'Scanned Receipt';
    final items = _parseItems(lines);
    final fallbackItem = ReceiptItem(
      id: 'ri_fallback_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Unknown Item',
      quantity: 1,
      unitPrice: 0,
      totalPrice: 0,
      isUnknown: true,
    );
    final finalItems = items.isEmpty ? [fallbackItem] : items;

    final subtotal =
        _extractAmount(lines, labels: const ['subtotal', 'sub total']) ??
        _sumItems(finalItems);
    final tax = _extractAmount(lines, labels: const ['tax']) ?? 0;
    final total =
        _extractAmount(lines, labels: const ['total']) ?? (subtotal + tax);

    return Receipt(
      id: 'receipt_scan_${DateTime.now().millisecondsSinceEpoch}',
      storeName: storeName,
      scanDate: DateTime.now(),
      items: finalItems,
      subtotal: subtotal,
      tax: tax,
      total: total,
      imageUrl: imagePath,
    );
  }

  Future<List<String>?> _scanDocumentImages() async {
    if (Platform.isAndroid) {
      final scanner = DocumentScanner(
        options: DocumentScannerOptions(
          documentFormats: const {DocumentFormat.jpeg},
          mode: ScannerMode.full,
          pageLimit: 1,
          isGalleryImport: true,
        ),
      );

      try {
        final result = await scanner.scanDocument();
        return result.images;
      } finally {
        await scanner.close();
      }
    }

    if (Platform.isIOS) {
      return CunningDocumentScanner.getPictures(
        noOfPages: 1,
        isGalleryImportAllowed: true,
      );
    }

    return null;
  }

  Future<String> _extractTextFromImages(List<String> imagePaths) async {
    final buffer = StringBuffer();

    for (final path in imagePaths) {
      final inputImage = InputImage.fromFilePath(path);
      final recognized = await _recognizer.processImage(inputImage);
      final text = recognized.text.trim();

      if (text.isEmpty) continue;
      if (buffer.isNotEmpty) buffer.writeln('\n');
      buffer.writeln(text);
    }

    return buffer.toString();
  }

  List<ReceiptItem> _parseItems(List<String> lines) {
    final receiptService = ReceiptService.instance;
    final items = <ReceiptItem>[];
    final qtyPricePattern = RegExp(
      r'^(.+?)\s+(\d+)\s*[xX]\s*(\$?\d+(?:[.,]\d{2}))$',
    );
    final trailingPricePattern = RegExp(r'^(.+?)\s+(\$?\d+(?:[.,]\d{2}))$');

    for (final rawLine in lines) {
      final line = rawLine.replaceAll(RegExp(r'\s+'), ' ').trim();
      final lower = line.toLowerCase();

      if (_shouldSkipLine(lower)) continue;

      final qtyPrice = qtyPricePattern.firstMatch(line);
      if (qtyPrice != null) {
        final name = qtyPrice.group(1)!.trim();
        final qty = int.tryParse(qtyPrice.group(2)!) ?? 1;
        final unitPrice = _toMoney(qtyPrice.group(3)!);
        final totalPrice = unitPrice * qty;

        items.add(
          ReceiptItem(
            id: 'ri_${DateTime.now().microsecondsSinceEpoch}_${items.length}',
            name: name,
            quantity: qty,
            unitPrice: unitPrice,
            totalPrice: totalPrice,
            isVerified: false,
            matchedFridgeItemId: receiptService.findFridgeMatch(name),
            suggestedCategory: receiptService.suggestCategory(name),
          ),
        );
        continue;
      }

      final trailingPrice = trailingPricePattern.firstMatch(line);
      if (trailingPrice != null) {
        final name = trailingPrice.group(1)!.trim();
        final price = _toMoney(trailingPrice.group(2)!);

        if (name.isEmpty || price <= 0) continue;

        items.add(
          ReceiptItem(
            id: 'ri_${DateTime.now().microsecondsSinceEpoch}_${items.length}',
            name: name,
            quantity: 1,
            unitPrice: price,
            totalPrice: price,
            isVerified: false,
            matchedFridgeItemId: receiptService.findFridgeMatch(name),
            suggestedCategory: receiptService.suggestCategory(name),
          ),
        );
      }
    }

    return items;
  }

  bool _shouldSkipLine(String lowerLine) {
    if (!RegExp(r'[a-zA-Z]').hasMatch(lowerLine)) return true;

    const ignoredWords = [
      'subtotal',
      'sub total',
      'total',
      'tax',
      'vat',
      'change',
      'cash',
      'balance',
      'invoice',
      'receipt',
      'date',
      'time',
      'card',
      'visa',
      'mastercard',
      'thank',
    ];

    for (final word in ignoredWords) {
      if (lowerLine.contains(word)) return true;
    }
    return false;
  }

  String? _inferStoreName(List<String> lines) {
    for (final line in lines.take(6)) {
      final hasLetters = RegExp(r'[A-Za-z]').hasMatch(line);
      final hasManyDigits = RegExp(r'\d{3,}').hasMatch(line);
      if (hasLetters && !hasManyDigits && line.length >= 3) {
        return line;
      }
    }
    return null;
  }

  double _sumItems(List<ReceiptItem> items) {
    return items.fold<double>(0, (sum, item) => sum + item.totalPrice);
  }

  double? _extractAmount(List<String> lines, {required List<String> labels}) {
    final amountPattern = RegExp(r'(\d+[.,]\d{2})');

    for (final line in lines.reversed) {
      final lower = line.toLowerCase();
      if (!labels.any(lower.contains)) continue;
      final matches = amountPattern.allMatches(line).toList();
      if (matches.isEmpty) continue;
      return _toMoney(matches.last.group(1)!);
    }

    return null;
  }

  double _toMoney(String value) {
    final normalized = value.replaceAll('\$', '').replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0;
  }

  Future<void> close() async {
    await _textRecognizer?.close();
    _textRecognizer = null;
  }
}
