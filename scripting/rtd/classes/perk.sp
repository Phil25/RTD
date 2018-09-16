/**
* Perk class
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

#if defined _perkclass_included
	#endinput
#endif
#define _perkclass_included

#include "rtd/parsing.sp"

#define GET_PROP(%1,%2) \
	public get(){ \
		%1 i; \
		this.GetValue("m_" ... #%2, i); \
		return i;}

#define SET_PROP(%1,%2) \
	public set(%1 i){ \
		this.SetValue("m_" ... #%2, i);}

#define GET_VALUE(%1,%2) \
	public %1 Get%2(){ \
		%1 i; \
		this.GetValue("m_" ... #%2, i); \
		return i;}

#define SET_VALUE(%1,%2) \
	public void Set%2(%1 i){ \
		this.SetValue("m_" ... #%2, i);}

#define GET_STRING(%1) \
	public void Get%1(char[] s, int i){ \
		this.GetString("m_" ... #%1, s, i);}

#define SET_STRING(%1) \
	public void Set%1(const char[] s){ \
		this.SetString("m_" ... #%1, s);}

#define DISPOSE_MEMBER(%1) \
	Handle m_h%1; \
	if(this.GetValue("m_" ... #%1, m_h%1)){ \
		delete m_h%1;}

enum PerkPropType{
	Type_Invalid = 0,
	Type_Bool,
	Type_Int,
	Type_String,
	Type_Array
}

/* TF2 class enum offsets numbered accoring to their appearance in-game */
int g_iClassConverter[10] = {0, 1, 8, 2, 4, 7, 5, 3, 9, 6};

