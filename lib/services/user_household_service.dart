import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Handles authenticated user identity and household bootstrapping.
///
/// Data shape created/maintained:
/// - users/{uid}
/// - households/{householdId}
/// - households/{householdId}/members/{uid}
/// - households/{householdId}/subscriptions/current
/// - households/{householdId}/payments/payment_profile
class UserHouseholdService {
  UserHouseholdService._();
  static final UserHouseholdService instance = UserHouseholdService._();

  static const String _fallbackUserId = 'local_debug_user';
  static const String _fallbackHouseholdId = 'local_debug_household';
  static const String _roleOwner = 'owner';
  static const String _roleAdmin = 'admin';
  static const String _roleMember = 'member';
  static const String _roleNone = 'none';
  static const Set<String> _assignableRoles = {
    _roleOwner,
    _roleAdmin,
    _roleMember,
  };

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  bool _isInitialized = false;
  bool _firebaseEnabled = false;
  String _userId = _fallbackUserId;
  String _householdId = _fallbackHouseholdId;
  String _memberRole = _roleOwner;

  bool get isFirebaseEnabled => _firebaseEnabled;
  String get userId => _userId;
  String get householdId => _householdId;
  String get memberRole => _memberRole;
  bool get isAuthenticated => _firebaseEnabled && _userId != _fallbackUserId;
  bool get isOwner => _memberRole == _roleOwner;
  bool get isAdmin => _memberRole == _roleAdmin;
  bool get canManageMembers => isOwner || isAdmin;
  bool get canManageHousehold => canManageMembers;

  @visibleForTesting
  void setAuthAndFirestoreForTesting({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    String? testUserId,
    String? testHouseholdId,
  }) {
    _auth = auth;
    _firestore = firestore;
    _firebaseEnabled = true;
    _isInitialized = true;
    if (testUserId != null) {
      _userId = testUserId;
    }
    if (testHouseholdId != null) {
      _householdId = testHouseholdId;
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (Firebase.apps.isEmpty) return;

    try {
      _auth ??= FirebaseAuth.instance;
      _firestore ??= FirebaseFirestore.instance;
      final user = await _ensureAuthenticatedUser();
      if (user == null) {
        if (!_firebaseEnabled) _firebaseEnabled = false;
        return;
      }

      // We only update `_userId` if it matches fallback or was not set by tests
      if (_userId == _fallbackUserId) {
        _userId = user.uid;
      }

      await _ensureUserAndHouseholdDocuments(user);
      _firebaseEnabled = true;
    } catch (_) {
      if (!_firebaseEnabled) _firebaseEnabled = false;
    }
  }

  Future<void> refreshCurrentMemberRoleFromCloud() async {
    if (!_firebaseEnabled) return;

    final memberSnapshot = await _firestore!
        .collection('households')
        .doc(_householdId)
        .collection('members')
        .doc(_userId)
        .get();
    final role = memberSnapshot.data()?['role'] as String?;
    if (role != null) {
      _memberRole = _normalizeRole(role);
    }
  }

  Future<User?> _ensureAuthenticatedUser() async {
    final auth = _auth!;
    final currentUser = auth.currentUser;
    if (currentUser != null) return currentUser;

    try {
      final credential = await auth.signInAnonymously();
      final signedInUser = credential.user;
      if (signedInUser == null) {
        debugPrint(
          'Firebase auth returned null user for anonymous sign-in; '
          'falling back to local-only mode.',
        );
        return null;
      }
      return signedInUser;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Anonymous auth failed (${e.code}): ${e.message}. '
        'Falling back to local-only mode.',
      );
      return null;
    } catch (e) {
      debugPrint(
        'Anonymous auth failed with unexpected error: $e. '
        'Falling back to local-only mode.',
      );
      return null;
    }
  }

