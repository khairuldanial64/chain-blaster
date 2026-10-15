# 2D Space Shooter

A fast-paced 2D arcade space shooter developed independently in **Godot 4.7 using GDScript**. Built for the Stop Killing Games Community Jam 2026 and GMTK Game Jam 2026, the game challenges players to survive hostile encounters, chain kills, and achieve the highest possible score.

## Game Jam Achievements

- **Stop Killing Games Community Jam 2026:** Ranked 10th out of 500+ submissions.
- **GMTK Game Jam 2026:** Ranked 500th out of 10,000+ submissions.
- **Development:** Independently developed within a 7-day game jam.

## Gameplay Features

- **Space Combat:** Pilot a spaceship through an asteroid-filled arena and fight hostile enemies.
- **Multiple Enemy Behaviours:** Face stationary shooters, fast-moving dash enemies, and mobile enemies that fire projectiles.
- **Combo System:** Chain consecutive kills to build and maintain a score multiplier.
- **Dynamic Scoring:** Earn points for defeating enemies and increase your multiplier through sustained kill streaks.
- **Boss Encounter:** Face a dedicated boss battle where normal scoring and combo mechanics are disabled.
- **High Score Tracking:** Track your best performance across play sessions.

## Technical Highlights

- **Engine:** Godot 4.7
- **Language:** GDScript
- **Game Systems:** Modular score and combo managers implemented as autoloads.
- **State Management:** Separate control of scoring and combo behaviour during normal gameplay and boss encounters.
- **Persistent Data:** Local high-score saving using Godot's `FileAccess` system.
- **Cross-Platform Development:** Web-playable build, with Android adaptation planned for a future Google Play release.

## Scoring and Combo Mechanics

The game rewards aggressive and consistent play through a timed kill-chain system.

- Build a combo by achieving consecutive kills.
- Maintain the combo before its timer expires.
- Increase the score multiplier through continued successful kills.
- Take damage or miss the required kill window to break the combo.
- Reach a maximum score multiplier of **10×**.
- Entering the boss encounter disables normal scoring and combo mechanics.

## Development

This project was developed independently during two game jams, involving the design and implementation of the core gameplay loop, enemy behaviours, scoring logic, combo management, and persistent high-score tracking.

The project also serves as an opportunity to explore modular game architecture, gameplay state management, and cross-platform deployment with Godot.

## Play the Game

- **Web Build:** [https://melonsss.itch.io/chain-blaster]
- **Source Code:** This repository

## Future Plans

- Complete and test the Android build.
- Adapt controls and interface elements for touchscreen devices.
- Prepare the game for a potential Google Play release.

## Technologies

`Godot 4.7` · `GDScript` · `Game Development` · `Score Management` · `State Management` · `Cross-Platform Development`

---

Developed independently by Khairul as part of the Stop Killing Games Community Jam 2026 and GMTK Game Jam 2026.
