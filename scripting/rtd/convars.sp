#define DESC_PLUGIN_ENABLED "0/1 - Enable or disable RTD."
Handle g_hCvarPluginEnabled;
bool g_bCvarPluginEnabled = true;

#if defined _updater_included
#define DESC_AUTO_UPDATE "0/1 - Enable or disable automatic updating of RTD when Updater is installed."
Handle g_hCvarAutoUpdate;
bool g_bCvarAutoUpdate = true;

#define DESC_RELOAD_UPDATE "0/1 - Enable or disable automatic RTD reloading when a new version has been downloaded."
Handle g_hCvarReloadUpdate;
bool g_bCvarReloadUpdate = true;
#endif

#define DESC_CUSTOM_CONFIG "Name of the custom config file for perk configuration."
Handle g_hCvarCustomConfig;
char g_sCustomConfigPath[PLATFORM_MAX_PATH];
bool g_bCustomConfigFound = false;

enum ChatFlag
{
	ChatFlag_Ad = 1 << 0,
	ChatFlag_AppRoller = 1 << 1,
	ChatFlag_AppOther = 1 << 2,
	ChatFlag_RemRoller = 1 << 3,
	ChatFlag_RemOther = 1 << 4,
	ChatFlag_Reasons = 1 << 5,
}

enum LogFlag
{
	LogFlag_System = 1 << 0,
	LogFlag_Action = 1 << 1,
	LogFlag_PerkApply = 1 << 2,
	LogFlag_PerkRemove = 1 << 3,
}

#define DESC_LOG "0/1 - Enable or disable RTD action logging to SourceMod logs. **DEPRECATED** Use \"sm_rtd2_logging\" instead."
Handle g_hCvarLog;

#define DESC_LOGGING "Add/substract these values to control logs:\n1 - general RTD-internal messages\n2 - command actions\n4 - perk applications\n8 - perk removals\nEx.: \"3\" - show general logs and admin command usage only (1 + 2)"
Handle g_hCvarLogging;
int g_iCvarLogging = 3;

#define DESC_CHAT "Add/substract these values to control chat messages:\n1 - RTD ad (round start)\n2 - Perk applic. for rollers\n4 - P. applic. for others\n8 - P. removal for rollers\n16 - P. removal for others\n32 - Can't-roll reasons\nEx.: \"6\" - applications only (2 + 4)"
Handle g_hCvarChat;
int g_iCvarChat = 63;

#define DESC_PERK_DURATION "Default time for the perk to last. This value can be overridden for any perk in rtd2_perks.cfg"
Handle g_hCvarPerkDuration;
int g_iCvarPerkDuration = 25;

#define DESC_ROLL_INTERVAL "Time in seconds a client has to wait to roll again after a perk has finished."
Handle g_hCvarRollInterval;
int g_iCvarRollInterval = 60;

#define DESC_DISABLED_PERKS "Enter the effects you'd like to disable, separated by commas. You can use IDs, tokens or tags which occur in a single perk (ex. \"0, toxic, sandvich\" disables first 3)."
Handle g_hCvarDisabledPerks;

#define DESC_ALLOWED "Admin flags which are required to use RTD. If blank, all is assumed."
Handle g_hCvarAllowed;
int g_iCvarAllowed = 0;

#define DESC_IN_SETUP "0/1 - Can RTD be used during Setup?"
Handle g_hCvarInSetup;
bool g_bCvarInSetup = true;

#define DESC_TRIGGERS "Chat triggers which will initiate rolls, separated by comma."
Handle g_hCvarTriggers;
Handle g_arrCvarTriggers = INVALID_HANDLE;
int g_iCvarTriggers = 2;

#define DESC_SHOW_TRIGGERS "0/1 - Should the chat triggers be shown once they're typed?"
Handle g_hCvarShowTriggers;
bool g_bCvarShowTriggers = false;

#define DESC_SHOW_TIME "0/1 - Should time the perk was applied for be displayed?"
Handle g_hCvarShowTime;
bool g_bCvarShowTime = false;

#define DESC_RTD_TEAM "0 - both teams can roll, 1 - only BLU team can roll, 2 - only RED team can roll."
Handle g_hCvarRtdTeam;
int g_iCvarRtdTeam = 0;

#define DESC_RTD_MODE "0 - No restrain except the interval, 1 - Limit by rollers, 2 - Limit by rollers in team."
Handle g_hCvarRtdMode;
int g_iCvarRtdMode = 0;

