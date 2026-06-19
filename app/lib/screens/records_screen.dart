import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/record.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/stats_grid.dart';
import 'record_detail_screen.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  DateTime _calDate = DateTime.now();
  bool _detailOpen = false;

  void _navigateToDay(DateTime d) {
    final state = Get.find<AppState>();
    final list = state.records
        .where((r) => isSameDay(r.time, d))
        .toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    if (list.isEmpty) return;
    Get.to(() => RecordDetailScreen(recordId: list.first.id));
  }

  @override
  Widget build(BuildContext context) {
    final state = Get.find<AppState>();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Text(
              '✈️ 航班记录',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          CalendarWidget(
            currentDate: _calDate,
            onMonthChanged: (delta) {
              setState(() {
                _calDate = DateTime(
                    _calDate.year, _calDate.month + delta, _calDate.day);
              });
            },
            hasRecordOn: state.hasRecordOn,
            onDateTapped: _navigateToDay,
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Text(
              '快速统计',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                StatCard(
                  icon: '✈️',
                  iconBg: AppColors.primaryBg,
                  value: '${state.totalRecords}',
                  label: '总起飞次数',
                ),
                StatCard(
                  icon: '🔥',
                  iconBg: const Color(0xFFF0FDF4),
                  value: '${state.currentStreak}',
                  label: '连续天数',
                ),
                StatCard(
                  icon: '⏰',
                  iconBg: const Color(0xFFFFFBEB),
                  value: () {
                    final avg = state.averageTakeoffHour;
                    return avg == null
                        ? '--:--'
                        : '${avg.toString().padLeft(2, '0')}:00';
                  }(),
                  label: '平均起飞时间',
                ),
                StatCard(
                  icon: '🏆',
                  iconBg: const Color(0xFFFAF5FF),
                  value: '${state.badges}',
                  label: '徽章',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _detailOpen = !_detailOpen),
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '查看起飞记录',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: _detailOpen ? 0.25 : 0,
                    child: const Icon(
                      Icons.chevron_right,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Obx(() {
            final records = state.records;
            final sorted = [...records]..sort((a, b) => b.time.compareTo(a.time));
            final grouped = <String, List<FlightRecord>>{};
            for (final r in sorted) {
              final k = DateFormatters.dayLabel(r.time);
              grouped.putIfAbsent(k, () => []).add(r);
            }
            return AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _detailOpen
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                      child: grouped.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  '暂无记录',
                                  style: TextStyle(color: AppColors.textLight),
                                ),
                              ),
                            )
                          : Column(
                              children:
                                  grouped.entries.expand((entry) {
                                final recs = entry.value;
                                return [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        4, 14, 4, 8),
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  ...recs.asMap().entries.map((e) {
                                    final i = e.key;
                                    final r = e.value;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _RecordItem(
                                        record: r,
                                        indexInDay: recs.length - i,
                                      ),
                                    );
                                  }),
                                ];
                              }).toList(),
                            ),
                    )
                  : const SizedBox.shrink(),
            );
          }),
        ],
      ),
    );
  }
}

class _RecordItem extends StatelessWidget {
  final FlightRecord record;
  final int indexInDay;
  const _RecordItem({required this.record, required this.indexInDay});

  @override
  Widget build(BuildContext context) {
    final t = DateFormatters.timeHM(record.time);
    final noteText = record.note.isEmpty ? '' : ' · ${record.note}';
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Get.to(() => RecordDetailScreen(recordId: record.id)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text('✈️', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '第 $indexInDay 次起飞',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$t$noteText',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      ),
    );
  }
}
