/**
* Outline perk.
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


bool g_bOutlined_Outline[MAXPLAYERS+1] = {false, ...};

public void Outline_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		Outline_ApplyPerk(client);
	
	else
		Outline_RemovePerk(client);

}

void Outline_ApplyPerk(int client){

	g_bOutlined_Outline[client] = view_as<bool>(GetEntProp(client, Prop_Send, "m_bGlowEnabled"));

	if(g_bOutlined_Outline[client])
		return;

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);

}

void Outline_RemovePerk(int client){

	if(!g_bOutlined_Outline[client])
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);

}
