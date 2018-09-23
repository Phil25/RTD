/**
* Increased Speed perk.
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

float g_fBaseSpeed[MAXPLAYERS+1] = {0.0, ...};

void IncreasedSpeed_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		IncreasedSpeed_ApplyPerk(client, StringToFloat(sPref));
	
	else
		IncreasedSpeed_RemovePerk(client);

}

void IncreasedSpeed_ApplyPerk(int client, float fValue){

	switch(TF2_GetPlayerClass(client)){
	
		case TFClass_Scout:		{g_fBaseSpeed[client] = 400.0;}
		case TFClass_Soldier:	{g_fBaseSpeed[client] = 240.0;}
		case TFClass_DemoMan:	{g_fBaseSpeed[client] = 280.0;}
		case TFClass_Heavy:		{g_fBaseSpeed[client] = 230.0;}
		case TFClass_Medic:		{g_fBaseSpeed[client] = 320.0;}
		default:				{g_fBaseSpeed[client] = 300.0;}
	
	}

	TF2Attrib_SetByDefIndex(client, ATTRIB_SPEED, fValue);
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", g_fBaseSpeed[client]*fValue);

}

void IncreasedSpeed_RemovePerk(int client){

	TF2Attrib_RemoveByDefIndex(client, ATTRIB_SPEED);
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", g_fBaseSpeed[client]);

}
