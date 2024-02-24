import 'package:app/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'camera.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

var kColourScheme =
    ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 4, 175, 238));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    name: 'sign app',
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    navigatorKey: navigatorKey,
    debugShowCheckedModeBanner: false,
    home: AnimatedSplashScreen(
      splash: Image.asset('./asset/images/logo.png'),
      splashTransition: SplashTransition.fadeTransition,
      backgroundColor: const Color.fromARGB(255, 250, 214, 238),
      splashIconSize: 400,
      //nextScreen: HomePage(),
      nextScreen: LoginPage(),
    ),
    routes: {
      //'/videoplayer': (context) => const VideoPlayerScreen(),
      '/camera': (context) =>
          CameraPage(onUploadProgress: (bool isProgress) {}),
      // '/video': (context) => const VideoPlayer(),
    },
  ));
}
