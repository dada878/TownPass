import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

/// Service for pushing events from Flutter to WebView
class WebViewPushService extends GetxService {
  final RxMap<int, InAppWebViewController> _webViewControllers = <int, InAppWebViewController>{}.obs;

  /// Register a WebView controller to receive push events
  void registerWebView(InAppWebViewController controller) {
    final hash = controller.hashCode;

    // 檢查是否已經註冊過（避免重複）
    if (_webViewControllers.containsKey(hash)) {
      debugPrint('WebView already registered (hash: $hash), skipping');
      return;
    }

    // 清除所有舊的 WebView controllers（因為同時只會有一個同步控制台）
    if (_webViewControllers.isNotEmpty) {
      debugPrint('Clearing ${_webViewControllers.length} old WebView controller(s) before registering new one');
      _webViewControllers.clear();
    }

    _webViewControllers[hash] = controller;
    debugPrint('WebView registered (hash: $hash). Total: ${_webViewControllers.length}');
  }

  /// Unregister a WebView controller
  void unregisterWebView(InAppWebViewController controller) {
    final hash = controller.hashCode;
    _webViewControllers.remove(hash);
    debugPrint('WebView unregistered (hash: $hash). Total: ${_webViewControllers.length}');
  }

  /// Push a request event to all registered WebViews
  Future<void> pushRequest({
    required String url,
    required String method,
    required dynamic body,
  }) async {
    final data = {
      'url': url,
      'method': method,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _pushEvent('townpass_sync_request', data);
  }

  /// Push a response event to all registered WebViews
  Future<void> pushResponse({
    required int statusCode,
    required String body,
  }) async {
    final data = {
      'statusCode': statusCode,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _pushEvent('townpass_sync_response', data);
  }

  /// Push a message event to all registered WebViews
  Future<void> pushMessage(Map<String, dynamic> message) async {
    await _pushEvent('townpass_sync_message', message);
  }

  /// Push a state update event to all registered WebViews
  Future<void> pushStateUpdate(Map<String, dynamic> state) async {
    await _pushEvent('townpass_state_update', state);
  }

  /// Push a location update event to all registered WebViews
  Future<void> pushLocation({
    required double latitude,
    required double longitude,
    required bool isManual,
  }) async {
    final data = {
      'latitude': latitude,
      'longitude': longitude,
      'isManual': isManual,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _pushEvent('townpass_location_update', data);
  }

  /// Internal method to push events to all registered WebViews
  Future<void> _pushEvent(String eventType, dynamic data) async {
    if (_webViewControllers.isEmpty) {
      // 減少 log 頻率，避免干擾
      // debugPrint('No WebView controllers registered, skipping push: $eventType');
      return;
    }

    try {
      final jsonData = jsonEncode(data);
      final script = '''
        (function() {
          try {
            if (typeof window.townpassEventHandlers !== 'undefined') {
              const event = new CustomEvent('$eventType', { detail: $jsonData });
              window.dispatchEvent(event);
              console.log('TownPass event dispatched: $eventType');
            } else {
              console.warn('TownPass event handlers not initialized');
            }
          } catch (e) {
            console.error('TownPass event dispatch error:', e);
          }
        })();
      ''';

      final hashesToRemove = <int>[];

      for (final entry in _webViewControllers.entries.toList()) {
        try {
          // 加上 timeout 防止卡住
          await entry.value.evaluateJavascript(source: script)
              .timeout(const Duration(milliseconds: 500));
          debugPrint('Pushed $eventType to WebView (hash: ${entry.key})');
        } catch (e) {
          debugPrint('Failed to push $eventType to WebView (hash: ${entry.key}): $e');
          // 標記要移除的 hash
          hashesToRemove.add(entry.key);
        }
      }

      // 清理失效的 controllers
      for (final hash in hashesToRemove) {
        _webViewControllers.remove(hash);
      }
    } catch (e) {
      debugPrint('Error in _pushEvent: $e');
    }
  }

  /// Clear all registered WebView controllers
  void clearAll() {
    _webViewControllers.clear();
    debugPrint('All WebView controllers cleared');
  }
}
