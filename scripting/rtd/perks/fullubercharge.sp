/**
* Full Ubercharge perk.
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


int		g_iMediGunCond[MAXPLAYERS+1]	= {-1, ...};
int		g_iMediGun[MAXPLAYERS+1]		= {0, ...};
bool	g_bRefreshUber[MAXPLAYERS+1]	= {false, ...};
bool	g_bUberComplete[MAXPLAYERS+1]	= {true, ...};

public void FullUbercharge_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		FullUbercharge_ApplyPerk(client);
	
	else
		FullUbercharge_RemovePerk(client);

}

void FullUbercharge_ApplyPerk(int client){

	int iWeapon = GetPlayerWeaponSlot(client, 1);
	if(iWeapon > MaxClients && IsValidEntity(iWeapon)){
	
		char sClass[20];GetEdictClassname(iWeapon, sClass, sizeof(sClass));
		if(strcmp(sClass, "tf_weapon_medigun") == 0){
		
			g_iMediGun[client]		= EntIndexToEntRef(iWeapon);
			g_bRefreshUber[client]	= true;
			g_bUberComplete[client]	= false;
			
			CreateTimer(0.2, Timer_RefreshUber, GetClientSerial(client), TIMER_REPEAT);
			
			int iWeapIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
			switch(iWeapIndex){
			
				case 35:	g_iMediGunCond[client] = view_as<int>(TFCond_Kritzkrieged);	//Kritzkrieg
				case 411:	g_iMediGunCond[client] = view_as<int>(TFCond_MegaHeal);		//Quick-Fix
				case 998:	g_iMediGunCond[client] = -1;								//Screw you, Vaccinator
				default:	g_iMediGunCond[client] = view_as<int>(TFCond_Ubercharged);	//Default
			
			}
		
		}
	
	}

}

void FullUbercharge_RemovePerk(int client){

	g_bRefreshUber[client] = false;

	if(g_iMediGunCond[client] > -1)
		CreateTimer(0.2, Timer_UberchargeEnd, GetClientSerial(client), TIMER_REPEAT);

}

public Action Timer_RefreshUber(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;
	
	if(!g_bRefreshUber[client])
		return Plugin_Stop;
	
	int iMediGun = EntRefToEntIndex(g_iMediGun[client]);
	if(iMediGun <= MaxClients)
		return Plugin_Stop;

	SetEntPropFloat(iMediGun, Prop_Send, "m_flChargeLevel", 1.0);
	return Plugin_Continue;

}

public Action Timer_UberchargeEnd(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;

	int iMediGun = EntRefToEntIndex(g_iMediGun[client]);
	if(iMediGun <= MaxClients){
		g_bUberComplete[client] = true;
		return Plugin_Stop;
	}
	
	if(GetEntPropFloat(iMediGun, Prop_Send, "m_flChargeLevel") > 0.05)
		return Plugin_Continue;
	
	g_bUberComplete[client] = true;
	return Plugin_Stop;

}

void FullUbercharge_OnConditionRemoved(int client, TFCond cond){

	if(g_bUberComplete[client])
		return;
	
	if(view_as<int>(cond) != g_iMediGunCond[client])
		return;

	if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == EntRefToEntIndex(g_iMediGun[client]))
		TF2_AddCondition(client, cond, 2.0);

}
