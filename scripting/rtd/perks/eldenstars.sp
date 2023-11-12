/**
* Elden Stars perk.
* Copyright (C) 2023 Filip Tomaszewski
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

#define SOUND_FIRE "weapons/mortar/mortar_fire1.wav"
#define SOUND_LOOP "weapons/phlog_loop.wav"
#define SOUND_CHANGE "weapons/phlog_end.wav"

#define Team Int[0]
#define LastOrb Int[1]
#define LastChip Int[2]
#define Speed Int[3]
#define NextAttack Float[0]
#define Rate Float[1]
#define Lifetime Float[2]
#define Damage Float[3]

DEFINE_CALL_APPLY_REMOVE(EldenStars)

public void EldenStars_Init(const Perk perk)
{
	PrecacheSound(SOUND_FIRE);
	PrecacheSound(SOUND_LOOP);
	PrecacheSound(SOUND_CHANGE);

	Events.OnVoice(perk, EldenStars_OnVoice);
}

void EldenStars_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Team = GetClientTeam(client);
	Cache[client].LastOrb = INVALID_ENT_REFERENCE;
	Cache[client].LastChip = INVALID_ENT_REFERENCE;
	Cache[client].Speed = perk.GetPrefCell("speed", 200);
	Cache[client].NextAttack = GetEngineTime();
	Cache[client].Rate = perk.GetPrefFloat("rate", 1.0);
	Cache[client].Lifetime = perk.GetPrefFloat("lifetime", 3.5);
	Cache[client].Damage = perk.GetPrefFloat("damage", 15.0);

	PrintToChat(client, "%s %T", CHAT_PREFIX, "RTD2_Perk_Attack", LANG_SERVER, 0x03, 0x01);
}

void EldenStars_RemovePerk(const int client)
{
	int iLastOrb = EntRefToEntIndex(Cache[client].LastOrb);
	if (iLastOrb > MaxClients)
	{
		EldenStars_StopSound(iLastOrb);
		AcceptEntityInput(iLastOrb, "Kill");
	}
}

void EldenStars_OnVoice(const int client)
{
	float fTime = GetEngineTime();
	if (fTime < Cache[client].NextAttack)
		return;

	Cache[client].NextAttack = fTime + Cache[client].Rate;

	int iLastOrb = EntRefToEntIndex(Cache[client].LastOrb);
	if (iLastOrb > MaxClients)
	{
		EldenStars_StopSound(iLastOrb);
		AcceptEntityInput(iLastOrb, "Kill");
	}

	int iOrb = CreateEntityByName("tf_projectile_energy_ball");
	if (iOrb <= MaxClients)
		return;

	int iReference = EntIndexToEntRef(iOrb);
	Cache[client].LastOrb = iReference;

	int iTeam = Cache[client].Team;
	SetEntPropEnt(iOrb, Prop_Send, "m_hOwnerEntity", client);  
	SetEntProp(iOrb, Prop_Send, "m_iTeamNum", iTeam);  
	SetEntProp(iOrb, Prop_Send, "m_nSkin", iTeam - 2);  
	SetEntDataFloat(iOrb, PropOffsets.EnergyBallDamage, 150.0, true);

	float fAng[3], fPos[3], fVel[3];
	GetClientEyeAngles(client, fAng);
	GetClientEyePosition(client, fPos);
	GetAngleVectors(fAng, fVel, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fVel, 180.0);

	fPos[2] += 20.0;

	DispatchSpawn(iOrb);
	TeleportEntity(iOrb, fPos, fAng, fVel);

	SetEntityModel(iOrb, EMPTY_MODEL);

	SendTEParticleLingeringAttachedProxy(TEParticlesLingering.GodRays, iOrb, _, true);
	SendTEParticleLingeringAttachedProxy(TEParticlesLingering.GoldenTwinkles, iOrb);

	static int iColor[4] = {255, 255, 128, 255};
	TE_SetupBeamFollow(iOrb, Materials.Laser, Materials.Halo, 5.0, 5.0, 0.0, 5, iColor);
	TE_SendToAll();

	switch (view_as<TFTeam>(iTeam))
	{
		case TFTeam_Red:
			SendTEParticleLingeringAttachedProxy(TEParticlesLingering.FireballGlowRed, iOrb);

		case TFTeam_Blue:
			SendTEParticleLingeringAttachedProxy(TEParticlesLingering.FireballGlowBlue, iOrb);
	}

	EmitSoundToAll(SOUND_CHANGE, iOrb, _, _, _, _, 200);
	EmitSoundToAll(SOUND_LOOP, iOrb, SNDCHAN_ITEM, _, _, _, 150);
	SDKHook(iOrb, SDKHook_StartTouchPost, EldenStars_StopSound);

	CreateTimer(1.0, Timer_EldenStars_ChipStart, iReference);
}

public void EldenStars_StopSound(const int iOrb)
{
	StopSound(iOrb, SNDCHAN_ITEM, SOUND_LOOP);
	EmitSoundToAll(SOUND_CHANGE, iOrb, _, _, _, _, 50);
}

public Action Timer_EldenStars_ChipStart(Handle hTimer, const int iRef)
{
	CreateTimer(0.25, Timer_EldenStars_Chip, iRef, TIMER_REPEAT);
	return Plugin_Stop;
}

public Action Timer_EldenStars_Chip(Handle hTimer, const int iRef)
{
	int iOrb = EntRefToEntIndex(iRef);
	if (iOrb <= MaxClients)
		return Plugin_Stop;

	int client = GetEntPropEnt(iOrb, Prop_Send, "m_hOwnerEntity");
	if (!(1 <= client <= MaxClients))
		return Plugin_Stop;

	int iLastChip = EntRefToEntIndex(Cache[client].LastChip);
	if (iLastChip > MaxClients)
		Homing_Push(iLastChip, _, 4);

	int iChip = CreateEntityByName("tf_projectile_energy_ball");
	if (iChip <= MaxClients)
		return Plugin_Continue;

	KillEntIn(iChip, Cache[client].Lifetime);
	Cache[client].LastChip = EntIndexToEntRef(iChip);

	EmitSoundToAll(SOUND_FIRE, iChip, _, _, _, _, 200);

	int iTeam = GetClientTeam(client);
	float fSpeed = float(Cache[client].Speed);
	float fVelocity[3];
	fVelocity[0] = fSpeed;
	fVelocity[1] = fSpeed;
	fVelocity[2] = fSpeed;

	SetEntPropEnt(iChip, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(iChip, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iChip, Prop_Send, "m_nSkin", iTeam - 2);
	SetEntPropVector(iChip, Prop_Send, "m_vInitialVelocity", fVelocity);
	SetEntDataFloat(iChip, PropOffsets.EnergyBallDamage, Cache[client].Damage, true);

	float fPos[3], fAng[3];
	GetEntPropVector(iOrb, Prop_Send, "m_vecOrigin", fPos);
	GetEntPropVector(iOrb, Prop_Send, "m_angRotation", fAng);

	fAng[2] = GetRandomFloat(0.0, 360.0);

	float fForward[3], fRight[3];
	GetAngleVectors(fAng, fForward, fRight, NULL_VECTOR);
	ScaleVector(fForward, -5.0); // offset to spawn chip, otherwise they collide with the orb
	ScaleVector(fRight, fSpeed);
	AddVectors(fPos, fForward, fPos);

	DispatchSpawn(iChip);
	TeleportEntity(iChip, fPos, NULL_VECTOR, fRight);

	SetEntityModel(iChip, EMPTY_MODEL);

	SendTEParticleLingeringAttachedProxy(TEParticlesLingering.GoldenTwinkles, iChip, _, true);

	static int iColorRed[4] = {255, 50, 50, 255};
	static int iColorBlue[4] = {50, 50, 255, 255};

	switch (view_as<TFTeam>(iTeam))
	{
		case TFTeam_Red:
			TE_SetupBeamFollow(iChip, Materials.Laser, Materials.Halo, 1.0, 10.0, 5.0, 5, iColorRed);

		case TFTeam_Blue:
			TE_SetupBeamFollow(iChip, Materials.Laser, Materials.Halo, 1.0, 10.0, 5.0, 5, iColorBlue);
	}

	TE_SendToAll();

	return Plugin_Continue;
}

#undef SOUND_FIRE
#undef SOUND_LOOP
#undef SOUND_CHANGE

#undef Team
#undef LastOrb
#undef LastChip
#undef Speed
#undef NextAttack
#undef Rate
#undef Lifetime
#undef Damage
