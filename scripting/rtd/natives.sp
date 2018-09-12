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
	CreateNative("RTD2_GetClientPerkId",	Native_GetClientPerkId); // deprecated
	CreateNative("RTD2_GetClientPerk",		Native_GetClientPerk);
	CreateNative("RTD2_GetClientPerkTime",	Native_GetClientPerkTime);

	CreateNative("RTD2_ForcePerk",			Native_ForcePerk); // deprecated
	CreateNative("RTD2_Force",				Native_Force);
	CreateNative("RTD2_RollPerk",			Native_RollPerk); // deprecated
	CreateNative("RTD2_Roll",				Native_Roll);
	CreateNative("RTD2_RemovePerk",			Native_RemovePerk); // deprecated
	CreateNative("RTD2_Remove",				Native_Remove);

	CreateNative("RTD2_GetPerkOfString",	Native_GetPerkOfString); // deprecated
	CreateNative("RTD2_FindPerk",			Native_FindPerk);
	CreateNative("RTD2_FindPerks",			Native_FindPerks);

	CreateNative("RTD2_RegisterPerk",		Native_RegisterPerk); // deprecated
	CreateNative("RTD2_MakePerk",			Native_MakePerk);

	CreateNative("RTD2_IsRegOpen",			Native_IsRegisteringOpen);

	CreateNative("RTD2_SetPerkByToken",		Native_SetPerkByToken); // deprecated
	CreateNative("RTD2_SetPerkById",		Native_SetPerkById); // deprecated
	CreateNative("RTD2_DefaultCorePerk",	Native_DefaultCorePerk); // deprecated

	CreateNative("RTD2_GetPerkAny",			Native_GetPerkAny);
	CreateNative("RTD2_SetPerkAny",			Native_SetPerkAny);
	CreateNative("RTD2_GetPerkString",		Native_GetPerkString);
	CreateNative("RTD2_SetPerkString",		Native_SetPerkString);
	CreateNative("RTD2_GetPerkHandle",		Native_GetPerkHandle);
	CreateNative("RTD2_SetPerkCall",		Native_SetPerkCall);

	CreateNative("RTD2_CanPlayerBeHurt",	Native_CanPlayerBeHurt);
}

public int Native_GetClientPerkId(Handle hPlugin, int iParams){ // deprecated
	Perk perk = g_hRollers.GetPerk(GetNativeCell(1));
	return perk ? perk.GetId() : -1;
}

public int Native_GetClientPerkTime(Handle hPlugin, int iParams){
	int client = GetNativeCell(1);
	return g_hRollers.GetInRoll(client) ? g_hRollers.GetEndRollTime(client) -GetTime() : -1;
}

public int Native_GetClientPerk(Handle hPlugin, int iParams){
	return -1; // TODO: finish me
}

public int Native_ForcePerk(Handle hPlugin, int iParams){ // deprecated
	char sPerkString[32]; int iStringSize = sizeof(sPerkString);
	GetNativeString(2, sPerkString, iStringSize);
	/*return ForcePerk( TODO: correct me
		GetNativeCell(1),
		sPerkString,
		iStringSize,
		GetNativeCell(3),
		GetNativeCell(4) > 0 ? true : false,
		GetNativeCell(5)
	);*/
	return 0;
}

public int Native_Force(Handle hPlugin, int iParams){
	return view_as<int>(RTDForce_Success); // TODO: finish me
}

public int Native_RollPerk(Handle hPlugin, int iParams){ // deprecated
	return view_as<int>(RollPerk(0, 0, "")); // TODO: correct me, view_as too
}

public int Native_Roll(Handle hPlugin, int iParams){
	return -1; // TODO: finish me
}

public int Native_RemovePerk(Handle hPlugin, int iParams){ // TODO: figure out what to return // deprecated
	char sReason[32]; GetNativeString(3, sReason, sizeof(sReason));
	int client = GetNativeCell(1);

	Forward_OnRemovePerkPre(client);
	if(!g_hRollers.GetInRoll(client))
		return -1;

	return ForceRemovePerk(
		client,
		GetNativeCell(2),
		sReason
	);
}

public int Native_Remove(Handle hPlugin, int iParams){
	return -1; // TODO: finish me
}

public int Native_GetPerkOfString(Handle hPlugin, int iParams){ // deprecated
	char sString[32]; int iSize = sizeof(sString);
	GetNativeString(1, sString, iSize);
	return GetPerkOfString(sString, iSize);
}

