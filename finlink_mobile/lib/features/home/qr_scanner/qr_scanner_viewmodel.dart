import 'package:finlink_mobile/features/base_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QrScannerViewmodel extends BaseViewmodel {
  QrScannerViewmodel({this.onScan, this.returnOnScan = false});

  final ValueChanged<String>? onScan;
  final bool returnOnScan;

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  QRViewController? _controller;
  String _scannedValue = 'No QR scanned yet';
  bool _isFlashOn = false;
  bool _hasResult = false;

  String get scannedValue => _scannedValue;
  bool get isFlashOn => _isFlashOn;

  void onQRViewCreated(QRViewController controller) {
    _controller = controller;
    _controller?.scannedDataStream.listen((scanData) {
      final code = scanData.code;
      if (code == null || code.isEmpty) {
        return;
      }
      if (_hasResult) {
        return;
      }
      _hasResult = true;
      _scannedValue = code;
      notifyListeners();
      if (returnOnScan && onScan != null) {
        onScan!(code);
      }
    });
  }

  Future<void> toggleFlash() async {
    await _controller?.toggleFlash();
    _isFlashOn = await _controller?.getFlashStatus() ?? false;
    notifyListeners();
  }

  Future<void> flipCamera() async {
    await _controller?.flipCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}