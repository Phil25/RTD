/**
* Noclip perk.
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


int g_iNoclipId = 4;

public void Noclip_Call(int client, Perk perk, bool apply){
	if(apply){
		g_iNoclipId = perk.Id;
		SetIntCache(client, perk.GetPrefCell("mode"));

		if(GetIntCache(client))
			SetEntityMoveType(client, MOVETYPE_NOCLIP);
		else{
			SetFloatCache(client, GetEntityGravity(client));
			SetEntityGravity(client, 0.0001);
			TF2_AddCondition(client, TFCond_SwimmingNoEffects);
		}

		SetClientPerkCache(client, g_iNoclipId);
	}else{
		UnsetClientPerkCache(client, g_iNoclipId);

		if(perk.GetPrefCell("mode")){
			SetEntityMoveType(client, MOVETYPE_WALK);
			FixPotentialStuck(client);
		}else{
			SetEntityGravity(client, GetFloatCache(client));
			TF2_RemoveCondition(client, TFCond_SwimmingNoEffects);
		}
	}
}

void Noclip_OnPlayerRunCmd(const int client, float fVel[3], float fAng[3]){
	if(!CheckClientPerkCache(client, g_iNoclipId))
		return;

	if(GetIntCache(client))
		return;

	bool bStationary = fVel[0] == 0.0 && fVel[1] == 0.0;
	bool bSwimming = TF2_IsPlayerInCondition(client, TFCond_SwimmingNoEffects);

	// Apply the swimming condition only during movement. When we're stationary and in air,
	// we float down. Which is super hilarious btw if you get the reference (btw).
	if(bStationary && bSwimming)
		TF2_RemoveCondition(client, TFCond_SwimmingNoEffects);
	else if(!bStationary && !bSwimming)
		TF2_AddCondition(client, TFCond_SwimmingNoEffects);

	float fForward[3], fRight[3], fFinal[3];
	GetAngleVectors(fAng, fForward, fRight, NULL_VECTOR);

	fForward[0] *= 3.0 * fVel[0];
	fForward[1] *= 3.0 * fVel[0];
	fForward[2] *= 3.0 * fVel[0];
	fRight[0] *= 3.0 * fVel[1];
	fRight[1] *= 3.0 * fVel[1];
	fRight[2] *= 3.0 * fVel[1];

	AddVectors(fForward, fRight, fFinal);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fFinal);
}
