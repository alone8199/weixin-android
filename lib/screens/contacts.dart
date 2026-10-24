import 'package:flutter/material.dart';
import '../socket_service.dart';
import '../utils.dart';
import 'chat_detail.dart';

class Contacts extends StatelessWidget {
  const Contacts({super.key});

  @override
  Widget build(BuildContext context) {
    final addCtl = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('通讯录')),
      body: StreamBuilder<void>(
        stream: app.onChange,
        initialData: null,
        builder: (context, _) {
          final friends = app.contacts;
          final others = app.users
              .where((u) =>
                  u['name'] != app.meName && !app.isFriend(u['name']))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: addCtl,
                        decoration: const InputDecoration(
                          labelText: '输入昵称添加好友',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_add_alt_1_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final n = addCtl.text.trim();
                        if (n.isNotEmpty) app.addFriend(n);
                        addCtl.clear();
                      },
                      child: const Text('添加'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text('我的好友',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    if (friends.isEmpty)
                      const ListTile(
                          title: Text('还没有好友，在下方添加',
                              style: TextStyle(color: Colors.grey))),
                    ...friends.map((f) => ListTile(
                          leading: avatarWidget(f['name']),
                          title: Text(f['name']),
                          subtitle: Text(
                              app.online.contains(f['name']) ? '在线' : '离线',
                              style: const TextStyle(fontSize: 12)),
                          trailing: TextButton(
                            child: const Text('删除',
                                style: TextStyle(color: Colors.red)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('删除好友'),
                                  content: Text('确定删除好友「${f['name']}」吗？'),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('取消')),
                                    FilledButton(
                                      onPressed: () {
                                        app.removeFriend(f['name']);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('删除'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ChatDetail(cid: app.dmId(app.meName, f['name'])))))),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: Text('全部用户',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    ...others.map((u) => ListTile(
                          leading: avatarWidget(u['name']),
                          title: Text(u['name']),
                          subtitle: Text(
                              (u['online'] ?? false) ? '在线' : '离线',
                              style: const TextStyle(fontSize: 12)),
                          trailing: TextButton(
                            child: const Text('添加'),
                            onPressed: () => app.addFriend(u['name']),
                          ))),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
