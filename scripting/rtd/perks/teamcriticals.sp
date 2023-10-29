/**
* Team Criticals perk.
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

#define CritCond Int[0]
#define RangeSquared Float[1]

int g_iTeamCriticalsBoostSourceCount[MAXPLAYERS + 1] = {0, ...};

DEFINE_CALL_APPLY_REMOVE(TeamCriticals)

public void TeamCriticals_ApplyPerk(const int client, const Perk perk)
{
	TFCond eCritType = perk.GetPrefCell("crits", 1) ? TFCond_CritOnFirstBlood : TFCond_Buffed;
	float fRange = perk.GetPrefFloat("range", 270.0);

	Cache[client].CritCond = view_as<int>(eCritType);
	Cache[client].RangeSquared = fRange * fRange;
	Cache[client].Flags.Reset();

	++g_iTeamCriticalsBoostSourceCount[client];
	TF2_AddCondition(client, eCritType);

	Cache[client].Repeat(0.25, TeamCriticals_SetTargets);
}

void TeamCriticals_RemovePerk(const int client)
{
	--g_iTeamCriticalsBoostSourceCount[client];
	TF2_RemoveCondition(client, view_as<TFCond>(Cache[client].CritCond));

	for (int i = 1; i <= MaxClients; ++i)
		if (IsClientInGame(i))
			TeamCriticals_UnsetCritBoost(client, i);
}

public Action TeamCriticals_SetTargets(const int client)
{
	TFTeam eTeam = TF2_GetClientTeam(client);
	float fRangeSquared = Cache[client].RangeSquared;

	for (int i = 1; i <= MaxClients; ++i)
	{
		if (TeamCriticals_IsValidTarget(client, i, eTeam, fRangeSquared))
		{
			TeamCriticals_SetCritBoost(client, i);
		}
		else
		{
			TeamCriticals_UnsetCritBoost(client, i);
		}
	}

	return Plugin_Continue;
}

void TeamCriticals_SetCritBoost(int client, int iTarget)
{
	if (Cache[client].Flags.Test(iTarget))
		return;

	Cache[client].Flags.Set(iTarget);
	++g_iTeamCriticalsBoostSourceCount[iTarget];
	TF2_AddCondition(iTarget, view_as<TFCond>(Cache[client].CritCond));
}

void TeamCriticals_UnsetCritBoost(int client, int iTarget)
{
	if (!Cache[client].Flags.Test(iTarget))
		return;

	Cache[client].Flags.Unset(iTarget);
	if (--g_iTeamCriticalsBoostSourceCount[iTarget] <= 0)
		TF2_RemoveCondition(iTarget, view_as<TFCond>(Cache[client].CritCond));
}

bool TeamCriticals_IsValidTarget(int client, int iTarget, TFTeam eClientTeam, float fRangeSquared)
{
	if (client == iTarget)
		return false;

	if (!IsClientInGame(iTarget))
		return false;

	float fPos[3], fEndPos[3];
	GetClientAbsOrigin(client, fPos);
	GetClientAbsOrigin(iTarget, fEndPos);

	if (GetVectorDistance(fPos, fEndPos, true) > fRangeSquared)
		return false;

	if (TF2_IsPlayerInCondition(iTarget, TFCond_Cloaked))
		return false;

	bool bDisguised = TF2_IsPlayerInCondition(iTarget, TFCond_Disguised);
	bool bSameTeam = eClientTeam == TF2_GetClientTeam(iTarget);

	// Do not draw beam if:
	// - our friendly Spy is disguised, or
	// - an enemy Spy is NOT disguised.
	// This does not account for being able to disguise as the same team.
	if ((bDisguised && bSameTeam) || (!bDisguised && !bSameTeam))
		return false;

	// Most expensive call last
	return CanEntitySeeTarget(client, iTarget);
}

#undef CritCond
#undef RangeSquared
