
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

bool	g_bCanSpawnSentry[MAXPLAYERS+1]	= {false, ...};
Handle	g_hSpawnedSentries[MAXPLAYERS+1]= INVALID_HANDLE;

int		g_iSentryLevel	= 2;
bool	g_bShouldStay	= true;
int		g_iMaxSentries	= 1;

void SpawnSentry_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		SpawnSentry_ApplyPerk(client, sPref);
	
	else
		SpawnSentry_RemovePerk(client);

}

void SpawnSentry_ApplyPerk(int client, const char[] sPref){

	SpawnSentry_ProcessSettings(sPref);
	
	if(g_hSpawnedSentries[client] == INVALID_HANDLE)
		g_hSpawnedSentries[client] = CreateArray();
	else
		ClearArray(g_hSpawnedSentries[client]);
	
	g_bCanSpawnSentry[client] = true;
	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Sentry_Initialization", LANG_SERVER, 0x03, 0x01);

}

void SpawnSentry_RemovePerk(int client){

	g_bCanSpawnSentry[client] = false;

	if(g_bShouldStay)
		return;
	
	int iSize = GetArraySize(g_hSpawnedSentries[client]);
	for(int i = 0; i < iSize; i++){
	
		int iEnt = EntRefToEntIndex(GetArrayCell(g_hSpawnedSentries[client], i));
		
		if(iEnt > MaxClients && IsValidEntity(iEnt))
		AcceptEntityInput(iEnt, "Kill");
	
	}

}

void SpawnSentry_Voice(int client){

	if(!g_bCanSpawnSentry[client])
		return;
	
	float fPos[3];
	if(GetClientLookPosition(client, fPos)){
	
		if(CanBuildAtPos(fPos, true)){
		
			float fSentryAng[3], fClientAng[3];
			GetClientEyeAngles(client, fClientAng);
			
			fSentryAng[1] = fClientAng[1];
			PushArrayCell(g_hSpawnedSentries[client], EntIndexToEntRef(SpawnSentry(client, fPos, fSentryAng, g_iSentryLevel > 0 ? g_iSentryLevel : 1, g_iSentryLevel < 1 ? true : false)));
			
			int iSpawned = GetArraySize(g_hSpawnedSentries[client]);
			PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Sentry_Spawned", LANG_SERVER, 0x03, iSpawned, g_iMaxSentries, 0x01);
			
			if(iSpawned >= g_iMaxSentries)
				if(g_bShouldStay)
					ForceRemovePerk(client);
				else
					g_bCanSpawnSentry[client] = false;
		
		}
	
	}

}

/*
	The SpawnSentry stock is taken from Pelipoika's TF2 Building Spawner EXTREME
	https://forums.alliedmods.net/showthread.php?p=2148102
*/
stock int SpawnSentry(int builder, float Position[3], float Angle[3], int level, bool mini=false, bool disposable=false, int flags=4){

	float m_vecMinsMini[3] = {-15.0, -15.0, 0.0}, m_vecMaxsMini[3] = {15.0, 15.0, 49.5};
	float m_vecMinsDisp[3] = {-13.0, -13.0, 0.0}, m_vecMaxsDisp[3] = {13.0, 13.0, 42.9};
	
	int sentry = CreateEntityByName("obj_sentrygun");
	
	if(!IsValidEntity(sentry)) return 0;
	
	int iTeam = GetClientTeam(builder);
	
	SetEntPropEnt(sentry, Prop_Send, "m_hBuilder", builder);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(sentry, "SetTeam");

	DispatchKeyValueVector(sentry, "origin", Position);
	DispatchKeyValueVector(sentry, "angles", Angle);
	
	if(mini){
	
		SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
		SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
		SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
		SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
		SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
		SetEntProp(sentry, Prop_Send, "m_nSkin", level == 1 ? iTeam : iTeam -2);
		DispatchSpawn(sentry);
		
		SetVariantInt(100);
		AcceptEntityInput(sentry, "SetHealth");
		
		SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.75);
		SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsMini);
		SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsMini);
	
	}else if(disposable){
	
		SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
		SetEntProp(sentry, Prop_Send, "m_bDisposableBuilding", 1);
		SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
		SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
		SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
		SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
		SetEntProp(sentry, Prop_Send, "m_nSkin", level == 1 ? iTeam : iTeam -2);
		DispatchSpawn(sentry);
		
		SetVariantInt(100);
		AcceptEntityInput(sentry, "SetHealth");
		
		SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.60);
		SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsDisp);
		SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsDisp);
	
	}else{
	
		SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
		SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
		SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
		SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
		SetEntProp(sentry, Prop_Send, "m_nSkin", iTeam -2);
		DispatchSpawn(sentry);
	
	}
	
	return sentry;

}

void SpawnSentry_ProcessSettings(const char[] sSettings){
	
	char[][] sPieces = new char[3][8];
	ExplodeString(sSettings, ",", sPieces, 3, 8);

	g_iSentryLevel	= StringToInt(sPieces[0]);
	g_bShouldStay	= StringToInt(sPieces[1]) > 0 ? true : false;
	g_iMaxSentries	= StringToInt(sPieces[2]);

}