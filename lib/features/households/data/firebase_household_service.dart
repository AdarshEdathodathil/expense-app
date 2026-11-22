import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/core/currency/currency_option.dart';
import 'package:expense_tracker/features/households/domain/household.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

/// Owns authentication, household creation, and invitation acceptance.
///
/// Invitation acceptance uses one atomic batch. The Firestore rules require
/// both the invitation acceptance and member creation to succeed together.
class FirebaseHouseholdService {
  FirebaseHouseholdService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  Stream<User?> watchAuthState() => _auth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null || user.emailVerified) return;
    await user.sendEmailVerification();
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(displayName.trim());
    await user.sendEmailVerification();
    await _firestore.collection('users').doc(user.uid).set({
      'displayName': displayName.trim(),
      'email': normalizedEmail,
      'activeHouseholdId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return credential;
  }

  Stream<String?> watchActiveHouseholdId(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['activeHouseholdId'] as String?);
  }

  Stream<int> watchMonthlyBudget(String householdId) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.data()?['monthlyBudgetMinor'] as int? ?? 6000000,
        );
  }

  Stream<String> watchDefaultCurrency(String householdId) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .snapshots()
        .map(
          (snapshot) => snapshot.data()?['defaultCurrency'] as String? ?? 'INR',
        );
  }

  Stream<String> watchHouseholdName(String householdId) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .snapshots()
        .map(
          (snapshot) => snapshot.data()?['name'] as String? ?? 'Our household',
        );
  }

  Future<void> updateMonthlyBudget({
    required String householdId,
    required int amountMinor,
  }) {
    if (amountMinor <= 0) throw ArgumentError.value(amountMinor);
    return _firestore.collection('households').doc(householdId).update({
      'monthlyBudgetMinor': amountMinor,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateDefaultCurrency({
    required String householdId,
    required String currency,
  }) {
    if (!supportedCurrencies.any((option) => option.code == currency)) {
      throw ArgumentError.value(currency, 'currency');
    }
    return _firestore.collection('households').doc(householdId).update({
      'defaultCurrency': currency,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<String>> watchCustomCategories({
    required String householdId,
    required String transactionType,
  }) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .collection('categories')
        .where('type', isEqualTo: transactionType)
        .snapshots()
        .map((snapshot) {
          final names = snapshot.docs
              .map((document) => document.data()['name'] as String)
              .toList();
          names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
          return names;
        });
  }

  Future<void> createCustomCategory({
    required String householdId,
    required String transactionType,
    required String name,
  }) {
    final user = _requireUser();
    final normalizedName = name.trim();
    final safeId = normalizedName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final documentId = '${transactionType}_$safeId';
    return _firestore
        .collection('households')
        .doc(householdId)
        .collection('categories')
        .doc(documentId)
        .set({
          'name': normalizedName,
          'type': transactionType,
          'createdBy': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<String> createHouseholdForCurrentUser({
    required String householdName,
  }) async {
    final user = _requireUser();
    final householdRef = _firestore.collection('households').doc();
    final userRef = _firestore.collection('users').doc(user.uid);
    final memberRef = householdRef.collection('members').doc(user.uid);
    final batch = _firestore.batch();
    final displayName =
        user.displayName ?? user.email?.split('@').first ?? 'Owner';

    batch.set(householdRef, {
      'name': householdName.trim(),
      'ownerId': user.uid,
      'defaultCurrency': 'INR',
      'monthlyBudgetMinor': 6000000,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(memberRef, {
      'userId': user.uid,
      'displayName': displayName,
      'email': user.email?.toLowerCase(),
      'role': 'owner',
      'status': 'active',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.set(userRef, {
      'displayName': displayName,
      'email': user.email?.toLowerCase(),
      'activeHouseholdId': householdRef.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
    return householdRef.id;
  }

  Future<String> createOwnerAccount({
    required String email,
    required String password,
    required String displayName,
    required String householdName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(displayName.trim());

    final householdRef = _firestore.collection('households').doc();
    final userRef = _firestore.collection('users').doc(user.uid);
    final memberRef = householdRef.collection('members').doc(user.uid);
    final batch = _firestore.batch();

    batch.set(householdRef, {
      'name': householdName.trim(),
      'ownerId': user.uid,
      'defaultCurrency': 'INR',
      'monthlyBudgetMinor': 6000000,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(memberRef, {
      'userId': user.uid,
      'displayName': displayName.trim(),
      'email': email.trim().toLowerCase(),
      'role': 'owner',
      'status': 'active',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.set(userRef, {
      'displayName': displayName.trim(),
      'email': email.trim().toLowerCase(),
      'activeHouseholdId': householdRef.id,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return householdRef.id;
  }

  Future<HouseholdInvitation> createInvitation({
    required String householdId,
    required String invitedEmail,
  }) async {
    final user = _requireUser();
    final code = const Uuid()
        .v4()
        .replaceAll('-', '')
        .substring(0, 10)
        .toUpperCase();
    final expiresAt = DateTime.now().toUtc().add(const Duration(days: 7));

    await _firestore.collection('invites').doc(code).set({
      'householdId': householdId,
      'invitedEmail': invitedEmail.trim().toLowerCase(),
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'acceptedBy': null,
      'acceptedAt': null,
    });

    return HouseholdInvitation(
      code: code,
      householdId: householdId,
      invitedEmail: invitedEmail.trim().toLowerCase(),
      expiresAt: expiresAt,
    );
  }

  Future<String> acceptInvitation({required String code}) async {
    final user = _requireUser();
    final normalizedCode = code.trim().toUpperCase();
    final inviteRef = _firestore.collection('invites').doc(normalizedCode);
    final inviteSnapshot = await inviteRef.get();
    if (!inviteSnapshot.exists) {
      throw StateError('Invitation not found.');
    }

    final invite = inviteSnapshot.data()!;
    final householdId = invite['householdId'] as String;
    final expiresAt = (invite['expiresAt'] as Timestamp).toDate();
    if (expiresAt.isBefore(DateTime.now().toUtc())) {
      throw StateError('This invitation has expired.');
    }

    final householdRef = _firestore.collection('households').doc(householdId);
    final memberRef = householdRef.collection('members').doc(user.uid);
    final userRef = _firestore.collection('users').doc(user.uid);
    final batch = _firestore.batch();

    batch.update(inviteRef, {
      'acceptedBy': user.uid,
      'acceptedAt': FieldValue.serverTimestamp(),
    });
    batch.set(memberRef, {
      'userId': user.uid,
      'displayName':
          user.displayName ?? user.email?.split('@').first ?? 'Member',
      'email': user.email?.toLowerCase(),
      'role': 'member',
      'status': 'active',
      'acceptedInviteId': normalizedCode,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.set(userRef, {
      'displayName':
          user.displayName ?? user.email?.split('@').first ?? 'Member',
      'email': user.email?.toLowerCase(),
      'activeHouseholdId': householdId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
    return householdId;
  }

  Stream<List<HouseholdMember>> watchMembers(String householdId) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .collection('members')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((document) {
            final data = document.data();
            return HouseholdMember(
              userId: document.id,
              displayName: data['displayName'] as String,
              email: data['email'] as String,
              role: data['role'] == 'owner'
                  ? HouseholdRole.owner
                  : HouseholdRole.member,
              joinedAt:
                  (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList(),
        );
  }

  Stream<HouseholdMember?> watchMember({
    required String householdId,
    required String userId,
  }) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .collection('members')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null || data['status'] != 'active') return null;
          return HouseholdMember(
            userId: snapshot.id,
            displayName: data['displayName'] as String,
            email: data['email'] as String,
            role: data['role'] == 'owner'
                ? HouseholdRole.owner
                : HouseholdRole.member,
            joinedAt:
                (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        });
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    return user;
  }
}
