
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void>? _googleInitialization;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authChanges => _auth.authStateChanges();

  DocumentReference<Map<String, dynamic>> _profileRef(String uid) {
    return _db.collection('users').doc(uid);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> profileChanges(
      String uid,
      ) {
    return _profileRef(uid).snapshots();
  }

  Future<UserCredential> signInWithGoogle() async {
    _googleInitialization ??= GoogleSignIn.instance.initialize();
    await _googleInitialization;

    final googleUser = await GoogleSignIn.instance.authenticate();

    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('Google did not return an ID token.');
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> createProfile({
    required String name,
    required String degree,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in with Google first.');
    }

    final cleanedName = name.trim();
    final cleanedDegree = degree.trim();

    if (cleanedName.isEmpty || cleanedDegree.isEmpty) {
      throw Exception('Name and degree are required.');
    }

    final ref = _profileRef(user.uid);

    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(ref);

      if (existing.exists) {
        throw Exception('A profile already exists.');
      }

      transaction.set(ref, {
        'uid': user.uid,
        'name': cleanedName,
        'degree': cleanedDegree,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'profileEditUsed': false,
      });
    });
  }

  Future<void> updateProfileOnce({
    required String name,
    required String degree,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in again.');
    }

    final cleanedName = name.trim();
    final cleanedDegree = degree.trim();

    if (cleanedName.isEmpty || cleanedDegree.isEmpty) {
      throw Exception('Name and degree are required.');
    }

    final ref = _profileRef(user.uid);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists) {
        throw Exception('Profile not found.');
      }

      final data = snapshot.data()!;

      if (data['profileEditUsed'] == true) {
        throw Exception('Your one profile edit has already been used.');
      }

      transaction.update(ref, {
        'name': cleanedName,
        'degree': cleanedDegree,
        'updatedAt': FieldValue.serverTimestamp(),
        'profileEditUsed': true,
      });
    });
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn.instance.signOut();
  }
}
