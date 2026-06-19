import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../api/api_exception.dart';
import '../models/settings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _type = 'week';
  bool _loading = false;
  String? _error;
  List<LeaderboardEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list =
          await Get.find<AppState>().api.getLeaderboard(type: _type);
      if (mounted) setState(() => _entries = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '加载失败');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Get.find<AppState>();
    final r = context.r;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.only(bottom: r.bottomNavSafeGap),
        children: [
          Padding(
            padding: r.padFromLTRB(1.4, 1.0, 1.4, 0.8),
            child: Text(
              '🏆 排行榜',
              style: TextStyle(fontSize: r.text2xl, fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: r.padH(1.4),
            child: Container(
              padding: EdgeInsets.all(r.gap2xs),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(r.radiusMd),
              ),
              child: Row(
                children: [
                  _Tab(
                    label: '本周',
                    active: _type == 'week',
                    onTap: () {
                      setState(() => _type = 'week');
                      _load();
                    },
                  ),
                  _Tab(
                    label: '总榜',
                    active: _type == 'all',
                    onTap: () {
                      setState(() => _type = 'all');
                      _load();
                    },
                  ),
                ],
              ),
            ),
          ),
          Obx(() {
            if (state.isManualLocalMode.value) {
              return Padding(
                padding: r.padFromLTRB(1.4, 3.0, 1.4, 0),
                child: Column(
                  children: [
                    Text('📱', style: TextStyle(fontSize: r.textDisplay * 0.75)),
                    SizedBox(height: r.gapMd),
                    Text(
                      '本地模式不可用',
                      style: TextStyle(
                        fontSize: r.textLg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: r.gapXs),
                    Text(
                      '登录账号后可使用排行榜功能',
                      style: TextStyle(
                        fontSize: r.textBase,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (_loading) {
              return Padding(
                padding: EdgeInsets.all(r.gapXl * 1.5),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (_error != null) {
              return Padding(
                padding: EdgeInsets.all(r.gapXl),
                child: Center(
                  child: Text(
                    _error!,
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              );
            }
            if (_entries.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(r.gapXl),
                child: Center(
                  child: Text('暂无数据',
                      style: TextStyle(color: AppColors.textLight)),
                ),
              );
            }
            return Column(
              children: [
                SizedBox(height: r.gapLg),
                _Podium(entries: _entries),
                SizedBox(height: r.gapLg),
                ..._entries.asMap().entries.map((e) {
                  final i = e.key;
                  final u = e.value;
                  return Padding(
                    padding: r.padFromLTRB(1.4, 0, 1.4, 0.6),
                    child: _LbItem(rank: i + 1, entry: u),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: r.buttonHsm,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(r.radiusSm),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: r.textBase,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? AppColors.text : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  const _Podium({required this.entries});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final colors = [AppColors.lbFirst, AppColors.lbSecond, AppColors.lbThird];
    // 领奖台高度用相对量
    final baseHeight = r.gapLg * 1.6;  // ≈ 31~62
    final heights = [baseHeight * 1.5, baseHeight * 1.15, baseHeight * 0.85];
    final avatars = [r.avatarLg * 1.2, r.avatarMd * 1.3, r.avatarMd * 1.3];
    final order = [1, 0, 2];

    return Padding(
      padding: r.padH(1.4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final realRank = order[i];
          if (realRank >= entries.length) {
            return const Expanded(child: SizedBox());
          }
          final u = entries[realRank];
          final isFirst = realRank == 0;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFirst)
                  Text('👑', style: TextStyle(fontSize: r.textXl))
                else
                  SizedBox(height: r.textXl),
                SizedBox(height: r.gapXs * 0.5),
                Container(
                  width: avatars[realRank],
                  height: avatars[realRank],
                  decoration: BoxDecoration(
                    color: colors[realRank],
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white, width: isFirst ? 4 : 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    u.avatar.isEmpty ? '✈️' : u.avatar,
                    style: TextStyle(fontSize: isFirst ? r.text2xl * 1.4 : r.text2xl * 1.15),
                  ),
                ),
                SizedBox(height: r.gapXs * 0.6),
                Text(
                  u.nickname.isNotEmpty ? u.nickname : u.account,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: r.textXs, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: r.gapXs * 0.6),
                Container(
                  width: double.infinity,
                  height: heights[realRank],
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors[realRank],
                        colors[realRank].withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(r.radiusSm)),
                  ),
                  alignment: Alignment.topCenter,
                  padding: EdgeInsets.only(top: r.gapXs),
                  child: Text(
                    '${realRank + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: r.textXl,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _LbItem extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  const _LbItem({required this.rank, required this.entry});

  static const _medals = ['🥇', '🥈', '🥉'];
  static const _colors = [
    AppColors.lbFirst,
    AppColors.lbSecond,
    AppColors.lbThird,
    AppColors.lbFourth,
    AppColors.lbFifth,
  ];

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final color = rank - 1 < _colors.length
        ? _colors[rank - 1]
        : const Color(0xFFE2E8F0);
    return Container(
      padding: r.padAll(0.875),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(r.radiusLg),
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
          SizedBox(
            width: r.gapLg * 1.2,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: r.textLg,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(width: r.gapSm * 0.7),
          Container(
            width: r.touchTarget * 1.2,
            height: r.touchTarget * 1.2,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              entry.avatar.isEmpty ? '✈️' : entry.avatar,
              style: TextStyle(fontSize: r.text2xl * 0.95),
            ),
          ),
          SizedBox(width: r.gapSm * 0.95),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.nickname.isNotEmpty ? entry.nickname : entry.account,
                  style: TextStyle(
                    fontSize: r.textMd,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: r.gap2xs),
                Text(
                  '✈️ ${entry.count} 次起飞',
                  style: TextStyle(
                    fontSize: r.textXs,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (rank <= 3)
            Text(_medals[rank - 1], style: TextStyle(fontSize: r.textXl)),
        ],
      ),
    );
  }
}