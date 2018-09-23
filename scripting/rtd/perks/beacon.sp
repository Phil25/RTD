/**
* Beacon perk.
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


#define SOUND_BEEP "buttons/blip1.wav"

bool	g_bIsBeaconed[MAXPLAYERS+1]		= {false, ...};
float	g_fBeaconInterval				= 1.0;
float	g_fBeaconRadius					= 375.0;
int		g_iSpriteBeam, g_iSpriteHalo;

void Beacon_Start(){

	PrecacheSound(SOUND_BEEP);
	g_iSpriteBeam		= PrecacheModel("materials/sprites/laser.vmt");
	g_iSpriteHalo		= PrecacheModel("materials/sprites/halo01.vmt");

}

void Beacon_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		Beacon_ApplyPerk(client, sPref);
	
	else
		g_bIsBeaconed[client] = false;

}

void Beacon_ApplyPerk(int client, const char[] sSettings){

	Beacon_ProcessSettings(sSettings);

	CreateTimer(g_fBeaconInterval, Timer_BeaconBeep, GetClientSerial(client), TIMER_REPEAT);
	g_bIsBeaconed[client] = true;

}

public Action Timer_BeaconBeep(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;

	if(!g_bIsBeaconed[client])
		return Plugin_Stop;
	
	Beacon_Beep(client);
	
	return Plugin_Continue;

}

void Beacon_Beep(int client){
	
	float fPos[3]; GetClientAbsOrigin(client, fPos);
	fPos[2] += 10.0;
	
	int iColorGra[4] = {128,128,128,255};
	int iColorRed[4] = {255,75,75,255};
	int iColorBlu[4] = {75,75,255,255};
	
	TE_SetupBeamRingPoint(fPos, 10.0, g_fBeaconRadius, g_iSpriteBeam, g_iSpriteHalo, 0, 15, 0.5, 5.0, 0.0, iColorGra, 10, 0);
	TE_SendToAll();
	
	if(GetClientTeam(client) == _:TFTeam_Red)
		TE_SetupBeamRingPoint(fPos, 10.0, g_fBeaconRadius, g_iSpriteBeam, g_iSpriteHalo, 0, 10, 0.6, 10.0, 0.5, iColorRed, 10, 0);
	else
		TE_SetupBeamRingPoint(fPos, 10.0, g_fBeaconRadius, g_iSpriteBeam, g_iSpriteHalo, 0, 10, 0.6, 10.0, 0.5, iColorBlu, 10, 0);
	
	TE_SendToAll();
	
	EmitSoundToAll(SOUND_BEEP, client);

}

void Beacon_ProcessSettings(const char[] sSettings){
	
	char[][] sPieces = new char[2][4];
	ExplodeString(sSettings, ",", sPieces, 2, 4);

	g_fBeaconInterval	= StringToFloat(sPieces[0]);
	g_fBeaconRadius		= StringToFloat(sPieces[1]);

}
