import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:town_pass/page/sync_test/sync_test_view_controller.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_route.dart';

class SyncTestView extends GetView<SyncTestViewController> {
  const SyncTestView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TPAppBar(
        title: '同步測試',
        backgroundColor: TPColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, size: 24),
            tooltip: 'Debug Log',
            onPressed: () => Get.toNamed(TPRoute.debugLog),
          ),
        ],
      ),
      body: Column(
        children: [
          // 模式切換區
          _buildModeSelector(),
          const Divider(height: 1),

          // 資訊顯示區
          _buildInfoSection(),
          const Divider(height: 1),

          // 接收設定區
          _buildReceiveSettings(),
          const Divider(height: 1),

          // 訊息列表
          Expanded(child: _buildMessageList()),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: TPColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '當前模式',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: TPColors.grayscale900,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => Row(
                children: [
                  Expanded(
                    child: _buildModeButton(
                      UserMode.pedestrian,
                      '行人',
                      Icons.directions_walk,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildModeButton(
                      UserMode.bicycle,
                      '自行車',
                      Icons.directions_bike,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildModeButton(
                      UserMode.vehicle,
                      '車輛',
                      Icons.directions_car,
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildModeButton(UserMode mode, String label, IconData icon) {
    final isSelected = controller.currentMode.value == mode;

    return ElevatedButton(
      onPressed: () => controller.toggleMode(mode),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? TPColors.primary500 : TPColors.grayscale100,
        foregroundColor: isSelected ? Colors.white : TPColors.grayscale700,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: isSelected ? 2 : 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: TPColors.white,
      child: Column(
        children: [
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '位置資訊',
                    style: TextStyle(
                      fontSize: 14,
                      color: TPColors.grayscale700,
                    ),
                  ),
                  Text(
                    controller.currentPosition.value != null
                        ? '${controller.currentPosition.value!.latitude.toStringAsFixed(4)}, ${controller.currentPosition.value!.longitude.toStringAsFixed(4)}'
                        : '定位中...',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: TPColors.grayscale900,
                    ),
                  ),
                ],
              )),
          const SizedBox(height: 8),
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '最後同步',
                    style: TextStyle(
                      fontSize: 14,
                      color: TPColors.grayscale700,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        controller.lastSyncTime.value.isEmpty
                            ? '尚未同步'
                            : controller.lastSyncTime.value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: TPColors.grayscale900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (controller.isSyncing.value)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildReceiveSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: TPColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '接收設定',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: TPColors.grayscale900,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildReceiveChip(UserMode.pedestrian, '行人'),
                  _buildReceiveChip(UserMode.bicycle, '自行車'),
                  _buildReceiveChip(UserMode.vehicle, '車輛'),
                ],
              )),
          const SizedBox(height: 16),
          Obx(() => SwitchListTile(
                title: const Text('推送通知'),
                subtitle: const Text('收到訊息時顯示通知'),
                value: controller.enableNotifications.value,
                onChanged: (_) => controller.toggleNotifications(),
                contentPadding: EdgeInsets.zero,
              )),
          const SizedBox(height: 8),
          Obx(() => SwitchListTile(
                title: const Text('Demo 模式'),
                subtitle: const Text('使用模擬訊息進行測試'),
                value: controller.isDemoMode.value,
                onChanged: (_) => controller.toggleDemoMode(),
                contentPadding: EdgeInsets.zero,
              )),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.testNotification,
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('測試通知'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TPColors.primary500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.clearMessages,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('清除訊息'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TPColors.grayscale700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.testVibration,
              icon: const Icon(Icons.vibration),
              label: const Text('測試震動'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TPColors.orange500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiveChip(UserMode mode, String label) {
    final isSelected = controller.receiveModes.contains(mode);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.toggleReceiveMode(mode),
      selectedColor: TPColors.primary100,
      checkmarkColor: TPColors.primary500,
      labelStyle: TextStyle(
        color: isSelected ? TPColors.primary500 : TPColors.grayscale700,
      ),
    );
  }

  Widget _buildMessageList() {
    return Container(
      color: TPColors.grayscale50,
      child: Obx(() {
        if (controller.messages.isEmpty) {
          return const Center(
            child: Text(
              '目前沒有訊息',
              style: TextStyle(
                fontSize: 16,
                color: TPColors.grayscale500,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.messages.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final message = controller.messages[index];
            return _buildMessageCard(message);
          },
        );
      }),
    );
  }

  Widget _buildMessageCard(SyncMessage message) {
    Color priorityColor;
    switch (message.priority.toLowerCase()) {
      case 'high':
        priorityColor = TPColors.red500;
        break;
      case 'medium':
        priorityColor = TPColors.orange500;
        break;
      default:
        priorityColor = TPColors.grayscale500;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: TPColors.grayscale200),
      ),
      child: InkWell(
        onTap: () {
          // 顯示訊息詳情
          Get.dialog(
            AlertDialog(
              title: Row(
                children: [
                  if (message.icon != null) ...[
                    Text(message.icon!),
                    const SizedBox(width: 8),
                  ],
                  Expanded(child: Text(message.title)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.content),
                  const SizedBox(height: 16),
                  Text(
                    '時間: ${DateTime.fromMillisecondsSinceEpoch(message.timestamp).toString().substring(0, 19)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: TPColors.grayscale600,
                    ),
                  ),
                  Text(
                    '優先級: ${controller.getPriorityLabel(message.priority)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: TPColors.grayscale600,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('關閉'),
                ),
              ],
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (message.icon != null) ...[
                    Text(message.icon!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      message.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: TPColors.grayscale900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      controller.getPriorityLabel(message.priority),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: priorityColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: TPColors.grayscale700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    DateTime.fromMillisecondsSinceEpoch(message.timestamp)
                        .toString()
                        .substring(11, 19),
                    style: const TextStyle(
                      fontSize: 12,
                      color: TPColors.grayscale500,
                    ),
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 4,
                    children: message.targetModes
                        .map((mode) => Chip(
                              label: Text(
                                controller.getModeLabel(mode),
                                style: const TextStyle(fontSize: 10),
                              ),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
