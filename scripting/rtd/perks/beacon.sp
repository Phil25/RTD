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

int g_iSpriteBeam, g_iSpriteHalo;
int g_iBeaconId = 24;

void Beacon_Start(){
	PrecacheSound(SOUND_BEEP);
	g_iSpriteBeam = PrecacheModel("materials/sprites/laser.vmt");
	g_iSpriteHalo = PrecacheModel("materials/sprites/halo01.vmt");
}

public void Beacon_Call(int client, Perk perk, bool apply){
	if(apply) Beacon_ApplyPerk(client, perk);
	else UnsetClientPerkCache(client, g_iBeaconId);
}

void Beacon_ApplyPerk(int client, Perk perk){
	g_iBeaconId = perk.Id;
	SetClientPerkCache(client, g_iBeaconId);
	CreateTimer(perk.GetPrefFloat("interval"), Timer_BeaconBeep, GetClientUserId(client), TIMER_REPEAT);
	SetFloatCache(client, perk.GetPrefFloat("radius"));
}

public Action Timer_BeaconBeep(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iBeaconId))
		return Plugin_Stop;

	Beacon_Beep(client);
	return Plugin_Continue;
}

void Beacon_Beep(int client){
	float fPos[3];
	GetClientAbsOrigin(client, fPos);
	fPos[2] += 10.0;

	int iColorGra[4] = {128,128,128,255};
	int iColorRed[4] = {255,75,75,255};
	int iColorBlu[4] = {75,75,255,255};

	float fRadius = GetFloatCache(client);

	TE_SetupBeamRingPoint(fPos, 10.0, fRadius, g_iSpriteBeam, g_iSpriteHalo, 0, 15, 0.5, 5.0, 0.0, iColorGra, 10, 0);
	TE_SendToAll();

	if(TF2_GetClientTeam(client) == TFTeam_Red)
		TE_SetupBeamRingPoint(fPos, 10.0, fRadius, g_iSpriteBeam, g_iSpriteHalo, 0, 10, 0.6, 10.0, 0.5, iColorRed, 10, 0);
	else
		TE_SetupBeamRingPoint(fPos, 10.0, fRadius, g_iSpriteBeam, g_iSpriteHalo, 0, 10, 0.6, 10.0, 0.5, iColorBlu, 10, 0);

	TE_SendToAll();
	EmitSoundToAll(SOUND_BEEP, client);
}
