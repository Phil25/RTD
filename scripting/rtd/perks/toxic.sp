/**
* Toxic perk.
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


#define TOXIC_PARTICLE "eb_aura_angry01"
int g_iToxicId = 1;

void Toxic_Perk(int client, Perk perk, bool apply){
	if(apply) Toxic_ApplyPerk(client, perk);
	else UnsetClientPerkCache(client, g_iToxicId);
}

void Toxic_ApplyPerk(int client, Perk perk){
	g_iToxicId = perk.Id;
	SetFloatCache(client, perk.GetPrefFloat("radius"), 0);
	SetFloatCache(client, perk.GetPrefFloat("interval"), 1);
	SetFloatCache(client, perk.GetPrefFloat("damage"), 2);

	SetClientPerkCache(client, g_iToxicId);
	SetEntCache(client, CreateParticle(client, TOXIC_PARTICLE));

	CreateTimer(GetFloatCache(client, 1), Timer_Toxic, GetClientUserId(client), TIMER_REPEAT);
}

public Action Timer_Toxic(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(client == 0) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iToxicId)){
		KillEntCache(client);
		return Plugin_Stop;
	}

	float fPos[3];
	GetClientAbsOrigin(client, fPos);
	DamageRadius(fPos, client, client, GetFloatCache(client, 0), GetFloatCache(client, 2), DMG_BLAST);
	return Plugin_Continue;
}
