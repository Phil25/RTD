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

public void IncreasedSpeed_Call(int client, Perk perk, bool apply){
	if(apply) IncreasedSpeed_ApplyPerk(client, perk);
	else IncreasedSpeed_RemovePerk(client);
}

void IncreasedSpeed_ApplyPerk(int client, Perk perk){
	float fValue = perk.GetPrefFloat("multiplier");
	float fBaseSpeed = 300.0;

	TFClassType class = TF2_GetPlayerClass(client);
	switch(class){
		case TFClass_Scout:		fBaseSpeed = 400.0;
		case TFClass_Soldier:	fBaseSpeed = 240.0;
		case TFClass_DemoMan:	fBaseSpeed = 280.0;
		case TFClass_Heavy:		fBaseSpeed = 230.0;
		case TFClass_Medic:		fBaseSpeed = 320.0;
	}
	SetFloatCache(client, fBaseSpeed);

	TF2Attrib_SetByDefIndex(client, ATTRIB_SPEED, fValue);
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", fBaseSpeed*fValue);
}

void IncreasedSpeed_RemovePerk(int client){
	TF2Attrib_RemoveByDefIndex(client, ATTRIB_SPEED);
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetFloatCache(client));
}