#define DESC_CLIENT_LIMIT "How many players could use RTD at once. Active only when RTD Mode is 1"
Handle g_hCvarClientLimit;
int g_iCvarClientLimit = 2;

#define DESC_TEAM_LIMIT "How many players in each team could use RTD at once. Active only when RTD Mode is 2"
Handle g_hCvarTeamLimit;
int g_iCvarTeamLimit = 2;

#define DESC_RESPAWN_STUCK "0/1 - Should a player be forcibly respawned when a perk has ended and he's detected stuck?"
Handle g_hCvarRespawnStuck;
bool g_bCvarRespawnStuck = true;

#define DESC_REPEAT_PLAYER "How many perks are NOT allowed to repeat, per player."
Handle g_hCvarRepeatPlayer;
int g_iCvarRepeatPlayer = 2;

#define DESC_REPEAT_PERK "How many perks are NOT allowed to repeat, per perk."
Handle g_hCvarRepeatPerk;
int g_iCvarRepeatPerk = 2;

#define DESC_GOOD_CHANCE "0.0-1.0 - Chance of rolling a good perk. If there are no good perks available, a bad one will be tried to be rolled instead."
Handle g_hCvarGoodChance;
float g_fCvarGoodChance = 0.5;

#define DESC_GOOD_DONATOR_CHANCE "0.0-1.0 - Chance of rolling a good perk if roller is a donator. If there are no good perks available, a bad one will be tried to roll instead."
Handle g_hCvarGoodDonatorChance;
float g_fCvarGoodDonatorChance = 0.75;

#define DESC_DONATOR_FLAG "Admin flag used by donators."
Handle g_hCvarDonatorFlag;
int g_iCvarDonatorFlag = 0;

#define DESC_TIMER_POS_X "0.0-1.0 - The X position of the perk HUD timer display. -1.0 to center."
Handle g_hCvarTimerPosX;
float g_fCvarTimerPosX = -1.0;

#define DESC_TIMER_POS_Y "0.0-1.0 - The Y position of the perk HUD timer display. -1.0 to center."
Handle g_hCvarTimerPosY;
float g_fCvarTimerPosY = 0.55;

#define DESC_SHOW_DESC "0.0-1.0 - Show perk description to roller after applying effect."
ConVar g_hCvarShowDesc;

