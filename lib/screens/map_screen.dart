import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/location_provider.dart';
import '../services/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _autoFollowUser = true;

  Color _parseColorHex(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF3B82F6);
    }
  }

  void _recenterMap(double lat, double lng) {
    _mapController.move(LatLng(lat, lng), 15.0);
    setState(() => _autoFollowUser = true);
  }

  void _showActiveUsersBottomSheet(BuildContext context, LocationProvider provider, List<SharingUser> users, double? myLat, double? myLng) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isSimEnabled = provider.includeSimulatedUsers;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF475569),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Users (${users.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF064E3B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.cloud_done_rounded, size: 14, color: Color(0xFF10B981)),
                            SizedBox(width: 4),
                            Text(
                              'Cloud Sync 5s',
                              style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Option to toggle demo simulated users
                  InkWell(
                    onTap: () {
                      provider.toggleSimulatedUsers();
                      setModalState(() {});
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSimEnabled ? Icons.smart_toy_rounded : Icons.person_search_rounded,
                            size: 18,
                            color: const Color(0xFF38BDF8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isSimEnabled ? 'Including Demo Simulated Users' : 'Showing Real Cloud Devices Only',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Switch(
                            value: isSimEnabled,
                            activeColor: const Color(0xFF0284C7),
                            onChanged: (val) {
                              provider.toggleSimulatedUsers();
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  users.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'No active users currently sharing location.',
                              style: TextStyle(color: Color(0xFF94A3B8)),
                            ),
                          ),
                        )
                      : Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: users.length,
                            separatorBuilder: (_, _) => const Divider(color: Color(0xFF334155), height: 1),
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final color = _parseColorHex(user.avatarColorHex);
                              final dist = (myLat != null && myLng != null)
                                  ? user.distanceFormattedTo(myLat, myLng)
                                  : '';

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: color,
                                  child: Text(
                                    user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      user.username,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: user.isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    if (user.isCurrentUser) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0284C7),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'YOU',
                                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  'Speed: ${(user.speed * 3.6).toStringAsFixed(1)} km/h • Updated ${user.timeAgoFormatted}',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                ),
                                trailing: Text(
                                  user.isCurrentUser ? 'Self' : dist,
                                  style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _recenterMap(user.latitude, user.longitude);
                                },
                              );
                            },
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocationProvider>(context);

    final myLat = provider.currentLat ?? LocationService.defaultLat;
    final myLng = provider.currentLng ?? LocationService.defaultLng;
    final isSharing = provider.isSharing;
    final activeUsers = provider.activeSharingUsers;

    // Center point for map
    final centerPosition = LatLng(myLat, myLng);

    // Auto follow user if enabled
    if (_autoFollowUser && provider.currentLat != null && provider.currentLng != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(centerPosition, _mapController.camera.zoom);
      });
    }

    // Build map markers
    final markers = <Marker>[];

    // Other Active Users Markers
    for (final user in activeUsers) {
      final userColor = _parseColorHex(user.avatarColorHex);
      final isSelf = user.isCurrentUser;

      markers.add(
        Marker(
          width: 80,
          height: 80,
          point: LatLng(user.latitude, user.longitude),
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${user.username}: ${user.distanceFormattedTo(myLat, myLng)} away'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: userColor,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Username badge tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelf ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: userColor, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    user.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                // Avatar pin
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: userColor,
                    boxShadow: [
                      BoxShadow(color: userColor.withOpacity(0.5), blurRadius: 10, spreadRadius: 2),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFF1E293B),
                    child: Text(
                      user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: userColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            const Text(
              'Live Map',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSharing ? const Color(0xFF064E3B) : const Color(0xFF334155),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSharing ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isSharing ? 'Sharing Live' : 'Paused',
                    style: TextStyle(
                      color: isSharing ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline_rounded, color: Colors.white),
            tooltip: 'Active Users',
            onPressed: () => _showActiveUsersBottomSheet(context, provider, activeUsers, myLat, myLng),
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap Container
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerPosition,
              initialZoom: 15.0,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && _autoFollowUser) {
                  setState(() => _autoFollowUser = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.livelocation.share',
              ),
              MarkerLayer(markers: markers),
            ],
          ),

          // Top Floating Information Chip
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.92),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_sync_rounded, color: Color(0xFF38BDF8), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${activeUsers.length} Users Live',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    isSharing ? 'Cloud Live Sync 5s' : 'Tap Start Sharing',
                    style: TextStyle(
                      color: isSharing ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Map Controls: Recenter & Start/Stop Sharing Toggle
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Recenter My Position Button
                FloatingActionButton.small(
                  heroTag: 'recenter_fab',
                  backgroundColor: _autoFollowUser ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  onPressed: () => _recenterMap(myLat, myLng),
                  child: const Icon(Icons.my_location_rounded),
                ),
                const SizedBox(height: 12),

                // Start/Stop Sharing Floating Toggle Button
                FloatingActionButton.extended(
                  heroTag: 'share_toggle_fab',
                  backgroundColor: isSharing ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  icon: Icon(isSharing ? Icons.stop_rounded : Icons.play_arrow_rounded),
                  label: Text(
                    isSharing ? 'Stop Sharing' : 'Start Sharing',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    if (isSharing) {
                      provider.stopSharing();
                    } else {
                      provider.startSharing();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
