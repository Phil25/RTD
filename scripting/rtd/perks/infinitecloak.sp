/**
* Infinite Cloak perk.
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


bool	g_bInfiniteCloak[MAXPLAYERS+1]	= {false, ...};

public void InfiniteCloak_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		InfiniteCloak_ApplyPerk(client);
	
	else
		g_bInfiniteCloak[client] = false;

}

void InfiniteCloak_ApplyPerk(int client){

	g_bInfiniteCloak[client] = true;
	CreateTimer(0.25, Timer_RefreshCloak, GetClientSerial(client), TIMER_REPEAT);

}

public Action Timer_RefreshCloak(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;

	if(!g_bInfiniteCloak[client])
		return Plugin_Stop;
	
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 105.0);
	
	return Plugin_Continue;

}
