// views/offline_map_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:maps_offline/controllers/map_controller.dart';
import 'package:maps_offline/views/polygon_details.dart';

import '../controllers/offlne_map_controller.dart';
import '../controllers/polygon_controller.dart';

class OfflineMapScreen extends StatelessWidget {
  const OfflineMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OfflineMapController>();
    final mapController = Get.find<MapController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tanzania Offline Maps'),
        actions: [
          Obx(() {
            if (controller.selectedRegion.value != null &&
                controller.downloadedRegions.contains(
                  controller.selectedRegion.value!.id,
                )) {
              return IconButton(
                icon: const Icon(Icons.delete),
                onPressed: controller.cleanup,
              );
            }
            return Container();
          }),
          IconButton(
            onPressed: () {
              if (mapController.currentPosition.value != null) {
                mapController.mapboxMap?.flyTo(
                  CameraOptions(
                    center: mapController.currentPosition.value,
                    zoom: 16.0,
                  ),
                  MapAnimationOptions(duration: 1000, startDelay: 0),
                );
              }
            },
            icon: Icon(Icons.my_location),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // --- Region Selection Panel ---
              SizedBox(
                height: 100,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Region:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        Expanded(
                          child: Obx(
                            () => ListView(
                              scrollDirection: Axis.horizontal,
                              children: controller.regions.map((region) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: ChoiceChip(
                                    label: Text(
                                      "${region.name} (~${region.estimatedSize}MB)",
                                    ),
                                    selected:
                                        controller.selectedRegion.value?.id ==
                                        region.id,
                                    onSelected: (_) {
                                      if (controller.selectedRegion.value?.id !=
                                          region.id) {
                                        controller.selectRegion(region);
                                      }
                                    },
                                    avatar:
                                        controller.isRegionDownloaded(region)
                                        ? const Icon(
                                            Icons.download_done,
                                            size: 18,
                                          )
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- Map / Download Section ---
              Expanded(
                child: Obx(() {
                  if (controller.selectedRegion.value == null) {
                    return const Center(child: Text('Please select a region'));
                  }

                  final region = controller.selectedRegion.value!;
                  final isDownloaded = controller.downloadedRegions.contains(
                    region.id,
                  );

                  if (isDownloaded) {
                    return MapWidget(
                      key: ValueKey("map-${region.id}"),
                      styleUri: MapboxStyles.OUTDOORS,
                      cameraOptions: CameraOptions(
                        center: mapController.currentPosition.value,
                        zoom: 16,
                      ),
                      onMapCreated: mapController.onMapCreated,
                    );
                  } else {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${region.name} not downloaded',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.download),
                            label: const Text('Download Region'),
                            onPressed: controller.isDownloading.value
                                ? null
                                : controller.downloadRegion,
                          ),
                        ],
                      ),
                    );
                  }
                }),
              ),
            ],
          ),

          // Show FABs only if region is downloaded
          Obx(() {
            if (controller.selectedRegion.value != null &&
                controller.downloadedRegions.contains(
                  controller.selectedRegion.value!.id,
                )) {
              return Positioned(
                top: 120,
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
                      label: const Text("Go Online"),
                      heroTag: 'toggle_map_mode',
                      icon: const Icon(Icons.wifi),
                      onPressed: () {
                        // Get.to(() => MapView());
                      },
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Details + Complete Polygon button
          Obx(() {
            if (mapController.showDetails.value &&
                mapController.locationDetails.isNotEmpty) {
              return Positioned(
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
                                'Lat: ${point['latitude']!.toStringAsFixed(6)}, Lng: ${point['longitude']!.toStringAsFixed(6)}',
                              ),
                              subtitle: Text(
                                'Alt: ${point['altitude']!.toStringAsFixed(2)} m, Acc: ${point['accuracy']!.toStringAsFixed(2)} m',
                              ),
                              trailing: IconButton(
                                onPressed: () {
                                  mapController.removeAtIndex(index);
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
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
                                  polygonController: polygonInfoController,
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
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}
