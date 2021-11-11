import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kachow_mvp/pages/merchant/edit_coupon.dart';
import 'package:kachow_mvp/utils/auth_service.dart';
import 'package:kachow_mvp/utils/constants.dart';
import 'package:kachow_mvp/utils/utils.dart';

class AddCoupon extends StatelessWidget {
  AddCoupon({Key? key}) : super(key: key);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  late final String couponName;
  late final double couponValue;
  late final int couponQuantity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Coupon'),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(12),
        child: FloatingActionButton(
          child: const Icon(Icons.done),
          onPressed: () async {
            // Validate form
            if (_formKey.currentState!.validate()) {
              Utils.showInSnackBar(context, 'Generating coupons...');
              _formKey.currentState!.save();

              List<String> couponCodes = List<String>.generate(couponQuantity, (_) => Utils.getRandomString(Constants.couponCodeLength));
              Map<String, dynamic> coupon = {
                'name': couponName,
                'value': couponValue,
                'claimed_codes': [],
                'unclaimed_codes': couponCodes,
              };

              await firestore
                  .collection('merchants')
                  .doc(AuthService.user!.uid)
                  .collection('coupons')
                  .add(coupon);

              Navigator.of(context).pop(true);
            }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Name
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextFormField(
                decoration: const InputDecoration(
                  filled: true,
                  hintText: '10% off Soup!',
                  labelText: 'Coupon name',
                ),
                keyboardType: TextInputType.name,
                onSaved: (String? value) {
                  couponName = value!;
                },
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Name cannot be empty';
                  } else if (value.length > EditCoupon.nameMaxChars) {
                    return 'Name cannot have more than ${EditCoupon.nameMaxChars} characters';
                  }
                  return null;
                },
              ),
            ),

            // Value
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextFormField(
                decoration: const InputDecoration(
                  filled: true,
                  hintText: '10',
                  labelText: 'Value (%)',
                ),
                keyboardType: TextInputType.number,
                onSaved: (String? strValue) {
                  couponValue = double.parse(strValue!);
                },
                validator: (String? strValue) {
                  if (strValue == null || strValue.isEmpty) {
                    return 'Value cannot be empty';
                  }

                  double? value = double.tryParse(strValue);
                  if (value == null) {
                    return 'Value must be a number';
                  }

                  if (value <= 0) {
                    return 'Value must be greater than 0';
                  }

                  if (value > 100) {
                    return 'Value cannot be greater than 100';
                  }

                  return null;
                },
              ),
            ),

            // Quantity
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextFormField(
                decoration: const InputDecoration(
                  filled: true,
                  hintText: '50',
                  labelText: 'Quantity to Distribute',
                ),
                keyboardType: TextInputType.number,
                onSaved: (String? strQuantity) {
                  couponQuantity = int.parse(strQuantity!);
                },
                validator: (String? strQuantity) {
                  if (strQuantity == null || strQuantity.isEmpty) {
                    return 'Quantity cannot be empty';
                  }

                  if (strQuantity.contains('.')) {
                    return 'Quantity must be an integer';
                  }

                  int? quantity = int.tryParse(strQuantity);
                  if (quantity == null) {
                    return 'Quantity must be a number';
                  }

                  if (quantity <= 0) {
                    return 'Quantity must be greater than 0';
                  }

                  if (quantity > 1000) {
                    return 'Quantity cannot be greater than 1000';
                  }

                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
