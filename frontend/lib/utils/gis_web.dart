import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

@JS('gisSelectAccount')
external void _gisSelectAccount(
  JSString clientId,
  JSFunction successCb,
  JSFunction errorCb,
);

Future<Map<String, dynamic>?> signInWithGISWeb(String clientId) async {
  final completer = Completer<Map<String, dynamic>?>();

  final successCb = ((JSString resultJson) {
    if (!completer.isCompleted) {
      try {
        final data = jsonDecode(resultJson.toDart) as Map<String, dynamic>;
        completer.complete(data);
      } catch (e) {
        completer.completeError(e);
      }
    }
  }).toJS;

  final errorCb = ((JSAny error) {
    if (!completer.isCompleted) {
      completer.completeError(error.toString());
    }
  }).toJS;

  try {
    _gisSelectAccount(clientId.toJS, successCb, errorCb);
  } catch (e) {
    if (!completer.isCompleted) {
      completer.completeError(e);
    }
  }

  return completer.future;
}
