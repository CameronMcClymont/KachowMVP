import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kachow_mvp/classes/coupon.dart';
import 'package:kachow_mvp/classes/merchant.dart';
import 'package:kachow_mvp/pages/customer/coupon_details.dart';
import 'package:kachow_mvp/utils/auth_service.dart';
import 'package:kachow_mvp/utils/constants.dart';
import 'package:kachow_mvp/utils/utils.dart';
import 'package:maps_launcher/maps_launcher.dart';

class MerchantDetails extends StatefulWidget {
  final Merchant merchant;
  final Map<String, String> userCoupons; // A map of the IDs and codes of coupons the user has claimed

  const MerchantDetails(this.merchant, {required this.userCoupons, Key? key}) : super(key: key);

  @override
  State<MerchantDetails> createState() => _MerchantDetailsState();
}

class _MerchantDetailsState extends State<MerchantDetails> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<Coupon> merchantCoupons = [];

  // True if the user has claimed at least one coupon since visiting this page
  bool refreshOnPop = false;

  /// Fetches this merchant's coupons.
  ///
  /// Calls setState() to rebuild the widget with the new data.
  Future fetchMerchantCoupons() async {
    // Fetch documents from this merchant's coupons collection
    QuerySnapshot couponDocs =
        await firestore.collection('merchants').doc(widget.merchant.id).collection('coupons').get();

    // Extract coupons from DocumentSnapshot
    merchantCoupons.clear();
    merchantCoupons = couponDocs.docs
        .map((doc) => Coupon.fromFirestore(doc)) // Map each document to a Coupon object
        .toList();

    for (int i = merchantCoupons.length - 1; i >= 0; i--) {
      // Remove coupons that have no codes left to be claimed
      if (merchantCoupons[i].unclaimedCodes.isEmpty) {
        // Only remove the coupon if it is not owned by the user
        bool userOwnsThisCoupon = false;
        for (String ownedCouponId in widget.userCoupons.keys) {
          if (merchantCoupons[i].id == ownedCouponId) {
            // The user owns this coupon so don't remove it
            userOwnsThisCoupon = true;
            break;
          }
        }

        // The user doesn't own this coupon so remove it
        if (!userOwnsThisCoupon) {
          merchantCoupons.removeAt(i);
        }
      }
    }

    // Rebuild widget
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      fetchMerchantCoupons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(refreshOnPop);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.merchant.name),
        ),
        body: RefreshIndicator(
          onRefresh: fetchMerchantCoupons,
          child: ListView(
            children: [
              // Image
              AspectRatio(
                aspectRatio: 1.4,
                child: Builder(
                  builder: (_) {
                    if (widget.merchant.downloadUrl == null) {
                      return const Placeholder();
                    } else {
                      return Constants.networkImage(widget.merchant.downloadUrl!);
                    }
                  },
                ),
              ),

              // Address
              ListTile(
                onTap: () {
                  MapsLauncher.launchQuery(widget.merchant.address);
                },
                title: Row(
                  children: [
                    const Icon(Icons.location_on),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                      widget.merchant.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )),
                  ],
                ),
              ),

              // Hours
              const Padding(
                padding: EdgeInsets.only(left: 12, right: 12, bottom: 12),
                child: Text(
                  'Opening Hours',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Constants.formattedHoursWidget(widget.merchant.hours),

              // Coupons list
              const Padding(
                padding: EdgeInsets.only(left: 12, right: 12, top: 8),
                child: Text(
                  'Coupons',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (merchantCoupons.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 12, top: 4),
                  child: Text('(No coupons available right now)'),
                ),
              ...merchantCoupons
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
                          title: Text(coupon.name),
                          subtitle: widget.userCoupons.keys.contains(coupon.id)
                              ? const Text('(Claimed)')
                              : Text('Value: ${coupon.value}%'),
                          onTap: () async {
                            if (widget.userCoupons.keys.contains(coupon.id)) {
                              // The user has already claimed this coupon
                              bool? couponRedeemed = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CouponDetails(
                                    coupon: coupon,
                                    couponCode: widget.userCoupons[coupon.id]!,
                                  ),
                                ),
                              );

                              if (couponRedeemed != null) {
                                // The coupon was redeemed after opening the CouponDetails page
                                Utils.showInSnackBar(context, 'Successfully redeemed code');
                                // Remove the coupon code from the userCoupons Map:
                                setState(() {
                                  widget.userCoupons.remove(coupon.id);
                                });

                                // Update the list of coupons so that this coupon gets removed
                                // if there are no more of this type available to claim.
                                await fetchMerchantCoupons();
                              }
                            } else {
                              // The user hasn't yet claimed this coupon
                              showDialog(
                                context: context,
                                builder: (_) {
                                  return AlertDialog(
                                    title: const Text('Claim coupon'),
                                    content: Text('Claim coupon "${coupon.name}"?'),
                                    actions: [
                                      TextButton(
                                        child: const Text('Maybe later..'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: const Text("It's mine!"),
                                        onPressed: () async {
                                          Navigator.of(context).pop();
                                          Utils.showInSnackBar(context, 'Claiming coupon...');

                                          try {
                                            // Get latest update of all coupons to check if the ID is still valid
                                            QuerySnapshot couponsSnapshot = await firestore
                                                .collection('merchants')
                                                .doc(widget.merchant.id)
                                                .collection('coupons')
                                                .get();

                                            List<DocumentSnapshot> couponDocs = couponsSnapshot.docs;

                                            // Check if a coupon with this ID still exists and that
                                            // it still has codes left to claim.
                                            for (DocumentSnapshot couponDoc in couponDocs) {
                                              if (couponDoc.id == coupon.id &&
                                                  couponDoc.get('unclaimed_codes').isNotEmpty) {
                                                // The coupon is valid
                                                // Remove the code from the merchant's unclaimed codes
                                                List<dynamic> updatedUnclaimed = couponDoc.get('unclaimed_codes');
                                                String claimedCode =
                                                    updatedUnclaimed.removeAt(0); // Remove first unclaimed code
                                                await firestore
                                                    .collection('merchants')
                                                    .doc(widget.merchant.id)
                                                    .collection('coupons')
                                                    .doc(couponDoc.id)
                                                    .update({'unclaimed_codes': updatedUnclaimed});

                                                // Add the code to the merchant's claimed codes
                                                List<dynamic> updatedClaimed = couponDoc.get('claimed_codes');
                                                updatedClaimed.add(claimedCode); // Add newly claimed code
                                                await firestore
                                                    .collection('merchants')
                                                    .doc(widget.merchant.id)
                                                    .collection('coupons')
                                                    .doc(couponDoc.id)
                                                    .update({'claimed_codes': updatedClaimed});

                                                // Add the code to the customer's coupons
                                                await firestore
                                                    .collection('customers')
                                                    .doc(AuthService.user!.uid)
                                                    .update({'coupons.${coupon.id}': claimedCode});

                                                // Update list of coupons
                                                widget.userCoupons[coupon.id] = claimedCode;
                                                await fetchMerchantCoupons();

                                                Utils.showInSnackBar(context, 'Done!');
                                                return;
                                              }
                                            }

                                            // The coupon is no longer valid so display an error
                                            Utils.showInSnackBar(context, 'Sorry, this coupon is no longer available');
                                          } catch (e, stacktrace) {
                                            Utils.showInSnackBar(context, 'Sorry, something went wrong');
                                            print('Error claiming coupon: $e\n$stacktrace');
                                          }
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  )
                  .toList()
            ],
          ),
        ),
      ),
    );
  }
}
