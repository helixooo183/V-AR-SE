# Pixel Canvas

A layer-based graphic editor for Android (and iOS, once platform folders are
added). Build posters, quotes and social posts by stacking text, photos and
stickers on a canvas.

## Features

**Canvas**
- Aspect presets: 1:1, 4:5, 16:9, 9:16, 3:4, and custom pixel size (256–4096 px).
- Changing the size keeps the layout proportional.
- Background: solid colour, two-colour gradient with angle, photo from the
  gallery, or transparent (checkerboard in the editor, transparent PNG on export).

**Layers**
- Everything is a layer: text, image, sticker.
- Tap to select (blue frame with corner handles). Drag to move, pinch to scale,
  two fingers to rotate. The point under your fingers stays under them.
- Layer manager (bottom sheet): drag to reorder, eye to hide, lock to freeze,
  bin to delete.
- Bring forward / send backward / duplicate / delete from the selection bar.
- Locked and hidden layers cannot be selected on the canvas, so taps pass
  through them.

**Text**
- Unlimited text layers. Double-tap a text layer to edit it.
- 11 bundled font families (OFL licensed, work offline), plus the system font.
- Size, letter spacing, line height, bold, italic, UPPERCASE, alignment.
- Fill colour, outline (width and colour), shadow (blur and colour),
  background box, and per-layer opacity.

**Undo / redo**
- Whole-document snapshots, up to 100 steps.
- A drag, pinch, or slider session is one undo step.

**Export**
- Saves a full-resolution PNG to the gallery album "Pixel Canvas".

## Project layout

```
lib/
  model/       Immutable data: layers, text style, background, document, fonts
  engine/      Text measurement and hit testing (shared by render and input)
  state/       EditorController: selection, history, all document edits
  services/    Gallery import and PNG export
  ui/          Start screen, editor page, canvas stage, bottom sheets, widgets
test/          Unit tests for the controller, hit testing and text measurement
assets/fonts/  Bundled OFL fonts, with licence texts in assets/fonts/licenses/
```

The core rule: the canvas is laid out in **canvas units** (the exported pixel
size) and scaled to the screen with a `FittedBox`. Rendering, gestures and
export therefore agree exactly, and text looks the same at every zoom.

## Running it

Requirements: Flutter stable 3.41 or newer, JDK 17, Android SDK.

```bash
flutter create --platforms=android --org com.viapixel --project-name pixel_canvas .
flutter pub get
flutter run
```

`flutter create .` adds the `android/` folder without touching `lib/`,
`test/` or `pubspec.yaml`. If it adds `test/widget_test.dart`, delete that
file; the project's tests live in `test/*_test.dart`.

Commit the generated `pubspec.lock` once you have run `flutter pub get`.

### Tests and checks

```bash
flutter analyze
flutter test
```

GitHub Actions runs analyze, tests and a release APK build on every push
(see `.github/workflows/flutter.yml`). It also downloads the APK as an artifact.

### Before a Play Store release

- Set the launcher label in `android/app/src/main/AndroidManifest.xml`
  (`android:label="Pixel Canvas"`).
- Create an upload key and configure `android/app/build.gradle` signing.
  Keep the keystore out of git (`.gitignore` already excludes `*.jks`).
- Set a real `applicationId` (currently `com.viapixel.pixel_canvas`).

## Not built yet

These are planned, but not in this version:

- Saving and reopening projects (designs currently live only while the app is open).
- Free-hand drawing layers and brush tools.
- A PNG sticker library (stickers are emoji for now).
- Text on a path or curved text, and per-character styling.
- Filters, blend modes, masks and erasers.
