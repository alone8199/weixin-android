import 'package:flutter/material.dart';
import '../socket_service.dart';
import '../constants.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameCtl = TextEditingController(text: app.nickname);
    final serverCtl = TextEditingController(text: app.serverUrl);
    final nameFocus = FocusNode();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2FD075), Color(GREEN_SEED)],
                        ),
                      ),
                      child: const Center(
                        child: Text('味',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(APP_NAME,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text('Material Design 3 · 真实后端',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameCtl,
                      focusNode: nameFocus,
                      decoration: const InputDecoration(
                        labelText: '昵称',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: serverCtl,
                      decoration: const InputDecoration(
                        labelText: '服务器地址',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.dns_outlined),
                        helperText: '默认已填局域网地址，可修改',
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          final url = serverCtl.text.trim();
                          if (url.isNotEmpty) app.setServerUrl(url);
                          app.login(nameCtl.text);
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('进入味信'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      app.connected ? '已连接到服务器' : '正在连接服务器…',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
