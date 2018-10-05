/**
* Drunk Walk perk.
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

#define BASE_WALK_SPEED 0
#define MIN_WALK_SPEED 1
#define MAX_WALK_SPEED 2

int g_iDrunkWalkId = 65;

public void DrunkWalk_Call(int client, Perk perk, bool apply){
	if(apply) DrunkWalk_ApplyPerk(client, perk);
	else DrunkWalk_RemovePerk(client);
}

void DrunkWalk_ApplyPerk(int client, Perk perk){
	g_iDrunkWalkId = perk.Id;
	SetClientPerkCache(client, g_iDrunkWalkId);

	SetFloatCache(client, GetBaseSpeed(client), BASE_WALK_SPEED);
	SetFloatCache(client, perk.GetPrefFloat("minspeed"), MIN_WALK_SPEED);
	SetFloatCache(client, perk.GetPrefFloat("maxspeed"), MAX_WALK_SPEED);
}

void DrunkWalk_RemovePerk(int client){
	UnsetClientPerkCache(client, g_iDrunkWalkId);
	float fBase = GetFloatCache(client, BASE_WALK_SPEED);
	SetSpeed(client, fBase);
}

bool DrunkWalk_Sound(int client, const char[] sSound){
	if(CheckClientPerkCache(client, g_iDrunkWalkId) && IsFootstepSound(sSound))
		DrunkWalk_Tick(client);
	return true;
}

void DrunkWalk_Tick(int client){
	ViewPunchRand(client, 25.0);
	Drugged_Tick(client);

	float fBase = GetFloatCache(client, BASE_WALK_SPEED);
	float fMin = GetFloatCache(client, MIN_WALK_SPEED);
	float fMax = GetFloatCache(client, MAX_WALK_SPEED);
	SetSpeed(client, fBase, GetRandomFloat(fMin, fMax));
}

#undef BASE_WALK_SPEED
#undef MIN_WALK_SPEED
#undef MAX_WALK_SPEED
