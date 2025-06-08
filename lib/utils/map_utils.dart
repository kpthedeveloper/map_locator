// lib/utils/map_utils.dart
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart'; // Ensure this is imported here

class MapUtils {
  static Future<String?> getGoogleMapsUrl(List<LatLng> points) async {
    if (points.isEmpty) {
      return null;
    }

    if (points.length == 1) {
      final LatLng point = points.first;
      // For a single point, try the geo URI scheme first.
      // This is often good for triggering an app picker on Android.
      // On iOS, geo: URIs might not work as expected or simply open Apple Maps if registered.
      final String geoUri =
          'geo:${point.latitude},${point.longitude}?q=${point.latitude},${point.longitude}(Marked Point)';

      // Check if the geo URI can be launched.
      // If not (e.g., on iOS, web, or some desktops), fallback to a more universal Google Maps web link.
      if (await canLaunchUrl(Uri.parse(geoUri))) {
        return geoUri;
      } else {
        // Fallback for platforms where geo: is not well supported.
        // This will open Google Maps web or the Google Maps app if installed on iOS.
        return 'https://www.google.com/maps/search/?api=1&query=${point.latitude},${point.longitude}';
      }
    } else {
      // For multiple points, Google Maps directions URL is the most robust and
      // often triggers an app chooser on Android devices.
      // iOS will typically open Google Maps if installed, or Safari to Google Maps.
      String destination = '${points.last.latitude},${points.last.longitude}';
      String waypoints = points
          .sublist(
            0,
            points.length - 1,
          ) // All points except the last one as waypoints
          .map((p) => '${p.latitude},${p.longitude}')
          .join('|');

      // The 'api=1' parameter indicates the URL is for an API, which can help
      // in opening the app directly. 'dir' is for directions.
      return 'https://www.google.com/maps/dir/?api=1&destination=$destination&waypoints=$waypoints';
    }
  }
}
