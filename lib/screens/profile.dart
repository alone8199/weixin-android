import 'package:flutter/material.dart';
import '../socket_service.dart';
import '../utils.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我')),
      body: StreamBuilder<void>(
        stream: app.onChange,
        initialData: null,
        builder: (context, _) {
          final momentsCount =
              app.moments.where((m) => m['author'] == app.meName).length;
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    gradientAvatar(app.meName, size: 64),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.meName,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600)),
                        Text('味信号: ${app.meWxid.isNotEmpty ? app.meWxid : 'wxid_demo'}',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              _row('我的好友', '${app.contacts.length} 位', Icons.people_outline),
              _row('我的朋友圈', '$momentsCount 条动态',
                  Icons.photo_outlined),
              ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: const Text('服务器地址'),
                subtitle: Text(app.serverUrl),
                onTap: () => _editServer(context),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('深色模式'),
                value: app.darkMode,
                onChanged: (v) => app.setDarkMode(v),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FilledButton(
                  style:
                      FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => _logout(context),
                  child: const Text('退出登录'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(value, style: const TextStyle(color: Colors.grey)),
    );
  }

  void _editServer(BuildContext context) {
    final ctl = TextEditingController(text: app.serverUrl);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('服务器地址'),
        content: TextField(
          controller: ctl,
          decoration: const InputDecoration(
            hintText: 'http://192.168.1.5:5000',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final v = ctl.text.trim();
              if (v.isNotEmpty) app.setServerUrl(v);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定退出当前账号吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              app.logout();
              Navigator.pop(context);
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}
