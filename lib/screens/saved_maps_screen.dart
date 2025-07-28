// lib/screens/saved_maps_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:map_locator/utils/database_helper.dart';
import 'package:map_locator/models/map_data.dart';

class SavedMapsScreen extends StatefulWidget {
  final Function(MapData) onLoadMap;

  const SavedMapsScreen({super.key, required this.onLoadMap});

  @override
  SavedMapsScreenState createState() => SavedMapsScreenState();
}

class SavedMapsScreenState extends State<SavedMapsScreen> {
  late Future<List<MapData>> _mapsFuture;

  @override
  void initState() {
    super.initState();
    _mapsFuture = DatabaseHelper.instance.getMaps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Maps')),
      body: FutureBuilder<List<MapData>>(
        future: _mapsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final maps = snapshot.data!;
            if (maps.isEmpty) {
              return const Center(child: Text('No maps saved yet.'));
            }
            return ListView.builder(
              itemCount: maps.length,
              itemBuilder: (context, index) {
                final map = maps[index];
                return ListTile(
                  title: Text(map.name),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${map.points.length} point(s)'),
                      Text(
                        'Modified: ${DateFormat('dd MMM yy hh:mm').format(map.lastModifiedOn.toLocal())}',
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await DatabaseHelper.instance.deleteMap(map.id!);
                      setState(() {
                        _mapsFuture = DatabaseHelper.instance.getMaps();
                      });
                    },
                  ),
                  onTap: () {
                    widget.onLoadMap(map);
                    Navigator.of(context).pop();
                  },
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
