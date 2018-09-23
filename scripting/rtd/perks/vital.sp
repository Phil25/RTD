/**
* Vital perk.
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


#define MAX_HEALTH_ATTRIB 26

public void Vital_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		Vital_ApplyPerk(client, StringToInt(sPref));
	
	else
		TF2Attrib_RemoveByDefIndex(client, MAX_HEALTH_ATTRIB);

}

void Vital_ApplyPerk(int client, int iValue){

	TF2Attrib_SetByDefIndex(client, MAX_HEALTH_ATTRIB, float(iValue));

	SetEntityHealth(client, GetEntProp(client, Prop_Data, "m_iHealth") +iValue);

}
