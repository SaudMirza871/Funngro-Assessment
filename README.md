# Funngro Mobile Engineer Take-Home Assessment

A production-grade, high-performance Flutter mobile application engineered for teen freelance opportunities and wallet management. Built with Material 3, clean architecture, and strict memory and lifecycle safety.

---

## 📱 Project Overview

The **Funngro Assessment** mobile application delivers two core capabilities tailored for young creators:
1. **Projects Marketplace:** Infinite-scroll paginated catalog of 160 freelance opportunities with search, category filtering, resilient error recovery, and granular retry.
2. **Earnings & Wallet Ledger:** High-throughput virtualized financial ledger rendering 3,000+ transaction entries at 60 FPS, complete with lifecycle-safe real-time stream subscription handling and withdrawal flows.

---

## ✨ Features

### Part 1: Production Earnings Screen & Architecture Rewrite
* **Virtualization for Scale:** Utilizes `SliverList.builder` to smoothly render 3,000+ ledger entries without frame drops or memory inflation.
* **Lifecycle-Safe Stream Management:** Broadcast stream listener strictly managed, guarded against duplicate subscriptions, and guaranteed to cancel on `dispose()`.
* **State Coverage:** Complete coverage of `Loading`, `Error` (with retry), `Empty`, and `Success` UI states.
* **Wallet Mutations:** Interactive modal bottom sheet for instant fund withdrawals with validation against live balance.

### Part 2: Projects List with Resilient Infinite Pagination
* **Fake API Specification:**
  - 20 projects per page across Pages 0 to 7 (160 total projects).
  - Page 8 returns an empty list (`[]`).
  - 900ms simulated latency with ~1-in-5 random network timeouts.
  - Every project includes `id`, `title`, `company`, and `payout`.
* **Resilient Pagination Engine:**
  - Initial loading indicator and pull-to-refresh (resets to Page 0).
  - Infinite scroll listener triggers next page when within 250px of list bottom.
  - Dedicated bottom pagination loading spinner.
  - **Granular Error Recovery:** When a page fails, previously loaded items are **preserved**; a bottom retry banner re-requests specifically the failed page index without restarting the entire list.
  - **Concurrency & Duplicate Guard:** Locks prevent duplicate simultaneous requests, and a unique `Set<String>` prevents duplicate keys.
  - Clean end-of-list banner upon reaching the 160th project.

---

## 📂 Folder Structure

The project follows a clean, feature-driven structure:

```
lib/
├── main.dart                               # Application bootstrap & bottom NavigationBar
│
├── core/
│   ├── theme/
│   │   └── app_theme.dart                  # Material 3 colors, typography, card & chip themes
│   └── utils/
│       ├── constants.dart                  # Categories, filter definitions, and app constants
│       └── formatters.dart                 # Currency (₹ INR), date, and relative time formatters
│
├── models/
│   ├── project.dart                        # Project entity (id, title, company, payout) + JSON mapping
│   └── earning.dart                        # Earning summary and transaction models
│
├── services/
│   ├── projects_api.dart                   # Fake paginated API with failure rate & latency
│   └── earnings_api.dart                   # High-volume mock ledger (3,000+ items) with live stream
│
├── features/
│   ├── projects/
│   │   ├── controllers/
│   │   │   └── projects_controller.dart    # Infinite scroll pagination, search, and retry state
│   │   ├── screens/
│   │   │   └── projects_screen.dart        # Virtualized sliver view with pull-to-refresh
│   │   └── widgets/
│   │       ├── pagination_indicator.dart   # Bottom spinner, retry action, and end-of-list banner
│   │       ├── project_card.dart           # Project card with payout, company, and tags
│   │       └── project_details_modal.dart  # Bottom sheet with project description and Apply CTA
│   │
│   └── earnings/
│       ├── controllers/
│       │   └── earnings_controller.dart    # StreamSubscription lifecycle & filter logic
│       ├── screens/
│       │   └── earnings_screen.dart        # Virtualized earnings ledger with wallet overview
│       └── widgets/
│           ├── transaction_tile.dart       # Virtualized transaction item
│           ├── wallet_card.dart            # Gradient balance card with withdraw action
│           └── withdraw_modal.dart         # Validated withdrawal form
│
└── widgets/
    ├── custom_search_bar.dart              # Debounced text search bar
    ├── empty_view.dart                     # Reusable error & empty state display
    ├── stat_card.dart                      # Metrics card
    └── status_chip.dart                    # Status indicators for projects and transactions
```

