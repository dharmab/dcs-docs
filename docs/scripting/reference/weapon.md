# Weapon

The Weapon class represents a weapon in flight: missiles, bombs, rockets, and shells.

Inherits from: [Object](object.md), [CoalitionObject](coalition-object.md)

You obtain Weapon objects through events, particularly the `S_EVENT_SHOT` event.

The `Weapon.Category` enum defines the weapon categories:

```lua
Weapon.Category = {
    SHELL = 0,
    MISSILE = 1,
    ROCKET = 2,
    BOMB = 3
}
```

The `Weapon.GuidanceType` enum defines the guidance types:

```lua
Weapon.GuidanceType = {
    INS = 1,
    IR = 2,
    RADAR_ACTIVE = 3,
    RADAR_SEMI_ACTIVE = 4,
    RADAR_PASSIVE = 5,
    TV = 6,
    LASER = 7,
    TELE = 8
}
```

The `weapon:getCategory()` method returns `Object.Category.WEAPON`. Use `weapon:getDesc().category` to get a value from `Weapon.Category`.

## weapon:getLauncher

```lua
Unit weapon:getLauncher()
```

The `weapon:getLauncher` method returns the unit that fired this weapon.

**Returns:** A Unit object, or nil.

```lua
function handler:onEvent(event)
    if event.id == world.event.S_EVENT_SHOT then
        local shooter = event.weapon:getLauncher()
        local weaponType = event.weapon:getTypeName()
        env.info(shooter:getName() .. " fired " .. weaponType)
    end
end
```

## weapon:getTarget

```lua
Object weapon:getTarget()
```

The `weapon:getTarget` method returns the weapon's target.

**Returns:** The target Object, or nil for unguided weapons.

## See Also

- [object](object.md) - Base class methods
- [coalition-object](coalition-object.md) - Coalition and country methods
- [unit](unit.md) - Unit class (weapon launcher)
- [events](events.md) - S_EVENT_SHOT and weapon-related events
