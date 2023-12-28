/**
* Custom stocks used throughout RTD and its perks.
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

/* TABLE OF CONTENTS
*
* GENERAL
* - GetCallerName
* - EscapeString
* - AccountIDToClient
* - KillEntIn
* - GetOppositeTeam
* - GetLauncher
* - Parent
* - TeleportTo
*
* MATH
* - Min
* - MinInt
* - Max
* - MaxInt
* - ClampInt
* - GetPointOnSphere
* - GetRandomDeviationAddition
* - GetRandomSign
* - IsolateLastBit
*
* CLIENT
* - IsValidClient
* - IsGrounded
* - GetOppositeTeamOf
* - GetCaptureValue
* - ApplyPreventCapture
* - RemovePreventCapture
* - GetUniqueId
* - ForceResupplyCrude
* - SetOverlay
*
* DAMAGE
* - DamageRadius
* - TakeDamage
*
* TRACE
* - CanBuildAtPos
* - FindBuildPosition
* - IsEntityStuck
* - CanEntitySeeTarget
* - GetClientLookPosition
*
* TRACE FILTERS
* - TraceFilterIgnoreSelf
* - TraceFilterIgnorePlayers
* - TraceFilterIgnorePlayersAndSelf
*
* ALPHA
* - GetEntityAlpha
* - SetEntityAlpha
* - SetClientAlpha
*
* LOADOUT
* - IsWearable
* - DisarmWeapons
* - SwitchSlot
* - ForceSwitchSlot
* - SwitchToFirstValidWeapon
* - GetAmmo
* - SetAmmo
* - GetClip
* - SetClip
*
* ENTITY CREATION
* - CreateEffect
* - CreateParticle
* - CreateRagdoll
* - CreateExplosion
* - CreateTesla
* - CreateProxy
* - ConnectWithBeam
* - AttachRotating
* - AttachGlow
* - ShowAnnotationFor
* - HideAnnotationFor
*
* TEMPORARY ENTITIES
* - GetEffectIndex
* - _SetupTEParticle
* - SendTEParticle
* - SendTEParticleWithPriority
* - SendTEParticleWithPriorityTo
* - _SetupTEPartilceAttached
* - SendTEParticleAttached
* - SendTEParticleLingeringAttached
* - SendTEParticleLingeringAttachedProxy
* - SendTEParticleLingeringAttachedProxyOnly
* - SendTEParticleLingeringAttachedProxyExcept
*
* SPEED MANIPULATION
* - GetBaseSpeed
* - SetSpeed
*
* VIEW MANIPULATION
* - ViewPunch
* - ViewPunchRand
* - RotateClientSmooth
*
* SOUNDS
* - IsFootstepSound
* - IsVoicelineSound
*
* HOMING
* - Homing_Push
* - Homing_OnGameFrame
* - Homing_Think
* - Homing_IsValidTarget
* - Homing_FindTarget
* - Homing_TurnToTarget
* - Homing_AptClass
*/

#define LASERBEAM "sprites/laserbeam.vmt"
#define EMPTY_MODEL "models/empty.mdl"
#define MODEL_PROJECTILE "models/weapons/w_models/w_rocket.mdl"

// Homing target flags
#define HOMING_NONE 0
#define HOMING_SELF (1 << 0) // rocket's owner
#define HOMING_SELF_ORIG (1 << 1) // original launcher's owner
#define HOMING_ENEMIES (1 << 2) // enemies of owner
#define HOMING_FRIENDLIES (1 << 3) // friendlies of owner

#define HOMING_SPEED_MULTIPLIER 0.5
#define HOMING_AIRBLAST_MULTIPLIER 1.1

methodmap NotifyMessages
{
	public void Attack(const int client)
	{
		RTDPrint(client, "%t", "RTD2_Perk_Attack", 0x03, 0x01);
	}

	public void PlayerDamage(const int client, const int iDamage)
	{
		RTDPrint(client, "%t", "RTD2_Perk_Timebomb_Damage", 0x03, iDamage, 0x01);
	}

	public void PlayersIgnited(const int client, const int iAmount)
	{
		RTDPrint(client, "%t", "RTD2_Perk_Timebomb_Ignite", 0x03, iAmount, 0x01);
	}

	public void Dispenser(const int client)
	{
		RTDPrint(client, "%t", "RTD2_Perk_Dispenser_Initialization", 0x03, 0x01);
	}

	public void DispenserSpawned(const int client, const int iSpawned, const int iMax)
	{
		RTDPrint(client, "%t", "RTD2_Perk_Dispenser_Spawned", 0x03, iSpawned, iMax, 0x01);
	}

	public void Sentry(const int client)
	{
		RTDPrint(client, "%t", "RTD2_Perk_Sentry_Initialization", 0x03, 0x01);
	}

	public void SentrySpawned(const int client, const int iSpawned, const int iMax)
	{
		RTDPrint(client, "%t", "RTD2_Perk_Sentry_Spawned", 0x03, iSpawned, iMax, 0x01);
	}
}

/*
* g_hHoming ArrayList is multidimensional:
* - [0] -> Projectile index
* - [1] -> last target index
* - [2] -> homing target flags
*
*/
ArrayList g_hHoming = null;

int g_iWaterLevel[MAXPLAYERS +1] = {0, ...};
ClientFlags g_eMuteNextResupply;

NotifyMessages Notify;

void Stocks_OnMapStart()
{
	PrecacheModel(LASERBEAM);
	PrecacheModel(EMPTY_MODEL);
	PrecacheModel(MODEL_PROJECTILE);

	g_hHoming = new ArrayList(4);
	HookEvent("teamplay_round_start", Event_Homing_RoundStart);
}

bool Stocks_Sound(int client, const char[] sSound)
{
	if(g_eMuteNextResupply.Test(client) && StrEqual(sSound, "items/regenerate.wav"))
	{
		g_eMuteNextResupply.Unset(client);
		return false;
	}

	return true;
}

public Action Event_Homing_RoundStart(Handle hEvent, const char[] sName, bool bDontBroadcast)
{
	g_hHoming.Clear();
	return Plugin_Continue;
}

/*
* GENERAL
*/

