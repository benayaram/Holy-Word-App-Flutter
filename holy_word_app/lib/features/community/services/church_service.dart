import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ChurchLocation {
  final String name;
  final double lat;
  final double lng;
  final String address;
  final double? distance;

  ChurchLocation({
    required this.name,
    required this.lat,
    required this.lng,
    required this.address,
    this.distance,
  });

  factory ChurchLocation.fromJson(Map<String, dynamic> json) {
    final tags = json['tags'] ?? {};
    final lat = json['lat'] as double;
    final lng = json['lon'] as double;

    // Try to construct a readable address/location
    final street = tags['addr:street'] ?? '';
    final city = tags['addr:city'] ?? '';
    final location = [street, city].where((s) => s.isNotEmpty).join(', ');

    return ChurchLocation(
      name: tags['name'] ?? 'Church',
      lat: lat,
      lng: lng,
      address: location.isNotEmpty ? location : 'Location available on map',
    );
  }
}

class ChurchService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  Future<List<ChurchLocation>> fetchChurches(double lat, double lng,
      {int radius = 5000}) async {
    try {
      // Query for nodes with amenity=place_of_worship AND religion=christian
      // using [out:json];
      final String query = """
        [out:json][timeout:25];
        (
          node["amenity"="place_of_worship"]["religion"="christian"](around:$radius,$lat,$lng);
        );
        out body;
        >;
        out skel qt;
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
            .where((church) =>
                church.name !=
                'Church') // Optional: Filter out unnamed if desired, but "Church" is fallback
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
}
