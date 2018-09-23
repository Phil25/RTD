/**
* Team Criticals perk.
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

float	g_fTeamCritsRange	= 270.0;
bool	g_bTeamCritsFull	= true;

bool	g_bHasTeamCriticals[MAXPLAYERS+1] = {false, ...};
int		g_iCritBoostEnt[MAXPLAYERS+1][MAXPLAYERS+1];
int		g_iCritBoostsGetting[MAXPLAYERS+1] = {0, ...};

void TeamCriticals_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		TeamCriticals_ApplyPerk(client, sPref);
	
	else
		TeamCriticals_RemovePerk(client);

}

void TeamCriticals_ApplyPerk(int client, const char[] sPref){

	TeamCriticals_ProcessSettings(sPref);
	
	g_bHasTeamCriticals[client] = true;
	TF2_AddCondition(client, g_bTeamCritsFull ? FULLCRIT : MINICRIT);
	g_iCritBoostsGetting[client]++;
	
	CreateTimer(0.25, Timer_DrawBeamsFor, GetClientSerial(client), TIMER_REPEAT);

}

void TeamCriticals_RemovePerk(int client){

	g_bHasTeamCriticals[client] = false;
	TF2_RemoveCondition(client, g_bTeamCritsFull ? FULLCRIT : MINICRIT);
	g_iCritBoostsGetting[client]--;
	
	for(int i = 1; i <= MaxClients; i++){
	
		if(g_iCritBoostEnt[client][i] > MaxClients)
			TeamCriticals_SetCritBoost(client, i, false, 0);
	
	}

}

public Action Timer_DrawBeamsFor(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;
	
	if(!g_bHasTeamCriticals[client])
		return Plugin_Stop;
	
	TeamCriticals_DrawBeamsFor(client);
	
	return Plugin_Continue;

}

void TeamCriticals_DrawBeamsFor(int client){

	int iTeam = GetClientTeam(client);
	for(int i = 1; i <= MaxClients; i++){
	
		if(i == client)
			continue;
		
		if(!IsClientInGame(i)){
		
			if(g_iCritBoostEnt[client][i] > MaxClients)
				TeamCriticals_SetCritBoost(client, i, false, iTeam);
			
			continue;
		
		}
		
		if(!TeamCriticals_IsValidTarget(client, i, iTeam)){
		
			if(g_iCritBoostEnt[client][i] > MaxClients)
				TeamCriticals_SetCritBoost(client, i, false, iTeam);
		
			continue;
		
		}
		
		if(!CanEntitySeeTarget(client, i)){
		
			if(g_iCritBoostEnt[client][i] > MaxClients)
				TeamCriticals_SetCritBoost(client, i, false, iTeam);
			
			continue;
		
		}
		
		if(g_iCritBoostEnt[client][i] <= MaxClients)
			TeamCriticals_SetCritBoost(client, i, true, iTeam);
	
	}

}

bool TeamCriticals_IsValidTarget(int client, int iTrg, int iClientTeam){
	
	float fPos[3], fEndPos[3];
	GetClientAbsOrigin(client, fPos);
	GetClientAbsOrigin(iTrg, fEndPos);
	
	if(GetVectorDistance(fPos, fEndPos) > g_fTeamCritsRange)
		return false;
	
	if(TF2_IsPlayerInCondition(iTrg, TFCond_Cloaked))
		return false;
	
	int iEndTeam = GetClientTeam(iTrg);
	
	if(TF2_IsPlayerInCondition(iTrg, TFCond_Disguised)){
	
		if(iClientTeam == iEndTeam)
			return false;
		
		else
			return true;
	
	}
	
	return (iClientTeam == iEndTeam);

}

void TeamCriticals_SetCritBoost(int client, int iTrg, bool bSet, int iTeam){

	g_iCritBoostsGetting[iTrg] += bSet ? 1 : -1;

	if(bSet){
	
		g_iCritBoostEnt[client][iTrg] = ConnectWithBeam(client, iTrg, iTeam == 2 ? 255 : 64, 64, iTeam == 2 ? 64 : 255);
	
		if(g_iCritBoostsGetting[iTrg] < 2)
			TF2_AddCondition(iTrg, g_bTeamCritsFull ? FULLCRIT : MINICRIT);
	
	}else{
	
		if(IsValidEntity(g_iCritBoostEnt[client][iTrg]))
			AcceptEntityInput(g_iCritBoostEnt[client][iTrg], "Kill");
		
		g_iCritBoostEnt[client][iTrg] = 0;
	
		if(g_iCritBoostsGetting[iTrg] < 1)
			TF2_RemoveCondition(iTrg, g_bTeamCritsFull ? FULLCRIT : MINICRIT);
	
	}

}

void TeamCriticals_ProcessSettings(const char[] sSettings){
	
	char[][] sPieces = new char[2][8];
	ExplodeString(sSettings, ",", sPieces, 2, 8);

	g_fTeamCritsRange = StringToFloat(sPieces[0]);
	g_bTeamCritsFull = StringToInt(sPieces[1]) > 0 ? true : false;

}
