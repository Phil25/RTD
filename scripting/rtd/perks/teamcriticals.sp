
/*
This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd2.sp instead of this one.

*** HOW TO ADD A PERK ***
A quick note: This tutorial may not be kept up to date; for an updated one, go to the plugin's thread.
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

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

#define MINICRIT TFCond_Buffed
#define FULLCRIT TFCond_CritOnFirstBlood

float	g_fTeamCritsRange	= 270.0;
bool	g_bTeamCritsFull	= true;

bool	g_bHasTeamCriticals[MAXPLAYERS+1] = {false, ...};
int		g_iCritBoostEnt[MAXPLAYERS+1][MAXPLAYERS+1];
int		g_iCritBoostsGetting[MAXPLAYERS+1] = {0, ...};

void TeamCriticals_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		TeamCriticals_ApplyPerk(client, sPref);
	
	else
		TeamCriticals_RemovePerk(client);

}

void TeamCriticals_ApplyPerk(int client, const char[] sPref){

	TeamCriticals_ProcessSettings(sPref);
	
	g_bHasTeamCriticals[client] = true;
	TF2_AddCondition(client, g_bTeamCritsFull ? FULLCRIT : MINICRIT);
	g_iCritBoostsGetting[client]++;
	
	CreateTimer(0.25, Timer_DrawBeamsFor, GetClientSerial(client), TIMER_REPEAT);

}

void TeamCriticals_RemovePerk(int client){

	g_bHasTeamCriticals[client] = false;
	TF2_RemoveCondition(client, g_bTeamCritsFull ? FULLCRIT : MINICRIT);
	g_iCritBoostsGetting[client]--;
	
	for(int i = 1; i <= MaxClients; i++){
	
		if(g_iCritBoostEnt[client][i] > MaxClients)
			TeamCriticals_SetCritBoost(client, i, false, 0);
	
	}

}

public Action Timer_DrawBeamsFor(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;
	
	if(!g_bHasTeamCriticals[client])
		return Plugin_Stop;
	
	TeamCriticals_DrawBeamsFor(client);
	
	return Plugin_Continue;

}

void TeamCriticals_DrawBeamsFor(int client){

	int iTeam = GetClientTeam(client);
	for(int i = 1; i <= MaxClients; i++){
	
		if(i == client)
			continue;
		
		if(!IsClientInGame(i)){
		
			if(g_iCritBoostEnt[client][i] > MaxClients)
				TeamCriticals_SetCritBoost(client, i, false, iTeam);
			
			continue;
		
		}
		
		if(!TeamCriticals_IsValidTarget(client, i, iTeam)){
		
			if(g_iCritBoostEnt[client][i] > MaxClients)
				TeamCriticals_SetCritBoost(client, i, false, iTeam);
		
			continue;
		
		}
		
		if(!CanEntitySeeTarget(client, i)){
		
			if(g_iCritBoostEnt[client][i] > MaxClients)
				TeamCriticals_SetCritBoost(client, i, false, iTeam);
			
			continue;
		
		}
		
		if(g_iCritBoostEnt[client][i] <= MaxClients)
			TeamCriticals_SetCritBoost(client, i, true, iTeam);
	
	}

}

bool TeamCriticals_IsValidTarget(int client, int iTrg, int iClientTeam){
	
	float fPos[3], fEndPos[3];
	GetClientAbsOrigin(client, fPos);
	GetClientAbsOrigin(iTrg, fEndPos);
	
	if(GetVectorDistance(fPos, fEndPos) > g_fTeamCritsRange)
		return false;
	
	if(TF2_IsPlayerInCondition(iTrg, TFCond_Cloaked))
		return false;
	
	int iEndTeam = GetClientTeam(iTrg);
	
	if(TF2_IsPlayerInCondition(iTrg, TFCond_Disguised)){
	
		if(iClientTeam == iEndTeam)
			return false;
		
		else
			return true;
	
	}
	
	return (iClientTeam == iEndTeam);

}

void TeamCriticals_SetCritBoost(int client, int iTrg, bool bSet, int iTeam){

	g_iCritBoostsGetting[iTrg] += bSet ? 1 : -1;

	if(bSet){
	
		g_iCritBoostEnt[client][iTrg] = ConnectWithBeam(client, iTrg, iTeam == 2 ? 255 : 64, 64, iTeam == 2 ? 64 : 255);
	
		if(g_iCritBoostsGetting[iTrg] < 2)
			TF2_AddCondition(iTrg, g_bTeamCritsFull ? FULLCRIT : MINICRIT);
	
	}else{
	
		if(IsValidEntity(g_iCritBoostEnt[client][iTrg]))
			AcceptEntityInput(g_iCritBoostEnt[client][iTrg], "Kill");
		
		g_iCritBoostEnt[client][iTrg] = 0;
	
		if(g_iCritBoostsGetting[iTrg] < 1)
			TF2_RemoveCondition(iTrg, g_bTeamCritsFull ? FULLCRIT : MINICRIT);
	
	}

}

void TeamCriticals_ProcessSettings(const char[] sSettings){
	
	char[][] sPieces = new char[2][8];
	ExplodeString(sSettings, ",", sPieces, 2, 8);

	g_fTeamCritsRange = StringToFloat(sPieces[0]);
	g_bTeamCritsFull = StringToInt(sPieces[1]) > 0 ? true : false;

}