public int Native_FindPerk(Handle hPlugin, int iParams){
	return -1; // TODO: finish me
}

public int Native_FindPerks(Handle hPlugin, int iParams){
	return 0; // TODO: finish me
}

public int Native_RegisterPerk(Handle hPlugin, int iParams){ // deprecated
	if(!g_bIsRegisteringOpen){
		char sPluginName[32];
		GetPluginFilename(hPlugin, sPluginName, sizeof(sPluginName));
		ThrowNativeError(SP_ERROR_NATIVE, "%s Plugin \"%s\" is trying to register perks before it's possible.\nPlease use the forward RTD2_OnRegOpen() and native RTD2_IsRegOpen() to determine.", CONS_PREFIX, sPluginName);
		return -1;
	}

	char sTokenBuffer[2][PERK_MAX_LOW], sClassBuffer[2][PERK_MAX_LOW], sWeaponsBuffer[2][PERK_MAX_HIGH], sTagsBuffer[2][PERK_MAX_VERYH];

		//---[ Token ]---//
	GetNativeString(1, sTokenBuffer[0], PERK_MAX_LOW);
	EscapeString(sTokenBuffer[0], ' ', '\0', sTokenBuffer[1], PERK_MAX_LOW);

	int iPerkId = FindPerkByToken(sTokenBuffer[1]);
	if(iPerkId == -1){
		iPerkId = g_iPerkCount;
		g_iPerkCount++;
	}

	strcopy(ePerks[iPerkId][sToken], PERK_MAX_LOW, sTokenBuffer[1]);

		//---[ Name ]---//
	GetNativeString(2, ePerks[iPerkId][sName], PERK_MAX_LOW);

		//---[ Good ]---//
	ePerks[iPerkId][bGood] = GetNativeCell(3) > 0 ? true : false;

		//---[ Sound ]---//
	GetNativeString(4, ePerks[iPerkId][sSound], PERK_MAX_HIGH);
	PrecacheSound(ePerks[iPerkId][sSound]);

		//---[ Time ]---//
	ePerks[iPerkId][iTime] = GetNativeCell(5);

		//---[ Class ]---//
	strcopy(sClassBuffer[1], PERK_MAX_LOW, "");
	GetNativeString(6, sClassBuffer[0], PERK_MAX_LOW);
	EscapeString(sClassBuffer[0], ' ', '\0', sClassBuffer[1], PERK_MAX_LOW);

	int iClassFlags = ClassStringToFlags(sClassBuffer[1]);
	if(iClassFlags < 1)
		iClassFlags = 511;

	ePerks[iPerkId][iClasses] = iClassFlags;

		//---[ Weapons ]---//
	strcopy(sWeaponsBuffer[1], PERK_MAX_HIGH, "");
	GetNativeString(7, sWeaponsBuffer[0], PERK_MAX_HIGH);
	EscapeString(sWeaponsBuffer[0], ' ', '\0', sWeaponsBuffer[1], PERK_MAX_HIGH);

	if(ePerks[iPerkId][hWeaponClasses] == INVALID_HANDLE)
		ePerks[iPerkId][hWeaponClasses] = CreateArray(32);
	else ClearArray(ePerks[iPerkId][hWeaponClasses]);

	if(FindCharInString(sWeaponsBuffer[1], '0') < 0){
		int iSize = CountCharInString(sWeaponsBuffer[1], ',')+1;
		char[][] sPieces = new char[iSize][32];

		ExplodeString(sWeaponsBuffer[1], ",", sPieces, iSize, 64);
		for(int i = 0; i < iSize; i++)
			PushArrayString(ePerks[iPerkId][hWeaponClasses], sPieces[i]);
	}

		//---[ Tags ]---//
	strcopy(sTagsBuffer[1], PERK_MAX_VERYH, "");
	GetNativeString(8, sTagsBuffer[0], PERK_MAX_VERYH);
	EscapeString(sTagsBuffer[0], ' ', '\0', sTagsBuffer[1], PERK_MAX_VERYH);

	if(ePerks[iPerkId][hTags] == INVALID_HANDLE)
		ePerks[iPerkId][hTags] = CreateArray(32);
	else ClearArray(ePerks[iPerkId][hTags]);

	if(strlen(sTagsBuffer[1]) > 0){
		int iTagSize = CountCharInString(sTagsBuffer[1], '|')+1;
		char[][] sPieces = new char[iTagSize][24];

		ExplodeString(sTagsBuffer[1], "|", sPieces, iTagSize, 24);
		for(int i = 0; i < iTagSize; i++)
			PushArrayString(ePerks[iPerkId][hTags], sPieces[i]);
	}

		//---[ The Rest ]---//
	ePerks[iPerkId][bIsExternal]	= true;
	ePerks[iPerkId][funcCallback]	= GetNativeCell(9);
	ePerks[iPerkId][plParent]		= hPlugin;

	return iPerkId;
}

