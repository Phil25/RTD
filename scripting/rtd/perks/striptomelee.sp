/**
* String to Melee perk.
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

#define MODEL_BOX "models/props_island/mannco_case_small.mdl"

#define SOUND_RESUPPLY_DENY "replay/replaydialog_warn.wav"
#define SOUND_BOX_DESTROY "ui/itemcrate_smash_ultrarare_short.wav"
#define SOUND_BOX_EXPLODE "weapons/explode3.wav"

#define IsForcedResupply Int[0]
#define OwnedWeapons Int[1]
#define LastWeaponsRemoved Int[2]
#define RefillHealth Int[3]
#define ChargeProgress Float[0]
#define FlingSpeed Float[1]
#define BoxHealth Float[2]

DEFINE_CALL_APPLY(StripToMelee)

public void StripToMelee_Init(const Perk perk)
{
	PrecacheSound(SOUND_RESUPPLY_DENY);
	PrecacheSound(SOUND_BOX_DESTROY);
	PrecacheSound(SOUND_BOX_EXPLODE);
	PrecacheModel(MODEL_BOX);

	Events.OnResupply(perk, StripToMelee_OnResupply);
}

void StripToMelee_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].IsForcedResupply = false;
	Cache[client].OwnedWeapons = 0;
	Cache[client].RefillHealth = perk.GetPrefCell("fullhealth", 1);
	Cache[client].ChargeProgress = -1.0;
	Cache[client].FlingSpeed = perk.GetPrefFloat("flingspeed", 2000.0);
	Cache[client].BoxHealth = perk.GetPrefFloat("boxhealth", 100.0); // will be round to int

	// Client isn't in roll during *_ApplyPerk functions. Let's wait a frame for that to happen.
	// We need to do this because we trigger a resupply, event of which won't run this early.
	Cache[client].Repeat(0.0, StripToMelee_ApplyPerkPost);
}

public Action StripToMelee_ApplyPerkPost(const int client)
{
	StripToMelee_ForceResupply(client, Cache[client].RefillHealth > 0); // sets LastWeaponsRemoved

	float fFlingSpeed = Cache[client].FlingSpeed;
	int iBoxHealth = RoundFloat(Cache[client].BoxHealth);

	for (int i = 0; i < Cache[client].LastWeaponsRemoved; ++i)
	{
		int iBox = StripToMelee_SpawnBox(client, i, iBoxHealth, fFlingSpeed);
		if (iBox > MaxClients)
			Cache[client].SetEnt(view_as<EntSlot>(i), iBox);
	}

	Cache[client].Repeat(0.5, StripToMelee_Ping);
	return Plugin_Stop;
}

public Action StripToMelee_Ping(const int client)
{
	TFTeam eTeam = TF2_GetClientTeam(client);

	for (int i = 0; i < 3; ++i)
	{
		int iBox = Cache[client].GetEnt(view_as<EntSlot>(i)).Index;
		if (iBox > MaxClients)
			StripToMelee_PingBox(iBox, i, eTeam);
	}

	return Plugin_Continue;
}

void StripToMelee_PingBox(const int iBox, const int iSlot, const TFTeam eTeam)
{
	float fPos[3];
	GetEntPropVector(iBox, Prop_Send, "m_vecOrigin", fPos);

	int iColor[] = {255, 255, 255, 255};
	float fLifetime = 0.5 * (3 - iSlot); // lifetime by importance

	TE_SetupBeamRingPoint(fPos, 80.0, 192.0, Materials.Laser, Materials.Halo, 0, 15, fLifetime, 5.0, 1.0, iColor, 10, 0);

	int iTotal = 0;
	int[] clients = new int[MaxClients];

	for (int i = 1; i <= MaxClients; ++i)
		if (IsClientInGame(i) && TF2_GetClientTeam(i) == eTeam)
			clients[iTotal++] = i;

	TE_Send(clients, iTotal);
}

public void StripToMelee_OnResupply(const int client)
{
	int iWeaponsRemoved = StripToMelee_StripWeapons(client);
	Cache[client].LastWeaponsRemoved = iWeaponsRemoved;

	if (!Cache[client].IsForcedResupply && iWeaponsRemoved > 0)
		EmitSoundToClient(client, SOUND_RESUPPLY_DENY);

	float fSecondaryCharge = Cache[client].ChargeProgress;
	int iSecondary = GetPlayerWeaponSlot(client, 1);

	// Apply the saved charge to the Medigun/Gas Passer if one is stored and player regained the secondary
	if (fSecondaryCharge > 0.0 && iSecondary > MaxClients)
	{
		char sClassname[32];
		GetEntityClassname(iSecondary, sClassname, sizeof(sClassname));

		if (StrEqual(sClassname, "tf_weapon_medigun"))
		{
			SetEntPropFloat(iSecondary, Prop_Send, "m_flChargeLevel", fSecondaryCharge);
			Cache[client].ChargeProgress = -1.0;
		}
		// TODO: Make this work for tf_weapon_jar_gas too, its `m_flEnergy` doesn't work
	}
}

int StripToMelee_StripWeapons(const int client)
{
	int iOwnedWeapons = Cache[client].OwnedWeapons;
	int iWeaponsRemoved = 0;

	if (!(iOwnedWeapons & (1 << 0)))
		iWeaponsRemoved += StripToMelee_RemoveWeaponSlotIfExists(client, 0);

	if (!(iOwnedWeapons & (1 << 1)))
		iWeaponsRemoved += StripToMelee_RemoveWeaponSlotIfExists(client, 1);

	if (!(iOwnedWeapons & (1 << 2)))
		iWeaponsRemoved += StripToMelee_RemoveWeaponSlotsIfExist(client, 3, 4);

	if (iWeaponsRemoved == 0)
	{
		// Can do nothing on full Demoknight, who only has melee. The perk will either run its time
		// or be removed once a resupply cabinet is touched.
		ForceRemovePerk(client);
		return 0;
	}

	SwitchToFirstValidWeapon(client);

	return iWeaponsRemoved;
}

int StripToMelee_RemoveWeaponSlotIfExists(const int client, const int iSlot)
{
	int iWeap = GetPlayerWeaponSlot(client, iSlot);
	if (iWeap <= MaxClients)
		return 0;

	// Save Medigun/Gas Passer charge, but do not overwrite if it's already stored
	if (iSlot == 1 && Cache[client].ChargeProgress < 0.0)
	{
		char sClassname[32];
		GetEntityClassname(iWeap, sClassname, sizeof(sClassname));

		if (StrEqual(sClassname, "tf_weapon_medigun"))
			Cache[client].ChargeProgress = GetEntPropFloat(iWeap, Prop_Send, "m_flChargeLevel");
	}

	TF2_RemoveWeaponSlot(client, iSlot);
	return 1;
}

int StripToMelee_RemoveWeaponSlotsIfExist(const int client, const int iSlot1, const int iSlot2)
{
	int iSlot1Removed = StripToMelee_RemoveWeaponSlotIfExists(client, iSlot1);
	int iSlot2Removed = StripToMelee_RemoveWeaponSlotIfExists(client, iSlot2);
	return view_as<int>(iSlot1Removed || iSlot2Removed);
}

int StripToMelee_SpawnBox(const int client, const int iSlot, const int iHealth, const float fSpeed)
{
	int iBox = CreateEntityByName("prop_physics_override");
	if (iBox <= MaxClients) return -1;

	// 4 -- debris
	// 4096 -- debris with trigger interaction
	DispatchKeyValue(iBox, "spawnflags", "4100");
	DispatchKeyValue(iBox, "model", MODEL_BOX);
	DispatchKeyValue(iBox, "skin", "1"); // whiteish

	DispatchSpawn(iBox);

	SetEntProp(iBox, Prop_Data, "m_iMaxHealth", (client << 3) | (1 << iSlot)); // m_iMaxHealth not used for anything
	SetEntProp(iBox, Prop_Data, "m_iHealth", iHealth);

	SDKHook(iBox, SDKHook_OnTakeDamage, StripToMelee_OnBoxTakeDamage);

	float fAng[3], fPos[3], fVel[3], fVelAng[3], fBuf[3];
	GetClientEyeAngles(client, fAng);
	GetClientEyePosition(client, fPos);
	GetAngleVectors(fAng, fBuf, NULL_VECTOR, NULL_VECTOR);

	fVel[0] = fBuf[0] * fSpeed;
	fVel[1] = fBuf[1] * fSpeed;
	fVel[2] = fBuf[2] * fSpeed;

	fVelAng[0] = GetRandomFloat(-fSpeed, fSpeed);
	fVelAng[1] = GetRandomFloat(-fSpeed, fSpeed);
	fVelAng[2] = GetRandomFloat(-fSpeed, fSpeed);

	switch (TF2_GetClientTeam(client))
	{
		case TFTeam_Blue:
		{
			DispatchKeyValue(iBox, "rendercolor", "150 150 255");
			SendTEParticleAttached(TEParticles.PickupTrailBlue, iBox);
		}

		case TFTeam_Red:
		{
			DispatchKeyValue(iBox, "rendercolor", "255 150 150");
			SendTEParticleAttached(TEParticles.PickupTrailRed, iBox);
		}
	}

	TeleportEntity(iBox, fPos, fVelAng, fVel);

	return iBox;
}

public Action StripToMelee_OnBoxTakeDamage(int iBox, int& iAtk, int& iInflictor, float& fDamage, int& iType, int& iWeapon, float fForce[3], float fPos[3])
{
	if (!(1 <= iAtk <= MaxClients))
		return Plugin_Continue; // prop_physics_override can get hurt by world

	int iClientAndSlot = GetEntProp(iBox, Prop_Data, "m_iMaxHealth");
	int client = iClientAndSlot >> 3;

	if (TF2_GetClientTeam(client) != TF2_GetClientTeam(iAtk))
	{
		fForce[0] *= 80;
		fForce[1] *= 80;
		fForce[2] *= 120;
		fDamage = 0.0;
		return Plugin_Changed;
	}

	int iHealth = GetEntProp(iBox, Prop_Data, "m_iHealth") - RoundFloat(fDamage);
	if (iHealth > 0)
	{
		SetEntProp(iBox, Prop_Data, "m_iHealth", iHealth);

		fForce[0] *= 40;
		fForce[1] *= 40;
		fForce[2] *= 40;

		SendTEParticleAttached(TEParticles.BulletImpactHeavier, iBox);

		return Plugin_Changed;
	}

	int iOwnedWeapons = Cache[client].OwnedWeapons;
	for (int i = 0; i < 3; ++i)
		iOwnedWeapons |= (iClientAndSlot & (1 << i));

	Cache[client].OwnedWeapons = iOwnedWeapons;
	StripToMelee_ForceResupply(client, Cache[client].RefillHealth > 0);

	float fBoxPos[3];
	GetEntPropVector(iBox, Prop_Send, "m_vecOrigin", fBoxPos);
	SendTEParticle(TEParticles.LootExplosion, fBoxPos);

	AcceptEntityInput(iBox, "Kill");
	EmitSoundToClient(client, SOUND_BOX_DESTROY);
	EmitSoundToAll(SOUND_BOX_EXPLODE, iBox);

	if (iAtk != client)
	{
		EmitSoundToClient(iAtk, SOUND_BOX_DESTROY);
		StripToMelee_Resupply(iAtk, Cache[client].RefillHealth > 0);
	}

	return Plugin_Continue;
}

void StripToMelee_Resupply(const int client, const bool bRefillHealth)
{
	int iHealth = GetClientHealth(client);

	TF2_RegeneratePlayer(client);

	if (!bRefillHealth)
		SetEntityHealth(client, iHealth);
}

void StripToMelee_ForceResupply(const int client, const bool bRefillHealth)
{
	Cache[client].IsForcedResupply = true;
	StripToMelee_Resupply(client, bRefillHealth);
	Cache[client].IsForcedResupply = false;
}

#undef MODEL_BOX

#undef SOUND_RESUPPLY_DENY
#undef SOUND_BOX_DESTROY
#undef SOUND_BOX_EXPLODE

#undef IsForcedResupply
#undef OwnedWeapons
#undef LastWeaponsRemoved
#undef RefillHealth
#undef ChargeProgress
#undef FlingSpeed
#undef BoxHealth
