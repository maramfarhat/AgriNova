// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthenticationProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  User? get user => _user;

  // Méthode de connexion
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      _user = userCredential.user;
      notifyListeners();
      return {'success': true, 'message': ''};
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error Code: ${e.code}');
      debugPrint('Firebase Auth Error Message: ${e.message}');

      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
        case 'INVALID_PASSWORD':
          errorMessage = 'Mot de passe incorrect.';
          break;
        case 'user-not-found':
          errorMessage = 'Aucun utilisateur trouvé avec cet email.';
          break;
        case 'invalid-email':
          errorMessage = 'L\'adresse email n\'est pas valide.';
          break;
        case 'too-many-requests':
          errorMessage =
              'Trop de tentatives de connexion. Veuillez réessayer plus tard.';
          break;
        case 'invalid-credential':
          errorMessage = 'Email ou mot de passe incorrect.';
          break;
        default:
          debugPrint('Unhandled error code: ${e.code}');
          errorMessage = 'Une erreur est survenue lors de la connexion.';
      }
      return {'success': false, 'message': errorMessage};
    } catch (e, stackTrace) {
      debugPrint('Unexpected Error: $e');
      debugPrint('StackTrace: $stackTrace');
      return {
        'success': false,
        'message': 'Une erreur est survenue lors de la connexion.'
      };
    }
  }

  // Méthode d'inscription
  Future<Map<String, dynamic>> signUp(String email, String password) async {
    try {
      List<String> methods =
          await _auth.fetchSignInMethodsForEmail(email.trim());
      if (methods.isNotEmpty) {
        return {
          'success': false,
          'message': 'Un compte existe déjà avec cet email.'
        };
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        return {'success': true, 'message': 'Inscription réussie'};
      } else {
        return {'success': false, 'message': 'Échec de l\'inscription'};
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code}');
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Un compte existe déjà avec cet email.';
          break;
        case 'invalid-email':
          errorMessage = 'L\'adresse email n\'est pas valide.';
          break;
        case 'weak-password':
          errorMessage = 'Le mot de passe doit contenir au moins 6 caractères.';
          break;
        case 'network-request-failed':
          errorMessage = 'Problème de connexion internet.';
          break;
        default:
          errorMessage = 'Une erreur est survenue lors de l\'inscription.';
      }
      return {'success': false, 'message': errorMessage};
    } catch (e, stackTrace) {
      debugPrint('Unexpected Error: $e');
      debugPrint('StackTrace: $stackTrace');
      return {
        'success': false,
        'message': 'Une erreur est survenue lors de l\'inscription.'
      };
    }
  }

  // Méthode de déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  // Gérer les erreurs d'authentification

  // Connexion avec Google
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      debugPrint('Google Sign-in User: ${userCredential.user?.email}');

      _user = userCredential.user;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error during Google sign in: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }
}
