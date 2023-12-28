/**
* Main RTD source file.
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
#pragma semicolon 1

#include <rtd2>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2attributes>

#undef REQUIRE_PLUGIN
#tryinclude <updater>
#tryinclude <friendly>
#tryinclude <friendlysimple>

#define PLUGIN_VERSION	"2.5.0"

#define CHAT_PREFIX 	"\x07FFD700[RTD]\x01"
#define CONS_PREFIX 	"[RTD]"

#define PERK_COLOR_GOOD	"\x0732CD32"
#define PERK_COLOR_BAD	"\x078650AC"

#define FLAG_FEIGNDEATH	(1 << 5)
#define FLAGS_CVARS		FCVAR_NOTIFY

#if defined _updater_included
#define UPDATE_URL		"https://phil25.github.io/RTD/update.txt"
#endif

//#define DEBUG // log extra messages
#define DEBUG_VECTOR3(%1,%2) \
	PrintToServer(%1 ... ": [%.2f, %.2f, %.2f]", %2[0], %2[1], %2[2]); \
	PrintToChatAll(%1 ... ": [%.2f, %.2f, %.2f]", %2[0], %2[1], %2[2])

public Plugin myinfo = {
	name = "Roll The Dice (Revamped)",
	author = "Phil25",
	description = "Lets players roll for temporary benefits.",
	version	= PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=278579"
};

static char g_sTeamColors[][] = {"\x07B2B2B2", "\x07B2B2B2", "\x07FF4040", "\x0799CCFF"};

#if defined _updater_included
bool g_bPluginUpdater = false;
bool g_bIsUpdateForced = false;
#endif
#if defined _friendly_included
bool g_bPluginFriendly = false;
#endif
#if defined _friendlysimple_included
bool g_bPluginFriendlySimple = false;
#endif

bool g_bIsRegisteringOpen = false;

ArrayList g_hPerkHistory = null;
int g_iCorePerks = 0;

bool g_bIsGameArena = false;
bool g_bIsGameMedieval = false;
int g_iLastPerkTime = -1;

Rollers g_hRollers = null;
int g_iActiveEntitySpawnedSubscribers = 0;
int g_iLastEntitySpawnTime = 0;

Handle g_hFwdCanRoll;
Handle g_hFwdCanForce;
Handle g_hFwdCanRemove;
Handle g_hFwdRolled;
Handle g_hFwdRemoved;
Handle g_hFwdOnRegOpen;

#include "rtd/macros.sp"
#include "rtd/storage/precached.sp"
#include "rtd/storage/cache.sp"
#include "rtd/storage/event_registrar.sp"
#include "rtd/stocks.sp"
#include "rtd/parsing.sp"
#include "rtd/classes/perk.sp"
#include "rtd/classes/containers.sp"
#include "rtd/classes/iterators.sp"
#include "rtd/classes/rollers.sp"
#include "rtd/perks.sp"
#include "rtd/natives.sp"
#include "rtd/convars.sp"

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrorSize)
{
	char sGame[32];
	sGame[0] = '\0';

	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "tf"))
	{
		Format(sError, iErrorSize, CONS_PREFIX ... " This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}

	CreateNatives();
	RegPluginLibrary("RollTheDice2");

	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("rtd2.phrases.txt");
	LoadTranslations("rtd2_perks.phrases.txt");
	LoadTranslations("common.phrases.txt");

	// ConVars
	CreateConVar("sm_rtd2_version", PLUGIN_VERSION, "Current RTD version, do not change.", FLAGS_CVARS|FCVAR_DONTRECORD|FCVAR_SPONLY);
	SetupConVars();

	AutoExecConfig(true);

	// cache and perks
	InitClientCache();

	if (ParseEffects())
		ParseCustomEffects();

	// Forwards
	g_hFwdCanRoll = CreateGlobalForward("RTD2_CanRollDice", ET_Event, Param_Cell);
	g_hFwdCanForce = CreateGlobalForward("RTD2_CanForcePerk", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFwdCanRemove = CreateGlobalForward("RTD2_CanRemovePerk", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFwdRolled = CreateGlobalForward("RTD2_Rolled", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFwdRemoved = CreateGlobalForward("RTD2_Removed", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFwdOnRegOpen = CreateGlobalForward("RTD2_OnRegOpen", ET_Ignore);

	// Commands
	RegAdminCmd("sm_rtd", Command_RTD, 0, "Roll a perk.");
	RegAdminCmd("sm_perks", Command_DescMenu, 0, "Display a description menu of RTD perks.");

	RegAdminCmd("sm_forcertd", Command_ForceRTD, ADMFLAG_SLAY, "Applies perk to selected player(s).");
	RegAdminCmd("sm_timertd", Command_TimeRTD, ADMFLAG_SLAY, "Check or add perk time to selected player(s).");
	RegAdminCmd("sm_removertd", Command_RemoveRTD, ADMFLAG_SLAY, "Removes perk from selected player(s).");

	RegAdminCmd("sm_rtds", Command_PerkSearchup, ADMFLAG_SLAY, "Displays customized perk list.");
	RegAdminCmd("sm_rtdsearch", Command_PerkSearchup, ADMFLAG_SLAY, "Displays customized perk list.");

	RegAdminCmd("sm_reloadrtd", Command_Reload, ADMFLAG_CONFIG, "Reloads the config files.");
#if defined _updater_included
	RegAdminCmd("sm_updatertd", Command_Update, ADMFLAG_ROOT, "Force an update check. Does nothing if Updater is not installed.");
#endif

	// Listeners
	AddCommandListener(Listener_Say, "say");
	AddCommandListener(Listener_Say, "say_team");
	AddCommandListener(Listener_Voice, "voicemenu");
	AddNormalSoundHook(Listener_Sound);

	g_hRollers = new Rollers();
	g_hPerkHistory = new PerkList();

	for (int i = 1; i <= MaxClients; ++i)
		if (IsClientInGame(i))
			OnClientPutInServer(i);
}

public void OnConfigsExecuted()
{
	g_bIsRegisteringOpen = true;

	Forward_OnRegOpen();
	ParseDisabledPerks();
}

public void OnPluginEnd()
{
	ResetAllClients();
}

void InitClientCache()
{
	for (int i = 1; i <= MaxClients; ++i)
		Cache[i].Init(i);
}

void ResetAllClients(RTDRemoveReason reason=RTDRemove_PluginUnload)
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (g_hRollers.GetInRoll(i))
			ForceRemovePerk(i, reason);

		g_hRollers.Reset(i);
	}
}

public void OnMapStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_changeclass", Event_ClassChange);
	HookEvent("teamplay_round_active", Event_RoundActive);
	HookEvent("post_inventory_application", Event_Resupply);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_chargedeployed", Event_UberchargeDeployed);

	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("arena_round_start", Event_RoundStart);
	HookEvent("mvm_begin_wave", Event_RoundStart);

	Storage_Precache();
	Stocks_OnMapStart(); // rtd/stocks.sp
	PrecachePerkSounds();

	Events.Init();
	InitPerks();

	g_bIsGameArena = (FindEntityByClassname(MaxClients + 1, "tf_logic_arena") > MaxClients);

	ConVar cvMedieval = FindConVar("tf_medieval");
	if (cvMedieval != null)
		g_bIsGameMedieval = cvMedieval.BoolValue;

	g_bIsGameMedieval |= (FindEntityByClassname(MaxClients + 1, "tf_logic_medieval") > MaxClients);
}

public void OnMapEnd()
{
	Events.Cleanup();

	UnhookEvent("player_death", Event_PlayerDeath);
	UnhookEvent("player_changeclass", Event_ClassChange);
	UnhookEvent("teamplay_round_active", Event_RoundActive);
	UnhookEvent("post_inventory_application", Event_Resupply);
	UnhookEvent("player_hurt", Event_PlayerHurt);
	UnhookEvent("player_chargedeployed", Event_UberchargeDeployed);

	UnhookEvent("teamplay_round_start", Event_RoundStart);
	UnhookEvent("arena_round_start", Event_RoundStart);
	UnhookEvent("mvm_begin_wave", Event_RoundStart);
}

public void OnClientPutInServer(int client)
{
	g_hRollers.Reset(client);

	if (g_hRollers.GetHud(client) == null)
		g_hRollers.SetHud(client, CreateHudSynchronizer());

	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
}

public void OnClientDisconnect(int client)
{
	Events.PlayerDisconnected(client);

	if (g_hRollers.GetInRoll(client))
		ForceRemovePerk(client, RTDRemove_Disconnect, _, client);

	g_hRollers.Reset(client);
	SDKUnhook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
}

public Action OnGetMaxHealth(int client, int& iMaxHealh)
{
	Shared[client].MaxHealth = iMaxHealh;
	return Plugin_Continue;
}

public void OnAllPluginsLoaded()
{
#if defined _updater_included
	g_bPluginUpdater = LibraryExists("updater");
	if (g_bPluginUpdater)
		Updater_AddPlugin(UPDATE_URL);
#endif

#if defined _friendly_included
	g_bPluginFriendly = LibraryExists("[TF2] Friendly Mode");
#endif

#if defined _friendlysimple_included
	g_bPluginFriendlySimple = LibraryExists("Friendly Simple");
#endif
}

public void OnLibraryAdded(const char[] sLibName)
{
#if defined _updater_included
	if (StrEqual(sLibName, "updater"))
	{
		g_bPluginUpdater = true;
		Updater_AddPlugin(UPDATE_URL);
		return;
	}
#endif

#if defined _friendly_included
	if (StrEqual(sLibName, "[TF2] Friendly Mode"))
	{
		g_bPluginFriendly = true;
		return;
	}
#endif

#if defined _friendlysimple_included
	if (StrEqual(sLibName, "Friendly Simple"))
	{
		g_bPluginFriendlySimple = true;
		return;
	}
#endif
}

public void OnLibraryRemoved(const char[] sLibName)
{
#if defined _updater_included
	if (StrEqual(sLibName, "updater"))
	{
		g_bPluginUpdater = false;
		return;
	}
#endif

#if defined _friendly_included
	if (StrEqual(sLibName, "[TF2] Friendly Mode"))
	{
		g_bPluginFriendly = false;
		return;
	}
#endif

#if defined _friendlysimple_included
	if(StrEqual(sLibName, "Friendly Simple"))
	{
		g_bPluginFriendlySimple = false;
		return;
	}
#endif
}

#if defined _updater_included
public Action Updater_OnPluginChecking()
{
	if (!g_bCvarAutoUpdate && !g_bIsUpdateForced)
		return Plugin_Handled;

	g_bIsUpdateForced = false;
	return Plugin_Continue;
}

public int Updater_OnPluginUpdated()
{
	if (g_bCvarReloadUpdate)
		ReloadPlugin();
}
#endif

public Action Command_RTD(const int client, const int args)
{
	if (client != 0)
		RollPerkForClient(client);

	return Plugin_Handled;
}

public Action Command_DescMenu(const int client, const int args)
{
	if (client != 0)
		ShowDescriptionMenu(client);

	return Plugin_Handled;
}

public Action Command_ForceRTD(const int client, const int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_forcertd <target> [perk query] [time in seconds]");
		return Plugin_Handled;
	}

	char sTrgName[MAX_TARGET_LENGTH], sTrg[32];
	int aTrgList[MAXPLAYERS], iTrgCount;
	bool bNameMultiLang;
	GetCmdArg(1, sTrg, sizeof(sTrg));

	if ((iTrgCount = ProcessTargetString(sTrg, client, aTrgList, MAXPLAYERS, COMMAND_FILTER_ALIVE, sTrgName, sizeof(sTrgName), bNameMultiLang)) <= 0)
	{
		ReplyToTargetError(client, iTrgCount);
		return Plugin_Handled;
	}

	int iPerkTime = -1;
	char sQuery[32] = "";

	if (args > 1)
	{
		GetCmdArg(2, sQuery, sizeof(sQuery));

		if (args > 2)
		{
			char sPerkTime[8];
			GetCmdArg(3, sPerkTime, sizeof(sPerkTime));
			iPerkTime = StringToInt(sPerkTime);
		}
	}

	for (int i = 0; i < iTrgCount; ++i)
		ForcePerk(aTrgList[i], sQuery, iPerkTime, client);

	return Plugin_Handled;
}

public Action Command_TimeRTD(const int client, const int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addrtdtime <target> [time to add in seconds]");
		return Plugin_Handled;
	}

	char sTrgName[MAX_TARGET_LENGTH], sTrg[32];
	int aTrgList[MAXPLAYERS], iTrgCount;
	bool bNameMultiLang;
	GetCmdArg(1, sTrg, sizeof(sTrg));

	if ((iTrgCount = ProcessTargetString(sTrg, client, aTrgList, MAXPLAYERS, COMMAND_FILTER_ALIVE, sTrgName, sizeof(sTrgName), bNameMultiLang)) <= 0)
	{
		ReplyToTargetError(client, iTrgCount);
		return Plugin_Handled;
	}

	int iCurrentTime = GetTime();

	if (args < 2)
	{
		for (int i = 0; i < iTrgCount; ++i)
		{
			int iTarget = aTrgList[i];

			if (g_hRollers.GetInRoll(iTarget))
			{
				int iRemaining = g_hRollers.GetEndRollTime(iTarget) - iCurrentTime;
				RTDPrint(client, "%N has %d seconds remaining.", iTarget, iRemaining);
			}
			else
			{
				RTDPrint(client, "%N is not in roll.", iTarget);
			}
		}

		return Plugin_Handled;
	}

	char sAddTime[32] = "";
	GetCmdArg(2, sAddTime, sizeof(sAddTime));

	int iAddTime = StringToInt(sAddTime);
	if (iAddTime == 0)
	{
		ReplyToCommand(client, "[SM] Provided 0 or invalid time: \"%s\"", sAddTime);
		return Plugin_Handled;
	}

	for (int i = 0; i < iTrgCount; ++i)
	{
		int iTarget = aTrgList[i];

		if (g_hRollers.GetInRoll(iTarget))
		{
			g_hRollers.AddRollTime(iTarget, iAddTime);
			int iRemaining = g_hRollers.GetEndRollTime(iTarget) - iCurrentTime;
			RTDPrint(client, "%N's perk time has been %s to %d seconds.", iTarget, iAddTime > 0 ? "increased" : "decreased", iRemaining);

			if (g_iCvarLogging & view_as<int>(LogFlag_Action))
				LogAction(client, iTarget, "\"%L\" %s perk time of \"%L\" to %d seconds", client, iAddTime > 0 ? "increased" : "decreased", iTarget, iRemaining);
		}
		else
		{
			RTDPrint(client, "%N is not in roll.", iTarget);
		}
	}

	return Plugin_Handled;
}

public Action Command_RemoveRTD(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_removertd <player> [\"reason\"]");
		return Plugin_Handled;
	}

	char sTrgName[MAX_TARGET_LENGTH], sTrg[32];
	int aTrgList[MAXPLAYERS], iTrgCount;
	bool bNameMultiLang;
	GetCmdArg(1, sTrg, sizeof(sTrg));

	if ((iTrgCount = ProcessTargetString(sTrg, client, aTrgList, MAXPLAYERS, COMMAND_FILTER_ALIVE, sTrgName, sizeof(sTrgName), bNameMultiLang)) <= 0)
	{
		ReplyToTargetError(client, iTrgCount);
		return Plugin_Handled;
	}

	char sReason[128] = "";
	if (args > 1)
		GetCmdArg(2, sReason, sizeof(sReason));

	bool bFuncCount = GetForwardFunctionCount(g_hFwdCanRemove) > 0;
	for (int i = 0; i < iTrgCount; ++i)
	{
		if (g_hRollers.GetInRoll(aTrgList[i]) && bFuncCount)
		{
			Call_StartForward(g_hFwdCanRemove);
			Call_PushCell(client);
			Call_PushCell(aTrgList[i]);
			Call_PushCell(g_hRollers.GetPerk(aTrgList[i]).Id);
			Action result = Plugin_Continue;
			Call_Finish(result);

			if (result != Plugin_Continue)
				continue;
		}

		if (g_hRollers.GetInRoll(aTrgList[i]))
			ForceRemovePerk(aTrgList[i], args > 1 ? RTDRemove_Custom : RTDRemove_WearOff, sReason, client);
	}

	return Plugin_Handled;
}

public Action Command_PerkSearchup(int client, int args)
{
	char sQuery[64] = "";
	if (args > 0)
		GetCmdArg(1, sQuery, 64);

	char sFormat[64] = "$Id$. $Name$";
	if (args > 1)
		GetCmdArg(2, sFormat, 64);

	PerkList list = g_hPerkContainer.FindPerks(sQuery);
	int iLen = list.Length;

	char sBuffer[1024];
	for (int i = 0; i < iLen; ++i)
	{
		list.Get(i).Format(sBuffer, 1024, sFormat);
		PrintToConsole(client, sBuffer);
	}

	RTDPrint(client, "%d perk%s found matching given criteria.", iLen, iLen != 1 ? "s" : "");

	delete list;
	return Plugin_Handled;
}

public Action Command_Reload(int client, int args)
{
	if (g_iCvarLogging & view_as<int>(LogFlag_Action))
		LogAction(client, -1, "\"%L\" triggered configs and perks reload", client);

	ResetAllClients();

	ParseEffects();
	ParseCustomEffects();
	ParseDisabledPerks();

	Events.Cleanup();
	Events.Init();
	InitPerks();

	Forward_OnRegOpen();

	ReplyToCommand(client, CONS_PREFIX ... " Configs and perks reloaded successfully.");

	return Plugin_Handled;
}

#if defined _updater_included
public Action Command_Update(int client, int args)
{
	if (g_iCvarLogging & view_as<int>(LogFlag_Action))
		LogAction(client, -1, "\"%L\" triggered plugin update", client);

	if (!g_bPluginUpdater)
	{
		ReplyToCommand(client, CONS_PREFIX ... " Updater is not installed.");
		return Plugin_Handled;
	}

	g_bIsUpdateForced = true;
	if (Updater_ForceUpdate())
	{
		ReplyToCommand(client, CONS_PREFIX ... " New RTD version available!");
	}
	else
	{
		ReplyToCommand(client, CONS_PREFIX ... " This RTD version is up to date or unable to update.");
	}

	g_bIsUpdateForced = false;
	return Plugin_Handled;
}
#endif

public Action Listener_Say(int client, const char[] sCommand, int args)
{
	if (!IsValidClient(client))
		return Plugin_Continue;

	char sText[16];
	GetCmdArg(1, sText, sizeof(sText));
	if (!IsArgumentTrigger(sText))
		return Plugin_Continue;

	RollPerkForClient(client);
	return g_bCvarShowTriggers ? Plugin_Continue : Plugin_Stop;
}

public Action Listener_Voice(int client, const char[] sCommand, int args)
{
	if (IsValidClient(client))
		Events.Voice(client);

	return Plugin_Continue;
}

public Action Listener_Sound(int clients[MAXPLAYERS], int& iLen, char sSample[PLATFORM_MAX_PATH], int& iEnt, int& iChannel, float& fVol, int& iLevel, int& iPitch, int& iFlags, char sEntry[PLATFORM_MAX_PATH], int& iSeed)
{
	if (!IsValidClient(iEnt))
		return Plugin_Continue;

	return (Stocks_Sound(iEnt, sSample) && Events.Sound(iEnt, sSample)) ? Plugin_Continue : Plugin_Stop;
}

public Action Event_PlayerDeath(Handle hEvent, const char[] sEventName, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!client)
		return Plugin_Continue;

	if (GetEventInt(hEvent, "death_flags") & FLAG_FEIGNDEATH)
		return Plugin_Continue;

	Events.PlayerDied(client);

	if (!g_hRollers.GetInRoll(client))
		return Plugin_Continue;

	ForceRemovePerk(client, RTDRemove_Death);
	return Plugin_Continue;
}

public Action Event_ClassChange(Handle hEvent, const char[] sEventName, bool dontBroadcast)
{
	int iUserId = GetEventInt(hEvent, "userid");
	int client = GetClientOfUserId(iUserId);
	if (client == 0)
		return Plugin_Continue;

	int iClass = GetEventInt(hEvent, "class");
	if (view_as<int>(TF2_GetPlayerClass(client)) == iClass)
		return Plugin_Continue; // no actual class change in effect

	if (!g_hRollers.GetInRoll(client))
		return Plugin_Continue;

	DataPack hData = new DataPack();
	hData.WriteCell(iUserId);
	hData.WriteCell(iClass);
	CreateTimer(0.1, Timer_ClassChangePost, hData, TIMER_DATA_HNDL_CLOSE);

	return Plugin_Continue;
}

public Action Timer_ClassChangePost(Handle hTimer, DataPack hData)
{
	hData.Reset();

	int client = GetClientOfUserId(hData.ReadCell());
	if (!client)
		return Plugin_Stop;

	int iDesiredClass = hData.ReadCell();
	if (view_as<int>(TF2_GetPlayerClass(client)) == iDesiredClass)
		ForceRemovePerk(client, RTDRemove_ClassChange, _, client);

	return Plugin_Stop;
}

public Action Event_RoundActive(Handle hEvent, const char[] sEventName, bool dontBroadcast)
{
	if (g_bCvarPluginEnabled && (g_iCvarChat & view_as<int>(ChatFlag_Ad)) && IsRTDInRound())
		RTDPrintAll("%t", "RTD2_Ad", 0x03, 0x01);

	return Plugin_Continue;
}

public Action Event_Resupply(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (1 <= client <= MaxClients)
		Events.Resupply(client);

	return Plugin_Continue;
}

public Action Event_PlayerHurt(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	int iDamage = GetEventInt(hEvent, "damageamount");
	int iRemainingHealth = GetEventInt(hEvent, "health");

	if (1 <= iVictim <= MaxClients && 1 <= iAttacker <= MaxClients)
		Events.PlayerAttacked(iAttacker, iVictim, iDamage, iRemainingHealth);

	return Plugin_Continue;
}

public Action Event_UberchargeDeployed(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int iTarget = GetClientOfUserId(GetEventInt(hEvent, "targetid"));
	Events.UberchargeDeployed(client, iTarget);
	return Plugin_Continue;
}

public Action Event_RoundStart(Handle hEvent, const char[] sEventName, bool dontBroadcast)
{
	ResetAllClients(RTDRemove_NoPrint);
	return Plugin_Continue;
}

public void OnEntityCreated(int iEnt, const char[] sClassname)
{
	if (g_iActiveEntitySpawnedSubscribers <= 0)
		return;

	if (!Events.ClassnameHasSubscribers(sClassname))
		return;

	SDKHook(iEnt, SDKHook_SpawnPost, OnEntitySpawned);
}

public void OnEntitySpawned(const int iEnt)
{
	int iSpawnTime = RoundToNearest(GetEngineTime() * 1000);

	// For certain entities Spawn hook fires twice for some reason
	if (iSpawnTime == g_iLastEntitySpawnTime)
		return;

	g_iLastEntitySpawnTime = iSpawnTime;
	Events.EntitySpawned(iEnt);
}

public void OnGameFrame()
{
	Homing_OnGameFrame();
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	Events.ConditionAdded(client, condition);
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	Events.ConditionRemoved(client, condition);
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVel[3], float fAng[3], int &iWeapon)
{
	if (!IsValidClient(client))
		return Plugin_Continue;

	return Events.PlayerRunCmd(client, iButtons, fVel, fAng) ? Plugin_Changed : Plugin_Continue;
}

public Action TF2_CalcIsAttackCritical(int client, int iWeapon, char[] sWeaponName, bool &bResult)
{
	if (!IsValidClient(client))
		return Plugin_Continue;

	if (!Events.AttackCritCheck(client, iWeapon))
		return Plugin_Continue;

	bResult = true;
	return Plugin_Changed;
}

void ParseTriggers()
{
	char sCvar[64], sBuffer[64];
	GetConVarString(g_hCvarTriggers, sCvar, sizeof(sCvar));
	EscapeString(sCvar, ' ', '\0', sBuffer, sizeof(sBuffer));

	g_iCvarTriggers = CountCharInString(sBuffer, ',') + 1;
	char[][] sPieces = new char[g_iCvarTriggers][64];

	ExplodeString(sBuffer, ",", sPieces, g_iCvarTriggers, 64);

	if (g_arrCvarTriggers == INVALID_HANDLE)
	{
		g_arrCvarTriggers = CreateArray(16);
	}
	else
	{
		ClearArray(g_arrCvarTriggers);
	}

	for (int i = 0; i < g_iCvarTriggers; ++i)
		PushArrayString(g_arrCvarTriggers, sPieces[i]);
}

#define CHECK_PATH(%1) \
	BuildPath(Path_SM, g_sCustomConfigPath, PLATFORM_MAX_PATH, %1, sCustomConfig); \
	if (FileExists(g_sCustomConfigPath)) return true

bool FindCustomConfigPath(const char[] sCustomConfig)
{
	CHECK_PATH("configs/%s");
	CHECK_PATH("configs/%s.cfg");
	CHECK_PATH("configs/rtd2_perks.%s.cfg");
	CHECK_PATH("%s");
	return false;
}

#undef CHECK_PATH

bool ParseCustomConfig()
{
	char sCustomConfig[PLATFORM_MAX_PATH];
	GetConVarString(g_hCvarCustomConfig, sCustomConfig, sizeof(sCustomConfig));

	if (FindCustomConfigPath(sCustomConfig))
		return true; // config found

	if (StrEqual(sCustomConfig, "rtd2_perks.custom.cfg"))
		return false; // config not found, but user did not specify it

	LogError("Custom perk config is specified as \"%s\", but could find it under any path:\n"
		... "> <Path_SM>/configs/%s\n"
		... "> <Path_SM>/configs/%s.cfg\n"
		... "> <Path_SM>/configs/rtd2_perks.%s.cfg\n"
		... "> <Path_SM>/%s\n",
		sCustomConfig, sCustomConfig, sCustomConfig, sCustomConfig, sCustomConfig);

	return false;
}

bool ParseEffects()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/rtd2_perks.default.cfg");

	if (!FileExists(sPath))
	{
		LogError("Failed to find rtd2_perks.default.cfg in configs/ folder");
		SetFailState("Failed to find rtd2_perks.default.cfg in configs/ folder");
		return false;
	}

	if (g_hPerkContainer == null)
		g_hPerkContainer = new PerkContainer();

	g_hPerkContainer.DisposePerks();

	int iStatus[2];
	g_iCorePerks = g_hPerkContainer.ParseFile(sPath, iStatus);

	if (g_iCorePerks == -1)
	{
		LogError("Parsing rtd2_perks.default.cfg failed");
		SetFailState("Parsing rtd2_perks.default.cfg failed");
		return false;
	}

	if (g_iCvarLogging & view_as<int>(LogFlag_System))
		LogMessage("Loaded %d perk%s (%d good, %d bad)", g_iCorePerks, g_iCorePerks == 1 ? "" : "s", iStatus[1], iStatus[0]);

	return true;
}

void ParseCustomEffects()
{
	if (!g_bCustomConfigFound)
	{
		PrecachePerkSounds();
		return;
	}

	int iPerksCustomized = g_hPerkContainer.ParseCustomFile(g_sCustomConfigPath);

	if (g_iCvarLogging & view_as<int>(LogFlag_System))
		LogMessage("Customized %d perk%s", iPerksCustomized, iPerksCustomized == 1 ? "" : "s");

	PrecachePerkSounds();
}

void PrecachePerkSounds()
{
	char sBuffer[64];
	PerkIter iter = new PerkContainerIter(-1);

	while ((++iter).Perk())
	{
		iter.Perk().GetSound(sBuffer, 64);
		PrecacheSound(sBuffer);
	}

	delete iter;
}

void InitPerks()
{
	PerkIter iter = new PerkContainerIter(-1);

	while ((++iter).Perk())
	{
		iter.Perk().InitInternal();
	}

	delete iter;
}

void ParseDisabledPerks()
{
	PerkIter iter = new PerkContainerIter(-1);

	while ((++iter).Perk())
		iter.Perk().Enabled = true;

	delete iter;

	char sDisabledPre[255], sDisabled[255];
	GetConVarString(g_hCvarDisabledPerks, sDisabledPre, sizeof(sDisabledPre));
	EscapeString(sDisabledPre, ' ', '\0', sDisabled, sizeof(sDisabled));
	if (strlen(sDisabled) == 0)
		return;

	int iDisabledCount = CountCharInString(sDisabled, ',') + 1;
	char[][] sDisabledPieces = new char[iDisabledCount][32];
	ExplodeString(sDisabled, ",", sDisabledPieces, iDisabledCount, 32);

	PerkList hDisabledPerks = new PerkList();
	for (int i = 0; i < iDisabledCount; ++i)
	{
		Perk perk = g_hPerkContainer.FindPerk(sDisabledPieces[i]);
		if (perk == null)
			continue;

		perk.Enabled = false;
		hDisabledPerks.Push(perk);
	}

	if (!(g_iCvarLogging & view_as<int>(LogFlag_System)))
	{
		delete hDisabledPerks;
		return;
	}

	char sNameBuffer[64];
	int iLen = hDisabledPerks.Length;
	switch (iLen)
	{
		case 1:
		{
			hDisabledPerks.Get(0).GetName(sNameBuffer, sizeof(sNameBuffer));
			LogMessage(CONS_PREFIX ... " Perk disabled: %s", sNameBuffer);
		}

		default:
		{
			LogMessage(CONS_PREFIX ... " %d perks disabled:", iLen);

			for (int i = 0; i < iLen; ++i)
			{
				hDisabledPerks.Get(i).GetName(sNameBuffer, sizeof(sNameBuffer));
				LogMessage("  > %s", sNameBuffer);
			}
		}
	}

	delete hDisabledPerks;
}

void RollPerkForClient(int client)
{
	if (!g_bCvarPluginEnabled)
	{
		if (g_iCvarChat & view_as<int>(ChatFlag_Reasons))
			RTDPrint(client, "%t", "RTD2_Cant_Roll_Disabled");

		return;
	}

	if (!IsRollerAllowed(client))
	{
		if (g_iCvarChat & view_as<int>(ChatFlag_Reasons))
			RTDPrint(client, "%t", "RTD2_Cant_Roll_No_Access");

		return;
	}

	if (!IsRTDInRound())
	{
		if (g_iCvarChat & view_as<int>(ChatFlag_Reasons))
			RTDPrint(client, "%t", "RTD2_Not_In_Round");

		return;
	}

	if (g_iCvarRtdTeam > 0 && g_iCvarRtdTeam == GetClientTeam(client) - 1)
	{
		if (g_iCvarChat & view_as<int>(ChatFlag_Reasons))
			RTDPrint(client, "%t", "RTD2_Cant_Roll_Team");

		return;
	}

	if (GetForwardFunctionCount(g_hFwdCanRoll) > 0)
	{
		Call_StartForward(g_hFwdCanRoll);
		Call_PushCell(client);

		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result != Plugin_Continue)
			return;
	}

	if (!IsPlayerAlive(client))
	{
		if (g_iCvarChat & view_as<int>(ChatFlag_Reasons))
			RTDPrint(client, "%t", "RTD2_Cant_Roll_Alive");

		return;
	}

	if (g_hRollers.GetInRoll(client))
	{
		if (g_iCvarChat & view_as<int>(ChatFlag_Reasons))
			RTDPrint(client, "%t", "RTD2_Cant_Roll_Using");

		return;
	}

	int iTimeLeft = g_hRollers.GetLastRollTime(client) + g_iCvarRollInterval;
	if (GetTime() < iTimeLeft)
	{
		if (g_iCvarChat & view_as<int>(ChatFlag_Reasons))
			RTDPrint(client, "%t", "RTD2_Cant_Roll_Wait", 0x04, iTimeLeft - GetTime(), 0x01);

		return;
	}

	switch (g_iCvarRtdMode)
	{
		case 1:
		{
			int iCount = 0;
			for (int i = 1; i <= MaxClients; ++i)
				if (g_hRollers.GetInRoll(i))
					++iCount;

			if (iCount >= g_iCvarClientLimit)
			{
				if (g_iCvarChat & view_as<int>(ChatFlag_Reasons))
					RTDPrint(client, "%t", "RTD2_Cant_Roll_Mode1");

				return;
			}
		}

		case 2:
		{
			int iCount = 0, iTeam = GetClientTeam(client);
			for (int i = 1; i <= MaxClients; ++i)
				if (g_hRollers.GetInRoll(i) && GetClientTeam(i) == iTeam)
					++iCount;

			if (iCount >= g_iCvarTeamLimit)
			{
				if (g_iCvarChat & view_as<int>(ChatFlag_Reasons))
					RTDPrint(client, "%t", "RTD2_Cant_Roll_Mode2");

				return;
			}
		}
	}

	Perk perk = RollPerk(client);

	if (perk == null) // should not happen unless everything is disabled or not applicable to player
	{
		LogMessage("WARNING: Perk not found for player when they attempted a roll");

		if (g_iCvarChat & view_as<int>(ChatFlag_Reasons))
			RTDPrint(client, "%t", "RTD2_Cant_Roll_No_Access");

		return;
	}

	ApplyPerk(client, perk);

	if (g_iCvarLogging & view_as<int>(LogFlag_PerkApply))
	{
		char sBuffer[64];
		perk.Format(sBuffer, 64, "$Name$ ($Token$)");
		LogMessage("%L rolled %s", client, sBuffer);
	}
}

RTDForceResult ForcePerk(const int client, const char[] sQuery, const int iPerkTime=-1, const int iInitiator=0)
{
	if (!IsValidClient(client))
		return RTDForce_ClientInvalid;

	bool bIsValidInitiator = IsValidClient(iInitiator);
	if (g_hRollers.GetInRoll(client))
	{
		RTDPrint(iInitiator, "%N is already using RTD.", client);
		return RTDForce_ClientInRoll;
	}

	if (!IsPlayerAlive(client))
	{
		RTDPrint(iInitiator, "%N is dead.", client);
		return RTDForce_ClientDead;
	}

	Perk perk = g_hPerkContainer.FindPerk(sQuery);
	if (!perk)
	{
		RTDPrint(iInitiator, "Perk not found or invalid info, forcing a roll.");
		perk = RollPerk(client, _, sQuery);
		if (!perk)
		{
			RTDPrint(iInitiator, "No perks available for %N.", client);
			return RTDForce_NullPerk;
		}
	}

	if (bIsValidInitiator && GetForwardFunctionCount(g_hFwdCanForce) > 0)
	{
		Call_StartForward(g_hFwdCanForce);
		Call_PushCell(iInitiator);
		Call_PushCell(client);
		Call_PushCell(perk.Id);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result != Plugin_Continue)
			return RTDForce_Blocked;
	}

	g_iLastPerkTime = iPerkTime;
	ApplyPerk(client, perk, iPerkTime);
	g_iLastPerkTime = -1; // Set back to default

	if (!(g_iCvarLogging & view_as<int>(LogFlag_Action)))
		return RTDForce_Success;

	char sPerk[64];
	perk.Format(sPerk, sizeof(sPerk), "$Name$ ($Token$)");

	char sDuration[32];
	if (perk.Time != -1) // not instant
		Format(sDuration, sizeof(sDuration), "for %d seconds ", GetPerkTimeEx(perk, iPerkTime));

	if (bIsValidInitiator)
	{
		LogAction(iInitiator, client, "\"%L\" forced %s on \"%L\" %s(query: %s)", iInitiator, sPerk, client, sDuration, sQuery);
	}
	else
	{
		LogAction(-1, client, "%s was forced on \"%L\" %s(query: %s)", sPerk, client, sDuration, sQuery);
	}

	return RTDForce_Success;
}

bool GoodRoll(const int client)
{
	float fGoodChance = g_fCvarGoodChance;

	if (IsValidClient(client) && IsRollerDonator(client))
		fGoodChance = g_fCvarGoodDonatorChance;

	return fGoodChance > GetURandomFloat();
}

Perk RollPerk(const int client=0, const int iRollFlags=ROLLFLAG_NONE, const char[] sFilter="")
{
	bool bFilter = strlen(sFilter) > 0;
	Perk perk = null;
	PerkList candidates = g_hPerkContainer.FindPerks(sFilter);
	PerkList list = new PerkList();
	PerkIter iter = new PerkListIter(candidates, -1);

#if defined DEBUG
	PrintToServer("Perk pool for %N<%d>:", client, client);
#endif

	if (bFilter)
	{
		while ((perk = (++iter).Perk()))
			if (perk.IsAptForSetupOf(client, iRollFlags))
			{
				list.Push(perk);

#if defined DEBUG
				char sName[64];
				perk.GetName(sName, sizeof(sName));
				PrintToServer("> %s", sName);
#endif
			}
	}
	else
	{
		bool bBeGood = GoodRoll(client);

		while ((perk = (++iter).Perk()))
			if (perk.Good == bBeGood && perk.IsAptFor(client, iRollFlags))
			{
				list.Push(perk);

#if defined DEBUG
				char sName[64];
				perk.GetName(sName, sizeof(sName));
				PrintToServer("> %s", sName);
#endif
			}
	}

	delete iter;
	delete candidates;

	perk = list.GetRandom();
	delete list;

	return perk;
}

void ApplyPerk(const int client, Perk perk, const int iPerkTime=-1)
{
	if (!IsValidClient(client))
		return;

	// Save player class for the duration of the perk, specifically until the next one is applied
	Shared[client].ClassForPerk = TF2_GetPlayerClass(client);

	perk.EmitSound(client);
	ManagePerk(client, perk, true);

	g_hPerkHistory.Push(perk.Id);

	int iDuration = -1;
	int iTime = perk.Time;
	if (iTime > -1)
	{
		iDuration = (iPerkTime > -1) ? iPerkTime : (iTime > 0) ? iTime : g_iCvarPerkDuration;

		g_hRollers.SetInRoll(client, true);
		g_hRollers.SetPerk(client, perk);
		g_hRollers.SetUnconsumedAddedTime(client, 0);
		g_hRollers.SetEndRollTime(client, GetTime() + iDuration);

		Handle hTimer = CreateTimer(1.0, Timer_PerkRunTick, GetClientUserId(client), TIMER_REPEAT);
		g_hRollers.SetTimer(client, hTimer);

		DisplayPerkTimeFrame(client);
	}
	else
	{
		g_hRollers.SetLastRollTime(client, GetTime());
	}

	Forward_PerkApplied(client, perk, iDuration);
	g_hRollers.PushToPerkHistory(client, perk);

	PrintToRoller(client, perk, iDuration);
	PrintToNonRollers(client, perk, iDuration);
}

void ManagePerk(const int client, const Perk perk, const bool bEnable, const RTDRemoveReason reason=RTDRemove_WearOff, const char[] sReason="")
{
	if (perk.External)
	{
		perk.Call(client, bEnable);
	}
	else
	{
		perk.CallInternal(client, bEnable);
	}

	int iSubscribesToEntitySpawned = view_as<int>(Events.SubscribesToEntitySpawned(perk));

	if (bEnable)
	{
		perk.IncrementActiveCount(client);

		g_iActiveEntitySpawnedSubscribers += iSubscribesToEntitySpawned;
	}
	else
	{
		Cache[client].Cleanup();
		perk.DecrementActiveCount(client);

		RemovedPerk(client, reason, sReason);

		g_iActiveEntitySpawnedSubscribers -= iSubscribesToEntitySpawned;
	}
}

Menu BuildDescriptionMenu(const int client)
{
	Menu hMenu = new Menu(ManagerDescriptionMenu);
	hMenu.SetTitle("%T", "RTD2_Menu_Title", client);

	char sPerkName[RTD2_MAX_PERK_NAME_LENGTH], sPerkToken[32];
	PerkIter iter = new PerkContainerIter(-1);
	Perk perk = null;

	while ((perk = (++iter).Perk()))
	{
		perk.GetToken(sPerkToken, sizeof(sPerkToken));
		perk.GetName(sPerkName, sizeof(sPerkName));
		hMenu.AddItem(sPerkToken, sPerkName);
	}

	delete iter;

	hMenu.ExitBackButton = false;
	hMenu.ExitButton = true;

	return hMenu;
}

void ShowDescriptionMenu(const int client, const int iPos=0)
{
	if (iPos == 0)
	{
		BuildDescriptionMenu(client).Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		BuildDescriptionMenu(client).DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
	}
}

public int ManagerDescriptionMenu(Menu hMenu, MenuAction maState, const int client, const int iPos)
{
	switch (maState)
	{
		case MenuAction_Select: { /* fallthrough */ }

		case MenuAction_End:
		{
			delete hMenu;
			return 0;
		}

		default:
			return 0;
	}

	Perk perk = null;
	char sPerkToken[32], sPerkName[RTD2_MAX_PERK_NAME_LENGTH], sTranslate[64];

	hMenu.GetItem(iPos, sPerkToken, sizeof(sPerkToken));
	perk = g_hPerkContainer.Get(sPerkToken);
	perk.GetName(sPerkName, sizeof(sPerkName));
	FormatEx(sTranslate, sizeof(sTranslate), "RTD2_Desc_%s", sPerkToken);

	RTDPrint(client, "%s%s%c: \x03%t\x01",
		perk.Good ? PERK_COLOR_GOOD : PERK_COLOR_BAD,
		sPerkName, 0x01,
		sTranslate);

	ShowDescriptionMenu(client, iPos);
	return 1;
}

