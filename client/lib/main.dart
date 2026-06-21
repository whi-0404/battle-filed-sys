import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/radar_provider.dart';
import 'theme/app_theme.dart';
import 'features/map/map_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.bgDeep,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const BattlefieldApp());
}

class BattlefieldApp extends StatelessWidget {
  const BattlefieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RadarProvider()),
      ],
      child: MaterialApp(
        title: 'Battlefield Radar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark.copyWith(
          textTheme: GoogleFonts.interTextTheme(AppTheme.dark.textTheme).apply(
            bodyColor: AppTheme.textPrimary,
            displayColor: AppTheme.textPrimary,
          ),
        ),
        home: const MapPage(),
      ),
    );
  }
}
