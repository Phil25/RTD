
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

#define DEADLYVOICE_SOUND_ATTACK "weapons/cow_mangler_explosion_charge_04.wav"

char	g_sDeadlyVoiceParticles[][] = {
	"default", "default",
	"powerup_supernova_explode_red",
	"powerup_supernova_explode_blue"
};

bool	g_bHasDeadlyVoice[MAXPLAYERS+1] 		= {false, ...};
int		g_iDeadlyVoiceParticle[MAXPLAYERS+1]	= {0, ...};
float	g_fDeadlyVoiceLastAttack[MAXPLAYERS+1]	= {0.0, ...};

float	g_fDeadlyVoiceRate	= 1.0;
float	g_fDeadlyVoiceRange	= 128.0;
float	g_fDeadlyVoiceDamage= 72.0;

void DeadlyVoice_Start(){

	PrecacheSound(DEADLYVOICE_SOUND_ATTACK);

}

void DeadlyVoice_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		DeadlyVoice_ApplyPerk(client, sPref);
	else
		DeadlyVoice_RemovePerk(client);

}

void DeadlyVoice_ApplyPerk(int client, const char[] sPref){

	DeadlyVoice_ProcessSettings(sPref);
	
	g_bHasDeadlyVoice[client] = true;
	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Attack", LANG_SERVER, 0x03, 0x01);

}

void DeadlyVoice_RemovePerk(int client){

	g_bHasDeadlyVoice[client] = false;

}

void DeadlyVoice_Voice(int client){

	if(!g_bHasDeadlyVoice[client]) return;
	
	float fEngineTime = GetEngineTime();
	
	if(fEngineTime < g_fDeadlyVoiceLastAttack[client] +g_fDeadlyVoiceRate)
		return;
	
	g_fDeadlyVoiceLastAttack[client] = fEngineTime;
	
	if(g_iDeadlyVoiceParticle[client] < 1)
		g_iDeadlyVoiceParticle[client] = CreateParticle(client, g_sDeadlyVoiceParticles[GetClientTeam(client)]);
	
	float fShake[3];
	fShake[0] = GetRandomFloat(-5.0, -25.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fShake);
	
	DeadlyVoice_HurtSurroundings(client);
	EmitSoundToAll(DEADLYVOICE_SOUND_ATTACK, client);
	
	CreateTimer(g_fDeadlyVoiceRate, Timer_DeadlyVoice_DestroyParticle, GetClientSerial(client));

}

public Action Timer_DeadlyVoice_DestroyParticle(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);

	if(g_iDeadlyVoiceParticle[client] > MaxClients && IsValidEntity(g_iDeadlyVoiceParticle[client])){
	
		AcceptEntityInput(g_iDeadlyVoiceParticle[client], "Kill");
		g_iDeadlyVoiceParticle[client] = 0;
	
	}
	
	return Plugin_Stop;

}

void DeadlyVoice_HurtSurroundings(client){

	if(!IsClientInGame(client)) return;
	
	float fClientPos[3];
	GetClientAbsOrigin(client, fClientPos);
	
	for(int i = 1; i <= MaxClients; i++){
	
		if(!DeadlyVoice_IsValidTargetFor(client, i)) continue;
		
		float fTargetPos[3];
		GetClientAbsOrigin(i, fTargetPos);
		
		float fDistance = GetVectorDistance(fClientPos, fTargetPos);
		if(fDistance < g_fDeadlyVoiceRange){
		
			DeadlyVoice_ShakeScreen(i);
			SDKHooks_TakeDamage(i, 0, client, g_fDeadlyVoiceDamage, DMG_BLAST);
		
		}
	
	}

}

void DeadlyVoice_ShakeScreen(int client){

	if(IsFakeClient(client))	return;
	
	float vec[3];
	vec[0] = GetRandomFloat(-15.0, 15.0);
	vec[1] = GetRandomFloat(-15.0, 15.0);
	vec[2] = GetRandomFloat(-15.0, 15.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", vec);

}

stock bool DeadlyVoice_IsValidTargetFor(int client, int target){

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

void DeadlyVoice_ProcessSettings(const char[] sSettings){

	char[][] sPieces = new char[3][8];
	ExplodeString(sSettings, ",", sPieces, 3, 8);

	g_fDeadlyVoiceRate		= StringToFloat(sPieces[0]);
	g_fDeadlyVoiceRange		= StringToFloat(sPieces[1]);
	g_fDeadlyVoiceDamage	= StringToFloat(sPieces[2]);

}
