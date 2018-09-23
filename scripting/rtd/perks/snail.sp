/**
* Snail perk.
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


#define ATTRIB_SPEED 107 //the player speed attribute

float g_fBaseSpeed_Snail[MAXPLAYERS+1] = {0.0, ...};

void Snail_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		Snail_ApplyPerk(client, StringToFloat(sPref));
	
	else
		Snail_RemovePerk(client);

}

void Snail_ApplyPerk(int client, float fMultp){

	switch(TF2_GetPlayerClass(client)){
	
		case TFClass_Scout:		{g_fBaseSpeed_Snail[client] = 400.0;}
		case TFClass_Soldier:	{g_fBaseSpeed_Snail[client] = 240.0;}
		case TFClass_DemoMan:	{g_fBaseSpeed_Snail[client] = 280.0;}
		case TFClass_Heavy:		{g_fBaseSpeed_Snail[client] = 230.0;}
		case TFClass_Medic:		{g_fBaseSpeed_Snail[client] = 320.0;}
		default:				{g_fBaseSpeed_Snail[client] = 300.0;}
	
	}

	TF2Attrib_SetByDefIndex(client, ATTRIB_SPEED, fMultp);
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", g_fBaseSpeed_Snail[client]*fMultp);

}

void Snail_RemovePerk(int client){

	TF2Attrib_RemoveByDefIndex(client, ATTRIB_SPEED);
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", g_fBaseSpeed_Snail[client]);

}