public Action Timer_PerkRunTick(Handle hTimer, const int iUserId)
{
	int client = GetClientOfUserId(iUserId);
	if (!client)
		return Plugin_Stop;

	if (!g_hRollers.GetInRoll(client))
		return Plugin_Stop;

	if (GetTime() >= g_hRollers.GetEndRollTime(client))
	{
		ManagePerk(client, g_hRollers.GetPerk(client), false);
		return Plugin_Stop;
	}

	DisplayPerkTimeFrame(client);
	return Plugin_Continue;
}

void FormatRemoveReasonLog(char[] sBuffer, const int iBufferLen, const RTDRemoveReason reason, const char[] sReason)
{
	int iWritten = 0;

	switch (reason)
	{
	case RTDRemove_PluginUnload:
		iWritten = strcopy(sBuffer, iBufferLen, "(plugin unloaded)");

	case RTDRemove_Death:
		iWritten = strcopy(sBuffer, iBufferLen, "(client died)");

	case RTDRemove_ClassChange:
		iWritten = strcopy(sBuffer, iBufferLen, "(client changed class)");

	case RTDRemove_WearOff:
		iWritten = strcopy(sBuffer, iBufferLen, "(perk has worn off)");

	case RTDRemove_Disconnect:
		iWritten = strcopy(sBuffer, iBufferLen, "(client disconnected)");

	case RTDRemove_Custom:
		iWritten = strcopy(sBuffer, iBufferLen, "(custom reason)");

	case RTDRemove_NoPrint:
		iWritten = strcopy(sBuffer, iBufferLen, "(internal reason)");

	default: // should never happen
		iWritten = strcopy(sBuffer, iBufferLen, "(unknown reason)");
	}

	if (StrEqual(sReason, ""))
		return;

	// `-1` to overwrite the closing bracket
	Format(sBuffer[iWritten - 1], iBufferLen, ": %s)", sReason);
}

