/**
* Hell's Reach perk
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

#define HELL_HURT "ghost_appearation"
#define HELL_GHOSTS "utaunt_hellpit_parent"
#define SOUND_SLOWDOWN "ambient/halloween/windgust_12.wav"
#define SOUND_LAUNCH "vo/halloween_boss/knight_attack01.mp3"

#define BASE_SPEED 0
#define CUR_SPEED 1
#define MIN_DAMAGE 2
#define MAX_DAMAGE 3

int g_iHellsReachId = 66;

void HellsReach_Start(){
	PrecacheSound(SOUND_SLOWDOWN);
	PrecacheSound(SOUND_LAUNCH);
}

public void HellsReach_Call(int client, Perk perk, bool apply){
	if(apply) HellsReach_ApplyPerk(client, perk);
	else HellsReach_RemovePerk(client);
}

void HellsReach_ApplyPerk(int client, Perk perk){
	g_iHellsReachId = perk.Id;
	SetClientPerkCache(client, g_iHellsReachId);

	SetFloatCache(client, GetBaseSpeed(client), BASE_SPEED);
	SetFloatCache(client, 1.0, CUR_SPEED);
	SetFloatCache(client, perk.GetPrefFloat("mindamage"), MIN_DAMAGE);
	SetFloatCache(client, perk.GetPrefFloat("maxdamage"), MAX_DAMAGE);

	float fAttachPos[3];
	fAttachPos[2] -= 0.0;
	SetEntCache(client, CreateParticle(client, HELL_GHOSTS, _, _, fAttachPos));
	CreateTimer(1.0, Timer_HellsReach_SlowDown, GetClientUserId(client), TIMER_REPEAT);

	EmitSoundToAll(SOUND_SLOWDOWN, client, _, _, _, _, 50);
}

void HellsReach_RemovePerk(int client){
	HellsReach_Launch(client);

	KillEntCache(client);
	SetSpeed(client, GetFloatCache(client, BASE_SPEED), 1.0);
	UnsetClientPerkCache(client, g_iHellsReachId);
}

public Action Timer_HellsReach_SlowDown(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iHellsReachId))
		return Plugin_Stop;

	float fCurSpeed = GetFloatCache(client, CUR_SPEED) *0.8;
	SetFloatCache(client, fCurSpeed, CUR_SPEED);
	SetSpeed(client, GetFloatCache(client, BASE_SPEED), fCurSpeed);
	if(fCurSpeed > 0.1) return Plugin_Continue;

	CreateTimer(1.0, Timer_HellsReach_Hurt, iUserId, TIMER_REPEAT);
	return Plugin_Stop;
}

public Action Timer_HellsReach_Hurt(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iHellsReachId))
		return Plugin_Stop;

	HellsReach_Hurt(client);
	return Plugin_Continue;
}

void HellsReach_Hurt(int client){
	int iEnt = CreateParticle(client, HELL_HURT);
	KILL_ENT_IN(iEnt,1.0)

	float fDamage = GetRandomFloat(GetFloatCache(client, MIN_DAMAGE), GetFloatCache(client, MAX_DAMAGE));
	SDKHooks_TakeDamage(client, client, client, fDamage, DMG_ACID|DMG_PREVENT_PHYSICS_FORCE);
	ViewPunchRand(client, 100.0);
}

void HellsReach_Launch(int client){
	float fVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVel);
	fVel[2] += 2048.0;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVel);

	EmitSoundToAll(SOUND_LAUNCH, client, _, _, _, _, 50);
	TF2_IgnitePlayer(client, client);
	HellsReach_Hurt(client);
}

#undef BASE_SPEED
#undef CUR_SPEED
#undef MIN_DAMAGE
#undef MAX_DAMAGE
