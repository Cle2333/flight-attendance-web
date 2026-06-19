import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../api/api_exception.dart';
import '../models/settings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

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
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Text(
              '🏆 排行榜',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
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
            if (state.isLocalMode.value) {
              return const Padding(
                padding: EdgeInsets.fromLTRB(24, 60, 24, 0),
                child: Column(
                  children: [
                    Text('📱', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 16),
                    Text(
                      '本地模式不可用',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '登录账号后可使用排行榜功能',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (_loading) {
              return const Padding(
                padding: EdgeInsets.all(60),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (_error != null) {
              return Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              );
            }
            if (_entries.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text('暂无数据',
                      style: TextStyle(color: AppColors.textLight)),
                ),
              );
            }
            return Column(
              children: [
                const SizedBox(height: 20),
                _Podium(entries: _entries),
                const SizedBox(height: 20),
                ..._entries.asMap().entries.map((e) {
                  final i = e.key;
                  final u = e.value;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
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
              fontSize: 14,
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
    final colors = [AppColors.lbFirst, AppColors.lbSecond, AppColors.lbThird];
    final heights = [80.0, 60.0, 44.0];
    final avatars = [68.0, 56.0, 56.0];
    final order = [1, 0, 2];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  const Text('👑', style: TextStyle(fontSize: 24))
                else
                  const SizedBox(height: 24),
                const SizedBox(height: 4),
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
                    style: TextStyle(fontSize: isFirst ? 34 : 28),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  u.nickname.isNotEmpty ? u.nickname : u.account,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
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
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                  ),
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${realRank + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
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
    final color = rank - 1 < _colors.length
        ? _colors[rank - 1]
        : const Color(0xFFE2E8F0);
    return Container(
      padding: const EdgeInsets.all(14),
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
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              entry.avatar.isEmpty ? '✈️' : entry.avatar,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.nickname.isNotEmpty ? entry.nickname : entry.account,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '✈️ ${entry.count} 次起飞',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (rank <= 3)
            Text(_medals[rank - 1], style: const TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}
