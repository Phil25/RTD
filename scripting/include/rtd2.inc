#if defined _rtd2_included
  #endinput
#endif
#define _rtd2_included

public SharedPlugin:__pl_rtd2 = {
	name = "RollTheDice2",
	file = "rtd2.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_rtd2_SetNTVOptional(){

	MarkNativeAsOptional("RTD2_GetClientPerkId");
	MarkNativeAsOptional("RTD2_GetClientPerkTime");
	
	MarkNativeAsOptional("RTD2_ForcePerk");
	MarkNativeAsOptional("RTD2_RollPerk");
	MarkNativeAsOptional("RTD2_RemovePerk");
	
	MarkNativeAsOptional("RTD2_GetPerkOfString");
	
	MarkNativeAsOptional("RTD2_RegisterPerk");
	MarkNativeAsOptional("RTD2_IsRegOpen");
	MarkNativeAsOptional("RTD2_SetPerkByToken");
	MarkNativeAsOptional("RTD2_SetPerkById");
	MarkNativeAsOptional("RTD2_DefaultCorePerk");
	
	MarkNativeAsOptional("RTD2_CanPlayerBeHurt");

}
#endif



	/**************************\
		-	D E F I N E S  -
	\**************************/

#define ROLLFLAG_NONE					0
#define ROLLFLAG_OVERRIDE_DISABLED		(1 << 0)	/* Accept disabled perks */
#define ROLLFLAG_OVERRIDE_CLASS			(1 << 1)	/* If client is specified, ignore their class */
#define ROLLFLAG_OVERRIDE_LOADOUT		(1 << 2)	/* Ignore whether the client has irrelevant loadout */
#define ROLLFLAG_IGNORE_PERK_REPEATS	(1 << 3)	/* Ignore whether the perk was rolled recently */
#define ROLLFLAG_IGNORE_PLAYER_REPEATS	(1 << 4)	/* Ignore whether the client has rolled the perk recently */



	/****************************\
		-	F O R W A R D S  -
	\****************************/


/**
 * Called everytime rtd is activated to determine if the player can use the dice mod.
 * Return Plugin_Continue to allow, anything else denies them access.
 *
 * @note sm_forcertd command and RTD2_ForcePerk native does not call this.
 *
 * @param client		Client index.
 */
forward Action:RTD2_CanRollDice(client);


/**
 * Called when a perk (iPerkId) is about to be forced by an admin (client) on a target (iTarget).
 * Return Plugin_Continue to allow, anything else denies the force.
 *
 * @note Called only by sm_forcertd command and RTD2_ForcePerk native.
 *
 * @param client		Client index.
 * @param iTarget		Target client index.
 * @param iPerkId		ID of the perk about to be forced.
 */
forward Action:RTD2_CanForcePerk(client, iTarget, iPerkId);


/**
 * Called when a perk (iPerkId) is about to be removed by an admin (client) from a target (iTarget).
 * Return Plugin_Continue to allow, anything else denies the force.
 *
 * @note Called only by sm_removertd command and RTD2_RemovePerk native.
 *
 * @param client		Client index.
 * @param iTarget		Target client index.
 * @param iPerkId		ID of the perk about to be removed.
 */
forward Action:RTD2_CanRemovePerk(client, iTarget, iPerkId);


/**
 * Called when a perk has just been activated on a player.
 *
 * @param client		Client Index.
 * @param iPerk			Perk Index.
 * @param iDuration		Perk Duration (-1 if no time).
 */
forward RTD2_Rolled(client, iPerk, iDuration);


/**
 * Called when a perk has just been activated on a player.
 *
 * @param client		Client Index.
 * @param iPerk			Removed Perk's Index.
 * @param iReason		Reason Index (0=plugin unload, 1=death, 2=class change, 3=wear off, 4=disconnect, 5=custom/unknown).
 */
forward RTD2_Removed(client, iPerk, iReason);




	/**************************\
		-	N A T I V E S  -
	\**************************/


/**
 * Returns player's current perk index. Meant to check if player is using RTD.
 *
 * @param client		Client Index.
 *
 * @return				Perk index if client is using RTD, -1 otherwise.
 */
native RTD2_GetClientPerkId(client);


/**
 * Returns time in seconds the player has left to the perk end.
 *
 * @param client		Client Index.
 *
 * @return				Time in seconds if client is using RTD, -1 otherwise.
 */
native RTD2_GetClientPerkTime(client);


/**
 * Forces a perk on a player
 *
 * @param client		Client Index.
 * @param sPerk			Perk string, containing id, token or a tag. If invalid a roll will be used.
 * @param iTime			Custom perk's time. -1 = don't use.
 * @param bOvrClass		0/1 - If perk doesn't match player's class, should it be applied anyway?
 * @param initiator		Entity which initiated forcing the perk.
 * 
 * @return				-5 if RTD2_CanForcePerk forward was blocked,
 *						-4 if client index is not valid (bots are not valid either),
 *						-3 if client is using RTD,
 * 						-2 if client is dead,
 * 						-1 if there were no perks available,
 * 						<0 and more> forced perk's index.
 */
native RTD2_ForcePerk(client, String:sPerk[]="-1", iTime=-1, bOvrClass=0, initiator=0);


