# visorroute

Flutter app for VisorRoute — supervisor/student field routing, backed by the `visorroute-backend` API.

## HERE SDK setup

The HERE SDK for Flutter (Navigate/Explore Edition) is a licensed, proprietary
plugin — not distributed via pub.dev, Maven, or CocoaPods. It has to be
downloaded by hand from the HERE Developer Portal and unzipped locally by
every machine that builds this app (it's gitignored — `plugins/here_sdk/` and
`heresdk-*/`, since the unzipped package is ~1GB and isn't ours to
redistribute).

1. Log into the HERE Developer Portal with this project's account and
   download the Flutter Explore/Navigate Edition SDK package
   (`heresdk-explore-flutter-<version>.zip` or similar).
2. Unzip it. Inside, find the actual plugin tarball —
   `heresdk-explore-flutter-<version>.tar.gz` (or `here_sdk-<edition>-<version>.release.tar.gz`
   depending on the release) — and unzip *that* into `plugins/here_sdk/`, so
   `plugins/here_sdk/pubspec.yaml` exists directly (not nested another folder deep).
3. **Delete the bundled `plugins/here_sdk/.dart_tool/` and `pubspec.lock` if
   present.** HERE ships these pre-generated from their own build machine
   (referencing a `/home/bldadmin/...` path that doesn't exist anywhere else)
   and they shadow this project's own package resolution, producing spurious
   `package:meta`/`package:ffi`/`package:intl` unresolved-import errors that
   have nothing to do with this app.
4. **Fix `plugins/here_sdk/android/build.gradle`:** it ships referencing the
   defunct `jcenter()` repository (shut down in 2021), which fails outright
   under this project's Gradle 9.1.0/AGP 8.11.1. Replace both `jcenter()`
   occurrences with `mavenCentral()`.
5. Uncomment the `here_sdk: path: plugins/here_sdk` dependency in
   `pubspec.yaml` (it's usually already left uncommented once someone's done
   this once — check first) and run `flutter pub get`.
6. `flutter build apk --debug` and `flutter build ios --simulator --debug`
   should both succeed clean. If disk space is tight, `build/` (Flutter's own
   output) and `~/Library/Developer/Xcode/DerivedData` are both safe to
   delete — they regenerate automatically.

Native Android (`compileSdk`/`minSdk`/`targetSdk`/`ndkVersion`) and iOS
(Impeller workaround, deployment target) config for the SDK are already
committed and don't need repeating.
