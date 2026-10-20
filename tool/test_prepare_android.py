"""Regression tests for the generated Android scaffold preparation script."""
from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path

import prepare_android


KOTLIN_GRADLE = '''plugins { id("com.android.application") }
android {
    namespace = "com.example.generated"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    defaultConfig {
        applicationId = "com.example.generated"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
    }
    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }
}
'''

GROOVY_GRADLE = '''plugins { id 'com.android.application' }
android {
    namespace 'org.example.generated'
    compileSdkVersion flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion
    defaultConfig {
        applicationId 'org.example.generated'
        minSdkVersion flutter.minSdkVersion
        targetSdkVersion flutter.targetSdkVersion
    }
    buildTypes {
        release {
            minifyEnabled false
        }
    }
}
'''


class PrepareAndroidTests(unittest.TestCase):
    def test_kotlin_gradle_identity_and_idempotence(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            gradle = Path(temp_dir) / "build.gradle.kts"
            gradle.write_text(KOTLIN_GRADLE, encoding="utf-8")
            self.assertEqual(
                prepare_android.android_identity(gradle, kotlin=True),
                ("com.example.generated", "com.example.generated"),
            )
            prepare_android.configure_kotlin_gradle(gradle)
            configured = gradle.read_text(encoding="utf-8")
            prepare_android.configure_kotlin_gradle(gradle)
            self.assertEqual(gradle.read_text(encoding="utf-8"), configured)
            for required in (
                "compileSdk = 36",
                "minSdk = 24",
                "targetSdk = 36",
                "isMinifyEnabled = true",
                "useLegacyPackaging = false",
            ):
                self.assertIn(required, configured)

    def test_groovy_gradle_identity_and_configuration(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            gradle = Path(temp_dir) / "build.gradle"
            gradle.write_text(GROOVY_GRADLE, encoding="utf-8")
            self.assertEqual(
                prepare_android.android_identity(gradle, kotlin=False),
                ("org.example.generated", "org.example.generated"),
            )
            prepare_android.configure_groovy_gradle(gradle)
            configured = gradle.read_text(encoding="utf-8")
            for required in (
                "compileSdkVersion 36",
                "minSdkVersion 24",
                "targetSdkVersion 36",
                "minifyEnabled true",
                "useLegacyPackaging = false",
            ):
                self.assertIn(required, configured)

    def test_main_activity_package_and_path_stay_aligned(self) -> None:
        for extension, language, expected_package in (
            (".kt", "kotlin", "package com.example.generated"),
            (".java", "java", "package com.example.generated;"),
        ):
            with self.subTest(language=language), tempfile.TemporaryDirectory() as temp_dir:
                root = Path(temp_dir)
                source_root = root / "android" / "app" / "src" / "main"
                source = source_root / language / "com" / "old" / f"MainActivity{extension}"
                source.parent.mkdir(parents=True)
                old_package = "package com.old\n" if extension == ".kt" else "package com.old;\n"
                source.write_text(f"{old_package}class MainActivity {{}}\n", encoding="utf-8")

                previous_dir = Path.cwd()
                os.chdir(root)
                try:
                    prepare_android.configure_main_activity_package("com.example.generated")
                finally:
                    os.chdir(previous_dir)

                destination = (
                    source_root / language / "com" / "example" / "generated"
                    / f"MainActivity{extension}"
                )
                self.assertTrue(destination.exists())
                self.assertIn(expected_package, destination.read_text(encoding="utf-8"))
                self.assertFalse(source.exists())


if __name__ == "__main__":
    unittest.main()
