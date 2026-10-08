# Mobile Performance Validation

This document outlines the findings and prioritized fixes from the mobile performance inspection of the Hesably MVP, focusing specifically on mid/low-spec Android devices.

## Executive Summary

The Hesably mobile application follows a solid baseline architecture utilizing BLoC and GoRouter. However, several critical performance and memory issues exist in the current implementation—particularly around image capture and memory handling—that will likely cause Out-Of-Memory (OOM) crashes and sluggishness on low-end Android devices.

## Validation Findings

### 1. Image Memory Handling (CRITICAL)
- **Finding:** `capture_screen.dart` uses `Image.file(File(state.localPath!))` to display the captured receipt without specifying `cacheWidth` or `cacheHeight`.
- **Impact:** Loading a full-resolution camera image (often 12MP+) directly into memory forces Flutter to decode the full uncompressed bitmap. On devices with 2GB-4GB RAM, this will reliably trigger an OOM crash.
- **Fix:** Provide `cacheWidth` (e.g., `cacheWidth: 800`) to `Image.file()` so the framework decodes a downscaled version.

### 2. Receipt Compression (CRITICAL)
- **Finding:** `ImagePicker.pickImage(source: source)` is called without parameters to restrict resolution or quality.
- **Impact:** Images uploaded to Supabase Storage and sent to Gemini are unnecessarily large (3MB-8MB). This violates the `< 1MB` rule mentioned in observability docs, exhausts user bandwidth, and drastically increases upload latency.
- **Fix:** Pass `imageQuality: 50` and `maxWidth: 1080` directly to `pickImage`, or utilize the already-installed `flutter_image_compress` package before dispatching the `CaptureReceiptImage` event.

### 3. Startup Time (HIGH)
- **Finding:** `main.dart` awaits `Supabase.initialize()` and `EasyLocalization.ensureInitialized()` before calling `runApp()`. 
- **Impact:** Network/IO operations block the first Flutter frame. Low-end Android devices will sit on a blank white screen (or static splash) longer than necessary.
- **Fix:** Defer non-critical initializations or ensure a proper native Android splash screen is configured in `android/app/src/main/res/drawable/launch_background.xml` to mask the initialization time.

### 4. Network-Failure UX (HIGH)
- **Finding:** Bloc error states map exceptions directly to the UI (e.g., `SnackBar(content: Text('Upload failed: ${state.error}'))`).
- **Impact:** Users will see raw technical errors like `SocketException` when offline.
- **Fix:** Map common exceptions to user-safe strings in the repository or BLoC layer (e.g., "Please check your connection and try again"), as required by the `observability-and-reliability.md` contract.

### 5. Upload Responsiveness & AI Loading UX (MEDIUM)
- **Finding:** The UI displays a basic `CircularProgressIndicator()` with "Processing receipt..." during the `UploadReceipt` bloc event.
- **Impact:** While it satisfies the "never a frozen screen" rule, a 10-15 second wait on a static spinner feels unresponsive. 
- **Fix:** Implement a more engaging shimmer or skeleton loader that better indicates AI extraction progress.

### 6. Realistic List Scrolling (MEDIUM)
- **Finding:** `transactions_page.dart` correctly uses `ListView.builder` for virtualization. However, it lacks an `itemExtent` or `prototypeItem`.
- **Impact:** Flutter must calculate the height of each item during layout, which can cause micro-stutters during fast scrolling on low-end CPUs.
- **Fix:** Since list items have a uniform height, specify `itemExtent` on the `ListView.builder` to bypass the expensive layout calculation phase.

### 7. Route Transitions (LOW)
- **Finding:** Default `GoRouter` transitions are used.
- **Impact:** Flutter's default `ZoomPageTransitionsBuilder` on Android is slightly heavier than standard fades.
- **Fix:** Override the page transitions theme to use `FadeUpwardsPageTransitionsBuilder` or `CupertinoPageTransitionsBuilder` if route animation jank is observed on low-end devices.

### 8. Unnecessary Rebuilds (PASS)
- **Finding:** State management via `BlocBuilder` and `BlocConsumer` is scoped correctly to local widgets rather than the entire `Scaffold`. Rebuilds are well-contained.

### 9. Excessive Animations (PASS)
- **Finding:** The app currently avoids heavy or unnecessary animations, which is ideal for the target demographic.

### 10. Report Query Responsiveness (PASS/MONITOR)
- **Finding:** `ReportsBloc` delegates to `_reportRepository.getReportSummary`.
- **Impact:** Client-side architecture is correct. Responsiveness entirely depends on backend indexing of the `transactions` table (specifically covering `business_id`, `date`, and `type`).

## Prioritized Action Plan

1. **Sprint Task:** Add `imageQuality` and `maxWidth` to `ImagePicker`. (5 minutes)
2. **Sprint Task:** Add `cacheWidth` to all `Image.file` and `Image.network` usages. (5 minutes)
3. **Sprint Task:** Map network exceptions to localized user-safe strings in `ReceiptCaptureBloc`. (15 minutes)
4. **Sprint Task:** Add `itemExtent` to `ListView.builder` in `TransactionsPage`. (5 minutes)
5. **Backlog:** Improve the AI Loading UX with a shimmer effect.
6. **Backlog:** Audit and configure the Android native splash screen.
