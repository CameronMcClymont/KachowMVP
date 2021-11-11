import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kachow_mvp/classes/coupon.dart';
import 'package:kachow_mvp/classes/merchant.dart';
import 'package:kachow_mvp/pages/merchant/add_coupon.dart';
import 'package:kachow_mvp/pages/merchant/edit_coupon.dart';
import 'package:kachow_mvp/pages/merchant/qr_scanner.dart';
import 'package:kachow_mvp/pages/merchant/settings_merchant.dart';
import 'package:kachow_mvp/utils/auth_service.dart';
import 'package:kachow_mvp/utils/utils.dart';

class HomeMerchant extends StatefulWidget {
  const HomeMerchant({Key? key}) : super(key: key);

  @override
  State<HomeMerchant> createState() => _HomeMerchantState();
}

class _HomeMerchantState extends State<HomeMerchant> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Merchant? merchant;
  List<Coupon> coupons = [];

  /// Fetches the details of the currently signed in merchant.
  /// Assumes that the uid of the currently signed in user matches the
  /// id of one of the documents in the 'merchants' collection in Firestore.
  ///
  /// Calls setState() to rebuild the widget with the new data.
  Future fetchMerchantDetails() async {
    // Fetch documents from this merchant's coupons collection
    DocumentSnapshot merchantDoc = await firestore.collection('merchants').doc(AuthService.user!.uid).get();

    merchant = Merchant.fromFirestore(merchantDoc);

    // Rebuild widget
    setState(() {});
  }

  /// Fetches the coupons of the currently signed in merchant.
  /// Assumes that the uid of the currently signed in user matches the
  /// id of one of the documents in the 'merchants' collection in Firestore.
  ///
  /// Calls setState() to rebuild the widget with the new data.
  Future fetchCoupons() async {
    // Fetch documents from this merchant's coupons collection
    QuerySnapshot couponDocs =
        await firestore.collection('merchants').doc(AuthService.user!.uid).collection('coupons').get();

    // Extract coupons from DocumentSnapshot to Map<String, Map<String, dynamic>>
    coupons.clear();
    coupons = couponDocs.docs.map((doc) => Coupon.fromFirestore(doc)).toList();

    // Rebuild widget
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    // Fetch latest merchant/coupon data
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      fetchMerchantDetails();
      fetchCoupons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Image.asset('assets/images/logo.png', height: 30),
        actions: [
          IconButton(
            icon: Icon(
              Platform.isIOS ? CupertinoIcons.settings : Icons.settings,
              color: Colors.white,
            ),
            onPressed: () {
              if (merchant != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsMerchant(merchant: merchant!),
                  ),
                );
              }
            },
          )
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'qr_button',
              child: const Icon(Icons.qr_code),
              onPressed: () async {
                String? scanResult = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QRScanner(),
                  ),
                );

                if (scanResult == null) {
                  // Exited before the QR code was scanned
                  return;
                }

                Utils.showInSnackBar(context, 'Please wait...');

                // Extract coupon ID and code from scan result
                int colonIndex = scanResult.indexOf(':');
                int plusIndex = scanResult.indexOf('+');
                if (colonIndex == -1 || plusIndex == -1) {
                  Utils.showInSnackBar(context, 'Sorry, something went wrong');
                }

                // Parse result of scan: scanResult = 'customer_id:coupon_id+coupon_code';
                String customerId = scanResult.substring(0, colonIndex);
                String couponId = scanResult.substring(colonIndex + 1, plusIndex);
                String couponCode = scanResult.substring(plusIndex + 1);

                // Get latest update of all coupons to check if the coupon is still valid
                String merchantId = AuthService.user!.uid;
                QuerySnapshot couponsSnapshot =
                    await firestore.collection('merchants').doc(merchantId).collection('coupons').get();

                List<DocumentSnapshot> couponDocs = couponsSnapshot.docs;

                // Check if a coupon with this ID still exists and that the
                // code is available to redeem (it is in claimed_codes).
                for (DocumentSnapshot couponDoc in couponDocs) {
                  if (couponDoc.id == couponId && couponDoc.get('claimed_codes').contains(couponCode)) {
                    // The coupon is valid
                    // Remove the code from the customer's codes
                    await firestore
                        .collection('customers')
                        .doc(customerId)
                        .update({'coupons.$couponId': FieldValue.delete()});

                    // Remove the code from the merchant's claimed codes
                    List<dynamic> updatedClaimed = couponDoc.get('claimed_codes');
                    updatedClaimed.remove(couponCode); // Remove redeemed code
                    await firestore
                        .collection('merchants')
                        .doc(merchantId)
                        .collection('coupons')
                        .doc(couponId)
                        .update({'claimed_codes': updatedClaimed});

                    Utils.showInSnackBar(context, 'Successfully redeemed code');
                    setState(() {});
                    return;
                  }
                }

                // The coupon is not valid so display an error
                Utils.showInSnackBar(context, 'Coupon is invalid');
              },
            ),
            const SizedBox(
              height: 16,
            ),
            FloatingActionButton(
              heroTag: 'add_button',
              child: const Icon(Icons.add),
              onPressed: () async {
                bool? refreshCoupons = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddCoupon(),
                  ),
                );

                if (refreshCoupons != null && refreshCoupons) {
                  Utils.showInSnackBar(context, 'Done!');
                  await fetchCoupons();
                }
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchCoupons,
        child: ListView(
          children: coupons
              .map(
                (coupon) => Padding(
                  padding: const EdgeInsets.only(
                    left: 8,
                    top: 8,
                    right: 8,
                    bottom: 4,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text('${coupon.name} (${coupon.value}%)'),
                      subtitle: Builder(
                        builder: (_) {
                          int unredeemedCoupons = coupon.claimedCodes.length + coupon.unclaimedCodes.length;
                          return LinearProgressIndicator(
                            backgroundColor: Colors.transparent,
                            value: unredeemedCoupons == 0 ? 0 : coupon.unclaimedCodes.length / unredeemedCoupons,
                          );
                        }
                      ),
                      onTap: () async {
                        bool? refreshCoupons = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditCoupon(coupon),
                          ),
                        );

                        // Refresh coupon list if edited
                        if (refreshCoupons != null && refreshCoupons) {
                          await fetchCoupons();
                        }
                      },
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
