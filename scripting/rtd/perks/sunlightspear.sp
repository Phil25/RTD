/**
* Sunlight Spear perk.
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

#define SOUND_CONJURE "misc/halloween/spell_lightning_ball_cast.wav"

#define TICK_INTERVAL 0.1

#define ElectrocuteEffect Int[0]
#define Ticks Int[1]
#define Slowdown Int[2]
#define AllySpeed Int[3]
#define NextAttack Float[0]
#define Rate Float[1]
#define Speed Float[2]
#define Damage Float[3]

static char g_sSoundZap[][] = {
	"ambient/energy/zap1.wav",
	"ambient/energy/zap2.wav",
	"ambient/energy/zap3.wav",
}

DEFINE_CALL_APPLY(SunlightSpear)

public void SunlightSpear_Init(const Perk perk)
{
	PrecacheSound(SOUND_CONJURE);
	PrecacheSound(g_sSoundZap[0]);
	PrecacheSound(g_sSoundZap[1]);
	PrecacheSound(g_sSoundZap[2]);

	Events.OnVoice(perk, SunlightSpear_OnVoice);
}

void SunlightSpear_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Ticks = perk.GetPrefCell("ticks", 5);
	Cache[client].Slowdown = ClampInt(RoundFloat(perk.GetPrefFloat("slowdown", 0.2) * 100), 0, 100);
	Cache[client].AllySpeed = RoundFloat(perk.GetPrefFloat("ally_speed", 2.0) * 100);
	Cache[client].NextAttack = GetEngineTime();
	Cache[client].Rate = perk.GetPrefFloat("rate", 1.0);
	Cache[client].Speed = perk.GetPrefFloat("speed", 1600.0);
	Cache[client].Damage = perk.GetPrefFloat("damage", 10.0);

	switch (TF2_GetClientTeam(client))
	{
		case TFTeam_Red:
			Cache[client].ElectrocuteEffect = view_as<int>(TEParticles.ElectrocutedRed);

		case TFTeam_Blue:
			Cache[client].ElectrocuteEffect = view_as<int>(TEParticles.ElectrocutedBlue);
	}

	PrintToChat(client, CHAT_PREFIX ... " %T", "RTD2_Perk_Attack", LANG_SERVER, 0x03, 0x01);
}

void SunlightSpear_OnVoice(const int client)
{
	float fTime = GetEngineTime();
	if (fTime < Cache[client].NextAttack)
		return;

	Cache[client].NextAttack = fTime + Cache[client].Rate;

	EmitSoundToAll(SOUND_CONJURE, client, _, _, _, _, 160);
	
	float fAng[3], fPos[3], fVel[3];
	GetClientEyeAngles(client, fAng);
	GetClientEyePosition(client, fPos);

	fPos[2] -= 12.0;

	GetAngleVectors(fAng, fVel, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fVel, Cache[client].Speed);

	int iTesla = CreateTesla(fPos);
	if (iTesla <= MaxClients)
		return;

	KILL_ENT_IN(iTesla,10.0)

	// prop_physics_override needs some sort of active func_* entity in its parent hierarchy in
	// order to move with a "fly" movetype. An infinitely rotating func_door_rotating works well.
	int iRot = CreateEntityByName("func_door_rotating");
	if (iRot <= MaxClients)
		return;

	KILL_ENT_IN(iRot,10.0);

	DispatchKeyValueVector(iRot, "origin", fPos);
	DispatchKeyValue(iRot, "distance", "99999");
	DispatchKeyValue(iRot, "spawnflags", "4104"); // passable | silent
	DispatchSpawn(iRot);

	AcceptEntityInput(iRot, "Open");

	int iCarrier = CreateEntityByName("prop_physics_override");
	if (iCarrier <= MaxClients)
		return;

	KILL_ENT_IN(iCarrier,10.0);

	SetEntPropEnt(iCarrier, Prop_Send, "m_hOwnerEntity", client);
	DispatchKeyValue(iCarrier, "model", MODEL_PROJECTILE);
	DispatchKeyValue(iCarrier, "modelscale", "0");

	DispatchSpawn(iCarrier);
	ActivateEntity(iCarrier);

	SetEntityMoveType(iCarrier, MOVETYPE_FLY);
	TeleportEntity(iCarrier, fPos, NULL_VECTOR, fVel);

	Parent(iTesla, iRot);
	Parent(iRot, iCarrier);

	static int iColor[4] = {255, 255, 128, 255};
	TE_SetupBeamFollow(iTesla, Materials.Laser, Materials.Halo, 0.4, 20.0, 10.0, 1, iColor);
	TE_SendToAll();

	SDKHook(iCarrier, SDKHook_StartTouch, SunlightSpear_OnTouch);
}

public Action SunlightSpear_OnTouch(const int iProjectile, const int iVictim)
{
	int iAttacker = GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity");
	if (!iAttacker)
		return Plugin_Handled; // left the game

	int iVictimUserId = -1;
	if (1 <= iVictim <= MaxClients)
	{
		iVictimUserId = GetClientUserId(iVictim);

		int iParticle = Cache[iAttacker].ElectrocuteEffect;
		SendTEParticleAttached(view_as<TEParticleId>(iParticle), iVictim);

		if (TF2_GetClientTeam(iAttacker) == TF2_GetClientTeam(iVictim))
		{
			TF2_AddCondition(iVictim, TFCond_SpeedBuffAlly, float(Cache[iAttacker].AllySpeed) / 100.0);
			return Plugin_Handled;
		}

		SunlightSpear_DamageTick(iVictim, iAttacker, true);

		float fSlowdown = 1.0 - float(Cache[iAttacker].Slowdown) / 100.0;
		TF2_StunPlayer(iVictim, Cache[iAttacker].Ticks * TICK_INTERVAL, fSlowdown, TF_STUNFLAG_SLOWDOWN, iAttacker);
	}

	float fOrigin[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", fOrigin);

	SunlightSpear_ParticlesTick(fOrigin);

	DataPack hData = new DataPack();
	hData.WriteCell(Cache[iAttacker].Ticks);
	hData.WriteFloat(fOrigin[0]);
	hData.WriteFloat(fOrigin[1]);
	hData.WriteFloat(fOrigin[2]);
	hData.WriteCell(iVictimUserId);
	hData.WriteCell(GetClientUserId(iAttacker));
	CreateTimer(TICK_INTERVAL, Timer_SunlightSpear_Tick, hData, TIMER_REPEAT | TIMER_DATA_HNDL_CLOSE);

	AcceptEntityInput(iProjectile, "KillHierarchy");

	return Plugin_Handled;
}

public Action Timer_SunlightSpear_Tick(Handle hTimer, DataPack hData)
{
	hData.Reset();

	int iTicks = hData.ReadCell() - 1;
	if (iTicks <= 0)
		return Plugin_Stop;

	float fOrigin[3];
	fOrigin[0] = hData.ReadFloat();
	fOrigin[1] = hData.ReadFloat();
	fOrigin[2] = hData.ReadFloat();

	SunlightSpear_ParticlesTick(fOrigin);

	int iVictim = GetClientOfUserId(hData.ReadCell());
	int iAttacker = GetClientOfUserId(hData.ReadCell());

	if (!iVictim || !iAttacker)
		return Plugin_Stop;

	SunlightSpear_DamageTick(iVictim, iAttacker);

	hData.Reset();
	hData.WriteCell(iTicks);

	return Plugin_Continue;
}

void SunlightSpear_DamageTick(const int iVictim, const int iAttacker, const bool bInitial=false)
{
	if (!CanPlayerBeHurt(iVictim, iAttacker))
		return;

	float fDamage = Cache[iAttacker].Damage;
	fDamage += fDamage * view_as<int>(bInitial);

	SDKHooks_TakeDamage(iVictim, iAttacker, iAttacker, fDamage, DMG_SHOCK);
	EmitSoundToAll(g_sSoundZap[GetRandomInt(0, 2)], iVictim, _, _, _, _, GetRandomInt(90, 110));
}

void SunlightSpear_ParticlesTick(const float fOrigin[3])
{
	float fPos[3], fDir[2];
	for (int i = 0; i < 3; ++i)
	{
		float fRadius = GetRandomFloat(10.0, 30.0);
		fDir[0] = GetRandomFloat(0.0, 2.0 * 3.1415);
		fDir[1] = GetRandomFloat(0.0, 2.0 * 3.1415);

		GetPointOnSphere(fOrigin, fDir, fRadius, fPos);
		SendTEParticleWithPriority(TEParticles.ElectricBurst, fPos);
	}
}

#undef SOUND_CONJURE

#undef TICK_INTERVAL

#undef ElectrocuteEffect
#undef Ticks
#undef Slowdown
#undef AllySpeed
#undef NextAttack
#undef Rate
#undef Speed
#undef Damage
