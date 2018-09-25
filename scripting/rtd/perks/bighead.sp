/**
* Big Head perk.
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


#define ATTRIB_VOICEPITCH 2048

int g_iBigHeadId = 33;

void BigHead_Perk(int client, Perk perk, bool apply){
	if(apply) BigHead_Apply(client, perk);
	else BigHead_Remove(client);
}

void BigHead_Apply(int client, Perk perk){
	g_iBigHeadId = perk.Id;
	SetClientPerkCache(client, g_iBigHeadId);

	float fScale = perk.GetPrefFloat("scale");
	SetFloatCache(client, fScale);
	TF2Attrib_SetByDefIndex(client, ATTRIB_VOICEPITCH, 1/(fScale > 3.0 ? 3.0 : fScale));
}

void BigHead_Remove(int client){
	UnsetClientPerkCache(client, g_iBigHeadId);
	TF2Attrib_RemoveByDefIndex(client, ATTRIB_VOICEPITCH);
}

void BigHead_OnPlayerRunCmd(int client){
	if(CheckClientPerkCache(client, g_iBigHeadId))
		SetEntPropFloat(client, Prop_Send, "m_flHeadScale", GetFloatCache(client));
}
