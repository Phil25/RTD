/**
* Invisibility perk.
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


/*
	IF YOU TELL ME HOW TO GET THE INSIDE OF THE B.A.S.E. JUMPER TO DISAPPEAR I WILL LOVE YOU FOREVER
*/

int		g_iBaseAlpha[MAXPLAYERS+1]	= {255, ...};
bool	g_bBaseSentry[MAXPLAYERS+1]	= {true, ...};
bool	g_bHasInvis[MAXPLAYERS+1]	= {false, ...};
int		g_iInvisValue				= 0;

void Invisibility_Start(){

	HookEvent("post_inventory_application", Event_Invisibility_Resupply, EventHookMode_Post);

}

void Invisibility_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		Invisibility_ApplyPerk(client, StringToInt(sPref));

	else
		Invisibility_RemovePerk(client);

}

void Invisibility_ApplyPerk(int client, int iValue){

	g_bHasInvis[client]		= true;
	g_iInvisValue			= iValue;
	
	g_iBaseAlpha[client]	= GetEntityAlpha(client);
	g_bBaseSentry[client]	= (GetEntityFlags(client) & FL_NOTARGET) ? true : false;
	
	Invisibility_Set(client, iValue);
	
	SetSentryTarget(client, false);

}

void Invisibility_RemovePerk(int client){

	g_bHasInvis[client]		= false;
	
	Invisibility_Set(client, g_iBaseAlpha[client]);
	
	SetSentryTarget(client, g_bBaseSentry[client]);

}

void Invisibility_Set(int client, int iValue){
	
	if(GetEntityRenderMode(client) == RENDER_NORMAL)
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	
	SetEntityAlpha(client, iValue);
	
	int iWeapon = 0;
	for(int i = 0; i < 5; i++){
	
		iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;
		
		if(GetEntityRenderMode(iWeapon) == RENDER_NORMAL)
			SetEntityRenderMode(iWeapon, RENDER_TRANSCOLOR);
		
		SetEntityAlpha(iWeapon, iValue);
	
	}
	
	char sClass[24];
	for(int i = MaxClients+1; i < GetMaxEntities(); i++){
	
		if(!IsCorrectWearable(client, i, sClass, sizeof(sClass))) continue;
		
		if(GetEntityRenderMode(i) == RENDER_NORMAL)
			SetEntityRenderMode(i, RENDER_TRANSCOLOR);
		
		SetEntityAlpha(i, iValue);
	
	}

}

public void Event_Invisibility_Resupply(Handle hEvent, const char[] sEventName, bool bDontBroadcast){

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client == 0)				return;
	if(!g_bHasInvis[client])	return;
	
	Invisibility_Set(client, g_iInvisValue);

}

stock int GetEntityAlpha(int iEntity){

	return GetEntData(iEntity, GetEntSendPropOffs(iEntity, "m_clrRender") + 3, 1);

}

stock void SetEntityAlpha(int iEntity, int iValue){

	SetEntData(iEntity, GetEntSendPropOffs(iEntity, "m_clrRender") + 3, iValue, 1, true);

}

bool IsCorrectWearable(int client, int i, char[] sClass, iBufferSize){

	if(!IsValidEntity(i))
		return false;

	GetEdictClassname(i, sClass, iBufferSize);
	if(StrContains(sClass, "tf_wearable", false) < 0 && StrContains(sClass, "tf_powerup", false) < 0)
		return false;
	
	if(GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") != client)
		return false;
	
	return true;

}

void SetSentryTarget(int client, bool bTarget){

	int iFlags = GetEntityFlags(client);	
	if(bTarget)
		SetEntityFlags(client, iFlags &~ FL_NOTARGET);
	else
		SetEntityFlags(client, iFlags | FL_NOTARGET);

}
