/**
* Main RTD source file.
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
#pragma semicolon 1

/****** M A C R O S *****/

#define KILL_ENT_IN(%1,%2) \
	SetVariantString("OnUser1 !self:Kill::" ... #%2 ... ":1"); \
	AcceptEntityInput(%1, "AddOutput"); \
	AcceptEntityInput(%1, "FireUser1");


/****** I N C L U D E S *****/

#include <rtd2>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2attributes>

#undef REQUIRE_PLUGIN
#include <updater>
#include <friendly>
#include <friendlysimple>

#include "rtd/includes.sp"


/******* D E F I N E S ******/

#define PLUGIN_VERSION	"2.1.0"

#define CHAT_PREFIX 	"\x07FFD700[RTD]\x01"
#define CONS_PREFIX 	"[RTD]"

#define CHAT_AD			1
#define CHAT_APPROLLER	2
#define CHAT_APPOTHER	4
#define CHAT_REMROLLER	8
#define CHAT_REMOTHER	16
#define CHAT_REASONS	32

#define PERK_COLOR_GOOD	"\x0732CD32"
#define PERK_COLOR_BAD	"\x078650AC"

#define FLAG_FEIGNDEATH	(1 << 5)
#define FLAGS_CVARS		FCVAR_NOTIFY

#define LASERBEAM		"sprites/laserbeam.vmt"

#define UPDATE_URL		"https://phil25.github.io/RTD/update.txt"



/********* E N U M S ********/

Rollers g_hRollers = null;


/********* M A N A G E R ********/

#include "rtd/manager.sp" //For info, go to the script itself



/***** V A R I A B L E S ****/

char	g_sTeamColors[][]		= {"\x07B2B2B2", "\x07B2B2B2", "\x07FF4040", "\x0799CCFF"};

bool	g_bPluginUpdater		= false;
bool	g_bPluginFriendly		= false;
bool	g_bPluginFriendlySimple	= false;

bool	g_bIsRegisteringOpen	= false;
bool	g_bIsUpdateForced		= false;

Menu	g_hDescriptionMenu		= null;
ArrayList g_hPerkHistory		= null;
int		g_iCorePerks			= 0;

bool	g_bIsGameArena			= false;
int		g_iLastPerkTime			= -1;



/***** C O N V A R S ****/

Handle g_hCvarPluginEnabled;		bool g_bCvarPluginEnabled = true;
#define DESC_PLUGIN_ENABLED "0/1 - Enable or disable the plugin."
Handle g_hCvarAutoUpdate;			bool g_bCvarAutoUpdate = true;
#define DESC_AUTO_UPDATE "0/1 - Enable or disable automatic updating of the plugin when Updater is installed."
Handle g_hCvarReloadUpdate;			bool g_bCvarReloadUpdate = true;
#define DESC_RELOAD_UPDATE "0/1 - Enable or disable automatic plugin reloading when a new version has been downloaded."
Handle g_hCvarLog;					bool g_bCvarLog = false;
#define DESC_LOG "0/1 - Log RTD actions to SourceMod logs?"
Handle g_hCvarChat;					int g_iCvarChat = 63;
#define DESC_CHAT "Add/substract these values to control messages:\n1 - RTD ad (round start)\n2 - Perk applic. for rollers\n4 - P. applic. for others\n8 - P. removal for rollers\n16 - P. removal for others\n32 - Can't-roll reasons\nEXAMPLE: \"6\" - show applications only (2 + 4)"

Handle g_hCvarPerkDuration;			int g_iCvarPerkDuration = 25;
#define DESC_PERK_DURATION "Default time for the perk to last. This value can be overridden for any perk in rtd2_perks.cfg"
Handle g_hCvarRollInterval;			int g_iCvarRollInterval = 60;
#define DESC_ROLL_INTERVAL "Time in seconds a client has to wait to roll again after a perk has finished."
Handle g_hCvarDisabledPerks;
#define DESC_DISABLED_PERKS "Enter the effects you'd like to disable, seperated by commas. You can use IDs, tokens or tags which occur in a single perk. ('0, toxic, sandvich' disables first 3)"

Handle g_hCvarAllowed;				int g_iCvarAllowed = 0;
#define DESC_ALLOWED "Admin flags which are required to use RTD. If blank, all is assumed."
Handle g_hCvarInSetup;				bool g_bCvarInSetup = true;
#define DESC_IN_SETUP "0/1 - Can RTD be used during Setup?"
Handle g_hCvarTriggers;				Handle g_arrCvarTriggers = INVALID_HANDLE;	int g_iCvarTriggers = 2;
#define DESC_TRIGGERS "Chat triggers which will initiate rolls, seperated by comma."
Handle g_hCvarShowTriggers;			bool g_bCvarShowTriggers = false;
#define DESC_SHOW_TRIGGERS "0/1 - Should the chat triggers be shown once they're typed?"
Handle g_hCvarShowTime;				bool g_bCvarShowTime = false;
#define DESC_SHOW_TIME "0/1 - Should time the perk was applied for be displayed?"

Handle g_hCvarRtdTeam;				int g_iCvarRtdTeam = 0;
#define DESC_RTD_TEAM "0 - both teams can roll, 1 - only RED team can roll, 2 - only BLU team can roll."
Handle g_hCvarRtdMode;				int g_iCvarRtdMode = 0;
#define DESC_RTD_MODE "0 - No restrain except the interval, 1 - Limit by rollers, 2 - Limit by rollers in team."
Handle g_hCvarClientLimit;			int g_iCvarClientLimit = 2;
#define DESC_CLIENT_LIMIT "How many players could use RTD at once. Active only when RTD Mode is 1"
Handle g_hCvarTeamLimit;			int g_iCvarTeamLimit = 2;
#define DESC_TEAM_LIMIT "How many players in each team could use RTD at once. Active only when RTD Mode is 2"
Handle g_hCvarRespawnStuck;			bool g_bCvarRespawnStuck = true;
#define DESC_RESPAWN_STUCK "0/1 - Should a player be forcibly respawned when a perk has ended and he's detected stuck?"

Handle g_hCvarRepeatPlayer;			int g_iCvarRepeatPlayer = 2;
#define DESC_REPEAT_PLAYER			"How many perks are NOT allowed to repeat, per player."
Handle g_hCvarRepeatPerk;			int g_iCvarRepeatPerk = 2;
#define DESC_REPEAT_PERK			"How many perks are NOT allowed to repeat, per perk."

Handle g_hCvarGoodChance;			float g_fCvarGoodChance = 0.5;
#define DESC_GOOD_CHANCE "0.0-1.0 - Chance of rolling a good perk. If there are no good perks available, a bad one will be tried to be rolled instead."
Handle g_hCvarGoodDonatorChance;	float g_fCvarGoodDonatorChance = 0.5;
#define DESC_GOOD_DONATOR_CHANCE "0.0-1.0 - Chance of rolling a good perk if roller is a donator. If there are no good perks available, a bad one will be tried to roll instead."
Handle g_hCvarDonatorFlag;			int g_iCvarDonatorFlag = 0;
#define DESC_DONATOR_FLAG "Admin flag required for donators."

Handle g_hCvarTimerPosX;			float g_fCvarTimerPosX = -1.0;
#define DESC_TIMER_POS_X "0.0-1.0 - The X position of the perk HUD timer display. -1.0 to center."
Handle g_hCvarTimerPosY;			float g_fCvarTimerPosY = 0.55;
#define DESC_TIMER_POS_Y "0.0-1.0 - The Y position of the perk HUD timer display. -1.0 to center."



/***** F O R W A R D S ****/

Handle g_hFwdCanRoll;
Handle g_hFwdCanForce;
Handle g_hFwdCanRemove;
Handle g_hFwdRolled;
Handle g_hFwdRemoved;
Handle g_hFwdOnRegOpen;



/********** I N F O *********/

public Plugin myinfo = {
	name = "Roll The Dice (Revamped)",
	author = "Phil25",
	description = "Lets players roll for temporary benefits.",
	version	= PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=278579"
};



			//*************************//
			//----  G E N E R A L  ----//
			//*************************//

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrorSize){
	char sGame[32]; sGame[0] = '\0';
	GetGameFolderName(sGame, sizeof(sGame));
	if(!StrEqual(sGame, "tf")){
		Format(sError, iErrorSize, CONS_PREFIX ... " This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}

	CreateNatives();
	RegPluginLibrary("RollTheDice2");

	return APLRes_Success;
}

public void OnPluginStart(){
	LoadTranslations("rtd2.phrases.txt");
	LoadTranslations("rtd2_perks.phrases.txt");
	LoadTranslations("common.phrases.txt");

	if(!ParseEffects())
		return;

	ParseCustomEffects();

		//-----[ ConVars ]-----//
	CreateConVar("sm_rtd2_version", PLUGIN_VERSION, "Current RTD2 Version", FLAGS_CVARS|FCVAR_DONTRECORD|FCVAR_SPONLY);

	g_hCvarPluginEnabled		= CreateConVar("sm_rtd2_enabled",		"1",		DESC_PLUGIN_ENABLED,		FLAGS_CVARS);
	g_hCvarAutoUpdate			= CreateConVar("sm_rtd2_autoupdate",	"1",		DESC_AUTO_UPDATE,			FLAGS_CVARS);
	g_hCvarReloadUpdate			= CreateConVar("sm_rtd2_reloadupdate",	"1",		DESC_RELOAD_UPDATE,			FLAGS_CVARS);
	g_hCvarLog					= CreateConVar("sm_rtd2_log",			"0",		DESC_LOG,					FLAGS_CVARS);
	g_hCvarChat					= CreateConVar("sm_rtd2_chat",			"63",		DESC_CHAT,					FLAGS_CVARS);

	g_hCvarPerkDuration			= CreateConVar("sm_rtd2_duration",		"25",		DESC_PERK_DURATION,			FLAGS_CVARS);
	g_hCvarRollInterval			= CreateConVar("sm_rtd2_interval",		"60",		DESC_ROLL_INTERVAL,			FLAGS_CVARS);
	g_hCvarDisabledPerks		= CreateConVar("sm_rtd2_disabled",		"",			DESC_DISABLED_PERKS,		FLAGS_CVARS);

	g_hCvarAllowed				= CreateConVar("sm_rtd2_accessflags",	"",			DESC_ALLOWED,				FLAGS_CVARS);
	g_hCvarInSetup				= CreateConVar("sm_rtd2_insetup",		"0",		DESC_IN_SETUP,				FLAGS_CVARS, true, 0.0, true, 1.0);
	g_hCvarTriggers				= CreateConVar("sm_rtd2_triggers",		"rtd,roll",	DESC_TRIGGERS,				FLAGS_CVARS);
	g_hCvarShowTriggers			= CreateConVar("sm_rtd2_showtriggers",	"0",		DESC_SHOW_TRIGGERS,			FLAGS_CVARS, true, 0.0, true, 1.0);
	g_hCvarShowTime				= CreateConVar("sm_rtd2_showtime",		"0",		DESC_SHOW_TIME,				FLAGS_CVARS, true, 0.0, true, 1.0);

	g_hCvarRtdTeam				= CreateConVar("sm_rtd2_team",			"0",		DESC_RTD_TEAM,				FLAGS_CVARS, true, 0.0, true, 2.0);
	g_hCvarRtdMode				= CreateConVar("sm_rtd2_mode",			"0",		DESC_RTD_MODE,				FLAGS_CVARS, true, 0.0, true, 2.0);
	g_hCvarClientLimit			= CreateConVar("sm_rtd2_playerlimit",	"2",		DESC_CLIENT_LIMIT,			FLAGS_CVARS, true, 0.0);
	g_hCvarTeamLimit			= CreateConVar("sm_rtd2_teamlimit",		"2",		DESC_TEAM_LIMIT,			FLAGS_CVARS, true, 0.0);
	g_hCvarRespawnStuck			= CreateConVar("sm_rtd2_respawnstuck",	"1",		DESC_RESPAWN_STUCK,			FLAGS_CVARS, true, 0.0, true, 1.0);

	g_hCvarRepeatPlayer			= CreateConVar("sm_rtd2_repeat_player", "2",		DESC_REPEAT_PLAYER,			FLAGS_CVARS, true, 0.0, true, 6.0);
	g_hCvarRepeatPerk			= CreateConVar("sm_rtd2_repeat_perk",	"2",		DESC_REPEAT_PERK,			FLAGS_CVARS, true, 0.0, true, 6.0);

	g_hCvarGoodChance			= CreateConVar("sm_rtd2_chance",		"0.5",		DESC_GOOD_CHANCE,			FLAGS_CVARS, true, 0.0, true, 1.0);
	g_hCvarGoodDonatorChance	= CreateConVar("sm_rtd2_dchance",		"0.75",		DESC_GOOD_DONATOR_CHANCE,	FLAGS_CVARS, true, 0.0, true, 1.0);
	g_hCvarDonatorFlag			= CreateConVar("sm_rtd2_donatorflag",	"",			DESC_DONATOR_FLAG,			FLAGS_CVARS);

	g_hCvarTimerPosX			= CreateConVar("sm_rtd2_timerpos_x",	"-1.0",		DESC_TIMER_POS_X,			FLAGS_CVARS);
	g_hCvarTimerPosY			= CreateConVar("sm_rtd2_timerpos_y",	"0.55",		DESC_TIMER_POS_Y,			FLAGS_CVARS);


		//-----[ ConVars Hooking & Setting ]-----//
	HookConVarChange(g_hCvarPluginEnabled,		ConVarChange_Plugin	);	g_bCvarPluginEnabled		= GetConVarInt(g_hCvarPluginEnabled) > 0 ? true : false;
	HookConVarChange(g_hCvarAutoUpdate,			ConVarChange_Plugin	);	g_bCvarAutoUpdate			= GetConVarInt(g_hCvarAutoUpdate) > 0 ? true : false;
	HookConVarChange(g_hCvarReloadUpdate,		ConVarChange_Plugin	);	g_bCvarReloadUpdate			= GetConVarInt(g_hCvarReloadUpdate) > 0 ? true : false;
	HookConVarChange(g_hCvarLog,				ConVarChange_Plugin	);	g_bCvarLog					= GetConVarInt(g_hCvarLog) > 0 ? true : false;
	HookConVarChange(g_hCvarChat,				ConVarChange_Plugin	);	g_iCvarChat					= GetConVarInt(g_hCvarChat);

	HookConVarChange(g_hCvarPerkDuration,		ConVarChange_Perks	);	g_iCvarPerkDuration			= GetConVarInt(g_hCvarPerkDuration);
	HookConVarChange(g_hCvarRollInterval,		ConVarChange_Perks	);	g_iCvarRollInterval			= GetConVarInt(g_hCvarRollInterval);
	HookConVarChange(g_hCvarDisabledPerks,		ConVarChange_Perks	);

	HookConVarChange(g_hCvarAllowed,			ConVarChange_Usage	);	g_iCvarAllowed				= ReadFlagFromConVar(g_hCvarAllowed);
	HookConVarChange(g_hCvarInSetup,			ConVarChange_Usage	);	g_bCvarInSetup				= GetConVarInt(g_hCvarInSetup) > 0 ? true : false;
	HookConVarChange(g_hCvarTriggers,			ConVarChange_Usage	);	ParseTriggers();
	HookConVarChange(g_hCvarShowTriggers,		ConVarChange_Usage	);	g_bCvarShowTriggers			= GetConVarInt(g_hCvarShowTriggers) > 0 ? true : false;
	HookConVarChange(g_hCvarShowTime,			ConVarChange_Usage	);	g_bCvarShowTime				= GetConVarInt(g_hCvarShowTime) > 0 ? true : false;

	HookConVarChange(g_hCvarRtdTeam,			ConVarChange_Rtd	);	g_iCvarRtdTeam				= GetConVarInt(g_hCvarRtdTeam);
	HookConVarChange(g_hCvarRtdMode,			ConVarChange_Rtd	);	g_iCvarRtdMode				= GetConVarInt(g_hCvarRtdMode);
	HookConVarChange(g_hCvarClientLimit,		ConVarChange_Rtd	);	g_iCvarClientLimit			= GetConVarInt(g_hCvarClientLimit);
	HookConVarChange(g_hCvarTeamLimit,			ConVarChange_Rtd	);	g_iCvarTeamLimit			= GetConVarInt(g_hCvarTeamLimit);
	HookConVarChange(g_hCvarRespawnStuck,		ConVarChange_Rtd	);	g_bCvarRespawnStuck			= GetConVarInt(g_hCvarRespawnStuck) > 0 ? true : false;

	HookConVarChange(g_hCvarRepeatPlayer,		ConVarChange_Repeat	);	g_iCvarRepeatPlayer			= GetConVarInt(g_hCvarRepeatPlayer);
	HookConVarChange(g_hCvarRepeatPerk,			ConVarChange_Repeat	);	g_iCvarRepeatPerk			= GetConVarInt(g_hCvarRepeatPerk);

	HookConVarChange(g_hCvarGoodChance,			ConVarChange_Good	);	g_fCvarGoodChance			= GetConVarFloat(g_hCvarGoodChance);
	HookConVarChange(g_hCvarGoodDonatorChance,	ConVarChange_Good	);	g_fCvarGoodDonatorChance	= GetConVarFloat(g_hCvarGoodDonatorChance);
	HookConVarChange(g_hCvarDonatorFlag,		ConVarChange_Good	);	g_iCvarDonatorFlag			= ReadFlagFromConVar(g_hCvarDonatorFlag);

	HookConVarChange(g_hCvarTimerPosX,			ConVarChange_Timer	);	g_fCvarTimerPosX			= GetConVarFloat(g_hCvarTimerPosX);
	HookConVarChange(g_hCvarTimerPosY,			ConVarChange_Timer	);	g_fCvarTimerPosY			= GetConVarFloat(g_hCvarTimerPosY);

	AutoExecConfig(true);


		//-----[ Forwards ]-----//
	g_hFwdCanRoll	= CreateGlobalForward("RTD2_CanRollDice",	ET_Event, Param_Cell						);
	g_hFwdCanForce	= CreateGlobalForward("RTD2_CanForcePerk",	ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFwdCanRemove	= CreateGlobalForward("RTD2_CanRemovePerk",	ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFwdRolled	= CreateGlobalForward("RTD2_Rolled",		ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFwdRemoved	= CreateGlobalForward("RTD2_Removed",		ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFwdOnRegOpen	= CreateGlobalForward("RTD2_OnRegOpen",		ET_Ignore									);


		//-----[ Commands ]-----//
	RegAdminCmd("sm_rtd",		Command_RTD,			0,				"Roll a perk.");
	RegAdminCmd("sm_perks",		Command_DescMenu,		0,				"Display a description menu of RTD perks.");

	RegAdminCmd("sm_forcertd",	Command_ForceRTD,		ADMFLAG_SLAY,	"Applies perk to selected player(s).");
	RegAdminCmd("sm_removertd",	Command_RemoveRTD,		ADMFLAG_SLAY,	"Removes perk from selected player(s).");

	RegAdminCmd("sm_rtds",		Command_PerkSearchup,	ADMFLAG_SLAY,	"Displays customized perk list.");
	RegAdminCmd("sm_rtdsearch",	Command_PerkSearchup,	ADMFLAG_SLAY,	"Displays customized perk list.");

	RegAdminCmd("sm_reloadrtd",	Command_Reload,			ADMFLAG_CONFIG,	"Reloads the config files.");
	RegAdminCmd("sm_updatertd",	Command_Update,			ADMFLAG_ROOT,	"Force an update check. Does nothing if Updater is not installed.");


		//-----[ Listeners ]-----//
	AddCommandListener(Listener_Say,	"say");
	AddCommandListener(Listener_Say,	"say_team");
	AddCommandListener(Listener_Voice,	"voicemenu");

	g_hRollers = new Rollers();
	g_hPerkHistory = new PerkList();

	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			OnClientPutInServer(i);
}

public void OnConfigsExecuted(){
	g_hDescriptionMenu		= BuildDesc();
	g_bIsRegisteringOpen	= true;

	Forward_OnRegOpen();
	ParseDisabledPerks();
}

public void OnPluginEnd(){
	ReloadPluginState();
}

void ReloadPluginState(){
	for(int i = 1; i <= MaxClients; i++){
		if(g_hRollers.GetInRoll(i))
			ForceRemovePerk(i, RTDRemove_PluginUnload);

		g_hRollers.Reset(i);
	}
}

public void OnMapStart(){
	HookEvent("player_death",				Event_PlayerDeath);
	HookEvent("player_changeclass",			Event_ClassChange);
	HookEvent("teamplay_round_active",		Event_RoundActive);
	HookEvent("post_inventory_application",	Event_Resupply, EventHookMode_Post);
	HookEvent("player_hurt",				Event_PlayerHurt);

	PrecacheModel(LASERBEAM);

	Forward_OnMapStart();
	PrecachePerkSounds();

	g_bIsGameArena = (FindEntityByClassname(MaxClients +1, "tf_logic_arena") > MaxClients);
}

public void OnMapEnd(){
	UnhookEvent("player_death",				Event_PlayerDeath);
	UnhookEvent("player_changeclass",		Event_ClassChange);
	UnhookEvent("teamplay_round_active",	Event_RoundActive);
	UnhookEvent("post_inventory_application",Event_Resupply, EventHookMode_Post);
	UnhookEvent("player_hurt",				Event_PlayerHurt);
}

public void OnClientPutInServer(int client){
	g_hRollers.Reset(client);

	if(g_hRollers.GetHud(client) == null)
		g_hRollers.SetHud(client, CreateHudSynchronizer());

	Forward_OnClientPutInServer(client);
}

public void OnClientDisconnect(int client){
	if(g_hRollers.GetInRoll(client))
		ForceRemovePerk(client, RTDRemove_Disconnect);

	g_hRollers.Reset(client);
}

public void OnAllPluginsLoaded(){
	g_bPluginUpdater		= LibraryExists("updater");
	g_bPluginFriendly		= LibraryExists("[TF2] Friendly Mode");
	g_bPluginFriendlySimple	= LibraryExists("Friendly Simple");

	if(g_bPluginUpdater)
		Updater_AddPlugin(UPDATE_URL);
}

public void OnLibraryAdded(const char[] sLibName){
	if(StrEqual(sLibName, "updater")){
		g_bPluginUpdater = true;
		Updater_AddPlugin(UPDATE_URL);
	}

	else if(StrEqual(sLibName, "[TF2] Friendly Mode"))
		g_bPluginFriendly = true;

	else if(StrEqual(sLibName, "Friendly Simple"))
		g_bPluginFriendlySimple = true;
}

public void OnLibraryRemoved(const char[] sLibName){
	if(StrEqual(sLibName, "updater"))
		g_bPluginUpdater = false;

	else if(StrEqual(sLibName, "[TF2] Friendly Mode"))
		g_bPluginFriendly = false;

	else if(StrEqual(sLibName, "Friendly Simple"))
		g_bPluginFriendlySimple = false;
}



			//*************************//
			//----  U P D A T E R  ----//
			//*************************//

public Action Updater_OnPluginChecking(){
	if(!g_bCvarAutoUpdate && !g_bIsUpdateForced)
		return Plugin_Handled;

	g_bIsUpdateForced = false;
	return Plugin_Continue;
}

public int Updater_OnPluginUpdated(){
	if(g_bCvarReloadUpdate)
		ReloadPlugin();
}



			//***************************//
			//----  C O M M A N D S  ----//
			//***************************//

public Action Command_RTD(int client, int args){
	if(client != 0)
		RollPerkForClient(client);

	return Plugin_Handled;
}

public Action Command_DescMenu(int client, int args){
	if(client != 0)
		ShowDesc(client);

	return Plugin_Handled;
}

public Action Command_ForceRTD(int client, int args){
	if(args < 1){
		ReplyToCommand(client, "[SM] Usage: sm_forcertd <player> <perk id>* <time>* <override class restriction (0 / 1)>*");
		return Plugin_Handled;
	}

	char sTrgName[MAX_TARGET_LENGTH], sTrg[32];
	int	 aTrgList[MAXPLAYERS], iTrgCount;
	bool bNameMultiLang;
	GetCmdArg(1, sTrg, sizeof(sTrg));

	if((iTrgCount = ProcessTargetString(sTrg, client, aTrgList, MAXPLAYERS, COMMAND_FILTER_ALIVE, sTrgName, sizeof(sTrgName), bNameMultiLang)) <= 0){
		ReplyToTargetError(client, iTrgCount);
		return Plugin_Handled;
	}

	int iPerkTime = -1;
	char sQuery[32] = "";

	if(args > 1){
		GetCmdArg(2, sQuery, sizeof(sQuery));

		if(args > 2){
			char sPerkTime[8];
			GetCmdArg(3, sPerkTime, sizeof(sPerkTime));
			iPerkTime = StringToInt(sPerkTime);
		}
	}

	for(int i = 0; i < iTrgCount; i++)
		ForcePerk(aTrgList[i], sQuery, iPerkTime, client);

	return Plugin_Handled;
}

public Action Command_RemoveRTD(int client, int args){
	if(args < 1){
		ReplyToCommand(client, "[SM] Usage: sm_removertd <player> <\"reason\">*");
		return Plugin_Handled;
	}

	char sTrgName[MAX_TARGET_LENGTH], sTrg[32];
	int	 aTrgList[MAXPLAYERS], iTrgCount;
	bool bNameMultiLang;
	GetCmdArg(1, sTrg, sizeof(sTrg));

	if((iTrgCount = ProcessTargetString(sTrg, client, aTrgList, MAXPLAYERS, COMMAND_FILTER_ALIVE, sTrgName, sizeof(sTrgName), bNameMultiLang)) <= 0){
		ReplyToTargetError(client, iTrgCount);
		return Plugin_Handled;
	}

	char sReason[128] = "";
	if(args > 1)
		GetCmdArg(2, sReason, sizeof(sReason));

	bool bFuncCount = GetForwardFunctionCount(g_hFwdCanRemove) > 0;
	for(int i = 0; i < iTrgCount; i++){
		if(g_hRollers.GetInRoll(aTrgList[i]) && bFuncCount){
			Call_StartForward(g_hFwdCanRemove);
			Call_PushCell(client);
			Call_PushCell(aTrgList[i]);
			Call_PushCell(g_hRollers.GetPerk(aTrgList[i]).Id);
			Action result = Plugin_Continue;
			Call_Finish(result);

			if(result != Plugin_Continue)
				continue;
		}

		if(g_hRollers.GetInRoll(aTrgList[i]))
			ForceRemovePerk(aTrgList[i], args > 1 ? RTDRemove_Custom : RTDRemove_WearOff, sReason);
	}
	return Plugin_Handled;
}

public Action Command_PerkSearchup(int client, int args){
	char sQuery[64] = "";
	if(args > 0)
		GetCmdArg(1, sQuery, 64);

	char sFormat[64] = "$Id$. $Name$";
	if(args > 1)
		GetCmdArg(2, sFormat, 64);

	PerkList list = g_hPerkContainer.FindPerks(sQuery);
	int iLen = list.Length;

	char sBuffer[1024];
	for(int i = 0; i < iLen; i++){
		list.Get(i).Format(sBuffer, 1024, sFormat);
		PrintToConsole(client, sBuffer);
	}

	RTDPrint(client, "%d perk%s found matching given criteria.", iLen, iLen != 1 ? "s" : "");

	delete list;
	return Plugin_Handled;
}

public Action Command_Reload(int client, int args){
	ReloadPluginState();
	ParseEffects();
	ParseCustomEffects();
	Forward_OnRegOpen();
	return Plugin_Handled;
}

public Action Command_Update(int client, int args){
	if(!g_bPluginUpdater){
		ReplyToCommand(client, CONS_PREFIX ... " Updater is not installed.");
		return Plugin_Handled;
	}

	g_bIsUpdateForced = true;
	if(Updater_ForceUpdate())
		ReplyToCommand(client, CONS_PREFIX ... " New RTD version available!");
	else ReplyToCommand(client, CONS_PREFIX ... " This RTD version is up to date or unable to update.");

	g_bIsUpdateForced = false;
	return Plugin_Handled;
}



			//*****************************//
			//----  L I S T E N E R S  ----//
			//*****************************//

public Action Listener_Say(int client, const char[] sCommand, int args){
	if(!IsValidClient(client))
		return Plugin_Continue;

	char sText[16];
	GetCmdArg(1, sText, sizeof(sText));
	if(!IsArgumentTrigger(sText))
		return Plugin_Continue;

	RollPerkForClient(client);
	return g_bCvarShowTriggers ? Plugin_Continue : Plugin_Stop;
}

public Action Listener_Voice(int client, const char[] sCommand, int args){
	if(IsValidClient(client))
		Forward_Voice(client);

	return Plugin_Continue;
}



			//***********************//
			//----  C O N V A R  ----//
			//***********************//

public int ConVarChange_Plugin(Handle hCvar, const char[] sOld, const char[] sNew){
	if(hCvar == g_hCvarPluginEnabled)
		g_bCvarPluginEnabled = StringToInt(sNew) > 0 ? true : false;

	else if(hCvar == g_hCvarAutoUpdate)
		g_bCvarAutoUpdate = StringToInt(sNew) > 0 ? true : false;

	else if(hCvar == g_hCvarReloadUpdate)
		g_bCvarReloadUpdate = StringToInt(sNew) > 0 ? true : false;

	else if(hCvar == g_hCvarLog)
		g_bCvarLog = StringToInt(sNew) > 0 ? true : false;

	else if(hCvar == g_hCvarChat)
		g_iCvarChat = StringToInt(sNew);
}

public int ConVarChange_Perks(Handle hCvar, const char[] sOld, const char[] sNew){
	if(hCvar == g_hCvarPerkDuration)
		g_iCvarPerkDuration = StringToInt(sNew);

	else if(hCvar == g_hCvarRollInterval)
		g_iCvarRollInterval = StringToInt(sNew);

	else if(hCvar == g_hCvarDisabledPerks)
		ParseDisabledPerks();
}

public int ConVarChange_Usage(Handle hCvar, const char[] sOld, const char[] sNew){
	if(hCvar == g_hCvarAllowed)
		g_iCvarAllowed = ReadFlagString(sNew);

	else if(hCvar == g_hCvarInSetup)
		g_bCvarInSetup = StringToInt(sNew) > 0 ? true : false;

	else if(hCvar == g_hCvarTriggers)
		ParseTriggers();

	else if(hCvar == g_hCvarShowTriggers)
		g_bCvarShowTriggers = StringToInt(sNew) > 0 ? true : false;

	else if(hCvar == g_hCvarShowTime)
		g_bCvarShowTime = StringToInt(sNew) > 0 ? true : false;
}

public int ConVarChange_Rtd(Handle hCvar, const char[] sOld, const char[] sNew){
	if(hCvar == g_hCvarRtdTeam)
		g_iCvarRtdTeam = StringToInt(sNew);

	else if(hCvar == g_hCvarRtdMode)
		g_iCvarRtdMode = StringToInt(sNew);

	else if(hCvar == g_hCvarClientLimit)
		g_iCvarClientLimit = StringToInt(sNew);

	else if(hCvar == g_hCvarTeamLimit)
		g_iCvarTeamLimit = StringToInt(sNew);

	else if(hCvar == g_hCvarRespawnStuck)
		g_bCvarRespawnStuck = StringToInt(sNew) > 0 ? true : false;
}

public int ConVarChange_Repeat(Handle hCvar, const char[] sOld, const char[] sNew){
	if(hCvar == g_hCvarRepeatPlayer){
		g_iCvarRepeatPlayer = StringToInt(sNew);
		g_hRollers.ResetPerkHisories();
	}else if(hCvar == g_hCvarRepeatPerk){
		g_iCvarRepeatPerk = StringToInt(sNew);
		g_hPerkHistory.Clear();
	}
}

public int ConVarChange_Good(Handle hCvar, const char[] sOld, const char[] sNew){
	if(hCvar == g_hCvarGoodChance)
		g_fCvarGoodChance = StringToFloat(sNew);

	else if(hCvar == g_hCvarGoodDonatorChance)
		g_fCvarGoodDonatorChance = StringToFloat(sNew);

	else if(hCvar == g_hCvarDonatorFlag)
		g_iCvarDonatorFlag = ReadFlagString(sNew);
}

public int ConVarChange_Timer(Handle hCvar, const char[] sOld, const char[] sNew){
	if(hCvar == g_hCvarTimerPosX)
		g_fCvarTimerPosX = StringToFloat(sNew);

	else if(hCvar == g_hCvarTimerPosY)
		g_fCvarTimerPosY = StringToFloat(sNew);
}



			//***********************//
			//----  E V E N T S  ----//
			//***********************//

public Action Event_PlayerDeath(Handle hEvent, const char[] sEventName, bool dontBroadcast){
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client == 0)
		return Plugin_Continue;

	int flags = GetEventInt(hEvent, "death_flags");
	if(flags & FLAG_FEIGNDEATH)
		return Plugin_Continue;

	if(!g_hRollers.GetInRoll(client))
		return Plugin_Continue;

	ForceRemovePerk(client, RTDRemove_Death);
	return Plugin_Continue;
}

public Action Event_ClassChange(Handle hEvent, const char[] sEventName, bool dontBroadcast){
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client == 0)
		return Plugin_Continue;

	if(!g_hRollers.GetInRoll(client))
		return Plugin_Continue;

	ForceRemovePerk(client, RTDRemove_ClassChange);
	return Plugin_Continue;
}

public Action Event_RoundActive(Handle hEvent, const char[] sEventName, bool dontBroadcast){
	if(g_bCvarPluginEnabled && (g_iCvarChat & CHAT_AD) && IsRTDInRound())
		RTDPrintAll("%T", "RTD2_Ad", LANG_SERVER, 0x03, 0x01);

	return Plugin_Continue;
}

public Action Event_Resupply(Handle hEvent, const char[] sEventName, bool bDontBroadcast){
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client) Forward_Resupply(client);
	return Plugin_Continue;
}

public Action Event_PlayerHurt(Handle hEvent, const char[] sEventName, bool bDontBroadcast){
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client) Forward_PlayerHurt(client, hEvent);
	return Plugin_Continue;
}

public void OnEntityCreated(int iEnt, const char[] sClassname){
	Forward_OnEntityCreated(iEnt, sClassname);
}

public void OnGameFrame(){
	Forward_OnGameFrame();
}

public void TF2_OnConditionAdded(int client, TFCond condition){
	Forward_OnConditionAdded(client, condition);
}

public void TF2_OnConditionRemoved(int client, TFCond condition){
	Forward_OnConditionRemoved(client, condition);
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVel[3], float fAng[3], int &iWeapon){
	if(!IsValidClient(client))
		return Plugin_Continue;

	if(Forward_OnPlayerRunCmd(client, iButtons, iImpulse, fVel, fAng, iWeapon))
		return Plugin_Changed;

	return Plugin_Continue;
}

public Action TF2_CalcIsAttackCritical(int client, int iWeapon, char[] sWeaponName, bool &bResult){
	if(!IsValidClient(client))
		return Plugin_Continue;

	if(!Forward_AttackIsCritical(client, iWeapon, sWeaponName))
		return Plugin_Continue;

	bResult = true;
	return Plugin_Changed;
}



			//*********************//
			//----  P E R K S  ----//
			//*********************//

//-----[ Parsing & Precaching ]-----//

void ParseTriggers(){
	char sCvar[64], sBuffer[64];
	GetConVarString(g_hCvarTriggers, sCvar, sizeof(sCvar));
	EscapeString(sCvar, ' ', '\0', sBuffer, sizeof(sBuffer));

	g_iCvarTriggers = CountCharInString(sBuffer, ',')+1;
	char[][] sPieces = new char[g_iCvarTriggers][64];

	ExplodeString(sBuffer, ",", sPieces, g_iCvarTriggers, 64);

	if(g_arrCvarTriggers == INVALID_HANDLE)
		g_arrCvarTriggers = CreateArray(16);
	else ClearArray(g_arrCvarTriggers);

	for(int i = 0; i < g_iCvarTriggers; i++)
		PushArrayString(g_arrCvarTriggers, sPieces[i]);
}

bool ParseEffects(){
	char sPath[255];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/rtd2_perks.default.cfg");
	if(!FileExists(sPath)){
		LogError(CONS_PREFIX ... " Failed to find rtd2_perks.default.cfg in configs/ folder!");
		SetFailState("Failed to find rtd2_perks.default.cfg in configs/ folder!");
		return false;
	}

	if(g_hPerkContainer == null)
		g_hPerkContainer = new PerkContainer();
	g_hPerkContainer.DisposePerks();

	int iStatus[2];
	g_iCorePerks = g_hPerkContainer.ParseFile(sPath, iStatus);
	if(g_iCorePerks == -1){
		LogError(CONS_PREFIX ... " Parsing rtd2_perks.default.cfg failed!");
		SetFailState("Parsing rtd2_perks.default.cfg failed!");
		return false;
	}

	PrintToServer(CONS_PREFIX ... " Loaded %d perk%s (%d good, %d bad).", g_iCorePerks, g_iCorePerks > 1 ? "s" : "", iStatus[1], iStatus[0]);
	return true;
}

void ParseCustomEffects(){
	char sPath[255];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/rtd2_perks.custom.cfg");
	if(!FileExists(sPath)){
		PrecachePerkSounds();
		return;
	}

	int iPerksCustomized = g_hPerkContainer.ParseCustomFile(sPath);
	PrintToServer(CONS_PREFIX ... " Customized %d perk%s.", iPerksCustomized, iPerksCustomized == 1 ? "" : "s");
	PrecachePerkSounds();
}

void PrecachePerkSounds(){
	char sBuffer[64];
	PerkIter iter = new PerkContainerIter(-1);
	while((++iter).Perk()){
		iter.Perk().GetSound(sBuffer, 64);
		PrecacheSound(sBuffer);
	}
	delete iter;
}

void ParseDisabledPerks(){
	PerkIter iter = new PerkContainerIter(-1);
	while((++iter).Perk())
		iter.Perk().Enabled = true;
	delete iter;

	char sDisabledPre[255], sDisabled[255];
	GetConVarString(g_hCvarDisabledPerks, sDisabledPre, 255);
	EscapeString(sDisabledPre, ' ', '\0', sDisabled, 255);
	if(strlen(sDisabled) == 0)
		return;

	int iDisabledCount = CountCharInString(sDisabled, ',') +1;
	char[][] sDisabledPieces = new char[iDisabledCount][32];
	ExplodeString(sDisabled, ",", sDisabledPieces, iDisabledCount, 32);

	Perk perk = null;
	PerkList hDisabledPerks = new PerkList();
	for(int i = 0; i < iDisabledCount; ++i){
		perk = g_hPerkContainer.FindPerk(sDisabledPieces[i]);
		if(perk == null) continue;

		perk.Enabled = false;
		hDisabledPerks.Push(perk);
	}

	char sNameBuffer[64];
	int iLen = hDisabledPerks.Length;
	switch(iLen){
		case 0:{}

		case 1:{
			hDisabledPerks.Get(0).GetName(sNameBuffer, 64);
			if(g_bCvarLog)
				LogMessage(CONS_PREFIX ... " Perk disabled: %s.", sNameBuffer);
			PrintToServer(CONS_PREFIX ... " Perk disabled: %s.", sNameBuffer);
		}

		default:{
			hDisabledPerks.Get(0).GetName(sNameBuffer, 64);
			if(g_bCvarLog)
				LogMessage(CONS_PREFIX ... " %d perks disabled:", iLen);
			PrintToServer(CONS_PREFIX ... " %d perks disabled:", iLen);
			for(int i = 0; i < iLen; ++i){
				hDisabledPerks.Get(i).GetName(sNameBuffer, 64);
				if(g_bCvarLog)
					LogMessage("  • %s", sNameBuffer);
				PrintToServer("  > %s", sNameBuffer);
			}
		}
	}
	delete hDisabledPerks;
}

//-----[ Applying ]-----//
void RollPerkForClient(int client){
	if(!g_bCvarPluginEnabled){
		if(g_iCvarChat & CHAT_REASONS)
			RTDPrint(client, "%T", "RTD2_Cant_Roll_Disabled", LANG_SERVER);
		return;
	}

	if(!IsRollerAllowed(client)){
		if(g_iCvarChat & CHAT_REASONS)
			RTDPrint(client, "%T", "RTD2_Cant_Roll_No_Access", LANG_SERVER);
		return;
	}

	if(!IsRTDInRound()){
		if(g_iCvarChat & CHAT_REASONS)
			RTDPrint(client, "%T", "RTD2_Not_In_Round", LANG_SERVER);
		return;
	}

	if(g_iCvarRtdTeam > 0 && g_iCvarRtdTeam == GetClientTeam(client)-1){
		if(g_iCvarChat & CHAT_REASONS)
			RTDPrint(client, "%T", "RTD2_Cant_Roll_Team", LANG_SERVER);
		return;
	}

	if(GetForwardFunctionCount(g_hFwdCanRoll) > 0){
		Call_StartForward(g_hFwdCanRoll);
		Call_PushCell(client);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if(result != Plugin_Continue)
			return;
	}

	if(!IsPlayerAlive(client)){
		if(g_iCvarChat & CHAT_REASONS)
			RTDPrint(client, "%T", "RTD2_Cant_Roll_Alive", LANG_SERVER);
		return;
	}

	if(g_hRollers.GetInRoll(client)){
		if(g_iCvarChat & CHAT_REASONS)
			RTDPrint(client, "%T", "RTD2_Cant_Roll_Using", LANG_SERVER);
		return;
	}

	int iTimeLeft = g_hRollers.GetLastRollTime(client) +g_iCvarRollInterval;
	if(GetTime() < iTimeLeft){
		if(g_iCvarChat & CHAT_REASONS)
			RTDPrint(client, "%T", "RTD2_Cant_Roll_Wait", LANG_SERVER, 0x04, iTimeLeft -GetTime(), 0x01);
		return;
	}

	switch(g_iCvarRtdMode){
		case 1:{
			int iCount = 0;
			for(int i = 1; i <= MaxClients; i++){
				if(g_hRollers.GetInRoll(i))
					iCount++;
			}

			if(iCount >= g_iCvarClientLimit){
				if(g_iCvarChat & CHAT_REASONS)
					RTDPrint(client, "%T", "RTD2_Cant_Roll_Mode1", LANG_SERVER);
				return;
			}
		}

		case 2:{
			int iCount = 0, iTeam = GetClientTeam(client);
			for(int i = 1; i <= MaxClients; i++){
				if(g_hRollers.GetInRoll(i))
					if(GetClientTeam(i) == iTeam)
						iCount++;
			}

			if(iCount >= g_iCvarTeamLimit){
				if(g_iCvarChat & CHAT_REASONS)
					RTDPrint(client, "%T", "RTD2_Cant_Roll_Mode2", LANG_SERVER);
				return;
			}
		}
	}

	Perk perk = RollPerk(client);
	ApplyPerk(client, perk);
	if(g_bCvarLog){
		char sBuffer[64];
		perk.Format(sBuffer, 64, "$Name$ ($Token$)");
		LogMessage("%L rolled %s.", client, sBuffer);
	}
}

RTDForceResult ForcePerk(int client, const char[] sQuery, int iPerkTime=-1, int initiator=0){
	if(!IsValidClient(client))
		return RTDForce_ClientInvalid;

	bool bIsValidInitiator = IsValidClient(initiator);
	if(g_hRollers.GetInRoll(client)){
		RTDPrint(initiator, "%N is already using RTD.", client);
		return RTDForce_ClientInRoll;
	}

	if(!IsPlayerAlive(client)){
		RTDPrint(initiator, "%N is dead.", client);
		return RTDForce_ClientDead;
	}

	Perk perk = g_hPerkContainer.FindPerk(sQuery);
	if(!perk){
		RTDPrint(initiator, "Perk not found or invalid info, forcing a roll.");
		perk = RollPerk(client, _, sQuery);
		if(!perk){
			RTDPrint(initiator, "No perks available for %N.", client);
			return RTDForce_NullPerk;
		}
	}

	if(bIsValidInitiator && GetForwardFunctionCount(g_hFwdCanForce) > 0){
		Call_StartForward(g_hFwdCanForce);
		Call_PushCell(initiator);
		Call_PushCell(client);
		Call_PushCell(perk.Id);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if(result != Plugin_Continue)
			return RTDForce_Blocked;
	}

	g_iLastPerkTime = iPerkTime;
	ApplyPerk(client, perk, iPerkTime);
	g_iLastPerkTime = -1; // Set back to default

	if(g_bCvarLog){
		char sBuffer[64];
		perk.Format(sBuffer, 64, "$Name$ ($Token$)");
		if(bIsValidInitiator)
			LogMessage("A perk %s has been forced on %L for %d seconds by %L.", sBuffer, client, iPerkTime, initiator);
		else LogMessage("A perk %s has been forced on %L for %d seconds.", sBuffer, client, iPerkTime);
	}

	return RTDForce_Success;
}

//-----[ General ]-----//
bool GoodRoll(int client){
	float fGoodChance = g_fCvarGoodChance;
	if(IsValidClient(client) && IsRollerDonator(client))
		fGoodChance = g_fCvarGoodDonatorChance;
	return fGoodChance > GetURandomFloat();
}

Perk RollPerk(int client=0, int iRollFlags=ROLLFLAG_NONE, const char[] sFilter=""){
	bool bFilter = strlen(sFilter) > 0;
	Perk perk = null;
	PerkList candidates = g_hPerkContainer.FindPerks(sFilter);
	PerkList list = new PerkList();
	PerkIter iter = new PerkListIter(candidates, -1);

	if(bFilter){
		while((perk = (++iter).Perk()))
			if(perk.IsAptForSetupOf(client, iRollFlags))
				list.Push(perk);
	}else{
		bool bBeGood = GoodRoll(client);
		while((perk = (++iter).Perk()))
			if(perk.Good == bBeGood && perk.IsAptFor(client, iRollFlags))
				list.Push(perk);
	}

	delete iter;
	delete candidates;

	perk = list.GetRandom();
	delete list;
	return perk;
}

void ApplyPerk(int client, Perk perk, int iPerkTime=-1){
	if(!IsValidClient(client)) return;

	perk.EmitSound(client);
	ManagePerk(client, perk, true);

	g_hPerkHistory.Push(perk.Id);

	int iDuration = -1;
	int iTime = perk.Time;
	if(iTime > -1){
		iDuration = (iPerkTime > -1) ? iPerkTime : (iTime > 0) ? iTime : g_iCvarPerkDuration;
		int iSerial = GetClientSerial(client);

		g_hRollers.SetInRoll(client, true);
		g_hRollers.SetPerk(client, perk);
		g_hRollers.SetEndRollTime(client, GetTime() +iDuration);

		Handle hTimer = CreateTimer(float(iDuration), Timer_RemovePerk, iSerial);
		g_hRollers.SetTimer(client, hTimer);

		DisplayPerkTimeFrame(client);
		CreateTimer(1.0, Timer_Countdown, iSerial, TIMER_REPEAT);
	}else g_hRollers.SetLastRollTime(client, GetTime());

	Forward_PerkApplied(client, perk, iDuration);
	g_hRollers.PushToPerkHistory(client, perk);

	PrintToRoller(client, perk, iDuration);
	PrintToNonRollers(client, perk, iDuration);
}

//-----[ Descriptions ]-----//
Menu BuildDesc(){
	Menu hMenu = new Menu(ManagerDesc);
	hMenu.SetTitle("%T", "RTD2_Menu_Title", LANG_SERVER);

	char sPerkName[MAX_NAME_LENGTH], sPerkToken[32];
	PerkIter iter = new PerkContainerIter(-1);
	Perk perk = null;

	while((perk = (++iter).Perk())){
		perk.GetToken(sPerkToken, 32);
		perk.GetName(sPerkName, MAX_NAME_LENGTH);
		hMenu.AddItem(sPerkToken, sPerkName);
	}

	delete iter;

	hMenu.ExitBackButton = false;
	hMenu.ExitButton = true;

	return hMenu;
}

void ShowDesc(int client, int iPos=0){
	if(iPos == 0)
		g_hDescriptionMenu.Display(client, MENU_TIME_FOREVER);
	else g_hDescriptionMenu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
}

public int ManagerDesc(Menu hMenu, MenuAction maState, int client, int iPos){
	if(maState != MenuAction_Select)
		return 0;

	Perk perk = null;
	char sPerkToken[32], sPerkName[MAX_NAME_LENGTH], sTranslate[64];

	hMenu.GetItem(iPos, sPerkToken, 32);
	perk = g_hPerkContainer.Get(sPerkToken);
	perk.GetName(sPerkName, MAX_NAME_LENGTH);
	FormatEx(sTranslate, 64, "RTD2_Desc_%s", sPerkToken);

	RTDPrint(client, "%s%s%c: \x03%T\x01",
		perk.Good ? PERK_COLOR_GOOD : PERK_COLOR_BAD,
		sPerkName, 0x01,
		sTranslate, LANG_SERVER);

	ShowDesc(client, iPos);
	return 1;
}

//-----[ Timers ]-----//
public Action Timer_Countdown(Handle hTimer, int iSerial){
	int client = GetClientFromSerial(iSerial);
	if(client == 0)
		return Plugin_Stop;

	if(!g_hRollers.GetInRoll(client))
		return Plugin_Stop;

	DisplayPerkTimeFrame(client);
	return Plugin_Continue;
}

public Action Timer_RemovePerk(Handle hTimer, int iSerial){
	int client = GetClientFromSerial(iSerial);
	if(client == 0)
		return Plugin_Stop;

	if(g_bCvarLog){
		char sBuffer[64];
		g_hRollers.GetPerk(client).Format(sBuffer, 64, "$Name$ ($Token$)");
		LogMessage("Perk %s ended on %L.", sBuffer, client);
	}

	ManagePerk(client, g_hRollers.GetPerk(client), false);
	return Plugin_Handled;
}

//-----[ Removing ]-----//
Perk ForceRemovePerk(int client, RTDRemoveReason reason=RTDRemove_WearOff, const char[] sReason=""){
	if(!IsValidClient(client)) return null;

	Perk perk = g_hRollers.GetPerk(client);
	if(perk) ManagePerk(client, perk, false, reason, sReason);
	return perk;
}

void RemovedPerk(int client, RTDRemoveReason reason, const char[] sReason=""){
	g_hRollers.SetInRoll(client, false);
	g_hRollers.SetLastRollTime(client, GetTime());

	Forward_PerkRemoved(client, g_hRollers.GetPerk(client), reason);
	g_hRollers.SetPerk(client, null);
	PrintPerkEndReason(client, reason, sReason);

	Handle hTimer = g_hRollers.GetTimer(client);
	KillTimerSafe(hTimer);
}

//-----[ Printing ]-----//
void PrintToRoller(int client, Perk perk, int iDuration){
	if(!(g_iCvarChat & CHAT_APPROLLER))
		return;

	char sPerkName[MAX_NAME_LENGTH];
	perk.GetName(sPerkName, MAX_NAME_LENGTH);

	if(!g_bCvarShowTime || perk.Time == -1)
		RTDPrint(client, "%T",
			"RTD2_Rolled_Perk_Roller", LANG_SERVER,
			perk.Good ? PERK_COLOR_GOOD : PERK_COLOR_BAD,
			sPerkName,
			0x01);
	else{
		int iTrueDuration = (iDuration > -1) ? iDuration : (perk.Time > 0) ? perk.Time : g_iCvarPerkDuration;
		RTDPrint(client, "%T",
			"RTD2_Rolled_Perk_Roller_Time", LANG_SERVER,
			perk.Good ? PERK_COLOR_GOOD : PERK_COLOR_BAD,
			sPerkName,
			0x01, 0x03, iTrueDuration, 0x01);
	}
}

void PrintToNonRollers(int client, Perk perk, int iDuration){
	if(!(g_iCvarChat & CHAT_APPOTHER))
		return;

	char sRollerName[MAX_NAME_LENGTH], sPerkName[MAX_NAME_LENGTH];
	GetClientName(client, sRollerName, sizeof(sRollerName));
	perk.GetName(sPerkName, MAX_NAME_LENGTH);

	if(!g_bCvarShowTime || perk.Time == -1)
		RTDPrintAllExcept(client, "%T",
			"RTD2_Rolled_Perk_Others", LANG_SERVER,
			g_sTeamColors[GetClientTeam(client)],
			sRollerName,
			0x01,
			perk.Good ? PERK_COLOR_GOOD : PERK_COLOR_BAD,
			sPerkName, 0x01);
	else{
		int iTrueDuration = (iDuration > -1) ? iDuration : (perk.Time > 0) ? perk.Time : g_iCvarPerkDuration;
		RTDPrintAllExcept(client, "%T",
			"RTD2_Rolled_Perk_Others_Time", LANG_SERVER,
			g_sTeamColors[GetClientTeam(client)],
			sRollerName,
			0x01,
			perk.Good ? PERK_COLOR_GOOD : PERK_COLOR_BAD,
			sPerkName, 0x01, 0x03, iTrueDuration, 0x01);
	}
}

void PrintPerkEndReason(int client, RTDRemoveReason reason=RTDRemove_WearOff, const char[] sCustomReason=""){
	char sReasonSelf[32], sReasonOthers[32];
	switch(reason){
		case RTDRemove_PluginUnload:{
			strcopy(sReasonSelf, sizeof(sReasonSelf), "RTD2_Remove_Perk_Unload_Self");
			strcopy(sReasonOthers, sizeof(sReasonOthers), "RTD2_Remove_Perk_Unload_Others");
		}

		case RTDRemove_Death:{
			strcopy(sReasonSelf, sizeof(sReasonSelf), "RTD2_Remove_Perk_Died_Self");
			strcopy(sReasonOthers, sizeof(sReasonOthers), "RTD2_Remove_Perk_Died_Others");
		}

		case RTDRemove_ClassChange:{
			strcopy(sReasonSelf, sizeof(sReasonSelf), "RTD2_Remove_Perk_Class_Self");
			strcopy(sReasonOthers, sizeof(sReasonOthers), "RTD2_Remove_Perk_Class_Others");
		}

		case RTDRemove_WearOff:{
			strcopy(sReasonSelf, sizeof(sReasonSelf), "RTD2_Remove_Perk_End_Self");
			strcopy(sReasonOthers, sizeof(sReasonOthers), "RTD2_Remove_Perk_End_Others");
		}

		case RTDRemove_Disconnect:{
			strcopy(sReasonSelf, sizeof(sReasonSelf), "0");
			strcopy(sReasonOthers, sizeof(sReasonOthers), "RTD2_Remove_Perk_Disconnected");
		}

		case RTDRemove_Custom:{
			strcopy(sReasonSelf, sizeof(sReasonSelf), "RTD2_Remove_Perk_Custom_Self");
			strcopy(sReasonOthers, sizeof(sReasonOthers), "RTD2_Remove_Perk_Custom_Others");
		}
	}

	if(sReasonSelf[0] != '0' && (g_iCvarChat & CHAT_REMROLLER))
		RTDPrint(client, "%T", sReasonSelf, LANG_SERVER, reason == RTDRemove_Custom ? sCustomReason : "");

	if(g_iCvarChat & CHAT_REMOTHER)
		RTDPrintAllExcept(client, "%T", sReasonOthers, LANG_SERVER, g_sTeamColors[GetClientTeam(client)], client, 0x01, reason == RTDRemove_Custom ? sCustomReason : "");
}



			//*************************//
			//----  N A T I V E S  ----//
			//*************************//

#include "rtd/natives.sp"



			//***************************//
			//----  F O R W A R D S  ----//
			//***************************//

void Forward_PerkApplied(int client, Perk perk, int iDuration){
	if(GetForwardFunctionCount(g_hFwdRolled) < 1)
		return;

	Call_StartForward(g_hFwdRolled);
	Call_PushCell(client);
	Call_PushCell(perk.Id);
	Call_PushCell(iDuration);
	Call_Finish();
}

void Forward_PerkRemoved(int client, Perk perk, RTDRemoveReason reason){
	if(GetForwardFunctionCount(g_hFwdRemoved) < 1)
		return;

	Call_StartForward(g_hFwdRemoved);
	Call_PushCell(client);
	Call_PushCell(perk.Id);
	Call_PushCell(reason);
	Call_Finish();
}

void Forward_OnRegOpen(){
	if(GetForwardFunctionCount(g_hFwdOnRegOpen) < 1)
		return;

	Call_StartForward(g_hFwdOnRegOpen);
	Call_Finish();
}



			//***********************//
			//----  S T O C K S  ----//
			//***********************//

bool IsInPerkHistory(Perk perk){
	return perk.IsInHistory(g_hPerkHistory, g_iCvarRepeatPerk);
}

bool IsInClientHistory(int client, Perk perk){
	return g_hRollers.IsInPerkHistory(client, perk, g_iCvarRepeatPlayer);
}

//-----[ Strings ]-----//
int EscapeString(const char[] input, int escape, int escaper, char[] output, int maxlen){
	/*
		Thanks Popoklopsi for EscapeString()
		https://forums.alliedmods.net/showthread.php?t=212230
	*/

	int escaped = 0;
	Format(output, maxlen, "");
	for(int offset = 0; offset < strlen(input); offset++){
		int ch = input[offset];
		if(ch == escape || ch == escaper){
			Format(output, maxlen, "%s%c%c", output, escaper, ch);
			escaped++;
		}else Format(output, maxlen, "%s%c", output, ch);
	}
	return escaped;
}

//-----[ Feedback ]-----//
void RTDPrint(int to, const char[] sFormat, any ...){
	char sMsg[255];
	VFormat(sMsg, 255, sFormat, 3);
	if(IsValidClient(to))
		PrintToChat(to, "%s %s", CHAT_PREFIX, sMsg);
	else PrintToServer("%s %s", CONS_PREFIX, sMsg);
}

void RTDPrintAll(const char[] sFormat, any ...){
	char sMsg[255];
	VFormat(sMsg, 255, sFormat, 2);
	PrintToChatAll("%s %s", CHAT_PREFIX, sMsg);
}

void RTDPrintAllExcept(int client, char[] sFormat, any ...){
	char sMsg[255];
	VFormat(sMsg, 255, sFormat, 3);
	int i = 0;

	while(++i < client)
		if(IsClientInGame(i))
			PrintToChat(i, "%s %s", CHAT_PREFIX, sMsg);

	while(++i <= MaxClients)
		if(IsClientInGame(i))
			PrintToChat(i, "%s %s", CHAT_PREFIX, sMsg);
}

void DisplayPerkTimeFrame(client){
	int iTeam	= GetClientTeam(client);
	int iRed	= (iTeam == 2) ? 255 : 32;
	int iBlue	= (iTeam == 3) ? 255 : 32;

	SetHudTextParams(g_fCvarTimerPosX, g_fCvarTimerPosY, 1.0, iRed, 32, iBlue, 255);
	char sPerkName[MAX_NAME_LENGTH];
	g_hRollers.GetPerk(client).GetName(sPerkName, MAX_NAME_LENGTH);
	ShowSyncHudText(client, g_hRollers.GetHud(client), "%s: %d", sPerkName, g_hRollers.GetEndRollTime(client) -GetTime());
}

//-----[ Perks ]-----//
int GetPerkTime(Perk perk){
	if(g_iLastPerkTime != -1)
		return g_iLastPerkTime;
	int iTime = perk.Time;
	return (iTime > 0) ? iTime : g_iCvarPerkDuration;
}

void RemovePerkFromClients(Perk perk){
	for(int i = 1; i <= MaxClients; ++i)
		if(IsClientInGame(i) && g_hRollers.GetPerk(i) == perk)
			ForceRemovePerk(i);
}

void DisableModulePerks(Handle hPlugin){
	Perk perk = null;
	for(int i = 1; i <= MaxClients; ++i){
		if(!IsClientInGame(i))
			continue;

		perk = g_hRollers.GetPerk(i);
		if(perk && perk.External && perk.Parent == hPlugin)
			perk.Call(i, false);
	}

	PerkIter iter = new PerkContainerIter(-1);
	while((perk = (++iter).Perk())){
		if(perk.External && perk.Parent == hPlugin){
			perk.Enabled = perk.Id < g_iCorePerks; // disable if external
			perk.External = false; // set perk to unaltered call
		}
	}
	delete iter;
}

//-----[ Miscellaneous ]-----//
int ReadFlagFromConVar(Handle hCvar){
	char sBuffer[32];
	GetConVarString(hCvar, sBuffer, sizeof(sBuffer));
	return ReadFlagString(sBuffer);
}

int ConnectWithBeam(int iEnt, int iEnt2, int iRed=255, int iGreen=255, int iBlue=255, float fStartWidth=1.0, float fEndWidth=1.0, float fAmp=1.35){
	int iBeam = CreateEntityByName("env_beam");
	if(iBeam <= MaxClients)
		return -1;

	if(!IsValidEntity(iBeam))
		return -1;

	SetEntityModel(iBeam, LASERBEAM);
	char sColor[16];
	Format(sColor, sizeof(sColor), "%d %d %d", iRed, iGreen, iBlue);

	DispatchKeyValue(iBeam, "rendercolor", sColor);
	DispatchKeyValue(iBeam, "life", "0");

	DispatchSpawn(iBeam);

	SetEntPropEnt(iBeam, Prop_Send, "m_hAttachEntity", EntIndexToEntRef(iEnt));
	SetEntPropEnt(iBeam, Prop_Send, "m_hAttachEntity", EntIndexToEntRef(iEnt2), 1);

	SetEntProp(iBeam, Prop_Send, "m_nNumBeamEnts", 2);
	SetEntProp(iBeam, Prop_Send, "m_nBeamType", 2);

	SetEntPropFloat(iBeam, Prop_Data, "m_fWidth", fStartWidth);
	SetEntPropFloat(iBeam, Prop_Data, "m_fEndWidth", fEndWidth);

	SetEntPropFloat(iBeam, Prop_Data, "m_fAmplitude", fAmp);

	SetVariantFloat(32.0);
	AcceptEntityInput(iBeam, "Amplitude");
	AcceptEntityInput(iBeam, "TurnOn");
	return iBeam;
}

int CreateParticle(int iClient, char[] strParticle, bool bAttach=true, char[] strAttachmentPoint="", float fOffset[3]={0.0, 0.0, 36.0}){
	//Thanks J-Factor for CreateParticle()
	int iParticle = CreateEntityByName("info_particle_system");
	if(!IsValidEdict(iParticle)) return 0;

	float fPosition[3], fAngles[3], fForward[3], fRight[3], fUp[3];
	GetClientAbsOrigin(iClient, fPosition);
	GetClientAbsAngles(iClient, fAngles);

	GetAngleVectors(fAngles, fForward, fRight, fUp);
	fPosition[0] += fRight[0]*fOffset[0] + fForward[0]*fOffset[1] + fUp[0]*fOffset[2];
	fPosition[1] += fRight[1]*fOffset[0] + fForward[1]*fOffset[1] + fUp[1]*fOffset[2];
	fPosition[2] += fRight[2]*fOffset[0] + fForward[2]*fOffset[1] + fUp[2]*fOffset[2];

	TeleportEntity(iParticle, fPosition, fAngles, NULL_VECTOR);
	DispatchKeyValue(iParticle, "effect_name", strParticle);

	if(bAttach){
		SetVariantString("!activator");
		AcceptEntityInput(iParticle, "SetParent", iClient, iParticle, 0);

		if(!StrEqual(strAttachmentPoint, "")){
			SetVariantString(strAttachmentPoint);
			AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset", iParticle, iParticle, 0);
		}
	}

	DispatchSpawn(iParticle);
	ActivateEntity(iParticle);
	AcceptEntityInput(iParticle, "Start");

	return iParticle;
}

void FixPotentialStuck(int client){
	if(g_bCvarRespawnStuck && IsValidClient(client))
		CreateTimer(0.1, Timer_FixStuck, GetClientSerial(client));
}

public Action Timer_FixStuck(Handle hTimer, int iSerial){
	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;

	if(!IsPlayerAlive(client))
		return Plugin_Stop;

	if(!IsEntityStuck(client))
		return Plugin_Stop;

	RTDPrint(client, "%T", "RTD2_Stuck_Respawn", LANG_SERVER);
	TF2_RespawnPlayer(client);
	return Plugin_Stop;
}

//-----[ Checks ]-----//
bool IsArgumentTrigger(const char[] sArg){
	char sTrigger[16];
	for(int i = 0; i < g_iCvarTriggers; i++){
		GetArrayString(g_arrCvarTriggers, i, sTrigger, 16);
		if(StrEqual(sArg, sTrigger, false))
			return true;
	}
	return false;
}

bool IsEntityStuck(int iEntity){
	float fPos[3], fMins[3], fMaxs[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPos);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMins", fMins);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", fMaxs);

	TR_TraceHullFilter(fPos, fPos, fMins, fMaxs, MASK_SOLID, TraceFilterIgnoreSelf, iEntity);
	return TR_DidHit();
}

bool IsRollerAllowed(int client){
	if(g_iCvarAllowed > 0)
		return view_as<bool>(GetUserFlagBits(client) & g_iCvarAllowed);
	return true;
}

bool IsRollerDonator(int client){
	if(g_iCvarDonatorFlag > 0)
		return view_as<bool>(GetUserFlagBits(client) & g_iCvarDonatorFlag);
	return false;
}

bool CanBuildAtPos(float fPos[3], bool bSentry){
	//TODO: Figure out a neat way of checking nobuild areas. I've spent 5h non stop trying to do it, help pls.
	float fMins[3], fMaxs[3];
	if(bSentry){
		fMins[0] = -20.0;
		fMins[1] = -20.0;
		fMins[2] = 0.0;

		fMaxs[0] = 20.0;
		fMaxs[1] = 20.0;
		fMaxs[2] = 66.0;
	}else{
		fMins[0] = -24.0;
		fMins[1] = -24.0;
		fMins[2] = 0.0;

		fMaxs[0] = 24.0;
		fMaxs[1] = 24.0;
		fMaxs[2] = 55.0;
	}
	TR_TraceHull(fPos, fPos, fMins, fMaxs, MASK_SOLID);
	return !TR_DidHit();
}

bool CanPlayerBeHurt(int client, int by=0, bool bCanHurtSelf=false){
	if(IsValidClient(by))
		if(GetClientTeam(by) == GetClientTeam(client)){
			if(client != by || !bCanHurtSelf)
				return false;
		}

	if(IsPlayerFriendly(client))
		return false;

	if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
		return false;

	if(GetEntProp(client, Prop_Data, "m_takedamage") != 2)
		return false;

	return true;
}

void DamageRadius(float fOrigin[3], int iInflictor=0, int iAttacker=0, float fRadius, float fDamage, int iFlags=0, float fSelfDamage=0.0, bool bCheckSight=true, Function call=INVALID_FUNCTION){
	fRadius *= fRadius;
	float fOtherPos[3];
	for(int i = 1; i <= MaxClients; ++i){
		if(!IsClientInGame(i))
			continue;

		GetClientAbsOrigin(i, fOtherPos);
		if(GetVectorDistance(fOrigin, fOtherPos, true) <= fRadius)
			if(CanPlayerBeHurt(i, iAttacker, fSelfDamage > 0.0))
				if(!bCheckSight || (bCheckSight && CanEntitySeeTarget(iAttacker, i)))
					TakeDamage(i, iInflictor, iAttacker, i == iAttacker ? fSelfDamage : fDamage, iFlags, call);
	}
}

void TakeDamage(int client, int iInflictor, int iAttacker, float fDamage, int iFlags, Function call){
	SDKHooks_TakeDamage(client, iInflictor, iAttacker, fDamage, iFlags);
	if(call == INVALID_FUNCTION) return;
	Call_StartFunction(INVALID_HANDLE, call);
	Call_PushCell(client);
	Call_PushCell(iAttacker);
	Call_PushFloat(fDamage);
	Call_Finish();
}

bool IsPlayerFriendly(int client){
	if(g_bPluginFriendly)
		if(TF2Friendly_IsFriendly(client))
			return true;

	if(g_bPluginFriendlySimple)
		if(FriendlySimple_IsFriendly(client))
			return true;

	return false;
}

bool CanEntitySeeTarget(int iEnt, int iTarget){
	if(!iEnt) return false;

	float fStart[3], fEnd[3];
	if(IsValidClient(iEnt))
		GetClientEyePosition(iEnt, fStart);
	else GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fStart);

	if(IsValidClient(iTarget))
		GetClientEyePosition(iTarget, fEnd);
	else GetEntPropVector(iTarget, Prop_Send, "m_vecOrigin", fEnd);

	Handle hTrace = TR_TraceRayFilterEx(fStart, fEnd, MASK_SOLID, RayType_EndPoint, TraceFilterIgnorePlayersAndSelf, iEnt);
	if(hTrace != INVALID_HANDLE){
		if(TR_DidHit(hTrace)){
			CloseHandle(hTrace);
			return false;
		}
		CloseHandle(hTrace);
	}
	return true;
}

