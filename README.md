# Plastic Platoon 🪖

> *An army-men IO battle royale for Android & iOS.*

Plastic Platoon is a top-down mobile shooter where you collect **plastic scraps** dropped by fallen soldiers to upgrade your weapon through 5 tiers — from a humble pistol to a devastating rocket launcher. Outmanoeuvre rivals, stay inside the shrinking safe zone, and be the last soldier standing.

---

## Concept

| Feature | Slither.io analogy | Plastic Platoon |
|---|---|---|
| Primary resource | Glowing orbs | Plastic scraps / spent shells |
| Growth metric | Body length | Gun tier / effective range |
| Risk/reward | Boost (lose length) | Rapid fire / recoil dash |
| Death result | Trail of food | Explodes into plastic parts |
| Map style | Abstract arena | Sandbox / backyard floor |

---

## Weapon Tiers

| Tier | Scraps needed | Weapon | Special |
|---|---|---|---|
| 0 | 0 | Pistol | – |
| 1 | 10 | Rifle | Increased range |
| 2 | 30 | Machine Gun | High fire rate |
| 3 | 60 | Minigun | Very high fire rate + zoom out |
| 4 | 100 | Rocket Launcher | Explosive area damage |

As your tier rises the **camera zooms out**, giving you a wider view (and longer effective range) — a direct parallel to Slither's length-as-shield mechanic.

---

## Controls (mobile)

```
┌─────────────────────────────────────┐
│                                     │
│  [L-stick]              [R-stick]   │
│   Move                  Aim+Fire    │
│                                     │
└─────────────────────────────────────┘
```

* **Left virtual joystick** — move your soldier in any direction.
* **Right virtual joystick** — aim and **auto-fire** while the stick is pushed.
* **Recoil dash** — firing a heavy shot pushes you backward; use it to dodge!

---

## Game Mechanics

### Growth Loop
1. Shoot enemies or explore the map to find **plastic scraps** (◆).
2. Scraps are magnetic — they fly toward you when you get close.
3. Collecting enough scraps automatically upgrades your weapon to the next tier.
4. The barrel visually grows longer with each tier.

### Combat
* Bullets deal full damage on direct hits; rockets deal AoE splash damage.
* Enemies are vulnerable from all angles (no hit-location system yet).
* **Recoil dash** is built into every shot — time your shots to dodge incoming fire.

### Safe Zone
* A glowing green ring shrinks over time.
* Soldiers outside the ring take continuous damage (8 HP/s).
* The ring is visible on the HUD **minimap** in the bottom-right corner.

### Enemy AI
AI soldiers cycle through four states:
- **Wander** — random patrol
- **Chase** — move toward the player when in detection range (~340 px)
- **Attack** — stop and shoot when in attack range (~260 px)
- **Flee** — run away when health drops below 25%

---

## Project Structure

```
lib/
├── main.dart                        # App entry point
├── screens/
│   ├── main_menu.dart               # Title screen
│   └── game_screen.dart             # GameWidget wrapper + overlays
└── game/
    ├── constants.dart               # World constants + GunTier data
    ├── plastic_platoon_game.dart    # FlameGame orchestrator
    ├── world/
    │   └── game_world.dart          # World (HasCollisionDetection)
    ├── components/
    │   ├── soldier.dart             # Abstract base: rendering, recoil, fire
    │   ├── player.dart              # Human-controlled soldier
    │   ├── enemy.dart               # AI soldier (FSM)
    │   ├── bullet.dart              # Projectile + explosion effect
    │   ├── plastic_scrap.dart       # Collectible pickup (magnetic)
    │   ├── obstacle.dart            # Soda cans, toy blocks, pencils
    │   ├── safe_zone.dart           # Shrinking battle-royale ring
    │   └── background.dart          # Sandy tiled floor
    └── ui/
        └── hud.dart                 # Health, tier, kills, scrap bar, minimap
```

---

## Getting Started

### Prerequisites
* Flutter SDK ≥ 3.2.0 — [install guide](https://docs.flutter.dev/get-started/install)
* Android Studio / Xcode for device deployment

### Setup

```bash
# 1. Generate the platform folders (run once)
flutter create --project-name plastic_platoon --org com.yourorg .

# 2. Install dependencies
flutter pub get

# 3. Run on a connected device or emulator
flutter run
```

> **Tip:** Use a physical device for the best joystick experience. The game is locked to landscape orientation.

### Android build
```bash
flutter build apk --release
```

### iOS build
```bash
flutter build ipa --release
```

---

## Roadmap

- [ ] Sprite-based soldier models (replace procedural drawing)
- [ ] Sound effects & background music via `flame_audio`
- [ ] Player colour customisation (Green / Tan / Arctic / Desert)
- [ ] Different soldier "molds" with stat variations (Sniper, Commando, Heavy)
- [ ] Online multiplayer (replace AI enemies with real players)
- [ ] Leaderboard / score persistence
- [ ] Moving hazards (toy lawnmower, bouncing ball)
- [ ] Team mode (3v3 squads)

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x |
| Game engine | [Flame](https://flame-engine.org/) 1.18 |
| Audio | flame_audio 2.x |
| Target platforms | Android, iOS |
| Rendering | Procedural Canvas (no sprites required to run) |

---

*Built with Flutter + Flame. All graphics are procedurally rendered — no external assets required to build and run the prototype.*
