
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

#define MODEL_BOMB				"models/props_lakeside_event/bomb_temp_hat.mdl"

#define SOUND_FTIMEBOMB_TICK	"buttons/button17.wav"
#define SOUND_FTIMEBOMB_GOFF	"weapons/cguard/charging.wav"
#define SOUND_FEXPLODE			"misc/halloween/spell_fireball_impact.wav"

#define TICK_SLOW			0.75
#define TICK_FAST			0.35

int		g_iFTimebombTicks	= 10;
float	g_fFTimebombRadius	= 512.0;

bool	g_bHasFTimebomb[MAXPLAYERS+1]			= {false, ...};
int		g_iFTimebombClientTicks[MAXPLAYERS+1]	= {0, ...};
float	g_fFTimebombClientBeeps[MAXPLAYERS+1]	= {TICK_SLOW, ...};
int		g_iFTimebombHead[MAXPLAYERS+1]			= {0, ...};
int		g_iFTimebombState[MAXPLAYERS+1]			= {0, ...};

int		g_iFTimebombFlame[MAXPLAYERS+1]			= {0, ...};

void FireTimebomb_Start(){

	PrecacheModel(MODEL_BOMB);
	
	PrecacheSound(SOUND_FEXPLODE);
	PrecacheSound(SOUND_FTIMEBOMB_TICK);
	PrecacheSound(SOUND_FTIMEBOMB_GOFF);

}

void FireTimebomb_Perk(int client, const char[] sPref, bool apply){

	if(!apply)
		return;
	
	g_bHasFTimebomb[client] = true;
	
	FireTimebomb_ProcessSettings(sPref);
	
	if(g_iFTimebombHead[client] <= MaxClients)
		g_iFTimebombHead[client] = FireTimebomb_SpawnBombHead(client);
	
	int iSerial = GetClientSerial(client);
	
	CreateTimer(1.0, Timer_FireTimebomb_Tick, iSerial, TIMER_REPEAT);
	
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");

}

public Action Timer_FireTimebomb_Tick(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);

	if(!IsValidClient(client))
		return Plugin_Stop;
	
	if(!g_bHasFTimebomb[client])
		return Plugin_Stop;
	
	g_iFTimebombClientTicks[client]++;
	
	if(g_iFTimebombHead[client] > MaxClients && IsValidEntity(g_iFTimebombHead[client]))
		if(g_iFTimebombClientTicks[client] >= RoundToFloor(g_iFTimebombTicks*0.3))
			if(g_iFTimebombClientTicks[client] < RoundToFloor(g_iFTimebombTicks*0.7))
				FireTimebomb_BombState(client, 1);
			else FireTimebomb_BombState(client, 2);
	
	
	if(g_iFTimebombClientTicks[client] == g_iFTimebombTicks-1)
		EmitSoundToAll(SOUND_FTIMEBOMB_GOFF, client);
	else if(g_iFTimebombClientTicks[client] >= g_iFTimebombTicks){
	
		FireTimebomb_Explode(client);
		return Plugin_Stop;
	
	}
	
	return Plugin_Continue;

}

public Action Timer_FireTimebomb_Beep(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);

	if(!IsValidClient(client))
		return Plugin_Stop;
	
	if(!g_bHasFTimebomb[client])
		return Plugin_Stop;
	
	EmitSoundToAll(SOUND_FTIMEBOMB_TICK, client);
	
	CreateTimer(g_fFTimebombClientBeeps[client], Timer_FireTimebomb_Beep, GetClientSerial(client));
	
	return Plugin_Stop;

}

void FireTimebomb_BombState(int client, int iState){

	if(iState == g_iFTimebombState[client])
		return;

	switch(iState){
	
		case 1:{
		
			EmitSoundToAll(SOUND_FTIMEBOMB_TICK, client);
			g_fFTimebombClientBeeps[client] = TICK_SLOW;
			CreateTimer(g_fFTimebombClientBeeps[client], Timer_FireTimebomb_Beep, GetClientSerial(client));
		
		}
		
		case 2:{
		
			g_fFTimebombClientBeeps[client] = TICK_FAST;
		
		}
	
	}
	
	SetEntProp(g_iFTimebombHead[client], Prop_Send, "m_nSkin", g_iFTimebombState[client]+1);
	
	g_iFTimebombState[client] = iState;

}

