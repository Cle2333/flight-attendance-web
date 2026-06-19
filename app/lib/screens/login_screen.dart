import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../api/api_exception.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'server_config_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _loading = false;
  String? _message;
  MessageType _msgType = MessageType.error;

  final _accountCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();

  @override
  void dispose() {
    _accountCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isLogin = !_isLogin;
      _message = null;
    });
  }

  void _setMessage(String? msg, [MessageType t = MessageType.error]) {
    setState(() {
      _message = msg;
      _msgType = t;
    });
  }

  Future<void> _submit() async {
    final account = _accountCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (account.isEmpty || password.isEmpty) {
      _setMessage('请填写完整信息');
      return;
    }
    final state = Get.find<AppState>();
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await state.login(account, password);
        _setMessage('登录成功', MessageType.success);
      } else {
        final nickname = _nicknameCtrl.text.trim();
        if (nickname.isEmpty) {
          _setMessage('请输入昵称');
          setState(() => _loading = false);
          return;
        }
        if (password != _confirmCtrl.text) {
          _setMessage('两次输入的密码不一致');
          setState(() => _loading = false);
          return;
        }
        if (password.length < 6) {
          _setMessage('密码长度不能少于6位');
          setState(() => _loading = false);
          return;
        }
        await state.register(account, password, nickname);
        _setMessage('注册成功', MessageType.success);
      }
    } on ApiException catch (e) {
      _setMessage(e.message);
    } catch (e) {
      _setMessage('操作失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _enterLocal() async {
    await Get.find<AppState>().enterLocalMode();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            CenteredFrame(
              maxWidth: r.contentMaxWidth,
              child: SingleChildScrollView(
                padding: r.padH(2.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.vertical,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: r.gap2xl),
                      Container(
                        width: r.gap2xl * 1.05,
                        height: r.gap2xl * 1.05,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(r.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.flight,
                          color: Colors.white,
                          size: r.icon2xl,
                        ),
                      ),
                      SizedBox(height: r.gapLg),
                      Text(
                        '航班打卡',
                        style: TextStyle(
                          fontSize: r.text3xl,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: r.gapXs * 0.6),
                      Text(
                        '记录每一次起飞',
                        style: TextStyle(
                          fontSize: r.textBase,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: r.gap2xl),
                      TextField(
                        controller: _accountCtrl,
                        decoration: const InputDecoration(labelText: '账号'),
                      ),
                      if (!_isLogin) ...[
                        SizedBox(height: r.gapSm),
                        TextField(
                          controller: _nicknameCtrl,
                          decoration: const InputDecoration(labelText: '昵称'),
                        ),
                      ],
                      SizedBox(height: r.gapSm),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: '密码'),
                      ),
                      if (!_isLogin) ...[
                        SizedBox(height: r.gapSm),
                        TextField(
                          controller: _confirmCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: '确认密码'),
                        ),
                      ],
                      SizedBox(height: r.gapLg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_box,
                                  size: r.iconSm, color: AppColors.textSecondary),
                              SizedBox(width: r.gapXs * 0.6),
                              Text('记住我',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: r.textSm)),
                            ],
                          ),
                          GestureDetector(
                            onTap: _toggle,
                            behavior: HitTestBehavior.opaque,
                            child: Text(
                              _isLogin ? '注册账号' : '返回登录',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: r.textSm,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: r.gapLg),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? SizedBox(
                                  width: r.gapMd * 1.25,
                                  height: r.gapMd * 1.25,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_isLogin ? '登录' : '注册'),
                        ),
                      ),
                      SizedBox(height: r.gapSm),
                      if (_message != null)
                        Text(
                          _message!,
                          style: TextStyle(
                            color: _msgType == MessageType.error
                                ? AppColors.danger
                                : AppColors.success,
                            fontSize: r.textSm,
                          ),
                        ),
                      SizedBox(height: r.gapLg),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _enterLocal,
                          icon: const Text('📱'),
                          label: const Text('本地模式（无需登录）'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: AppColors.textSecondary,
                            minimumSize: Size.fromHeight(r.buttonHsm),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(r.radiusMd)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: r.gapXs,
              right: r.gapXs,
              child: SafeArea(
                child: IconButton(
                  icon: Icon(Icons.settings_outlined,
                      size: r.iconMd, color: AppColors.textLight),
                  onPressed: () => Get.to(() => const ServerConfigScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum MessageType { error, success }