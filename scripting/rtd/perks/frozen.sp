
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

int	g_iIceStatue[MAXPLAYERS+1]	= {0, ...};
int	g_iBaseFrozen[MAXPLAYERS+1]	= {255, ...};

public void Frozen_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		Frozen_ApplyPerk(client);
	
	else
		Frozen_RemovePerk(client);

}

void Frozen_ApplyPerk(int client){

	g_iBaseFrozen[client] = Frozen_GetEntityAlpha(client);
	Frozen_Set(client, 0);
	Frozen_DisarmWeapons(client, true);
	
	if(g_iIceStatue[client] < 1){
	
		g_iIceStatue[client] = CreateDummy(client);
		if(g_iIceStatue[client] > MaxClients && IsValidEntity(g_iIceStatue[client]))
			SetClientViewEntity(client, g_iIceStatue[client]);
	
	}
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");

}

void Frozen_RemovePerk(int client){
	
	SetClientViewEntity(client, client);
	
	if(g_iIceStatue[client] > MaxClients && IsValidEntity(g_iIceStatue[client]))
		AcceptEntityInput(g_iIceStatue[client], "Kill");
	
	g_iIceStatue[client] = 0;
	Frozen_Set(client, g_iBaseFrozen[client]);
	Frozen_DisarmWeapons(client, false);
	
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");

}

int CreateDummy(client){

	int iRag = CreateEntityByName("tf_ragdoll");
	if(iRag < 1 || iRag <= MaxClients || !IsValidEntity(iRag))
		return 0;
	
	float fPos[3], fAng[3], fVel[3];
	GetClientAbsOrigin(client, fPos);
	GetClientAbsAngles(client, fAng);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);
	
	TeleportEntity(iRag, fPos, fAng, fVel);
	
	SetEntProp(iRag, Prop_Send, "m_iPlayerIndex", client);
	SetEntProp(iRag, Prop_Send, "m_bIceRagdoll", 1);
	SetEntProp(iRag, Prop_Send, "m_iTeam", GetClientTeam(client));
	SetEntProp(iRag, Prop_Send, "m_iClass", _:TF2_GetPlayerClass(client));
	SetEntProp(iRag, Prop_Send, "m_bOnGround", 1);
	
	//Scale fix by either SHADoW NiNE TR3S or ddhoward (dunno who was first :p)
	//https://forums.alliedmods.net/showpost.php?p=2383502&postcount=1491
	//https://forums.alliedmods.net/showpost.php?p=2366104&postcount=1487
	SetEntPropFloat(iRag, Prop_Send, "m_flHeadScale", GetEntPropFloat(client, Prop_Send, "m_flHeadScale"));
	SetEntPropFloat(iRag, Prop_Send, "m_flTorsoScale", GetEntPropFloat(client, Prop_Send, "m_flTorsoScale"));
	SetEntPropFloat(iRag, Prop_Send, "m_flHandScale", GetEntPropFloat(client, Prop_Send, "m_flHandScale"));
	
	SetEntityMoveType(iRag, MOVETYPE_NONE);
	
	DispatchSpawn(iRag);
	ActivateEntity(iRag);
	
	return iRag;

}

void Frozen_Set(int client, int iValue){
	
	if(GetEntityRenderMode(client) == RENDER_NORMAL)
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	
	Frozen_SetEntityAlpha(client, iValue);
	
	int iWeapon = 0;
	for(int i = 0; i < 5; i++){
	
		iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;
		
		if(GetEntityRenderMode(iWeapon) == RENDER_NORMAL)
			SetEntityRenderMode(iWeapon, RENDER_TRANSCOLOR);
		
		Frozen_SetEntityAlpha(iWeapon, iValue);
	
	}
	
	char sClass[24];
	for(int i = MaxClients+1; i < GetMaxEntities(); i++){
	
		if(!IsCorrectWearable(client, i, sClass, sizeof(sClass))) continue;
		
		if(GetEntityRenderMode(i) == RENDER_NORMAL)
			SetEntityRenderMode(i, RENDER_TRANSCOLOR);
		
		Frozen_SetEntityAlpha(i, iValue);
	
	}

}

stock int Frozen_GetEntityAlpha(int entity){

	return GetEntData(entity, GetEntSendPropOffs(entity, "m_clrRender") + 3, 1);

}

stock void Frozen_SetEntityAlpha(int entity, int value){

	SetEntData(entity, GetEntSendPropOffs(entity, "m_clrRender") + 3, value, 1, true);

}

void Frozen_DisarmWeapons(int client, bool bDisarm){

	int iWeapon = 0;
	for(int i = 0; i < 3; i++){
	
		iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;
		
		SetEntPropFloat(iWeapon, Prop_Data, "m_flNextPrimaryAttack",	bDisarm ? GetGameTime() + 86400.0 : 0.1);
		SetEntPropFloat(iWeapon, Prop_Data, "m_flNextSecondaryAttack",	bDisarm ? GetGameTime() + 86400.0 : 0.1);
	
	}

}