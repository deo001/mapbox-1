import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'bindings/inirtial_bindings.dart';
import 'views/map_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  MapboxOptions.setAccessToken(
      "pk.eyJ1IjoiYnJlbGxhaDEyIiwiYSI6ImNtZTlvcDVybjBseDcybHIwYTRsa2QxZmsifQ.CxllK7CvkV4UZzUnhodUzQ");
  InitialBindings().dependencies(); // Initialize controllers

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Mapbox Offline',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: MapView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
