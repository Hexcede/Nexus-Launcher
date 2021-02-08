# Nexus-Launcher
A special launcher for TheNexusAvenger's Nexus Embedded Editor which improves behaviour of the embedded editor, supporting Roblox Studio Mod Manager, and adds additional behaviour inspired by both.

This is an external manager to NE Editor, just like how RSMM is an external manager for Roblox Studio.

## Features
* Runs the Nexus Embedded Editor Server in the background automatically, and restarts it if it crashes
* Tray icon with various options
* Automatic detection & improvement of Nexus Embedded Editor's Attach functionality
  - Prevents accidental dragging or rescaling of VSCode when a script is open
  - Keeps the editor above Roblox Studio, so it stays visible even if you interact with Studio's UI
* Allows you to select a project directory for Nexus Embedded Editor via a dialogue, or pass one via the command line
  - Can be switched via the tray bar icon
* Compatible with Roblox Studio Mod Manager
  - If the executable is available to the launcher, RSMM will be shown automatically by the launcher
  - Vanilla studio is not shown automatically by default, it can only be launched from the tray icon
    - To change this behaviour, edit the `nexus.ahk` script, and at the top under `Default Config`, change `IntrusiveStudioLaunchMode` to `true` instead of false
	- Then, recompile the launcher with AHK or by running `compile.cmd`

## Note about Rojo & Nexus Embedded Editor
Enabling Rojo's editor functionality seems to consistently cause an engine crash with Nexus, which I believe is caused by the two fighting eachother, though, I'm not sure.
Additionally at the time of writing, some Two-Way Sync code appears to be missing in Rojo 0.5.x and 6.x making the feature non-functional (which doesn't have anything to do with NE Editor, but, it means I couldn't test the compatibility).

I recommend disabling both features before using Rojo with Nexus.

## Planned Features
* Version management UI for Roblox Studio and Roblox Player (Essentially a remake of one of my old projects in UI form, https://github.com/Hexcede/Roblox-Wrapper)
  - Update freezing for Studio and the Player
  - Custom version locations & automatic version discovery for subdirectories
  - Old version downloading
    - This only works for recent Roblox versions, e.g. within the past three months
  - MAYBE fast flag editing for the Roblox Client (This is actually possible in the same exact way Studio Fast Flag editing works)
    - (Investigation required)
* Rewrite of Nexus Embedded Editor in AutoHotKey + C# (E.g. window scaling/positioning/activation)
  - Would require a helper program, likely written in C#
    - Using HTTP polling instead of making requests for updates for additional speed
    - This plus the above, would improve responsiveness tenfold, maybe enough to make the relocation of the editor seamless
  - Would also come with some further improvements that aren't possible with something external