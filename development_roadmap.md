# 🗺️ خريطة طريق التطوير (Development Roadmap)

## ✅ المهام المكتملة
- [x] إنشاء مشروع Flutter ودعم منصة Android فقط باستخدام `flutter create --platforms=android .`.
- [x] توليد وتعديل ملفات Android (`android/app`, `android/build.gradle.kts`, `AndroidManifest.xml`).
- [x] تحديث الـ namespace والـ applicationId إلى `com.spygame.app`.
- [x] نقل وإعادة هيكلة ملف `MainActivity.kt` إلى الحزمة `com.spygame.app` وحذف مجلد `com/example` القديم.
- [x] تعديل عنوان التطبيق إلى `Spy Game` في `AndroidManifest.xml`.
- [x] تهيئة `pubspec.yaml` بتبعيات Flutter الأساسية وتبعيات المشروع.
- [x] ترقية البكجات إلى أحدث الإصدارات الرئيسية (`flutter pub upgrade --major-versions`).
- [x] استخراج الألوان الثابتة وإعداد نظام السمات [AppTheme](file:///e:/spy%20game/app/lib/features/spy_game/presentation/theme/app_theme.dart) و [AppColors](file:///e:/spy%20game/app/lib/features/spy_game/presentation/theme/app_theme.dart).
- [x] تطبيق إعدادات Gradle و Kotlin المستقرة من مشروع `E:\skyjet`:
  - `gradle.properties`: تفعيل `kotlin.incremental=false` و `kotlin.compiler.execution.strategy=in-process`.
  - `gradle-wrapper.properties`: استخدام `gradle-9.1.0-all.zip`.
  - `settings.gradle.kts`: استخدام AGP `9.0.1`، كوتلن `2.3.20`، و Google Services `4.4.4`.
- [x] التحقق واجتياز `flutter analyze` بنجاح 100% (No issues found).
- [x] تشغيل واجتياز جميع الاختبارات `flutter test` (32/32 tests passed).
- [x] إنشاء وتهيئة ملفات `firebase.json` و `.firebaserc` لمشروع `saramomry`.
- [x] نشر قواعد Firestore بنجاح إلى مشروع Firebase (`saramomry`).
- [x] نشر قواعد Realtime Database بنجاح إلى قاعدة `saramomry-default-rtdb`.
- [x] تسجيل تطبيق Android في Firebase لمشروع `saramomry` بالمعرّف `com.spygame.app` وتوليد `google-services.json`.
- [x] تفعيل إضافة `com.google.gms.google-services` في `android/app/build.gradle.kts`.
- [x] توليد ملف [firebase_options.dart](file:///e:/spy%20game/app/lib/firebase_options.dart) لمنصتي Android و Web.
- [x] إضافة حزمة `flutter_localizations` إلى `pubspec.yaml` وحل جميع مشاكل التعريب.
- [x] ربط سمات التصميم [AppTheme](file:///e:/spy%20game/app/lib/features/spy_game/presentation/theme/app_theme.dart) في [main.dart](file:///e:/spy%20game/app/lib/main.dart).
- [x] توثيق المشاكل والحلول في [error.md](./error.md) والدروس في [lessons.md](./lessons.md).

## 🔄 المهام الحالية
- [ ] تهيئة OneSignal ونشر Cloud Functions (`spy_game_functions`).
- [ ] اختبار بناء التطبيق `flutter build apk --release`.

## 🔮 المهام المستقبلية
- [ ] نشر Cloud Functions (`firebase deploy --only functions`).
- [ ] إطلاق واختبار دورة اللعبة الكاملة (إنشاء غرفة، انضمام، تصويت، إشعارات).

