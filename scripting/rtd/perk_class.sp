/**
* Perk class and Perk Container class.
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

#include "rtd/perk_parsing.sp"

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


typedef PerkCall = function void(int client, int iPerkId, bool bEnable);

methodmap Perk < StringMap{
	public Perk(){
		return view_as<Perk>(new StringMap());
	}

	public void Dispose(){
		DISPOSE_MEMBER(WeaponClass)
		DISPOSE_MEMBER(Tags)
		DISPOSE_MEMBER(Call)

		this.Clear();
		delete this;
	}

	GET_VALUE(int,Id)
	SET_VALUE(int,Id)

	GET_STRING(Name)
	SET_STRING(Name)

	GET_VALUE(bool,Good)
	SET_VALUE(bool,Good)

	GET_STRING(Sound)
	SET_STRING(Sound)

	GET_STRING(Token)
	SET_STRING(Token)

	GET_VALUE(int,Time)
	SET_VALUE(int,Time)

	GET_VALUE(int,Class)
	public void SetClass(const char[] s){
		int h = StringToClass(s);
		this.SetValue("m_Class", h);
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

	GET_VALUE(bool,Enabled)
	SET_VALUE(bool,Enabled)

	GET_VALUE(bool,External)
	SET_VALUE(bool,External)

	public Handle GetCall(){
		Handle hFwd = null;
		this.GetValue("m_Call", hFwd);
		return hFwd;
	}

	public void SetCall(PerkCall func){
		delete this.GetCall();
		Handle hFwd = CreateForward(ET_Single, Param_Cell, Param_Cell, Param_Cell);
		AddToForward(hFwd, null, func);
		this.SetValue("m_Call", hFwd);
	}

	public void Call(int client, bool bEnable){
		Call_StartForward(this.GetCall());
		Call_PushCell(client);
		Call_PushCell(this.GetId());
		Call_PushCell(bEnable);
		Call_Finish();
	}

	GET_VALUE(Handle,Parent)
	SET_VALUE(Handle,Parent) // TODO: leak when setting multiple times

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

}

#undef GET_VALUE
#undef SET_VALUE
#undef GET_STRING
#undef SET_STRING
#undef DISPOSE_MEMBER

// Small wrapper so you can do stuff like perkList.Get(x).Print()
methodmap PerkList < ArrayList{
	public PerkList(){
		return view_as<PerkList>(new ArrayList());
	}

	public Perk Get(int i){
		return view_as<Perk>(this.Get(i));
	}

	public Perk GetRandom(){
		int iLen = this.Length;
		if(!iLen) return null;
		return this.Get(GetRandomInt(0, --iLen));
	}
}


// helper array which maps perk IDs to tokens
ArrayList g_hPerkTokenMapper = null;

methodmap PerkContainer < StringMap{
	public PerkContainer(){
		g_hPerkTokenMapper = new ArrayList(32);
		return view_as<PerkContainer>(new StringMap());
	}

	public void DisposePerks(){
		Perk perk = null;
		char sToken[32];

		int i = g_hPerkTokenMapper.Length;
		while(--i >= 0){
			g_hPerkTokenMapper.GetString(i, sToken, 32);
			this.GetValue(sToken, perk);
			perk.Dispose();
		}

		this.Clear();
		g_hPerkTokenMapper.Clear();
	}

	public void Dispose(){
		this.DisposePerks();
		delete this;
	}

	public int Add(Perk p){
		char sToken[32]; // TODO: check if token already exists
		p.GetToken(sToken, 32);

		this.SetValue(sToken, p);
		int iId = g_hPerkTokenMapper.PushString(sToken);

		p.SetId(iId);
		return iId;
	}

	public Perk Get(const char[] sToken){
		Perk p;
		this.GetValue(sToken, p);
		return p;
	}

	public Perk GetFromIdEx(int iId){
		char sToken[32];
		g_hPerkTokenMapper.GetString(iId, sToken, 32);
		return this.Get(sToken);
	}

	public Perk GetFromId(int iId){
		// checks if bigger first because iterator uses it
		if(iId >= g_hPerkTokenMapper.Length || iId < 0)
			return null;
		return this.GetFromIdEx(iId);
	}

#define READ_STRING(%1,%2) \
	hKv.GetString(%1, sBuffer, sizeof(sBuffer)); \
	perk.Set%2(sBuffer);

#define READ_IF_EXISTS_STRING(%1,%2) \
	if(hKv.JumpToKey(%1)){ \
		hKv.GoBack(); \
		READ_STRING(%1,%2)}

#define READ_IF_EXISTS_BOOL(%1,%2) \
	if(hKv.JumpToKey(%1)){ \
		hKv.GoBack(); \
		perk.Set%2(hKv.GetNum(%1) > 0);}

#define READ_IF_EXISTS_NUM(%1,%2) \
	if(hKv.JumpToKey(%1)){ \
		hKv.GoBack(); \
		perk.Set%2(hKv.GetNum(%1));}


	public bool ParseAndAdd(KeyValues hKv, int iStats[2]){
		char sBuffer[127];
		Perk perk = new Perk();

		READ_STRING("name",Name)
		perk.SetGood(hKv.GetNum("good") > 0);
		READ_STRING("sound",Sound)
		READ_STRING("token",Token)
		perk.SetTime(hKv.GetNum("time"));
		READ_STRING("class",Class)
		READ_STRING("weapons",WeaponClass)
		READ_STRING("settings",Pref)
		READ_STRING("tags",Tags)
		iStats[perk.GetGood()]++;

		this.Add(perk);
		return true;
	}

	public bool ParseAndEdit(KeyValues hKv){
		char sBuffer[127];
		hKv.GetSectionName(sBuffer, 127);

		Perk perk = this.Get(sBuffer);
		if(perk == null)
			return false;

		READ_IF_EXISTS_STRING("name",Name)
		READ_IF_EXISTS_BOOL("good",Good)
		READ_IF_EXISTS_STRING("sound",Sound)
		READ_IF_EXISTS_NUM("time",Time)
		READ_IF_EXISTS_STRING("class",Class)
		READ_IF_EXISTS_STRING("weapons",WeaponClass)
		READ_IF_EXISTS_STRING("settings",Pref)
		READ_IF_EXISTS_STRING("tags",Tags)

		return true;
	}

#undef READ_IF_EXISTS_STRING
#undef READ_IF_EXISTS_BOOL
#undef READ_IF_EXISTS_NUM
#undef READ_STRING

	public int ParseKv(KeyValues hKv, int iStats[2]){
		int iPerksParsed = 0;
		do iPerksParsed += view_as<int>(this.ParseAndAdd(hKv, iStats));
		while(hKv.GotoNextKey());
		return iPerksParsed;
	}

	/* iStats filled with amount of bad perks (index 0), and good perks (index 1) */
	public int ParseFile(const char[] sPath, int iStats[2]){
		KeyValues hKv = new KeyValues("Effects");

		int iPerksParsed = -1;
		if(hKv.ImportFromFile(sPath) && hKv.GotoFirstSubKey())
			iPerksParsed = this.ParseKv(hKv, iStats);

		delete hKv;
		return iPerksParsed;
	}

	public int ParseCustomKv(KeyValues hKv){
		int iPerksParsed = 0;
		do iPerksParsed += view_as<int>(this.ParseAndEdit(hKv));
		while(hKv.GotoNextKey());
		return iPerksParsed;
	}

	public int ParseCustomFile(const char[] sPath){
		KeyValues hKv = new KeyValues("Effects");

		int iPerksParsed = -1;
		if(hKv.ImportFromFile(sPath) && hKv.GotoFirstSubKey())
			iPerksParsed = this.ParseCustomKv(hKv);

		delete hKv;
		return iPerksParsed;
	}

	public PerkList ToPerkList(){
		PerkList list = new PerkList();
		int iLen = g_hPerkTokenMapper.Length;
		for(int i = 0; i < iLen; i++)
			list.Push(this.GetFromIdEx(i));
		return list;
	}

	/* Returns Perk handle, do not close, might be null */
	public Perk FindPerk(const char[] sQuery){
		Perk perk = null;
		if(this.GetValue(sQuery, perk))
			return perk;

		int iId = -1;
		if(StringToIntEx(sQuery, iId) > 0)
			return this.GetFromId(iId);

		return perk;
	}