stock void GetCallerName(char[] sBuffer, const int iBufferLenght, const int iOffset=1)
{
	FrameIterator eFrameIter = new FrameIterator();

	eFrameIter.Next(); // exit FrameIterator ctor
	eFrameIter.Next(); // exit GetCallerName

	// exit the function GetCallerName is called from, or any custom offset
	for (int i = 0; i < iOffset; ++i)
		eFrameIter.Next();

	eFrameIter.GetFunctionName(sBuffer, iBufferLenght);
	delete eFrameIter;
}

stock int EscapeString(const char[] input, int escape, int escaper, char[] output, int maxlen)
{
	/*
		Thanks Popoklopsi for EscapeString()
		https://forums.alliedmods.net/showthread.php?t=212230
	*/

	int escaped = 0;
	Format(output, maxlen, "");

	for (int offset = 0; offset < strlen(input); ++offset)
	{
		int ch = input[offset];
		if (ch == escape || ch == escaper)
		{
			Format(output, maxlen, "%s%c%c", output, escaper, ch);
			escaped++;
		}
		else
		{
			Format(output, maxlen, "%s%c", output, ch);
		}
	}

	return escaped;
}

stock int AccountIDToClient(int iAccountID)
{
	for (int i = 1; i <= MaxClients; ++i)
		if (IsClientInGame(i))
			if (GetSteamAccountID(i) == iAccountID)
				return i;

	return 0;
}

stock void KillEntIn(int iEnt, float fTime)
{
	char sStr[32];
	Format(sStr, 32, "OnUser1 !self:Kill::%f:1", fTime);
	SetVariantString(sStr);
	AcceptEntityInput(iEnt, "AddOutput");
	AcceptEntityInput(iEnt, "FireUser1");
}

stock int GetOppositeTeam(int iTeam)
{
	return iTeam == 2 ? 3 : 2;
}

stock int GetLauncher(int iProjectile)
{
	int iWeapon = GetEntPropEnt(iProjectile, Prop_Send, "m_hOriginalLauncher");
	if (iWeapon > MaxClients)
		return GetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity");

	return 0;
}

stock void Parent(int iEnt, int iTo)
{
	SetVariantString("!activator");
	AcceptEntityInput(iEnt, "SetParent", iTo, iEnt, 0);
}

stock void TeleportToClient(int iEnt, int client, float fOffset[3]={0.0, 0.0, 36.0})
{
	float fPosition[3], fAngles[3], fForward[3], fRight[3], fUp[3];
	GetClientAbsOrigin(client, fPosition);
	GetClientAbsAngles(client, fAngles);

	GetAngleVectors(fAngles, fForward, fRight, fUp);
	fPosition[0] += fRight[0]*fOffset[0] + fForward[0]*fOffset[1] + fUp[0]*fOffset[2];
	fPosition[1] += fRight[1]*fOffset[0] + fForward[1]*fOffset[1] + fUp[1]*fOffset[2];
	fPosition[2] += fRight[2]*fOffset[0] + fForward[2]*fOffset[1] + fUp[2]*fOffset[2];

	TeleportEntity(iEnt, fPosition, fAngles, NULL_VECTOR);
}


/*
* MATH
*/

stock float Min(const float f1, const float f2)
{
	return f1 < f2 ? f1 : f2;
}

stock int MinInt(const int i1, const int i2)
{
	return i1 < i2 ? i1 : i2;
}

stock float Max(const float f1, const float f2)
{
	return f1 > f2 ? f1 : f2;
}

stock int MaxInt(const int i1, const int i2)
{
	return i1 > i2 ? i1 : i2;
}

stock int ClampInt(const int i, const int iMin, const int iMax)
{
	return MaxInt(iMin, MinInt(iMax, i));
}

stock void GetPointOnSphere(const float fOrigin[3], const float fDirectionRads[2], float fRadius, float fOut[3])
{
	fOut[0] = fOrigin[0] + fRadius * Cosine(fDirectionRads[0]) * Sine(fDirectionRads[1]);
	fOut[1] = fOrigin[1] + fRadius * Sine(fDirectionRads[0]) * Sine(fDirectionRads[1]);
	fOut[2] = fOrigin[2] + fRadius * Cosine(fDirectionRads[1]);
}

// Returns a random value that can be added to fCurrent such that fCurrent will be in [-fMaxDeviation, fMaxDeviation]
stock float GetRandomDeviationAddition(const float fCurrent, float fMaxDeviation)
{
	return GetRandomFloat(-fMaxDeviation, fMaxDeviation) - fCurrent;
}

stock int GetRandomSign()
{
	static int iSign[2] = {-1, 1};
	return iSign[GetRandomInt(0, 1)];
}

stock int IsolateLastSetBit(int iValue, const int iMask)
{
	iValue &= iMask; // keep only bits which are specified in the mask
	return iValue & -iValue; // isolate lowest set bit
}


/*
* CLIENT
*/

stock bool IsValidClient(const int client)
{
	return (1 <= client <= MaxClients) && IsClientInGame(client);
}

stock bool IsGrounded(const int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") > -1;
}

stock int GetOppositeTeamOf(const int client)
{
	int iTeam = GetClientTeam(client);
	return GetOppositeTeam(iTeam);
}

