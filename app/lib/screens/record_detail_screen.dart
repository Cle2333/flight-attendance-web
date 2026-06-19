import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/edit_record_modal.dart';

class RecordDetailScreen extends StatelessWidget {
  final int recordId;
  const RecordDetailScreen({super.key, required this.recordId});

  @override
  Widget build(BuildContext context) {
    final state = Get.find<AppState>();
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('起飞详情'),
      ),
      body: Obx(() {
        final r = state.records.firstWhere(
          (e) => e.id == recordId,
          orElse: () => state.records.isNotEmpty
              ? state.records.first
              : (throw StateError('记录不存在')),
        );
        final t = r.time;

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: '起飞时间',
                    value: DateFormatters.timeFull(t),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _DetailRow(
                    label: '感受',
                    value: r.note.isEmpty ? '（无）' : r.note,
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '状态',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '已完成',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await Get.dialog(
                        EditRecordModal(
                          record: r,
                          onSave: (newTime) => state.updateRecord(
                              r.id, newTime, r.note),
                        ),
                      );
                    },
                    child: const Text('编辑'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final confirm = await Get.dialog<bool>(
                        AlertDialog(
                          title: const Text('删除起飞记录'),
                          content: const Text('确定删除这条记录？'),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text('取消'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.danger),
                              onPressed: () => Get.back(result: true),
                              child: const Text('删除'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await state.deleteRecord(r.id);
                        if (Get.isOverlaysOpen == false &&
                            Get.currentRoute == '/RecordDetailScreen') {
                          Get.back();
                        }
                      }
                    },
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger),
                    child: const Text('删除'),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
