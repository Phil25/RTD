/**
* Suffocation perk.
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


bool	g_bIsSuffocating[MAXPLAYERS+1] = {false, ...};
float	g_fSuffocationStart		= 12.0;
float	g_fSuffocationInterval	= 1.0;
float	g_fSuffocationDamage	= 5.0;

void Suffocation_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		Suffocation_ApplyPerk(client, sPref);
	
	else
		g_bIsSuffocating[client] = false;

}

void Suffocation_ApplyPerk(client, const char[] sPref){

	Suffocation_ProcessSettings(sPref);
	
	g_bIsSuffocating[client] = true;
	
	CreateTimer(g_fSuffocationStart, Timer_Suffocation_Begin, GetClientSerial(client));

}

public Action Timer_Suffocation_Begin(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;
	
	if(!g_bIsSuffocating[client])
		return Plugin_Stop;

	SDKHooks_TakeDamage(client, 0, 0, g_fSuffocationDamage, DMG_DROWN);
	
	CreateTimer(g_fSuffocationInterval, Timer_Suffocation_Cont, GetClientSerial(client), TIMER_REPEAT);
	
	return Plugin_Stop;

}

public Action Timer_Suffocation_Cont(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;
	
	if(!g_bIsSuffocating[client])
		return Plugin_Stop;

	SDKHooks_TakeDamage(client, 0, 0, g_fSuffocationDamage, DMG_DROWN);
	
	return Plugin_Continue;

}

void Suffocation_ProcessSettings(const char[] sSettings){

	char[][] sPieces = new char[3][8];
	ExplodeString(sSettings, ",", sPieces, 3, 8);
	
	g_fSuffocationStart		= StringToFloat(sPieces[0]);
	g_fSuffocationInterval	= StringToFloat(sPieces[1]);
	g_fSuffocationDamage	= StringToFloat(sPieces[2]);

}
