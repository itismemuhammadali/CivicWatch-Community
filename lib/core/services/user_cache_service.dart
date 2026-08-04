import 'package:cloud_firestore/cloud_firestore.dart';

class CachedUserInfo {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String avatarUrl;

  const CachedUserInfo({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.avatarUrl,
  });

  String get displayName => '$firstName $lastName'.trim();

  String get initials {
    final parts = displayName.split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Map<String, dynamic> toMap() => {
    'first_name': firstName,
    'last_name': lastName,
    'user_email': email,
    'avatar_url': avatarUrl,
    'application_meta': {
      'meta_id': 0,
      'meta_type_id': 1,
      'meta_url': avatarUrl,
    },
  };

  static CachedUserInfo? fromFirestoreData(
    Map<String, dynamic> data, {
    String? docId,
  }) {
    final rawId =
        data['user_id'] ??
        data['userId'] ??
        data['id'] ??
        data['uid'] ??
        data['firebase_uid'] ??
        docId;
    final intId = rawId is int
        ? rawId
        : (int.tryParse('$rawId') ?? rawId?.toString().hashCode.abs());
    if (intId == null || intId == 0) return null;

    var firstName = _normalizeField(data, [
      'firstName',
      'first_name',
      'name',
      'full_name',
      'username',
      'display_name',
    ]);
    var lastName = _normalizeField(data, ['lastName', 'last_name']);
    final email = _normalizeField(data, ['email', 'user_email']);
    var avatarUrl = _normalizeField(data, [
      'profileImageUrl',
      'profile_image_url',
      'avatar_url',
      'avatar',
      'image_url',
    ]);

    if (avatarUrl.isEmpty) {
      final appMeta =
          data['application_meta'] ?? data['profile_meta'] ?? data['meta'];
      if (appMeta is Map) {
        final metaUrl = appMeta['meta_url'] ?? appMeta['url'];
        if (metaUrl is String && metaUrl.trim().isNotEmpty) {
          avatarUrl = metaUrl.trim();
        }
      }
    }

    if (lastName.isEmpty && firstName.contains(' ')) {
      final parts = firstName.split(' ');
      firstName = parts.first;
      lastName = parts.sublist(1).join(' ');
    }

    if (firstName.isEmpty && lastName.isEmpty && email.isNotEmpty) {
      firstName = email.split('@').first;
    }

    return CachedUserInfo(
      userId: intId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      avatarUrl: avatarUrl,
    );
  }

  static String _normalizeField(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }
}

class UserCacheService {
  static final UserCacheService _instance = UserCacheService._internal();
  factory UserCacheService() => _instance;
  UserCacheService._internal();

  final Map<int, _CacheEntry> _cache = {};
  static const Duration _ttl = Duration(minutes: 5);

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<CachedUserInfo?> getUser(int userId) async {
    final cached = _cache[userId];
    if (cached != null && !cached.isExpired) {
      return cached.info;
    }

    final info = await _fetchUser(userId);
    if (info != null) {
      _cache[userId] = _CacheEntry(info);
      _cache[info.userId] = _CacheEntry(info);
    }
    return info;
  }

  Future<CachedUserInfo?> getUserDynamic(dynamic rawUserId) async {
    if (rawUserId == null) return null;
    if (rawUserId is int) return getUser(rawUserId);

    final strVal = '$rawUserId'.trim();
    if (strVal.isEmpty) return null;

    final parsedInt = int.tryParse(strVal);
    if (parsedInt != null) {
      final info = await getUser(parsedInt);
      if (info != null) return info;
    }

    // Try string-based lookup via _fetchUser
    final info = await _fetchUser(strVal);
    if (info != null) {
      _cache[info.userId] = _CacheEntry(info);
      return info;
    }

    // Try hashCodes
    final h1 = strVal.hashCode;
    final u1 = await getUser(h1);
    if (u1 != null) return u1;

    final h2 = strVal.hashCode.abs();
    final u2 = await getUser(h2);
    if (u2 != null) return u2;

    return null;
  }

  Future<Map<int, CachedUserInfo>> batchGetUsers(List<int> userIds) async {
    final result = <int, CachedUserInfo>{};
    for (final id in userIds.toSet()) {
      final info = await getUser(id);
      if (info != null) {
        result[id] = info;
        result[info.userId] = info;
      }
    }
    return result;
  }

