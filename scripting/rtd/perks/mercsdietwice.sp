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

#define SOUND_RESURRECT "mvm/mvm_revive.wav"

#define FAKE_DEATH 0
#define ALPHA 1
#define HEALTH 2

int g_iMercsDieTwiceId = 64;

void MercsDieTwice_Start(){
	PrecacheSound(SOUND_RESURRECT);
}

public void MercsDieTwice_Call(int client, Perk perk, bool bApply){
	if(bApply) MercsDieTwice_ApplyPerk(client, perk);
	else MercsDieTwice_RemovePerk(client);
}

void MercsDieTwice_ApplyPerk(int client, Perk perk){
	g_iMercsDieTwiceId = perk.Id;
	SetClientPerkCache(client, g_iMercsDieTwiceId);

	SetFloatCache(client, perk.GetPrefFloat("protection"));
	SetIntCache(client, false, FAKE_DEATH);
	SetIntCache(client, perk.GetPrefCell("health"), HEALTH);
}

void MercsDieTwice_RemovePerk(int client){
	UnsetClientPerkCache(client, g_iMercsDieTwiceId);

	if(GetIntCacheBool(client, FAKE_DEATH))
		MercsDieTwice_Resurrect(client);

	SetIntCache(client, false, FAKE_DEATH);
}

void MercsDieTwice_Voice(int client){
	if(CheckClientPerkCache(client, g_iMercsDieTwiceId))
		if(GetIntCacheBool(client, FAKE_DEATH))
			MercsDieTwice_Resurrect(client);
}

void MercsDieTwice_PlayerHurt(int client, Handle hEvent){
	if(!CheckClientPerkCache(client, g_iMercsDieTwiceId))
		return;

	if(!CanPlayerBeHurt(client))
		return;

	if(GetEventInt(hEvent, "health") < 1)
		MercsDieTwice_FakeDeath(client);
}

void MercsDieTwice_FakeDeath(int client){
	SetEntityHealth(client, 1);
	SetIntCache(client, true, FAKE_DEATH);

	float fVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);
	SetVectorCache(client, fVel);

	SetIntCache(client, GetEntityAlpha(client), ALPHA);
	SetClientAlpha(client, 0);

	int iRag = CreateRagdoll(client);
	if(iRag){
		SetEntCache(client, iRag);
		SetClientViewEntity(client, iRag);
	}

	DisarmWeapons(client, true);
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");
	TF2_AddCondition(client, TFCond_UberchargedCanteen);

	PrintCenterText(client, "%T", "RTD2_Perk_Resurrect", LANG_SERVER, 0x03, 0x01);
}

void MercsDieTwice_Resurrect(int client){
	SetIntCache(client, false, FAKE_DEATH);

	float fVec[3];
	GetVectorCache(client, fVec);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVec);
	SetClientAlpha(client, GetIntCache(client, ALPHA));

	DisarmWeapons(client, false);
	SetEntityMoveType(client, MOVETYPE_WALK);

	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");

	SetClientViewEntity(client, client);
	KillEntCache(client);

	TF2_RemoveCondition(client, TFCond_UberchargedCanteen);
	TF2_AddCondition(client, TFCond_UberchargedCanteen, GetFloatCache(client));
	EmitSoundToAll(SOUND_RESURRECT, client);

	float fMulti = float(GetIntCache(client, HEALTH)) /100.0;
	float fMaxHealth = float(GetEntProp(client, Prop_Data, "m_iMaxHealth"));
	SetEntityHealth(client, RoundFloat(fMaxHealth *fMulti));
}

#undef FAKE_DEATH
#undef ALPHA
#undef HEALTH
