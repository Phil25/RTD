/**
* Weakened perk.
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

#define Multiplier Float[0]

DEFINE_CALL_APPLY_REMOVE(Weakened)

public void Weakened_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Multiplier = perk.GetPrefFloat("multiplier", 2.5);

	SDKHook(client, SDKHook_OnTakeDamage, Weakened_OnTakeDamage);
}

public void Weakened_RemovePerk(const int client, const RTDRemoveReason eRemoveReason)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, Weakened_OnTakeDamage);
}

public Action Weakened_OnTakeDamage(int client, int& iAtk, int& iInflictor, float& fDmg, int& iType)
{
	if (client == iAtk)
		return Plugin_Continue;

	fDmg *= Cache[client].Multiplier;
	return Plugin_Changed;
}

#undef Multiplier
