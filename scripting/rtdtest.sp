/**
* Standalone plugin used for testing of RTD features.
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

#include <sdktools>
#include <sdkhooks>
#include <rtd2>

bool g_bStress = false;

public void OnPluginStart(){
	RegAdminCmd("sm_rtdstress", Command_Stress, 0);
	for(int i = 1; i <= MaxClients; ++i)
		if(IsClientInGame(i))
			OnClientPutInServer(i);
}

public Action Command_Stress(int client, int args){
	g_bStress = !g_bStress;
	PrintToChatAll("Stress test %d", g_bStress);
	return Plugin_Handled;
}

public void OnClientPutInServer(int client){
	if(!IsFakeClient(client)) return;
	CreateTimer(GetRandomFloat(1.0, 2.0), Timer_Roll, GetClientUserId(client));
}

public Action Timer_Roll(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client || !IsFakeClient(client))
		return Plugin_Stop;

	if(g_bStress) FakeClientCommand(client, "sm_rtd");
	CreateTimer(GetRandomFloat(1.0, 2.0), Timer_Roll, iUserId);
	return Plugin_Stop;
}
