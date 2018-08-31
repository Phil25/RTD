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


/****** I N C L U D E S *****/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2attributes>

#undef REQUIRE_PLUGIN
#include <updater>
#include <friendly>
#include <friendlysimple>

#include "rtd/perk_class.sp"
#include "rtd/perk_includes.sp"


/******* D E F I N E S ******/

#define PLUGIN_VERSION	"1.03"

#define CHAT_PREFIX 	"\x07FFD700[RTD]\x01"
#define CONS_PREFIX 	"[RTD]"

#define PERK_MAX_COUNT	64
#define PERK_MAX_LOW	32
#define PERK_MAX_HIGH	64
#define PERK_MAX_VERYH	128

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

#define UPDATE_URL		"https://bitbucket.org/Phil25/rtd/raw/default/update.txt"



/********* E N U M S ********/

enum Perks{
	String:sName[PERK_MAX_LOW],
	bool:bGood,
	String:sSound[PERK_MAX_HIGH],
	String:sToken[PERK_MAX_LOW],
	iTime,
	iClasses,
	Handle:hWeaponClasses,
	String:sPref[PERK_MAX_HIGH],
	Handle:hTags,
	bool:bIsDisabled,
	bool:bIsExternal,
	Function:funcCallback,
	Handle:plParent
};
int ePerks[PERK_MAX_COUNT][Perks];
PerkContainer g_hPerkContainer = null;

enum ClientInfo{
	bool:bRolling,
	iLastRoll,
	iLastPerk,
	iGreatLastPerk,
	iCurPerk,
	iPerkEnd,
	Handle:hPerkTimer,
	Handle:hHudSync,
	iGroupRollId
};
int eClients[MAXPLAYERS+1][ClientInfo];

enum GroupRolls{
	bool:bActive,
	iGroupPerkId,
	Handle:hClientArray,
	iClientCount
};
int eGroup[MAXPLAYERS+1][GroupRolls];



/********* M A N A G E R ********/

#include "rtd/manager.sp" //For info, go to the script itself



/***** V A R I A B L E S ****/

char	g_sTeamColors[][]		= {"\x07B2B2B2", "\x07B2B2B2", "\x07FF4040", "\x0799CCFF"};
int		g_iPerkCount			= 0;
int		g_iCorePerkCount		= 0;
bool	g_bTempPrint			= false;

bool	g_bPluginUpdater		= false;
bool	g_bPluginFriendly		= false;
bool	g_bPluginFriendlySimple	= false;

bool	g_bIsRegisteringOpen	= false;
bool	g_bIsUpdateForced		= false;

Handle	g_hDescriptionMenu		= INVALID_HANDLE;

bool	g_bIsGameArena			= false;



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

Handle g_hCvarCanRepeatPerk;		bool g_bCvarCanRepeatPerk = false;
#define DESC_CAN_REPEAT_PERK "0/1 - Can a perk can be allowed to be rolled twice in a row."
Handle g_hCvarCanRepeatGreatPerk;	bool g_bCvarCanRepeatGreatPerk = false;
#define DESC_CAN_REPEAT_GREAT_PERK "0/1 - Can a perk can be allowed to be rolled the second time in 3 rolls."

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
		Format(sError, iErrorSize, "%s This plugin only works for Team Fortress 2.", CONS_PREFIX);
		return APLRes_Failure;
	}

	CreateNative("RTD2_GetClientPerkId",	Native_GetClientPerkId);
	CreateNative("RTD2_GetClientPerkTime",	Native_GetClientPerkTime);

	CreateNative("RTD2_ForcePerk",			Native_ForcePerk);
	CreateNative("RTD2_RollPerk",			Native_RollPerk);
	CreateNative("RTD2_RemovePerk",			Native_RemovePerk);

	CreateNative("RTD2_GetPerkOfString",	Native_GetPerkOfString);

	CreateNative("RTD2_RegisterPerk",		Native_RegisterPerk);
	CreateNative("RTD2_IsRegOpen",			Native_IsRegisteringOpen);
	CreateNative("RTD2_SetPerkByToken",		Native_SetPerkByToken);
	CreateNative("RTD2_SetPerkById",		Native_SetPerkById);
	CreateNative("RTD2_DefaultCorePerk",	Native_DefaultCorePerk);

	CreateNative("RTD2_CanPlayerBeHurt",	Native_CanPlayerBeHurt);

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

	g_hCvarCanRepeatPerk		= CreateConVar("sm_rtd2_repeat", 		"0",		DESC_CAN_REPEAT_PERK,		FLAGS_CVARS, true, 0.0, true, 1.0);
	g_hCvarCanRepeatGreatPerk	= CreateConVar("sm_rtd2_repeatgreat",	"0",		DESC_CAN_REPEAT_GREAT_PERK,	FLAGS_CVARS, true, 0.0, true, 1.0);

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

	HookConVarChange(g_hCvarCanRepeatPerk,		ConVarChange_Repeat	);	g_bCvarCanRepeatPerk		= GetConVarInt(g_hCvarCanRepeatPerk) > 0 ? true : false;
	HookConVarChange(g_hCvarCanRepeatGreatPerk,	ConVarChange_Repeat	);	g_bCvarCanRepeatGreatPerk	= GetConVarInt(g_hCvarCanRepeatGreatPerk) > 0 ? true : false;

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

	for(int i = 1; i <= MaxClients; i++)
		if(IsValidClient(i))
			OnClientPutInServer(i);
}

public void OnConfigsExecuted(){
	g_hDescriptionMenu		= BuildDesc();
	g_bIsRegisteringOpen	= true;

	Forward_OnRegOpen();
	ParseDisabledPerks();
}

public void OnPluginEnd(){
	for(int i = 1; i <= MaxClients; i++){
		Forward_OnRemovePerkPre(i);

		if(eClients[i][bRolling])
			ForceRemovePerk(i, 0);

		eClients[i][bRolling]	= false;
		eClients[i][iLastRoll]	= 0;
		eClients[i][iCurPerk]	= -1;
	}
}

public void OnMapStart(){
	HookEvent("player_death",			Event_PlayerDeath);
	HookEvent("player_changeclass",		Event_ClassChange);
	HookEvent("teamplay_round_active",	Event_RoundActive);

	PrecacheModel(LASERBEAM);

	Forward_OnMapStart();
	PrecachePerkSounds();

	g_bIsGameArena = (FindEntityByClassname(MaxClients +1, "tf_logic_arena") > MaxClients);
}

public void OnMapEnd(){
	UnhookEvent("player_death",				Event_PlayerDeath);
	UnhookEvent("player_changeclass",		Event_ClassChange);
	UnhookEvent("teamplay_round_active",	Event_RoundActive);
}

public void OnClientPutInServer(int client){
	eClients[client][bRolling]	= false;
	eClients[client][iLastRoll]	= 0;
	eClients[client][iCurPerk]	= -1;
	eClients[client][hHudSync]	= CreateHudSynchronizer();

	Forward_OnClientPutInServer(client);
}

public void OnClientDisconnect(int client){
	Forward_OnRemovePerkPre(client);

	if(eClients[client][bRolling])
		ForceRemovePerk(client, 4);

	eClients[client][bRolling]	= false;
	eClients[client][iLastRoll]	= 0;
	eClients[client][iCurPerk]	= -1;
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
	if(IsValidClient(client))
		RollPerkForClient(client);

	return Plugin_Handled;
}