  Future<void> _ensureUserAndHouseholdDocuments(User user) async {
    final firestore = _firestore!;
    final users = firestore.collection('users');

    final userRef = users.doc(user.uid);
    final userSnapshot = await userRef.get();
    final userData = userSnapshot.data();

    // If testing has forcefully injected household Id via TestSeeder, use it
    String? existingHouseholdId = userData?['primaryHouseholdId'] as String?;

    // Fallback to currently configured testing ID if the cloud doc isn't immediately ready
    if (existingHouseholdId == null || existingHouseholdId.isEmpty) {
      if (_householdId != _fallbackHouseholdId) {
        existingHouseholdId = _householdId;
      }
    }

    if (existingHouseholdId != null && existingHouseholdId.isNotEmpty) {
      final householdRef = firestore
          .collection('households')
          .doc(existingHouseholdId);
      final householdSnapshot = await householdRef.get();
      if (householdSnapshot.exists) {
        final memberSnapshot = await householdRef
            .collection('members')
            .doc(user.uid)
            .get();
        if (memberSnapshot.exists) {
          final existingRole = memberSnapshot.data()?['role'] as String?;
          final role = _normalizeRole(existingRole);
          _householdId = existingHouseholdId;
          _memberRole = role;
          await userRef.set(
            _buildUserProfileData(
              user: user,
              primaryHouseholdId: existingHouseholdId,
              role: role,
              includeCreatedAt: false,
            ),
            SetOptions(merge: true),
          );
          return;
        }
      }
    }

    await _provisionPersonalHousehold(
      user: user,
      userRef: userRef,
      includeUserCreatedAt: !userSnapshot.exists,
    );
  }

  Future<void> _provisionPersonalHousehold({
    required User user,
    required DocumentReference<Map<String, dynamic>> userRef,
    required bool includeUserCreatedAt,
  }) async {
    final firestore = _firestore!;
    final householdRef = firestore.collection('households').doc();
    final householdId = householdRef.id;
    final inviteCode = _generateInviteCode(seed: householdId);
    await householdRef.set(
      _buildHouseholdData(
        householdId: householdId,
        ownerUserId: user.uid,
        householdName: _defaultHouseholdName(user),
        inviteCode: inviteCode,
      ),
    );
    await householdRef
        .collection('members')
        .doc(user.uid)
        .set(_buildHouseholdMemberData(user: user, role: _roleOwner));
    await householdRef
        .collection('subscriptions')
        .doc('current')
        .set(_buildDefaultSubscriptionData());
    await householdRef
        .collection('payments')
        .doc('payment_profile')
        .set(_buildDefaultPaymentProfileData());
    await userRef.set(
      _buildUserProfileData(
        user: user,
        primaryHouseholdId: householdId,
        role: _roleOwner,
        includeCreatedAt: includeUserCreatedAt,
      ),
      SetOptions(merge: true),
    );

    _householdId = householdId;
    _memberRole = _roleOwner;
  }