bool IsRTDInRound(){
	if(GameRules_GetProp("m_bInWaitingForPlayers", 1))
		return false;

	if(!g_bCvarInSetup){
		if(g_bIsGameArena && GameRules_GetRoundState() != view_as<RoundState>(7))
			return false;

		if(GameRules_GetProp("m_bInSetup", 1))
			return false;
	}
	return true;
}

//-----[ Trace ]-----//
public bool TraceFilterIgnoreSelf(int iEntity, int iContentsMask, any iTarget){
	return iEntity != iTarget;
}

public bool TraceFilterIgnorePlayers(int iEntity, int iContentsMask, any data){
	return !(1 <= iEntity <= MaxClients);
}

public bool TraceFilterIgnorePlayersAndSelf(int iEntity, int iContentsMask, any iTarget){
	if(iEntity == iTarget)
		return false;

	if(1 <= iEntity <= MaxClients)
		return false;

	return true;
}

bool GetClientLookPosition(int client, float fPosition[3]){
	float fPos[3], fAng[3];
	GetClientEyePosition(client, fPos);
	GetClientEyeAngles(client, fAng);

	Handle hTrace = TR_TraceRayFilterEx(fPos, fAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, client);
	if(hTrace != INVALID_HANDLE && TR_DidHit(hTrace)){
		TR_GetEndPosition(fPosition, hTrace);
		return true;
	}
	return false;
}

