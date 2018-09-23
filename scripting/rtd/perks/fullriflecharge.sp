/**
* Full Rifle Charge perk.
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


int		g_iSniperPrimary[MAXPLAYERS+1]	= {0, ...};
bool	g_bHasFullCharge[MAXPLAYERS+1]	= {false, ...};
bool	g_bHasBow[MAXPLAYERS+1]			= {false, ...};

void FullRifleCharge_Start(){

	HookEvent("post_inventory_application", Event_FullRifleCharge_Resupply, EventHookMode_Post);

}

public void FullRifleCharge_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		FullRifleCharge_ApplyPerk(client);
	
	else
		g_bHasFullCharge[client] = false;

}

void FullRifleCharge_ApplyPerk(int client){
	
	FullRifleCharge_SetSniperPrimary(client);
	g_bHasFullCharge[client] = true;

}

void FullRifleCharge_SetSniperPrimary(int client){

	int iWeapon = GetPlayerWeaponSlot(client, 0);
	if(iWeapon > MaxClients && IsValidEntity(iWeapon)){
	
		char sClass[32];GetEdictClassname(iWeapon, sClass, sizeof(sClass));
		if(StrContains(sClass, "tf_weapon_sniperrifle") > -1){
			
			g_iSniperPrimary[client]	= iWeapon;
			g_bHasBow[client]			= false;
		
		}else if(StrContains(sClass, "tf_weapon_compound_bow") > -1){
			
			g_iSniperPrimary[client]	= iWeapon;
			g_bHasBow[client]			= true;
		
		}
	
	}

}

void FullRifleCharge_OnConditionAdded(int client, TFCond condition){

	if(!IsClientInGame(client))		return;
	if(!g_bHasFullCharge[client])	return;
	if(condition != TFCond_Slowed)	return;

	if(g_iSniperPrimary[client] > MaxClients && IsValidEntity(g_iSniperPrimary[client]))
		SetEntPropFloat(
			g_iSniperPrimary[client], Prop_Send,
			g_bHasBow[client] ? "m_flChargeBeginTime"	: "m_flChargedDamage",
			g_bHasBow[client] ? GetGameTime()-1.0		: 150.0
		);

}

public void Event_FullRifleCharge_Resupply(Handle hEvent, const char[] sEventName, bool bDontBroadcast){

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client == 0) return;

	if(!g_bHasFullCharge[client])
		return;
	
	FullRifleCharge_SetSniperPrimary(client);

}
