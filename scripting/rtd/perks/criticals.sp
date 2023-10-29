/**
* Criticals perk.
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

#define Condition Int[0]

DEFINE_CALL_APPLY_REMOVE(Criticals)

public void Criticals_ApplyPerk(const int client, const Perk perk)
{
	TFCond eCond = perk.GetPrefCell("full", 1) > 0 ? TFCond_CritOnFirstBlood : TFCond_Buffed;

	Cache[client].Condition = view_as<int>(eCond);
	TF2_AddCondition(client, eCond);
}

void Criticals_RemovePerk(int client)
{
	TF2_RemoveCondition(client, view_as<TFCond>(Cache[client].Condition));
}

#undef Condition
