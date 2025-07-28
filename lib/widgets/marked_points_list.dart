// lib/widgets/marked_points_list.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MarkedPointsList extends StatelessWidget {
  final List<LatLng> markedPoints;
  final List<String> pointNames;
  final Function(int) onRenamePoint;
  final Function(LatLng) onRemoveMarker;
  final Function(int oldIndex, int newIndex) onReorderPoints;
  const MarkedPointsList({
    super.key,
    required this.markedPoints,
    required this.pointNames,
    required this.onRenamePoint,
    required this.onRemoveMarker,
    required this.onReorderPoints,
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
            maxHeight: 400.0,
            maxWidth:
                MediaQuery.of(context).size.width > 600
                    ? MediaQuery.of(context).size.width * 0.25
                    : MediaQuery.of(context).size.width * .90,
          ),
          child:
              markedPoints.isEmpty
                  ? const Text("No points marked yet.")
                  : SingleChildScrollView(
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

                      children: [
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: markedPoints.length,
                          buildDefaultDragHandles: false,
                          onReorder: onReorderPoints,
                          itemBuilder: (context, index) {
                            final point = markedPoints[index];

                            return Padding(
                              key: ObjectKey(point),
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
                                    '${index + 1}',
                                    style: const TextStyle(fontSize: 10.0),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        size: 18.0,
                                        color: Colors.green,
                                      ),
                                      onPressed: () {
                                        onRenamePoint(index);
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32.0,
                                        minHeight: 32.0,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_rounded,
                                        size: 18.0,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        onRemoveMarker(point);
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32.0,
                                        minHeight: 32.0,
                                      ),
                                    ),

                                    ReorderableDragStartListener(
                                      index: index,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 0.0,
                                        ),
                                        child: const Icon(
                                          Icons.drag_indicator,
                                          color: Colors.grey,
                                          size: 24.0,
                                        ),
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
