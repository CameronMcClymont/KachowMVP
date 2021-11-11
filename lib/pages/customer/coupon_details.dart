import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kachow_mvp/classes/coupon.dart';
import 'package:kachow_mvp/utils/auth_service.dart';
import 'package:kachow_mvp/utils/constants.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CouponDetails extends StatelessWidget {
  final Coupon coupon;
  final String couponCode;

  static const double qrCodeSize = 0.8;

  bool initialDocSnapshot = true;

  CouponDetails({required this.coupon, required this.couponCode, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(coupon.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('customers').doc(AuthService.user!.uid).snapshots(),
          builder: (_, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasData) {
              if (initialDocSnapshot) {
                // QR code has not yet been scanned
                initialDocSnapshot = false;

                return Stack(
                  children: [
                    Text('Show this QR code at the till to get ${coupon.value}% off!'),
                    Center(
                      child: QrImage(
                        data: '${AuthService.user!.uid}:${coupon.id}+$couponCode',
                        version: QrVersions.auto,
                        size: min(
                          MediaQuery.of(context).size.width * qrCodeSize,
                          MediaQuery.of(context).size.height * qrCodeSize,
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // QR code has been scanned (since there was a document change)
                Navigator.of(context).pop(true);
                return Container();
              }
            } else {
              // Snapshot doesn't yet have data
              return const Center(child: Constants.loadingIndicator);
            }
          },
        ),
      ),
    );
  }
}
