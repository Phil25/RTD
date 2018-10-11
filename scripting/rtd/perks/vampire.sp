/**
* Vampire perk.
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


#define HEARTBEAT_NEXT_TICK 0.5 // TODO: adjust this to heartbeat
#define SOUND_HEARTBEAT "ambient/voices/cough1.wav" // TODO: change this

#define MIN_DAMAGE 0
#define MAX_DAMAGE 1
#define RESISTANCE 2
#define NEXT_HURT 3

int g_iVampireId = 68;

void Vampire_Start(){
	PrecacheSound(SOUND_HEARTBEAT);
}

public void Vampire_Call(int client, Perk perk, bool apply){
	if(apply) Vampire_ApplyPerk(client, perk);
	else UnsetClientPerkCache(client, g_iVampireId);
}

void Vampire_ApplyPerk(client, Perk perk){
	g_iVampireId = perk.Id;
	SetClientPerkCache(client, g_iVampireId);

	SetFloatCache(client, perk.GetPrefFloat("mindamage"), MIN_DAMAGE);
	SetFloatCache(client, perk.GetPrefFloat("maxdamage"), MAX_DAMAGE);

	float fResistance = perk.GetPrefFloat("resistance");
	SetFloatCache(client, fResistance, RESISTANCE);
	SetFloatCache(client, GetGameTime() +fResistance, NEXT_HURT);

	CreateTimer(HEARTBEAT_NEXT_TICK, Timer_Vampire_Tick, GetClientUserId(client));
}

public Action Timer_Vampire_Tick(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iVampireId))
		return Plugin_Stop;

	EmitSoundToAll(SOUND_HEARTBEAT, client);

	if(GetFloatCache(client, NEXT_HURT) < GetGameTime()){
		Vampire_Hurt(client);
		CreateTimer(0.25, Timer_Vampire_Tick2, iUserId);
	}

	CreateTimer(HEARTBEAT_NEXT_TICK, Timer_Vampire_Tick, iUserId);
	return Plugin_Stop;
}

public Action Timer_Vampire_Tick2(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(client) Vampire_Hurt(client);
	return Plugin_Handled;
}

void Vampire_Hurt(int client){
	float fDamage = GetRandomFloat(GetFloatCache(client), GetFloatCache(client, 1));
	SDKHooks_TakeDamage(client, client, client, fDamage, DMG_PREVENT_PHYSICS_FORCE);
	ViewPunchRand(client, 15.0);
}

void Vampire_PlayerHurt(Handle hEvent){
	int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(iAttacker && CheckClientPerkCache(iAttacker, g_iVampireId))
		SetFloatCache(iAttacker, GetGameTime() +GetFloatCache(iAttacker, RESISTANCE), NEXT_HURT);
}

#undef MIN_DAMAGE
#undef MAX_DAMAGE
#undef RESISTANCE
#undef NEXT_HURT
