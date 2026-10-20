<div align="center">
<img alt="Identixia" src="https://raw.githubusercontent.com/identixia-IDV/identixia-assets/main/brand/logo.png" width="320"/>

<a href="https://identixia.com"><img src="https://img.shields.io/badge/Website-0F766E?style=for-the-badge&logo=googlechrome&logoColor=white" alt="Website" /></a>
<a href="https://docs.identixia.com"><img src="https://img.shields.io/badge/Docs-0F766E?style=for-the-badge&logo=gitbook&logoColor=white" alt="Docs" /></a>
<a href="https://huggingface.co/Identixia"><img src="https://img.shields.io/badge/HuggingFace-FFD21E?style=for-the-badge&logo=huggingface&logoColor=black" alt="Hugging Face" /></a>
<a href="https://hub.docker.com/u/identixia"><img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker Hub" /></a>
<a href="https://playground.identixia.com/"><img src="https://img.shields.io/badge/Playground-0F766E?style=for-the-badge&logo=cloudplayground&logoColor=white" alt="Playground" /></a>
</div>

<div align="center">

# <img src="https://cdn.simpleicons.org/flutter/02569B" width="32" height="32" alt="" /> ID Document Liveness Detection SDK for Flutter — Plugin and Sample App | Identixia

</div>

Integrate **document liveness detection and anti-spoofing** with the **Identixia Flutter SDK**. This repository provides a Flutter plugin for Android and iOS for checking ID documents for presentation attacks such as screen replays, printed copies, and replaced photos. Document presentation attack detection (PAD) adds an authenticity check to identity verification workflows. This liveness-only sample does not include OCR or MRZ text extraction.

Use the sample to add document anti-spoofing checks to customer onboarding and Know Your Customer (KYC) workflows alongside a separate document recognition service. Processing runs on the device; images are not sent to the Identixia cloud.

Package: `document_reader_sdk`. Database pack: `document.xdb` packed from `db_liveness.dat` only

<p><img src="https://img.shields.io/badge/On-device-0F766E?style=flat-square" alt="On-device" /> <img src="https://img.shields.io/badge/Document%20liveness-0F766E?style=flat-square" alt="Document liveness" /> <img src="https://img.shields.io/badge/Liveness--only-5A6573?style=flat-square" alt="Liveness-only" /> <img src="https://img.shields.io/badge/Android%20%2B%20iOS-0F766E?style=flat-square" alt="Android + iOS" /> <img src="https://img.shields.io/badge/Plugin-5A6573?style=flat-square" alt="Plugin" /></p>

