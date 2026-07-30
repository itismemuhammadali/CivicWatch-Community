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

  static CachedUserInfo? fromFirestoreData(Map<String, dynamic> data) {
    final rawId = data['user_id'] ?? data['userId'] ?? data['id'] ?? data['uid'];
    final intId = rawId is int
        ? rawId
        : (int.tryParse('$rawId') ?? (rawId != null ? rawId.toString().hashCode.abs() : null));
    if (intId == null) return null;

    var firstName = _normalizeField(data, ['firstName', 'first_name', 'name', 'full_name', 'username', 'display_name']);
    var lastName = _normalizeField(data, ['lastName', 'last_name']);
    final email = _normalizeField(data, ['email', 'user_email']);
    final avatarUrl = _normalizeField(data, [
      'profileImageUrl',
      'profile_image_url',
      'avatar_url',
      'avatar',
      'image_url',
    ]);

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
    }
    return info;
  }

  Future<Map<int, CachedUserInfo>> batchGetUsers(List<int> userIds) async {
    final result = <int, CachedUserInfo>{};
    final toFetch = <int>[];

    for (final id in userIds.toSet()) {
      final cached = _cache[id];
      if (cached != null && !cached.isExpired) {
        result[id] = cached.info;
      } else {
        toFetch.add(id);
      }
    }

    if (toFetch.isEmpty) return result;

    // Firestore whereIn limit is 30
    for (var i = 0; i < toFetch.length; i += 30) {
      final batch = toFetch.sublist(i, (i + 30).clamp(0, toFetch.length));
      final query = await _db
          .collection('users')
          .where('user_id', whereIn: batch)
          .get();

      for (final doc in query.docs) {
        final info = CachedUserInfo.fromFirestoreData(doc.data());
        if (info != null) {
          _cache[info.userId] = _CacheEntry(info);
          result[info.userId] = info;
        }
      }
    }

    // Fallback for any IDs not found via whereIn (may be string-typed in Firestore)
    final missing = toFetch.where((id) => !result.containsKey(id)).toList();
    for (final id in missing) {
      final info = await _fetchUser(id);
      if (info != null) {
        _cache[id] = _CacheEntry(info);
        result[id] = info;
      }
    }

    return result;
  }

  void invalidate(int userId) {
    _cache.remove(userId);
  }

  void invalidateAll() {
    _cache.clear();
  }

  Future<CachedUserInfo?> _fetchUser(dynamic userId) async {
    if (userId == null) return null;
    final intId = userId is int ? userId : int.tryParse('$userId');
    if (intId == null) return null;

    // Strategy 1: query by int user_id
    final q1 = await _db
        .collection('users')
        .where('user_id', isEqualTo: intId)
        .limit(1)
        .get();
    if (q1.docs.isNotEmpty) {
      return CachedUserInfo.fromFirestoreData(q1.docs.first.data());
    }

    // Strategy 2: query by string user_id
    final q2 = await _db
        .collection('users')
        .where('user_id', isEqualTo: '$userId')
        .limit(1)
        .get();
    if (q2.docs.isNotEmpty) {
      return CachedUserInfo.fromFirestoreData(q2.docs.first.data());
    }

    // Strategy 3: direct document ID lookup
    final doc = await _db.collection('users').doc('$userId').get();
    if (doc.exists && doc.data() != null) {
      return CachedUserInfo.fromFirestoreData(doc.data()!);
    }

    return null;
  }
}

class _CacheEntry {
  final CachedUserInfo info;
  final DateTime createdAt;

  _CacheEntry(this.info) : createdAt = DateTime.now();

  bool get isExpired => DateTime.now().difference(createdAt) > UserCacheService._ttl;
}
