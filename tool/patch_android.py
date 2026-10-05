from pathlib import Path

manifest = Path('android/app/src/main/AndroidManifest.xml')
text = manifest.read_text(encoding='utf-8')

if 'android.permission.INTERNET' not in text:
    text = text.replace(
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android">',
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <uses-permission android:name="android.permission.INTERNET" />'
    )

if 'android:usesCleartextTraffic=' not in text:
    text = text.replace(
        '<application ',
        '<application android:usesCleartextTraffic="false" ',
        1
    )

text = text.replace(
    'android:label="glia_leitner"',
    'android:label="گلیا کنکور"'
)

manifest.write_text(text, encoding='utf-8')
