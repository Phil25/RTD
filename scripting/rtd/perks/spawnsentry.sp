/**
* Spawn Sentry perk.
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
