/**
* Custom stocks used throughout RTD and its perks.
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

/* TABLE OF CONTENTS
*
* GENERAL
* - EscapeString
* - AccountIDToClient
* - KillTimerSafe
* - IsValidClient
* - KillEntIn
*
* DAMAGE
* - DamageRadius
* - TakeDamage
*
* TRACE
* - CanBuildAtPos
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
*
* ENTITY CREATION
* - CreateParticle
* - CreateRagdoll
* - ConnectWithBeam
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
*/

#define LASERBEAM "sprites/laserbeam.vmt"

void Stocks_OnMapStart(){
	PrecacheModel(LASERBEAM);
}

/*
* GENERAL
*/

stock int EscapeString(const char[] input, int escape, int escaper, char[] output, int maxlen){
	/*
		Thanks Popoklopsi for EscapeString()
		https://forums.alliedmods.net/showthread.php?t=212230
	*/

	int escaped = 0;
	Format(output, maxlen, "");
	for(int offset = 0; offset < strlen(input); offset++){
		int ch = input[offset];
		if(ch == escape || ch == escaper){
			Format(output, maxlen, "%s%c%c", output, escaper, ch);
			escaped++;
		}else Format(output, maxlen, "%s%c", output, ch);
	}
	return escaped;
}

stock int AccountIDToClient(int iAccountID){
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			if(GetSteamAccountID(i) == iAccountID)
				return i;
	return 0;
}

stock void KillTimerSafe(Handle &hTimer){
	if(hTimer == INVALID_HANDLE)
		return;

	KillTimer(hTimer);
	hTimer = INVALID_HANDLE;
}

stock bool IsValidClient(int client){
	return (1 <= client <= MaxClients) && IsClientInGame(client);
}

stock void KillEntIn(int iEnt, float fTime){
	char sStr[32];
	Format(sStr, 32, "OnUser1 !self:Kill::%f:1", fTime);
	SetVariantString(sStr);
	AcceptEntityInput(iEnt, "AddOutput");
	AcceptEntityInput(iEnt, "FireUser1");
}


/*
* DAMAGE
*/

stock void DamageRadius(float fOrigin[3], int iInflictor=0, int iAttacker=0, float fRadius, float fDamage, int iFlags=0, float fSelfDamage=0.0, bool bCheckSight=true, Function call=INVALID_FUNCTION){
	fRadius *= fRadius;
	float fOtherPos[3];
	for(int i = 1; i <= MaxClients; ++i){
		if(!IsClientInGame(i))
			continue;

		GetClientAbsOrigin(i, fOtherPos);
		if(GetVectorDistance(fOrigin, fOtherPos, true) <= fRadius)
			if(CanPlayerBeHurt(i, iAttacker, fSelfDamage > 0.0))
				if(!bCheckSight || (bCheckSight && CanEntitySeeTarget(iAttacker, i)))
					TakeDamage(i, iInflictor, iAttacker, i == iAttacker ? fSelfDamage : fDamage, iFlags, call);
	}
}

stock void TakeDamage(int client, int iInflictor, int iAttacker, float fDamage, int iFlags, Function call){
	SDKHooks_TakeDamage(client, iInflictor, iAttacker, fDamage, iFlags);
	if(call == INVALID_FUNCTION) return;
	Call_StartFunction(INVALID_HANDLE, call);
	Call_PushCell(client);
	Call_PushCell(iAttacker);
	Call_PushFloat(fDamage);
	Call_Finish();
}


/*
* TRACE
*/

