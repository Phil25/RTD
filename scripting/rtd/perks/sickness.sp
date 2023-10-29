/**
* Sickness perk.
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

#include "rtd/macros.sp"

#define SICKNESS_PARTICLE "spell_skeleton_goop_green"

#define HealthyTicks Int[0]
#define MinDamage Float[0]
#define MaxDamage Float[1]

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
	Cache[client].HealthyTicks = GetRandomInt(8, 16);
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
			Sickness_Cough(client);
		}

		case -1:
		{
			Sickness_Cough(client);
			Cache[client].HealthyTicks = GetRandomInt(8, 16);
		}
	}

	return Plugin_Continue;
}

void Sickness_Cough(const int client)
{
	int iParticle = CreateParticle(client, SICKNESS_PARTICLE);
	KILL_ENT_IN(iParticle,0.1);

	float fDamage = GetRandomFloat(Cache[client].MinDamage, Cache[client].MaxDamage);
	SDKHooks_TakeDamage(client, client, client, fDamage, DMG_PREVENT_PHYSICS_FORCE);

	float fShake[3];
	fShake[0] = GetRandomFloat(10.0, 15.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fShake);
}

#undef SICKNESS_PARTICLE

#undef HealthyTicks
#undef MinDamage
#undef MaxDamage
