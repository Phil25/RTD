/**
* Eye for an Eye perk.
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


int g_iEyeForAnEyeId = 38;

public void EyeForAnEye_Call(int client, Perk perk, bool apply){
	if(apply){
		g_iEyeForAnEyeId = perk.Id;
		SetClientPerkCache(client, g_iEyeForAnEyeId);
	}else UnsetClientPerkCache(client, g_iEyeForAnEyeId);
}

void EyeForAnEye_PlayerHurt(Handle hEvent){
	int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(CheckClientPerkCache(iAttacker, g_iEyeForAnEyeId))
		SDKHooks_TakeDamage(iAttacker, 0, 0, float(GetEventInt(hEvent, "damageamount")));
}
