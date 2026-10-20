import 'package:flutter/material.dart';


import 'router.dart';
import 'theme.dart';


class DocumentReaderApp extends StatelessWidget {
  const DocumentReaderApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Identixia DocumentReader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
