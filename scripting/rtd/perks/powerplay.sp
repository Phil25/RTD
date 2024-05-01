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

#define SOUND_BUFF "ambient/chamber_open.wav"

#define STATUS_EFFECT_DURATION 4.0
#define TEMPORARY_DURATION 3.0
#define CRIT_MULTIPLIER 3.0
#define BOUNCE_COOLDOWN 2.0

#define MeleeFlags Int[0]
#define ColorRed Int[1]
#define ColorBlue Int[2]
#define BaseSpeed Int[3]
#define CurrentSpeed Float[0]
#define EnableLegacy Float[0] = -1.0
#define IsLegacy Float[0] < 0.0
#define SpeedRegainTime Float[1]
#define KnockbackResistance Float[2]
#define NextBounce Float[3]
#define Effect EntSlot_1
#define Glow EntSlot_2

enum PowerPlay_AttackType
{
	PowerPlay_AttackType_Unknown,
	PowerPlay_AttackType_Bullet,
	PowerPlay_AttackType_BulletCrit,
	PowerPlay_AttackType_Explosion,
	PowerPlay_AttackType_ExplosionCrit,
	PowerPlay_AttackType_Flame,
	PowerPlay_AttackType_FlameCrit,
	PowerPlay_AttackType_StatusEffect, // bleed / afterburn
	PowerPlay_AttackType_Melee,
	PowerPlay_AttackType_MeleeCrit, // incl. backstab
}

enum PowerPlay_MeleeFlags
{
	PowerPlay_MeleeFlags_None = 0,
	PowerPlay_MeleeFlags_Knife = 1 << 0,
	PowerPlay_MeleeFlags_SpyCicle = 1 << 1,
}

DEFINE_CALL_APPLY_REMOVE(PowerPlay)

public void PowerPlay_Init(const Perk perk)
{
	PrecacheSound(SOUND_BUFF);

	Events.OnAttackCritCheck(perk, PowerPlay_OnAttack);
	Events.OnPlayerAttacked(perk, PowerPlay_OnPlayerAttacked);
	Events.OnConditionAdded(perk, PowerPlay_OnConditionAdded);
}

