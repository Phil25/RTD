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
	MarkNativeAsOptional("RTD2_GetPerkAny");
	MarkNativeAsOptional("RTD2_SetPerkAny");
	MarkNativeAsOptional("RTD2_GetPerkString");
	MarkNativeAsOptional("RTD2_SetPerkString");
	MarkNativeAsOptional("RTD2_GetPerkHandle");
	MarkNativeAsOptional("RTD2_SetPerkCall");
	MarkNativeAsOptional("RTD2_Format");

	MarkNativeAsOptional("RTD2_GetClientPerkId"); // deprecated
	MarkNativeAsOptional("RTD2_GetClientPerk");
	MarkNativeAsOptional("RTD2_GetClientPerkTime");

	MarkNativeAsOptional("RTD2_ForcePerk"); // deprecated
	MarkNativeAsOptional("RTD2_Force");
	MarkNativeAsOptional("RTD2_RollPerk"); // deprecated
	MarkNativeAsOptional("RTD2_Roll");
	MarkNativeAsOptional("RTD2_RemovePerk"); // deprecated
	MarkNativeAsOptional("RTD2_Remove");

	MarkNativeAsOptional("RTD2_GetPerkOfString"); // deprecated
	MarkNativeAsOptional("RTD2_FindPerk");
	MarkNativeAsOptional("RTD2_FindPerks");

	MarkNativeAsOptional("RTD2_RegisterPerk"); // deprecated
	MarkNativeAsOptional("RTD2_ObtainPerk");

	MarkNativeAsOptional("RTD2_IsRegOpen");

	MarkNativeAsOptional("RTD2_SetPerkByToken"); // deprecated
	MarkNativeAsOptional("RTD2_SetPerkById"); // deprecated
	MarkNativeAsOptional("RTD2_DefaultCorePerk"); // deprecated

	MarkNativeAsOptional("RTD2_CanPlayerBeHurt");
}
#endif



/*
 *=========
 * DEFINES
 *=========
 */


#define ROLLFLAG_NONE					0
#define ROLLFLAG_OVERRIDE_DISABLED		(1 << 0)	/* Accept disabled perks */
#define ROLLFLAG_OVERRIDE_CLASS			(1 << 1)	/* If client is specified, ignore their class */
#define ROLLFLAG_OVERRIDE_LOADOUT		(1 << 2)	/* Ignore whether the client has irrelevant loadout */
#define ROLLFLAG_IGNORE_PERK_REPEATS	(1 << 3)	/* Ignore whether the perk was rolled recently */
#define ROLLFLAG_IGNORE_PLAYER_REPEATS	(1 << 4)	/* Ignore whether the client has rolled the perk recently */



/*
 *=======
 * ENUMS
 *=======
 */


enum RTDPerkProp{
	RTDPerk_Name = 0,
	RTDPerk_Good,
	RTDPerk_Sound,
	RTDPerk_Token,
	RTDPerk_Time,
	RTDPerk_Classes,
	RTDPerk_WeaponClasses,
	RTDPerk_Pref,
	RTDPerk_Tags,
	RTDPerk_Enabled,
	RTDPerk_External
}

enum RTDRemoveReason{
	RTDRemove_PluginUnload = 0,
	RTDRemove_Death,
	RTDRemove_ClassChange,
	RTDRemove_WearOff,
	RTDRemove_Disconnect,
	RTDRemove_Custom
}

enum RTDForceResult{
	RTDForce_Success = 0,
	RTDForce_NullPerk,
	RTDForce_ClientDead,
	RTDForce_ClientInRoll,
	RTDForce_ClientInvalid,
	RTDForce_Blocked
}



/*
 *==========
 * FETCHING
 *==========
 */


// TODO: document
native any RTD2_GetPerkAny(RTDPerk perk, RTDPerkProp prop);


// TODO: document
native void RTD2_SetPerkAny(RTDPerk perk, RTDPerkProp prop, any value);


