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

#define Level Int[0]
#define Cleanup Int[1]
#define Max Int[2]
#define Spawned Int[3]

DEFINE_CALL_APPLY(SpawnDispenser)

public void SpawnDispenser_Init(const Perk perk)
{
	Events.OnVoice(perk, SpawnDispenser_OnVoice);
}

public void SpawnDispenser_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Level = perk.GetPrefCell("level", 3);
	Cache[client].Cleanup = perk.GetPrefCell("keep", 1) > 0 ? view_as<int>(EntCleanup_None) : view_as<int>(EntCleanup_Auto);
	Cache[client].Max = MinInt(perk.GetPrefCell("amount", 1), view_as<int>(EntSlot_SIZE));
	Cache[client].Spawned = 0;

	PrintToChat(client, "%s %T", CHAT_PREFIX, "RTD2_Perk_Dispenser_Initialization", LANG_SERVER, 0x03, 0x01);
}

public void SpawnDispenser_OnVoice(const int client)
{
	int iSpawned = Cache[client].Spawned;
	int iMax = Cache[client].Max;

	if (iSpawned >= iMax)
		return;

	float fPos[3];
	if (!GetClientLookPosition(client, fPos))
		return;

	if (!FindBuildPosition(fPos, false))
		return;

	float fAng[3];
	GetClientEyeAngles(client, fAng);
	fAng[0] = 0.0;
	fAng[2] = 0.0;

	int iDispenser = SpawnDispenser(client, fPos, fAng, Cache[client].Level);

	Cache[client].SetEnt(view_as<EntSlot>(iSpawned++), iDispenser, view_as<EntCleanup>(Cache[client].Cleanup))
	Cache[client].Spawned = iSpawned;

	PrintToChat(client, "%s %T", CHAT_PREFIX, "RTD2_Perk_Dispenser_Spawned", LANG_SERVER, 0x03, iSpawned, iMax, 0x01);

	if (iSpawned < iMax)
		return;

	if (view_as<EntCleanup>(Cache[client].Cleanup) == EntCleanup_None)
	{
		// We can remove the perk early if Dispensers are to be kept
		ForceRemovePerk(client);
	}
}

/*
	The SpawnDispenser stock is taken from Pelipoika's TF2 Building Spawner EXTREME
	https://forums.alliedmods.net/showthread.php?p=2148102
*/
stock int SpawnDispenser(int iBuilder, float Position[3], float Angle[3], int iLevel)
{

	int iDispenser = CreateEntityByName("obj_dispenser");
	if (iDispenser <= MaxClients)
		return 0;

	int iTeam = GetClientTeam(iBuilder);

	DispatchKeyValueVector(iDispenser, "origin", Position);
	DispatchKeyValueVector(iDispenser, "angles", Angle);
	SetEntProp(iDispenser, Prop_Send, "m_iHighestUpgradeLevel", iLevel);
	SetEntProp(iDispenser, Prop_Data, "m_spawnflags", 4);
	SetEntProp(iDispenser, Prop_Send, "m_bBuilding", 1);
	DispatchSpawn(iDispenser);

	SetVariantInt(iTeam);
	AcceptEntityInput(iDispenser, "SetTeam");
	SetEntProp(iDispenser, Prop_Send, "m_nSkin", iTeam - 2);

	ActivateEntity(iDispenser);
	SetEntPropEnt(iDispenser, Prop_Send, "m_hBuilder", iBuilder);

	return iDispenser;
}

#undef Level
#undef Cleanup
#undef Max
#undef Spawned
