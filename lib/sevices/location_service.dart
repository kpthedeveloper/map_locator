import 'package:flutter/foundation.dart'; // Keep for kIsWeb if needed elsewhere in the class
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

    // Define location settings based on platform for high accuracy
    LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0, // No distance filter
        forceLocationManager: false, // Use FusedLocationProvider if available
        intervalDuration: const Duration(
          seconds: 1,
        ), // How often to get updates
        // Other Android-specific settings can be added here
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness, // Or appropriate type for your app
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: false,
        // Other iOS/macOS-specific settings can be added here
      );
    } else {
      // For web, Windows, Linux, and fallback
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }

    return await Geolocator.getCurrentPosition(
      // Use the settings parameter instead of desiredAccuracy
      locationSettings: locationSettings,
    );
  }
}
