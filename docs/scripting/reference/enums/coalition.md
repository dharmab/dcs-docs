# Coalition Enums

This document describes the coalition-related enumerations used in the DCS World Simulator Scripting Engine.

## coalition.side

Countries are identified by numeric IDs from the `country.id` enum. The game determines coalition membership based on the country. The three coalitions are represented by the `coalition.side` enum:

```lua
coalition.side = {
    NEUTRAL = 0,
    RED = 1,
    BLUE = 2
}
```

Some functions such as `markupToAll` accept a coalition value of -1, which represents "all coalitions."

## See Also

- [coalition](../singletons/coalition.md) - Coalition management functions
