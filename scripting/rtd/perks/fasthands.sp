/**
* Fast Hands perk.
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

#define Attack Float[0]
#define Reload Float[1]

DEFINE_CALL_APPLY_REMOVE(FastHands)

public void FastHands_Init(const Perk perk)
{
	Events.OnResupply(perk, FastHands_Apply);
	Events.OnEntitySpawned(perk, FastHands_OnDroppedWeaponSpawn, Classname_DroppedWeapon, Retriever_AccountId);
}

public void FastHands_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Attack = 1.0 / perk.GetPrefFloat("attack", 2.0);
	Cache[client].Reload = 1.0 / perk.GetPrefFloat("reload", 2.0);

	FastHands_Apply(client);
}

void FastHands_RemovePerk(const int client)
{
	for (int i = 0; i < 3; ++i)
	{
		int iWeapon = GetPlayerWeaponSlot(client, i);
		if (iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;

		TF2Attrib_RemoveByDefIndex(iWeapon, Attribs.FireRate);
		TF2Attrib_RemoveByDefIndex(iWeapon, Attribs.ReloadSpeed);
	}
}

public void FastHands_Apply(const int client)
{
	for (int i = 0; i < 3; ++i)
	{
		int iWeapon = GetPlayerWeaponSlot(client, i);
		if (iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;

		TF2Attrib_SetByDefIndex(iWeapon, Attribs.FireRate, Cache[client].Attack);
		TF2Attrib_SetByDefIndex(iWeapon, Attribs.ReloadSpeed, Cache[client].Reload);
	}

}

public void FastHands_OnDroppedWeaponSpawn(const int client, const int iEnt)
{
	AcceptEntityInput(iEnt, "Kill");
}

#undef Attack
#undef Reload
