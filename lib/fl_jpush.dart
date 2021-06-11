import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

typedef JPushEventHandler = void Function(JPushMessage? event);
typedef JPushNotificationAuthorization = void Function(bool? state);

MethodChannel _channel = const MethodChannel('fl_jpush');

Future<bool> setupJPush(
    {required String iosKey,
    bool production = false,
    String? channel = '',
    bool debug = false}) async {
  final bool? state = await _channel.invokeMethod<bool?>(
      'setup', <String, dynamic>{
    'appKey': iosKey,
    'channel': channel,
    'production': production,
    'debug': debug
  });
  return state ?? false;
}

/// 初始化 JPush 必须先初始化才能执行其他操作(比如接收事件传递)
void addJPushEventHandler({
  /// 接收普通消息
  JPushEventHandler? onReceiveNotification,

  /// 点击通知栏消息回调
  JPushEventHandler? onOpenNotification,
  JPushEventHandler? onReceiveMessage,

  /// ios 获取消息认证 回调
  JPushNotificationAuthorization? onReceiveNotificationAuthorization,
}) {
  _channel.setMethodCallHandler((MethodCall call) async {
    Map<dynamic, dynamic>? map;
    JPushMessage? message;
    try {
      if (call.arguments is Map) {
        map = call.arguments as Map<dynamic, dynamic>;
        message = JPushMessage.fromMap(map);
      }
    } catch (e) {
      print(e);
    }
    switch (call.method) {
      case 'onReceiveNotification':
        if (onReceiveNotification != null) onReceiveNotification(message);
        break;
      case 'onOpenNotification':
        if (onOpenNotification != null) onOpenNotification(message);
        break;
      case 'onReceiveMessage':
        if (onReceiveMessage != null) onReceiveMessage(message);
        break;
      case 'onReceiveNotificationAuthorization':
        if (onReceiveNotificationAuthorization != null)
          onReceiveNotificationAuthorization(call.arguments as bool?);
        break;
      default:
        throw UnsupportedError('Unrecognized Event');
    }
  });
}

/// iOS Only
/// 申请推送权限，注意这个方法只会向用户弹出一次推送权限请求（如果用户不同意，之后只能用户到设置页面里面勾选相应权限），需要开发者选择合适的时机调用。
Future<bool> applyJPushAuthority(
    [NotificationSettingsIOS iosSettings =
        const NotificationSettingsIOS()]) async {
  if (!Platform.isIOS) return false;
  final bool? state = await _channel.invokeMethod<bool?>(
      'applyPushAuthority', iosSettings.toMap);
  return state ?? false;
}

/// 设置 Tag （会覆盖之前设置的 tags）
Future<TagResultModel?> setJPushTags(List<String> tags) async {
  final Map<dynamic, dynamic>? map =
      await _channel.invokeMethod('setTags', tags);
  if (map != null) return TagResultModel.fromMap(map);
  return null;
}

/// 验证tag是否绑定
Future<TagResultModel?> validJPushTag(String tag) async {
  final Map<dynamic, dynamic>? map =
      await _channel.invokeMethod('validTag', tag);
  if (map != null) return TagResultModel.fromMap(map, tag);
  return null;
}

/// 清空所有 tags。
Future<TagResultModel?> cleanJPushTags() async {
  final Map<dynamic, dynamic>? map = await _channel.invokeMethod('cleanTags');
  if (map != null) return TagResultModel.fromMap(map);
  return null;
}

/// 在原有 tags 的基础上添加 tags
Future<TagResultModel?> addJPushTags(List<String> tags) async {
  final Map<dynamic, dynamic>? map =
      await _channel.invokeMethod('addTags', tags);
  if (map != null) return TagResultModel.fromMap(map);
  return null;
}

/// 删除指定的 tags
Future<TagResultModel?> deleteJPushTags(List<String> tags) async {
  final Map<dynamic, dynamic>? map =
      await _channel.invokeMethod('deleteTags', tags);
  if (map != null) return TagResultModel.fromMap(map);
  return null;
}

/// 获取所有当前绑定的 tags
Future<TagResultModel?> getAllJPushTags() async {
  final Map<dynamic, dynamic>? map = await _channel.invokeMethod('getAllTags');
  if (map != null) return TagResultModel.fromMap(map);
  return null;
}

/// 获取 alias.
Future<AliasResultModel?> getJPushAlias() async {
  final Map<dynamic, dynamic>? map = await _channel.invokeMethod('getAlias');
  if (map != null) return AliasResultModel.fromMap(map);
  return null;
}

/// 重置 alias.
Future<AliasResultModel?> setJPushAlias(String alias) async {
  final Map<dynamic, dynamic>? map =
      await _channel.invokeMethod('setAlias', alias);
  if (map != null) return AliasResultModel.fromMap(map);
  return null;
}

