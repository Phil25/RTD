
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

bool	g_bIsForcedTaunt[MAXPLAYERS+1]	= {false, ...};
float	g_fTauntInterval				= 1.0;
bool	g_bShouldTaunt[MAXPLAYERS+1]	= {false, ...};
char	g_sSoundScoutBB[][] = {
	"items/scout_boombox_02.wav",
	"items/scout_boombox_03.wav",
	"items/scout_boombox_04.wav",
	"items/scout_boombox_05.wav"
};

void ForcedTaunt_Start(){

	for(int i = 0; i < sizeof(g_sSoundScoutBB); i++){
	
		PrecacheSound(g_sSoundScoutBB[i]);
	
	}

}

void ForcedTaunt_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		ForcedTaunt_ApplyPerk(client, StringToFloat(sPref));
	
	else
		g_bIsForcedTaunt[client] = false;

}

void ForcedTaunt_ApplyPerk(int client, float fInterval){

	g_fTauntInterval = fInterval;
	
	ForceTaunt_PerformTaunt(client);

	g_bIsForcedTaunt[client] = true;

}

public Action Timer_ForceTaunt(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;

	if(!g_bIsForcedTaunt[client])
		return Plugin_Stop;
	
	ForceTaunt_PerformTaunt(client);
	
	return Plugin_Stop;

}

void ForceTaunt_PerformTaunt(int client){

	if(GetEntProp(client, Prop_Send, "m_hGroundEntity") > -1){
		FakeClientCommand(client, "taunt");
		return;
	}
	
	g_bShouldTaunt[client] = true;
	CreateTimer(0.1, Timer_RetryForceTaunt, GetClientSerial(client), TIMER_REPEAT);

}

public Action Timer_RetryForceTaunt(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;

	if(!g_bIsForcedTaunt[client] || !g_bShouldTaunt[client])
		return Plugin_Stop;
	
	if(GetEntProp(client, Prop_Send, "m_hGroundEntity") < 0)
		return Plugin_Continue;
	
	g_bShouldTaunt[client] = false;
	FakeClientCommand(client, "taunt");
	
	return Plugin_Stop;

}

void ForcedTaunt_OnConditionAdded(int client, TFCond condition){

	if(g_bIsForcedTaunt[client] && condition == TFCond_Taunting)
		EmitSoundToAll(g_sSoundScoutBB[GetRandomInt(0, sizeof(g_sSoundScoutBB)-1)], client);

}

void ForcedTaunt_OnConditionRemoved(int client, TFCond condition){

	if(g_bIsForcedTaunt[client] && condition == TFCond_Taunting)
		CreateTimer(g_fTauntInterval, Timer_ForceTaunt, GetClientSerial(client));

}
