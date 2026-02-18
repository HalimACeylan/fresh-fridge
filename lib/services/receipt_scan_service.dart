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

class ReceiptScanNoTextException implements Exception {
  const ReceiptScanNoTextException();

  @override
  String toString() =>
      'No text was detected in the receipt photo. Please retake the photo in better lighting.';
}

/// Cross-platform receipt scan + OCR + parse pipeline.
class ReceiptScanService {
  ReceiptScanService._();
  static final ReceiptScanService instance = ReceiptScanService._();
  static final RegExp _moneyTokenPattern = RegExp(r'-?\$?\d+(?:[.,-]\s?\d{2})');
  static const Set<String> _weekdayTokens = {
    'mon',
    'monday',
    'tue',
    'tues',
    'tuesday',
    'wed',
    'weds',
    'wednesday',
    'thu',
    'thur',
    'thurs',
    'thursday',
    'fri',
    'friday',
    'sat',
    'saturday',
    'sun',
    'sunday',
  };

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
    if (rawText.trim().isEmpty) {
      throw const ReceiptScanNoTextException();
    }

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
        .map(_normalizeLine)
        .where((line) => line.isNotEmpty)
        .toList();

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
    var storeName = _inferStoreName(lines) ?? 'Scanned Receipt';
    if (finalItems.any(
      (item) => item.name.toLowerCase() == storeName.toLowerCase(),
    )) {
      storeName = 'Scanned Receipt';
    }

    final subtotal =
        _extractAmount(lines, labels: const ['subtotal', 'sub total']) ??
        _sumItems(finalItems);
    final tax = _extractAmount(lines, labels: const ['tax']) ?? 0;
    final total =
        _extractAmount(
          lines,
          labels: const ['total'],
          excludedLabels: const ['subtotal', 'sub total'],
        ) ??
        (subtotal + tax);

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
    final nameCandidates = <({int lineIndex, String name})>[];
    final amountCandidates = <({int lineIndex, double amount})>[];
    final qtyPricePattern = RegExp(
      r'^(.+?)\s+(\d+)\s*[xX*]\s*(\$?-?\d+(?:[.,-]\s?\d{2}))\s*$',
    );
    final trailingPricePattern = RegExp(
      r'^(.+?)\s+(-?\$?\d+(?:[.,-]\s?\d{2}))\s*$',
    );

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = _normalizeLine(lines[lineIndex]);
      if (line.isEmpty) continue;
      final lower = line.toLowerCase();

      final standaloneAmount = _extractStandaloneAmount(line);
      if (standaloneAmount != null && standaloneAmount > 0) {
        amountCandidates.add((lineIndex: lineIndex, amount: standaloneAmount));
        continue;
      }

      if (_shouldSkipLine(lower)) {
        continue;
      }

      final qtyPrice = qtyPricePattern.firstMatch(line);
      if (qtyPrice != null) {
        final name = qtyPrice.group(1)!.trim();
        final qty = int.tryParse(qtyPrice.group(2)!) ?? 1;
        final unitPrice = _toMoney(qtyPrice.group(3)!);
        if (name.isEmpty || unitPrice <= 0 || _isLikelyNonItemName(name)) {
          continue;
        }

        items.add(
          _buildReceiptItem(
            name: name,
            quantity: qty,
            unitPrice: unitPrice,
            index: items.length,
            receiptService: receiptService,
          ),
        );
        continue;
      }

      final trailingPrice = trailingPricePattern.firstMatch(line);
      if (trailingPrice != null) {
        final name = trailingPrice.group(1)!.trim();
        final price = _toMoney(trailingPrice.group(2)!);

        if (name.isEmpty || price <= 0 || _isLikelyNonItemName(name)) {
          continue;
        }

        items.add(
          _buildReceiptItem(
            name: name,
            quantity: 1,
            unitPrice: price,
            index: items.length,
            receiptService: receiptService,
          ),
        );
        continue;
      }