> For setup, integration, and API guides, see the [ID Document Liveness Detection SDK documentation for Flutter](https://docs.identixia.com). This page covers the sample repository.

## <img src="https://api.iconify.design/lucide/clipboard-list.svg?color=%230F766E" width="24" height="24" alt="" /> SDK overview

The sample includes a demo license. Your own application requires a key issued for its application identifier.

| Topic | Basic information |
| --- | --- |
| **Product** | On-device **ID Document Liveness Detection** Flutter plugin (KYC / eKYC) |
| **Documents** | Passport, national ID, driver license (capabilities depend on pack / license) |
| **Pack** | `document.xdb` packed from `db_liveness.dat` only |
| **Runtime** | Android AAR + iOS framework from local clone or `v1.0.0` Release |
| **Demo id** | `com.identixia.documentliveness` / `com.identixia.documentliveness.app` |
| **UI** | Home screen with Camera, Gallery, and About options; results on one scrollable screen |
| **Privacy** | All processing on device — no Identixia cloud for document data |

---

## <img src="https://api.iconify.design/lucide/terminal.svg?color=%230F766E" width="24" height="24" alt="" /> Quick start

Choose the instructions for your device below. Run the Android and iOS steps separately; iOS builds require a Mac.

### <img src="https://img.shields.io/badge/-1-0F766E?style=for-the-badge" alt="" /> Clone

```bash
git clone https://github.com/identixia-IDV/ID-Document-Liveness-Detection-Flutter.git
cd ID-Document-Liveness-Detection-Flutter
```

Download [`documentlivenesssdk.aar`](https://github.com/identixia-IDV/ID-Document-Liveness-Detection-Android/releases/tag/runtime) from the [ID-Document-Liveness-Detection-Android Releases](https://github.com/identixia-IDV/ID-Document-Liveness-Detection-Android/releases/tag/runtime). Save the file as `example/android/libdocumentlivenesssdk/documentlivenesssdk.aar`.

Download [`documentlivenesssdk.framework.zip`](https://github.com/identixia-IDV/ID-Document-Liveness-Detection-iOS/releases/tag/runtime) from the [ID-Document-Liveness-Detection-iOS Releases](https://github.com/identixia-IDV/ID-Document-Liveness-Detection-iOS/releases/tag/runtime). Unzip it into `ios/Frameworks/`. The files should sit in that folder, not inside an extra directory.

### Android

Use a physical **arm64** Android phone with USB debugging on. Flutter 3.44 or newer. The camera sample does not run on an emulator.

From the repository root:

```bash
dart run tool/bootstrap.dart
cd example
flutter devices
flutter run -d android
```

`flutter devices` prints the id of each connected phone. When more than one Android device is listed, pass that id instead of `android`.

### iOS

Use a Mac with Xcode, CocoaPods, and a physical **iPhone**. The camera sample does not run in the Simulator.

From the repository root:

```bash
dart run tool/bootstrap.dart
cd example
cd ios && pod install && cd ..
flutter devices
flutter run -d ios
```

When more than one iPhone is listed, pass that device id instead of `ios`.

### <img src="https://img.shields.io/badge/-2-0F766E?style=for-the-badge" alt="" /> Activate / license

1. Copy the id of your own app. On Android this is the application id. On iOS this is the bundle id. The sample id is `com.identixia.documentliveness`, `com.identixia.documentliveness.app`.
2. Email that id and the product name to [contact@identixia.com](mailto:contact@identixia.com).
3. Replace the demo key in `example/lib/core/constants/license.dart` with the key you receive.
4. Rebuild, then continue with the next step.

### <img src="https://img.shields.io/badge/-3-0F766E?style=for-the-badge" alt="" /> First capture

Wait for the Home screen to show **Ready**, then choose **Camera** to capture a document or **Gallery** to select an image. Check the license status on the Result or About screen.

---

## <img src="https://api.iconify.design/lucide/list-checks.svg?color=%230F766E" width="24" height="24" alt="" /> Features

| Capability | What it does |
| --- | --- |
| <img src="https://api.iconify.design/lucide/shield.svg?color=%230F766E" width="16" height="16" alt="" /> Document liveness | Check for presentation attacks such as screen replays, printed copies, and replaced photos when licensed |
| <img src="https://api.iconify.design/lucide/camera.svg?color=%230F766E" width="16" height="16" alt="" /> Live capture | Locate and capture a document with the camera, or select front and optional back images from the gallery |
| <img src="https://api.iconify.design/lucide/scroll-text.svg?color=%230F766E" width="16" height="16" alt="" /> Result UI | A single scrollable screen showing status, checks, images, and the raw JSON response |
| <img src="https://api.iconify.design/lucide/house.svg?color=%230F766E" width="16" height="16" alt="" /> Home UI | Home screen with Camera, Gallery, and About options |

---

## <img src="https://api.iconify.design/lucide/pc-case.svg?color=%230F766E" width="24" height="24" alt="" /> System requirements

| | |
| --- | --- |
| Devices | Physical **arm64** Android and/or **iPhone** |
| Demo Android id | `com.identixia.documentliveness` |
| Demo iOS id | `com.identixia.documentliveness.app` |
| Package | `document_reader_sdk` |

---

## <img src="https://api.iconify.design/lucide/package.svg?color=%230F766E" width="24" height="24" alt="" /> SDK installation

Download [`documentlivenesssdk.aar`](https://github.com/identixia-IDV/ID-Document-Liveness-Detection-Android/releases/tag/runtime) from the [ID-Document-Liveness-Detection-Android Releases](https://github.com/identixia-IDV/ID-Document-Liveness-Detection-Android/releases/tag/runtime). Save the file as `example/android/libdocumentlivenesssdk/documentlivenesssdk.aar`.

Download [`documentlivenesssdk.framework.zip`](https://github.com/identixia-IDV/ID-Document-Liveness-Detection-iOS/releases/tag/runtime) from the [ID-Document-Liveness-Detection-iOS Releases](https://github.com/identixia-IDV/ID-Document-Liveness-Detection-iOS/releases/tag/runtime). Unzip it into `ios/Frameworks/`. The files should sit in that folder, not inside an extra directory.

---

## <img src="https://api.iconify.design/lucide/rocket.svg?color=%230F766E" width="24" height="24" alt="" /> Run

Start in the repository root and follow the commands for your target platform. These commands are also listed in [Quick start](#-quick-start).

**Android** — physical arm64 phone, USB debugging on:

```bash
dart run tool/bootstrap.dart
cd example
flutter devices
flutter run -d android
```

**iOS** — Mac, Xcode, CocoaPods, physical iPhone (not the Simulator):

```bash
dart run tool/bootstrap.dart
cd example
cd ios && pod install && cd ..
flutter devices
flutter run -d ios
```

---

## <img src="https://api.iconify.design/lucide/key-round.svg?color=%230F766E" width="24" height="24" alt="" /> SDK license and activation

1. Run the sample with the bundled key and the sample id below.
2. For your own app, email [contact@identixia.com](mailto:contact@identixia.com) with the platform, your application id or bundle id, and the features you need.
3. Put the key you receive in the same place as the demo key.
4. Rebuild. Activation runs before SDK init. If it fails, the key does not match that id.

Sample id:

- `com.identixia.documentliveness`
- `com.identixia.documentliveness.app`

Set the key, then activate:

https://github.com/identixia-IDV/ID-Document-Liveness-Detection-Flutter/blob/1e805288dcada21997be9543432469f42c475049/example/lib/core/constants/license.dart#L9-L19

https://github.com/identixia-IDV/ID-Document-Liveness-Detection-Flutter/blob/1e805288dcada21997be9543432469f42c475049/example/lib/services/sdk_service.dart#L37-L37

## <img src="https://api.iconify.design/lucide/images.svg?color=%230F766E" width="24" height="24" alt="" /> Screenshots

<p align="center">
<img src="https://raw.githubusercontent.com/identixia-IDV/identixia-assets/main/screenshots/document-reader/desktop/demo-ui-status.png" width="720" alt="Document result status" />
</p>
<p align="center">
<img src="https://raw.githubusercontent.com/identixia-IDV/identixia-assets/main/screenshots/document-reader/desktop/demo-ui-fields-code.png" width="420" alt="CODE fields" />
<img src="https://raw.githubusercontent.com/identixia-IDV/identixia-assets/main/screenshots/document-reader/desktop/demo-ui-fields-visual.png" width="420" alt="VISUAL fields" />
</p>

## <img src="https://api.iconify.design/lucide/braces.svg?color=%230F766E" width="24" height="24" alt="" /> API

The following SDK methods are used by the sample and can also be called from your application.

| API | Purpose |
| --- | --- |
| `activate(license)` then `init()` | Activate the license, then initialize the engine. Run these calls in order on one background thread. |
| Camera | Live capture from the sample Home screen. |
| Gallery | Still image of a passport, national ID, or driver license. |
| Document liveness | Presentation-attack result when the license includes it. |
| OCR / MRZ | Not included. Use the document recognition product for fields. |

---

## <img src="https://api.iconify.design/lucide/layers.svg?color=%230F766E" width="24" height="24" alt="" /> SDKs for other platforms

| | Platform | Repo |
| --- | --- | --- |
| <img src="https://cdn.simpleicons.org/android/3DDC84" width="18" height="18" alt="" /> | Android | [ID-Document-Liveness-Detection-Android](https://github.com/identixia-IDV/ID-Document-Liveness-Detection-Android) |
| <img src="https://cdn.simpleicons.org/apple/000000" width="18" height="18" alt="" /> | iOS | [ID-Document-Liveness-Detection-iOS](https://github.com/identixia-IDV/ID-Document-Liveness-Detection-iOS) |
| <img src="https://cdn.simpleicons.org/flutter/02569B" width="18" height="18" alt="" /> | Flutter | [ID-Document-Liveness-Detection-Flutter](https://github.com/identixia-IDV/ID-Document-Liveness-Detection-Flutter) |
| <img src="https://cdn.simpleicons.org/react/61DAFB" width="18" height="18" alt="" /> | React Native | [ID-Document-Liveness-Detection-React-Native](https://github.com/identixia-IDV/ID-Document-Liveness-Detection-React-Native) |
| <img src="https://cdn.simpleicons.org/ionic/3880FF" width="18" height="18" alt="" /> | Ionic Capacitor | [ID-Document-Liveness-Detection-Ionic-Capacitor](https://github.com/identixia-IDV/ID-Document-Liveness-Detection-Ionic-Capacitor) |
| <img src="https://cdn.simpleicons.org/apachecordova/E8E8E8" width="18" height="18" alt="" /> | Ionic Cordova | [ID-Document-Liveness-Detection-Ionic-Cordova](https://github.com/identixia-IDV/ID-Document-Liveness-Detection-Ionic-Cordova) |
| <img src="https://cdn.simpleicons.org/windows/0078D4" width="18" height="18" alt="" /> | Windows | [ID-Document-Liveness-Detection-Windows](https://github.com/identixia-IDV/ID-Document-Liveness-Detection-Windows) |
| <img src="https://cdn.simpleicons.org/docker/2496ED" width="18" height="18" alt="" /> | Linux / Docker | [ID-Document-Liveness-Detection-Docker](https://github.com/identixia-IDV/ID-Document-Liveness-Detection-Docker) |

---

## <img src="https://api.iconify.design/lucide/mail.svg?color=%230F766E" width="24" height="24" alt="" /> Contact

<div align="center">

<a href="mailto:contact@identixia.com"><img alt="Email contact@identixia.com" src="https://img.shields.io/badge/Email-contact%40identixia.com-0F766E?style=for-the-badge&logo=gmail&logoColor=white" /></a>
<a href="https://wa.me/17018854218"><img alt="WhatsApp +1 (701) 885-4218" src="https://img.shields.io/badge/WhatsApp-%2B1_(701)_885--4218-25D366?style=for-the-badge&logo=whatsapp&logoColor=white" /></a>
<a href="https://t.me/identixia"><img alt="Telegram @identixia" src="https://img.shields.io/badge/Telegram-%40identixia-26A5E4?style=for-the-badge&logo=telegram&logoColor=white" /></a>

</div>

---
