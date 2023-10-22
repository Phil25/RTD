/**
* Smite perk.
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

#define SOUND_ELECTRIC_MIST "ambient/nucleus_electricity.wav"

// not configurable, distance between electrocution ticks needs this to be small
#define TICK_INTERVAL 0.1

#define TICK_DAMAGE 0
#define BASE_SPEED 1
#define ELECTROCUTION_TIME 2
#define SLOWDOWN 3

#define ELECTROCUTION_TICKS 0
#define IS_ELECTROCUTED 1
#define TICKS_LEFT 2
#define ELECTROCUTE_EFFECT 3

char g_sSoundZap[][] = {
	"ambient/energy/zap1.wav",
	"ambient/energy/zap2.wav",
	"ambient/energy/zap3.wav",
}

int g_iSmiteId = 72;

void Smite_Start(){
	PrecacheSound(SOUND_ELECTRIC_MIST);
	PrecacheSound(g_sSoundZap[0]);
	PrecacheSound(g_sSoundZap[1]);
	PrecacheSound(g_sSoundZap[2]);
}

public void Smite_Call(int client, Perk perk, bool apply){
	if(apply) Smite_ApplyPerk(client, perk);
	else Smite_RemovePerk(client);
}

void Smite_ApplyPerk(int client, Perk perk){
	g_iSmiteId = perk.Id;
	SetClientPerkCache(client, g_iSmiteId);

	int iMaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
	int iElectrocutionTics = perk.GetPrefCell("damage_ticks", 3);
	float fInitialDamageMultiplier = perk.GetPrefFloat("initial_damage", 0.2);
	float fTickDamageMultiplier = perk.GetPrefFloat("tick_damage", 0.04);

	SetFloatCache(client, fTickDamageMultiplier * iMaxHealth, TICK_DAMAGE);
	SetFloatCache(client, GetBaseSpeed(client), BASE_SPEED);
	SetFloatCache(client, TICK_INTERVAL * iElectrocutionTics, ELECTROCUTION_TIME);
	SetFloatCache(client, perk.GetPrefFloat("slowdown"), SLOWDOWN);

	SetIntCache(client, iElectrocutionTics, ELECTROCUTION_TICKS);
	SetIntCache(client, false, IS_ELECTROCUTED);
	SetIntCache(client, Smite_GenerateTicksLeft(client), TICKS_LEFT);

	// Due to technical reasons, client cannot die on the same frame as the perk is applied, make
	// sure they are left with at least 1 health.
	float fDamage = Min(fInitialDamageMultiplier * iMaxHealth, float(GetClientHealth(client) - 1));

	SDKHook(client, SDKHook_OnTakeDamagePost, Smite_OnTakeDamage);
	SDKHooks_TakeDamage(client, client, client, fDamage, DMG_SHOCK);

	int iStrike[2];
	iStrike[0] = CreateEntityByName("info_target");
	if(iStrike[0] <= MaxClients)
		return;

	KILL_ENT_IN(iStrike[0],0.25)

	iStrike[1] = CreateEntityByName("info_target");
	if(iStrike[1] <= MaxClients)
		return;

	KILL_ENT_IN(iStrike[1],0.25)

	float fPos[3];
	GetClientAbsOrigin(client, fPos);

	int iRed, iBlue;
	switch(TF2_GetClientTeam(client)){
		case TFTeam_Red:{
			iRed = 255;
			iBlue = 100;
			SetIntCache(client, view_as<int>(TEParticle_ElectrocutedRed), ELECTROCUTE_EFFECT);
			SendTEParticleWithPriority(TEParticle_SparkVortexRed, fPos);
		}
		case TFTeam_Blue:{
			iRed = 100;
			iBlue = 255;
			SetIntCache(client, view_as<int>(TEParticle_ElectrocutedBlue), ELECTROCUTE_EFFECT);
			SendTEParticleWithPriority(TEParticle_SparkVortexBlue, fPos);
		}
	}

	SendTEParticleWithPriority(TEParticle_ShockwaveFlat, fPos);
	Smite_SendElectrocuteParticle(client);

	int iProxy = CreateProxy(client);
	if(iProxy > MaxClients){
		SetEntCache(client, iProxy);
		SendTEParticleLingeringAttached(TEParticle_ElectricMist, iProxy, fPos);
		EmitSoundToAll(SOUND_ELECTRIC_MIST, client, _, _, _, _, 150);
	}

	fPos[2] += 32.0;
	TeleportEntity(iStrike[0], fPos, NULL_VECTOR, NULL_VECTOR);
	fPos[2] += 1024.0;
	TeleportEntity(iStrike[1], fPos, NULL_VECTOR, NULL_VECTOR);

	int iBeam = ConnectWithBeam(iStrike[1], iStrike[0], iRed, 100, iBlue, 10.0, 4.0, 10.0);
	KILL_ENT_IN(iBeam,0.1)

	CreateTimer(TICK_INTERVAL, Timer_SmiteTick, GetClientUserId(client), TIMER_REPEAT);
}

void Smite_RemovePerk(int client){
	UnsetClientPerkCache(client, g_iSmiteId);

	SDKUnhook(client, SDKHook_OnTakeDamagePost, Smite_OnTakeDamage);
	KillEntCache(client);

	SetSpeed(client, GetFloatCache(client, BASE_SPEED), 1.0);
	StopSound(client, SNDCHAN_AUTO, SOUND_ELECTRIC_MIST);
}

public Action Timer_SmiteTick(Handle hTimer, const int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client || !CheckClientPerkCache(client, g_iSmiteId))
		return Plugin_Stop;

	int iTicksLeft = GetIntCache(client, TICKS_LEFT) - 1;
	if(iTicksLeft > 0){
		SetIntCache(client, iTicksLeft, TICKS_LEFT);

		if(GetIntCacheBool(client, IS_ELECTROCUTED))
			SDKHooks_TakeDamage(client, client, client, GetFloatCache(client, TICK_DAMAGE), DMG_SHOCK);

		return Plugin_Continue;
	}

	if(GetIntCacheBool(client, IS_ELECTROCUTED)){
		SetIntCache(client, false, IS_ELECTROCUTED);

		SetSpeed(client, GetFloatCache(client, BASE_SPEED), 1.0);
		SetIntCache(client, Smite_GenerateTicksLeft(client), TICKS_LEFT);
	}else{ // not being electrocuted
		SetIntCache(client, true, IS_ELECTROCUTED);
		SetIntCache(client, GetIntCache(client, ELECTROCUTION_TICKS), TICKS_LEFT);

		TF2_AddCondition(client, TFCond_CritOnFirstBlood, GetFloatCache(client, ELECTROCUTION_TIME));
		SetSpeed(client, GetFloatCache(client, BASE_SPEED), GetFloatCache(client, SLOWDOWN));

		ViewPunchRand(client, 5.0);
		EmitSoundToAll(g_sSoundZap[GetRandomInt(0, 2)], client, _, _, _, _, GetRandomInt(90, 110));
		Smite_SendElectrocuteParticle(client);
	}

	return Plugin_Continue;
}

public void Smite_OnTakeDamage(int client, int iAttacker, int iInflictor, float fDamage, int iType){
	// Speed up the electrocution after getting hit
	if(client != iAttacker && !GetIntCacheBool(client, IS_ELECTROCUTED) && fDamage > 8.0)
		SetIntCache(client, GetIntCache(client, TICKS_LEFT) - 10, TICKS_LEFT);
}

int Smite_GenerateTicksLeft(int client){
	int iElectrocutionTicks = GetIntCache(client, ELECTROCUTION_TICKS);
	return GetRandomInt(iElectrocutionTicks + 20, iElectrocutionTicks + 30);
}

void Smite_SendElectrocuteParticle(int client){
	int iParticle = GetIntCache(client, ELECTROCUTE_EFFECT);
	SendTEParticleAttached(view_as<TEParticle>(iParticle), client);
}

#undef SOUND_ELECTRIC_MIST

#undef TICK_INTERVAL

#undef TICK_DAMAGE
#undef BASE_SPEED
#undef ELECTROCUTION_TIME
#undef SLOWDOWN

#undef ELECTROCUTION_TICKS
#undef IS_ELECTROCUTED
#undef TICKS_LEFT
#undef ELECTROCUTE_EFFECT
