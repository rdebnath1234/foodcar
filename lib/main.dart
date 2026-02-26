import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'package:foodcar/screens/food_order/login.dart';
import 'package:foodcar/phonecheck.dart';
import 'package:foodcar/screens/myhomepage.dart';
import 'package:foodcar/about.dart';
import 'package:foodcar/contact.dart';
import 'package:foodcar/utils/cart_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firestore settings for mobile data stability
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false, // Avoid offline cache issues
    host: 'firestore.googleapis.com',
    sslEnabled: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartManager()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const NetworkWrapper(), // Wrap login with network check
        routes: {
          '/otp': (context) => const PhoneCheck(),
          '/home': (context) => const MyHomePage(title: 'FoodCar'),
          '/about': (context) => const About(title: 'About Page'),
          '/contact': (context) => const Contact(title: 'Contact Page'),
        },
      ),
    );
  }
}

// Widget to check internet before showing Login
class NetworkWrapper extends StatefulWidget {
  const NetworkWrapper({super.key});

  @override
  State<NetworkWrapper> createState() => _NetworkWrapperState();
}

class _NetworkWrapperState extends State<NetworkWrapper> {
  bool _hasInternet = true;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkInternet();
  }

  Future<void> _checkInternet() async {
    bool connected = await checkInternet();
    setState(() {
      _hasInternet = connected;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasInternet) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.signal_wifi_off, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'No Internet Connection.\nPlease check your mobile data or Wi-Fi.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkInternet,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return const Login(); // Show login if internet is available
  }
}

Future<bool> checkInternet() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException catch (_) {
    return false;
  }
}
