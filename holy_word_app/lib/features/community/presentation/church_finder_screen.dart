import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/church_service.dart';

class ChurchFinderScreen extends StatefulWidget {
  const ChurchFinderScreen({super.key});

  @override
  State<ChurchFinderScreen> createState() => _ChurchFinderScreenState();
}

class _ChurchFinderScreenState extends State<ChurchFinderScreen> {
  final MapController _mapController = MapController();
  final PageController _pageController = PageController(viewportFraction: 0.85);
  final ChurchService _churchService = ChurchService();

  LatLng _currentCenter = const LatLng(17.3850, 78.4867); // Default: Hyderabad
  bool _isLoadingLocation = true;
  bool _isFetchingChurches = false;

  List<ChurchLocation> _churches = [];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoadingLocation = true);

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoadingLocation = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isLoadingLocation = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      final newCenter = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentCenter = newCenter;
        _isLoadingLocation = false;
      });

      _mapController.move(newCenter, 14.0);
      _fetchChurchesInArea(newCenter);
    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _fetchChurchesInArea(LatLng center) async {
    setState(() => _isFetchingChurches = true);
    try {
      final results =
          await _churchService.fetchChurches(center.latitude, center.longitude);

      // Calculate distances
      final List<ChurchLocation> churchesWithDistance = results.map((church) {
        final distanceInMeters = Geolocator.distanceBetween(
          _currentCenter.latitude,
          _currentCenter.longitude,
          church.lat,
          church.lng,
        );
        // Create new instance with distance (assuming ChurchLocation has a copyWith or I construct it)
        // Since I can't modify the final field and didn't make a copyWith, I'll return a new object
        return ChurchLocation(
          name: church.name,
          lat: church.lat,
          lng: church.lng,
          address: church.address,
          distance: distanceInMeters / 1000, // Convert to km
        );
      }).toList();

      // Sort by distance
      churchesWithDistance
          .sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));

      if (mounted) {
        setState(() {
          _churches = churchesWithDistance;
          _isFetchingChurches = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching churches: $e");
      if (mounted) setState(() => _isFetchingChurches = false);
    }
  }

  void _moveToUser() {
    _determinePosition();
  }

  void _searchThisArea() {
    // When searching area manually, we calculate distance from the MAP CENTER, not user?
    // User requested "distance", usually implies from User.
    // I will keep calculating from _currentCenter (User's last known location) even if searching elsewhere,
    // OR I should update _currentCenter to map center?
    // Let's stick to distance from User's real location for utility.
    _fetchChurchesInArea(_mapController.camera.center);
  }

  void _onCardChanged(int index) {
    if (index >= 0 && index < _churches.length) {
      final church = _churches[index];
      _mapController.move(LatLng(church.lat, church.lng), 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Churches')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.benayaram.holy_word_app',
              ),
              MarkerLayer(
                markers: [
                  // User Location Marker
                  if (!_isLoadingLocation)
                    Marker(
                      point: _currentCenter,
                      width: 60,
                      height: 60,
                      child: const Column(
                        children: [
                          Icon(Icons.my_location, color: Colors.blue, size: 30),
                        ],
                      ),
                    ),
                  // Church Markers
                  ..._churches.map((church) => Marker(
                        point: LatLng(church.lat, church.lng),
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () {
                            // Find index and scroll to it
                            final index = _churches.indexOf(church);
                            if (index != -1) {
                              _pageController.animateToPage(index,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut);
                            }
                          },
                          child: const Icon(Icons.location_on,
                              color: Colors.red, size: 40),
                        ),
                      )),
                ],
              ),
            ],
          ),

          // Search Here Button
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: _isFetchingChurches
                  ? const Card(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 8),
                            Text("Searching area..."),
                          ],
                        ),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: _searchThisArea,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Search This Area"),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                      ),
                    ),
            ),
          ),

          // Church Cards PageView
          if (_churches.isNotEmpty && !_isFetchingChurches)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              height: 160,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _churches.length,
                onPageChanged: _onCardChanged,
                itemBuilder: (context, index) {
                  final church = _churches[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    church.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${church.distance?.toStringAsFixed(1)} km',
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                church.address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 36,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Directions logic placeholder
                                },
                                icon: const Icon(Icons.directions, size: 18),
                                label: const Text('Directions'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          if (_isLoadingLocation)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Locating you..."),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _moveToUser,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