stock bool CanBuildAtPos(float fPos[3], bool bSentry){
	//TODO: Figure out a neat way of checking nobuild areas. I've spent 5h non stop trying to do it, help pls.
	float fMins[3], fMaxs[3];
	if(bSentry){
		fMins[0] = -20.0;
		fMins[1] = -20.0;
		fMins[2] = 0.0;

		fMaxs[0] = 20.0;
		fMaxs[1] = 20.0;
		fMaxs[2] = 66.0;
	}else{
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

stock bool IsEntityStuck(int iEntity){
	float fPos[3], fMins[3], fMaxs[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPos);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMins", fMins);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", fMaxs);

	TR_TraceHullFilter(fPos, fPos, fMins, fMaxs, MASK_SOLID, TraceFilterIgnoreSelf, iEntity);
	return TR_DidHit();
}

stock bool CanEntitySeeTarget(int iEnt, int iTarget){
	if(!iEnt) return false;

	float fStart[3], fEnd[3];
	if(IsValidClient(iEnt))
		GetClientEyePosition(iEnt, fStart);
	else GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fStart);

	if(IsValidClient(iTarget))
		GetClientEyePosition(iTarget, fEnd);
	else GetEntPropVector(iTarget, Prop_Send, "m_vecOrigin", fEnd);

	Handle hTrace = TR_TraceRayFilterEx(fStart, fEnd, MASK_SOLID, RayType_EndPoint, TraceFilterIgnorePlayersAndSelf, iEnt);
	if(hTrace != INVALID_HANDLE){
		if(TR_DidHit(hTrace)){
			CloseHandle(hTrace);
			return false;
		}
		CloseHandle(hTrace);
	}
	return true;
}

stock bool GetClientLookPosition(int client, float fPosition[3]){
	float fPos[3], fAng[3];
	GetClientEyePosition(client, fPos);
	GetClientEyeAngles(client, fAng);

	Handle hTrace = TR_TraceRayFilterEx(fPos, fAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, client);
	if(hTrace != INVALID_HANDLE && TR_DidHit(hTrace)){
		TR_GetEndPosition(fPosition, hTrace);
		return true;
	}
	return false;
}


/*
* TRACE FILTERS
*/

public bool TraceFilterIgnoreSelf(int iEntity, int iContentsMask, any iTarget){
	return iEntity != iTarget;
}

public bool TraceFilterIgnorePlayers(int iEntity, int iContentsMask, any data){
	return !(1 <= iEntity <= MaxClients);
}

public bool TraceFilterIgnorePlayersAndSelf(int iEntity, int iContentsMask, any iTarget){
	if(iEntity == iTarget)
		return false;

	if(1 <= iEntity <= MaxClients)
		return false;

	return true;
}


/*
* ALPHA
*/

stock int GetEntityAlpha(int iEnt){
	return GetEntData(iEnt, GetEntSendPropOffs(iEnt, "m_clrRender") + 3, 1);
}

stock void SetEntityAlpha(int iEnt, int iVal){
	SetEntityRenderMode(iEnt, RENDER_TRANSCOLOR);
	SetEntData(iEnt, GetEntSendPropOffs(iEnt, "m_clrRender") + 3, iVal, 1, true);
}

stock void SetClientAlpha(int client, int iVal){
	SetEntityAlpha(client, iVal);

	int iWeapon = 0;
	for(int i = 0; i < 5; i++){
		iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon > MaxClients && IsValidEntity(iWeapon))
			SetEntityAlpha(iWeapon, iVal);
	}

	for(int i = MaxClients+1; i < GetMaxEntities(); i++)
		if(IsWearable(i, client))
			SetEntityAlpha(i, iVal);
}


/*
* LOADOUT
*/

