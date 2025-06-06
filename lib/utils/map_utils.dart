import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapUtils {
  static Future<void> launchGoogleMaps(List<LatLng> positions) async {
    if (positions.isEmpty) return;

    String googleMapsUrl;
    if (positions.length == 1) {
      googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=${positions.first.latitude},${positions.first.longitude}';
    } else {
      // For multiple points, Google Maps "Directions" API is more suitable
      // or you can create a custom URL for displaying multiple markers if needed.
      // This example focuses on navigating to the first point or a single point.
      // For a more robust multi-point solution, consider Google Maps SDK or a more complex URL.
      googleMapsUrl = 'https://www.google.com/maps/dir/';
      for (int i = 0; i < positions.length; i++) {
        googleMapsUrl += '${positions[i].latitude},${positions[i].longitude}';
        if (i < positions.length - 1) {
          googleMapsUrl += '/';
        }
      }
    }

    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl));
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
  }
}
