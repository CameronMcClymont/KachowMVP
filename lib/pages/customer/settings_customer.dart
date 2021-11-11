import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kachow_mvp/authentication/login.dart';
import 'package:kachow_mvp/authentication/password_field.dart';
import 'package:kachow_mvp/utils/auth_service.dart';
import 'package:kachow_mvp/utils/firebase_error.dart';
import 'package:kachow_mvp/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Setting extends StatelessWidget {
  final IconData iconData;
  final String title;
  final SharedPreferences prefs;
  final String prefKey;
  final Function() onChanged;
  final List<Widget> children;
  final bool isRed;

  const Setting(
      {Key? key,
      required this.iconData,
      required this.title,
      required this.prefs,
      required this.prefKey,
      required this.onChanged,
      required this.children,
      this.isRed = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: InkWell(
        onTap: onChanged,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(iconData, color: isRed ? Colors.red : null),
              const SizedBox(width: 24),
              Text(title, style: isRed ? const TextStyle(color: Colors.red) : null),
              const Spacer(),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class SwitchSetting extends StatefulWidget {
  final IconData iconData;
  final String title;
  final SharedPreferences prefs;
  final String prefKey;
  final Function() onChanged;
  final bool defaultValue;

  const SwitchSetting(
      {Key? key,
      required this.iconData,
      required this.title,
      required this.prefs,
      required this.prefKey,
      required this.onChanged,
      required this.defaultValue})
      : super(key: key);

  @override
  _SwitchSettingState createState() => _SwitchSettingState();
}

class _SwitchSettingState extends State<SwitchSetting> {
  @override
  Widget build(BuildContext context) {
    return Setting(
      iconData: widget.iconData,
      title: widget.title,
      prefs: widget.prefs,
      prefKey: widget.prefKey,
      onChanged: () {
        setState(() {
          widget.prefs.setBool(widget.prefKey, !(widget.prefs.getBool(widget.prefKey) ?? widget.defaultValue));
        });
        widget.onChanged();
      },
      children: [
        Switch(
          activeColor: Theme.of(context).colorScheme.primary,
          value: widget.prefs.getBool(widget.prefKey) ?? widget.defaultValue,
          onChanged: (bool value) {
            setState(() {
              widget.prefs.setBool(widget.prefKey, value);
            });
            widget.onChanged();
          },
        ),
      ],
    );
  }
}

class SettingsCustomer extends StatefulWidget {
  static const String someSettingKey = 'some_setting_key';

  const SettingsCustomer({Key? key}) : super(key: key);

  @override
  _SettingsCustomerState createState() => _SettingsCustomerState();
}

class _SettingsCustomerState extends State<SettingsCustomer> {
  SharedPreferences? prefs;
  final TextEditingController _passwordController = TextEditingController();
  bool accountDeletionInProgress = false;

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
                SwitchSetting(
                  iconData: Icons.settings,
                  title: 'Some setting',
                  prefs: prefs!,
                  prefKey: SettingsCustomer.someSettingKey,
                  onChanged: () {},
                  defaultValue: true,
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
                Setting(
                  iconData: Icons.delete_forever,
                  title: 'Delete account',
                  isRed: true,
                  prefs: prefs!,
                  prefKey: '',
                  onChanged: () async {
                    // Reset form field text
                    _passwordController.text = '';

                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete account'),
                        content: PasswordField(controller: _passwordController),
                        actions: accountDeletionInProgress
                            ? []
                            : [
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: const Text('Delete forever'),
                                  onPressed: () async {
                                    setState(() {
                                      accountDeletionInProgress = true;
                                    });
                                    Utils.showInSnackBar(context, 'Please wait...');
                                    FirebaseError? error = await AuthService().deleteUser(_passwordController.text);

                                    if (error == null) {
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (context) => const Login()),
                                        (Route<dynamic> route) => false,
                                      );
                                    } else {
                                      switch (error) {
                                        case FirebaseError.incorrectPassword:
                                          Utils.showInSnackBar(context, 'The password entered was incorrect.');
                                          break;
                                        default:
                                          Utils.showInSnackBar(context, 'Sorry, something went wrong.');
                                      }
                                      setState(() {
                                        accountDeletionInProgress = false;
                                      });
                                    }
                                  },
                                ),
                              ],
                      ),
                    );
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
