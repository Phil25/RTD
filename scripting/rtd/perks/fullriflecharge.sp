/**
* Full Rifle Charge perk.
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


int g_iFullRifleChargeId = 14;

public void FullRifleCharge_Call(int client, Perk perk, bool apply){
	if(apply) FullRifleCharge_ApplyPerk(client, perk);
	else UnsetClientPerkCache(client, g_iFullRifleChargeId);
}

void FullRifleCharge_ApplyPerk(int client, Perk perk){
	g_iFullRifleChargeId = perk.Id;
	SetClientPerkCache(client, g_iFullRifleChargeId);
}

void FullRifleCharge_OnConditionAdded(int client, TFCond condition){
	if(!IsClientInGame(client)) return;

	if(!CheckClientPerkCache(client, g_iFullRifleChargeId))
		return;

	if(condition != TFCond_Slowed)
		return;

	int iWeapon = GetPlayerWeaponSlot(client, 0);
	if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
		return;

	char sClass[32];
	GetEdictClassname(iWeapon, sClass, sizeof(sClass));

	if(StrContains(sClass, "tf_weapon_sniperrifle") > -1)
		SetEntPropFloat(iWeapon, Prop_Send, "m_flChargedDamage", 150.0);

	else if(StrContains(sClass, "tf_weapon_compound_bow") > -1)
		SetEntPropFloat(iWeapon, Prop_Send, "m_flChargeBeginTime", GetGameTime() -1.0);
}