void SetupConVars()
{
	g_hCvarPluginEnabled		= CreateConVar("sm_rtd2_enabled",		"1",		DESC_PLUGIN_ENABLED,		FLAGS_CVARS);
#if defined _updater_included
	g_hCvarAutoUpdate			= CreateConVar("sm_rtd2_autoupdate",	"1",		DESC_AUTO_UPDATE,			FLAGS_CVARS);
	g_hCvarReloadUpdate			= CreateConVar("sm_rtd2_reloadupdate",	"1",		DESC_RELOAD_UPDATE,			FLAGS_CVARS);
#endif
	g_hCvarCustomConfig			= CreateConVar("sm_rtd2_custom_config",	"rtd2_perks.custom.cfg",DESC_CUSTOM_CONFIG,FLAGS_CVARS);
	g_hCvarLog					= CreateConVar("sm_rtd2_log",			"0",		DESC_LOG,					FLAGS_CVARS|FCVAR_DONTRECORD);
	g_hCvarLogging				= CreateConVar("sm_rtd2_logging",		"3",		DESC_LOGGING,				FLAGS_CVARS);
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

	g_hCvarShowDesc 			= CreateConVar("sm_rtd2_show_description", "0",		DESC_SHOW_DESC,				FLAGS_CVARS, true, 0.0, true, 1.0);


		//-----[ ConVars Hooking & Setting ]-----//
	HookConVarChange(g_hCvarPluginEnabled,		ConVarChange_Plugin	);	g_bCvarPluginEnabled		= GetConVarInt(g_hCvarPluginEnabled) > 0;
#if defined _updater_included
	HookConVarChange(g_hCvarAutoUpdate,			ConVarChange_Plugin	);	g_bCvarAutoUpdate			= GetConVarInt(g_hCvarAutoUpdate) > 0;
	HookConVarChange(g_hCvarReloadUpdate,		ConVarChange_Plugin	);	g_bCvarReloadUpdate			= GetConVarInt(g_hCvarReloadUpdate) > 0;
#endif
	HookConVarChange(g_hCvarCustomConfig,		ConVarChange_Plugin	);	g_bCustomConfigFound		= ParseCustomConfig();
	HookConVarChange(g_hCvarLog,				ConVarChange_Plugin	);
	HookConVarChange(g_hCvarLogging,			ConVarChange_Plugin	);	g_iCvarLogging				= GetConVarInt(g_hCvarLogging);
	HookConVarChange(g_hCvarChat,				ConVarChange_Plugin	);	g_iCvarChat					= GetConVarInt(g_hCvarChat);

	HookConVarChange(g_hCvarPerkDuration,		ConVarChange_Perks	);	g_iCvarPerkDuration			= GetConVarInt(g_hCvarPerkDuration);
	HookConVarChange(g_hCvarRollInterval,		ConVarChange_Perks	);	g_iCvarRollInterval			= GetConVarInt(g_hCvarRollInterval);
	HookConVarChange(g_hCvarDisabledPerks,		ConVarChange_Perks	);

	HookConVarChange(g_hCvarAllowed,			ConVarChange_Usage	);	g_iCvarAllowed				= ReadFlagFromConVar(g_hCvarAllowed);
	HookConVarChange(g_hCvarInSetup,			ConVarChange_Usage	);	g_bCvarInSetup				= GetConVarInt(g_hCvarInSetup) > 0;
	HookConVarChange(g_hCvarTriggers,			ConVarChange_Usage	);	ParseTriggers();
	HookConVarChange(g_hCvarShowTriggers,		ConVarChange_Usage	);	g_bCvarShowTriggers			= GetConVarInt(g_hCvarShowTriggers) > 0;
	HookConVarChange(g_hCvarShowTime,			ConVarChange_Usage	);	g_bCvarShowTime				= GetConVarInt(g_hCvarShowTime) > 0;

	HookConVarChange(g_hCvarRtdTeam,			ConVarChange_Rtd	);	g_iCvarRtdTeam				= GetConVarInt(g_hCvarRtdTeam);
	HookConVarChange(g_hCvarRtdMode,			ConVarChange_Rtd	);	g_iCvarRtdMode				= GetConVarInt(g_hCvarRtdMode);
	HookConVarChange(g_hCvarClientLimit,		ConVarChange_Rtd	);	g_iCvarClientLimit			= GetConVarInt(g_hCvarClientLimit);
	HookConVarChange(g_hCvarTeamLimit,			ConVarChange_Rtd	);	g_iCvarTeamLimit			= GetConVarInt(g_hCvarTeamLimit);
	HookConVarChange(g_hCvarRespawnStuck,		ConVarChange_Rtd	);	g_bCvarRespawnStuck			= GetConVarInt(g_hCvarRespawnStuck) > 0;

	HookConVarChange(g_hCvarRepeatPlayer,		ConVarChange_Repeat	);	g_iCvarRepeatPlayer			= GetConVarInt(g_hCvarRepeatPlayer);
	HookConVarChange(g_hCvarRepeatPerk,			ConVarChange_Repeat	);	g_iCvarRepeatPerk			= GetConVarInt(g_hCvarRepeatPerk);

	HookConVarChange(g_hCvarGoodChance,			ConVarChange_Good	);	g_fCvarGoodChance			= GetConVarFloat(g_hCvarGoodChance);
	HookConVarChange(g_hCvarGoodDonatorChance,	ConVarChange_Good	);	g_fCvarGoodDonatorChance	= GetConVarFloat(g_hCvarGoodDonatorChance);
	HookConVarChange(g_hCvarDonatorFlag,		ConVarChange_Good	);	g_iCvarDonatorFlag			= ReadFlagFromConVar(g_hCvarDonatorFlag);

	HookConVarChange(g_hCvarTimerPosX,			ConVarChange_Timer	);	g_fCvarTimerPosX			= GetConVarFloat(g_hCvarTimerPosX);
	HookConVarChange(g_hCvarTimerPosY,			ConVarChange_Timer	);	g_fCvarTimerPosY			= GetConVarFloat(g_hCvarTimerPosY);
}

