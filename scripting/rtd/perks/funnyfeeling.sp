/**
* Funny Feeling perk.
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

	FunnyFeeling_SetFov(client, Cache[client].FunnyFov);
}

public void FunnyFeeling_RemovePerk(const int client, const RTDRemoveReason eRemoveReason)
{
	FunnyFeeling_SetFov(client, Cache[client].BaseFov);
}

public void FunnyFeeling_OnConditionRemoved(const int client, const TFCond eCond)
{
	switch (eCond)
	{
		case TFCond_Zoomed, TFCond_Teleporting:
			FunnyFeeling_SetFov(client, Cache[client].FunnyFov);
	}
}

void FunnyFeeling_SetFov(const int client, const int iFov)
{
	// Taunting seems to save Fov value and reset it once the taunt ends. We can remove it manually
	// to prevent effect not applying on perk's start, or staying on perk's end.
	TF2_RemoveCondition(client, TFCond_Taunting);

	SetEntProp(client, Prop_Send, "m_iFOV", iFov);
}

#undef FunnyFov
#undef BaseFov
