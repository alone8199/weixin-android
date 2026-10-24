import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../socket_service.dart';
import '../utils.dart';

class ChatDetail extends StatefulWidget {
  final String cid;
  const ChatDetail({super.key, required this.cid});

  @override
  State<ChatDetail> createState() => _ChatDetailState();
}

class _ChatDetailState extends State<ChatDetail> {
  final TextEditingController _ctl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _typingTimer;
  final List<String> _quick = ['😊', '👍', '😂', '🎉', '❤️', '🤝', '🌹', '😎'];

  @override
  void initState() {
    super.initState();
    app.activeChat = widget.cid;
    app.isChatActive = true;
    app.unread[widget.cid] = 0;
  }

  @override
  void dispose() {
    if (app.activeChat == widget.cid) app.isChatActive = false;
    _typingTimer?.cancel();
    super.dispose();
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _doSend() {
    final t = _ctl.text.trim();
    if (t.isEmpty) return;
    app.send(widget.cid, 'text', {'text': t});
    _ctl.clear();
    app.setTyping(widget.cid, false);
  }

  void _onTextChanged(String v) {
    app.setTyping(widget.cid, true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      app.setTyping(widget.cid, false);
    });
  }

  void _sendImage() async {
    final url = await makeGradientImageDataUrl();
    app.send(widget.cid, 'image', {'src': url});
  }

  void _sendFile() {
    final names = ['周报.docx', '设计稿.png', '需求说明.pdf', '代码.zip'];
    final n = names[Random().nextInt(names.length)];
    app.send(widget.cid, 'file',
        {'name': n, 'size': '${(Random().nextInt(900) + 100)} KB'});
  }

  void _sendRedpacket() {
    final amtCtl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('发红包'),
        content: TextField(
          controller: amtCtl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '金额（元）', border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final a = double.tryParse(amtCtl.text);
              if (a == null || a <= 0 || a > 200) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('金额需在 0.01 - 200 之间')));
                return;
              }
              app.send(widget.cid, 'redpacket',
                  {'amount': a, 'blessing': '恭喜发财，大吉大利'});
              Navigator.pop(context);
            },
            child: const Text('塞钱进红包'),
          ),
        ],
      ),
    );
  }

  void _openRedpacket(Map<String, dynamic> m) {
    if (m['opened'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('已领取 ${((m['amount'] ?? 0)).toStringAsFixed(2)} 元')));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('领取红包'),
        content: Text(m['blessing'] ?? '恭喜发财，大吉大利'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          FilledButton(
            onPressed: () {
              app.openRedpacket(widget.cid, m['id']);
              Navigator.pop(context);
            },
            child: const Text('开'),
          ),
        ],
      ),
    );
  }

  void _msgLongPress(Map<String, dynamic> m) {
    final fromMe = m['from'] == app.meName;
    final canRecall = fromMe &&
        (DateTime.now().millisecondsSinceEpoch - (m['time'] ?? 0) < 120000);
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canRecall)
              ListTile(
                leading: const Icon(Icons.undo_outlined),
                title: const Text('撤回'),
                onTap: () {
                  app.recall(widget.cid, m['id']);
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                app.deleteMessage(widget.cid, m['id']);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(Map<String, dynamic> m) {
    final type = m['type'];
    if (type == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(m['text'] ?? '',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline)),
        ),
      );
    }
    final fromMe = m['from'] == app.meName;
    final meta = app.contactById(widget.cid);
    final isGroup = meta?['type'] == 'group';
    final senderName = m['from'] == app.meName
        ? app.meName
        : (meta?['name'] ?? m['from']);

    Widget body;
    if (type == 'image') {
      final src = m['src'] ?? '';
      ImageProvider? img;
      if (src.startsWith('data:image')) {
        img = MemoryImage(base64Decode(src.substring(src.indexOf(',') + 1)));
      }
      body = img == null
          ? const Text('[图片]')
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image(image: img, width: 160),
            );
    } else if (type == 'redpacket') {
      body = InkWell(
        onTap: () => _openRedpacket(m),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
                colors: [Color(0xFFF2A53C), Color(0xFFE6502E)]),
          ),
          child: Row(
            children: [
              const Text('🧧', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m['blessing'] ?? '恭喜发财，大吉大利',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500)),
                    Text(
                        m['opened'] == true
                            ? '已领取 ${(m['amount'] ?? 0).toStringAsFixed(2)} 元'
                            : '领取红包',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (type == 'file') {
      body = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file, size: 30),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m['name'] ?? '文件',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(m['size'] ?? '',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      );
    } else {
      body = Text(m['text'] ?? '',
          style: const TextStyle(fontSize: 15),
          softWrap: true);
    }

    return GestureDetector(
      onLongPress: () => _msgLongPress(m),
      child: Row(
        mainAxisAlignment:
            fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!fromMe) gradientAvatar(senderName, size: 36),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (isGroup && !fromMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 2),
                    child: Text(senderName,
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: fromMe
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: body,
                ),
              ],
            ),
          ),
          if (fromMe) ...[
            const SizedBox(width: 8),
            gradientAvatar(app.meName, size: 36),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = app.contactById(widget.cid);
    final title = meta?['type'] == 'group'
        ? '${meta!['name']}（${app.online.length} 人在线）'
        : (meta?['name'] ?? '');
    final typingList = app.typing[widget.cid] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: meta?['type'] == 'group'
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Center(
                    child: Text('${app.online.length}',
                        style: const TextStyle(fontSize: 13)),
                  ),
                )
              ]
            : null,
      ),
      body: StreamBuilder<void>(
        stream: app.onChange,
        initialData: null,
        builder: (context, _) {
          final ch = app.chats[widget.cid];
          final msgs = (ch?['messages'] as List? ?? []).cast<Map<String, dynamic>>();
          _scrollBottom();
          final typingNames =
              typingList.where((n) => n != app.meName).toList();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _bubble(msgs[i]),
                  ),
                ),
              ),
              if (typingNames.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 16, bottom: 6),
                  child: Text(
                    '${typingNames.map((n) => n).join('、')} 正在输入…',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline),
                  ),
                ),
              _inputBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.mood_outlined),
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (_) => GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 5,
                  childAspectRatio: 1.4,
                  children: _quick
                      .map((e) => InkWell(
                            onTap: () {
                              _ctl.text += e;
                              Navigator.pop(context);
                            },
                            child: Center(child: Text(e, style: const TextStyle(fontSize: 24))),
                          ))
                      .toList(),
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.image_outlined), onPressed: _sendImage),
            IconButton(icon: const Icon(Icons.attach_file_outlined), onPressed: _sendFile),
            IconButton(icon: const Icon(Icons.redeem_outlined), onPressed: _sendRedpacket),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _ctl,
                onChanged: _onTextChanged,
                onSubmitted: (_) => _doSend(),
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: '发送消息',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _doSend,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
