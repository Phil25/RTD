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

RTDPerk perk = view_as<RTDPerk>(-1);

public void OnPluginStart(){
	if(RTD2_IsRegOpen())
		perk = RTD2_ObtainPerk("token");
}

public void RTD2_OnRegOpen(){
	perk = RTD2_ObtainPerk("token");
}
