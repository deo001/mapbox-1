import 'dart:io';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:flutter/material.dart';

class PolygonInfo {
  final String name;
  final List<Point> points;
  final File? image;

  PolygonInfo({
    required this.name,
    required this.points,
    this.image,
  });
}

class PolygonController extends GetxController {
  var polygons = <PolygonInfo>[].obs;
  final picker.ImagePicker _picker = picker.ImagePicker();

  PolygonAnnotationManager? _polygonManager; // store the manager here

  // Capture image from camera
  Future<File?> captureImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: picker.ImageSource.camera,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to capture image: $e');
    }
    return null;
  }

  // Save polygon with optional image
  void savePolygon(String name, List<Point> points, {File? image, required List<Position> positions}) {
    polygons.add(PolygonInfo(name: name, points: points, image: image));
  }

  // Clear all saved polygons
  void clearPolygons() {
    polygons.clear();
    _polygonManager?.deleteAll();
    Get.snackbar('Success', 'All polygons cleared');
  }

  Future<void> onMapCreated(MapboxMap mapboxMap) async {
    _polygonManager =
    await mapboxMap.annotations.createPolygonAnnotationManager();

    await _drawSamplePolygons();
  }

  Future<void> _drawSamplePolygons() async {
    polygons.clear();
    await _polygonManager?.deleteAll();

    final polygonsToDraw = [
      _createRectangle(
        center: Position(39.2300, -6.7800),
        width: 0.002,
        height: 0.001,
        color: Colors.blue,
      ),
      _createRectangle(
        center: Position(39.2320, -6.7810),
        width: 0.0015,
        height: 0.0008,
        color: Colors.green,
      ),
      _createRectangle(
        center: Position(39.2280, -6.7790),
        width: 0.001,
        height: 0.002,
        color: Colors.orange,
      ),
      _createRectangle(
        center: Position(39.2330, -6.7785),
        width: 0.0022,
        height: 0.0012,
        color: Colors.purple,
      ),
    ];

    for (final polygon in polygonsToDraw) {
      await _polygonManager?.create(polygon);
    }
  }

  // Future<void> _drawSamplePolygons() async {
  //   if (_polygonManager == null) return;
  //
  //   await _polygonManager!.deleteAll(); // clear old polygons
  //
  //   for (final polyInfo in polygons) {
  //     final coordinates = [
  //       polyInfo.points.map((p) => Position(p.coordinates[1]!, p.coordinates[0]!)).toList()// lat, lng
  //
  //   ];
  //     await _polygonManager!.create(
  //       PolygonAnnotationOptions(
  //         geometry: Polygon(coordinates: coordinates),
  //         fillColor: Colors.blue.withOpacity(0.5).value,
  //         fillOutlineColor: Colors.blue.value,
  //         fillOpacity: 0.7,
  //       ),
  //     );
  //   }
  // }

  PolygonAnnotationOptions _createRectangle({
    required Position center,
    required double width,
    required double height,
    required Color color,
  }) {
    final halfWidth = width / 2;
    final halfHeight = height / 2;

    final coordinates = [
      Position(center.lng - halfWidth, center.lat - halfHeight),
      Position(center.lng + halfWidth, center.lat - halfHeight),
      Position(center.lng + halfWidth, center.lat + halfHeight),
      Position(center.lng - halfWidth, center.lat + halfHeight),
      Position(center.lng - halfWidth, center.lat - halfHeight),
    ];

    return PolygonAnnotationOptions(
      geometry: Polygon(coordinates: [coordinates]),
      fillColor: color.withOpacity(0.5).value,
      fillOutlineColor: color.value,
      fillOpacity: 0.7,
    );
  }

  List<PolygonInfo> get savedPolygons => polygons.toList();

  Future<void> drawPolygonsOnMap() async {

  }

}
