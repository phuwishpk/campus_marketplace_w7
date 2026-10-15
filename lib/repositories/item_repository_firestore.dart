import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryFirestore implements ItemRepository {
  final FirebaseFirestore _firestore;

  ItemRepositoryFirestore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _itemsCollection =>
      _firestore.collection('items');

  @override
  Future<List<Item>> getItems() async {
    try {
      final snapshot = await _itemsCollection.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        var imageUrl = data['imageUrl'] as String? ?? '';
        final title = (data['title'] as String? ?? '').toLowerCase();

        // ตรวจสอบและอัปเดต URL รูปภาพให้ตรงกับสินค้าจริง
        if (imageUrl.contains('1521572267360') || imageUrl.isEmpty) {
          if (title.contains('short') || title.contains('กางเกง')) {
            imageUrl = 'https://upload.wikimedia.org/wikipedia/commons/5/52/Running-shorts-black.png';
          } else if (title.contains('sunglass') || title.contains('glasses') || title.contains('แว่น')) {
            imageUrl = 'https://upload.wikimedia.org/wikipedia/commons/0/0f/Gold_rim_sunglasses_%281474039438%29.jpg';
          } else {
            imageUrl = 'https://upload.wikimedia.org/wikipedia/commons/f/f5/Red-t-shirt-.jpg';
          }
          // บันทึกกลับไปแก้ไขใน Firestore อัตโนมัติ
          doc.reference.update({'imageUrl': imageUrl}).catchError((_) {});
        }

        return Item(
          id: int.tryParse(doc.id) ?? data['id'] ?? doc.hashCode,
          title: data['title'] ?? '',
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          description: data['description'] ?? '',
          category: data['category'] ?? '',
          imageUrl: imageUrl,
          sellerId: data['sellerId'],
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> postItem(Item item) async {
    await _itemsCollection.add(item.toFirestore());
  }

  Stream<List<Item>> watchMyListings(String sellerId) {
    return _itemsCollection
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList());
  }
}
