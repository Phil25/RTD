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
#define ATTRIB_JUMP_BLOCK 819

bool g_bIsSpringJumping[MAXPLAYERS+1] = {false, ...};

void SpringShoes_Start(){
	PrecacheSound(SPRING_JUMP);
}

public void SpringShoes_Perk(int client, const char[] sPref, bool apply){
	g_bIsSpringJumping[client] = apply;
	if(apply){
		CreateTimer(0.25, Timer_ForceSpringJump, GetClientUserId(client), TIMER_REPEAT);
		TF2Attrib_SetByDefIndex(client, ATTRIB_JUMP_BLOCK, 1.0);
	}else TF2Attrib_RemoveByDefIndex(client, ATTRIB_JUMP_BLOCK);
}

public Action Timer_ForceSpringJump(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client || !g_bIsSpringJumping[client])
		return Plugin_Stop;
	SpringJump(client);
	return Plugin_Continue;
}

void SpringJump(int client){
	if(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1)
		return;

	float fVec[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVec);

	fVec[2] += 300.0;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVec);
	EmitSoundToAll(SPRING_JUMP, client);
}
