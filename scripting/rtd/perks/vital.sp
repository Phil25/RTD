/**
* Vital perk.
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

DEFINE_CALL_APPLY_REMOVE(Vital)

public void Vital_ApplyPerk(const int client, const Perk perk)
{
	int iAddedHealth = perk.GetPrefCell("health", 300);

	TF2Attrib_SetByDefIndex(client, Attribs.MaxHealth, float(iAddedHealth));
	SetEntityHealth(client, GetClientHealth(client) + iAddedHealth);
}

public void Vital_RemovePerk(int client)
{
	TF2Attrib_RemoveByDefIndex(client, Attribs.MaxHealth);
}
