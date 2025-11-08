import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:town_pass/page/sync_test/sync_test_view_controller.dart';
import 'package:town_pass/util/web_message_handler/tp_web_message_handler.dart';

/// 設定使用者模式（行人/自行車/車輛）
class SyncTestSetModeMessageHandler extends TPWebMessageHandler {
  @override
  String get name => 'sync_test_set_mode';

  @override
  Future<void> handle({
    required Object? message,
    required WebUri? sourceOrigin,
    required bool isMainFrame,
    required Function(WebMessage reply)? onReply,
  }) async {
    try {
      final controller = Get.find<SyncTestViewController>();

      if (message == null || message is! String) {
        onReply?.call(replyWebMessage(data: {'success': false, 'error': 'Invalid mode'}));
        return;
      }

      UserMode? mode;
      switch (message.toLowerCase()) {
        case 'pedestrian':
          mode = UserMode.pedestrian;
          break;
        case 'bicycle':
          mode = UserMode.bicycle;
          break;
        case 'vehicle':
          mode = UserMode.vehicle;
          break;
        default:
          onReply?.call(replyWebMessage(data: {'success': false, 'error': 'Unknown mode'}));
          return;
      }

      controller.toggleMode(mode);
      onReply?.call(replyWebMessage(data: {'success': true, 'mode': message}));
    } catch (e) {
      debugPrint('SyncTestSetModeMessageHandler error: $e');
      onReply?.call(replyWebMessage(data: {'success': false, 'error': e.toString()}));
    }
  }
}

/// 設定同步間隔時間
class SyncTestSetSyncIntervalMessageHandler extends TPWebMessageHandler {
  @override
  String get name => 'sync_test_set_sync_interval';

  @override
  Future<void> handle({
    required Object? message,
    required WebUri? sourceOrigin,
    required bool isMainFrame,
    required Function(WebMessage reply)? onReply,
  }) async {
    try {
      final controller = Get.find<SyncTestViewController>();

      if (message == null || message is! num) {
        onReply?.call(replyWebMessage(data: {'success': false, 'error': 'Invalid interval'}));
        return;
      }

      final intervalMs = message.toInt();
      controller.setSyncInterval(intervalMs);

      onReply?.call(replyWebMessage(data: {'success': true, 'intervalMs': intervalMs}));
    } catch (e) {
      debugPrint('SyncTestSetSyncIntervalMessageHandler error: $e');
      onReply?.call(replyWebMessage(data: {'success': false, 'error': e.toString()}));
    }
  }
}

/// 開始或停止同步
class SyncTestToggleSyncMessageHandler extends TPWebMessageHandler {
  @override
  String get name => 'sync_test_toggle_sync';

  @override
  Future<void> handle({
    required Object? message,
    required WebUri? sourceOrigin,
    required bool isMainFrame,
    required Function(WebMessage reply)? onReply,
  }) async {
    try {
      final controller = Get.find<SyncTestViewController>();

      if (message == null || message is! bool) {
        onReply?.call(replyWebMessage(data: {'success': false, 'error': 'Invalid start flag'}));
        return;
      }

      controller.toggleSyncEnabled(message);

      onReply?.call(replyWebMessage(data: {'success': true, 'isSyncing': message}));
    } catch (e) {
      debugPrint('SyncTestToggleSyncMessageHandler error: $e');
      onReply?.call(replyWebMessage(data: {'success': false, 'error': e.toString()}));
    }
  }
}

/// 取得當前同步狀態
class SyncTestGetStateMessageHandler extends TPWebMessageHandler {
  @override
  String get name => 'sync_test_get_state';

