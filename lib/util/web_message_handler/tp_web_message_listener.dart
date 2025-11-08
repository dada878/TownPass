import 'dart:convert';

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
        if (webMessage == null) {
          return;
        }

        try {
          final Map dataMap = jsonDecode(webMessage.data);
          final String handlerName = dataMap['name'] as String;

          // 尋找對應的 handler
          for (TPWebMessageHandler handler in messageHandler) {
            if (handler.name == handlerName) {
              await handler.handle(
                message: dataMap['data'],
                sourceOrigin: sourceOrigin,
                isMainFrame: isMainFrame,
                onReply: (reply) {
                  replyProxy.postMessage(reply);
                },
              );
              // 找到並處理完成後就跳出
              return;
            }
          }

          // 如果沒有找到對應的 handler
          print('Warning: No handler found for: $handlerName');
        } catch (e) {
          print('Error in webMessageListener: $e');
        }
      },
    );
  }
}
