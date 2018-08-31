/**
* Standalone plugin used for testing of RTD features.
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

#include "rtd/perk_class.sp"


PerkContainer g_hPerks = null;

public void OnPluginStart(){
	ParseEffects();
	PrintToServer("Size: %d", g_hPerks.Size);
	g_hPerks.DisposePerks();
	PrintToServer("Size: %d", g_hPerks.Size);
}

bool ParseEffects(){
	if(g_hPerks == null)
		g_hPerks = new PerkContainer();
	g_hPerks.DisposePerks();

	char sPath[255];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/rtd2_perks.default.cfg");
	int iStatus[2];
	return FileExists(sPath) && g_hPerks.ParseFile(sPath, iStatus) != -1;
}
