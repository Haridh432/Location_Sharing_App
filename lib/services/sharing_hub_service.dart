import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class SharingHubService {
  // Public Firebase Realtime Database REST Endpoint for cross-device real-time sync
  static const String _cloudDbUrl =
      'https://live-location-share-app-default-rtdb.firebaseio.com';

  final Map<String, SharingUser> _localUsers = {};
  final Map<String, SharingUser> _remoteCloudUsers = {};

  Timer? _syncTimer;
  String? _currentUserId;
  bool _includeSimulatedUsers = false;

  final _usersStreamController = StreamController<List<SharingUser>>.broadcast();

  Stream<List<SharingUser>> get activeUsersStream => _usersStreamController.stream;

  List<SharingUser> get activeUsersList => _combinedActiveUsers();

  bool get includeSimulatedUsers => _includeSimulatedUsers;

  void toggleSimulatedUsers(bool enable) {
    _includeSimulatedUsers = enable;
    _notifyListeners();
  }

  void initSimulatedUsers(double baseLat, double baseLng) {
    _startSyncLoop();
    _fetchRemoteCloudUsers();
    _notifyListeners();
  }

  /// Broadcast current user's location to both local state and Realtime Cloud Database
  Future<void> broadcastCurrentUser(SharingUser user) async {
    _currentUserId = user.id;

    final updatedUser = user.copyWith(
      isCurrentUser: true,
      lastUpdated: DateTime.now(),
      isSharing: true,
    );

    _localUsers[user.id] = updatedUser;
    _notifyListeners();

    // Push live coordinates to Cloud Database for multi-device sync
    try {
      final uri = Uri.parse('$_cloudDbUrl/users/${user.id}.json');
      await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedUser.toJson()),
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Cloud sync broadcast error: $e');
    }
  }

  /// Stop broadcasting user location
  Future<void> stopBroadcastingCurrentUser(String userId) async {
    _currentUserId = userId;

    if (_localUsers.containsKey(userId)) {
      final existing = _localUsers[userId]!;
      _localUsers[userId] = existing.copyWith(
        isSharing: false,
        lastUpdated: DateTime.now(),
      );
    }
    _notifyListeners();

    // Update cloud node to stop sharing
    try {
      final uri = Uri.parse('$_cloudDbUrl/users/$userId.json');
      await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'isSharing': false,
          'lastUpdated': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Cloud sync stop sharing error: $e');
    }
  }

  void _startSyncLoop() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _fetchRemoteCloudUsers();
    });
  }

  /// Fetch active users sharing locations across all devices from Realtime Cloud DB
  Future<void> _fetchRemoteCloudUsers() async {
    try {
      final uri = Uri.parse('$_cloudDbUrl/users.json');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 && response.body != 'null') {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final now = DateTime.now();

        _remoteCloudUsers.clear();
        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final user = SharingUser.fromJson(value);
            // Ignore self or users who are not actively sharing or stale (> 2 mins old)
            if (user.id != _currentUserId &&
                user.isSharing &&
                now.difference(user.lastUpdated).inSeconds < 120) {
              _remoteCloudUsers[user.id] = user;
            }
          }
        });

        _notifyListeners();
      }
    } catch (e) {
      debugPrint('Cloud sync fetch error: $e');
    }
  }

  List<SharingUser> _combinedActiveUsers() {
    final Map<String, SharingUser> combined = {};

    // 1. Current user
    for (final u in _localUsers.values) {
      if (u.isSharing && u.isCurrentUser) {
        combined[u.id] = u;
      }
    }

    // 2. Remote Cloud users (real users on other devices)
    for (final u in _remoteCloudUsers.values) {
      if (u.isSharing && u.id != _currentUserId) {
        combined[u.id] = u;
      }
    }

    return combined.values.toList();
  }

  void _notifyListeners() {
    final list = _combinedActiveUsers();
    if (!_usersStreamController.isClosed) {
      _usersStreamController.add(list);
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _usersStreamController.close();
  }
}
