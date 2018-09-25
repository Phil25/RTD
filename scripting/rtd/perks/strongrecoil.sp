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


int g_iStrongRecoilId = 50;

public void StrongRecoil_Call(int client, Perk perk, bool apply){
	if(apply){
		g_iStrongRecoilId = perk.Id;
		SetClientPerkCache(client, g_iStrongRecoilId);
	}else UnsetClientPerkCache(client, g_iStrongRecoilId);
}

void StrongRecoil_CritCheck(int client, int iWeapon){
	if(!CheckClientPerkCache(client, g_iStrongRecoilId))
		return;

	if(GetPlayerWeaponSlot(client, 2) == iWeapon)
		return;

	float fShake[3];
	fShake[0] = GetRandomFloat(-20.0, -80.0);
	fShake[1] = GetRandomFloat(-25.0, 25.0);
	fShake[2] = GetRandomFloat(-25.0, 25.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fShake);
}
