import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../services/location_service.dart';
import '../services/sharing_hub_service.dart';
import '../services/storage_service.dart';

class LocationProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final LocationService _locationService = LocationService();
  final SharingHubService _sharingHubService = SharingHubService();

  String? _username;
  String _userId = '';
  String _avatarColorHex = '#3B82F6';
  bool _isSharing = false;
  bool _isInitialized = false;
  bool _isLoadingLocation = false;
  LocationPermission _permissionStatus = LocationPermission.denied;

  double? _currentLat;
  double? _currentLng;
  double _currentSpeed = 0.0;
  double _currentHeading = 0.0;
  double _currentAccuracy = 5.0;
  DateTime? _lastUpdated;

  Timer? _sharingTimer;
  StreamSubscription? _usersSubscription;
  List<SharingUser> _activeSharingUsers = [];

  // Getters
  String? get username => _username;
  String get userId => _userId;
  String get avatarColorHex => _avatarColorHex;
  bool get isSharing => _isSharing;
  bool get isInitialized => _isInitialized;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get hasUsername => _username != null && _username!.isNotEmpty;
  bool get includeSimulatedUsers => _sharingHubService.includeSimulatedUsers;
  LocationPermission get permissionStatus => _permissionStatus;
  bool get isPermissionGranted =>
      _permissionStatus == LocationPermission.always ||
      _permissionStatus == LocationPermission.whileInUse;

  double? get currentLat => _currentLat;
  double? get currentLng => _currentLng;
  double get currentSpeed => _currentSpeed;
  double get currentHeading => _currentHeading;
  double get currentAccuracy => _currentAccuracy;
  DateTime? get lastUpdated => _lastUpdated;
  List<SharingUser> get activeSharingUsers => _activeSharingUsers;

  SharingUser? get currentUserModel {
    if (_username == null || _currentLat == null || _currentLng == null) {
      return null;
    }
    return SharingUser(
      id: _userId,
      username: _username!,
      latitude: _currentLat!,
      longitude: _currentLng!,
      speed: _currentSpeed,
      heading: _currentHeading,
      lastUpdated: _lastUpdated ?? DateTime.now(),
      isSharing: _isSharing,
      avatarColorHex: _avatarColorHex,
      isCurrentUser: true,
    );
  }

  Future<void> initialize() async {
    _userId = await _storageService.getOrGenerateUserId();
    _avatarColorHex = await _storageService.getOrGenerateAvatarColor();
    _username = await _storageService.getUsername();

    // Check & request location permission on app launch
    _permissionStatus = await _locationService.checkPermissionStatus();
    if (!isPermissionGranted) {
      _permissionStatus = await _locationService.requestPermission();
    }

    // Listen to multi-user updates
    _usersSubscription = _sharingHubService.activeUsersStream.listen((users) {
      _activeSharingUsers = users;
      notifyListeners();
    });

    // Get initial position
    await updateCurrentLocation();

    // Init sharing service
    _sharingHubService.initSimulatedUsers(
      _currentLat ?? LocationService.defaultLat,
      _currentLng ?? LocationService.defaultLng,
    );

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> requestLocationPermission() async {
    _permissionStatus = await _locationService.requestPermission();
    if (isPermissionGranted) {
      await updateCurrentLocation();
    }
    notifyListeners();
  }

  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  void toggleSimulatedUsers() {
    _sharingHubService.toggleSimulatedUsers(!includeSimulatedUsers);
    notifyListeners();
  }

  Future<void> setUsername(String newUsername) async {
    final trimmed = newUsername.trim();
    if (trimmed.isEmpty) return;
    _username = trimmed;
    await _storageService.saveUsername(trimmed);

    if (_currentLat != null && _currentLng != null && _isSharing) {
      _broadcastCurrentPosition();
    }

    notifyListeners();
  }

  Future<void> updateCurrentLocation() async {
    _isLoadingLocation = true;
    notifyListeners();

    final locResult = await _locationService.getCurrentLocation();
    if (locResult != null) {
      _currentLat = locResult.latitude;
      _currentLng = locResult.longitude;
      _currentSpeed = locResult.speed;
      _currentHeading = locResult.heading;
      _currentAccuracy = locResult.accuracy;
      _lastUpdated = DateTime.now();

      if (_isSharing && currentUserModel != null) {
        _broadcastCurrentPosition();
      }
    }

    _isLoadingLocation = false;
    notifyListeners();
  }

  void startSharing() async {
    if (_isSharing) return;

    if (!isPermissionGranted) {
      _permissionStatus = await _locationService.requestPermission();
      if (!isPermissionGranted) {
        notifyListeners();
        return;
      }
    }

    _isSharing = true;

    // Immediate location update & cloud broadcast
    updateCurrentLocation();

    // Continuous location updates every 5 seconds
    _sharingTimer?.cancel();
    _sharingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      updateCurrentLocation();
    });

    notifyListeners();
  }

  void stopSharing() {
    if (!_isSharing) return;
    _isSharing = false;

    // Cancel 5-second periodic timer
    _sharingTimer?.cancel();
    _sharingTimer = null;

    // Stop broadcasting active user state to cloud
    _sharingHubService.stopBroadcastingCurrentUser(_userId);

    notifyListeners();
  }

  void _broadcastCurrentPosition() {
    final model = currentUserModel;
    if (model != null) {
      _sharingHubService.broadcastCurrentUser(model);
    }
  }

  @override
  void dispose() {
    _sharingTimer?.cancel();
    _usersSubscription?.cancel();
    _sharingHubService.dispose();
    super.dispose();
  }
}
