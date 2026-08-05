import 'package:cctv_app/core/deeplink/post_link_manager.dart';
import 'package:cctv_app/core/firebase/firebase_options.dart';
import 'package:cctv_app/core/session/app_session_manager.dart';
import 'package:cctv_app/core/network/api_config.dart';
import 'package:cctv_app/feature/session/session_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:cctv_app/core/ads/admob_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (ApiConfig.USE_FIREBASE) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (kDebugMode) {
        // try {
        //   FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
        //   await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
        //   FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
        // } catch (e) {
        //   debugPrint('Emulator setup error: $e');
        // }
      }
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  }
  PostLinkManager.instance.initialize().catchError((e) {
    debugPrint('PostLinkManager init error: $e');
  });
  AdMobService.instance.initialize().catchError((e) {
    debugPrint('AdMobService init error: $e');
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          navigatorKey: AppSessionManager.instance.navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'CCTV Mobile App',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          home: const SessionGate(),
        );
      },
    );
  }
}
