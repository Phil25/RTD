/**
* Tiny Mann perk.
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


float	g_fBaseTinyMann[MAXPLAYERS+1]	= {1.0, ...};
bool	g_bIsTinyMann[MAXPLAYERS+1]		= {false, ...};
float	g_fTinyMannScale				= 0.15;

void TinyMann_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		TinyMann_ApplyPerk(client, StringToFloat(sPref));

	else
		TinyMann_RemovePerk(client);

}

void TinyMann_ApplyPerk(int client, float fMultiplayer){

	g_bIsTinyMann[client]	= true;
	g_fTinyMannScale		= fMultiplayer;
	
	TF2Attrib_SetByDefIndex(client, 2048, 1/g_fTinyMannScale/2);
	g_fBaseTinyMann[client] = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", fMultiplayer);

}

void TinyMann_RemovePerk(int client){

	g_bIsTinyMann[client] = false;
	
	TF2Attrib_RemoveByDefIndex(client, 2048);
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_fBaseTinyMann[client]);
	
	FixPotentialStuck(client);

}
