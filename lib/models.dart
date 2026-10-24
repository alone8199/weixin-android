// 数据模型：与服务器 JSON 字段保持一致

class WxUser {
  final String name;
  final String wxid;
  final bool online;

  WxUser({required this.name, this.wxid = '', this.online = false});

  factory WxUser.fromJson(Map<String, dynamic> m) => WxUser(
        name: m['name'] ?? '',
        wxid: m['wxid'] ?? '',
        online: m['online'] ?? false,
      );
}

class ChatMessage {
  final String id;
  final String from;
  final String type;
  final int time;
  final String text;
  final String src;
  final String name;
  final String size;
  final double amount;
  final String blessing;
  final bool opened;
  final String openedBy;

  ChatMessage({
    required this.id,
    required this.from,
    required this.type,
    required this.time,
    this.text = '',
    this.src = '',
    this.name = '',
    this.size = '',
    this.amount = 0,
    this.blessing = '',
    this.opened = false,
    this.openedBy = '',
  });

  factory ChatMessage.fromJson(Map<String, dynamic> m) => ChatMessage(
        id: m['id'] ?? '',
        from: m['from'] ?? '',
        type: m['type'] ?? 'text',
        time: m['time'] ?? 0,
        text: m['text'] ?? '',
        src: m['src'] ?? '',
        name: m['name'] ?? '',
        size: m['size'] ?? '',
        amount: (m['amount'] is num) ? (m['amount'] as num).toDouble() : 0,
        blessing: m['blessing'] ?? '',
        opened: m['opened'] ?? false,
        openedBy: m['openedBy'] ?? '',
      );
}

class WxMoment {
  final String id;
  final String author;
  final String text;
  final List<int> images;
  final int time;
  final List<String> likes;
  final List<Map<String, dynamic>> comments;

  WxMoment({
    required this.id,
    required this.author,
    required this.text,
    required this.images,
    required this.time,
    required this.likes,
    required this.comments,
  });

  factory WxMoment.fromJson(Map<String, dynamic> m) {
    final imgs = <int>[];
    if (m['images'] is List) {
      for (final x in m['images']) {
        if (x is num) imgs.add(x.toInt());
      }
    }
    final likes = <String>[];
    if (m['likes'] is List) {
      for (final x in m['likes']) likes.add(x.toString());
    }
    final comments = <Map<String, dynamic>>[];
    if (m['comments'] is List) {
      for (final x in m['comments']) {
        if (x is Map) comments.add(Map<String, dynamic>.from(x));
      }
    }
    return WxMoment(
      id: m['id'] ?? '',
      author: m['author'] ?? '',
      text: m['text'] ?? '',
      images: imgs,
      time: m['time'] ?? 0,
      likes: likes,
      comments: comments,
    );
  }
}
