/**
* Funny Feeling perk.
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

#define DESIRED 0
#define BASE 1

int g_iFunnyFeelingId = 28;

void FunnyFeeling_Perk(int client, Perk perk, bool apply){
	if(apply) FunnyFeeling_ApplyPerk(client, perk);
	else FunnyFeeling_RemovePerk(client);
}

void FunnyFeeling_ApplyPerk(int client, Perk perk){
	g_iFunnyFeelingId = perk.Id;
	SetClientPerkCache(client, g_iFunnyFeelingId);
	int iDesired = perk.GetPrefCell("fov");

	SetIntCache(client, iDesired, DESIRED);
	SetIntCache(client, GetEntProp(client, Prop_Send, "m_iFOV"), BASE);
	SetEntProp(client, Prop_Send, "m_iFOV", iDesired);
}

void FunnyFeeling_RemovePerk(int client){
	SetEntProp(client, Prop_Send, "m_iFOV", GetIntCache(client, BASE));
	UnsetClientPerkCache(client, g_iFunnyFeelingId);
}

void FunnyFeeling_OnConditionRemoved(int client, TFCond condition){
	if(condition != TFCond_Zoomed) return;

	if(CheckClientPerkCache(client, g_iFunnyFeelingId))
		SetEntProp(client, Prop_Send, "m_iFOV", GetIntCache(client, DESIRED));
}

#undef DESIRED
#undef BASE
