/**
* Forced Taunt perk.
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

#define Interval Float[0]
#define NextTaunt Float[1]

static char g_sSoundScoutBB[][] = {
	"items/scout_boombox_02.wav",
	"items/scout_boombox_03.wav",
	"items/scout_boombox_04.wav",
	"items/scout_boombox_05.wav"
};

DEFINE_CALL_APPLY(ForcedTaunt)

public void ForcedTaunt_Init(const Perk perk)
{
	for (int i = 0; i < sizeof(g_sSoundScoutBB); ++i)
		PrecacheSound(g_sSoundScoutBB[i]);

	Events.OnConditionAdded(perk, ForcedTaunt_OnConditionAdded);
	Events.OnConditionRemoved(perk, ForcedTaunt_OnConditionRemoved);
}

void ForcedTaunt_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Interval = perk.GetPrefFloat("interval", 1.0);

	ForcedTaunt_Perform(client);
	Cache[client].Repeat(0.1, ForcedTaunt_Perform);
}

public Action ForcedTaunt_Perform(const int client)
{
	if (GetEngineTime() < Cache[client].NextTaunt)
		return Plugin_Continue;

	if (GetEntProp(client, Prop_Send, "m_hGroundEntity") == -1)
		return Plugin_Continue;

	FakeClientCommand(client, "taunt");
	return Plugin_Continue;
}

public void ForcedTaunt_OnConditionAdded(const int client, const TFCond eCondition)
{
	if (eCondition == TFCond_Taunting)
		EmitSoundToAll(g_sSoundScoutBB[GetRandomInt(0, sizeof(g_sSoundScoutBB) - 1)], client);
}

public void ForcedTaunt_OnConditionRemoved(const int client, const TFCond eCondition)
{
	if (eCondition == TFCond_Taunting)
		Cache[client].NextTaunt = GetEngineTime() + Cache[client].Interval;
}

#undef Interval
#undef NextTaunt
