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

#define INTERVAL 120.0

bool g_bStress = false;
int g_iFile = 0;
bool g_bPause = false;
Handle g_hTimer = null

public void OnPluginStart(){
	RegAdminCmd("sm_test", Command_TestRTD, 0, "blah");
	for(int i = 1; i <= MaxClients; ++i)
		if(IsClientInGame(i))
			OnClientPutInServer(i);
}

public Action Command_TestRTD(int client, int args){
	if(!client) return Plugin_Handled;
	if(args < 1) return Plugin_Handled;

	char sPerk[64];
	GetCmdArg(1, sPerk, 64);
	if(StrContains(sPerk, ";") == -1)
		ServerCommand("sm_forcertd #%d %s", GetClientUserId(client), sPerk);
	
	return Plugin_Handled;
}

public Action Command_Stress(int client, int args){
	g_bStress = !g_bStress;
	PrintToServer("Stress test %d", g_bStress);
	if(g_bStress){
		ServerCommand("sm_cvar sm_rtd2_interval 2");
		ServerCommand("sm_cvar sm_rtd2_duration 2");
		ServerCommand("sm_cvar tf_bot_join_after_player 0");
		g_hTimer = CreateTimer(INTERVAL, Timer_DumpHandles, _, TIMER_REPEAT);
	}else delete g_hTimer;
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

	if(g_bStress){
		g_bPause = g_iFile %10 == 0;
		if(!g_bPause) FakeClientCommand(client, "sm_rtd");
	}

	CreateTimer(GetRandomFloat(1.0, 2.0), Timer_Roll, iUserId);
	return Plugin_Stop;
}

public Action Timer_DumpHandles(Handle hTimer, any aData){
	ServerCommand("sm_dump_handles handles/%d.dump", ++g_iFile);
}
