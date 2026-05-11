from setuptools import setup
import subprocess
import os

# Найти libffi автоматически
def find_libffi():
    result = subprocess.run(
        ["find", "/opt/homebrew", "-name", "libffi.8.dylib"],
        capture_output=True, text=True
    )
    paths = result.stdout.strip().splitlines()
    for p in paths:
        if os.path.exists(p):
            return p
    return None

libffi_path = find_libffi()
if not libffi_path:
    raise RuntimeError("libffi.8.dylib не найден! Запусти: brew install libffi")

print(f"✓ Найден libffi: {libffi_path}")

APP = ["app.py"]
DATA_FILES = []
OPTIONS = {
    "argv_emulation": False,
    "iconfile": "assets/app-icon.icns",
    "semi_standalone": False,
    "plist": {
        "CFBundleName": "ServicesMenu",
        "CFBundleDisplayName": "ServicesMenu",
        "CFBundleIdentifier": "com.agaibadulin.services-menu",
        "CFBundleVersion": "1.0.0",
        "CFBundleShortVersionString": "1.0.0",
        "LSUIElement": True,
        "LSBackgroundOnly": False,
        "NSHighResolutionCapable": True,
    },
    "packages": ["rumps", "encodings"],
    "includes": [
        "encodings",
        "encodings.utf_8",
        "encodings.ascii",
        "encodings.latin_1",
    ],
    "frameworks": [libffi_path],
}

setup(
    app=APP,
    data_files=DATA_FILES,
    options={"py2app": OPTIONS},
    setup_requires=["py2app"],
)
