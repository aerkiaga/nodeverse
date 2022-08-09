# Nodeverse
[![ContentDB](https://content.minetest.net/packages/aerkiaga/nodeverse/shields/downloads/)](https://content.minetest.net/packages/aerkiaga/nodeverse/)

![Screenshot](screenshot.jpg)

This is a procedurally generated space exploration game, inspired by No Man's
Sky and other similar titles, but built around voxel mechanics. It features an
immensely large universe with a never-ending variety of planets to explore.

It is still in very early development, but a simple proof-of-concept game has
been built on top of the code to make it playable. Since this is an
[early](https://semver.org/#spec-item-4) release version, it is expected that
any following versions will make breaking changes to the core game.

## Status
A huge cloud of floating planets is created. Blocks include stone, gravel, dust,
sediment, water, hydrocarbon, lava, grass soil, grass, dry grass, tall grass and
snow. Planets of different colors, rockier, more hilly or flat, richer in
oceans, arid, frozen, volcanic, and with or without living organisms are
generated. World generation features oceans, caves, deserts and craters.

The player starts out flying a small, boring spaceship near the ground. Pressing
'sneak' (shift by default) will land it. After landing, it's possible to unboard
('move') or lift off ('jump'). A ship can be boarded by pressing 'use' (right-
click by default) on any of its nodes.

Some planets may have a few colorful piñatas scattered over their surface.
Breaking them affords new spaceship parts as random loot. These can be used to
modify one's ship or create a new one.

## Mods
This is a list of the components that make up this game. Each of these mods can
be used by itself, as long as its dependencies are satisfied.

Name | Dependencies | Description
---- | ------------ | -----------
`nv_planetgen` | None | Generates planet terrain. See its `README.md` for instructions on advanced usage.
`nv_ships` | `nv_player` | Adds spaceships that can be built from nodes.
`nv_player` | `player_api` | Adds player models and tools.
`nv_game` | `nv_planetgen`, `nv_ships` | Introduces a basic minigame on top of other mods.

## TODO
 * Add minerals and ores
 * Add more complex flora
 * Add fauna
 * Add player mechanics
 * Add basic items
 * Add basic crafting
 * Add interplanetary space
 * Add interstellar travel
 * Improve all of the above
