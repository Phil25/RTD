/**
* Mercs Die Twice perk.
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

public void MercsDieTwice_Call(int client, Perk perk, bool bApply){
	if(bApply) MercsDieTwice_ApplyPerk(client, perk);
	else MercsDieTwice_RemovePerk(client);
}

void MercsDieTwice_ApplyPerk(int client, Perk perk){
	SDKHook(client, SDKHook_OnTakeDamage, MercsDieTwice_OnTakeDamage);
	SetFloatCache(client, perk.GetPrefFloat("protection"));
	SetIntCache(client, false);
}

void MercsDieTwice_RemovePerk(int client){
	SDKUnhook(client, SDKHook_OnTakeDamage, MercsDieTwice_OnTakeDamage);
	KillEntCache(client);
	SetIntCache(client, false);
	if(GetIntCacheBool(client))
		SDKHooks_TakeDamage(client, 0, 0, view_as<float>(GetClientHealth(client)) +1.0);
}

void MercsDieTwice_Voice(int client){
	if(GetIntCacheBool(client))
		MercsDieTwice_Revive(client);
}

public Action MercsDieTwice_OnTakeDamage(int client, int& iAttacker, int& iInflictor, float& fDamage, int& iType){
	int iHealth = GetClientHealth(client);
	if(iHealth > fDamage)
		return Plugin_Continue;

	if(!GetIntCacheBool(client))
		MercsDieTwice_FakeDeath(client);
	return Plugin_Handled;
}

void MercsDieTwice_FakeDeath(int client){
	SetIntCache(client, true);
	float fVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);
	SetVectorCache(client, fVel);

	int iRag = CreateRagdoll(client);
	if(iRag){
		SetEntCache(client, iRag);
		SetClientViewEntity(client, iRag);
	}

	DisarmWeapons(client, true);
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");
}

void MercsDieTwice_Revive(int client){
	SetIntCache(client, false);

	float fVec[3];
	GetVectorCache(client, fVec);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVec);

	DisarmWeapons(client, false);
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");

	TF2_AddCondition(client, TFCond_UberchargedCanteen, GetFloatCache(client));
}
