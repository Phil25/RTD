/**
* Infinite Ammo perk.
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

#define NoReload Int[0]
#define Weapon Int[1]
#define Clip Int[2]
#define Ammo Int[3]

DEFINE_CALL_APPLY(InfiniteAmmo)

public void InfiniteAmmo_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].NoReload = perk.GetPrefCell("reload", 0) < 1;
	Cache[client].Repeat(0.25, InfiniteAmmo_ResupplyAmmo);
}

public Action InfiniteAmmo_ResupplyAmmo(const int client)
{
	switch (TF2_GetPlayerClass(client))
	{
		case TFClass_Engineer:
			SetEntProp(client, Prop_Data, "m_iAmmo", 200, 4, 3);

		case TFClass_Spy:
			SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 105.0);
	}

	int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (iWeapon <= MaxClients || !IsValidEntity(iWeapon))
		return Plugin_Continue;

	switch (GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		case 441, 442, 588:
			SetEntPropFloat(iWeapon, Prop_Send, "m_flEnergy", 20.0);

		case 307: // caber
		{
			SetEntProp(iWeapon, Prop_Send, "m_bBroken", 0);
			SetEntProp(iWeapon, Prop_Send, "m_iDetonated", 0);
		}

		default:
		{
			if (Cache[client].Weapon != iWeapon)
			{
				Cache[client].Weapon = iWeapon;
				Cache[client].Clip = GetClip(iWeapon);
				Cache[client].Ammo = GetAmmo(client, iWeapon);
			}
			else
			{
				int iClip = Cache[client].NoReload ? GetClip(iWeapon) : -1;
				if (iClip > -1)
				{
					if (iClip > Cache[client].Clip)
					{
						Cache[client].Clip = iClip;
					}
					else if (iClip < Cache[client].Clip)
					{
						SetClip(iWeapon, Cache[client].Clip);
					}
				}

				int iAmmo = GetAmmo(client, iWeapon);
				if (iAmmo > -1)
				{
					if (iAmmo > Cache[client].Ammo)
					{
						Cache[client].Ammo = iAmmo;
					}
					else if (iAmmo < Cache[client].Ammo)
					{
						SetAmmo(client, iWeapon, Cache[client].Ammo);
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

#define NoReload Int[0]
#define Weapon Int[1]
#define Clip Int[2]
#define Ammo Int[3]
