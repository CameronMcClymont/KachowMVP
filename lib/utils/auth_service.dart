import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kachow_mvp/utils/firebase_error.dart';
import 'package:kachow_mvp/utils/utils.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static User? user; // null if no user is signed in

  /// Signs a user in given an `email` and `password`.
  ///
  /// Returns whether the sign-in was successful or not.
  Future<bool> signIn({required String email, required String password}) async {
    try {
      final UserCredential authResult =
          await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      user = authResult.user;
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  /// Registers a user in given an `email` and `password`.
  ///
  /// Returns whether the registration was successful or not.
  Future<bool> registerUser({required String email, required String password}) async {
    try {
      final UserCredential authResult =
          await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      user = authResult.user;
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  /// Signs out the currently logged in user.
  /// Assumes that a user is currently logged in.
  ///
  /// Returns whether the sign-out was successful or not.
  Future<bool> signOut() async {
    try {
      await _firebaseAuth.signOut();
      user = null;
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  /// Sends a password reset email to the given `email`.
  ///
  /// Returns whether the password-reset email was successfully sent or not.
  Future<FirebaseError?> resetPassword(BuildContext context, {required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print(e);
      if (e.toString().contains('USER_NOT_FOUND')) {
        return FirebaseError.userNotFound;
      } else if (e.toString().contains('INVALID_EMAIL')) {
        return FirebaseError.invalidEmail;
      }

      return FirebaseError.other;
    }
  }

  /// Deletes the currently signed in user from Firestore and Firebase Auth.
  ///
  /// Returns whether or not the deletion was successful.
  Future<FirebaseError?> deleteUser(String password) async {
    try {
      // Delete user entry from Firestore
      await FirebaseFirestore.instance.collection('customers').doc(user!.uid).delete();

      // Delete user from Firebase Auth
      AuthCredential credentials = EmailAuthProvider.credential(email: user!.email!, password: password);
      await user!.reauthenticateWithCredential(credentials);
      await user!.delete();
    } catch (e) {
      print(e);

      if (e.toString().contains('wrong-password')) {
        return FirebaseError.incorrectPassword;
      }

      return FirebaseError.other;
    }
  }
}
