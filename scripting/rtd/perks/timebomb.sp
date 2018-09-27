/**
* Timebomb perk.
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


#define MODEL_BOMB			"models/props_lakeside_event/bomb_temp_hat.mdl"

#define SOUND_TIMEBOMB_TICK	"buttons/button17.wav"
#define SOUND_TIMEBOMB_GOFF	"weapons/cguard/charging.wav"
#define SOUND_EXPLODE		"weapons/explode3.wav"

#define TICK_SLOW			0.75
#define TICK_FAST			0.35

// ent cache
#define HEAD 0
#define FLAME 1

// int cache
#define MAX_TICKS 0
#define CLIENT_TICKS 1
#define STATE 3

// float cache
#define RADIUS 0
#define DAMAGE 1
#define CLIENT_BEEPS 2


int g_iTimebombId = 18;

void Timebomb_Start(){
	PrecacheModel(MODEL_BOMB);
	PrecacheSound(SOUND_EXPLODE);
	PrecacheSound(SOUND_TIMEBOMB_TICK);
	PrecacheSound(SOUND_TIMEBOMB_GOFF);
}

public void Timebomb_Call(int client, Perk perk, bool apply){
	if(!apply) return;

	g_iTimebombId = perk.Id;
	SetClientPerkCache(client, g_iTimebombId);

	SetIntCache(client, perk.GetPrefCell("ticks"), MAX_TICKS);
	SetFloatCache(client, perk.GetPrefFloat("radius"), RADIUS);
	SetFloatCache(client, perk.GetPrefFloat("damage"), DAMAGE);

	SetEntCache(client, Timebomb_SpawnBombHead(client), HEAD);

	SetIntCache(client, 0, CLIENT_TICKS);
	SetFloatCache(client, TICK_SLOW, CLIENT_BEEPS);
	SetIntCache(client, 0, STATE);

	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");
	CreateTimer(1.0, Timer_Timebomb_Tick, GetClientUserId(client), TIMER_REPEAT);
}

public Action Timer_Timebomb_Tick(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iTimebombId))
		return Plugin_Stop;

	int iClientTicks = GetIntCache(client, CLIENT_TICKS) +1;
	int iMaxTicks = GetIntCache(client, MAX_TICKS);

	SetIntCache(client, iClientTicks, CLIENT_TICKS);
	if(GetEntCache(client, HEAD) > MaxClients)
		if(iClientTicks >= RoundToFloor(iMaxTicks*0.3))
			if(iClientTicks < RoundToFloor(iMaxTicks*0.7))
				Timebomb_BombState(client, 1);
			else Timebomb_BombState(client, 2);

	if(iClientTicks == iMaxTicks-1)
		EmitSoundToAll(SOUND_TIMEBOMB_GOFF, client);

	else if(iClientTicks >= iMaxTicks){
		Timebomb_Explode(client);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public Action Timer_Timebomb_Beep(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(client == 0) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iTimebombId))
		return Plugin_Stop;

	EmitSoundToAll(SOUND_TIMEBOMB_TICK, client);
	CreateTimer(GetFloatCache(client, CLIENT_BEEPS), Timer_Timebomb_Beep, GetClientUserId(client));
	return Plugin_Stop;
}

void Timebomb_BombState(int client, int iState){
	int iCurState = GetIntCache(client, STATE);
	if(iState == iCurState)
		return;

	switch(iState){
		case 1:{
			EmitSoundToAll(SOUND_TIMEBOMB_TICK, client);
			SetFloatCache(client, TICK_SLOW, CLIENT_BEEPS);
			CreateTimer(TICK_SLOW, Timer_Timebomb_Beep, GetClientUserId(client));
		}
		case 2:{
			SetFloatCache(client, TICK_FAST, CLIENT_BEEPS);
		}
	}

	int iHead = GetEntCache(client, HEAD);
	char sClass[18];
	GetEntityClassname(iHead, sClass, 18);
	if(strcmp(sClass, "prop_dynamic") == 0)
		SetEntProp(iHead, Prop_Send, "m_nSkin", iCurState+1);
	SetIntCache(client, iState, STATE);
}

void Timebomb_OnRemovePerk(int client){
	if(CheckClientPerkCache(client, g_iTimebombId))
		Timebomb_Explode(client, true);
}

void Timebomb_Explode(int client, bool bSilent=false){
	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");

	UnsetClientPerkCache(client, g_iTimebombId);
	KillEntCache(client, HEAD);
	KillEntCache(client, FLAME);

	if(bSilent) return;

	float fDamage = GetFloatCache(client, DAMAGE);
	float fPos[3];
	GetClientAbsOrigin(client, fPos);
	float fRadius = GetFloatCache(client, RADIUS);
	fRadius *= fRadius;

	int iPlayerDamage;
	for(int i = 1; i <= MaxClients; i++){
		if(i == client || !IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		if(!CanPlayerBeHurt(i, client))
			continue;

		if(!CanEntitySeeTarget(client, i))
			continue;

		float fPosTarget[3];
		GetClientAbsOrigin(i, fPosTarget);

		if(GetVectorDistance(fPos, fPosTarget, true) <= fRadius){
			iPlayerDamage += RoundToFloor(fDamage);
			SDKHooks_TakeDamage(i, 0, client, fDamage, DMG_PREVENT_PHYSICS_FORCE|DMG_CRUSH|DMG_ALWAYSGIB|DMG_BLAST);
		}
	}

	int iShockwave = CreateParticle(client, "rd_robot_explosion_shockwave");
	KILL_ENT_IN(iShockwave,1.0)

	int iExplosion = CreateParticle(client, "rd_robot_explosion");
	KILL_ENT_IN(iExplosion,1.0)

	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Timebomb_Damage", LANG_SERVER, 0x03, iPlayerDamage, 0x01);
	EmitSoundToAll(SOUND_EXPLODE, client);
	FakeClientCommandEx(client, "explode");
}

int Timebomb_SpawnBombHead(int client){
	int iBomb = CreateEntityByName("prop_dynamic");
	if(!iBomb) return 0;

	DispatchKeyValue(iBomb, "model", MODEL_BOMB);
	DispatchSpawn(iBomb);

	SetVariantString("!activator");
	AcceptEntityInput(iBomb, "SetParent", client, -1, 0);

	TFClassType clsPlayer = TF2_GetPlayerClass(client);
	if(clsPlayer == TFClass_Pyro || clsPlayer == TFClass_Engineer)
		SetVariantString("OnUser1 !self,SetParentAttachment,head,0.0,-1");
	else SetVariantString("OnUser1 !self,SetParentAttachment,eyes,0.0,-1");

	AcceptEntityInput(iBomb, "AddOutput");
	AcceptEntityInput(iBomb, "FireUser1");

	float fOffs[3];
	fOffs[2] = 64.0;
	SetEntCache(client, CreateParticle(client, "burningplayer_corpse", true, "", fOffs), FLAME);
	return iBomb;
}

#undef HEAD
#undef FLAME
#undef MAX_TICKS
#undef CLIENT_TICKS
#undef STATE
#undef RADIUS
#undef DAMAGE
#undef CLIENT_BEEPS
