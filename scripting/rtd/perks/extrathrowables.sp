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


void ExtraThrowables_Perk(int client, Perk perk, bool apply){
	if(!apply) return;

	int iAmount = perk.GetPrefCell("amount");
	int iWeapon = 0;

	if(TF2_GetPlayerClass(client) == TFClass_Scout){
		iWeapon = GetPlayerWeaponSlot(client, 2);
		if(IsValidEntity(iWeapon)){
			int iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
			if(iIndex == 44 || iIndex == 648)
				ExtraThrowables_Set(client, iWeapon, iAmount);
		}
	}

	iWeapon = GetPlayerWeaponSlot(client, 1);
	if(!IsValidEntity(iWeapon))
		return;

	int iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
	switch(iIndex){
		case 222, 812, 833, 1121, 42, 159, 311, 433, 863, 1002, 58, 1083, 1105:
			ExtraThrowables_Set(client, iWeapon, iAmount);
	}
}

stock void ExtraThrowables_Set(int client, int iWeapon, int iAmount){
	int iOffset		= GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
	int iAmmoTable	= FindSendPropInfo("CTFPlayer", "m_iAmmo");
	SetEntData(client, iAmmoTable+iOffset, iAmount, 4, true);
}
