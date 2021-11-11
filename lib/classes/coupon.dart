import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a coupon from the 'merchants' collection in Firestore.
class Coupon {
  final String id;
  String name;
  double value;
  final List<String> claimedCodes;
  final List<String> unclaimedCodes;

  Coupon(
      {required this.id,
      required this.name,
      required this.value,
      required this.claimedCodes,
      required this.unclaimedCodes});

  static Coupon fromFirestore(DocumentSnapshot snapshot) {
    List<String> claimedCodes = [];
    List<String> unclaimedCodes = [];

    for (dynamic code in snapshot.get('claimed_codes')) {
      claimedCodes.add(code.toString());
    }
    for (dynamic code in snapshot.get('unclaimed_codes')) {
      unclaimedCodes.add(code.toString());
    }

    return Coupon(
      id: snapshot.id,
      name: snapshot.get('name'),
      value: snapshot.get('value'),
      claimedCodes: claimedCodes,
      unclaimedCodes: unclaimedCodes,
    );
  }
}
