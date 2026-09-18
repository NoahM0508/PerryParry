# ⚡ Perry Parry

[![Godot Engine](https://img.shields.io/badge/Godot-4.x%20Forward%2B-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-blue)](#)
[![Genre](https://img.shields.io/badge/Genre-Action%20Roguelite%20%2F%20Bullet%20Hell-critical)](#)
[![Version](https://img.shields.io/badge/Version-v0.5-orange)](#)

> **"Turn their firepower into your greatest weapon."**  
> **Perry Parry** is a fast-paced 2D roguelite top-down shooter built in Godot 4. Deflect incoming projectile storms with pinpoint timing, build synergistic upgrades, tackle adaptive AI enemies, and survive the bullet-riddled depths of the dungeon maze!

---

## 🎮 Gameplay Highlights

- 🛡️ **Precision Parry & Deflection System**: Time your parry window (`Space`) to deflect enemy bullets straight back at your attackers. Upgrades unlock projectile duplication, shockwave pulses, high-damage explosive retaliation, and critical overload damage buffs!
- 🧬 **Dual XP & Progression Pools**:
  - **Player XP**: Gather XP shards from eliminated enemies to earn core survivor enhancements (Max HP, Armor, Movement Speed, Life Steal, Fire Rate, Passive Regeneration).
  - **Parry XP**: Level up specifically by parrying incoming fire to earn specialized deflection abilities and tighten your deflection accuracy spread.
- 🔫 **Modular Weapon Arsenal & Rarity System**:
  - 6 rarity tiers: **Common**, **Uncommon**, **Rare**, **Epic**, **Legendary**, and **Mythic**.
  - Dynamic recoil, magazine sizes, reload timings, and distinct projectile types (Pistol, Shotgun shells, Rifle rounds, Energy blasts).
  - Multi-slot inventory management with live weapon swapping (`C`) and ground drops (`Q`).
- 🧠 **Adaptive AI Enemy Scaling**:
  - Enemies scale across **10 AI Levels** as your kill count increases.
  - Advanced tactics: strafing, retreat-and-heal states, incoming projectile evasion, and predictive shot leading.
- 🏰 **Dungeon Maze, Arena Challenges & Epic Boss**:
  - Explore an interconnected labyrinth featuring destructible barricades and hidden rooms.
  - Battle through sealed, multi-wave lock-in combat arenas.
  - Face the boulder-throwing **Boss** in the Boss Arena!
- ⏳ **Endless "Overtime" Survival**:
  - Defeating the boss triggers high-stakes Overtime mode with survival timers and persistent high scores!

---

## 🕹️ Controls

| Action | Keyboard / Mouse | Description |
| :--- | :--- | :--- |
| **Move** | `W` / `A` / `S` / `D` | Omnidirectional player movement |
| **Dash** | `Left Shift` | Quick dash granting brief invincibility frames |
| **Parry / Deflect** | `Spacebar` | Activate deflection shield window |
| **Aim & Shoot** | `Mouse` / `Left Click` | Aim with cursor and fire weapon |
| **Reload** | `R` | Reload equipped weapon |
| **Swap Weapon** | `C` | Cycle active inventory weapon slot |
| **Drop Weapon** | `Q` | Drop equipped weapon onto the floor |
| **Pause Menu** | `P` / `Esc` | Pause game, view run stats, adjust volume |

---

## 🏗️ Project Architecture & Tech Stack

```
perry-parry/
├── project.godot                  # Engine configuration & Input mappings (Godot 4.x)
└── PerryParry/
    ├── assets/                    # Pixel art sprites, fonts, audio SFX, and OST
    │   ├── Bullets/               # Custom projectile sprites
    │   ├── EnemySprite/           # Enemy spritesheets & animations
    │   ├── Guns/                  # Weapon models (Packs 1 & 2)
    │   ├── Perry/                 # Player character sprites & animations
    │   ├── UI/                    # SimplePixelArtUIpack components & fonts
    │   └── audio/                 # Guns, player, enemy audio, and music tracks
    ├── resources/
    │   ├── Upgrades/              # Core, Parry, and Player UpgradeData resources
    │   └── weapons/               # Tiered WeaponStats resources (Common to Mythic)
    ├── scenes/                    # Main scenes (lvl_1, arenas, boss_arena, HUD, menus)
    └── scripts/                   # Core GDScript gameplay logic
        ├── Perry.gd               # Character controller, parry logic, and damage calculations
        ├── UpgradeManager.gd      # Global Autoload: Deckbuilding, persistence, and RNG weights
        ├── base_enemy.gd          # 6-state FSM enemy AI with dynamic dodging and leading
        ├── weapon.gd              # Weapon firing mechanics, timers, and reload animations
        └── run_director.gd        # Arena wave spawning, timeouts, and overtime handling
```

### Key Technologies
- **Engine**: [Godot Engine 4.x (Forward+ Renderer)](https://godotengine.org)
- **Language**: GDScript 2.0
- **Physics**: Godot 2D Physics Engine with custom area raycasting
- **State Management**: Autoload Singletons (`UpgradeManager`, `MusicManager`) with cross-arena scene state preservation

---

## 🚀 Getting Started

### Prerequisites
- [Godot Engine 4.3 or higher (Standard Edition)](https://godotengine.org/download)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/SkylanderUnknown/PerryParry.git
   ```
2. Open Godot Engine.
3. Click **Import**, navigate to the project directory, and select `project.godot`.
4. Click **Import & Edit**.
5. Press **F5** (or click the Play button in the top right) to launch from the Main Menu (`res://PerryParry/scenes/main_menu.tscn`)!

---

## 🗺️ Roadmap & Upcoming Features

- [ ] **Home UI & Main Menu Polish**: Full pixel-art menu overhaul with animated background, character mascot preview, and sound effects.
- [ ] **Comprehensive Settings Menu**: Master, SFX, and Music volume controls, window modes (Fullscreen / Windowed / Borderless), VSync, and rebindable input controls.
- [ ] **2D Smart Pathfinding**: Implement `NavigationAgent2D` / `NavigationServer2D` or dynamic raycast steering so enemies navigate dungeon walls seamlessly without getting stuck.
- [ ] **Upgrade Screen Overhaul**: Dedicated card selection highlighting with an interactive **"Upgrade / Confirm"** button, reroll tokens, and audio stingers.
- [ ] **New Enemy Archetypes & Boss Phases**: Melee dashers, explosive kamikaze drones, and multi-phase boss mechanics.
- [ ] **Juice & Combat Feedback**: Screen shake, floating combat text, muzzle flashes, and dynamic parry freeze frames (hitstop).

---

## 📜 License & Credits

- **Game Design & Code**: SkylanderUnknown
- **Engine**: Godot Engine (MIT License)
- **Audio & Visual Assets**: Included under respective creator licenses (see `PerryParry/assets/`).
