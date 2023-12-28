/**
* Low Gravity perk.
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

#define JumpMode Int[0]
#define FallDamage Int[1]
#define Gravity Float[0]
#define MaxBoostSquared Float[1]

DEFINE_CALL_APPLY_REMOVE(LowGravity)

public void LowGravity_Init(const Perk perk)
{
	Events.OnPlayerRunCmd(perk, LowGravity_OnPlayerRunCmd);
}

public void LowGravity_ApplyPerk(int client, Perk perk)
{
	float fMultiplier = perk.GetPrefFloat("multiplier", 0.25);
	float fBaseSpeed = GetBaseSpeed(client);

	Cache[client].JumpMode = perk.GetPrefCell("jump_mode", 1);
	Cache[client].FallDamage = perk.GetPrefCell("fall_damage", 0);
	Cache[client].Gravity = GetEntityGravity(client);
	Cache[client].MaxBoostSquared = fBaseSpeed * fBaseSpeed * 1.5;

	if (Cache[client].JumpMode)
	{
		TF2Attrib_SetByDefIndex(client, Attribs.JumpHeight, 1.0 / fMultiplier);
	}
	else
	{
		SetEntityGravity(client, fMultiplier);
	}

	if (!Cache[client].FallDamage)
		TF2Attrib_SetByDefIndex(client, Attribs.NoFallDamage, 1.0);
}

public void LowGravity_RemovePerk(int client)
{
	if (Cache[client].JumpMode)
	{
		TF2Attrib_RemoveByDefIndex(client, Attribs.JumpHeight);
	}
	else
	{
		SetEntityGravity(client, Cache[client].Gravity);
	}

	if (!Cache[client].FallDamage)
		TF2Attrib_RemoveByDefIndex(client, Attribs.NoFallDamage);
}

bool LowGravity_OnPlayerRunCmd(const int client, int& iButtons, float fVel[3], float fAng[3])
{
	if (!(iButtons & IN_JUMP))
		return false;

	float fMoveVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fMoveVel);

	float fVerticalSpeed = fMoveVel[2];
	fMoveVel[2] = 0.0;

	if (GetVectorLength(fMoveVel, true) > Cache[client].MaxBoostSquared)
		return false;

	ScaleVector(fMoveVel, 1.1);
	fMoveVel[2] = fVerticalSpeed;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fMoveVel);

	return false;
}

#undef JumpMode
#undef FallDamage
#undef Gravity
#undef MaxBoostSquared