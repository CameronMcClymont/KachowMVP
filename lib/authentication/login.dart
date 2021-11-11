import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kachow_mvp/authentication/password_field.dart';
import 'package:kachow_mvp/authentication/register.dart';
import 'package:kachow_mvp/main.dart';
import 'package:kachow_mvp/pages/customer/home_customer.dart';
import 'package:kachow_mvp/pages/merchant/home_merchant.dart';
import 'package:kachow_mvp/utils/auth_service.dart';
import 'package:kachow_mvp/utils/constants.dart';
import 'package:kachow_mvp/utils/firebase_error.dart';
import 'package:kachow_mvp/utils/utils.dart';

class LoginData {
  String email = '';
  String password = '';
}

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // Form keys
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _passwordResetFormKey = GlobalKey<FormState>();

  bool showProgressBar = false;

  late String passwordResetEmail;
  LoginData loginData = LoginData();
  final AuthService _authService = AuthService();

  /// Processes the submitted login form by validating the form and
  /// attempting to sign in the user.
  void _handleSubmitted() async {
    if (_loginFormKey.currentState == null) {
      Utils.showInSnackBar(context, 'Sorry, something went wrong');
      return;
    }

    // Validate form
    final form = _loginFormKey.currentState!;
    if (form.validate()) {
      form.save();

      // Show progress bar
      setState(() {
        showProgressBar = true;
      });

      // Try to sign in user
      bool successfulSignIn = await _authService.signIn(
        email: loginData.email,
        password: loginData.password,
      );
      if (successfulSignIn) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => Kachow.staticMerchantIds.contains(AuthService.user!.uid)
                  ? const HomeMerchant()
                  : const HomeCustomer()),
          (Route<dynamic> route) => false,
        );
      } else {
        Utils.showInSnackBar(context, "Account with this email and password doesn't exist");
      }

      // Hide progress bar
      setState(() {
        showProgressBar = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cursorColor = Theme.of(context).textSelectionTheme.cursorColor;
    const sizedBoxSpace = SizedBox(height: 24);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 32,
                  right: 32,
                  top: 72,
                  bottom: 48,
                ),
                child: Image.asset('assets/images/logo.png'),
              ),
              Card(
                child: SizedBox(
                  width: 500,
                  child: Form(
                    key: _loginFormKey,
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        dragStartBehavior: DragStartBehavior.down,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Login title
                            sizedBoxSpace,
                            const Center(
                              child: Text(
                                "Login",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),

                            // Email
                            sizedBoxSpace,
                            Padding(
                              padding: const EdgeInsets.only(right: 32),
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  filled: true,
                                  icon: Icon(Icons.email),
                                  hintText: "Your email address",
                                  labelText: "Email",
                                ),
                                keyboardType: TextInputType.emailAddress,
                                onSaved: (String? value) {
                                  loginData.email = value!;
                                },
                                textInputAction: TextInputAction.go,
                                validator: (String? value) {
                                  if (value == null || value.isEmpty) {
                                    return "Email cannot be empty";
                                  } else if (!value.contains("@")) {
                                    return "Email is not valid";
                                  }
                                  return null;
                                },
                              ),
                            ),

                            // Password
                            sizedBoxSpace,
                            Padding(
                              padding: const EdgeInsets.only(right: 32),
                              child: PasswordField(
                                labelText: "Password",
                                hintText: 'Your password',
                                onFieldSubmitted: showProgressBar
                                    ? null
                                    : (_) {
                                        _handleSubmitted();
                                      },
                                onSaved: (String? value) {
                                  loginData.password = value!;
                                },
                                validator: (String? value) {
                                  if (value == null || value.isEmpty) {
                                    return "Password cannot be empty";
                                  }
                                  return null;
                                },
                              ),
                            ),

                            // Forgot password
                            Padding(
                              padding: const EdgeInsets.only(left: 40, right: 32),
                              child: TextButton(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                            title: const Text("Password reset"),
                                            content: Form(
                                              key: _passwordResetFormKey,
                                              child: TextFormField(
                                                cursorColor: cursorColor,
                                                decoration: const InputDecoration(
                                                    filled: true, labelText: "Email", hintText: "Enter your email"),
                                                keyboardType: TextInputType.emailAddress,
                                                onSaved: (String? value) {
                                                  passwordResetEmail = value!;
                                                },
                                                validator: (String? value) {
                                                  if (value == null || value.isEmpty) {
                                                    return "Email cannot be empty";
                                                  } else if (!value.contains("@")) {
                                                    return "Email is invalid";
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
                                                child: const Text('Send'),
                                                onPressed: () async {
                                                  if (_passwordResetFormKey.currentState == null) {
                                                    Utils.showInSnackBar(context, 'Sorry, something went wrong');
                                                    return;
                                                  }

                                                  final form = _passwordResetFormKey.currentState!;
                                                  if (form.validate()) {
                                                    form.save();
                                                    FirebaseError? error = await _authService.resetPassword(
                                                      context,
                                                      email: passwordResetEmail,
                                                    );

                                                    if (error == null) {
                                                      Utils.showInSnackBar(context, 'Email sent! Please allow a few minutes for the email to come through');
                                                    } else {
                                                      switch (error) {
                                                        case FirebaseError.userNotFound:
                                                          Utils.showInSnackBar(context, "An account linked to that email doesn't exist");
                                                          break;
                                                        case FirebaseError.invalidEmail:
                                                          Utils.showInSnackBar(context, 'The email provided was incorrectly formatted');
                                                          break;
                                                        default:
                                                          Utils.showInSnackBar(context, 'Sorry, something went wrong');
                                                      }
                                                    }

                                                    Navigator.of(context).pop();
                                                  }
                                                },
                                              ),
                                            ],
                                          ));
                                },
                                child: const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text("Forgot password?"),
                                ),
                              ),
                            ),

                            // Login button
                            sizedBoxSpace,
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: OutlinedButton(
                                onPressed: showProgressBar ? null : _handleSubmitted,
                                child: const Text("Log in"),
                              ),
                            ),

                            // Register instead button
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: TextButton(
                                onPressed: showProgressBar
                                    ? null
                                    : () {
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(builder: (context) => const Register()),
                                          (Route<dynamic> route) => false,
                                        );
                                      },
                                child: const Text("Don't have an account?"),
                              ),
                            ),

                            // Progress bar
                            sizedBoxSpace,
                            Visibility(
                              visible: showProgressBar,
                              child: Constants.loadingIndicator,
                            ),

                            sizedBoxSpace,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
