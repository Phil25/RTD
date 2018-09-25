/**
* Lag perk.
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


int g_iLagId = 57;

public void Lag_Perk(int client, Perk perk, bool apply){
	if(!apply){
		UnsetClientPerkCache(client, g_iLagId);
		return;
	}

	g_iLagId = perk.Id;
	SetClientPerkCache(client, g_iLagId);

	float fPos[3];
	GetClientAbsOrigin(client, fPos);
	SetVectorCache(client, fPos);

	int iUserId = GetClientUserId(client);
	CreateTimer(1.0, Timer_Lag_Teleport, iUserId, TIMER_REPEAT);
	CreateTimer(0.5, Timer_Lag_SetPos, iUserId, TIMER_REPEAT);
}

public Action Timer_Lag_Teleport(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iLagId))
		return Plugin_Stop;

	float fPos[3];
	GetVectorCache(client, fPos);
	TeleportEntity(client, fPos, NULL_VECTOR, NULL_VECTOR);
	return Plugin_Continue;
}

public Action Timer_Lag_SetPos(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iLagId))
		return Plugin_Stop;

	float fPos[3];
	GetClientAbsOrigin(client, fPos);
	SetVectorCache(client, fPos);
	return Plugin_Continue;
}
