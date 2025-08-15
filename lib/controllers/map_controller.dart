import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../controllers/polygon_controller.dart';
import '../views/dowlnloaded_map.dart';

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
  final String tileRegionId = "dar_es_salaam_region";
  final CoordinateBounds darEsSalaamBounds = CoordinateBounds(
    southwest: Point(coordinates: Position(39.15, -6.96)),
    northeast: Point(coordinates: Position(39.35, -6.54)),
    infiniteBounds: false,
  );
  final tileStore = Rxn<TileStore>();
  final isOfflineMapAvailable = false.obs;

  Future<void> checkOfflineMap() async {
    final ts = await TileStore.createDefault();
    final regions = await ts.allTileRegions();

    // Check if our Dar es Salaam region exists
    final exists = regions.any((r) => r.id == tileRegionId);
    if (exists) {
      isOfflineMapAvailable.value = true;
      tileStore.value = ts;
    } else {
      isOfflineMapAvailable.value = false;
    }
  }

  final isOfflineMode = false.obs; // whether user wants offline map

  Future<void> switchToOffline() async {
    final ts = await TileStore.createDefault();
    final regions = await ts.allTileRegions();

    if (regions.isNotEmpty) {
      isOfflineMapAvailable.value = true;
      isOfflineMode.value = true;
      update();
    } else {
      isOfflineMapAvailable.value = false;
      Get.snackbar("Offline Map", "No downloaded map available.");
    }
  }

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

  TileStore? _tileStore;
  OfflineManager? _offlineManager;
  final _tileRegionId = "my-tile-region";
  Future<void> initOfflineMap() async {
    _offlineManager = await OfflineManager.create();
    _tileStore = await TileStore.createDefault();

    // Reset disk quota to default value
    _tileStore?.setDiskQuota(null);
  }

  // void _moveCameraToCurrentPosition() {
  //   if (mapboxMap != null && currentPosition.value != null) {
  //     mapboxMap!.setCamera(
  //       CameraOptions(center: currentPosition.value, zoom: 16),
  //     );
  //   }
  // }

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

  // -------------------- OFFLINE MAP --------------------
  Future<void> downloadDarEsSalaamOffline(dynamic Style) async {
    final offlineManager = await OfflineManager.create();
    final tileStore = await TileStore.createDefault();
    final descriptor = TilesetDescriptorOptions(
      styleURI: MapboxStyles.OUTDOORS,
      minZoom: 10,
      maxZoom: 16,
    );

    final estSizeMB = _estimateOfflineSizeMB(0, 16, darEsSalaamBounds);
    Get.snackbar(
      "Offline Map Size",
      "Estimated size: ${estSizeMB.toStringAsFixed(2)} MB",
    );

    await tileStore
        .loadTileRegion(
          tileRegionId,
          TileRegionLoadOptions(
            geometry: darEsSalaamBounds.toPolygonGeoJson(),
            acceptExpired: false,
            descriptorsOptions: [descriptor],
            networkRestriction: NetworkRestriction.NONE,
            metadata: {"region": "Dar es Salaam"},
          ),
          (progress) {
            final percent =
                (progress.completedResourceCount /
                    progress.requiredResourceCount) *
                100;
            debugPrint("Download progress: ${percent.toStringAsFixed(1)}%");
          },
        )
        .then(
          (_) => Get.snackbar(
            "Offline Map",
            "Dar es Salaam map downloaded successfully!",
          ),
        )
        .catchError((err) => Get.snackbar("Error", "Failed to download: $err"));
    isOfflineMapAvailable.value = true;

    await listDownloadedMaps();
  }

  final useOfflineMap = false.obs;

  get index => null;

  void toggleOfflineView() {
    if (isOfflineMapAvailable.value) {
      useOfflineMap.toggle();
    } else {
      Get.snackbar("Offline Map", "No downloaded map available.");
    }
  }

  Future<void> listDownloadedMaps() async {
    try {
      final tileStore = await TileStore.createDefault();

      // Get all downloaded regions
      final regions = await tileStore.allTileRegions();

      if (regions.isEmpty) {
        debugPrint("No offline regions found.");
        Get.snackbar("Offline Map", "No downloaded regions found.");
        return;
      }

      for (final region in regions) {
        debugPrint("Region ID: ${region.id}");
        // Size calculation (bytes → MB)
        final sizeMB = (region.completedResourceSize / (1024 * 1024));
        debugPrint("Size: ${sizeMB.toStringAsFixed(2)} MB");

        Get.snackbar(
          "Offline Region",
          "${region.id}: ${sizeMB.toStringAsFixed(2)} MB",
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      debugPrint("Error listing offline maps: $e");
      Get.snackbar("Error", "Failed to list offline maps");
    }

    Get.to(() => OfflineMapPage()); // Navigate to the map ready page
  }

  double _estimateOfflineSizeMB(
    int minZoom,
    int maxZoom,
    CoordinateBounds bounds,
  ) {
    double factor = 0.002;
    double tiles = 0;
    for (int z = minZoom; z <= maxZoom; z++) {
      tiles += (factor * (1 << z) * (1 << z));
    }
    double sizeKB = tiles * 20; // ~20KB per tile
    return sizeKB / 1024;
  }
}

// -------------------- EXTENSIONS --------------------
extension BoundsToPolygon on CoordinateBounds {
  Map<String, dynamic> toPolygonGeoJson() {
    return {
      "type": "Polygon",
      "coordinates": [
        [
          [southwest.coordinates.lng, southwest.coordinates.lat],
          [northeast.coordinates.lng, southwest.coordinates.lat],
          [northeast.coordinates.lng, northeast.coordinates.lat],
          [southwest.coordinates.lng, northeast.coordinates.lat],
          [southwest.coordinates.lng, southwest.coordinates.lat],
        ],
      ],
    };
  }
}
