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


int g_iInfiniteCloakId = 8;

public void InfiniteCloak_Call(int client, Perk perk, bool apply){
	if(apply) InfiniteCloak_ApplyPerk(client, perk);
	else UnsetClientPerkCache(client, g_iInfiniteCloakId);
}

void InfiniteCloak_ApplyPerk(int client, Perk perk){
	g_iInfiniteCloakId = perk.Id;
	SetClientPerkCache(client, g_iInfiniteCloakId);
	CreateTimer(0.25, Timer_RefreshCloak, GetClientUserId(client), TIMER_REPEAT);
}

public Action Timer_RefreshCloak(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iInfiniteCloakId))
		return Plugin_Stop;

	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 105.0);
	return Plugin_Continue;
}
