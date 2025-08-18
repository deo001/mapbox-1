import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/polygon_controller.dart';
import 'map_view.dart';

class SavedPolygonsView extends StatelessWidget {
  final PolygonController polygonController = Get.find();

  SavedPolygonsView({super.key});

  get point => ControllerCallback;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Polygons')),
      body: Obx(() {
        if (polygonController.polygons.isEmpty) {
          return const Center(child: Text('No saved polygons.'));
        }
        return ListView.builder(
          itemCount: polygonController.polygons.length,
          itemBuilder: (context, index) {
            final poly = polygonController.polygons[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: GestureDetector(
                child: ExpansionTile(
                  leading: poly.image != null
                      ? Image.file(File(poly.image!.path),
                      width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.map),
                  title: Text(poly.name),
                  subtitle: Text('Points: ${poly.points.length}'),
                  children: poly.points.map((p) {
                    // Assuming your points store extra info as a Map or object
                    final lat = p.coordinates[1];
                    final lng = p.coordinates[0];
                    // If you stored altitude/accuracy, retrieve here; otherwise just show lat/lng
                    return ListTile(
                      title: Text('Lat: ${lat?.toStringAsFixed(6)}, Lng: ${lng?.toStringAsFixed(6)}'),
                      // subtitle: Text('Alt: ${p.altitude}, Acc: ${p.accuracy}'),
                    );
                  }).toList(),
                ),
                onTap: (){

                },
              ),
            );
          },
        );

      }),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.home),
          label: const Text('Back to Map'),
          onPressed: () => Get.offAll(() => MapView()),
        ),
      ),
    );
  }
}
