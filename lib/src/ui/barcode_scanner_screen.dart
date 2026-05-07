import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('扫描二维码/条形码')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_handled) {
            return;
          }
          final value = capture.barcodes
              .map((barcode) => barcode.rawValue)
              .whereType<String>()
              .firstOrNull;
          if (value == null || value.isEmpty) {
            return;
          }
          _handled = true;
          Navigator.of(context).pop(value);
        },
      ),
    );
  }
}