public void PowerPlay_ApplyPerk(const int client, const Perk perk)
{
	if (perk.GetPrefCell("legacy", 0))
	{
		Cache[client].EnableLegacy;

		// yuck
		TF2_AddCondition(client, TFCond_UberchargedCanteen);
		TF2_AddCondition(client, TFCond_UberBulletResist);
		TF2_AddCondition(client, TFCond_UberBlastResist);
		TF2_AddCondition(client, TFCond_UberFireResist);
		TF2_AddCondition(client, TFCond_MegaHeal);
		TF2_SetPlayerPowerPlay(client, true);

		Shared[client].AddCritBoost(client, CritBoost_Full);

		return;
	}

	Cache[client].MeleeFlags = view_as<int>(PowerPlay_MeleeFlags_None);
	Cache[client].BaseSpeed = RoundFloat(GetBaseSpeed(client) * 1.3);
	Cache[client].CurrentSpeed = 1.0;
	Cache[client].KnockbackResistance = PowerPlay_GetKnockbackResistance(client);
	Cache[client].NextBounce = GetEngineTime();

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
	ForceSwitchSlot(client, 2);
	SDKHook(client, SDKHook_WeaponCanSwitchTo, PowerPlay_BlockWeaponSwitch);

	int iMelee = GetPlayerWeaponSlot(client, 2);
	if (iMelee > MaxClients && IsValidEntity(iMelee))
	{
		TF2Attrib_SetByDefIndex(iMelee, Attribs.MeleeRange, 1.1);

		char sClassname[32];
		GetEntityClassname(iMelee, sClassname, sizeof(sClassname));

		if (StrEqual(sClassname, "tf_weapon_knife"))
		{
			Cache[client].MeleeFlags |= view_as<int>(PowerPlay_MeleeFlags_Knife);

			if (GetEntProp(iMelee, Prop_Send, "m_iItemDefinitionIndex") == 649
			|| TF2Attrib_GetByDefIndex(iMelee, Attribs.MeltsInFire) != Address_Null)
				Cache[client].MeleeFlags |= view_as<int>(PowerPlay_MeleeFlags_SpyCicle);
		}
	}

	SDKHook(client, SDKHook_OnTakeDamage, PowerPlay_OnTakeDamage);
	Cache[client].Repeat(0.1, PowerPlay_SlowDownCheck);

	if (!(Cache[client].MeleeFlags & view_as<int>(PowerPlay_MeleeFlags_Knife)))
		Shared[client].AddCritBoost(client, CritBoost_Full);

	TF2_AddCondition(client, TFCond_SpeedBuffAlly);
	TF2Attrib_SetByDefIndex(client, Attribs.AirblastVulnerability, 0.2);
	ApplyPreventCapture(client);
	SetOverlay(client, ClientOverlay_Burning);

	int iEffect = CreateProxy(client);
	SendTEParticleLingeringAttachedProxy(TEParticlesLingering.BurningBody, iEffect);
	SendTEParticleLingeringAttachedProxy(TEParticlesLingering.RisingSparklesYellow, iEffect);
	Cache[client].SetEnt(Effect, iEffect);

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
	if (Cache[client].IsLegacy)
	{
		TF2_RemoveCondition(client, TFCond_UberchargedCanteen);
		TF2_RemoveCondition(client, TFCond_UberBulletResist);
		TF2_RemoveCondition(client, TFCond_UberBlastResist);
		TF2_RemoveCondition(client, TFCond_UberFireResist);
		TF2_RemoveCondition(client, TFCond_MegaHeal);
		TF2_SetPlayerPowerPlay(client, false);

		Shared[client].RemoveCritBoost(client, CritBoost_Full);

		return;
	}

	// PowerPlay has not been set yet
	if (!g_eInGodmode.Test(client))
		return;

	g_eInGodmode.Unset(client);

	SDKUnhook(client, SDKHook_WeaponCanSwitchTo, PowerPlay_BlockWeaponSwitch);
	SDKUnhook(client, SDKHook_PostThinkPost, PowerPlay_OnGlowUpdate);
	SDKUnhook(client, SDKHook_OnTakeDamage, PowerPlay_OnTakeDamage);

	ResetSpeed(client);

	if (!(Cache[client].MeleeFlags & view_as<int>(PowerPlay_MeleeFlags_Knife)))
		Shared[client].RemoveCritBoost(client, CritBoost_Full);

	TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);
	TF2Attrib_RemoveByDefIndex(client, Attribs.AirblastVulnerability);
	RemovePreventCapture(client);
	SetOverlay(client, ClientOverlay_None);

	int iMelee = GetPlayerWeaponSlot(client, 2);
	if (iMelee > MaxClients && IsValidEntity(iMelee))
		TF2Attrib_RemoveByDefIndex(iMelee, Attribs.MeleeRange);
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
	if (Cache[client].IsLegacy)
		return false;

	if (GetPlayerWeaponSlot(client, 2) != iWeapon)
		return false; // should never happen -- PowerPlay is melee only

	if (Shared[client].ClassForPerk != TFClass_Scout)
		TF2_AddCondition(client, TFCond_LostFooting, 1.0);

	UserMessages.Shake(client, 10.0, 3.0, 0.4);

	return false;
}

public void PowerPlay_OnPlayerAttacked(const int client, const int iVictim, const int iDamage, const int iRemainingHealth)
{
	if (Cache[client].IsLegacy)
		return;

	if (Cache[client].MeleeFlags & view_as<int>(PowerPlay_MeleeFlags_Knife) && (1 <= iVictim <= MaxClients))
		TF2_StunPlayer(iVictim, 1.0, _, TF_STUNFLAG_BONKSTUCK | TF_STUNFLAG_NOSOUNDOREFFECT | TF_STUNFLAG_THIRDPERSON, client);

	TF2_RemoveCondition(client, TFCond_LostFooting);
}

public void PowerPlay_OnConditionAdded(const int client, const TFCond eCond)
{
	if (Cache[client].IsLegacy)
		return;

	switch (eCond)
	{
		case TFCond_Jarated:
		{
			TF2_RemoveCondition(client, TFCond_Jarated);
			TF2_AddCondition(client, TFCond_Jarated, STATUS_EFFECT_DURATION);
			PowerPlay_Slowdown(client, 0.75, STATUS_EFFECT_DURATION);
		}

		case TFCond_Milked:
		{
			TF2_RemoveCondition(client, TFCond_Milked);
			TF2_AddCondition(client, TFCond_Milked, STATUS_EFFECT_DURATION);
			PowerPlay_Slowdown(client, 0.75, STATUS_EFFECT_DURATION);
		}
	}
}

public Action PowerPlay_BlockWeaponSwitch(const int client, const int iWeapon)
{
	return GetPlayerWeaponSlot(client, 2) == iWeapon ? Plugin_Continue : Plugin_Handled;
}

