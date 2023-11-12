/**
* Hell's Reach perk
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

#define HELL_HURT "ghost_appearation"
#define HELL_GHOSTS "utaunt_hellpit_parent"

#define SOUND_SLOWDOWN "ambient/halloween/windgust_12.wav"
#define SOUND_HELL_DAMAGE "player/fall_damage_dealt.wav"

#define BaseSpeed Float[0]
#define CurrentSpeed Float[1]
#define MinDamage Float[2]
#define MaxDamage Float[3]
#define Ghosts EntSlot_1

DEFINE_CALL_APPLY_REMOVE(HellsReach)

public void HellsReach_Init(const Perk perk)
{
	PrecacheSound(SOUND_SLOWDOWN);
	PrecacheSound(SOUND_HELL_DAMAGE);
}

void HellsReach_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].BaseSpeed = GetBaseSpeed(client);
	Cache[client].CurrentSpeed = 2.0;
	Cache[client].MinDamage = perk.GetPrefFloat("mindamage", 5.0);
	Cache[client].MaxDamage = perk.GetPrefFloat("maxdamage", 10.0);

	float fAttachPos[3];
	Cache[client].SetEnt(Ghosts, CreateParticle(client, HELL_GHOSTS, _, _, fAttachPos));

	EmitSoundToAll(SOUND_SLOWDOWN, client, _, _, _, _, 50);
	Cache[client].Repeat(1.0, HellsReach_Slowdown);
}

void HellsReach_RemovePerk(int client)
{
	SetSpeed(client, Cache[client].BaseSpeed);
}

Action HellsReach_Slowdown(const int client)
{
	Cache[client].CurrentSpeed *= 0.8;

	if (Cache[client].CurrentSpeed > 1.0)
		return Plugin_Continue;

	SetSpeed(client, Cache[client].BaseSpeed, Cache[client].CurrentSpeed);

	if (Cache[client].CurrentSpeed > 0.6)
		return Plugin_Continue;

	HellsReach_Hurt(client);

	Cache[client].CurrentSpeed = 2.0;
	SetSpeed(client, Cache[client].BaseSpeed);

	return Plugin_Continue;
}

void HellsReach_Hurt(const int client)
{
	int iEnt = CreateParticle(client, HELL_HURT);
	KILL_ENT_IN(iEnt,1.0);

	float fDamage = GetRandomFloat(Cache[client].MinDamage, Cache[client].MaxDamage);
	SDKHooks_TakeDamage(client, client, client, fDamage, DMG_PREVENT_PHYSICS_FORCE);

	ViewPunchRand(client, 70.0);
	EmitSoundToAll(SOUND_HELL_DAMAGE, client);
}

#undef HELL_HURT
#undef HELL_GHOSTS

#undef SOUND_SLOWDOWN
#undef SOUND_HELL_DAMAGE

#undef BaseSpeed
#undef CurrentSpeed
#undef MinDamage
#undef MaxDamage
#undef Ghosts