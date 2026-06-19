import 'package:get/get.dart';

import '../api/api_client.dart' show ApiClient;
import '../api/api_exception.dart';
import '../models/record.dart';
import '../models/settings.dart';
import '../models/user.dart';
import '../storage/local_store.dart';

/// 全局应用状态。GetX 注入。
class AppState extends GetxController {
  final LocalStore store;
  final ApiClient api;

  AppState({required this.store, required this.api});

  // ====== 会话 ======
  final RxBool isLocalMode = false.obs;
  final Rxn<AppUser> currentUser = Rxn<AppUser>();
  final RxBool booted = false.obs;

  // ====== 数据 ======
  final RxList<FlightRecord> records = <FlightRecord>[].obs;
  final Rx<AppSettings> settings = const AppSettings().obs;

  // ====== 起飞 ======
  final Rxn<DateTime> lastTakeoff = Rxn<DateTime>();

  /// 应用启动
  Future<void> bootstrap() async {
    isLocalMode.value = store.isLocalMode();
    api.setToken(store.getToken());

    if (isLocalMode.value) {
      currentUser.value = store.getLocalUser() ??
          const AppUser(id: 0, account: 'local', nickname: '本地用户', avatar: '✈️');
      records.assignAll(store.getLocalRecords());
      settings.value = store.getLocalSettings();
      lastTakeoff.value = store.getLastTakeoff() ??
          (records.isNotEmpty
              ? records.map((r) => r.time).reduce((a, b) => a.isAfter(b) ? a : b)
              : null);
    } else {
      currentUser.value = store.getUser();
      if (currentUser.value != null) {
        try {
          await refreshAll();
        } on ApiException catch (e) {
          if (e.statusCode == 401 || e.statusCode == 403) {
            await api.logout();
            currentUser.value = null;
          } else {
            rethrow;
          }
        }
      }
    }
    booted.value = true;
  }

  Future<void> refreshAll() async {
    final user = await api.getUserProfile();
    currentUser.value = user;
    await store.setUser(user);
    final fetched = await api.getRecords();
    records.assignAll(fetched);
    settings.value = await api.getSettings();
    if (records.isNotEmpty) {
      lastTakeoff.value =
          records.map((r) => r.time).reduce((a, b) => a.isAfter(b) ? a : b);
      await store.setLastTakeoff(lastTakeoff.value);
    } else {
      lastTakeoff.value = null;
      await store.setLastTakeoff(null);
    }
  }

  // ====== 认证 ======
  Future<void> login(String account, String password) async {
    final u = await api.login(account, password);
    isLocalMode.value = false;
    await store.setLocalMode(false);
    currentUser.value = u;
    await refreshAll();
  }

  Future<void> register(String account, String password, String nickname) async {
    final u = await api.register(account, password, nickname);
    isLocalMode.value = false;
    await store.setLocalMode(false);
    currentUser.value = u;
    await refreshAll();
  }

  Future<void> enterLocalMode() async {
    isLocalMode.value = true;
    await store.setLocalMode(true);
    final u = store.getLocalUser() ??
        const AppUser(id: 0, account: 'local', nickname: '本地用户', avatar: '✈️');
    currentUser.value = u;
    await store.setUser(u);
    await store.setLocalUser(u);
    records.assignAll(store.getLocalRecords());
    settings.value = store.getLocalSettings();
    lastTakeoff.value = store.getLastTakeoff() ??
        (records.isNotEmpty
            ? records.map((r) => r.time).reduce((a, b) => a.isAfter(b) ? a : b)
            : null);
  }

  Future<void> logout() async {
    if (isLocalMode.value) {
      await store.clearLocal();
      records.clear();
      settings.value = const AppSettings();
      lastTakeoff.value = null;
      currentUser.value = null;
      isLocalMode.value = false;
    } else {
      await api.logout();
      records.clear();
      settings.value = const AppSettings();
      lastTakeoff.value = null;
      currentUser.value = null;
    }
  }

  Future<void> switchMode() async {
    if (isLocalMode.value) {
      await logout();
    } else {
      await enterLocalMode();
    }
  }

  // ====== 起飞 ======
  Future<FlightRecord> takeOff() async {
    final now = DateTime.now();
    if (isLocalMode.value) {
      final id = records.isEmpty
          ? 1
          : records.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
      final r = FlightRecord(id: id, userId: 0, time: now);
      records.add(r);
      await store.setLocalRecords(records);
      lastTakeoff.value = now;
      await store.setLastTakeoff(now);
    } else {
      await api.addRecord(now, '');
      await refreshAll();
    }
    return records.last;
  }

