/**
* Scary Bullets perk.
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


#define SCARYBULLETS_PARTICLE "ghost_glow"

int g_iScaryBulletsId = 11;

void ScaryBullets_Perk(int client, Perk perk, bool apply){
	if(apply) ScaryBullets_ApplyPerk(client, perk);
	else ScaryBullets_RemovePerk(client);
}

void ScaryBullets_ApplyPerk(int client, Perk perk){
	g_iScaryBulletsId = perk.Id;
	SetClientPerkCache(client, g_iScaryBulletsId);
	SetFloatCache(client, perk.GetPrefFloat("duration"));
	SetEntCache(client, CreateParticle(client, SCARYBULLETS_PARTICLE));
}

void ScaryBullets_RemovePerk(int client){
	UnsetClientPerkCache(client, g_iScaryBulletsId);
	KillEntCache(client);
}

void ScaryBullets_PlayerHurt(int client, Handle hEvent){
	int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(!iAttacker) return;

	if(!CheckClientPerkCache(iAttacker, g_iScaryBulletsId))
		return;

	if(client == iAttacker)
		return;

	int iHealth = GetEventInt(hEvent, "health");
	if(IsPlayerAlive(client) && iHealth > 0 && !TF2_IsPlayerInCondition(client, TFCond_Dazed))
		TF2_StunPlayer(client, GetFloatCache(iAttacker), _, TF_STUNFLAGS_GHOSTSCARE, iAttacker);

}
