import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<User?> signInWithGoogle() async {
  try {
    // Start the Google Sign-In process
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    
    if (googleUser == null) {
      // If the user cancels the sign-in
      return null;
    }

    // Obtain the authentication details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential for Firebase
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the new credential
    final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    return userCredential.user;
  } catch (e) {
    print("Error during sign in with Google: $e");
    return null;
  }
}

Future<void> signOut() async {
  try {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  } catch (e) {
    print("Error during sign out: $e");
  }
}
