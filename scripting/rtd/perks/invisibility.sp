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

#define SOUND_PING "tools/ifm/beep.wav"

#define BASE_ALPHA 0
#define BASE_SENTRY 1
#define INVIS_VALUE 2
#define BLINK_ON_ATTACK 3

#define LAST_PLAYER_BUMP 0
#define BLINK_RATE 1

int g_iInvisibilityId = 7;

void Invisibility_Start(){
	PrecacheSound(SOUND_PING);
}

public void Invisibility_Call(int client, Perk perk, bool apply){
	if(apply) Invisibility_ApplyPerk(client, perk);
	else Invisibility_RemovePerk(client);
}

void Invisibility_ApplyPerk(int client, Perk perk){
	g_iInvisibilityId = perk.Id;
	SetClientPerkCache(client, g_iInvisibilityId);

	int iAlpha = perk.GetPrefCell("alpha");
	bool bOnFoe = perk.GetPrefCell("blink_on_foe", 1) > 0;
	bool bOnBump = perk.GetPrefCell("blink_on_bump", 0) > 0;

	SetIntCache(client, iAlpha, INVIS_VALUE);
	SetIntCache(client, GetEntityAlpha(client), BASE_ALPHA);
	SetIntCache(client, GetEntityFlags(client) & FL_NOTARGET, BASE_SENTRY);
	SetIntCache(client, perk.GetPrefCell("blink_on_fire", 1), BLINK_ON_ATTACK);

	SetFloatCache(client, 0.0, LAST_PLAYER_BUMP);
	SetFloatCache(client, perk.GetPrefFloat("blink_rate", 0.5), BLINK_RATE);

	Invisibility_Set(client, iAlpha);
	SetSentryTarget(client, false);
	ApplyPreventCapture(client);

	if(bOnFoe && !bOnBump)
		SDKHook(client, SDKHook_StartTouchPost, Invisibility_OnStartTouchPlayerOnly);

	else if(bOnBump)
		SDKHook(client, SDKHook_StartTouchPost, Invisibility_OnStartTouchAny);

	if(perk.GetPrefCell("blink_on_hurt", 1))
		SDKHook(client, SDKHook_OnTakeDamagePost, Invisibility_OnTakeDamage);
}

void Invisibility_RemovePerk(int client){
	UnsetClientPerkCache(client, g_iInvisibilityId);

	SDKUnhook(client, SDKHook_StartTouchPost, Invisibility_OnStartTouchPlayerOnly);
	SDKUnhook(client, SDKHook_StartTouchPost, Invisibility_OnStartTouchAny);
	SDKUnhook(client, SDKHook_OnTakeDamagePost, Invisibility_OnTakeDamage);

	Invisibility_Set(client, GetIntCache(client, BASE_ALPHA));
	SetSentryTarget(client, !GetIntCacheBool(client, BASE_SENTRY));
	RemovePreventCapture(client);
}

public void Invisibility_OnStartTouchPlayerOnly(int client, int iOther){
	char sClassname[24];
	GetEntityClassname(iOther, sClassname, sizeof(sClassname));

	// can only bump into enemy players
	if(StrEqual(sClassname, "player"))
		Invisibility_Blink(client);
}

public void Invisibility_OnStartTouchAny(int client, int iOther){
	Invisibility_Blink(client);
}

public void Invisibility_OnTakeDamage(int client, int iAttacker){
	Invisibility_Blink(client);
}

void Invisibility_OnAttack(int client){
	if(CheckClientPerkCache(client, g_iInvisibilityId) && GetIntCacheBool(client, BLINK_ON_ATTACK))
		Invisibility_Blink(client);
}

void Invisibility_Blink(int client){
	float fEngineTime = GetEngineTime();
	if(fEngineTime < GetFloatCache(client, LAST_PLAYER_BUMP) + GetFloatCache(client, BLINK_RATE))
		return;

	SetFloatCache(client, fEngineTime, LAST_PLAYER_BUMP);

	float fPos[3];
	GetClientAbsOrigin(client, fPos);

	fPos[2] += 26.0;

	switch(TF2_GetClientTeam(client)){
		case TFTeam_Red:{
			SendTEParticleWithPriorityTo(client, TEParticle_SmallPingWithEmbersRed, fPos);
			SendTEParticleAttached(TEParticle_PlayerStationarySilhouetteRed, client);
		}
		case TFTeam_Blue:{
			SendTEParticleWithPriorityTo(client, TEParticle_SmallPingWithEmbersBlue, fPos);
			SendTEParticleAttached(TEParticle_PlayerStationarySilhouetteBlue, client);
		}
	}

	EmitSoundToAll(SOUND_PING, client);
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

#undef SOUND_PING

#undef BASE_ALPHA
#undef BASE_SENTRY
#undef INVIS_VALUE
#undef BLINK_ON_ATTACK

#undef LAST_PLAYER_BUMP
#undef BLINK_RATE
