/**
* Frozen perk.
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


public void Frozen_Call(int client, Perk perk, bool apply){
	if(apply) Frozen_ApplyPerk(client);
	else Frozen_RemovePerk(client);
}

void Frozen_ApplyPerk(int client){
	SetIntCache(client, Frozen_GetEntityAlpha(client));
	Frozen_Set(client, 0);
	DisarmWeapons(client, true);

	int iStatue = CreateRagdoll(client, true);
	SetEntCache(client, iStatue);
	if(iStatue)
		SetClientViewEntity(client, iStatue);

	SetEntityMoveType(client, MOVETYPE_NONE);
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");
}

void Frozen_RemovePerk(int client){
	SetClientViewEntity(client, client);
	KillEntCache(client);

	Frozen_Set(client, GetIntCache(client));
	DisarmWeapons(client, false);

	SetEntityMoveType(client, MOVETYPE_WALK);
	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");
}

void Frozen_Set(int client, int iValue){
	if(GetEntityRenderMode(client) == RENDER_NORMAL)
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);

	Frozen_SetEntityAlpha(client, iValue);

	int iWeapon = 0;
	for(int i = 0; i < 5; i++){
		iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;

		if(GetEntityRenderMode(iWeapon) == RENDER_NORMAL)
			SetEntityRenderMode(iWeapon, RENDER_TRANSCOLOR);

		Frozen_SetEntityAlpha(iWeapon, iValue);
	}

	char sClass[24];
	for(int i = MaxClients+1; i < GetMaxEntities(); i++){
		if(!IsCorrectWearable(client, i, sClass, sizeof(sClass)))
			continue;

		if(GetEntityRenderMode(i) == RENDER_NORMAL)
			SetEntityRenderMode(i, RENDER_TRANSCOLOR);

		Frozen_SetEntityAlpha(i, iValue);
	}
}

stock int Frozen_GetEntityAlpha(int entity){
	return GetEntData(entity, GetEntSendPropOffs(entity, "m_clrRender") + 3, 1);
}

stock void Frozen_SetEntityAlpha(int entity, int value){
	SetEntData(entity, GetEntSendPropOffs(entity, "m_clrRender") + 3, value, 1, true);
}