Perk RemovePerk(const int client, const RTDRemoveReason reason=RTDRemove_WearOff, const char[] sReason="")
{
	Perk perk = g_hRollers.GetPerk(client);
	if (perk != null)
		ManagePerk(client, perk, false, reason, sReason);

	return perk;
}

Perk ForceRemovePerk(const int client, const RTDRemoveReason reason=RTDRemove_WearOff, const char[] sReason="", const int iInitiator=0)
{
	if (!IsValidClient(client))
		return null;

	Perk perk = RemovePerk(client, reason, sReason);

	if (!(g_iCvarLogging & view_as<int>(LogFlag_Action)))
		return perk;

	char sBuffer[64];
	perk.Format(sBuffer, sizeof(sBuffer), "$Name$ ($Token$)");

	char sReasonLog[128];
	FormatRemoveReasonLog(sReasonLog, sizeof(sReasonLog), reason, sReason);

	if (IsValidClient(iInitiator))
	{
		LogAction(iInitiator, client, "\"%L\" removed %s from \"%L\" %s", iInitiator, sBuffer, client, sReasonLog);
	}
	else
	{
		LogAction(-1, client, "%s was removed from \"%L\" %s", sBuffer, client, sReasonLog);
	}

	return perk;
}

void RemovedPerk(int client, RTDRemoveReason reason, const char[] sReason="")
{
	Perk perk = g_hRollers.GetPerk(client);

	if (g_iCvarLogging & view_as<int>(LogFlag_PerkRemove))
	{
		char sBuffer[64];
		perk.Format(sBuffer, sizeof(sBuffer), "$Name$ ($Token$)");
		LogMessage("Perk %s ended on %L", sBuffer, client);
	}

	g_hRollers.SetInRoll(client, false);
	g_hRollers.SetLastRollTime(client, GetTime());

	Forward_PerkRemoved(client, perk, reason);
	g_hRollers.SetPerk(client, null);

	if (reason != RTDRemove_NoPrint)
		PrintPerkEndReason(client, reason, sReason);
}

