import 'dart:io';
// import 'package:geolocator_platform_interface/src/models/position.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:image_picker/image_picker.dart' as picker;

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

  // Capture image from camera
  Future<File?> captureImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: picker.ImageSource.camera);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to capture image: $e');
    }
    return null;
  }

  //Save polygon with optional image
  void savePolygon(String name, List<Point> points, {File? image, 
  required List<Position> positions}) {
    polygons.add(
      PolygonInfo(name: name, points: points, image: image),
    );
  }

  // Clear all saved polygons
  void clearPolygons() {
    polygons.clear();
    Get.snackbar('Success', 'All polygons cleared');
  }

  // Getter for saved polygons
  List<PolygonInfo> get savedPolygons => polygons.toList();
}
