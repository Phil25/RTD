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

#define BASE_ALPHA 0
#define BASE_SENTRY 1
#define INVIS_VALUE 2

int g_iInvisibilityId = 7;

public void Invisibility_Call(int client, Perk perk, bool apply){
	if(apply) Invisibility_ApplyPerk(client, perk);
	else Invisibility_RemovePerk(client);
}

void Invisibility_ApplyPerk(int client, Perk perk){
	g_iInvisibilityId = perk.Id;
	SetClientPerkCache(client, g_iInvisibilityId);

	int iValue = perk.GetPrefCell("alpha");
	SetIntCache(client, iValue, INVIS_VALUE);
	SetIntCache(client, GetEntityAlpha(client), BASE_ALPHA);
	SetIntCache(client, GetEntityFlags(client) & FL_NOTARGET, BASE_SENTRY);

	Invisibility_Set(client, iValue);
	SetSentryTarget(client, false);
}

void Invisibility_RemovePerk(int client){
	UnsetClientPerkCache(client, g_iInvisibilityId);
	Invisibility_Set(client, GetIntCache(client, BASE_ALPHA));
	SetSentryTarget(client, !GetIntCacheBool(client, BASE_SENTRY));
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
		if(!IsCorrectWearable(client, i, sClass, sizeof(sClass)))
			continue;

		if(GetEntityRenderMode(i) == RENDER_NORMAL)
			SetEntityRenderMode(i, RENDER_TRANSCOLOR);

		SetEntityAlpha(i, iValue);
	}
}

void Invisibility_Resupply(int client){
	if(CheckClientPerkCache(client, g_iInvisibilityId))
		Invisibility_Set(client, GetIntCache(client, INVIS_VALUE));
}

bool IsCorrectWearable(int client, int i, char[] sClass, int iBufferSize){
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
	if(bTarget) SetEntityFlags(client, iFlags &~ FL_NOTARGET);
	else SetEntityFlags(client, iFlags | FL_NOTARGET);
}

#undef BASE_ALPHA
#undef BASE_SENTRY
#undef INVIS_VALUE
