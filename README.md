# گلیا کنکور — Native Flutter

نسخه فعلی کاملاً Native Flutter است و دیگر HTML/WebView را در زمان اجرای APK استفاده نمی‌کند. فایل‌های HTML داخل `reference/` فقط منبع داده و مرجع تبدیل هستند.

## داده‌های حفظ‌شده
- ۲۱۵۱ کارت اصلی لایتنر
- ۶۳۹ سؤال املای پک فارسی
- ۴۳۴ کارت واژه پک فارسی
- ترتیب داده‌ها در مرحله تولید Native از همان آرایه‌های منبع خوانده می‌شود.

## امکانات
- کارت سه‌حالته: دوباره / بعداً / یاد گرفتم
- ذخیره دائمی پیشرفت و استریک
- بخش یادگرفته‌ها و نیازمند مرور
- آزمون املای فارسی
- آمار عملکرد
- حالت روشن/تیره
- کنترل انیمیشن، سرعت، اندازه متن، Shuffle، Haptic و حالت کم‌مصرف
- پشتیبان‌گیری و بازیابی JSON
- سه ABI: `armeabi-v7a`، `arm64-v8a`، `x86_64`
- رابط راست‌به‌چپ و طراحی نزدیک به قالب مرجع

## تولید داده
`tool/generate_native_data.dart` آرایه‌های JavaScript موجود در دو فایل مرجع را در زمان build می‌خواند و به JSON داخلی Flutter تبدیل می‌کند. در APK هیچ WebView یا JavaScript runtime لازم نیست.

## Release و Play Protect
برای Release از keystore ثابت استفاده می‌شود. چهار Secret زیر باید در GitHub Repository تنظیم شوند:
- `GLIA_KEYSTORE_B64`
- `GLIA_STORE_PASSWORD`
- `GLIA_KEY_ALIAS`
- `GLIA_KEY_PASSWORD`

کلید خصوصی داخل Git قرار نمی‌گیرد. برای Google Play، AAB و Play App Signing مسیر پیشنهادی انتشار رسمی است. Play Protect را نمی‌توان از طرف APK به‌صورت مطلق تضمین کرد، اما این نسخه از WebView/کد راه‌دور/مجوزهای غیرضروری استفاده نمی‌کند و با امضای Release ثابت برای انتشار امن‌تر آماده شده است.

## Build
GitHub Actions سه APK جداگانه، AAB و SHA256 تولید می‌کند و برای Tagهای `v*` آن‌ها را در GitHub Releases قرار می‌دهد.
