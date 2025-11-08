import 'package:get/get.dart';
import 'package:town_pass/page/sync_test/models/debug_log.dart';

class DebugLogViewController extends GetxController {
  final RxList<DebugLog> logs = <DebugLog>[].obs;
  final RxBool autoScroll = true.obs;

  void addLog(DebugLog log) {
    logs.insert(0, log);
    // 保留最近 100 條記錄
    if (logs.length > 100) {
      logs.removeRange(100, logs.length);
    }
  }

  void clearLogs() {
    logs.clear();
  }

  void toggleAutoScroll() {
    autoScroll.value = !autoScroll.value;
  }
}
