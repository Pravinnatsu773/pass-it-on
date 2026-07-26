# Pass It On ♻️

A local community marketplace app designed to help you give away items to people nearby. 
This project features **Local AI on-device generation** to instantly auto-complete product listings (descriptions and categories) using a Google Gemma model running entirely locally via MediaPipe.

## Features ✨
* **Local On-Device AI:** Uses a compressed Gemma Large Language Model (`gemma3-1B-it-int4.task`) running completely offline on your phone via MediaPipe to generate listing details.
* **Firebase Authentication:** Secure email/password and social login.
* **Cloud Firestore:** Real-time database for product listings and user profiles.
* **Location Services:** Google Maps and Geocoding integration for local item discovery.
* **Modern UI:** Clean, intuitive UI built with standard Flutter Material design.

## Prerequisites 📋
* Flutter SDK (3.19 or higher)
* Android Studio / Android SDK (Target SDK 34+)
* A Firebase Project

## How to Run 🚀

### 1. Firebase Setup (Required)
This project uses Firebase for backend services. You **must** provide your own Firebase configuration file to run the app.
1. Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project.
2. Add an Android app to your Firebase project with the package name `com.example.pass_it_on`.
3. Download the `google-services.json` file.
4. Place the `google-services.json` file in your local project directory at:
   ```
   android/app/google-services.json
   ```
*(Note: If you plan to run on iOS, you will similarly need to generate and add a `GoogleService-Info.plist` file via Xcode).*

### 2. Install Dependencies
Run the following command in the root of the project to install all Flutter packages:
```bash
flutter pub get
```

### 3. Build and Run
Connect a physical Android device or start an Android Emulator, then run:
```bash
flutter run
```

### ⚡ Running in Release Mode (Recommended for AI)
Running Large Language Models on-device is heavily resource-intensive. Debug mode in Flutter carries significant performance overhead. To experience the AI auto-complete at true speed, you should build the app in release mode:
```bash
flutter run --release
```
*Note: Release mode obfuscates code via R8. We have already configured `proguard-rules.pro` to keep MediaPipe dependencies intact.*

## Important Note on Local AI 🧠
The app uses a custom `ModelDownloadService` to fetch the Gemma AI model (`.task` file) from Google Drive on the first launch. 
* The model size is roughly **~1.2 GB**. 
* The download will happen automatically in the background when you visit the profile setup or product listing page.
* Due to the heavy nature of local LLMs, running the app on older devices or emulators with less than 4GB of RAM may result in out-of-memory (OOM) crashes.
