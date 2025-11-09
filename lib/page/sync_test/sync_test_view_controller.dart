import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';
import 'package:town_pass/service/geo_locator_service.dart';
import 'package:town_pass/service/notification_service.dart';
import 'package:town_pass/page/sync_test/debug_log/debug_log_view_controller.dart';
import 'package:town_pass/page/sync_test/models/debug_log.dart';
import 'package:town_pass/page/sync_test/webview_push_service.dart';

enum UserMode { pedestrian, bicycle, vehicle }

class SyncMessage {
  final String id;
  final String type;
  final List<UserMode> targetModes;
  final String priority;
  final String title;
  final String content;
  final int timestamp;
  final String? icon;
  final String alertMethod;
  final String vibrationPattern;

  SyncMessage({
    required this.id,
    required this.type,
    required this.targetModes,
    required this.priority,
    required this.title,
    required this.content,
    required this.timestamp,
    this.icon,
    required this.alertMethod,
    required this.vibrationPattern,
  });

  factory SyncMessage.fromJson(Map<String, dynamic> json) {
    return SyncMessage(
      id: json['id'] ?? '',
      type: json['type'] ?? 'info',
      targetModes: (json['targetModes'] as List<dynamic>?)
              ?.map((e) => _parseMode(e.toString()))
              .toList() ??
          [],
      priority: json['priority'] ?? 'low',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      icon: json['icon'],
      alertMethod: json['alertMethod'] ?? 'silent',
      vibrationPattern: json['vibrationPattern'] ?? 'none',
    );
  }

  static UserMode _parseMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'pedestrian':
        return UserMode.pedestrian;
      case 'bicycle':
        return UserMode.bicycle;
      case 'vehicle':
        return UserMode.vehicle;
      default:
        return UserMode.pedestrian;
    }
  }
}

class SyncTestViewController extends GetxController {
  final Rx<UserMode> currentMode = UserMode.pedestrian.obs;
  final RxList<UserMode> receiveModes = <UserMode>[UserMode.pedestrian].obs;
  final RxList<SyncMessage> messages = <SyncMessage>[].obs;
  final RxBool isDemoMode = false.obs;
  final RxBool isSyncing = false.obs;
  final RxBool syncEnabled = true.obs;
  final RxBool enableNotifications = true.obs;
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxString lastSyncTime = ''.obs;
  final RxInt syncIntervalMs = 2000.obs;

  // 手動定位模式
  final RxBool isManualLocationMode = false.obs;
  final RxDouble manualLatitude = 25.033000.obs;  // 台北市預設座標
  final RxDouble manualLongitude = 121.565400.obs;

  Timer? _syncTimer;
  http.Client? _httpClient;
  CancelableOperation? _currentRequest;

  static const String apiEndpoint = 'https://tmp114514.ricecall.com/interact';
  Duration get syncInterval => Duration(milliseconds: syncIntervalMs.value);

  @override
  void onInit() {
    super.onInit();
    _httpClient = http.Client();
    _startSync();
    _getCurrentLocation();
    _requestNotificationPermission();

    // Initialize WebView push service if not already initialized
    if (!Get.isRegistered<WebViewPushService>()) {
      Get.put(WebViewPushService());
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      await NotificationService.requestPermission();
      debugPrint('Notification permission requested');
    } catch (e) {
      debugPrint('Failed to request notification permission: $e');
    }
  }

  @override
  void onClose() {
    _syncTimer?.cancel();
    _currentRequest?.cancel();
    _httpClient?.close();
    super.onClose();
  }

  void toggleMode(UserMode mode) {
    currentMode.value = mode;
    if (!receiveModes.contains(mode)) {
      receiveModes.add(mode);
    }
  }

  void toggleReceiveMode(UserMode mode) {
    if (receiveModes.contains(mode)) {
      if (receiveModes.length > 1) {
        receiveModes.remove(mode);
      }
    } else {
      receiveModes.add(mode);
    }
  }

  void toggleDemoMode() {
    isDemoMode.value = !isDemoMode.value;
    if (isDemoMode.value) {
      _addDemoMessage();
    }
  }