void PrintToRoller(int client, Perk perk, int iDuration)
{
	if (!(g_iCvarChat & view_as<int>(ChatFlag_AppRoller)))
		return;

	char sPerkName[RTD2_MAX_PERK_NAME_LENGTH];
	perk.GetName(sPerkName, sizeof(sPerkName));

	if (!g_bCvarShowTime || perk.Time == -1)
	{
		RTDPrint(client, "%t",
			"RTD2_Rolled_Perk_Roller",
			perk.Good ? PERK_COLOR_GOOD : PERK_COLOR_BAD,
			sPerkName,
			0x01);
	}
	else
	{
		RTDPrint(client, "%t",
			"RTD2_Rolled_Perk_Roller_Time",
			perk.Good ? PERK_COLOR_GOOD : PERK_COLOR_BAD,
			sPerkName,
			0x01, 0x03, GetPerkTimeEx(perk, iDuration), 0x01);
	}

	if (g_hCvarShowDesc.BoolValue)
	{
		char sPerkToken[32], sPerkDesc[64];
		perk.GetToken(sPerkToken, sizeof(sPerkToken));
		FormatEx(sPerkDesc, sizeof(sPerkDesc), "RTD2_Desc_%s", sPerkToken);
		RTDPrint(client, "\x03%t\x01", sPerkDesc);
	}
}

