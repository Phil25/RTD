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

#define GET_VALUE(%1) \
	public any Get%1(){ \
		any i; \
		this.GetValue("m_" ... #%1, i); \
		return i;}

#define SET_VALUE(%1) \
	public void Set%1(any i){ \
		this.SetValue("m_" ... #%1, i);}

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


typedef PerkCall = function void(int client, int iPerkId, bool bEnable);

methodmap Perk < StringMap{
	public Perk(){
		return view_as<Perk>(new StringMap());
	}

	/*public void DisposeMember(const char[] sMemName){
		Handle aMem;
		if(this.GetValue(sMemName, aMem)){
			PrintToServer("Disposing %s...", sMemName);
			delete aMem;
		}
	}*/

	public void Clear(){
		DISPOSE_MEMBER(WeaponClasses)
		DISPOSE_MEMBER(Tags)
		DISPOSE_MEMBER(Call)
	}

	public void Dispose(){
		this.Clear();
		delete this;
	}

	GET_VALUE(Id)
	SET_VALUE(Id)

	GET_STRING(Name)
	SET_STRING(Name)

	GET_VALUE(Good)
	SET_VALUE(Good)

	GET_STRING(Sound)
	SET_STRING(Sound)

	GET_STRING(Token)
	SET_STRING(Token)

	GET_VALUE(Time)
	SET_VALUE(Time)

	GET_VALUE(Class)
	public void SetClass(const char[] s){
		int h = StringToClass(s);
		this.SetValue("m_Class", h);
	}

	GET_VALUE(WeaponClass) // ArrayList storing strings of weapon classes
	public void SetWeaponClass(const char[] s){
		ArrayList h = StringToWeaponClass(s);
		this.SetValue("m_WeaponClass", h);
	}

	GET_STRING(Pref) // preference string
	SET_STRING(Pref)

	GET_STRING(Tags) // ArrayList storing strings of perk tags
	public void SetTags(const char[] s){
		ArrayList h = StringToTags(s);
		this.SetValue("m_Tags", h);
	}

	GET_VALUE(IsDisabled)
	SET_VALUE(IsDisabled)

	GET_VALUE(IsExternal)
	SET_VALUE(IsExternal)

	public void SetCall(PerkCall func){
		Handle hFwd = CreateForward(ET_Single, Param_Cell, Param_Cell, Param_Cell);
		AddToForward(hFwd, null, func);
		this.SetValue("m_Call", hFwd);
	}

	public Handle GetCall(){
		Handle hFwd = null;
		this.GetValue("m_Call", hFwd);
		return hFwd;
	}

	public void Call(int client, bool bEnable){
		Call_StartForward(this.GetCall());
		Call_PushCell(client);
		Call_PushCell(this.GetId());
		Call_PushCell(bEnable);
		Call_Finish();
	}

	GET_VALUE(Parent)
	SET_VALUE(Parent)

	public void FormatStringProperty(const char[] sProp, char[] sBuffer, char[] sInto){
		this.GetString(sProp, sBuffer, MAX_NAME_LENGTH);
		FormatEx(sInto, 1024, "%s\n* %s: %s", sInto, sProp, sBuffer);
	}

	public void FormatIntProperty(const char[] sProp, char[] sInto){
		int iVal;
		this.GetValue(sProp, iVal);
		FormatEx(sInto, 1024, "%s\n* %s: %d", sInto, sProp, iVal);
	}

	public void FormatArrayProperty(const char[] sProp, char[] sBuffer, char[] sInto){
		ArrayList list;
		this.GetValue(sProp, list);
		FormatEx(sInto, 1024, "%s\n* %s: [", sInto, sProp);

		int iSize = list.Length;
		if(iSize > 0){
			list.GetString(1, sBuffer, MAX_NAME_LENGTH);
			FormatEx(sInto, 1024, "%s%s", sInto, sBuffer);
			for(int i = 1; i < iSize; ++i){
				list.GetString(i, sBuffer, MAX_NAME_LENGTH);
				FormatEx(sInto, 1024, "%s, %s", sInto, sBuffer);
			}
		}

		FormatEx(sInto, 1024, "%s]", sInto);
	}

	public void Print(){
		char sBuffer[MAX_NAME_LENGTH];
		char sPrint[1024] = "\n======================";

		this.FormatStringProperty("m_Name", sBuffer, sPrint);
		this.FormatIntProperty("m_Good", sPrint);
		this.FormatStringProperty("m_Sound", sBuffer, sPrint);
		this.FormatStringProperty("m_Token", sBuffer, sPrint);
		this.FormatIntProperty("m_Time", sPrint);
		this.FormatIntProperty("m_Class", sPrint);
		this.FormatArrayProperty("m_WeaponClass", sBuffer, sPrint);
		this.FormatStringProperty("m_Pref", sBuffer, sPrint);
		this.FormatArrayProperty("m_Tags", sBuffer, sPrint);

		PrintToServer(sPrint);
	}
}

#undef GET_VALUE
#undef SET_VALUE
#undef GET_STRING
#undef SET_STRING
#undef DISPOSE_MEMBER

#define READ_STRING(%1,%2) \
	hKv.GetString(%1, sBuffer, sizeof(sBuffer)); \
	perk.Set%2(sBuffer);

methodmap PerkContainer < StringMap{
	public PerkContainer(){
		return view_as<PerkContainer>(new StringMap());
	}

	/*public void Clear(){
		Perk p = null;
		int i = this.Length;
		while(--i >= 0){
			p = this.Get(i);
			p.Dispose();
		}
		++i; // should end at -1
		this.Resize(i);
		if(i != 0)
			ThrowError("Error clearning PerkContainer: stopped at perk %d!", i)
	}

	public void Dispose(){
		this.Clear();
		delete this;
	}*/

	public int Add(Perk p){
		int iId = view_as<int>(this.GetValue("i", iId)) +iId;
		this.SetValue("i", iId);

		char sToken[32]; // TODO: check if token already exists
		p.GetToken(sToken, 32);

		p.SetId(iId);
		this.SetValue(sToken, p);

		return iId;
	}

	public Perk Get(const char[] sToken){
		Perk p;
		this.GetValue(sToken, p);
		return p;
	}

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
		perk.Print();
		return true;
	}

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
}

#undef READ_STRING