/**
 * Rolls a perk with given data.
 *
 * @note This does NOT apply the perk to the client.
 *
 * @param client				Client Index.
 * @param bOverrideDisabled		0/1 - Roll disabled perks?
 * @param bOverrideClass		0/1 - Roll perks NOT for player's class?
 * @param bCountRepeat			0/1 - Roll perks which repeated twice in 2 rolls for client? (sm_rtd2_repeat 1 ONLY)
 * @param bCountGreatRepeat		0/1 - Roll perks which repeated twice in 3 rolls for client? (sm_rtd2_repeatgreat 1 ONLY)
 * 
 * @return						Perk index on success, -1 otherwise
 */
native RTD2_RollPerk(client=0, bOverrideDisabled=0, bOverrideClass=0, bCountRepeat=1, bCountGreatRepeat=1);


/**
 * Removes current perk from the client.
 *
 * @param client		Client Index.
 * @param iReason		Reason Index (0=plugin unload, 1=death, 2=class change, 3=wear off, 4=disconnect, 5=custom/unknown).
 * @param sReason		Provide custom reason IF iReason=5.
 * 
 * @return				Perk index which got removed, -1 if client wasn't using RTD.
 */
native RTD2_RemovePerk(client, iReason=3, const String:sReason[]="");


/**
 * Gets the perk's index by either the actual index, perk's token or a single tag
 *
 * @param sString		String to search by.
 *
 * @return				Perk's index on success, -1 otherwise.
 */
native RTD2_GetPerkOfString(const String:sString[]="");




	/****************************\
	******************************
		-	E X T E R N A L  -
	******************************
	\****************************/

/*

		The following are grouped individually,
	because they are meant to be for plugins
	which register their own perks to the RTD.
	
		For a full tutorial on how to use those,
	see the RTD's thread on AlliedModders:
	
	https://forums.alliedmods.net/showthread.php?t=278579
	
*/

functag RTD2Manager public(client, iPerkId, bool:bEnable);

/**
 * Registers a perk from a different plugin to the core.
 * The parameters match the fields in the KV file.
 * Perks cannot be unregistered, disable them instead.
 * If a token was found in another perk, it will OVERRIDE that perk.
 * For in-depth information, see the RTD thread on AlliedModders.
 *
 * @param sToken	Unique token used for addressing the perk.
 * @param sName		Perk name.
 * @param iGood		0 - bad perk; 1 - good perk
 * @param sSound	Path to the initiation sound file.
 * @param iTime		-1 -> no timer; 0 -> ConVar default time; 0< -> Custom perk time.
 * @param sClass	Class string to limit the perk to.
 * @param sWeapon	Weapon classnames to limit the perk to.
 * @param sTags		Perk's tags used to find or address the perk.
 * @param funcPerk	Callback function; public(client, iPerkId, bool:bEnable)
 *
 * @return			Perk's index on success, -1 otherwise (not all paremeters filled).
 */
native RTD2_RegisterPerk(const String:sToken[], const String:sName[], iGood, const String:sSound[], iTime, const String:sClass[], const String:sWeapons[], const String:sTags[], RTD2Manager:funcPerk);


/**
 * Registering a perk via external plugin is possible only after all the core ones were registered.
 * You can register new perks in OnPluginStart() when this native returns 1 (if late-loaded).
 * Otherwise, register them in the RTD2_OnRegOpen() forward.
 *
 * @return			1 if registering is open, 0 otherwise.
 */
native RTD2_IsRegOpen();


/**
 * This forward will fire when RTD is ready handle perk registration.
 * RTD2_RegisterPerk() should ALWAYS be executed in this forward.
 */
forward RTD2_OnRegOpen();


/**
 * Enables/disables perk by token.
 *
 * @params sToken	The token to find the perk by.
 * @params iDir		(direction) -1 = disable, 0 = toggle, 1 = enable
 *
 * @return			ID of the perk, -1 if not found.
 */
native RTD2_SetPerkByToken(const String:sToken[], iDir=0);


/**
 * Enables/disables perk by ID.
 *
 * @params iId		Perk's ID.
 * @params iDir		(direction) -1 = disable, 0 = toggle, 1 = enable
 *
 * @return			1 if anything changed, 0 if was already in the requested state, -1 on error.
 */
native RTD2_SetPerkById(iId, iDir=0);


/**
 * If RTD2_RegisterPerk() was used to override functionality of a core perk,
 * this native can be used to set it back to the default one.
 * It will accept either the perk's ID or its token (id > token).
 * You should use it only on core perks.
 *
 * @params iId		Perk's ID.
 * @params sToken	Perk's token.
 *
 * @return			1 if anything was changed, 0 nothing was changed, -1 on error.
 */
native RTD2_DefaultCorePerk(iId=-1, const String:sToken[]="");


/**
 * A miscellaneous native which returns whether the client can be hurt.
 * Optionally, hurt by whom.
 * It is adived to use this as it checks if the client is in Friendly Mode.
 *
 * @params client	Can this client be hurt...
 * @params by		...by this client?
 *
 * @return			1 if yes, 0 if not or error.
 */
native RTD2_CanPlayerBeHurt(client, by=0);
