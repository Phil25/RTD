
/*
This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd2.sp instead of this one.

*** HOW TO ADD A PERK ***
A quick note: This tutorial may not be kept up to date; for an updated one, go to the plugin's thread.

1. Set up:
	a) Have <perkname>.sp in scripting/rtd.
	b) Add it to the includes in scripting/rtd/#perks.sp.
	c) Add a new section with a correct ID (highest one +1) to the config/rtd2_perks.cfg and set its settings.

2. Edit scripting/rtd/#manager.sp
	a) In a function named ManagePerk() add a new case to the switch() with your perk's ID.
	b) In the added case specify a function which is going to execute from <perkname>.sp with parameters:
		1) @client			- the client the perk should be applied to/removed from
		2) @fSpecialPref	- the optional "special" value in config/rtd2_perks.cfg
		2) @enable			- to specify whether the perk should be applied/removed
	c) OPTIONAL: You can specify a function in your perk which should run at OnMapStart() in the Forward_OnMapStart() function.
		You will need it if you'd want to, for example, precache a sound or loop through existing clients.
	d) OPTIONAL: You can specify a function in your perk which should run at OnPlayerRunCmd() in the Forward_OnPlayerRunCmd() function.
		You can use it if you'd need something to run each frame or on a certain button press.
		NOTE: The forwarded client is guaranteed to be valid BUT NOT GUARANTEED IF THEY ARE ALIVE.

3. Script your perk:
	a) Create a public function in <perkname>.sp with parameters @client, @iPref, @bool:apply as an example below
	   - This is the only function used to transfer info between the core and the include
	   - You don't need to include any includes that are in the rtd2.sp
	b) NOTE: If you need to transfer the iPref to a different function, set it globally but remember to use an unique name
	c) Name it AS SAME AS you named the function in the added case in the switch() in #manager.sp
	d) From there, script the functionality like there's no tomorrow
	e) You are free to use IsValidClient(). It returns false when:
		- An incorrect client index is specified
		- Client is not in game
		- Client is fake (bot)
		- Client is Coaching

4. Compile rtd2.sp and you're good to go!

*/

float	g_fBaseTinyMann[MAXPLAYERS+1]	= {1.0, ...};
bool	g_bIsTinyMann[MAXPLAYERS+1]		= {false, ...};
float	g_fTinyMannScale				= 0.15;

void TinyMann_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		TinyMann_ApplyPerk(client, StringToFloat(sPref));

	else
		TinyMann_RemovePerk(client);

}

void TinyMann_ApplyPerk(int client, float fMultiplayer){

	g_bIsTinyMann[client]	= true;
	g_fTinyMannScale		= fMultiplayer;
	
	TF2Attrib_SetByDefIndex(client, 2048, 1/g_fTinyMannScale/2);
	g_fBaseTinyMann[client] = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", fMultiplayer);

}

void TinyMann_RemovePerk(int client){

	g_bIsTinyMann[client] = false;
	
	TF2Attrib_RemoveByDefIndex(client, 2048);
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_fBaseTinyMann[client]);
	
	FixPotentialStuck(client);

}
