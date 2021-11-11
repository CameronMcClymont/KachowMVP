import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a merchant from the 'merchants' collection in Firestore.
class Merchant {
  String id;
  String name;
  String address;
  Map<String, String> hours;
  String? downloadUrl;

  Merchant(
      {required this.id,
      required this.name,
      required this.address,
      required this.hours});

  static Merchant fromFirestore(DocumentSnapshot snapshot) {
    // Cast hours from Map<String, dynamic> to Map<String, String>
    Map<String, String> castedHours = {};
    for (var entry in snapshot.get('hours').entries) {
      castedHours[entry.key] = entry.value.toString();
    }

    return Merchant(
      id: snapshot.id,
      name: snapshot.get('name'),
      address: snapshot.get('address'),
      hours: castedHours,
    );
  }
}
