import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../models/offline_map_model.dart';
import '../models/region.dart';

class OfflineMapController extends GetxController {
  MapboxMap? mapboxMap;
  final _tileRegionPrefix = "offline-region-";
  final _model = OfflineMapModel();
  final stylePackProgress = 0.0.obs;
  final tileRegionProgress = 0.0.obs;
  final selectedRegion = Rxn<Region>();
  final isDownloading = false.obs;
  final downloadedRegions = <String>[].obs;
  final cameraOptions = Rxn<CameraOptions>();
  final showLocation = false.obs;

  // Current device location
  final currentPosition = Rxn<Point>();

  // Subscription to location stream
  StreamSubscription<geo.Position>? _geoSub;

  List<Region> get regions => _model.regions;

  // Annotation Managers
  PolylineAnnotationManager? polylineManager;
  PolygonAnnotationManager? polygonManager;
  CircleAnnotationManager? circleManager;

  @override
  void onInit() {
    super.onInit();
    initialize();
    _initLocationTracking();
  }

  @override
  void onClose() {
    _geoSub?.cancel();
    super.onClose();
  }

  Future<void> initialize() async {
    final offlineManager = await OfflineManager.create();
    final tileStore = await TileStore.createDefault();
    tileStore.setDiskQuota(null); // Reset to default quota

    // Check existing downloads
    final existingRegions = await tileStore.allTileRegions();
    for (var region in existingRegions) {
      if (region.id.startsWith(_tileRegionPrefix)) {
        final regionId = region.id.replaceFirst(_tileRegionPrefix, '');
        if (!downloadedRegions.contains(regionId)) {
          downloadedRegions.add(regionId);
        }
      }
    }
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

  /// Initialize location tracking using geolocator only
  Future<void> _initLocationTracking() async {
    // Ensure location services are enabled
    if (!await geo.Geolocator.isLocationServiceEnabled()) return;

    // Handle permission flow
    var permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }
    if (permission == geo.LocationPermission.denied ||
        permission == geo.LocationPermission.deniedForever) {
      return;
    }

    // Seed initial position
    final pos = await geo.Geolocator.getCurrentPosition(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.bestForNavigation,
      ),
    );
    _updateFromGeo(pos);
    if (showLocation.value) _moveCameraToGeo(pos);

    // Listen for continuous updates
    await _geoSub?.cancel();
    _geoSub =
        geo.Geolocator.getPositionStream(
          locationSettings: const geo.LocationSettings(
            accuracy: geo.LocationAccuracy.bestForNavigation,
            distanceFilter: 0,
          ),
        ).listen((pos) {
          _updateFromGeo(pos);
          if (showLocation.value) _moveCameraToGeo(pos);
        });
  }

  void _updateFromGeo(geo.Position pos) {
    currentPosition.value = Point(
      coordinates: Position(pos.longitude, pos.latitude),
    );
  }

  void _moveCameraToGeo(geo.Position pos) {
    cameraOptions.value = CameraOptions(
      center: Point(coordinates: Position(pos.longitude, pos.latitude)),
      zoom: 16.0,
    );
  }

  void selectRegion(Region region) {
    selectedRegion.value = region;

    // Calculate center point for camera
    final coords = region.geometry.coordinates[0];
    double lngSum = 0, latSum = 0;
    for (final pos in coords) {
      lngSum += pos.lng;
      latSum += pos.lat;
    }

    final center = Point(
      coordinates: Position(lngSum / coords.length, latSum / coords.length),
    );

    cameraOptions.value = CameraOptions(center: center, zoom: 9.0);
  }

  Future<void> downloadRegion() async {
    if (selectedRegion.value == null) return;

    isDownloading.value = true;
    stylePackProgress.value = 0;
    tileRegionProgress.value = 0;

    try {
      await _downloadStylePack();
      await _downloadTileRegion();
      downloadedRegions.add(selectedRegion.value!.id);
      Get.snackbar('Success', '${selectedRegion.value!.name} downloaded!');
    } catch (e) {
      debugPrint("Download error: $e");
      Get.snackbar(
        'Error',
        'Failed to download region: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDownloading.value = false;
    }
  }

  Future<void> _downloadStylePack() async {
    final offlineManager = await OfflineManager.create();
    final options = StylePackLoadOptions(
      glyphsRasterizationMode:
      GlyphsRasterizationMode.IDEOGRAPHS_RASTERIZED_LOCALLY,
      acceptExpired: false,
    );

    offlineManager.loadStylePack(MapboxStyles.STANDARD, options, (progress) {
      final percent =
          progress.completedResourceCount / progress.requiredResourceCount;
      stylePackProgress.value = percent;
    });
  }

  Future<void> _downloadTileRegion() async {
    if (selectedRegion.value == null) return;

    final tileStore = await TileStore.createDefault();
    final options = TileRegionLoadOptions(
      geometry: selectedRegion.value!.geometry.toJson(),
      descriptorsOptions: [
        TilesetDescriptorOptions(
          styleURI: MapboxStyles.STANDARD,
          minZoom: 6,
          maxZoom: 18,
          // pixelRatio: 1.0,
        ),
      ],
      acceptExpired: true,
      networkRestriction: NetworkRestriction.NONE,
    );

    tileStore.loadTileRegion(
      '$_tileRegionPrefix${selectedRegion.value!.id}',
      options,
          (progress) {
        final percent =
            progress.completedResourceCount / progress.requiredResourceCount;
        tileRegionProgress.value = percent;
      },
    );
  }

  Future<void> cleanup() async {
    if (selectedRegion.value == null) return;

    final tileStore = await TileStore.createDefault();
    final offlineManager = await OfflineManager.create();

    await tileStore.removeRegion(
      '$_tileRegionPrefix${selectedRegion.value!.id}',
    );
    downloadedRegions.remove(selectedRegion.value!.id);

    Get.snackbar('Cleaned', '${selectedRegion.value!.name} data removed');
  }

  bool isRegionDownloaded(Region region) {
    return downloadedRegions.contains(region.id);
  }
}
