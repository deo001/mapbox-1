import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../controllers/map_controller.dart';
import '../controllers/polygon_controller.dart';
import '../views/polygon_details.dart';
import '../views/saved_polygon.dart';
import 'offline_map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';


class MapView extends StatelessWidget {
  final MapController mapController = Get.find();
  final PolygonController polygonController = Get.find();

  MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              Get.to(() => OfflineMapScreen());
            },
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Get.to(() => SavedPolygonsView());
            },
          ),
        ],
      ),
      body: Obx(() {
        if (mapController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Stack(
          children: [
            MapWidget(
              onMapCreated: (map) async {
                 await mapController.onMapCreated(map);
                  await polygonController.onMapCreated(map);
                 await polygonController.drawPolygonsOnMap();
        } ,
              styleUri: MapboxStyles.OUTDOORS,
              cameraOptions: CameraOptions(
                center: mapController.currentPosition.value,
                zoom: 16,
              ),
            ),

            Positioned(
              top: 30,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'add_point',
                    onPressed: () => mapController.addCurrentPoint(),
                    label: const Text('Add Point'),
                    icon: const Icon(Icons.add_location),
                  ),
                  const SizedBox(height: 10),

                  FloatingActionButton.extended(
                    heroTag: 'toggle_details',
                    onPressed: () => mapController.toggleDetails(),
                    label: Obx(
                      () => Text(
                        mapController.showDetails.value
                            ? 'Hide Details'
                            : 'Show Details',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  FloatingActionButton.extended(
                    heroTag: 'clear_all',
                    onPressed: () => mapController.clearAll(),
                    label: const Text('Clear All'),
                    icon: const Icon(Icons.delete),
                    backgroundColor: Colors.red,
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton.extended(
                    label: Text("Go Offline"),
                    heroTag: 'toggle_map_mode',
                    icon: Icon(Icons.offline_pin),
                    onPressed: () {
                      Get.to(() => OfflineMapScreen());
                    },
                  ),
                ],
              ),
            ),
            // Details + Complete Polygon button
            if (mapController.showDetails.value &&
                mapController.locationDetails.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: mapController.locationDetails.length,
                          itemBuilder: (context, index) {
                            final point = mapController.locationDetails[index];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text('${index + 1}'),
                              ),
                              title: Text(
                                'Lat: ${point['latitude'].toStringAsFixed(6)}, Lng: ${point['longitude'].toStringAsFixed(6)}',
                              ),
                              subtitle: Text(
                                'Alt: ${point['altitude'].toStringAsFixed(2)} m, Acc: ${point['accuracy'].toStringAsFixed(2)} m',
                              ),
                              trailing: IconButton(
                                onPressed: () {
                                  mapController.removeAtIndex(index);
                                },
                                icon: Icon(Icons.delete, color: Colors.red),
                              ),
                            );
                          },
                        ),
                      ),
                      if (mapController.polygonPoints.length >= 3)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              // Draw polygon on the map
                              mapController.completePolygon();

                              // Open bottom sheet with polygon details
                              final polygonInfoController = Get.put(
                                PolygonController(),
                              );
                              Get.bottomSheet(
                                PolygonDetailsSheet(
                                  polygonController: polygonController,
                                  points: mapController.polygonPoints.toList(),
                                ),
                                isScrollControlled: true,
                              );
                            },
                            icon: const Icon(Icons.check),
                            label: const Text("Complete Polygon"),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox.shrink(),
          ],
        );
      }),
    );
  }
}