//-----[ Helpers ]-----//
int AccountIDToClient(int iAccountID){
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			if(GetSteamAccountID(i) == iAccountID)
				return i;
	return 0;
}

void KillTimerSafe(Handle &hTimer){
	if(hTimer == INVALID_HANDLE)
		return;

	KillTimer(hTimer);
	hTimer = INVALID_HANDLE;
}

bool IsValidClient(int client){
	return (1 <= client <= MaxClients) && IsClientInGame(client);
}

void KillEntIn(int iEnt, float fTime){
	char sStr[32];
	Format(sStr, 32, "OnUser1 !self:Kill::%f:1", fTime);
	SetVariantString(sStr);
	AcceptEntityInput(iEnt, "AddOutput");
	AcceptEntityInput(iEnt, "FireUser1");
}

int GetEntityAlpha(int iEnt){
	return GetEntData(iEnt, GetEntSendPropOffs(iEnt, "m_clrRender") + 3, 1);
}

void SetEntityAlpha(int iEnt, int iVal){
	SetEntData(iEnt, GetEntSendPropOffs(iEnt, "m_clrRender") + 3, iVal, 1, true);
}

void DisarmWeapons(int client, bool bDisarm){
	int iWeapon = 0;
	float fNextAttack = bDisarm ? GetGameTime() +86400.0 : 0.1;
	for(int i = 0; i < 3; i++){
		iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;

		SetEntPropFloat(iWeapon, Prop_Data, "m_flNextPrimaryAttack", fNextAttack);
		SetEntPropFloat(iWeapon, Prop_Data, "m_flNextSecondaryAttack", fNextAttack);
	}
}