/// 删除原有 alias
Future<AliasResultModel?> deleteJPushAlias() async {
  final Map<dynamic, dynamic>? map = await _channel.invokeMethod('deleteAlias');
  if (map != null) return AliasResultModel.fromMap(map);
  return null;
}

/// 设置应用 Badge（小红点）
/// 清空应用Badge（小红点）设置 badge = 0
/// 注意：如果是 Android 手机，目前仅支持华为手机
Future<bool> setJPushBadge(int badge) async {
  final bool? state = await _channel.invokeMethod<bool?>('setBadge', badge);
  return state ?? false;
}

/// 停止接收推送，调用该方法后应用将不再受到推送，如果想要重新收到推送可以调用 resumePush。
Future<bool> stopJPush() async {
  final bool? state = await _channel.invokeMethod<bool?>('stopPush');
  return state ?? false;
}

/// 恢复推送功能。
Future<bool> resumeJPush() async {
  final bool? state = await _channel.invokeMethod<bool?>('resumePush');
  return state ?? false;
}

/// 清空通知栏上的所有通知。
Future<bool> clearAllJPushNotifications() async {
  final bool? state =
      await _channel.invokeMethod<bool?>('clearAllNotifications');
  return state ?? false;
}

/// 清空通知栏上某个通知
Future<bool> clearJPushNotification(int notificationId) async {
  final bool? state =
      await _channel.invokeMethod<bool?>('clearNotification', notificationId);
  return state ?? false;
}

///
/// iOS Only
/// 点击推送启动应用的时候原生会将该 notification 缓存起来，该方法用于获取缓存 notification
/// 注意：notification 可能是 remoteNotification 和 localNotification，两种推送字段不一样。
/// 如果不是通过点击推送启动应用，比如点击应用 icon 直接启动应用，notification 会返回 @{}。
///
Future<Map<dynamic, dynamic>?> getJPushLaunchAppNotification() async {
  if (!Platform.isIOS) return null;
  return await _channel.invokeMethod('getLaunchAppNotification');
}

/// 获取 RegistrationId, JPush 可以通过制定 RegistrationId 来进行推送。
Future<String?> getJPushRegistrationID() =>
    _channel.invokeMethod('getRegistrationID');

/// 发送本地通知到调度器，指定时间出发该通知。
Future<LocalNotification?> sendJPushLocalNotification(
    LocalNotification notification) async {
  final bool? data = await _channel.invokeMethod<bool>(
      'sendLocalNotification', notification.toMap);
  if (data == null) return null;
  return notification;
}

///  检测通知授权状态是否打开
Future<bool?> isNotificationEnabled() =>
    _channel.invokeMethod<bool>('isNotificationEnabled');

///  Push Service 是否已经被停止
Future<bool?> isJPushStopped() async {
  if (!Platform.isAndroid) return true;
  return _channel.invokeMethod<bool>('isPushStopped');
}

/// 获取UDID
/// 仅支持android
Future<String?> getAndroidJPushUdID() async {
  if (!Platform.isAndroid) return null;
  return await _channel.invokeMethod<String>('getUdID');
}

///  跳转至系统设置中应用设置界面
Future<void> openSettingsForNotification() =>
    _channel.invokeMethod('openSettingsForNotification');

/// 统一android ios 回传数据解析
class JPushMessage {
  JPushMessage({
    this.original,
    this.sound,
    this.alert,
    this.extras,
    this.message,
    this.badge,
    this.title,
    this.mutableContent,
    this.notificationAuthorization,
  });

  JPushMessage.fromMap(Map<dynamic, dynamic> json) {
    original = json;
    if (json.containsKey('aps')) {
      final Map<dynamic, dynamic>? aps = json['aps'] as Map<dynamic, dynamic>?;
      if (aps != null) {
        alert = aps['alert'] as dynamic;
        badge = aps['badge'] as int?;
        sound = aps['sound'] as String?;
        mutableContent = aps['mutableContent'] as int?;
        notificationAuthorization = aps['notificationAuthorization'] as bool?;
      }
      msgID = json['_j_msgid'] == null ? null : json['_j_msgid'].toString();
      notificationID = json['_j_uid'] as int?;
      extras = json['arguments'];
    } else {
      title = json['title'] as String?;
      message = json['message'] as String?;
      alert = json['alert'] as dynamic;
      final Map<dynamic, dynamic>? _extras =
          json['extras'] as Map<dynamic, dynamic>?;
      if (_extras != null) {
        msgID = _extras['cn.jpush.android.MSG_ID'] as String?;
        notificationID = _extras['cn.jpush.android.NOTIFICATION_ID'] as int?;
        extras = _extras['cn.jpush.android.EXTRA'];
      }
    }
  }

  /// 原始数据 原生返回未解析的数据
  Map<dynamic, dynamic>? original;

  dynamic alert;
  dynamic extras;

