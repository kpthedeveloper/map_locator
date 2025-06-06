import 'package:flutter/material.dart';

class MapControls extends StatelessWidget {
  final VoidCallback onClearMarkers;
  final VoidCallback onShareMarkers;
  final VoidCallback onCenterToUser;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final bool hasMarkedPoints; // New parameter to indicate if points are marked

  const MapControls({
    super.key,
    required this.onClearMarkers,
    required this.onShareMarkers,
    required this.onCenterToUser,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.hasMarkedPoints, // Initialize the new parameter
  });

  @override
  Widget build(BuildContext context) {
    // Determine the color for the share icon and if the button should be enabled
    final Color shareIconColor = hasMarkedPoints ? Colors.green : Colors.grey;
    final VoidCallback? shareOnPressed =
        hasMarkedPoints ? onShareMarkers : null;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Share Markers button
              FloatingActionButton(
                heroTag: 'googleMaps',
                onPressed: shareOnPressed, // Use the conditional onPressed
                child: Icon(
                  Icons.pin_drop,
                  color: shareIconColor,
                ), // Use conditional color
              ),

              const SizedBox(height: 20.0), // Spacing between buttons
              FloatingActionButton(
                heroTag: 'clearMarkers',
                onPressed: onClearMarkers,
                child: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            // Use a Column to stack the FABs
            children: [
              FloatingActionButton(
                heroTag: 'centerToUser', // Unique tag
                onPressed: onCenterToUser,
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
              const SizedBox(height: 20.0), // Spacing between buttons
              // Zoom In button
              FloatingActionButton(
                heroTag: 'zoomIn', // Unique tag
                onPressed: onZoomIn,
                child: const Icon(Icons.zoom_in_rounded),
              ),
              const SizedBox(height: 20.0), // Spacing between buttons
              // Zoom Out button
              FloatingActionButton(
                heroTag: 'zoomOut', // Unique tag
                onPressed: onZoomOut,
                child: const Icon(Icons.zoom_out_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
