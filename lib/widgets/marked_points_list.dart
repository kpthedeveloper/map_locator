// lib/widgets/marked_points_list.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MarkedPointsList extends StatelessWidget {
  final List<LatLng> markedPoints;
  final List<String> pointNames;
  final Function(int) onRenamePoint;
  final Function(LatLng) onRemoveMarker;
  final Function(int oldIndex, int newIndex)
  onReorderPoints; // NEW: Callback for reordering

  const MarkedPointsList({
    super.key,
    required this.markedPoints,
    required this.pointNames,
    required this.onRenamePoint,
    required this.onRemoveMarker,
    required this.onReorderPoints, // NEW: Required in constructor
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.width > 600 ? 150.0 : 5,
      right: 20.0,
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          constraints: BoxConstraints(
            maxHeight: 400.0, // Max height for the entire list container
            maxWidth:
                MediaQuery.of(context).size.width > 600
                    ? MediaQuery.of(context).size.width * 0.25
                    : MediaQuery.of(context).size.width * .90,
          ),
          child:
              markedPoints.isEmpty
                  ? const Text("No points marked yet.")
                  : SingleChildScrollView(
                    // Allows the entire list container to scroll if contents exceed maxHeight
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 0.0,
                      ),
                      title: Text(
                        'Marked Points (${markedPoints.length})',
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // ReorderableListView will be a child of ExpansionTile
                      children: [
                        ReorderableListView.builder(
                          shrinkWrap:
                              true, // Crucial for nesting inside ExpansionTile
                          physics:
                              const NeverScrollableScrollPhysics(), // Crucial to allow parent SingleChildScrollView to handle scrolling
                          itemCount: markedPoints.length,
                          buildDefaultDragHandles: false,
                          onReorder:
                              onReorderPoints, // <-- Pass the reorder callback here
                          itemBuilder: (context, index) {
                            final point = markedPoints[index];
                            // Each item in ReorderableListView MUST have a unique key.
                            // Using ObjectKey(point) is good as it keys by object identity,
                            // which is unique for each LatLng instance in the list.
                            return Padding(
                              key: ObjectKey(
                                point,
                              ), // <-- UNIQUE KEY REQUIRED FOR REORDERABLELISTVIEW
                              padding: const EdgeInsets.symmetric(
                                vertical: 0.0,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                  vertical: 0.0,
                                ),
                                title: Text(
                                  pointNames[index],
                                  style: const TextStyle(fontSize: 14.0),
                                ),
                                subtitle: Text(
                                  '(${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})',
                                  style: const TextStyle(fontSize: 10.0),
                                ),
                                leading: CircleAvatar(
                                  radius: 12.0,
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    '${index + 1}', // Display current visual index as serial number
                                    style: const TextStyle(fontSize: 10.0),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18.0),
                                      onPressed: () {
                                        onRenamePoint(index);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_rounded,
                                        color: Colors.red,
                                        size: 18.0,
                                      ),
                                      onPressed: () {
                                        onRemoveMarker(point);
                                      },
                                    ),
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: Icon(
                                        Icons.drag_indicator_rounded,
                                        color: Colors.blue,
                                        size: 18.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
