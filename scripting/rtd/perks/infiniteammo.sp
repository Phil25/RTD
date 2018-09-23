/**
* Infinite Ammo perk.
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


bool	g_bResupplyAmmo[MAXPLAYERS+1]	= {false, ...};
bool	g_bNoReload						= true;
int		g_iWeaponCache[MAXPLAYERS+1][3];

int		g_iOffsetClip, g_iOffsetAmmo, g_iOffsetAmmoType;

void InfiniteAmmo_Start(){

	g_iOffsetClip		= FindSendPropInfo("CTFWeaponBase", "m_iClip1");
	g_iOffsetAmmo		= FindSendPropInfo("CTFPlayer", "m_iAmmo");
	g_iOffsetAmmoType	= FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");

}

void InfiniteAmmo_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		InfiniteAmmo_ApplyPerk(client, StringToInt(sPref));
	
	else
		g_bResupplyAmmo[client] = false;

}

void InfiniteAmmo_ApplyPerk(int client, int iNoReload){

	g_bNoReload					= (iNoReload < 1) ? true : false;
	g_bResupplyAmmo[client]		= true;
	
	CreateTimer(0.25, Timer_ResupplyAmmo, GetClientSerial(client), TIMER_REPEAT);

}

public Action Timer_ResupplyAmmo(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;

	if(!g_bResupplyAmmo[client])
		return Plugin_Stop;
	
	InfiniteAmmo_Resupply(client);
	
	return Plugin_Continue;

}

void InfiniteAmmo_Resupply(int client){

	switch(TF2_GetPlayerClass(client)){

		case TFClass_Engineer:{
			SetEntProp(client, Prop_Data, "m_iAmmo", 200, 4, 3);
		}
		
		case TFClass_Spy:{
			SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 100.0);
		}

	}
	
	int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
		return;
	
	switch(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex")){
	
		case 441,442,588:{
		
			SetEntPropFloat(iWeapon, Prop_Send, "m_flEnergy", 20.0);
		
		}
		
		case 307:{
		
			SetEntProp(iWeapon, Prop_Send, "m_bBroken", 0);
			SetEntProp(iWeapon, Prop_Send, "m_iDetonated", 0);
		
		}
		
		default:{
		
			if(g_iWeaponCache[client][0] != iWeapon){
			
				g_iWeaponCache[client][0] = iWeapon;
				g_iWeaponCache[client][1] = GetClip(iWeapon);
				g_iWeaponCache[client][2] = GetAmmo(client, iWeapon);
			
			}else{
			
				int iClip = g_bNoReload ? GetClip(iWeapon) : -1;
				if(iClip > -1){
				
					if(iClip > g_iWeaponCache[client][1])
						g_iWeaponCache[client][1] = iClip;
					else if(iClip < g_iWeaponCache[client][1])
						SetClip(iWeapon, g_iWeaponCache[client][1]);
				
				}
			
				int iAmmo = GetAmmo(client, iWeapon);
				if(iAmmo > -1){
				
					if(iAmmo > g_iWeaponCache[client][2])
						g_iWeaponCache[client][2] = iAmmo;
					else if(iAmmo < g_iWeaponCache[client][2])
						SetAmmo(client, iWeapon, g_iWeaponCache[client][2]);
				
				}
			
			}
		
		}
	
	}

}

//The bellow are ripped straight from the original RTD

void SetAmmo(int client, int iWeapon, int iAmount){

	int iOffset = g_iOffsetAmmo + GetEntData(iWeapon, g_iOffsetAmmoType, 1) * 4;
	SetEntData(client, iOffset, iAmount);

}

int GetAmmo(int client, int iWeapon){

	int iAmmoType = GetEntData(iWeapon, g_iOffsetAmmoType, 1);
	if(iAmmoType == 4) return -1;
	
	return GetEntData(client, g_iOffsetAmmo + iAmmoType * 4);

}

void SetClip(int iWeapon, int iAmount){

	SetEntData(iWeapon, g_iOffsetClip, iAmount, _, true);

}

int GetClip(int iWeapon){

	return GetEntData(iWeapon, g_iOffsetClip);

}
