# گلیا کنکور — Native Flutter

گلیا کنکور یک برنامهٔ لایتنر بومی Flutter است؛ محتوای آموزشی و پیشرفت کاربر به‌صورت محلی نگهداری می‌شوند و موتور معنایی Noql برای جست‌وجوی آفلاین در زمان ساخت APK به برنامه اضافه می‌شود.

## داده‌های آموزشی

- کارت‌های اصلی لایتنر
- سؤال‌های املای پک فارسی
- کارت‌های واژهٔ پک فارسی

تعداد رکوردها از روی فایل‌های JSON خوانده می‌شود و ابزار اعتبارسنجی، ساختار، شناسه‌های تکراری و گزینهٔ صحیح سؤال‌ها را بررسی می‌کند.

## دریافت APK از GitHub Actions

1. در GitHub، مخزن را باز کنید و وارد زبانهٔ **Actions** شوید.
2. اجرای **Build Android APK and Release** را انتخاب کنید.
3. روی **Run workflow** بزنید؛ یا بعد از push روی شاخهٔ `main`، اجرای خودکار را باز کنید.
4. پس از موفقیت بیلد، در پایین صفحهٔ همان اجرا، بخش **Artifacts** را باز کنید و فایل `glia-konkor-apk` را دریافت کنید. داخل آن APK و فایل checksum قرار دارد.

برای انتشار نسخهٔ قابل‌دریافت در بخش **Releases**، بعد از push تغییرات این دستورات را اجرا کنید:

```bash
git tag v2.3.0
git push origin v2.3.0
```

همان workflow، APK و checksum را به Release ضمیمه می‌کند. هنگام استفاده از APK مبهم‌سازی‌شده، فایل symbol مربوط به tag را هم از Artifacts نگه دارید تا برای تحلیل stack traceهای crash قابل استفاده باشد.

## اجرای اعتبارسنجی داده

```bash
python tool/validate_data.py
```

## ساخت محلی Android

این مخزن فایل‌های Android تولیدشده و مدل حجیم ONNX را داخل Git نگه نمی‌دارد. در محیطی با Flutter و Python نصب‌شده، ابتدا پلتفرم Android را تولید کنید و وابستگی‌های مدل را نصب کنید:

```bash
flutter create --platforms=android --org com.glia.konkor --project-name glia_leitner .
python tool/prepare_android.py
python -m pip install "torch>=2.4,<2.8" "transformers>=5,<6" "sentence-transformers>=6.1,<6.2" "huggingface_hub>=0.25" "onnx>=1.16" "onnxruntime>=1.18"
python tool/build_noql_ai.py
base64 --decode assets/glia_app_icon.png.b64 > assets/glia_icon.png
flutter pub get
dart run flutter_launcher_icons
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm64
```

بیلد مدل Noql نیازمند دریافت مدل از Hugging Face است و ممکن است در اجرای نخست زمان و فضای دیسک قابل‌توجهی مصرف کند.