stock float GetCaptureValue(const int client)
{
	// float instead of int so the return value can be used in a TF2Attrib call
	float fValue = 1.0;

	fValue += view_as<int>(TF2_GetPlayerClass(client) == TFClass_Scout);

	for (int iSlot = 0; iSlot < 5; iSlot++)
	{
		int iWeapon = GetPlayerWeaponSlot(client, iSlot);
		if (iWeapon > MaxClients && IsValidEntity(iWeapon))
			if (GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") == 154) // Pain Train
				fValue += 1.0;
	}

	// We could iterate weapons and use TF2Attrib_ListDefIndices on each of them instead of checking
	// for Pain Train directly, but native attributes cannot be read without parsing the itemschema,
	// which I don't think is worth for the ~1% of cases when it's needed.

	return fValue;
}

stock void ApplyPreventCapture(const int client)
{
	TF2Attrib_SetByDefIndex(client, 400, 1.0); // cannot pick up intel
	TF2Attrib_SetByDefIndex(client, 68, -GetCaptureValue(client)); // balance capture value to 0
	FakeClientCommandEx(client, "dropitem"); // in case intel is already picked up
}

stock void RemovePreventCapture(const int client)
{
	TF2Attrib_RemoveByDefIndex(client, 400);
	TF2Attrib_RemoveByDefIndex(client, 68);
}

stock int GetUniqueId(const int client, const int iOther)
{
	// iOther + MAXPLAYERS -- reversing args should yield different IDs
	// MAXPLAYERS * 2 -- add more than MAXPLAYERS in case iOther is negative
	// 91 -- bit of randomness to discern it from other plugins, on the off chance that algos are similar
	return client * (iOther + MAXPLAYERS * 2) * 91;
}

stock void ForceResupplyCrude(const int client, const float fPos[3])
{
	int iResupply = CreateEntityByName("func_regenerate");
	if (iResupply <= MaxClients)
		return;

	g_eMuteNextResupply.Set(client);
	KILL_ENT_IN(iResupply,0.1); // 0.0 (next frame) doesn't work sometimes

	SetEntPropEnt(iResupply, Prop_Send, "m_hOwnerEntity", client);
	SDKHook(iResupply, SDKHook_Touch, Stocks_ForceResupplyTouch);

	SetEntityModel(iResupply, EMPTY_MODEL); // set whatever model

	DispatchSpawn(iResupply);
	ActivateEntity(iResupply);

	TeleportEntity(iResupply, fPos, NULL_VECTOR, NULL_VECTOR);

	// 20 x 20 x 20 HU cube
	float fMinBounds[3] = {-10.0, -10.0, 0.0};
	float fMaxBounds[3] = {10.0, 10.0, 20.0};
	SetEntPropVector(iResupply, Prop_Send, "m_vecMins", fMinBounds);
	SetEntPropVector(iResupply, Prop_Send, "m_vecMaxs", fMaxBounds);

	SetEntProp(iResupply, Prop_Send, "m_nSolidType", 2); // must be 2

	int iEffects = GetEntProp(iResupply, Prop_Send, "m_fEffects");
	SetEntProp(iResupply, Prop_Send, "m_fEffects", iEffects | 32); // must have ef_nodraw flag
}

public Action Stocks_ForceResupplyTouch(int iResupply, int iOther)
{
	int iOwner = GetEntPropEnt(iResupply, Prop_Send, "m_hOwnerEntity");
	return iOther == iOwner ? Plugin_Continue : Plugin_Handled;
}

enum ClientOverlay
{
	ClientOverlay_None,
	ClientOverlay_Monochrome,
	ClientOverlay_InvulnerableRed,
	ClientOverlay_InvulnerableBlue,
	ClientOverlay_Stealth,
	ClientOverlay_Burning,
	ClientOverlay_Dodge,
	ClientOverlay_Beams,
}

stock void SetOverlay(const int client, const ClientOverlay eOverlay)
{
	switch (eOverlay)
	{
		case ClientOverlay_None:
			SetVariantString("");

		case ClientOverlay_Monochrome:
			SetVariantString("debug/yuv");

		case ClientOverlay_InvulnerableRed:
			SetVariantString("effects/invuln_overlay_red");

		case ClientOverlay_InvulnerableBlue:
			SetVariantString("effects/invuln_overlay_blue");

		case ClientOverlay_Stealth:
			SetVariantString("effects/stealth_overlay");

		case ClientOverlay_Burning:
			SetVariantString("effects/imcookin");

		case ClientOverlay_Dodge:
			SetVariantString("effects/dodge_overlay");

		case ClientOverlay_Beams:
			SetVariantString("effects/beam_neutral");
	}

	AcceptEntityInput(client, "SetScriptOverlayMaterial", client, client);
}


/*
* DAMAGE
*/

stock void DamageRadius(float fOrigin[3], int iInflictor=0, int iAttacker=0, float fRadius, float fDamage, int iFlags=0, float fSelfDamage=0.0, bool bCheckSight=true, Function call=INVALID_FUNCTION)
{
	fRadius *= fRadius;
	float fOtherPos[3];
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (!IsClientInGame(i))
			continue;

		GetClientAbsOrigin(i, fOtherPos);
		if (GetVectorDistance(fOrigin, fOtherPos, true) <= fRadius)
			if (CanPlayerBeHurt(i, iAttacker, fSelfDamage > 0.0))
				if (!bCheckSight || (bCheckSight && CanEntitySeeTarget(iAttacker, i)))
					TakeDamage(i, iInflictor, iAttacker, i == iAttacker ? fSelfDamage : fDamage, iFlags, call);
	}
}

stock void TakeDamage(int client, int iInflictor, int iAttacker, float fDamage, int iFlags, Function call)
{
	SDKHooks_TakeDamage(client, iInflictor, iAttacker, fDamage, iFlags);

	if (call == INVALID_FUNCTION)
		return;

	Call_StartFunction(INVALID_HANDLE, call);
	Call_PushCell(client);
	Call_PushCell(iAttacker);
	Call_PushFloat(fDamage);
	Call_Finish();
}


/*
* TRACE
*/

stock bool CanBuildAtPos(const float fPos[3], bool bSentry)
{
	//TODO: Figure out a neat way of checking nobuild areas. I've spent 5h non stop trying to do it, help pls.
	float fMins[3], fMaxs[3];

	if (bSentry)
	{
		fMins[0] = -20.0;
		fMins[1] = -20.0;
		fMins[2] = 0.0;

		fMaxs[0] = 20.0;
		fMaxs[1] = 20.0;
		fMaxs[2] = 66.0;
	}
	else
	{
		fMins[0] = -24.0;
		fMins[1] = -24.0;
		fMins[2] = 0.0;

		fMaxs[0] = 24.0;
		fMaxs[1] = 24.0;
		fMaxs[2] = 55.0;
	}

	TR_TraceHull(fPos, fPos, fMins, fMaxs, MASK_SOLID);
	return !TR_DidHit();
}

stock bool FindBuildPosition(float fPos[3], bool bSentry, int iBuildCheckLimit=10, const float fOffset=1.0)
{
	while (iBuildCheckLimit-- > 0)
	{
		if (CanBuildAtPos(fPos, bSentry))
			return true;

		fPos[2] += fOffset;
	}

	return false;
}