int CreateRagdoll(int client, bool bFrozen=false){
	int iRag = CreateEntityByName("tf_ragdoll");
	if(iRag <= MaxClients || !IsValidEntity(iRag))
		return 0;

	float fPos[3], fAng[3], fVel[3];
	GetClientAbsOrigin(client, fPos);
	GetClientAbsAngles(client, fAng);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);

	TeleportEntity(iRag, fPos, fAng, fVel);

	SetEntProp(iRag, Prop_Send, "m_iPlayerIndex", client);
	SetEntProp(iRag, Prop_Send, "m_bIceRagdoll", bFrozen);
	SetEntProp(iRag, Prop_Send, "m_iTeam", GetClientTeam(client));
	SetEntProp(iRag, Prop_Send, "m_iClass", view_as<int>(TF2_GetPlayerClass(client)));
	SetEntProp(iRag, Prop_Send, "m_bOnGround", 1);

	//Scale fix by either SHADoW NiNE TR3S or ddhoward (dunno who was first :p)
	//https://forums.alliedmods.net/showpost.php?p=2383502&postcount=1491
	//https://forums.alliedmods.net/showpost.php?p=2366104&postcount=1487
	SetEntPropFloat(iRag, Prop_Send, "m_flHeadScale", GetEntPropFloat(client, Prop_Send, "m_flHeadScale"));
	SetEntPropFloat(iRag, Prop_Send, "m_flTorsoScale", GetEntPropFloat(client, Prop_Send, "m_flTorsoScale"));
	SetEntPropFloat(iRag, Prop_Send, "m_flHandScale", GetEntPropFloat(client, Prop_Send, "m_flHandScale"));

	SetEntityMoveType(iRag, MOVETYPE_NONE);

	DispatchSpawn(iRag);
	ActivateEntity(iRag);

	return iRag;
}
