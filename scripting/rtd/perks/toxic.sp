
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

#define TOXIC_PARTICLE "eb_aura_angry01"

float	g_fToxicRange		= 128.0;
float	g_fToxicInterval	= 0.25;
float	g_fToxicDamage		= 24.0;

bool	g_bIsToxic[MAXPLAYERS+1]		= {false, ...};
int		g_iToxicParticle[MAXPLAYERS+1]	= {0, ...};

void Toxic_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		Toxic_ApplyPerk(client, sPref);
	
	else
		g_bIsToxic[client] = false;

}

void Toxic_ApplyPerk(int client, const char[] sSettings){

	Toxic_ProcessSettings(sSettings);

	g_bIsToxic[client]		 = true;
	g_iToxicParticle[client] = CreateParticle(client, TOXIC_PARTICLE);
	
	CreateTimer(g_fToxicInterval, Timer_Toxic, GetClientSerial(client), TIMER_REPEAT);

}

public Action Timer_Toxic(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;
	
	if(!g_bIsToxic[client]){
	
		if(g_iToxicParticle[client] > MaxClients && IsValidEntity(g_iToxicParticle[client])){
			AcceptEntityInput(g_iToxicParticle[client], "Kill");
			g_iToxicParticle[client] = 0;
		}
		
		return Plugin_Stop;
	
	}
	
	Toxic_HurtSurroundings(client);
	
	return Plugin_Continue;

}

void Toxic_HurtSurroundings(client){
	
	float fClientPos[3];
	GetClientAbsOrigin(client, fClientPos);
	
	for(int i = 1; i <= MaxClients; i++){
	
		if(!Toxic_IsValidTargetFor(client, i)) continue;
		
		float fTargetPos[3];
		GetClientAbsOrigin(i, fTargetPos);
		
		float fDistance = GetVectorDistance(fClientPos, fTargetPos);
		if(fDistance < g_fToxicRange)
			SDKHooks_TakeDamage(i, 0, client, g_fToxicDamage, DMG_BLAST);
	
	}

}

stock bool Toxic_IsValidTargetFor(int client, int target){

	if(client == target)
		return false;
	
	if(!IsClientInGame(target))
		return false;
		
	if(!IsPlayerAlive(target))
		return false;
	
	if(!CanEntitySeeTarget(client, target))
		return false;
	
	return CanPlayerBeHurt(target, client);

}

void Toxic_ProcessSettings(const char[] sSettings){
	
	char[][] sPieces = new char[3][8];
	ExplodeString(sSettings, ",", sPieces, 3, 8);

	g_fToxicRange		= StringToFloat(sPieces[0]);
	g_fToxicInterval	= StringToFloat(sPieces[1]);
	g_fToxicDamage		= StringToFloat(sPieces[2]);

}
