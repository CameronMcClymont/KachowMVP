import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kachow_mvp/authentication/login.dart';
import 'package:kachow_mvp/pages/customer/home_customer.dart';
import 'package:kachow_mvp/pages/merchant/home_merchant.dart';
import 'package:kachow_mvp/utils/auth_service.dart';
import 'package:kachow_mvp/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  QuerySnapshot merchantSnapshot = await FirebaseFirestore.instance.collection('merchants').get();
  List<String> merchantIds = merchantSnapshot.docs.map((doc) => doc.id).toList();

  runApp(Kachow(merchantIds));
}

class Kachow extends StatelessWidget {
  final List<String> merchantIds;

  const Kachow(this.merchantIds, {Key? key}) : super(key: key);

  static final List<String> staticMerchantIds = [];

  @override
  Widget build(BuildContext context) {
    for (String id in merchantIds) {
      staticMerchantIds.add(id);
    }

    return MaterialApp(
      title: 'Kachow',
      theme: ThemeData(
        primarySwatch: MaterialColor(
          Constants.themeColor.value,
          const {
            50: Constants.themeColor,
            100: Constants.themeColor,
            200: Constants.themeColor,
            300: Constants.themeColor,
            400: Constants.themeColor,
            500: Constants.themeColor,
            600: Constants.themeColor,
            700: Constants.themeColor,
            800: Constants.themeColor,
            900: Constants.themeColor,
          },
        ),
      ),
      home: Builder(
        builder: (_) {
          if (FirebaseAuth.instance.currentUser == null) {
            return const Login();
          } else {
            AuthService.user = FirebaseAuth.instance.currentUser;

            if (merchantIds.contains(FirebaseAuth.instance.currentUser!.uid)) {
              // User is a merchant
              return const HomeMerchant();
            } else {
              // User is a customer
              return const HomeCustomer();
            }
          }
        },
      ),
    );
  }
}
