# بناء Android عبر GitHub Actions

يوجد Workflow في `.github/workflows/build-android.yml` يعمل عند كل push إلى `main`، وعند فتح Pull Request على `main`، ويمكن تشغيله يدويًا من تبويب **Actions** عبر **Run workflow**.

يستخدم البناء Flutter `3.50.0`، وهو متوافق مع قيد Dart الموجود في `pubspec.yaml` (`>=3.12.0`). كما يستخدم Java 17 وGradle 9.3.1 وAndroid Gradle Plugin `9.1.1`، ويولّد Gradle Wrapper أثناء التشغيل لأن ملفات `gradlew` و`gradle-wrapper.jar` غير محفوظة في المستودع.

ينتج البناء ملفي APK مقسّمين حسب المعمارية وملف AAB، ويتم رفعها كـ GitHub Actions Artifacts لمدة 14 يومًا. يمكن تنزيلها من صفحة تشغيل الـ Workflow.

## ملاحظة التوقيع

إعداد Android الحالي يربط `release` بمفتاح debug الموجود في بيئة البناء. لذلك تصلح الملفات الناتجة للاختبار الداخلي والتثبيت التجريبي، لكنها ليست موقعة بمفتاح نشر Google Play. قبل النشر، يجب إضافة keystore خاص بالإصدار إلى GitHub Secrets وتعديل `android/app/build.gradle` لقراءة بياناته من متغيرات البيئة أو من ملف مؤقت ينشئه الـ Workflow.
