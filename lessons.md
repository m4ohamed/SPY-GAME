# 📚 الدروس المستفادة (Lessons Learned)

### 📌 الدرس 1: تشغيل `flutter create` على مشروع دارت قائم
* **النمط الخاطئ (Anti-pattern)**:
  الاعتماد التام على أمر `flutter create --platforms=... .` لتهيئة المشروع كلياً عند وجود `pubspec.yaml` مسبق، وافتراض أنه سيقوم بإضافة تبعيات `flutter sdk` تلقائياً إلى `pubspec.yaml`.
* **النمط الصحيح (Approved Pattern)**:
  فحص ملف `pubspec.yaml` بعد أمر الإنشاء والتأكد من إضافة:
  ```yaml
  dependencies:
    flutter:
      sdk: flutter

  dev_dependencies:
    flutter_test:
      sdk: flutter

  flutter:
    uses-material-design: true
  ```
  ثم تشغيل `flutter pub get` والتحقق من `flutter analyze`.

### 📌 الدرس 2: تجنب الألوان المكتوبة يدوياً (Hardcoded Colors)
* **النمط الخاطئ (Anti-pattern)**:
  استخدام ألوان صريحة ومباشرة مثل `Colors.deepPurple` أو قيم `Color(0x...)` داخل عناصر الواجهة أو مباشرة في `main.dart`.
* **النمط الصحيح (Approved Pattern)**:
  فصل لوحة الألوان وسمات التطبيق في كلاسات مخصصة للتصميم مثل `AppColors` و `AppTheme` داخل طبقة العرض واستدعائها عبر السمات المركزية للتطبيق (`ThemeData`).

### 📌 الدرس 3: إعدادات Gradle و Kotlin المستقرة على Windows (وفق نموذج مشروع Skyjet)
* **النمط الخاطئ (Anti-pattern)**:
  - استخدام إصدار Kotlin غير متوافق مثل `2.4.0` أو AGP تجريبي `9.1.0` مع Gradle حديث بدون استراتيجية الترجمة المناسبة، مما يؤدي على أنظمة Windows إلى فشل شيطان كوتلن وتعطل الكاش التزايدي:
    `Could not close incremental caches: class-fq-name-to-source.tab`
    `Could not connect to Kotlin compile daemon`
* **النمط الصحيح (Approved Pattern)**:
  - ضبط الخصائص في `android/gradle.properties`:
    ```properties
    kotlin.incremental=false
    kotlin.compiler.execution.strategy=in-process
    ```
  - استخدام إصدارات Gradle و Kotlin المستقرة والمجربة في `settings.gradle.kts`:
    * Gradle Distribution: `gradle-9.1.0-all.zip`
    * Android Gradle Plugin: `9.0.1`
    * Kotlin: `2.3.20`
    * Google Services Plugin: `4.4.4`
