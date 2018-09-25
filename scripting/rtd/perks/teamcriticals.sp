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

int g_iCritBoostsGetting[33] = {0, ...};
int g_iCritBoostEnt[33][33];
int g_iTeamCriticalsId = 47;

void TeamCriticals_Perk(int client, Perk perk, bool apply){
	if(apply) TeamCriticals_ApplyPerk(client, perk);
	else TeamCriticals_RemovePerk(client);
}

void TeamCriticals_ApplyPerk(int client, Perk perk){
	g_iTeamCriticalsId = perk.Id;
	SetClientPerkCache(client, g_iTeamCriticalsId);

	TFCond iCritType = perk.GetPrefCell("crits") ? FULLCRIT : MINICRIT;
	SetIntCache(client, view_as<int>(iCritType));
	SetFloatCache(client, perk.GetPrefFloat("range"));

	TF2_AddCondition(client, iCritType);
	++g_iCritBoostsGetting[client];

	CreateTimer(0.25, Timer_DrawBeamsFor, GetClientUserId(client), TIMER_REPEAT);
}

void TeamCriticals_RemovePerk(int client){
	UnsetClientPerkCache(client, g_iTeamCriticalsId);

	TF2_RemoveCondition(client, view_as<TFCond>(GetIntCache(client)));
	--g_iCritBoostsGetting[client];

	for(int i = 1; i <= MaxClients; i++)
		if(g_iCritBoostEnt[client][i] > MaxClients)
			TeamCriticals_SetCritBoost(client, i, false, 0);
}

public Action Timer_DrawBeamsFor(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iTeamCriticalsId))
		return Plugin_Stop;

	TeamCriticals_DrawBeamsFor(client);
	return Plugin_Continue;
}

void TeamCriticals_DrawBeamsFor(int client){
	int iTeam = GetClientTeam(client);
	float fRange = GetFloatCache(client);
	fRange *= fRange;

	for(int i = 1; i <= MaxClients; i++){
		if(i == client) continue;

		if(!IsClientInGame(i)){
			if(g_iCritBoostEnt[client][i] > MaxClients)
				TeamCriticals_SetCritBoost(client, i, false, iTeam);
			continue;
		}

		if(!TeamCriticals_IsValidTarget(client, i, iTeam, fRange)){
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

bool TeamCriticals_IsValidTarget(int client, int iTrg, int iClientTeam, float fRange){
	float fPos[3], fEndPos[3];
	GetClientAbsOrigin(client, fPos);
	GetClientAbsOrigin(iTrg, fEndPos);

	if(GetVectorDistance(fPos, fEndPos, true) > fRange)
		return false;

	if(TF2_IsPlayerInCondition(iTrg, TFCond_Cloaked))
		return false;

	int iEndTeam = GetClientTeam(iTrg);
	if(TF2_IsPlayerInCondition(iTrg, TFCond_Disguised))
		return iClientTeam != iEndTeam;

	return iClientTeam == iEndTeam;
}

void TeamCriticals_SetCritBoost(int client, int iTrg, bool bSet, int iTeam){
	g_iCritBoostsGetting[iTrg] += bSet ? 1 : -1;
	if(bSet){
		int iRed = 255, iBlue = 64;
		if(iTeam == 3){
			iRed = 64;
			iBlue = 255;
		}
		g_iCritBoostEnt[client][iTrg] = ConnectWithBeam(client, iTrg, iRed, 64, iBlue);

		if(g_iCritBoostsGetting[iTrg] < 2)
			TF2_AddCondition(iTrg, view_as<TFCond>(GetIntCache(client)));
	}else{
		if(IsValidEntity(g_iCritBoostEnt[client][iTrg]))
			AcceptEntityInput(g_iCritBoostEnt[client][iTrg], "Kill");

		g_iCritBoostEnt[client][iTrg] = 0;
		if(g_iCritBoostsGetting[iTrg] < 1)
			TF2_RemoveCondition(iTrg, view_as<TFCond>(GetIntCache(client)));
	}
}
