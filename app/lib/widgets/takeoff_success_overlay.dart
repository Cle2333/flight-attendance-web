import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';

/// 起飞成功遮罩 —— 选感受 / 自定义 / 完成
class TakeoffSuccessOverlay extends StatefulWidget {
  final DateTime time;
  final ValueChanged<String> onComplete;
  final VoidCallback onDismiss;

  const TakeoffSuccessOverlay({
    super.key,
    required this.time,
    required this.onComplete,
    required this.onDismiss,
  });

  @override
  State<TakeoffSuccessOverlay> createState() => _TakeoffSuccessOverlayState();
}

class _TakeoffSuccessOverlayState extends State<TakeoffSuccessOverlay>
    with SingleTickerProviderStateMixin {
  String? _selected;
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  static const _presets = ['🔥 太爽了', '💫 燃尽了', '😰 后悔了'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    widget.onComplete(_selected ?? '');
  }

  Future<void> _showCustomDialog() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('写下你的感受'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(hintText: '例如：飞向云端'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _selected = result);
      await _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Positioned.fill(
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          color: AppColors.primary,
          child: SafeArea(
            child: CenteredFrame(
              maxWidth: r.contentMaxWidth,
              child: SlideTransition(
                position: _slide,
                child: Column(
                  children: [
                    const Spacer(),
                    Text('✈️', style: TextStyle(fontSize: r.textDisplay * 1.25)),
                    SizedBox(height: r.gapLg),
                    Text(
                      '起飞成功！',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: r.text3xl,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: r.gapXs),
                    Text(
                      DateFormatters.timeHM(widget.time),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: r.textLg,
                      ),
                    ),
                    SizedBox(height: r.gap2xl),
                    Padding(
                      padding: r.padH(2.4),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 2.4,
                        mainAxisSpacing: r.gapMd,
                        crossAxisSpacing: r.gapMd,
                        children: [
                          ..._presets.map(
                            (p) => _FeelingButton(
                              label: p,
                              selected: _selected == p,
                              onTap: () => setState(() => _selected = p),
                            ),
                          ),
                          _FeelingButton(
                            label: '✏️ 自定义感受',
                            selected: false,
                            onTap: _showCustomDialog,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: r.gap2xl),
                    ElevatedButton(
                      onPressed: _complete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: r.padHV(2.6, 1.0),
                        shape: const StadiumBorder(),
                        elevation: 4,
                        shadowColor: Colors.black26,
                        textStyle: TextStyle(
                          fontSize: r.textLg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('完成记录'),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeelingButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FeelingButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Material(
      color: selected
          ? Colors.white.withValues(alpha: 0.4)
          : Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(r.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r.radiusMd),
            border: Border.all(
              color: selected ? Colors.white : Colors.white.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: r.textMd,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}