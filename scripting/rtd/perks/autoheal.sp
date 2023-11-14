/**
* Autoheal perk.
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
#define Healing Int[1]
#define Particle Int[2]

DEFINE_CALL_APPLY_REMOVE(Autoheal)

public void Autoheal_Init(const Perk perk)
{
	PrecacheSound(SOUND_HEALING);
	PrecacheSound(SOUND_ENDHEAL);
}

public void Autoheal_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Health = perk.GetPrefCell("health", 4);
	Cache[client].Healing = false;

	switch (TF2_GetClientTeam(client))
	{
		case TFTeam_Red:
			Cache[client].Particle = view_as<int>(TEParticles.HealJoltRed);

		case TFTeam_Blue:
			Cache[client].Particle = view_as<int>(TEParticles.HealJoltBlue);
	}

	Cache[client].Repeat(perk.GetPrefFloat("rate", 0.1), Autoheal_Tick);
}

public void Autoheal_RemovePerk(const int client)
{
	StopSound(client, SNDCHAN_AUTO, SOUND_HEALING);
}

Action Autoheal_Tick(const int client)
{
	int iCurHealth = GetClientHealth(client);
	bool bShouldHeal = iCurHealth < Shared[client].MaxHealth;

	if (bShouldHeal)
	{
		SetEntityHealth(client, MinInt(iCurHealth + Cache[client].Health, Shared[client].MaxHealth));
		SendTEParticleAttached(view_as<TEParticleId>(Cache[client].Particle), client, GetRandomInt(0, 22));

		if (!Cache[client].Healing)
			EmitSoundToAll(SOUND_HEALING, client, SNDCHAN_AUTO, _, _, 0.35);
	}
	else
	{
		if (Cache[client].Healing)
		{
			StopSound(client, SNDCHAN_AUTO, SOUND_HEALING);
			EmitSoundToAll(SOUND_ENDHEAL, client, SNDCHAN_AUTO);
		}
	}

	Cache[client].Healing = bShouldHeal;

	return Plugin_Continue;
}

#undef SOUND_HEALING
#undef SOUND_ENDHEAL

#undef Health
#undef Healing
#undef Particle
