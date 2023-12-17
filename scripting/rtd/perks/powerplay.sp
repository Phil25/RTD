/**
* PowerPlay perk.
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

#define InEffect Int[0]
#define ColorRed Int[1]
#define ColorBlue Int[2]
#define BaseSpeed Float[0]
#define SpeedRegainTime Float[1]
#define Effect EntSlot_1
#define Glow EntSlot_2

DEFINE_CALL_APPLY_REMOVE(PowerPlay)

public void PowerPlay_Init(const Perk perk)
{
	Events.OnAttackCritCheck(perk, PowerPlay_OnAttack);
}

public void PowerPlay_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].BaseSpeed = GetBaseSpeed(client);
	Cache[client].InEffect = false;

	if (TF2_IsPlayerInCondition(client, TFCond_Slowed))
	{
		// Minigun revved up sound lingers and is annoying. Coincidentally this also covers Sniper
		// Rifle zoom, which can be removed manually without waiting, but whatever.
		Cache[client].Repeat(0.1, PowerPlay_ApplyCheck);
	}
	else
	{
		PowerPlay_Apply(client);
	}
}

Action PowerPlay_ApplyCheck(const int client)
{
	if (TF2_IsPlayerInCondition(client, TFCond_Slowed))
		return Plugin_Continue;

	PowerPlay_Apply(client);
	return Plugin_Stop;
}

void PowerPlay_Apply(const int client)
{
	Cache[client].InEffect = true;
	SDKHook(client, SDKHook_WeaponCanSwitchTo, PowerPlay_BlockWeaponSwitch);

	ForceSwitchSlot(client, 2);

	switch (Shared[client].ClassForPerk)
	{
		case TFClass_Scout:
		{
			SDKHook(client, SDKHook_OnTakeDamage, PowerPlay_ResistanceAndSlowdown);
			TF2Attrib_SetByDefIndex(client, Attribs.JumpHeight, 1.25);
			Cache[client].Repeat(0.1, PowerPlay_SlowDownCheck);
		}

		case TFClass_Heavy:
		{
			SDKHook(client, SDKHook_OnTakeDamage, PowerPlay_Resistance);
		}

		default:
		{
			SDKHook(client, SDKHook_OnTakeDamage, PowerPlay_Resistance);
			TF2Attrib_SetByDefIndex(client, Attribs.ForceDamageTaken, 40.0);
		}
	}

	TF2_AddCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_UberBulletResist);
	TF2_AddCondition(client, TFCond_UberBlastResist);
	TF2_AddCondition(client, TFCond_UberFireResist);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly);

	TF2Attrib_SetByDefIndex(client, Attribs.AirblastVulnerability, 0.2);

	int iMelee = GetPlayerWeaponSlot(client, 2);
	if (iMelee > MaxClients && IsValidEntity(iMelee))
		TF2Attrib_SetByDefIndex(iMelee, Attribs.MeleeRange, 1.1);

	ApplyPreventCapture(client);

	int iEffect = CreateProxy(client);
	SendTEParticleLingeringAttachedProxy(TEParticlesLingering.BurningBody, iEffect);
	SendTEParticleLingeringAttachedProxy(TEParticlesLingering.RisingSparklesYellow, iEffect);
	Cache[client].SetEnt(Effect, iEffect);

	SetOverlay(client, ClientOverlay_Burning);

	switch (TF2_GetClientTeam(client))
	{
		case TFTeam_Red:
		{
			SendTEParticleLingeringAttachedProxyExcept(TEParticlesLingering.GlowRed, iEffect, client);

			Cache[client].ColorRed = 255;
			Cache[client].ColorBlue = 150;
		}

		case TFTeam_Blue:
		{
			SendTEParticleLingeringAttachedProxyExcept(TEParticlesLingering.GlowBlue, iEffect, client);

			Cache[client].ColorRed = 150;
			Cache[client].ColorBlue = 255;
		}
	}

	int iGlow = AttachGlow(client);
	if (iGlow <= MaxClients)
		return;

	Cache[client].SetEnt(Glow, iGlow);
	SDKHook(client, SDKHook_PostThinkPost, PowerPlay_OnGlowUpdate);

	g_eInGodmode.Set(client);
}

void PowerPlay_RemovePerk(const int client)
{
	if (!Cache[client].InEffect)
		return;

	g_eInGodmode.Unset(client);

	SDKUnhook(client, SDKHook_WeaponCanSwitchTo, PowerPlay_BlockWeaponSwitch);
	SDKUnhook(client, SDKHook_PostThinkPost, PowerPlay_OnGlowUpdate);

	ResetSpeed(client);

	switch (Shared[client].ClassForPerk)
	{
		case TFClass_Scout:
		{
			SDKUnhook(client, SDKHook_OnTakeDamage, PowerPlay_ResistanceAndSlowdown);
			TF2Attrib_RemoveByDefIndex(client, Attribs.JumpHeight);
		}

		case TFClass_Heavy:
		{
			SDKUnhook(client, SDKHook_OnTakeDamage, PowerPlay_Resistance);
		}

		default:
		{
			SDKUnhook(client, SDKHook_OnTakeDamage, PowerPlay_Resistance);
			TF2Attrib_RemoveByDefIndex(client, Attribs.ForceDamageTaken);
		}
	}

	int iMelee = GetPlayerWeaponSlot(client, 2);
	if (iMelee > MaxClients && IsValidEntity(iMelee))
		TF2Attrib_RemoveByDefIndex(iMelee, Attribs.MeleeRange);

	RemovePreventCapture(client);

	SetOverlay(client, ClientOverlay_None);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_RemoveCondition(client, TFCond_UberBulletResist);
	TF2_RemoveCondition(client, TFCond_UberBlastResist);
	TF2_RemoveCondition(client, TFCond_UberFireResist);
	TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);

	TF2Attrib_RemoveByDefIndex(client, Attribs.AirblastVulnerability);
}

public void PowerPlay_OnGlowUpdate(const int client)
{
	int iGlow = Cache[client].GetEnt(Glow).Index;
	if (iGlow <= MaxClients)
		return;

	int iColor[4];
	iColor[0] = Cache[client].ColorRed;
	iColor[1] = 150;
	iColor[2] = Cache[client].ColorBlue;
	iColor[3] = RoundToNearest(Cosine(GetGameTime() * 12.0) * 60.0 + 195.0);

	SetVariantColor(iColor);
	AcceptEntityInput(iGlow, "SetGlowColor");
}

bool PowerPlay_OnAttack(const int client, const int iWeapon)
{
	if (GetPlayerWeaponSlot(client, 2) != iWeapon)
		return false; // should never happen -- PowerPlay is melee only

	TF2_AddCondition(client, TFCond_LostFooting, 1.0);
	UserMessages.Shake(client, 10.0, 3.0, 0.4);

	return false;
}

public Action PowerPlay_BlockWeaponSwitch(const int client, const int iWeapon)
{
	return Plugin_Handled;
}

public Action PowerPlay_Resistance(int client, int& iAtk, int& iInflictor, float& fDamage, int& iType)
{
	fDamage *= 0.025;

	if (iInflictor > MaxClients && IsValidEntity(iInflictor))
	{
		char sClass[32];
		GetEntityClassname(iInflictor, sClass, sizeof(sClass));

		if (StrEqual(sClass, "obj_sentrygun"))
			iType |= DMG_PREVENT_PHYSICS_FORCE;
	}

	return Plugin_Changed;
}

public Action PowerPlay_ResistanceAndSlowdown(int client, int& iAtk, int& iInflictor, float& fDamage, int& iType)
{
	float fOriginalDamage = fDamage;

	fDamage *= 0.025;
	iType |= DMG_PREVENT_PHYSICS_FORCE;

	if(fOriginalDamage < 8.0)
		return Plugin_Changed;

	Cache[client].SpeedRegainTime = GetEngineTime() + fOriginalDamage / 50.0;
	SetSpeed(client, Cache[client].BaseSpeed, 0.65);

	return Plugin_Changed;
}

public Action PowerPlay_SlowDownCheck(const int client)
{
	if (GetEngineTime() > Cache[client].SpeedRegainTime)
		SetSpeed(client, Cache[client].BaseSpeed);

	return Plugin_Continue;
}

#undef InEffect
#undef ColorRed
#undef ColorBlue
#undef BaseSpeed
#undef SpeedRegainTime
#undef Effect
#undef Glow
