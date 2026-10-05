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

gradle = Path('android/app/build.gradle.kts')
gradle_text = gradle.read_text(encoding='utf-8')

key_properties = Path('android/key.properties')
if key_properties.exists():
    imports = 'import java.io.FileInputStream\nimport java.util.Properties\n\n'
    if 'import java.io.FileInputStream' not in gradle_text:
        gradle_text = imports + gradle_text

    load_block = '''val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }

'''
    if 'val keystorePropertiesFile' not in gradle_text:
        gradle_text = gradle_text.replace('android {', load_block + 'android {', 1)

    signing_block = '''signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    '''

    if 'create("release")' not in gradle_text:
        gradle_text = gradle_text.replace(
            '    buildTypes {',
            '    ' + signing_block + 'buildTypes {',
            1,
        )

    gradle_text = gradle_text.replace(
        'signingConfig = signingConfigs.getByName("debug")',
        'signingConfig = signingConfigs.getByName("release")',
    )

gradle.write_text(gradle_text, encoding='utf-8')
