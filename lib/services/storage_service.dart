import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static const String _keyUsername = 'live_location_username';
  static const String _keyUserId = 'live_location_user_id';
  static const String _keyAvatarColor = 'live_location_avatar_color';

  static final List<String> _avatarColors = [
    '#3B82F6', // Blue
    '#10B981', // Emerald
    '#8B5CF6', // Purple
    '#F59E0B', // Amber
    '#EC4899', // Pink
    '#06B6D4', // Cyan
    '#F97316', // Orange
  ];

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username.trim());
  }

  Future<String> getOrGenerateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_keyUserId);
    if (userId == null || userId.isEmpty) {
      userId = const Uuid().v4();
      await prefs.setString(_keyUserId, userId);
    }
    return userId;
  }

  Future<String> getOrGenerateAvatarColor() async {
    final prefs = await SharedPreferences.getInstance();
    String? colorHex = prefs.getString(_keyAvatarColor);
    if (colorHex == null || colorHex.isEmpty) {
      final random = Random();
      colorHex = _avatarColors[random.nextInt(_avatarColors.length)];
      await prefs.setString(_keyAvatarColor, colorHex);
    }
    return colorHex;
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
  }
}
