#if defined _rtd2_included
  #endinput
#endif
#define _rtd2_included

public SharedPlugin __pl_rtd2 = {
	name = "RollTheDice2",
	file = "rtd2.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_rtd2_SetNTVOptional(){
	MarkNativeAsOptional("RTD2_GetPerkAny");
	MarkNativeAsOptional("RTD2_SetPerkAny");
	MarkNativeAsOptional("RTD2_GetPerkString");
	MarkNativeAsOptional("RTD2_SetPerkString");
	MarkNativeAsOptional("RTD2_SetPerkCall");

	MarkNativeAsOptional("RTD2_GetPerkPrefString");
	MarkNativeAsOptional("RTD2_GetPerkPrefCell");
	MarkNativeAsOptional("RTD2_GetPerkPrefFloat");
	MarkNativeAsOptional("RTD2_SetPerkPref");

	MarkNativeAsOptional("RTD2_Format");

	MarkNativeAsOptional("RTD2_GetClientPerkId"); // deprecated
	MarkNativeAsOptional("RTD2_GetClientPerk");
	MarkNativeAsOptional("RTD2_GetClientPerkTime");
	MarkNativeAsOptional("RTD2_AddClientPerkTime");

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
	MarkNativeAsOptional("RTD2_DisableModulePerks");

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
#define ROLLFLAG_IGNORE_GLOBAL_LIMIT	(1 << 5)	/* Ignore whether the perk is globally limited */
#define ROLLFLAG_IGNORE_TEAM_LIMIT		(1 << 6)	/* Ignore whether the perk is team limited */

#define RTD2_MAX_PERK_NAME_LENGTH	128


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
	RTDPerk_Tags,
	RTDPerk_InternalCall,
	RTDPerk_InternalInit,
	RTDPerk_NoMedieval,
	RTDPerk_LimitGlobal,
	RTDPerk_LimitTeam,
	RTDPerk_Enabled,
	RTDPerk_External
}

