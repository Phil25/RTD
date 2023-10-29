/**
* Extra Throwables perk.
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

DEFINE_CALL_APPLY(ExtraThrowables)

public void ExtraThrowables_ApplyPerk(const int client, const Perk perk)
{
	int iAmount = perk.GetPrefCell("amount", 20);
	ExtraThrowables_SetOnSlot(client, 1, iAmount);
	ExtraThrowables_SetOnSlot(client, 2, iAmount);
}

void ExtraThrowables_SetOnSlot(const int client, const int iSlot, const int iAmount)
{
	int iWeapon = GetPlayerWeaponSlot(client, iSlot);
	if (!IsValidEntity(iWeapon))
		return;

	switch (GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		case 44, 648, 222, 812, 833, 1121, 42, 159, 311, 433, 863, 1002, 58, 1083, 1105, 1190:
			ExtraThrowables_SetOnWeapon(client, iWeapon, iAmount);
	}
}

void ExtraThrowables_SetOnWeapon(const int client, const int iWeapon, const int iAmount)
{
	int iOffset = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType", 1) * 4;
	int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	SetEntData(client, iAmmoTable + iOffset, iAmount, 4, true);
}
