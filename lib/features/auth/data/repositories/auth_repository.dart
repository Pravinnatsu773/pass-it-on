import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Get the current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (!_googleSignIn.supportsAuthenticate()) {
        throw Exception('Google sign-in is not supported on this platform.');
      }

      // 1. Trigger the native Google Authentication flow
      final GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.authenticate();
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          return null; // User canceled
        }
        rethrow;
      }

      if (googleUser == null) {
        return null;
      }

      // 2. Obtain the auth details
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 3. Create a new credential with ONLY the idToken
      // (accessToken is handled internally in google_sign_in 7.0.0+)
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase
      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
  /// Get UserModel from Firestore
  Future<UserModel?> getUserModel(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user model: $e');
      return null;
    }
  }

  /// Save UserModel to Firestore
  Future<void> saveUserModel(UserModel userModel) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userModel.id).set(userModel.toJson());
    } catch (e) {
      debugPrint('Error saving user model: $e');
      rethrow;
    }
  }

  /// Upload Profile Picture to Firebase Storage
  Future<String> uploadProfilePicture(String uid, File imageFile) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('profile_pictures').child('$uid.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      rethrow;
    }
  }

  /// Toggle Saved Product for a user
  Future<void> toggleSavedProduct(String uid, String productId, bool save) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      if (save) {
        await userRef.update({
          'savedProducts': FieldValue.arrayUnion([productId])
        });
      } else {
        await userRef.update({
          'savedProducts': FieldValue.arrayRemove([productId])
        });
      }
    } catch (e) {
      debugPrint('Error toggling saved product: $e');
      rethrow;
    }
  }
}
