/**
* Invisibility perk.
* Copyright (C) 2023 Filip Tomaszewski
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

#define BaseAlpha Int[0]
#define Alpha Int[1]
#define BlinkOnAttack Int[2]
#define LastBlink Float[0]
#define BlinkRate Float[1]

DEFINE_CALL_APPLY_REMOVE(Invisibility)

public void Invisibility_Init(const Perk perk)
{
	PrecacheSound(SOUND_PING);

	Events.OnAttackCritCheck(perk, Invisiblity_OnAttackCritCheck);
	Events.OnResupply(perk, Invisibility_OnResupply);
}

void Invisibility_ApplyPerk(const int client, const Perk perk)
{
	int iAlpha = perk.GetPrefCell("alpha", 0);
	bool bOnFoe = perk.GetPrefCell("blink_on_foe", 1) > 0;
	bool bOnBump = perk.GetPrefCell("blink_on_bump", 0) > 0;

	Cache[client].Alpha = iAlpha;
	Cache[client].BaseAlpha = GetEntityAlpha(client);
	Cache[client].BlinkOnAttack = perk.GetPrefCell("blink_on_fire", 1);
	Cache[client].LastBlink = 0.0;
	Cache[client].BlinkRate = perk.GetPrefFloat("blink_rate", 0.5);

	Invisibility_SetOverlay(client);
	Invisibility_Set(client, iAlpha);
	TF2_AddCondition(client, TFCond_DisguisedAsDispenser);
	ApplyPreventCapture(client);

	if (bOnFoe && !bOnBump)
	{
		SDKHook(client, SDKHook_StartTouchPost, Invisibility_OnStartTouchPlayerOnly);
	}
	else if (bOnBump)
	{
		SDKHook(client, SDKHook_StartTouchPost, Invisibility_OnStartTouchAny);
	}

	if (perk.GetPrefCell("blink_on_hurt", 1))
		SDKHook(client, SDKHook_OnTakeDamagePost, Invisibility_OnTakeDamage);
}

public void Invisibility_RemovePerk(const int client, const RTDRemoveReason eRemoveReason)
{
	SDKUnhook(client, SDKHook_StartTouchPost, Invisibility_OnStartTouchPlayerOnly);
	SDKUnhook(client, SDKHook_StartTouchPost, Invisibility_OnStartTouchAny);
	SDKUnhook(client, SDKHook_OnTakeDamagePost, Invisibility_OnTakeDamage);

	Invisibility_UnsetOverlay(client);
	Invisibility_Set(client, Cache[client].BaseAlpha);
	TF2_RemoveCondition(client, TFCond_DisguisedAsDispenser);
	RemovePreventCapture(client);
}

public void Invisibility_OnStartTouchPlayerOnly(int client, int iOther)
{
	char sClassname[24];
	GetEntityClassname(iOther, sClassname, sizeof(sClassname));

	// can bump into enemy players only
	if (StrEqual(sClassname, "player"))
		Invisibility_Blink(client);
}

public void Invisibility_OnStartTouchAny(int client, int iOther)
{
	Invisibility_Blink(client);
}

public void Invisibility_OnTakeDamage(int client, int iAttacker)
{
	Invisibility_Blink(client);
}

public bool Invisiblity_OnAttackCritCheck(const int client, const int iWeapon)
{
	if (Cache[client].BlinkOnAttack)
		Invisibility_Blink(client);

	return false;
}

void Invisibility_Blink(const int client)
{
	float fEngineTime = GetEngineTime();
	if (fEngineTime < Cache[client].LastBlink + Cache[client].BlinkRate)
		return;

	Cache[client].LastBlink = fEngineTime;

	float fPos[3];
	GetClientAbsOrigin(client, fPos);

	fPos[2] += 26.0;

	switch (TF2_GetClientTeam(client))
	{
		case TFTeam_Red:
		{
			SendTEParticleWithPriorityTo(client, TEParticles.SmallPingWithEmbersRed, fPos);
			SendTEParticleAttached(TEParticles.PlayerStationarySilhouetteRed, client);
		}

		case TFTeam_Blue:
		{
			SendTEParticleWithPriorityTo(client, TEParticles.SmallPingWithEmbersBlue, fPos);
			SendTEParticleAttached(TEParticles.PlayerStationarySilhouetteBlue, client);
		}
	}

	EmitSoundToAll(SOUND_PING, client);

	Invisibility_UnsetOverlay(client);
	Cache[client].Delay(Cache[client].BlinkRate / 2, Invisibility_SetOverlay);
}

void Invisibility_Set(const int client, const int iValue)
{
	if(GetEntityRenderMode(client) == RENDER_NORMAL)
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);

	SetEntityAlpha(client, iValue);

	for (int i = 0; i < 5; ++i)
	{
		int iWeapon = GetPlayerWeaponSlot(client, i);
		if (iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;

		if (GetEntityRenderMode(iWeapon) == RENDER_NORMAL)
			SetEntityRenderMode(iWeapon, RENDER_TRANSCOLOR);

		SetEntityAlpha(iWeapon, iValue);
	}

	char sClass[24];
	for (int i = MaxClients + 1; i < GetMaxEntities(); ++i)
	{
		if (!IsCorrectWearable(client, i, sClass, sizeof(sClass)))
			continue;

		if (GetEntityRenderMode(i) == RENDER_NORMAL)
			SetEntityRenderMode(i, RENDER_TRANSCOLOR);

		SetEntityAlpha(i, iValue);
	}
}

public void Invisibility_SetOverlay(const int client)
{
	SetOverlay(client, ClientOverlay_Stealth);
}

public void Invisibility_UnsetOverlay(const int client)
{
	SetOverlay(client, ClientOverlay_None);
}

public void Invisibility_OnResupply(const int client)
{
	Invisibility_Set(client, Cache[client].Alpha);
}

stock bool IsCorrectWearable(const int client, const int iEnt, char[] sClass, const int iBufferSize)
{
	if (!IsValidEntity(iEnt))
		return false;

	GetEdictClassname(iEnt, sClass, iBufferSize);
	if (StrContains(sClass, "tf_wearable", false) < 0 && StrContains(sClass, "tf_powerup", false) < 0)
		return false;

	if (GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity") != client)
		return false;

	return true;
}

#undef SOUND_PING

#undef BaseAlpha
#undef Alpha
#undef BlinkOnAttack
#undef LastBlink
#undef BlinkRate
