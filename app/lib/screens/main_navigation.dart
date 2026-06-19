import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'records_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    RecordsScreen(),
    LeaderboardScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = Get.find<AppState>();
    final r = context.r;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // 离线 banner —— 只在 (在线模式 + 网络不可达) 时出现
          Obx(() {
            if (!state.offline.value || state.isLocalMode.value) {
              return const SizedBox.shrink();
            }
            return _OfflineBanner(
              onRetry: () async {
                final ok = await state.retryConnection();
                if (!ok && mounted) {
                  Get.snackbar(
                    '仍不可达',
                    '服务器没响应，继续本地保存',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2),
                  );
                }
              },
            );
          }),

          // 桌面端：内容居中 + 约束在手机列宽内
          Expanded(
            child: CenteredFrame(
              maxWidth: r.contentMaxWidth,
              child: IndexedStack(
                index: _index,
                children: _screens,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: CenteredFrame(
          maxWidth: r.contentMaxWidth,
          padding: EdgeInsets.only(bottom: r.gapSm),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: r.gapMd),
            height: r.navBarH,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9).withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(r.radiusXl),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(r.radiusXl),
              child: Row(
                children: List.generate(_icons.length, (i) {
                  final active = i == _index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _index = i),
                      behavior: HitTestBehavior.opaque,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            width: active ? r.gapXl * 1.4 : 0,
                            height: r.buttonHsm,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(r.radiusMd),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _icons[i],
                                size: r.iconMd,
                                color: active
                                    ? AppColors.primary
                                    : AppColors.textLight,
                              ),
                              SizedBox(height: r.gap2xs),
                              Text(
                                _labels[i],
                                style: TextStyle(
                                  fontSize: r.textXs,
                                  fontWeight: active
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _icons = <IconData>[
    Icons.home_outlined,
    Icons.calendar_today_outlined,
    Icons.emoji_events_outlined,
    Icons.person_outline,
  ];

  static const _labels = ['首页', '记录', '排行', '我的'];
}

/// 顶部黄条 —— server 不可达时提醒，本地缓存可用、所有操作仍工作
class _OfflineBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _OfflineBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Material(
      color: const Color(0xFFFEF3C7),
      child: SafeArea(
        bottom: false,
        child: CenteredFrame(
          maxWidth: r.contentMaxWidth,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: r.gapSm, vertical: r.gapSm),
            child: Row(
              children: [
                Icon(Icons.cloud_off_outlined,
                    size: r.iconMd * 0.9, color: const Color(0xFF92400E)),
                SizedBox(width: r.gapXs),
                Expanded(
                  child: Text(
                    '无法连接服务器，已切换到本地保存',
                    style: TextStyle(
                      fontSize: r.textSm,
                      color: const Color(0xFF92400E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF92400E),
                    padding: EdgeInsets.symmetric(
                      horizontal: r.gapXs,
                      vertical: r.gap2xs,
                    ),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('重试', style: TextStyle(fontSize: r.textSm)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}