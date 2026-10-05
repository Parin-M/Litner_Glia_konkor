from pathlib import Path
p=Path('android/app/build.gradle.kts')
s=p.read_text()
s=s.replace('applicationId = "com.example.glia_leitner"','applicationId = "com.glia.konkor"')
s=s.replace('applicationId = "com.example.glialeitner"','applicationId = "com.glia.konkor"')
s=s.replace('minSdk = flutter.minSdkVersion','minSdk = 24')
if 'create("release")' not in s:
    marker='    defaultConfig {'
    block='''    signingConfigs {\n        create("release") {\n            val props = java.util.Properties()\n            val kp = rootProject.file("key.properties")\n            if (kp.exists()) kp.inputStream().use { props.load(it) }\n            keyAlias = props.getProperty("keyAlias")\n            keyPassword = props.getProperty("keyPassword")\n            storeFile = props.getProperty("storeFile")?.let { rootProject.file(it) }\n            storePassword = props.getProperty("storePassword")\n        }\n    }\n'''
    s=s.replace(marker,block+marker)
if Path('android/key.properties').exists():
    s=s.replace('signingConfig = signingConfigs.getByName("debug")','signingConfig = signingConfigs.getByName("release")')
p.write_text(s)
