/**
* Full Rifle Charge perk.
* Copyright (C) 2023 Filip Tomaszewski
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

DEFINE_CALL_EMPTY(FullRifleCharge)

public void FullRifleCharge_Init(const Perk perk)
{
	Events.OnConditionAdded(perk, FullRifleCharge_OnConditionAdded);
}

void FullRifleCharge_OnConditionAdded(int client, TFCond condition){
	if (condition != TFCond_Slowed)
		return;

	int iWeapon = GetPlayerWeaponSlot(client, 0);
	if (iWeapon <= MaxClients || !IsValidEntity(iWeapon))
		return;

	char sClass[32];
	GetEdictClassname(iWeapon, sClass, sizeof(sClass));

	if (strcmp(sClass[10], "sniperrifle") == 0)
	{
		SetEntPropFloat(iWeapon, Prop_Send, "m_flChargedDamage", 150.0);
	}
	else if (strcmp(sClass[10], "compound_bow") == 0)
	{
		SetEntPropFloat(iWeapon, Prop_Send, "m_flChargeBeginTime", GetGameTime() - 1.0);
	}
}
