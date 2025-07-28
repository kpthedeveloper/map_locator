// lib/utils/map_utils.dart
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapUtils {
  static Future<String?> getGoogleMapsUrl(List<LatLng> points) async {
    if (points.isEmpty) {
      return null;
    }

    if (points.length == 1) {
      final LatLng point = points.first;

      final String geoUri =
          'geo:${point.latitude},${point.longitude}?q=${point.latitude},${point.longitude}(Marked Point)';

      if (await canLaunchUrl(Uri.parse(geoUri))) {
        return geoUri;
      } else {
        return 'https://www.google.com/maps/search/?api=1&query=${point.latitude},${point.longitude}';
      }
    } else {
      String destination = '${points.last.latitude},${points.last.longitude}';
      String waypoints = points
          .sublist(0, points.length - 1)
          .map((p) => '${p.latitude},${p.longitude}')
          .join('|');

      return 'https://www.google.com/maps/dir/?api=1&destination=$destination&waypoints=$waypoints';
    }
  }
}
