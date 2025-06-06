import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  bool _isLocationServiceEnabled = false;
  LocationPermission _locationPermission = LocationPermission.denied;

  bool get isLocationServiceEnabled => _isLocationServiceEnabled;
  LocationPermission get locationPermission => _locationPermission;

  Future<void> checkLocationPermissions() async {
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

  Future<Position> getCurrentPosition() async {
    await checkLocationPermissions();

    if (_locationPermission == LocationPermission.denied ||
        _locationPermission == LocationPermission.deniedForever ||
        !_isLocationServiceEnabled) {
      throw Exception("Location permissions not granted or service disabled.");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
