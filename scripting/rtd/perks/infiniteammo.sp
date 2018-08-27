
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

bool	g_bResupplyAmmo[MAXPLAYERS+1]	= {false, ...};
bool	g_bNoReload						= true;
int		g_iWeaponCache[MAXPLAYERS+1][3];

int		g_iOffsetClip, g_iOffsetAmmo, g_iOffsetAmmoType;

void InfiniteAmmo_Start(){

	g_iOffsetClip		= FindSendPropInfo("CTFWeaponBase", "m_iClip1");
	g_iOffsetAmmo		= FindSendPropInfo("CTFPlayer", "m_iAmmo");
	g_iOffsetAmmoType	= FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");

}

void InfiniteAmmo_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		InfiniteAmmo_ApplyPerk(client, StringToInt(sPref));
	
	else
		g_bResupplyAmmo[client] = false;

}

void InfiniteAmmo_ApplyPerk(int client, int iNoReload){

	g_bNoReload					= (iNoReload < 1) ? true : false;
	g_bResupplyAmmo[client]		= true;
	
	CreateTimer(0.25, Timer_ResupplyAmmo, GetClientSerial(client), TIMER_REPEAT);

}

public Action Timer_ResupplyAmmo(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);

	if(!IsValidClient(client))		return Plugin_Stop;
	if(!g_bResupplyAmmo[client])	return Plugin_Stop;
	
	InfiniteAmmo_Resupply(client);
	
	return Plugin_Continue;

}

void InfiniteAmmo_Resupply(int client){

	switch(TF2_GetPlayerClass(client)){

		case TFClass_Engineer:{
			SetEntProp(client, Prop_Data, "m_iAmmo", 200, 4, 3);
		}
		
		case TFClass_Spy:{
			SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 100.0);
		}

	}
	
	int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
		return;
	
	switch(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex")){
	
		case 441,442,588:{
		
			SetEntPropFloat(iWeapon, Prop_Send, "m_flEnergy", 20.0);
		
		}
		
		case 307:{
		
			SetEntProp(iWeapon, Prop_Send, "m_bBroken", 0);
			SetEntProp(iWeapon, Prop_Send, "m_iDetonated", 0);
		
		}
		
		default:{
		
			if(g_iWeaponCache[client][0] != iWeapon){
			
				g_iWeaponCache[client][0] = iWeapon;
				g_iWeaponCache[client][1] = GetClip(iWeapon);
				g_iWeaponCache[client][2] = GetAmmo(client, iWeapon);
			
			}else{
			
				int iClip = g_bNoReload ? GetClip(iWeapon) : -1;
				if(iClip > -1){
				
					if(iClip > g_iWeaponCache[client][1])
						g_iWeaponCache[client][1] = iClip;
					else if(iClip < g_iWeaponCache[client][1])
						SetClip(iWeapon, g_iWeaponCache[client][1]);
				
				}
			
				int iAmmo = GetAmmo(client, iWeapon);
				if(iAmmo > -1){
				
					if(iAmmo > g_iWeaponCache[client][2])
						g_iWeaponCache[client][2] = iAmmo;
					else if(iAmmo < g_iWeaponCache[client][2])
						SetAmmo(client, iWeapon, g_iWeaponCache[client][2]);
				
				}
			
			}
		
		}
	
	}

}

//The bellow are ripped straight from the original RTD

void SetAmmo(int client, int iWeapon, int iAmount){

	int iOffset = g_iOffsetAmmo + GetEntData(iWeapon, g_iOffsetAmmoType, 1) * 4;
	SetEntData(client, iOffset, iAmount);

}

int GetAmmo(int client, int iWeapon){

	int iAmmoType = GetEntData(iWeapon, g_iOffsetAmmoType, 1);
	if(iAmmoType == 4) return -1;
	
	return GetEntData(client, g_iOffsetAmmo + iAmmoType * 4);

}

void SetClip(int iWeapon, int iAmount){

	SetEntData(iWeapon, g_iOffsetClip, iAmount, _, true);

}

int GetClip(int iWeapon){

	return GetEntData(iWeapon, g_iOffsetClip);

}
