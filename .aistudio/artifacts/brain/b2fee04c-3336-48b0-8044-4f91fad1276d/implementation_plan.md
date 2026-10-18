# Vyshu AI — Autonomous On-Device Agent & Decoupled Brain Upgrade

Upgrade **Vyshu-Ai** into an autonomous on-device Android AI agent powered by her own decoupled **VyshuBrain**, swappable **LLMProvider** layer, real-time **Observe → Plan → Act → Verify** accessibility loop, zero-key rule router, strict safety guardrails, sub-agent dispatch hooks, and live task execution telemetry.

---

## User Review & Critical Decisions

> [!IMPORTANT]
> The following architectural and UX choices incorporate your confirmed selections and preserve all existing features (chat, 5-tab layout, local memory, key vault, and GitHub Actions APK pipeline).

- **Confirmed Decision 1 (Wake-Word & Always-On Loop)**: Uses an **Android Native `SpeechRecognizer` Continuous Wake Loop** inside a foreground service with zero paid keys required, while providing an extensible hook for Picovoice Porcupine if a key is added later.
- **Confirmed Decision 2 (Live Task UI & Emergency STOP)**: Implements both an **Android System Overlay Window** (`TYPE_APPLICATION_OVERLAY` visible on top of external apps like YouTube or WhatsApp) with an instant hardware-level **STOP** button, plus an **In-App Live Task Drawer / HUD** inside the Flutter & Web interfaces.
- **Confirmed Decision 3 (Navigation Structure)**: Preserves your **5-tab navigation** (`Vyshu`, `3D Room`, `Athlete`, `Control`, `Vault`) while upgrading the `Vault` tab into a full Multi-Provider Pool & Priority Tester and adding the floating Live Task HUD across the app.
- **Package & Build Integrity**: Aligns `MainActivity.kt`, `VyshuAccessibilityService.kt`, and `AndroidManifest.xml` cleanly so GitHub Actions builds `Vyshu-AI-Primary.apk` and `Vyshu-Key-Vault.apk` on the first run.

---

## 1. Overview & Core Concept

- **What It Does**: Allows you to speak or type high-level goals (*"open YouTube and play lo-fi for 1 hour"*, *"message Ravi on WhatsApp I'm late"*, *"turn on torch"*). Vyshu classifies the intent: simple hardware/system actions execute immediately with zero LLM latency, while multi-step UI goals activate the autonomous **Observe → Plan → Act → Verify** loop that reads the live screen hierarchy, plans one validated JSON step at a time, performs gestures/intents, verifies screen transitions, and recovers from unexpected popups or errors.
- **Core Separation Principle**: **VyshuBrain** owns identity, persona, memory, routing, task planning, and safety validation. **LLMProviders** (Gemini, OpenAI-compatible endpoints like Groq/OpenRouter/Mistral, and OnDevice stubs) are strictly interchangeable reasoning engines underneath.
- **Zero-Key Resilience**: With zero API keys configured, Vyshu still operates via the rule-based `CommandRouter` for torch, volume, brightness, alarms, app launching, phone calls, and time queries, displaying a non-intrusive notice to add a key in the Vault for full multi-step reasoning.

---

## 2. User Experience & Visual Design

- **Key User Flows**:
  1. **Zero-Key / Direct Command Flow**: User says *"turn on flashlight"* or *"open Spotify"* → `CommandRouter` matches rule → executes immediately via native bridge → logs to `VYSHU_AGENT` and speaks confirmation.
  2. **Multi-Step Autonomous Goal Flow**: User says *"open YouTube and play lo-fi for 1 hour"* → `VyshuBrain` initiates an Agent Task → System Overlay Pill appears at the top of the screen showing the goal, current step (`Step 2/25: Tapping search bar`), and a high-contrast red **STOP** button → Agent observes compact UI tree, plans JSON action, acts, and verifies until `finish(summary)` or timed sub-agent handoff.
  3. **Safety Confirmation Gate**: Before executing any sensitive action (`send_whatsapp`, `call_contact`, settings modification, or deleting items), Vyshu pauses the loop and prompts for spoken (*"yes" / "confirm"*) or on-screen confirmation. Banking/UPI apps and password fields are strictly blocked and scrubbed.
  4. **Accessibility & Always-On Control Flow**: In the `Control` tab, tapping *"Tap to enable"* opens Android Accessibility Settings and polls `isServiceEnabled` on resume so connection status updates reliably in real time. Includes the Always-On Wake-Word Service toggle and battery optimization exemption trigger.

