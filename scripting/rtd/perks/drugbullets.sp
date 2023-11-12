/**
* Drug Bullets perk.
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

#define MinDamage Int[0]
#define NextStun Float[0]

DEFINE_CALL_APPLY(DrugBullets)

public void DrugBullets_Init(const Perk perk)
{
	Events.OnPlayerAttacked(perk, DrugBullets_OnPlayerAttacked);
}

public void DrugBullets_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].MinDamage = perk.GetPrefCell("min_damage", 5);
	Cache[client].NextStun = GetEngineTime() + 1.0;
}

public void DrugBullets_OnPlayerAttacked(const int client, const int iVictim, const int iDamage, const int iRemainingHealth)
{
	if (iRemainingHealth <= 0)
		return

	if (iDamage < Cache[client].MinDamage)
		return;

	float fTime = GetEngineTime();
	if (Cache[client].NextStun > fTime)
	{
		ViewPunchRand(iVictim, 15.0);
		return;
	}

	Drugged_Tick(iVictim); // from Drugged perk
	TF2_StunPlayer(iVictim, 0.1, _, TF_STUNFLAG_THIRDPERSON, client);

	Cache[client].NextStun = fTime + 1.0;
}

#undef MinDamage
#undef NextStun
