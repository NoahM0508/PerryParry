# 🎨 Art, VFX & Audio Backlog: *Perry Parry*

This document tracks every visual effect, sound effect, sprite sheet, and animation needed across the game's mechanics and upgrades. It is organized so you can execute the visual/audio pass independently once code systems are in place.

---

## 🛡️ Core Parry & Combat Systems

| Feature / Trigger | Visual Effect (VFX / Sprites) | Sound Effect (SFX) |
| :--- | :--- | :--- |
| **Parry Activation (Trigger)** | Procedural glowing directional arc/cone pointing at cursor with alpha fade (0.22s duration) | Quick metallic whoosh / shield flick |
| **Successful Parry (Hit)** | Bright flash sparks, small screen-space ring pulse, deflected bullet gets glowing trail | Crisp, punchy metallic "CLANG!" or energy chime |
| **Perfect Parry (Sweet Spot)** | Golden sparks burst, purple/gold tint on deflected bullet, 3-frame hitstop flash | Heavy resonant "PWONG!" or glass-shattering bass drop |
| **Parry Whiff (Missed)** | Dim gray dissipating vapor, subtle red flash on Parry cooldown icon | Dull metallic "clack" or hollow whiff buzz |
| **Parry Combo Counter** | Floating animated text popup (`x2`, `x3`, `x5 MAX!`) pulsing in size over Perry | Pitch-ascending hit chime on each consecutive parry |
| **Dash Strike (Vulnerable)** | Crackling electric trail during dash; cracked armor / broken shield icon over affected enemies | Electric sizzle / shield-break crunch |

---

## 🃏 New Upgrades Visual & Audio Needs

### Parry & Core Upgrades
1. **Focus Beam (`parry_accuracy`)**:
   - **VFX**: Narrower, sharper, laser-like parry cone visual; reflected bullets gain an intense trailing streak.
   - **SFX**: High-frequency piercing deflection sound.
2. **Bullet Vortex (Gravitational Deflect)**:
   - **VFX**: Swirling inward gravitational distortion ring pulling bullet trails toward Perry.
   - **SFX**: Deep gravitational suction hum followed by a release pop.
3. **Kinetic Battery (Ammo on Deflect)**:
   - **VFX**: Tiny green energy spark flying from deflected bullet into Perry's weapon HUD ammo counter.
   - **SFX**: Metallic ammo chamber click / reload click.
4. **Chronoshift (Bullet Time)**:
   - **VFX**: Vignette desaturation (screen edges turn icy blue/grayscale) for 0.6s while active.
   - **SFX**: Muffled audio warp / ticking clock distortion.
5. **Disruption Field (`shockwave`)**:
   - **VFX**: Blue expanding EMP ring + lingering electrical sparks dancing over stunned enemies.
   - **SFX**: Low-frequency bass thud + electric crackle.

### Player Upgrades
6. **Shrapnel Rounds**:
   - **VFX**: Bullet collision creates 2–3 jagged glowing metal fragments ricocheting outward.
   - **SFX**: Glass/metal fracture shard clatter.
7. **Heavy Caliber (Piercing Rounds)**:
   - **VFX**: Longer, elongated bullet tracer leaving small entry/exit puff on pierced enemies.
   - **SFX**: Heavier gunshot punch with a hollow punching echo.
8. **Berserker / Adrenaline Overdrive**:
   - **VFX**: Pulsing red heartbeat vignette along screen edges when below 40% HP; Perry gets red after-image sprint trails.
   - **SFX**: Muffled heartbeat thump in background.
9. **Overclocked Chamber**:
   - **VFX**: Gun muzzle sparks orange fire on the final round; massive impact blast.
   - **SFX**: Loud, distinct warning click when down to 1 bullet + cannon-like blast on final shot.
10. **Demolitionist**:
    - **VFX**: Rubble particles and dust clouds when destructible walls break; sparkling loot beam on dropped shards.
    - **SFX**: Heavy stone crumbling / brick wall smashing sound.
11. **Emergency Discharge**:
    - **VFX**: Sudden 360-degree shockwave dome vaporizing all incoming projectiles.
    - **SFX**: Emergency siren blip + catastrophic explosive shockwave boom.
12. **Bounty Hunter**:
    - **VFX**: Golden tractor-beam lines connecting deflected kill spots to Perry as XP shards fly in.
    - **SFX**: Pleasant coin/crystal pickup chime cascade.
13. **Ricochet**:
    - **VFX**: Bright impact sparks on wall bounce; bullet switches to target-seeking trail.
    - **SFX**: Classic cartoonish/action "ricochet ping!"

---

## 🏰 World & Dungeon Environment
- **Modular Room Doors**: Flashing lock runes that change from glowing red (sealed) to green (open/cleared).
- **Arena Entry Gateway**: Demonic/alien lock seal with an interactive keyhole animation.
- **Boss Room Entrance**: Grand skull/hazard gateway with glowing eye sockets when keys are slotted.

---

## 👹 Boss Fight Rework Visuals
- **Phase 1**: Telegraphed bullet arcs with bright pink/neon parryable core bullets.
- **Phase 2 Enrage**: Boss eyes glow fiery red, steam/smoke venting from shoulders.
- **Charge Attack**: Red directional floor lane indicating oncoming rush.
- **Stunned State**: Spinning stars/dizzy icons with vulnerable core exposed to gunfire.
