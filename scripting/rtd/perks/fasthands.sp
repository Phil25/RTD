/**
* Fast Hands perk.
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


#define ATTRIB_RATE 394
#define ATTRIB_RELOAD 241

int g_iFastHandsId = 43;

void FastHands_OnEntityCreated(int iEnt, const char[] sClassname){
	if(StrEqual(sClassname, "tf_dropped_weapon"))
		SDKHook(iEnt, SDKHook_SpawnPost, FastHands_OnDroppedWeaponSpawn);
}

public void FastHands_OnDroppedWeaponSpawn(int iEnt){
	int client = AccountIDToClient(GetEntProp(iEnt, Prop_Send, "m_iAccountID"));
	if(client && GetIntCacheBool(client, 3))
		AcceptEntityInput(iEnt, "Kill");
}

public void FastHands_Call(int client, Perk perk, bool apply){
	if(apply) FastHands_ApplyPerk(client, perk);
	else FastHands_RemovePerk(client);
}

void FastHands_ApplyPerk(int client, Perk perk){
	g_iFastHandsId = perk.Id;
	SetClientPerkCache(client, g_iFastHandsId);

	float fRate = 1/perk.GetPrefFloat("attack");
	float fReload = 1/perk.GetPrefFloat("reload");

	FastHands_EditClientWeapons(client, true, fRate, fReload);
	SetIntCache(client, true, 3);
}

void FastHands_RemovePerk(int client){
	FastHands_EditClientWeapons(client, false);
	UnsetClientPerkCache(client, g_iFastHandsId);
	CreateTimer(0.25, Timer_FastHands_FullUnset, GetClientUserId(client));
}

public Action Timer_FastHands_FullUnset(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(client) SetIntCache(client, false, 3);
	return Plugin_Stop;
}

void FastHands_EditClientWeapons(int client, bool apply, float fRate=0.0, float fReload=0.0){
	int iWeapon = 0;
	if(apply) for(int i = 0; i < 3; i++){
		iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;

		if(fRate != 0.0) TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_RATE, fRate);
		if(fReload != 0.0) TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_RELOAD, fReload);
	}else for(int i = 0; i < 3; i++){
		iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;

		TF2Attrib_RemoveByDefIndex(iWeapon, ATTRIB_RATE);
		TF2Attrib_RemoveByDefIndex(iWeapon, ATTRIB_RELOAD);
	}
}

void FastHands_Resupply(int client){
	if(CheckClientPerkCache(client, g_iFastHandsId))
		FastHands_EditClientWeapons(client, true);
}
