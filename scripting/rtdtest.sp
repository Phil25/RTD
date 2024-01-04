/**
* Standalone plugin used for testing of RTD features.
* Copyright (C) 2023 Filip Tomaszewski
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

#define HANDLE_DUMP_INTERVAL 30.0
#define RTD_RELOAD_INTERVAL 120.0

bool g_bStress = false;
int g_iActionTicks[MAXPLAYERS + 1] = {0, ...};

enum struct HandleDumper
{
	Handle hTimer;

	void Start(const float fInterval=HANDLE_DUMP_INTERVAL)
	{
		this.Stop();
		this.Dump();
		this.hTimer = CreateTimer(fInterval, Timer_DumpHandles, _, TIMER_REPEAT);
	}

	void Stop()
	{
		delete this.hTimer;
	}

	void Dump()
	{
		char sCmd[128];
		FormatTime(sCmd, sizeof(sCmd), "sm_dump_handles rtd-handles/%Y-%m-%d_%H-%M-%S.txt", GetTime());
		ServerCommand(sCmd);
	}
}

HandleDumper g_eHandleDumper;
Handle g_hReloadTimer;

public Action Timer_DumpHandles(Handle hTimer, any aData)
{
	g_eHandleDumper.Dump();
	return Plugin_Continue;
}

public void OnPluginStart()
{
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("arena_round_start", Event_RoundStart);
	HookEvent("mvm_begin_wave", Event_RoundStart);

	RegAdminCmd("sm_rtdstress", Command_Stress, ADMFLAG_ROOT, "Run RTD stress test.");

	for (int i = 1; i <= MaxClients; ++i)
		if (IsClientInGame(i))
			OnClientPutInServer(i);
}

public void OnMapStart()
{
	RemoveObjectives();
}

public void TF2_OnWaitingForPlayersStart()
{
	ServerCommand("mp_waitingforplayers_cancel 1");
}

public Action Event_RoundStart(Handle hEvent, const char[] sEventName, bool dontBroadcast)
{
	RemoveObjectives();
	return Plugin_Continue;
}

void RemoveObjectives()
{
	char sMapName[32];
	GetCurrentMap(sMapName, sizeof(sMapName));
	if (!StrEqual(sMapName, "ultiduo_grove_b4"))
		return;

	int iCapArea = FindEntityByClassname(MaxClients + 1, "trigger_capture_area");
	if (iCapArea > MaxClients)
		AcceptEntityInput(iCapArea, "Kill");

	int iCapPoint = FindEntityByClassname(MaxClients + 1, "team_control_point");
	if (iCapPoint > MaxClients)
		AcceptEntityInput(iCapPoint, "HideModel");

	int iProp = MaxClients + 1;
	while ((iProp = FindEntityByClassname(iProp, "prop_dynamic")) != -1)
	{
		char sName[32];
		GetEntPropString(iProp, Prop_Data, "m_iName", sName, sizeof(sName));

		if (StrEqual(sName, "cp_koth_prop"))
		{
			AcceptEntityInput(iProp, "Kill");
			break;
		}
	}
}

public Action Command_Stress(int client, int args)
{
	g_bStress = !g_bStress;

	if (g_bStress)
	{
		int iDuration = 25;

		if (args > 0)
		{
			char sDuration[8];
			GetCmdArg(1, sDuration, sizeof(sDuration));
			iDuration = StringToInt(sDuration);
		}

		ServerCommand("sm_cvar sm_rtd2_interval 2");
		ServerCommand("sm_cvar sm_rtd2_duration %d", iDuration);
		ServerCommand("sm_cvar tf_bot_join_after_player 0");

		g_eHandleDumper.Start();
		g_hReloadTimer = CreateTimer(RTD_RELOAD_INTERVAL, Timer_ReloadRtd, _, TIMER_REPEAT);

		PrintCenterTextAll("RTD stress test begun (perk duration: %d).", iDuration);
		PrintToServer("[RTD] Stress test begun (perk duration: %d).", iDuration);
	}
	else
	{
		g_eHandleDumper.Stop();
		delete g_hReloadTimer;

		PrintCenterTextAll("RTD stress test finished.");
		PrintToServer("[RTD] Stress test finished.");
	}

	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
		return;

	g_iActionTicks[client] = 3;
	CreateTimer(1.0, Timer_Roll, GetClientUserId(client), TIMER_REPEAT);
}

public Action Timer_Roll(Handle hTimer, int iUserId)
{
	int client = GetClientOfUserId(iUserId);
	if (!client || !IsFakeClient(client))
		return Plugin_Stop;

	if (!g_bStress)
		return Plugin_Continue;

	if (--g_iActionTicks[client] > 0)
		return Plugin_Continue;

	g_iActionTicks[client] = GetRandomInt(1, 4);

	FakeClientCommand(client, "sm_rtd");
	FakeClientCommand(client, "voicemenu 1 8"); // "pass to me" is silent

	return Plugin_Continue;
}

public Action Timer_ReloadRtd(Handle hTimer, any aData)
{
	ServerCommand("sm_reloadrtd");
	return Plugin_Continue;
}
