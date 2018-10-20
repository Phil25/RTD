/**
* Pumpkin Trail perk.
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

#define SOUND_ACALLBEYOND_CONJURE "misc/flame_engulf.wav"
#define ACALLBEYOND_SIZE 70.0

// float cache
#define RATE 0
#define DAMAGE 1
#define LAST_ATTACK 2

// int cache
#define PROJECTILE_AMOUNT 0

char g_sSoundAirStrikeFire[][] = {
	"weapons/airstrike_fire_01.wav",
	"weapons/airstrike_fire_02.wav",
	"weapons/airstrike_fire_03.wav"
};

int g_iACallBeyondId = 71;

void ACallBeyond_Start(){
	PrecacheSound(SOUND_ACALLBEYOND_CONJURE);
	PrecacheSound(g_sSoundAirStrikeFire[0]);
	PrecacheSound(g_sSoundAirStrikeFire[1]);
	PrecacheSound(g_sSoundAirStrikeFire[2]);
}

public void ACallBeyond_Call(int client, Perk perk, bool apply){
	if(apply) ACallBeyond_ApplyPerk(client, perk);
	else UnsetClientPerkCache(client, g_iACallBeyondId);
}

public void ACallBeyond_ApplyPerk(int client, Perk perk){
	g_iACallBeyondId = perk.Id;
	SetClientPerkCache(client, g_iACallBeyondId);

	SetFloatCache(client, perk.GetPrefFloat("rate"), RATE);
	SetFloatCache(client, perk.GetPrefFloat("damage"), DAMAGE);
	SetFloatCache(client, 0.0, LAST_ATTACK);
	SetIntCache(client, perk.GetPrefCell("amount"), PROJECTILE_AMOUNT);

	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Attack", LANG_SERVER, 0x03, 0x01);
}

void ACallBeyond_Voice(int client){
	if(!CheckClientPerkCache(client, g_iACallBeyondId))
		return;

	float fTime = GetEngineTime();
	if(fTime < GetFloatCache(client, LAST_ATTACK) +GetFloatCache(client, RATE))
		return;

	SetFloatCache(client, fTime, LAST_ATTACK);
	ACallBeyond_SpawnMultiple(client);
}

void ACallBeyond_SpawnMultiple(int client){
	float fPos[3];
	GetClientEyePosition(client, fPos);
	fPos[2] += 80.0;

	CreateEffect(fPos, "eyeboss_tp_vortex", 2.0);
	EmitSoundToAll(SOUND_ACALLBEYOND_CONJURE, client, _, _, _, _, 50);

	int iTeam = GetClientTeam(client);
	float fDamage = GetFloatCache(client, DAMAGE);

	int iAmount = GetIntCache(client, PROJECTILE_AMOUNT);
	for(int i = 0; i < iAmount; ++i)
		ACallBeyond_Spawn(fPos, client, iTeam, fDamage);
}

void ACallBeyond_Spawn(float fOrigPos[3], int client, int iTeam, float fDamage){
	int iSpell = CreateEntityByName("tf_projectile_energy_ball");
	if(iSpell <= MaxClients)
		return;

	SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(iSpell, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iSpell, Prop_Send, "m_nSkin", iTeam -2);
	SetEntPropVector(iSpell, Prop_Send, "m_vInitialVelocity", view_as<float>({600.0, 600.0, 600.0}));
	SetEntDataFloat(iSpell, g_iEnergyBallDamageOffset, fDamage, true);

	DispatchSpawn(iSpell);

	float fPos[3], fAng[3];
	fAng[0] = 270.0;
	for(int i = 0; i < 3; ++i){
		fPos[i] = fOrigPos[i] +GetRandomFloat(-ACALLBEYOND_SIZE, ACALLBEYOND_SIZE);
		fAng[i] += GetRandomFloat(-60.0, 60.0);
	}

	TeleportEntity(iSpell, fPos, fAng, NULL_VECTOR);
	CreateTimer(2.0, Timer_ACallBeyond_PushToHoming, EntIndexToEntRef(iSpell));
	KILL_ENT_IN(iSpell,10.0)
}

public Action Timer_ACallBeyond_PushToHoming(Handle hTimer, int iRef){
	int iSpell = EntRefToEntIndex(iRef);
	if(iSpell <= MaxClients)
		return Plugin_Stop;

	EmitSoundToAll(g_sSoundAirStrikeFire[GetRandomInt(0, 2)], iSpell, _, _, _, _, 250);
	TeleportEntity(iSpell, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, 100.0}));
	Homing_Push(iSpell, HOMING_ENEMIES|HOMING_SMOOTH);
	return Plugin_Stop;
}

#undef RATE
#undef DAMAGE
#undef LAST_ATTACK
#undef PROJECTILE_AMOUNT
