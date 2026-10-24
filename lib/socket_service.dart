import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

/// 全局单例：维护 Socket.IO 连接与内存状态，并通过流通知 UI 刷新
class AppState extends ChangeNotifier {
  static final AppState instance = AppState._internal();
  AppState._internal();

  // —— 连接信息 ——
  String serverUrl = DEFAULT_SERVER;
  String nickname = '';
  bool darkMode = false;
  bool loggedIn = false;
  bool connected = false;

  // —— 数据 ——
  String meName = '';
  String meWxid = '';
  List<Map<String, dynamic>> contacts = []; // 好友 [{name,wxid}]
  Map<String, dynamic> chats = {}; // cid -> {pinned:bool, messages:List<Map>}
  List<Map<String, dynamic>> moments = [];
  List<Map<String, dynamic>> users = []; // 目录 [{name,wxid,online}]
  List<String> online = [];

  final Map<String, int> unread = {};
  final Map<String, List<String>> typing = {};

  // —— 流 ——
  final StreamController<void> onChange = StreamController<void>.broadcast();
  final StreamController<String> toast = StreamController<String>.broadcast();

  IO.Socket? _socket;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    serverUrl = prefs.getString('wx_server') ?? DEFAULT_SERVER;
    nickname = prefs.getString('wx_name') ?? '';
    darkMode = prefs.getBool('wx_dark') ?? false;
    if (nickname.isNotEmpty) {
      meName = nickname;
      loggedIn = true;
      connect();
    }
    notifyListeners();
  }

  Future<void> setServerUrl(String url) async {
    url = url.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://' + url;
    }
    serverUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wx_server', url);
    _socket?.disconnect();
    _socket = null;
    if (loggedIn) connect();
    notifyListeners();
  }

  Future<void> setDarkMode(bool v) async {
    darkMode = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wx_dark', v);
    notifyListeners();
  }

  void connect() {
    // 每次创建新连接都要重新绑定监听：切服务器 / 重新登录都会 new 一个 socket，
    // 不复用旧的监听，否则新 socket 收不到任何事件。
    _socket?.disconnect();
    _socket = IO.io(serverUrl,
        IO.Options(autoConnect: true, transports: ['websocket'], timeout: 8000));
    _bind();
    _socket!.connect();
  }

  void _bind() {
    final s = _socket!;
    s.onConnect((_) {
      connected = true;
      if (meName.isNotEmpty) s.emit('login', {'name': meName});
      onChange.add(null);
    });
    s.onDisconnect((_) {
      connected = false;
      onChange.add(null);
    });
    s.on('ready', (data) {
      loggedIn = true;
      final st = data['state'] as Map<String, dynamic>? ?? {};
      final me = data['me'] as Map<String, dynamic>? ?? {};
      meName = me['name'] ?? meName;
      meWxid = me['wxid'] ?? '';
      contacts = List<Map<String, dynamic>>.from(st['contacts'] ?? []);
      chats = Map<String, dynamic>.from(st['chats'] ?? {});
      moments = List<Map<String, dynamic>>.from(st['moments'] ?? []);
      users = List<Map<String, dynamic>>.from(st['users'] ?? []);
      online = List<String>.from(st['online'] ?? []);
      onChange.add(null);
    });
    s.on('message', (data) {
      final cid = data['chatId'] as String;
      final msg = data['message'] as Map<String, dynamic>;
      if (!chats.containsKey(cid)) {
        chats[cid] = {'pinned': false, 'messages': <Map<String, dynamic>>[]};
      }
      (chats[cid]['messages'] as List).add(msg);
      final t = msg['type'];
      if (!(cid == activeChat && isChatActive)) {
        if (t != 'system') unread[cid] = (unread[cid] ?? 0) + 1;
      }
      onChange.add(null);
    });
    s.on('message_update', (data) {
      final cid = data['chatId'] as String;
      final msg = data['message'] as Map<String, dynamic>;
      final list = chats[cid]?['messages'] as List?;
      if (list != null) {
        for (var i = 0; i < list.length; i++) {
          if (list[i]['id'] == msg['id']) list[i] = msg;
        }
      }
      onChange.add(null);
    });
    s.on('message_deleted', (data) {
      final cid = data['chatId'] as String;
      final mid = data['msgId'] as String;
      final list = chats[cid]?['messages'] as List?;
      if (list != null) list.removeWhere((m) => m['id'] == mid);
      onChange.add(null);
    });
    s.on('chat_pinned', (data) {
      final cid = data['chatId'] as String;
      if (chats[cid] != null) chats[cid]['pinned'] = data['pinned'];
      onChange.add(null);
    });
    s.on('chat_removed', (data) {
      final cid = data['chatId'] as String;
      chats.remove(cid);
      if (activeChat == cid) activeChat = null;
      onChange.add(null);
    });
    s.on('typing', (data) {
      final cid = data['chatId'] as String;
      final name = data['name'] as String;
      final on = data['on'] as bool;
      final list = typing.putIfAbsent(cid, () => <String>[]);
      if (on) {
        if (!list.contains(name)) list.add(name);
      } else {
        list.remove(name);
      }
      onChange.add(null);
    });
    s.on('users', (data) {
      online = List<String>.from(data['online'] ?? []);
      onChange.add(null);
    });
    s.on('moments', (data) {
      moments = List<Map<String, dynamic>>.from(data['moments'] ?? []);
      onChange.add(null);
    });
    s.on('contacts', (data) {
      contacts = List<Map<String, dynamic>>.from(data['contacts'] ?? []);
      onChange.add(null);
    });
    s.on('add_result', (data) {
      final ok = data['ok'] as bool;
      final msg = ok
          ? '已添加「${data['name']}」为好友'
          : (data['error'] ?? '添加失败');
      toast.add(msg);
      onChange.add(null);
    });
    s.on('friend_removed', (data) {
      final name = data['name'] as String;
      final cid = dmId(meName, name);
      chats.remove(cid);
      toast.add('已删除好友「$name」');
      onChange.add(null);
    });
  }

  // —— 对外方法 ——
  void login(String name) {
    name = name.trim();
    if (name.isEmpty) name = '我';
    meName = name;
    nickname = name;
    SharedPreferences.getInstance().then((p) => p.setString('wx_name', name));
    connect();
  }

  void logout() {
    loggedIn = false;
    meName = '';
    nickname = '';
    contacts = [];
    chats = {};
    moments = [];
    users = [];
    online = [];
    unread.clear();
    typing.clear();
    activeChat = null;
    SharedPreferences.getInstance().then((p) => p.remove('wx_name'));
    _socket?.disconnect();
    notifyListeners();
  }

  void send(String chatId, String type, Map<String, dynamic> extra) {
    final m = <String, dynamic>{'chatId': chatId, 'type': type, ...extra};
    _socket?.emit('send', m);
  }

  void openRedpacket(String chatId, String msgId) {
    _socket?.emit('open_redpacket', {'chatId': chatId, 'msgId': msgId});
  }

  void addFriend(String name) => _socket?.emit('add_friend', {'name': name});
  void removeFriend(String name) =>
      _socket?.emit('remove_friend', {'name': name});
  void publishMoment(String text, List<int> images) =>
      _socket?.emit('publish_moment', {'text': text, 'images': images});
  void likeMoment(String postId) =>
      _socket?.emit('like_moment', {'postId': postId});
  void commentMoment(String postId, String text) =>
      _socket?.emit('comment_moment', {'postId': postId, 'text': text});
  void recall(String chatId, String msgId) =>
      _socket?.emit('recall', {'chatId': chatId, 'msgId': msgId});
  void deleteMessage(String chatId, String msgId) =>
      _socket?.emit('delete_message', {'chatId': chatId, 'msgId': msgId});
  void pinChat(String chatId) => _socket?.emit('pin_chat', {'chatId': chatId});
  void deleteChat(String chatId) =>
      _socket?.emit('delete_chat', {'chatId': chatId});
  void setTyping(String chatId, bool on) =>
      _socket?.emit('typing', {'chatId': chatId, 'on': on});

  // —— 辅助 ——
  String activeChat = '';
  bool isChatActive = false;

  String dmId(String a, String b) {
    final l = [a, b]..sort();
    return 'dm:' + l.join('|');
  }

  Map<String, dynamic>? contactById(String cid) {
    if (cid == 'lobby') return {'id': 'lobby', 'name': '味信大厅', 'type': 'group'};
    if (cid.startsWith('self:')) {
      return {'id': cid, 'name': '文件传输助手', 'type': 'self'};
    }
    if (cid.startsWith('dm:')) {
      final other =
          cid.substring(3).split('|').firstWhere((n) => n != meName, orElse: () => meName);
      return {'id': cid, 'name': other, 'type': 'friend'};
    }
    return null;
  }

  bool chatVisible(String cid) {
    if (cid == 'lobby') return true;
    if (cid.startsWith('self:')) return cid == 'self:$meName';
    if (cid.startsWith('dm:')) return cid.substring(3).split('|').contains(meName);
    return false;
  }

  String previewOf(Map<String, dynamic> m) {
    switch (m['type']) {
      case 'image':
        return '[图片]';
      case 'redpacket':
        return '[红包]';
      case 'file':
        return '[文件] ${m['name'] ?? ''}';
      default:
        return m['text'] ?? '';
    }
  }

  bool isFriend(String name) =>
      contacts.any((f) => f['name'] == name);

  @override
  void notifyListeners() {
    onChange.add(null);
    super.notifyListeners();
  }
}

final AppState app = AppState.instance;
