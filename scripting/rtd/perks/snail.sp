/**
* Snail perk.
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

DEFINE_CALL_APPLY_REMOVE(Snail)

public void Snail_ApplyPerk(const int client, const Perk perk)
{
	SetSpeedEx(client, perk.GetPrefFloat("multiplier", 0.4));
}

public void Snail_RemovePerk(const int client, const RTDRemoveReason eRemoveReason)
{
	SetSpeedEx(client);
}
