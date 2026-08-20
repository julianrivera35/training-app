import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/app_provider.dart';
import 'providers/rest_timer.dart';
import 'services/notification_service.dart';
import 'screens/main_scaffold.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  await NotificationService.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const PivoteApp());
}

class PivoteApp extends StatelessWidget {
  const PivoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..init()),
        ChangeNotifierProvider(create: (_) => RestTimerController()),
      ],
      child: MaterialApp(
        title: 'Pivote Training',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        // Tocar fuera de un campo de texto oculta el teclado (útil con
        // teclados numéricos que no tienen botón "return").
        builder: (context, child) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        ),
        home: const MainScaffold(),
      ),
    );
  }
}
