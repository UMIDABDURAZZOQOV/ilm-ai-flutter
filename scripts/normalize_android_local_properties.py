"""Normalize Flutter-generated Windows SDK paths for Android PropertyEscape lint.

Only the ignored local SDK configuration is changed; no signing file is read.
Run after Flutter builds and before native lint, since Flutter rewrites this file.
"""
from pathlib import Path
import re


def normalize_paths(text: str) -> str:
    return re.sub(r"(?m)^((?:sdk\.dir|flutter\.sdk)=)([A-Za-z]):", r"\1\2\\:", text)


if __name__ == "__main__":
    path = Path(__file__).resolve().parent.parent / "android/local.properties"
    original = path.read_text(encoding="utf8")
    normalized = normalize_paths(original)
    if original != normalized:
        path.write_text(normalized, encoding="utf8")
    print("Android SDK paths normalized; no signing configuration accessed.")
