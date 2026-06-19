import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:http/http.dart' as http;

import '../models/record.dart';
import '../models/settings.dart';
import '../models/user.dart';
import '../storage/local_store.dart';

/// 从 `flutter run --dart-define=API_BASE_URL=...` 读取的全局默认后端地址
const _kApiBaseUrl = String.fromEnvironment('API_BASE_URL');

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

/// REST 客户端 —— 内部根据 localMode 切换"真后端"和"本地存储"
class ApiClient {
  final LocalStore store;
  String baseUrl;
  String? _token;
  http.Client _client;

  ApiClient(this.store, {String? baseUrl})
      : baseUrl = baseUrl ?? _resolveBaseUrl(store),
        _client = http.Client() {
    _token = store.getToken();
  }

  /// 测试用：注入 mock http client（AppState.bootstrap 的离线场景用）
  @visibleForTesting
  void setHttpClient(http.Client client) {
    _client = client;
  }

  static String _resolveBaseUrl(LocalStore store) {
    if (_kApiBaseUrl.isNotEmpty) return _kApiBaseUrl;
    final saved = store.getBaseUrl();
    if (saved != null && saved.isNotEmpty) return saved;
    return _defaultBaseUrl();
  }

  static String _defaultBaseUrl() {
    // Android 模拟器访问宿主机用 10.0.2.2，其他平台用 localhost
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  Future<void> updateBaseUrl(String url) async {
    baseUrl = url;
    await store.setBaseUrl(url);
  }

  String? get token => _token;
  void setToken(String? t) {
    _token = t;
  }

  Map<String, String> _headers([bool needAuth = true]) {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (needAuth && _token != null) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool needAuth = true,
    Duration? timeout,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    // 默认 8s 超时 —— 避免后端挂掉时启动黑屏 / 操作卡死
    final effectiveTimeout = timeout ?? const Duration(seconds: 8);
    http.Response res;
    try {
      switch (method) {
        case 'GET':
          res = await _client.get(uri, headers: _headers(needAuth)).timeout(effectiveTimeout);
          break;
        case 'POST':
          res = await _client.post(uri, headers: _headers(needAuth), body: body == null ? null : jsonEncode(body)).timeout(effectiveTimeout);
          break;
        case 'PUT':
          res = await _client.put(uri, headers: _headers(needAuth), body: body == null ? null : jsonEncode(body)).timeout(effectiveTimeout);
          break;
        case 'DELETE':
          res = await _client.delete(uri, headers: _headers(needAuth)).timeout(effectiveTimeout);
          break;
        default:
          throw ApiException('不支持的 HTTP 方法: $method');
      }
    } on TimeoutException {
      // .timeout() 抛的 TimeoutException 优先于 _request 后面那个，避免被吞
      throw ApiException('请求超时');
    } on http.ClientException catch (e) {
      throw ApiException('网络错误: ${e.message}');
    } on FormatException catch (e) {
      throw ApiException('服务器响应格式错误: ${e.message}');
    } catch (e) {
      throw ApiException('请求失败: $e');
    }

    final bodyText = utf8.decode(res.bodyBytes);
    Map<String, dynamic> data;
    try {
      data = jsonDecode(bodyText) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('服务器返回非 JSON: ${res.statusCode}');
    }
    if (data['success'] != true) {
      throw ApiException(
        data['message'] as String? ?? '请求失败 (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    return data;
  }

  // ==================== Auth ====================
  Future<AppUser> login(String account, String password) async {
    final data = await _request(
      'POST',
      '/api/auth/login',
      body: {'account': account, 'password': password},
      needAuth: false,
    );
    final d = data['data'] as Map<String, dynamic>;
    final token = d['token'] as String;
    _token = token;
    await store.setToken(token);
    final u = AppUser(
      id: (d['userId'] as num).toInt(),
      account: d['account'] as String,
      nickname: d['nickname'] as String? ?? account,
    );
    await store.setUser(u);
    return u;
  }

  Future<AppUser> register(String account, String password, String nickname) async {
    final data = await _request(
      'POST',
      '/api/auth/register',
      body: {'account': account, 'password': password, 'nickname': nickname},
      needAuth: false,
    );
    final d = data['data'] as Map<String, dynamic>;
    final token = d['token'] as String;
    _token = token;
    await store.setToken(token);
    final u = AppUser(
      id: (d['userId'] as num).toInt(),
      account: d['account'] as String,
      nickname: d['nickname'] as String? ?? nickname,
    );
    await store.setUser(u);
    return u;
  }

  Future<void> logout() async {
    _token = null;
    await store.setToken(null);
    await store.setUser(null);
  }

  // ==================== User ====================
  Future<AppUser> getUserProfile() async {
    final data = await _request('GET', '/api/user/profile');
    return AppUser.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<AppUser> updateUserProfile({String? nickname, String? avatar}) async {
    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (avatar != null) body['avatar'] = avatar;
    final data = await _request('PUT', '/api/user/profile', body: body);
    return AppUser.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ==================== Records ====================
  Future<List<FlightRecord>> getRecords() async {
    final data = await _request('GET', '/api/records');
    final list = (data['data'] as List? ?? []);
    return list
        .map((e) => FlightRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> addRecord(DateTime time, String note) async {
    final data = await _request(
      'POST',
      '/api/records',
      body: {'time': time.toUtc().toIso8601String(), 'note': note},
    );
    return ((data['data'] as Map<String, dynamic>)['id'] as num).toInt();
  }

  Future<void> updateRecord(int id, DateTime time, String note) async {
    await _request(
      'PUT',
      '/api/records/$id',
      body: {'time': time.toUtc().toIso8601String(), 'note': note},
    );
  }

  Future<void> deleteRecord(int id) async {
    await _request('DELETE', '/api/records/$id');
  }

  Future<void> syncRecords(List<Map<String, dynamic>> records) async {
    await _request('POST', '/api/records/sync', body: {'records': records});
  }

  // ==================== Settings ====================
  Future<AppSettings> getSettings() async {
    final data = await _request('GET', '/api/settings');
    return AppSettings.fromJson(data['data'] as Map<String, dynamic>?);
  }

  Future<void> updateSettings({
    String? precision,
    String? effect,
    String? effectEmoji,
    String? theme,
    List<String>? quotes,
  }) async {
    final body = <String, dynamic>{};
    if (precision != null) body['precision'] = precision;
    if (effect != null) body['effect'] = effect;
    if (effectEmoji != null) body['effectEmoji'] = effectEmoji;
    if (theme != null) body['theme'] = theme;
    if (quotes != null) body['quotes'] = quotes;
    await _request('PUT', '/api/settings', body: body);
  }

  // ==================== Admin ====================
  Future<List<LeaderboardEntry>> getLeaderboard({String type = 'all'}) async {
    final data = await _request(
      'GET',
      '/api/admin/leaderboard?type=$type',
      needAuth: false,
    );
    final list = (data['data'] as List? ?? []);
    return list
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminStats> getAdminStats() async {
    final data = await _request('GET', '/api/admin/stats', needAuth: false);
    return AdminStats.fromJson(data['data'] as Map<String, dynamic>);
  }
}
