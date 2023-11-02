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

#define Level Int[0]
#define Cleanup Int[1]
#define Max Int[2]
#define Spawned Int[3]

DEFINE_CALL_APPLY(SpawnSentry)

public void SpawnSentry_Init(const Perk perk)
{
	Events.OnVoice(perk, SpawnSentry_OnVoice);
}

public void SpawnSentry_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Level = perk.GetPrefCell("level", 2);
	Cache[client].Cleanup = perk.GetPrefCell("keep", 0) > 0 ? view_as<int>(EntCleanup_None) : view_as<int>(EntCleanup_Auto);
	Cache[client].Max = MinInt(perk.GetPrefCell("amount", 1), view_as<int>(EntSlot_SIZE));
	Cache[client].Spawned = 0;

	PrintToChat(client, "%s %T", CHAT_PREFIX, "RTD2_Perk_Sentry_Initialization", LANG_SERVER, 0x03, 0x01);
}

void SpawnSentry_OnVoice(const int client)
{
	int iSpawned = Cache[client].Spawned;
	int iMax = Cache[client].Max;

	if (iSpawned >= iMax)
		return;

	float fPos[3];
	if (!GetClientLookPosition(client, fPos))
		return;

	if (!FindBuildPosition(fPos, true))
		return;

	float fAng[3];
	GetClientEyeAngles(client, fAng);
	fAng[0] = 0.0;
	fAng[2] = 0.0;

	int iLvl = Cache[client].Level;
	int iSentry = SpawnSentry(client, fPos, fAng, iLvl > 0 ? iLvl : 1, iLvl == 0);

	Cache[client].SetEnt(view_as<EntSlot>(iSpawned++), iSentry, view_as<EntCleanup>(Cache[client].Cleanup))
	Cache[client].Spawned = iSpawned;

	PrintToChat(client, "%s %T", CHAT_PREFIX, "RTD2_Perk_Sentry_Spawned", LANG_SERVER, 0x03, iSpawned, iMax, 0x01);

	if (iSpawned < iMax)
		return;

	if (view_as<EntCleanup>(Cache[client].Cleanup) == EntCleanup_None)
	{
		// We can remove the perk early if Sentries are to be kept
		ForceRemovePerk(client);
	}
}

/*
	The SpawnSentry stock is taken from Pelipoika's TF2 Building Spawner EXTREME
	https://forums.alliedmods.net/showthread.php?p=2148102
*/
stock int SpawnSentry(int iBuilder, float Position[3], float Angle[3], int iLevel, bool bMini=false)
{
	static int iSentryFlags = 4;
	static float fMinsMini[3] = {-15.0, -15.0, 0.0}
	static float fMaxsMini[3] = {15.0, 15.0, 49.5};

	int iSentry = CreateEntityByName("obj_sentrygun");
	if (!IsValidEntity(iSentry))
		return 0;

	int iTeam = GetClientTeam(iBuilder);
	SetEntPropEnt(iSentry, Prop_Send, "m_hBuilder", iBuilder);

	SetVariantInt(iTeam);
	AcceptEntityInput(iSentry, "SetTeam");

	DispatchKeyValueVector(iSentry, "origin", Position);
	DispatchKeyValueVector(iSentry, "angles", Angle);

	if (bMini)
	{
		SetEntProp(iSentry, Prop_Send, "m_bMiniBuilding", 1);
		SetEntProp(iSentry, Prop_Send, "m_iUpgradeLevel", iLevel);
		SetEntProp(iSentry, Prop_Send, "m_iHighestUpgradeLevel", iLevel);
		SetEntProp(iSentry, Prop_Data, "m_spawnflags", iSentryFlags);
		SetEntProp(iSentry, Prop_Send, "m_bBuilding", 1);
		SetEntProp(iSentry, Prop_Send, "m_nSkin", iLevel == 1 ? iTeam : iTeam -2);
		DispatchSpawn(iSentry);

		SetVariantInt(100);
		AcceptEntityInput(iSentry, "SetHealth");

		SetEntPropFloat(iSentry, Prop_Send, "m_flModelScale", 0.75);
		SetEntPropVector(iSentry, Prop_Send, "m_vecMins", fMinsMini);
		SetEntPropVector(iSentry, Prop_Send, "m_vecMaxs", fMaxsMini);
	}
	else
	{
		SetEntProp(iSentry, Prop_Send, "m_iUpgradeLevel", iLevel);
		SetEntProp(iSentry, Prop_Send, "m_iHighestUpgradeLevel", iLevel);
		SetEntProp(iSentry, Prop_Data, "m_spawnflags", iSentryFlags);
		SetEntProp(iSentry, Prop_Send, "m_bBuilding", 1);
		SetEntProp(iSentry, Prop_Send, "m_nSkin", iTeam -2);
		DispatchSpawn(iSentry);
	}

	return iSentry;
}

#undef Level
#undef Cleanup
#undef Max
#undef Spawned