void PrintToNonRollers(int client, Perk perk, int iDuration)
{
	if (!(g_iCvarChat & view_as<int>(ChatFlag_AppOther)))
		return;

	char sRollerName[MAX_NAME_LENGTH], sPerkName[RTD2_MAX_PERK_NAME_LENGTH];
	GetClientName(client, sRollerName, sizeof(sRollerName));
	perk.GetName(sPerkName, sizeof(sPerkName));

	if (!g_bCvarShowTime || perk.Time == -1)
	{
		RTDPrintAllExcept(client, "%t",
			"RTD2_Rolled_Perk_Others",
			g_sTeamColors[GetClientTeam(client)],
			sRollerName,
			0x01,
			perk.Good ? PERK_COLOR_GOOD : PERK_COLOR_BAD,
			sPerkName, 0x01);
	}
	else
	{
		RTDPrintAllExcept(client, "%t",
			"RTD2_Rolled_Perk_Others_Time",
			g_sTeamColors[GetClientTeam(client)],
			sRollerName,
			0x01,
			perk.Good ? PERK_COLOR_GOOD : PERK_COLOR_BAD,
			sPerkName, 0x01, 0x03, GetPerkTimeEx(perk, iDuration), 0x01);
	}
}

void PrintPerkEndReason(int client, RTDRemoveReason reason=RTDRemove_WearOff, const char[] sCustomReason="")
{
	char sReasonSelf[32], sReasonOthers[32];
	switch (reason)
	{
		case RTDRemove_PluginUnload:
		{
			strcopy(sReasonSelf, sizeof(sReasonSelf), "RTD2_Remove_Perk_Unload_Self");
			strcopy(sReasonOthers, sizeof(sReasonOthers), "RTD2_Remove_Perk_Unload_Others");
		}

		case RTDRemove_Death:
		{
			strcopy(sReasonSelf, sizeof(sReasonSelf), "RTD2_Remove_Perk_Died_Self");
			strcopy(sReasonOthers, sizeof(sReasonOthers), "RTD2_Remove_Perk_Died_Others");
		}

		case RTDRemove_ClassChange:
		{
			strcopy(sReasonSelf, sizeof(sReasonSelf), "RTD2_Remove_Perk_Class_Self");
			strcopy(sReasonOthers, sizeof(sReasonOthers), "RTD2_Remove_Perk_Class_Others");
		}

		case RTDRemove_WearOff:
		{
			strcopy(sReasonSelf, sizeof(sReasonSelf), "RTD2_Remove_Perk_End_Self");
			strcopy(sReasonOthers, sizeof(sReasonOthers), "RTD2_Remove_Perk_End_Others");
		}

		case RTDRemove_Disconnect:
		{
			strcopy(sReasonSelf, sizeof(sReasonSelf), "0");
			strcopy(sReasonOthers, sizeof(sReasonOthers), "RTD2_Remove_Perk_Disconnected");
		}

		case RTDRemove_Custom:
		{
			strcopy(sReasonSelf, sizeof(sReasonSelf), "RTD2_Remove_Perk_Custom_Self");
			strcopy(sReasonOthers, sizeof(sReasonOthers), "RTD2_Remove_Perk_Custom_Others");
		}
	}

	if (sReasonSelf[0] != '0' && (g_iCvarChat & view_as<int>(ChatFlag_RemRoller)))
		RTDPrint(client, "%t", sReasonSelf, reason == RTDRemove_Custom ? sCustomReason : "");

	if (g_iCvarChat & view_as<int>(ChatFlag_RemOther))
		RTDPrintAllExcept(client, "%t", sReasonOthers, g_sTeamColors[GetClientTeam(client)], client, 0x01, reason == RTDRemove_Custom ? sCustomReason : "");
}

