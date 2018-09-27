/**
* Full Ubercharge perk.
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


int g_iMediGuns[33] = {INVALID_ENT_REFERENCE, ...};
int g_iFullUberchargeIndex = 6;

public void FullUbercharge_Call(int client, Perk perk, bool apply){
	if(apply) FullUbercharge_ApplyPerk(client, perk);
	else FullUbercharge_RemovePerk(client);
}

void FullUbercharge_ApplyPerk(int client, Perk perk){
	g_iFullUberchargeIndex = perk.Id;
	int iWeapon = GetPlayerWeaponSlot(client, 1);
	if(iWeapon > MaxClients && IsValidEntity(iWeapon)){
		char sClass[20];
		GetEdictClassname(iWeapon, sClass, sizeof(sClass));

		if(strcmp(sClass, "tf_weapon_medigun") == 0){
			g_iMediGuns[client] = EntIndexToEntRef(iWeapon);
			SetClientPerkCache(client, g_iFullUberchargeIndex);
			SetIntCache(client, 0);

			CreateTimer(0.2, Timer_RefreshUber, GetClientUserId(client), TIMER_REPEAT);

			int iWeapIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
			switch(iWeapIndex){
				case 35:	SetIntCache(client, view_as<int>(TFCond_Kritzkrieged), 1);
				case 411:	SetIntCache(client, view_as<int>(TFCond_MegaHeal), 1);
				case 998:	SetIntCache(client, -1, 1);
				default:	SetIntCache(client, view_as<int>(TFCond_Ubercharged), 1);
			}
		}
	}
}

void FullUbercharge_RemovePerk(int client){
	UnsetClientPerkCache(client, g_iFullUberchargeIndex);
	if(GetIntCache(client, 1) > -1)
		CreateTimer(0.2, Timer_UberchargeEnd, GetClientUserId(client), TIMER_REPEAT);
}

public Action Timer_RefreshUber(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iFullUberchargeIndex))
		return Plugin_Stop;

	int iMediGun = EntRefToEntIndex(g_iMediGuns[client]);
	if(iMediGun <= MaxClients)
		return Plugin_Stop;

	SetEntPropFloat(iMediGun, Prop_Send, "m_flChargeLevel", 1.0);
	return Plugin_Continue;

}

public Action Timer_UberchargeEnd(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	int iMediGun = EntRefToEntIndex(g_iMediGuns[client]);
	if(iMediGun <= MaxClients){
		SetIntCache(client, 1);
		return Plugin_Stop;
	}

	if(GetEntPropFloat(iMediGun, Prop_Send, "m_flChargeLevel") > 0.05)
		return Plugin_Continue;

	SetIntCache(client, 1);
	return Plugin_Stop;
}

void FullUbercharge_OnConditionRemoved(int client, TFCond cond){
	if(GetIntCache(client))
		return;

	if(view_as<int>(cond) != GetIntCache(client, 1))
		return;

	int iMediGun = EntRefToEntIndex(g_iMediGuns[client]);
	if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == iMediGun)
		TF2_AddCondition(client, cond, 2.0);
}