public int Native_MakePerk(Handle hPlugin, int iParams){
	return -1; // TODO: finish me
}

public int Native_IsRegisteringOpen(Handle hPlugin, int iParams){
	return g_bIsRegisteringOpen;
}

public int Native_SetPerkByToken(Handle hPlugin, int iParams){ // deprecated
	char sTokenBuffer[PERK_MAX_LOW];
	GetNativeString(1, sTokenBuffer, PERK_MAX_LOW);

	int iPerkId = FindPerkByToken(sTokenBuffer);
	if(iPerkId == -1)
		return -1;

	int iDir = GetNativeCell(2);
	if(iDir < -1) iDir = -1;
	else if(iDir > 1) iDir = 1;

	switch(iDir){
		case -1:ePerks[iPerkId][bIsDisabled] = true;
		case 0:	ePerks[iPerkId][bIsDisabled] = ePerks[iPerkId][bIsDisabled] ? false : true;
		case 1:	ePerks[iPerkId][bIsDisabled] = false;
	}

	return iPerkId;
}

public int Native_SetPerkById(Handle hPlugin, int iParams){ // deprecated
	int iPerkId = GetNativeCell(1);
	if(iPerkId < 0 || iPerkId >= g_iPerkCount)
		return -1;

	int iDir = GetNativeCell(2);
	if(iDir < -1) iDir = -1;
	else if(iDir > 1) iDir = 1;

	int iChange = 0;
	switch(iDir){
		case -1:{
			if(!ePerks[iPerkId][bIsDisabled]){
				ePerks[iPerkId][bIsDisabled] = true;
				iChange = 1;
			}
		}

		case 0:{
			ePerks[iPerkId][bIsDisabled] = ePerks[iPerkId][bIsDisabled] ? false : true;
			iChange = 1;
		}

		case 1:{
			if(ePerks[iPerkId][bIsDisabled]){
				ePerks[iPerkId][bIsDisabled] = false;
				iChange = 1;
			}
		}
	}
	return iChange;
}

public int Native_DefaultCorePerk(Handle hPlugin, int iParams){ // deprecated
	int iPerkId = GetNativeCell(1);
	if(iPerkId < 0 || iPerkId >= g_iCorePerkCount){
		char sTokenBuffer[PERK_MAX_LOW];
		GetNativeString(2, sTokenBuffer, PERK_MAX_LOW);

		if(strlen(sTokenBuffer) < 1)
			return -1;

		iPerkId = FindPerkByToken(sTokenBuffer);
		if(iPerkId == -1)
			return -1;
	}

	int iChange = 0;
	if(ePerks[iPerkId][bIsExternal]){
		iChange = 1;
		ePerks[iPerkId][bIsExternal] = false;
	}

	return iChange;
}

public int Native_GetPerkAny(Handle hPlugin, int iParams){
	return 0; // TODO: finish me
}

public int Native_SetPerkAny(Handle hPlugin, int iParams){
	return 0; // TODO: finish me
}

public int Native_GetPerkString(Handle hPlugin, int iParams){
	return 0; // TODO: finish me
}

public int Native_SetPerkString(Handle hPlugin, int iParams){
	return 0; // TODO: finish me
}

public int Native_GetPerkHandle(Handle hPlugin, int iParams){
	return 0; // TODO: finish me
}

public int Native_SetPerkCall(Handle hPlugin, int iParams){
	return 0; // TODO: finish me
}

public int Native_CanPlayerBeHurt(Handle hPlugin, int iParams){
	int client = GetNativeCell(1);
	if(client < 1 || client > MaxClients)
		return 0;

	if(!IsClientInGame(client))
		return 0;

	return view_as<int>(CanPlayerBeHurt(client, GetNativeCell(2)));
}
