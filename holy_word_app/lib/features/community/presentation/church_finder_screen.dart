import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../services/church_service.dart';

class ChurchFinderScreen extends StatefulWidget {
  const ChurchFinderScreen({super.key});

  @override
  State<ChurchFinderScreen> createState() => _ChurchFinderScreenState();
}

class _ChurchFinderScreenState extends State<ChurchFinderScreen> {
  final MapController _mapController = MapController();
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final ChurchService _churchService = ChurchService();
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentCenter = const LatLng(17.3850, 78.4867); // Default: Hyderabad
  bool _isLoadingLocation = true;
  bool _isFetchingChurches = false;
  int _selectedIndex = -1;
  bool _isSatellite = false;
  bool _isSearchingPlace = false;

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

    // Calculate dynamic radius based on zoom/bounds
    int radius = 5000;
    try {
      final bounds = _mapController.camera.visibleBounds;
      final camCenter = _mapController.camera.center;
      // FIX: Use northEast instead of northeast
      final northEast = bounds.northEast;

      final distance =
          const Distance().as(LengthUnit.Meter, camCenter, northEast);
      radius = distance.toInt().clamp(2000, 50000);
    } catch (e) {
      // Bounds might be null initially
    }

    try {
      final results = await _churchService.fetchChurches(
        center.latitude,
        center.longitude,
        radius: radius,
      );

      final List<ChurchLocation> churchesWithDistance = results.map((church) {
        final distanceInMeters = Geolocator.distanceBetween(
          _currentCenter.latitude,
          _currentCenter.longitude,
          church.lat,
          church.lng,
        );
        return ChurchLocation(
          name: church.name,
          lat: church.lat,
          lng: church.lng,
          address: church.address,
          distance: distanceInMeters / 1000,
          imageUrl: church.imageUrl,
        );
      }).toList();

      churchesWithDistance
          .sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));

      if (mounted) {
        setState(() {
          _churches = churchesWithDistance;
          _isFetchingChurches = false;
          _selectedIndex = 0;
        });
      }
    } catch (e) {
      debugPrint("Error fetching churches: $e");
      if (mounted) setState(() => _isFetchingChurches = false);
    }
  }

  void _moveToUser() {
    _searchController.clear();
    _determinePosition();
  }

  Future<void> _searchPlace(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearchingPlace = true);

    final location = await _churchService.searchCity(query);
    if (location != null) {
      setState(() {
        // Just move map
      });
      _mapController.move(location, 13.0);
      await _fetchChurchesInArea(location);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not find "$query"')));
      }
    }
    setState(() => _isSearchingPlace = false);
  }

  void _onCardChanged(int index) {
    setState(() => _selectedIndex = index);
    if (index >= 0 && index < _churches.length) {
      final church = _churches[index];
      _mapController.move(LatLng(church.lat, church.lng), 15.0);
    }
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchGoogleMapsSearch() async {
    final center = _mapController.camera.center;
    String query = "churches";

    // If user has searched for a place, include it in the Google Maps query
    if (_searchController.text.trim().isNotEmpty) {
      query = "churches in ${_searchController.text.trim()}";
    }

    final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$query&center=${center.latitude},${center.longitude}');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _shareChurch(ChurchLocation church) {
    Share.share(
        'Check out ${church.name} at ${church.address}. \nLocation: https://www.google.com/maps/search/?api=1&query=${church.lat},${church.lng}');
  }

  @override
  Widget build(BuildContext context) {
    // Tile URL logic
    final tileUrl = _isSatellite
        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Nearby Churches'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.transparent,
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          // AppBar Action: Persistent "Open External" button
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Search on Google Maps',
            onPressed: _launchGoogleMapsSearch,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 14.0,
              onTap: (_, __) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.benayaram.holy_word_app',
              ),
              MarkerLayer(
                markers: [
                  if (!_isLoadingLocation)
                    Marker(
                      point: _currentCenter,
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.my_location,
                            color: Colors.blue, size: 30),
                      ),
                    ),
                  ..._churches.asMap().entries.map((entry) {
                    final index = entry.key;
                    final church = entry.value;
                    final isSelected = index == _selectedIndex;

                    return Marker(
                        point: LatLng(church.lat, church.lng),
                        width: 200,
                        height: 90,
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                            setState(() => _selectedIndex = index);
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.blue.shade900
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    church.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Icon(
                                Icons.location_on,
                                color: isSelected
                                    ? Colors.blue.shade900
                                    : Colors.redAccent,
                                size: isSelected ? 50 : 40,
                              ),
                            ],
                          ),
                        ));
                  }),
                ],
              ),
            ],
          ),

          // Search Box
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search city or place...',
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _isSearchingPlace
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : IconButton(
                            icon: const Icon(Icons.arrow_forward,
                                color: Colors.blue),
                            onPressed: () =>
                                _searchPlace(_searchController.text),
                          ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: _searchPlace,
                ),
              ),
            ),
          ),

          // Layer Switcher
          Positioned(
            right: 16,
            top: 170,
            child: FloatingActionButton.small(
              heroTag: 'layer_switcher',
              onPressed: () => setState(() => _isSatellite = !_isSatellite),
              backgroundColor: Colors.white,
              child: Icon(
                _isSatellite ? Icons.map : Icons.satellite_alt,
                color: Colors.black87,
              ),
            ),
          ),

          // Cards & Empty State Logic
          if (_churches.isNotEmpty && !_isFetchingChurches)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              height: 240,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _churches.length,
                onPageChanged: _onCardChanged,
                itemBuilder: (context, index) {
                  final church = _churches[index];
                  final isSelected = index == _selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: AnimatedScale(
                      scale: isSelected ? 1.0 : 0.95,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: isSelected
                              ? Border.all(
                                  color: Colors.blue.shade300, width: 2)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _mapController.move(
                                  LatLng(church.lat, church.lng), 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Image Section
                                  Expanded(
                                    flex: 3,
                                    child: church.imageUrl != null
                                        ? Image.network(
                                            church.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _buildPlaceholder(),
                                          )
                                        : _buildPlaceholder(),
                                  ),
                                  // Details Section
                                  Expanded(
                                    flex: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  church.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (church.distance != null)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                      color:
                                                          Colors.blue.shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4)),
                                                  child: Text(
                                                      '${church.distance!.toStringAsFixed(1)} km',
                                                      style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors
                                                              .blue.shade800,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                )
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Expanded(
                                            child: Text(
                                              church.address,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: SizedBox(
                                                  height: 32,
                                                  child: ElevatedButton.icon(
                                                    onPressed: () =>
                                                        _launchMaps(church.lat,
                                                            church.lng),
                                                    icon: const Icon(
                                                        Icons.directions,
                                                        size: 16),
                                                    label: const Text(
                                                        'Directions',
                                                        style: TextStyle(
                                                            fontSize: 12)),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .primaryColor,
                                                      foregroundColor:
                                                          Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              SizedBox(
                                                width: 32,
                                                height: 32,
                                                child: IconButton.filledTonal(
                                                  onPressed: () =>
                                                      _shareChurch(church),
                                                  icon: const Icon(Icons.share,
                                                      size: 16),
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Empty State Helper (Only if no results)
          if (_churches.isEmpty && !_isFetchingChurches)
            Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.church_outlined,
                          size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text("No churches in this search area.",
                          style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text("Need to look broader?",
                          style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _launchGoogleMapsSearch,
                        icon: const Icon(Icons.travel_explore),
                        label: const Text("Search on Google Maps"),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),

          if (_isFetchingChurches && !_isSearchingPlace)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 250.0),
        child: FloatingActionButton(
          onPressed: _moveToUser,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          child: const Icon(Icons.my_location),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.blue.shade100],
        ),
      ),
      child: Center(
        child: Icon(Icons.church, color: Colors.blue.shade200, size: 40),
      ),
    );
  }
}