  Future<void> joinHousehold(
    String householdId, {
    required String inviteCode,
    String role = _roleMember,
  }) async {
    if (!_firebaseEnabled) return;

    final firestore = _firestore!;
    final householdRef = firestore.collection('households').doc(householdId);
    final householdSnapshot = await householdRef.get();
    if (!householdSnapshot.exists) {
      throw StateError('Household does not exist.');
    }
    final householdData = householdSnapshot.data();
    final expectedInviteCode = householdData?['inviteCode'] as String?;
    if (expectedInviteCode == null || expectedInviteCode != inviteCode) {
      throw StateError('Invalid household invite code.');
    }

    final memberRef = householdRef.collection('members').doc(_userId);
    final memberSnapshot = await memberRef.get();
    final existingRole = memberSnapshot.data()?['role'] as String?;
    final roleToWrite = existingRole == null
        ? _roleMember
        : _normalizeRole(existingRole);
    final memberData = _buildHouseholdMemberData(
      user: _auth!.currentUser!,
      role: roleToWrite,
    )..['inviteCode'] = inviteCode;

    final batch = firestore.batch();
    final sanitizedJoinRole = role.trim().toLowerCase();
    if (sanitizedJoinRole != _roleMember) {
      debugPrint(
        'Ignoring requested role "$role" during join. '
        'New members are always assigned "$_roleMember".',
      );
    }
    batch.set(memberRef, memberData, SetOptions(merge: true));
    batch.set(firestore.collection('users').doc(_userId), {
      'primaryHouseholdId': householdId,
      'role': roleToWrite,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSignInAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();

    _householdId = householdId;
    _memberRole = roleToWrite;
  }

  Future<String?> rotateHouseholdInviteCode() async {
    if (!_firebaseEnabled) return null;
    await _requireHouseholdAdminRole();

    final code = _generateInviteCode(seed: _householdId);
    await _firestore!.collection('households').doc(_householdId).set({
      'inviteCode': code,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return code;
  }

  Future<Map<String, dynamic>?> readCurrentUserFromCloud() async {
    if (!_firebaseEnabled) return null;
    final snapshot = await _firestore!.collection('users').doc(_userId).get();
    return snapshot.data();
  }

  Future<Map<String, dynamic>?> readCurrentHouseholdFromCloud() async {
    if (!_firebaseEnabled) return null;
    final snapshot = await _firestore!
        .collection('households')
        .doc(_householdId)
        .get();
    return snapshot.data();
  }

  Future<List<Map<String, dynamic>>> queryHouseholdMembersFromCloud({
    String? role,
    int limit = 50,
  }) async {
    if (!_firebaseEnabled) return const [];

    Query<Map<String, dynamic>> query = _firestore!
        .collection('households')
        .doc(_householdId)
        .collection('members');

    if (role != null && role.trim().isNotEmpty) {
      query = query.where('role', isEqualTo: _normalizeRole(role));
    }

    final snapshot = await query.limit(limit).get();
    final members = snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      data['role'] = _normalizeRole(data['role'] as String?);
      return data;
    }).toList();

    members.sort((a, b) {
      final roleA = _normalizeRole(a['role'] as String?);
      final roleB = _normalizeRole(b['role'] as String?);
      final rankA = _roleSortOrder(roleA);
      final rankB = _roleSortOrder(roleB);
      if (rankA != rankB) return rankA.compareTo(rankB);

      final nameA = ((a['displayName'] as String?) ?? '').toLowerCase();
      final nameB = ((b['displayName'] as String?) ?? '').toLowerCase();
      if (nameA != nameB) return nameA.compareTo(nameB);
      return (a['id'] as String).compareTo(b['id'] as String);
    });

    return members;
  }

  Future<void> updateCurrentUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    if (!_firebaseEnabled) return;
    final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (displayName != null) data['displayName'] = displayName;
    if (photoUrl != null) data['photoUrl'] = photoUrl;

    await _firestore!
        .collection('users')
        .doc(_userId)
        .set(data, SetOptions(merge: true));
  }

  Future<void> updateCurrentHousehold({
    String? name,
    String? description,
    String? planTier,
    String? billingStatus,
    bool? aiReceiptParsingEnabled,
  }) async {
    if (!_firebaseEnabled) return;
    await _requireHouseholdAdminRole();

    final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (name != null) data['name'] = _sanitizeHouseholdName(name);
    if (description != null) {
      data['description'] = _sanitizeOptionalDescription(description);
    }
    if (planTier != null) data['planTier'] = _sanitizePlanTier(planTier);
    if (billingStatus != null) {
      data['billingStatus'] = _sanitizeBillingStatus(billingStatus);
    }
    if (aiReceiptParsingEnabled != null) {
      data['aiReceiptParsingEnabled'] = aiReceiptParsingEnabled;
    }

    await _firestore!
        .collection('households')
        .doc(_householdId)
        .set(data, SetOptions(merge: true));
  }

  Future<void> upsertCurrentSubscription({
    required String planId,
    required String status,
    String interval = 'month',
    int amountCents = 0,
    String currency = 'USD',
    int seatCount = 1,
    String? stripeSubscriptionId,
    DateTime? trialEndsAt,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
  }) async {
    if (!_firebaseEnabled) return;
    await _requireHouseholdAdminRole();

    final householdRef = _firestore!.collection('households').doc(_householdId);
    await householdRef.collection('subscriptions').doc('current').set({
      'id': 'current',
      'provider': 'stripe',
      'planId': planId,
      'status': status,
      'interval': interval,
      'amountCents': amountCents,
      'currency': currency,
      'seatCount': seatCount,
      'stripeSubscriptionId': stripeSubscriptionId,
      'trialEndsAt': trialEndsAt == null
          ? null
          : Timestamp.fromDate(trialEndsAt),
      'currentPeriodStart': currentPeriodStart == null
          ? null
          : Timestamp.fromDate(currentPeriodStart),
      'currentPeriodEnd': currentPeriodEnd == null
          ? null
          : Timestamp.fromDate(currentPeriodEnd),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await householdRef.set({
      'planTier': planId,
      'billingStatus': status,
      'stripeSubscriptionId': stripeSubscriptionId,
      'currentPeriodEnd': currentPeriodEnd == null
          ? null
          : Timestamp.fromDate(currentPeriodEnd),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateCurrentPaymentProfile({
    String? customerId,
    String? defaultPaymentMethodId,
    String? billingEmail,
    String? billingName,
    String? taxCountry,
    String? taxId,
  }) async {
    if (!_firebaseEnabled) return;
    await _requireHouseholdAdminRole();

    final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (customerId != null) data['customerId'] = customerId;
    if (defaultPaymentMethodId != null) {
      data['defaultPaymentMethodId'] = defaultPaymentMethodId;
    }
    if (billingEmail != null) data['billingEmail'] = billingEmail;
    if (billingName != null) data['billingName'] = billingName;
    if (taxCountry != null) data['taxCountry'] = taxCountry;
    if (taxId != null) data['taxId'] = taxId;

    await _firestore!
        .collection('households')
        .doc(_householdId)
        .collection('payments')
        .doc('payment_profile')
        .set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> readHouseholdMemberFromCloud(
    String memberUserId,
  ) async {
    if (!_firebaseEnabled) return null;
    final id = memberUserId.trim();
    if (id.isEmpty) return null;

    final snapshot = await _firestore!
        .collection('households')
        .doc(_householdId)
        .collection('members')
        .doc(id)
        .get();
    if (!snapshot.exists || snapshot.data() == null) return null;

    final data = Map<String, dynamic>.from(snapshot.data()!);
    data['id'] = snapshot.id;
    data['role'] = _normalizeRole(data['role'] as String?);
    return data;
  }

  Future<void> updateHouseholdMemberRole({
    required String memberUserId,
    required String role,
  }) async {
    if (!_firebaseEnabled) {
      throw StateError('Firebase is not enabled for this project.');
    }

    final targetMemberId = memberUserId.trim();
    if (targetMemberId.isEmpty) {
      throw StateError('Member id is required.');
    }
    if (targetMemberId == _userId) {
      throw StateError('You cannot change your own role.');
    }

    final normalizedRole = _normalizeRole(role);
    if (!_assignableRoles.contains(normalizedRole)) {
      throw StateError('Unsupported role: $role');
    }

    final firestore = _firestore!;
    final householdRef = firestore.collection('households').doc(_householdId);
    final membersRef = householdRef.collection('members');
    final actorRef = membersRef.doc(_userId);
    final targetRef = membersRef.doc(targetMemberId);

    await firestore.runTransaction((transaction) async {
      final actorSnapshot = await transaction.get(actorRef);
      if (!actorSnapshot.exists) {
        throw StateError('You are not a member of this household.');
      }

      final actorRole = _normalizeRole(
        actorSnapshot.data()?['role'] as String?,
      );
      if (actorRole != _roleOwner && actorRole != _roleAdmin) {
        throw StateError('You do not have permission to edit member roles.');
      }

      final targetSnapshot = await transaction.get(targetRef);
      if (!targetSnapshot.exists) {
        throw StateError('Member not found.');
      }

      final targetRole = _normalizeRole(
        targetSnapshot.data()?['role'] as String?,
      );

      if (actorRole == _roleAdmin) {
        if (targetRole != _roleMember || normalizedRole != _roleMember) {
          throw StateError('Admins can only manage member-level users.');
        }
      }

      if (normalizedRole == _roleOwner) {
        if (actorRole != _roleOwner) {
          throw StateError('Only the current owner can transfer ownership.');
        }
        transaction.update(householdRef, {
          'ownerUserId': targetMemberId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(actorRef, {
          'role': _roleAdmin,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _memberRole = _roleAdmin;
      } else if (targetRole == _roleOwner) {
        throw StateError('Transfer ownership instead of demoting the owner.');
      }

      transaction.update(targetRef, {
        'role': normalizedRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> removeHouseholdMember(String memberUserId) async {
    if (!_firebaseEnabled) {
      throw StateError('Firebase is not enabled for this project.');
    }

    final targetMemberId = memberUserId.trim();
    if (targetMemberId.isEmpty) {
      throw StateError('Member id is required.');
    }
    if (targetMemberId == _userId) {
      throw StateError('You cannot remove yourself from this screen.');
    }

    final firestore = _firestore!;
    final householdRef = firestore.collection('households').doc(_householdId);
    final membersRef = householdRef.collection('members');
    final actorRef = membersRef.doc(_userId);
    final targetRef = membersRef.doc(targetMemberId);

    await firestore.runTransaction((transaction) async {
      final actorSnapshot = await transaction.get(actorRef);
      if (!actorSnapshot.exists) {
        throw StateError('You are not a member of this household.');
      }
      final actorRole = _normalizeRole(
        actorSnapshot.data()?['role'] as String?,
      );
      if (actorRole != _roleOwner && actorRole != _roleAdmin) {
        throw StateError('You do not have permission to remove members.');
      }

      final targetSnapshot = await transaction.get(targetRef);
      if (!targetSnapshot.exists) {
        throw StateError('Member not found.');
      }
      final targetRole = _normalizeRole(
        targetSnapshot.data()?['role'] as String?,
      );
      if (targetRole == _roleOwner) {
        throw StateError('The owner cannot be removed.');
      }
      if (actorRole == _roleAdmin && targetRole == _roleAdmin) {
        throw StateError('Admins cannot remove another admin.');
      }

      final householdSnapshot = await transaction.get(householdRef);
      final currentCount =
          (householdSnapshot.data()?['memberCount'] as num?)?.toInt() ?? 1;
      final nextCount = currentCount <= 0 ? 0 : currentCount - 1;

      transaction.delete(targetRef);
      transaction.update(householdRef, {
        'memberCount': nextCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Map<String, dynamic> buildAuditFields({required bool includeCreatedAt}) {
    return {
      'householdId': _householdId,
      'updatedByUserId': _userId,
      'updatedAt': FieldValue.serverTimestamp(),
      if (includeCreatedAt) 'createdByUserId': _userId,
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  String _defaultHouseholdName(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return '$displayName Household';
    }
    return 'My Household';
  }

  String _generateInviteCode({required String seed}) {
    final safeSeed = seed.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final left = safeSeed.padRight(3, 'X').substring(0, 3);
    final millis = DateTime.now().millisecondsSinceEpoch
        .toRadixString(36)
        .toUpperCase();
    final right = millis.padLeft(4, '0').substring(millis.length - 4);
    return '$left-$right';
  }

  Future<void> _requireHouseholdAdminRole() async {
    if (!_firebaseEnabled) {
      throw StateError('Firebase is not enabled for this project.');
    }

    final memberSnapshot = await _firestore!
        .collection('households')
        .doc(_householdId)
        .collection('members')
        .doc(_userId)
        .get();
    if (!memberSnapshot.exists || memberSnapshot.data() == null) {
      throw StateError('You are not a member of this household.');
    }

    final role = _normalizeRole(memberSnapshot.data()!['role'] as String?);
    if (role != _roleOwner && role != _roleAdmin) {
      throw StateError('Only owner/admin can modify household settings.');
    }
    _memberRole = role;
  }

  String _normalizeRole(String? role) {
    final normalized = role?.trim().toLowerCase();
    if (normalized == _roleOwner) return _roleOwner;
    if (normalized == _roleAdmin) return _roleAdmin;
    if (normalized == _roleMember) return _roleMember;
    if (normalized == _roleNone) return _roleNone;
    return _roleMember;
  }

  int _roleSortOrder(String role) {
    switch (role) {
      case _roleOwner:
        return 0;
      case _roleAdmin:
        return 1;
      case _roleMember:
        return 2;
      default:
        return 3;
    }
  }

  String _sanitizeHouseholdName(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return 'My Household';
    if (trimmed.length > 80) return trimmed.substring(0, 80);
    return trimmed;
  }

  String _sanitizeOptionalDescription(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return '';
    if (trimmed.length > 240) return trimmed.substring(0, 240);
    return trimmed;
  }

  String _sanitizePlanTier(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return 'free';
    if (normalized.length > 32) return normalized.substring(0, 32);
    return normalized;
  }

  String _sanitizeBillingStatus(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return 'none';
    if (normalized.length > 32) return normalized.substring(0, 32);
    return normalized;
  }

  Map<String, dynamic> _buildUserProfileData({
    required User user,
    required String primaryHouseholdId,
    required String role,
    required bool includeCreatedAt,
  }) {
    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'isAnonymous': user.isAnonymous,
      'authProviderIds': user.providerData.map((p) => p.providerId).toList(),
      'primaryHouseholdId': primaryHouseholdId,
      'role': role,
      'status': 'active',
      'planTier': 'free',
      'billingStatus': 'none',
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSignInAt': FieldValue.serverTimestamp(),
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _buildHouseholdData({
    required String householdId,
    required String ownerUserId,
    required String householdName,
    required String inviteCode,
  }) {
    return {
      'id': householdId,
      'name': householdName,
      'ownerUserId': ownerUserId,
      'inviteCode': inviteCode,
      'description': '',
      'memberCount': 1,
      'status': 'active',
      'planTier': 'free',
      'billingStatus': 'trialing',
      'billingCycle': 'monthly',
      'seatLimit': 5,
      'stripeCustomerId': null,
      'stripeSubscriptionId': null,
      'trialEndsAt': null,
      'currentPeriodEnd': null,
      'aiReceiptParsingEnabled': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _buildHouseholdMemberData({
    required User user,
    required String role,
  }) {
    return {
      'userId': user.uid,
      'role': role,
      'status': 'active',
      'displayName': user.displayName,
      'email': user.email,
      'photoUrl': user.photoURL,
      'joinedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _buildDefaultSubscriptionData() {
    return {
      'id': 'current',
      'provider': 'stripe',
      'planId': 'free',
      'status': 'trialing',
      'interval': 'month',
      'amountCents': 0,
      'currency': 'USD',
      'seatCount': 1,
      'cancelAtPeriodEnd': false,
      'trialEndsAt': null,
      'currentPeriodStart': null,
      'currentPeriodEnd': null,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _buildDefaultPaymentProfileData() {
    return {
      'id': 'payment_profile',
      'provider': 'stripe',
      'customerId': null,
      'defaultPaymentMethodId': null,
      'taxCountry': null,
      'taxId': null,
      'billingEmail': null,
      'billingName': null,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
