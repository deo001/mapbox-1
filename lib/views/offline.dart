import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../controllers/map_controller.dart';
import 'example.dart';
import 'utils.dart';

class OfflineMapExample extends StatefulWidget implements Example {
  @override
  final Widget leading = const Icon(Icons.wifi_off);

  @override
  final String title = 'Offline Map';
  @override
  final String subtitle =
      "Shows how to use OfflineManager and TileStore to download regions for offline use.";

  const OfflineMapExample({super.key});

  @override
  State createState() => OfflineMapExampleState();
}

class OfflineMapExampleState extends State<OfflineMapExample> {
  final StreamController<double> _stylePackProgress =
      StreamController.broadcast();
  final StreamController<double> _tileRegionLoadProgress =
      StreamController.broadcast();

  TileStore? _tileStore;
  OfflineManager? _offlineManager;
  final _tileRegionId = "my-tile-region";
  bool _mapIsReady = false;
  bool _checkingStatus = true;

  final MapController mapController = Get.put(MapController());

  @override
  void initState() {
    super.initState();
    _checkOfflineResources();
  }

  @override
  void dispose() async {
    super.dispose();
    await OfflineSwitch.shared.setMapboxStackConnected(true);
    _stylePackProgress.close();
    _tileRegionLoadProgress.close();
  }

  Future<void> _checkOfflineResources() async {
    _offlineManager = await OfflineManager.create();
    _tileStore = await TileStore.createDefault();

    bool styleExists = false;
    bool tileExists = false;

    try {
      final stylePack = await _offlineManager!.stylePack(
        MapboxStyles.SATELLITE_STREETS,
      );
      styleExists = stylePack != null;
    } catch (_) {}

    try {
      final tileRegion = await _tileStore!.tileRegion(_tileRegionId);
      tileExists = tileRegion != null;
    } catch (_) {}

    if (styleExists && tileExists) {
      await OfflineSwitch.shared.setMapboxStackConnected(false);
      _mapIsReady = true;
    }

    setState(() {
      _checkingStatus = false;
    });
  }

  Future<void> _downloadStylePack() async {
    final stylePackLoadOptions = StylePackLoadOptions(
      glyphsRasterizationMode:
          GlyphsRasterizationMode.IDEOGRAPHS_RASTERIZED_LOCALLY,
      metadata: {"tag": "offline-map"},
      acceptExpired: false,
    );

    await _offlineManager?.loadStylePack(
      MapboxStyles.SATELLITE_STREETS,
      stylePackLoadOptions,
      (progress) {
        final percentage =
            progress.completedResourceCount / progress.requiredResourceCount;
        if (!_stylePackProgress.isClosed) {
          _stylePackProgress.sink.add(percentage);
        }
      },
    );
    _stylePackProgress.sink.add(1);
    _stylePackProgress.close();
  }

  Future<void> _downloadTileRegion() async {
    final tileRegionLoadOptions = TileRegionLoadOptions(
      geometry: City.mbeya.toJson(),
      descriptorsOptions: [
        TilesetDescriptorOptions(
          styleURI: MapboxStyles.SATELLITE_STREETS,
          minZoom: 0,
          maxZoom: 18,
        ),
      ],
      acceptExpired: true,
      networkRestriction: NetworkRestriction.NONE,
    );

    await _tileStore?.loadTileRegion(_tileRegionId, tileRegionLoadOptions, (
      progress,
    ) {
      final percentage =
          progress.completedResourceCount / progress.requiredResourceCount;
      if (!_tileRegionLoadProgress.isClosed) {
        _tileRegionLoadProgress.sink.add(percentage);
      }
    });
    _tileRegionLoadProgress.sink.add(1);
    _tileRegionLoadProgress.close();
  }

  Future<void> _downloadOfflineMap() async {
    await _downloadStylePack();
    await _downloadTileRegion();
    await OfflineSwitch.shared.setMapboxStackConnected(false);
    setState(() {
      _mapIsReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingStatus) {
      return Scaffold(
        appBar: AppBar(title: Text('Dar Map')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Dar Map')),
      body: Column(
        children: [
          Expanded(
            child: _mapIsReady
                ? MapWidget(
                    key: ValueKey("mapWidget"),
                    styleUri: MapboxStyles.SATELLITE_STREETS,
                    cameraOptions: CameraOptions(
                      center: mapController.currentPosition.value,
                      zoom: 16,
                    ),
                  )
                : Center(
                    child: TextButton(
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.all<Color>(
                          Colors.blue,
                        ),
                      ),
                      onPressed: _downloadOfflineMap,
                      child: Text("Download Map"),
                    ),
                  ),
          ),
          if (!_mapIsReady)
            SizedBox(
              height: 100,
              child: Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StreamBuilder<double>(
                      stream: _stylePackProgress.stream,
                      initialData: 0.0,
                      builder: (context, snapshot) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Style pack ${(snapshot.data! * 100).toStringAsFixed(0)}%",
                            ),
                            LinearProgressIndicator(value: snapshot.data),
                          ],
                        );
                      },
                    ),
                    StreamBuilder<double>(
                      stream: _tileRegionLoadProgress.stream,
                      initialData: 0.0,
                      builder: (context, snapshot) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Tile region ${(snapshot.data! * 100).toStringAsFixed(0)}%",
                            ),
                            LinearProgressIndicator(value: snapshot.data),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
