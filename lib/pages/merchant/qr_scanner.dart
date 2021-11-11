import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScanner extends StatefulWidget {
  const QRScanner({Key? key}) : super(key: key);

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  Barcode? result;

  /// Listens for scan data being sent to the `controller` and
  /// pops the screen, returning the scan data.
  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) {
      controller.stopCamera();
      Navigator.of(context).pop(scanData.code);
    });
  }

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 104),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                'Point at QR code',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: FloatingActionButton(
                child: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
