/**
* Toxic perk.
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


#define TOXIC_PARTICLE "eb_aura_angry01"

float	g_fToxicRange		= 128.0;
float	g_fToxicInterval	= 0.25;
float	g_fToxicDamage		= 24.0;

bool	g_bIsToxic[MAXPLAYERS+1]		= {false, ...};
int		g_iToxicParticle[MAXPLAYERS+1]	= {0, ...};

void Toxic_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		Toxic_ApplyPerk(client, sPref);
	
	else
		g_bIsToxic[client] = false;

}

void Toxic_ApplyPerk(int client, const char[] sSettings){

	Toxic_ProcessSettings(sSettings);

	g_bIsToxic[client]		 = true;
	g_iToxicParticle[client] = CreateParticle(client, TOXIC_PARTICLE);
	
	CreateTimer(g_fToxicInterval, Timer_Toxic, GetClientSerial(client), TIMER_REPEAT);

}

public Action Timer_Toxic(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;
	
	if(!g_bIsToxic[client]){
	
		if(g_iToxicParticle[client] > MaxClients && IsValidEntity(g_iToxicParticle[client])){
			AcceptEntityInput(g_iToxicParticle[client], "Kill");
			g_iToxicParticle[client] = 0;
		}
		
		return Plugin_Stop;
	
	}
	
	Toxic_HurtSurroundings(client);
	
	return Plugin_Continue;

}

void Toxic_HurtSurroundings(client){
	
	float fClientPos[3];
	GetClientAbsOrigin(client, fClientPos);
	
	for(int i = 1; i <= MaxClients; i++){
	
		if(!Toxic_IsValidTargetFor(client, i)) continue;
		
		float fTargetPos[3];
		GetClientAbsOrigin(i, fTargetPos);
		
		float fDistance = GetVectorDistance(fClientPos, fTargetPos);
		if(fDistance < g_fToxicRange)
			SDKHooks_TakeDamage(i, 0, client, g_fToxicDamage, DMG_BLAST);
	
	}

}

stock bool Toxic_IsValidTargetFor(int client, int target){

	if(client == target)
		return false;
	
	if(!IsClientInGame(target))
		return false;
		
	if(!IsPlayerAlive(target))
		return false;
	
	if(!CanEntitySeeTarget(client, target))
		return false;
	
	return CanPlayerBeHurt(target, client);

}

void Toxic_ProcessSettings(const char[] sSettings){
	
	char[][] sPieces = new char[3][8];
	ExplodeString(sSettings, ",", sPieces, 3, 8);

	g_fToxicRange		= StringToFloat(sPieces[0]);
	g_fToxicInterval	= StringToFloat(sPieces[1]);
	g_fToxicDamage		= StringToFloat(sPieces[2]);

}
