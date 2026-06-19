import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// 自定义日历：周视图 + 可展开月视图
class CalendarWidget extends StatefulWidget {
  final DateTime currentDate;
  final ValueChanged<int> onMonthChanged; // -1: prev month, +1: next month
  final bool Function(DateTime) hasRecordOn;
  final ValueChanged<DateTime> onDateTapped;

  const CalendarWidget({
    super.key,
    required this.currentDate,
    required this.onMonthChanged,
    required this.hasRecordOn,
    required this.onDateTapped,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  bool _expanded = false;

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHead(),
          const SizedBox(height: 12),
          if (!_expanded) _buildWeek(),
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildMonth(),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),
          Center(
            child: GestureDetector(
              onTap: _toggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _expanded ? '收起月视图' : '展开月视图',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHead() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormatters.monthLabel(widget.currentDate),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        Row(
          children: [
            _navBtn('‹', () => widget.onMonthChanged(-1)),
            const SizedBox(width: 8),
            _navBtn('›', () => widget.onMonthChanged(1)),
          ],
        ),
      ],
    );
  }

  Widget _navBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildWeek() {
    final d = DateTime(widget.currentDate.year, widget.currentDate.month, widget.currentDate.day);
    // 找到这周的周一
    final mondayOffset = (d.weekday - 1);
    final monday = d.subtract(Duration(days: mondayOffset));
    final today = DateTime.now();
    final labels = ['一', '二', '三', '四', '五', '六', '日'];

    return Row(
      children: List.generate(7, (i) {
        final day = monday.add(Duration(days: i));
        final isToday = isSameDay(day, today);
        final marked = widget.hasRecordOn(day);
        return Expanded(
          child: GestureDetector(
            onTap: () => widget.onDateTapped(day),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isToday ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 11,
                      color: isToday
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isToday ? Colors.white : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday
                          ? Colors.white
                          : (marked ? AppColors.primary : Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMonth() {
    final year = widget.currentDate.year;
    final month = widget.currentDate.month;
    final first = DateTime(year, month, 1);
    // Monday = 1 ... Sunday = 7 → 我们用 0..6
    var firstWeekday = first.weekday - 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final today = DateTime.now();
    final labels = ['一', '二', '三', '四', '五', '六', '日'];

    return Column(
      children: [
        Row(
          children: labels
              .map(
                (l) => Expanded(
                  child: Center(
                    child: Text(
                      l,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        ...List.generate(6, (row) {
          return Row(
            children: List.generate(7, (col) {
              final idx = row * 7 + col;
              final day = idx - firstWeekday + 1;
              if (day < 1 || day > daysInMonth) {
                return const Expanded(child: SizedBox(height: 40));
              }
              final d = DateTime(year, month, day);
              final isToday = isSameDay(d, today);
              final marked = widget.hasRecordOn(d);
              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onDateTapped(d),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isToday ? AppColors.primary : null,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                              color: isToday ? Colors.white : AppColors.text,
                            ),
                          ),
                        ),
                        if (marked)
                          Positioned(
                            bottom: 4,
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isToday ? Colors.white : AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}
