import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../controllers/polygon_controller.dart';

class MapController extends GetxController {
  // -------------------- STATE --------------------
  MapboxMap? mapboxMap;
  final isLoading = true.obs;
  final currentPosition = Rxn<Point>();
  final polygonPoints = <Point>[].obs;
  final locationDetails = <Map<String, dynamic>>[].obs;
  final showDetails = false.obs;

  // Annotation Managers
  PolylineAnnotationManager? polylineManager;
  PolygonAnnotationManager? polygonManager;
  CircleAnnotationManager? circleManager;

  // Polygon Controller
  final PolygonController polygonController = Get.put(PolygonController());

  // Offline Map Variables

  final isOfflineMode = false.obs; // whether user wants offline map


  void switchToOnline() {
    isOfflineMode.value = false;
    update();
  }

  // -------------------- LIFECYCLE --------------------
  @override
  void onInit() {
    super.onInit();
    _initLocationTracking();

    ever<List<Point>>(polygonPoints, _drawPolyline);
    ever<Point?>(currentPosition, _updateCurrentPositionMarker);
  }

  // -------------------- LOCATION --------------------
  Future<void> _initLocationTracking() async {
    if (!await geo.Geolocator.isLocationServiceEnabled()) return;

    var permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) return;
    }
    if (permission == geo.LocationPermission.deniedForever) return;

    await _setCurrentPosition();
    isLoading.value = false;

    geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen((pos) {
      _setCurrentPositionFromGeo(pos);
      // _moveCameraToCurrentPosition();
    });
  }

  Future<void> _setCurrentPosition() async {
    final pos = await geo.Geolocator.getCurrentPosition(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
      ),
    );
    _setCurrentPositionFromGeo(pos);
  }

  void _setCurrentPositionFromGeo(geo.Position pos) {
    currentPosition.value = Point(
      coordinates: Position(pos.longitude, pos.latitude),
    );
  }


  // -------------------- MAP INIT --------------------
  Future<void> onMapCreated(MapboxMap map) async {
    mapboxMap = map;
    polylineManager = await map.annotations.createPolylineAnnotationManager();
    polygonManager = await map.annotations.createPolygonAnnotationManager();
    circleManager = await map.annotations.createCircleAnnotationManager();
    if (currentPosition.value != null) {
      _updateCurrentPositionMarker(currentPosition.value);
    }
  }

  // -------------------- ANNOTATIONS --------------------
  Future<void> _updateCurrentPositionMarker(Point? point) async {
    if (point == null || circleManager == null) return;
    await circleManager!.deleteAll();
    await circleManager!.create(
      CircleAnnotationOptions(
        geometry: point,
        circleRadius: 8,
        circleColor: Colors.blue.value,
      ),
    );
  }

  Future<void> _drawPolyline(List<Point> points) async {
    if (polylineManager == null) return;
    await polylineManager!.deleteAll();
    if (points.isNotEmpty) {
      await polylineManager!.create(
        PolylineAnnotationOptions(
          geometry: LineString(
            coordinates: points.map((p) => p.coordinates).toList(),
          ),
          lineColor: Colors.blue.value,
          lineWidth: 4.0,
        ),
      );
    }
  }

  // -------------------- POLYGON --------------------
  void addCurrentPoint() {
    if (currentPosition.value == null) return;
    polygonPoints.add(currentPosition.value!);

    geo.Geolocator.getCurrentPosition(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
      ),
    ).then((pos) {
      locationDetails.add({
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'altitude': pos.altitude,
        'accuracy': pos.accuracy,
      });
      showDetails.value = true;
    });
    if (polygonPoints.length > 3) {
      completePolygon();
    }
  }

  void removeCurrentPoint() {
    if (polygonPoints.isNotEmpty) {
      polygonPoints.removeLast();
      locationDetails.removeLast();
      if (polygonPoints.isEmpty) {
        showDetails.value = false;
      }
    } else {
      Get.snackbar('No points', 'No points to remove');
    }
  }

  void removeAtIndex(int index) {
    if (index >= 0 && index < polygonPoints.length) {
      polygonPoints.removeAt(index);
      locationDetails.removeAt(index);
      if (polygonPoints.isEmpty) {
        showDetails.value =
            false; // Redraw polyline after removal _drawPolyline(polygonPoints);
      }
    }
  }

  void toggleDetails() {
    if (polygonPoints.isEmpty) {
      Get.snackbar('No points', 'Add points before showing details');
      return;
    }
    showDetails.toggle();
  }

  Future<void> completePolygon() async {
    if (polygonPoints.length < 3) {
      Get.snackbar(
        'Not enough points',
        'Add at least 3 points to complete the polygon',
      );
      return;
    }
    if (polygonManager == null) return;

    await polygonManager!.deleteAll();
    await polygonManager!.create(
      PolygonAnnotationOptions(
        geometry: Polygon(
          coordinates: [
            polygonPoints.map((p) => p.coordinates).toList()
              ..add(polygonPoints.first.coordinates),
          ],
        ),
        fillColor: Colors.blue.withOpacity(0.3).value,
        fillOutlineColor: Colors.blue.value,
      ),
    );

    await polylineManager?.deleteAll();
  }

  Future<void> clearAll() async {
    polygonPoints.clear();
    locationDetails.clear();
    await polylineManager?.deleteAll();
    await polygonManager?.deleteAll();
    await circleManager?.deleteAll();
    showDetails.value = false;
    Get.snackbar('Cleared', 'All points and details have been cleared');
  }

}

