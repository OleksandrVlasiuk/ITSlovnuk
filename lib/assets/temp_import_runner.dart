import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';
import '../utils/deck_importer.dart' as DeckImporter;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ImportApp());
}

final navigatorKey = GlobalKey<NavigatorState>();

class ImportApp extends StatelessWidget {
  const ImportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Імпорт колоди'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Увійдіть у систему.')),
                );
                return;
              }

              await DeckImporter.importDeckFromJson(user.uid);

            },
            child: const Text("Імпортувати колоду з JSON"),
          ),
        ),
      ),
    );
  }
}
