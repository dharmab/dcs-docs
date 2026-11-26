# Restore Unit Life

The mission scripting API has no `unit:setLife()`. There are two workarounds: call the Mission Editor's **Set Unit Life** trigger command to heal a unit, or delete the unit or group and spawn a fresh copy.

## Set life with a trigger command

Run this in a [Lua](https://www.lua.org/about.html) environment with `net.dostring_in` access, such as a server hook, with permission to execute code in the `mission` state (see [cross-environment execution](../scripting/reference/singletons/net.md#netdostring_in)). The hook needs the target unit's numeric ID, not its name or a `Unit` object. In mission scripting, `unit:getID()` returns the ID; pass it to the hook through your own integration.

```lua
-- In a server hook; unitId is the target unit's numeric ID.
net.dostring_in("mission", [[a_unit_set_life_percentage(]] .. unitId .. "," .. 100 .. ")")
```

The `100` argument sets life to 100 percent. This calls an internal trigger command, **not** a supported SSE API; it may change in future DCS versions. Enabling cross-environment execution has security implications, so use it only in a trusted environment.

In one reported test, the unit's life was restored but a small fire effect remained. Do not rely on this workaround to clear damage effects or revive a unit that has already been destroyed.

## Replace the unit or group

To avoid the internal trigger command, remove the damaged unit or group and spawn a fresh copy from a saved group definition with [`coalition.addGroup`](../scripting/reference/singletons/coalition.md#coalitionaddgroup). To replace the whole group, use [`group:destroy()`](../scripting/reference/classes/group.md#groupdestroy) before spawning its replacement. Save the group definition before deleting the group. This creates a **new** unit or group; it does not repair the original.

The replacement starts with fresh life but does not preserve the original's runtime state (such as damage, ammunition, or active tasks). Restore any state you need separately, and take care with player-controlled units and name collisions. See the `coalition.addGroup` documentation for spawn timing and name-reuse behavior.
