import 'package:flutter/material.dart';

/// key ของ ScaffoldMessenger ระดับแอป ใช้แสดง SnackBar ได้แม้หน้าที่เรียกจะถูกแทนที่ไปแล้ว
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
