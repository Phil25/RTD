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

int		g_bHasScaryBullets[MAXPLAYERS+1]	= {false, ...};
int		g_bScaryParticle[MAXPLAYERS+1]		= {-1, ...};
float	g_fScaryStunDuration				= 4.0;

void ScaryBullets_Start(){

	HookEvent("player_hurt", Event_ScaryBullets_PlayerHurt);

}

void ScaryBullets_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		ScaryBullets_ApplyPerk(client, StringToFloat(sPref));
	
	else
		ScaryBullets_RemovePerk(client);

}

void ScaryBullets_ApplyPerk(int client, float fDuration){

	g_fScaryStunDuration		= fDuration;
	g_bHasScaryBullets[client]	= true;
	
	if(g_bScaryParticle[client] < 0)
		g_bScaryParticle[client] = CreateParticle(client, SCARYBULLETS_PARTICLE);

}

void ScaryBullets_RemovePerk(int client){

	if(g_bScaryParticle[client] > MaxClients && IsValidEntity(g_bScaryParticle[client])){
		AcceptEntityInput(g_bScaryParticle[client], "Kill");
		g_bScaryParticle[client] = -1;
	}

	g_bHasScaryBullets[client] = false;

}

public void Event_ScaryBullets_PlayerHurt(Handle hEvent, const char[] sEventName, bool bDontBroadcast){
	
	int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(attacker == 0) return;

	if(!g_bHasScaryBullets[attacker])		return;

	int victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(attacker == victim)					return;
	if(!IsClientInGame(victim))				return;
	if(victim < 1 || victim > MaxClients)	return;
	
	if(IsPlayerAlive(victim) && GetEventInt(hEvent, "health") > 0 && !TF2_IsPlayerInCondition(victim, TFCond_Dazed))
		TF2_StunPlayer(victim, g_fScaryStunDuration, _, TF_STUNFLAGS_GHOSTSCARE, attacker);

}
