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

#define Destroyed Int[0]
#define InRadius Int[2]
#define RadiusSquared Float[0]
#define Bomb EntSlot_1
#define Sparks EntSlot_2
#define Beam EntSlot_3

#define BEAM_COLOR_R 60
#define BEAM_COLOR_G 60
#define BEAM_COLOR_B 60

#define BEAM_COLOR_INACTIVE "60 60 60"
#define BEAM_COLOR_ACTIVE "255 255 255"

DEFINE_CALL_APPLY_REMOVE(Explode)

public void Explode_Init(const Perk perk)
{
	PrecacheModel(MODEL_BOMB);
	PrecacheSound(BOMB_HIT_SOUND);
	PrecacheSound(BOMB_FUSE_SOUND);
	PrecacheSound(BOMB_DESTROY_SOUND);
	PrecacheSound(BOMB_BEAM_DRAG);
	PrecacheSound(SOUND_EXPLODE);
}

void Explode_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Destroyed = false;
	Cache[client].InRadius = true;

	float fBombRange = perk.GetPrefFloat("range");
	Cache[client].RadiusSquared = fBombRange * fBombRange;

	int iBomb = CreateEntityByName("prop_physics_override");
	if( iBomb <= MaxClients)
		return;

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
	Cache[client].SetEnt(Bomb, iBomb);
	Cache[client].SetEnt(Sparks, CreateEffect(fPos, "flare_sparks", GetPerkTimeFloat(perk)));
	Cache[client].SetEnt(Beam, ConnectWithBeam(client, iBomb, BEAM_COLOR_R, BEAM_COLOR_G, BEAM_COLOR_B));

	EmitSoundToAll(BOMB_FUSE_SOUND, iBomb);

	Cache[client].Repeat(0.1, Explode_BindToBomb);
}

void Explode_RemovePerk(int client)
{
	int iBomb = Cache[client].GetEnt(Bomb).Index;
	if (iBomb <= MaxClients)
		return;

	int iTimeLeft = g_hRollers.GetEndRollTime(client) - GetTime();
	bool bForcefullyRemoved = iTimeLeft > 1; // assumption

	if (!Cache[client].Destroyed && !bForcefullyRemoved)
	{
		float fPos[3];
		GetEntPropVector(iBomb, Prop_Send, "m_vecOrigin", fPos);

		SendTEParticle(TEParticles.ExplosionLarge, fPos);
		SendTEParticle(TEParticles.ExplosionLargeShockwave, fPos);
		EmitSoundToAll(SOUND_EXPLODE, iBomb);

		FakeClientCommandEx(client, "explode");
	}

	StopSound(iBomb, SNDCHAN_AUTO, BOMB_FUSE_SOUND);
}

public Action Explode_BindToBomb(const int client)
{
	int iBomb = Cache[client].GetEnt(Bomb).Index;
	if (iBomb <= MaxClients)
		return Plugin_Stop;

	float fClientOrigin[3], fBombOrigin[3];
	GetClientAbsOrigin(client, fClientOrigin);
	GetEntPropVector(iBomb, Prop_Send, "m_vecOrigin", fBombOrigin);

	if (GetVectorDistance(fClientOrigin, fBombOrigin, true) < Cache[client].RadiusSquared)
	{
		if (!Cache[client].InRadius)
		{
			Cache[client].InRadius = true;

			SetVariantString(BEAM_COLOR_INACTIVE);
			AcceptEntityInput(Cache[client].GetEnt(Beam).Index, "Color");

			StopSound(client, SNDCHAN_AUTO, BOMB_BEAM_DRAG);
		}

		return Plugin_Continue;
	}
	else
	{
		if (Cache[client].InRadius)
		{
			Cache[client].InRadius = false;

			SetVariantString(BEAM_COLOR_ACTIVE);
			AcceptEntityInput(Cache[client].GetEnt(Beam).Index, "Color");

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

public void Explode_OnBombTakeDamagePost(int iBomb, int iAtk, int iInflictor, float fDamage, int iType, int iWeapon, float fForce[3], float fPos[3])
{
	if (iType & (DMG_BULLET | DMG_CLUB))
	{
		SendTEParticleWithPriority(TEParticles.GreenBitsImpact, fPos);
	}
	else if (iType & DMG_BUCKSHOT)
	{
		float fShotPos[3];
		for (int i = 0; i < 3; ++i)
		{
			fShotPos[0] = fPos[0] + GetRandomFloat(-10.0, 10.0);
			fShotPos[1] = fPos[1] + GetRandomFloat(-10.0, 10.0);
			fShotPos[2] = fPos[2] + GetRandomFloat(-10.0, 10.0);
			SendTEParticleWithPriority(TEParticles.GreenBitsImpact, fShotPos);
		}
	}

	int iHealth = GetEntProp(iBomb, Prop_Data, "m_iHealth") - RoundFloat(fDamage);
	if (iHealth <= 0)
	{
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

void Explode_CompleteSuccess(const int iBomb, const float fPos[3])
{
	int client = Explode_FindOwningClient(iBomb);
	if (client == 0) // should never happen
	{
		AcceptEntityInput(iBomb, "Kill");
		return;
	}

	Cache[client].Destroyed = true;

	SendTEParticle(TEParticles.GreenBitsTwirl, fPos);
	SendTEParticle(TEParticles.GreenFog, fPos);
	EmitSoundToAll(BOMB_DESTROY_SOUND, iBomb);

	ForceRemovePerk(client);
}

int Explode_FindOwningClient(int iBomb)
{
	int iEntReference = EntIndexToEntRef(iBomb);

	for (int client = 1; client <= MaxClients; ++client)
		if (Cache[client].GetEnt(Bomb).Reference == iEntReference)
			return client;

	return 0;
}

#undef MODEL_BOMB

#undef BOMB_FUSE_SOUND
#undef BOMB_HIT_SOUND
#undef BOMB_DESTROY_SOUND
#undef BOMB_BEAM_DRAG
#undef SOUND_EXPLODE

#undef Destroyed
#undef InRadius
#undef RadiusSquared
#undef Bomb
#undef Sparks
#undef Beam

#undef BEAM_COLOR_R
#undef BEAM_COLOR_G
#undef BEAM_COLOR_B

#undef BEAM_COLOR_INACTIVE
#undef BEAM_COLOR_ACTIVE
