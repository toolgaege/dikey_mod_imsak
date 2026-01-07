class PlaceModel {
  final String id;
  final String country;
  final String region;
  final String city;
  final double latitude;
  final double longitude;

  PlaceModel({
    required this.id,
    required this.country,
    required this.region,
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id']?.toString() ?? '',
      country: json['country'] ?? '',
      region: json['region'] ?? '',
      city: json['city'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'country': country,
      'region': region,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String getFullName() {
    final parts = <String>[];
    if (city.isNotEmpty) parts.add(city);
    if (region.isNotEmpty && region != city) parts.add(region);
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }

  String getShortName() {
    return city.isNotEmpty ? city : region;
  }
}
