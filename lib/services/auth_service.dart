import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current Firebase User
  User? get currentUser => _auth.currentUser;

  // Fetch full UserModel for current user
  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUserProfile(user.uid);
  }

  // Fetch user profile by UID
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(AppConstants.collectionUsers).doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }
  
  // Register a new Student account (Role is strictly locked to 'student')
  Future<UserModel> registerStudent({
    required String name,
    required String email,
    required String password,
    required String studentId,
    required String hostel,
    required String roomNumber,
    String? phone,
  }) async {
    try {
      // 1. Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      // 2. Create UserModel strictly with role = 'student'
      final userModel = UserModel(
        uid: uid,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        studentId: studentId.trim().toUpperCase(),
        hostel: hostel.trim(),
        roomNumber: roomNumber.trim(),
        role: AppConstants.roleStudent,
        createdAt: DateTime.now(),
        phone: phone?.trim(),
      );

      // 3. Save to Firestore
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred during registration. Please try again.';
    }
  }

  // Sign In with Email & Password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      final userModel = await getUserProfile(uid);

      if (userModel == null) {
        throw 'User profile not found. Please contact administration.';
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is String) rethrow;
      throw 'Unable to sign in. Please verify your credentials and network connection.';
    }
  }

  // Update permitted profile fields for student
  Future<void> updateStudentProfile({
    required String uid,
    required String name,
    required String hostel,
    required String roomNumber,
    String? phone,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'name': name.trim(),
        'hostel': hostel.trim(),
        'roomNumber': roomNumber.trim(),
      };
      if (phone != null) {
        updateData['phone'] = phone.trim();
      }

      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .update(updateData);
    } catch (e) {
      throw 'Failed to update profile. Please try again.';
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Translate FirebaseAuth errors to human readable strings
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak. Must be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled by an administrator.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication error. Please try again.';
    }
  }
}
