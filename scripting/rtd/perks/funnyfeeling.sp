/**
* Funny Feeling perk.
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

#define FunnyFov Int[0]
#define BaseFov Int[1]

DEFINE_CALL_APPLY_REMOVE(FunnyFeeling)

public void FunnyFeeling_Init(const Perk perk)
{
	Events.OnConditionRemoved(perk, FunnyFeeling_OnConditionRemoved);
}

public void FunnyFeeling_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].FunnyFov = perk.GetPrefCell("fov", 160);
	Cache[client].BaseFov = GetEntProp(client, Prop_Send, "m_iFOV");

	SetEntProp(client, Prop_Send, "m_iFOV", Cache[client].FunnyFov);
}

void FunnyFeeling_RemovePerk(const int client)
{
	SetEntProp(client, Prop_Send, "m_iFOV", Cache[client].BaseFov);
}

public void FunnyFeeling_OnConditionRemoved(const int client, const TFCond condition)
{
	if (condition == TFCond_Zoomed)
		SetEntProp(client, Prop_Send, "m_iFOV", Cache[client].FunnyFov);
}

#undef FunnyFov
#undef BaseFov
