import 'package:flutter/material.dart';

import 'ui/start_page.dart';
import 'ui/theme.dart';

class PixelCanvasApp extends StatelessWidget {
  const PixelCanvasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Canvas',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const StartPage(),
    );
  }
}