public Action PowerPlay_OnTakeDamage(int client, int& iAtk, int& iInflictor, float& fDamage, int& iType, int& iWeapon, float fForce[3], float fPos[3], int iCustomType)
{
	float fOriginalDamage = fDamage;
	fDamage *= 0.025;

	if (!(1 <= iAtk <= MaxClients) || !IsClientInGame(iAtk))
		return Plugin_Changed;

	iType |= DMG_PREVENT_PHYSICS_FORCE;

	float fKnockback[3];
	NormalizeVector(fForce, fKnockback);
	ScaleVector(fKnockback, fOriginalDamage * 5.0); // roughly regular knockback

	switch (PowerPlay_GetAttackType(iType))
	{
		case PowerPlay_AttackType_Bullet:
		{
			if (iInflictor > MaxClients && IsValidEntity(iInflictor))
			{
				char sClass[16];
				GetEntityClassname(iInflictor, sClass, sizeof(sClass));

				if (StrEqual(sClass, "obj_sentrygun"))
					ScaleVector(fKnockback, 0.0);
			}
			else
			{
				ScaleVector(fKnockback, 0.5);
			}
		}

		case PowerPlay_AttackType_BulletCrit:
		{
			fDamage *= 5.0;
			fOriginalDamage *= CRIT_MULTIPLIER;
		}

		case PowerPlay_AttackType_Explosion:
		{
			fKnockback[0] *= 0.25;
			fKnockback[1] *= 0.25;
			fKnockback[2] = 100.0 + 200.0 * PowerPlay_GetBounceMultiplier(client);
		}

		case PowerPlay_AttackType_ExplosionCrit:
		{
			fDamage *= 5.0;
			fOriginalDamage *= CRIT_MULTIPLIER;

			fKnockback[0] *= 0.75;
			fKnockback[1] *= 0.75;
			fKnockback[2] = 100.0 + 200.0 * PowerPlay_GetBounceMultiplier(client);
		}

		case PowerPlay_AttackType_Flame:
		{
			if (Cache[client].MeleeFlags & view_as<int>(PowerPlay_MeleeFlags_SpyCicle))
			{
				TF2_AddCondition(client, TFCond_FireImmune, 0.5);
				PowerPlay_Slowdown(client, 0.7, 0.5);
			}
			else
			{
				PowerPlay_Slowdown(client, 0.9, 0.5);
			}
		}

		case PowerPlay_AttackType_FlameCrit:
		{
			if (Cache[client].MeleeFlags & view_as<int>(PowerPlay_MeleeFlags_SpyCicle))
			{
				TF2_AddCondition(client, TFCond_FireImmune, 0.5);
				PowerPlay_Slowdown(client, 0.55, 0.5);
			}
			else
			{
				PowerPlay_Slowdown(client, 0.75, 0.5);
			}

			fDamage *= 5.0;
			fOriginalDamage *= CRIT_MULTIPLIER;
		}

		case PowerPlay_AttackType_StatusEffect:
		{
			fDamage = Max(fDamage, 1.0);
		}

		case PowerPlay_AttackType_Melee:
		{
			PowerPlay_EnableTemporary(iAtk, fPos);
		}

		case PowerPlay_AttackType_MeleeCrit:
		{
			PowerPlay_DisableTemporary(iAtk);

			if (iCustomType == TF_CUSTOM_BACKSTAB)
			{
				// 24 is roughly your average melee attack, hardcoding because backstabs will deal
				// less damage with less health the target has, and they become a bit too weak even
				// against PowerPlay. Dividing by 3 because crit calculation is not applied yet.
				fDamage = 24.0 / CRIT_MULTIPLIER;
			}
			else
			{
				// Becomes roughly 24 on your average melee attack.
				fDamage *= 5.0;
			}

			fOriginalDamage *= CRIT_MULTIPLIER;

			fKnockback[0] *= 5.0;
			fKnockback[1] *= 5.0;
			fKnockback[2] = 300.0;
		}
	}

	if (fOriginalDamage > 50.0)
		PowerPlay_Slowdown(client, 0.75, (fOriginalDamage - 50.0) / 30.0);

	ScaleVector(fKnockback, Cache[client].KnockbackResistance);

	float fClientVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fClientVelocity);
	AddVectors(fKnockback, fClientVelocity, fClientVelocity);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fClientVelocity);

	return Plugin_Changed;
}

void PowerPlay_EnableTemporary(const int client, const float fPos[3])
{
	if (!Shared[client].IsCritBoosted(client))
		TF2_AddCondition(client, TFCond_CritOnFirstBlood, TEMPORARY_DURATION);

	TF2_AddCondition(client, TFCond_SpeedBuffAlly, TEMPORARY_DURATION);

	SDKHook(client, SDKHook_WeaponSwitchPost, PowerPlay_WeaponSwitchWithTemporary);
	SDKHook(client, SDKHook_OnTakeDamage, PowerPlay_CritResistanceWithTemporary);

	Shared[client].TempPowerPlayTimePoint = GetEngineTime();
	CreateTimer(TEMPORARY_DURATION, Timer_PowerPlay_DisableTemporary, GetClientUserId(client));

	EmitSoundToAll(SOUND_BUFF, client, _, _, _, _, 120);
	SendTEParticle(TEParticles.ImpactStars, fPos);
}

