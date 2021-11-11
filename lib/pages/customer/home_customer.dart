import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:kachow_mvp/classes/merchant.dart';
import 'package:kachow_mvp/pages/customer/merchant_details.dart';
import 'package:kachow_mvp/pages/customer/settings_customer.dart';
import 'package:kachow_mvp/utils/auth_service.dart';
import 'package:kachow_mvp/utils/constants.dart';
import 'package:kachow_mvp/utils/utils.dart';
import 'package:shimmer/shimmer.dart';

class HomeCustomer extends StatefulWidget {
  const HomeCustomer({Key? key}) : super(key: key);

  @override
  State<HomeCustomer> createState() => _HomeCustomerState();
}

class _HomeCustomerState extends State<HomeCustomer> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<Merchant> merchants = [];
  Map<String, String> walletCoupons = {};

  /// Fetches the details of all merchants from the 'merchants'
  /// collection in Firestore and stores them as `Merchant` objects.
  ///
  /// Calls setState() to rebuild the widget with the new data.
  Future fetchMerchants() async {
    // Fetch documents from the merchants collection
    merchants.clear();
    QuerySnapshot querySnapshot = await firestore.collection('merchants').get();
    for (DocumentSnapshot merchantDoc in querySnapshot.docs) {
      Merchant merchant = Merchant.fromFirestore(merchantDoc);

      // Fetch download URL of merchant image
      final Reference ref = FirebaseStorage.instance.ref().child('${merchantDoc.id}.png');
      try {
        merchant.downloadUrl = await ref.getDownloadURL();
      } catch (e) {
        // Merchant doesn't have an image so leave downloadUrl as null
        print('${merchant.name} has no image! $e');
      }

      merchants.add(merchant);
    }

    // Rebuild widget
    setState(() {});
  }

  /// Fetches the details of all the claimed coupons of the user
  /// currently signed in.
  /// Assumes that the uid of the currently signed in user matches the
  /// id of one of the documents in the 'customers' collection in Firestore.
  ///
  /// Calls setState() to rebuild the widget with the new data.
  Future fetchClaimedCoupons() async {
    // Fetch documents from the logged in user's coupons collection
    walletCoupons.clear();
    DocumentSnapshot userDoc = await firestore.collection('customers').doc(AuthService.user!.uid).get();

    // Extract coupons from DocumentSnapshot
    try {
      for (MapEntry coupon in userDoc.get('coupons').entries) {
        walletCoupons[coupon.key] = coupon.value.toString();
      }
    } catch (e) {
      print('User has no coupons.');
    }

    // Rebuild widget
    setState(() {});
  }

  Widget merchantCardPlaceholder() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: AspectRatio(
        aspectRatio: 2,
        child: Shimmer.fromColors(
          child: Container(color: Colors.grey),
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
        ),
      ),
    );
  }

  Widget merchantCard(Merchant merchant) {
    return Card(
      child: InkWell(
        onTap: () async {
          bool refreshWalletCoupons = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MerchantDetails(
                merchant,
                userCoupons: walletCoupons,
              ),
            ),
          );

          if (refreshWalletCoupons) {
            await fetchClaimedCoupons();
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2,
              child: Builder(
                builder: (_) {
                  if (merchant.downloadUrl != null) {
                    return Constants.networkImage(merchant.downloadUrl!);
                  } else {
                    return const Placeholder(fallbackHeight: 150);
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      merchant.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Builder(
                    builder: (_) {
                      late String text;
                      late IconData icon;
                      late Color color;
                      if (Utils.isMerchantOpen(merchant.hours)) {
                        text = 'Open';
                        icon = Icons.check;
                        color = Colors.green;
                      } else {
                        text = 'closed';
                        icon = Icons.cancel;
                        color = Colors.red;
                      }

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: color),
                          const SizedBox(width: 8),
                          Text(
                            text,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Fetch latest merchant/coupon data
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      fetchMerchants();
      fetchClaimedCoupons();
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsCustomer(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchMerchants();
          await fetchClaimedCoupons();
        },
        child: merchants.isEmpty
            ? ListView(
                children: [
                  merchantCardPlaceholder(),
                  merchantCardPlaceholder(),
                  merchantCardPlaceholder(),
                ],
              )
            : ListView(
                children: merchants
                    .map((merchant) => Padding(
                          padding: const EdgeInsets.all(12),
                          child: merchantCard(merchant),
                        ))
                    .toList(),
              ),
      ),
    );
  }
}
