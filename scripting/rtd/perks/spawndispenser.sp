
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

bool	g_bCanSpawnDispenser[MAXPLAYERS+1]	= {false, ...};
Handle	g_iSpawnedDispensers[MAXPLAYERS+1]	= INVALID_HANDLE;

int		g_iDispenserLevel		= 2;
bool	g_bShouldDispenserStay	= true;
int		g_iMaxDispensers		= 1;

public SpawnDispenser_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		SpawnDispenser_ApplyPerk(client, sPref);
	
	else
		SpawnDispenser_RemovePerk(client);

}

void SpawnDispenser_ApplyPerk(int client, const char[] sPref){

	SpawnDispenser_ProcessSettings(sPref);
	
	if(g_iSpawnedDispensers[client] == INVALID_HANDLE)
		g_iSpawnedDispensers[client] = CreateArray();
	else
		ClearArray(g_iSpawnedDispensers[client]);
	
	g_bCanSpawnDispenser[client] = true;
	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Dispenser_Initialization", LANG_SERVER, 0x03, 0x01);

}

void SpawnDispenser_RemovePerk(int client){

	g_bCanSpawnDispenser[client] = false;

	if(g_bShouldDispenserStay)
		return;

	int iSize = GetArraySize(g_iSpawnedDispensers[client]);
	for(int i = 0; i < iSize; i++){
	
		int iEnt = EntRefToEntIndex(GetArrayCell(g_iSpawnedDispensers[client], i));
		
		if(iEnt > MaxClients && IsValidEntity(iEnt))
		AcceptEntityInput(iEnt, "Kill");
	
	}

}

void SpawnDispenser_Voice(int client){

	if(!g_bCanSpawnDispenser[client])
		return;
	
	float fPos[3];
	if(GetClientLookPosition(client, fPos)){
	
		if(CanBuildAtPos(fPos, false)){
		
			float fDispenserAng[3], fClientAng[3];
			GetClientEyeAngles(client, fClientAng);
			
			fDispenserAng[1] = fClientAng[1];
			PushArrayCell(g_iSpawnedDispensers[client], EntIndexToEntRef(SpawnDispenser(client, fPos, fDispenserAng, g_iDispenserLevel)));
			
			int iSpawned = GetArraySize(g_iSpawnedDispensers[client]);
			PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Dispenser_Spawned", LANG_SERVER, 0x03, iSpawned, g_iMaxDispensers, 0x01);
			
			if(iSpawned >= g_iMaxDispensers)
				if(g_bShouldDispenserStay)
					ForceRemovePerk(client);
				else
					g_bCanSpawnDispenser[client] = false;
		
		}
	
	}

}

/*
	The SpawnDispenser stock is taken from Pelipoika's TF2 Building Spawner EXTREME
	https://forums.alliedmods.net/showthread.php?p=2148102
*/
stock int SpawnDispenser(int builder, float Position[3], float Angle[3], int level, int flags=4){

	int dispenser = CreateEntityByName("obj_dispenser");
	
	if(!IsValidEntity(dispenser)) return 0;
	
	int iTeam = GetClientTeam(builder);
	
	DispatchKeyValueVector(dispenser, "origin", Position);
	DispatchKeyValueVector(dispenser, "angles", Angle);
	SetEntProp(dispenser, Prop_Send, "m_iHighestUpgradeLevel", level);
	SetEntProp(dispenser, Prop_Data, "m_spawnflags", flags);
	SetEntProp(dispenser, Prop_Send, "m_bBuilding", 1);
	DispatchSpawn(dispenser); 
	
	SetVariantInt(iTeam);
	AcceptEntityInput(dispenser, "SetTeam");
	SetEntProp(dispenser, Prop_Send, "m_nSkin", iTeam -2);
	
	ActivateEntity(dispenser);
	SetEntPropEnt(dispenser, Prop_Send, "m_hBuilder", builder);
	
	return dispenser;

} 

void SpawnDispenser_ProcessSettings(const char[] sSettings){
	
	char[][] sPieces = new char[3][8];
	ExplodeString(sSettings, ",", sPieces, 3, 8);

	g_iDispenserLevel		= StringToInt(sPieces[0]);
	g_bShouldDispenserStay	= StringToInt(sPieces[1]) > 0 ? true : false;
	g_iMaxDispensers		= StringToInt(sPieces[2]);

}