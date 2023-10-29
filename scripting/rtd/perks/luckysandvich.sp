/**
* Lucky Sandvich perk.
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

ClientFlags g_bLuckySandvichCrit;

DEFINE_CALL_APPLY(LuckySandvich)

public void LuckySandvich_Init(const Perk perk)
{
	Events.OnAttackCritCheck(perk, LuckySandvich_AttackCritCheck_Any, SubscriptionType_Any);
}

void LuckySandvich_ApplyPerk(const int client, const Perk perk)
{
	g_bLuckySandvichCrit.Set(client);

	int iHealth = perk.GetPrefCell("amount", 1000);
	SetEntityHealth(client, GetEntProp(client, Prop_Data, "m_iHealth") + iHealth);
}

public bool LuckySandvich_AttackCritCheck_Any(const int client, const int iWeapon)
{
	if (!g_bLuckySandvichCrit.Test(client))
		return false;

	g_bLuckySandvichCrit.Unset(client);
	return true;
}
