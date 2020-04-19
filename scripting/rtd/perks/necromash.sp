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

void NecroMash_Start(){
	PrecacheModel("models/props_halloween/hammer_gears_mechanism.mdl");
	PrecacheModel("models/props_halloween/hammer_mechanism.mdl");
	PrecacheModel("models/props_halloween/bell_button.mdl");

	PrecacheSound("misc/halloween/strongman_fast_impact_01.wav");
	PrecacheSound("ambient/explosions/explode_1.wav");
	PrecacheSound("misc/halloween/strongman_fast_whoosh_01.wav");
	PrecacheSound("misc/halloween/strongman_fast_swing_01.wav");
	PrecacheSound("doors/vent_open2.wav");
}

public void NecroMash_Call(int client, Perk perk, bool apply){
	if(!apply) return;

	if(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") > -1)
		NecroMash_SmashClient(client);
	else CreateTimer(0.1, Timer_NecroMash_Retry, GetClientUserId(client), TIMER_REPEAT);
}

public Action Timer_NecroMash_Retry(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	if(GetEntProp(client, Prop_Send, "m_hGroundEntity") < 0)
		return Plugin_Continue;

	NecroMash_SmashClient(client);
	return Plugin_Stop;
}

void NecroMash_SmashClient(int client){
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
	int gears = CreateEntityByName("prop_dynamic");
	if(IsValidEntity(gears)){
		DispatchKeyValueVector(gears, "origin", flPos);
		DispatchKeyValueVector(gears, "angles", flAngles);
		DispatchKeyValue(gears, "model", "models/props_halloween/hammer_gears_mechanism.mdl");
		DispatchSpawn(gears);
	}

	int hammer = CreateEntityByName("prop_dynamic");
	if(IsValidEntity(hammer)){
		DispatchKeyValueVector(hammer, "origin", flPos);
		DispatchKeyValueVector(hammer, "angles", flAngles);
		DispatchKeyValue(hammer, "model", "models/props_halloween/hammer_mechanism.mdl");
		DispatchSpawn(hammer);
	}

	int button = CreateEntityByName("prop_dynamic");
	if(IsValidEntity(button)){
		flPos[0] += (vForward[0] * 600);
		flPos[1] += (vForward[1] * 600);
		flPos[2] += (vForward[2] * 600);

		flPos[2] -= 100.0;
		flAngles[1] += 180.0;

		DispatchKeyValueVector(button, "origin", flPos);
		DispatchKeyValueVector(button, "angles", flAngles);
		DispatchKeyValue(button, "model", "models/props_halloween/bell_button.mdl");
		DispatchSpawn(button);

		Handle pack;
		CreateDataTimer(1.3, Timer_NecroMash_Hit, pack);
		WritePackFloat(pack, flPpos[0]); //Position of effects
		WritePackFloat(pack, flPpos[1]); //Position of effects
		WritePackFloat(pack, flPpos[2]); //Position of effects

		Handle pack2;
		CreateDataTimer(1.0, Timer_NecroMash_Whoosh, pack2);
		WritePackFloat(pack2, flPpos[0]); //Position of effects
		WritePackFloat(pack2, flPpos[1]); //Position of effects
		WritePackFloat(pack2, flPpos[2]); //Position of effects

		EmitSoundToAll("misc/halloween/strongman_fast_swing_01.wav", _, _, _, _, _, _, _, flPpos);
	}

	SetVariantString("OnUser2 !self:SetAnimation:smash:0:1");
	AcceptEntityInput(gears, "AddOutput");
	AcceptEntityInput(gears, "FireUser2");

	SetVariantString("OnUser2 !self:SetAnimation:smash:0:1");
	AcceptEntityInput(hammer, "AddOutput");
	AcceptEntityInput(hammer, "FireUser2");

	SetVariantString("OnUser2 !self:SetAnimation:hit:1.3:1");
	AcceptEntityInput(button, "AddOutput");
	AcceptEntityInput(button, "FireUser2");

	KILL_ENT_IN(gears,5.0)
	KILL_ENT_IN(hammer,5.0)
	KILL_ENT_IN(button,5.0)
}

public Action Timer_NecroMash_Hit(Handle timer, any pack){
	ResetPack(pack);

	float pos[3];
	pos[0] = ReadPackFloat(pack);
	pos[1] = ReadPackFloat(pack);
	pos[2] = ReadPackFloat(pack);

	int shaker = CreateEntityByName("env_shake");
	if(shaker != -1){
		DispatchKeyValue(shaker, "amplitude", "10");
		DispatchKeyValue(shaker, "radius", "1500");
		DispatchKeyValue(shaker, "duration", "1");
		DispatchKeyValue(shaker, "frequency", "2.5");
		DispatchKeyValue(shaker, "spawnflags", "4");
		DispatchKeyValueVector(shaker, "origin", pos);

		DispatchSpawn(shaker);
		AcceptEntityInput(shaker, "StartShake");

		KILL_ENT_IN(shaker,1.0)
	}

	EmitSoundToAll("ambient/explosions/explode_1.wav", _, _, _, _, _, _, _, pos);
	EmitSoundToAll("misc/halloween/strongman_fast_impact_01.wav", _, _, _, _, _, _, _, pos);

	float pos2[3], Vec[3], AngBuff[3];
	for(int i = 1; i <= MaxClients; i++){
		if(IsClientInGame(i) && IsPlayerAlive(i)){
			GetClientAbsOrigin(i, pos2);
			if(GetVectorDistance(pos, pos2) <= 500.0){
				MakeVectorFromPoints(pos, pos2, Vec);
				GetVectorAngles(Vec, AngBuff);
				AngBuff[0] -= 30.0;
				GetAngleVectors(AngBuff, Vec, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(Vec, Vec);
				ScaleVector(Vec, 500.0);
				Vec[2] += 250.0;
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, Vec);
			}

			if(GetVectorDistance(pos, pos2) <= 60.0)
				SDKHooks_TakeDamage(i, i, i, 999999.0, DMG_CLUB|DMG_ALWAYSGIB|DMG_BLAST);
		}
	}

	pos[2] += 10.0;
	NecroMash_CreateParticle("hammer_impact_button", pos);
	NecroMash_CreateParticle("hammer_bones_kickup", pos);
}

public Action Timer_NecroMash_Whoosh(Handle timer, any pack){
	ResetPack(pack);

	float pos[3];
	pos[0] = ReadPackFloat(pack);
	pos[1] = ReadPackFloat(pack);
	pos[2] = ReadPackFloat(pack);

	EmitSoundToAll("misc/halloween/strongman_fast_whoosh_01.wav", _, _, _, _, _, _, _, pos);
}

stock void NecroMash_CreateParticle(char[] particle, float pos[3]){
	int tblidx = FindStringTable("ParticleEffectNames");
	char tmp[256];
	int count = GetStringTableNumStrings(tblidx);
	int stridx = INVALID_STRING_INDEX;

	for(int i = 0; i < count; i++){
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));
		if(StrEqual(tmp, particle, false)){
			stridx = i;
			break;
		}
	}

	for(int i = 1; i <= MaxClients; i++){
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		TE_Start("TFParticleEffect");
		TE_WriteFloat("m_vecOrigin[0]", pos[0]);
		TE_WriteFloat("m_vecOrigin[1]", pos[1]);
		TE_WriteFloat("m_vecOrigin[2]", pos[2]);
		TE_WriteNum("m_iParticleSystemIndex", stridx);
		TE_WriteNum("entindex", -1);
		TE_WriteNum("m_iAttachType", 2);
		TE_SendToClient(i, 0.0);
	}
}