  void _startSync() {
    _syncTimer = Timer.periodic(syncInterval, (_) {
      _syncWithBackend();
    });
  }

  Future<void> _getCurrentLocation() async {
    if (isManualLocationMode.value) {
      // 使用手動輸入的座標
      debugPrint('Using manual location: ${manualLatitude.value}, ${manualLongitude.value}');

      // Push manual location to WebView
      try {
        final pushService = Get.find<WebViewPushService>();
        await pushService.pushLocation(
          latitude: manualLatitude.value,
          longitude: manualLongitude.value,
          isManual: true,
        );
        debugPrint('Manual location pushed to WebView');
      } catch (e) {
        debugPrint('Failed to push manual location to WebView: $e');
      }

      return;
    }

    try {
      final position = await Get.find<GeoLocatorService>().position();
      currentPosition.value = position;

      // Push GPS location to WebView
      try {
        final pushService = Get.find<WebViewPushService>();
        await pushService.pushLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          isManual: false,
        );
        debugPrint('GPS location pushed to WebView: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        debugPrint('Failed to push GPS location to WebView: $e');
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _syncWithBackend() async {
    if (!syncEnabled.value || isSyncing.value || isDemoMode.value) return;

    await _getCurrentLocation();

    // 在手動模式下，檢查是否有手動座標；在 GPS 模式下，檢查是否有 GPS 座標
    if (!isManualLocationMode.value && currentPosition.value == null) return;

    isSyncing.value = true;

    // 根據模式選擇座標來源
    final double latitude;
    final double longitude;

    if (isManualLocationMode.value) {
      latitude = manualLatitude.value;
      longitude = manualLongitude.value;
    } else {
      latitude = currentPosition.value!.latitude;
      longitude = currentPosition.value!.longitude;
    }

    final requestData = {
      'lng': longitude,
      'lat': latitude,
      'type': getModeType(currentMode.value),
    };
    final headers = {'Content-Type': 'application/json'};
    final startTime = DateTime.now();

    // === 詳細 Request 日誌 ===
    debugPrint('');
    debugPrint('╔════════════════════════════════════════════════════════════════');
    debugPrint('║ 🚀 Sending Request');
    debugPrint('╠════════════════════════════════════════════════════════════════');
    debugPrint('║ URL: $apiEndpoint');
    debugPrint('║ Method: PUT');
    debugPrint('║ Time: ${startTime.toString()}');
    debugPrint('╠════════════════════════════════════════════════════════════════');
    debugPrint('║ Headers:');
    headers.forEach((key, value) {
      debugPrint('║   $key: $value');
    });
    debugPrint('╠════════════════════════════════════════════════════════════════');
    debugPrint('║ Request Body:');
    debugPrint('║   {');
    debugPrint('║     "lng": ${requestData['lng']}');
    debugPrint('║     "lat": ${requestData['lat']}');
    debugPrint('║     "type": "${requestData['type']}"');
    debugPrint('║   }');
    debugPrint('╠════════════════════════════════════════════════════════════════');
    debugPrint('║ 定位模式: ${isManualLocationMode.value ? "手動輸入" : "GPS"}');
    debugPrint('║ 使用者模式: ${getModeLabel(currentMode.value)} (${getModeType(currentMode.value)})');
    debugPrint('╚════════════════════════════════════════════════════════════════');
    debugPrint('');

    // 記錄 Request 到 Debug Log Controller
    try {
      final debugLogController = Get.find<DebugLogViewController>();
      debugLogController.addLog(
        DebugLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          timestamp: startTime,
          type: LogType.request,
          url: apiEndpoint,
          requestData: requestData,
          headers: headers,
        ),
      );
    } catch (e) {
      debugPrint('Debug log controller not found: $e');
    }

    // Push request to WebView
    try {
      final pushService = Get.find<WebViewPushService>();
      await pushService.pushRequest(
        url: apiEndpoint,
        method: 'PUT',
        body: requestData,
      );
    } catch (e) {
      debugPrint('WebView push service not found: $e');
    }

    try {
      final response = await _httpClient!.put(
        Uri.parse(apiEndpoint),
        headers: headers,
        body: jsonEncode(requestData),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Request timeout after 5 seconds');
        },
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      lastSyncTime.value = DateTime.now().toString().substring(11, 19);

      // === 詳細 Response 日誌 ===
      debugPrint('');
      debugPrint('╔════════════════════════════════════════════════════════════════');
      debugPrint('║ ✅ Received Response');
      debugPrint('╠════════════════════════════════════════════════════════════════');
      debugPrint('║ Status Code: ${response.statusCode}');
      debugPrint('║ Duration: ${duration.inMilliseconds}ms');
      debugPrint('║ Time: ${endTime.toString()}');
      debugPrint('╠════════════════════════════════════════════════════════════════');
      debugPrint('║ Response Body:');
      // 格式化顯示 JSON (如果可以解析)
      try {
        final jsonData = jsonDecode(response.body);
        final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonData);
        prettyJson.split('\n').forEach((line) {
          debugPrint('║   $line');
        });
      } catch (e) {
        debugPrint('║   ${response.body}');
      }
      debugPrint('╚════════════════════════════════════════════════════════════════');
      debugPrint('');

      // 記錄 Response 到 Debug Log Controller
      try {
        final debugLogController = Get.find<DebugLogViewController>();
        debugLogController.addLog(
          DebugLog(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            timestamp: endTime,
            type: LogType.response,
            url: apiEndpoint,
            statusCode: response.statusCode,
            responseBody: response.body,
            duration: duration,
          ),
        );
      } catch (e) {
        debugPrint('Debug log controller not found: $e');
      }

      // Push response to WebView
      try {
        final pushService = Get.find<WebViewPushService>();
        await pushService.pushResponse(
          statusCode: response.statusCode,
          body: response.body,
        );
      } catch (e) {
        debugPrint('WebView push service not found: $e');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _processMessages(data);
      }
    } on TimeoutException {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // === Timeout Error 日誌 ===
      debugPrint('');
      debugPrint('╔════════════════════════════════════════════════════════════════');
      debugPrint('║ ⏱️  Request Timeout');
      debugPrint('╠════════════════════════════════════════════════════════════════');
      debugPrint('║ URL: $apiEndpoint');
      debugPrint('║ Duration: ${duration.inSeconds}s (${duration.inMilliseconds}ms)');
      debugPrint('║ Time: ${endTime.toString()}');
      debugPrint('║ Error: Request timeout after 5 seconds');
      debugPrint('╚════════════════════════════════════════════════════════════════');
      debugPrint('');

      // 記錄 Timeout Error
      try {
        final debugLogController = Get.find<DebugLogViewController>();
        debugLogController.addLog(
          DebugLog(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            timestamp: endTime,
            type: LogType.error,
            url: apiEndpoint,
            errorMessage: 'Request timeout after ${duration.inSeconds}s',
            duration: duration,
          ),
        );
      } catch (logError) {
        debugPrint('Debug log controller not found: $logError');
      }
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // === Error 日誌 ===
      debugPrint('');
      debugPrint('╔════════════════════════════════════════════════════════════════');
      debugPrint('║ ❌ Request Error');
      debugPrint('╠════════════════════════════════════════════════════════════════');
      debugPrint('║ URL: $apiEndpoint');
      debugPrint('║ Duration: ${duration.inMilliseconds}ms');
      debugPrint('║ Time: ${endTime.toString()}');
      debugPrint('╠════════════════════════════════════════════════════════════════');
      debugPrint('║ Error Message:');
      debugPrint('║   $e');
      debugPrint('╚════════════════════════════════════════════════════════════════');
      debugPrint('');

      // 記錄 Error
      try {
        final debugLogController = Get.find<DebugLogViewController>();
        debugLogController.addLog(
          DebugLog(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            timestamp: endTime,
            type: LogType.error,
            url: apiEndpoint,
            errorMessage: e.toString(),
            duration: duration,
          ),
        );
      } catch (logError) {
        debugPrint('Debug log controller not found: $logError');
      }
    } finally {
      isSyncing.value = false;
    }
  }

  void _processMessages(Map<String, dynamic> data) {
    debugPrint('Processing messages from response...');
    debugPrint('Response data: $data');

    // 檢查新格式: {message: "xxx", lng: 123, lat: 2}
    if (data['message'] != null && data['message'].toString().isNotEmpty) {
      final messageContent = data['message'].toString();
      final lng = data['lng'];
      final lat = data['lat'];

      debugPrint('Found message in response: $messageContent (lng: $lng, lat: $lat)');

      // 生成訊息 ID（使用時間戳確保每次都是唯一的）
      final messageId = '${messageContent.hashCode}-${DateTime.now().millisecondsSinceEpoch}';

      // 創建 SyncMessage
      final message = SyncMessage(
        id: messageId,
        type: 'info',
        targetModes: [currentMode.value], // 使用當前模式
        priority: 'medium',
        title: '路況訊息',
        content: messageContent,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        icon: '📍',
        alertMethod: 'notification',
        vibrationPattern: 'normal',
      );

      debugPrint('Created SyncMessage: ${message.id} - ${message.title}');

      // 加入訊息列表
      messages.insert(0, message);

      // 觸發提醒
      _triggerAlert(message);

      // Push message to WebView
      _pushMessageToWebView(message);

      return;
    }

    // 舊格式支援: {messages: [...]}
    if (data['messages'] != null) {
      final List<dynamic> messageList = data['messages'] as List<dynamic>;
      debugPrint('Found ${messageList.length} messages in old format');

      for (var msgData in messageList) {
        final message = SyncMessage.fromJson(msgData as Map<String, dynamic>);
        debugPrint('Processing message: ${message.id} - ${message.title}');

        // 檢查是否符合接收模式
        final hasMatchingMode = message.targetModes.any((mode) => receiveModes.contains(mode));
        if (!hasMatchingMode) {
          debugPrint('Message ${message.id} does not match receive modes, skipping');
          continue;
        }

        debugPrint('Adding message ${message.id} to list and triggering alert');

        // 加入訊息列表
        messages.insert(0, message);

        // 觸發提醒
        _triggerAlert(message);

        // Push message to WebView
        _pushMessageToWebView(message);
      }

      return;
    }

    debugPrint('No message or messages field in response');
  }

  void _triggerAlert(SyncMessage message) {
    debugPrint('Triggering alert for message: ${message.title}');

    // 推送通知
    _pushNotification(message);

    // 觸發震動
    if (message.vibrationPattern == 'urgent') {
      debugPrint('Triggering urgent vibration');
      _triggerVibration(const [0, 500, 100, 500]);
    } else if (message.vibrationPattern == 'normal') {
      debugPrint('Triggering normal vibration');
      _triggerVibration(const [0, 200]);
    }

    // 桌面震動模擬
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      debugPrint('Simulating desktop vibration');
      _simulateDesktopVibration();
    }
  }

