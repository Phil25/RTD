#if defined _perkclass_included
	#endinput
#endif
#define _perkclass_included

int ClassStringToFlags(const char[] sClasses){
	if(FindCharInString(sClasses, '0') > -1)
		return 511;

	int iLength = strlen(sClasses);
	if(iLength < 2){
		int iClass = StringToInt(sClasses);
		if(iClass < 1) return 0;
		else return (2 << (iClass -1));
	}else{
		int iCharSize = (iLength+1)/2;
		char[][] sPieces = new char[iCharSize][4];
		ExplodeString(sClasses, ",", sPieces, iCharSize, 4);

		int iValue = 0, iPowed = 0, iFlags = 0;
		for(int i = 0; i < iCharSize; i++){
			iValue = StringToInt(sPieces[i]);
			if(iValue > 9)
				continue;

			iPowed = 2 << (iValue -1);
			if(iFlags & iPowed)
				continue;

			iFlags |= iPowed;
		}
		return iFlags;
	}
}

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
		PrintToServer("Disposing member " ... #%1); \
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
	public void SetClass(const char[] sClass){
		int iFlags = ClassStringToFlags(sClass);
		this.SetValue("m_Class", iFlags);
	}

	//GET_VALUE(Classes)
	//SET_VALUE(Classes)

	GET_VALUE(WeaponClasses) // ArrayList storing strings
	SET_VALUE(WeaponClasses) // of weapon classes

	GET_STRING(Pref) // preference string
	SET_STRING(Pref)

	GET_VALUE(Tags) // ArrayList storing strings
	SET_VALUE(Tags) // of perk tags

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

		char sToken[32]; // TODO: check for token presence
		p.GetToken(sToken, 32);

		p.SetId(iId);
		this.SetValue(sToken, p);
		PrintToServer("Adding perk %s %d", sToken, iId);

		return iId;
	}

	public Perk Get(const char[] sToken){
		Perk p;
		this.GetValue(sToken, p);
		return p;
	}

	public Perk ParseKey(KeyValues hKv){
		char sBuffer[127];
		Perk perk = new Perk();

		READ_STRING("name",Name)
		perk.SetGood(hKv.GetNum("good") > 0);
		READ_STRING("sound",Sound)
		READ_STRING("token",Token)
		perk.SetTime(hKv.GetNum("time"));
		READ_STRING("class",Class)

		return perk;

			//----[ CLASS ]----//
		/*strcopy(sClassBuffer[1], PERK_MAX_HIGH, "");
		KvGetString(hKv, "class", sClassBuffer[0], PERK_MAX_LOW);
		EscapeString(sClassBuffer[0], ' ', '\0', sClassBuffer[1], PERK_MAX_LOW);

		iClassFlags = ClassStringToFlags(sClassBuffer[1]);
		if(iClassFlags < 1){
			PrintToServer("%s WARNING: Invalid class restriction(s) set at perk ID:%d (rtd2_perks.default.cfg). Assuming it's all-class.", CONS_PREFIX, iPerkId);
			LogError("%s WARNING: Invalid class restriction(s) set at perk ID:%d (rtd2_perks.default.cfg). Assuming it's all-class.", CONS_PREFIX, iPerkId);
			iWarnings++;
			iClassFlags = 511;
		}ePerks[iPerkId][iClasses] = iClassFlags;

			//----[ WEAPONS ]----//
		strcopy(sWeaponBuffer[1], PERK_MAX_HIGH, "");
		KvGetString(hKv, "weapons", sWeaponBuffer[0], PERK_MAX_HIGH);
		EscapeString(sWeaponBuffer[0], ' ', '\0', sWeaponBuffer[1], PERK_MAX_HIGH);

		if(ePerks[iPerkId][hWeaponClasses] == INVALID_HANDLE)
			ePerks[iPerkId][hWeaponClasses] = CreateArray(32);
		else ClearArray(ePerks[iPerkId][hWeaponClasses]);

		if(FindCharInString(sWeaponBuffer[1], '0') < 0){
			int iSize = CountCharInString(sWeaponBuffer[1], ',')+1;
			char[][] sPieces = new char[iSize][32];

			ExplodeString(sWeaponBuffer[1], ",", sPieces, iSize, 64);
			for(int i = 0; i < iSize; i++)
				PushArrayString(ePerks[iPerkId][hWeaponClasses], sPieces[i]);
		}

			//----[ SETTINGS ]----//
		KvGetString(hKv, "settings", sSettingBuffer, PERK_MAX_HIGH);
		EscapeString(sSettingBuffer, ' ', '\0', ePerks[iPerkId][sPref], PERK_MAX_HIGH);

			//----[ TAGS ]----//
		strcopy(sTagBuffer[1], PERK_MAX_VERYH, ""); iTagSize = 0;
		KvGetString(hKv, "tags", sTagBuffer[0], PERK_MAX_VERYH);
		EscapeString(sTagBuffer[0], ' ', '\0', sTagBuffer[1], PERK_MAX_VERYH);

		if(ePerks[iPerkId][hTags] == INVALID_HANDLE)
			ePerks[iPerkId][hTags] = CreateArray(32);
		else ClearArray(ePerks[iPerkId][hTags]);

		if(strlen(sTagBuffer[1]) > 0){
			iTagSize = CountCharInString(sTagBuffer[1], '|')+1;
			char[][] sPieces = new char[iTagSize][24];

			ExplodeString(sTagBuffer[1], "|", sPieces, iTagSize, 24);
			for(int i = 0; i < iTagSize; i++)
				PushArrayString(ePerks[iPerkId][hTags], sPieces[i]);
		}

			//----[ STATS ]----//
		if(ePerks[iPerkId][bGood])
			iGood++;
		else iBad++;

		g_iPerkCount++;
		g_iCorePerkCount++;*/
	}

	public void ParseKv(KeyValues hKv){
		do this.Add(this.ParseKey(hKv));
		while(hKv.GotoNextKey());
	}

	public bool ParseFile(const char[] sPath){
		KeyValues hKv = new KeyValues("Effects");

		bool bOpened = hKv.ImportFromFile(sPath) && hKv.GotoFirstSubKey();
		if(bOpened)
			this.ParseKv(hKv);

		delete hKv;
		return bOpened;
	}
}

#undef READ_STRING