// TODO: document
native void RTD2_GetPerkString(RTDPerk perk, RTDPerkProp prop, char[] sBuffer, int iBufferLen);


// TODO: document
native void RTD2_SetPerkString(RTDPerk perk, RTDPerkProp prop, const char[] sStr);


// TODO: document
native any RTD2_GetPerkHandle(RTDPerk perk, RTDPerkProp prop);


// TODO: document?
typedef RTDCall = function void(int client, RTDPerk perk, bool bEnable);


// TODO: document
native any RTD2_SetPerkCall(RTDPerk perk, RTDCall func);


// TODO: document
native any RTD2_Format(RTDPerk perk, char[] sBuffer, int iBufferLen, const char[] sFormat);


// TODO: document
methodmap RTDPerk{
	public RTDPerk(const char[] sToken){
		return view_as<RTDPerk>(0);
	}

	property bool Valid{
		public get(){return view_as<int>(this) != -1;}
	}

	public void GetName(char[] sBuffer, int iBufferLen){
		RTD2_GetPerkString(this, RTDPerk_Name, sBuffer, iBufferLen);}

	public void SetName(const char[] sVal){
		RTD2_SetPerkString(this, RTDPerk_Name, sVal);}

	property bool Good{
		public get(){
			return view_as<bool>(RTD2_GetPerkAny(this, RTDPerk_Good));}
		public set(bool bVal){
			RTD2_SetPerkAny(this, RTDPerk_Good, bVal);}
	}

	public void GetSound(char[] sBuffer, int iBufferLen){
		RTD2_GetPerkString(this, RTDPerk_Sound, sBuffer, iBufferLen);}

	public void SetSound(const char[] sVal){
		RTD2_SetPerkString(this, RTDPerk_Sound, sVal);}

	public void GetToken(char[] sBuffer, int iBufferLen){
		RTD2_GetPerkString(this, RTDPerk_Token, sBuffer, iBufferLen);}

	property int Time{
		public get(){
			return view_as<int>(RTD2_GetPerkAny(this, RTDPerk_Time));}
		public set(int iVal){
			RTD2_SetPerkAny(this, RTDPerk_Time, iVal);}
	}

	property int Classes{
		public get(){
			return view_as<int>(RTD2_GetPerkAny(this, RTDPerk_Classes));}
	}
	public void SetClasses(const char[] sClasses){
		RTD2_SetPerkString(this, RTDPerk_Classes, sClasses);}

	property ArrayList WeaponClasses{
		public get(){
			return view_as<ArrayList>(RTD2_GetPerkHandle(this, RTDPerk_WeaponClasses));}
	}

	public void GetPref(char[] sBuffer, int iBufferLen){
		RTD2_GetPerkString(this, RTDPerk_Pref, sBuffer, iBufferLen);}

	public void SetPref(const char[] sVal){
		RTD2_SetPerkString(this, RTDPerk_Pref, sVal);}

	property ArrayList Tags{
		public get(){
			return view_as<ArrayList>(RTD2_GetPerkHandle(this, RTDPerk_Tags));}
	}

	property bool Enabled{
		public get(){
			return view_as<bool>(RTD2_GetPerkAny(this, RTDPerk_Enabled));}
		public set(bool bVal){
			RTD2_SetPerkAny(this, RTDPerk_Enabled, bVal);}
	}

	property bool External{
		public get(){
			return view_as<bool>(RTD2_GetPerkAny(this, RTDPerk_External));}
		public set(bool bVal){
			RTD2_SetPerkAny(this, RTDPerk_External, bVal);}
	}

	public void SetCall(RTDCall func){
		RTD2_SetPerkCall(this, func);}

	public void Format(char[] sBuffer, int iBufferLen, const char[] sFormat){
		RTD2_Format(this, sBuffer, iBufferLen, sFormat);}
}

