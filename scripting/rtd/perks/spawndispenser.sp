/**
* Spawn Dispenser perk.
* Copyright (C) 2018 Filip Tomaszewski
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