---

## 🛠️ Setup Instructions

### Prerequisites
* Flutter SDK (3.24+ recommended, tested on 3.41.0 / Dart 3.11)
* Android Studio / Xcode for simulator/device deployment

### Installation
1. Clone the repository and navigate to the project directory:
   ```bash
   cd /path/to/funngro_assessment
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

---

## 🚀 Run Commands

### Running the App
* Launch on an attached device or simulator:
  ```bash
  flutter run
  ```
* Launch specifically on Chrome (web):
  ```bash
  flutter run -d chrome
  ```
* Launch on macOS desktop:
  ```bash
  flutter run -d macos
  ```

---

## 🧪 Test Commands

Comprehensive unit and widget tests are included under the `test/` directory.

Run the test suite:
```bash
flutter test
```

Run static analysis:
```bash
dart analyze
```

Format all Dart source files:
```bash
dart format .
```

---

## 🏛️ Architecture & Engineering Decisions

### 1. State Management: Native `ChangeNotifier` + `ListenableBuilder`
* **Decision:** We opted for Flutter's first-party `ChangeNotifier` paired with `ListenableBuilder` instead of adding large external packages (Bloc, GetX, or Riverpod).
* **Rationale:**
  - Zero third-party dependency vulnerabilities or breaking changes across Flutter SDK upgrades.
  - Predictable unidirectional data flow and clean separation of concerns.
  - Controllers contain zero UI dependencies and are 100% unit-testable in pure Dart.

### 2. StreamSubscription Lifecycle Safety
* **Decision:** Streams are explicitly managed within controller lifecycles.
* **Rationale:**
  - Before subscribing to a new stream, any active subscription is cancelled.
  - All subscriptions are cancelled in `dispose()`.
  - Guarantees zero memory leaks, eliminates duplicate listeners, and avoids `setState()` after dispose.

### 3. High-Performance Virtualization (3,000+ Items)
* **Decision:** Both Projects and Earnings screens use `CustomScrollView` with `SliverList.builder`.
* **Rationale:** Eager instantiation via `SingleChildScrollView` + `Column` causes severe jank and OOM on 3,000+ items. Slivers ensure only visible items within the viewport cache are allocated.

### 4. Resilient Pagination Algorithm
* **Decision:** A two-phase error model separates the initial page 0 failure (`errorMessage`) from subsequent page failures (`paginationErrorMessage`).
* **Rationale:** Prevents catastrophic data wiping when a user is on page 4 and page 5 experiences a network timeout. The user retains all loaded content, and the footer exposes a targeted retry for page 5.

---

## 📄 Assessment Documentation

Detailed technical documents are included under `docs/`:

1. [docs/part1_review.md](file:///Users/saud/StudioProjects/funngro_assessment/docs/part1_review.md): Audit of bugs in legacy Earnings screens ranked by severity, technical root causes, fixes, and guardrails for 60+ screen codebases.
2. [docs/part3_incident_analysis.md](file:///Users/saud/StudioProjects/funngro_assessment/docs/part3_incident_analysis.md): Executive founder-facing incident response plan for a production ad SDK `PlatformException` during a staged rollout.
3. [docs/part4_recording_guide.md](file:///Users/saud/StudioProjects/funngro_assessment/docs/part4_recording_guide.md): 5-minute screen recording script with walkthrough directions and thoughtful architectural questions.

---

## ⚖️ Known Assumptions & Limitations

* **Simulated Network Latency:** Network calls intentionally sleep for 900ms (projects) and 600ms (earnings) to demonstrate loading animations and pagination transitions. In unit tests, `simulatedLatency` is set to `Duration.zero`.
* **Random 1-in-5 Failure Rate:** The Projects API introduces a 20% random failure rate to showcase the resilience and retry mechanisms. This is disabled during automated unit test suites for determinism.
