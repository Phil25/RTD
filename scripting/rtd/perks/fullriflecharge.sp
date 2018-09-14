
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

int		g_iSniperPrimary[MAXPLAYERS+1]	= {0, ...};
bool	g_bHasFullCharge[MAXPLAYERS+1]	= {false, ...};
bool	g_bHasBow[MAXPLAYERS+1]			= {false, ...};

void FullRifleCharge_Start(){

	HookEvent("post_inventory_application", Event_FullRifleCharge_Resupply, EventHookMode_Post);

}

public void FullRifleCharge_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		FullRifleCharge_ApplyPerk(client);
	
	else
		g_bHasFullCharge[client] = false;

}

void FullRifleCharge_ApplyPerk(int client){
	
	FullRifleCharge_SetSniperPrimary(client);
	g_bHasFullCharge[client] = true;

}

void FullRifleCharge_SetSniperPrimary(int client){

	int iWeapon = GetPlayerWeaponSlot(client, 0);
	if(iWeapon > MaxClients && IsValidEntity(iWeapon)){
	
		char sClass[32];GetEdictClassname(iWeapon, sClass, sizeof(sClass));
		if(StrContains(sClass, "tf_weapon_sniperrifle") > -1){
			
			g_iSniperPrimary[client]	= iWeapon;
			g_bHasBow[client]			= false;
		
		}else if(StrContains(sClass, "tf_weapon_compound_bow") > -1){
			
			g_iSniperPrimary[client]	= iWeapon;
			g_bHasBow[client]			= true;
		
		}
	
	}

}

void FullRifleCharge_OnConditionAdded(int client, TFCond condition){

	if(!IsClientInGame(client))		return;
	if(!g_bHasFullCharge[client])	return;
	if(condition != TFCond_Slowed)	return;

	if(g_iSniperPrimary[client] > MaxClients && IsValidEntity(g_iSniperPrimary[client]))
		SetEntPropFloat(
			g_iSniperPrimary[client], Prop_Send,
			g_bHasBow[client] ? "m_flChargeBeginTime"	: "m_flChargedDamage",
			g_bHasBow[client] ? GetGameTime()-1.0		: 150.0
		);

}

public void Event_FullRifleCharge_Resupply(Handle hEvent, const char[] sEventName, bool bDontBroadcast){

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client == 0) return;

	if(!g_bHasFullCharge[client])
		return;
	
	FullRifleCharge_SetSniperPrimary(client);

}