  String? message;
  String? title;
  String? msgID;
  int? notificationID;

  /// only ios
  /// 监测通知授权状态返回结果
  bool? notificationAuthorization;
  String? sound;
  String? subtitle;
  int? badge;
  int? mutableContent;

  Map<String, dynamic> get toMap => <String, dynamic>{
        'original': original,
        'alert': alert,
        'extras': extras,
        'message': message,
        'title': title,
        'msgID': msgID,
        'notificationID': notificationID,
        'notificationAuthorization': notificationAuthorization,
        'subtitle': subtitle,
        'sound': sound,
        'badge': badge,
        'mutableContent': mutableContent,
      };
}

class TagResultModel {
  TagResultModel({
    required this.code,
    required this.tags,
    this.isBind,
  });

  TagResultModel.fromMap(Map<dynamic, dynamic> json, [String? tag]) {
    code = json['code'] as int;
    isBind = json['isBind'] as bool?;
    tags = json['tags'] == null
        ? tag == null
            ? <String>[]
            : <String>[tag]
        : (json['tags'] as List<dynamic>)
            .map((dynamic e) => e as String)
            .toList();
  }

  late List<String> tags;

  /// jPush状态🐴
  late int code;

  /// 校验tag 是否绑定
  bool? isBind;

  Map<String, dynamic> get toMap =>
      <String, dynamic>{'tags': tags, 'code': code, 'isBind': isBind};
}

class AliasResultModel {
  AliasResultModel({
    required this.code,
    this.alias,
  });

  AliasResultModel.fromMap(Map<dynamic, dynamic> json) {
    code = json['code'] as int;
    alias = json['alias'] as String?;
    if (alias != null && alias!.isEmpty) alias = null;
  }

  String? alias;

  /// jPush状态🐴
  late int code;

  Map<String, dynamic> get toMap =>
      <String, dynamic>{'alias': alias, 'code': code};
}

class NotificationSettingsIOS {
  const NotificationSettingsIOS({
    this.sound = true,
    this.alert = true,
    this.badge = true,
  });

  final bool sound;
  final bool alert;
  final bool badge;

  Map<String, dynamic> get toMap =>
      <String, bool>{'sound': sound, 'alert': alert, 'badge': badge};
}

///  {number} [buildId] - 通知样式：1 为基础样式，2 为自定义样式（需先调用 `setStyleCustom` 设置自定义样式）
///  {number} [id] - 通知 id, 可用于取消通知
///  {string} [title] - 通知标题
///  {string} [content] - 通知内容
///  {object} [extra] - extra 字段
///  {number} [fireTime] - 通知触发时间（毫秒）
///  iOS Only
///  {number} [badge] - 本地推送触发后应用角标值
///  iOS Only
///  {string} [soundName] - 指定推送的音频文件
///  iOS 10+ Only
///  {string} [subtitle] - 子标题
class LocalNotification {
  const LocalNotification(
      {required this.id,
      required this.title,
      required this.content,
      required this.fireTime,
      this.buildId,
      this.extra,
      this.badge = 0,
      this.soundName,
      this.subtitle});

  final int? buildId;
  final int id;
  final String title;
  final String content;
  final Map<String, String>? extra;
  final DateTime fireTime;
  final int badge;
  final String? soundName;
  final String? subtitle;

  Map<String, dynamic> get toMap => <String, dynamic>{
        'id': id,
        'title': title,
        'content': content,
        'fireTime': fireTime.millisecondsSinceEpoch,
        'buildId': buildId,
        'extra': extra,
        'badge': badge,
        'soundName': soundName,
        'subtitle': subtitle
      };
}
//
// /// ios 回传数据解析
// class _IOSModel {
//   _IOSModel({this.aps, this.extras, this.notificationAuthorization});
//
//   _IOSModel.fromJson(Map<dynamic, dynamic> json) {
//     aps = json['aps'] != null
//         ? _ApsModel.fromJson(json['aps'] as Map<dynamic, dynamic>)
//         : null;
//     extras = json['extras'] as Map<dynamic, dynamic>?;
//     print('-----ios-------');
//     print(json);
//     print(extras);
//     notificationAuthorization = json['notificationAuthorization'] as bool?;
//   }
//
//   bool? notificationAuthorization;
//   _ApsModel? aps;
//   Map<dynamic, dynamic>? extras;
// }
//
// class _ApsModel {
//   _ApsModel({this.mutableContent, this.alert, this.badge, this.sound});
//
//   _ApsModel.fromJson(Map<dynamic, dynamic> json) {
//     mutableContent = json['mutable-content'] as int?;
//     alert = json['alert'] as dynamic;
//     badge = json['badge'] as int?;
//     sound = json['sound'] as String?;
//   }
//
//   int? mutableContent;
//   dynamic alert;
//   int? badge;
//   String? sound;
// }
