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
#include <tf2_stocks>

public void OnPluginStart(){
	if(RTD2_IsRegOpen())
		RegisterPerk();
}

public void RTD2_OnRegOpen(){
	RegisterPerk();
}

void RegisterPerk(){
	RTDPerk perk = RTD2_ObtainPerk("token");
	perk.SetName("Name");
	perk.Good = true;
	perk.SetSound("Sound");
	perk.Time = 10;
	perk.SetClasses("123");
	perk.WeaponClasses.Clear();
	perk.WeaponClasses.PushString("weapon1");
	perk.WeaponClasses.PushString("weapon2");
	perk.WeaponClasses.PushString("weapon3");
	perk.SetPref("Preferece string");
	perk.Tags.Clear();
	perk.Tags.PushString("tag1");
	perk.Tags.PushString("tag2");
	perk.Tags.PushString("tag3");
	perk.Enabled = true;
	perk.External = true;
	perk.SetCall(PerkCall);
	char sPrint[1024];
	perk.Format(sPrint, 1024, "Token: $Token$\nName: $Name$\nGood: $Good$\nTime: $Time$\nClasses: $Class$\nWeapon Classes: $WeaponClass$\nPref: $Pref$\nTags: $Tags$");
	PrintToServer("%s\nEnabled: %d\nExternal: %d", sPrint, perk.Enabled, perk.External);
	RTD2_ObtainPerk("godmode").SetCall(GodmodeOverride);
	RTD2_ObtainPerk("godmode").External = true;
}

public void PerkCall(int client, RTDPerk perk, bool bEnable){
	PrintToServer("Perk %s on client %d", bEnable ? "enabled" : "disabled", client);
}

public void GodmodeOverride(int client, RTDPerk perk, bool bEnable){
	PrintToChat(client, "%s godmode", bEnable ? "Applying" : "Disabling");
}