enum RTDRemoveReason{
	RTDRemove_PluginUnload = 0,
	RTDRemove_Death,
	RTDRemove_ClassChange,
	RTDRemove_WearOff,
	RTDRemove_Disconnect,
	RTDRemove_Custom,
	RTDRemove_NoPrint
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


/**
 * Gets perk property of type any or Handle.
 *
 * @note Prefer to use RTDPerk methodmap over this.
 * @note Handle type properties are not null.
 * @note Handle type properties are not cloned.
 *
 * @param perk		RTDPerk object
 * @param prop		RTDPerkProp property
 *
 * @return			Value of specified property
 */
native any RTD2_GetPerkAny(RTDPerk perk, RTDPerkProp prop);


/**
 * Sets perk property of type any.
 *
 * @note Prefer to use RTDPerk methodmap over this.
 * @note Unlike RTD2_GetPerkAny, cannot interact with Handle type properties.
 *
 * @param perk		RTDPerk object
 * @param prop		RTDPerkProp property
 * @param value	Value to set the property to
 *
 * @return			Same RTDPerk object
 */
native RTDPerk RTD2_SetPerkAny(RTDPerk perk, RTDPerkProp prop, any value);


/**
 * Gets perk property of type char[].
 *
 * @note Prefer to use RTDPerk methodmap over this.
 *
 * @param perk			RTDPerk object
 * @param prop			RTDPerkProp property
 * @param sBuffer		char[] buffer to store the result in
 * @param iBufferLen	Length of the buffer
 *
 * @noreturn
 */
native void RTD2_GetPerkString(RTDPerk perk, RTDPerkProp prop, char[] sBuffer, int iBufferLen);


/**
 * Sets perk property of type char[].
 *
 * @note Prefer to use RTDPerk methodmap over this.
 *
 * @param perk		RTDPerk object
 * @param prop		RTDPerkProp property
 * @param sStr		Value to set the property to
 *
 * @return			Same RTDPerk object
 */
native RTDPerk RTD2_SetPerkString(RTDPerk perk, RTDPerkProp prop, const char[] sStr);


/**
 * Prototype for external perk calls.
 *
 * @param client	Client to edit the perk on, guaranteed valid
 * @param perk		RTDPerk object
 * @param bEeable	Wether the perk should be enabled or disabled
 */
typedef RTDCall = function void(int client, RTDPerk perk, bool bEnable);


/**
 * Set the function to call when perk should operate on client.
 *
 * @note Prefer to use RTDPerk methodmap over this.
 *
 * @param perk		RTDPerk object
 * @param func		RTDCall function
 *
 * @return			Same RTDPerk object
 */
native RTDPerk RTD2_SetPerkCall(RTDPerk perk, RTDCall func);


/**
 * Gets perk setting of type cell.
 *
 * @note Prefer to use RTDPerk methodmap over this.
 * @note This is just a wrapper for rounding the float type setting.
 *
 * @param perk			RTDPerk object
 * @param sKey			Setting's key
 *
 * @return				Setting's value
 */
native int RTD2_GetPerkPrefCell(RTDPerk perk, const char[] sKey);


/**
 * Gets perk setting of type float.
 *
 * @note Prefer to use RTDPerk methodmap over this.
 *
 * @param perk			RTDPerk object
 * @param sKey			Setting's key
 *
 * @return				Setting's value
 */
native float RTD2_GetPerkPrefFloat(RTDPerk perk, const char[] sKey);


/**
 * Gets perk setting of type char[].
 *
 * @note Prefer to use RTDPerk methodmap over this.
 *
 * @param perk			RTDPerk object
 * @param sKey			Setting's key
 * @param sBuffer		char[] buffer to store the result in
 * @param iBufferLen	Length of the buffer
 *
 * @noreturn
 */
native void RTD2_GetPerkPrefString(RTDPerk perk, const char[] sKey, char[] sBuffer, int iBufferLen);


/**
 * Sets perk property of type char[].
 *
 * @note Prefer to use RTDPerk methodmap over this.
 * @note It will be determined internally whether to save the value as char[] or float.
 *
 * @param perk		RTDPerk object
 * @param sKey		Setting's key
 * @param sValue	Value to set the setting to
 *
 * @return			Same RTDPerk object
 */
native RTDPerk RTD2_SetPerkPref(RTDPerk perk, const char[] sKey, const char[] sValue);


/**
 * Format specific perk properties into a buffer.
 * Available specifiers: $Id$, $Name, $Good$,
 * $Sound$, $Token$, $Time$, $Tags$, $Class$,
 * $WeaponClass$, $Settings$, $InternalCall$,
 * $InternalInit$
 *
 * @note Format example: "Perk: $Id$ - $Name$"
 * @note Mind the capitalization.
 * @note Prefer to use RTDPerk methodmap over this.
 *
 * @param perk			RTDPerk object
 * @param sBuffer		Buffer to store the result in
 * @param iBufferLen	Length of the buffer
 * @param sFormat		Formatting rules
 *
 * @return				Same RTDPerk object
 */
native RTDPerk RTD2_Format(RTDPerk perk, char[] sBuffer, int iBufferLen, const char[] sFormat);


/* Object-oriented wrapper for perk management */
methodmap RTDPerk{

	// Specifies a perk. The perk is defined by the perk's ID.
	// Defines getters and setters for accessing all of the
	// perk's properties.
	//
	// RTDPerk methodmap would most of the times be obtained
	// through other natives or passed as an argument in a
	// forward. You probably don't want to call this
	// constructor at all.
	//
	// For creating perks, use RTD2_ObtainPerk().
	// For finding perks, use RTD2_FindPerk() and RTD2_FindPerks().
	//
	// RTDPerk is a cell under the hood, therefor doesn't need
	// to be freed with delete or CloseHandle().
	//
	// @param sToken	Token to bind the ID of
	// @return			RTDPerk object
	public RTDPerk(const char[] sToken){
		return view_as<RTDPerk>(0);
	}

	// Check if the perk is valid. This should be called after RTD2_FindPerk().
	property bool Valid{
		public get(){return view_as<int>(this) != -1;}
	}

	// Get name of the perk.
	//
	// @param sBuffer		Buffer to store the result in
	// @param iBufferLen	Length of the buffer
	//
	// @noreturn
	public void GetName(char[] sBuffer, int iBufferLen){
		RTD2_GetPerkString(this, RTDPerk_Name, sBuffer, iBufferLen);}

	// Set name of the perk.
	//
	// @param sVal		Value to set the name to
	//
	// @return			Same RTDPerk object
	public RTDPerk SetName(const char[] sVal){
		return RTD2_SetPerkString(this, RTDPerk_Name, sVal);}

	// Retrieves or sets whether the perk is good.
	property bool Good{
		public get(){
			return view_as<bool>(RTD2_GetPerkAny(this, RTDPerk_Good));}
		public set(bool bVal){
			RTD2_SetPerkAny(this, RTDPerk_Good, bVal);}
	}

	// Sets whether the perk is good.
	//
	// @note Prefer the property if not chaining methods.
	//
	// @param bSet		Value to determine whether the perk is good
	//
	// @return			Same RTDPerk object
	public RTDPerk SetGood(bool bSet){
		return RTD2_SetPerkAny(this, RTDPerk_Good, bSet);}

	// Get sound path of the perk.
	//
	// @param sBuffer		Buffer to store the result in
	// @param iBufferLen	Length of the buffer
	//
	// @noreturn
	public void GetSound(char[] sBuffer, int iBufferLen){
		RTD2_GetPerkString(this, RTDPerk_Sound, sBuffer, iBufferLen);}

	// Set sound path of the perk.
	//
	// @param sVal		Value to set the sound path to
	//
	// @return			Same RTDPerk object
	public RTDPerk SetSound(const char[] sVal){
		return RTD2_SetPerkString(this, RTDPerk_Sound, sVal);}

	// Get token of the perk.
	//
	// @param sBuffer		Buffer to store the result in
	// @param iBufferLen	Length of the buffer
	//
	// @noreturn
	public void GetToken(char[] sBuffer, int iBufferLen){
		RTD2_GetPerkString(this, RTDPerk_Token, sBuffer, iBufferLen);}

	// Retrieves or sets custom time of the perk.
	property int Time{
		public get(){
			return view_as<int>(RTD2_GetPerkAny(this, RTDPerk_Time));}
		public set(int iVal){
			RTD2_SetPerkAny(this, RTDPerk_Time, iVal);}
	}

	// Sets custom time of the perk.
	//
	// @note Prefer the property if not chaining methods.
	//
	// @param iVal		Value to set the time to
	//
	// @return			Same RTDPerk object
	public RTDPerk SetTime(int iVal){
		return RTD2_SetPerkAny(this, RTDPerk_Time, iVal);}

	// Retrieves perk class flags.
	property int Classes{
		public get(){
			return view_as<int>(RTD2_GetPerkAny(this, RTDPerk_Classes));}
	}

	// Set class flags the perk is applicable to.
	//
	// @note This string is parsed the same way its config equivalent is.
	//
	// @param sClasses	String with digits representing classes.
	//
	// @return			Same RTDPerk object
	public RTDPerk SetClasses(const char[] sClasses){
		return RTD2_SetPerkString(this, RTDPerk_Classes, sClasses);}

	// Retrieves ArrayList of weapon classes the perk is applicable to. This is never null and is not cloned.
	property ArrayList WeaponClasses{
		public get(){
			return view_as<ArrayList>(RTD2_GetPerkAny(this, RTDPerk_WeaponClasses));}
	}

	// Set weapon classes the perk is applicable to.
	//
	// @note Prefer the property if not chaining methods. Manually pushing classes is faster.
	// @note This string is parsed the same way its config equivalent is.
	// @note This will destroy and create the weapon classes Handle.
	//
	// @param sWeapClasses	String representing weapon classes or parts of them, separated by comma.
	//
	// @return				Same RTDPerk object
	public RTDPerk SetWeaponClasses(const char[] sWeapClasses){
		return RTD2_SetPerkString(this, RTDPerk_WeaponClasses, sWeapClasses);}

	// Retrieves ArrayList of perk's tags. This is never null and is not cloned.
	property ArrayList Tags{
		public get(){
			return view_as<ArrayList>(RTD2_GetPerkAny(this, RTDPerk_Tags));}
	}

	// Set search tags of the perk.
	//
	// @note Prefer the property if not chaining methods. Manually pushing tags is faster.
	// @note This string is parsed the same way its config equivalent is.
	// @note This will destroy and create the tags Handle.
	//
	// @param sTags		String representing tags, separated by comma
	//
	// @return			Same RTDPerk object
	public RTDPerk SetTags(const char[] sTags){
		return RTD2_SetPerkString(this, RTDPerk_Tags, sTags);}

	// Gets perk setting of type cell.
	//
	// @note This is just a wrapper for rounding the float type setting.
	//
	// @param sKey			Setting's key
	//
	// @return				Setting's value
	public int GetPrefCell(const char[] sKey){
		return RTD2_GetPerkPrefCell(this, sKey);}

	// Gets perk setting of type float.
	//
	// @param sKey			Setting's key
	//
	// @return				Setting's value
	public float GetPrefFloat(const char[] sKey){
		return RTD2_GetPerkPrefFloat(this, sKey);}

	// Gets perk setting of type char[].
	//
	// @param sKey			Setting's key
	// @param sBuffer		char[] buffer to store the result in
	// @param iBufferLen	Length of the buffer
	//
	// @noreturn
	public void GetPrefString(const char[] sKey, char[] sBuffer, int iBufferLen){
		RTD2_GetPerkPrefString(this, sKey, sBuffer, iBufferLen);}

	// Set settings of the perk.
	//
	// @note This will silently fail if sKey is prefixed with "m_".
	//
	// @param sKey		Setting's key
	// @param sValue	Value to set the setting to
	//
	// @return			Same RTDPerk object
	public RTDPerk SetPref(const char[] sKey, const char[] sValue){
		return RTD2_SetPerkPref(this, sKey, sValue);}

	// Get internal call function name assigned to the perk.
	//
	// @param sBuffer		Buffer to store the result in
	// @param iBufferLen	Length of the buffer
	//
	// @noreturn
	public void GetInternalCall(char[] sBuffer, int iBufferLen){
		RTD2_GetPerkString(this, RTDPerk_InternalCall, sBuffer, iBufferLen);}

	// Set internal call of the perk.
	//
	// @param sName		Name of the function to call during perk's execution.
	//
	// @return			Same RTDPerk object
	public RTDPerk SetInternalCall(const char[] sName){
		return RTD2_SetPerkString(this, RTDPerk_InternalCall, sName);}

	// Retrieves or sets whether the perk is enabled.
	property bool Enabled{
		public get(){
			return view_as<bool>(RTD2_GetPerkAny(this, RTDPerk_Enabled));}
		public set(bool bVal){
			RTD2_SetPerkAny(this, RTDPerk_Enabled, bVal);}
	}

	// Sets whether the perk is enabled
	//
	// @note Prefer the property if not chaining methods.
	// @note Perk is automatically enabled on registration.
	//
	// @param bVal		Value to determine whether the perk is enabled
	//
	// @return			Same RTDPerk object
	public RTDPerk SetEnabled(bool bVal){
		return RTD2_SetPerkAny(this, RTDPerk_Enabled, bVal);}

	// Retrieves or sets whether the perk should call an external function.
	property bool External{
		public get(){
			return view_as<bool>(RTD2_GetPerkAny(this, RTDPerk_External));}
		public set(bool bVal){
			RTD2_SetPerkAny(this, RTDPerk_External, bVal);}
	}

	// Sets whether the perk should call an external function.
	//
	// @note Prefer the property if not chaining methods.
	// @note Perk is automatically set to call an external function on registration.
	//
	// @param bVal		Value to determine whether the perk should call an external function
	//
	// @return			Same RTDPerk object
	public RTDPerk SetExternal(bool bVal){
		return RTD2_SetPerkAny(this, RTDPerk_External, bVal);}

	// Set external call of the perk.
	//
	// @note This also sets Enable and External to true.
	//
	// @param func		RTDCall function
	//
	// @return			Same RTDPerk object
	public RTDPerk SetCall(RTDCall func){
		return RTD2_SetPerkCall(this, func);}

	// Sets whether the perk is disabled in Medieval mode.
	//
	// @note Prefer the property if not chaining methods.
	//
	// @param bVal		Value to determine whether the perk is disabled in Medieval mode
	//
	// @return			Same RTDPerk object
	public RTDPerk SetNoMedieval(bool bVal){
		return RTD2_SetPerkAny(this, RTDPerk_NoMedieval, bVal);}

	// Retrieves or sets whether the perk is disabled in Medieval mode.
	property bool NoMedieval{
		public get(){
			return view_as<bool>(RTD2_GetPerkAny(this, RTDPerk_NoMedieval));}
		public set(bool bVal){
			RTD2_SetPerkAny(this, RTDPerk_NoMedieval, bVal);}
	}

	// Sets the active use limit of the perk, globally.
	//
	// @note Prefer the property if not chaining methods.
	//
	// @param bVal		Value to set the limit to
	//
	// @return			Same RTDPerk object
	public RTDPerk SetLimitGlobal(int iVal){
		return RTD2_SetPerkAny(this, RTDPerk_LimitGlobal, iVal);}

	// Retrieves or sets the active use limit of the perk, globally.
	property int LimitGlobal{
		public get(){
			return view_as<int>(RTD2_GetPerkAny(this, RTDPerk_LimitGlobal));}
		public set(int iVal){
			RTD2_SetPerkAny(this, RTDPerk_LimitGlobal, iVal);}
	}

	// Sets the active use limit of the perk, per team.
	//
	// @note Prefer the property if not chaining methods.
	//
	// @param bVal		Value to set the limit to
	//
	// @return			Same RTDPerk object
	public RTDPerk SetLimitTeam(int iVal){
		return RTD2_SetPerkAny(this, RTDPerk_LimitTeam, iVal);}

	// Retrieves or sets the active use limit of the perk, per team.
	property int LimitTeam{
		public get(){
			return view_as<int>(RTD2_GetPerkAny(this, RTDPerk_LimitTeam));}
		public set(int iVal){
			RTD2_SetPerkAny(this, RTDPerk_LimitTeam, iVal);}
	}

	// Format specific perk properties into a buffer.
	// Available specifiers: $Id$, $Name, $Good$,
	// $Sound$, $Token$, $Time$, $Tags$, $Class$,
	// $WeaponClass$, $Settings$, $NoMedieval$,
	// $LimitGlobal$, $LimitTeam$.
	//
	// @note Format example: "Perk: $Id$ - $Name$"
	// @note Mind the capitalization.
	//
	// @param sBuffer		Buffer to store the result in
	// @param iBufferLen	Length of the buffer
	// @param sFormat		Formatting rules
	//
	// @return				Same RTDPerk object
	public RTDPerk Format(char[] sBuffer, int iBufferLen, const char[] sFormat){
		return RTD2_Format(this, sBuffer, iBufferLen, sFormat);}
}

// Object-oriented wrapper for ArrayList of RTDPerk's
methodmap RTDPerkList < ArrayList{

	// Creates a RTDPerkList. RTDPerkLits inherits from ArrayList and holds
	// RTDPerks, which in turn are simply IDs of perks.
	//
	// The RTDPerkList must be freed via delete or CloseHandle().
	//
	// @return	RTDPerkList object
	public RTDPerkList(){
		return view_as<RTDPerkList>(new ArrayList());
	}

	// Wrapper for receiving contents as RTDPerk.
	//
	// @param i		Index to retrieve the perk at.
	//
	// @return		RTDPerk object
	public RTDPerk Get(int i){
		return view_as<RTDPerk>(view_as<ArrayList>(this).Get(i));
	}

	// Get random perk from the list.
	//
	// @return	RTDPerk object
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
 * @note sm_forcertd command and RTD2_Force native do not call this.
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
 * @param perk		Perk object.
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
 * @param perk		Perk object.
 */
forward Action RTD2_CanRemovePerk(int client, int iTarget, RTDPerk perk);


/**
 * Called when a perk has just been activated on a player.
 *
 * @param client		Client Index.
 * @param perk			Perk object.
 * @param iDuration		Perk Duration (-1 if no time).
 */
forward void RTD2_Rolled(int client, RTDPerk perk, int iDuration);


/**
 * Called when a perk has just been removed from a player.
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
#pragma deprecated Use RTD2_GetClientPerk instead
native int RTD2_GetClientPerkId(int client);


/**
 * Returns player's current RTDPerk. Can be used to check if the player is in roll.
 *
 * @note RTDPerk.Valid is false if client was not in roll.
 *
 * @param client		Client Index.
 *
 * @return				RTDPerk object
 */
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
 * Adds time to client's current roll.
 *
 * @param client		Client Index.
 * @param iAddedTime	Additional time in seconds, can be negative to subtract.
 *
 * @return				New remaining perk time, or non-positive if client was not in roll or perk is about to be removed because of this call.
 */
native int RTD2_AddClientPerkTime(int client, int iAddedTime);


/**
 * Forces a perk on a player
 *
 * @param client		Client Index.
 * @param sPerk			Perk string, containing id, token or a tag. If invalid a roll will be used.
 * @param iTime			Custom perk's time. -1 = don't use.
 * @param bOvrClass		0/1 - If perk doesn't match player's class, should it be applied anyway?
 * @param initiator		Entity which initiated forcing the perk.
 *
 * @return				-1 because deprecated
 */
#pragma deprecated Use RTD2_Force instead
native int RTD2_ForcePerk(int client, const char[] sQuery="", iTime=-1, bOvrClass=0, initiator=0);


/**
 * Forces a perk on a player
 *
 * @param client		Client Index.
 * @param sQuery		Query string, containing id, token or a tag. If invalid a roll will occur.
 * @param iTime			Custom perk's time. -1 = don't use.
 * @param iInitiator	Entity which initiated forcing the perk.
 *
 * @return				RTDForceResult enum value
 */
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


/**
 * Rolls a perk with given data.
 *
 * @note This does NOT apply the perk to the client.
 * @note RTDPerk.Valid is false is no applicable perks are found.
 *
 * @param client		Client Index.
 * @param iRollFlags	Roll flag definitions.
 * @param sFilter		Query by which to filter the applicable perks.
 *
 * @return				RTDPerk object
 */
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


/**
 * Removes current perk from the client.
 *
 * @note RTDPerk.Valid is falce if client was not in roll.
 *
 * @param client		Client Index.
 * @param reason		Reason enum.
 * @param sReason		Provide custom reason IF reason=RTDRemove_Custom.
 * @param bForce		Forced removals are treated as loggable actions, whereas non-forced are "natural" reasons. No distinction other than what is logged.
 * @param iInitiator	Client who initiated the removal. Used only when bForce=true.
 *
 * @return				RTDPerk object
 */
native RTDPerk RTD2_Remove(int client, RTDRemoveReason reason=RTDRemove_WearOff, const char[] sReason="", bool bForce=false, int iInitiator=0);


/**
 * Gets the perk's index by either the actual index, perk's token or a single tag
 *
 * @param sString		String to search by.
 *
 * @return				Perk's index on success, -1 otherwise.
 */
#pragma deprecated Use RTD2_FindPerk instead
native RTDPerk RTD2_GetPerkOfString(const char[] sString="");


/**
 * Finds a perk by token or ID, where token is prioritized.
 *
 * @note RTDPerk.Valid is false if perk is not found.
 *
 * @param sQuery		Query to search by.
 *
 * @return				RTDPerk object
 */
native RTDPerk RTD2_FindPerk(const char[] sQuery="");


/**
 * Finds perks by token, ID or tags.
 *
 * @note Will not be null, might be empty.
 * @note Must be freed via delete or CloseHandle().
 *
 * @param sQuery		Query to search by.
 *
 * @return				RTDPerkList object
 */
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


/**
 * Gets a perk by token, or registers one if not found.
 * Perks cannot be unregistered, disable them instead.
 * If a perk is registered, a new ID is automatically assigned.
 * For in-depth information, see the RTD thread on AlliedModders.
 *
 * @note This sets External to true on that perk.
 *
 * @param sToken	Unique token used for addressing the perk.
 *
 * @return			RTDPerk object
 */
native RTDPerk RTD2_ObtainPerk(const char[] sToken);


/**
 * Disables all the perks that were registered by the plugin this
 * native is called from, and sets all overriden core perks back
 * to the default state.
 *
 * If registering perks, this must be called in the OnPluginEnd.
 * This will make sure perks registered by the module will be
 * properly disposed on clients who currently are using them,
 * by calling the RTDCall function that disables them.
 *
 * @noreturn
 */
native void RTD2_DisableModulePerks();


/**
 * Registering a perk via external plugin is possible only after all the core ones were registered.
 * You can register new perks in OnPluginStart() when this native returns true (if late-loaded).
 * Otherwise, register them in the RTD2_OnRegOpen() forward.
 *
 * @return	true if registering is open, false otherwise.
 */
native bool RTD2_IsRegOpen();


/**
 * This forward will fire when RTD is ready handle perk registration.
 * RTD2_ObtainPerk() should ALWAYS be executed in this forward.
 */
forward void RTD2_OnRegOpen();


/**
 * Enables/disables perk by token.
 *
 * @param sToken	The token to find the perk by.
 * @param iDir		(direction) -1 = disable, 0 = toggle, 1 = enable
 *
 * @return			ID of the perk, -1 if not found.
 */
#pragma deprecated Use RTD2_SetPerk instead
native int RTD2_SetPerkByToken(const char[] sToken, int iDir=0);


/**
 * Enables/disables perk by ID.
 *
 * @param iId		Perk's ID.
 * @param iDir		(direction) -1 = disable, 0 = toggle, 1 = enable
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
 * @param iId		Perk's ID.
 * @param sToken	Perk's token.
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
 * @param client	Can this client be hurt...
 * @param by		...by this client?
 *
 * @return			1 if yes, 0 if not or error.
 */
native bool RTD2_CanPlayerBeHurt(int client, int by=0);
