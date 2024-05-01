/**
* Weapon Mixup perk.
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

#define Ticks Int[0]

DEFINE_CALL_APPLY_REMOVE(WeaponMixup)

public void WeaponMixup_Init(const Perk perk)
{
	Events.OnResupply(perk, WeaponMixup_Apply);
	Events.OnAttackCritCheck(perk, WeaponMixup_OnAttackCritCheck);
	Events.OnEntitySpawned(perk, WeaponMixup_OnDroppedWeaponSpawn, Classname_DroppedWeapon, Retriever_AccountId);
}

public void WeaponMixup_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Ticks = 2;

	WeaponMixup_Apply(client);

	Cache[client].Repeat(0.5, WeaponMixup_SwitchTick);
}

public void WeaponMixup_RemovePerk(const int client, const RTDRemoveReason eRemoveReason)
{
	// If Heavy was revved up, this should fix it lingering
	TF2_RemoveCondition(client, TFCond_Slowed);

	for (int i = 0; i < 3; ++i)
	{
		int iWeapon = GetPlayerWeaponSlot(client, i);
		if (iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;

		TF2Attrib_RemoveByDefIndex(iWeapon, Attribs.DeploySpeed);
		TF2Attrib_RemoveByDefIndex(iWeapon, Attribs.ReloadSpeed);
		TF2Attrib_RemoveByDefIndex(iWeapon, Attribs.SilentRev);
	}
}

void WeaponMixup_Apply(const int client)
{
	for (int i = 0; i < 3; ++i)
	{
		int iWeapon = GetPlayerWeaponSlot(client, i);
		if (iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;

		TF2Attrib_SetByDefIndex(iWeapon, Attribs.DeploySpeed, 0.5);
		TF2Attrib_SetByDefIndex(iWeapon, Attribs.ReloadSpeed, 0.1);
		TF2Attrib_SetByDefIndex(iWeapon, Attribs.SilentRev, 1.0);
	}
}

public void WeaponMixup_OnDroppedWeaponSpawn(const int client, const int iEnt)
{
	AcceptEntityInput(iEnt, "Kill");
}

Action WeaponMixup_SwitchTick(const int client)
{
	if (--Cache[client].Ticks > 0)
		return Plugin_Continue;

	Cache[client].Ticks = 2;

	int iCurrentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	int iNextSlot = WeaponMixup_GetNextSlot(client, iCurrentWeapon);

	if (!SwitchSlot(client, iNextSlot))
	{
		// If switch failed, assume next slot is recharing and fallback to melee
		if (!SwitchSlot(client, 2))
		{
			// If failed again, assume client state is blocking (ex. revved up) then force switch
			ForceSwitchSlot(client, 2);
		}
	}

	return Plugin_Continue;
}

bool WeaponMixup_OnAttackCritCheck(const int client, const int iWeapon)
{
	Cache[client].Ticks = 0;
	return false;
}

int WeaponMixup_GetNextSlot(const int client, const int iCurrentWeapon)
{
	static int iSlotOrder[] = {0, 1, 2, 0, 1, 2};
	int iCurrentSlot = 0;

	for (; iCurrentSlot < 3; ++iCurrentSlot)
		if (GetPlayerWeaponSlot(client, iCurrentSlot) == iCurrentWeapon)
			break;

	int iNextSlotId = iCurrentSlot + 1;
	for (; iNextSlotId < sizeof(iSlotOrder); ++iNextSlotId)
		if (GetPlayerWeaponSlot(client, iSlotOrder[iNextSlotId]) > MaxClients)
			break;

	return iNextSlotId >= sizeof(iSlotOrder) ? iCurrentSlot : iSlotOrder[iNextSlotId];
}

#undef Ticks
