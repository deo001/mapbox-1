import 'package:flutter/material.dart';

abstract interface class Example extends Widget {
  const Example({super.key});

  Widget get leading;
  String get title;
  String? get subtitle;
}