stock bool IsEntityStuck(int iEntity)
{
	float fPos[3], fMins[3], fMaxs[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPos);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMins", fMins);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", fMaxs);

	TR_TraceHullFilter(fPos, fPos, fMins, fMaxs, MASK_SOLID, TraceFilterIgnoreSelf, iEntity);
	return TR_DidHit();
}

stock bool CanEntitySeeTarget(int iEnt, int iTarget)
{
	if (!iEnt)
		return false;

	float fStart[3], fEnd[3];
	if(IsValidClient(iEnt))
	{
		GetClientEyePosition(iEnt, fStart);
	}
	else
	{
		GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fStart);
	}

	if (IsValidClient(iTarget))
	{
		GetClientEyePosition(iTarget, fEnd);
	}
	else
	{
		GetEntPropVector(iTarget, Prop_Send, "m_vecOrigin", fEnd);
	}

	Handle hTrace = TR_TraceRayFilterEx(fStart, fEnd, MASK_SOLID, RayType_EndPoint, TraceFilterIgnorePlayersAndSelf, iEnt);
	bool bResult = hTrace != INVALID_HANDLE && !TR_DidHit(hTrace);

	delete hTrace;
	return bResult;
}

stock bool GetClientLookPosition(int client, float fPosition[3])
{
	float fPos[3], fAng[3];
	GetClientEyePosition(client, fPos);
	GetClientEyeAngles(client, fAng);

	Handle hTrace = TR_TraceRayFilterEx(fPos, fAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, client);
	if (hTrace != INVALID_HANDLE && TR_DidHit(hTrace))
	{
		TR_GetEndPosition(fPosition, hTrace);
		delete hTrace;
		return true;
	}

	delete hTrace;
	return false;
}


/*
* TRACE FILTERS
*/

public bool TraceFilterIgnoreSelf(int iEntity, int iContentsMask, any iTarget)
{
	return iEntity != iTarget;
}

public bool TraceFilterIgnorePlayers(int iEntity, int iContentsMask, any data)
{
	return !(1 <= iEntity <= MaxClients);
}

public bool TraceFilterIgnorePlayersAndSelf(int iEntity, int iContentsMask, any iTarget)
{
	if (iEntity == iTarget)
		return false;

	if (1 <= iEntity <= MaxClients)
		return false;

	return true;
}


/*
* ALPHA
*/

stock int GetEntityAlpha(int iEnt)
{
	return GetEntData(iEnt, GetEntSendPropOffs(iEnt, "m_clrRender") + 3, 1);
}

stock void SetEntityAlpha(int iEnt, int iVal)
{
	SetEntityRenderMode(iEnt, RENDER_TRANSCOLOR);
	SetEntData(iEnt, GetEntSendPropOffs(iEnt, "m_clrRender") + 3, iVal, 1, true);
}

stock void SetClientAlpha(int client, int iVal)
{
	SetEntityAlpha(client, iVal);

	int iWeapon = 0;
	for (int i = 0; i < 5; ++i)
	{
		iWeapon = GetPlayerWeaponSlot(client, i);
		if (iWeapon > MaxClients && IsValidEntity(iWeapon))
			SetEntityAlpha(iWeapon, iVal);
	}

	for (int i = MaxClients + 1; i < GetMaxEntities(); ++i)
		if (IsWearable(i, client))
			SetEntityAlpha(i, iVal);
}


/*
* LOADOUT
*/

