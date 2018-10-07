/**
* Long Melee perk.
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


#define ATTRIB_MELEE_RANGE 264

int g_iLongMeleeId = 59;

void LongMelee_OnEntityCreated(int iEnt, const char[] sClassname){
	if(StrEqual(sClassname, "tf_dropped_weapon"))
		SDKHook(iEnt, SDKHook_SpawnPost, LongMelee_OnDroppedWeaponSpawn);
}

public void LongMelee_OnDroppedWeaponSpawn(int iEnt){
	int client = AccountIDToClient(GetEntProp(iEnt, Prop_Send, "m_iAccountID"));
	if(client && GetIntCacheBool(client, 3))
		AcceptEntityInput(iEnt, "Kill");
}

public void LongMelee_Call(int client, Perk perk, bool apply){
	if(apply) LongMelee_ApplyPerk(client, perk);
	else LongMelee_RemovePerk(client);
}

void LongMelee_ApplyPerk(int client, Perk perk){
	g_iLongMeleeId = perk.Id;
	SetClientPerkCache(client, g_iLongMeleeId);

	SetFloatCache(client, perk.GetPrefFloat("multiplier"));
	SetIntCache(client, true, 3);

	LongMelee_EditClientWeapons(client, true);
}

void LongMelee_RemovePerk(int client){
	LongMelee_EditClientWeapons(client, false);
	UnsetClientPerkCache(client, g_iLongMeleeId);
	CreateTimer(0.25, Timer_LongMelee_FullUnset, GetClientUserId(client));
}

public Action Timer_LongMelee_FullUnset(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(client) SetIntCache(client, false, 3);
	return Plugin_Stop;
}

void LongMelee_EditClientWeapons(int client, bool apply){
	int iWeapon = GetPlayerWeaponSlot(client, 2);
	if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
		return;

	if(apply) TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_MELEE_RANGE, GetFloatCache(client));
	else TF2Attrib_RemoveByDefIndex(iWeapon, ATTRIB_MELEE_RANGE);
}

void LongMelee_Resupply(int client){
	if(CheckClientPerkCache(client, g_iLongMeleeId))
		LongMelee_EditClientWeapons(client, true);
}
