/**
* Smite perk.
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

#define SOUND_ELECTRIC_MIST "ambient/nucleus_electricity.wav"

// not configurable, distance between electrocution ticks needs this to be small
#define TICK_INTERVAL 0.1

#define ElectrocutionTicks Int[0]
#define IsElectrocuted Int[1]
#define TicksLeft Int[2]
#define ElectrocuteEffect Int[3]
#define TickDamage Float[0]
#define BaseSpeed Float[1]
#define ElectrocutionTime Float[2]
#define Slowdown Float[3]
#define Proxy EntSlot_1

static char g_sSoundZap[][] = {
	"ambient/energy/zap1.wav",
	"ambient/energy/zap2.wav",
	"ambient/energy/zap3.wav",
}

DEFINE_CALL_APPLY_REMOVE(Smite)

public void Smite_Init(const Perk perk)
{
	PrecacheSound(SOUND_ELECTRIC_MIST);
	PrecacheSound(g_sSoundZap[0]);
	PrecacheSound(g_sSoundZap[1]);
	PrecacheSound(g_sSoundZap[2]);
}

void Smite_ApplyPerk(const int client, const Perk perk)
{
	float fDamage = 999.0;

	if (perk.Time != -1)
	{
		int iMaxHealth = Shared[client].MaxHealth;
		int iElectrocutionTics = perk.GetPrefCell("damage_ticks", 3);
		float fInitialDamageMultiplier = perk.GetPrefFloat("initial_damage", 0.2);
		float fTickDamageMultiplier = perk.GetPrefFloat("tick_damage", 0.04);

		Cache[client].ElectrocutionTicks = iElectrocutionTics;
		Cache[client].IsElectrocuted = false;
		Cache[client].TicksLeft = Smite_GenerateTicksLeft(client);
		Cache[client].TickDamage = fTickDamageMultiplier * iMaxHealth;
		Cache[client].BaseSpeed = GetBaseSpeed(client);
		Cache[client].ElectrocutionTime = TICK_INTERVAL * iElectrocutionTics;
		Cache[client].Slowdown = perk.GetPrefFloat("slowdown", 0.2);

		// Due to technical reasons, client cannot die on the same frame a timed perk is applied,
		// make sure they are left with at least 1 health.
		fDamage = Min(fInitialDamageMultiplier * iMaxHealth, float(GetClientHealth(client) - 1));
		SDKHook(client, SDKHook_OnTakeDamagePost, Smite_OnTakeDamage);
	}

	SDKHooks_TakeDamage(client, client, client, fDamage, DMG_SHOCK);

	int iStrike[2];
	iStrike[0] = CreateEntityByName("info_target");
	if (iStrike[0] <= MaxClients)
		return;

	KILL_ENT_IN(iStrike[0],0.25);

	iStrike[1] = CreateEntityByName("info_target");
	if (iStrike[1] <= MaxClients)
		return;

	KILL_ENT_IN(iStrike[1],0.25);

	float fPos[3];
	GetClientAbsOrigin(client, fPos);

	int iRed, iBlue;
	switch (TF2_GetClientTeam(client))
	{
		case TFTeam_Red:
		{
			iRed = 255;
			iBlue = 100;
			Cache[client].ElectrocuteEffect = view_as<int>(TEParticles.ElectrocutedRed);
			SendTEParticleWithPriority(TEParticles.SparkVortexRed, fPos);
		}

		case TFTeam_Blue:
		{
			iRed = 100;
			iBlue = 255;
			Cache[client].ElectrocuteEffect = view_as<int>(TEParticles.ElectrocutedBlue);
			SendTEParticleWithPriority(TEParticles.SparkVortexBlue, fPos);
		}
	}

	SendTEParticleWithPriority(TEParticles.ShockwaveFlat, fPos);

	if (perk.Time != -1)
	{
		Smite_SendElectrocuteParticle(client);

		int iProxy = CreateProxy(client);
		if (iProxy > MaxClients)
		{
			Cache[client].SetEnt(Proxy, iProxy);
			SendTEParticleLingeringAttachedProxy(TEParticlesLingering.ElectricMist, iProxy);
			EmitSoundToAll(SOUND_ELECTRIC_MIST, client, _, _, _, _, 150);
		}

		Cache[client].Repeat(TICK_INTERVAL, Smite_Tick);
	}

	fPos[2] += 32.0;
	TeleportEntity(iStrike[0], fPos, NULL_VECTOR, NULL_VECTOR);
	fPos[2] += 1024.0;
	TeleportEntity(iStrike[1], fPos, NULL_VECTOR, NULL_VECTOR);

	int iBeam = ConnectWithBeam(iStrike[1], iStrike[0], iRed, 100, iBlue, 10.0, 4.0, 10.0);
	KILL_ENT_IN(iBeam,0.1);
}

void Smite_RemovePerk(const int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamagePost, Smite_OnTakeDamage);

	ResetSpeed(client);
	StopSound(client, SNDCHAN_AUTO, SOUND_ELECTRIC_MIST);
}

public Action Smite_Tick(const int client)
{
	int iTicksLeft = Cache[client].TicksLeft - 1;
	if (iTicksLeft > 0)
	{
		Cache[client].TicksLeft = iTicksLeft;

		if (Cache[client].IsElectrocuted)
			SDKHooks_TakeDamage(client, client, client, Cache[client].TickDamage, DMG_SHOCK);

		return Plugin_Continue;
	}

	if (Cache[client].IsElectrocuted)
	{
		Cache[client].IsElectrocuted = false;

		SetSpeed(client, Cache[client].BaseSpeed);
		Cache[client].TicksLeft = Smite_GenerateTicksLeft(client);
	}
	else // not being electrocuted
	{
		Cache[client].IsElectrocuted = true;
		Cache[client].TicksLeft = Cache[client].ElectrocutionTicks;

		TF2_AddCondition(client, TFCond_CritOnFirstBlood, Cache[client].ElectrocutionTime);
		SetSpeed(client, Cache[client].BaseSpeed, Cache[client].Slowdown);

		ViewPunchRand(client, 5.0);
		EmitSoundToAll(g_sSoundZap[GetRandomInt(0, 2)], client, _, _, _, _, GetRandomInt(90, 110));
		Smite_SendElectrocuteParticle(client);
	}

	return Plugin_Continue;
}

public void Smite_OnTakeDamage(int client, int iAttacker, int iInflictor, float fDamage, int iType)
{
	// Speed up the electrocution after getting hit
	if (client != iAttacker && !Cache[client].IsElectrocuted && fDamage > 8.0)
		Cache[client].TicksLeft -= 10;
}

int Smite_GenerateTicksLeft(const int client)
{
	int iElectrocutionTicks = Cache[client].ElectrocutionTicks;
	return GetRandomInt(iElectrocutionTicks + 20, iElectrocutionTicks + 30);
}

void Smite_SendElectrocuteParticle(const int client)
{
	int iParticle = Cache[client].ElectrocuteEffect;
	SendTEParticleAttached(view_as<TEParticleId>(iParticle), client);
}

#undef SOUND_ELECTRIC_MIST

#undef TICK_INTERVAL

#undef ElectrocutionTicks
#undef IsElectrocuted
#undef TicksLeft
#undef ElectrocuteEffect
#undef TickDamage
#undef BaseSpeed
#undef ElectrocutionTime
#undef Slowdown
#undef Proxy
