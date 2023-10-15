/**
* String to Melee perk.
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


#define MODEL_BOX "models/props_island/mannco_case_small.mdl"

#define SOUND_RESUPPLY_DENY "replay/replaydialog_warn.wav"
#define SOUND_BOX_DESTROY "ui/itemcrate_smash_ultrarare_short.wav"
#define SOUND_BOX_EXPLODE "weapons/explode3.wav"

#define IS_FORCED_RESUPPLY 0
#define OWNED_WEAPONS 1
#define LAST_WEAPONS_REMOVED 2
#define REFILL_HEALTH 3

#define CHARGE_PROGRESS 0

int g_iStripToMeleeId = 23;

void StripToMelee_Start(){
	PrecacheSound(SOUND_RESUPPLY_DENY);
	PrecacheSound(SOUND_BOX_DESTROY);
	PrecacheSound(SOUND_BOX_EXPLODE);
	PrecacheModel(MODEL_BOX);
}

public void StripToMelee_Call(int client, Perk perk, bool apply){
	if(apply) StripToMelee_ApplyPerk(client, perk);
	else StripToMelee_RemovePerk(client);
}

void StripToMelee_ApplyPerk(int client, Perk perk){
	g_iStripToMeleeId = perk.Id;
	SetClientPerkCache(client, g_iStripToMeleeId);

	SetIntCache(client, false, IS_FORCED_RESUPPLY);
	SetIntCache(client, 0, OWNED_WEAPONS);
	SetIntCache(client, perk.GetPrefCell("fullhealth"), REFILL_HEALTH);

	SetFloatCache(client, -1.0, CHARGE_PROGRESS);

	StripToMelee_ForceResupply(client, GetIntCacheBool(client, REFILL_HEALTH)); // sets LAST_WEAPONS_REMOVED
	int iWeaponsRemoved = GetIntCache(client, LAST_WEAPONS_REMOVED);
	int iBoxHealth = perk.GetPrefCell("boxhealth", 100);
	float fFlingSpeed = perk.GetPrefFloat("flingspeed", 2000.0);

	for(int i = 0; i < iWeaponsRemoved; ++i){
		int iBox = StripToMelee_SpawnBox(client, i, iBoxHealth, fFlingSpeed);
		if(iBox > MaxClients)
			SetEntCache(client, iBox, i);
	}

	CreateTimer(0.5, Timer_StripToMeleeBeep, GetClientUserId(client), TIMER_REPEAT);
}

void StripToMelee_RemovePerk(int client){
	UnsetClientPerkCache(client, g_iStripToMeleeId);

	for(int i = 0; i < 3; ++i)
		KillEntCache(client, i);
}

void StripToMelee_Resupply(int client, bool bRefillHealth){
	int iHealth = GetClientHealth(client);

	TF2_RegeneratePlayer(client);

	if(!bRefillHealth)
		SetEntityHealth(client, iHealth);
}

void StripToMelee_ForceResupply(int client, bool bRefillHealth){
	SetIntCache(client, true, IS_FORCED_RESUPPLY);
	StripToMelee_Resupply(client, bRefillHealth);
	SetIntCache(client, false, IS_FORCED_RESUPPLY);
}

public Action Timer_StripToMeleeBeep(Handle hTimer, const int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client)
		return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iStripToMeleeId))
		return Plugin_Stop;

	for(int i = 0; i < 3; ++i){
		int iBox = GetEntCache(client, i);
		if(iBox > MaxClients)
			StripToMelee_BeepBox(iBox, i);
	}

	return Plugin_Continue;
}

void StripToMelee_BeepBox(int iBox, int iSlot){
	float fPos[3];
	GetEntPropVector(iBox, Prop_Send, "m_vecOrigin", fPos);

	int iColor[] = {255, 255, 255, 255};
	float fLifetime = 0.5 * (3 - iSlot); // lifetime by importance

	TE_SetupBeamRingPoint(fPos, 80.0, 192.0, GetEntMaterial().iLaser, GetEntMaterial().iHalo, 0, 15, fLifetime, 5.0, 1.0, iColor, 10, 0);
	TE_SendToAll();
}

void StripToMelee_OnResupply(int client){
	if(!CheckClientPerkCache(client, g_iStripToMeleeId))
		return;

	int iWeaponsRemoved = StripToMelee_StripWeapons(client);
	SetIntCache(client, iWeaponsRemoved, LAST_WEAPONS_REMOVED);

	if(!GetIntCacheBool(client, IS_FORCED_RESUPPLY) && iWeaponsRemoved > 0)
		EmitSoundToClient(client, SOUND_RESUPPLY_DENY);

	float fSecondaryCharge = GetFloatCache(client, CHARGE_PROGRESS);
	int iSecondary = GetPlayerWeaponSlot(client, 1);

	// Apply the saved charge to the Medigun/Gas Passer if one is stored and player regained the secondary
	if(fSecondaryCharge > 0.0 && iSecondary > MaxClients){
		char sClassname[32];
		GetEntityClassname(iSecondary, sClassname, sizeof(sClassname));

		if(StrEqual(sClassname, "tf_weapon_medigun")){
			SetEntPropFloat(iSecondary, Prop_Send, "m_flChargeLevel", fSecondaryCharge);
			SetFloatCache(client, -1.0, CHARGE_PROGRESS);
		}
		// TODO: Make this work for tf_weapon_jar_gas too, its `m_flEnergy` doesn't work
	}
}

int StripToMelee_StripWeapons(int client){
	int iOwnedWeapons = GetIntCache(client, OWNED_WEAPONS);
	int iWeaponsRemoved = 0;

	if(!(iOwnedWeapons & (1 << 0)))
		iWeaponsRemoved += StripToMelee_RemoveWeaponSlotIfExists(client, 0);

	if(!(iOwnedWeapons & (1 << 1)))
		iWeaponsRemoved += StripToMelee_RemoveWeaponSlotIfExists(client, 1);

	if(!(iOwnedWeapons & (1 << 2)))
		iWeaponsRemoved += StripToMelee_RemoveWeaponSlotsIfExist(client, 3, 4);

	if(iWeaponsRemoved == 0){
		// Can do nothing on full Demoknight, who only has melee. The perk will either run its time
		// or be removed once a resupply cabinet is touched.
		ForceRemovePerk(client);
		return 0;
	}

	SwitchToFirstValidWeapon(client);

	return iWeaponsRemoved;
}

int StripToMelee_RemoveWeaponSlotIfExists(int client, int iSlot){
	int iWeap = GetPlayerWeaponSlot(client, iSlot);
	if(iWeap <= MaxClients)
		return 0;

	// Save Medigun/Gas Passer charge, but do not overwrite if it's already stored
	if(iSlot == 1 && GetFloatCache(client, CHARGE_PROGRESS) < 0.0){
		char sClassname[32];
		GetEntityClassname(iWeap, sClassname, sizeof(sClassname));

		if(StrEqual(sClassname, "tf_weapon_medigun"))
			SetFloatCache(client, GetEntPropFloat(iWeap, Prop_Send, "m_flChargeLevel"), CHARGE_PROGRESS);
	}

	TF2_RemoveWeaponSlot(client, iSlot);
	return 1;
}

int StripToMelee_RemoveWeaponSlotsIfExist(int client, int iSlot1, int iSlot2){
	int iSlot1Removed = StripToMelee_RemoveWeaponSlotIfExists(client, iSlot1);
	int iSlot2Removed = StripToMelee_RemoveWeaponSlotIfExists(client, iSlot2);
	return view_as<int>(iSlot1Removed || iSlot2Removed);
}

int StripToMelee_SpawnBox(int client, int iSlot, int iHealth, float fSpeed){
	int iBox = CreateEntityByName("prop_physics_override");
	if(iBox <= MaxClients) return -1;

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

	switch(TF2_GetClientTeam(client)){
		case TFTeam_Blue:{
			DispatchKeyValue(iBox, "rendercolor", "150 150 255");
			SendTEParticleAttached(TEParticle_PickupTrailBlue, iBox);
		}
		case TFTeam_Red:{
			DispatchKeyValue(iBox, "rendercolor", "255 150 150");
			SendTEParticleAttached(TEParticle_PickupTrailRed, iBox);
		}
	}

	TeleportEntity(iBox, fPos, fVelAng, fVel);

	return iBox;
}

public Action StripToMelee_OnBoxTakeDamage(int iBox, int &iAtk, int &iInflictor, float &fDamage, int &iType, int &iWeapon, float fForce[3], float fPos[3]){
	if(!(1 <= iAtk <= MaxClients))
		return Plugin_Continue; // prop_physics_override can get hurt by world

	int iClientAndSlot = GetEntProp(iBox, Prop_Data, "m_iMaxHealth");
	int client = iClientAndSlot >> 3;

	if(TF2_GetClientTeam(client) != TF2_GetClientTeam(iAtk))
		return Plugin_Continue;

	int iHealth = GetEntProp(iBox, Prop_Data, "m_iHealth") - RoundFloat(fDamage);
	if(iHealth > 0){
		SetEntProp(iBox, Prop_Data, "m_iHealth", iHealth);

		fForce[0] *= 40;
		fForce[1] *= 40;
		fForce[2] *= 40;

		SendTEParticleAttached(TEParticle_BulletImpactHeavier, iBox);

		return Plugin_Changed;
	}

	int iOwnedWeapons = GetIntCache(client, OWNED_WEAPONS);
	for(int i = 0; i < 3; ++i)
		iOwnedWeapons |= (iClientAndSlot & (1 << i));

	SetIntCache(client, iOwnedWeapons, OWNED_WEAPONS);
	StripToMelee_ForceResupply(client, GetIntCacheBool(client, REFILL_HEALTH));

	float fBoxPos[3];
	GetEntPropVector(iBox, Prop_Send, "m_vecOrigin", fBoxPos);
	SendTEParticle(TEParticle_LootExplosion, fBoxPos);

	AcceptEntityInput(iBox, "Kill");
	EmitSoundToClient(client, SOUND_BOX_DESTROY);
	EmitSoundToAll(SOUND_BOX_EXPLODE, iBox);

	if(iAtk != client){
		EmitSoundToClient(iAtk, SOUND_BOX_DESTROY);
		StripToMelee_Resupply(iAtk, GetIntCacheBool(client, REFILL_HEALTH));
	}

	return Plugin_Continue;
}

#undef MODEL_BOX

#undef SOUND_RESUPPLY_DENY
#undef SOUND_BOX_DESTROY
#undef SOUND_BOX_EXPLODE

#undef IS_FORCED_RESUPPLY
#undef OWNED_WEAPONS
#undef LAST_WEAPONS_REMOVED
#undef REFILL_HEALTH

#undef CHARGE_PROGRESS
