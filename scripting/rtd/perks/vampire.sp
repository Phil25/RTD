/**
* Vampire perk.
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

#define HEARTBEAT_TICK 0.5
#define HEARTBEAT_FOLLOWUP 0.12

#define SOUND_HEARTBEAT_1 "player/taunt_yeti_chest_hit1.wav"
#define SOUND_HEARTBEAT_2 "player/taunt_yeti_chest_hit7.wav"

#define MinDamage Float[0]
#define MaxDamage Float[1]
#define Resistance Float[2]
#define NextHurt Float[3]

DEFINE_CALL_APPLY(Vampire)

public void Vampire_Init(const Perk perk)
{
	PrecacheSound(SOUND_HEARTBEAT_1);
	PrecacheSound(SOUND_HEARTBEAT_2);

	Events.OnPlayerAttacked(perk, Vampire_OnPlayerAttacked);
}

void Vampire_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].MinDamage = perk.GetPrefFloat("mindamage", 1.0);
	Cache[client].MaxDamage = perk.GetPrefFloat("maxdamage", 3.0);
	Cache[client].Resistance = perk.GetPrefFloat("resistance", 3.0);
	Cache[client].NextHurt = GetEngineTime() + Cache[client].Resistance;

	Cache[client].Repeat(HEARTBEAT_TICK, Vampire_Tick);
}

public Action Vampire_Tick(const int client)
{
	if (Cache[client].NextHurt > GetEngineTime())
		return Plugin_Continue;

	Vampire_Hurt(client);
	EmitSoundToAll(SOUND_HEARTBEAT_1, client);

	CreateTimer(HEARTBEAT_FOLLOWUP, Vampire_Tick_Followup, GetClientUserId(client));

	return Plugin_Continue;
}

public Action Vampire_Tick_Followup(Handle hTimer, const int iUserId)
{
	int client = GetClientOfUserId(iUserId);
	if (!client || !IsPlayerAlive(client))
		return Plugin_Stop;

	Vampire_Hurt(client);
	EmitSoundToAll(SOUND_HEARTBEAT_2, client);

	return Plugin_Stop;
}

void Vampire_Hurt(const int client)
{
	float fDamage = GetRandomFloat(Cache[client].MinDamage, Cache[client].MaxDamage);
	SDKHooks_TakeDamage(client, client, client, fDamage, DMG_PREVENT_PHYSICS_FORCE);

	ViewPunchRand(client, 5.0);
}

void Vampire_OnPlayerAttacked(const int client, const int iVictim, const int iDamage, const int iRemainingHealth)
{
	if (client != iVictim)
		Cache[client].NextHurt = GetEngineTime() + Cache[client].Resistance;
}

#undef HEARTBEAT_TICK
#undef HEARTBEAT_FOLLOWUP

#undef SOUND_HEARTBEAT_1
#undef SOUND_HEARTBEAT_2

#undef MinDamage
#undef MaxDamage
#undef Resistance
#undef NextHurt
