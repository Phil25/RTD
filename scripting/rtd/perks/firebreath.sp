
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

#define FIREBREATH_SOUND_ATTACK "player/taunt_fire.wav"

bool	g_bHasFireBreath[MAXPLAYERS+1] 			= {false, ...};
float	g_fFireBreathLastAttack[MAXPLAYERS+1]	= {0.0, ...};
float	g_fFireBreathRate						= 2.0;
float	g_fFireBreathCritChance					= 0.05;

void FireBreath_Start(){

	PrecacheSound(FIREBREATH_SOUND_ATTACK);

}

void FireBreath_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		FireBreath_ApplyPerk(client, sPref);
	
	else
		g_bHasFireBreath[client] = false;

}

void FireBreath_ApplyPerk(int client, const char[] sPref){

	FireBreath_ProcessString(sPref);
	
	g_bHasFireBreath[client] = true;
	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Attack", LANG_SERVER, 0x03, 0x01);

}

void FireBreath_Voice(int client){

	if(!g_bHasFireBreath[client])
		return;
	
	float fEngineTime = GetEngineTime();
	
	if(fEngineTime < g_fFireBreathLastAttack[client] +g_fFireBreathRate)
		return;
	
	g_fFireBreathLastAttack[client] = fEngineTime;
	
	float fShake[3];
	fShake[0] = GetRandomFloat(-5.0, -25.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fShake);
	
	FireBreath_Fireball(client);
	EmitSoundToAll(FIREBREATH_SOUND_ATTACK, client);

}

/*
	Code borrowed from: [TF2] Spell casting!
	https://forums.alliedmods.net/showthread.php?p=2054678
*/

void FireBreath_Fireball(client){
	
	float fAng[3], fPos[3];
	GetClientEyeAngles(client, fAng);
	GetClientEyePosition(client, fPos);
	
	int iTeam	= GetClientTeam(client);
	int iSpell	= CreateEntityByName("tf_projectile_spellfireball");
	
	if(!IsValidEntity(iSpell))
		return;
	
	float fVel[3], fBuf[3];
	
	GetAngleVectors(fAng, fBuf, NULL_VECTOR, NULL_VECTOR);
	fVel[0] = fBuf[0]*1100.0; //Speed of a tf2 rocket.
	fVel[1] = fBuf[1]*1100.0;
	fVel[2] = fBuf[2]*1100.0;

	SetEntPropEnt	(iSpell, Prop_Send, "m_hOwnerEntity",	client);
	SetEntProp		(iSpell, Prop_Send, "m_bCritical",		(GetURandomFloat() <= g_fFireBreathCritChance) ? 1 : 0, 1);
	SetEntProp		(iSpell, Prop_Send, "m_iTeamNum",		iTeam, 1);
	SetEntProp		(iSpell, Prop_Send, "m_nSkin",			iTeam-2);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0);
	
	DispatchSpawn(iSpell);
	TeleportEntity(iSpell, fPos, fAng, fVel);

}

void FireBreath_ProcessString(const char[] sSettings){

	char[][] sPieces = new char[2][8];
	ExplodeString(sSettings, ",", sPieces, 3, 8);
	
	g_fFireBreathRate		= StringToFloat(sPieces[0]);
	g_fFireBreathCritChance	= StringToFloat(sPieces[1]);

}