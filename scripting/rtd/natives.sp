/**
* Functions for RTD modules.
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

#if defined _natives_included
	#endinput
#endif
#define _natives_included

void CreateNatives(){
	CreateNative("RTD2_GetPerkAny",			Native_GetPerkAny);
	CreateNative("RTD2_SetPerkAny",			Native_SetPerkAny);
	CreateNative("RTD2_GetPerkString",		Native_GetPerkString);
	CreateNative("RTD2_SetPerkString",		Native_SetPerkString);
	CreateNative("RTD2_SetPerkCall",		Native_SetPerkCall);

	CreateNative("RTD2_GetPerkPrefCell",	Native_GetPerkPrefCell);
	CreateNative("RTD2_GetPerkPrefFloat",	Native_GetPerkPrefFloat);
	CreateNative("RTD2_GetPerkPrefString",	Native_GetPerkPrefString);
	CreateNative("RTD2_SetPerkPref",		Native_SetPerkPref);

	CreateNative("RTD2_Format",				Native_Format);

	CreateNative("RTD2_GetClientPerkId",	Native_GetClientPerkId); // deprecated
	CreateNative("RTD2_GetClientPerk",		Native_GetClientPerk);
	CreateNative("RTD2_GetClientPerkTime",	Native_GetClientPerkTime);

	CreateNative("RTD2_ForcePerk",			Native_ForcePerk); // deprecated
	CreateNative("RTD2_Force",				Native_Force);
	CreateNative("RTD2_RollPerk",			Native_RollPerk); // deprecated
	CreateNative("RTD2_Roll",				Native_Roll);
	CreateNative("RTD2_RemovePerk",			Native_Remove); // deprecated
	CreateNative("RTD2_Remove",				Native_Remove);

	CreateNative("RTD2_GetPerkOfString",	Native_FindPerk); // deprecated
	CreateNative("RTD2_FindPerk",			Native_FindPerk);
	CreateNative("RTD2_FindPerks",			Native_FindPerks);

	CreateNative("RTD2_RegisterPerk",		Native_RegisterPerk); // deprecated
	CreateNative("RTD2_ObtainPerk",			Native_ObtainPerk);
	CreateNative("RTD2_DisableModulePerks",	Native_DisableModulePerks);

	CreateNative("RTD2_IsRegOpen",			Native_IsRegisteringOpen);

	CreateNative("RTD2_SetPerkByToken",		Native_SetPerkByToken); // deprecated
	CreateNative("RTD2_SetPerkById",		Native_SetPerkById); // deprecated
	CreateNative("RTD2_DefaultCorePerk",	Native_DefaultCorePerk); // deprecated

	CreateNative("RTD2_CanPlayerBeHurt",	Native_CanPlayerBeHurt);
}

#define GET_PERK \
	int iId = GetNativeCell(1); \
	Perk perk = g_hPerkContainer.GetFromId(iId); \
	if(!perk) ThrowNativeError(0, "Invalid perk: %d. Is RTDPerk.Valid true?", GetNativeCell(1));

public int Native_GetPerkAny(Handle hPlugin, int iParams){
	GET_PERK
	RTDPerkProp prop = view_as<RTDPerkProp>(GetNativeCell(2));

	switch(prop){
		case RTDPerk_Good: return perk.Good;
		case RTDPerk_Time: return perk.Time;
		case RTDPerk_Classes: return perk.Class;
		case RTDPerk_WeaponClasses: return view_as<int>(perk.GetWeaponClass());
		case RTDPerk_Tags: return view_as<int>(perk.GetTags());
		case RTDPerk_Enabled: return perk.Enabled;
		case RTDPerk_External: return perk.External;
	}

	ThrowNativeError(0, "Property %d is not of type cell.", prop);
	return 0;
}

public int Native_SetPerkAny(Handle hPlugin, int iParams){
	GET_PERK
	RTDPerkProp prop = view_as<RTDPerkProp>(GetNativeCell(2));
	any aVal = GetNativeCell(3);

	switch(prop){
		case RTDPerk_Good: perk.Good = view_as<bool>(aVal);
		case RTDPerk_Time: perk.Time = view_as<int>(aVal);
		case RTDPerk_Enabled: perk.Enabled = view_as<bool>(aVal);
		case RTDPerk_External: perk.External = view_as<bool>(aVal);
		default: ThrowNativeError(0, "Property %d is not of type cell.", prop);
	}

	return iId;
}

public int Native_GetPerkString(Handle hPlugin, int iParams){
	GET_PERK
	RTDPerkProp prop = view_as<RTDPerkProp>(GetNativeCell(2));
	int iLen = GetNativeCell(4);
	char[] sBuffer = new char[iLen];

	switch(prop){
		case RTDPerk_Name: perk.GetName(sBuffer, iLen);
		case RTDPerk_Sound: perk.GetSound(sBuffer, iLen);
		case RTDPerk_Token: perk.GetToken(sBuffer, iLen);
		case RTDPerk_InternalCall: perk.GetInternalCall(sBuffer, iLen);
		default: ThrowNativeError(0, "Property %d is not of type char[].", prop);
	}

	SetNativeString(3, sBuffer, iLen);
	return 0;
}

public int Native_SetPerkString(Handle hPlugin, int iParams){
	GET_PERK
	RTDPerkProp prop = view_as<RTDPerkProp>(GetNativeCell(2));
	char sVal[127];
	GetNativeString(3, sVal, 127);

	switch(prop){
		case RTDPerk_Name: perk.SetName(sVal);
		case RTDPerk_Sound: perk.SetSound(sVal);
		case RTDPerk_Token: ThrowNativeError(0, "Tokens cannot be changed.");
		case RTDPerk_Classes: perk.SetClass(sVal);
		case RTDPerk_WeaponClasses: perk.SetWeaponClass(sVal);
		case RTDPerk_InternalCall: perk.SetInternalCall(sVal);
		case RTDPerk_Tags: perk.SetTags(sVal);
		default: ThrowNativeError(0, "Property %d is not of type char[].", prop);
	}

	return iId;
}

public int Native_SetPerkCall(Handle hPlugin, int iParams){
	GET_PERK
	perk.SetCall(GetNativeCell(2), hPlugin);
	return iId;
}

public int Native_GetPerkPrefCell(Handle hPlugin, int iParams){
	GET_PERK
	char sKey[16];
	GetNativeString(2, sKey, 16);
	return perk.GetPrefCell(sKey);
}

public int Native_GetPerkPrefFloat(Handle hPlugin, int iParams){
	GET_PERK
	char sKey[16];
	GetNativeString(2, sKey, 16);
	return view_as<int>(perk.GetPrefFloat(sKey));
}

public int Native_GetPerkPrefString(Handle hPlugin, int iParams){
	GET_PERK

	char sKey[16];
	GetNativeString(2, sKey, 16);
	int iLen = GetNativeCell(4);

	char[] sBuffer = new char[iLen];
	perk.GetPrefString(sKey, sBuffer, iLen);

	SetNativeString(3, sBuffer, iLen);
	return 0;
}

public int Native_SetPerkPref(Handle hPlugin, int iParams){
	GET_PERK

	char sKey[16], sVal[32];
	GetNativeString(2, sKey, 16);
	GetNativeString(3, sVal, 32);

	perk.SetPref(sKey, sVal);
	return iId;
}

// 1 perk, 2 buffer, 3 buffer len, 4 format
public int Native_Format(Handle hPlugin, int iParams){
	int iFormatLen = 0;
	GetNativeStringLength(4, iFormatLen);
	if(!iFormatLen)
		return 0;

	GET_PERK
	int iLen = GetNativeCell(3);
	char[] sBuffer = new char[iLen];
	char[] sFormat = new char[iFormatLen];
	GetNativeString(4, sFormat, iFormatLen);

	perk.Format(sBuffer, iLen, sFormat);
	SetNativeString(2, sBuffer, iLen);
	return iId;
}

#undef GET_PERK

public int Native_GetClientPerkId(Handle hPlugin, int iParams){ // deprecated
	Perk perk = g_hRollers.GetPerk(GetNativeCell(1));
	return perk ? perk.Id : -1;
}

public int Native_GetClientPerkTime(Handle hPlugin, int iParams){
	int client = GetNativeCell(1);
	return g_hRollers.GetInRoll(client) ? g_hRollers.GetEndRollTime(client) -GetTime() : -1;
}

public int Native_GetClientPerk(Handle hPlugin, int iParams){
	int client = GetNativeCell(1);
	Perk perk = g_hRollers.GetPerk(client);
	return perk ? perk.Id : -1;
}

public int Native_ForcePerk(Handle hPlugin, int iParams){ // deprecated
	char sQuery[32];
	GetNativeString(2, sQuery, sizeof(sQuery));
	return view_as<int>(ForcePerk(
		GetNativeCell(1),
		sQuery,
		GetNativeCell(3),
		GetNativeCell(5)
	));
}

public int Native_Force(Handle hPlugin, int iParams){
	char sQuery[32];
	GetNativeString(2, sQuery, sizeof(sQuery));
	int client = GetNativeCell(1),
		iPerkTime = GetNativeCell(3),
		iInitiator = GetNativeCell(4);
	return view_as<int>(ForcePerk(client, sQuery, iPerkTime, iInitiator));
}

public int Native_RollPerk(Handle hPlugin, int iParams){ // deprecated
	int client = GetNativeCell(1);
	Perk perk = RollPerk(client, ROLLFLAG_NONE, "");
	return perk ? perk.Id : -1;
}

public int Native_Roll(Handle hPlugin, int iParams){
	int client = GetNativeCell(1),
		iRollFlags = GetNativeCell(2);
	char sQuery[32];
	GetNativeString(3, sQuery, sizeof(sQuery));
	Perk perk = RollPerk(client, iRollFlags, sQuery);
	return perk ? perk.Id : -1;
}

public int Native_Remove(Handle hPlugin, int iParams){
	int client = GetNativeCell(1);
	RTDRemoveReason iReason = view_as<RTDRemoveReason>(GetNativeCell(2));
	char sReason[32];
	if(iReason == RTDRemove_Custom)
		GetNativeString(3, sReason, sizeof(sReason));

	Forward_OnRemovePerkPre(client);
	Perk perk = ForceRemovePerk(client, iReason, sReason);
	return perk ? perk.Id : -1;
}

public int Native_FindPerk(Handle hPlugin, int iParams){
	char sQuery[32];
	GetNativeString(1, sQuery, sizeof(sQuery));
	Perk perk = g_hPerkContainer.FindPerk(sQuery);
	return perk ? perk.Id : -1;
}

public int Native_FindPerks(Handle hPlugin, int iParams){
	char sQuery[32];
	GetNativeString(1, sQuery, sizeof(sQuery));
	PerkList results = g_hPerkContainer.FindPerks(sQuery);
	int i = results.Length;

	ArrayList idList = new ArrayList(_, i);
	while(--i >= 0) idList.Set(i, results.Get(i).Id);
	delete results;

	Handle list = CloneHandle(idList, hPlugin);
	delete idList;
	return view_as<int>(list);
}

public int Native_RegisterPerk(Handle hPlugin, int iParams){ // deprecated
	if(!g_bIsRegisteringOpen){
		char sPluginName[32];
		GetPluginFilename(hPlugin, sPluginName, sizeof(sPluginName));
		ThrowNativeError(SP_ERROR_NATIVE, "%s Plugin \"%s\" is trying to register perks before it's possible.\nPlease use the forward RTD2_OnRegOpen() and native RTD2_IsRegOpen() to determine.", CONS_PREFIX, sPluginName);
		return -1;
	}
	char sBuffer[127];
	GetNativeString(1, sBuffer, sizeof(sBuffer)); // token

	Perk perk = g_hPerkContainer.Get(sBuffer);
	int iId = -1;
	if(!perk){
		perk = new Perk();
		perk.SetToken(sBuffer);
		iId = g_hPerkContainer.Add(perk);
	}else iId = perk.Id;

	GetNativeString(2, sBuffer, sizeof(sBuffer)); // name
	perk.SetName(sBuffer);

	perk.Good = GetNativeCell(3) > 0;

	GetNativeString(4, sBuffer, sizeof(sBuffer)); // sound
	perk.SetSound(sBuffer);

	perk.Time = GetNativeCell(5);

	GetNativeString(6, sBuffer, sizeof(sBuffer)); // class
	perk.SetClass(sBuffer);

	GetNativeString(7, sBuffer, sizeof(sBuffer)); // weapons
	perk.SetWeaponClass(sBuffer);

	GetNativeString(8, sBuffer, sizeof(sBuffer)); // tags
	perk.SetTags(sBuffer);

	perk.SetCall(GetNativeCell(9), hPlugin);

	perk.External = true;

	return iId;
}

public int Native_ObtainPerk(Handle hPlugin, int iParams){
	if(!g_bIsRegisteringOpen){
		char sPluginName[32];
		GetPluginFilename(hPlugin, sPluginName, sizeof(sPluginName));
		ThrowNativeError(SP_ERROR_NATIVE, "%s Plugin \"%s\" is trying to register perks before it's possible.\nPlease use the forward RTD2_OnRegOpen() and native RTD2_IsRegOpen() to determine.", CONS_PREFIX, sPluginName);
		return -1;
	}
	char sToken[32];
	GetNativeString(1, sToken, sizeof(sToken));

	int iId = 0;
	Perk perk = g_hPerkContainer.Get(sToken);
	if(perk) return perk.Id;

	perk = new Perk();
	perk.SetToken(sToken);

	iId = g_hPerkContainer.Add(perk);
	perk.External = true;

	return iId;
}

public int Native_DisableModulePerks(Handle hPlugin, int iParams){
	DisableModulePerks(hPlugin);
	return 0;
}

public int Native_IsRegisteringOpen(Handle hPlugin, int iParams){
	return g_bIsRegisteringOpen;
}

public int Native_SetPerkByToken(Handle hPlugin, int iParams){ // deprecated
	char sTokenBuffer[32];
	GetNativeString(1, sTokenBuffer, sizeof(sTokenBuffer));

	Perk perk = g_hPerkContainer.Get(sTokenBuffer);
	if(!perk) return -1;

	int iDir = GetNativeCell(2);
	if(iDir < -1) iDir = -1;
	else if(iDir > 1) iDir = 1;

	switch(iDir){
		case -1:perk.Enabled = false;
		case 0:	perk.Enabled = !perk.Enabled;
		case 1:	perk.Enabled = true;
	}

	return perk.Id;
}

public int Native_SetPerkById(Handle hPlugin, int iParams){ // deprecated
	Perk perk = g_hPerkContainer.GetFromId(GetNativeCell(1));
	if(!perk) return -1;

	int iDir = GetNativeCell(2);
	if(iDir < -1) iDir = -1;
	else if(iDir > 1) iDir = 1;

	bool bPrevState = perk.Enabled;
	switch(iDir){
		case -1:perk.Enabled = false;
		case 0:	perk.Enabled = !perk.Enabled;
		case 1:	perk.Enabled = true;
	}
	return view_as<int>(perk.Enabled != bPrevState);
}

public int Native_DefaultCorePerk(Handle hPlugin, int iParams){ // deprecated
	Perk perk = g_hPerkContainer.GetFromId(GetNativeCell(1));
	if(!perk){
		char sTokenBuffer[32];
		GetNativeString(2, sTokenBuffer, 32);
		perk = g_hPerkContainer.Get(sTokenBuffer);
		if(!perk) return -1;
	}

	if(!perk.External)
		return 0;

	perk.External = false;
	return 1;
}

public int Native_CanPlayerBeHurt(Handle hPlugin, int iParams){
	int client = GetNativeCell(1);
	if(client < 1 || client > MaxClients)
		return 0;

	if(!IsClientInGame(client))
		return 0;

	return view_as<int>(CanPlayerBeHurt(client, GetNativeCell(2)));
}
