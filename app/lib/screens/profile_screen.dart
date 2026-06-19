import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/picker_modals.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Get.find<AppState>();
    return SafeArea(
      bottom: false,
      child: Obx(() {
        final user = state.currentUser.value;
        final isLocal = state.isLocalMode.value;
        final avatar = user?.avatar?.isNotEmpty == true ? user!.avatar! : '✈️';
        final nickname = user?.nickname ?? '用户';
        final id = isLocal
            ? '本地模式'
            : 'ID: USER-${(user?.id ?? 0).toString().padLeft(4, '0')}';

        return ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(28),
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
                  GestureDetector(
                    onTap: () => Get.dialog(
                      AvatarPicker(
                        current: avatar,
                        onPick: (e) => state.updateAvatar(e),
                      ),
                    ),
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(avatar, style: const TextStyle(fontSize: 34)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => Get.dialog(
                      NicknameEditor(
                        current: nickname,
                        onSave: state.updateNickname,
                      ),
                    ),
                    child: Text(
                      nickname,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(id,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      )),
                  const SizedBox(height: 22),
                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ProfileStat(n: '${state.totalRecords}', l: '总起飞'),
                      _ProfileStat(n: '${state.currentStreak}', l: '连续天数'),
                      _ProfileStat(n: '${state.badges}', l: '徽章'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Group(
              children: [
                _Row(
                  icon: '✏️',
                  color: AppColors.primaryBg,
                  title: '修改昵称',
                  subtitle: '当前: $nickname',
                  onTap: () => Get.dialog(
                    NicknameEditor(
                      current: nickname,
                      onSave: state.updateNickname,
                    ),
                  ),
                ),
                _Row(
                  icon: '🖼️',
                  color: const Color(0xFFFAF5FF),
                  title: '更换头像',
                  subtitle: '选择喜欢的头像',
                  onTap: () => Get.dialog(
                    AvatarPicker(
                      current: avatar,
                      onPick: state.updateAvatar,
                    ),
                  ),
                ),
              ],
            ),
            _Group(
              children: [
                _Row(
                  icon: '⏱️',
                  color: AppColors.primaryBg,
                  title: '计时精度',
                  subtitle: '当前: ${state.settings.value.precisionEnum.displayName}',
                  onTap: () => Get.dialog(
                    PrecisionPicker(
                      current: state.settings.value.precisionEnum,
                      onPick: (p) => state.updatePrecision(p.name),
                    ),
                  ),
                ),
                _Row(
                  icon: '🎆',
                  color: const Color(0xFFFAF5FF),
                  title: '起飞特效',
                  subtitle: '当前: ${state.settings.value.effectEmoji}',
                  onTap: () => Get.dialog(
                    EffectEmojiPicker(
                      current: state.settings.value.effectEmoji,
                      onPick: state.updateEffectEmoji,
                    ),
                  ),
                ),
                _Row(
                  icon: '💬',
                  color: const Color(0xFFFFFBEB),
                  title: '机长语录',
                  subtitle: '${state.settings.value.quotes.length} 条',
                  onTap: () => Get.dialog(
                    QuotesEditor(
                      initial: state.settings.value.quotes,
                      onSave: state.updateQuotes,
                    ),
                  ),
                ),
              ],
            ),
            _Group(
              children: [
                _Row(
                  icon: '🔄',
                  color: AppColors.primaryBg,
                  title: isLocal ? '切换到云端模式' : '切换到本地模式',
                  subtitle: '当前: ${isLocal ? '本地模式' : '云端模式'}',
                  onTap: () async {
                    if (isLocal) {
                      await state.logout();
                    } else {
                      await state.enterLocalMode();
                    }
                  },
                ),
                _Row(
                  icon: '🚪',
                  color: const Color(0xFFFEF2F2),
                  iconColor: AppColors.danger,
                  title: '退出登录',
                  subtitle: null,
                  onTap: () async {
                    final ok = await Get.dialog<bool>(
                      AlertDialog(
                        title: const Text('退出登录'),
                        content: Text(isLocal
                            ? '退出本地模式？本地数据将被清空。'
                            : '确定要退出登录？'),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(result: false),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.danger),
                            onPressed: () => Get.back(result: true),
                            child: const Text('退出'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await state.logout();
                    }
                  },
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String n;
  final String l;
  const _ProfileStat({required this.n, required this.l});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          n,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(l,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            )),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
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
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(
                  height: 1,
                  color: AppColors.border,
                  indent: 16,
                  endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback onTap;

  const _Row({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(icon,
                    style: TextStyle(
                      fontSize: 17,
                      color: iconColor,
                    )),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        )),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          )),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}
