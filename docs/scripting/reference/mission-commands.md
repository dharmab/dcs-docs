# missionCommands

The missionCommands singleton allows you to add and remove entries in the F10 "Other" radio menu.

## missionCommands.addCommand

```lua
table missionCommands.addCommand(string name, table path, function handler, any argument)
```

The `missionCommands.addCommand` function adds a command to the F10 menu that all players can see and use.

**Parameters:**
- `name` (string): The menu item text.
- `path` (table): The parent menu path. Pass nil to add the command to the root menu.
- `handler` (function): The function called when the player selects the command.
- `argument` (any): The value passed to the handler function.

**Returns:** A path table identifying this command. Use this value with `missionCommands.removeItem` to remove the command later.

```lua
missionCommands.addCommand("Request SITREP", nil, function()
    trigger.action.outText("All objectives intact", 10)
end)

local supportMenu = missionCommands.addSubMenu("Support", nil)
missionCommands.addCommand("Call Artillery", supportMenu, function()
    fireArtillery()
end)
```

## missionCommands.addSubMenu

```lua
table missionCommands.addSubMenu(string name, table path)
```

The `missionCommands.addSubMenu` function adds a submenu to the F10 menu.

**Parameters:**
- `name` (string): The submenu text.
- `path` (table): The parent menu path. Pass nil to add the submenu to the root menu.

**Returns:** A path table for this submenu. Use this value as the `path` parameter when adding child items.

```lua
local mainMenu = missionCommands.addSubMenu("Mission Control", nil)
local airMenu = missionCommands.addSubMenu("Air Support", mainMenu)
missionCommands.addCommand("CAS Strike", airMenu, performCAS)
```

## missionCommands.removeItem

```lua
nil missionCommands.removeItem(table path)
```

The `missionCommands.removeItem` function removes a command or submenu from the F10 menu.

**Parameters:**
- `path` (table): The path table returned by `missionCommands.addCommand` or `missionCommands.addSubMenu`.

## missionCommands.addCommandForCoalition

```lua
table missionCommands.addCommandForCoalition(number coalitionId, string name, table path, function handler, any argument)
```

The `missionCommands.addCommandForCoalition` function adds a command visible only to players of a specific coalition.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.
- `name` (string): The menu item text.
- `path` (table): The parent menu path. Pass nil to add the command to the root menu.
- `handler` (function): The function called when the player selects the command.
- `argument` (any): The value passed to the handler function.

**Returns:** A path table for this command.

## missionCommands.addSubMenuForCoalition

```lua
table missionCommands.addSubMenuForCoalition(number coalitionId, string name, table path)
```

The `missionCommands.addSubMenuForCoalition` function adds a submenu visible only to players of a specific coalition.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.
- `name` (string): The submenu text.
- `path` (table): The parent menu path. Pass nil to add the submenu to the root menu.

**Returns:** A path table for this submenu.

## missionCommands.removeItemForCoalition

```lua
nil missionCommands.removeItemForCoalition(number coalitionId, table path)
```

The `missionCommands.removeItemForCoalition` function removes a coalition-specific menu item.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.
- `path` (table): The path table returned when the item was created.

## missionCommands.addCommandForGroup

```lua
table missionCommands.addCommandForGroup(number groupId, string name, table path, function handler, any argument)
```

The `missionCommands.addCommandForGroup` function adds a command visible only to players in a specific group. This function is the most common way to create player-specific menus.

**Parameters:**
- `groupId` (number): The group's numeric ID. Call `group:getID()` on a Group object to obtain this value.
- `name` (string): The menu item text.
- `path` (table): The parent menu path. Pass nil to add the command to the root menu.
- `handler` (function): The function called when the player selects the command.
- `argument` (any): The value passed to the handler function.

**Returns:** A path table for this command.

```lua
local function setupPlayerMenu(unit)
    local group = unit:getGroup()
    local groupId = group:getID()

    local menu = missionCommands.addSubMenuForGroup(groupId, "Player Actions", nil)
    missionCommands.addCommandForGroup(groupId, "Check Fuel", menu, function()
        local fuel = unit:getFuel() * 100
        trigger.action.outTextForGroup(groupId, "Fuel: " .. math.floor(fuel) .. "%", 5)
    end)
end
```

## missionCommands.addSubMenuForGroup

```lua
table missionCommands.addSubMenuForGroup(number groupId, string name, table path)
```

The `missionCommands.addSubMenuForGroup` function adds a submenu visible only to players in a specific group.

**Parameters:**
- `groupId` (number): The group's numeric ID. Call `group:getID()` on a Group object to obtain this value.
- `name` (string): The submenu text.
- `path` (table): The parent menu path. Pass nil to add the submenu to the root menu.

**Returns:** A path table for this submenu.

## missionCommands.removeItemForGroup

```lua
nil missionCommands.removeItemForGroup(number groupId, table path)
```

The `missionCommands.removeItemForGroup` function removes a group-specific menu item.

**Parameters:**
- `groupId` (number): The group's numeric ID.
- `path` (table): The path table returned when the item was created.

## See Also

- [coalition](coalition.md) - Coalition identifiers
- [group](group.md) - Group objects and IDs
- [trigger](trigger.md) - Message display functions
