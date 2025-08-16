import 'package:get/get.dart';

import '../controllers/map_controller.dart';
import '../controllers/offlne_map_controller.dart';
import '../controllers/polygon_controller.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(MapController());
    Get.put(PolygonController());
    Get.put(OfflineMapController());
  }
}
