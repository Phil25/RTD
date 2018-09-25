/**
* Drug Bullets perk.
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


int g_iDrugBulletsId = 58;

public void DrugBullets_Perk(int client, Perk perk, bool apply){
	if(apply){
		g_iDrugBulletsId = perk.Id;
		SetClientPerkCache(client, g_iDrugBulletsId);
		SetIntCache(client, 0);
	}else UnsetClientPerkCache(client, g_iDrugBulletsId);
}

void DrugBullets_PlayerHurt(int client, Handle hEvent){
	int iAtk = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(!iAtk || iAtk == client)
		return;

	if(!CheckClientPerkCache(iAtk, g_iDrugBulletsId))
		return;

	if(!IsPlayerAlive(client) || !GetEventInt(hEvent, "health"))
		return;

	int iTime = GetTime();
	if(GetIntCache(iAtk) > iTime){
		float fPunch[3];
		fPunch[0] = GetRandomFloat(-15.0, 15.0);
		fPunch[1] = GetRandomFloat(-15.0, 15.0);
		fPunch[2] = GetRandomFloat(-15.0, 15.0);
		SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fPunch);
		return;
	}

	Drugged_Tick(client); // From Drugged perk
	TF2_StunPlayer(client, 0.1, _, TF_STUNFLAG_THIRDPERSON, iAtk);
	SetIntCache(iAtk, iTime +1);
}
