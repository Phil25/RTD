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

#include <rtd2>

public void OnPluginStart(){
	if(RTD2_IsRegOpen())
		RegisterPerk();
}

public void OnPluginEnd(){
	RTD2_DisableModulePerks();
}

public void RTD2_OnRegOpen(){
	RegisterPerk();
}

void RegisterPerk(){
	//RTD2_ObtainPerk("godmode").SetCall(GodmodeOverride);
	/*RTDPerk perk = RTD2_ObtainPerk("token");
	perk.Good = true;
	perk.SetClasses("0");
	perk.SetCall(TestCall);*/
}

public void GodmodeOverride(int client, RTDPerk perk, bool bEnable){
	PrintToChat(client, "%s godmode", bEnable ? "Applying" : "Disabling");
}

public void TestCall(int client, RTDPerk perk, bool bEnable){
	PrintToChat(client, "%s test", bEnable ? "Applying" : "Disabling");
}