public Action Command_DescMenu(int client, int args){
	if(IsValidClient(client))
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

	int		iPerkTime		= -1;
	bool	bOverrideClass	= false;
	char	sPerkString[16]	= "-";

	if(args > 1){
		GetCmdArg(2, sPerkString, sizeof(sPerkString));

		if(args > 2){
			char sPerkTime[8];
			GetCmdArg(3, sPerkTime, sizeof(sPerkTime));
			iPerkTime = StringToInt(sPerkTime);

			if(args > 3){
				char sOverrideClass[2];
				GetCmdArg(4, sOverrideClass, sizeof(sOverrideClass));

				if(StringToInt(sOverrideClass) > 0)
					bOverrideClass = true;
			}
		}
	}

	int iGroup = -1;
	if(iTrgCount > 1){
		iGroup = GetNextAvailableGroup();
		if(iGroup < 0) return Plugin_Handled;

		eGroup[iGroup][bActive]			= true;
		eGroup[iGroup][iClientCount]	= iTrgCount;

		if(eGroup[iGroup][hClientArray] == INVALID_HANDLE)
			eGroup[iGroup][hClientArray] = CreateArray();

		ClearArray(eGroup[iGroup][hClientArray]);
	}

	for(int i = 0; i < iTrgCount; i++){
		if(iGroup > -1)
			PushArrayCell(eGroup[iGroup][hClientArray], GetClientSerial(aTrgList[i]));

		eClients[aTrgList[i]][iGroupRollId] = iGroup;
		ForcePerk(aTrgList[i], sPerkString, 16, iPerkTime, bOverrideClass, iGroup, client);
	}
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

	bool bFuncCount = (GetForwardFunctionCount(g_hFwdCanRemove) > 0);
	for(int i = 0; i < iTrgCount; i++){
		if(eClients[i][bRolling] && bFuncCount){
			Call_StartForward(g_hFwdCanRemove);
			Call_PushCell(client);
			Call_PushCell(aTrgList[i]);
			Call_PushCell(eClients[aTrgList[i]][iCurPerk]);
			Action result = Plugin_Continue;
			Call_Finish(result);

			if(result != Plugin_Continue)
				continue;
		}

		Forward_OnRemovePerkPre(client);
		if(eClients[aTrgList[i]][bRolling])
			ForceRemovePerk(aTrgList[i], args > 1 ? 5 : 3, sReason);
	}
	return Plugin_Handled;
}

public Action Command_PerkSearchup(int client, int args){
	if(args < 1){
		for(int i = 0; i < g_iPerkCount; i++)
			PrintToConsole(client, "%d. %s", i, ePerks[i][sName]);

		if(client > 0)
			PrintToChat(client, "%s Perk list has been printed to your console.", CHAT_PREFIX);
		return Plugin_Handled;
	}

	char sTagString[64], sTagBuffer[32];
	for(int i = 1; i <= args; i++){
		GetCmdArg(i, sTagBuffer, sizeof(sTagBuffer));
		if(i < 2){
			Format(sTagString, sizeof(sTagString), "%s", sTagBuffer);
			continue;
		}
		Format(sTagString, sizeof(sTagString), "%s|%s", sTagString, sTagBuffer);
	}

	int iPerksFound = 0;
	for(int j = 0; j < g_iPerkCount; j++){
		if(!IsPerkInTags(j, sTagString, args))
			continue;

		PrintToConsole(client, "%d. %s", j, ePerks[j][sName]);
		iPerksFound++;
	}

	if(client > 0)
		PrintToChat(client, "%s %d %s found matching given criteria.", CHAT_PREFIX, iPerksFound, iPerksFound != 1 ? "perks" : "perk");
	return Plugin_Handled;
}

public Action Command_Reload(int client, int args){
	ParseEffects();
	ParseCustomEffects();
	return Plugin_Handled;
}

public Action Command_Update(int client, int args){
	if(!g_bPluginUpdater){
		ReplyToCommand(client, "%s Updater is not installed.", CONS_PREFIX);
		return Plugin_Handled;
	}

	g_bIsUpdateForced = true;
	if(Updater_ForceUpdate())
		ReplyToCommand(client, "%s New RTD version available!", CONS_PREFIX);
	else ReplyToCommand(client, "%s This RTD version is up to date or unable to update.", CONS_PREFIX);

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
	if(hCvar == g_hCvarCanRepeatPerk)
		g_bCvarCanRepeatPerk = StringToInt(sNew) > 0 ? true : false;

	else if(hCvar == g_hCvarCanRepeatGreatPerk)
		g_bCvarCanRepeatGreatPerk = StringToInt(sNew) > 0 ? true : false;
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
	if(!IsValidClient(client))
		return Plugin_Continue;

	int flags = GetEventInt(hEvent, "death_flags");
	if(flags & FLAG_FEIGNDEATH)
		return Plugin_Continue;

	Forward_OnRemovePerkPre(client);

	if(!eClients[client][bRolling])
		return Plugin_Continue;

	ForceRemovePerk(client, 1);
	return Plugin_Continue;
}

public Action Event_ClassChange(Handle hEvent, const char[] sEventName, bool dontBroadcast){
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(client))
		return Plugin_Continue;

	Forward_OnRemovePerkPre(client);
	if(!eClients[client][bRolling])
		return Plugin_Continue;

	ForceRemovePerk(client, 2);
	return Plugin_Continue;
}

public Action Event_RoundActive(Handle hEvent, const char[] sEventName, bool dontBroadcast){
	if(g_bCvarPluginEnabled && (g_iCvarChat & CHAT_AD) && IsRTDInRound())
		PrintToChatAll("%s %T", CHAT_PREFIX, "RTD2_Ad", LANG_SERVER, 0x03, 0x01);

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
		LogError("%s Failed to find rtd2_perks.default.cfg in configs/ folder!", CONS_PREFIX);
		SetFailState("Failed to find rtd2_perks.default.cfg in configs/ folder!");
		return false;
	}

	if(g_hPerkContainer == null)
		g_hPerkContainer = new PerkContainer();
	g_hPerkContainer.DisposePerks();

	int iStatus[2];
	int iParsed = g_hPerkContainer.ParseFile(sPath, iStatus);
	if(iParsed == -1){
		LogError("%s Parsing rtd2_perks.default.cfg failed!", CONS_PREFIX);
		SetFailState("Parsing rtd2_perks.default.cfg failed!");
		return false;
	}

	PrintToServer("%s Loaded %d perk%s (%d good, %d bad).", CONS_PREFIX, iParsed, iParsed > 1 ? "s" : "", iStatus[1], iStatus[0]);
	return true;
}

