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


bool g_bHasEyeForAnEye[MAXPLAYERS+1] = {false, ...};

void EyeForAnEye_Start(){

	HookEvent("player_hurt", EyeForAnEye_PlayerHurt);

}

public void EyeForAnEye_Perk(int client, const char[] sPref, bool apply){

	g_bHasEyeForAnEye[client] = apply;

}

public EyeForAnEye_PlayerHurt(Handle hEvent, const char[] sEventName, bool bDontBroadcast){

	int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(!g_bHasEyeForAnEye[attacker])
		return;
	
	SDKHooks_TakeDamage(attacker, 0, 0, float(GetEventInt(hEvent, "damageamount")));

}
