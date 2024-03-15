# Changelog
## [0.4.2] - unreleased
### Performance
 - Added support for the new async mapgen API in Minetest 5.9, with fallback for older versions.

## [0.4.1] - 28-12-2023
### Fixed
 - Erratic jumps after landing a ship for the second time.

## [0.4.0] - 28-12-2023
This is a major release; it breaks compatibility with existing worlds and adds
many new features to the game. Most fixes and small changes made during its
development have been ported to the 0.3.x versions.

### Added
 - Mods `nv_flora`, `nv_gui` and `nv_encyclopedia`.
 - Short and tall plants, cave flora, cacti, vines, lily pads, trees and large mushrooms.
 - 17 kinds of floral nodes.
 - Underground lakes.
 - Ability to break nodes.
 - A GUI to keep track of your discovered planets and floral species.

### Changed
 - Made caves larger, as well as less common and predictable.
 - Balanced cliff generation.

### Performance
 - Dramatically reduced the number of necessary node registrations.
 - Now uses a single entity type for ships (thanks to Siegmentation Fault).

### Fixed
 - Now ships are preserved even if planets are re-generated.

## [0.3.3] - 24-12-2023
### Fixed
 - Players being placed in space with no ship upon respawning.
 - Incorrect rotation of some node entities on liftoff.

## [0.3.2] - 13-12-2023
### Fixed
 - Bumped maximum supported engine version to 5.8.

## [0.3.1] - 03-08-2023
### Fixed
 - Re-encoded the main menu music so it can play.

## [0.3.0] - 03-08-2023
This is a major release; it breaks compatibility with existing worlds and adds
many new features to the game. Most fixes and small changes made during its
development have been ported to the 0.2.x versions.

### Added
 - Mod `nv_universe`.
 - Huge planets with their own atmospheric effects.
 - Outer space around each planet.
 - A GUI to travel between planets and planetary systems.
 - Planet thumbnails and descriptions.
 - Cliffs and more varied terrain shapes.
 - Ice nodes covering cold planets.
 - Support for dynamic shadows.

### Changed
 - New main menu music, The Nodeverse Awaits version 2.
 - Tweaked cave generation.

## [0.2.5] - 03-08-2023
### Fixed
 - Fix unstable data storage causing ships to malfunction.

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
