
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

int		g_iMediGunCond[MAXPLAYERS+1]	= {-1, ...};
int		g_iMediGun[MAXPLAYERS+1]		= {0, ...};
bool	g_bRefreshUber[MAXPLAYERS+1]	= {false, ...};
bool	g_bUberComplete[MAXPLAYERS+1]	= {true, ...};

public void FullUbercharge_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		FullUbercharge_ApplyPerk(client);
	
	else
		FullUbercharge_RemovePerk(client);

}

void FullUbercharge_ApplyPerk(int client){

	int iWeapon = GetPlayerWeaponSlot(client, 1);
	if(iWeapon > MaxClients && IsValidEntity(iWeapon)){
	
		char sClass[20];GetEdictClassname(iWeapon, sClass, sizeof(sClass));
		if(strcmp(sClass, "tf_weapon_medigun") == 0){
		
			g_iMediGun[client]		= EntIndexToEntRef(iWeapon);
			g_bRefreshUber[client]	= true;
			g_bUberComplete[client]	= false;
			
			CreateTimer(0.2, Timer_RefreshUber, GetClientSerial(client), TIMER_REPEAT);
			
			int iWeapIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
			switch(iWeapIndex){
			
				case 35:	g_iMediGunCond[client] = view_as<int>(TFCond_Kritzkrieged);	//Kritzkrieg
				case 411:	g_iMediGunCond[client] = view_as<int>(TFCond_MegaHeal);		//Quick-Fix
				case 998:	g_iMediGunCond[client] = -1;								//Screw you, Vaccinator
				default:	g_iMediGunCond[client] = view_as<int>(TFCond_Ubercharged);	//Default
			
			}
		
		}
	
	}

}

void FullUbercharge_RemovePerk(int client){

	g_bRefreshUber[client] = false;

	if(g_iMediGunCond[client] > -1)
		CreateTimer(0.2, Timer_UberchargeEnd, GetClientSerial(client), TIMER_REPEAT);

}

public Action Timer_RefreshUber(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;
	
	if(!g_bRefreshUber[client])
		return Plugin_Stop;
	
	int iMediGun = EntRefToEntIndex(g_iMediGun[client]);
	if(iMediGun <= MaxClients)
		return Plugin_Stop;

	SetEntPropFloat(iMediGun, Prop_Send, "m_flChargeLevel", 1.0);
	return Plugin_Continue;

}

public Action Timer_UberchargeEnd(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;

	int iMediGun = EntRefToEntIndex(g_iMediGun[client]);
	if(iMediGun <= MaxClients){
		g_bUberComplete[client] = true;
		return Plugin_Stop;
	}
	
	if(GetEntPropFloat(iMediGun, Prop_Send, "m_flChargeLevel") > 0.05)
		return Plugin_Continue;
	
	g_bUberComplete[client] = true;
	return Plugin_Stop;

}

void FullUbercharge_OnConditionRemoved(int client, TFCond cond){

	if(g_bUberComplete[client])
		return;
	
	if(view_as<int>(cond) != g_iMediGunCond[client])
		return;

	if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == EntRefToEntIndex(g_iMediGun[client]))
		TF2_AddCondition(client, cond, 2.0);

}
