import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kachow_mvp/classes/coupon.dart';
import 'package:kachow_mvp/utils/auth_service.dart';
import 'package:kachow_mvp/utils/utils.dart';

class EditCoupon extends StatelessWidget {
  final Coupon coupon;

  static const nameMaxChars = 50;

  EditCoupon(this.coupon, {Key? key}) : super(key: key);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(coupon.name),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'delete',
              child: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) {
                    return AlertDialog(
                      title: const Text('Delete Coupon'),
                      content: Text('Are you sure you want to delete coupon "${coupon.name}"?'),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Delete'),
                          onPressed: () async {
                            Navigator.of(context).pop();
                            Utils.showInSnackBar(context, 'Deleting coupon...');

                            await firestore
                                .collection('merchants')
                                .doc(AuthService.user!.uid)
                                .collection('coupons')
                                .doc(coupon.id)
                                .delete();

                            Utils.showInSnackBar(context, 'Done!');
                            Navigator.of(context).pop(true);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(
              height: 16,
            ),
            FloatingActionButton(
              heroTag: 'save',
              child: const Icon(Icons.done),
              onPressed: () async {
                // Validate form
                if (_formKey.currentState!.validate()) {
                  Utils.showInSnackBar(context, 'Updating coupon...');
                  _formKey.currentState!.save();

                  // Update coupon name and value in Firestore
                  Map<String, dynamic> updatedCoupon = {
                    'name': coupon.name,
                    'value': coupon.value,
                  };

                  await firestore
                      .collection('merchants')
                      .doc(AuthService.user!.uid)
                      .collection('coupons')
                      .doc(coupon.id)
                      .update(updatedCoupon);

                  Utils.showInSnackBar(context, 'Done!');
                  Navigator.of(context).pop(true);
                }
              },
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            // ID
            ListTile(
              title: Text('ID: ${coupon.id}'),
            ),

            // Amount claimed
            Builder(
              builder: (context) {
                int unredeemedCoupons = coupon.claimedCodes.length + coupon.unclaimedCodes.length;
                if (unredeemedCoupons == 0) {
                  return const ListTile(
                    title: Text('All codes for this coupon have been redeemed!'),
                    subtitle: Text('You can delete this coupon now.'),
                  );
                } else {
                  return ListTile(
                    title: Text('Unclaimed codes (${coupon.unclaimedCodes.length}/$unredeemedCoupons):'),
                    subtitle: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      value: coupon.unclaimedCodes.length / unredeemedCoupons,
                    ),
                  );
                }
              }
            ),

            // Name
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextFormField(
                decoration: const InputDecoration(
                  filled: true,
                  hintText: '10% off Soup!',
                  labelText: 'Coupon name',
                ),
                initialValue: coupon.name,
                keyboardType: TextInputType.name,
                onSaved: (String? value) {
                  coupon.name = value!;
                },
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Name cannot be empty';
                  } else if (value.length > nameMaxChars) {
                    return 'Name cannot have more than $nameMaxChars characters';
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
                initialValue: coupon.value.toString(),
                keyboardType: TextInputType.number,
                onSaved: (String? strValue) {
                  coupon.value = double.parse(strValue!);
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
          ],
        ),
      ),
    );
  }
}
