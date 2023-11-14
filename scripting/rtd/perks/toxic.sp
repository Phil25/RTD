/**
* Toxic perk.
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

#define Radius Float[0]
#define Damage Float[1]
#define SplatIndex Int[0]
#define EffectCount Int[1]

#define SOUND_TOXIC "player/general/flesh_burn.wav"

DEFINE_CALL_APPLY_REMOVE(Toxic)

public void Toxic_Init()
{
	PrecacheSound(SOUND_TOXIC);
}

void Toxic_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Radius = perk.GetPrefFloat("radius", 192.0);
	Cache[client].Damage = perk.GetPrefFloat("damage", 20.0);
	Cache[client].EffectCount = RoundFloat(Cache[client].Radius / 64.0);

	switch (TF2_GetClientTeam(client))
	{
		case TFTeam_Blue:
			Cache[client].SplatIndex = view_as<int>(TEParticles.GasPasserImpactBlue);

		case TFTeam_Red:
			Cache[client].SplatIndex = view_as<int>(TEParticles.GasPasserImpactRed);
	}

	EmitSoundToAll(SOUND_TOXIC, client, _, _, _, 0.5, 250);

	Cache[client].Repeat(perk.GetPrefFloat("interval", 0.2), Toxic_ApplyDamage);
	Cache[client].Repeat(0.1, Toxic_SpawnParticles);
}

void Toxic_RemovePerk(const int client)
{
	StopSound(client, SNDCHAN_AUTO, SOUND_TOXIC);
}

public Action Toxic_ApplyDamage(const int client)
{
	float fPos[3];
	GetClientAbsOrigin(client, fPos);
	fPos[2] += 60.0; // roughly player center

	DamageRadius(fPos, client, client, Cache[client].Radius, Cache[client].Damage, DMG_BLAST);
	return Plugin_Continue;
}

public Action Toxic_SpawnParticles(const int client)
{
	float fClientPos[3];
	GetClientAbsOrigin(client, fClientPos);
	fClientPos[2] += 60.0; // roughly player center

	float fPos[3], fDir[2];
	TEParticleId eParticleId = view_as<TEParticleId>(Cache[client].SplatIndex);

	for (int i = 0; i < Cache[client].EffectCount; ++i)
	{
		float fRadius = GetRandomFloat(Cache[client].Radius - 30.0, Cache[client].Radius);

		fDir[0] = GetRandomFloat(0.0, 2.0 * 3.1415); // radians
		fDir[1] = GetRandomFloat(0.0, 2.0 * 3.1415);
		GetPointOnSphere(fClientPos, fDir, fRadius, fPos);

		SendTEParticle(eParticleId, fPos);
	}

	// Use last spawned particle's position to create the fog
	SendTEParticle(TEParticles.LingeringFogSmall, fPos);
	return Plugin_Continue;
}

#undef Radius
#undef Damage
#undef SplatIndex
#undef EffectCount

#undef SOUND_TOXIC
