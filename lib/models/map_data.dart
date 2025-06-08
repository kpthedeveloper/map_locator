// lib/models/map_data.dart

class MapData {
  int? id;
  String name;
  List<MapPoint> points;
  DateTime createdOn;
  DateTime lastModifiedOn;

  MapData({
    this.id,
    required this.name,
    required this.points,
    DateTime? createdOn,
    DateTime? lastModifiedOn,
  }) : createdOn = createdOn ?? DateTime.now(),
       lastModifiedOn = lastModifiedOn ?? DateTime.now();

  MapData.fromMap(Map<String, dynamic> map)
    : id = map['id'] as int?,
      name = map['name'] as String,
      points =
          (map['points'] as List<dynamic>)
              .map((p) => MapPoint.fromMap(p as Map<String, dynamic>))
              .toList(),

      createdOn =
          map['createdOn'] != null
              ? DateTime.parse(map['createdOn'] as String)
              : DateTime.now(),
      lastModifiedOn =
          map['lastModifiedOn'] != null
              ? DateTime.parse(map['lastModifiedOn'] as String)
              : DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'points': points.map((p) => p.toMap()).toList(),
      'createdOn': createdOn.toIso8601String(),
      'lastModifiedOn': lastModifiedOn.toIso8601String(),
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
