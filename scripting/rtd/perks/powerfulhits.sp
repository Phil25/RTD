/**
* Powerful Hits perk.
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


bool	g_bHasPowerfulHits[MAXPLAYERS+1]	= {false, ...};
float	g_fPowerFulHitsMultiplayer			= 5.0;

void PowerfulHits_OnClientPutInServer(int client){

	SDKHook(client, SDKHook_OnTakeDamage, PowerfulHits_OnTakeDamage);

}

void PowerfulHits_Perk(int client, const char[] sPref, bool apply){

	g_bHasPowerfulHits[client]	= apply;
	g_fPowerFulHitsMultiplayer	= StringToFloat(sPref);

}

public Action PowerfulHits_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype){

	if(victim == attacker)
		return Plugin_Continue;
	
	if(attacker < 1 || attacker > MaxClients)
		return Plugin_Continue;
	
	if(!IsClientInGame(attacker))
		return Plugin_Continue;
	
	if(!g_bHasPowerfulHits[attacker])
		return Plugin_Continue;
	
	damage *= g_fPowerFulHitsMultiplayer;
	
	return Plugin_Changed;

}