  String? getAvatarSync(int userId) {
    final entry = _cache[userId];
    if (entry != null && entry.info.avatarUrl.isNotEmpty) {
      return entry.info.avatarUrl;
    }
    return null;
  }

  CachedUserInfo? getUserInfoSync(int userId) {
    final entry = _cache[userId];
    return entry?.info;
  }

  void invalidate(int userId) {
    _cache.remove(userId);
  }

  void invalidateByFirebaseUid(String uid) {
    _cache.remove(uid.hashCode);
    _cache.remove(uid.hashCode.abs());
  }

  void invalidateAll() {
    _cache.clear();
  }

  Future<CachedUserInfo?> _fetchUser(dynamic userId) async {
    if (userId == null) return null;
    final intId = userId is int ? userId : int.tryParse('$userId');

    // Strategy 1: query by int user_id
    if (intId != null) {
      final q1 = await _db
          .collection('users')
          .where('user_id', isEqualTo: intId)
          .limit(1)
          .get();
      if (q1.docs.isNotEmpty) {
        return CachedUserInfo.fromFirestoreData(
          q1.docs.first.data(),
          docId: q1.docs.first.id,
        );
      }
    }

    // Strategy 2: query by string user_id
    final q2 = await _db
        .collection('users')
        .where('user_id', isEqualTo: '$userId')
        .limit(1)
        .get();
    if (q2.docs.isNotEmpty) {
      return CachedUserInfo.fromFirestoreData(
        q2.docs.first.data(),
        docId: q2.docs.first.id,
      );
    }

    // Strategy 3: query by int or string camelCase userId
    if (intId != null) {
      final q3 = await _db
          .collection('users')
          .where('userId', isEqualTo: intId)
          .limit(1)
          .get();
      if (q3.docs.isNotEmpty) {
        return CachedUserInfo.fromFirestoreData(
          q3.docs.first.data(),
          docId: q3.docs.first.id,
        );
      }
    }

    final q3s = await _db
        .collection('users')
        .where('userId', isEqualTo: '$userId')
        .limit(1)
        .get();
    if (q3s.docs.isNotEmpty) {
      return CachedUserInfo.fromFirestoreData(
        q3s.docs.first.data(),
        docId: q3s.docs.first.id,
      );
    }

    // Strategy 4: query by firebase_uid field
    final q4 = await _db
        .collection('users')
        .where('firebase_uid', isEqualTo: '$userId')
        .limit(1)
        .get();
    if (q4.docs.isNotEmpty) {
      return CachedUserInfo.fromFirestoreData(
        q4.docs.first.data(),
        docId: q4.docs.first.id,
      );
    }

    // Strategy 5: direct document ID lookup
    final doc = await _db.collection('users').doc('$userId').get();
    if (doc.exists && doc.data() != null) {
      return CachedUserInfo.fromFirestoreData(doc.data()!, docId: doc.id);
    }

    // Strategy 6: Fallback collection scan (matches intId against parsed CachedUserInfo OR firebase_uid.hashCode)
    try {
      final allDocs = await _db.collection('users').get();
      for (final doc in allDocs.docs) {
        final data = doc.data();
        final info = CachedUserInfo.fromFirestoreData(data, docId: doc.id);
        if (info != null &&
            intId != null &&
            (info.userId == intId || info.userId == intId.abs())) {
          return info;
        }
        // Also check if firebase_uid or doc.id matches or its hashCode matches (signed or abs)
        final rawUid = data['firebase_uid'] ?? doc.id;
        if (rawUid is String) {
          if (rawUid == '$userId') {
            return CachedUserInfo.fromFirestoreData(data, docId: doc.id);
          }
          if (intId != null &&
              (rawUid.hashCode == intId ||
                  rawUid.hashCode.abs() == intId ||
                  rawUid.hashCode == intId.abs() ||
                  rawUid.hashCode.abs() == intId.abs())) {
            return CachedUserInfo.fromFirestoreData(data, docId: doc.id);
          }
        }
      }
    } catch (_) {}

    return null;
  }
}

class _CacheEntry {
  final CachedUserInfo info;
  final DateTime createdAt;

  _CacheEntry(this.info) : createdAt = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(createdAt) > UserCacheService._ttl;
}
