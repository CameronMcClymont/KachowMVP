import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kachow_mvp/authentication/login.dart';
import 'package:kachow_mvp/classes/merchant.dart';
import 'package:kachow_mvp/pages/customer/settings_customer.dart';
import 'package:kachow_mvp/utils/auth_service.dart';
import 'package:kachow_mvp/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsMerchant extends StatefulWidget {
  final Merchant merchant;

  const SettingsMerchant({required this.merchant, Key? key}) : super(key: key);

  @override
  _SettingsMerchantState createState() => _SettingsMerchantState();
}

class _SettingsMerchantState extends State<SettingsMerchant> {
  static const nameMaxChars = 50;
  static const addressMaxChars = 75;

  SharedPreferences? prefs;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final GlobalKey<FormState> _nameKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _addressKey = GlobalKey<FormState>();

  getSharedPrefs() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      prefs = sharedPreferences;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      getSharedPrefs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: prefs != null
          ? Column(
              children: [
                ListTile(
                  title: const Text('Edit name'),
                  subtitle: Text(widget.merchant.name),
                  onTap: () {
                    // Show edit name dialog
                    showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              title: const Text('Edit name'),
                              content: Form(
                                key: _nameKey,
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    filled: true,
                                    labelText: 'Merchant name',
                                  ),
                                  initialValue: widget.merchant.name,
                                  onSaved: (String? value) {
                                    widget.merchant.name = value!;
                                  },
                                  validator: (String? value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Name cannot be empty';
                                    } else if (value.length > nameMaxChars) {
                                      return 'Name is too long';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              actions: [
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: const Text('Save'),
                                  onPressed: () async {
                                    if (_nameKey.currentState == null) {
                                      Utils.showInSnackBar(context, 'Sorry, something went wrong');
                                      return;
                                    }

                                    final form = _nameKey.currentState!;
                                    if (form.validate()) {
                                      Utils.showInSnackBar(context, 'Updating...');

                                      setState(() {
                                        form.save();
                                      });

                                      await firestore
                                          .collection('merchants')
                                          .doc(widget.merchant.id)
                                          .update({'name': widget.merchant.name});

                                      Utils.showInSnackBar(context, 'Done!');
                                      Navigator.of(context).pop();
                                    }
                                  },
                                ),
                              ],
                            ));
                  },
                ),
                ListTile(
                  title: const Text('Edit address'),
                  subtitle: Text(widget.merchant.address),
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              title: const Text('Edit address'),
                              content: Form(
                                key: _addressKey,
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    filled: true,
                                    labelText: 'Merchant address',
                                  ),
                                  initialValue: widget.merchant.address,
                                  onSaved: (String? value) {
                                    widget.merchant.address = value!;
                                  },
                                  validator: (String? value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Address cannot be empty';
                                    } else if (value.length > addressMaxChars) {
                                      return 'Address is too long';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              actions: [
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: const Text('Save'),
                                  onPressed: () async {
                                    if (_addressKey.currentState == null) {
                                      Utils.showInSnackBar(context, 'Sorry, something went wrong');
                                      return;
                                    }

                                    final form = _addressKey.currentState!;
                                    if (form.validate()) {
                                      Utils.showInSnackBar(context, 'Updating...');

                                      setState(() {
                                        form.save();
                                      });

                                      await firestore
                                          .collection('merchants')
                                          .doc(widget.merchant.id)
                                          .update({'address': widget.merchant.address});

                                      Utils.showInSnackBar(context, 'Done!');
                                      Navigator.of(context).pop();
                                    }
                                  },
                                ),
                              ],
                            ));
                  },
                ),
                Setting(
                  iconData: Icons.logout,
                  title: 'Log out',
                  prefs: prefs!,
                  prefKey: '',
                  onChanged: () async {
                    bool success = await AuthService().signOut();

                    if (success) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const Login()),
                        (Route<dynamic> route) => false,
                      );
                    } else {
                      Utils.showInSnackBar(context, 'Failed to sign out');
                    }
                  },
                  children: const [],
                ),
                const Spacer(),
                Builder(
                  builder: (_) {
                    User? user = AuthService.user;

                    if (user != null && user.email != null) {
                      return ListTile(
                        title: Text(user.email!),
                        subtitle: Text(user.uid),
                        onTap: () {
                          HapticFeedback.vibrate();
                          Clipboard.setData(ClipboardData(text: user.uid));
                          Utils.showInSnackBar(context, 'ID copied to clipboard!');
                        },
                      );
                    } else {
                      return const ListTile(
                        title: Text('Error: please sign in again.'),
                      );
                    }
                  },
                ),
              ],
            )
          : const Center(child: Text("Couldn't fetch user settings.")),
    );
  }
}
