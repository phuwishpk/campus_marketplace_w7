import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/listing_draft.dart';

class GeminiVisionService {
  static const _model = 'gemini-3.5-flash-lite';
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const _maxRetries = 3;

  Future<ListingDraft> analyzeProductImage(File imageFile, String prompt) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isEmpty) {
      throw Exception('ไม่ได้ระบุ API Key');
    }

    // อ่านไฟล์ภาพเป็นไบต์ → เข้ารหัส Base64
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final url = Uri.parse('$_baseUrl/models/$_model:generateContent?key=$apiKey');

    final payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'title': {
              'type': 'STRING',
              'description': 'ชื่อสินค้าภาษาไทย'
            },
            'category': {
              'type': 'STRING',
              'description': 'หมวดหมู่สินค้า'
            },
            'description': {
              'type': 'STRING',
              'description': 'คำบรรยายสินค้าสำหรับลงประกาศขาย'
            }
          },
          'required': ['title', 'category', 'description']
        }
      }
    };

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        print('GeminiVisionService: attempt $attempt/$_maxRetries');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 90));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List<dynamic>?;

          // ตรวจสอบว่ามี candidates หรือไม่
          if (candidates == null || candidates.isEmpty) {
            throw Exception(
                'AI ไม่สามารถวิเคราะห์ภาพนี้ได้ อาจเข้าข่ายเนื้อหาที่ไม่เหมาะสม ลองใช้ภาพอื่น');
          }

          // ตรวจสอบ finishReason
          final finishReason = candidates[0]['finishReason'] as String?;
          if (finishReason == 'SAFETY') {
            throw Exception(
                'เนื้อหาที่วิเคราะห์เข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini กรุณาใช้ภาพอื่น');
          }

          // ดึงข้อความ JSON จาก response
          final text = candidates[0]['content']['parts'][0]['text'] as String;
          print('GeminiVisionService: ได้ JSON: $text');

          // jsonDecode สองชั้น: ชั้นแรกจาก response body, ชั้นสองจาก text ที่ AI ส่งกลับ
          final Map<String, dynamic> jsonResult = jsonDecode(text);
          return ListingDraft.fromJson(jsonResult);
        } else if ((response.statusCode == 503 || response.statusCode == 429) &&
            attempt < _maxRetries) {
          final waitSec = attempt * 5;
          print(
              'GeminiVisionService: ได้ ${response.statusCode} → รอ ${waitSec}s แล้วลองใหม่');
          await Future.delayed(Duration(seconds: waitSec));
          continue;
        } else {
          throw Exception(
              'Gemini API Error (สถานะ ${response.statusCode})\n${response.body}');
        }
      } catch (e) {
        if (attempt == _maxRetries) {
          throw Exception('เชื่อมต่อ AI ไม่สำเร็จ (ลอง $attempt ครั้งแล้ว): $e');
        }
        if (e.toString().contains('ไม่ปลอดภัย') ||
            e.toString().contains('ไม่เหมาะสม')) {
          rethrow; // ถ้าเป็น Safety block ไม่ต้อง retry
        }
        print('GeminiVisionService: error attempt $attempt → $e');
        await Future.delayed(Duration(seconds: attempt * 5));
      }
    }
    throw Exception('เชื่อมต่อ AI ไม่สำเร็จหลังจากลอง $_maxRetries ครั้ง');
  }
}
