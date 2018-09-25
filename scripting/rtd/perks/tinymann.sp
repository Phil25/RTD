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

#define SCALE 0
#define BASE 1

public void TinyMann_Call(int client, Perk perk, bool apply){
	if(apply) TinyMann_ApplyPerk(client, perk);
	else TinyMann_RemovePerk(client);
}

void TinyMann_ApplyPerk(int client, Perk perk){
	float fScale = perk.GetPrefFloat("scale");
	float fBase = GetEntPropFloat(client, Prop_Send, "m_flModelScale");

	SetFloatCache(client, fScale, SCALE);
	SetFloatCache(client, fBase, BASE);

	TF2Attrib_SetByDefIndex(client, 2048, 1/fScale/2);
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", fScale);
}

void TinyMann_RemovePerk(int client){
	TF2Attrib_RemoveByDefIndex(client, 2048);
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", GetFloatCache(client, BASE));

	FixPotentialStuck(client);
}

#undef SCALE
#undef BASE
