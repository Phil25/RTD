/**
* Spring Shoes perk.
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

#define SPRING_JUMP "misc/halloween/duck_pickup_neg_01.wav"

DEFINE_CALL_APPLY_REMOVE(SpringShoes)

public void SpringShoes_Init(const Perk perk)
{
	PrecacheSound(SPRING_JUMP);
}

public void SpringShoes_ApplyPerk(const int client, const Perk perk)
{
	TF2Attrib_SetByDefIndex(client, Attribs.PreventJump, 1.0);

	Cache[client].Repeat(0.25, SpringShoes_ForceJump);
}

void SpringShoes_RemovePerk(const int client)
{
	TF2Attrib_RemoveByDefIndex(client, Attribs.PreventJump);
}


public Action SpringShoes_ForceJump(const int client)
{
	if (GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1)
		return Plugin_Continue;

	float fVec[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVec);

	fVec[2] += 300.0;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVec);

	EmitSoundToAll(SPRING_JUMP, client);

	return Plugin_Continue;
}

#undef SPRING_JUMP
