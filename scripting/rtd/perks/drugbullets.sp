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


int g_bHasDrugBullets[MAXPLAYERS+1] = {false, ...};
int g_bNextDrugBulles[MAXPLAYERS+1] = {0, ...};

void DrugBullets_Start(){
	HookEvent("player_hurt", Event_DrugBullets_PlayerHurt);
}

public void DrugBullets_Perk(int client, const char[] sPref, bool apply){
	g_bHasDrugBullets[client] = apply;
}

public void Event_DrugBullets_PlayerHurt(Handle hEvent, const char[] sEventName, bool bDontBroadcast){
	int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(!attacker || !g_bHasDrugBullets[attacker])
		return;

	int victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!victim || attacker == victim)
		return;

	if(!IsPlayerAlive(victim) || !GetEventInt(hEvent, "health"))
		return;

	int iTime = GetTime();
	if(g_bNextDrugBulles[victim] > iTime){
		float fPunch[3];
		fPunch[0] = GetRandomFloat(-15.0, 15.0);
		fPunch[1] = GetRandomFloat(-15.0, 15.0);
		fPunch[2] = GetRandomFloat(-15.0, 15.0);
		SetEntPropVector(victim, Prop_Send, "m_vecPunchAngle", fPunch);
		return;
	}

	Drugged_Tick(victim); // From Drugged perk
	TF2_StunPlayer(victim, 0.1, _, TF_STUNFLAG_THIRDPERSON, attacker);
	g_bNextDrugBulles[victim] = iTime +1;
}
