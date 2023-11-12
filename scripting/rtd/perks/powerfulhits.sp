/**
* Powerful Hits perk.
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

DEFINE_CALL_APPLY_REMOVE(PowerfulHits)

public void PowerfulHits_Init(const Perk perk)
{
	Events.OnResupply(perk, PowerfulHits_Apply);
	Events.OnEntitySpawned(perk, PowerfulHits_OnDroppedWeaponSpawn, Classname_DroppedWeapon, Retriever_AccountId);
}

public void PowerfulHits_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Multiplier = perk.GetPrefFloat("multiplier", 3.0);
	PowerfulHits_Apply(client);
}

void PowerfulHits_RemovePerk(const int client)
{
	for (int i = 0; i < 3; ++i)
	{
		int iWeapon = GetPlayerWeaponSlot(client, i);
		if (iWeapon > MaxClients && IsValidEntity(iWeapon))
			TF2Attrib_RemoveByDefIndex(iWeapon, Attribs.Damage);
	}
}

public void PowerfulHits_Apply(const int client)
{
	for (int i = 0; i < 3; ++i)
	{
		int iWeapon = GetPlayerWeaponSlot(client, i);
		if (iWeapon > MaxClients && IsValidEntity(iWeapon))
			TF2Attrib_SetByDefIndex(iWeapon, Attribs.Damage, Cache[client].Multiplier);
	}
}

public void PowerfulHits_OnDroppedWeaponSpawn(const int client, const int iEnt)
{
	AcceptEntityInput(iEnt, "Kill");
}

#undef Multiplier
