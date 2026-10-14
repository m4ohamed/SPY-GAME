# 📋 سجل الأخطاء والحلول (Error Log)

### [BUG-001] Missing Flutter SDK dependencies in pubspec.yaml after `flutter create`
* **الخطأ (The Bug)**:
  `flutter analyze` أظهر أكثر من 700 خطأ من نوع `Target of URI doesn't exist: 'package:flutter/material.dart'` و `The imported package 'flutter' isn't a dependency of the importing package`.
* **السبب الجذري (Root Cause)**:
  عند تشغيل أمر `flutter create --platforms=android .` على مشروع يحتوي مسبقاً على ملف `pubspec.yaml` (مشروع Pure Dart)، تقوم أداة Flutter بإنشاء مجلد `android` وملفات المنصة فقط ولا تقوم بتعديل أو استبدال `pubspec.yaml` القائم لتجنب مسح إعدادات المطور. بالتالي ظل المشروع يفتقر لتعريف تبعية `sdk: flutter` وإعدادات Flutter.
* **الحل الفعلي (The Fix)**:
  تحديث `pubspec.yaml` لإضافة `flutter: sdk: flutter` تحت `dependencies`، و`flutter_test: sdk: flutter` تحت `dev_dependencies`، وتفعيل `flutter: uses-material-design: true` بالإضافة إلى حزم التطبيق المطلوبة (`flutter_riverpod`, `cloud_firestore`, `cloud_functions`, `firebase_auth`, `firebase_core`, `onesignal_flutter`).

### [BUG-002] Dot-shorthands syntax compatibility in Dart template
* **الخطأ (The Bug)**:
  `lib\main.dart:105:30 - experiment_not_enabled: This requires the 'dot-shorthands' language feature to be enabled. Try updating your pubspec.yaml to set the minimum SDK constraint to 3.10.0 or higher`.
* **السبب الجذري (Root Cause)**:
  قالب Flutter الافتراضي في الإصدار 3.47 استخدم اختصار النقطة `.center` و `.fromSeed`، بينما إعداد `environment: sdk: ^3.3.0` لم يفعل هذه الميزة التجريبية.
* **الحل الفعلي (The Fix)**:
  استبدال `.center` بـ `MainAxisAlignment.center` و `.fromSeed` بـ `ColorScheme.fromSeed` لضمان التوافقية الكاملة.

### [BUG-003] Missing `flutter_localizations` dependency in `pubspec.yaml`
* **الخطأ (The Bug)**:
  `lib/main.dart`: `Target of URI doesn't exist: 'package:flutter_localizations/flutter_localizations.dart'`, و `Undefined name 'GlobalMaterialLocalizations'`, `GlobalWidgetsLocalizations`, `GlobalCupertinoLocalizations`.
* **السبب الجذري (Root Cause)**:
  تم استيراد واستخدام مندوبي التعريب (Localizations delegates) في `main.dart` دون إدراج تبعية حزمة `flutter_localizations: sdk: flutter` داخل `dependencies` في `pubspec.yaml`.
* **الحل الفعلي (The Fix)**:
  إضافة `flutter_localizations: sdk: flutter` إلى `dependencies` في `pubspec.yaml` ثم تشغيل `flutter pub get`.

### [BUG-004] Missing `firebase_options.dart` and `google-services.json` for Android App
* **الخطأ (The Bug)**:
  `lib/main.dart`: `Target of URI doesn't exist: 'firebase_options.dart'` و `Undefined name 'DefaultFirebaseOptions'`.
* **السبب الجذري (Root Cause)**:
  استدعاء `DefaultFirebaseOptions.currentPlatform` في `Firebase.initializeApp()` بملف `main.dart` دون إنشاء ملف الخيارات ومزامنة إعدادات Firebase لمشروع `saramomry` وتطبيق Android `com.spygame.app`.
* **الحل الفعلي (The Fix)**:
  1. تسجيل تطبيق Android الجديد `com.spygame.app` في مشروع Firebase (`saramomry`).
  2. إنشاء وتنزيل ملف الإعدادات `android/app/google-services.json`.
  3. تفعيل إضافة `com.google.gms.google-services` في `android/app/build.gradle.kts`.
  4. توليد ملف `lib/firebase_options.dart` الذي يحتوي على إعدادات Android و Web لمشروع `saramomry`.

