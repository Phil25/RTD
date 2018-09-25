/**
* Criticals perk.
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


#define FULLCRIT TFCond_CritOnFirstBlood
#define MINICRIT TFCond_Buffed

public void Criticals_Call(int client, Perk perk, bool apply){
	if(apply) Criticals_ApplyPerk(client, perk);
	else Criticals_RemovePerk(client);
}

void Criticals_ApplyPerk(int client, Perk perk){
	TFCond iFull = perk.GetPrefCell("full") > 0 ? FULLCRIT : MINICRIT;
	SetIntCache(client, view_as<int>(iFull));
	TF2_AddCondition(client, iFull);
}

void Criticals_RemovePerk(int client){
	TF2_RemoveCondition(client, view_as<TFCond>(GetIntCache(client)));
}

#undef FULLCRIT
#undef MINICRIT
