import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> loadGoogleMaps(String apiKey) {
  final completer = Completer<void>();
  final script = web.HTMLScriptElement()
    ..async = true
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey';

  void onLoad(web.Event _) => completer.complete();
  void onError(web.Event _) => completer.completeError(
    Exception('Failed to load Google Maps JS API'),
  );

  script.addEventListener('load', onLoad.toJS);
  script.addEventListener('error', onError.toJS);

  web.document.head!.append(script);
  return completer.future;
}