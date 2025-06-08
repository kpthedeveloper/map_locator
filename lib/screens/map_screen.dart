import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_locator/sevices/location_service.dart';
import 'package:map_locator/utils/map_utils.dart';
import 'package:map_locator/widgets/map_controls.dart';
import 'package:map_locator/widgets/marked_points_list.dart';
import 'dart:io'; // For File operations
import 'dart:ui' as ui; // For Image operations (used for toImage)
import 'package:path_provider/path_provider.dart'; // For getting temporary directory
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart'; // For sharing
import 'package:flutter/scheduler.dart'; // Add this import for SchedulerBinding
// For RenderRepaintBoundary
import 'dart:async';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final List<Marker> _markers = [];
  final List<LatLng> _markedPoints = [];
  final List<String> _pointNames = [];
  double initialZoom = 15.0;
  final MapController mapController = MapController();
  LatLng currentCenter = const LatLng(
    50.97,
    4.95,
  ); // Initialize at Scherpenheuvel-Zichem
  LatLng? _userLocation;
  final GlobalKey _qrKey = GlobalKey();
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
      _markedPoints.add(position);
      _pointNames.add(
        'Point ${_markedPoints.length}',
      ); // Assign initial name based on new length
      _rebuildMarkersAfterReorder(); // Rebuild markers after adding
    });
  }

  void _removeMarker(LatLng position) {
    setState(() {
      final indexToRemove = _markedPoints.indexWhere(
        (p) =>
            p.latitude == position.latitude &&
            p.longitude == position.longitude,
      );
      if (indexToRemove != -1) {
        _markedPoints.removeAt(indexToRemove);
        _pointNames.removeAt(indexToRemove);
        _rebuildMarkersAfterReorder(); // Rebuild markers after removing
      }
    });
  }

  void _onReorderPoints(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1; // Adjust index when moving down
      }
      // Reorder markedPoints
      final LatLng removedPoint = _markedPoints.removeAt(oldIndex);
      _markedPoints.insert(newIndex, removedPoint);

      // Reorder pointNames (must be kept in sync)
      final String removedName = _pointNames.removeAt(oldIndex);
      _pointNames.insert(newIndex, removedName);

      // Now, rebuild the map markers to reflect the new order and serial numbers
      _rebuildMarkersAfterReorder();
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

  Future<void> _generateAndShowQrCode() async {
    if (_markedPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please mark at least one point to generate a QR code.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final String? googleMapsUrl = await MapUtils.getGoogleMapsUrl(
      _markedPoints,
    );

    if (googleMapsUrl == null || googleMapsUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not generate Google Maps link.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          // Renamed context to dialogContext for clarity
          return AlertDialog(
            title: const Text('Map Locator QR Code'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Wrap QrImageView in a RepaintBoundary with a GlobalKey
                RepaintBoundary(
                  key: _qrKey, // Assign the GlobalKey here
                  child: SizedBox(
                    width: 200.0, // Explicitly set width
                    height: 200.0, // Explicitly set height
                    child: QrImageView(
                      data: googleMapsUrl,
                      version: QrVersions.auto,
                      size:
                          200.0, // This size property affects the internal rendering of the QR code
                      gapless: false,
                      backgroundColor: Colors.white,
                      // Use eyeStyle and dataModuleStyle for coloring
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square, // Or QrEyeShape.circle
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape:
                            QrDataModuleShape
                                .square, // Or QrDataModuleShape.circle
                        color: Colors.black,
                      ),
                      errorStateBuilder: (cxt, err) {
                        return Center(
                          child: Text(
                            'Uh oh! Something went wrong: $err',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scan this QR code to open the map link.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Use dialogContext here
                },
                child: const Text('Close'),
              ),
              // Share QR button
              TextButton(
                onPressed: () async {
                  // Call the capture and share function.
                  // It will handle popping the dialog once the process is complete.
                  await _captureAndShareQrCode(dialogContext: dialogContext);
                },
                child: const Text('Share QR'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _captureAndShareQrCode({
    required BuildContext dialogContext,
  }) async {
    try {
      // Use a Completer to await the result of addPostFrameCallback.
      // This ensures the widget is rendered before attempting to capture.
      final completer = Completer<RenderRepaintBoundary?>();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        completer.complete(
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?,
        );
      });
      RenderRepaintBoundary? boundary = await completer.future;

      if (boundary == null) {
        debugPrint(
          'DEBUG: QR Code RepaintBoundary is null in addPostFrameCallback. Context: ${_qrKey.currentContext}',
        );
        if (dialogContext.mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to capture QR code image. Boundary not found.',
              ),
            ),
          );
          Navigator.of(dialogContext).pop(); // Pop on failure
        }
        return;
      }

      // Get image from boundary
      ui.Image image = await boundary.toImage(
        pixelRatio: 3.0,
      ); // Adjust pixelRatio for quality
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        if (dialogContext.mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar(
              content: Text('Failed to convert QR code to image data.'),
            ),
          );
          Navigator.of(dialogContext).pop(); // Pop on failure
        }
        return;
      }

      // Save image to a temporary file
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/qrcode.png';
      final file = File(imagePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // Share the image file
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'Check out this Google Maps link!', // Optional text
        subject: 'Map Locator QR Code', // Optional subject for email
      );

      // Pop the dialog AFTER successful capture and share
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
    } catch (e) {
      debugPrint('Error capturing or sharing QR code: ${e.toString()}');
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(content: Text('Error sharing QR code: ${e.toString()}')),
        );
        Navigator.of(dialogContext).pop(); // Pop on error as well
      }
    }
  }

  void _rebuildMarkersAfterReorder() {
    _markers.clear(); // Clear existing markers
    for (int i = 0; i < _markedPoints.length; i++) {
      final LatLng position = _markedPoints[i];
      final serialNumber =
          i + 1; // Recalculate serial number based on new order
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
                  _removeMarker(position); // Ensure tap to remove still works
                },
                behavior: HitTestBehavior.opaque,
              ),
            ],
          ),
        ),
      );
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
                  if (event is MapEventMoveEnd ||
                      event is MapEventDoubleTapZoomEnd ||
                      event is MapEventFlingAnimationEnd ||
                      event is MapEventRotateEnd ||
                      event is MapEventScrollWheelZoom) {
                    if (initialZoom < event.camera.zoom) {
                      initialZoom += 1;
                    } else if (initialZoom > event.camera.zoom) {
                      initialZoom -= 1;
                    }
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
                MapUtils.getGoogleMapsUrl(_markedPoints);
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
            onQRCodeGeneration: _generateAndShowQrCode,
            hasMarkedPoints: _markedPoints.isNotEmpty,
          ),

          MarkedPointsList(
            markedPoints: _markedPoints,
            pointNames: _pointNames,
            onRenamePoint: _renamePoint,
            onRemoveMarker: _removeMarker,
            onReorderPoints: _onReorderPoints,
          ),
        ],
      ),
    );
  }
}
