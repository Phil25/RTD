/**
* Explode perk.
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


#define MODEL_BOMB "models/passtime/ball/passtime_ball_halloween.mdl"

#define BOMB_FUSE_SOUND "misc/halloween/hwn_bomb_fuse.wav"
#define BOMB_HIT_SOUND "weapons/bugbait/bugbait_impact1.wav"
#define BOMB_DESTROY_SOUND "ui/mm_rank_up_achieved.wav"
#define BOMB_BEAM_DRAG "weapons/gauss/chargeloop.wav"
#define SOUND_EXPLODE "weapons/explode3.wav"

#define BOMB_DESTROYED 0
#define IN_RADIUS 1

#define BOMB_RADIUS_SQR 0

#define BOMB_ENT_BOMB 0
#define BOMB_ENT_SPARKS 1
#define BOMB_ENT_BEAM 2

#define BEAM_COLOR_R 60
#define BEAM_COLOR_G 60
#define BEAM_COLOR_B 60

#define BEAM_COLOR_INACTIVE "60 60 60"
#define BEAM_COLOR_ACTIVE "255 255 255"

int g_iExplodeId = 15;

void Explode_Start(){
	PrecacheModel(MODEL_BOMB);
	PrecacheSound(BOMB_HIT_SOUND);
	PrecacheSound(BOMB_FUSE_SOUND);
	PrecacheSound(BOMB_DESTROY_SOUND);
	PrecacheSound(BOMB_BEAM_DRAG);
	PrecacheSound(SOUND_EXPLODE);
}

public void Explode_Call(int client, Perk perk, bool apply){
	if(apply) Explode_ApplyPerk(client, perk);
	else Explode_RemovePerk(client);
}

void Explode_ApplyPerk(int client, Perk perk){
	g_iExplodeId = perk.Id;
	SetClientPerkCache(client, g_iExplodeId);

	SetIntCache(client, false, BOMB_DESTROYED);
	SetIntCache(client, true, IN_RADIUS);

	float fBombRange = perk.GetPrefFloat("range");
	SetFloatCache(client, fBombRange * fBombRange, BOMB_RADIUS_SQR);

	int iBomb = CreateEntityByName("prop_physics_override");
	if(iBomb <= MaxClients) return;

	float fPos[3];
	GetClientAbsOrigin(client, fPos);
	fPos[2] += 16.0;

	DispatchKeyValueVector(iBomb, "origin", fPos);
	DispatchKeyValue(iBomb, "model", MODEL_BOMB);
	DispatchKeyValue(iBomb, "modelscale", "1.5");
	DispatchKeyValue(iBomb, "MoveType", "8"); // noclip

	// 4 -- debris
	// 8 -- motion disabled
	// 4096 -- debris with trigger interaction
	DispatchKeyValue(iBomb, "spawnflags", "4108");

	DispatchSpawn(iBomb);

	SetEntProp(iBomb, Prop_Data, "m_iHealth", perk.GetPrefCell("health"));
	SDKHook(iBomb, SDKHook_OnTakeDamagePost, Explode_OnBombTakeDamagePost);

	fPos[2] += 22.0;
	SetEntCache(client, CreateEffect(fPos, "flare_sparks", GetPerkTimeFloat(perk)), BOMB_ENT_SPARKS);
	SetEntCache(client, iBomb, BOMB_ENT_BOMB);
	SetEntCache(client, ConnectWithBeam(client, iBomb, BEAM_COLOR_R, BEAM_COLOR_G, BEAM_COLOR_B), BOMB_ENT_BEAM);

	EmitSoundToAll(BOMB_FUSE_SOUND, iBomb);

	CreateTimer(0.1, Explode_BindToBomb, GetClientUserId(client), TIMER_REPEAT);
}

void Explode_RemovePerk(int client){
	UnsetClientPerkCache(client, g_iExplodeId);

	KillEntCache(client, BOMB_ENT_SPARKS);

	int iBomb = GetEntCache(client, BOMB_ENT_BOMB);
	if(iBomb <= MaxClients)
		return;

	int iTimeLeft = g_hRollers.GetEndRollTime(client) - GetTime();
	bool bForcefullyRemoved = iTimeLeft > 1; // assumption

	if(!GetIntCacheBool(client, BOMB_DESTROYED) && !bForcefullyRemoved){
		float fPos[3];
		GetEntPropVector(iBomb, Prop_Send, "m_vecOrigin", fPos);

		SendTEParticle(TEParticle_ExplosionLarge, fPos);
		SendTEParticle(TEParticle_ExplosionLargeShockwave, fPos);
		EmitSoundToAll(SOUND_EXPLODE, iBomb);

		FakeClientCommandEx(client, "explode");
	}

	StopSound(iBomb, SNDCHAN_AUTO, BOMB_FUSE_SOUND);
	KillEntCache(client, BOMB_ENT_BOMB);
	KillEntCache(client, BOMB_ENT_BEAM);
}

public Action Explode_BindToBomb(Handle hTimer, const int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client)
		return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iExplodeId))
		return Plugin_Stop;

	int iBomb = GetEntCache(client, BOMB_ENT_BOMB);
	if(iBomb <= MaxClients)
		return Plugin_Stop;

	float fClientOrigin[3], fBombOrigin[3];
	GetClientAbsOrigin(client, fClientOrigin);
	GetEntPropVector(iBomb, Prop_Send, "m_vecOrigin", fBombOrigin);

	if(GetVectorDistance(fClientOrigin, fBombOrigin, true) < GetFloatCache(client, BOMB_RADIUS_SQR)){
		if(!GetIntCacheBool(client, IN_RADIUS)){
			SetIntCache(client, true, IN_RADIUS);

			int iBeam = GetEntCache(client, BOMB_ENT_BEAM);
			SetVariantString(BEAM_COLOR_INACTIVE);
			AcceptEntityInput(iBeam, "Color");

			StopSound(client, SNDCHAN_AUTO, BOMB_BEAM_DRAG);
		}
		return Plugin_Continue;
	}else{
		if(GetIntCacheBool(client, IN_RADIUS)){
			SetIntCache(client, false, IN_RADIUS);

			int iBeam = GetEntCache(client, BOMB_ENT_BEAM);
			SetVariantString(BEAM_COLOR_ACTIVE);
			AcceptEntityInput(iBeam, "Color");

			EmitSoundToAll(BOMB_BEAM_DRAG, client);
		}
	}

	float fVel[3];
	MakeVectorFromPoints(fClientOrigin, fBombOrigin, fVel);

	NormalizeVector(fVel, fVel);
	ScaleVector(fVel, 300.0);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVel);

	return Plugin_Continue;
}

public void Explode_OnBombTakeDamagePost(int iBomb, int iAtk, int iInflictor, float fDamage, int iType, int iWeapon, float fForce[3], float fPos[3]){
	if(iType & (DMG_BULLET | DMG_CLUB)){
		SendTEParticleWithPriority(TEParticle_GreenBitsImpact, fPos);
	}else if(iType & (DMG_BUCKSHOT)){
		float fShotPos[3];
		for(int i = 0; i < 3; ++i){
			fShotPos[0] = fPos[0] + GetRandomFloat(-10.0, 10.0);
			fShotPos[1] = fPos[1] + GetRandomFloat(-10.0, 10.0);
			fShotPos[2] = fPos[2] + GetRandomFloat(-10.0, 10.0);
			SendTEParticleWithPriority(TEParticle_GreenBitsImpact, fShotPos);
		}
	}

	int iHealth = GetEntProp(iBomb, Prop_Data, "m_iHealth") - RoundFloat(fDamage);
	if(iHealth <= 0){
		Explode_CompleteSuccess(iBomb, fPos);
		return;
	}

	SetEntProp(iBomb, Prop_Data, "m_iHealth", iHealth);

	EmitSoundToAll(BOMB_HIT_SOUND, iBomb);

	float fAng[3];
	GetEntPropVector(iBomb, Prop_Send, "m_angRotation", fAng);

	fAng[0] += GetRandomDeviationAddition(fAng[0], 10.0);
	fAng[1] += GetRandomFloat(-20.0, 20.0);
	fAng[2] += GetRandomDeviationAddition(fAng[2], 10.0);

	TeleportEntity(iBomb, NULL_VECTOR, fAng, NULL_VECTOR);
}

int Explode_FindOwningClient(int iBomb){
	int iEntReference = EntIndexToEntRef(iBomb);

	for(int client = 1; client <= MaxClients; ++client)
		if(GetEntCacheRef(client, BOMB_ENT_BOMB) == iEntReference)
			return client;

	return 0;
}

void Explode_CompleteSuccess(const int iBomb, const float fPos[3]){
	int client = Explode_FindOwningClient(iBomb);
	if(client == 0){ // should never happen
		AcceptEntityInput(iBomb, "Kill");
		return;
	}

	SetIntCache(client, true, BOMB_DESTROYED);

	SendTEParticle(TEParticle_GreenBitsTwirl, fPos);
	SendTEParticle(TEParticle_GreenFog, fPos);
	EmitSoundToAll(BOMB_DESTROY_SOUND, iBomb);

	ForceRemovePerk(client);
}

#undef MODEL_BOMB

#undef BOMB_FUSE_SOUND
#undef BOMB_HIT_SOUND
#undef BOMB_DESTROY_SOUND
#undef BOMB_BEAM_DRAG
#undef SOUND_EXPLODE

#undef BOMB_DESTROYED
#undef IN_RADIUS

#undef BOMB_RADIUS_SQR

#undef BOMB_ENT_BOMB
#undef BOMB_ENT_SPARKS
#undef BOMB_ENT_BEAM

#undef BEAM_COLOR_R
#undef BEAM_COLOR_G
#undef BEAM_COLOR_B

#undef BEAM_COLOR_INACTIVE
#undef BEAM_COLOR_ACTIVE
