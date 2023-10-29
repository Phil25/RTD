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

#define BaseSpeed Float[0]
#define MinSpeed Float[1]
#define MaxSpeed Float[2]
#define TurnAngle Float[3]

DEFINE_CALL_APPLY_REMOVE(DrunkWalk)

public void DrunkWalk_Init(const Perk perk)
{
	Events.OnSound(perk, DrunkWalk_OnSound);
}

public void DrunkWalk_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].BaseSpeed = GetBaseSpeed(client);
	Cache[client].MinSpeed = perk.GetPrefFloat("minspeed", 0.35);
	Cache[client].MaxSpeed = perk.GetPrefFloat("maxspeed", 1.8);
	Cache[client].TurnAngle = perk.GetPrefFloat("turnangle", 15.0);
}

void DrunkWalk_RemovePerk(const int client)
{
	SetSpeed(client, Cache[client].BaseSpeed);
}

bool DrunkWalk_OnSound(const int client, const char[] sSound)
{
	if (IsFootstepSound(sSound))
		DrunkWalk_Tick(client);

	return true;
}

void DrunkWalk_Tick(const int client)
{
	RotateClientSmooth(client, Cache[client].TurnAngle * GetRandomSign());

	float fSpeed = GetRandomFloat(Cache[client].MinSpeed, Cache[client].MaxSpeed);
	SetSpeed(client, Cache[client].BaseSpeed, fSpeed);
}

#undef BaseSpeed
#undef MinSpeed
#undef MaxSpeed
#undef TurnAngle
