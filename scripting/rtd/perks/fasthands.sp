
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

#define ATTRIB_RATE 6
#define ATTRIB_RELOAD 97

bool	g_bHasFastHands[MAXPLAYERS+1]	= {false, ...};
bool	g_bHasFastHands2[MAXPLAYERS+1]	= {false, ...};
float	g_fFastHandsRateMultiplier		= 2.0;
float	g_fFastHandsReloadMultiplier	= 2.0;

void FastHands_Start(){

	HookEvent("post_inventory_application", FastHands_Resupply, EventHookMode_Post);

}

public void FastHands_OnEntityCreated(int iEnt, const char[] sClassname){

	if(StrEqual(sClassname, "tf_dropped_weapon"))
		SDKHook(iEnt, SDKHook_SpawnPost, FastHands_OnDroppedWeaponSpawn);

}

public void FastHands_OnDroppedWeaponSpawn(int iEnt){

	int client = AccountIDToClient(GetEntProp(iEnt, Prop_Send, "m_iAccountID"));

	if(client == -1)
		return;
	
	if(g_bHasFastHands2[client])
		AcceptEntityInput(iEnt, "Kill");

} 

void FastHands_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		FastHands_ApplyPerk(client, sPref);
	
	else
		FastHands_RemovePerk(client);

}

void FastHands_ApplyPerk(int client, const char[] sSettings){

	FastHands_ProcessSettings(sSettings);

	FastHands_EditClientWeapons(client, true);
	g_bHasFastHands[client]	= true;
	g_bHasFastHands2[client]= true;

}

void FastHands_RemovePerk(int client){

	FastHands_EditClientWeapons(client, false);
	g_bHasFastHands[client] = false;
	CreateTimer(0.5, Timer_FastHands_FullUnset, GetClientSerial(client));

}

public Action Timer_FastHands_FullUnset(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	
	if(client < 1)
		return Plugin_Stop;
	
	g_bHasFastHands2[client] = false;
	
	return Plugin_Stop;

}

void FastHands_EditClientWeapons(int client, bool apply){

	int iWeapon = 0;
	for(int i = 0; i < 3; i++){
	
		iWeapon = GetPlayerWeaponSlot(client, i);
		
		if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;
		
		if(apply){
		
			if(g_fFastHandsRateMultiplier != 0.0)
				TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_RATE, g_fFastHandsRateMultiplier);
			
			if(g_fFastHandsReloadMultiplier != 0.0)
				TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_RELOAD, g_fFastHandsReloadMultiplier);
		
		}else{
		
			TF2Attrib_RemoveByDefIndex(iWeapon, ATTRIB_RATE);
			TF2Attrib_RemoveByDefIndex(iWeapon, ATTRIB_RELOAD);
		
		}
	
	}

}

public void FastHands_Resupply(Handle hEvent, const char[] sEventName, bool bDontBroadcast){

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(client))		return;
	if(!g_bHasFastHands[client])	return;
	
	FastHands_EditClientWeapons(client, true);

}

void FastHands_ProcessSettings(const char[] sSettings){

	char[][] sPieces = new char[2][8];
	ExplodeString(sSettings, ",", sPieces, 2, 8);
	
	g_fFastHandsRateMultiplier		= Pow(StringToFloat(sPieces[0]), -1.0);
	g_fFastHandsReloadMultiplier	= Pow(StringToFloat(sPieces[1]), -1.0);

}