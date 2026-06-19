import 'package:get/get.dart';

import '../../api/api_exception.dart';
import '../../models/settings.dart';
import '../app_state.dart';

/// 排行榜页面状态 —— type/week|all、loading、错误、条目。
///
/// 抽 controller 的好处:
///   - 切 tab 不会重建整个 screen(只 setState 太重,Obx 更细粒度)
///   - 排行榜数据可以扩展(加缓存、加分页、加搜索)都在 controller 里,
///     不污染 widget
class LeaderboardController extends GetxController {
  final AppState _state = Get.find<AppState>();

  final RxString type = 'week'.obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();
  final RxList<LeaderboardEntry> entries = <LeaderboardEntry>[].obs;

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  @override
  Future<void> refresh() async {
    loading.value = true;
    error.value = null;
    try {
      final list = await _state.api.getLeaderboard(type: type.value);
      entries.assignAll(list);
    } on ApiException catch (e) {
      error.value = e.message;
    } catch (_) {
      error.value = '加载失败';
    } finally {
      loading.value = false;
    }
  }

  void switchType(String t) {
    if (type.value == t) return;
    type.value = t;
    refresh();
  }
}