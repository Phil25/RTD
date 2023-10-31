/**
* Perk container classes: PerkContainer & PerkList
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

#if defined _containers_included
	#endinput
#endif
#define _containers_included

// Small wrapper so you can do stuff like perkList.Get(x).Print()
methodmap PerkList < ArrayList{
	public PerkList(){
		return view_as<PerkList>(new ArrayList());
	}

	public Perk Get(int i){
		return view_as<Perk>(view_as<ArrayList>(this).Get(i));
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

	public Perk Get(const char[] sToken){
		Perk perk = null;
		this.GetValue(sToken, perk);
		return perk;
	}

	public int Add(Perk perk){
		char sToken[32];
		perk.GetToken(sToken, 32);

		if(this.Get(sToken) != null){
			delete perk;
			return -1;
		}

		this.SetValue(sToken, perk);
		int iId = g_hPerkTokenMapper.PushString(sToken);

		perk.Id = iId;
		return iId;
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
		perk.%2 = hKv.GetNum(%1) > 0;}

#define READ_IF_EXISTS_NUM(%1,%2) \
	if(hKv.JumpToKey(%1)){ \
		hKv.GoBack(); \
		perk.%2 = hKv.GetNum(%1);}

	public void ParseSetting(KeyValues& hKv, Perk& perk){
		char sKey[16], sVal[32];
		hKv.GetSectionName(sKey, sizeof(sKey));
		hKv.GetString(NULL_STRING, sVal, sizeof(sVal), "0");
		perk.SetPref(sKey, sVal);
	}

	public void ParseSettings(KeyValues& hKv, Perk& perk){
		if(hKv.GotoFirstSubKey(false)){
			do this.ParseSetting(hKv, perk);
			while(hKv.GotoNextKey(false));
		}
		hKv.GoBack();
	}

	public bool ParseAndAdd(KeyValues hKv, int iStats[2]){
		char sBuffer[127];
		Perk perk = new Perk();

		READ_STRING("name",Name)
		perk.Good = hKv.GetNum("good") > 0;
		READ_STRING("sound",Sound)
		READ_STRING("token",Token)
		perk.Time = hKv.GetNum("time");
		READ_STRING("class",Class)
		READ_STRING("weapons",WeaponClass)

		if(hKv.JumpToKey("settings")){
			this.ParseSettings(hKv, perk);
			hKv.GoBack();
		}

		READ_STRING("tags",Tags)
		READ_STRING("call",InternalCall)
		READ_IF_EXISTS_STRING("init",InternalInit)
		iStats[view_as<int>(perk.Good)]++;

#if defined DEBUG
		char sName[64];
		perk.GetName(sName, sizeof(sName));
		LogError("New perk: %s (%x)", sName, perk);
#endif

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

		if(hKv.JumpToKey("settings")){
			this.ParseSettings(hKv, perk);
			hKv.GoBack();
		}

		READ_IF_EXISTS_STRING("tags",Tags)
		READ_IF_EXISTS_STRING("call",InternalCall)

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

		int iPerksParsed = 0;
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
			int iOtherId = include.Id;
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
