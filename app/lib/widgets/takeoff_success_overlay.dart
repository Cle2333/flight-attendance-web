import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';

/// 起飞成功遮罩 —— 选感受 / 自定义 / 完成
///
/// 布局策略:
///  - 移动端(< 1024): 沿用原 Column + Spacer 居中堆叠
///  - 桌面端(>= 1024): Row 左右分栏 —— 左庆祝文案,右感受按钮 + 完成按钮
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
                // 窄屏兜底 —— 桌面端 Row 需要 ~ 200 + 2*compactPanelMaxWidth 的宽,
                // 不到的话用移动布局避免 overflow。
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wideEnough =
                        constraints.maxWidth >= r.compactPanelMaxWidth * 2 + 200;
                    return (r.isDesktop && wideEnough)
                        ? _buildDesktop(r)
                        : _buildMobile(r);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 移动端:纵向居中堆叠。
  ///
  /// 用 LayoutBuilder + 内层缩放因子 k(=min(1, maxHeight/idealH))把
  /// emoji/字号/间距按可用高度等比缩,避免高 >= ~480 的屏幕(如 Chrome
  /// devtools 420×447、iPhone SE 等短高场景)出现 vertical overflow。
  /// k=1 时与原版完全一致。
  Widget _buildMobile(Responsive r) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const idealH = 540.0; // 设计稿高度参考值
        final k = (constraints.maxHeight / idealH).clamp(0.55, 1.0).toDouble();

        // 在 k<1 的场景下,额外收紧 grid 的 childAspectRatio(更扁),
        // 让 2 行 grid 高度总和降下来。
        final gridAspect = 2.4 + (1.0 - k) * 1.2; // k=1 → 2.4, k=0.55 → 3.24

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('✈️',
                style: TextStyle(fontSize: r.textDisplay * 1.25 * k)),
            SizedBox(height: r.gapLg * k),
            Text(
              '起飞成功！',
              style: TextStyle(
                color: Colors.white,
                fontSize: r.text3xl * k,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: r.gapXs * k),
            Text(
              DateFormatters.timeHM(widget.time),
              style: TextStyle(
                color: Colors.white,
                fontSize: r.textLg * k,
              ),
            ),
            SizedBox(height: r.gap2xl * k),
            Padding(
              padding: r.padH(2.4),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: gridAspect,
                mainAxisSpacing: r.gapMd * k,
                crossAxisSpacing: r.gapMd * k,
                children: _buttons(),
              ),
            ),
            SizedBox(height: r.gap2xl * k),
            ElevatedButton(
              onPressed: _complete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: r.padHV(2.6, 1.0 * k),
                shape: const StadiumBorder(),
                elevation: 4,
                shadowColor: Colors.black26,
                textStyle: TextStyle(
                  fontSize: r.textLg * k,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('完成记录'),
            ),
          ],
        );
      },
    );
  }

  /// 桌面端:Row 左右分栏。
  ///   - 左:emoji + 标题 + 时间(居左,主信息)
  ///   - 右:感受按钮(2x2 grid,限宽 compactPanelMaxWidth)+ 完成按钮
  ///
  /// 父级 CenteredFrame 已经给了 Row 有界高度,直接 mainAxisAlignment.center
  /// 就能让两侧内容垂直居中。**不能**套 IntrinsicHeight —— GridView(shrinkWrap:true)
  /// 用的是 RenderShrinkWrappingViewport,不支持计算 intrinsic dimensions,
  /// 任何要求子节点报告 intrinsic height 的父节点都会炸。
  Widget _buildDesktop(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.gapXl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── 左:庆祝文案 ──────────────────────────
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✈️',
                  style: TextStyle(fontSize: r.textDisplay * 1.5),
                ),
                SizedBox(height: r.gapLg),
                Text(
                  '起飞成功！',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: r.text4xl,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: r.gapXs),
                Text(
                  DateFormatters.timeHM(widget.time),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: r.textXl,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: r.gap2xl),
          // ── 右:感受 + 完成(走 compactPanelMaxWidth,宽屏不拉爆) ──
          SizedBox(
            width: r.compactPanelMaxWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.4,
                  mainAxisSpacing: r.gapMd,
                  crossAxisSpacing: r.gapMd,
                  children: _buttons(),
                ),
                SizedBox(height: r.gapXl),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buttons() {
    return [
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
    ];
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
