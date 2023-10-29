/**
* Lag perk.
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

#define Pos(%1) Float[%1]

DEFINE_CALL_APPLY(Lag)

public void Lag_ApplyPerk(const int client, const Perk perk)
{
	Lag_SetPosition(client);

	Cache[client].Repeat(1.0, Lag_Teleport);
	Cache[client].Repeat(0.5, Lag_SetPosition);
}

public Action Lag_Teleport(const int client)
{
	float fPos[3];
	fPos[0] = Cache[client].Pos(0);
	fPos[1] = Cache[client].Pos(1);
	fPos[2] = Cache[client].Pos(2);

	TeleportEntity(client, fPos, NULL_VECTOR, NULL_VECTOR);

	return Plugin_Continue;
}

public Action Lag_SetPosition(const int client)
{
	float fPos[3];
	GetClientAbsOrigin(client, fPos);

	Cache[client].Pos(0) = fPos[0];
	Cache[client].Pos(1) = fPos[1];
	Cache[client].Pos(2) = fPos[2];

	return Plugin_Continue;
}

#undef Pos
