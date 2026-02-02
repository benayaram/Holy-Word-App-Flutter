import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class ChurchLocation {
  final String name;
  final double lat;
  final double lng;
  final String address;
  final double? distance;
  final String? imageUrl; // Added image URL

  ChurchLocation({
    required this.name,
    required this.lat,
    required this.lng,
    required this.address,
    this.distance,
    this.imageUrl,
  });

  factory ChurchLocation.fromJson(Map<String, dynamic> json) {
    final tags = json['tags'] ?? {};
    double lat;
    double lng;

    if (json.containsKey('center')) {
      lat = json['center']['lat'];
      lng = json['center']['lon'];
    } else {
      lat = json['lat'] ?? 0.0;
      lng = json['lon'] ?? 0.0;
    }

    // Try to construct a readable address/location
    final street = tags['addr:street'] ?? '';
    final city = tags['addr:city'] ?? '';
    final location = [street, city].where((s) => s.isNotEmpty).join(', ');

    // Extract image tag if available (image, wikipedia image, etc could be complex, sticking to simple 'image' tag for now)
    String? imgUrl = tags['image'];

    // Some OSM data uses 'wikimedia_commons' but parsing that requires another API call usually.
    // We will stick to direct 'image' or 'url' or 'website' if needed, but 'image' is safest for direct display.

    return ChurchLocation(
      name: tags['name'] ?? 'Church',
      lat: lat,
      lng: lng,
      address: location.isNotEmpty ? location : 'Location available on map',
      imageUrl: imgUrl,
    );
  }
}

class ChurchService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const String _nominatimUrl =
      'https://nominatim.openstreetmap.org/search';

  Future<List<ChurchLocation>> fetchChurches(double lat, double lng,
      {int radius = 5000}) async {
    try {
      // Query for nodes, ways, and relations with amenity=place_of_worship AND religion=christian
      final String query = """
        [out:json][timeout:90];
        (
          node["amenity"="place_of_worship"]["religion"="christian"](around:$radius,$lat,$lng);
          way["amenity"="place_of_worship"]["religion"="christian"](around:$radius,$lat,$lng);
          relation["amenity"="place_of_worship"]["religion"="christian"](around:$radius,$lat,$lng);
          node["building"="church"](around:$radius,$lat,$lng);
          way["building"="church"](around:$radius,$lat,$lng);
          relation["building"="church"](around:$radius,$lat,$lng);
        );
        out center;
      """;

      final response = await http.post(
        Uri.parse(_overpassUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'data=$query',
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final elements = data['elements'] as List;

        return elements
            .map((e) => ChurchLocation.fromJson(e))
            .where((church) => church.name != 'Church')
            .toList();
      } else {
        debugPrint('Overpass API Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching churches: $e');
      return [];
    }
  }

  Future<LatLng?> searchCity(String query) async {
    try {
      final url = Uri.parse('$_nominatimUrl?q=$query&format=json&limit=1');
      // Nominatim requires a User-Agent
      final response =
          await http.get(url, headers: {'User-Agent': 'HolyWordApp/1.0'});

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lng = double.parse(data[0]['lon']);
          return LatLng(lat, lng);
        }
      }
    } catch (e) {
      debugPrint('Error searching city: $e');
    }
    return null;
  }
}
