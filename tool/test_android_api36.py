import unittest

from configure_android_api36 import configure


class Api36Tests(unittest.TestCase):
    def test_generated_flutter_wrapper_and_idempotence(self):
        source = '''android {
    compileSdk = flutter.compileSdkVersion
    defaultConfig {
        targetSdk = flutter.targetSdkVersion
        minSdk = flutter.minSdkVersion
    }
}
'''
        result = configure(source)
        self.assertIn("compileSdk = 36", result)
        self.assertIn("targetSdk = 36", result)
        self.assertIn("minSdk = flutter.minSdkVersion", result)
        self.assertEqual(result, configure(result))

    def test_template_change_cannot_silently_skip_sdk_pin(self):
        with self.assertRaises(ValueError):
            configure("compileSdkVersion(35)\ntargetSdkVersion(35)\n")

    def test_duplicate_assignments_fail_closed(self):
        with self.assertRaises(ValueError):
            configure("compileSdk = 36\ncompileSdk = 35\ntargetSdk = 36\n")


if __name__ == "__main__":
    unittest.main()
