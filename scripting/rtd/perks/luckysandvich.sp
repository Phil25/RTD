/**
* Lucky Sandvich perk.
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


bool g_bLuckySandvich_HasCrit[MAXPLAYERS+1] = {false, ...};

void LuckySandvich_Perk(int client, const char[] sPref, bool apply){

	if(!apply)
		return;

	SetEntityHealth(client, GetEntProp(client, Prop_Data, "m_iHealth") +StringToInt(sPref));
	g_bLuckySandvich_HasCrit[client] = true;

}

bool LuckySandvich_SetCritical(int client){

	if(!g_bLuckySandvich_HasCrit[client])
		return false;
	
	g_bLuckySandvich_HasCrit[client] = false;
	return true;

}
