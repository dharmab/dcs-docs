# atmosphere

The atmosphere singleton provides weather information.

All functions in this singleton that accept coordinate parameters may fail or return undefined results if the coordinates fall outside the current map's boundaries. When calling these functions with dynamically calculated positions, consider using `pcall()` to handle potential errors gracefully.

## atmosphere.getWind

```lua
Vec3 atmosphere.getWind(Vec3 position)
```

The `atmosphere.getWind` function returns the wind vector at a position without including turbulence effects. The returned vector indicates the direction the wind is blowing to, not from.

**Parameters:**
- `position` (Vec3): The world position to query.

**Returns:** A Vec3 wind vector in meters per second.

```lua
local windVec = atmosphere.getWind(unit:getPoint())
local windSpeed = math.sqrt(windVec.x^2 + windVec.z^2)
local windHeading = math.atan2(windVec.z, windVec.x)
```

## atmosphere.getWindWithTurbulence

```lua
Vec3 atmosphere.getWindWithTurbulence(Vec3 position)
```

The `atmosphere.getWindWithTurbulence` function returns the wind vector including turbulence effects.

**Parameters:**
- `position` (Vec3): The world position to query.

**Returns:** A Vec3 wind vector in meters per second.

## atmosphere.getTemperatureAndPressure

```lua
number, number atmosphere.getTemperatureAndPressure(Vec3 position)
```

The `atmosphere.getTemperatureAndPressure` function returns atmospheric conditions at a position.

**Parameters:**
- `position` (Vec3): The world position to query.

**Returns:** Two numbers representing the temperature in Kelvin and the pressure in Pascals.

```lua
local temp, pressure = atmosphere.getTemperatureAndPressure(unit:getPoint())
local tempC = temp - 273.15
local pressureHPa = pressure / 100
```

## See Also

- [Coordinate Types](../types/coordinates.md) - Vec3 coordinate system
