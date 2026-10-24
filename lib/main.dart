import 'package:flutter/material.dart';
import 'constants.dart';
import 'socket_service.dart';
import 'screens/login.dart';
import 'screens/home.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldKey =
    GlobalKey<ScaffoldMessengerState>();

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  void initState() {
    super.initState();
    app.init();
    app.toast.stream.listen((msg) {
      rootScaffoldKey.currentState?.showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: app.onChange,
      initialData: null,
      builder: (context, _) {
        return MaterialApp(
          title: '味信',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: rootScaffoldKey,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(GREEN_SEED),
              brightness: app.darkMode ? Brightness.dark : Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(GREEN_SEED),
              brightness: Brightness.dark,
            ),
          ),
          themeMode: app.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: app.loggedIn ? const Home() : const LoginScreen(),
        );
      },
    );
  }
}

void main() => runApp(const AppRoot());
