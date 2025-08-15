import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/polygon_controller.dart';
import 'map_view.dart';

class SavedPolygonsView extends StatelessWidget {
  final PolygonController polygonController = Get.find();

  SavedPolygonsView({super.key});

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
              child: ListTile(
                
                leading: poly.image != null
                    ? Image.file(File(poly.image!.path),
                        width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.map),
                title: Text(poly.name),
                subtitle: Text('Points: ${poly.points.length}'),
                trailing: Expanded(
                  child: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      polygonController.polygons.removeAt(index);
                      Get.snackbar('Deleted', 'Polygon "${poly.name}" removed');
                    },
                  ),
                ),
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
