/**
* Overheal Bonus perk.
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


#define ATTRIB_OVERHEAL_BONUS 11 //the overheal bonus attribute

int g_iOverhealBonusId = 43;

void OverhealBonus_OnEntityCreated(int iEnt, const char[] sClassname){
	if(StrEqual(sClassname, "tf_dropped_weapon"))
		SDKHook(iEnt, SDKHook_SpawnPost, OverhealBonus_OnDroppedWeaponSpawn);
}

public void OverhealBonus_OnDroppedWeaponSpawn(int iEnt){
	int client = AccountIDToClient(GetEntProp(iEnt, Prop_Send, "m_iAccountID"));
	if(client && GetIntCacheBool(client, 3))
		AcceptEntityInput(iEnt, "Kill");
}

public void OverhealBonus_Call(int client, Perk perk, bool apply){
	if(apply) OverhealBonus_ApplyPerk(client, perk);
	else OverhealBonus_RemovePerk(client);
}

void OverhealBonus_ApplyPerk(int client, Perk perk){
	g_iOverhealBonusId = perk.Id;
	SetClientPerkCache(client, g_iOverhealBonusId);

	float fBonus = perk.GetPrefFloat("scale");

	OverhealBonus_EditClientWeapons(client, true, fBonus);
	SetIntCache(client, true, 3);
}

void OverhealBonus_RemovePerk(int client){
	OverhealBonus_EditClientWeapons(client, false);
	UnsetClientPerkCache(client, g_iOverhealBonusId);
	CreateTimer(0.25, Timer_OverhealBonus_FullUnset, GetClientUserId(client));
}

public Action Timer_OverhealBonus_FullUnset(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(client) SetIntCache(client, false, 3);
	return Plugin_Stop;
}

void OverhealBonus_EditClientWeapons(int client, bool apply, float fBonus=0.0){
	int iMediGun = GetPlayerWeaponSlot(client, 1);
	if(iMediGun <= MaxClients || !IsValidEntity(iMediGun))
		return;

	if(apply){
		if(fBonus != 0.0)
			TF2Attrib_SetByDefIndex(iMediGun, ATTRIB_OVERHEAL_BONUS, fBonus);
	}else TF2Attrib_RemoveByDefIndex(iMediGun, ATTRIB_OVERHEAL_BONUS);
}

void OverhealBonus_Resupply(int client){
	if(CheckClientPerkCache(client, g_iOverhealBonusId))
		OverhealBonus_EditClientWeapons(client, true);
}
