import 'dart:math';

class SharingUser {
  final String id;
  final String username;
  final double latitude;
  final double longitude;
  final double speed; // in m/s
  final double heading; // in degrees
  final DateTime lastUpdated;
  final bool isSharing;
  final String avatarColorHex;
  final bool isCurrentUser;

  SharingUser({
    required this.id,
    required this.username,
    required this.latitude,
    required this.longitude,
    this.speed = 0.0,
    this.heading = 0.0,
    required this.lastUpdated,
    this.isSharing = true,
    this.avatarColorHex = '#3B82F6',
    this.isCurrentUser = false,
  });

  SharingUser copyWith({
    String? id,
    String? username,
    double? latitude,
    double? longitude,
    double? speed,
    double? heading,
    DateTime? lastUpdated,
    bool? isSharing,
    String? avatarColorHex,
    bool? isCurrentUser,
  }) {
    return SharingUser(
      id: id ?? this.id,
      username: username ?? this.username,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isSharing: isSharing ?? this.isSharing,
      avatarColorHex: avatarColorHex ?? this.avatarColorHex,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'heading': heading,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isSharing': isSharing,
      'avatarColorHex': avatarColorHex,
    };
  }

  factory SharingUser.fromJson(Map<String, dynamic> json) {
    return SharingUser(
      id: json['id'] as String? ?? 'unknown',
      username: json['username'] as String? ?? 'Anonymous',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String) ?? DateTime.now()
          : DateTime.now(),
      isSharing: json['isSharing'] as bool? ?? true,
      avatarColorHex: json['avatarColorHex'] as String? ?? '#3B82F6',
      isCurrentUser: false,
    );
  }

  String get timeAgoFormatted {
    final difference = DateTime.now().difference(lastUpdated);
    if (difference.inSeconds < 5) {
      return 'Just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  double distanceInKmTo(double targetLat, double targetLng) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((targetLat - latitude) * p) / 2 +
        cos(latitude * p) *
            cos(targetLat * p) *
            (1 - cos((targetLng - longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  String distanceFormattedTo(double targetLat, double targetLng) {
    final km = distanceInKmTo(targetLat, targetLng);
    if (km < 1.0) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }
}
