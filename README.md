This is a collection of addons and scripts I personally use for multiple purposes. Certain addons can be compiled into a pk3.

# Gameplay
These are addons I always have loaded, as they help improve my gameplay experience.

## Freecam	
Adds an extensive and customizable free-camera, togglable by command, "`freecam`".

## Exacto-Cam
A camera script that replaces the vanilla camera with a more responsive version. Based off Roblox's camera, and also adds its "invisicam", where it can make objects blocking your view translucent.

# Libraries
These hold Lua scripts that provide utilities for their purposes.

## Vec3.lua
Adds a Vec3 object. See inside for details.
```lua
local forwardVector = Vec3.New(10*FU, 0, 0)
local sidewaysVector = Vec3.New(0, 10*FU, 0)
local myVector = forwardVector + sidewaysVector
myVector:ToMobjMom(mobj, false)
```

## Vec2.lua
Similar to Vec3.lua.

## GeneralMath.lua
Adds general math functions, like `P_RandomFixedRange` and `R_PointTo3DAngles`. See inside for more details.

## ObjectTracking.lua
A highly accurate world-2-screen script. Based off the projection code in SRB2Kart Saturn.

# Debug
These scripts provide some simple debugging utilities.

## ForceRespawns.lua
Forces a player to respawn after 3 seconds. Useful for bots.

## PFlagsDebug.lua
Togglable through `pflagsdebug`, draws player-related flags to HUD.

## Teleportation.lua
Adds a command that warps you any coordinate.

# Cheats

## ESP.lua
Wallhacks. Draws players to your HUD through walls.

## TeleEmblem.lua
Teleports you to any emblem in the map with the `tpemblem` command.

## Wombo.lua
Togglable through `wombo`, can disable i-frames for all players.