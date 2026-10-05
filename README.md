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
برای Release از **یک keystore ثابت** استفاده می‌شود تا نسخه‌های بعدی با همان کلید قابل Update باشند. چهار Secret زیر را در GitHub Repository → Settings → Secrets and variables → Actions قرار دهید:
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

کلید خصوصی داخل Git قرار نمی‌گیرد. اگر Secretها تنظیم نشده باشند، CI فقط APK اعتبارسنجی می‌سازد؛ Release رسمی بدون امضای ثابت منتشر نمی‌شود.

برای Google Play، انتشار AAB با Play App Signing بهترین مسیر است. Play Protect را نمی‌توان ۱۰۰٪ تضمین کرد، اما این نسخه WebView اجرایی، کد راه‌دور یا مجوزهای غیرضروری ندارد و برای امضای Release ثابت آماده شده است.

## Build
GitHub Actions سه APK جداگانه برای `armeabi-v7a`، `arm64-v8a` و `x86_64` تولید می‌کند، آن‌ها را با SHA256 بررسی می‌کند و در صورت وجود keystore ثابت، برای Tagهای `v*` در GitHub Releases قرار می‌دهد.
