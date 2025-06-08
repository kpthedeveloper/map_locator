// lib/models/map_data.dart

class MapData {
  int? id;
  String name;
  List<MapPoint> points;

  MapData({this.id, required this.name, required this.points});

  MapData.fromMap(Map<String, dynamic> map)
    : id = map['id'],
      name = map['name'],
      points =
          (map['points'] as List<dynamic>)
              .map((p) => MapPoint.fromMap(p as Map<String, dynamic>))
              .toList();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'points': points.map((p) => p.toMap()).toList(),
    };
  }
}

class MapPoint {
  double latitude;
  double longitude;
  String name;

  MapPoint({
    required this.latitude,
    required this.longitude,
    required this.name,
  });

  MapPoint.fromMap(Map<String, dynamic> map)
    : latitude = map['latitude'],
      longitude = map['longitude'],
      name = map['name'];

  Map<String, dynamic> toMap() {
    return {'latitude': latitude, 'longitude': longitude, 'name': name};
  }
}
