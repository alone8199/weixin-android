import 'package:flutter/material.dart';
import '../socket_service.dart';
import 'chat_list.dart';
import 'contacts.dart';
import 'moments.dart';
import 'profile.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final totalUnread =
        app.unread.values.fold(0, (a, b) => a + b);

    return StreamBuilder<void>(
      stream: app.onChange,
      initialData: null,
      builder: (context, _) {
        final tabs = [
          const ChatList(),
          const Contacts(),
          const Moments(),
          const Profile(),
        ];
        return Scaffold(
          body: IndexedStack(index: _idx, children: tabs),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _idx,
            onDestinationSelected: (i) => setState(() => _idx = i),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.chat_bubble_outline),
                selectedIcon: const Icon(Icons.chat_bubble),
                label: '聊天',
                badge: totalUnread > 0
                    ? Badge(label: Text('$totalUnread'))
                    : null,
              ),
              const NavigationDestination(
                icon: Icon(Icons.contacts_outlined),
                selectedIcon: Icon(Icons.contacts),
                label: '通讯录',
              ),
              const NavigationDestination(
                icon: Icon(Icons.photo_outlined),
                selectedIcon: Icon(Icons.photo),
                label: '朋友圈',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: '我',
              ),
            ],
          ),
        );
      },
    );
  }
}
