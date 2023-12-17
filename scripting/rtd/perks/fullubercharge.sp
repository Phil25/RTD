/**
* Full Ubercharge perk.
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

#define UberchargeDeployed Int[0]
#define MedigunEffect Int[1]
#define CarriedMedigun EntSlot_1

ClientFlags g_eFullUberchargeExtendUbercharge;
ClientFlags g_eFullUberchargeExtendKritzkrieg;
ClientFlags g_eFullUberchargeExtendMegaHeal;

DEFINE_CALL_APPLY_REMOVE(FullUbercharge)

public void FullUbercharge_Init(const Perk perk)
{
	Events.OnConditionRemoved(perk, FullUbercharge_OnConditionRemoved, SubscriptionType_Any);
	Events.OnUberchargeDeployed(perk, FullUbercharge_OnUberchargeDeployed);
}

public void FullUbercharge_ApplyPerk(const int client, const Perk perk)
{
	int iMedigun = GetPlayerWeaponSlot(client, 1);
	if (iMedigun <= MaxClients || !IsValidEntity(iMedigun))
		return;

	char sClass[20];
	GetEdictClassname(iMedigun, sClass, sizeof(sClass));
	if (strcmp(sClass, "tf_weapon_medigun") != 0) // failsafe
		return;

	switch (GetEntProp(iMedigun, Prop_Send, "m_iItemDefinitionIndex"))
	{
		case 35:
			Cache[client].MedigunEffect = view_as<int>(TFCond_Kritzkrieged);

		case 411:
			Cache[client].MedigunEffect = view_as<int>(TFCond_MegaHeal);

		case 998:
			Cache[client].MedigunEffect = -1;

		default:
			Cache[client].MedigunEffect = view_as<int>(TFCond_Ubercharged);
	}

	g_eFullUberchargeExtendUbercharge.Unset(client);
	g_eFullUberchargeExtendKritzkrieg.Unset(client);
	g_eFullUberchargeExtendMegaHeal.Unset(client);

	Cache[client].UberchargeDeployed = false;
	Cache[client].SetEnt(CarriedMedigun, iMedigun, EntCleanup_None);
	Cache[client].Repeat(0.1, FullUbercharge_RefillCharge);
}

public void FullUbercharge_RemovePerk(const int client)
{
	if (!Cache[client].UberchargeDeployed)
		return;

	if (Cache[client].MedigunEffect <= 0)
		return;

	DataPack hData = new DataPack();
	hData.WriteCell(GetClientUserId(client));
	hData.WriteCell(Cache[client].GetEnt(CarriedMedigun).Reference);
	hData.WriteCell(Cache[client].MedigunEffect);

	CreateTimer(0.2, Timer_FullUbercharge_ExtendCharge, hData, TIMER_REPEAT | TIMER_DATA_HNDL_CLOSE);
}

public Action FullUbercharge_RefillCharge(const int client)
{
	int iMedigun = Cache[client].GetEnt(CarriedMedigun).Index;
	if (iMedigun <= MaxClients)
		return Plugin_Stop;

	SetEntPropFloat(iMedigun, Prop_Send, "m_flChargeLevel", 1.0);

	return Plugin_Continue;
}

public void FullUbercharge_OnUberchargeDeployed(const int client, const int iTarget)
{
	switch (view_as<TFCond>(Cache[client].MedigunEffect))
	{
		case TFCond_Ubercharged:
			g_eFullUberchargeExtendUbercharge.Set(client);

		case TFCond_Kritzkrieged:
			g_eFullUberchargeExtendKritzkrieg.Set(client);

		case TFCond_MegaHeal:
			g_eFullUberchargeExtendMegaHeal.Set(client);
	}

	Cache[client].UberchargeDeployed = true;
}

public Action Timer_FullUbercharge_ExtendCharge(Handle hTimer, DataPack hData)
{
	hData.Reset();

	int client = GetClientOfUserId(hData.ReadCell());
	if (!client)
		return Plugin_Stop;

	int iMedigun = EntRefToEntIndex(hData.ReadCell());
	if (iMedigun > MaxClients && GetEntPropFloat(iMedigun, Prop_Send, "m_flChargeLevel") > 0.05)
		return Plugin_Continue;

	switch (view_as<TFCond>(hData.ReadCell()))
	{
		case TFCond_Ubercharged:
			g_eFullUberchargeExtendUbercharge.Unset(client);

		case TFCond_Kritzkrieged:
			g_eFullUberchargeExtendKritzkrieg.Unset(client);

		case TFCond_MegaHeal:
			g_eFullUberchargeExtendMegaHeal.Unset(client);
	}

	return Plugin_Stop;
}

public void FullUbercharge_OnConditionRemoved(const int client, const TFCond eCondition)
{
	switch (eCondition)
	{
		case TFCond_Ubercharged:
			if (g_eFullUberchargeExtendUbercharge.Test(client))
				TF2_AddCondition(client, eCondition, 2.0);

		case TFCond_Kritzkrieged:
			if (g_eFullUberchargeExtendKritzkrieg.Test(client))
				TF2_AddCondition(client, eCondition, 2.0);

		case TFCond_MegaHeal:
			if (g_eFullUberchargeExtendMegaHeal.Test(client))
				TF2_AddCondition(client, eCondition, 2.0);
	}
}

#undef UberchargeDeployed
#undef MedigunEffect
#undef CarriedMedigun
