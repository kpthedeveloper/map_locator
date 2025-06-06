import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_locator/sevices/location_service.dart';
import 'package:map_locator/utils/map_utils.dart';
import 'package:map_locator/widgets/map_controls.dart';
import 'package:map_locator/widgets/marked_points_list.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final List<Marker> _markers = [];
  final List<LatLng> _markedPoints = [];
  final List<String> _pointNames = [];
  double initialZoom = 15;
  final MapController mapController = MapController();
  LatLng currentCenter = const LatLng(
    50.97,
    4.95,
  ); // Initialize at Scherpenheuvel-Zichem
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    final locationService = LocationService();
    await locationService.checkLocationPermissions();

    if (!locationService.isLocationServiceEnabled ||
        locationService.locationPermission == LocationPermission.denied ||
        locationService.locationPermission ==
            LocationPermission.deniedForever) {
      if (kIsWeb) {
        setState(() {}); // Trigger rebuild for web
      }
      return;
    }

    try {
      final position = await locationService.getCurrentPosition();
      final LatLng newCenter = LatLng(position.latitude, position.longitude);
      setState(() {
        _userLocation = newCenter;
        currentCenter = newCenter;
        mapController.move(newCenter, initialZoom);
      });
    } catch (e) {
      if (kIsWeb) {
        setState(() {}); // Trigger rebuild for web
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
                  _removeMarker(position);
                },
                behavior: HitTestBehavior.opaque,
              ),
            ],
          ),
        ),
      );
      _markedPoints.add(position);
      _pointNames.add('Point $serialNumber');
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
                _addMarker(point);
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
                tileProvider: CancellableNetworkTileProvider(),
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
          // Using the new MapControls widget
          MapControls(
            onClearMarkers: () {
              setState(() {
                _markers.clear();
                _markedPoints.clear();
                _pointNames.clear();
              });
            },
            onShareMarkers: () {
              if (_markedPoints.isNotEmpty) {
                MapUtils.launchGoogleMaps(_markedPoints);
              }
            },
            onCenterToUser: _centerMapToUser,
            onZoomIn: () {
              setState(() {
                initialZoom++;
                mapController.move(currentCenter, initialZoom);
              });
            },
            onZoomOut: () {
              setState(() {
                initialZoom--;
                mapController.move(currentCenter, initialZoom);
              });
            },
            hasMarkedPoints: _markedPoints.isNotEmpty,
          ),

          MarkedPointsList(
            markedPoints: _markedPoints,
            pointNames: _pointNames,
            onRenamePoint: _renamePoint,
            onRemoveMarker: _removeMarker,
          ),
        ],
      ),
    );
  }
}
