/**
* Infinite Double Jump perk.
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

DEFINE_CALL_EMPTY(InfiniteJump)

public void InfiniteJump_Init(const Perk perk)
{
	Events.OnPlayerRunCmd(perk, InfiniteJump_OnPlayerRunCmd);
}

bool InfiniteJump_OnPlayerRunCmd(const int client, int& iButtons, float fVel[3], float fAng[3])
{
	if (iButtons & IN_JUMP)
		SetEntProp(client, Prop_Send, "m_iAirDash", 0);

	return false;
}
