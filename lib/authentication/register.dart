import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kachow_mvp/authentication/login.dart';
import 'package:kachow_mvp/authentication/password_field.dart';
import 'package:kachow_mvp/pages/customer/home_customer.dart';
import 'package:kachow_mvp/utils/auth_service.dart';
import 'package:kachow_mvp/utils/constants.dart';
import 'package:kachow_mvp/utils/utils.dart';

class RegisterData {
  String email = "";
  String password = "";
  String confirmPassword = "";
  bool agreesToTerms = false;
}

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _passwordController = TextEditingController();

  bool showProgressBar = false;

  RegisterData registerData = RegisterData();
  final AuthService _authService = AuthService();

  /// Processes the submitted login form by validating the form and
  /// attempting to sign in the user.
  void _handleSubmitted() async {
    if (_formKey.currentState == null) {
      Utils.showInSnackBar(context, 'Sorry, something went wrong');
      return;
    }

    // Validate form
    final form = _formKey.currentState!;
    if (!registerData.agreesToTerms) {
      Utils.showInSnackBar(
        context,
        "You must agree to the Terms and Conditions and Privacy Policy to create an account",
      );
    } else if (form.validate()) {
      form.save();

      // Show progress bar
      setState(() {
        showProgressBar = true;
      });

      // Try to register user
      bool successfulRegistration = await _authService.registerUser(
        email: registerData.email,
        password: registerData.password,
      );
      if (successfulRegistration) {
        // Create Firestore entry for user
        Map<String, Map<String, String>> initialData = {'coupons': {}};
        FirebaseFirestore.instance.collection('customers').doc(AuthService.user!.uid).set(initialData);

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeCustomer()),
          (Route<dynamic> route) => false,
        );
      } else {
        Utils.showInSnackBar(context,
            "Error creating account. This email is invalid or already in use.");
      }

      // Hide progress bar
      setState(() {
        showProgressBar = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    key: _formKey,
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        dragStartBehavior: DragStartBehavior.down,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Page title
                            sizedBoxSpace,
                            const Center(
                              child: Text(
                                "Create account",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),

                            // Email field
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
                                  registerData.email = value!;
                                },
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
                                controller: _passwordController,
                                onSaved: (String? value) {
                                  registerData.password = value!;
                                },
                                validator: (String? value) {
                                  if (value == null || value.length < 6) {
                                    return 'Password must have at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            // Confirm password
                            sizedBoxSpace,
                            Padding(
                              padding: const EdgeInsets.only(right: 32),
                              child: PasswordField(
                                labelText: 'Confirm password',
                                onFieldSubmitted: showProgressBar
                                    ? null
                                    : (_) {
                                        _handleSubmitted();
                                      },
                                onSaved: (String? value) {
                                  registerData.confirmPassword = value!;
                                },
                                validator: (value) {
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match.';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            // Terms and Conditions and Privacy Policy checkbox
                            sizedBoxSpace,
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: CheckboxListTile(
                                activeColor: Constants.themeColor,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: const Text(
                                  "I have read and agree to the Terms and Conditions and Privacy Policy.",
                                  style: TextStyle(fontSize: 16),
                                ),
                                onChanged: (bool? value) {
                                  if (value != null) {
                                    setState(() {
                                      registerData.agreesToTerms = value;
                                    });
                                  }
                                },
                                value: registerData.agreesToTerms,
                              ),
                            ),

                            // Register button
                            sizedBoxSpace,
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: OutlinedButton(
                                onPressed:
                                    showProgressBar ? null : _handleSubmitted,
                                child: const Text("Create account"),
                              ),
                            ),

                            // Login instead button
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: TextButton(
                                onPressed: showProgressBar
                                    ? null
                                    : () {
                                        Navigator.of(context)
                                            .pushAndRemoveUntil(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const Login()),
                                          (Route<dynamic> route) => false,
                                        );
                                      },
                                child: const Text("Already have an account?"),
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
