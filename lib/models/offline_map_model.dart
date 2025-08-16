// models/offline_map_model.dart
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'region.dart';

class OfflineMapModel {
  final List<Region> regions = [
    Region(
      id: "dar-es-salaam",
      name: "Dar es Salaam",
      estimatedSize: 45,
      geometry: Polygon.fromJson({
        "type": "Polygon",
        "coordinates": [
          [
            [39.208786, -6.822373],
            [39.306473, -6.796845],
            [39.317719, -6.742306],
            [39.253418, -6.715122],
            [39.208786, -6.822373],
          ],
        ],
      }),
    ),
    Region(
      id: "arusha",
      name: "Arusha",
      estimatedSize: 90,
      geometry: Polygon.fromJson({
        "type": "Polygon",
        "coordinates": [
          [
            [36.560, -3.210],
            [36.780, -3.210],
            [36.780, -3.470],
            [36.560, -3.470],
            [36.560, -3.210],
          ],
        ],
      }),
    ),
    Region(
      id: "mbeya",
      name: "Mbeya",
      estimatedSize: 85,
      geometry: Polygon.fromJson({
        "type": "Polygon",
        "coordinates": [
          [
            [33.200, -8.700],
            [33.500, -8.700],
            [33.500, -9.000],
            [33.200, -9.000],
            [33.200, -8.700],
          ],
        ],
      }),
    ),
    Region(
      id: "iringa",
      name: "Iringa",
      estimatedSize: 75,
      geometry: Polygon.fromJson({
        "type": "Polygon",
        "coordinates": [
          [
            [35.300, -7.500],
            [35.700, -7.500],
            [35.700, -7.900],
            [35.300, -7.900],
            [35.300, -7.500],
          ],
        ],
      }),
    ),
  ];
}