stock bool IsWearable(int iEnt, int iOwner){
	if(!IsValidEntity(iEnt))
		return false;

	char sClass[24];
	GetEntityClassname(iEnt, sClass, 24);
	if(strlen(sClass) < 7)
		return false;

	if(strncmp(sClass, "tf_", 3) != 0)
		return false;

	if(strncmp(sClass[3], "wear", 4) != 0
	&& strncmp(sClass[3], "powe", 4) != 0)
		return false;

	if(GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity") != iOwner)
		return false;

	return true;
}

stock void DisarmWeapons(int client, bool bDisarm){
	int iWeapon = 0;
	float fNextAttack = bDisarm ? GetGameTime() +86400.0 : 0.1;
	for(int i = 0; i < 3; i++){
		iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;

		SetEntPropFloat(iWeapon, Prop_Data, "m_flNextPrimaryAttack", fNextAttack);
		SetEntPropFloat(iWeapon, Prop_Data, "m_flNextSecondaryAttack", fNextAttack);
	}
}


/*
* ENTITY CREATION
*/

stock int CreateParticle(int iClient, char[] strParticle, bool bAttach=true, char[] strAttachmentPoint="", float fOffset[3]={0.0, 0.0, 36.0}){
	//Thanks J-Factor for CreateParticle()
	int iParticle = CreateEntityByName("info_particle_system");
	if(!IsValidEdict(iParticle)) return 0;

	float fPosition[3], fAngles[3], fForward[3], fRight[3], fUp[3];
	GetClientAbsOrigin(iClient, fPosition);
	GetClientAbsAngles(iClient, fAngles);

	GetAngleVectors(fAngles, fForward, fRight, fUp);
	fPosition[0] += fRight[0]*fOffset[0] + fForward[0]*fOffset[1] + fUp[0]*fOffset[2];
	fPosition[1] += fRight[1]*fOffset[0] + fForward[1]*fOffset[1] + fUp[1]*fOffset[2];
	fPosition[2] += fRight[2]*fOffset[0] + fForward[2]*fOffset[1] + fUp[2]*fOffset[2];

	TeleportEntity(iParticle, fPosition, fAngles, NULL_VECTOR);
	DispatchKeyValue(iParticle, "effect_name", strParticle);

	if(bAttach){
		SetVariantString("!activator");
		AcceptEntityInput(iParticle, "SetParent", iClient, iParticle, 0);

		if(!StrEqual(strAttachmentPoint, "")){
			SetVariantString(strAttachmentPoint);
			AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset", iParticle, iParticle, 0);
		}
	}

	DispatchSpawn(iParticle);
	ActivateEntity(iParticle);
	AcceptEntityInput(iParticle, "Start");

	return iParticle;
}

stock int CreateRagdoll(int client, bool bFrozen=false){
	int iRag = CreateEntityByName("tf_ragdoll");
	if(iRag <= MaxClients || !IsValidEntity(iRag))
		return 0;

	float fPos[3], fAng[3], fVel[3];
	GetClientAbsOrigin(client, fPos);
	GetClientAbsAngles(client, fAng);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);

	TeleportEntity(iRag, fPos, fAng, fVel);

	SetEntProp(iRag, Prop_Send, "m_iPlayerIndex", client);
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

	return iRag;
}

stock int ConnectWithBeam(int iEnt, int iEnt2, int iRed=255, int iGreen=255, int iBlue=255, float fStartWidth=1.0, float fEndWidth=1.0, float fAmp=1.35){
	int iBeam = CreateEntityByName("env_beam");
	if(iBeam <= MaxClients)
		return -1;

	if(!IsValidEntity(iBeam))
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


/*
* SPEED MANIPULATION
*/

stock float GetBaseSpeed(int client){
	float fBaseSpeed = 300.0;
	TFClassType class = TF2_GetPlayerClass(client);
	switch(class){
		case TFClass_Scout:		fBaseSpeed = 400.0;
		case TFClass_Soldier:	fBaseSpeed = 240.0;
		case TFClass_DemoMan:	fBaseSpeed = 280.0;
		case TFClass_Heavy:		fBaseSpeed = 230.0;
		case TFClass_Medic:		fBaseSpeed = 320.0;
		case TFClass_Spy:		fBaseSpeed = 320.0;
	}
	return fBaseSpeed;
}

stock void SetSpeed(int client, float fBase, float fMul=1.0){
	if(fMul == 1.0){ // reset to base
		TF2Attrib_RemoveByDefIndex(client, 107);
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", fBase);
	}else{
		TF2Attrib_SetByDefIndex(client, 107, fMul);
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", fBase *fMul);
	}
}


/*
* VIEW MANIPULATION
*/

stock void ViewPunch(int client, float fPunch[3]){
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fPunch);
}

stock void ViewPunchRand(int client, float fThreshold=25.0){
	float fPunch[3];
	fPunch[0] = GetRandomFloat(-fThreshold, fThreshold);
	fPunch[1] = GetRandomFloat(-fThreshold, fThreshold);
	fPunch[2] = GetRandomFloat(-fThreshold, fThreshold);
	ViewPunch(client, fPunch);
}

stock void RotateClientSmooth(int client, float fAngle){
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

stock bool IsFootstepSound(const char[] sSound){
	return !strncmp(sSound[7], "footstep", 8);
}