      if (_looksLikeItemNameCandidate(line, lower)) {
        nameCandidates.add((lineIndex: lineIndex, name: line));
      }
    }

    final pairedItems = _pairNameAndAmountCandidates(
      nameCandidates: nameCandidates,
      amountCandidates: amountCandidates,
      receiptService: receiptService,
      startIndex: items.length,
    );
    items.addAll(pairedItems);

    return items;
  }

  bool _shouldSkipLine(String lowerLine) {
    if (!RegExp(r'[a-zA-Z]').hasMatch(lowerLine)) return true;
    if (_isWeightMetadataLine(lowerLine)) return true;

    const ignoredPrefixes = [
      'subtotal',
      'sub total',
      'total',
      'tax',
      'vat',
      'discount',
      'change',
      'cash',
      'balance',
      'loyalty',
      'invoice',
      'receipt',
      'date',
      'time',
      'card',
      'visa',
      'mastercard',
      'debit',
      'credit',
      'eftpos',
      'auth',
    ];
    const ignoredContains = ['thank you'];

    for (final prefix in ignoredPrefixes) {
      if (_lineStartsWithLabel(lowerLine, prefix)) return true;
    }
    for (final token in ignoredContains) {
      if (lowerLine.contains(token)) return true;
    }
    return false;
  }

  String? _inferStoreName(List<String> lines) {
    for (final rawLine in lines.take(8)) {
      final line = _normalizeLine(rawLine);
      final lower = line.toLowerCase();
      final hasLetters = RegExp(r'[A-Za-z]').hasMatch(line);
      final hasManyDigits = RegExp(r'\d{3,}').hasMatch(line);
      final hasAmount = _extractLastAmount(line) != null;
      if (hasLetters &&
          !hasManyDigits &&
          !hasAmount &&
          !_shouldSkipLine(lower) &&
          line.length >= 3) {
        return line;
      }
    }
    return null;
  }

  double _sumItems(List<ReceiptItem> items) {
    return items.fold<double>(0, (sum, item) => sum + item.totalPrice);
  }

  double? _extractAmount(
    List<String> lines, {
    required List<String> labels,
    List<String> excludedLabels = const [],
  }) {
    for (final rawLine in lines.reversed) {
      final line = _normalizeLine(rawLine);
      final lower = line.toLowerCase();
      if (!_containsLabel(lower, labels)) continue;
      if (_containsLabel(lower, excludedLabels)) continue;

      final amount = _extractLastAmount(line);
      if (amount != null) return amount;
    }

    return null;
  }

  ReceiptItem _buildReceiptItem({
    required String name,
    required int quantity,
    required double unitPrice,
    required int index,
    required ReceiptService receiptService,
  }) {
    final cleanName = _cleanItemName(name);
    return ReceiptItem(
      id: 'ri_${DateTime.now().microsecondsSinceEpoch}_$index',
      name: cleanName,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: unitPrice * quantity,
      isVerified: false,
      matchedFridgeItemId: receiptService.findFridgeMatch(cleanName),
      suggestedCategory: receiptService.suggestCategory(cleanName),
    );
  }

  String _normalizeLine(String line) {
    return line
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _cleanItemName(String name) {
    return name
        .replaceAll(RegExp(r'^[^\w]+|[^\w)]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _looksLikeItemNameCandidate(String line, String lowerLine) {
    if (line.length < 2) return false;
    if (!RegExp(r'[A-Za-z]').hasMatch(line)) return false;
    if (_isLikelyNonItemName(line)) return false;
    if (_isWeightMetadataLine(lowerLine)) return false;
    if (_extractLastAmount(line) != null) return false;
    return !_shouldSkipLine(lowerLine);
  }

  bool _isWeightMetadataLine(String lowerLine) {
    return lowerLine.contains('/kg') ||
        lowerLine.contains('/lb') ||
        lowerLine.contains('net @') ||
        lowerLine.contains('kg net') ||
        lowerLine.contains(' lb ') ||
        lowerLine.contains(' oz ');
  }

  bool _containsLabel(String lowerLine, List<String> labels) {
    for (final label in labels) {
      if (label.isEmpty) continue;
      final pattern = RegExp(
        '(^|[^a-z])${RegExp.escape(label.toLowerCase())}([^a-z]|\$)',
      );
      if (pattern.hasMatch(lowerLine)) return true;
    }
    return false;
  }

  bool _lineStartsWithLabel(String lowerLine, String label) {
    final pattern = RegExp('^${RegExp.escape(label)}([^a-z]|\$)');
    return pattern.hasMatch(lowerLine);
  }

  double? _extractLastAmount(String text) {
    final matches = _moneyTokenPattern.allMatches(text).toList();
    if (matches.isEmpty) return null;
    return _toMoney(matches.last.group(0)!);
  }

  double? _extractStandaloneAmount(String line) {
    final trimmed = line.trim();
    if (!RegExp(r'^\$?\s*-?\d+(?:[.,-]\s?\d{2})$').hasMatch(trimmed)) {
      return null;
    }
    return _toMoney(trimmed);
  }

  List<ReceiptItem> _pairNameAndAmountCandidates({
    required List<({int lineIndex, String name})> nameCandidates,
    required List<({int lineIndex, double amount})> amountCandidates,
    required ReceiptService receiptService,
    required int startIndex,
  }) {
    if (nameCandidates.isEmpty || amountCandidates.isEmpty) return [];

    var pairableNames = nameCandidates;
    if (pairableNames.length > amountCandidates.length) {
      final overflow = pairableNames.length - amountCandidates.length;
      if (overflow > 0 && overflow < pairableNames.length) {
        pairableNames = pairableNames.sublist(overflow);
      }
    }

    final paired = <ReceiptItem>[];
    var amountPointer = 0;
    var itemIndex = startIndex;

    for (final candidate in pairableNames) {
      while (amountPointer < amountCandidates.length &&
          amountCandidates[amountPointer].lineIndex <= candidate.lineIndex) {
        amountPointer++;
      }
      if (amountPointer >= amountCandidates.length) break;

      final amount = amountCandidates[amountPointer].amount;
      if (amount <= 0) {
        amountPointer++;
        continue;
      }

      paired.add(
        _buildReceiptItem(
          name: candidate.name,
          quantity: 1,
          unitPrice: amount,
          index: itemIndex,
          receiptService: receiptService,
        ),
      );
      itemIndex++;
      amountPointer++;
    }

    return paired;
  }

  bool _isLikelyNonItemName(String rawName) {
    final lower = rawName.toLowerCase().trim();
    if (lower.isEmpty) return true;

    final alphaOnly = lower.replaceAll(RegExp(r'[^a-z]'), '');
    if (alphaOnly.isEmpty) return true;
    if (_weekdayTokens.contains(alphaOnly)) return true;

    if (alphaOnly.length <= 2) return true;

    if (_lineStartsWithLabel(lower, 'date') ||
        _lineStartsWithLabel(lower, 'time') ||
        _lineStartsWithLabel(lower, 'subtotal') ||
        _lineStartsWithLabel(lower, 'total') ||
        _lineStartsWithLabel(lower, 'tax') ||
        _lineStartsWithLabel(lower, 'cash') ||
        _lineStartsWithLabel(lower, 'change')) {
      return true;
    }

    return false;
  }

  double _toMoney(String value) {
    var normalized = value
        .replaceAll(RegExp(r'[^0-9,.\-\s]'), '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(',', '.')
        .trim();

    normalized = normalized.replaceAllMapped(
      RegExp(r'(?<=\d)-(?=\d{2}$)'),
      (_) => '.',
    );

    final isNegative = normalized.startsWith('-');
    if (isNegative) {
      normalized = normalized.substring(1);
    }

    final lastDot = normalized.lastIndexOf('.');
    if (lastDot != -1) {
      final left = normalized.substring(0, lastDot).replaceAll('.', '');
      final right = normalized.substring(lastDot + 1);
      normalized = '$left.$right';
    } else {
      normalized = normalized.replaceAll('.', '');
    }

    if (isNegative) normalized = '-$normalized';
    return double.tryParse(normalized) ?? 0;
  }

  Future<void> close() async {
    await _textRecognizer?.close();
    _textRecognizer = null;
  }
}
