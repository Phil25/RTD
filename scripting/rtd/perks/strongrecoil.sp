/**
* Strong Recoil perk.
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


bool g_bHasStrongRecoil[MAXPLAYERS+1] = {false, ...};

public void StrongRecoil_Perk(int client, const char[] sPref, bool apply){

	g_bHasStrongRecoil[client] = apply;

}

void StrongRecoil_CritCheck(int client, int iWeapon){

	if(!g_bHasStrongRecoil[client])
		return;

	if(GetPlayerWeaponSlot(client, 2) == iWeapon)
		return;
	
	float fShake[3];
	fShake[0] = GetRandomFloat(-20.0, -80.0);
	fShake[1] = GetRandomFloat(-25.0, 25.0);
	fShake[2] = GetRandomFloat(-25.0, 25.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fShake);

}
