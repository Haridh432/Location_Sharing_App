import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final double accuracy;
  final bool isMock;

  LocationResult({
    required this.latitude,
    required this.longitude,
    this.speed = 0.0,
    this.heading = 0.0,
    this.accuracy = 5.0,
    this.isMock = false,
  });
}

class LocationService {
  // Default fallback center (San Francisco) if location services are unavailable or denied on desktop
  static const double defaultLat = 37.7749;
  static const double defaultLng = -122.4194;

  Future<LocationPermission> checkPermissionStatus() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      return LocationPermission.denied;
    }
  }

  Future<LocationPermission> requestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
      }
      return await Geolocator.requestPermission();
    } catch (e) {
      return LocationPermission.denied;
    }
  }

  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkAndRequestPermissions() async {
    try {
      LocationPermission permission = await checkPermissionStatus();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Error checking location permissions: $e');
      return false;
    }
  }

  Future<LocationResult?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) {
        return LocationResult(
          latitude: defaultLat,
          longitude: defaultLng,
          speed: 0.0,
          heading: 0.0,
          accuracy: 10.0,
          isMock: true,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      ).timeout(
        const Duration(seconds: 6),
        onTimeout: () async {
          final lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null) {
            return lastKnown;
          }
          return Position(
            longitude: defaultLng,
            latitude: defaultLat,
            timestamp: DateTime.now(),
            accuracy: 10,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        },
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        heading: position.heading,
        accuracy: position.accuracy,
        isMock: position.isMocked,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return LocationResult(
        latitude: defaultLat,
        longitude: defaultLng,
        isMock: true,
      );
    }
  }
}
