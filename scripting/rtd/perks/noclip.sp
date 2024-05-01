/**
* Noclip perk.
* Copyright (C) 2023 Filip Tomaszewski
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

#define Mode Int[0]
#define BaseGravity Float[0]

DEFINE_CALL_APPLY_REMOVE(Noclip)

public void Noclip_Init(const Perk perk)
{
	Events.OnPlayerRunCmd(perk, Noclip_OnPlayerRunCmd);
}

void Noclip_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Mode = perk.GetPrefCell("mode", 0);

	if (Cache[client].Mode)
	{
		SetEntityMoveType(client, MOVETYPE_NOCLIP);
	}
	else
	{
		Cache[client].BaseGravity = GetEntityGravity(client);
		SetEntityGravity(client, 0.0001);
		TF2_AddCondition(client, TFCond_SwimmingNoEffects);
	}
}

public void Noclip_RemovePerk(const int client, const RTDRemoveReason eRemoveReason)
{
	if (Cache[client].Mode)
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		FixPotentialStuck(client);
	}
	else
	{
		SetEntityGravity(client, Cache[client].BaseGravity);
		TF2_RemoveCondition(client, TFCond_SwimmingNoEffects);
	}
}

bool Noclip_OnPlayerRunCmd(const int client, int& iButtons, float fVel[3], float fAng[3])
{
	if (Cache[client].Mode)
		return false;

	bool bStationary = fVel[0] == 0.0 && fVel[1] == 0.0;
	bool bSwimming = TF2_IsPlayerInCondition(client, TFCond_SwimmingNoEffects);

	// Apply the swimming condition only during movement. When we're stationary and in air,
	// we float down. Which is super hilarious btw if you get the reference (btw).
	if (bStationary && bSwimming)
	{
		TF2_RemoveCondition(client, TFCond_SwimmingNoEffects);
	}
	else if (!bStationary && !bSwimming)
	{
		TF2_AddCondition(client, TFCond_SwimmingNoEffects);
	}

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

	return false;
}

#undef Mode
#undef BaseGravity
