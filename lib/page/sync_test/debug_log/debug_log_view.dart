import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:town_pass/page/sync_test/debug_log/debug_log_view_controller.dart';
import 'package:town_pass/page/sync_test/models/debug_log.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_colors.dart';

class DebugLogView extends GetView<DebugLogViewController> {
  const DebugLogView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TPAppBar(
        title: 'Debug Log',
        backgroundColor: TPColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 24),
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  title: const Text('清除記錄'),
                  content: const Text('確定要清除所有 debug log 嗎？'),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        controller.clearLogs();
                        Get.back();
                      },
                      child: const Text('確定'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (controller.logs.isEmpty) {
                return const Center(
                  child: Text(
                    '目前沒有記錄',
                    style: TextStyle(
                      fontSize: 16,
                      color: TPColors.grayscale500,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: controller.logs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final log = controller.logs[index];
                  return _buildLogCard(log);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: TPColors.white,
      child: Row(
        children: [
          Obx(() => Text(
                '共 ${controller.logs.length} 筆記錄',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: TPColors.grayscale700,
                ),
              )),
          const Spacer(),
          Obx(() => FilterChip(
                label: const Text('自動滾動'),
                selected: controller.autoScroll.value,
                onSelected: (_) => controller.toggleAutoScroll(),
              )),
        ],
      ),
    );
  }

  Widget _buildLogCard(DebugLog log) {
    Color borderColor;
    Color backgroundColor;

    switch (log.type) {
      case LogType.request:
        borderColor = TPColors.primary500;
        backgroundColor = TPColors.primary50;
        break;
      case LogType.response:
        if (log.statusCode != null && log.statusCode! >= 200 && log.statusCode! < 300) {
          borderColor = Colors.green;
          backgroundColor = Colors.green.withOpacity(0.05);
        } else {
          borderColor = TPColors.red500;
          backgroundColor = TPColors.red50;
        }
        break;
      case LogType.error:
        borderColor = TPColors.red500;
        backgroundColor = TPColors.red50;
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: InkWell(
        onTap: () => _showLogDetails(log),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.typeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (log.statusCode != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        log.statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: borderColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (log.duration != null) ...[
                    Text(
                      '${log.duration!.inMilliseconds}ms',
                      style: const TextStyle(
                        fontSize: 12,
                        color: TPColors.grayscale600,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  Text(
                    log.formattedTime,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TPColors.grayscale600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                log.url,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: TPColors.grayscale900,
                ),
              ),
              if (log.type == LogType.request && log.requestData != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Request: ${_formatJson(log.requestData!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TPColors.grayscale700,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (log.type == LogType.response && log.responseBody != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Response: ${log.responseBody}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TPColors.grayscale700,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (log.type == LogType.error && log.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Error: ${log.errorMessage}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TPColors.red500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLogDetails(DebugLog log) {
    Get.dialog(
      Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: TPColors.primary500,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(
                  children: [
                    Text(
                      log.typeLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('時間', log.formattedTime),
                      _buildDetailRow('URL', log.url),
                      if (log.statusCode != null)
                        _buildDetailRow('Status Code', log.statusLabel),
                      if (log.duration != null)
                        _buildDetailRow('Duration', '${log.duration!.inMilliseconds}ms'),
                      if (log.headers != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Headers:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildJsonSection(log.headers!),
                      ],
                      if (log.requestData != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Request Body:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildJsonSection(log.requestData!),
                      ],
                      if (log.responseBody != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Response Body:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTextSection(log.responseBody!),
                      ],
                      if (log.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Error Message:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: TPColors.red500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          log.errorMessage!,
                          style: const TextStyle(
                            color: TPColors.red500,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: TPColors.grayscale700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: TPColors.grayscale900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonSection(Map<String, dynamic> data) {
    final jsonString = _formatJson(data);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TPColors.grayscale50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TPColors.grayscale200),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              jsonString,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: TPColors.grayscale900,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              Get.snackbar(
                '已複製',
                'JSON 已複製到剪貼簿',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 1),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextSection(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TPColors.grayscale50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TPColors.grayscale200),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: TPColors.grayscale900,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Get.snackbar(
                '已複製',
                '內容已複製到剪貼簿',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 1),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatJson(Map<String, dynamic> data) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (e) {
      return data.toString();
    }
  }
}