  @override
  Future<void> handle({
    required Object? message,
    required WebUri? sourceOrigin,
    required bool isMainFrame,
    required Function(WebMessage reply)? onReply,
  }) async {
    try {
      final controller = Get.find<SyncTestViewController>();

      debugPrint('=== Building state object ===');
      debugPrint('mode: ${controller.currentMode.value.name}');
      debugPrint('isSyncing: ${controller.syncEnabled.value}');
      debugPrint('isDemoMode: ${controller.isDemoMode.value}');
      debugPrint('enableNotifications: ${controller.enableNotifications.value}');
      debugPrint('messages count: ${controller.messages.length}');
      debugPrint('position: ${controller.currentPosition.value}');
      debugPrint('lastSyncTime: "${controller.lastSyncTime.value}"');

      final state = {
        'mode': controller.currentMode.value.name,
        'isSyncing': controller.syncEnabled.value,
        'isDemoMode': controller.isDemoMode.value,
        'enableNotifications': controller.enableNotifications.value,
        'messages': controller.messages.map((m) => {
          'id': m.id,
          'type': m.type,
          'targetModes': m.targetModes.map((mode) => mode.name).toList(),
          'priority': m.priority,
          'title': m.title,
          'content': m.content,
          'timestamp': m.timestamp,
          'icon': m.icon ?? '',  // 確保不是 null
          'alertMethod': m.alertMethod,
          'vibrationPattern': m.vibrationPattern,
        }).toList(),
        'position': controller.currentPosition.value != null ? {
          'latitude': controller.currentPosition.value!.latitude,
          'longitude': controller.currentPosition.value!.longitude,
        } : null,
        'lastSyncTime': controller.lastSyncTime.value.isNotEmpty
          ? controller.lastSyncTime.value
          : DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(state);
      debugPrint('=== JSON output (first 500 chars) ===');
      debugPrint(jsonString.substring(0, jsonString.length > 500 ? 500 : jsonString.length));

      debugPrint('=== Calling onReply with state data ===');
      final reply = replyWebMessage(data: state);
      debugPrint('=== Reply message created ===');
      onReply?.call(reply);
      debugPrint('=== onReply called successfully ===');
    } catch (e) {
      debugPrint('SyncTestGetStateMessageHandler error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      onReply?.call(replyWebMessage(data: {'error': e.toString()}));
    }
  }
}

/// 清除所有訊息
class SyncTestClearMessagesMessageHandler extends TPWebMessageHandler {
  @override
  String get name => 'sync_test_clear_messages';

  @override
  Future<void> handle({
    required Object? message,
    required WebUri? sourceOrigin,
    required bool isMainFrame,
    required Function(WebMessage reply)? onReply,
  }) async {
    try {
      final controller = Get.find<SyncTestViewController>();
      controller.clearMessages();

      onReply?.call(replyWebMessage(data: {'success': true}));
    } catch (e) {
      debugPrint('SyncTestClearMessagesMessageHandler error: $e');
      onReply?.call(replyWebMessage(data: {'success': false, 'error': e.toString()}));
    }
  }
}

/// 切換 Demo 模式
class SyncTestToggleDemoMessageHandler extends TPWebMessageHandler {
  @override
  String get name => 'sync_test_toggle_demo';

  @override
  Future<void> handle({
    required Object? message,
    required WebUri? sourceOrigin,
    required bool isMainFrame,
    required Function(WebMessage reply)? onReply,
  }) async {
    try {
      final controller = Get.find<SyncTestViewController>();
      controller.toggleDemoMode();

      onReply?.call(replyWebMessage(data: {
        'success': true,
        'isDemoMode': controller.isDemoMode.value,
      }));
    } catch (e) {
      debugPrint('SyncTestToggleDemoMessageHandler error: $e');
      onReply?.call(replyWebMessage(data: {'success': false, 'error': e.toString()}));
    }
  }
}

/// 切換通知開關
class SyncTestToggleNotificationsMessageHandler extends TPWebMessageHandler {
  @override
  String get name => 'sync_test_toggle_notifications';

  @override
  Future<void> handle({
    required Object? message,
    required WebUri? sourceOrigin,
    required bool isMainFrame,
    required Function(WebMessage reply)? onReply,
  }) async {
    try {
      final controller = Get.find<SyncTestViewController>();
      controller.toggleNotifications();

      onReply?.call(replyWebMessage(data: {
        'success': true,
        'enableNotifications': controller.enableNotifications.value,
      }));
    } catch (e) {
      debugPrint('SyncTestToggleNotificationsMessageHandler error: $e');
      onReply?.call(replyWebMessage(data: {'success': false, 'error': e.toString()}));
    }
  }
}
