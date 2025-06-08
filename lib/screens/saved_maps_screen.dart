// lib/screens/saved_maps_screen.dart

import 'package:flutter/material.dart';
import 'package:map_locator/utils/database_helper.dart';
import 'package:map_locator/models/map_data.dart';

class SavedMapsScreen extends StatefulWidget {
  // --- FIX THIS LINE: Change the type of onLoadMap to accept MapData ---
  final Function(MapData) onLoadMap;

  const SavedMapsScreen({super.key, required this.onLoadMap});

  @override
  SavedMapsScreenState createState() => SavedMapsScreenState();
}

class SavedMapsScreenState extends State<SavedMapsScreen> {
  // ... (rest of your SavedMapsScreenState class remains the same) ...
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
                  subtitle: Text('${map.points.length} points'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await DatabaseHelper.instance.deleteMap(map.id!);
                      setState(() {
                        _mapsFuture =
                            DatabaseHelper.instance
                                .getMaps(); // Refresh the list
                      });
                    },
                  ),
                  onTap: () {
                    // This part is already correct as it passes the whole map object
                    widget.onLoadMap(map);
                    Navigator.of(context).pop(); // Go back to the map screen
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
