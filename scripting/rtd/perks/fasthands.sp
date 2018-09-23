/**
* Fast Hands perk.
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


#define ATTRIB_RATE 6
#define ATTRIB_RELOAD 97

bool	g_bHasFastHands[MAXPLAYERS+1]	= {false, ...};
bool	g_bHasFastHands2[MAXPLAYERS+1]	= {false, ...};
float	g_fFastHandsRateMultiplier		= 2.0;
float	g_fFastHandsReloadMultiplier	= 2.0;

void FastHands_Start(){

	HookEvent("post_inventory_application", FastHands_Resupply, EventHookMode_Post);

}

public void FastHands_OnEntityCreated(int iEnt, const char[] sClassname){

	if(StrEqual(sClassname, "tf_dropped_weapon"))
		SDKHook(iEnt, SDKHook_SpawnPost, FastHands_OnDroppedWeaponSpawn);

}

public void FastHands_OnDroppedWeaponSpawn(int iEnt){

	int client = AccountIDToClient(GetEntProp(iEnt, Prop_Send, "m_iAccountID"));
	if(client && g_bHasFastHands2[client])
		AcceptEntityInput(iEnt, "Kill");

} 

void FastHands_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		FastHands_ApplyPerk(client, sPref);
	
	else
		FastHands_RemovePerk(client);

}

void FastHands_ApplyPerk(int client, const char[] sSettings){

	FastHands_ProcessSettings(sSettings);

	FastHands_EditClientWeapons(client, true);
	g_bHasFastHands[client]	= true;
	g_bHasFastHands2[client]= true;

}

void FastHands_RemovePerk(int client){

	FastHands_EditClientWeapons(client, false);
	g_bHasFastHands[client] = false;
	CreateTimer(0.5, Timer_FastHands_FullUnset, GetClientSerial(client));

}

public Action Timer_FastHands_FullUnset(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	
	if(client < 1)
		return Plugin_Stop;
	
	g_bHasFastHands2[client] = false;
	
	return Plugin_Stop;

}

void FastHands_EditClientWeapons(int client, bool apply){

	int iWeapon = 0;
	for(int i = 0; i < 3; i++){
	
		iWeapon = GetPlayerWeaponSlot(client, i);
		
		if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;
		
		if(apply){
		
			if(g_fFastHandsRateMultiplier != 0.0)
				TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_RATE, g_fFastHandsRateMultiplier);
			
			if(g_fFastHandsReloadMultiplier != 0.0)
				TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_RELOAD, g_fFastHandsReloadMultiplier);
		
		}else{
		
			TF2Attrib_RemoveByDefIndex(iWeapon, ATTRIB_RATE);
			TF2Attrib_RemoveByDefIndex(iWeapon, ATTRIB_RELOAD);
		
		}
	
	}

}

public void FastHands_Resupply(Handle hEvent, const char[] sEventName, bool bDontBroadcast){

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client == 0) return;

	if(g_bHasFastHands[client])
		FastHands_EditClientWeapons(client, true);

}

void FastHands_ProcessSettings(const char[] sSettings){

	char[][] sPieces = new char[2][8];
	ExplodeString(sSettings, ",", sPieces, 2, 8);
	
	g_fFastHandsRateMultiplier		= Pow(StringToFloat(sPieces[0]), -1.0);
	g_fFastHandsReloadMultiplier	= Pow(StringToFloat(sPieces[1]), -1.0);

}
