# Changelog
## [0.3.0] - unreleased
This is a major release; it breaks compatibility with existing worlds and adds
many new features to the game. Most fixes and small changes made during its
development have been ported to the 0.2.x versions.

### Added
 - Mod `nv_universe`.
 - Huge planets with their own atmospheric effects.
 - A GUI to travel across planets.
 - Support for dynamic shadows.

### Removed
 - Default "piñata" mini-game.

## [0.2.4] - 30-06-2023
### Fixed
 - Bump max supported Minetest version to 5.7.

## [0.2.3] - 30-06-2023
### Fixed
 - Fix coordinates above 2048 getting corrupted on save.

## [0.2.2] - 25-08-2022
### Changed
 - Replace game icon with Zaraz7's new version.

## [0.2.1] - 16-08-2022
### Changed
 - Update title music with an intro and make the harp quieter.

## [0.2.0] - 10-08-2022
This is a major release; it breaks compatibility with existing worlds and adds
many new features to the game. Most fixes and small changes made during its
development have been ported to the 0.1.x versions.

### Added
 - Mods `nv_game`, `nv_ships` and `nv_player`.
 - A new mini-game about finding ship parts inside piñatas.
 - Ability to build ships out of nodes and fly them.
 - Eight node varieties to build a ship with.
 - Colored spaceship hull, can be applied to ship nodes.
 - New, simpler flying mechanics, with vertical liftoff and landing.
 - A small ship to start the game with.
 - Custom spacesuit player skin.
 - A title theme, "The Nodeverse awaits"; score included.
 - Four distinct sound effects for spaceship maneuvering.
 - Twelve different footstep sound effects.

### Changed
 - All media are namespaced to improve compatibility with other mods.
 - Bump maximum supported Minetest version to 5.5.

### Removed
 - Mods `nv_rocket` and `autobox`.
 - Default "lunar lander" mini-game.
 - Default rocket mechanics, including item and model.

## [0.1.7] - 31-01-2022
### Fixed
 - Fix badly rotated stone nodes in walls.

### Changed
 - Bump maximum supported Minetest version to 5.5.

## [0.1.6] - 06-01-2022
### Fixed
 - Fix some nodes appearing to generate shadows.
 - Fix spurious grass or snow nodes.
 - Fix Autobox path capitalization.

## [0.1.5] - 28-12-2021
### Changed
 - Adjusted viscosity of liquids.
 - Made water non-pointable.
 - Grass now has an improved bounding box.

### Fixed
 - Fix ocean borders with no walls.
 - Fix snow side texture.
 - Fix inability to lift off from inside liquids.

## [0.1.4] - 29-08-2021
Development on 0.2.x has started. Subsequent 0.1.x versions will be released to
backport fixes and small changes.

### Performance
 - Optimized globalstep mechanism.

## [0.1.3] - 29-08-2021
### Added
 - Custom sky texture.

### Changed
 - Title background is now less harsh to the eyes.

## [0.1.2] - 29-08-2021
### Changed
 - `planetgen` renamed to `nv_planetgen`.
 - `player_api` made into submodule.

## [0.1.1] - 29-08-2021
No-change re-release to follow ContentDB criteria.

## [0.1.0] - 28-08-2021
Initial release.