methodmap Perk < StringMap{
	public Perk(){
		StringMap map = new StringMap();
		map.SetValue("m_WeaponClass", new ArrayList(127));
		map.SetValue("m_Tags", new ArrayList(32));
		map.SetValue("m_Class", 511);
		return view_as<Perk>(map);
	}

	public void Dispose(){
		DISPOSE_MEMBER(WeaponClass)
		DISPOSE_MEMBER(Tags)
		DISPOSE_MEMBER(Call)

		this.Clear();
		delete this;
	}

	property int Id{
		GET_PROP(int,Id)
		SET_PROP(int,Id)
	}

	GET_STRING(Name)
	SET_STRING(Name)

	property bool Good{
		GET_PROP(bool,Good)
		SET_PROP(bool,Good)
	}

	GET_STRING(Sound)
	SET_STRING(Sound)

	GET_STRING(Token)
	SET_STRING(Token)

	property int Time{
		GET_PROP(int,Time)
		SET_PROP(int,Time)
	}

	property int Class{
		GET_PROP(int,Class)
	}
	public void SetClass(const char[] s){
		int iClassFlags = StringToClass(s);
		this.SetValue("m_Class", iClassFlags);
	}

	GET_VALUE(ArrayList,WeaponClass) // ArrayList storing strings of weapon classes
	public void SetWeaponClass(const char[] s){
		delete this.GetWeaponClass();
		ArrayList hWeapClass = StringToWeaponClass(s);
		this.SetValue("m_WeaponClass", hWeapClass);
	}

	GET_STRING(Pref) // preference string
	SET_STRING(Pref)

	GET_VALUE(ArrayList,Tags) // ArrayList storing strings of perk tags
	public void SetTags(const char[] s){
		delete this.GetTags();
		ArrayList hTags = StringToTags(s);
		this.SetValue("m_Tags", hTags);
	}

	property bool Enabled{
		GET_PROP(bool,Enabled)
		SET_PROP(bool,Enabled)
	}

	property bool External{
		GET_PROP(bool,External)
		SET_PROP(bool,External)
	}

	property Handle Parent{
		GET_PROP(Handle,Parent)
		SET_PROP(Handle,Parent)
	}

	public Handle GetCall(){
		Handle hFwd = null;
		this.GetValue("m_Call", hFwd);
		return hFwd;
	}

	public void SetCall(RTDCall func, Handle hPlugin){
		RemovePerkFromClients(this);
		delete this.GetCall();

		Handle hFwd = CreateForward(ET_Single, Param_Cell, Param_Cell, Param_Cell);
		AddToForward(hFwd, hPlugin, func);

		this.Parent = hPlugin;
		this.External = true;
		this.Enabled = true;
		this.SetValue("m_Call", hFwd);
	}

	public void Call(int client, bool bEnable){
		Call_StartForward(this.GetCall());
		Call_PushCell(client);
		Call_PushCell(this.Id);
		Call_PushCell(bEnable);
		Call_Finish();
	}

	public PerkPropType GetPropType(const char[] sProp){
		if(strlen(sProp) < 4)
			return Type_Invalid;
		switch(sProp[2]){
			case 'I': return Type_Int; // m_Id
			case 'N': return Type_String; // m_Name
			case 'G': return Type_Bool; // m_Good
			case 'S': return Type_String; // m_Sound
			case 'T': switch(sProp[3]){
				case 'o': return Type_String; // m_Token
				case 'i': return Type_Int; // m_Time
				case 'a': return Type_Array; // m_Tags
			}
			case 'C': return Type_Int; // m_Class
			case 'W': return Type_Array; // m_Array
			case 'P': return Type_String; // m_Pref
		}
		return Type_Invalid;
	}

	public void GetStringAsString(const char[] sProp, char[] sBuffer, int iLen){
		this.GetString(sProp, sBuffer, iLen);
	}

	public void GetBoolAsString(const char[] sProp, char[] sBuffer, int iLen){
		bool bVal = false;
		if(this.GetValue(sProp, bVal))
			Format(sBuffer, iLen, bVal ? "true" : "false");
	}

	public void GetIntAsString(const char[] sProp, char[] sBuffer, int iLen){
		int iVal = 0;
		if(this.GetValue(sProp, iVal))
			IntToString(iVal, sBuffer, iLen);
	}

	public void GetArrayAsString(const char[] sProp, char[] sBuffer, int iLen){
		ArrayList list;
		if(!this.GetValue(sProp, list))
			return;

		FormatEx(sBuffer, iLen, "[");
		char sItemBuffer[64];
		int iSize = list.Length;
		if(iSize > 0){
			list.GetString(0, sItemBuffer, 64);
			FormatEx(sBuffer, iLen, "%s%s", sBuffer, sItemBuffer);
			for(int i = 1; i < iSize; ++i){
				list.GetString(i, sItemBuffer, 64);
				FormatEx(sBuffer, iLen, "%s, %s", sBuffer, sItemBuffer);
			}
		}

		FormatEx(sBuffer, iLen, "%s]", sBuffer);
	}

	public int GetPropAsString(const char[] sProp, char[] sBuffer, int iLen){
		PerkPropType iPropType = this.GetPropType(sProp);
		switch(iPropType){
			case Type_Invalid:	return 0;
			case Type_Bool:		this.GetBoolAsString(sProp, sBuffer, iLen);
			case Type_Int:		this.GetIntAsString(sProp, sBuffer, iLen);
			case Type_String:	this.GetStringAsString(sProp, sBuffer, iLen);
			case Type_Array:	this.GetArrayAsString(sProp, sBuffer, iLen);
		}
		return strlen(sBuffer);
	}

	public int ExtractProp(const char[] sFormat, int iStart, int iLen, char[] sBuffer){
		int i = iStart+1;
		sBuffer[2] = '\0';
		for(; i < iLen; ++i){
			if(sFormat[i] != '$'){
				// i-iStart+1 -> sProp[2], sProp[3], ..., sProp[n]
				sBuffer[i-iStart+1] = sFormat[i];
				continue;
			}
			sBuffer[i-iStart+1] = '\0';
			break;
		}
		return i-iStart;
	}

	public int FormatProp(char[] sBuffer, int iStart, int iLen, const char[] sProp){
		char sPropString[127];
		int iPropLen = this.GetPropAsString(sProp, sPropString, 127);
		int i = 0;
		for(; (iStart+i) < iLen && i < iPropLen; ++i)
			sBuffer[iStart+i] = sPropString[i];
		return i;
	}

	public void Format(char[] sBuffer, int iLen, const char[] sFormat){
		int iFormatLen = strlen(sFormat);
		char sProp[32] = "m_";
		int i = 0, j = 0;
		for(; i < iFormatLen; ++i){
			if(sFormat[i] != '$'){
				sBuffer[j++] = sFormat[i];
				continue;
			}
			int iPropLen = this.ExtractProp(sFormat, i, iFormatLen, sProp);
			j += this.FormatProp(sBuffer, j, iLen, sProp);
			i += iPropLen;
		}
		sBuffer[j] = '\0';
	}

	public bool HasTag(const char[] sQuery){
		ArrayList tags = this.GetTags();
		char sBuffer[32];

		int i = tags.Length;
		while(--i >= 0){
			tags.GetString(i, sBuffer, 32);
			if(strcmp(sBuffer, sQuery, false) == 0)
				return true;
		}

		return false;
	}

	public bool IsInHistory(ArrayList history, int iLimit){
		int i = history.Length;
		if(i < iLimit) return false;

		iLimit = i -iLimit;
		int iId = this.Id;

		while(--i >= iLimit)
			if(history.Get(i) == iId)
				return true;
		return false;
	}

	public bool IsAptForClassOf(int client){
		int iClass = view_as<int>(TF2_GetPlayerClass(client));
		iClass = g_iClassConverter[iClass];
		return view_as<bool>(this.Class & (1 << --iClass));
	}

	public bool IsAptForLoadoutOf(int client){
		ArrayList hWeaps = this.GetWeaponClass();
		if(hWeaps == null) return true;

		int iLen = hWeaps.Length;
		if(!iLen) return true;

		int iWeap = 0;
		char sClass[32], sWeapClass[32];

		for(int i = 0; i < 5; i++){
			iWeap = GetPlayerWeaponSlot(client, i);

			if(iWeap <= MaxClients) continue;
			if(!IsValidEntity(iWeap)) continue;

			GetEntityClassname(iWeap, sWeapClass, 32);
			for(int j = 0; j < iLen; j++){
				hWeaps.GetString(j, sClass, 32);
				if(StrContains(sWeapClass, sClass, false) > -1)
					return true;
			}
		}
		return false;
	}

	public bool IsAptForSetupOf(int client, int iRollFlags){
		if(!(iRollFlags & ROLLFLAG_OVERRIDE_CLASS))
			if(!this.IsAptForClassOf(client))
				return false;

		if(!(iRollFlags & ROLLFLAG_OVERRIDE_LOADOUT))
			if(!this.IsAptForLoadoutOf(client))
				return false;

		return true;
	}

	public bool IsAptFor(int client, int iRollFlags){
		if(!(iRollFlags & ROLLFLAG_OVERRIDE_DISABLED))
			if(!this.Enabled) return false;

		if(client != 0){
			if(!(iRollFlags & ROLLFLAG_IGNORE_PLAYER_REPEATS))
				if(IsInClientHistory(client, this))
					return false;
			if(!(iRollFlags & ROLLFLAG_IGNORE_PERK_REPEATS))
				if(IsInPerkHistory(this))
					return false;
		}
		return this.IsAptForSetupOf(client, iRollFlags);
	}

	public void EmitSound(int client){
		char sSound[64];
		this.GetSound(sSound, 64);
		EmitSoundToAll(sSound, client);
	}
}

#undef GET_PROP
#undef SET_PROP
#undef GET_VALUE
#undef SET_VALUE
#undef GET_STRING
#undef SET_STRING
#undef DISPOSE_MEMBER
