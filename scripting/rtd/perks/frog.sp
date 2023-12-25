/**
* Frog perk.
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

#define InJump Int[0]
#define NextJump Float[0]
#define Rate Float[1]
#define Vertical Float[2]
#define Horizontal Float[3]

static char g_sCritters[][] = {
	"ambient/levels/canals/critter1.wav",
	"ambient/levels/canals/critter2.wav",
	"ambient/levels/canals/critter3.wav",
	"ambient/levels/canals/critter5.wav"
};

DEFINE_CALL_APPLY_REMOVE(Frog)

public void Frog_Init(const Perk perk)
{
	PrecacheSound(g_sCritters[0]);
	PrecacheSound(g_sCritters[1]);
	PrecacheSound(g_sCritters[2]);
	PrecacheSound(g_sCritters[3]);

	Events.OnPlayerRunCmd(perk, Frog_OnPlayerRunCmd);
}

public void Frog_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].InJump = !IsGrounded(client);
	Cache[client].NextJump = GetEngineTime();
	Cache[client].Rate = perk.GetPrefFloat("rate", 0.5);
	Cache[client].Vertical = perk.GetPrefFloat("vertical", 300.0);
	Cache[client].Horizontal = perk.GetPrefFloat("horizontal", 500.0);

	int iFlags = GetEntityFlags(client);
	SetEntityFlags(client, iFlags | FL_ATCONTROLS);

	Cache[client].Repeat(0.1, Frog_JumpCheck);
}

public void Frog_RemovePerk(const int client)
{
	int iFlags = GetEntityFlags(client);
	SetEntityFlags(client, iFlags & ~FL_ATCONTROLS);
}

Action Frog_JumpCheck(const int client)
{
	if (Cache[client].InJump && IsGrounded(client))
	{
		// prevent slide
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, {0.0, 0.0, 0.0});

		Cache[client].NextJump = GetEngineTime() + Cache[client].Rate;
		Cache[client].InJump = false;
	}

	return Plugin_Continue;
}

bool Frog_OnPlayerRunCmd(const int client, int& iButtons, float fVel[3], float fAng[3])
{
	if (Cache[client].InJump)
		return false;

	if (!IsGrounded(client))
	{
		// client jumped on their own
		Cache[client].InJump = true;
		return false;
	}

	if (!(iButtons & (IN_MOVELEFT | IN_MOVERIGHT | IN_FORWARD | IN_BACK)))
		return false;

	if (Cache[client].NextJump > GetEngineTime())
		return false;

	float fForward[3], fRight[3], fFinal[3];
	GetAngleVectors(fAng, fForward, fRight, NULL_VECTOR);

	fForward[0] *= fVel[0];
	fForward[1] *= fVel[0];
	fRight[0] *= fVel[1];
	fRight[1] *= fVel[1];

	AddVectors(fForward, fRight, fFinal);
	NormalizeVector(fFinal, fFinal);

	ScaleVector(fFinal, Cache[client].Horizontal);
	fFinal[2] = Cache[client].Vertical;

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fFinal);
	EmitSoundToAll(g_sCritters[GetRandomInt(0, sizeof(g_sCritters) - 1)], client, _, _, _, _, GetRandomInt(80, 120));

	Cache[client].InJump = true;

	return false;
}

#undef InJump
#undef NextJump
#undef Rate
#undef Vertical
#undef Horizontal