// TODO: document
methodmap RTDPerkList < ArrayList{
	public RTDPerkList(){
		return view_as<RTDPerkList>(new ArrayList());
	}

	public RTDPerk Get(int i){
		return view_as<RTDPerk>(this.Get(i));
	}

	public RTDPerk GetRandom(){
		int iLen = this.Length;
		if(!iLen) return view_as<RTDPerk>(-1);
		return this.Get(GetRandomInt(0, --iLen));
	}
}



/*
 *==========
 * FORWARDS
 *==========
 */


/**
 * Called everytime rtd is activated to determine if the player can use the dice mod.
 * Return Plugin_Continue to allow, anything else denies them access.
 *
 * @note sm_forcertd command and RTD2_Force native does not call this.
 *
 * @param client		Client index.
 */
forward Action RTD2_CanRollDice(int client);


/**
 * Called when a perk is about to be forced by an admin (client) on a target (iTarget).
 * Return Plugin_Continue to allow, anything else denies the force.
 *
 * @note Called only by sm_forcertd command and RTD2_Force native.
 *
 * @param client	Client index.
 * @param iTarget	Target client index.
 * @param perk		Perk methodmap.
 */
forward Action RTD2_CanForcePerk(int client, int iTarget, RTDPerk perk);


/**
 * Called when a perk is about to be removed by an admin (client) from a target (iTarget).
 * Return Plugin_Continue to allow, anything else denies the force.
 *
 * @note Called only by sm_removertd command and RTD2_Remove native.
 *
 * @param client	Client index.
 * @param iTarget	Target client index.
 * @param perk		Perk methodmap.
 */
forward Action RTD2_CanRemovePerk(int client, int iTarget, RTDPerk perk);


/**
 * Called when a perk has just been activated on a player.
 *
 * @param client		Client Index.
 * @param perk			Perk methodmap.
 * @param iDuration		Perk Duration (-1 if no time).
 */
forward void RTD2_Rolled(int client, RTDPerk perk, int iDuration);


/**
 * Called when a perk has just been activated on a player.
 *
 * @param client		Client Index.
 * @param perk			Removed Perk's Index.
 * @param reason		Reason for removal.
 */
forward void RTD2_Removed(int client, RTDPerk perk, RTDRemoveReason reason);



/*
 *=========
 * NATIVES
 *=========
 */


/**
 * Returns player's current perk index. Meant to check if player is using RTD.
 *
 * @param client		Client Index.
 *
 * @return				Perk index if client is using RTD, -1 otherwise.
 */
#pragma deprecated Use RTD_GetClientPerk instead
native int RTD2_GetClientPerkId(int client);


// TODO: document
native RTDPerk RTD2_GetClientPerk(int client);


/**
 * Returns time in seconds the player has left to the perk end.
 *
 * @param client		Client Index.
 *
 * @return				Time in seconds if client is using RTD, -1 otherwise.
 */
native int RTD2_GetClientPerkTime(int client);


/**
 * Forces a perk on a player
 *
 * @param client		Client Index.
 * @param sPerk			Perk string, containing id, token or a tag. If invalid a roll will be used.
 * @param iTime			Custom perk's time. -1 = don't use.
 * @param bOvrClass		0/1 - If perk doesn't match player's class, should it be applied anyway?
 * @param initiator		Entity which initiated forcing the perk.
 *
 * @return				-1 because depricated
 */
#pragma deprecated Use RTD2_Force instead
native int RTD2_ForcePerk(int client, const char[] sQuery="", iTime=-1, bOvrClass=0, initiator=0);


// TODO: document
native RTDForceResult RTD2_Force(int client, const char[] sQuery, int iTime=-1, int iInitiator=0);


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
#pragma deprecated Use RTD2_Roll instead
native int RTD2_RollPerk(int client=0, int bOverrideDisabled=0, int bOverrideClass=0, int bCountRepeat=1, int bCountGreatRepeat=1);


// TODO: document
native RTDPerk RTD2_Roll(int client=0, int iRollFlags=ROLLFLAG_NONE, const char[] sFilter="");


