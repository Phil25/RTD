/**
* Homing Projectiles perk.
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

#define Crits Int[0]

DEFINE_CALL_APPLY_REMOVE(HomingProjectiles)

public void HomingProjectiles_Init(const Perk perk)
{
	Events.OnEntitySpawned(perk, HomingProjectiles_OnEntitySpawned, Homing_AptClass, Retriever_OwnerEntity);
}

void HomingProjectiles_ApplyPerk(const int client, const Perk perk)
{
	int iCrits = perk.GetPrefCell("crits");
	Cache[client].Crits = iCrits;

	if (iCrits > 0)
		TF2_AddCondition(client, iCrits < 2 ? TFCond_Buffed : TFCond_CritOnFirstBlood);
}

void HomingProjectiles_RemovePerk(const int client)
{
	int iCrits = Cache[client].Crits;
	if (iCrits > 0)
		TF2_RemoveCondition(client, iCrits < 2 ? TFCond_Buffed : TFCond_CritOnFirstBlood);
}

void HomingProjectiles_OnEntitySpawned(const int client, const int iEntity)
{
	Homing_Push(iEntity);
}

#undef Crits
