import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// 头像选择
class AvatarPicker extends StatefulWidget {
  final String current;
  final ValueChanged<String> onPick;
  const AvatarPicker({super.key, required this.current, required this.onPick});

  static const _emojis = [
    '✈️', '🚀', '🌟', '🎉', '💫', '🔥', '⚡', '🎯',
    '🦅', '🕊️', '🛸', '🎈', '🌈', '☀️', '🌙', '⭐',
  ];

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  late String _selected = widget.current;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '选择头像',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: AvatarPicker._emojis.map((e) {
                final isSelected = e == _selected;
                return InkWell(
                  onTap: () => setState(() => _selected = e),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryBg : Colors.white,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 32)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onPick(_selected);
                      Navigator.pop(context);
                    },
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 起飞特效 emoji 选择（少 8 个）
class EffectEmojiPicker extends StatefulWidget {
  final String current;
  final ValueChanged<String> onPick;
  const EffectEmojiPicker({super.key, required this.current, required this.onPick});

  static const _emojis = ['✈️', '🚀', '🌟', '🎉', '💫', '🔥', '⚡', '🎯'];

  @override
  State<EffectEmojiPicker> createState() => _EffectEmojiPickerState();
}

class _EffectEmojiPickerState extends State<EffectEmojiPicker> {
  late String _selected = widget.current;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '起飞特效 Emoji',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: EffectEmojiPicker._emojis.map((e) {
                final isSelected = e == _selected;
                return InkWell(
                  onTap: () => setState(() => _selected = e),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryBg : Colors.white,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 32)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onPick(_selected);
                      Navigator.pop(context);
                    },
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 计时精度选择
class PrecisionPicker extends StatefulWidget {
  final CountdownPrecision current;
  final ValueChanged<CountdownPrecision> onPick;
  const PrecisionPicker({super.key, required this.current, required this.onPick});

  @override
  State<PrecisionPicker> createState() => _PrecisionPickerState();
}

class _PrecisionPickerState extends State<PrecisionPicker> {
  late CountdownPrecision _selected = widget.current;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '计时精度',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            RadioGroup<CountdownPrecision>(
              groupValue: _selected,
              onChanged: (v) {
                if (v != null) setState(() => _selected = v);
              },
              child: Column(
                children: CountdownPrecision.values
                    .map((p) => RadioListTile<CountdownPrecision>(
                          value: p,
                          title: Text(p.displayName),
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onPick(_selected);
                      Navigator.pop(context);
                    },
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 昵称编辑
class NicknameEditor extends StatefulWidget {
  final String current;
  final ValueChanged<String> onSave;
  const NicknameEditor({super.key, required this.current, required this.onSave});

  @override
  State<NicknameEditor> createState() => _NicknameEditorState();
}

class _NicknameEditorState extends State<NicknameEditor> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.current);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '修改昵称',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLength: 20,
              decoration: const InputDecoration(hintText: '请输入新昵称'),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final v = _ctrl.text.trim();
                      if (v.isEmpty) return;
                      if (v.length > 20) return;
                      widget.onSave(v);
                      Navigator.pop(context);
                    },
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 机长语录编辑
class QuotesEditor extends StatefulWidget {
  final List<String> initial;
  final ValueChanged<List<String>> onSave;
  const QuotesEditor({super.key, required this.initial, required this.onSave});

  @override
  State<QuotesEditor> createState() => _QuotesEditorState();
}

class _QuotesEditorState extends State<QuotesEditor> {
  late final List<TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    final init = widget.initial.isEmpty ? [''] : widget.initial;
    _ctrls = init.map((q) => TextEditingController(text: q)).toList();
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _add() {
    setState(() => _ctrls.add(TextEditingController()));
  }

  void _remove(int i) {
    if (_ctrls.length <= 1) return;
    setState(() {
      _ctrls[i].dispose();
      _ctrls.removeAt(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '机长语录',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(_ctrls.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ctrls[i],
                              decoration: const InputDecoration(hintText: '一条语录'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _remove(i),
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.danger),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('添加语录'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final list = _ctrls
                          .map((c) => c.text.trim())
                          .where((s) => s.isNotEmpty)
                          .toList();
                      widget.onSave(list);
                      Navigator.pop(context);
                    },
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 后端地址配置
class ServerConfigModal extends StatefulWidget {
  final String current;
  final ValueChanged<String> onSave;
  const ServerConfigModal({super.key, required this.current, required this.onSave});

  @override
  State<ServerConfigModal> createState() => _ServerConfigModalState();
}

class _ServerConfigModalState extends State<ServerConfigModal> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.current);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '服务器地址',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Android 模拟器请用 10.0.2.2，真机请用局域网 IP',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'http://192.168.1.100:8080',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final v = _ctrl.text.trim();
                      if (v.isEmpty) return;
                      widget.onSave(v);
                      Navigator.pop(context);
                    },
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
