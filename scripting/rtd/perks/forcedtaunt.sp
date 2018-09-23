/**
* Forced Taunt perk.
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


bool	g_bIsForcedTaunt[MAXPLAYERS+1]	= {false, ...};
float	g_fTauntInterval				= 1.0;
bool	g_bShouldTaunt[MAXPLAYERS+1]	= {false, ...};
char	g_sSoundScoutBB[][] = {
	"items/scout_boombox_02.wav",
	"items/scout_boombox_03.wav",
	"items/scout_boombox_04.wav",
	"items/scout_boombox_05.wav"
};

void ForcedTaunt_Start(){

	for(int i = 0; i < sizeof(g_sSoundScoutBB); i++){
	
		PrecacheSound(g_sSoundScoutBB[i]);
	
	}

}

void ForcedTaunt_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		ForcedTaunt_ApplyPerk(client, StringToFloat(sPref));
	
	else
		g_bIsForcedTaunt[client] = false;

}

void ForcedTaunt_ApplyPerk(int client, float fInterval){

	g_fTauntInterval = fInterval;
	
	ForceTaunt_PerformTaunt(client);

	g_bIsForcedTaunt[client] = true;

}

public Action Timer_ForceTaunt(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;

	if(!g_bIsForcedTaunt[client])
		return Plugin_Stop;
	
	ForceTaunt_PerformTaunt(client);
	
	return Plugin_Stop;

}

void ForceTaunt_PerformTaunt(int client){

	if(GetEntProp(client, Prop_Send, "m_hGroundEntity") > -1){
		FakeClientCommand(client, "taunt");
		return;
	}
	
	g_bShouldTaunt[client] = true;
	CreateTimer(0.1, Timer_RetryForceTaunt, GetClientSerial(client), TIMER_REPEAT);

}

public Action Timer_RetryForceTaunt(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;

	if(!g_bIsForcedTaunt[client] || !g_bShouldTaunt[client])
		return Plugin_Stop;
	
	if(GetEntProp(client, Prop_Send, "m_hGroundEntity") < 0)
		return Plugin_Continue;
	
	g_bShouldTaunt[client] = false;
	FakeClientCommand(client, "taunt");
	
	return Plugin_Stop;

}

void ForcedTaunt_OnConditionAdded(int client, TFCond condition){

	if(g_bIsForcedTaunt[client] && condition == TFCond_Taunting)
		EmitSoundToAll(g_sSoundScoutBB[GetRandomInt(0, sizeof(g_sSoundScoutBB)-1)], client);

}

void ForcedTaunt_OnConditionRemoved(int client, TFCond condition){

	if(g_bIsForcedTaunt[client] && condition == TFCond_Taunting)
		CreateTimer(g_fTauntInterval, Timer_ForceTaunt, GetClientSerial(client));

}
