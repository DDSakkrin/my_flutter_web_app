import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final Logger _logger = Logger('AuthService');

  Future<User?> signInWithGoogle() async {
    try {
      _logger.info('Starting Google Sign-In process');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _logger.info('Google Sign-In cancelled by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      _logger.info('Successfully signed in with Google: ${userCredential.user}');
      return userCredential.user;
    } catch (e) {
      _logger.severe('Error during sign in with Google: $e');
      return null;
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      _logger.info('Signing out from Google and Firebase');
      await _googleSignIn.signOut();
      await _auth.signOut();

      // Navigate back to the login page after signing out
      Navigator.of(context).pushReplacementNamed('/login');
      _logger.info('Successfully signed out');
    } catch (e) {
      _logger.severe('Error during sign out: $e');
      // Optionally, you can show a dialog or snackbar here to inform the user of the error
      _showErrorDialog(context, 'Error during sign out: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sign-Out Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