#define ADD_PERK_IF_TAG_MATCHES { \
	perk = this.GetFromIdEx(i); \
	if(perk.HasTag(sQuery)) \
		list.Push(perk); }

	/* Returns PerkList, must be closed, never null, but may be empty;
	include parameter adds the perk additionally and omits it in further search */
	public PerkList FindPerksFromTags(const char[] sQuery, Perk include=null){
		PerkList list = new PerkList();

		Perk perk = null;
		int iLen = g_hPerkTokenMapper.Length,
			i = 0;

		if(include == null){
			for(;i < iLen; i++)
				ADD_PERK_IF_TAG_MATCHES
		}else{
			int iOtherId = include.GetId();
			for(;i < iOtherId; i++)
				ADD_PERK_IF_TAG_MATCHES

			list.Push(include);
			i++;

			for(;i < iLen; i++)
				ADD_PERK_IF_TAG_MATCHES
		}

		return list;
	}

#undef ADD_PERK_IF_TAG_MATCHES

	/* Returns PerkList, must be closed, never null, but may be empty */
	public PerkList FindPerks(const char[] sQuery){
		if(strlen(sQuery) == 0)
			return this.ToPerkList();
		Perk perk = this.FindPerk(sQuery);
		return this.FindPerksFromTags(sQuery, perk);
	}
}