public void ConVarChange_Plugin(Handle hCvar, const char[] sOld, const char[] sNew)
{
	if (hCvar == g_hCvarPluginEnabled)
	{
		g_bCvarPluginEnabled = StringToInt(sNew) > 0;
	}
#if defined _updater_included
	else if (hCvar == g_hCvarAutoUpdate)
	{
		g_bCvarAutoUpdate = StringToInt(sNew) > 0;
	}
	else if (hCvar == g_hCvarReloadUpdate)
	{
		g_bCvarReloadUpdate = StringToInt(sNew) > 0;
	}
#endif
	else if (hCvar == g_hCvarCustomConfig)
	{
		g_bCustomConfigFound = ParseCustomConfig();
		if (g_bCustomConfigFound && !StrEqual(sOld, sNew))
			PrintToServer(CONS_PREFIX ... " Custom config path changed, use \"sm_reloadrtd\" to reparse perks.");
	}
	else if (hCvar == g_hCvarLog)
	{
		LogError(
			"ConVar \"sm_rtd2_log\" is deprecated, use \"sm_rtd2_logging\" instead. Please make "
			... "sure to remove it from \"/tf/cfg/sourcemod/plugin.rtd.cfg\" or any custom configs "
			... "where it might be defined for this error to clear. You may safely delete "
			... "\"/tf/cfg/sourcemod/plugin.rtd.cfg\" and it will be recreated with default values "
			... "and documentation."
		);
	}
	else if (hCvar == g_hCvarLogging)
	{
		g_iCvarLogging = StringToInt(sNew);
	}
	else if (hCvar == g_hCvarChat)
	{
		g_iCvarChat = StringToInt(sNew);
	}
}

public void ConVarChange_Perks(Handle hCvar, const char[] sOld, const char[] sNew)
{
	if (hCvar == g_hCvarPerkDuration)
	{
		g_iCvarPerkDuration = StringToInt(sNew);
	}
	else if (hCvar == g_hCvarRollInterval)
	{
		g_iCvarRollInterval = StringToInt(sNew);
	}
	else if (hCvar == g_hCvarDisabledPerks)
	{
		ParseDisabledPerks();
	}
}

public void ConVarChange_Usage(Handle hCvar, const char[] sOld, const char[] sNew)
{
	if (hCvar == g_hCvarAllowed)
	{
		g_iCvarAllowed = ReadFlagString(sNew);
	}
	else if (hCvar == g_hCvarInSetup)
	{
		g_bCvarInSetup = StringToInt(sNew) > 0;
	}
	else if (hCvar == g_hCvarTriggers)
	{
		ParseTriggers();
	}
	else if (hCvar == g_hCvarShowTriggers)
	{
		g_bCvarShowTriggers = StringToInt(sNew) > 0;
	}
	else if (hCvar == g_hCvarShowTime)
	{
		g_bCvarShowTime = StringToInt(sNew) > 0;
	}
}

public void ConVarChange_Rtd(Handle hCvar, const char[] sOld, const char[] sNew)
{
	if (hCvar == g_hCvarRtdTeam)
	{
		g_iCvarRtdTeam = StringToInt(sNew);
	}
	else if (hCvar == g_hCvarRtdMode)
	{
		g_iCvarRtdMode = StringToInt(sNew);
	}
	else if (hCvar == g_hCvarClientLimit)
	{
		g_iCvarClientLimit = StringToInt(sNew);
	}
	else if (hCvar == g_hCvarTeamLimit)
	{
		g_iCvarTeamLimit = StringToInt(sNew);
	}
	else if (hCvar == g_hCvarRespawnStuck)
	{
		g_bCvarRespawnStuck = StringToInt(sNew) > 0;
	}
}

public void ConVarChange_Repeat(Handle hCvar, const char[] sOld, const char[] sNew)
{
	if (hCvar == g_hCvarRepeatPlayer)
	{
		g_iCvarRepeatPlayer = StringToInt(sNew);
		g_hRollers.ResetPerkHisories();
	}
	else if (hCvar == g_hCvarRepeatPerk)
	{
		g_iCvarRepeatPerk = StringToInt(sNew);
		g_hPerkHistory.Clear();
	}
}

public void ConVarChange_Good(Handle hCvar, const char[] sOld, const char[] sNew)
{
	if (hCvar == g_hCvarGoodChance)
	{
		g_fCvarGoodChance = StringToFloat(sNew);
	}
	else if (hCvar == g_hCvarGoodDonatorChance)
	{
		g_fCvarGoodDonatorChance = StringToFloat(sNew);
	}
	else if (hCvar == g_hCvarDonatorFlag)
	{
		g_iCvarDonatorFlag = ReadFlagString(sNew);
	}
}

public void ConVarChange_Timer(Handle hCvar, const char[] sOld, const char[] sNew)
{
	if (hCvar == g_hCvarTimerPosX)
	{
		g_fCvarTimerPosX = StringToFloat(sNew);
	}
	else if (hCvar == g_hCvarTimerPosY)
	{
		g_fCvarTimerPosY = StringToFloat(sNew);
	}
}
