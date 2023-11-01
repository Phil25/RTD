/**
* Necro Mash perk.
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

/*
	THESE FUNCTIONS ARE ENTIRELY MADE BY Pelipoika IN HIS PLUGIN "Necromasher":
	https://forums.alliedmods.net/showthread.php?p=2300875
	All credits go to him!
*/

DEFINE_CALL_APPLY(NecroMash)

public void NecroMash_Init(const Perk perk)
{
	PrecacheModel("models/props_halloween/hammer_gears_mechanism.mdl");
	PrecacheModel("models/props_halloween/hammer_mechanism.mdl");
	PrecacheModel("models/props_halloween/bell_button.mdl");

	PrecacheSound("misc/halloween/strongman_fast_impact_01.wav");
	PrecacheSound("ambient/explosions/explode_1.wav");
	PrecacheSound("misc/halloween/strongman_fast_whoosh_01.wav");
	PrecacheSound("misc/halloween/strongman_fast_swing_01.wav");
	PrecacheSound("doors/vent_open2.wav");
}

public void NecroMash_ApplyPerk(const int client, const Perk perk)
{
	if (GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") > -1)
	{
		NecroMash_SmashClient(client);
	}
	else
	{
		CreateTimer(0.1, Timer_NecroMash_Retry, GetClientUserId(client), TIMER_REPEAT);
	}
}

public Action Timer_NecroMash_Retry(Handle hTimer, const int iUserId)
{
	int client = GetClientOfUserId(iUserId);
	if (!client)
		return Plugin_Stop;

	if (GetEntProp(client, Prop_Send, "m_hGroundEntity") < 0)
		return Plugin_Continue;

	NecroMash_SmashClient(client);
	return Plugin_Stop;
}

void NecroMash_SmashClient(const int client)
{
	float flPos[3], flPpos[3], flAngles[3];
	GetClientAbsOrigin(client, flPos);
	GetClientAbsOrigin(client, flPpos);
	GetClientEyeAngles(client, flAngles);
	flAngles[0] = 0.0;

	float vForward[3];
	GetAngleVectors(flAngles, vForward, NULL_VECTOR, NULL_VECTOR);
	flPos[0] -= (vForward[0] * 750);
	flPos[1] -= (vForward[1] * 750);
	flPos[2] -= (vForward[2] * 750);

	flPos[2] += 350.0;
	int iGears = CreateEntityByName("prop_dynamic");
	if (IsValidEntity(iGears))
	{
		DispatchKeyValueVector(iGears, "origin", flPos);
		DispatchKeyValueVector(iGears, "angles", flAngles);
		DispatchKeyValue(iGears, "model", "models/props_halloween/hammer_gears_mechanism.mdl");
		DispatchSpawn(iGears);
	}

	int iHammer = CreateEntityByName("prop_dynamic");
	if (IsValidEntity(iHammer))
	{
		DispatchKeyValueVector(iHammer, "origin", flPos);
		DispatchKeyValueVector(iHammer, "angles", flAngles);
		DispatchKeyValue(iHammer, "model", "models/props_halloween/hammer_mechanism.mdl");
		DispatchSpawn(iHammer);
	}

	int iButton = CreateEntityByName("prop_dynamic");
	if (IsValidEntity(iButton))
	{
		flPos[0] += (vForward[0] * 600);
		flPos[1] += (vForward[1] * 600);
		flPos[2] += (vForward[2] * 600);

		flPos[2] -= 100.0;
		flAngles[1] += 180.0;

		DispatchKeyValueVector(iButton, "origin", flPos);
		DispatchKeyValueVector(iButton, "angles", flAngles);
		DispatchKeyValue(iButton, "model", "models/props_halloween/bell_button.mdl");
		DispatchSpawn(iButton);

		Handle pack;
		CreateDataTimer(1.3, Timer_NecroMash_Hit, pack);
		WritePackFloat(pack, flPpos[0]); // Position of effects
		WritePackFloat(pack, flPpos[1]); // Position of effects
		WritePackFloat(pack, flPpos[2]); // Position of effects

		Handle pack2;
		CreateDataTimer(1.0, Timer_NecroMash_Whoosh, pack2);
		WritePackFloat(pack2, flPpos[0]); // Position of effects
		WritePackFloat(pack2, flPpos[1]); // Position of effects
		WritePackFloat(pack2, flPpos[2]); // Position of effects

		EmitSoundToAll("misc/halloween/strongman_fast_swing_01.wav", _, _, _, _, _, _, _, flPpos);
	}

	SetVariantString("OnUser2 !self:SetAnimation:smash:0:1");
	AcceptEntityInput(iGears, "AddOutput");
	AcceptEntityInput(iGears, "FireUser2");

	SetVariantString("OnUser2 !self:SetAnimation:smash:0:1");
	AcceptEntityInput(iHammer, "AddOutput");
	AcceptEntityInput(iHammer, "FireUser2");

	SetVariantString("OnUser2 !self:SetAnimation:hit:1.3:1");
	AcceptEntityInput(iButton, "AddOutput");
	AcceptEntityInput(iButton, "FireUser2");

	KILL_ENT_IN(iGears,5.0);
	KILL_ENT_IN(iHammer,5.0);
	KILL_ENT_IN(iButton,5.0);
}

public Action Timer_NecroMash_Hit(Handle hTimer, any hPack)
{
	ResetPack(hPack);

	float fPos[3];
	fPos[0] = ReadPackFloat(hPack);
	fPos[1] = ReadPackFloat(hPack);
	fPos[2] = ReadPackFloat(hPack);

	int iShaker = CreateEntityByName("env_shake");
	if (iShaker != -1)
	{
		DispatchKeyValue(iShaker, "amplitude", "10");
		DispatchKeyValue(iShaker, "radius", "1500");
		DispatchKeyValue(iShaker, "duration", "1");
		DispatchKeyValue(iShaker, "frequency", "2.5");
		DispatchKeyValue(iShaker, "spawnflags", "4");
		DispatchKeyValueVector(iShaker, "origin", fPos);

		DispatchSpawn(iShaker);
		AcceptEntityInput(iShaker, "StartShake");

		KILL_ENT_IN(iShaker,1.0);
	}

	EmitSoundToAll("ambient/explosions/explode_1.wav", _, _, _, _, _, _, _, fPos);
	EmitSoundToAll("misc/halloween/strongman_fast_impact_01.wav", _, _, _, _, _, _, _, fPos);

	float fPos2[3], fVec[3], fAngBuff[3];
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, fPos2);
			if (GetVectorDistance(fPos, fPos2) <= 500.0)
			{
				MakeVectorFromPoints(fPos, fPos2, fVec);
				GetVectorAngles(fVec, fAngBuff);
				fAngBuff[0] -= 30.0;
				GetAngleVectors(fAngBuff, fVec, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(fVec, fVec);
				ScaleVector(fVec, 500.0);
				fVec[2] += 250.0;
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, fVec);
			}

			if (GetVectorDistance(fPos, fPos2) <= 60.0)
				SDKHooks_TakeDamage(i, i, i, 999999.0, DMG_CLUB | DMG_ALWAYSGIB | DMG_BLAST);
		}
	}

	fPos[2] += 10.0;
	NecroMash_CreateParticle("hammer_impact_button", fPos);
	NecroMash_CreateParticle("hammer_bones_kickup", fPos);

	return Plugin_Stop;
}

public Action Timer_NecroMash_Whoosh(Handle hTimer, any hPack)
{
	ResetPack(hPack);

	float fPos[3];
	fPos[0] = ReadPackFloat(hPack);
	fPos[1] = ReadPackFloat(hPack);
	fPos[2] = ReadPackFloat(hPack);

	EmitSoundToAll("misc/halloween/strongman_fast_whoosh_01.wav", _, _, _, _, _, _, _, fPos);

	return Plugin_Stop;
}

stock void NecroMash_CreateParticle(const char[] sParticle, float fPos[3])
{
	int iParticleId = GetEffectIndex(sParticle);

	for (int i = 1; i <= MaxClients; ++i)
	{
		if (!IsClientInGame(i))
			continue;

		TE_Start("TFParticleEffect");
		TE_WriteFloat("m_vecOrigin[0]", fPos[0]);
		TE_WriteFloat("m_vecOrigin[1]", fPos[1]);
		TE_WriteFloat("m_vecOrigin[2]", fPos[2]);
		TE_WriteNum("m_iParticleSystemIndex", iParticleId);
		TE_WriteNum("entindex", -1);
		TE_WriteNum("m_iAttachType", 2);
		TE_SendToClient(i, 0.0);
	}
}
