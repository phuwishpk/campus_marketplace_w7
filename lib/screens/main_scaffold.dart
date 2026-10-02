import 'package:flutter/material.dart';
import 'home_page.dart';
import 'sell_item_page.dart';
import '../repositories/item_repository.dart';

class MainScaffold extends StatefulWidget {
  final ItemRepository repository;
  const MainScaffold({super.key, required this.repository});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // มี 2 Tab ในสัปดาห์นี้ (Home, ลงประกาศขาย)
    final pages = [
      HomePage(repository: widget.repository),
      const SellItemPage(),
    ];

    return Scaffold(
      // IndexedStack เก็บ State ของทุก Tab ไว้พร้อมกัน สลับ Tab แล้วข้อมูลที่กรอก/เลือกไว้ไม่หาย
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.add_a_photo), label: 'ลงประกาศขาย'),
        ],
      ),
    );
  }
}
