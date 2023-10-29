/**
* Pumpkin Trail perk.
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

#include "rtd/macros.sp"

#define SOUND_PUMPKIN_EXPLODE "weapons/cow_mangler_explode.wav"
#define SOUND_PUMPKIN_SPAWN "misc/halloween/merasmus_appear.wav"
#define MODEL_PUMPKIN "models/props_halloween/pumpkin_explode.mdl"
#define PUMPKIN_DISTANCE 100.0

#define SpawnAmount Int[0]
#define Rate Float[0]
#define Range Float[1]
#define Damage Float[2]
#define LastAttack Float[3]

DEFINE_CALL_APPLY(PumpkinTrail)

public void PumpkinTrail_Init(const Perk perk)
{
	PrecacheModel(MODEL_PUMPKIN);
	PrecacheSound(SOUND_PUMPKIN_EXPLODE);
	PrecacheSound(SOUND_PUMPKIN_SPAWN);

	Events.OnVoice(perk, PumpkinTrail_OnVoice);
}

void PumpkinTrail_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].SpawnAmount = perk.GetPrefCell("amount", 5);
	Cache[client].Rate = perk.GetPrefFloat("rate", 3.0);
	Cache[client].Range = perk.GetPrefFloat("range", 150.0);
	Cache[client].Damage = perk.GetPrefFloat("damage", 80.0);
	Cache[client].LastAttack = 0.0;

	PrintToChat(client, "%s %T", CHAT_PREFIX, "RTD2_Perk_Attack", LANG_SERVER, 0x03, 0x01);
}

void PumpkinTrail_OnVoice(const int client)
{
	float fTime = GetEngineTime();
	if (fTime < Cache[client].LastAttack + Cache[client].Rate)
		return;

	Cache[client].LastAttack = fTime;

	DataPack hData = new DataPack();
	hData.WriteCell(Cache[client].SpawnAmount);
	hData.WriteCell(GetClientUserId(client));
	hData.WriteCell(Cache[client].SpawnAmount);
	hData.WriteFloat(Cache[client].Range);
	hData.WriteFloat(Cache[client].Damage);

	CreateTimer(0.25, Timer_PumpkinTrail_Spawn, hData, TIMER_REPEAT | TIMER_DATA_HNDL_CLOSE);
}

public Action Timer_PumpkinTrail_Spawn(Handle hTimer, DataPack hData)
{
	hData.Reset();
	int iLeftIndex = hData.ReadCell() - 1;
	int client = GetClientOfUserId(hData.ReadCell());

	if (iLeftIndex <= 0 || !client || !IsPlayerAlive(client))
		return Plugin_Stop;

	int iMaxIndex = hData.ReadCell();
	float fRange = hData.ReadFloat();
	float fDamage = hData.ReadFloat();

	hData.Reset();
	hData.WriteCell(iLeftIndex);

	PumpkinTrail_SpawnOffset(client, iMaxIndex - iLeftIndex, fRange, fDamage);
	return Plugin_Continue;
}

void PumpkinTrail_SpawnOffset(const int client, const int iSpawnIndex, const float fRange, const float fDamage)
{
	float fPos[3], fAng[3], fFwd[3];
	GetClientAbsOrigin(client, fPos);
	GetClientAbsAngles(client, fAng);
	GetAngleVectors(fAng, fFwd, NULL_VECTOR, NULL_VECTOR);

	fPos[0] += PUMPKIN_DISTANCE * fFwd[0] * iSpawnIndex;
	fPos[1] += PUMPKIN_DISTANCE * fFwd[1] * iSpawnIndex;

	PumpkinTrail_Spawn(client, fPos, fRange, fDamage);
}

void PumpkinTrail_Spawn(const int client, float fPos[3], const float fRange, const float fDamage)
{
	int iPumpkin = CreateEntityByName("prop_dynamic");
	if (iPumpkin <= MaxClients)
		return;

	SetEntityModel(iPumpkin, MODEL_PUMPKIN);
	TeleportEntity(iPumpkin, fPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(iPumpkin);

	SetEntPropEnt(iPumpkin, Prop_Send, "m_hOwnerEntity", client);

	if (!CanEntitySeeTarget(iPumpkin, client))
	{
		AcceptEntityInput(iPumpkin, "Kill");
		return;
	}

	EmitSoundToAll(SOUND_PUMPKIN_SPAWN, iPumpkin, _, _, _, _, 200);
	CreateEffect(fPos, "ghost_appearation");

	DataPack hData = new DataPack();
	hData.WriteCell(EntIndexToEntRef(iPumpkin));
	hData.WriteFloat(fRange);
	hData.WriteFloat(fDamage);

	CreateTimer(1.0, Timer_PumpkinTrail_Detonate, hData, TIMER_DATA_HNDL_CLOSE);
	KILL_ENT_IN(iPumpkin,1.1);
}

public Action Timer_PumpkinTrail_Detonate(Handle hTimer, DataPack hData)
{
	hData.Reset();
	int iPumpkin = EntRefToEntIndex(hData.ReadCell());

	if (iPumpkin <= MaxClients)
		return Plugin_Stop;

	float fPos[3];
	GetEntPropVector(iPumpkin, Prop_Send, "m_vecOrigin", fPos);
	int client = GetEntPropEnt(iPumpkin, Prop_Send, "m_hOwnerEntity");

	float fRange = hData.ReadFloat();
	float fDamage = hData.ReadFloat();

	CreateEffect(fPos, "ExplosionCore_MidAir");
	EmitSoundToAll(SOUND_PUMPKIN_EXPLODE, iPumpkin, _, _, _, _, 200);
	DamageRadius(fPos, iPumpkin, client, fRange, fDamage);

	AcceptEntityInput(iPumpkin, "Kill");

	return Plugin_Stop;
}

#undef SOUND_PUMPKIN_EXPLODE
#undef SOUND_PUMPKIN_SPAWN
#undef MODEL_PUMPKIN
#undef PUMPKIN_DISTANCE

#undef SpawnAmount
#undef Rate
#undef Range
#undef Damage
#undef LastAttack
