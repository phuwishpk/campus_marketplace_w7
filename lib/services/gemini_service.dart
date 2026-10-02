import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _model = 'gemini-3.5-flash';
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const _maxRetries = 3;

  Future<String> generateText(String prompt) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isEmpty) {
      throw Exception('ไม่ได้ระบุ API Key (ต้องรันแอปด้วย --dart-define=GEMINI_API_KEY=...)');
    }

    final url = Uri.parse('$_baseUrl/models/$_model:generateContent?key=$apiKey');
    
    final payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    };

    // Retry loop สำหรับ 503 / 429
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        print('GeminiService: attempt $attempt/$_maxRetries');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final text = candidates[0]['content']['parts'][0]['text'] as String;
            print('GeminiService: สำเร็จ! ได้ข้อความยาว ${text.length} ตัวอักษร');
            return text;
          }
          throw Exception('ไม่พบคำตอบจาก AI');
        } else if ((response.statusCode == 503 || response.statusCode == 429) &&
            attempt < _maxRetries) {
          // เซิร์ฟเวอร์ล้น → รอ แล้วลองใหม่
          final waitSec = attempt * 5; // 5s, 10s
          print('GeminiService: ได้ ${response.statusCode} → รอ ${waitSec}s แล้วลองใหม่');
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
        // ถ้ายังไม่หมดรอบ → รอ แล้วลองอีก
        print('GeminiService: error attempt $attempt → $e');
        await Future.delayed(Duration(seconds: attempt * 5));
      }
    }
    throw Exception('เชื่อมต่อ AI ไม่สำเร็จหลังจากลอง $_maxRetries ครั้ง');
  }
}
