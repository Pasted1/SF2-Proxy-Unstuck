# SF2-Proxy-Unstuck

 This gives the ability to unstuck a player that has spawned in as a proxy and somehow got stuck by a prop or a wrong location.



# Requirements
1. CBaseNPC : https://github.com/TF2-DMB/CBaseNPC
2. Slender Fortress Modified 1.8.0 (https://github.com/Mentrillum/Slender-Fortress-Modified-Versions/tree/1-8-0-rewrite)
 
   Note: This has also been tested on an earlier version (1.7.5)

# How it works:

 *  When a player is chosen as a proxy and is going to spawn this plugin simply checks if the player is stuck or not and moves the player to the closest point available and if it fails to do that it simply spawns the player in random RED Spawn (info_player_teamspawn) locations instead and if for some rare reason the map does not have "info_player_teamspawn" and the plugin fails to move the player it will simply just log an error and player will remain stuck.

# How to use:

1. Place in your /scripting/ folder
2. Compile
3. Place in /plugins/


# Important Note:

 *  I have only tested this successfully in my own test server with bots, this has not been tested in real gameplay with more players where errors might occur. Please report back with any issues you might find.
 
