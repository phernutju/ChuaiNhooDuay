import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

/// Native (Android/iOS/desktop) implementation — downloads bytes via
/// Firebase Storage SDK then renders with Image.memory.
/// No CORS restriction on native.
Widget buildNetworkImage({
  required String url,
  required double width,
  required double height,
  required bool isOwn,
}) {
  return _NativeImage(url: url, width: width, height: height, isOwn: isOwn);
}

class _NativeImage extends StatefulWidget {
  const _NativeImage({
    required this.url,
    required this.width,
    required this.height,
    required this.isOwn,
  });

  final String url;
  final double width;
  final double height;
  final bool isOwn;

  @override
  State<_NativeImage> createState() => _NativeImageState();
}

class _NativeImageState extends State<_NativeImage> {
  late final Future<Uint8List?> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = FirebaseStorage.instance
        .refFromURL(widget.url)
        .getData(10 * 1024 * 1024);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _placeholder(widget.width, widget.height);
        }
        if (snap.hasError || snap.data == null) {
          return _errorWidget(widget.width, widget.height);
        }
        return Image.memory(
          snap.data!,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.cover,
        );
      },
    );
  }
}

Widget _placeholder(double w, double h) =>
    SizedBox(width: w, height: h, child: const ColoredBox(color: Color(0xFF242424)));

Widget _errorWidget(double w, double h) => SizedBox(
      width: w,
      height: h,
      child: const ColoredBox(
        color: Color(0xFF242424),
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: Color(0xFF888888), size: 28),
        ),
      ),
    );
