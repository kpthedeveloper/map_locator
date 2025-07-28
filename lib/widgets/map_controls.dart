import 'package:flutter/material.dart';

class MapControls extends StatelessWidget {
  final VoidCallback onCenterToUser;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const MapControls({
    super.key,

    required this.onCenterToUser,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.end,

            children: [
              FloatingActionButton(
                heroTag: 'centerToUser',
                onPressed: onCenterToUser,
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
              const SizedBox(height: 20.0),

              FloatingActionButton(
                heroTag: 'zoomIn',
                onPressed: onZoomIn,
                child: const Icon(Icons.zoom_in_rounded),
              ),
              const SizedBox(height: 20.0),

              FloatingActionButton(
                heroTag: 'zoomOut',
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
