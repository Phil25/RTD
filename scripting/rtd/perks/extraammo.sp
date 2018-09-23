/**
* Extra Ammo perk.
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


int		g_iExtraAmmoOffsetClip, g_iExtraAmmoOffsetAmmo, g_iExtraAmmoOffsetAmmoType;

void ExtraAmmo_Start(){

	g_iExtraAmmoOffsetClip		= FindSendPropInfo("CTFWeaponBase", "m_iClip1");
	g_iExtraAmmoOffsetAmmo		= FindSendPropInfo("CTFPlayer", "m_iAmmo");
	g_iExtraAmmoOffsetAmmoType	= FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");

}

void ExtraAmmo_Perk(int client, const char[] sPref, bool apply){

	if(!apply)
		return;
	
	int iWeapon = -1;
	for(int i = 0; i < 2; i++){
	
		iWeapon = GetPlayerWeaponSlot(client, i);
		
		if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;
		
		ExtraAmmo_MultiplyAmmo(client, iWeapon, StringToFloat(sPref));
	
	}

}

void ExtraAmmo_MultiplyAmmo(int client, int iWeapon, float fMultiplier){

	switch(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex")){
	
		case 441,442,588:{
			SetEntPropFloat(iWeapon, Prop_Send, "m_flEnergy", 20.0*fMultiplier);
		
		}
		
		default:{
		
			int iClip = ExtraAmmo_GetClip(iWeapon);
			if(iClip > -1)
				ExtraAmmo_SetClip(iWeapon, iClip < 1 ? RoundFloat(fMultiplier) : RoundFloat(float(iClip) *fMultiplier));
		
			int iAmmo = ExtraAmmo_GetAmmo(client, iWeapon);
			if(iAmmo > -1)
				ExtraAmmo_SetAmmo(client, iWeapon, iAmmo < 1 ? RoundFloat(fMultiplier) : RoundFloat(float(iAmmo) *fMultiplier));
		
		}
	
	}

}

//The bellow are ripped straight from the original RTD

void ExtraAmmo_SetAmmo(int client, int iWeapon, int iAmount){

	int iOffset = g_iExtraAmmoOffsetAmmo + GetEntData(iWeapon, g_iExtraAmmoOffsetAmmoType, 1) * 4;
	SetEntData(client, iOffset, iAmount);

}

int ExtraAmmo_GetAmmo(int client, int iWeapon){

	int iAmmoType = GetEntData(iWeapon, g_iExtraAmmoOffsetAmmoType, 1);
	if(iAmmoType == 4) return -1;
	
	return GetEntData(client, g_iExtraAmmoOffsetAmmo + iAmmoType * 4);

}

void ExtraAmmo_SetClip(int iWeapon, int iAmount){

	SetEntData(iWeapon, g_iExtraAmmoOffsetClip, iAmount, _, true);

}

int ExtraAmmo_GetClip(int iWeapon){

	return GetEntData(iWeapon, g_iExtraAmmoOffsetClip);

}
