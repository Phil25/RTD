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

#define SOUND_PUMPKIN_EXPLODE "weapons/cow_mangler_explode.wav"
#define SOUND_PUMPKIN_SPAWN "misc/halloween/merasmus_appear.wav"
#define MODEL_PUMPKIN "models/props_halloween/pumpkin_explode.mdl"
#define PUMPKIN_DISTANCE 100.0

// int cache
#define SPAWN_INDEX 0
#define SPAWN_LIMIT 1

// float cache
#define RATE 0
#define RANGE 1
#define DAMAGE 2
#define LAST_ATTACK 3

int g_iPumpkinTrail = 70;

void PumpkinTrail_Start(){
	PrecacheModel(MODEL_PUMPKIN);
	PrecacheSound(SOUND_PUMPKIN_EXPLODE);
	PrecacheSound(SOUND_PUMPKIN_SPAWN);
}

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

	fPos[0] += PUMPKIN_DISTANCE *fFwd[0] *iSpawnIndex;
	fPos[1] += PUMPKIN_DISTANCE *fFwd[1] *iSpawnIndex;

	PumpkinTrail_Spawn(client, fPos);
}

void PumpkinTrail_Spawn(int client, float fPos[3]){
	int iPumpkin = CreateEntityByName("prop_dynamic");
	if(iPumpkin <= MaxClients)
		return;

	SetEntityModel(iPumpkin, MODEL_PUMPKIN);
	TeleportEntity(iPumpkin, fPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(iPumpkin);

	SetEntPropEnt(iPumpkin, Prop_Send, "m_hOwnerEntity", client);

	if(!CanEntitySeeTarget(iPumpkin, client)){
		AcceptEntityInput(iPumpkin, "Kill");
		return;
	}

	EmitSoundToAll(SOUND_PUMPKIN_SPAWN, iPumpkin, _, _, _, _, 200);
	CreateEffect(fPos, "ghost_appearation");

	CreateTimer(1.0, Timer_PumpkinTrail_Detonate, EntIndexToEntRef(iPumpkin));
	KILL_ENT_IN(iPumpkin,1.1)
}

public Action Timer_PumpkinTrail_Detonate(Handle hTimer, int iRef){
	int iPumpkin = EntRefToEntIndex(iRef);
	if(iPumpkin <= MaxClients)
		return Plugin_Stop;

	float fPos[3];
	GetEntPropVector(iPumpkin, Prop_Send, "m_vecOrigin", fPos);
	int client = GetEntPropEnt(iPumpkin, Prop_Send, "m_hOwnerEntity");

	PumpkinTrail_Detonate(client, iPumpkin, fPos);
	AcceptEntityInput(iPumpkin, "Kill");

	return Plugin_Stop;
}

void PumpkinTrail_Detonate(int client, int iPumpkin, float fPos[3]){
	CreateEffect(fPos, "ExplosionCore_MidAir");
	EmitSoundToAll(SOUND_PUMPKIN_EXPLODE, iPumpkin, _, _, _, _, 200);

	float fRange = GetFloatCache(client, RANGE);
	float fDamage = GetFloatCache(client, DAMAGE);
	DamageRadius(fPos, iPumpkin, client, fRange, fDamage);
}

#undef SPAWN_INDEX
#undef SPAWN_LIMIT
#undef RATE
#undef RANGE
#undef DAMAGE
#undef LAST_ATTACK