void ParseCustomEffects(){
	char sPath[255];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/rtd2_perks.custom.cfg");
	if(!FileExists(sPath)){
		PrecachePerkSounds();
		return;
	}

	int iCustomPerkCount = 0;
	Handle hKv = CreateKeyValues("Effects");
	if(FileToKeyValues(hKv, sPath) && KvGotoFirstSubKey(hKv)){
		Handle hCustomized = CreateArray();
		char sPerkId[4], sClassBuffer[2][PERK_MAX_LOW], sWeaponBuffer[2][PERK_MAX_HIGH], sSettingBuffer[PERK_MAX_HIGH], sTagBuffer[2][PERK_MAX_HIGH];
		int iPerkId = 0, iClassFlags = 0, iTagSize = 0;
		do{
			KvGetSectionName(hKv, sPerkId, sizeof(sPerkId));
			iPerkId = StringToInt(sPerkId);
			if(iPerkId >= g_iPerkCount || iPerkId < 0)
				continue;

				//----[ NAME ]----//
			if(KvJumpToKey(hKv, "name")){
				KvGoBack(hKv);
				KvGetString(hKv, "name", ePerks[iPerkId][sName], PERK_MAX_LOW);
			}

				//----[ GOOD ]----//
			if(KvJumpToKey(hKv, "good")){
				KvGoBack(hKv);
				ePerks[iPerkId][bGood] = KvGetNum(hKv, "good") > 0 ? true : false;
			}

				//----[ SOUND ]----//
			if(KvJumpToKey(hKv, "sound")){
				KvGoBack(hKv);
				KvGetString(hKv, "sound", ePerks[iPerkId][sSound], PERK_MAX_HIGH);
			}

				//----[ TOKEN ]----//
			if(KvJumpToKey(hKv, "token")){
				KvGoBack(hKv);
				KvGetString(hKv, "token", ePerks[iPerkId][sToken], PERK_MAX_LOW);
			}

				//----[ TIME ]----//
			if(KvJumpToKey(hKv, "time")){
				KvGoBack(hKv);
				ePerks[iPerkId][iTime] = KvGetNum(hKv, "time");
			}

				//----[ CLASS ]----//
			if(KvJumpToKey(hKv, "class")){
				KvGoBack(hKv);

				strcopy(sClassBuffer[1], PERK_MAX_LOW, "");
				KvGetString(hKv, "class", sClassBuffer[0], PERK_MAX_LOW, "0");
				EscapeString(sClassBuffer[0], ' ', '\0', sClassBuffer[1], PERK_MAX_LOW);

				iClassFlags = ClassStringToFlags(sClassBuffer[1]);
				if(iClassFlags < 1){
					PrintToServer("%s WARNING: Invalid class restriction(s) set at perk ID:%d (rtd2_perks.custom.cfg). Assuming it's all-class. (\"%s\")", CONS_PREFIX, iPerkId, sClassBuffer[1]);
					LogError("%s WARNING: Invalid class restriction(s) set at perk ID:%d (rtd2_perks.custom.cfg). Assuming it's all-class. (\"%s\")", CONS_PREFIX, iPerkId, sClassBuffer[1]);
					iClassFlags = 511;
				}
				ePerks[iPerkId][iClasses] = iClassFlags;
			}

				//----[ WEAPONS ]----//
			if(KvJumpToKey(hKv, "weapons")){
				KvGoBack(hKv);

				strcopy(sWeaponBuffer[1], PERK_MAX_HIGH, "");
				KvGetString(hKv, "weapons", sWeaponBuffer[0], PERK_MAX_HIGH);
				EscapeString(sWeaponBuffer[0], ' ', '\0', sWeaponBuffer[1], PERK_MAX_HIGH);

				ClearArray(ePerks[iPerkId][hWeaponClasses]);
				if(FindCharInString(sWeaponBuffer[1], '0') < 0){
					int iSize = CountCharInString(sWeaponBuffer[1], ',')+1;
					char[][] sPieces = new char[iSize][32];

					ExplodeString(sWeaponBuffer[1], ",", sPieces, iSize, 64);
					for(int i = 0; i < iSize; i++)
						PushArrayString(ePerks[iPerkId][hWeaponClasses], sPieces[i]);
				}
			}

				//----[ SETTINGS ]----//
			if(KvJumpToKey(hKv, "settings")){
				KvGoBack(hKv);

				KvGetString(hKv, "settings", sSettingBuffer, PERK_MAX_HIGH);
				EscapeString(sSettingBuffer, ' ', '\0', ePerks[iPerkId][sPref], PERK_MAX_HIGH);
			}

				//----[ TAGS ]----//
			if(KvJumpToKey(hKv, "tags")){
				KvGoBack(hKv);

				strcopy(sTagBuffer[1], PERK_MAX_HIGH, ""); iTagSize = 0;
				KvGetString(hKv, "tags", sTagBuffer[0], PERK_MAX_VERYH);
				EscapeString(sTagBuffer[0], ' ', '\0', sTagBuffer[1], PERK_MAX_VERYH);

				ClearArray(ePerks[iPerkId][hTags]);
				if(strlen(sTagBuffer[1]) > 0){
					iTagSize = CountCharInString(sTagBuffer[1], '|')+1;
					char[][] sPieces = new char[iTagSize][24];

					ExplodeString(sTagBuffer[1], "|", sPieces, iTagSize, 24);
					for(int i = 0; i < iTagSize; i++)
						PushArrayString(ePerks[iPerkId][hTags], sPieces[i]);
				}
			}

			if(FindValueInArray(hCustomized, iPerkId) > -1)
				continue;

			iCustomPerkCount++;
			PushArrayCell(hCustomized, iPerkId);
		}while(KvGotoNextKey(hKv));

		PrintToServer("%s Customized %d perk%s.", CONS_PREFIX, iCustomPerkCount, iCustomPerkCount == 1 ? "" : "s");
		delete hCustomized;
	}

	if(hKv != INVALID_HANDLE)
		CloseHandle(hKv);
	PrecachePerkSounds();
}

void PrecachePerkSounds(){
	for(int i = 0; i < g_iPerkCount; i++)
		PrecacheSound(ePerks[i][sSound]);
}

void ParseDisabledPerks(){
	for(int i = 0; i < g_iPerkCount; i++)
		ePerks[i][bIsDisabled] = false;

	char sDisabled[2][255];
	GetConVarString(g_hCvarDisabledPerks, sDisabled[0], 255);
	EscapeString(sDisabled[0], ' ', '\0', sDisabled[1], 255);
	if(strlen(sDisabled[1]) == 0)
		return;

	int iDisabledNum = CountCharInString(sDisabled[1], ',') +1;
	char[][] sDisabledPieces = new char[iDisabledNum][32];
	ExplodeString(sDisabled[1], ",", sDisabledPieces, iDisabledNum, 32);

	int iPerkId = -1, iArraySize = 0;
	Handle hDisabledArray = CreateArray();
	for(int i = 0; i < iDisabledNum; i++){
		iPerkId = GetPerkOfString(sDisabledPieces[i], 32);
		if(iPerkId < 0)
			continue;

		if(FindValueInArray(hDisabledArray, iPerkId) != -1)
			continue;

		ePerks[iPerkId][bIsDisabled] = true;
		PushArrayCell(hDisabledArray, iPerkId);
		iArraySize++;
	}

	switch(iArraySize){
		case 0:{}

		case 1:{
			if(g_bCvarLog)
				LogMessage("%s Perk disabled: %s.", CONS_PREFIX, ePerks[GetArrayCell(hDisabledArray, 0)][sName]);
			PrintToServer("%s Perk disabled: %s.", CONS_PREFIX, ePerks[GetArrayCell(hDisabledArray, 0)][sName]);
		}

		default:{
			if(g_bCvarLog)
				LogMessage("%s %d perks disabled:", CONS_PREFIX, iArraySize);
			PrintToServer("%s %d perks disabled:", CONS_PREFIX, iArraySize);
			for(int i = 0; i < iArraySize; i++){
				if(g_bCvarLog)
					LogMessage("  • %s", ePerks[GetArrayCell(hDisabledArray, i)][sName]);
				PrintToServer("  > %s", ePerks[GetArrayCell(hDisabledArray, i)][sName]);
			}
		}
	}
	delete hDisabledArray;
}

//-----[ Applying ]-----//
void RollPerkForClient(int client){
	if(!g_bCvarPluginEnabled){
		if(g_iCvarChat & CHAT_REASONS)
			PrintToChat(client, "%s %T", CHAT_PREFIX, "RTD2_Cant_Roll_Disabled", LANG_SERVER);
		return;
	}

	if(!IsRollerAllowed(client)){
		if(g_iCvarChat & CHAT_REASONS)
			PrintToChat(client, "%s %T", CHAT_PREFIX, "RTD2_Cant_Roll_No_Access", LANG_SERVER);
		return;
	}

	if(!IsRTDInRound()){
		if(g_iCvarChat & CHAT_REASONS)
			PrintToChat(client, "%s %T", CHAT_PREFIX, "RTD2_Not_In_Round", LANG_SERVER);
		return;
	}

	if(g_iCvarRtdTeam > 0 && g_iCvarRtdTeam == GetClientTeam(client)-1){
		if(g_iCvarChat & CHAT_REASONS)
			PrintToChat(client, "%s %T", CHAT_PREFIX, "RTD2_Cant_Roll_Team", LANG_SERVER);
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
			PrintToChat(client, "%s %T", CHAT_PREFIX, "RTD2_Cant_Roll_Alive", LANG_SERVER);
		return;
	}

	if(eClients[client][bRolling]){
		if(g_iCvarChat & CHAT_REASONS)
			PrintToChat(client, "%s %T", CHAT_PREFIX, "RTD2_Cant_Roll_Using", LANG_SERVER);
		return;
	}

	int iTimeLeft = eClients[client][iLastRoll] +g_iCvarRollInterval;
	if(GetTime() < iTimeLeft){
		if(g_iCvarChat & CHAT_REASONS)
			PrintToChat(client, "%s %T", CHAT_PREFIX, "RTD2_Cant_Roll_Wait", LANG_SERVER, 0x04, iTimeLeft -GetTime(), 0x01);
		return;
	}

	switch(g_iCvarRtdMode){
		case 1:{
			int iCount = 0;
			for(int i = 1; i <= MaxClients; i++){
				if(eClients[i][bRolling])
					iCount++;
			}

			if(iCount >= g_iCvarClientLimit){
				if(g_iCvarChat & CHAT_REASONS)
					PrintToChat(client, "%s %T", CHAT_PREFIX, "RTD2_Cant_Roll_Mode1", LANG_SERVER);
				return;
			}
		}

		case 2:{
			int iCount = 0, iTeam = GetClientTeam(client);
			for(int i = 1; i <= MaxClients; i++){
				if(eClients[i][bRolling])
					if(GetClientTeam(i) == iTeam)
						iCount++;
			}

			if(iCount >= g_iCvarTeamLimit){
				if(g_iCvarChat & CHAT_REASONS)
					PrintToChat(client, "%s %T", CHAT_PREFIX, "RTD2_Cant_Roll_Mode2", LANG_SERVER);
				return;
			}
		}
	}

	int iPerkId = RollPerk(client);
	ApplyPerk(client, iPerkId);
	if(g_bCvarLog)
		LogMessage("%L rolled %s(ID: %d).", client, ePerks[iPerkId][sName], iPerkId);
}

