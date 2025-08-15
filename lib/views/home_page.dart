import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapbox Map")),
      body: MapWidget(
        // styleUri: MapboxStyle.MAPBOX_STREETS,
        onMapCreated: (map) {
          // Map is ready
        },
      ),
    );
  }
}
