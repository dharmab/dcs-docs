# Handoff: Operation Infinity IADS Rework

Status: not started. Branch `fix/operation-infinity-review` has unrelated fixes; start the IADS work on its own branch.

## Current Behavior

**Emission control has never worked.** `BattlefieldGeneration.lua:1023` registers each site with IADS as `<samType>-<index>` (e.g. `SA6-1`). Virtualization spawns the group as `<name>-<groupId>` (`Virtualization.lua:107`, e.g. `SA6-1-57`). `IADS:setRadarState` calls `Group.getByName(samSite.groupName)` (`IADS.lua:125`), gets nil and returns false. Every SAM therefore runs on DCS default AI, radars always on. Fixing the lookup alone would switch on the flawed logic below, so fix it as part of the rework.

As written, `src/l10n/DEFAULT/IADS.lua` runs emission control on Normal and Hard only. Every 10 s it would toggle each registered SAM group between alarm state RED (radar on) and GREEN (radar off):

- No blue aircraft within 60 km: 30 s on, 45 s off, forever.
- Blue aircraft within 60 km: on, then off again after 30 s even with the target still in range (`IADS.lua:174`). Ten seconds later the next update turns it back on.
- `IADS:enable` starts every site in GREEN.

## Problems

1. **Shutdowns kill missiles in flight.** The 30 s cutoff ignores missiles in the air. SA-2, SA-3, SA-6, SA-10 and SA-11 missiles lose guidance when their radar goes dark.
2. **No HARM reaction.** Sites don't respond to anti-radiation missiles. A HARM gets a radar that's on whenever a threat is near, apart from the 10 s gap.
3. **EWRs do nothing.** `registerEWR` stores names that are never read, and `config.ewrDetectionRange` is unused. Killing EWRs doesn't weaken the network.
4. **Threat checks cheat.** `getBlueAircraftPositions` uses the true positions of every blue aircraft. Terrain masking and low-level flying don't matter. `MINIMUM_THREAT_ALTITUDE_METERS = 50` is compared against MSL, not AGL, so over the mountains every aircraft counts.
5. **One range for every type.** `samActivationRange = 60000` applies to the SA-3 and the SA-10 alike. The SA-10 wakes inside its own envelope and the SA-3 wakes far outside it.
6. **Fixed rhythm.** The 30/45 s cycle is predictable, so players can time it.
7. **SHORAD under the same control.** SA-8 and SA-15 sites are registered as SAM sites and pulse too. They can't act as point defense for the long-range sites.

Not a problem to fix here: Easy SAMs (incomplete SA-2, SA-9, SA-13) are deliberately outside emission control and run on DCS default AI.

## Proposed Design

Rules in priority order. A higher rule overrides a lower one.

1. **HARM defense.** On `S_EVENT_SHOT`, keep a list of weapons whose `weapon:getDesc().guidance == Weapon.GuidanceType.RADAR_PASSIVE` (value 5). Every 2-5 s, check each tracked ARM. If one is heading toward a site and inside a set distance (start with 20-30 km), that site goes dark for a random 60-180 s.
   - If the site has its own missiles in flight: shut down only if the HARM arrives before the site's own missile reaches its target. Otherwise keep guiding.
   - Point defense: if an SA-15 or SA-8 is within a few km of the threatened site, it goes or stays RED so it can shoot the HARM down.
2. **Keep guiding.** Track the site's own missiles from `S_EVENT_SHOT` (the initiator is one of the site's launchers). Hold RED until every missile has hit or disappeared (`weapon:isExist()` false).
3. **EWR cueing.** Each update, build the set of targets detected by live EWRs with `controller:getDetectedTargets(Controller.Detection.RADAR)`. A site wakes when a detected target is inside about 75% of that site type's max engagement range. It goes dark when no cued target is inside that range and rule 2 isn't holding it on.
4. **Autonomous fallback.** If no live EWR is within a set distance of a site, it pulses on its own: random 15-30 s on and 60-180 s off, still subject to rules 1 and 2. Killing EWRs should be a SEAD/DEAD goal.
5. **Optional relocation.** After firing, or after a HARM shutdown, mobile sites (SA-6, SA-8, SA-11, SA-15) move a few hundred meters. Stored F10 marks and TGP coordinates go stale. Needs a ground route and a terrain check, so do it last.

### Per-Type Engagement Ranges

Starting values only. Check them against Quaggles' datamine and `docs/units/ground.md` before using them.

| Site | Max range (approx) |
|------|--------------------|
| SA-2 | 40 km |
| SA-3 | 25 km |
| SA-6 | 25 km |
| SA-8 | 10 km |
| SA-10 | 90 km |
| SA-11 | 30 km |
| SA-15 | 12 km |

### Difficulty Scaling

- **Normal:** rules 2-4. HARM reaction (rule 1) only some of the time, such as 50%, with a 5-10 s reaction delay. No relocation.
- **Hard:** all rules, with a 1-3 s reaction delay and point defense on.

## Implementation Notes

- Site registration happens in `BattlefieldGeneration:generateSAMSite` (`IADS:registerSAMSite(groupName, samType, pos)`) and `generateEWRsBatched` (`IADS:registerEWR`). `samType` is the `samCounts` key (`SA2`, `SA10`, etc.), so you can look up per-type ranges and SHORAD roles by key.
- SAM sites and EWRs are permanent groups (`Virtualization:registerPermanentGroup`), always spawned. The live DCS group name is the permanent group's `spawnedGroupName`, set after spawning. Have `registerPermanentGroup`'s return value (the `pGroup` table) passed to IADS and resolve `pGroup.spawnedGroupName` at lookup time, instead of storing the registered name. EWR lookups have the same problem.
- Event handling: follow the `AirIntercept.eventHandler` pattern and dedupe by name. `S_EVENT_SHOT` fires once per missile.
- `IADS:update` uses `BatchScheduler:processArray`. Whether the scheduler's time budget actually splits work inside one array is unverified (it measures time with `timer.getTime()`, which may not advance during a callback). Keep per-update work small either way.
- Follow the Lua style in `AGENTS.md`: `array[#array + 1]`, named constants, verbose logging.
- Update `AGENTS.md` "IADS Behavior" when done.

## Testing

No automated tests for Lua behavior. Check in DCS with Normal and Hard:

1. Fly toward an SA-6 at medium altitude. The site should stay dark until you're inside about 75% of its range, then fire and keep guiding until the missile resolves.
2. Fire a HARM at an active SA-10 with an SA-15 nearby. The SA-10 should go dark, and the SA-15 should go or stay active.
3. Kill every EWR. Sites should switch to random autonomous pulsing.
4. Fly low behind terrain. Sites should stay dark.
5. Watch `dcs.log` for `[IADS]` state changes.

Also run `uv run check-mission check missions/operation-infinity/src` from `tools/mission-check`.

## References

- `docs/recipes/sam-site-setup.md`: SAM compositions and a basic IADS script.
- `docs/scripting/reference/classes/weapon.md`: `Weapon.GuidanceType`, `weapon:getTarget`.
- `docs/scripting/reference/classes/controller.md`: `controller:getDetectedTargets`.
- Skynet IADS (walder/Skynet-IADS on GitHub): an existing DCS IADS script with HARM defense, EWR cueing and point defense. Useful for checking behavior, though this mission doesn't use it.
