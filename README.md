# گلیا کنکور — لایتنر هوشمند

این نسخه Android با Flutter ساخته شده و **فایل HTML مرجع عیناً به‌عنوان asset** داخل برنامه قرار می‌گیرد؛ بنابراین ترتیب کارت‌ها، داده‌ها، فیلترها، انیمیشن‌ها، منطق مرور و وضعیت یادگیری از همان HTML اجرا می‌شود.

## ویژگی‌ها

- Flutter + WebView
- سه ABI: `armeabi-v7a`، `arm64-v8a`، `x86_64`
- Splash و آیکن گلیا با سبک لوگوی ارائه‌شده
- حفظ `localStorage` برای پیشرفت، تم و تنظیمات
- تنظیمات و Backup/Restore خود HTML بدون بازنویسی منطق کارت‌ها
- GitHub Actions برای Build APK و Release

## روند آپدیت

نسخه بعدی باید با همان `applicationId` و **همان کلید Release** منتشر شود و build number افزایش پیدا کند. کلید امضا نباید در مخزن قرار بگیرد؛ در CI باید از GitHub Secrets استفاده شود.

## Play Protect

هیچ پروژه‌ای نمی‌تواند هشدار Play Protect را ۱۰۰٪ تضمین کند. این پروژه cleartext HTTP را غیرفعال می‌کند و برای انتشار واقعی باید Release signing امن تنظیم شود. HTML مرجع از Google Fonts و GSAP روی HTTPS استفاده می‌کند.
