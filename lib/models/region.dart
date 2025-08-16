// models/region.dart
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class Region {
  final String id;
  final String name;
  final Polygon geometry;
  final int estimatedSize;

  Region({
    required this.id,
    required this.name,
    required this.geometry,
    required this.estimatedSize,
  });
}
