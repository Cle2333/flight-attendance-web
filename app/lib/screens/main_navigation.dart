import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'main_dock.dart';
import 'profile_screen.dart';
import 'records_screen.dart';

/// App 主壳：4 个 tab 的 IndexedStack + 底部 dock
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
      // body 延伸到 dock 后面渲染，避免 dock 槽高度被算入 bodyMaxHeight
      // (SafeArea + CenteredFrame 在无界高度的 bottomNavigationBar 槽里更稳)
      extendBody: true,
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

          // 主内容：IndexedStack 让 4 个 screen 都活着，切换无重建
          Expanded(
            child: CenteredFrame(
              maxWidth: r.contentMaxWidth,
              child: IndexedStack(index: _index, children: _screens),
            ),
          ),
        ],
      ),

      // 底部 dock —— 已拆到 main_dock.dart
      bottomNavigationBar: SafeArea(
        top: false,
        child: CenteredFrame(
          maxWidth: r.contentMaxWidth,
          padding: EdgeInsets.only(bottom: r.gapSm),
          child: MainDock(
            index: _index,
            onChanged: (i) => setState(() => _index = i),
          ),
        ),
      ),
    );
  }
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
            padding: EdgeInsets.symmetric(
              horizontal: r.gapSm,
              vertical: r.gapSm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: r.iconMd * 0.9,
                  color: const Color(0xFF92400E),
                ),
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