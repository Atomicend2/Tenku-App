import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    // Check username uniqueness
    final usernameQuery = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .get();
    if (usernameQuery.docs.isNotEmpty) {
      throw Exception('Username already taken');
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await cred.user!.sendEmailVerification();
    await cred.user!.updateDisplayName(displayName);

    final userModel = UserModel(
      uid: cred.user!.uid,
      email: email,
      username: username.toLowerCase(),
      displayName: displayName,
      createdAt: DateTime.now(),
      isOnline: true,
    );

    await _firestore
        .collection('users')
        .doc(cred.user!.uid)
        .set(userModel.toMap());

    return cred;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _updateOnlineStatus(true);
    return cred;
  }

  Future<void> signOut() async {
    await _updateOnlineStatus(false);
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Stream<UserModel?> getUserProfileStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
    await _firestore.collection('users').doc(uid).update(updates);
    if (displayName != null) {
      await _auth.currentUser?.updateDisplayName(displayName);
    }
  }
}
