import unittest
from normalize_android_local_properties import normalize_paths


class WindowsPropertiesTest(unittest.TestCase):
    def test_windows_drive_colons_are_escaped(self):
        self.assertEqual(normalize_paths('sdk.dir=C:\\\\Android\nflutter.sdk=D:\\\\flutter\n'),
                         'sdk.dir=C\\:\\\\Android\nflutter.sdk=D\\:\\\\flutter\n')

    def test_already_normalized_is_idempotent(self):
        text = 'sdk.dir=C\\:\\\\Android\nflutter.sdk=C\\:\\\\flutter\n'
        self.assertEqual(normalize_paths(text), text)

    def test_other_properties_and_unix_paths_unchanged(self):
        text = 'sdk.dir=/opt/android\nflutter.sdk=/opt/flutter\nflutter.versionCode=4\n'
        self.assertEqual(normalize_paths(text), text)


if __name__ == '__main__':
    unittest.main()