int ForcePerk(int client, const char[] sPerkString, int iPerkStringSize=32, int iPerkTime=-1, bool bOverrideClass=false, int iGroup=-1, int initiator=0){
	if(!IsValidClient(client))
		return -4;

	bool bIsValidInitiator = IsValidClient(initiator);
	if(eClients[client][bRolling]){
		if(iGroup < 0){
			if(bIsValidInitiator)
				PrintToChat(initiator, "%s %N is already using RTD.", CHAT_PREFIX, client);
			else PrintToServer("%s %N is already using RTD.", CONS_PREFIX, client);
		}
		return -3;
	}

	if(!IsPlayerAlive(client)){
		if(iGroup < 0){
			if(bIsValidInitiator)
				PrintToChat(initiator, "%s %N is dead.", CHAT_PREFIX, client);
			else PrintToServer("%s %N is already using RTD.", CONS_PREFIX, client);
		}
		return -2;
	}

	int iPerkId = GetPerkOfString(sPerkString, iPerkStringSize);
	bool bSamePerk = true;
	int iApplicats = iGroup < 0 ? 1 : eGroup[iGroup][iClientCount];
	if(iPerkId < 0 || iPerkId >= g_iPerkCount){
		bSamePerk = false;
		if(!g_bTempPrint){
			if(bIsValidInitiator)
				PrintToChat(initiator, "%s Perk not found or invalid info, forcing %s.", CHAT_PREFIX, iApplicats > 1 ? "rolls" : "a roll");
			else PrintToServer("%s Perk not found or invalid info, forcing %s.", CONS_PREFIX, iApplicats > 1 ? "rolls" : "a roll");
		}

		iPerkId = RollPerk(client, true, bOverrideClass, false, false, !StrEqual(sPerkString, "-"), sPerkString);
		if(iPerkId < 0){
			if(bIsValidInitiator)
				PrintToChat(initiator, "%s No perks available for %N.", CHAT_PREFIX, client);
			else PrintToServer("%s No perks available for %N.", CONS_PREFIX, client);
			return -1;
		}
	}

	if(bIsValidInitiator && GetForwardFunctionCount(g_hFwdCanForce) > 0){
		Call_StartForward(g_hFwdCanForce);
		Call_PushCell(initiator);
		Call_PushCell(client);
		Call_PushCell(iPerkId);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if(result != Plugin_Continue)
			return -5;
	}

	ApplyPerk(client, iPerkId, iPerkTime, iGroup, bSamePerk ? iPerkId : -1);
	if(g_bCvarLog){
		if(bIsValidInitiator)
			LogMessage("A perk %s(ID: %d) has been forced on %L for %d seconds by %L.", ePerks[iPerkId][sName], iPerkId, client, iPerkTime, initiator);
		else LogMessage("A perk %s(ID: %d) has been forced on %L for %d seconds.", ePerks[iPerkId][sName], iPerkId, client, iPerkTime);
	}

	return iPerkId;
}

//-----[ General ]-----//
int RollPerk(int client=0, bool bOverrideDisabled=false, bool bOverrideClass=false, bool bCountRepeat=true, bool bCountGreatRepeat=true, bool bUseFilter=false, const char[] sTagFilter=""){
	float fGoodChance = g_fCvarGoodChance;
	if(IsValidClient(client) && IsRollerDonator(client))
		fGoodChance = g_fCvarGoodDonatorChance;

	bool bGoodPerk = fGoodChance > GetURandomFloat() ? true : false;
	Handle hAvailablePerks = CreateArray();
	for(int i = 0; i < g_iPerkCount; i++){
		if(!bUseFilter){
			if(ePerks[i][bGood] != bGoodPerk)
				continue;

			if(!bOverrideDisabled)
				if(ePerks[i][bIsDisabled])
					continue;

			if(IsValidClient(client)){
				if(bCountRepeat)
					if(!g_bCvarCanRepeatPerk)
						if(i == eClients[client][iLastPerk])
							continue;

				if(bCountGreatRepeat)
					if(!g_bCvarCanRepeatGreatPerk)
						if(i == eClients[client][iGreatLastPerk])
							continue;
			}
		}else if(!IsPerkInTags(i, sTagFilter, CountCharInString(sTagFilter, '|')+1))
			continue;

		if(!bOverrideClass)
			if(!PerkAllowedForClassOf(client, i))
				continue;

		if(!PerkAllowedForWeaponsOf(client, i))
			continue;

		PushArrayCell(hAvailablePerks, i);
	}

	int iPerkNum = GetArraySize(hAvailablePerks);
	int iUsingHandle = 0;
	Handle hAvailablePerks2 = CreateArray();
	int iPerkNum2 = -1;
	if(!iPerkNum){
		for(int i = 0; i < g_iPerkCount; i++){
			if(!bUseFilter){
				if(ePerks[i][bGood] == bGoodPerk)
					continue;

				if(!bOverrideDisabled)
					if(ePerks[i][bIsDisabled])
						continue;

				if(IsValidClient(client)){
					if(bCountRepeat)
						if(!g_bCvarCanRepeatPerk)
							if(i == eClients[client][iLastPerk])
								continue;

					if(bCountGreatRepeat)
						if(!g_bCvarCanRepeatGreatPerk)
							if(i == eClients[client][iGreatLastPerk])
								continue;
				}
			}else if(!IsPerkInTags(i, sTagFilter, CountCharInString(sTagFilter, ',')+1))
				continue;

			if(!bOverrideClass)
				if(!PerkAllowedForClassOf(client, i))
					continue;

			if(!PerkAllowedForWeaponsOf(client, i))
				continue;

			PushArrayCell(hAvailablePerks2, i);
		}
		iPerkNum2 = GetArraySize(hAvailablePerks2);
		if(iPerkNum2)
			iUsingHandle = 2;

	}else iUsingHandle = 1;

	int iPerkId = -1;
	switch(iUsingHandle){
		case 1:{iPerkId = GetArrayCell(hAvailablePerks, GetRandomInt(0, iPerkNum-1));}
		case 2:{iPerkId = GetArrayCell(hAvailablePerks2, GetRandomInt(0, iPerkNum2-1));}
	}

	delete hAvailablePerks;
	if(!iPerkNum)
		delete hAvailablePerks2;

	return iPerkId;
}

void ApplyPerk(int client, int iPerk, int iPerkTime=-1, int iGroup=-1, int iSamePerk=-1){
	if(!IsValidClient(client))
		return;

	EmitSoundToAll(ePerks[iPerk][sSound], client);
	ManagePerk(client, iPerk, true);
	int iDuration = -1;
	if(ePerks[iPerk][iTime] > -1){
		iDuration = (iPerkTime > -1) ? iPerkTime : (ePerks[iPerk][iTime] > 0) ? ePerks[iPerk][iTime] : g_iCvarPerkDuration;
		int iSerial = GetClientSerial(client);

		eClients[client][bRolling]	= true;
		eClients[client][iCurPerk]	= iPerk;
		eClients[client][iPerkEnd]	= GetTime() + iDuration;
		eClients[client][hPerkTimer]= CreateTimer(float(iDuration), Timer_RemovePerk, iSerial);
		DisplayPerkTimeFrame(client);
		CreateTimer(1.0, Timer_Countdown, iSerial, TIMER_REPEAT);
	}else eClients[client][iLastRoll] = GetTime();

	Forward_PerkApplied(client, iPerk, iDuration);
	eClients[client][iGreatLastPerk]= eClients[client][iLastPerk];
	eClients[client][iLastPerk]		= iPerk;

	PrintToRoller(client, iPerk, iDuration);
	if(iGroup < 0 || iSamePerk < 0){
		PrintToNonRollers(client, iPerk, iDuration);
		if(iSamePerk < 0){
			g_bTempPrint = true;
			CreateTimer(0.1, Timer_ReloadTempPrint);
		}

		if(iGroup > -1)
			eGroup[iGroup][iGroupPerkId] = -1;

		return;
	}

	if(g_bTempPrint)	//----- Past this point, execution happens once -----//
		return;

	PrintGroupRolls(eGroup[iGroup][iClientCount], iSamePerk, iDuration);

	g_bTempPrint = true;
	CreateTimer(0.1, Timer_ReloadTempPrint);
	if(ePerks[iSamePerk][iTime] < 0)
		return;

	eGroup[iGroup][iGroupPerkId] = iSamePerk;
	CreateTimer(float(iDuration), Timer_PrintGroupEnd, iGroup);
}