void PowerPlay_DisableTemporary(const int client)
{
	if (!Shared[client].IsCritBoosted(client))
		TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);

	TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);

	SDKUnhook(client, SDKHook_WeaponSwitchPost, PowerPlay_WeaponSwitchWithTemporary);
	SDKUnhook(client, SDKHook_OnTakeDamage, PowerPlay_CritResistanceWithTemporary);
}

public Action Timer_PowerPlay_DisableTemporary(Handle hTimer, const int iUserId)
{
	int client = GetClientOfUserId(iUserId);
	if (client && GetEngineTime() >= Shared[client].TempPowerPlayTimePoint + TEMPORARY_DURATION - 0.3)
		PowerPlay_DisableTemporary(client);

	return Plugin_Stop;
}

public void PowerPlay_WeaponSwitchWithTemporary(const int client, const int iWeapon)
{
	PowerPlay_DisableTemporary(client);
}

public Action PowerPlay_CritResistanceWithTemporary(int client, int& iAtk, int& iInflictor, float& fDamage, int& iType)
{
	if (iType & DMG_CRIT)
	{
		fDamage *= 0.4;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

int PowerPlay_GetBounceMultiplier(const int client)
{
	if (Cache[client].NextBounce > GetEngineTime())
		return 0;

	Cache[client].NextBounce = GetEngineTime() + BOUNCE_COOLDOWN;
	return IsGrounded(client);
}

float PowerPlay_GetKnockbackResistance(const int client)
{
	// NOTE: Some effects apply flat 300.0 upward knockback causing a jump. A 10% resistance makes
	// it 270 which still results in a jump but barely. Anything above that will likely nullify it.

	// roughly based off class' base speed
	switch (Shared[client].ClassForPerk)
	{
		case TFClass_Scout: return 1.2;
		case TFClass_Soldier: return 0.8;
		case TFClass_DemoMan: return 0.9;
		case TFClass_Heavy: return 0.6;
	}

	return 1.0;
}

PowerPlay_AttackType PowerPlay_GetAttackType(const int iType)
{
	int iMutuallyExclusiveType = IsolateLastSetBit(iType, DMG_BULLET | DMG_BLAST | DMG_CLUB | DMG_PLASMA | DMG_SLASH | DMG_BURN);
	switch (iType & (DMG_CRIT | iMutuallyExclusiveType))
	{
		case DMG_BULLET: return PowerPlay_AttackType_Bullet;
		case DMG_BULLET | DMG_CRIT: return PowerPlay_AttackType_BulletCrit;
		case DMG_BLAST: return PowerPlay_AttackType_Explosion;
		case DMG_BLAST | DMG_CRIT: return PowerPlay_AttackType_ExplosionCrit;
		case DMG_CLUB: return PowerPlay_AttackType_Melee;
		case DMG_CLUB | DMG_CRIT: return PowerPlay_AttackType_MeleeCrit;
		case DMG_PLASMA: return PowerPlay_AttackType_Flame;
		case DMG_PLASMA | DMG_CRIT: return PowerPlay_AttackType_FlameCrit;
		case DMG_SLASH, DMG_SLASH | DMG_CRIT, DMG_BURN, DMG_BURN | DMG_CRIT:
			return PowerPlay_AttackType_StatusEffect;
	}

	return PowerPlay_AttackType_Unknown;
}

void PowerPlay_Slowdown(const int client, const float fValue, const float fDuration)
{
	if (fValue >= Cache[client].CurrentSpeed)
		return;

	Cache[client].CurrentSpeed = fValue;
	Cache[client].SpeedRegainTime = GetEngineTime() + Min(fDuration, 3.0);
	SetSpeed(client, float(Cache[client].BaseSpeed), fValue);
}

public Action PowerPlay_SlowDownCheck(const int client)
{
	if (Cache[client].CurrentSpeed == 1.0 || GetEngineTime() < Cache[client].SpeedRegainTime)
		return Plugin_Continue;

	SetSpeed(client, float(Cache[client].BaseSpeed));
	Cache[client].CurrentSpeed = 1.0;

	return Plugin_Continue;
}

#undef SOUND_BUFF

#undef STATUS_EFFECT_DURATION
#undef TEMPORARY_DURATION
#undef CRIT_MULTIPLIER
#undef BOUNCE_COOLDOWN

#undef MeleeFlags
#undef ColorRed
#undef ColorBlue
#undef BaseSpeed
#undef CurrentSpeed
#undef EnableLegacy
#undef IsLegacy
#undef SpeedRegainTime
#undef KnockbackResistance
#undef NextBounce
#undef Effect
#undef Glow