stock bool IsWearable(int iEnt, int iOwner)
{
	if (!IsValidEntity(iEnt))
		return false;

	char sClass[24];
	GetEntityClassname(iEnt, sClass, 24);

	if (strlen(sClass) < 7)
		return false;

	if (strncmp(sClass, "tf_", 3) != 0)
		return false;

	if (strncmp(sClass[3], "wear", 4) != 0 && strncmp(sClass[3], "powe", 4) != 0)
		return false;

	if (GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity") != iOwner)
		return false;

	return true;
}

stock void DisarmWeapons(int client, bool bDisarm)
{
	int iWeapon = 0;
	float fNextAttack = bDisarm ? GetGameTime() + 86400.0 : 0.1;

	for (int i = 0; i < 3; ++i)
	{
		iWeapon = GetPlayerWeaponSlot(client, i);
		if (iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;

		SetEntPropFloat(iWeapon, Prop_Data, "m_flNextPrimaryAttack", fNextAttack);
		SetEntPropFloat(iWeapon, Prop_Data, "m_flNextSecondaryAttack", fNextAttack);
	}
}

stock bool SwitchSlot(const int client, const int iSlot)
{
	int iLastWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (iLastWeapon == GetPlayerWeaponSlot(client, iSlot))
		return true;

	switch (iSlot)
	{
		case 0: ClientCommand(client, "slot1");
		case 1: ClientCommand(client, "slot2");
		case 2: ClientCommand(client, "slot3");
		case 3: ClientCommand(client, "slot4");
		case 4: ClientCommand(client, "slot5");
	}

	return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") != iLastWeapon;
}

stock bool ForceSwitchSlot(const int client, const int iSlot)
{
	int iWeapon = GetPlayerWeaponSlot(client, iSlot);
	if (iWeapon <= MaxClients || !IsValidEntity(iWeapon))
		return false;

	if (TF2_IsPlayerInCondition(client, TFCond_Zoomed))
	{
		// Switching away while zoomed in crashes clients
		TF2_RemoveCondition(client, TFCond_Zoomed);
	}

	if (TF2_IsPlayerInCondition(client, TFCond_Slowed))
	{
		// Unset weapon slowdown effect (minigun, sniper rifle)
		TF2_RemoveCondition(client, TFCond_Slowed);
		TF2_StunPlayer(client, 0.0, 0.0, TF_STUNFLAG_SLOWDOWN);
	}

	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iWeapon);
	return true;
}

stock void SwitchToFirstValidWeapon(const int client)
{
	if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") > MaxClients)
		return; // already holding an valid weapon

	for (int iSlot = 0; iSlot < 5; ++iSlot)
		if (ForceSwitchSlot(client, iSlot))
			break;
}

stock int GetAmmo(const int client, const int iWeapon)
{
	int iAmmoType = GetEntData(iWeapon, PropOffsets.CombatWeaponAmmoType, 1);
	if (iAmmoType == 4)
		return -1;

	return GetEntData(client, PropOffsets.PlayerAmmo + iAmmoType * 4);
}

stock void SetAmmo(const int client, const int iWeapon, const int iAmount)
{
	int iOffset = PropOffsets.PlayerAmmo + GetEntData(iWeapon, PropOffsets.CombatWeaponAmmoType, 1) * 4;
	SetEntData(client, iOffset, iAmount);
}

stock int GetClip(const int iWeapon)
{
	return GetEntData(iWeapon, PropOffsets.WeaponBaseClip);
}

stock void SetClip(const int iWeapon, const int iAmount)
{
	SetEntData(iWeapon, PropOffsets.WeaponBaseClip, iAmount, _, true);
}


/*
* ENTITY CREATION
*/

stock int CreateEffect(float fPos[3], const char[] sEffect, float fTime=1.0)
{
	int iEffect = CreateEntityByName("info_particle_system");
	if (!IsValidEdict(iEffect))
		return 0;

	TeleportEntity(iEffect, fPos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(iEffect, "effect_name", sEffect);

	DispatchSpawn(iEffect);
	ActivateEntity(iEffect);
	AcceptEntityInput(iEffect, "Start");

	KillEntIn(iEffect, fTime);
	return iEffect;
}

stock int CreateParticle(int iClient, char[] strParticle, bool bAttach=true, char[] strAttachmentPoint="", float fOffset[3]={0.0, 0.0, 36.0})
{
	//Thanks J-Factor for CreateParticle()
	int iParticle = CreateEntityByName("info_particle_system");
	if (!IsValidEdict(iParticle))
		return 0;

	TeleportToClient(iParticle, iClient, fOffset);
	DispatchKeyValue(iParticle, "effect_name", strParticle);

	if (bAttach)
	{
		Parent(iParticle, iClient);
		if(!StrEqual(strAttachmentPoint, ""))
		{
			SetVariantString(strAttachmentPoint);
			AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset", iParticle, iParticle, 0);
		}
	}

	DispatchSpawn(iParticle);
	ActivateEntity(iParticle);
	AcceptEntityInput(iParticle, "Start");

	return iParticle;
}

stock int CreateRagdoll(int client, bool bFrozen=false)
{
	int iRag = CreateEntityByName("tf_ragdoll");
	if (iRag <= MaxClients || !IsValidEntity(iRag))
		return 0;

	float fPos[3], fAng[3], fVel[3];
	GetClientAbsOrigin(client, fPos);
	GetClientAbsAngles(client, fAng);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);

	SetEntPropEnt(iRag, Prop_Send, "m_hPlayer", client);
	SetEntProp(iRag, Prop_Send, "m_bIceRagdoll", bFrozen);
	SetEntProp(iRag, Prop_Send, "m_iTeam", GetClientTeam(client));
	SetEntProp(iRag, Prop_Send, "m_iClass", view_as<int>(TF2_GetPlayerClass(client)));
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

	TeleportEntity(iRag, fPos, fAng, fVel);

	return iRag;
}

stock void CreateExplosion(float fPos[3], float fDamage=100.0, float fRadius=80.0, float fForce=100.0, int iOwner=0)
{
	int iExplosion = CreateEntityByName("env_explosion");
	if (!iExplosion)
		return;

	DispatchKeyValueFloat(iExplosion, "iMagnitude", fDamage);
	DispatchKeyValueFloat(iExplosion, "iRadiusOverride", fRadius);
	DispatchKeyValueFloat(iExplosion, "DamageForce", fForce);

	DispatchSpawn(iExplosion);
	ActivateEntity(iExplosion);

	SetEntPropEnt(iExplosion, Prop_Data, "m_hOwnerEntity", iOwner);

	TeleportEntity(iExplosion, fPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iExplosion, "Explode");
	AcceptEntityInput(iExplosion, "Kill");
}

stock int CreateTesla(float fPos[3])
{
	int iTesla = CreateEntityByName("point_tesla");
	if (iTesla <= MaxClients || !IsValidEntity(iTesla))
		return 0;

	TeleportEntity(iTesla, fPos, NULL_VECTOR, NULL_VECTOR);

	DispatchKeyValue(iTesla, "m_flRadius", "40.0");
	DispatchKeyValue(iTesla, "m_SoundName", "DoSpark");
	DispatchKeyValue(iTesla, "beamcount_min", "1");
	DispatchKeyValue(iTesla, "beamcount_max", "1");
	DispatchKeyValue(iTesla, "texture", "sprites/physbeam.vmt");
	DispatchKeyValue(iTesla, "m_Color", "255 128 0");
	DispatchKeyValue(iTesla, "thick_min", "2.0");
	DispatchKeyValue(iTesla, "thick_max", "8.0");
	DispatchKeyValue(iTesla, "lifetime_min", "0.1");
	DispatchKeyValue(iTesla, "lifetime_max", "0.4");
	DispatchKeyValue(iTesla, "interval_min", "0.01");
	DispatchKeyValue(iTesla, "interval_max", "0.03");

	ActivateEntity(iTesla);
	DispatchSpawn(iTesla);
	AcceptEntityInput(iTesla, "TurnOn");

	return iTesla;
}

/*
 * Based on nosoop's `TF2_AttachBasicGlow`
 * https://github.com/nosoop/stocksoup/blob/master/tf/entity_prefabs.inc
 */
stock int CreateProxy(int iEnt)
{
	char sModel[PLATFORM_MAX_PATH];
	GetEntPropString(iEnt, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

	if (strlen(sModel) == 0)
		return -1;

	int iProxy = CreateEntityByName("tf_taunt_prop");
	if (iProxy <= MaxClients)
		return -1;

	DispatchSpawn(iProxy);
	SetEntityModel(iProxy, sModel);

	SetEntPropEnt(iProxy, Prop_Data, "m_hEffectEntity", iEnt);

	// Add BONEMERGE, NOINTERP and NOSHADOW flags
	int iFlags = GetEntProp(iProxy, Prop_Send, "m_fEffects");
	SetEntProp(iProxy, Prop_Send, "m_fEffects", iFlags | 1 | 8 | 16);

	Parent(iProxy, iEnt);

	// Prevent entity not transmitting sometimes when far away, so attached tempents wouldn't break.
	// NOTE: Adding this flag must happen LAST when creating iProxy.
	SetEdictFlags(iProxy, GetEdictFlags(iProxy) | FL_EDICT_ALWAYS);

	return iProxy;
}

stock int ConnectWithBeam(int iEnt, int iEnt2, int iRed=255, int iGreen=255, int iBlue=255, float fStartWidth=1.0, float fEndWidth=1.0, float fAmp=1.35)
{
	int iBeam = CreateEntityByName("env_beam");
	if (iBeam <= MaxClients)
		return -1;

	if (!IsValidEntity(iBeam))
		return -1;

	SetEntityModel(iBeam, LASERBEAM);
	char sColor[16];
	Format(sColor, sizeof(sColor), "%d %d %d", iRed, iGreen, iBlue);

	DispatchKeyValue(iBeam, "rendercolor", sColor);
	DispatchKeyValue(iBeam, "life", "0");

	DispatchSpawn(iBeam);

	SetEntPropEnt(iBeam, Prop_Send, "m_hAttachEntity", EntIndexToEntRef(iEnt));
	SetEntPropEnt(iBeam, Prop_Send, "m_hAttachEntity", EntIndexToEntRef(iEnt2), 1);

	SetEntProp(iBeam, Prop_Send, "m_nNumBeamEnts", 2);
	SetEntProp(iBeam, Prop_Send, "m_nBeamType", 2);

	SetEntPropFloat(iBeam, Prop_Data, "m_fWidth", fStartWidth);
	SetEntPropFloat(iBeam, Prop_Data, "m_fEndWidth", fEndWidth);

	SetEntPropFloat(iBeam, Prop_Data, "m_fAmplitude", fAmp);

	SetVariantFloat(32.0);
	AcceptEntityInput(iBeam, "Amplitude");
	AcceptEntityInput(iBeam, "TurnOn");

	return iBeam;
}

stock int AttachRotating(int client, int iEnt, float fDist=128.0, float fSpeed=100.0)
{
	int iRot = CreateEntityByName("func_door_rotating");
	if (iRot <= MaxClients) return 0;

	float fPos[3];
	GetClientAbsOrigin(client, fPos);
	DispatchKeyValueVector(iRot, "origin", fPos);

	fPos[0] += fDist;
	DispatchKeyValueVector(iEnt, "origin", fPos);

	DispatchKeyValue(iRot, "distance", "99999");
	DispatchKeyValueFloat(iRot, "speed", fSpeed);
	DispatchKeyValue(iRot, "spawnflags", "4104"); // passable|silent
	DispatchSpawn(iRot);

	Parent(iEnt, iRot);
	Parent(iRot, client);
	AcceptEntityInput(iRot, "Open");

	return iRot;
}

stock int AttachGlow(const int iEntity)
{
	// Thanks Pelipoika for reference on attaching tf_glow entities
	// https://forums.alliedmods.net/showthread.php?t=287533

	int iEntLookup = -1;
	while ((iEntLookup = FindEntityByClassname(iEntLookup, "tf_glow")) != -1)
		if (GetEntPropEnt(iEntLookup, Prop_Send, "m_hTarget") == iEntity)
			return -1; // entities can only have 1 tf_glow object

	int iGlow = CreateEntityByName("tf_glow");
	if (iGlow <= MaxClients)
		return -1;

	char sOrigName[MAX_NAME_LENGTH], sTempName[32];
	GetEntPropString(iEntity, Prop_Data, "m_iName", sOrigName, sizeof(sOrigName));

	Format(sTempName, sizeof(sTempName), "rtd_tf_glow_%d", iEntity);
	DispatchKeyValue(iEntity, "targetname", sTempName);

	DispatchKeyValue(iGlow, "target", sTempName);
	AcceptEntityInput(iGlow, "Enable");
	DispatchSpawn(iGlow);

	// Set original name back
	SetEntPropString(iEntity, Prop_Data, "m_iName", sOrigName);

	return iGlow;
}

stock void ShowAnnotationFor(int client, int iOther, float fLifetime, char[] sText="", char[] sSound="")
{
	Event hEvent = CreateEvent("show_annotation");
	if (hEvent == null)
		return;

	hEvent.SetInt("follow_entindex", iOther);
	hEvent.SetInt("id", GetUniqueId(client, iOther));
	hEvent.SetFloat("lifetime", fLifetime);
	hEvent.SetString("text", sText);
	hEvent.SetString("play_sound", sSound);

	hEvent.FireToClient(client);
	hEvent.Cancel();
}

stock void HideAnnotationFor(int client, int iOther)
{
	Event hEvent = CreateEvent("hide_annotation");
	if (hEvent == null)
		return;

	hEvent.SetInt("id", GetUniqueId(client, iOther));

	hEvent.FireToClient(client);
	hEvent.Cancel();
}


/*
* TEMPORARY ENTITIES
*/

stock int GetEffectIndex(const char[] sEffectName)
{
	static int iTable = INVALID_STRING_TABLE;

	if (iTable == INVALID_STRING_TABLE)
		iTable = FindStringTable("ParticleEffectNames");

	return FindStringIndex(iTable, sEffectName);
}

void _SetupTEParticle(const TEParticleId eParticleId, const float fPos[3])
{
	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", fPos[0]);
	TE_WriteFloat("m_vecOrigin[1]", fPos[1]);
	TE_WriteFloat("m_vecOrigin[2]", fPos[2]);
	TE_WriteFloat("m_vecStart[0]", 0.0);
	TE_WriteFloat("m_vecStart[1]", 0.0);
	TE_WriteFloat("m_vecStart[2]", 0.0);
	TE_WriteNum("m_iAttachType", 2); // custom origin, do not follow
	TE_WriteNum("m_iParticleSystemIndex", view_as<int>(eParticleId));
}

stock void SendTEParticle(const TEParticleId eParticleId, const float fPos[3])
{
	_SetupTEParticle(eParticleId, fPos);
	TE_SendToAll();
}

stock void SendTEParticleWithPriority(const TEParticleId eParticleId, const float fPos[3])
{
	_SetupTEParticle(eParticleId, fPos);
	TE_SendToAll(-1.0); // negative values attempt to send the TE on the same tick
}

stock void SendTEParticleWithPriorityTo(const int client, const TEParticleId eParticleId, const float fPos[3])
{
	_SetupTEParticle(eParticleId, fPos);
	TE_SendToClient(client, -1.0);
}

void _SetupParticleAttached(const int iParticleId, const int iEnt, const int iAttachPoint, const bool bResetPrevious)
{
	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecStart[0]", 0.0);
	TE_WriteFloat("m_vecStart[1]", 0.0);
	TE_WriteFloat("m_vecStart[2]", 0.0);
	TE_WriteNum("m_iParticleSystemIndex", iParticleId);
	TE_WriteNum("m_bResetParticles", view_as<int>(bResetPrevious));
	TE_WriteNum("entindex", iEnt);
	TE_WriteNum("m_iAttachType", iAttachPoint > 0 ? 4 : 1); // follow point or just follow

	if (iAttachPoint > 0)
		TE_WriteNum("m_iAttachmentPointIndex", iAttachPoint);
}

stock void SendTEParticleAttached(const TEParticleId eParticleId, const int iEnt, const int iAttachPoint=0, const bool bResetPrevious=false)
{
	_SetupParticleAttached(view_as<int>(eParticleId), iEnt, iAttachPoint, bResetPrevious);
	TE_SendToAll(-1.0);
}

stock void SendTEParticleLingeringAttached(const TEParticleLingeringId eParticleId, const int iEnt, float fPos[3], const int iAttachPoint=0, const bool bResetPrevious=false)
{
	_SetupParticleAttached(view_as<int>(eParticleId), iEnt, iAttachPoint, bResetPrevious);
	TE_SendToAllInRange(fPos, RangeType_Visibility, -1.0);
}

stock void SendTEParticleLingeringAttachedProxy(const TEParticleLingeringId eParticleId, const int iProxy, const int iAttachPoint=0, const bool bResetPrevious=false)
{
	_SetupParticleAttached(view_as<int>(eParticleId), iProxy, iAttachPoint, bResetPrevious);
	TE_SendToAll(-1.0);
}

stock void SendTEParticleLingeringAttachedProxyOnly(const TEParticleLingeringId eParticleId, const int iProxy, const int client, const int iAttachPoint=0, const bool bResetPrevious=false)
{
	_SetupParticleAttached(view_as<int>(eParticleId), iProxy, iAttachPoint, bResetPrevious);
	TE_SendToClient(client, -1.0);
}

stock void SendTEParticleLingeringAttachedProxyExcept(const TEParticleLingeringId eParticleId, const int iProxy, const int client, const int iAttachPoint=0, const bool bResetPrevious=false)
{
	_SetupParticleAttached(view_as<int>(eParticleId), iProxy, iAttachPoint, bResetPrevious);

	int iTotal = 0, i = 0;
	int[] clients = new int[MaxClients];

	while (++i < client)
		if (IsClientInGame(i))
			clients[iTotal++] = i;

	while (++i <= MaxClients)
		if (IsClientInGame(i))
			clients[iTotal++] = i;

	TE_Send(clients, iTotal, -1.0);
}


/*
* SPEED MANIPULATION
*/

stock float GetBaseSpeed(const int client)
{
	switch (TF2_GetPlayerClass(client))
	{
		case TFClass_Scout:
			return 400.0;

		case TFClass_Soldier:
			return 240.0;

		case TFClass_DemoMan:
			return 280.0;

		case TFClass_Heavy:
			return 230.0;

		case TFClass_Medic:
			return 320.0;

		case TFClass_Spy:
			return 320.0;
	}

	return 300.0;
}

stock void ResetSpeed(const int client)
{
	SetSpeed(client, GetBaseSpeed(client));
}

stock void SetSpeed(int client, float fBase, float fMul=1.0)
{
	if (fMul == 1.0)
	{
		TF2Attrib_RemoveByDefIndex(client, 107);
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", fBase);
	}
	else
	{
		TF2Attrib_SetByDefIndex(client, 107, fMul);
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", fBase *fMul);
	}
}

// calcualtes m_flMaxspeed itself, tad overkill for small, frequent updates (like drunkwalk)
stock void SetSpeedEx(int client, float fMul=1.0)
{
	if (fMul == 1.0)
	{
		TF2Attrib_RemoveByDefIndex(client, 107);
	}
	else
	{
		TF2Attrib_SetByDefIndex(client, 107, fMul);
	}

	TriggerSpeedRecalc(client);
}

// forces water level update which triggers recalculation of m_flMaxspeed (#18)
stock void TriggerSpeedRecalc(int client)
{
	g_iWaterLevel[client] = GetEntProp(client, Prop_Data, "m_nWaterLevel");
	SetEntProp(client, Prop_Data, "m_nWaterLevel", g_iWaterLevel[client] > 0 ? 0 : 1);
	CreateTimer(0.1, TriggerSpeedRecalc_Frame, GetClientUserId(client));
}

public Action TriggerSpeedRecalc_Frame(Handle hTimer, int iUserId)
{
	int client = GetClientOfUserId(iUserId);
	if (client)
		SetEntProp(client, Prop_Data, "m_nWaterLevel", g_iWaterLevel[client]);

	return Plugin_Stop;
}


/*
* VIEW MANIPULATION
*/

stock void ViewPunch(int client, float fPunch[3])
{
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fPunch);
}

stock void ViewPunchRand(int client, float fThreshold=25.0)
{
	float fPunch[3];
	fPunch[0] = GetRandomFloat(-fThreshold, fThreshold);
	fPunch[1] = GetRandomFloat(-fThreshold, fThreshold);
	fPunch[2] = GetRandomFloat(-fThreshold, fThreshold);

	ViewPunch(client, fPunch);
}

stock void RotateClientSmooth(int client, float fAngle)
{
	float fPunch[3], fEyeAng[3];
	GetClientEyeAngles(client, fEyeAng);

	fPunch[1] += fAngle;
	fEyeAng[1] -= fAngle;

	TeleportEntity(client, NULL_VECTOR, fEyeAng, NULL_VECTOR);
	ViewPunch(client, fPunch);
}


/*
* SOUNDS
*/

stock bool IsFootstepSound(const char[] sSound)
{
	return !strncmp(sSound[7], "footstep", 8);
}

stock bool IsVoicelineSound(const char[] sSound)
{
	return strncmp(sSound[0], "vo/", 3) == 0;
}


/*
* HOMING
*/

stock void Homing_Push(int iProjectile, int iFlags=HOMING_ENEMIES, const int iSharpness=0)
{
	int iData[4];
	iData[0] = EntIndexToEntRef(iProjectile);
	iData[2] = iFlags;
	iData[3] = iSharpness;
	g_hHoming.PushArray(iData);
}

stock void Homing_OnGameFrame()
{
	int iData[4];
	int iProjectile, i = g_hHoming.Length;

	while (--i >= 0)
	{
		g_hHoming.GetArray(i, iData);
		if (iData[0] == 0)
		{
			g_hHoming.Erase(i);
			continue;
		}

		iProjectile = EntRefToEntIndex(iData[0]);

		if (iProjectile > MaxClients)
		{
			Homing_Think(iProjectile, iData[0], i, iData[1], iData[2], iData[3]);
		}
		else
		{
			g_hHoming.Erase(i);
		}
	}
}

stock void Homing_Think(int iProjectile, int iRefProjectile, int iArrayIndex, int iCurrentTarget, int iFlags, int iSharpness)
{
	if (!Homing_IsValidTarget(iCurrentTarget, iProjectile, iFlags))
	{
		Homing_FindTarget(iProjectile, iRefProjectile, iArrayIndex, iFlags, iSharpness);
	}
	else
	{
		Homing_TurnToClient(iCurrentTarget, iProjectile, iSharpness);
	}
}

stock bool Homing_IsValidTarget(int client, int iProjectile, int iFlags)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return false;

	int iTeam = GetEntProp(iProjectile, Prop_Send, "m_iTeamNum");
	int iOwner = (iFlags & HOMING_SELF_ORIG) ? GetLauncher(iProjectile) : GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity");

	if(iOwner == client)
	{
		if (!(iFlags & HOMING_SELF) && !(iFlags & HOMING_SELF_ORIG))
			return false;
	}
	else
	{
		if (GetClientTeam(client) == iTeam)
		{
			if (!(iFlags & HOMING_FRIENDLIES))
				return false;
		}
		else
		{
			if (!(iFlags & HOMING_ENEMIES))
				return false;
		}
	}

	if (TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		return false;

	if (TF2_IsPlayerInCondition(client, TFCond_Disguised) && GetEntProp(client, Prop_Send, "m_nDisguiseTeam") == iTeam)
		return false;

	if (IsPlayerFriendly(client))
		return false;

	return CanEntitySeeTarget(iProjectile, client);
}

stock void Homing_FindTarget(int iProjectile, int iRefProjectile, int iArrayIndex, int iFlags, int iSharpness)
{
	float fPos[3], fPosOther[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", fPos);

	int iBestTarget = 0;
	float fBestDist = 9999999999.0;

	for (int i = 1; i <= MaxClients; ++i)
	{
		if (!Homing_IsValidTarget(i, iProjectile, iFlags))
			continue;

		GetClientEyePosition(i, fPosOther);
		float fDistance = GetVectorDistance(fPos, fPosOther, true);
		if (fDistance > fBestDist)
			continue;

		iBestTarget = i;
		fBestDist = fDistance;
	}

	int iData[4];
	iData[0] = iRefProjectile;
	iData[1] = iBestTarget;
	iData[2] = iFlags;
	iData[3] = iSharpness;
	g_hHoming.SetArray(iArrayIndex, iData);

	if (iBestTarget)
		Homing_TurnToClient(iBestTarget, iProjectile, iSharpness);
}

stock void Homing_TurnToClient(int client, int iProjectile, int iSharpness)
{
	float fTargetPos[3];
	GetClientAbsOrigin(client, fTargetPos);
	Homing_TurnToTarget(fTargetPos, iProjectile, iSharpness);
}

stock void Homing_TurnToTarget(float fTargetPos[3], int iProjectile, int iSharpness)
{
	float fRocketPos[3], fInitialVelocity[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", fRocketPos);
	GetEntPropVector(iProjectile, Prop_Send, "m_vInitialVelocity", fInitialVelocity);

	float fSpeedInit = GetVectorLength(fInitialVelocity);
	float fSpeedBase = fSpeedInit * HOMING_SPEED_MULTIPLIER;

	fTargetPos[2] += 30 + Pow(GetVectorDistance(fTargetPos, fRocketPos), 2.0) / 10000;

	if (iSharpness > 0)
		Homing_SmoothTurn(fTargetPos, fRocketPos, iProjectile, iSharpness);

	float fNewVec[3], fAng[3];
	SubtractVectors(fTargetPos, fRocketPos, fNewVec);
	NormalizeVector(fNewVec, fNewVec);
	GetVectorAngles(fNewVec, fAng);

	float fSpeedNew = fSpeedBase + GetEntProp(iProjectile, Prop_Send, "m_iDeflected") * fSpeedBase * HOMING_AIRBLAST_MULTIPLIER;

	ScaleVector(fNewVec, fSpeedNew);
	TeleportEntity(iProjectile, NULL_VECTOR, fAng, fNewVec);
}

stock void Homing_SmoothTurn(float fTargetPos[3], float fRocketPos[3], int iProjectile, int iSharpness)
{
	float fDist = GetVectorDistance(fRocketPos, fTargetPos);

	float fAng[3], fFwd[3];
	GetEntPropVector(iProjectile, Prop_Data, "m_angRotation", fAng);
	GetAngleVectors(fAng, fFwd, NULL_VECTOR, NULL_VECTOR);

	float fNewTargetPos[3];
	float fSmoothFactor = 1.0 - float(iSharpness) / 100.0;

	for (int i = 0; i < 3; ++i)
	{
		fNewTargetPos[i] = fRocketPos[i] + fDist * fFwd[i];
		fTargetPos[i] += (fNewTargetPos[i] - fTargetPos[i]) * fSmoothFactor;
	}
}

stock bool Homing_AptClass(const char[] sClass)
{
	if (strncmp(sClass, "tf_projectile_", 14))
		return false;

	return !strcmp(sClass[14], "rocket")
		|| !strcmp(sClass[14], "arrow")
		|| !strcmp(sClass[14], "flare")
		|| !strcmp(sClass[14], "energy_ball")
		|| !strcmp(sClass[14], "healing_bolt");
}
