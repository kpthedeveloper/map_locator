import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final List<Marker> _markers = [];
  final List<LatLng> _markedPoints = []; // To store the order of added points
  final List<String> _pointNames = []; // To store the names of the points
  double initialZoom = 15;
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
      final serialNumber = _markers.length + 1;
      _markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: position,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.location_pin, color: Colors.blue, size: 40.0),
              Positioned(
                bottom: 5.0,
                child: Text(
                  '$serialNumber',
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _removeMarker(position); // Remove marker on tap
                },
                behavior:
                    HitTestBehavior.opaque, // Make the whole stack tappable
              ),
            ],
          ),
        ),
      );
      _markedPoints.add(position); // Add the point to the ordered list
      _pointNames.add('Point $serialNumber'); // Initialize with default name
    });
  }

  void _removeMarker(LatLng position) {
    setState(() {
      final indexToRemove = _markers.indexWhere(
        (marker) =>
            marker.point.latitude == position.latitude &&
            marker.point.longitude == position.longitude,
      );
      if (indexToRemove != -1) {
        _markers.removeAt(indexToRemove);
        _markedPoints.removeAt(indexToRemove);
        _pointNames.removeAt(indexToRemove);
        // Rebuild the serial numbers for the remaining markers
        for (int i = 0; i < _markers.length; i++) {
          final newMarker = Marker(
            width: 80.0,
            height: 80.0,
            point: _markers[i].point,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.location_pin, color: Colors.blue, size: 40.0),
                Positioned(
                  bottom: 5.0,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _removeMarker(_markers[i].point);
                  },
                  behavior: HitTestBehavior.opaque,
                ),
              ],
            ),
          );
          _markers[i] = newMarker;
        }
      }
    });
  }

  void _renamePoint(int index) async {
    final TextEditingController controller = TextEditingController(
      text: _pointNames[index],
    );
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rename Point'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter new name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _pointNames[index] = controller.text;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
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
        googleMapsUrl += '${positions[i].latitude},${positions[i].longitude}';

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
                  _markedPoints.clear(); // Clear the list of marked points
                  _pointNames.clear(); // Clear the list of point names
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
          // Floating list of marked points
          Positioned(
            top: 150.0,
            right: 20.0,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                constraints: BoxConstraints(
                  maxHeight: 400.0, // Adjust as needed
                  maxWidth:
                      MediaQuery.of(context).size.width * 0.25, // Adjust width
                ),
                child:
                    _markedPoints.isEmpty
                        ? const Text("No points marked yet.")
                        : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _markedPoints.length,
                          itemBuilder: (context, index) {
                            final point = _markedPoints[index];
                            return ListTile(
                              title: Text(_pointNames[index]),
                              subtitle: Text(
                                '(${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})',
                                style: const TextStyle(fontSize: 12.0),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(fontSize: 12.0),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      _renamePoint(index);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _removeMarker(point);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