void FireTimebomb_OnRemovePerk(int client){

	if(g_bHasFTimebomb[client])
		FireTimebomb_Explode(client, true);

}

void FireTimebomb_Explode(int client, bool bSilent=false){

	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");

	g_iFTimebombClientTicks[client]	= 0;
	g_bHasFTimebomb[client]			= false;
	g_fFTimebombClientBeeps[client]	= TICK_SLOW;
	g_iFTimebombState[client]		= 0;

	if(g_iFTimebombHead[client] > MaxClients && IsValidEntity(g_iFTimebombHead[client]))
		AcceptEntityInput(g_iFTimebombHead[client], "Kill");

	if(g_iFTimebombFlame[client] > MaxClients && IsValidEntity(g_iFTimebombFlame[client]))
		AcceptEntityInput(g_iFTimebombFlame[client], "Kill");
	
	g_iFTimebombHead[client] = 0;
	g_iFTimebombFlame[client] = 0;
	
	if(bSilent)
		return;

	float fPos[3]; GetClientAbsOrigin(client, fPos);
	int iPlayersIgnited = 0;
	for(int i = 1; i <= MaxClients; i++){
	
		if(i == client || !IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if(!CanPlayerBeHurt(i, client))
			continue;
		
		if(!CanEntitySeeTarget(client, i))
			continue;
		
		float fPosTarget[3];
		GetClientAbsOrigin(i, fPosTarget);
		
		if(GetVectorDistance(fPos, fPosTarget) <= g_fFTimebombRadius){
		
			TF2_IgnitePlayer(i, client);
			iPlayersIgnited++;
		
		}
	
	}
	
	int iExplosion = CreateParticle(client, "bombinomicon_burningdebris");
	CreateTimer(1.0, Timer_FTimebombRemoveTempParticle, EntIndexToEntRef(iExplosion));
	
	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Timebomb_Ignite", LANG_SERVER, 0x03, iPlayersIgnited, 0x01);
	EmitSoundToAll(SOUND_FEXPLODE, client);
	TF2_IgnitePlayer(client, client);

}

public Action Timer_FTimebombRemoveTempParticle(Handle hTimer, int iRef){

	int iEnt = EntRefToEntIndex(iRef);
	
	if(iEnt <= MaxClients)
		return Plugin_Stop;
	
	if(!IsValidEntity(iEnt))
		return Plugin_Stop;
	
	AcceptEntityInput(iEnt, "Kill");
	
	return Plugin_Stop;

}

int FireTimebomb_SpawnBombHead(int client){

	int iBomb = CreateEntityByName("prop_dynamic");
	
	DispatchKeyValue(iBomb, "model", MODEL_BOMB);
	
	DispatchSpawn(iBomb);
	
	SetVariantString("!activator");
	AcceptEntityInput(iBomb, "SetParent", client, -1, 0);
	
	TFClassType clsPlayer = TF2_GetPlayerClass(client);
	
	if(clsPlayer == TFClass_Pyro || clsPlayer == TFClass_Engineer)
		SetVariantString("OnUser1 !self,SetParentAttachment,head,0.0,-1");
	else
		SetVariantString("OnUser1 !self,SetParentAttachment,eyes,0.0,-1");
	
	AcceptEntityInput(iBomb, "AddOutput");
	AcceptEntityInput(iBomb, "FireUser1");
	
	float fOffs[3];
	fOffs[2] = 64.0;
	
	g_iFTimebombFlame[client] = CreateParticle(client, "rockettrail", true, "", fOffs);
	
	return iBomb;

}

void FireTimebomb_ProcessSettings(const char[] sSettings){
	
	char[][] sPieces = new char[2][8];
	ExplodeString(sSettings, ",", sPieces, 2, 8);

	g_iFTimebombTicks	= StringToInt(sPieces[0]);
	g_fFTimebombRadius	= StringToFloat(sPieces[1]);

}