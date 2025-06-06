import 'package:flutter/material.dart';

class MapControls extends StatelessWidget {
  final VoidCallback onClearMarkers;
  final VoidCallback onShareMarkers;
  final VoidCallback onCenterToUser;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const MapControls({
    super.key,
    required this.onClearMarkers,
    required this.onShareMarkers,
    required this.onCenterToUser,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'clearMarkers',
                onPressed: onClearMarkers,
                child: const Icon(Icons.delete),
              ),
              const SizedBox(height: 20.0), // Spacing between buttons
              // Share Markers button
              FloatingActionButton(
                heroTag: 'shareMarkers',
                onPressed: onShareMarkers,
                child: const Icon(Icons.ios_share_rounded),
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
                child: const Icon(Icons.my_location),
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