  Future<void> _pushNotification(SyncMessage message) async {
    // 檢查是否啟用通知
    if (!enableNotifications.value) {
      debugPrint('Notifications disabled, skipping');
      return;
    }

    try {
      // 組合通知標題（包含圖示和標題）
      final title = message.icon != null
          ? '${message.icon} ${message.title}'
          : message.title;

      await NotificationService.showNotification(
        title: title,
        content: message.content,
      );

      debugPrint('Notification sent: ${message.title}');
    } catch (e) {
      debugPrint('Failed to send notification: $e');
    }
  }

  void toggleNotifications() {
    enableNotifications.value = !enableNotifications.value;
  }

  Future<void> testNotification() async {
    try {
      await NotificationService.showNotification(
        title: '🧪 測試通知',
        content: '這是一則測試通知，如果你看到這個訊息，表示通知功能正常運作。',
      );
      debugPrint('Test notification sent');
    } catch (e) {
      debugPrint('Failed to send test notification: $e');
    }
  }

  Future<void> testVibration() async {
    try {
      debugPrint('Testing vibration...');
      // 觸發震動
      _triggerVibration(const [0, 300, 200, 300]);
      debugPrint('Vibration test completed');
    } catch (e) {
      debugPrint('Failed to test vibration: $e');
    }
  }

