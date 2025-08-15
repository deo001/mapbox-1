import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../controllers/map_controller.dart';

class OfflineMapPage extends StatefulWidget {
  const OfflineMapPage({ Key? key}) : super(key: key);

  @override
  State<OfflineMapPage> createState() => _OfflineMapPageState();
}

class _OfflineMapPageState extends State<OfflineMapPage> {
  final MapController mapController = Get.find();
  MapboxMap? mapboxMap;
  bool isMapReady = false;

  @override
  void initState() {
    super.initState();
    _loadOfflineMap();
  }

  Future<void> _loadOfflineMap() async {
    try {
      // Use the existing tileStore from MapController
      if (mapController.isOfflineMapAvailable.value &&
          mapController.tileStore.value != null) {
        final tileStore = mapController.tileStore.value!;

        // Load the offline map region
        final darEsSalaamRegion = await tileStore.allTileRegions(
          ).then((regions) => regions.firstWhere(
            (region) => region.id == mapController.tileRegionId,
            orElse: () => throw Exception("Offline region not found"),
          ));
          mapController.tileRegionId;
        setState(() {
          isMapReady = true;
        });
        mapController.isOfflineMode(true);
        mapController.tileStore.value = tileStore;
        mapController.isLoading(false);
        mapController.update(); // Update the controller state
      } else if (mapController.isOfflineMapAvailable.value) {
        Get.snackbar("Error", "No downloaded offline map available");
       
      } else {
        Get.snackbar("Error", "No downloaded offline map available");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load offline map: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Offline Dar es Salaam Map")),
      body: isMapReady
          ? MapWidget(
              onMapCreated: (map) {
                mapboxMap = map;
                mapController.tileStore.value;
                mapController.isOfflineMode(true);
              },
              cameraOptions: CameraOptions(
                center: mapController.currentPosition.value,
                zoom: 16,
              ),
              styleUri: mapController.tileStore.string // Use the offline style
            )
          : const Center(child: CircularProgressIndicator()));
  
    }
}