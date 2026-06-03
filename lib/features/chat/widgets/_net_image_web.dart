import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Web implementation — renders via HtmlElementView + <img> DOM element.
/// <img> loads in no-cors mode: bypasses browser CORS enforcement entirely.
/// The CSS border-radius matches the bubble shape so ClipRRect is not needed.
Widget buildNetworkImage({
  required String url,
  required double width,
  required double height,
  required bool isOwn,
}) {
  final viewType = 'fi-img-${url.hashCode}-${url.length}';

  // registerViewFactory is idempotent — safe to call on every build.
  ui_web.platformViewRegistry.registerViewFactory(viewType, (_) {
    final tl = 16, tr = 16;
    final bl = isOwn ? 16 : 4;
    final br = isOwn ? 4 : 16;

    return web.HTMLImageElement()
      ..src = url
      ..style.width = '${width.toInt()}px'
      ..style.height = '${height.toInt()}px'
      ..style.objectFit = 'cover'
      ..style.borderRadius = '${tl}px ${tr}px ${br}px ${bl}px';
  });

  return SizedBox(
    width: width,
    height: height,
    child: HtmlElementView(viewType: viewType),
  );
}
