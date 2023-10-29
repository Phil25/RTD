/**
* Firework perk;
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

#define FIREWORK_EXPLOSION "weapons/flare_detonator_explode.wav"
#define FIREWORK_PARTICLE "burningplayer_rainbow_flame"

#define Particle EntSlot_1

DEFINE_CALL_APPLY(Firework)

public void Firework_Init(const Perk perk)
{
	PrecacheSound(FIREWORK_EXPLOSION);
}

void Firework_ApplyPerk(const int client, const Perk perk)
{
	float fPush[3];
	fPush[2] = perk.GetPrefFloat("force", 4096.0);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fPush);

	int iParticle = CreateParticle(client, FIREWORK_PARTICLE);
	Cache[client].SetEnt(Particle, iParticle);
	KILL_ENT_IN(iParticle,0.5);

	CreateTimer(0.5, Timer_Firework_Explode, GetClientUserId(client));
}

public Action Timer_Firework_Explode(Handle hTimer, const int iUserId)
{
	int client = GetClientOfUserId(iUserId);
	if (!client)
		return Plugin_Stop;

	float fPos[3];
	GetClientAbsOrigin(client, fPos);

	EmitSoundToAll(FIREWORK_EXPLOSION, _, _, _, _, _, _, _, fPos);
	SendTEParticle(TEParticles.ExplosionWooden, fPos);
	SendTEParticle(TEParticles.ShockwaveFlat, fPos);
	TF2_IgnitePlayer(client, client);

	DataPack hFollowup = new DataPack();
	hFollowup.WriteCell(3);
	hFollowup.WriteFloat(fPos[0]);
	hFollowup.WriteFloat(fPos[1]);
	hFollowup.WriteFloat(fPos[2]);
	CreateTimer(0.7, Timer_Firework_Followup_Trigger, hFollowup);

	return Plugin_Stop;
}

public Action Timer_Firework_Followup_Trigger(Handle hTimer, DataPack hFollowup)
{
	CreateTimer(0.1, Timer_Firework_Followup, hFollowup, TIMER_REPEAT | TIMER_DATA_HNDL_CLOSE);
	return Plugin_Stop;
}

public Action Timer_Firework_Followup(Handle hTimer, DataPack hFollowup){
	hFollowup.Reset();

	float fPos[3];
	int iTimes = hFollowup.ReadCell();
	fPos[0] = hFollowup.ReadFloat();
	fPos[1] = hFollowup.ReadFloat();
	fPos[2] = hFollowup.ReadFloat();

	hFollowup.Reset();
	hFollowup.WriteCell(--iTimes);

	int iCount = GetRandomInt(1, 4);
	for (int i = 0; i < iCount; ++i)
	{
		float fFireworkPos[3];
		fFireworkPos[0] = fPos[0] + GetRandomFloat(100.0, 250.0) * GetRandomSign();
		fFireworkPos[1] = fPos[1] + GetRandomFloat(100.0, 250.0) * GetRandomSign();
		fFireworkPos[2] = fPos[2] + GetRandomFloat(100.0, 250.0) * GetRandomSign();
		SendTEParticle(TEParticles.ExplosionEmbersOnly, fFireworkPos);
	}

	EmitSoundToAll(FIREWORK_EXPLOSION, _, _, _, _, _, 150, _, fPos);
	return iTimes > 0 ? Plugin_Continue : Plugin_Stop;
}

#undef FIREWORK_EXPLOSION
#undef FIREWORK_PARTICLE

#undef Particle