/**
* Homing Projectiles perk.
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


#define HOMING_SPEED 0.5
#define HOMING_REFLE 1.1

#define MINICRIT TFCond_Buffed
#define FULLCRIT TFCond_CritOnFirstBlood

int g_iHomingPlayerCount = 0;
int g_iHomingProjectilesId = 13;
ArrayList g_hHoming;

void HomingProjectiles_Start(){
	g_hHoming = new ArrayList(2);
	HookEvent("teamplay_round_start", Event_HomingProjectiles_RoundStart);
}

void HomingProjectiles_Perk(int client, Perk perk, bool apply){
	if(apply) HomingProjectiles_ApplyPerk(client, perk);
	else HomingProjectiles_RemovePerk(client);
}

void HomingProjectiles_ApplyPerk(int client, Perk perk){
	g_iHomingProjectilesId = perk.Id;
	SetClientPerkCache(client, g_iHomingProjectilesId);

	int iCrits = perk.GetPrefCell("crits");
	if(iCrits > 0)
		TF2_AddCondition(client, iCrits < 2 ? MINICRIT : FULLCRIT);

	SetIntCache(client, iCrits);
	++g_iHomingPlayerCount;
}

void HomingProjectiles_RemovePerk(int client){
	UnsetClientPerkCache(client, g_iHomingProjectilesId);

	int iCrits = GetIntCache(client);
	if(iCrits > 0)
		TF2_RemoveCondition(client, iCrits < 2 ? MINICRIT : FULLCRIT);

	--g_iHomingPlayerCount;
}

public Event_HomingProjectiles_RoundStart(Handle hEvent, const char[] strEventName, bool bDontBroadcast){
	g_hHoming.Clear();
}

//Just copy every bit of code from the original RTD!

void HomingProjectiles_OnEntityCreated(int iEnt, const char[] sClassname){
	if(g_iHomingPlayerCount > 0 && IsAcceptableForHoming(sClassname))
		CreateTimer(0.2, Timer_HomingProjectiles_CheckOwnership, EntIndexToEntRef(iEnt));
}

public Action Timer_HomingProjectiles_CheckOwnership(Handle hTimer, any iRef){
	int iProjectile = EntRefToEntIndex(iRef);
	if(iProjectile <= MaxClients || !IsValidEntity(iProjectile))
		return Plugin_Handled;

	int iLauncher = GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity");
	if(!IsValidClient(iLauncher) || !IsPlayerAlive(iLauncher))
		return Plugin_Handled;

	if(!CheckClientPerkCache(iLauncher, g_iHomingProjectilesId))
		return Plugin_Handled;

	if(GetEntProp(iProjectile, Prop_Send, "m_nForceBone") != 0)
		return Plugin_Handled;

	SetEntProp(iProjectile, Prop_Send, "m_nForceBone", 1);

	int iData[2];
	iData[0] = EntIndexToEntRef(iProjectile);
	g_hHoming.PushArray(iData);
	return Plugin_Handled;
}

void HomingProjectiles_OnGameFrame(){
	int iData[2], iProjectile,
		i = g_hHoming.Length;

	while(--i >= 0){
		g_hHoming.GetArray(i, iData);
		if(iData[0] == 0){
			g_hHoming.Erase(i);
			continue;
		}

		iProjectile = EntRefToEntIndex(iData[0]);
		if(iProjectile > MaxClients)
			HomingProjectile_Think(iProjectile, iData[0], i, iData[1]);
		else g_hHoming.Erase(i);
	}
}

void HomingProjectile_Think(int iProjectile, int iRefProjectile, int iArrayIndex, int iCurrentTarget){
	if(!HomingProjectile_IsValidTarget(iCurrentTarget, iProjectile))
		HomingProjectile_FindTarget(iProjectile, iRefProjectile, iArrayIndex);
	else HomingProjectile_TurnToTarget(iCurrentTarget, iProjectile);
}

bool HomingProjectile_IsValidTarget(int client, int iProjectile){
	if(!IsValidClient(client))			return false;
	if(!IsPlayerAlive(client))			return false;

	int iTeam = GetEntProp(iProjectile, Prop_Send, "m_iTeamNum");
	if(GetClientTeam(client) == iTeam)	return false;

	if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		return false;

	if(TF2_IsPlayerInCondition(client, TFCond_Disguised) && GetEntProp(client, Prop_Send, "m_nDisguiseTeam") == iTeam)
		return false;

	if(IsPlayerFriendly(client))
		return false;

	return CanEntitySeeTarget(iProjectile, client);
}

void HomingProjectile_FindTarget(int iProjectile, int iRefProjectile, int iArrayIndex){
	float fPos1[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", fPos1);

	int iBestTarget = 0;
	float fBestLength = 99999.9;
	fBestLength *= fBestLength;

	for(int i = 1; i <= MaxClients; ++i){
		if(!HomingProjectile_IsValidTarget(i, iProjectile))
			continue;

		float fPos2[3];
		GetClientEyePosition(i, fPos2);

		float fDistance = GetVectorDistance(fPos1, fPos2, true);
		if(fDistance > fBestLength)
			continue;

		iBestTarget = i;
		fBestLength = fDistance;
	}

	if(iBestTarget){
		int iData[2];
		iData[0] = iRefProjectile;
		iData[1] = iBestTarget;
		g_hHoming.SetArray(iArrayIndex, iData);

		HomingProjectile_TurnToTarget(iBestTarget, iProjectile);
	}else{
		int iData[2];
		iData[0] = iRefProjectile;
		iData[1] = 0;
		g_hHoming.SetArray(iArrayIndex, iData);
	}
}

void HomingProjectile_TurnToTarget(int client, int iProjectile){
	float fTargetPos[3], fRocketPos[3], fInitialVelocity[3];
	GetClientAbsOrigin(client, fTargetPos);
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", fRocketPos);
	GetEntPropVector(iProjectile, Prop_Send, "m_vInitialVelocity", fInitialVelocity);

	float fSpeedInit = GetVectorLength(fInitialVelocity);
	float fSpeedBase = fSpeedInit *HOMING_SPEED;

	fTargetPos[2] += 30 +Pow(GetVectorDistance(fTargetPos, fRocketPos), 2.0) /10000;

	float fNewVec[3], fAng[3];
	SubtractVectors(fTargetPos, fRocketPos, fNewVec);
	NormalizeVector(fNewVec, fNewVec);
	GetVectorAngles(fNewVec, fAng);

	float fSpeedNew = fSpeedBase +GetEntProp(iProjectile, Prop_Send, "m_iDeflected") *fSpeedBase *HOMING_REFLE;

	ScaleVector(fNewVec, fSpeedNew);
	TeleportEntity(iProjectile, NULL_VECTOR, fAng, fNewVec);
}

bool IsAcceptableForHoming(const char[] sClassname){
	if(strcmp(sClassname, "tf_projectile_rocket")		== 0
	|| strcmp(sClassname, "tf_projectile_arrow")		== 0
	|| strcmp(sClassname, "tf_projectile_flare")		== 0
	|| strcmp(sClassname, "tf_projectile_energy_ball")	== 0
	|| strcmp(sClassname, "tf_projectile_healing_bolt")	== 0)
		return true;

	return false;
}
