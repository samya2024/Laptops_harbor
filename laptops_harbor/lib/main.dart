import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'style/theme.dart';
import 'package:laptops_harbor/routes/route_guard.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'pages/splash_pages.dart';  // <-- SplashPage ka import




Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Enable offline persistence for Realtime Database on non-web platforms
  if (!kIsWeb) {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaptopsHarbor App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: cyan),
        useMaterial3: true,
        textTheme: GoogleFonts.emilysCandyTextTheme(),
      ), 
      
       home: const SplashPage(),

      onGenerateRoute: guardedRoute, // one line call
      debugShowCheckedModeBanner: false,
      builder:
          (context, child) => ScrollConfiguration(
            behavior: NoScrollbarBehavior(),
            child: child!,
          ),
    );
  }
}
