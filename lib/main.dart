import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/cart_model.dart';
import 'screens/login_page.dart';
import 'screens/main_scaffold.dart';
import 'repositories/item_repository_api.dart';
import 'repositories/favorites_repository_drift.dart';
import 'repositories/listing_draft_repository_drift.dart';
import 'database/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final db = AppDatabase(); // สร้าง AppDatabase ครั้งเดียวเท่านั้น
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartModel(),
      child: MyApp(db: db),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AppDatabase db;
  const MyApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Marketplace',
      debugShowCheckedModeBanner: false,
      // เชื่อม LoginPage ชั่วคราวเพื่อทดสอบ Checkpoint 2.1 & 3.1
      home: const LoginPage(),
      // home: MainScaffold(
      //   itemRepository: ItemRepositoryApi(),
      //   favoritesRepository: FavoritesRepositoryDrift(db),
      //   draftRepository: ListingDraftRepositoryDrift(db),
      // ),
    );
  }
}