/**
 * Removes current perk from the client.
 *
 * @param client		Client Index.
 * @param reason		Reason.
 * @param sReason		Provide custom reason IF iReason=RTDRemove_Custom.
 *
 * @return				Perk which got removed, invalid if client wasn't using RTD.
 */
#pragma deprecated Use RTD2_Roll instead
native RTDPerk RTD2_RemovePerk(int client, RTDRemoveReason reason=RTDRemove_WearOff, const char[] sReason="");


//TODO: document
native RTDPerk RTD2_Remove(int client, RTDRemoveReason reason=RTDRemove_WearOff, const char[] sReason="");


/**
 * Gets the perk's index by either the actual index, perk's token or a single tag
 *
 * @param sString		String to search by.
 *
 * @return				Perk's index on success, -1 otherwise.
 */
#pragma deprecated Use RTD2_FindPerk instead
native RTDPerk RTD2_GetPerkOfString(const char[] sString="");


// TODO: document
native RTDPerk RTD2_FindPerk(const char[] sQuery="");


// TODO: document
native RTDPerkList RTD2_FindPerks(const char[] sQuery="");



/*
 *==========
 * EXTERNAL
 *==========
 */


/*
The following are grouped individually,
because they are meant to be for plugins
which register their own perks to the RTD.

For a full tutorial on how to use those,
see the RTD's thread on AlliedModders:

https://forums.alliedmods.net/showthread.php?t=278579
*/

#pragma deprecated Use RTDCall instead
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
 * @param bGood		false - bad perk; true - good perk
 * @param sSound	Path to the initiation sound file.
 * @param iTime		-1 -> no timer; 0 -> ConVar default time; 0< -> Custom perk time.
 * @param sClass	Class string to limit the perk to.
 * @param sWeapon	Weapon classnames to limit the perk to.
 * @param sTags		Perk's tags used to find or address the perk.
 * @param func		Callback function; public(int client, RTDPerk perk, bool bEnable)
 *
 * @return			Perk's index on success, -1 otherwise (not all paremeters filled).
 */
#pragma deprecated Use RTD2_ObtainPerk instead
native RTDPerk RTD2_RegisterPerk(const char[] sToken, const char[] sName, bool bGood, const char[] sSound, int iTime, const char[] sClass, const char[] sWeapons, const char[] sTags, RTDCall func);

// TODO: document
native RTDPerk RTD2_ObtainPerk(const char[] sToken);


/**
 * Registering a perk via external plugin is possible only after all the core ones were registered.
 * You can register new perks in OnPluginStart() when this native returns 1 (if late-loaded).
 * Otherwise, register them in the RTD2_OnRegOpen() forward.
 *
 * @return			1 if registering is open, 0 otherwise.
 */
native bool RTD2_IsRegOpen();


/**
 * This forward will fire when RTD is ready handle perk registration.
 * RTD2_RegisterPerk() should ALWAYS be executed in this forward.
 */
forward void RTD2_OnRegOpen();


/**
 * Enables/disables perk by token.
 *
 * @params sToken	The token to find the perk by.
 * @params iDir		(direction) -1 = disable, 0 = toggle, 1 = enable
 *
 * @return			ID of the perk, -1 if not found.
 */
#pragma deprecated Use RTD2_SetPerk instead
native int RTD2_SetPerkByToken(const char[] sToken, int iDir=0);


/**
 * Enables/disables perk by ID.
 *
 * @params iId		Perk's ID.
 * @params iDir		(direction) -1 = disable, 0 = toggle, 1 = enable
 *
 * @return			1 if anything changed, 0 if was already in the requested state, -1 on error.
 */
#pragma deprecated Use RTD2_SetPerk instead
native int RTD2_SetPerkById(int iId, int iDir=0);


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
#pragma deprecated Use RTD2_SetPerk instead
native int RTD2_DefaultCorePerk(int iId=-1, const char[] sToken="");


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
native bool RTD2_CanPlayerBeHurt(int client, int by=0);
