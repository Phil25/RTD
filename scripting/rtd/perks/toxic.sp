/**
* Toxic perk.
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


#define TOXIC_RADIUS 0
#define TOXIC_INTERVAL 1
#define TOXIC_DAMAGE 2

#define TOXIC_EFFECT_SPLAT_INDEX 0
#define TOXIC_EFFECT_FOG_INDEX 1
#define TOXIC_EFFECT_COUNT 2

#define TOXIC_PARTICLE "eb_aura_angry01"
#define TOXIC_SOUND "player/general/flesh_burn.wav"

int g_iToxicId = 1;

void Toxic_Start(){
	PrecacheSound(TOXIC_SOUND);
}

public void Toxic_Call(int client, Perk perk, bool apply){
	if(apply) Toxic_ApplyPerk(client, perk);
	else{
		UnsetClientPerkCache(client, g_iToxicId);
		StopSound(client, SNDCHAN_AUTO, TOXIC_SOUND);
	}
}

void Toxic_ApplyPerk(int client, Perk perk){
	g_iToxicId = perk.Id;
	SetClientPerkCache(client, g_iToxicId);

	float fRadius = perk.GetPrefFloat("radius")
	SetFloatCache(client, fRadius, TOXIC_RADIUS);
	SetFloatCache(client, perk.GetPrefFloat("interval"), TOXIC_INTERVAL);
	SetFloatCache(client, perk.GetPrefFloat("damage"), TOXIC_DAMAGE);
	SetIntCache(client, RoundFloat(fRadius / 64.0), TOXIC_EFFECT_COUNT);
	SetIntCache(client, GetEffectIndex("god_rays_fog"), TOXIC_EFFECT_FOG_INDEX);

	switch(TF2_GetClientTeam(client)){
		case TFTeam_Blue:
			SetIntCache(client, GetEffectIndex("gas_can_impact_blue"), TOXIC_EFFECT_SPLAT_INDEX);
		case TFTeam_Red:
			SetIntCache(client, GetEffectIndex("gas_can_impact_red"), TOXIC_EFFECT_SPLAT_INDEX);
	}

	int iUserId = GetClientUserId(client);
	CreateTimer(GetFloatCache(client, TOXIC_INTERVAL), Timer_Toxic, iUserId, TIMER_REPEAT);

	if(GetIntCache(client, TOXIC_EFFECT_SPLAT_INDEX) == -1 || GetIntCache(client, TOXIC_EFFECT_FOG_INDEX) == -1){
		PrintToServer("[RTD] WARNING: Toxic could not find the indexes of its desired effects, ignoring...");
		return;
	}

	EmitSoundToAll(TOXIC_SOUND, client, _, _, _, _, 250);
	CreateTimer(0.1, Timer_ToxicParticles, iUserId, TIMER_REPEAT);
}

public Action Timer_Toxic(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(client == 0) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iToxicId))
		return Plugin_Stop;

	float fPos[3];
	GetClientAbsOrigin(client, fPos);
	fPos[2] += 60.0; // roughly player center

	DamageRadius(fPos, client, client, GetFloatCache(client, TOXIC_RADIUS), GetFloatCache(client, TOXIC_DAMAGE), DMG_BLAST);
	return Plugin_Continue;
}

public Action Timer_ToxicParticles(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(client == 0) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iToxicId))
		return Plugin_Stop;

	float fClientPos[3];
	GetClientAbsOrigin(client, fClientPos);
	fClientPos[2] += 60.0; // roughly player center

	float fPos[3], fDir[2];
	int iCount = GetIntCache(client, TOXIC_EFFECT_COUNT)
	int iEffectIndex = GetIntCache(client, TOXIC_EFFECT_SPLAT_INDEX);

	for(int i = 0; i < iCount; ++i){
		float fMaxRadius = GetFloatCache(client, TOXIC_RADIUS);
		float fRadius = GetRandomFloat(fMaxRadius - 30.0, fMaxRadius);

		fDir[0] = GetRandomFloat(0.0, 2.0 * 3.1415); // radians
		fDir[1] = GetRandomFloat(0.0, 2.0 * 3.1415);
		GetPointOnSphere(fClientPos, fDir, fRadius, fPos);

		SetupTEParticleEffect(iEffectIndex, fPos);
		TE_SendToAll();
	}

	// Use last spawned particle's position to create the fog
	SetupTEParticleEffect(GetIntCache(client, TOXIC_EFFECT_FOG_INDEX), fPos);
	TE_SendToAll();

	return Plugin_Continue;
}

#undef TOXIC_RADIUS
#undef TOXIC_INTERVAL
#undef TOXIC_DAMAGE

#undef TOXIC_EFFECT_SPLAT_INDEX
#undef TOXIC_EFFECT_FOG_INDEX
#undef TOXIC_EFFECT_COUNT

#undef TOXIC_PARTICLE
