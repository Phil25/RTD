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

public void OnPluginStart(){
	ParseEffects();
	RegServerCmd("sm_rtdstest", Command_PerkSearchupTest);
	char sBuffer[255];

	Perk perk = null;
	PerkIter iter = new PerkIter(-1);
	PerkList list = new PerkList();

	int i = 0;
	while((perk = (++iter).Perk())){
		perk.Format(sBuffer, 255, "$Id$. $Name$");
		PrintToServer(sBuffer);
		list.Push(perk);
		if(++i > 5) break;
	}

	i = 0;
	while(++i < 20){
		perk = list.GetRandom();
		perk.Format(sBuffer, 255, "Random: $Name$");
		PrintToServer(sBuffer);
	}

	delete list;
	delete iter;
}

bool ParseEffects(){
	if(g_hPerkContainer == null)
		g_hPerkContainer = new PerkContainer();
	g_hPerkContainer.DisposePerks();

	char sPath[255];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/rtd2_perks.default.cfg");
	int iStatus[2];
	return FileExists(sPath) && g_hPerkContainer.ParseFile(sPath, iStatus) != -1;
}

public Action Command_PerkSearchupTest(int args){
	if(args < 1)
		return Plugin_Handled;

	char sQuery[255];
	GetCmdArg(1, sQuery, 255);
	PerkList list = g_hPerkContainer.FindPerks(sQuery);

	char sBuffer[255];
	for(int i = 0; i < list.Length; i++){
		list.Get(i).Format(sBuffer, 255, "$Id$. $Name$");
		PrintToServer(sBuffer);
	}

	delete list;
	return Plugin_Handled;
}