- **Visual Identity & Theme**:
  - *Aesthetic Direction*: Tactical Cyber-Executive HUD — high-contrast dark slate canvas (`#070914` / `#0A0F24`), crisp electric cyan primary accents (`#00CCFF`), semantic status indicators (emerald for working/active, amber for rate-limited/cooldown, coral red for emergency STOP and invalid states).
  - *Typography & Hierarchy*: Clean geometric sans display headers paired with tabular monospace (`JetBrains Mono` / `monospace` with `tabular-nums`) for step counters, cooldown timers, and live `VYSHU_AGENT` log streams.
  - *Touch & Thumb-Zone Ergonomics*: All primary controls, confirmation buttons, and the emergency **STOP** button maintain $\ge 48 \times 48\text{px}$ touch hitboxes positioned in natural reach zones, keeping fixed header/footer chrome under 15% of viewport height.

---

## 3. Key Product Decisions & Trade-Offs

- **Decision 1: Strict Decoupling of VyshuBrain from LLM Providers**
  - *Chosen Approach*: All LLM network calls are isolated inside `LLMProvider` implementations managed by `ProviderManager`. `VyshuBrain` injects her canonical persona, selects relevant memory context (short-term task state + 14-day Hive history + learned shortcuts), and enforces strict JSON schema validation on provider outputs.
  - *Why*: Ensures switching from Gemini to Groq, OpenRouter, or a local model never alters Vyshu's personality, safety rules, or memory.

- **Decision 2: Compact Screen Observation & Password Scrubbing**
  - *Chosen Approach*: `VyshuAccessibilityService` traverses `rootInActiveWindow` and filters nodes into a compact list of interactive/meaningful elements (`id`, `text`, `desc`, `bounds`, `clickable`, `editable`, `scrollable`) capped at top relevant nodes, while immediately redacting any node where `isPassword == true` or package matches known banking/UPI apps.
  - *Why*: Raw accessibility XML dumps exceed token limits, increase latency, and risk leaking sensitive screen text. Compact observation keeps free-tier token usage minimal and fast.

- **Decision 3: Dual-Surface Live Task UI (System Overlay + In-App Drawer)**
  - *Chosen Approach*: Native Android `WindowManager` overlay displays a compact floating HUD when Vyshu navigates outside the app (e.g. inside WhatsApp or YouTube), complemented by a rich expandable Live Task Drawer inside the Flutter and Web apps.
  - *Why*: When an agent opens another app, an in-app UI alone becomes hidden; a system overlay guarantees you can always see what step Vyshu is performing and hit **STOP** at any moment.

---

## 4. Technical Architecture & Data Strategy

### Architecture & Component Diagram

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│                         USER VOICE / TEXT / WAKE WORD                        │
└──────────────────────────────────────┬───────────────────────────────────────┘
                                       ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                        1. VYSHU BRAIN (CORE LAYER)                           │
│  ┌────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐  │
│  │   CommandRouter    │  │   Persona & Memory   │  │     SafetyGuard      │  │
│  │ (Rule vs Agent vs  │  │ (Hive 14d Chat, User │  │ (UPI/Password Block, │  │
│  │   Normal Chat)     │  │  Facts, Task Logs)   │  │  Risky Action Gate)  │  │
│  └─────────┬──────────┘  └──────────┬───────────┘  └──────────┬───────────┘  │
│            └────────────────────────┼─────────────────────────┘              │
│                                     ▼                                        │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │            AGENT LOOP (Observe → Plan → Act → Verify)                  │  │
│  │   Max 25 steps · 60s step timeout · 3x identical loop detector         │  │
│  └─────────┬──────────────────────────────────────────────────┬───────────┘  │
└────────────┼──────────────────────────────────────────────────┼──────────────┘
             │ Reasoning / JSON Plan                            │ Device Actions
             ▼                                                  ▼
