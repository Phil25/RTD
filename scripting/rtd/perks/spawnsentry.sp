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


#define LEVEL 0
#define KEEP 1
#define AMOUNT 2

int g_iSpawnSentryId = 12;

void SpawnSentry_Perk(int client, Perk perk, bool apply){
	if(apply) SpawnSentry_ApplyPerk(client, perk);
	else SpawnSentry_RemovePerk(client);
}

void SpawnSentry_ApplyPerk(int client, Perk perk){
	g_iSpawnSentryId = perk.Id;
	SetClientPerkCache(client, g_iSpawnSentryId);

	SetIntCache(client, perk.GetPrefCell("level"), LEVEL);
	SetIntCache(client, perk.GetPrefCell("keep") > 0, KEEP);
	SetIntCache(client, perk.GetPrefCell("amount"), AMOUNT);

	PrepareArrayCache(client);

	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Sentry_Initialization", LANG_SERVER, 0x03, 0x01);
}

void SpawnSentry_RemovePerk(int client){
	UnsetClientPerkCache(client, g_iSpawnSentryId);

	if(GetIntCacheBool(client, KEEP))
		return;

	ArrayList list = GetArrayCache(client);
	int iLen = list.Length;
	for(int i = 0; i < iLen; i++){
		int iEnt = EntRefToEntIndex(list.Get(i));
		if(iEnt > MaxClients && IsValidEntity(iEnt))
			AcceptEntityInput(iEnt, "Kill");
	}
}

void SpawnSentry_Voice(int client){
	if(!CheckClientPerkCache(client, g_iSpawnSentryId))
		return;

	float fPos[3];
	if(!GetClientLookPosition(client, fPos))
		return;

	if(!CanBuildAtPos(fPos, true))
		return;

	float fSentryAng[3], fClientAng[3];
	GetClientEyeAngles(client, fClientAng);
	fSentryAng[1] = fClientAng[1];

	int iLevel = GetIntCache(client, LEVEL);
	int iSentry = SpawnSentry(client, fPos, fSentryAng, iLevel > 0 ? iLevel : 1, iLevel == 0);

	ArrayList list = GetArrayCache(client);
	list.Push(EntIndexToEntRef(iSentry));

	int iSpawned = list.Length;
	int iMax = GetIntCache(client, AMOUNT);

	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Sentry_Spawned", LANG_SERVER, 0x03, iSpawned, iMax, 0x01);

	if(iSpawned < iMax)
		return;

	if(GetIntCacheBool(client, KEEP))
		ForceRemovePerk(client);
	else UnsetClientPerkCache(client, g_iSpawnSentryId);
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

#undef LEVEL
#undef KEEP
#undef AMOUNT
