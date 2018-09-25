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

#define LEVEL 0
#define KEEP 1
#define AMOUNT 2

int g_iSpawnDispenserId = 30;

public SpawnDispenser_Call(int client, Perk perk, bool apply){
	if(apply) SpawnDispenser_ApplyPerk(client, perk);
	else SpawnDispenser_RemovePerk(client);
}

void SpawnDispenser_ApplyPerk(int client, Perk perk){
	g_iSpawnDispenserId = perk.Id;
	SetClientPerkCache(client, g_iSpawnDispenserId);

	SetIntCache(client, perk.GetPrefCell("level"), LEVEL);
	SetIntCache(client, perk.GetPrefCell("keep") > 0, KEEP);
	SetIntCache(client, perk.GetPrefCell("amount"), AMOUNT);

	PrepareArrayCache(client);

	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Dispenser_Initialization", LANG_SERVER, 0x03, 0x01);
}

void SpawnDispenser_RemovePerk(int client){
	UnsetClientPerkCache(client, g_iSpawnDispenserId);

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

void SpawnDispenser_Voice(int client){
	if(!CheckClientPerkCache(client, g_iSpawnDispenserId))
		return;

	float fPos[3];
	if(!GetClientLookPosition(client, fPos))
		return;

	if(!CanBuildAtPos(fPos, false))
		return;

	float fDispenserAng[3], fClientAng[3];
	GetClientEyeAngles(client, fClientAng);
	fDispenserAng[1] = fClientAng[1];

	int iLevel = GetIntCache(client, LEVEL);
	int iDispenser = SpawnDispenser(client, fPos, fDispenserAng, iLevel);

	ArrayList list = GetArrayCache(client);
	list.Push(EntIndexToEntRef(iDispenser));

	int iSpawned = list.Length;
	int iMax = GetIntCache(client, AMOUNT);

	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Dispenser_Spawned", LANG_SERVER, 0x03, iSpawned, iMax, 0x01);

	if(iSpawned < iMax)
		return;

	if(GetIntCacheBool(client, KEEP))
		ForceRemovePerk(client);
	else UnsetClientPerkCache(client, g_iSpawnDispenserId);
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

#define LEVEL 0
#define KEEP 1
#define AMOUNT 2
