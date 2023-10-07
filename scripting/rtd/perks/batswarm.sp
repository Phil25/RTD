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

#define BAT_LIFETIME 0
#define BAT_RATE 1
#define BAT_SPEED 2

#define BAT_COUNT 0
#define BAT_FLAGS 1

#define BAT_FLAG_ACTIVATED 1
#define BAT_FLAG_ACTIVATING 2

#define BAT_START_SOUND "misc/halloween/spell_bat_cast.wav"

methodmap BatSwarmFlags{
	public BatSwarmFlags(const int client){
		return view_as<BatSwarmFlags>(client)
	}

	public void Reset(){
		SetIntCache(view_as<int>(this), 0, BAT_FLAGS);
	}

	property bool Activated{
		public get(){
			return view_as<bool>(GetIntCache(view_as<int>(this), BAT_FLAGS) & BAT_FLAG_ACTIVATED);
		}

		public set(bool bEnable){
			int iFlags = GetIntCache(view_as<int>(this), BAT_FLAGS);
			if(bEnable)
				SetIntCache(view_as<int>(this), iFlags | BAT_FLAG_ACTIVATED, BAT_FLAGS);
			else
				SetIntCache(view_as<int>(this), iFlags & ~BAT_FLAG_ACTIVATED, BAT_FLAGS);
		}
	}

	property bool Activating{
		public get(){
			return view_as<bool>(GetIntCache(view_as<int>(this), BAT_FLAGS) & BAT_FLAG_ACTIVATING);
		}

		public set(bool bEnable){
			int iFlags = GetIntCache(view_as<int>(this), BAT_FLAGS);
			if(bEnable)
				SetIntCache(view_as<int>(this), iFlags | BAT_FLAG_ACTIVATING, BAT_FLAGS);
			else
				SetIntCache(view_as<int>(this), iFlags & ~BAT_FLAG_ACTIVATING, BAT_FLAGS);
		}
	}
}

int g_iBatSwarmId = 69;

void BatSwarm_Start(){
	PrecacheSound(BAT_START_SOUND);
}

public void BatSwarm_Call(int client, Perk perk, bool apply){
	if(apply) BatSwarm_ApplyPerk(client, perk);
	else BatSwarm_RemovePerk(client);
}

void BatSwarm_ApplyPerk(int client, Perk perk){
	g_iBatSwarmId = perk.Id;
	SetClientPerkCache(client, g_iBatSwarmId);

	SetFloatCache(client, perk.GetPrefFloat("lifetime"), BAT_LIFETIME);
	SetFloatCache(client, perk.GetPrefFloat("rate"), BAT_RATE);
	SetFloatCache(client, perk.GetPrefFloat("speed"), BAT_SPEED);
	SetIntCache(client, perk.GetPrefCell("amount"), BAT_COUNT);
	BatSwarmFlags(client).Reset();

	PrintToChat(client, "%s %T", CHAT_PREFIX, "RTD2_Perk_Attack", LANG_SERVER, 0x03, 0x01);
}

void BatSwarm_RemovePerk(int client){
	UnsetClientPerkCache(client, g_iBatSwarmId);

	if(BatSwarmFlags(client).Activated)
		BatSwarm_End(client);
}

void BatSwarm_Voice(int client){
	if(!CheckClientPerkCache(client, g_iBatSwarmId))
		return

	if(BatSwarmFlags(client).Activated){
		BatSwarm_End(client);
		return;
	}

	if(BatSwarmFlags(client).Activating)
		return;

	int iTimeLeft = g_hRollers.GetEndRollTime(client) - GetTime();
	float fPerkPercentage = Min(1.0, iTimeLeft / 20.0); // upper limit of 20 seconds
	float fActivationTime = Max(0.5, fPerkPercentage * 2.5); // between 0.5-2.5 activation time

	BatSwarmFlags(client).Activating = true;
	SetEntityMoveType(client, MOVETYPE_NONE);
	CreateTimer(fActivationTime, Timer_BatSwarm_ChargeEffect, GetClientUserId(client));

	EmitSoundToAll(BAT_START_SOUND, client, _, _, _, _, 70);
	int iSpawn = CreateParticle(client, "halloween_boss_summon", true, "", {0.0, 0.0, 0.0});
	if(!iSpawn)
		return;

	KILL_ENT_IN(iSpawn,2.0)
}

public Action Timer_BatSwarm_ChargeEffect(Handle hTimer, const int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	// On the off chance that somehing happens between the activation time
	if(GetEntityMoveType(client) == MOVETYPE_NONE)
		SetEntityMoveType(client, MOVETYPE_WALK);

	if(!CheckClientPerkCache(client, g_iBatSwarmId))
		return Plugin_Stop;

	BatSwarm_Begin(client, iUserId);
	BatSwarmFlags(client).Activating = false;

	return Plugin_Stop;
}

void BatSwarm_Begin(const int client, const int iUserId){
	BatSwarmFlags(client).Activated = true;

	SetSpeedEx(client, GetFloatCache(client, BAT_SPEED));
	TF2_AddCondition(client, TFCond_UberchargedCanteen);
	TF2_AddCondition(client, TFCond_MegaHeal);

	CreateTimer(GetFloatCache(client, BAT_RATE), Timer_BatSwarm_SpawnBats, iUserId, TIMER_REPEAT);
}

void BatSwarm_End(const int client){
	BatSwarmFlags(client).Activated = false;

	SetSpeedEx(client);
	TF2_RemoveCondition(client, TFCond_UberchargedCanteen);
	TF2_RemoveCondition(client, TFCond_MegaHeal);

	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 3.0);
}

public Action Timer_BatSwarm_SpawnBats(Handle hTimer, const int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iBatSwarmId) || !BatSwarmFlags(client).Activated)
		return Plugin_Stop;

	int iAmount = GetIntCache(client, BAT_COUNT);
	float fLifetime = GetFloatCache(client, BAT_LIFETIME);
	float fPos[3], fAng[3], fVel[3];
	GetClientEyePosition(client, fPos);

	while(--iAmount >= 0)
		BatSwarm_SpawnBats(client, fLifetime, fPos, fAng, fVel);

	return Plugin_Continue;
}

void BatSwarm_SpawnBats(const int client, float fLifetime, float fPos[3], float fAng[3], float fVel[3]){
	int iBats = CreateEntityByName("tf_projectile_spellbats");
	if(iBats <= MaxClients) return;

	SetEntPropEnt(iBats, Prop_Send, "m_hOwnerEntity", client);

	int iTeam = GetClientTeam(client);
	SetEntProp(iBats, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iBats, Prop_Send, "m_nSkin", iTeam -2);

	DispatchSpawn(iBats);

	fAng[0] = GetURandomFloat() *360.0;
	fAng[1] = GetURandomFloat() *360.0;

	GetAngleVectors(fAng, fVel, NULL_VECTOR, NULL_VECTOR);
	fVel[0] *= 500.0;
	fVel[1] *= 500.0;
	fVel[2] *= 500.0;

	TeleportEntity(iBats, fPos, fAng, fVel);
	KillEntIn(iBats, fLifetime);
}

#undef BAT_LIFETIME
#undef BAT_RATE

#undef BAT_COUNT
#undef BAT_FLAGS

#undef BAT_FLAG_ACTIVATED
#undef BAT_FLAG_ACTIVATING

#undef BAT_START_SOUND
