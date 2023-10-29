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

#include "rtd/macros.sp"
#include "rtd/storage/cache.sp"

#define SOUND_BEEP "buttons/blip1.wav"

#define Radius Float[0]

DEFINE_CALL_APPLY(Beacon)

public void Beacon_Init(const Perk perk)
{
	PrecacheSound(SOUND_BEEP);
}

void Beacon_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Radius = perk.GetPrefFloat("radius", 375.0);
	Cache[client].Repeat(perk.GetPrefFloat("interval", 0.5), Beacon_Beep);
}

Action Beacon_Beep(const int client)
{
	float fPos[3];
	GetClientAbsOrigin(client, fPos);
	fPos[2] += 10.0;

	static int iColorGra[4] = {128,128,128,255};
	static int iColorRed[4] = {255,75,75,255};
	static int iColorBlu[4] = {75,75,255,255};

	float fRadius = Cache[client].Radius;
	int iLaser = Materials.Laser;
	int iHalo = Materials.Halo;

	TE_SetupBeamRingPoint(fPos, 10.0, fRadius, iLaser, iHalo, 0, 15, 0.5, 5.0, 0.0, iColorGra, 10, 0);
	TE_SendToAll();

	if (TF2_GetClientTeam(client) == TFTeam_Red)
	{
		TE_SetupBeamRingPoint(fPos, 10.0, fRadius, iLaser, iHalo, 0, 10, 0.6, 10.0, 0.5, iColorRed, 10, 0);
	}
	else
	{
		TE_SetupBeamRingPoint(fPos, 10.0, fRadius, iLaser, iHalo, 0, 10, 0.6, 10.0, 0.5, iColorBlu, 10, 0);
	}

	TE_SendToAll();
	EmitSoundToAll(SOUND_BEEP, client);

	return Plugin_Continue;
}

#undef SOUND_BEEP

#undef Radius
