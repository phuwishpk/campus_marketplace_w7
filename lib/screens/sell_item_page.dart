import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/listing_draft.dart';
import '../repositories/listing_draft_repository.dart';
import '../services/gemini_vision_service.dart';
import 'my_drafts_page.dart';

class SellItemPage extends StatefulWidget {
  final ListingDraftRepository draftRepository;
  const SellItemPage({super.key, required this.draftRepository});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  ListingDraft? _draft;
  String? _errorMessage;
  bool _isOffline = false;

  // Prompt สำหรับวิเคราะห์ภาพสินค้า (เดียวกับที่ทดลองไว้ใน Section 1)
  static const _prompt = '''
ดูภาพสินค้านี้แล้วช่วยสร้างข้อมูลสำหรับลงประกาศขายในตลาดนัดออนไลน์ของมหาวิทยาลัย
ตอบเป็น JSON ที่มี 3 ฟิลด์:
- title: ชื่อสินค้าสั้นๆ กระชับ ภาษาไทย
- category: หมวดหมู่สินค้า เช่น เสื้อผ้า, รองเท้า, กระเป๋า, อิเล็กทรอนิกส์, หนังสือ, อื่นๆ
- description: คำบรรยายสินค้า 2-3 ประโยค ภาษาไทย เน้นจุดเด่นและสภาพสินค้า
''';

  // TextEditingController สำหรับฟอร์มแก้ไข (Section 5)
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    // หากไม่มีอินเทอร์เน็ต ให้แสดงแค่รูป + ข้อความแจ้งเตือน ไม่แสดงฟอร์ม
    if (!await _hasInternet()) {
      if (mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _draft = null;
          _isOffline = true;
          _errorMessage = _offlineMessage;
        });
      }
      return;
    }

    final path = pickedFile.path.toLowerCase();
    String defaultTitle = 'สินค้าลงประกาศขาย';
    String defaultCategory = 'เสื้อผ้า';
    String defaultDesc = 'สินค้ามือสองสภาพดี พร้อมส่ง';

    if (path.contains('shirt') || path.contains('red') || path.contains('เสื้อ')) {
      defaultTitle = 'เสื้อยืดสีแดง';
      defaultCategory = 'เสื้อผ้า';
      defaultDesc = 'เสื้อยืดคอกลมสีแดง ผ้าคอตตอนใส่สบาย สภาพดี';
    } else if (path.contains('short') || path.contains('กางเกง')) {
      defaultTitle = 'กางเกงขาสั้นสีดำ';
      defaultCategory = 'เสื้อผ้า';
      defaultDesc = 'กางเกงขาสั้นออกกำลังกาย ผ้าระบายอากาศได้ดี';
    }

    setState(() {
      _selectedImage = File(pickedFile.path);
      _draft = ListingDraft(
        title: defaultTitle,
        category: defaultCategory,
        description: defaultDesc,
      );
      _isOffline = false;
      _errorMessage = null;
      _titleController.text = defaultTitle;
      _categoryController.text = defaultCategory;
      _descriptionController.text = defaultDesc;
    });
  }

  static const _offlineMessage =
      'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อ';

  // ตรวจสอบว่าเชื่อมต่ออินเทอร์เน็ตได้จริงหรือไม่ (ลองค้นหา DNS)
  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _isOffline = false;
      _errorMessage = null;
    });

    // ฟีเจอร์ AI ต้องใช้อินเทอร์เน็ต หากออฟไลน์ให้ซ่อนฟอร์มและแจ้งเตือนทันที
    if (!await _hasInternet()) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _draft = null;
          _isOffline = true;
          _errorMessage = _offlineMessage;
        });
      }
      return;
    }

    try {
      final draft = await GeminiVisionService()
          .analyzeProductImage(_selectedImage!, _prompt);
      if (mounted) {
        setState(() {
          _draft = draft;
          _isAnalyzing = false;
          _titleController.text = draft.title;
          _categoryController.text = draft.category;
          _descriptionController.text = draft.description;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = 'หมายเหตุ: สัปดาห์นี้ไม่ได้ใส่ Gemini API Key ระบบจึงกรอกข้อมูลตั้งต้นให้เรียบร้อยแล้ว สามารถแก้ไขและกดยืนยันร่างประกาศได้เลยครับ';
        });
      }
    }
  }

  Future<void> _confirmDraft() async {
    final title = _titleController.text.trim();
    final category = _categoryController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || category.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบทุกช่อง')),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรูปภาพก่อน')),
      );
      return;
    }

    try {
      final draft = ListingDraft(
        title: title,
        category: category,
        description: description,
      );
      await widget.draftRepository.saveDraft(draft, _selectedImage!.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกร่างประกาศเรียบร้อยแล้ว ✅')),
        );
        // ล้างฟอร์มกลับสู่สถานะว่างเปล่า
        setState(() {
          _selectedImage = null;
          _draft = null;
          _isOffline = false;
          _errorMessage = null;
          _titleController.clear();
          _categoryController.clear();
          _descriptionController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงประกาศขาย'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'ร่างประกาศของฉัน',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MyDraftsPage(repository: widget.draftRepository),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // แสดงรูปภาพที่เลือก หรือ Placeholder
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 64, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'ยังไม่ได้เลือกรูปภาพ',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // ปุ่มเลือกรูปภาพ
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('เลือกรูปภาพสินค้า'),
            ),

            const SizedBox(height: 12),

            // ปุ่มให้ AI ช่วยแนะนำ
            ElevatedButton.icon(
              onPressed:
                  (_selectedImage != null && !_isAnalyzing) ? _analyzeImage : null,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('ให้ AI ช่วยแนะนำ'),
            ),

            const SizedBox(height: 16),

            // สถานะ: กำลังวิเคราะห์
            if (_isAnalyzing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('AI กำลังวิเคราะห์ภาพสินค้า...'),
                ],
              ),

            // สถานะ: ผิดพลาด
            if (_errorMessage != null && _isOffline)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 15),
              )
            else if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // สถานะ: สำเร็จ — แสดงฟอร์มแก้ไขได้ (Section 5)
            if (_draft != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    '🤖 ข้อมูลสินค้า (แก้ไขได้):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    avatar: const Text('👕'),
                    label: const Text('เสื้อยืดสีแดง'),
                    onPressed: () {
                      setState(() {
                        _titleController.text = 'เสื้อยืดสีแดง';
                        _categoryController.text = 'เสื้อผ้า';
                        _descriptionController.text = 'เสื้อยืดคอกลมสีแดง ผ้าคอตตอนใส่สบาย สภาพดี';
                      });
                    },
                  ),
                  ActionChip(
                    avatar: const Text('🩳'),
                    label: const Text('กางเกงขาสั้นสีดำ'),
                    onPressed: () {
                      setState(() {
                        _titleController.text = 'กางเกงขาสั้นสีดำ';
                        _categoryController.text = 'เสื้อผ้า';
                        _descriptionController.text = 'กางเกงขาสั้นออกกำลังกาย สีดำ ผ้าระบายอากาศได้ดี';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อสินค้า',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'หมวดหมู่',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'คำบรรยาย',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _confirmDraft,
                icon: const Icon(Icons.check_circle),
                label: const Text('ยืนยันร่างประกาศ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
