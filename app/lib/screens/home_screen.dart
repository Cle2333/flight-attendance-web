import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/particle_burst.dart';
import '../widgets/takeoff_success_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _countdownTimer;
  int _quoteIndex = 0;
  final _rand = Random();

  DateTime? _lastTap;
  Offset _lastTapPos = Offset.zero;

  DateTime? _pendingTakeoff;
  final List<_ParticleLayer> _particleLayers = [];
  int _particleKey = 0;

  @override
  void initState() {
    super.initState();
    _pickQuote();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _pickQuote() {
    final quotes = Get.find<AppState>().settings.value.quotes;
    if (quotes.isEmpty) return;
    _quoteIndex = _rand.nextInt(quotes.length);
  }

  void _nextQuote() {
    final quotes = Get.find<AppState>().settings.value.quotes;
    if (quotes.isEmpty) return;
    setState(() {
      _quoteIndex = (_quoteIndex + 1) % quotes.length;
    });
  }

  void _handleTap(TapUpDetails details) {
    final now = DateTime.now();
    final pos = details.localPosition;
    if (_lastTap != null &&
        now.difference(_lastTap!).inMilliseconds < 300 &&
        (pos - _lastTapPos).distance < 30) {
      _takeOff(pos);
      _lastTap = null;
    } else {
      _lastTap = now;
      _lastTapPos = pos;
    }
  }

  Future<void> _takeOff(Offset localPos) async {
    final state = Get.find<AppState>();
    final record = await state.takeOff();
    setState(() {
      _particleKey++;
      _particleLayers.add(_ParticleLayer(
        key: ValueKey(_particleKey),
        emoji: state.settings.value.effectEmoji,
        center: localPos,
      ));
      _pendingTakeoff = record.time;
    });
  }

  Future<void> _completeTakeoff(String note) async {
    if (note.isNotEmpty) {
      await Get.find<AppState>().setLastRecordNote(note);
    }
    if (mounted) {
      setState(() => _pendingTakeoff = null);
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 6) return '凌晨好';
    if (h < 12) return '早上好';
    if (h < 18) return '下午好';
    return '晚上好';
  }

  @override
  Widget build(BuildContext context) {
    final state = Get.find<AppState>();
    return Stack(
      children: [
        GestureDetector(
          onTapUp: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.transparent,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: const TextStyle(
                            fontSize: 20,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(
                          () => Text(
                            state.currentUser.value?.nickname ?? '用户',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        const Text('👋', style: TextStyle(fontSize: 32)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Obx(() {
                    final last = state.lastTakeoff.value;
                    if (last == null || state.records.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final diff = DateTime.now().difference(last);
                    final display = formatDuration(
                        diff, state.settings.value.precisionEnum);
                    return Column(
                      children: [
                        const Text(
                          '距离上次起飞',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          display,
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: -2,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    );
                  }),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: _nextQuote,
                      child: Obx(() {
                        final quotes = state.settings.value.quotes;
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            quotes.isEmpty
                                ? '每一次起飞都是一次冒险'
                                : quotes[_quoteIndex % quotes.length],
                            key: ValueKey(_quoteIndex),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textLight,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '双击屏幕起飞',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),

        for (final layer in _particleLayers)
          ParticleBurst(
            key: layer.key,
            emoji: layer.emoji,
            center: layer.center,
            onComplete: () {
              if (mounted) {
                setState(() => _particleLayers.remove(layer));
              }
            },
          ),

        if (_pendingTakeoff != null)
          TakeoffSuccessOverlay(
            time: _pendingTakeoff!,
            onDismiss: () => setState(() => _pendingTakeoff = null),
            onComplete: _completeTakeoff,
          ),
      ],
    );
  }
}

class _ParticleLayer {
  final ValueKey<int> key;
  final String emoji;
  final Offset center;
  _ParticleLayer({required this.key, required this.emoji, required this.center});
}
