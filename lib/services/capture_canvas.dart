// utils/canvas_capture.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';

class CanvasCapture {
  static Future<ui.Image?> captureCanvas(GlobalKey key) async {
    try {
      RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) return null;

      ui.Image image = await boundary.toImage(
        pixelRatio: 3.0, // Higher quality capture
      );

      return image;
    } catch (e) {
      print('Error capturing canvas: $e');
      return null;
    }
  }

  // Convert the image to byte data for processing
  static Future<ByteData?> imageToByteData(ui.Image image) async {
    try {
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData;
    } catch (e) {
      print('Error converting image to bytes: $e');
      return null;
    }
  }
}
