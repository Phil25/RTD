/**
* Extra Ammo perk.
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

DEFINE_CALL_APPLY(ExtraAmmo)

public void ExtraAmmo_ApplyPerk(const int client, const Perk perk)
{
	float fMultiplier = perk.GetPrefFloat("multiplier", 5.0);

	for (int i = 0; i < 2; ++i)
	{
		int iWeapon = GetPlayerWeaponSlot(client, i);
		if (iWeapon > MaxClients && IsValidEntity(iWeapon))
			ExtraAmmo_MultiplyAmmo(client, iWeapon, fMultiplier);
	}
}

void ExtraAmmo_MultiplyAmmo(const int client, const int iWeapon, const float fMulti)
{
	switch (GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		case 441, 442, 588:
		{
			SetEntPropFloat(iWeapon, Prop_Send, "m_flEnergy", 20.0 * fMulti);
		}

		default:
		{
			int iMulti = RoundFloat(fMulti);

			int iClip = GetClip(iWeapon);
			if (iClip > -1)
				SetClip(iWeapon, iClip < 1 ? iMulti : RoundFloat(float(iClip) * fMulti));

			int iAmmo = GetAmmo(client, iWeapon);
			if (iAmmo > -1)
				SetAmmo(client, iWeapon, iAmmo < 1 ? iMulti : RoundFloat(float(iAmmo) * fMulti));
		}
	}
}
