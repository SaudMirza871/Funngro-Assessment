# Part 3 – Production Incident Analysis & Response Plan

**To:** Executive Leadership / Founders  
**From:** Senior Mobile Engineer  
**Date:** November 17, 2026  
**Subject:** High-Severity Incident Response: Ad SDK `PlatformException` During 20% Staged Rollout  
**Status:** **Rollout Halted** | Investigation & Mitigation Active  

---

## 1. Executive Summary & Immediate Decision

### Rollout Decision: **HALT THE ROLLOUT IMMEDIATELY**

* **Rationale:** A drop from **99.6% to 98.1%** in crash-free sessions represents a **1.5% absolute increase in user-facing crashes** across our active cohort. In an active user base of 100,000 daily active users, this translates to over 1,500 users experiencing hard crashes daily. Because this occurs when returning from the background (a core interaction pattern for freelance teen gig workers multitasking between social media and our app), allowing the rollout to advance or holding at 20% would compromise user trust, harm app store ratings, and increase churn.
* **Why not "Fix Forward"?** A fix-forward strategy (pushing a new binary release to App Store / Google Play review) incurs a 24–48 hour lead time for review, indexing, and user adoption. We must stop user exposure immediately through server-side controls before patching client code.

---

## 2. Immediate Containment Actions (First 15 Minutes)

1. **Halt Rollout:**
   - **Google Play Console:** Navigate to *Release Overview* → *Production Track* → Click **Halt Rollout** at 20%.
   - **Apple App Store Connect:** Select *Phased Release* → Click **Pause Phased Release**.
2. **Kill-Switch via Remote Config / Feature Flags:**
   - Immediately set `ads_sdk_enabled = false` and `interstitial_on_resume_enabled = false` in Firebase Remote Config / LaunchDarkly.
   - Publish the Remote Config change with high fetch priority to disable the ad SDK initialization and lifecycle hooks for active clients without requiring an app update.
3. **Internal Stakeholder Communication:**
   - Post an incident broadcast to `#incident-sev-1` with current crash statistics, confirmation of the rollout halt, and link to the live war-room dashboard.
   - Notify Customer Support with canned responses acknowledging the issue and advising users that the fix is in effect.

---

## 3. Systematic Step-by-Step Technical Investigation Plan

We will investigate the crash rigorously without declaring assumptions as proven facts until validated with crash logs, stack traces, and deterministic reproduction.

```
+---------------------------------------------------------------------------------------------------+
|                                 INCIDENT INVESTIGATION WORKFLOW                                   |
+-------------------+--------------------+-----------------------+----------------------------------+
| 1. Crash Triage   | 2. Lifecycle Audit | 3. Lab Reproduction   | 4. Mitigation & Patch Validation |
| (Crashlytics, OS, | (Activity/VC state,| (Simulate process     | (Remote Config kill-switch,      |
| device breakdown) | platform channels) | death & resumption)   | unit/integration test suite)     |
+-------------------+--------------------+-----------------------+----------------------------------+
```

### Step 1: Crash Analytics & Cohort Identification
* **Data Sources:** Firebase Crashlytics, Google Play Vitals, Apple Xcode Organizer.
* **Metrics to Isolate:**
  - **App Versions:** Verify if the crash strictly isolates to Version `v2.4.0` (20% rollout) or also impacts legacy versions with refreshed remote ad payloads.
  - **OS & Platform Split:** Determine if the `PlatformException` is exclusive to Android (e.g., Activity destruction, `null` Activity reference in `MethodCallHandler`) or iOS (e.g., key window deallocation, UIKit threading violation).
  - **Device & OEM Characteristics:** Check for heavy concentration on specific Android OEMs (e.g., Xiaomi MIUI, Samsung OneUI) known for aggressive background RAM compression and process kills.

### Step 2: App Lifecycle & Ad SDK Callback Audit
* **Root Hypothesis:** When the application transitions from background to foreground, the Flutter engine resumes execution (`AppLifecycleState.resumed`). If an ad unit was requested prior to backgrounding or is configured to display on resume:
  1. The host native Android Activity or iOS ViewController may have been destroyed or detached while in the background.
  2. The Ad SDK's native completion callback attempts to invoke `result.success()` or `result.error()` over a detached Flutter platform channel binary messenger, throwing an unhandled `PlatformException`.
  3. The ad SDK attempts to display a fullscreen overlay before the Flutter surface texture is fully restored.
* **Code Review Focus:**
  - Audit the Flutter plugin's `MethodChannel` handler. Check for missing `try/catch (e)` blocks around `MethodChannel.invokeMethod('showAd')`.
  - Check whether `WidgetsBindingObserver.didChangeAppLifecycleState` invokes ad SDK methods without checking if the native view hierarchy is attached.

### Step 3: Deterministic Local Reproduction
* **Reproduction Protocol:**
  1. Configure a test device (both Android 14+ and iOS 17+) running the release build of the 20% release.
  2. Enable "Don't keep activities" under Android Developer Options to simulate low-memory process kills.
  3. Launch the app, trigger an ad preload, navigate out to the home screen (sending the app to background for >30 seconds), and reopen.
  4. Capture device system logs via `adb logcat -v time` and macOS Console (for iOS syslog) to record the exact exception stack trace.

### Step 4: Patch Implementation & Defensive Architecture
Once the specific failing channel call is isolated, apply defensive engineering:
1. **Wrap Platform Channel Invocations:**
   ```dart
   try {
     if (isAdSdkEnabled && isNativeViewAttached) {
       await _adChannel.invokeMethod('showResumeAd');
     }
   } on PlatformException catch (e, stackTrace) {
     _logger.e('Ad SDK failed to display on resume', error: e, stackTrace: stackTrace);
     // Non-fatal logging to Firebase Crashlytics; NEVER crash the user app
     FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
   }
   ```
2. **Native Lifecycle Synchronization:**
   - In the Android plugin (`FlutterPlugin` / `ActivityAware`), verify that `activity != null && !activity.isFinishing && !activity.isDestroyed` before attempting to present ad views.

---

## 4. Fix Validation & Rollout Resumption Criteria

### Pre-Release Validation Checklist
- [ ] **Deterministic Verification:** Tested in local lab with "Don't keep activities" and background/foreground toggles across 50 consecutive cycles with 0 crashes.
- [ ] **Unit & Regression Tests:** Added automated tests verifying that `PlatformException` thrown by the ad channel is cleanly caught and handled as a non-fatal event.
- [ ] **Internal Dogfooding:** 24-hour internal alpha build distributed to 50+ internal team members across Android and iOS devices.
- [ ] **Remote Config Guardrail:** Verified that toggling `ads_sdk_enabled` dynamically disables and enables the ad subsystem without requiring restart.

### Criteria for Resuming Production Rollout
1. Crash-free user rate on the newly patched build (`v2.4.1`) must remain **>= 99.8%** across the internal and staging cohorts.
2. Resume rollout in controlled, gradual stages:
   - **Stage 1:** 5% rollout for 24 hours. Monitor real-time Crashlytics telemetry closely.
   - **Stage 2:** 20% rollout for 24 hours (benchmark against previous failing threshold).
   - **Stage 3:** 50% rollout for 24 hours.
   - **Stage 4:** 100% full release once stability is confirmed.
3. Conduct a post-mortem within 48 hours to document lessons learned and update our CI pipeline tests.