void Forward_PerkApplied(int client, Perk perk, int iDuration)
{
	if (GetForwardFunctionCount(g_hFwdRolled) < 1)
		return;

	Call_StartForward(g_hFwdRolled);
	Call_PushCell(client);
	Call_PushCell(perk.Id);
	Call_PushCell(iDuration);
	Call_Finish();
}

void Forward_PerkRemoved(int client, Perk perk, RTDRemoveReason reason)
{
	if (GetForwardFunctionCount(g_hFwdRemoved) < 1)
		return;

	Call_StartForward(g_hFwdRemoved);
	Call_PushCell(client);
	Call_PushCell(perk.Id);
	Call_PushCell(reason);
	Call_Finish();
}

void Forward_OnRegOpen()
{
	if (GetForwardFunctionCount(g_hFwdOnRegOpen) < 1)
		return;

	Call_StartForward(g_hFwdOnRegOpen);
	Call_Finish();
}

bool IsInPerkHistory(Perk perk)
{
	return perk.IsInHistory(g_hPerkHistory, g_iCvarRepeatPerk);
}

bool IsInClientHistory(int client, Perk perk)
{
	return g_hRollers.IsInPerkHistory(client, perk, g_iCvarRepeatPlayer);
}

void RTDPrint(const int client, const char[] sFormat, any ...)
{
	char sBuffer[254];

	SetGlobalTransTarget(client);
	VFormat(sBuffer, sizeof(sBuffer), sFormat, 3);

	if (IsValidClient(client))
	{
		PrintToChat(client, CHAT_PREFIX ... " %s", sBuffer);
	}
	else
	{
		PrintToServer(CONS_PREFIX ... " %s", sBuffer);
	}
}

