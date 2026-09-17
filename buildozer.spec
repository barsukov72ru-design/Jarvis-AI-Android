[app]
title = Jarvis AI
package.name = jarvisapp
package.domain = org.test
source.dir = .
source.include_exts = py,png,jpg,kv,atlas,json
version = 0.1
requirements = python3, kivy==2.3.0, plyer, requests, urllib3, certifi, idna, charset-normalizer
orientation = portrait
fullscreen = 1
android.api = 31
android.minapi = 21
android.ndk = 25b
android.ndk_api = 21
android.permissions = INTERNET
android.archs = arm64-v8a
[buildozer]
log_level = 2
warn_on_root = 0
