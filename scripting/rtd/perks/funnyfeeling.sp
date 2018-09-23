/**
* Funny Feeling perk.
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


int		g_iBaseFunnyFov[MAXPLAYERS+1]		= {75, ...};
bool	g_bHasFunnyFeeling[MAXPLAYERS+1]	= {false, ...};
int		g_iDesiredFunnyFov = 160;

void FunnyFeeling_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		FunnyFeeling_ApplyPerk(client, StringToInt(sPref));
	
	else
		FunnyFeeling_RemovePerk(client);

}

void FunnyFeeling_ApplyPerk(int client, int iValue){

	g_iDesiredFunnyFov = iValue;

	g_iBaseFunnyFov[client] = GetEntProp(client, Prop_Send, "m_iFOV");
	SetEntProp(client, Prop_Send, "m_iFOV", g_iDesiredFunnyFov);
	
	g_bHasFunnyFeeling[client] = true;

}

void FunnyFeeling_RemovePerk(int client){

	SetEntProp(client, Prop_Send, "m_iFOV", g_iBaseFunnyFov[client]);
	
	g_bHasFunnyFeeling[client] = false;

}

void FunnyFeeling_OnConditionRemoved(int client, TFCond condition){

	if(!IsClientInGame(client))		return;
	if(!g_bHasFunnyFeeling[client])	return;
	if(condition != TFCond_Zoomed)	return;
	
	SetEntProp(client, Prop_Send, "m_iFOV", g_iDesiredFunnyFov);

}