┌─────────────────────────────────────────┐  ┌─────────────────────────────────┐
│     2. LLM PROVIDER LAYER               │  │   3. SKILLS / ACTION LIBRARY    │
│  ┌───────────────────────────────────┐  │  │  • launch_app, open_url         │
│  │         ProviderManager           │  │  │  • tap, type_text, scroll, swipe│
│  │ (Priority, Rotation, Cooldowns)   │  │  │  • back, home, recents, wait    │
│  └────┬────────────────┬─────────┬───┘  │  │  • read_screen, set_toggle      │
│       ▼                ▼         ▼      │  │  • set_alarm, call_contact      │
│  ┌──────────┐  ┌──────────────┐ ┌────┐  │  │  • send_whatsapp, search_in_app │
│  │  Gemini  │  │OpenAICompat  │ │OnDv│  │  │  • play_media, finish           │
│  │ Provider │  │(Groq/Router) │ │Stub│  │  │  • SubAgentDispatcher (Vaani..) │
│  └──────────┘  └──────────────┘ └────┘  │  └────────────────┬────────────────┘
└─────────────────────────────────────────┘                   │ MethodChannel
                                                              ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                 4. NATIVE ANDROID RUNTIME (com.vyshu.ai)                     │
│  • VyshuAccessibilityService (Compact Screen Dump, Gesture Dispatch, Node Tap│
│  • VyshuAgentForegroundService (Wake Word Loop, BootReceiver, WakeLock)      │
│  • VyshuOverlayHudManager (System Overlay Window + Instant Emergency STOP)   │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Data Model & State

1. **`LLMProvider` Interface & `ProviderManager`**:
   - Contract: `id`, `name`, `supportsVision`, `supportsJson`, `costTier`, `complete(prompt, systemPrompt, jsonSchema)`, `stream(...)`, `testKey(key)`.
   - Built-in providers: `GeminiProvider` (Gemini 2.5 Flash), `OpenAICompatibleProvider` (configurable base URL supporting Groq `https://api.groq.com/openai/v1`, OpenRouter, Mistral, Together), and `OnDeviceProvider` (stub ready for local runtime).
   - `ProviderManager` extends the Vault key pool with priority ordering, live key verification (`testKey`), automatic cooldown transitions on HTTP 429, and seamless cross-provider failover.

2. **`VyshuBrain` & Persistent Memory (`Hive`)**:
   - **Short-Term Memory**: Active goal, step history (`thought`, `action`, `args`, `observationHash`, `result`), and retry counter.
   - **Long-Term Memory**: 14-day conversation turns, extracted user facts (e.g., preferred contacts, habits), and learned UI shortcuts.
   - **Task Log**: Historical record of completed/aborted agent runs with timestamps and step outcomes.

3. **Observe → Plan → Act → Verify Cycle & Safety**:
   - **Observe**: Calls `dumpScreenCompact` on `VyshuAccessibilityService`. Checks package name against `BLOCKED_PACKAGES` (GPay, PhonePe, Paytm, banking apps, password managers). Scrubs any node with `isPassword == true`.
   - **Plan**: Sends compact screen state + goal + recent steps to `ProviderManager.complete()` requesting strict JSON: `{"thought": "...", "action": "...", "args": {...}, "done": false}`. Validates action name against the 18 allowed skills; retries once if JSON is malformed.
   - **Safety Gate**: If `action` is in `RISKY_ACTIONS` (`send_whatsapp`, `call_contact`, `set_toggle`), pauses and triggers confirmation modal/voice prompt before executing.
   - **Act & Verify**: Executes gesture (`GestureDescription` for coordinates/scroll/swipe or `AccessibilityNodeInfo.ACTION_CLICK` / `ACTION_SET_TEXT` for nodes), waits for UI settle, re-observes screen hash, and detects stuck loops (same screen hash + same action 3 times triggers replanning).

4. **Sub-Agent Hook (`SubAgentDispatcher`)**:
   - Standardized JSON contract `{"agent": "Vaani" | "Nisha" | "Garuda" | "Veda", "task": "...", "durationMinutes": 60, "status": "running"}` with an active timer that automatically invokes stop/cleanup when a timed task (such as *"play songs in Vaani for 1 hour"*) expires.
