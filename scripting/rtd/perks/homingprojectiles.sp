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


#define MINICRIT TFCond_Buffed
#define FULLCRIT TFCond_CritOnFirstBlood

int g_iHomingPlayerCount = 0;
int g_iHomingProjectilesId = 13;

public void HomingProjectiles_Call(int client, Perk perk, bool apply){
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

void HomingProjectiles_OnEntityCreated(int iEnt, const char[] sClassname){
	if(g_iHomingPlayerCount && Homing_AptClass(sClassname))
		CreateTimer(0.2, Timer_HomingProjectiles_CheckOwnership, EntIndexToEntRef(iEnt));
}

public Action Timer_HomingProjectiles_CheckOwnership(Handle hTimer, any iRef){
	int iProjectile = EntRefToEntIndex(iRef);
	if(iProjectile <= MaxClients || !IsValidEntity(iProjectile))
		return Plugin_Stop;

	int iLauncher = GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity");
	if(!IsValidClient(iLauncher) || !IsPlayerAlive(iLauncher))
		return Plugin_Stop;

	if(!CheckClientPerkCache(iLauncher, g_iHomingProjectilesId))
		return Plugin_Stop;

	if(GetEntProp(iProjectile, Prop_Send, "m_nForceBone") != 0)
		return Plugin_Stop;

	SetEntProp(iProjectile, Prop_Send, "m_nForceBone", 1);
	Homing_Push(iProjectile);
	return Plugin_Stop;
}
