# گلیا کنکور — لایتنر هوشمند

نسخه Android با Flutter + WebView که **فایل HTML مرجع همان فایل منبع برنامه** را داخل APK نگه می‌دارد؛ در نتیجه داده‌ها، کارت‌ها، ترتیب تعریف‌شده، فیلترها، انیمیشن‌ها و الگوریتم مرور از منبع HTML اجرا می‌شوند. منطق ساخت Deck و وضعیت‌های مرور در HTML مرجع باقی مانده است.

## کد Flutter

لایه بومی Flutter توسعه داده شده و مسئول این بخش‌هاست:

- راه‌اندازی امن WebView
- اعتبارسنجی فایل HTML قبل از اجرا
- مدیریت خطا و صفحه Retry
- مدیریت Back اندروید
- نمایش Progress بارگذاری
- باز کردن لینک‌های خارجی در مرورگر سیستم
- Bridge آماده برای ارتباط JavaScript ↔ Flutter
- تزریق لوگوی گلیا در Splash و Header
- ساختار ماژولار در `app/`, `core/`, `models/`, `services/`, `pages/`
- Unit Test برای اعتبارسنجی Asset

منطق کارت‌ها عمداً در HTML تغییر داده نشده تا رفتار برنامه با نسخه مرجع یکسان بماند.

## معماری Android

سه ABI ساخته می‌شود:

- `armeabi-v7a`
- `arm64-v8a`
- `x86_64`

## Release Signing

برای اینکه Updateهای آینده بدون خطای signature انجام شوند، **همان Release Keystore باید برای تمام نسخه‌های آینده نگه داشته شود**.

در GitHub → Settings → Secrets and variables → Actions این چهار Secret را اضافه کنید:

`ANDROID_KEYSTORE_BASE64`
`ANDROID_KEYSTORE_PASSWORD`
`ANDROID_KEY_ALIAS`
`ANDROID_KEY_PASSWORD`

CI در زمان Build فایل Keystore را از Secret می‌سازد، APK را با Release Key امضا می‌کند، امضا را با `apksigner` بررسی می‌کند و سپس APKها را در GitHub Release قرار می‌دهد.

Keystore و `key.properties` هیچ‌وقت نباید داخل Git commit شوند.

## انتشار خودکار

پس از Build موفقِ نسخه امضاشده، Workflow برای نسخه موجود در `pubspec.yaml` یک Release با Tag متناظر می‌سازد یا APKهای Release قبلی را با `--clobber` به‌روزرسانی می‌کند.

برای نسخه جدید فقط:

1. `pubspec.yaml` را با build number جدید افزایش دهید.
2. روی `main` push کنید.

CI نسخه جدید را Build و Release می‌کند.

## Play Protect

هیچ نرم‌افزاری نمی‌تواند عدم هشدار Play Protect را ۱۰۰٪ تضمین کند. برای کاهش ریسک:

- APK با Release Key ثابت امضا می‌شود.
- Cleartext HTTP غیرفعال است.
- کلید امضا داخل Repository قرار نمی‌گیرد.
- خروجی APKها بعد از Build از نظر امضا Verify می‌شوند.
- وابستگی‌های Flutter از Pub.dev رسمی استفاده می‌کنند.

قبل از انتشار عمومی نیز پیشنهاد می‌شود APK روی چند دستگاه واقعی و نسخه‌های مختلف Android تست شود.

## بررسی کیفیت

CI این مراحل را انجام می‌دهد:

- `flutter analyze`
- `flutter test`
- Release APK build برای سه معماری
- Signature verification در حالت Release signing

صفر باگ به‌صورت مطلق قابل تضمین نیست، اما Build تا زمان قبولی تمام کنترل‌های CI منتشر نمی‌شود.
