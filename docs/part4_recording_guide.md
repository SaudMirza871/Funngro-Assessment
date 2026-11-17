# Part 4 – Screen Recording & Interview Presentation Guide

**Target Duration:** 4:30 – 5:00 Minutes  
**Tone:** Confident, collaborative, senior engineering walkthrough  
**Audience:** Technical Hiring Manager & Lead Mobile Engineer  

---

## Recording Script & Step-by-Step Walkthrough

```
[0:00 - 0:45] Intro & Projects Screen Overview
[0:45 - 1:45] Infinite Scrolling, Pagination & End-of-List
[1:45 - 2:30] Simulated Failure, Error Handling & Granular Retry
[2:30 - 3:30] Earnings Screen Review & The #1 Critical Bug Fixed
[3:30 - 4:15] Key Architectural Decision
[4:15 - 5:00] Thoughtful Question for the Interviewer & Wrap-up
```

---

### [0:00 – 0:45] Introduction & Projects Screen Overview
> *"Hello! Today I'm excited to walk you through my implementation of the Funngro Mobile Engineer assessment. I've structured the application using a clean, feature-driven architecture that prioritizes predictable state management, memory safety, and 60 FPS performance.*
>
> *Starting here on the **Projects Screen**, we have a modern Material 3 interface designed for young freelancers. The app bar displays 'Projects', and cards clearly present the company, project title, and guaranteed payout in Indian Rupees. Notice the subtle elevation, rounded borders, and responsive badge chips. I've implemented pull-to-refresh right at the top, which resets our pagination state and fetches a fresh Page 0."*

### [0:45 – 1:45] Infinite Scrolling, Pagination & End of List
> *(Action: Smoothly scroll down the list of projects)*
>
> *"Let's look at the pagination behavior. The fake API provides 20 projects per page across Pages 0 through 7, totaling 160 projects. As my scroll controller nears the bottom threshold—around 200 pixels from the edge—it triggers `fetchNextPage()` automatically.*
>
> *Notice that while the next page loads, we don't lock the entire screen with a blocking dialog. Instead, a dedicated pagination progress indicator renders smoothly at the bottom of the list. We keep scrolling seamlessly past page 1, 2, 3... and once we cross page 7, page 8 correctly returns an empty response. The controller detects this, terminates subsequent scroll fetches to save network bandwidth, and displays our clean 'You've reached the end of projects' footer banner."*

### [1:45 – 2:30] Error Handling, Resilience & Granular Retry
> *(Action: Scroll or refresh until a 1-in-5 simulated network failure occurs, or trigger retry button)*
>
> *"A crucial requirement was handling network instability. Our fake API simulates real-world mobile conditions with a 900ms latency and a 1-in-5 random failure rate.*
>
> *Look at what happens when a page fails: our previously loaded items are **never wiped out**. If Page 2 fails, Pages 0 and 1 remain completely intact and interactive. At the bottom, our pagination footer gracefully swaps into an error state displaying 'Failed to load more projects' with a direct 'Tap to retry' button.*
>
> *When I tap **Retry**, the controller does not blow away the list and restart from scratch. It specifically re-requests the failed page index, appends it upon success, and deduplicates IDs using a Set to guarantee zero duplicate keys."*

### [2:30 – 3:30] Earnings Screen Review & The #1 Critical Bug Fixed
> *(Action: Tap bottom navigation to switch to the Earnings tab)*
>
> *"Now let's switch to the **Earnings Screen** for Part 1. In my architectural review document, I analyzed the common failure modes in legacy earnings screens. The most severe issue identified was an **uncancelled `StreamSubscription` causing memory leaks and OOM crashes**.*
>
> *In naive implementations, developers subscribe to transaction streams in `initState()` or even inside `build()`, but fail to cancel the subscription in `dispose()`. Every time a user navigates between Projects and Earnings, an orphaned listener remains in memory, holding onto context and child elements. On lower-end devices, this causes battery drain, UI lag, and inevitable crashes.*
>
> *In this rewrite, the subscription lifecycle is strictly managed: cancelled in `dispose()`, guarded against duplicate subscriptions, and the UI uses `ListView.builder` so that even with 3,000+ transaction records, memory consumption remains flat and scrolling stays buttery smooth."*

### [3:30 – 4:15] Key Technical Decision: Built-in State Management vs. Third-Party Bloat
> *"One deliberate technical decision I made was relying on Flutter's built-in `ChangeNotifier` with `ListenableBuilder` rather than pulling in external heavy dependencies like GetX or complex Bloc boilerplate.*
>
> *For a take-home assessment of this scope, `ChangeNotifier` is part of the Flutter core SDK, offers zero breaking changes across framework upgrades, produces minimal binary size, and provides complete testability. Our `ProjectsController` has no coupling to the UI layer and can be unit tested in pure Dart with 100% determinism."*

### [4:15 – 5:00] Questions for the Team & Wrap-Up
> *"To wrap up, working on this assessment raised an interesting engineering trade-off that I’d love to ask the Funngro engineering team about during our technical discussion:*
>
> *'In the real Funngro production app, when dealing with real-time financial earnings where teens receive payouts and complete milestones while browsing gigs, **what is your team's strategy around offline ledger synchronization and optimistic balance updates**—do you maintain a local encrypted Drift/Isar database with bi-directional sync, or rely purely on server-authoritative WebSockets/SSE?'*
>
> *Thank you for your time, and I look forward to walking through the codebase in our live session!"*
