/**
* Mercs Die Twice perk.
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

#define SOUND_RESURRECT "mvm/mvm_revive.wav"
#define SOUND_RESURRECT_DENY "replay/replaydialog_warn.wav"

#define InFakeDeath Int[0]
#define BaseAlpha Int[1]
#define HealthPercentage Int[2]
#define NextResurrection Int[3]
#define Velocity(%1) Float[%1]
#define ProtectionTime Float[3]
#define Ragdoll EntSlot_1

DEFINE_CALL_APPLY_REMOVE(MercsDieTwice)

public void MercsDieTwice_Init(const Perk perk)
{
	PrecacheSound(SOUND_RESURRECT);
	PrecacheSound(SOUND_RESURRECT_DENY);

	Events.OnVoice(perk, MercsDieTwice_OnVoice)
}

void MercsDieTwice_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].InFakeDeath = false;
	Cache[client].HealthPercentage = perk.GetPrefCell("health", 80);
	Cache[client].ProtectionTime = perk.GetPrefFloat("protection", 3.0);

	SDKHook(client, SDKHook_OnTakeDamageAlive, MercsDieTwice_OnTakeDamage);
}

void MercsDieTwice_RemovePerk(const int client)
{
	if (Cache[client].InFakeDeath)
		MercsDieTwice_Resurrect(client);

	SDKUnhook(client, SDKHook_OnTakeDamageAlive, MercsDieTwice_OnTakeDamage);
}

void MercsDieTwice_OnVoice(const int client)
{
	if (!Cache[client].InFakeDeath)
		return;

	if (GetTime() < Cache[client].NextResurrection)
	{
		EmitSoundToClient(client, SOUND_RESURRECT_DENY);
		return;
	}

	MercsDieTwice_Resurrect(client);
}

public Action MercsDieTwice_OnTakeDamage(int client, int& iAttacker, int& iInflictor, float& fDamage, int& iType, int& iWeapon, float fForce[3], float fPos[3])
{
	if (Cache[client].InFakeDeath)
		return Plugin_Handled;

	if (fDamage >= GetClientHealth(client) && CanPlayerBeHurt(client, iAttacker))
	{
		SetEntityHealth(client, RoundToCeil(fDamage + 2.0));
		MercsDieTwice_FakeDeath(client, iAttacker, iInflictor, iWeapon);
	}

	return Plugin_Continue;
}

void MercsDieTwice_FakeDeath(const int client, const int iAttacker, const int iInflictor, const int iWeapon)
{
	Cache[client].InFakeDeath = true;
	Cache[client].NextResurrection = GetTime() + 3;
	g_eInGodmode.Set(client);

	float fVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);
	Cache[client].Velocity(0) = fVel[0];
	Cache[client].Velocity(1) = fVel[1];
	Cache[client].Velocity(2) = fVel[2];

	Cache[client].BaseAlpha = GetEntityAlpha(client);
	SetClientAlpha(client, 0);

	int iRag = CreateRagdoll(client);
	if (iRag > MaxClients)
	{
		Cache[client].SetEnt(Ragdoll, iRag);
		SetClientViewEntity(client, iRag);
	}

	DisarmWeapons(client, true);
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");
	TF2_AddCondition(client, TFCond_DisguisedAsDispenser);
	ApplyPreventCapture(client);

	PrintCenterText(client, "%T", "RTD2_Perk_Resurrect", LANG_SERVER, 0x03, 0x01);

	MercsDieTwice_SendDeathEvent(client, iAttacker, iInflictor, iWeapon);
}

void MercsDieTwice_Resurrect(const int client)
{
	Cache[client].InFakeDeath = false;
	g_eInGodmode.Unset(client);

	float fVec[3];
	fVec[0] = Cache[client].Velocity(0);
	fVec[1] = Cache[client].Velocity(1);
	fVec[2] = Cache[client].Velocity(2);

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVec);
	SetClientAlpha(client, Cache[client].BaseAlpha);

	DisarmWeapons(client, false);
	SetEntityMoveType(client, MOVETYPE_WALK);
	TF2_RemoveCondition(client, TFCond_DisguisedAsDispenser);
	RemovePreventCapture(client);

	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");

	SetClientViewEntity(client, client);
	Cache[client].GetEnt(Ragdoll).Kill();

	TF2_AddCondition(client, TFCond_UberchargedCanteen, Cache[client].ProtectionTime);
	EmitSoundToAll(SOUND_RESURRECT, client);

	float fMulti = float(Cache[client].HealthPercentage) / 100.0;
	float fMaxHealth = float(GetEntProp(client, Prop_Data, "m_iMaxHealth"));
	SetEntityHealth(client, RoundFloat(fMaxHealth * fMulti));

	Cache[client].HealthPercentage = MaxInt(10, RoundFloat(Cache[client].HealthPercentage * 0.75));

	MercsDieTwice_SpawnEffect(client);
}

void MercsDieTwice_SpawnEffect(const int client)
{
	int iProxy = CreateProxy(client);
	if (iProxy <= MaxClients)
		return;

	float fPos[3];
	GetClientAbsOrigin(client, fPos);

	KILL_ENT_IN(iProxy,0.7); // adjusted specifically for utaunt_elebound_yellow_parent
	SendTEParticleLingeringAttached(TEParticlesLingering.LightningSwirl, iProxy, fPos);
}

void MercsDieTwice_SendDeathEvent(const int client, const int iAttacker, const int iInflictor, const int iWeapon)
{
	Event hEvent = CreateEvent("player_death");

	int iWeaponIndex = 0;
	if (IsValidEntity(iWeapon))
	{
		iWeaponIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
	}

	hEvent.SetInt("userid", GetClientUserId(client));
	hEvent.SetInt("victim_entindex", client);
	hEvent.SetInt("inflictor_entindex", iInflictor);
	hEvent.SetInt("attacker", iAttacker == 0 ? 0 : GetClientUserId(iAttacker));
	hEvent.SetInt("weaponid", iWeapon);
	hEvent.SetInt("weapon_def_index", iWeaponIndex);
	hEvent.SetInt("death_flags", FLAG_FEIGNDEATH);

	hEvent.Fire();
}

#undef SOUND_RESURRECT
#undef SOUND_RESURRECT_DENY

#undef InFakeDeath
#undef BaseAlpha
#undef HealthPercentage
#undef NextResurrection
#undef Velocity
#undef ProtectionTime
#undef Ragdoll
