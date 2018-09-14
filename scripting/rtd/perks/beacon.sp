
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

#define SOUND_BEEP "buttons/blip1.wav"

bool	g_bIsBeaconed[MAXPLAYERS+1]		= {false, ...};
float	g_fBeaconInterval				= 1.0;
float	g_fBeaconRadius					= 375.0;
int		g_iSpriteBeam, g_iSpriteHalo;

void Beacon_Start(){

	PrecacheSound(SOUND_BEEP);
	g_iSpriteBeam		= PrecacheModel("materials/sprites/laser.vmt");
	g_iSpriteHalo		= PrecacheModel("materials/sprites/halo01.vmt");

}

void Beacon_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		Beacon_ApplyPerk(client, sPref);
	
	else
		g_bIsBeaconed[client] = false;

}

void Beacon_ApplyPerk(int client, const char[] sSettings){

	Beacon_ProcessSettings(sSettings);

	CreateTimer(g_fBeaconInterval, Timer_BeaconBeep, GetClientSerial(client), TIMER_REPEAT);
	g_bIsBeaconed[client] = true;

}

public Action Timer_BeaconBeep(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;

	if(!g_bIsBeaconed[client])
		return Plugin_Stop;
	
	Beacon_Beep(client);
	
	return Plugin_Continue;

}

void Beacon_Beep(int client){
	
	float fPos[3]; GetClientAbsOrigin(client, fPos);
	fPos[2] += 10.0;
	
	int iColorGra[4] = {128,128,128,255};
	int iColorRed[4] = {255,75,75,255};
	int iColorBlu[4] = {75,75,255,255};
	
	TE_SetupBeamRingPoint(fPos, 10.0, g_fBeaconRadius, g_iSpriteBeam, g_iSpriteHalo, 0, 15, 0.5, 5.0, 0.0, iColorGra, 10, 0);
	TE_SendToAll();
	
	if(GetClientTeam(client) == _:TFTeam_Red)
		TE_SetupBeamRingPoint(fPos, 10.0, g_fBeaconRadius, g_iSpriteBeam, g_iSpriteHalo, 0, 10, 0.6, 10.0, 0.5, iColorRed, 10, 0);
	else
		TE_SetupBeamRingPoint(fPos, 10.0, g_fBeaconRadius, g_iSpriteBeam, g_iSpriteHalo, 0, 10, 0.6, 10.0, 0.5, iColorBlu, 10, 0);
	
	TE_SendToAll();
	
	EmitSoundToAll(SOUND_BEEP, client);

}

void Beacon_ProcessSettings(const char[] sSettings){
	
	char[][] sPieces = new char[2][4];
	ExplodeString(sSettings, ",", sPieces, 2, 4);

	g_fBeaconInterval	= StringToFloat(sPieces[0]);
	g_fBeaconRadius		= StringToFloat(sPieces[1]);

}
