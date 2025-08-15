import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../controllers/polygon_controller.dart';
import '../views/saved_polygon.dart';

class PolygonDetailsSheet extends StatefulWidget {
  final PolygonController polygonController;
  final List<Point> points;

  const PolygonDetailsSheet({
    super.key,
    required this.polygonController,
    required this.points,
  });

  @override
  State<PolygonDetailsSheet> createState() => _PolygonDetailsSheetState();
}

class _PolygonDetailsSheetState extends State<PolygonDetailsSheet> {
  final TextEditingController nameController = TextEditingController();
  File? capturedImage;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Polygon Name'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  capturedImage == null ? 'Capture Image' : 'Retake Image',
                ),
                onPressed: () async {
                  final image = await widget.polygonController.captureImage();
                  if (image != null) {
                    setState(() {
                      capturedImage = image;
                    });
                  }
                },
              ),
              if (capturedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Image.file(capturedImage!, height: 100),
                ),
              const SizedBox(height: 12),

              // Complete Polygon Button
              // ElevatedButton.icon(
              //   icon: const Icon(Icons.check),
              //   label: const Text('Complete Polygon'),
              //   onPressed: () async {
              //     // await widget.polygonController.completePolygon();
              //     Get.snackbar('Polygon', 'Polygon completed on map');
              //   },
              // ),
              const SizedBox(height: 12),

              // Save Polygon Button
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save Polygon'),
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    Get.snackbar('Error', 'Please enter a name');
                    return;
                  }

                  widget.polygonController.savePolygon(
                    name,
                    widget.points,
                    image: capturedImage,
                    positions: widget.points.map((p) => p.coordinates).toList(),
                  );

                  Get.back();
                  Get.to(() => SavedPolygonsView());
                  Get.snackbar('Saved', 'Polygon saved successfully');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
