/**
* Cursed perk.
* Copyright (C) 2023 Filip Tomaszewski
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

DEFINE_CALL_EMPTY(Cursed)

public void Cursed_Init(const Perk perk)
{
	Events.OnPlayerRunCmd(perk, Cursed_OnPlayerRunCmd);
}

bool Cursed_OnPlayerRunCmd(const int client, int& iButtons, float fVel[3], float fAng[3])
{
	fVel[0] = -fVel[0];
	fVel[1] = -fVel[1];

	if (iButtons & IN_MOVELEFT)
	{
		iButtons &= ~IN_MOVELEFT;
		iButtons |= IN_MOVERIGHT;
	}
	else if (iButtons & IN_MOVERIGHT)
	{
		iButtons &= ~IN_MOVERIGHT;
		iButtons |= IN_MOVELEFT;
	}

	if (iButtons & IN_FORWARD)
	{
		iButtons &= ~IN_FORWARD;
		iButtons |= IN_BACK;
	}
	else if (iButtons & IN_BACK)
	{
		iButtons &= ~IN_BACK;
		iButtons |= IN_FORWARD;
	}

	return true;
}
