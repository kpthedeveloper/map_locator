import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final List<Marker> _markers = [];
  double initialZoom = 13;
  final MapController mapController = MapController();
  LatLng currentCenter = LatLng(
    50.97,
    4.95,
  ); // Initialize at Scherpenheuvel-Zichem
  bool _isLocationServiceEnabled = false;
  LocationPermission _locationPermission = LocationPermission.denied;
  bool _locationReceived = false;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _checkLocationPermissions();
    _getLocation(); // Call get location in init state
  }

  Future<void> _checkLocationPermissions() async {
    _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_isLocationServiceEnabled) {
      return;
    }

    _locationPermission = await Geolocator.checkPermission();
    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
      if (_locationPermission == LocationPermission.denied) {
        return;
      }
    }

    if (_locationPermission == LocationPermission.deniedForever) {
      return;
    }
  }

  Future<void> _getLocation() async {
    try {
      await _checkLocationPermissions();

      if (_locationPermission == LocationPermission.denied ||
          _locationPermission == LocationPermission.deniedForever ||
          !_isLocationServiceEnabled) {
        if (kIsWeb) {
          setState(() {
            _locationReceived = true;
          });
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final LatLng newCenter = LatLng(position.latitude, position.longitude);
      //print("(*********** User's location: $newCenter");
      setState(() {
        _userLocation = newCenter;
        currentCenter = newCenter;
        mapController.move(
          newCenter,
          initialZoom,
        ); // Move map to user's location
        _locationReceived = true;
      });
    } catch (e) {
      //print("Error getting location: $e");
      if (kIsWeb) {
        setState(() {
          _locationReceived = true;
        });
      }
    }
  }

  void _addMarker(LatLng position) {
    setState(() {
      _markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: position,
          child: GestureDetector(
            onTap: () {
              _removeMarker(position); // Remove marker on tap
            },
            child: const Icon(
              Icons.location_pin,
              color: Colors.blue,
              size: 40.0,
            ),
          ),
        ),
      );
    });
  }

  void _removeMarker(LatLng position) {
    setState(() {
      _markers.removeWhere(
        (marker) =>
            marker.point.latitude == position.latitude &&
            marker.point.longitude == position.longitude,
      );
    });
  }

  void _launchGoogleMaps(List<LatLng> positions) async {
    if (positions.isEmpty) return; // Add this check
    String googleMapsUrl;
    if (positions.length == 1) {
      googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=${positions.first.latitude},${positions.first.longitude}';
    } else {
      // Build URL for multiple points (directions)
      googleMapsUrl = 'https://www.google.com/maps/dir/';
      for (int i = 0; i < positions.length; i++) {
        googleMapsUrl += '${positions[i].latitude},${positions[i].longitude}/';

        if (i < positions.length - 1) {
          googleMapsUrl +=
              '/'; // Add slash between coordinates, but not after the last
        }
      }
    }
    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl));
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
  }

  void _centerMapToUser() {
    if (_userLocation != null) {
      setState(() {
        currentCenter = _userLocation!;
        mapController.move(_userLocation!, initialZoom);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geo Marker App')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: currentCenter,
              initialZoom: initialZoom,
              onLongPress: (tapPosition, point) {
                _addMarker(point); // Add a marker on long press
              },
              onMapEvent: (MapEvent event) {
                setState(() {
                  if (event is MapEventMove) {
                    currentCenter = event.camera.center;
                  }
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: _userLocation!,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40.0,
                      ),
                    ),
                  ..._markers,
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 50.0,
            left: 20.0,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _markers.clear(); // Clear all markers
                });
              },
              child: const Icon(Icons.delete),
            ),
          ),
          Positioned(
            bottom: 120.0,
            left: 20.0,
            child: FloatingActionButton(
              onPressed: () {
                if (_markers.isNotEmpty) {
                  _launchGoogleMaps(
                    _markers.map((marker) => marker.point).toList(),
                  );
                }
              },
              child: const Icon(Icons.ios_share_rounded),
            ),
          ),
          Positioned(
            bottom: 190.0,
            right: 20.0,
            child: FloatingActionButton(
              onPressed: _centerMapToUser,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            bottom: 120.0,
            right: 20.0,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  initialZoom++; // Increase zoom level
                  mapController.move(currentCenter, initialZoom);
                });
              },
              child: const Icon(Icons.zoom_in_rounded),
            ),
          ),
          Positioned(
            bottom: 50.0,
            right: 20.0,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  initialZoom--; // Decrease zoom level
                  mapController.move(currentCenter, initialZoom);
                });
              },
              child: const Icon(Icons.zoom_out_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
