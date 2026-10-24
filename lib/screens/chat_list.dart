import 'package:flutter/material.dart';
import '../socket_service.dart';
import '../utils.dart';
import 'chat_detail.dart';

class ChatList extends StatelessWidget {
  const ChatList({super.key});

  Map<String, dynamic>? _lastMsg(Map<String, dynamic>? ch) {
    if (ch == null) return null;
    final msgs = ch['messages'] as List? ?? [];
    for (var i = msgs.length - 1; i >= 0; i--) {
      if (msgs[i]['type'] != 'system') return msgs[i];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('味信')),
      body: StreamBuilder<void>(
        stream: app.onChange,
        initialData: null,
        builder: (context, _) {
          final entries = <Map<String, dynamic>>[];
          entries.add({'cid': 'lobby', 'name': '味信大厅', 'type': 'group'});
          entries.add(
              {'cid': 'self:${app.meName}', 'name': '文件传输助手', 'type': 'self'});
          final seen = <String>{};
          for (final f in app.contacts) {
            final cid = app.dmId(app.meName, f['name']);
            entries.add({'cid': cid, 'name': f['name'], 'type': 'friend'});
            seen.add(cid);
          }
          app.chats.forEach((cid, ch) {
            if (app.chatVisible(cid) &&
                cid.startsWith('dm:') &&
                !seen.contains(cid)) {
              final meta = app.contactById(cid);
              entries
                  .add({'cid': cid, 'name': meta?['name'] ?? cid, 'type': 'friend'});
            }
          });

          // 排序：置顶优先，其次按最后消息时间
          entries.sort((a, b) {
            final pa = (app.chats[a['cid']]?['pinned'] ?? false);
            final pb = (app.chats[b['cid']]?['pinned'] ?? false);
            if (pa != pb) return pa ? -1 : 1;
            final la = _lastMsg(app.chats[a['cid']])?['time'] ?? 0;
            final lb = _lastMsg(app.chats[b['cid']])?['time'] ?? 0;
            return lb.compareTo(la);
          });

          if (entries.isEmpty) {
            return const Center(child: Text('还没有会话'));
          }

          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) {
              final e = entries[i];
              final cid = e['cid'];
              final ch = app.chats[cid];
              final last = _lastMsg(ch);
              final pre = last == null
                  ? (e['type'] == 'group' ? '公开聊天，认识更多人' : '')
                  : (last['from'] == app.meName && last['type'] != 'system'
                      ? '我: ${app.previewOf(last)}'
                      : app.previewOf(last));
              final unread = app.unread[cid] ?? 0;

              return ListTile(
                leading: gradientAvatar(e['name']),
                title: Text(e['name'],
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(
                  pre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.outline),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(fmtTime(last?['time'] ?? 0),
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline)),
                    const SizedBox(height: 4),
                    if (unread > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red, borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$unread',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11)),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChatDetail(cid: cid)));
                },
                onLongPress: () => _showMenu(context, cid),
              );
            },
          );
        },
      ),
    );
  }

  void _showMenu(BuildContext context, String cid) {
    final pinned = app.chats[cid]?['pinned'] ?? false;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: Text(pinned ? '取消置顶' : '置顶聊天'),
              onTap: () {
                app.pinChat(cid);
                Navigator.pop(context);
              },
            ),
            if (!cid.startsWith('self:'))
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('删除该聊天',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  app.deleteChat(cid);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}
