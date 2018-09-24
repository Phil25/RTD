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


void Frozen_Perk(int client, bool apply){
	if(apply) Frozen_ApplyPerk(client);
	else Frozen_RemovePerk(client);
}

void Frozen_ApplyPerk(int client){
	SetIntCache(client, Frozen_GetEntityAlpha(client));
	Frozen_Set(client, 0);
	Frozen_DisarmWeapons(client, true);

	int iStatue = CreateDummy(client);
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
	Frozen_DisarmWeapons(client, false);

	SetEntityMoveType(client, MOVETYPE_WALK);
	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");
}

int CreateDummy(client){
	int iRag = CreateEntityByName("tf_ragdoll");
	if(iRag < 1 || iRag <= MaxClients || !IsValidEntity(iRag))
		return 0;

	float fPos[3], fAng[3], fVel[3];
	GetClientAbsOrigin(client, fPos);
	GetClientAbsAngles(client, fAng);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);

	TeleportEntity(iRag, fPos, fAng, fVel);

	SetEntProp(iRag, Prop_Send, "m_iPlayerIndex", client);
	SetEntProp(iRag, Prop_Send, "m_bIceRagdoll", 1);
	SetEntProp(iRag, Prop_Send, "m_iTeam", GetClientTeam(client));
	SetEntProp(iRag, Prop_Send, "m_iClass", _:TF2_GetPlayerClass(client));
	SetEntProp(iRag, Prop_Send, "m_bOnGround", 1);

	//Scale fix by either SHADoW NiNE TR3S or ddhoward (dunno who was first :p)
	//https://forums.alliedmods.net/showpost.php?p=2383502&postcount=1491
	//https://forums.alliedmods.net/showpost.php?p=2366104&postcount=1487
	SetEntPropFloat(iRag, Prop_Send, "m_flHeadScale", GetEntPropFloat(client, Prop_Send, "m_flHeadScale"));
	SetEntPropFloat(iRag, Prop_Send, "m_flTorsoScale", GetEntPropFloat(client, Prop_Send, "m_flTorsoScale"));
	SetEntPropFloat(iRag, Prop_Send, "m_flHandScale", GetEntPropFloat(client, Prop_Send, "m_flHandScale"));

	SetEntityMoveType(iRag, MOVETYPE_NONE);

	DispatchSpawn(iRag);
	ActivateEntity(iRag);

	return iRag;
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

void Frozen_DisarmWeapons(int client, bool bDisarm){
	int iWeapon = 0;
	for(int i = 0; i < 3; i++){
		iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;

		SetEntPropFloat(iWeapon, Prop_Data, "m_flNextPrimaryAttack",	bDisarm ? GetGameTime() + 86400.0 : 0.1);
		SetEntPropFloat(iWeapon, Prop_Data, "m_flNextSecondaryAttack",	bDisarm ? GetGameTime() + 86400.0 : 0.1);
	}
}
