# Nodeverse

![Screenshot](screenshot.jpg)

This is a procedurally generated space exploration game, inspired by No Man's
Sky and other similar titles, but built around voxel mechanics. It features an
immensely large universe with a never-ending variety of planets to explore.

## Status
An infinite cloud of floating planets is created. Blocks include stone, gravel,
dust, sediment, water, hydrocarbon, lava, grass soil, grass, dry grass, tall
grass and snow. Planets of different colors, rockier, more hilly or flat, richer
in oceans, arid, frozen, volcanic, and with or without living organisms are
generated. World generation features oceans, caves, deserts and craters.

The player can fly using a rocket that they start with. No further interaction
has been added yet.

## Mods
This is a list of the components that make up this game. Each of these mods can
be used by itself, as long as its dependencies are satisfied.

Name | Dependencies | Description
---- | ------------ | -----------
`planetgen` | None | Generates planet terrain. See its `README.md` for instructions on advanced usage.
`rocket` | `autobox`, `player_api` | Adds a rocket to fly to many other planets.

## TODO
 * Add minerals and ores
 * Add more complex flora
 * Add fauna
 * Add player mechanics
 * Add basic items
 * Add basic crafting
 * Add interplanetary space
 * Add interstellar travel
 * Add spacecraft building
 * Improve all of the above
