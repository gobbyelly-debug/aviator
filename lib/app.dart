import 'package:flutter/material.dart';

import 'pages/prediction_page.dart';
import 'services/access_api_service.dart';
import 'theme/app_theme.dart';

class AviatorMockupApp extends StatelessWidget {
  const AviatorMockupApp({super.key, this.accessKeyValidator});

  final AccessKeyValidator? accessKeyValidator;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aviator Prediction',
      theme: buildAppTheme(),
      home: PredictionPage(accessKeyValidator: accessKeyValidator),
    );
  }
}
