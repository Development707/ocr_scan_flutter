import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:ocr_scan/ocr_scan.dart';

/// File mixin
mixin FileMixin on ScanFileStateDelegate {
  bool _canProcess = true;

  @override
  late ValueNotifier<Size> previewSize = ValueNotifier(widget.previewSize);

  @override
  Future<void> processImage(io.File file) async {
    if (!_canProcess) return;
    _canProcess = false;

    /// Decode image get preview size
    ui.Image decodedImage = await decodeImageFromList(file.readAsBytesSync());
    previewSize.value = Size(
      decodedImage.width.toDouble(),
      decodedImage.height.toDouble(),
    );

    try {
      final InputImage? inputImage = _inputImageFromFile(file);
      if (inputImage != null) {
        await Future.wait([
          processTextRecognizer(inputImage),
          processBarcodeScanner(inputImage),
        ]);
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _canProcess = true;
    }
  }

  @override
  void initState() {
    super.initState();
    previewSize.addListener(() {
      widget.onPreviewSizeChange?.call(previewSize.value);
    });
    processImage(widget.scanFile);
  }

  @override
  void didUpdateWidget(covariant ScanFile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scanFile != widget.scanFile) {
      processImage(widget.scanFile);
    }
  }

  @override
  void dispose() {
    previewSize.dispose();
    super.dispose();
  }

  InputImage? _inputImageFromFile(io.File file) {
    if (file.path.isEmpty) return null;

    return InputImage.fromFile(file);
  }

  @override
  List<TextLine> filterTextLines(
    List<TextLine> inputs,
    Zone zone,
    ui.Size imageSize,
    InputImageRotation imageRotation,
  ) {
    return super.filterTextLines(
      inputs,
      zone,
      previewSize.value,
      imageRotation,
    );
  }

  @override
  List<Barcode> filterBarcodes(
    List<Barcode> inputs,
    Zone zone,
    ui.Size imageSize,
    InputImageRotation imageRotation,
  ) {
    return super.filterBarcodes(
      inputs,
      zone,
      previewSize.value,
      imageRotation,
    );
  }
}
