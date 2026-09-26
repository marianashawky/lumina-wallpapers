# Lumina

Wallpaper app for stills, motion, and video. Categories include Live, Anime, Nature, Cars, Gaming, Space, Abstract, Minimal, Technology, and Dark.

No account. Favorites, settings, and search history stay on the device with `shared_preferences`.

## Run on Android

```bat
set PATH=C:\Users\marin\flutter\bin;%PATH%
flutter pub get
flutter run
```

Release APK:

```bat
flutter build apk --release
```

Before publishing, put your release keystore in `android/key.properties` and your AdMob app id in `android/local.properties` as `admob.app.id`. Production ad unit IDs are compile-time defines: `ADMOB_BANNER_ID`, `ADMOB_INTERSTITIAL_ID`, and `ADMOB_REWARDED_ID`. Placements stay off until those flags are enabled in `AdConfig`.
