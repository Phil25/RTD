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


bool g_bHasLag[MAXPLAYERS+1] = {false, ...};
float g_fLagLastPos[MAXPLAYERS+1][3];

public void Lag_Perk(int client, const char[] sPref, bool apply){
	g_bHasLag[client] = apply;
	if(!apply) return;

	GetClientAbsOrigin(client, g_fLagLastPos[client]);
	int iUserId = GetClientUserId(client);
	CreateTimer(1.0, Timer_Lag_Teleport, iUserId, TIMER_REPEAT);
	CreateTimer(0.5, Timer_Lag_SetPos, iUserId, TIMER_REPEAT);
}

public Action Timer_Lag_Teleport(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client || !g_bHasLag[client])
		return Plugin_Stop;

	TeleportEntity(client, g_fLagLastPos[client], NULL_VECTOR, NULL_VECTOR);
	return Plugin_Continue;
}

public Action Timer_Lag_SetPos(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client || !g_bHasLag[client])
		return Plugin_Stop;

	GetClientAbsOrigin(client, g_fLagLastPos[client]);
	return Plugin_Continue;
}