void RTDPrintAll(const char[] sFormat, any ...)
{
	char sBuffer[254];

	for (int i = 1; i <= MaxClients; ++i)
	{
		if (!IsClientInGame(i))
			continue;

		SetGlobalTransTarget(i);
		VFormat(sBuffer, sizeof(sBuffer), sFormat, 2);

		PrintToChat(i, CHAT_PREFIX ... " %s", sBuffer);
	}
}

void RTDPrintAllExcept(const int client, const char[] sFormat, any ...)
{
	char sBuffer[254];
	int i = 0;

	while (++i < client)
	{
		if (!IsClientInGame(i))
			continue;

		SetGlobalTransTarget(i);
		VFormat(sBuffer, sizeof(sBuffer), sFormat, 3);

		PrintToChat(i, CHAT_PREFIX ... " %s", sBuffer);
	}

	while (++i <= MaxClients)
	{
		if (!IsClientInGame(i))
			continue;

		SetGlobalTransTarget(i);
		VFormat(sBuffer, sizeof(sBuffer), sFormat, 3);

		PrintToChat(i, CHAT_PREFIX ... " %s", sBuffer);
	}
}

void DisplayPerkTimeFrame(const int client)
{
	int iTeam = GetClientTeam(client);
	int iRed = (iTeam == 2) ? 255 : 32;
	int iBlue = (iTeam == 3) ? 255 : 32;

	int iRemainingTime = g_hRollers.GetEndRollTime(client) - GetTime();
	int iAddedTime = g_hRollers.GetUnconsumedAddedTime(client);
	g_hRollers.SetUnconsumedAddedTime(client, 0);

	char sPerkName[RTD2_MAX_PERK_NAME_LENGTH];
	g_hRollers.GetPerk(client).GetName(sPerkName, sizeof(sPerkName));

	SetHudTextParams(g_fCvarTimerPosX, g_fCvarTimerPosY, 1.0, iRed, 32, iBlue, 255);

	if (iAddedTime == 0)
	{
		ShowSyncHudText(client, g_hRollers.GetHud(client), "%s: %d\n", sPerkName, iRemainingTime);
	}
	else if (iAddedTime > 0)
	{
		ShowSyncHudText(client, g_hRollers.GetHud(client), "%s: %d\n(+%d)", sPerkName, iRemainingTime, iAddedTime);
	}
	else
	{
		ShowSyncHudText(client, g_hRollers.GetHud(client), "%s: %d\n(-%d)", sPerkName, iRemainingTime, -iAddedTime);
	}
}

