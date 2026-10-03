import 'package:flutter/material.dart';

import 'model/tv_model.dart';
import 'ui/console.dart';
import 'ui/copy.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TvConsoleApp());
}

class TvConsoleApp extends StatefulWidget {
  const TvConsoleApp({super.key});
  @override
  State<TvConsoleApp> createState() => _TvConsoleAppState();
}

class _TvConsoleAppState extends State<TvConsoleApp> {
  final model = TvModel();
  ThemeMode theme = ThemeMode.system;
  @override
  void initState() {
    super.initState();
    model.guard(model.initialize);
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: Copy.text('appTitle'),
    debugShowCheckedModeBanner: false,
    themeMode: theme,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff006c67)),
      visualDensity: VisualDensity.standard,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    darkTheme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff63d9cf),
        brightness: Brightness.dark,
      ),
      visualDensity: VisualDensity.standard,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    home: Console(
      model: model,
      theme: theme,
      onTheme: (value) => setState(() => theme = value),
    ),
  );
}
