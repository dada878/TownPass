import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:town_pass/util/web_message_handler/tp_web_message_handler.dart';
import 'package:town_pass/util/web_message_handler/sync_test_message_handler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

abstract class TPWebMessageListener {
  static List<TPWebMessageHandler> get messageHandler => [
        UserinfoWebMessageHandler(),
        LaunchMapWebMessageHandler(),
        PhoneCallMessageHandler(),
        Agree1999MessageHandler(),
        LocationMessageHandler(),
        DeviceInfoMessageHandler(),
        OpenLinkMessageHandler(),
        NotifyMessageHandler(),
        QRCodeScanMessageHandler(),
        // Sync Test Handlers
        SyncTestSetModeMessageHandler(),
        SyncTestSetSyncIntervalMessageHandler(),
        SyncTestToggleSyncMessageHandler(),
        SyncTestGetStateMessageHandler(),
        SyncTestClearMessagesMessageHandler(),
        SyncTestToggleDemoMessageHandler(),
        SyncTestToggleNotificationsMessageHandler(),
      ];

  static WebMessageListener webMessageListener() {
    return WebMessageListener(
      jsObjectName: 'flutterObject',
      onPostMessage: (webMessage, sourceOrigin, isMainFrame, replyProxy) async {
        debugPrint('=== WebMessageListener onPostMessage ===');
        debugPrint('webMessage: $webMessage');
        debugPrint('webMessage.data: ${webMessage?.data}');
        debugPrint('sourceOrigin: $sourceOrigin');
        debugPrint('isMainFrame: $isMainFrame');
        debugPrint('replyProxy: $replyProxy');

        if (webMessage == null) {
          debugPrint('webMessage is null, returning');
          return;
        }

        try {
          final Map dataMap = jsonDecode(webMessage.data);
          final String handlerName = dataMap['name'] as String;
          debugPrint('Handler name: $handlerName');
          debugPrint('Handler data: ${dataMap['data']}');

          // 尋找對應的 handler
          for (TPWebMessageHandler handler in messageHandler) {
            if (handler.name == handlerName) {
              debugPrint('Found handler: ${handler.name}');
              await handler.handle(
                message: dataMap['data'],
                sourceOrigin: sourceOrigin,
                isMainFrame: isMainFrame,
                onReply: (reply) {
                  debugPrint('=== onReply callback called ===');
                  debugPrint('Reply WebMessage type: ${reply.type}');
                  debugPrint('Reply WebMessage data: ${reply.data}');
                  debugPrint('Calling replyProxy.postMessage...');
                  replyProxy.postMessage(reply);
                  debugPrint('replyProxy.postMessage completed');
                },
              );
              // 找到並處理完成後就跳出
              debugPrint('Handler execution completed');
              return;
            }
          }

          // 如果沒有找到對應的 handler
          debugPrint('Warning: No handler found for: $handlerName');
        } catch (e) {
          debugPrint('Error in webMessageListener: $e');
          debugPrint('Stack trace: ${StackTrace.current}');
        }
      },
    );
  }
}
