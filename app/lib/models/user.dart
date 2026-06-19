/// 用户信息
class AppUser {
  final int id;
  final String account;
  final String nickname;
  final String? avatar;

  const AppUser({
    required this.id,
    required this.account,
    required this.nickname,
    this.avatar,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] as num?)?.toInt() ?? 0,
        account: json['account'] as String? ?? '',
        nickname: json['nickname'] as String? ?? '',
        avatar: json['avatar'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'account': account,
        'nickname': nickname,
        'avatar': avatar,
      };

  AppUser copyWith({String? nickname, String? avatar}) => AppUser(
        id: id,
        account: account,
        nickname: nickname ?? this.nickname,
        avatar: avatar ?? this.avatar,
      );
}