PerkContainer g_hPerkContainer = null;

/*
"""Interface""" for iterator pattern for 2 perk containers
* Get(0) - ID
* Get(1) - Perk handle
* Get(2) - Container (if null, indicates this is PerkContainerIter)
*/
methodmap PerkIter < ArrayList{
	public int Id(){
		return this.Get(0);
	}

	public Perk Perk(){
		return this.Get(1);
	}

	public PerkList List(){
		return this.Get(2);
	}

	public void SetPerk(int iId){
		this.Set(0, iId);
		PerkList list = this.List();
		if(list == null)
			this.Set(1, g_hPerkContainer.GetFromId(iId));

		else{
			if(iId >= list.Length || iId < 0)
				this.Set(1, view_as<Perk>(null));
			else this.Set(1, list.Get(iId));
		}
	}

	public void Next(){
		int iId = this.Id();
		this.SetPerk(++iId);
	}

	public void Prev(){
		int iId = this.Id();
		this.SetPerk(--iId);
	}
}

/* prefix ++ operator */
stock PerkIter operator++(PerkIter iter){
	iter.Next();
	return iter;
}

/* prefix -- operator */
stock PerkIter operator--(PerkIter iter){
	iter.Prev();
	return iter;
}

/* Iterator pattern for perks container */
methodmap PerkContainerIter < PerkIter{
	public PerkContainerIter(int iId){
		ArrayList list = new ArrayList(_, 3);
		list.Set(0, iId);
		list.Set(1, g_hPerkContainer.GetFromId(iId));
		list.Set(2, view_as<PerkList>(null));
		return view_as<PerkContainerIter>(list);
	}
}

/* Iterator pattern for perks list */
methodmap PerkListIter < PerkIter{
	public PerkListIter(PerkList list, int iId){
		ArrayList data = new ArrayList(_, 3);
		data.Set(0, iId);

		int iLen = list.Length;
		if(iId >= iLen || iId < 0)
			data.Set(1, view_as<Perk>(null));
		else data.Set(1, list.Get(iId));

		data.Set(2, list);
		return view_as<PerkListIter>(data);
	}
}
