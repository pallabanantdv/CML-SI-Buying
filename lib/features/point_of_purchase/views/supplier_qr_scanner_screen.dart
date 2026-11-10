import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../shared/widgets/app_app_bar.dart';

class SupplierQrScannerScreen extends StatefulWidget {
  const SupplierQrScannerScreen({super.key});

  @override
  State<SupplierQrScannerScreen> createState() =>
      _SupplierQrScannerScreenState();
}

class _SupplierQrScannerScreenState extends State<SupplierQrScannerScreen> {
  bool _detected = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppAppBar(title: Text('Scan supplier QR code')),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Point the camera at the QR code containing the supplier ID.',
          ),
        ),
        Expanded(
          child: MobileScanner(
            onDetect: (capture) {
              if (_detected) return;
              for (final barcode in capture.barcodes) {
                final id = barcode.rawValue?.trim();
                if (barcode.format != BarcodeFormat.qrCode ||
                    id == null ||
                    id.isEmpty) {
                  continue;
                }
                _detected = true;
                Navigator.of(context).pop(id);
                break;
              }
            },
            errorBuilder: (context, error) => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Camera unavailable. Allow camera access in device settings, then reopen the scanner. You can also select the supplier from the form.',
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
