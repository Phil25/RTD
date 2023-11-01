/**
* Fire Breath perk.
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

#define BAT_START_SOUND "misc/halloween/spell_bat_cast.wav"

#define BAT_FLAG_ACTIVATED 1
#define BAT_FLAG_ACTIVATING 2

#define Count Int[0]
#define Flags Int[1]
#define ActivationTimer Int[2]
#define Lifetime Float[0]
#define Speed Float[1]

methodmap BatSwarmFlags
{
	public BatSwarmFlags(const int client)
	{
		return view_as<BatSwarmFlags>(client)
	}

	public void Reset()
	{
		Cache[view_as<int>(this)].Flags = 0;
	}

	property bool Activated
	{
		public get()
		{
			return view_as<bool>(Cache[view_as<int>(this)].Flags & BAT_FLAG_ACTIVATED);
		}

		public set(bool bEnable)
		{
			int iFlags = Cache[view_as<int>(this)].Flags;

			if (bEnable)
			{
				Cache[view_as<int>(this)].Flags = iFlags | BAT_FLAG_ACTIVATED;
			}
			else
			{
				Cache[view_as<int>(this)].Flags = iFlags & ~BAT_FLAG_ACTIVATED;
			}
		}
	}

	property bool Activating
	{
		public get()
		{
			return view_as<bool>(Cache[view_as<int>(this)].Flags & BAT_FLAG_ACTIVATING);
		}

		public set(bool bEnable)
		{
			int iFlags = Cache[view_as<int>(this)].Flags;

			if (bEnable)
			{
				Cache[view_as<int>(this)].Flags = iFlags | BAT_FLAG_ACTIVATING;
			}
			else
			{
				Cache[view_as<int>(this)].Flags = iFlags & ~BAT_FLAG_ACTIVATING;
			}
		}
	}
}

DEFINE_CALL_APPLY_REMOVE(BatSwarm)

public void BatSwarm_Init(const Perk perk)
{
	PrecacheSound(BAT_START_SOUND);

	Events.OnVoice(perk, BatSwarm_OnVoice);
}

void BatSwarm_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Count = perk.GetPrefCell("amount", 2);
	BatSwarmFlags(client).Reset();
	Cache[client].ActivationTimer = view_as<int>(INVALID_HANDLE);
	Cache[client].Lifetime = perk.GetPrefFloat("lifetime", 1.0);
	Cache[client].Speed = perk.GetPrefFloat("speed", 0.25);

	PrintToChat(client, "%s %T", CHAT_PREFIX, "RTD2_Perk_Attack", LANG_SERVER, 0x03, 0x01);

	Cache[client].Repeat(perk.GetPrefFloat("rate", 0.35), BatSwarm_Tick);
}

void BatSwarm_RemovePerk(const int client)
{
	if (Cache[client].ActivationTimer != view_as<int>(INVALID_HANDLE))
	{
		CloseHandle(view_as<Handle>(Cache[client].ActivationTimer));
		Cache[client].ActivationTimer = view_as<int>(INVALID_HANDLE);

		if (GetEntityMoveType(client) == MOVETYPE_NONE)
			SetEntityMoveType(client, MOVETYPE_WALK);
	}

	if (BatSwarmFlags(client).Activated)
		BatSwarm_End(client);
}

void BatSwarm_OnVoice(const int client)
{
	if (BatSwarmFlags(client).Activated)
	{
		BatSwarm_End(client);
		return;
	}

	if (BatSwarmFlags(client).Activating)
		return;

	int iTimeLeft = g_hRollers.GetEndRollTime(client) - GetTime();
	float fPerkPercentage = Min(1.0, iTimeLeft / 20.0); // upper limit of 20 seconds
	float fActivationTime = Max(0.5, fPerkPercentage * 2.5); // between 0.5-2.5 activation time

	BatSwarmFlags(client).Activating = true;
	SetEntityMoveType(client, MOVETYPE_NONE);

	Handle hActivationTimer = CreateTimer(fActivationTime, Timer_BatSwarm_ChargeEffect, GetClientUserId(client));
	Cache[client].ActivationTimer = view_as<int>(hActivationTimer);

	EmitSoundToAll(BAT_START_SOUND, client, _, _, _, _, 70);

	int iSpawn = CreateParticle(client, "halloween_boss_summon", true, "", {0.0, 0.0, 0.0});
	if (!iSpawn)
		return;

	KILL_ENT_IN(iSpawn,2.0);
}

public Action Timer_BatSwarm_ChargeEffect(Handle hTimer, const int iUserId)
{
	int client = GetClientOfUserId(iUserId);
	if (!client)
		return Plugin_Stop;

	// On the off chance that somehing happens between the activation time
	if (GetEntityMoveType(client) == MOVETYPE_NONE)
		SetEntityMoveType(client, MOVETYPE_WALK);

	BatSwarm_Begin(client);
	BatSwarmFlags(client).Activating = false;

	Cache[client].ActivationTimer = view_as<int>(INVALID_HANDLE);
	return Plugin_Stop;
}

void BatSwarm_Begin(const int client)
{
	SetSpeedEx(client, Cache[client].Speed);
	TF2_AddCondition(client, TFCond_UberchargedCanteen);
	TF2_AddCondition(client, TFCond_MegaHeal);

	BatSwarmFlags(client).Activated = true;
}

void BatSwarm_End(const int client)
{
	BatSwarmFlags(client).Activated = false;

	SetSpeedEx(client);
	TF2_RemoveCondition(client, TFCond_UberchargedCanteen);
	TF2_RemoveCondition(client, TFCond_MegaHeal);

	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 3.0);
}

public Action BatSwarm_Tick(const int client)
{
	if (!BatSwarmFlags(client).Activated)
		return Plugin_Continue;

	int iAmount = Cache[client].Count;
	float fLifetime = Cache[client].Lifetime;

	float fPos[3], fAng[3], fVel[3];
	GetClientEyePosition(client, fPos);

	while (--iAmount >= 0)
		BatSwarm_SpawnBats(client, fLifetime, fPos, fAng, fVel);

	return Plugin_Continue;
}

void BatSwarm_SpawnBats(const int client, float fLifetime, float fPos[3], float fAng[3], float fVel[3])
{
	int iBats = CreateEntityByName("tf_projectile_spellbats");
	if (iBats <= MaxClients)
		return;

	SetEntPropEnt(iBats, Prop_Send, "m_hOwnerEntity", client);

	int iTeam = GetClientTeam(client);
	SetEntProp(iBats, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iBats, Prop_Send, "m_nSkin", iTeam - 2);

	DispatchSpawn(iBats);

	fAng[0] = GetURandomFloat() * 360.0;
	fAng[1] = GetURandomFloat() * 360.0;

	GetAngleVectors(fAng, fVel, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fVel, 500.0);

	TeleportEntity(iBats, fPos, fAng, fVel);
	KillEntIn(iBats, fLifetime);
}

#undef BAT_START_SOUND

#undef BAT_FLAG_ACTIVATED
#undef BAT_FLAG_ACTIVATING

#undef Count
#undef Flags
#undef ActivationTimer
#undef Lifetime
#undef Speed