  void _triggerVibration(List<int> pattern) async {
    if (kIsWeb) return;

    try {
      // 檢查設備是否支援震動
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        // 使用自定義震動模式
        await Vibration.vibrate(pattern: pattern);
        debugPrint('Vibration triggered with pattern: $pattern');
      } else {
        debugPrint('Device does not support vibration');
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  void _simulateDesktopVibration() {
    // 桌面震動模擬 - 可以觸發視覺效果或音效
    debugPrint('Desktop vibration simulated');
    // 這裡可以發送一個事件，讓 UI 層做視覺震動效果
  }

  void _addDemoMessage() {
    debugPrint('Adding demo message...');

    final demoMessage = SyncMessage(
      id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
      type: 'danger',
      targetModes: [currentMode.value],
      priority: 'high',
      title: '測試訊息',
      content: '這是一則測試訊息，用於演示功能',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      icon: '⚠️',
      alertMethod: 'modal',
      vibrationPattern: 'urgent',
    );

    debugPrint('Demo message created: ${demoMessage.id} - ${demoMessage.title}');

    messages.insert(0, demoMessage);
    _triggerAlert(demoMessage);
  }

  void clearMessages() {
    messages.clear();
  }

  void setSyncInterval(int intervalMs) {
    if (intervalMs < 100) {
      debugPrint('Interval too short, setting to 100ms');
      intervalMs = 100;
    }

    syncIntervalMs.value = intervalMs;

    // 重新啟動計時器
    _syncTimer?.cancel();
    _startSync();

    debugPrint('Sync interval set to ${intervalMs}ms');
  }

  void toggleSyncEnabled(bool enabled) {
    syncEnabled.value = enabled;
    debugPrint('Sync enabled: $enabled');
  }

  Future<void> _pushMessageToWebView(SyncMessage message) async {
    try {
      final pushService = Get.find<WebViewPushService>();
      await pushService.pushMessage({
        'id': message.id,
        'type': message.type,
        'targetModes': message.targetModes.map((m) => m.name).toList(),
        'priority': message.priority,
        'title': message.title,
        'content': message.content,
        'timestamp': message.timestamp,
        'icon': message.icon,
        'alertMethod': message.alertMethod,
        'vibrationPattern': message.vibrationPattern,
      });
    } catch (e) {
      debugPrint('Failed to push message to WebView: $e');
    }
  }

  String getModeLabel(UserMode mode) {
    switch (mode) {
      case UserMode.pedestrian:
        return '行人';
      case UserMode.bicycle:
        return '自行車';
      case UserMode.vehicle:
        return '車輛';
    }
  }

  String getModeType(UserMode mode) {
    switch (mode) {
      case UserMode.pedestrian:
        return 'human';
      case UserMode.bicycle:
        return 'bicycle';
      case UserMode.vehicle:
        return 'car';
    }
  }

  String getPriorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return '高';
      case 'medium':
        return '中';
      case 'low':
        return '低';
      default:
        return priority;
    }
  }

  // 切換定位模式
  void toggleLocationMode() {
    isManualLocationMode.value = !isManualLocationMode.value;
    if (!isManualLocationMode.value) {
      // 切回 GPS 模式時立即更新位置
      _getCurrentLocation();
    }
  }

  // 更新手動經緯度
  void updateManualLocation(double latitude, double longitude) {
    manualLatitude.value = latitude;
    manualLongitude.value = longitude;

    // Push manual location to WebView
    if (isManualLocationMode.value) {
      try {
        final pushService = Get.find<WebViewPushService>();
        pushService.pushLocation(
          latitude: latitude,
          longitude: longitude,
          isManual: true,
        );
        debugPrint('Manual location updated and pushed to WebView: $latitude, $longitude');
      } catch (e) {
        debugPrint('Failed to push updated manual location to WebView: $e');
      }
    }
  }
}

class CancelableOperation {
  bool _isCanceled = false;

  bool get isCanceled => _isCanceled;

  void cancel() {
    _isCanceled = true;
  }
}
