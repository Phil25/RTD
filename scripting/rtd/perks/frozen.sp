/**
* Frozen perk.
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


#define ENT_STATUE 0
#define ENT_ICE 1

#define SOUND_FREEZE "weapons/icicle_freeze_victim_01.wav"
#define SOUND_ICE_IMPACT "physics/glass/glass_impact_bullet1.wav"
#define SOUND_ICE_BREAK "physics/glass/glass_largesheet_break1.wav"

#define ICE_STATUE "models/props_moonbase/moon_cube_crystal07.mdl"

#define ORIGINAL_ALPHA 0
#define NEEDS_RESUPPLY 1
#define RESULTING_HEALTH 2

#define LAST_FIRE_TOUCH 0
#define LAST_DAMAGE_TAKEN 1
#define FROZEN_RESISTANCE 2
#define FLAME_BUFF 3

#define DETACH_GROUND_DISTANCE 5.0

int g_iFrozenId = 17;

void Frozen_Start(){
	PrecacheSound(SOUND_FREEZE);
	PrecacheSound(SOUND_ICE_IMPACT);
	PrecacheSound(SOUND_ICE_BREAK);
	PrecacheModel(ICE_STATUE);
}

public void Frozen_Call(int client, Perk perk, bool apply){
	if(apply) Frozen_ApplyPerk(client, perk);
	else Frozen_RemovePerk(client);
}

void Frozen_ApplyPerk(int client, Perk perk){
	g_iFrozenId = perk.Id;
	SetClientPerkCache(client, g_iFrozenId);

	SetIntCache(client, Frozen_GetEntityAlpha(client), ORIGINAL_ALPHA);
	SetIntCache(client, false, NEEDS_RESUPPLY);
	SetFloatCache(client, 0.0, LAST_FIRE_TOUCH);
	SetFloatCache(client, 0.0, LAST_DAMAGE_TAKEN);
	SetFloatCache(client, perk.GetPrefFloat("resistance", 0.1), FROZEN_RESISTANCE);
	SetFloatCache(client, perk.GetPrefFloat("flame_buff", 5.0), FLAME_BUFF);

	DisarmWeapons(client, true);
	ApplyPreventCapture(client);
	TF2_RemoveCondition(client, TFCond_OnFire); // remove afterburn

	SetEntityMoveType(client, MOVETYPE_NONE);
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");

	SDKHook(client, SDKHook_OnTakeDamage, Frozen_OnTakeDamageClient);

	int iStatue = CreateEntityByName("prop_dynamic");
	if(iStatue <= MaxClients)
		return;

	SetEntCache(client, iStatue, ENT_STATUE);

	// Statue animation starts in a very awkward position, we can spawn it hidden, then switch to it
	// on a better frame. 0.2s from initialization seems like a good value.
	CreateTimer(0.2, Timer_FrozenPostApply, GetClientUserId(client));

	char sClientModel[64], sValueBuffer[8];
	float fPos[3], fAng[3];
	GetClientAbsOrigin(client, fPos);
	GetClientAbsAngles(client, fAng);
	GetClientModel(client, sClientModel, sizeof(sClientModel));

	DispatchKeyValueVector(iStatue, "origin", fPos);
	DispatchKeyValueVector(iStatue, "angles", fAng);

	IntToString(GetEntProp(client, Prop_Send, "m_nSkin"), sValueBuffer, sizeof(sValueBuffer));
	DispatchKeyValue(iStatue, "skin", sValueBuffer);

	IntToString(GetEntProp(client, Prop_Send, "m_nBody"), sValueBuffer, sizeof(sValueBuffer));
	DispatchKeyValue(iStatue, "body", sValueBuffer);

	DispatchKeyValue(iStatue, "model", sClientModel);
	DispatchKeyValue(iStatue, "DefaultAnim", "dieviolent");
	Frozen_SetEntityAlpha(iStatue, 0); // start invisible, will appear in Timer_FrozenPostApply

	DispatchSpawn(iStatue);
	EmitSoundToAll(SOUND_FREEZE, iStatue);

	fPos[2] += DETACH_GROUND_DISTANCE; // detach player from ground to avoid lingering footstep sounds
	TeleportEntity(client, fPos, NULL_VECTOR, NULL_VECTOR);

	SetVariantString("0.25");
	AcceptEntityInput(iStatue, "SetPlaybackRate");
	CreateTimer(1.0, Timer_FrozenFreezeAnimation, EntIndexToEntRef(iStatue));

	int iIce = CreateEntityByName("prop_physics_override");
	if(iIce <= MaxClients)
		return;

	SetEntCache(client, iIce, ENT_ICE);

	Frozen_GetIceTransformCorrected(client, fPos, fAng);
	DispatchKeyValueVector(iIce, "origin", fPos);
	DispatchKeyValueVector(iIce, "angles", fAng);
	DispatchKeyValue(iIce, "model", ICE_STATUE);
	DispatchKeyValue(iIce, "modelscale", "0.4");

	// 4 -- debris
	// 8 -- motion disabled
	// 4096 -- debris with trigger interaction
	DispatchKeyValue(iIce, "spawnflags", "4108");

	SetEntityRenderMode(iIce, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iIce, 255, 255, 255, 80);

	DispatchSpawn(iIce);

	SetEntProp(iIce, Prop_Data, "m_iHealth", perk.GetPrefCell("ice_health", 500));
	SetEntProp(iIce, Prop_Data, "m_iMaxHealth", client); // m_iMaxHealth not used for anything

	SDKHook(iIce, SDKHook_OnTakeDamage, Frozen_OnTakeDamageIce);
	SDKHook(iIce, SDKHook_Touch, Frozen_OnTouchIce);
}

public Action Timer_FrozenPostApply(Handle hTimer, const int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client || !CheckClientPerkCache(client, g_iFrozenId))
		return Plugin_Stop;

	int iStatue = GetEntCache(client, ENT_STATUE);
	if(iStatue <= MaxClients)
		return Plugin_Stop;

	Frozen_Set(client, 0);
	Frozen_SetEntityAlpha(iStatue, GetIntCache(client, ORIGINAL_ALPHA));

	// It's very unlikely that 3 or more players are frozen at the same time unless the perk was
	// forced. In this case let's optimize things and not recreate their wearables onto the
	// statue. This will also mean they do not have to be resupplied after the perk ends.
	if(Frozen_GetCurrentRollerCount() > 3)
		return Plugin_Stop;

	Frozen_TransferWearables(client, iStatue);
	SetIntCache(client, true, NEEDS_RESUPPLY);

	float fPos[3];
	GetClientAbsOrigin(client, fPos);

	// Let's also optimize particles away.
	// TODO: does a copy, refactor the whole RTD structure to fix visibility issues
	PlayerAttachmentPoint eAttachPoint;
	eAttachPoint = GetPlayerAttachmentPoint(TF2_GetPlayerClass(client));

	SendTEParticleLingeringAttached(TEParticle_IceBodyGlow, iStatue, fPos, eAttachPoint.Root);
	SendTEParticleLingeringAttached(TEParticle_SnowFlakes, iStatue, fPos, eAttachPoint.Root);
	SendTEParticleLingeringAttached(TEParticle_Frostbite, iStatue, fPos, eAttachPoint.HandL);
	SendTEParticleLingeringAttached(TEParticle_Frostbite, iStatue, fPos, eAttachPoint.HandR);
	SendTEParticleLingeringAttached(TEParticle_Frostbite, iStatue, fPos, eAttachPoint.Back);
	SendTEParticleLingeringAttached(TEParticle_Frostbite, iStatue, fPos, eAttachPoint.FootL);
	SendTEParticleLingeringAttached(TEParticle_Frostbite, iStatue, fPos, eAttachPoint.FootR);

	return Plugin_Stop;
}

public Action Timer_FrozenFreezeAnimation(Handle hTimer, const int iEntRef){
	int iStatue = EntRefToEntIndex(iEntRef);
	if(iStatue <= MaxClients)
		return Plugin_Stop;

	SetVariantString("0.0");
	AcceptEntityInput(iStatue, "SetPlaybackRate");

	return Plugin_Stop;
}

void Frozen_RemovePerk(int client){
	UnsetClientPerkCache(client, g_iFrozenId);

	SetClientViewEntity(client, client);
	KillEntCache(client, ENT_STATUE);
	KillEntCache(client, ENT_ICE);

	SDKUnhook(client, SDKHook_OnTakeDamage, Frozen_OnTakeDamageClient);

	float fPos[3];
	GetClientAbsOrigin(client, fPos);

	fPos[2] -= DETACH_GROUND_DISTANCE; // teleport player back
	TeleportEntity(client, fPos, NULL_VECTOR, NULL_VECTOR);

	Frozen_Set(client, GetIntCache(client, ORIGINAL_ALPHA));
	DisarmWeapons(client, false);
	RemovePreventCapture(client);
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");

	SetIntCache(client, GetClientHealth(client), RESULTING_HEALTH);
	if(GetIntCacheBool(client, NEEDS_RESUPPLY))
		ForceResupplyCrude(client, fPos);
}

void Frozen_Resupply(int client){
	// WARNING: This function runs outside of perk time of the player.
	if(!Frozen_IsPostFrozen(client))
		return;

	if(!GetIntCacheBool(client, NEEDS_RESUPPLY))
		return;

	SetIntCache(client, false, NEEDS_RESUPPLY);

	// We need to await player health change and set it back to `iHealth`. However, I'm not sure
	// if we could rely on it happening the next frame, so let's check up to 3 following frames.
	DataPack hData = new DataPack();
	hData.WriteCell(3); // retry limit
	hData.WriteCell(GetClientUserId(client));
	hData.WriteCell(GetIntCache(client, RESULTING_HEALTH));
	CreateTimer(0.0, Timer_FrozenSetResultingHealth, hData, TIMER_REPEAT);
}

public Action Timer_FrozenSetResultingHealth(Handle hTimer, DataPack hData){
	hData.Reset();

	int iTimes = hData.ReadCell();
	int iUserId = hData.ReadCell();

	int client = GetClientOfUserId(iUserId);
	if(!client){
		CloseHandle(hData);
		return Plugin_Stop;
	}

	int iCurrentHealth = GetClientHealth(client);
	int iResultingHealth = hData.ReadCell();

	if(!(iResultingHealth < iCurrentHealth)){
		// Resulting health is not lower than the current health. This means the client was
		// overhealed and the resupply didn't do anything, or the resupply hasn't refilled the
		// client health yet. We don't know, so let's keep checking until we hit our limit.
		hData.Reset();
		hData.WriteCell(--iTimes);
	}else{
		// Otherwise, client got healed somehow, let's hope it's related to the resupply.
		SetEntityHealth(client, iResultingHealth);
		iTimes = 0;
	}

	if(iTimes <= 0){
		CloseHandle(hData);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

bool Frozen_Sound(int client, const char[] sSound){
	if(!CheckClientPerkCache(client, g_iFrozenId))
		return true;

	if(!IsVoicelineSound(sSound))
		return true;

	// Voiceline is played on every hit also, let's make sure not to run this too frequently
	float fTime = GetEngineTime();
	if(fTime < GetFloatCache(client, LAST_DAMAGE_TAKEN) + 1.0)
		return false;

	SetFloatCache(client, fTime, LAST_DAMAGE_TAKEN);

	int iContextStart = 0;
	float fVolume = 0.5;
	int iPitch = 100;

	switch(TF2_GetPlayerClass(client)){
		case TFClass_Scout:{
			iContextStart = 9;
			iPitch = 130;
		}

		case TFClass_Soldier:{
			iContextStart = 11;
			iPitch = 80;
		}

		case TFClass_Pyro:{
			EmitSoundToAll(sSound, client, SNDCHAN_VOICE, _, _, fVolume, iPitch);
			return false;
		}

		case TFClass_DemoMan:{
			iContextStart = 11;
			iPitch = 90;
		}

		case TFClass_Heavy:{
			iContextStart = 9;
			iPitch = 70;
		}

		case TFClass_Engineer:{
			iContextStart = 12;
			iPitch = 100;
		}

		case TFClass_Medic:{
			iContextStart = 9;
			iPitch = 110;
		}

		case TFClass_Sniper:{
			iContextStart = 10;
			iPitch = 100;
		}

		case TFClass_Spy:{
			iContextStart = 7;
			iPitch = 120;
		}
	}

	if(strncmp(sSound[iContextStart], "HelpMe", 6) == 0)
		EmitSoundToAll("vo/pyro_helpme01.mp3", client, SNDCHAN_VOICE, _, _, fVolume, iPitch);

	else if(strncmp(sSound[iContextStart], "Medic", 5) == 0)
		EmitSoundToAll("vo/pyro_medic01.mp3", client, SNDCHAN_VOICE, _, _, fVolume, iPitch);

	else if(strncmp(sSound[iContextStart], "Thanks", 6) == 0)
		EmitSoundToAll("vo/pyro_thanks01.mp3", client, SNDCHAN_VOICE, _, _, fVolume, iPitch);

	else if(strncmp(sSound[iContextStart], "Cheers", 6) == 0)
		EmitSoundToAll("vo/pyro_cheers01.mp3", client, SNDCHAN_VOICE, _, _, fVolume, iPitch);

	else if(strncmp(sSound[iContextStart], "Jeers", 5) == 0)
		EmitSoundToAll("vo/pyro_jeers01.mp3", client, SNDCHAN_VOICE, _, _, fVolume, iPitch);

	else if(strncmp(sSound[iContextStart], "Yes", 3) == 0)
		EmitSoundToAll("vo/pyro_yes01.mp3", client, SNDCHAN_VOICE, _, _, fVolume, iPitch);

	else if(strncmp(sSound[iContextStart], "No", 2) == 0)
		EmitSoundToAll("vo/pyro_no01.mp3", client, SNDCHAN_VOICE, _, _, fVolume, iPitch);

	else if(strncmp(sSound[iContextStart], "GoodJob", 7) == 0)
		EmitSoundToAll("vo/pyro_goodjob01.mp3", client, SNDCHAN_VOICE, _, _, fVolume, iPitch);

	else if(strncmp(sSound[iContextStart], "Go", 2) == 0)
		EmitSoundToAll("vo/pyro_go01.mp3", client, SNDCHAN_VOICE, _, _, fVolume, iPitch);

	else if(strncmp(sSound[iContextStart], "BattleCry", 9) == 0)
		EmitSoundToAll("vo/pyro_battlecry01.mp3", client, SNDCHAN_VOICE, _, _, fVolume, iPitch);

	else if(strncmp(sSound[iContextStart], "CloakedSpy", 10) == 0)
		EmitSoundToAll("vo/pyro_cloakedspy01.mp3", client, SNDCHAN_VOICE, _, _, fVolume, iPitch);

	else if(strncmp(sSound[iContextStart], "NiceShot", 8) == 0)
		EmitSoundToAll("vo/pyro_niceshot01.mp3", client, SNDCHAN_VOICE, _, _, fVolume, iPitch);

	else if(strncmp(sSound[iContextStart], "Incoming", 8) == 0)
		EmitSoundToAll("vo/pyro_incoming01.mp3", client, SNDCHAN_VOICE, _, _, fVolume, iPitch);

	else{
		char sGeneric[32];
		Format(sGeneric, sizeof(sGeneric), "vo/pyro_paincrticialdeath0%d.mp3", GetRandomInt(1, 3));
		EmitSoundToAll(sGeneric, client, SNDCHAN_VOICE, _, _, fVolume, iPitch);
	}

	return false;
}

void Frozen_TransferWearables(int client, int iStatue){
	char sClassname[12];

	for(int iEnt = MaxClients + 1; iEnt < GetMaxEntities(); ++iEnt){
		if(!IsValidEntity(iEnt))
			continue;

		GetEntityClassname(iEnt, sClassname, sizeof(sClassname));
		if(!StrEqual(sClassname, "tf_wearable"))
			continue;

		if(GetEntPropEnt(iEnt, Prop_Send, "moveparent") != client)
			continue;

		Frozen_DuplicateAndAttachWearable(iEnt, iStatue);
		RemoveEntity(iEnt); // remove original wearable to lower entity count
	}
}

void Frozen_DuplicateAndAttachWearable(int iOriginalWearable, int iTarget){
	static char sModel[PLATFORM_MAX_PATH+1];
	GetEntPropString(iOriginalWearable, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

	if(strlen(sModel) == 0)
		return;

	int iWearable = CreateEntityByName("prop_dynamic_override");
	if(iWearable <= MaxClients)
		return;

	SetEntityModel(iWearable, sModel);

	SetEntProp(iWearable, Prop_Send, "m_iTeamNum", GetEntProp(iOriginalWearable, Prop_Send, "m_iTeamNum"));
	SetEntProp(iWearable, Prop_Data, "m_nSkin", GetEntProp(iOriginalWearable, Prop_Send, "m_nSkin"));
	SetEntProp(iWearable, Prop_Data, "m_nBody", GetEntProp(iOriginalWearable, Prop_Send, "m_nBody"));
	SetEntPropEnt(iWearable, Prop_Send, "m_hOwnerEntity", iTarget);

	DispatchKeyValue(iWearable, "solid", "0");

	DispatchSpawn(iWearable);
	ActivateEntity(iWearable);

	SetVariantString("!activator");
	AcceptEntityInput(iWearable, "SetParent", iTarget);

	SetVariantString("head");
	AcceptEntityInput(iWearable, "SetParentAttachment");

	SetEntProp(iWearable, Prop_Send, "m_fEffects", (0x001 + 0x080)); //EF_BONEMERGE + EF_BONEMERGE_FASTCULL
}

void Frozen_OnTakeDamage(int client, int iAttacker, int iInflictor, float fDamage, int iType, float fPos[3], bool bFriendly){
	if(!bFriendly)
		SDKHooks_TakeDamage(client, iInflictor, iAttacker, fDamage * GetFloatCache(client, FROZEN_RESISTANCE), iType);

	if(iType & (DMG_BULLET | DMG_CLUB)){
		SendTEParticleWithPriority(TEParticle_IceImpact, fPos);
	}else if(iType & DMG_BUCKSHOT){
		float fShotPos[3];
		for(int i = 0; i < 3; ++i){
			fShotPos[0] = fPos[0] + GetRandomFloat(-10.0, 10.0);
			fShotPos[1] = fPos[1] + GetRandomFloat(-10.0, 10.0);
			fShotPos[2] = fPos[2] + GetRandomFloat(-10.0, 10.0);
			SendTEParticleWithPriority(TEParticle_IceImpact, fShotPos);
		}
	}else if(iType & (DMG_BURN | DMG_PLASMA)){
		fDamage *= GetFloatCache(client, FLAME_BUFF);
		SendTEParticleWithPriority(TEParticle_WaterSteam, fPos);
	}else if(iType & DMG_BLAST){
		GetClientAbsOrigin(client, fPos); // override
		SendTEParticleWithPriority(TEParticle_WaterSteam, fPos);
	}

	int iIce = GetEntCache(client, ENT_ICE);
	if(iIce <= MaxClients)
		return; // should never happen

	int iIceHealth = GetEntProp(iIce, Prop_Data, "m_iHealth") - RoundFloat(fDamage);
	if(iIceHealth > 0){
		SetEntProp(iIce, Prop_Data, "m_iHealth", iIceHealth);
		EmitSoundToAll(SOUND_ICE_IMPACT, client, _, _, _, _, GetRandomInt(90, 110));
		return;
	}

	SendTEParticleWithPriority(TEParticle_SnowBurst, fPos);
	EmitSoundToAll(SOUND_ICE_BREAK, client, _, _, _, _, 120);
	ForceRemovePerk(client);
}

public Action Frozen_OnTakeDamageClient(int client, int &iAttacker, int &iInflictor, float &fDamage, int &iType, int &iWeapon, float fForce[3], float fPos[3], int iCustom){
	if(iType & DMG_BLAST) // explosions can hit bot ice and client, make sure it's handled by ice only
		return Plugin_Handled;

	if(iType & (DMG_BURN | DMG_PLASMA)) // flamethrower doesn't provide position
		GetClientAbsOrigin(client, fPos);

	Frozen_OnTakeDamage(client, iAttacker, iInflictor, fDamage, iType, fPos, false);

	return Plugin_Handled;
}

public Action Frozen_OnTakeDamageIce(int iIce, int &iAttacker, int &iInflictor, float &fDamage, int &iType, int &iWeapon, float fForce[3], float fPos[3], int iCustom){
	int client = GetEntProp(iIce, Prop_Data, "m_iMaxHealth");
	bool bFriendly = TF2_GetClientTeam(client) == TF2_GetClientTeam(iAttacker);

	Frozen_OnTakeDamage(client, iAttacker, iInflictor, fDamage, iType, fPos, bFriendly);

	return Plugin_Handled;
}

public Action Frozen_OnTouchIce(int iIce, int iOther){
	char sClassname[32];
	GetEntityClassname(iOther, sClassname, sizeof(sClassname));

	if(!StrEqual(sClassname, "tf_flame_manager"))
		return Plugin_Continue;

	int client = GetEntProp(iIce, Prop_Data, "m_iMaxHealth");
	int iTeam = GetEntProp(iOther, Prop_Send, "m_iTeamNum");
	if(TF2_GetClientTeam(client) != view_as<TFTeam>(iTeam))
		return Plugin_Continue; // custom fire handling is needed only for friendlies

	float fTime = GetEngineTime();
	if(fTime < GetFloatCache(client, LAST_FIRE_TOUCH) + 0.1)
		return Plugin_Continue;

	SetFloatCache(client, fTime, LAST_FIRE_TOUCH);

	float fPos[3];
	GetClientAbsOrigin(client, fPos);
	Frozen_OnTakeDamage(client, 0, 0, 6.0, DMG_BURN, fPos, true);

	return Plugin_Continue;
}

void Frozen_Set(int client, int iValue){
	Frozen_SetEntityAlpha(client, iValue);

	int iWeapon = 0;
	for(int i = 0; i < 5; ++i){
		iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon > MaxClients && IsValidEntity(iWeapon))
			Frozen_SetEntityAlpha(iWeapon, iValue);
	}

	char sClass[24];
	for(int i = MaxClients+1; i < GetMaxEntities(); ++i)
		if(IsCorrectWearable(client, i, sClass, sizeof(sClass)))
			Frozen_SetEntityAlpha(i, iValue);
}

void Frozen_GetIceTransformCorrected(int client, float fPos[3], float fAng[3]){
	fPos[2] += 46.0;

	switch(TF2_GetPlayerClass(client)){
		case TFClass_Scout:{
			fAng[0] += 5.0;
			fAng[1] += 40.0;
		}
		case TFClass_Soldier:{
			fAng[0] -= 20.0;
			fAng[1] += 90.0;
			fPos[2] += 9.0;
		}
		case TFClass_Pyro:{
			fAng[0] -= 25.0;
			fAng[1] += 90.0;
			fPos[2] += 9.0;
		}
		case TFClass_DemoMan:{
			fAng[1] += 100.0;
			fAng[2] -= 25.0;
		}
		case TFClass_Heavy:{
			fAng[0] -= 15.0;
			fAng[1] -= 90.0;
			fAng[2] += 32.0;
		}
		case TFClass_Engineer:{
			fAng[1] += 50.0;
			fAng[2] -= 10.0;
			fPos[2] -= 8.0;
		}
		case TFClass_Medic:{
			fAng[1] -= 30.0;
		}
		case TFClass_Sniper:{
			fAng[1] += 90.0;
		}
		case TFClass_Spy:{
			fAng[1] -= 105.0;
		}
	}
}

int Frozen_GetCurrentRollerCount(){
	int iCount = 0;

	for(int client = 1; client <= MaxClients; ++client)
		if(IsClientInGame(client) && g_hRollers.GetInRoll(client))
			iCount += view_as<int>(g_hRollers.GetPerk(client).Id == g_iFrozenId);

	return iCount;
}

bool Frozen_IsPostFrozen(int client){
	return !g_hRollers.GetInRoll(client) && g_hRollers.IsIdInPerkHistory(client, g_iFrozenId, 1);
}

stock int Frozen_GetEntityAlpha(int iEntity){
	return GetEntData(iEntity, GetEntSendPropOffs(iEntity, "m_clrRender") + 3, 1);
}

stock void Frozen_SetEntityAlpha(int iEntity, int iValue){
	if(GetEntityRenderMode(iEntity) == RENDER_NORMAL)
		SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);

	SetEntData(iEntity, GetEntSendPropOffs(iEntity, "m_clrRender") + 3, iValue, 1, true);
}

#undef ENT_STATUE
#undef ENT_ICE

#undef SOUND_FREEZE
#undef SOUND_ICE_IMPACT
#undef SOUND_ICE_BREAK

#undef ICE_STATUE

#undef ORIGINAL_ALPHA
#undef NEEDS_RESUPPLY
#undef RESULTING_HEALTH

#undef LAST_FIRE_TOUCH
#undef LAST_DAMAGE_TAKEN
#undef FROZEN_RESISTANCE
#undef FLAME_BUFF

#undef DETACH_GROUND_DISTANCE
