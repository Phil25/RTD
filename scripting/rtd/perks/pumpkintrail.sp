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

// int cache
#define SPAWN_INDEX 0
#define SPAWN_LIMIT 1

// float cache
#define RATE 0
#define RANGE 1
#define DAMAGE 2
#define LAST_ATTACK 3

int g_iPumpkinTrail = 70;

public void PumpkinTrail_Call(int client, Perk perk, bool apply){
	if(apply) PumpkinTrail_ApplyPerk(client, perk);
	else UnsetClientPerkCache(client, g_iPumpkinTrail);
}

public void PumpkinTrail_ApplyPerk(int client, Perk perk){
	g_iPumpkinTrail = perk.Id;
	SetClientPerkCache(client, g_iPumpkinTrail);

	SetFloatCache(client, perk.GetPrefFloat("rate"), RATE);
	SetFloatCache(client, perk.GetPrefFloat("range"), RANGE);
	SetFloatCache(client, perk.GetPrefFloat("damage"), DAMAGE);
	SetFloatCache(client, 0.0, LAST_ATTACK);
	SetIntCache(client, perk.GetPrefCell("amount"), SPAWN_LIMIT);

	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Attack", LANG_SERVER, 0x03, 0x01);
}

void PumpkinTrail_Voice(int client){
	if(!CheckClientPerkCache(client, g_iPumpkinTrail))
		return;

	float fTime = GetEngineTime();
	if(fTime < GetFloatCache(client, LAST_ATTACK) +GetFloatCache(client, RATE))
		return;

	SetFloatCache(client, fTime, LAST_ATTACK);
	SetIntCache(client, 0, SPAWN_INDEX);

	CreateTimer(0.25, Timer_PumpkinTrail_Spawn, GetClientUserId(client), TIMER_REPEAT);
}

public Action Timer_PumpkinTrail_Spawn(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iPumpkinTrail))
		return Plugin_Stop;

	int iSpawnIndex = GetIntCache(client, SPAWN_INDEX);
	PumpkinTrail_SpawnOffset(client, ++iSpawnIndex);
	SetIntCache(client, iSpawnIndex, SPAWN_INDEX);

	if(iSpawnIndex < GetIntCache(client, SPAWN_LIMIT))
		return Plugin_Continue;
	else return Plugin_Stop;
}

void PumpkinTrail_SpawnOffset(int client, int iSpawnIndex){
	float fPos[3], fAng[3], fFwd[3];
	GetClientAbsOrigin(client, fPos);
	GetClientAbsAngles(client, fAng);
	GetAngleVectors(fAng, fFwd, NULL_VECTOR, NULL_VECTOR);

	float fRange = GetFloatCache(client, RANGE);
	fPos[0] += fRange *fFwd[0] *iSpawnIndex;
	fPos[1] += fRange *fFwd[1] *iSpawnIndex;

	PumpkinTrail_Spawn(client, fPos);
}

void PumpkinTrail_Spawn(int client, float fPos[3]){
	int iPumpkin = CreateEntityByName("tf_pumpkin_bomb");
	if(iPumpkin <= MaxClients)
		return;

	DispatchSpawn(iPumpkin);
	TeleportEntity(iPumpkin, fPos, NULL_VECTOR, NULL_VECTOR);
	SetEntPropEnt(iPumpkin, Prop_Send, "m_hOwnerEntity", client);

	SetVariantString("OnUser1 !self:Ignite::3:1"); \
	AcceptEntityInput(iPumpkin, "AddOutput"); \
	AcceptEntityInput(iPumpkin, "FireUser1");
}

#undef SPAWN_INDEX
#undef SPAWN_LIMIT
#undef RATE
#undef RANGE
#undef DAMAGE
#undef LAST_ATTACK