  Future<void> setLastRecordNote(String note) async {
    if (records.isEmpty) return;
    final last = records.last;
    if (isLocalMode.value) {
      final idx = records.length - 1;
      records[idx] = FlightRecord(
        id: last.id,
        userId: last.userId,
        time: last.time,
        note: note,
        createdAt: last.createdAt,
      );
      await store.setLocalRecords(records);
    } else {
      await api.updateRecord(last.id, last.time, note);
      await refreshAll();
    }
  }

  // ====== 设置 ======
  Future<void> updatePrecision(String p) async {
    if (isLocalMode.value) {
      settings.value = settings.value.copyWith(precision: p);
      await store.setLocalSettings(settings.value);
    } else {
      await api.updateSettings(precision: p);
      settings.value = settings.value.copyWith(precision: p);
    }
  }

  Future<void> updateEffectEmoji(String e) async {
    if (isLocalMode.value) {
      settings.value = settings.value.copyWith(effectEmoji: e);
      await store.setLocalSettings(settings.value);
    } else {
      await api.updateSettings(effectEmoji: e);
      settings.value = settings.value.copyWith(effectEmoji: e);
    }
  }

  Future<void> updateQuotes(List<String> quotes) async {
    if (isLocalMode.value) {
      settings.value = settings.value.copyWith(quotes: quotes);
      await store.setLocalSettings(settings.value);
    } else {
      await api.updateSettings(quotes: quotes);
      settings.value = settings.value.copyWith(quotes: quotes);
    }
  }

  // ====== 用户 ======
  Future<void> updateNickname(String nickname) async {
    if (isLocalMode.value) {
      final updated = currentUser.value?.copyWith(nickname: nickname);
      currentUser.value = updated;
      if (updated != null) {
        await store.setLocalUser(updated);
        await store.setUser(updated);
      }
    } else {
      final u = await api.updateUserProfile(nickname: nickname);
      currentUser.value = u;
      await store.setUser(u);
    }
  }

  Future<void> updateAvatar(String avatar) async {
    if (isLocalMode.value) {
      final updated = currentUser.value?.copyWith(avatar: avatar);
      currentUser.value = updated;
      if (updated != null) {
        await store.setLocalUser(updated);
        await store.setUser(updated);
      }
    } else {
      final u = await api.updateUserProfile(avatar: avatar);
      currentUser.value = u;
      await store.setUser(u);
    }
  }

  // ====== 单条记录 ======
  Future<void> updateRecord(int id, DateTime time, String note) async {
    if (isLocalMode.value) {
      final idx = records.indexWhere((r) => r.id == id);
      if (idx != -1) {
        final r = records[idx];
        records[idx] = FlightRecord(
          id: r.id,
          userId: r.userId,
          time: time,
          note: note,
          createdAt: r.createdAt,
        );
        await store.setLocalRecords(records);
      }
    } else {
      await api.updateRecord(id, time, note);
      await refreshAll();
    }
  }

  Future<void> deleteRecord(int id) async {
    if (isLocalMode.value) {
      records.removeWhere((r) => r.id == id);
      await store.setLocalRecords(records);
      if (records.isEmpty) {
        lastTakeoff.value = null;
        await store.setLastTakeoff(null);
      } else {
        lastTakeoff.value =
            records.map((r) => r.time).reduce((a, b) => a.isAfter(b) ? a : b);
        await store.setLastTakeoff(lastTakeoff.value);
      }
    } else {
      await api.deleteRecord(id);
      await refreshAll();
    }
  }

  // ====== 派生（用 getter 让模板里 .obs 调用更顺）======
  int get totalRecords => records.length;

  int get currentStreak {
    if (records.isEmpty) return 0;
    final set = records
        .map((r) => DateTime(r.time.year, r.time.month, r.time.day))
        .toSet();
    int streak = 0;
    var d = DateTime.now();
    var d0 = DateTime(d.year, d.month, d.day);
    while (set.contains(d0)) {
      streak++;
      d0 = d0.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int? get averageTakeoffHour {
    if (records.isEmpty) return null;
    final hours = records.map((r) => r.time.hour);
    final avg = hours.reduce((a, b) => a + b) / hours.length;
    return avg.round();
  }

  int get badges => records.length ~/ 10;

  bool hasRecordOn(DateTime d) {
    final d0 = DateTime(d.year, d.month, d.day);
    return records.any((r) =>
        r.time.year == d0.year &&
        r.time.month == d0.month &&
        r.time.day == d0.day);
  }

  // ====== 后端地址 ======
  String get baseUrl => api.baseUrl;
  Future<void> updateBaseUrl(String url) async {
    await api.updateBaseUrl(url);
  }
}
