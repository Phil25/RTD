/**
* Sickness perk.
* Copyright (C) 2024 Filip Tomaszewski
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

#define HealthyTicks Int[0]
#define Infect Int[1]
#define InfectRangeSquared Float[0]
#define MinDamage Float[1]
#define MaxDamage Float[2]

static char g_sSoundCough[][] = {
	"ambient/voices/cough1.wav",
	"ambient/voices/cough2.wav",
	"ambient/voices/cough3.wav",
	"ambient/voices/cough4.wav"
};

DEFINE_CALL_APPLY(Sickness)

public void Sickness_Init(const Perk perk)
{
	for (int i = 0; i < 4; ++i)
		PrecacheSound(g_sSoundCough[i]);
}

void Sickness_ApplyPerk(const int client, const Perk perk)
{
	float fInfectRange = perk.GetPrefFloat("range", 100.0);

	Cache[client].HealthyTicks = GetRandomInt(8, 16);
	Cache[client].Infect = perk.GetPrefCell("infect", 1);
	Cache[client].InfectRangeSquared = fInfectRange * fInfectRange;
	Cache[client].MinDamage = perk.GetPrefFloat("mindamage", 5.0);
	Cache[client].MaxDamage = perk.GetPrefFloat("maxdamage", 10.0);

	Cache[client].Repeat(0.25, Sickness_Tick);
}

public Action Sickness_Tick(const int client)
{
	switch (--Cache[client].HealthyTicks)
	{
		case 0:
		{
			EmitSoundToAll(g_sSoundCough[GetRandomInt(0, 3)], client);
			Sickness_Cough(client, Cache[client].MinDamage, Cache[client].MaxDamage);

			if (Cache[client].Infect)
				Sickness_Spread(client);
		}

		case -1:
		{
			Sickness_Cough(client, Cache[client].MinDamage, Cache[client].MaxDamage);
			Cache[client].HealthyTicks = GetRandomInt(8, 16);
		}
	}

	return Plugin_Continue;
}

void Sickness_Cough(const int client, const float fMinDamage, const float fMaxDamage, const int iAttacker=0)
{
	SendTEParticleAttached(TEParticles.GreenGoop, client, .fOffset={0.0, 0.0, 36.0});

	float fDamage = GetRandomFloat(fMinDamage, fMaxDamage);
	SDKHooks_TakeDamage(client, iAttacker, iAttacker, fDamage, DMG_PREVENT_PHYSICS_FORCE);

	float fShake[3];
	fShake[0] = GetRandomFloat(10.0, 15.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fShake);
}

void Sickness_Spread(const int client)
{
	float fPos[3];
	GetClientAbsOrigin(client, fPos);

	TFTeam eTeam = TF2_GetClientTeam(client);
	float fRangeSquared = Cache[client].InfectRangeSquared;
	float fMinDamage = Cache[client].MinDamage * 0.8;
	float fMaxDamage = Cache[client].MaxDamage * 0.8;
	int iUserId = GetClientUserId(client);

	for (int i = 1; i <= MaxClients; ++i)
	{
		if (!Sickness_IsValidTarget(i, eTeam, fPos, fRangeSquared))
			continue;

		DataPack hData = new DataPack();
		hData.WriteCell(3);
		hData.WriteCell(GetRandomInt(6, 10));
		hData.WriteCell(GetClientUserId(i));
		hData.WriteCell(iUserId);
		hData.WriteFloat(fMinDamage);
		hData.WriteFloat(fMaxDamage);

		CreateTimer(0.2, Timer_Sickness_Infected, hData, TIMER_REPEAT | TIMER_HNDL_CLOSE);
	}
}

bool Sickness_IsValidTarget(const int iTarget, const TFTeam eClientTeam, const float fClientPos[3], const float fRangeSquared)
{
	if (!IsClientInGame(iTarget) || !IsPlayerAlive(iTarget) || TF2_GetClientTeam(iTarget) == eClientTeam)
		return false;

	float fTargetPos[3];
	GetClientAbsOrigin(iTarget, fTargetPos);

	return GetVectorDistance(fClientPos, fTargetPos, true) <= fRangeSquared;
}

public Action Timer_Sickness_Infected(Handle hTimer, DataPack hData)
{
	hData.Reset();
	int iTicks = hData.ReadCell();

	if (iTicks <= 0)
		return Plugin_Stop;

	int iHealthyTicks = hData.ReadCell();

	int client = GetClientOfUserId(hData.ReadCell());
	if (!client || !IsPlayerAlive(client) || g_eInGodmode.Test(client))
		return Plugin_Stop;

	int iAttacker = GetClientOfUserId(hData.ReadCell());
	if (!iAttacker)
		return Plugin_Stop;

	float fMinDamage = hData.ReadFloat();
	float fMaxDamage = hData.ReadFloat();

	switch (iHealthyTicks)
	{
		case 0:
		{
			EmitSoundToAll(g_sSoundCough[GetRandomInt(0, 3)], client);
			Sickness_Cough(client, fMinDamage, fMaxDamage, iAttacker);
			// fallthrough
		}

		case -1:
		{
			Sickness_Cough(client, fMinDamage, fMaxDamage, iAttacker);

			hData.Reset();
			hData.WriteCell(iTicks - 1);
			hData.WriteCell(GetRandomInt(6, 10));

			return Plugin_Continue;
		}

		default:
		{
			// fallthrough
		}
	}

	hData.Reset();
	hData.WriteCell(iTicks);
	hData.WriteCell(iHealthyTicks - 1);

	return Plugin_Continue;
}

#undef HealthyTicks
#undef Infect
#undef InfectRangeSquared
#undef MinDamage
#undef MaxDamage
