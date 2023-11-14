/**
* Team Autoheal perk.
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

#define SOUND_HEALING "items/medcharge4.wav"
#define SOUND_ENDHEAL "items/medshotno1.wav"

#define Health Int[0]
#define Team Int[1]
#define Particle Int[2]
#define EffectCount Int[3]
#define Range Float[0]
#define RangeSquared Float[1]
#define Healing Flags
#define Effect EntSlot_1

DEFINE_CALL_APPLY_REMOVE(TeamAutoheal)

public void TeamAutoheal_Init(const Perk perk)
{
	PrecacheSound(SOUND_HEALING);
	PrecacheSound(SOUND_ENDHEAL);
}

public void TeamAutoheal_ApplyPerk(const int client, const Perk perk)
{
	float fRange = perk.GetPrefFloat("range", 270.0);

	Cache[client].Health = perk.GetPrefCell("health", 2);
	Cache[client].EffectCount = RoundFloat(fRange / 45.0);
	Cache[client].Range = fRange;
	Cache[client].RangeSquared = fRange * fRange;
	Cache[client].Healing.Reset();

	TEParticleLingeringId eHealAura = TEParticlesLingering.GlowRed;

	switch (TF2_GetClientTeam(client))
	{
		case TFTeam_Red:
		{
			Cache[client].Team = view_as<int>(TFTeam_Red);
			Cache[client].Particle = view_as<int>(TEParticles.HealJoltRed);
			eHealAura = TEParticlesLingering.GlowRed;
		}

		case TFTeam_Blue:
		{
			Cache[client].Team = view_as<int>(TFTeam_Blue);
			Cache[client].Particle = view_as<int>(TEParticles.HealJoltBlue);
			eHealAura = TEParticlesLingering.GlowBlue;
		}
	}

	int iProxy = CreateProxy(client);
	if (iProxy > MaxClients)
	{
		SendTEParticleLingeringAttachedProxyExcept(eHealAura, iProxy, client);
		Cache[client].SetEnt(Effect, iProxy);
	}

	Cache[client].Repeat(perk.GetPrefFloat("rate", 0.1), TeamAutoheal_TeamTick);
}

public void TeamAutoheal_RemovePerk(const int client)
{
	for (int i = 1; i <= MaxClients; ++i)
		if (IsClientInGame(i) && Cache[client].Healing.Test(i))
			StopSound(i, SNDCHAN_AUTO, SOUND_HEALING);
}

Action TeamAutoheal_TeamTick(const int client)
{
	TFTeam eTeam = view_as<TFTeam>(Cache[client].Team);
	float fRangeSquared = Cache[client].RangeSquared;

	for (int i = 1; i <= MaxClients; ++i)
	{
		if (TeamAutoHeal_IsValidTarget(client, i, eTeam, fRangeSquared))
		{
			TeamAutoheal_Tick(client, i);
		}
		else if (Cache[client].Healing.Test(i))
		{
			StopSound(i, SNDCHAN_AUTO, SOUND_HEALING);
			Cache[client].Healing.Unset(i);
		}
	}

	float fClientPos[3];
	GetClientAbsOrigin(client, fClientPos);
	fClientPos[2] += 60.0; // roughly player center

	float fPos[3], fDir[2];
	TEParticleId eParticleId = view_as<TEParticleId>(Cache[client].Particle);

	for (int i = 0; i < Cache[client].EffectCount; ++i)
	{
		float fRadius = GetRandomFloat(Cache[client].Range - 80.0, Cache[client].Range);

		fDir[0] = GetRandomFloat(0.0, 2.0 * 3.1415); // radians
		fDir[1] = GetRandomFloat(0.0, 2.0 * 3.1415);
		GetPointOnSphere(fClientPos, fDir, fRadius, fPos);

		SendTEParticle(eParticleId, fPos);
	}

	return Plugin_Continue;
}

void TeamAutoheal_Tick(const int client, const int iTarget)
{
	int iCurHealth = GetClientHealth(iTarget);
	bool bShouldHeal = iCurHealth < Shared[iTarget].MaxHealth;

	if (bShouldHeal)
	{
		SetEntityHealth(iTarget, MinInt(iCurHealth + Cache[client].Health, Shared[iTarget].MaxHealth));
		SendTEParticleAttached(view_as<TEParticleId>(Cache[client].Particle), iTarget, GetRandomInt(0, 22));

		if (!Cache[client].Healing.Test(iTarget))
			EmitSoundToAll(SOUND_HEALING, iTarget, SNDCHAN_AUTO, _, _, 0.35);

		Cache[client].Healing.Set(iTarget);
	}
	else
	{
		if (Cache[client].Healing.Test(iTarget))
		{
			StopSound(iTarget, SNDCHAN_AUTO, SOUND_HEALING);
			EmitSoundToAll(SOUND_ENDHEAL, iTarget, SNDCHAN_AUTO);
		}

		Cache[client].Healing.Unset(iTarget);
	}
}

bool TeamAutoHeal_IsValidTarget(int client, int iTarget, TFTeam eClientTeam, float fRangeSquared)
{
	if (!IsClientInGame(iTarget))
		return false;

	if (TF2_IsPlayerInCondition(iTarget, TFCond_Cloaked))
		return false;

	float fPos[3], fEndPos[3];
	GetClientAbsOrigin(client, fPos);
	GetClientAbsOrigin(iTarget, fEndPos);

	if (GetVectorDistance(fPos, fEndPos, true) > fRangeSquared)
		return false;

	bool bDisguised = TF2_IsPlayerInCondition(iTarget, TFCond_Disguised);
	bool bSameTeam = eClientTeam == TF2_GetClientTeam(iTarget);

	// Do not heal if:
	// - our friendly Spy is disguised, or
	// - an enemy Spy is NOT disguised.
	// This does not account for being able to disguise as the same team.
	if ((bDisguised && bSameTeam) || (!bDisguised && !bSameTeam))
		return false;

	// Most expensive call last
	return CanEntitySeeTarget(client, iTarget);
}

#undef SOUND_HEALING
#undef SOUND_ENDHEAL

#undef Health
#undef Team
#undef Particle
#undef EffectCount
#undef Range
#undef RangeSquared
#undef Healing
#undef Effect
