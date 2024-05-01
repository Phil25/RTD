/**
* Suffocation perk.
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

#define Rate Float[0]
#define Damage Float[1]

DEFINE_CALL_APPLY(Suffocation)

public void Suffocation_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Rate = perk.GetPrefFloat("rate", 1.0);
	Cache[client].Damage = perk.GetPrefFloat("damage", 5.0);

	Cache[client].Delay(perk.GetPrefFloat("delay", 12.0), Suffocation_Begin);
}

public void Suffocation_Begin(const int client)
{
	TakeDamage(client, 0, 0, Cache[client].Damage, DMG_DROWN);
	Cache[client].Repeat(Cache[client].Rate, Suffocation_Tick);
}

public Action Suffocation_Tick(const int client)
{
	TakeDamage(client, 0, 0, Cache[client].Damage, DMG_DROWN);
	return Plugin_Continue;
}

#undef Rate
#undef Damage
