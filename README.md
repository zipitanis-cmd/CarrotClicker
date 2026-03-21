# 🥕 Carrot Clicker

A 2D GUI-only Roblox clicker game built entirely within a single `ScreenGui`. There is **no 3D world or player movement** — the entire game is one screen that expands with systems, tabs, and unlocks as you progress.

---

## Quick Start

### Using the Build Script (Recommended)

1. Open **Roblox Studio** and create a new **Baseplate** place (or any empty place).
2. Open the **Command Bar** (View → Command Bar).
3. Copy the contents of [`BuildScripts/BuildAll.lua`](BuildScripts/BuildAll.lua).
4. Paste into the Command Bar and press **Enter**.
5. The script will print progress messages and end with:
   ```
   ✅ Carrot Clicker build complete!
   ```
6. Press **Play** (F5) to test the game immediately.

### Manual Setup (from `src/`)

If you prefer to copy files manually into Roblox Studio:

| File | Roblox Location |
|------|----------------|
| `src/ReplicatedStorage/GameConfig.lua` | `ReplicatedStorage/Modules/GameConfig` (ModuleScript) |
| `src/ReplicatedStorage/NumberFormatter.lua` | `ReplicatedStorage/Modules/NumberFormatter` (ModuleScript) |
| `src/ReplicatedStorage/Remotes.lua` | `ReplicatedStorage/Modules/Remotes` (ModuleScript) |
| `src/ServerScriptService/GameServer.server.lua` | `ServerScriptService/GameServer` (Script) |
| `src/ServerScriptService/DataStoreManager.server.lua` | `ServerScriptService/DataStoreManager` (Script) |
| `src/StarterPlayerScripts/GameClient.client.lua` | `StarterPlayerScripts/GameClient` (LocalScript) |
| `src/StarterPlayerScripts/AnimationController.client.lua` | `StarterPlayerScripts/AnimationController` (LocalScript) |
| `src/StarterPlayerScripts/UIStateManager.client.lua` | `StarterPlayerScripts/UIStateManager` (LocalScript) |

---

## Game Design — Phase 1

### Core Loop
Click the giant carrot → earn **Carrots** → spend Carrots on **Upgrades** → earn more Carrots faster.

### Currencies
| Currency | Description |
|----------|-------------|
| **Carrots** | Main currency. Earned by clicking and passive production. |
| **Carrots/sec** | Passive income rate displayed in HUD. |
| **Seeds** | Reserved for Phase 2 (shown as 0). |

### Upgrades
| Name | Category | Base Cost | Multiplier | Effect |
|------|----------|-----------|------------|--------|
| Click Power | Click | 10 | ×1.15/level | +1 carrot per click |
| Auto Farmer | Idle | 50 | ×1.18/level | +1 carrot/sec |
| Compost | Boosts | 500 | ×1.35/level | +10% global multiplier |
| Crit Chance | Click | 200 | ×1.25/level | +2% crit chance (cap 50%) |
| Crit Power | Click | 1,000 | ×1.30/level | +1× crit multiplier |

Cost formula: `cost = baseCost × (multiplier ^ currentLevel)`

### Click Mechanics
- Base value: 1 carrot/click
- Modified by: Click Power + Compost multiplier + Streak bonus
- **Streak**: clicking within 2s builds a streak (max 50). Streak adds `streak/100` as a bonus multiplier.
- **Crit**: rolls against Crit Chance %. Hit = Crit Power × click value.
- **Golden Click**: every 25th click is automatically 10× (shows golden flash).

### Milestone System
| Milestone | Requirement | Reward |
|-----------|-------------|--------|
| First Harvest | 100 carrots | Badge |
| Sharp Eye | 1,000 carrots | Unlocks Crit Chance upgrade |
| Rich Soil | 10,000 carrots | Unlocks Compost upgrade |
| Critical Farming | 50,000 carrots | Unlocks Crit Power upgrade |
| Replant Available | 250,000 carrots | Teaser for Phase 2 |
| Millionaire Farmer | 1,000,000 carrots | Badge |

### Data Saving
- **DataStoreService** key: `CarrotClickerData_v1`
- Autosave every **120 seconds**
- Save on player leave and server shutdown
- Up to **3 retry attempts** on DataStore failures

---

## Repository Structure

```
CarrotClicker/
├── README.md
├── BuildScripts/
│   └── BuildAll.lua                         ← Paste into Studio command bar
└── src/
    ├── ReplicatedStorage/
    │   ├── GameConfig.lua                   ← All constants & upgrade definitions
    │   ├── NumberFormatter.lua              ← K/M/B/T number formatting
    │   └── Remotes.lua                      ← RemoteEvent setup
    ├── ServerScriptService/
    │   ├── GameServer.server.lua            ← Server authority: clicks, upgrades, passive income
    │   └── DataStoreManager.server.lua      ← Save/load with autosave
    ├── StarterGui/
    │   └── CarrotClickerGui/
    │       └── GuiStructure.lua             ← GUI tree documentation
    └── StarterPlayerScripts/
        ├── GameClient.client.lua            ← Click handling, HUD, upgrade cards
        ├── AnimationController.client.lua   ← All micro-animations
        └── UIStateManager.client.lua        ← Panel/tab switching, buy mode
```

---

## GUI Layout

```
┌─────────────────────────────────────────────────────┐
│  🥕 Carrot Clicker  │  123.4K  /s  /click  │  ⚙   │  ← TopBar
├──┬──────────────────────────────────────┬───────────┤
│🏠│                                      │ Upgrades  │
│⬆│         🥕 (big carrot button)       │ [Click]   │
│🌱│                                      │ [Idle]    │
│🐇│    ──────── Streak ────────          │ [Boosts]  │
│📋│    ──── Next Milestone ────          │ [Unlocks] │
│🛒│                                      │           │
│  │                                      │ Scroll↕   │
├──┴──────────────────────────────────────┴───────────┤
│           x1   x10   x100   Max   │  Auto 🔒        │  ← BottomBar
└─────────────────────────────────────────────────────┘
```

---

## Development Notes

- **Server authority**: All currency changes happen server-side. The client sends intents; the server validates and responds with `UpdateState`.
- **No image assets required**: The carrot button uses the 🥕 emoji and coloured `Frame` shapes. Works straight from a command-bar script without asset upload.
- **Animations**: Powered by `TweenService`. Timings match the spec (button bounce 0.07s down / 0.13s up, ripple 0.22s, floating numbers 0.45s average).
- **Phase 2** (Replant, Pets, Quests, Shop) tab buttons are visible but locked, with "Coming Soon" tooltips.