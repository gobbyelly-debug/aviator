# Aviator

Flutter Android app for the Aviator project. The app can be built as an APK and installed on a real Android phone over local Wi-Fi.

## Prerequisites

- Flutter SDK installed and available as `flutter`
- Android SDK platform tools installed and available as `adb`
- Java 17 or the JDK bundled with Android Studio
- An Android phone with Developer options and USB debugging enabled
- Computer and phone connected to the same Wi-Fi network

Check the local toolchain:

```bash
flutter doctor
adb version
```

## Start the Local API

The Flutter app talks to the Django backend in `api/django_backend/`.

From the project root:

```bash
cd api/django_backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

Keep this terminal running while testing the app.

Find your computer's Wi-Fi/LAN IP address:

```bash
hostname -I
```

Use the address that belongs to your local Wi-Fi network, for example `192.168.1.25`.

## Connect the Phone Over Wi-Fi

### Option 1: Android 11 and Newer

On the phone:

1. Open Developer options.
2. Enable Wireless debugging.
3. Tap Pair device with pairing code.

On the computer:

```bash
adb pair PHONE_IP:PAIR_PORT
adb connect PHONE_IP:ADB_PORT
adb devices
```

`PHONE_IP`, `PAIR_PORT`, and `ADB_PORT` are shown on the phone's Wireless debugging screen.

### Option 2: USB First, Then Wi-Fi

Connect the phone with USB once, then run:

```bash
adb devices
adb tcpip 5555
adb connect PHONE_IP:5555
adb devices
```

After `adb connect` succeeds, unplug the USB cable. You can find `PHONE_IP` in the phone's Wi-Fi network details.

To switch the phone back to USB mode later:

```bash
adb usb
```

## Run the App Over Wi-Fi

From the project root, install dependencies:

```bash
flutter pub get
```

Run directly on the Wi-Fi-connected phone:

```bash
flutter run --dart-define=AVIATOR_API_BASE_URL=http://COMPUTER_LAN_IP:8000
```

Replace `COMPUTER_LAN_IP` with your computer's local IP address, for example:

```bash
flutter run --dart-define=AVIATOR_API_BASE_URL=http://192.168.1.25:8000
```

## Build and Install an APK

Build a debug APK for local testing:

```bash
flutter build apk --debug --dart-define=AVIATOR_API_BASE_URL=http://COMPUTER_LAN_IP:8000
```

Install it over Wi-Fi:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Build a release APK:

```bash
flutter build apk --release --dart-define=AVIATOR_API_BASE_URL=http://COMPUTER_LAN_IP:8000
```

Install it over Wi-Fi:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

The release build currently uses the debug signing config in `android/app/build.gradle.kts`, so it is suitable for local testing. Use a proper release keystore before publishing.

## API URL Notes

Default API targets:

- Android emulator: `http://10.0.2.2:8000`
- iOS simulator or desktop: `http://127.0.0.1:8000`

For a real Android phone on Wi-Fi, always pass your computer's LAN IP:

```bash
--dart-define=AVIATOR_API_BASE_URL=http://COMPUTER_LAN_IP:8000
```

Do not use `127.0.0.1` on the phone, because that points to the phone itself. Do not use `10.0.2.2` on a physical phone, because that address is only for the Android emulator.

The app automatically calls these Django endpoints:

- `POST /api/access-keys/validate/`
- `GET /api/prediction/`

It also falls back to the legacy PHP-style paths if needed.

## Troubleshooting

- If `adb devices` shows `unauthorized`, unlock the phone and accept the USB/Wi-Fi debugging prompt.
- If `adb connect` fails, confirm the phone and computer are on the same Wi-Fi network and no VPN/firewall is blocking port `5555`.
- If the app cannot reach the API, open `http://COMPUTER_LAN_IP:8000/api/prediction/` from the phone browser.
- If the API works on the computer but not the phone, make sure Django is running with `0.0.0.0:8000`, not `127.0.0.1:8000`.
# aviator
