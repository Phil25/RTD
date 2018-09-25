/**
* Sickness perk.
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


#define SICKNESS_NEXT_TICK GetURandomFloat()*2.0+2.0
#define SICKNESS_PARTICLE "spell_skeleton_goop_green"

int g_iSicknessId = 62;

char g_sSoundCough[][] = {
	"ambient/voices/cough1.wav",
	"ambient/voices/cough2.wav",
	"ambient/voices/cough3.wav",
	"ambient/voices/cough4.wav"
};

void Sickness_Start(){
	for(int i = 0; i < 4; ++i)
		PrecacheSound(g_sSoundCough[i]);
}

void Sickness_Perk(int client, Perk perk, bool apply){
	if(apply) Sickness_ApplyPerk(client, perk);
	else UnsetClientPerkCache(client, g_iSicknessId);
}

void Sickness_ApplyPerk(client, Perk perk){
	g_iSicknessId = perk.Id;
	SetClientPerkCache(client, g_iSicknessId);

	SetFloatCache(client, perk.GetPrefFloat("mindamage"), 0);
	SetFloatCache(client, perk.GetPrefFloat("maxdamage"), 1);

	CreateTimer(SICKNESS_NEXT_TICK, Timer_Sickness_Tick, GetClientUserId(client));
}

public Action Timer_Sickness_Tick(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iSicknessId))
		return Plugin_Stop;

	EmitSoundToAll(g_sSoundCough[GetRandomInt(0, 3)], client);
	Sickness_Cough(client);

	CreateTimer(0.25, Timer_Sickness_Tick2, iUserId);
	CreateTimer(SICKNESS_NEXT_TICK, Timer_Sickness_Tick, iUserId);
	return Plugin_Stop;
}

public Action Timer_Sickness_Tick2(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(client) Sickness_Cough(client);
	return Plugin_Handled;
}

void Sickness_Cough(int client){
	int iParticle = CreateParticle(client, SICKNESS_PARTICLE);
	KILL_ENT_IN(iParticle,0.1)

	float fDamage = GetRandomFloat(GetFloatCache(client), GetFloatCache(client, 1));
	SDKHooks_TakeDamage(client, client, client, fDamage, DMG_PREVENT_PHYSICS_FORCE);

	float fShake[3];
	fShake[0] = GetRandomFloat(10.0, 15.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fShake);
}
