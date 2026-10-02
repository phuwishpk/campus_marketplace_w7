import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../repositories/favorites_repository.dart';

class FavoritesPage extends StatefulWidget {
  final FavoritesRepository repository;
  const FavoritesPage({super.key, required this.repository});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<FavoriteItem>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    _favoritesFuture = widget.repository.getAllFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายการโปรด ❤️')),
      body: FutureBuilder<List<FavoriteItem>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          final favorites = snapshot.data ?? [];
          if (favorites.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'ยังไม่มีรายการโปรด\nลองกดหัวใจที่หน้าหลักดูสิ',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final item = favorites[index];
              return ListTile(
                leading: Image.network(
                  item.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                ),
                title: Text(item.title),
                subtitle: Text('${item.price} บาท'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    await widget.repository.removeFavorite(item.itemId);
                    setState(() => _loadFavorites()); // โหลดรายการใหม่หลังลบ
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