int GetPerkTimeEx(Perk perk, const int iCustomTime)
{
	if (iCustomTime != -1)
		return iCustomTime;

	int iTime = perk.Time;
	return (iTime > 0) ? iTime : g_iCvarPerkDuration;
}

int GetPerkTime(Perk perk)
{
	return GetPerkTimeEx(perk, g_iLastPerkTime);
}

float GetPerkTimeFloat(Perk perk)
{
	return float(GetPerkTime(perk));
}

bool IsRecentPerk(const int client, const Perk perk, const int iTimeDelta=2)
{
	Perk current = g_hRollers.GetPerk(client);
	if (current == perk) // current counts as recent
		return true;

	if (current != null) // client in different perk
		return false;

	if (!g_hRollers.IsInPerkHistory(client, perk, 1))
		return false;

	return GetTime() - g_hRollers.GetLastRollTime(client) <= iTimeDelta;
}

void RemovePerkFromClients(Perk perk)
{
	for (int i = 1; i <= MaxClients; ++i)
		if (IsClientInGame(i) && g_hRollers.GetPerk(i) == perk)
			ForceRemovePerk(i);
}

void DisableModulePerks(Handle hPlugin)
{
	Perk perk = null;
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (!IsClientInGame(i))
			continue;

		perk = g_hRollers.GetPerk(i);
		if(perk && perk.External && perk.Parent == hPlugin)
			perk.Call(i, false);
	}

	PerkIter iter = new PerkContainerIter(-1);

	while ((perk = (++iter).Perk()))
	{
		if (perk.External && perk.Parent == hPlugin)
		{
			perk.Enabled = perk.Id < g_iCorePerks; // disable if external
			perk.External = false; // set perk to unaltered call
		}
	}

	delete iter;
}

int ReadFlagFromConVar(Handle hCvar)
{
	char sBuffer[32];
	GetConVarString(hCvar, sBuffer, sizeof(sBuffer));
	return ReadFlagString(sBuffer);
}

void FixPotentialStuck(int client)
{
	if (g_bCvarRespawnStuck && IsValidClient(client))
		CreateTimer(0.1, Timer_FixStuck, GetClientUserId(client));
}

public Action Timer_FixStuck(Handle hTimer, int iUserId)
{
	int client = GetClientOfUserId(iUserId);
	if (client == 0)
		return Plugin_Stop;

	if (!IsPlayerAlive(client))
		return Plugin_Stop;

	if (!IsEntityStuck(client))
		return Plugin_Stop;

	RTDPrint(client, "%t", "RTD2_Stuck_Respawn");
	TF2_RespawnPlayer(client);

	return Plugin_Stop;
}

bool IsArgumentTrigger(const char[] sArg)
{
	char sTrigger[16];
	for (int i = 0; i < g_iCvarTriggers; i++)
	{
		GetArrayString(g_arrCvarTriggers, i, sTrigger, 16);
		if (StrEqual(sArg, sTrigger, false))
			return true;
	}

	return false;
}

bool IsRollerAllowed(int client)
{
	if (g_iCvarAllowed > 0)
		return view_as<bool>(GetUserFlagBits(client) & g_iCvarAllowed);

	return true;
}

bool IsRollerDonator(int client)
{
	if(g_iCvarDonatorFlag > 0)
		return view_as<bool>(GetUserFlagBits(client) & g_iCvarDonatorFlag);

	return false;
}

// `stock` to suppress unused parameter when neither Friendly or FriendlySimple are present.
stock bool IsPlayerFriendly(const int client)
{
#if defined _friendly_included
	if (g_bPluginFriendly)
		if (TF2Friendly_IsFriendly(client))
			return true;
#endif

#if defined _friendlysimple_included
	if (g_bPluginFriendlySimple)
		if (FriendlySimple_IsFriendly(client))
			return true;
#endif

	return false;
}

bool IsRTDInRound()
{
	if (GameRules_GetProp("m_bInWaitingForPlayers", 1))
		return false;

	if (!g_bCvarInSetup)
	{
		if (g_bIsGameArena && GameRules_GetRoundState() != view_as<RoundState>(7))
			return false;

		if (GameRules_GetProp("m_bInSetup", 1))
			return false;
	}

	return true;
}

bool CanPlayerBeHurt(int client, int by=0, bool bCanHurtSelf=false)
{
	if (IsValidClient(by))
	{
		if (GetClientTeam(by) == GetClientTeam(client))
			if (client != by || !bCanHurtSelf)
				return false;
	}

	if (IsPlayerFriendly(client))
		return false;

	if (TF2_IsPlayerInCondition(client, TFCond_Ubercharged) || TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen))
		return false;

	if (GetEntProp(client, Prop_Data, "m_takedamage") != 2)
		return false;

	if (g_eInGodmode.Test(client))
		return false;

	return true;
}