//-----[ Descriptions ]-----//
Handle BuildDesc(){
	Handle hMenu = CreateMenu(ManagerDesc);
	SetMenuTitle(hMenu, "%T", "RTD2_Menu_Title", LANG_SERVER);
	for(int i = 0; i < g_iCorePerkCount; i++)
		AddMenuItem(hMenu, "", ePerks[i][sName]);

	SetMenuExitBackButton(hMenu, false);
	SetMenuExitButton(hMenu, true);

	return hMenu;
}

void ShowDesc(int client, int iPos=0){
	if(iPos == 0)
		DisplayMenu(g_hDescriptionMenu, client, MENU_TIME_FOREVER);
	else DisplayMenuAtItem(g_hDescriptionMenu, client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
}

public int ManagerDesc(Handle hMenu, MenuAction maState, int client, int iPos){
	if(maState != MenuAction_Select)
		return 0;

	char sTranslatePos[16];
	Format(sTranslatePos, sizeof(sTranslatePos), "RTD2_Desc_%d", iPos);
	PrintToChat(client, "%s %s%s%c: \x03%T\x01", CHAT_PREFIX,
		ePerks[iPos][bGood] ? PERK_COLOR_GOOD : PERK_COLOR_BAD,
		ePerks[iPos][sName], 0x01,
		sTranslatePos, LANG_SERVER);

	ShowDesc(client, iPos);
	return 1;
}

//-----[ Timers ]-----//
public Action Timer_ReloadTempPrint(Handle hTimer){
	g_bTempPrint = false;
	return Plugin_Stop;
}

public Action Timer_PrintGroupEnd(Handle hTimer, int iGroup){
	if(!eGroup[iGroup][bActive])
		return Plugin_Stop;

	int iSize = eGroup[iGroup][iClientCount];
	if(iSize < 1)
		return Plugin_Stop;

	int iPerk = eGroup[iGroup][iGroupPerkId];
	if(iPerk > -1){
		char sReason[128];
		Format(sReason, sizeof(sReason), "%s %T", CHAT_PREFIX,
			"RTD2_Remove_Perk_Group_Same", LANG_SERVER,
			ePerks[iPerk][bGood] ? PERK_COLOR_GOOD : PERK_COLOR_BAD,
			ePerks[iPerk][sName],
			0x01,
			iSize);
		PrintToChatAll(sReason);
	}

	eGroup[iGroup][bActive] = false;
	return Plugin_Stop;
}

public Action Timer_Countdown(Handle hTimer, int iSerial){
	int client = GetClientFromSerial(iSerial);
	if(!IsValidClient(client))
		return Plugin_Stop;

	if(!eClients[client][bRolling])
		return Plugin_Stop;

	DisplayPerkTimeFrame(client);
	return Plugin_Continue;
}

public Action Timer_RemovePerk(Handle hTimer, int iSerial){
	int client = GetClientFromSerial(iSerial);
	if(!IsValidClient(client))
		return Plugin_Stop;

	if(g_bCvarLog)
		LogMessage("Perk %s(ID: %d) ended on %L.", ePerks[eClients[client][iCurPerk]][sName], eClients[client][iCurPerk], client);

	ManagePerk(client, eClients[client][iCurPerk], false);
	return Plugin_Handled;
}

//-----[ Removing ]-----//
int ForceRemovePerk(int client, int iReason=3, const char[] sReason=""){
	if(!IsValidClient(client))
		return -1;

	int iClientPerk = eClients[client][iCurPerk];
	int iGroup = eClients[client][iGroupRollId];
	if(iGroup > -1){
		if(eGroup[iGroup][bActive]){
			int iPos = FindValueInArray(eGroup[iGroup][hClientArray], GetClientSerial(client));
			if(iPos > -1){
				RemoveFromArray(eGroup[iGroup][hClientArray], iPos);
				eGroup[iGroup][iClientCount]--;
			}

			if(eGroup[iGroup][iClientCount] < 1)
				eGroup[iGroup][bActive] = false;
		}
	}

	ManagePerk(client, iClientPerk , false, iReason, sReason);
	return iClientPerk;
}

void RemovedPerk(int client, int iReason, const char[] sReason=""){
	eClients[client][bRolling]	= false;
	eClients[client][iLastRoll]	= GetTime();

	Forward_PerkRemoved(client, eClients[client][iCurPerk], iReason);
	eClients[client][iCurPerk]	= -1;

	int iGroup = eClients[client][iGroupRollId];
	if(iGroup < 0)
		PrintPerkEndReason(client, iReason, sReason);
	else if(eGroup[iGroup][iGroupPerkId] < 0)
			PrintPerkEndReason(client, iReason, sReason);

	eClients[client][iGroupRollId] = -1;
	KillTimerSafe(eClients[client][hPerkTimer]);
}

//-----[ Printing ]-----//
void PrintToRoller(int client, int iPerk, int iDuration){
	if(!(g_iCvarChat & CHAT_APPROLLER))
		return;

	if(!g_bCvarShowTime || ePerks[iPerk][iTime] == -1)
		PrintToChat(client, "%s %T", CHAT_PREFIX,
			"RTD2_Rolled_Perk_Roller", LANG_SERVER,
			ePerks[iPerk][bGood] ? PERK_COLOR_GOOD : PERK_COLOR_BAD,
			ePerks[iPerk][sName],
			0x01);
	else{
		int iTrueDuration = (iDuration > -1) ? iDuration : (ePerks[iPerk][iTime] > 0) ? ePerks[iPerk][iTime] : g_iCvarPerkDuration;
		PrintToChat(client, "%s %T", CHAT_PREFIX,
			"RTD2_Rolled_Perk_Roller_Time", LANG_SERVER,
			ePerks[iPerk][bGood] ? PERK_COLOR_GOOD : PERK_COLOR_BAD,
			ePerks[iPerk][sName],
			0x01, 0x03, iTrueDuration, 0x01);
	}
}

void PrintToNonRollers(int client, int iPerk, int iDuration){
	if(!(g_iCvarChat & CHAT_APPOTHER))
		return;

	char sOthersPrint[128], sRollerName[MAX_NAME_LENGTH];
	GetClientName(client, sRollerName, sizeof(sRollerName));
	if(!g_bCvarShowTime || ePerks[iPerk][iTime] == -1)
		Format(sOthersPrint, sizeof(sOthersPrint), "%s %T", CHAT_PREFIX,
			"RTD2_Rolled_Perk_Others", LANG_SERVER,
			g_sTeamColors[GetClientTeam(client)],
			sRollerName,
			0x01,
			ePerks[iPerk][bGood] ? PERK_COLOR_GOOD : PERK_COLOR_BAD,
			ePerks[iPerk][sName], 0x01);
	else{
		int iTrueDuration = (iDuration > -1) ? iDuration : (ePerks[iPerk][iTime] > 0) ? ePerks[iPerk][iTime] : g_iCvarPerkDuration;
		Format(sOthersPrint, sizeof(sOthersPrint), "%s %T", CHAT_PREFIX,
			"RTD2_Rolled_Perk_Others_Time", LANG_SERVER,
			g_sTeamColors[GetClientTeam(client)],
			sRollerName,
			0x01,
			ePerks[iPerk][bGood] ? PERK_COLOR_GOOD : PERK_COLOR_BAD,
			ePerks[iPerk][sName], 0x01, 0x03, iTrueDuration, 0x01);
	}
	PrintToChatAllExcept(client, sOthersPrint);
}

void PrintGroupRolls(int iApplications, int iPerk, int iDuration){
	if(!(g_iCvarChat & CHAT_APPOTHER))
		return;

	char sReason[128];
	if(!g_bCvarShowTime || ePerks[iPerk][iTime] == -1)
		Format(sReason, sizeof(sReason), "%s %T", CHAT_PREFIX,
			"RTD2_Rolled_Perk_Multi", LANG_SERVER,
			iApplications,
			ePerks[iPerk][bGood] ? PERK_COLOR_GOOD : PERK_COLOR_BAD,
			ePerks[iPerk][sName],
			0x01);
	else{
		int iTrueDuration = (iDuration > -1) ? iDuration : (ePerks[iPerk][iTime] > 0) ? ePerks[iPerk][iTime] : g_iCvarPerkDuration;
		Format(sReason, sizeof(sReason), "%s %T", CHAT_PREFIX,
			"RTD2_Rolled_Perk_Multi_Time", LANG_SERVER,
			iApplications,
			ePerks[iPerk][bGood] ? PERK_COLOR_GOOD : PERK_COLOR_BAD,
			ePerks[iPerk][sName],
			0x01, 0x03, iTrueDuration, 0x01);
	}
	PrintToChatAll(sReason);
}

void PrintPerkEndReason(int client, int iReason=3, const char[] sCustomReason=""){
	char sReasonSelf[32], sReasonOthers[32];
	switch(iReason){
		case 0:{
			strcopy(sReasonSelf, sizeof(sReasonSelf), "RTD2_Remove_Perk_Unload_Self");
			strcopy(sReasonOthers, sizeof(sReasonOthers), "RTD2_Remove_Perk_Unload_Others");
		}

		case 1:{
			strcopy(sReasonSelf, sizeof(sReasonSelf), "RTD2_Remove_Perk_Died_Self");
			strcopy(sReasonOthers, sizeof(sReasonOthers), "RTD2_Remove_Perk_Died_Others");
		}

		case 2:{
			strcopy(sReasonSelf, sizeof(sReasonSelf), "RTD2_Remove_Perk_Class_Self");
			strcopy(sReasonOthers, sizeof(sReasonOthers), "RTD2_Remove_Perk_Class_Others");
		}

		case 3:{
			strcopy(sReasonSelf, sizeof(sReasonSelf), "RTD2_Remove_Perk_End_Self");
			strcopy(sReasonOthers, sizeof(sReasonOthers), "RTD2_Remove_Perk_End_Others");
		}

		case 4:{
			strcopy(sReasonSelf, sizeof(sReasonSelf), "0");
			strcopy(sReasonOthers, sizeof(sReasonOthers), "RTD2_Remove_Perk_Disconnected");
		}

		case 5:{
			strcopy(sReasonSelf, sizeof(sReasonSelf), "RTD2_Remove_Perk_Custom_Self");
			strcopy(sReasonOthers, sizeof(sReasonOthers), "RTD2_Remove_Perk_Custom_Others");
		}
	}

	if(sReasonSelf[0] != '0' && (g_iCvarChat & CHAT_REMROLLER))
		PrintToChat(client, "%s %T", CHAT_PREFIX, sReasonSelf, LANG_SERVER, iReason > 4 ? sCustomReason : "");

	if(!(g_iCvarChat & CHAT_REMOTHER))
		return;

	char sPrintReasonToOthers[128];
	Format(sPrintReasonToOthers, sizeof(sPrintReasonToOthers), "%s %T", CHAT_PREFIX, sReasonOthers, LANG_SERVER, g_sTeamColors[GetClientTeam(client)], client, 0x01, iReason > 4 ? sCustomReason : "");
	PrintToChatAllExcept(client, sPrintReasonToOthers);
}



			//*************************//
			//----  N A T I V E S  ----//
			//*************************//

public int Native_GetClientPerkId(Handle hPlugin, int iParams){
	return eClients[GetNativeCell(1)][iCurPerk];
}

public int Native_GetClientPerkTime(Handle hPlugin, int iParams){
	int client = GetNativeCell(1);
	return eClients[client][bRolling] ? eClients[client][iPerkEnd] -GetTime() : -1;
}

public int Native_ForcePerk(Handle hPlugin, int iParams){
	char sPerkString[32]; int iStringSize = sizeof(sPerkString);
	GetNativeString(2, sPerkString, iStringSize);
	return ForcePerk(
		GetNativeCell(1),
		sPerkString,
		iStringSize,
		GetNativeCell(3),
		GetNativeCell(4) > 0 ? true : false,
		GetNativeCell(5)
	);
}

public int Native_RollPerk(Handle hPlugin, int iParams){
	return RollPerk(
		GetNativeCell(1),
		GetNativeCell(2) > 0 ? true : false,
		GetNativeCell(3) > 0 ? true : false,
		GetNativeCell(4) > 0 ? true : false,
		GetNativeCell(5) > 0 ? true : false
	);
}

public int Native_RemovePerk(Handle hPlugin, int iParams){
	char sReason[32]; GetNativeString(3, sReason, sizeof(sReason));
	int client = GetNativeCell(1);

	Forward_OnRemovePerkPre(client);
	if(!eClients[client][bRolling])
		return -1;

	return ForceRemovePerk(
		client,
		GetNativeCell(2),
		sReason
	);
}

public int Native_GetPerkOfString(Handle hPlugin, int iParams){
	char sString[32]; int iSize = sizeof(sString);
	GetNativeString(1, sString, iSize);
	return GetPerkOfString(sString, iSize);
}

public int Native_RegisterPerk(Handle hPlugin, int iParams){
	char sPluginName[32];
	GetPluginFilename(hPlugin, sPluginName, sizeof(sPluginName));
	if(!g_bIsRegisteringOpen){
		ThrowNativeError(SP_ERROR_NATIVE, "%s Plugin \"%s\" is trying to register perks before it's possible.\nPlease use the forward RTD2_OnRegOpen() and native RTD2_IsRegOpen() to determine.", CONS_PREFIX, sPluginName);
		return -1;
	}

	if(g_iPerkCount >= PERK_MAX_COUNT-1){
		ThrowNativeError(SP_ERROR_NATIVE, "%s No space for new perks.\nPlease recompile the core increasing \"PERK_MAX_COUNT\" define.", CONS_PREFIX);
		return -1;
	}

	char sTokenBuffer[2][PERK_MAX_LOW], sClassBuffer[2][PERK_MAX_LOW], sWeaponsBuffer[2][PERK_MAX_HIGH], sTagsBuffer[2][PERK_MAX_VERYH];

		//---[ Token ]---//
	GetNativeString(1, sTokenBuffer[0], PERK_MAX_LOW);
	EscapeString(sTokenBuffer[0], ' ', '\0', sTokenBuffer[1], PERK_MAX_LOW);

	int iPerkId = FindPerkByToken(sTokenBuffer[1]);
	if(iPerkId == -1){
		iPerkId = g_iPerkCount;
		g_iPerkCount++;
	}

	strcopy(ePerks[iPerkId][sToken], PERK_MAX_LOW, sTokenBuffer[1]);

		//---[ Name ]---//
	GetNativeString(2, ePerks[iPerkId][sName], PERK_MAX_LOW);

		//---[ Good ]---//
	ePerks[iPerkId][bGood] = GetNativeCell(3) > 0 ? true : false;

		//---[ Sound ]---//
	GetNativeString(4, ePerks[iPerkId][sSound], PERK_MAX_HIGH);
	PrecacheSound(ePerks[iPerkId][sSound]);

		//---[ Time ]---//
	ePerks[iPerkId][iTime] = GetNativeCell(5);

		//---[ Class ]---//
	strcopy(sClassBuffer[1], PERK_MAX_LOW, "");
	GetNativeString(6, sClassBuffer[0], PERK_MAX_LOW);
	EscapeString(sClassBuffer[0], ' ', '\0', sClassBuffer[1], PERK_MAX_LOW);

	int iClassFlags = ClassStringToFlags(sClassBuffer[1]);
	if(iClassFlags < 1){
		PrintToServer("%s WARNING: A plugin \"%s\" is registering a perk with invalid class restriction(s) for perk \"%s\". Assuming it's all-class.", CONS_PREFIX, sPluginName, ePerks[g_iPerkCount][sName]);
		LogError("%s WARNING: A plugin \"%s\" is registering a perk with invalid class restriction(s) for perk \"%s\". Assuming it's all-class.", CONS_PREFIX, sPluginName, ePerks[g_iPerkCount][sName]);
		iClassFlags = 511;
	}

	ePerks[iPerkId][iClasses] = iClassFlags;

		//---[ Weapons ]---//
	strcopy(sWeaponsBuffer[1], PERK_MAX_HIGH, "");
	GetNativeString(7, sWeaponsBuffer[0], PERK_MAX_HIGH);
	EscapeString(sWeaponsBuffer[0], ' ', '\0', sWeaponsBuffer[1], PERK_MAX_HIGH);

	if(ePerks[iPerkId][hWeaponClasses] == INVALID_HANDLE)
		ePerks[iPerkId][hWeaponClasses] = CreateArray(32);
	else ClearArray(ePerks[iPerkId][hWeaponClasses]);

	if(FindCharInString(sWeaponsBuffer[1], '0') < 0){
		int iSize = CountCharInString(sWeaponsBuffer[1], ',')+1;
		char[][] sPieces = new char[iSize][32];

		ExplodeString(sWeaponsBuffer[1], ",", sPieces, iSize, 64);
		for(int i = 0; i < iSize; i++)
			PushArrayString(ePerks[iPerkId][hWeaponClasses], sPieces[i]);
	}

		//---[ Tags ]---//
	strcopy(sTagsBuffer[1], PERK_MAX_VERYH, "");
	GetNativeString(8, sTagsBuffer[0], PERK_MAX_VERYH);
	EscapeString(sTagsBuffer[0], ' ', '\0', sTagsBuffer[1], PERK_MAX_VERYH);

	if(ePerks[iPerkId][hTags] == INVALID_HANDLE)
		ePerks[iPerkId][hTags] = CreateArray(32);
	else ClearArray(ePerks[iPerkId][hTags]);

	if(strlen(sTagsBuffer[1]) > 0){
		int iTagSize = CountCharInString(sTagsBuffer[1], '|')+1;
		char[][] sPieces = new char[iTagSize][24];

		ExplodeString(sTagsBuffer[1], "|", sPieces, iTagSize, 24);
		for(int i = 0; i < iTagSize; i++)
			PushArrayString(ePerks[iPerkId][hTags], sPieces[i]);
	}

		//---[ The Rest ]---//
	ePerks[iPerkId][bIsExternal]	= true;
	ePerks[iPerkId][funcCallback]	= GetNativeCell(9);
	ePerks[iPerkId][plParent]		= hPlugin;

	return iPerkId;
}

public int Native_IsRegisteringOpen(Handle hPlugin, int iParams){
	return g_bIsRegisteringOpen;
}

public int Native_SetPerkByToken(Handle hPlugin, int iParams){
	char sTokenBuffer[PERK_MAX_LOW];
	GetNativeString(1, sTokenBuffer, PERK_MAX_LOW);

	int iPerkId = FindPerkByToken(sTokenBuffer);
	if(iPerkId == -1)
		return -1;

	int iDir = GetNativeCell(2);
	if(iDir < -1) iDir = -1;
	else if(iDir > 1) iDir = 1;

	switch(iDir){
		case -1:ePerks[iPerkId][bIsDisabled] = true;
		case 0:	ePerks[iPerkId][bIsDisabled] = ePerks[iPerkId][bIsDisabled] ? false : true;
		case 1:	ePerks[iPerkId][bIsDisabled] = false;
	}

	return iPerkId;
}

public int Native_SetPerkById(Handle hPlugin, int iParams){
	int iPerkId = GetNativeCell(1);
	if(iPerkId < 0 || iPerkId >= g_iPerkCount)
		return -1;

	int iDir = GetNativeCell(2);
	if(iDir < -1) iDir = -1;
	else if(iDir > 1) iDir = 1;

	int iChange = 0;
	switch(iDir){
		case -1:{
			if(!ePerks[iPerkId][bIsDisabled]){
				ePerks[iPerkId][bIsDisabled] = true;
				iChange = 1;
			}
		}

		case 0:{
			ePerks[iPerkId][bIsDisabled] = ePerks[iPerkId][bIsDisabled] ? false : true;
			iChange = 1;
		}

		case 1:{
			if(ePerks[iPerkId][bIsDisabled]){
				ePerks[iPerkId][bIsDisabled] = false;
				iChange = 1;
			}
		}
	}
	return iChange;
}

public int Native_DefaultCorePerk(Handle hPlugin, int iParams){
	int iPerkId = GetNativeCell(1);
	if(iPerkId < 0 || iPerkId >= g_iCorePerkCount){
		char sTokenBuffer[PERK_MAX_LOW];
		GetNativeString(2, sTokenBuffer, PERK_MAX_LOW);

		if(strlen(sTokenBuffer) < 1)
			return -1;

		iPerkId = FindPerkByToken(sTokenBuffer);
		if(iPerkId == -1)
			return -1;
	}

	int iChange = 0;
	if(ePerks[iPerkId][bIsExternal]){
		iChange = 1;
		ePerks[iPerkId][bIsExternal] = false;
	}

	return iChange;
}

public int Native_CanPlayerBeHurt(Handle hPlugin, int iParams){
	int client = GetNativeCell(1);
	if(client < 1 || client > MaxClients)
		return 0;

	if(!IsClientInGame(client))
		return 0;

	return view_as<int>(CanPlayerBeHurt(client, GetNativeCell(2)));
}



			//***************************//
			//----  F O R W A R D S  ----//
			//***************************//

void Forward_PerkApplied(int client, int iPerk, int iDuration){
	if(GetForwardFunctionCount(g_hFwdRolled) < 1)
		return;

	Call_StartForward(g_hFwdRolled);
	Call_PushCell(client);
	Call_PushCell(iPerk);
	Call_PushCell(iDuration);
	Call_Finish();
}

void Forward_PerkRemoved(int client, int iPerk, int iReason){
	if(GetForwardFunctionCount(g_hFwdRemoved) < 1)
		return;

	Call_StartForward(g_hFwdRemoved);
	Call_PushCell(client);
	Call_PushCell(iPerk);
	Call_PushCell(iReason);
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

//-----[ Strings ]-----//
stock bool PerkAllowedForClassOf(int client, int iPerkId){
	switch(TF2_GetPlayerClass(client)){
		case TFClass_Scout:		{if(ePerks[iPerkId][iClasses] & 1)		return true;}
		case TFClass_Soldier:	{if(ePerks[iPerkId][iClasses] & 2)		return true;}
		case TFClass_Pyro:		{if(ePerks[iPerkId][iClasses] & 4)		return true;}
		case TFClass_DemoMan:	{if(ePerks[iPerkId][iClasses] & 8)		return true;}
		case TFClass_Heavy:		{if(ePerks[iPerkId][iClasses] & 16)		return true;}
		case TFClass_Engineer:	{if(ePerks[iPerkId][iClasses] & 32)		return true;}
		case TFClass_Medic:		{if(ePerks[iPerkId][iClasses] & 64)		return true;}
		case TFClass_Sniper:	{if(ePerks[iPerkId][iClasses] & 128)	return true;}
		case TFClass_Spy:		{if(ePerks[iPerkId][iClasses] & 256)	return true;}
	}
	return false;
}

stock bool PerkAllowedForWeaponsOf(int client, int iPerkId){
	if(ePerks[iPerkId][hWeaponClasses] == INVALID_HANDLE)
		return true;

	int iSize = GetArraySize(ePerks[iPerkId][hWeaponClasses]);
	if(iSize < 1)
		return true;

	char sClass[32], sWeapClass[32];
	int iWeapon = 0;
	for(int i = 0; i < 5; i++){
		iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon <= MaxClients)
			continue;

		if(!IsValidEntity(iWeapon))
			continue;

		GetEntityClassname(iWeapon, sWeapClass, 32);
		for(int j = 0; j < iSize; j++){
			GetArrayString(ePerks[iPerkId][hWeaponClasses], j, sClass, 32);
			if(StrContains(sWeapClass, sClass, false) > -1)
				return true;
		}
	}
	return false;
}

stock bool IsPerkInTags(int iPerkId, const char[] sTagString, iTagNum){
	char[][] sPieces = new char[iTagNum][32];
	ExplodeString(sTagString, "|", sPieces, iTagNum, 32);

	int iPerkTags = GetArraySize(ePerks[iPerkId][hTags]);
	char sThisTag[16];
	for(int i = 0; i < iTagNum; i++)
		for(int j = 0; j < iPerkTags; j++){
			GetArrayString(ePerks[iPerkId][hTags], j, sThisTag, 16);
			if(StrEqual(sThisTag, sPieces[i], false))
				return true;
		}
	return false;
}

stock int CountTagOccurences(const char[] sTag, int iTagSize){
	int count = 0;
	for(int i = 0; i < g_iPerkCount; i++){
		if(IsPerkInTags(i, sTag, 1))
			count++;
	}
	return count;
}

/*stock int CountCharInString(const char[] sString, char cChar){
	int i = 0, count = 0;
	while(sString[i] != '\0')
		if(sString[i++] == cChar)
			count++;
	return count;
}*/

stock int EscapeString(const char[] input, int escape, int escaper, char[] output, int maxlen){
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
stock void PrintToChatAllExcept(int client, char[] sMessage){
	for(int i = 1; i <= MaxClients; i++){
		if(!IsValidClient(i) || i == client)
			continue;
		PrintToChat(i, sMessage);
	}
}

stock void DisplayPerkTimeFrame(client){
	int iTeam	= GetClientTeam(client);
	int iRed	= (iTeam == 2) ? 255 : 32;
	int iBlue	= (iTeam == 3) ? 255 : 32;

	SetHudTextParams(g_fCvarTimerPosX, g_fCvarTimerPosY, 1.0, iRed, 32, iBlue, 255);
	ShowSyncHudText(client, eClients[client][hHudSync], "%s: %d", ePerks[eClients[client][iCurPerk]][sName], eClients[client][iPerkEnd] -GetTime());
}

//-----[ Perks ]-----//
stock int ClassStringToFlags(char[] sClasses){
	if(FindCharInString(sClasses, '0') > -1)
		return 511;

	int iLength = strlen(sClasses);
	if(iLength < 2){
		int iClass = StringToInt(sClasses);
		if(iClass < 1) return 0;
		else return iPow(2, iClass-1);
	}else{
		int iCharSize = (iLength+1)/2;
		char[][] sPieces = new char[iCharSize][4];
		ExplodeString(sClasses, ",", sPieces, iCharSize, 4);

		int iValue = 0, iPowed = 0, iFlags = 0;
		for(int i = 0; i < iCharSize; i++){
			iValue = StringToInt(sPieces[i]);
			if(iValue > 9)
				continue;

			iPowed = iPow(2, iValue-1);
			if(iFlags & iPowed)
				continue;

			iFlags |= iPowed;
		}
		return iFlags;
	}
}

stock int GetPerkOfString(const char[] sString, int iStringSize){
	int iString = StringToInt(sString);
	if(!(FindCharInString(sString, '0') < 0 && iString == 0))
		return iString;

	for(int i = 0; i < g_iPerkCount; i++){
		if(StrEqual(sString, ePerks[i][sToken]))
			return i;
	}

	if(CountTagOccurences(sString, iStringSize) == 1)
		for(int j = 0; j < g_iPerkCount; j++){
			if(IsPerkInTags(j, sString, 1))
				return j;
		}
	return -1;
}

stock int GetPerkTime(int iPerkId){
	return (ePerks[iPerkId][iTime] > 0) ? ePerks[iPerkId][iTime] : g_iCvarPerkDuration;
}

stock int GetNextAvailableGroup(){
	for(int i = 0; i <= MaxClients; i++)
		if(!eGroup[i][bActive])
			return i;
	return -1;
}

//-----[ Miscellaneous ]-----//
stock int ReadFlagFromConVar(Handle hCvar){
	char sBuffer[32];
	GetConVarString(hCvar, sBuffer, sizeof(sBuffer));
	return ReadFlagString(sBuffer);
}

stock int ConnectWithBeam(int iEnt, int iEnt2, int iRed=255, int iGreen=255, int iBlue=255, float fStartWidth=1.0, float fEndWidth=1.0, float fAmp=1.35){
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

	SetEntPropFloat(iBeam, Prop_Data, "m_fWidth", 1.0);
	SetEntPropFloat(iBeam, Prop_Data, "m_fEndWidth", 1.0);

	SetEntPropFloat(iBeam, Prop_Data, "m_fAmplitude", 1.35);

	SetVariantFloat(32.0);
	AcceptEntityInput(iBeam, "Amplitude");
	AcceptEntityInput(iBeam, "TurnOn");
	return iBeam;
}

stock int CreateParticle(int iClient, char[] strParticle, bool bAttach=true, char[] strAttachmentPoint="", float fOffset[3]={0.0, 0.0, 36.0}){
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

stock void FixPotentialStuck(int client){
	if(!g_bCvarRespawnStuck)
		return;

	if(client < 1 || client > MaxClients)
		return;

	if(!IsClientInGame(client))
		return;

	CreateTimer(0.1, Timer_FixStuck, GetClientSerial(client));
}

public Action Timer_FixStuck(Handle hTimer, int iSerial){
	int client = GetClientFromSerial(iSerial);
	if(client < 1 || client > MaxClients)
		return Plugin_Stop;

	if(!IsClientInGame(client))
		return Plugin_Stop;

	if(!IsPlayerAlive(client))
		return Plugin_Stop;

	if(!IsEntityStuck(client))
		return Plugin_Stop;

	PrintToChat(client, "%s %T", CHAT_PREFIX, "RTD2_Stuck_Respawn", LANG_SERVER);
	TF2_RespawnPlayer(client);
	return Plugin_Stop;
}

//-----[ Checks ]-----//
stock int FindPerkByToken(const char[] sCheckToken){
	for(int i = 0; i < g_iPerkCount; i++)
		if(StrEqual(sCheckToken, ePerks[i][sToken], false))
			return i;
	return -1;
}

stock bool IsArgumentTrigger(const char[] sArg){
	char sTrigger[16];
	for(int i = 0; i < g_iCvarTriggers; i++){
		GetArrayString(g_arrCvarTriggers, i, sTrigger, 16);
		if(StrEqual(sArg, sTrigger, false))
			return true;
	}
	return false;
}

stock bool IsEntityStuck(int iEntity){
	float fPos[3], fMins[3], fMaxs[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPos);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMins", fMins);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", fMaxs);

	TR_TraceHullFilter(fPos, fPos, fMins, fMaxs, MASK_SOLID, TraceFilterIgnoreSelf, iEntity);
	return TR_DidHit();
}

stock bool IsRollerAllowed(int client){
	if(g_iCvarAllowed > 0)
		return view_as<bool>(GetUserFlagBits(client) & g_iCvarAllowed);
	return true;
}

stock bool IsRollerDonator(int client){
	if(g_iCvarDonatorFlag > 0)
		return view_as<bool>(GetUserFlagBits(client) & g_iCvarDonatorFlag);
	return false;
}

stock bool CanBuildAtPos(float fPos[3], bool bSentry){
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

stock bool CanPlayerBeHurt(int client, int by=0){
	if(IsValidClient(by))
		if(GetClientTeam(by) == GetClientTeam(client))
			return false;

	if(IsPlayerFriendly(client))
		return false;

	if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
		return false;

	if(GetEntProp(client, Prop_Data, "m_takedamage") != 2)
		return false;

	return true;
}

stock bool IsPlayerFriendly(int client){
	if(g_bPluginFriendly)
		if(TF2Friendly_IsFriendly(client))
			return true;

	if(g_bPluginFriendlySimple)
		if(FriendlySimple_IsFriendly(client))
			return true;

	return false;
}

stock bool CanEntitySeeTarget(int entity, int iTarget){
	float fStart[3], fEnd[3];
	if(IsValidClient(entity))
		GetClientEyePosition(entity, fStart);
	else GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fStart);

	if(IsValidClient(iTarget))
		GetClientEyePosition(iTarget, fEnd);
	else GetEntPropVector(iTarget, Prop_Send, "m_vecOrigin", fEnd);

	Handle hTrace = TR_TraceRayFilterEx(fStart, fEnd, MASK_SOLID, RayType_EndPoint, TraceFilterIgnorePlayersAndSelf, entity);
	if(hTrace != INVALID_HANDLE){
		if(TR_DidHit(hTrace)){
			CloseHandle(hTrace);
			return false;
		}
		CloseHandle(hTrace);
	}
	return true;
}

stock bool IsRTDInRound(){
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
	return !(iEntity >= 1 && iEntity <= MaxClients);
}

public bool TraceFilterIgnorePlayersAndSelf(int iEntity, int iContentsMask, any iTarget){
	if(iEntity >= 1 && iEntity <= MaxClients)
		return false;

	if(iEntity == iTarget)
		return false;

	return true;
}

stock bool GetClientLookPosition(int client, float fPosition[3]){
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
stock int AccountIDToClient(int iAccountID){
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			if(GetSteamAccountID(i) == iAccountID)
				return i;
	return -1;
}

stock void KillTimerSafe(Handle &hTimer){
	if(hTimer == INVALID_HANDLE)
		return;

	KillTimer(hTimer);
	hTimer = INVALID_HANDLE;
}

stock int iPow(int iValue, int iExponent){
	//Thanks, D.Moder
	return RoundFloat(Pow(float(iValue), float(iExponent)));
}

public bool IsValidClient(int client){
	if(client > 4096)
		client = EntRefToEntIndex(client);

	if(client < 1 || client > MaxClients)				return false;
	if(!IsClientInGame(client))							return false;
	if(IsFakeClient(client))							return false;
	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))	return false;
	return true;
}
