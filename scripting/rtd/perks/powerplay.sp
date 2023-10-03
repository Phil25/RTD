/**
* PowerPlay perk.
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


#define ATTRIB_CAPTURE_VALUE_INCREASE 68
#define ATTRIB_MELEE_RANGE 264
#define ATTRIB_JUMP_HEIGHT 326
#define ATTRIB_CANNOT_PICK_UP_INTEL 400
#define ATTRIB_DAMAGE_FORCE_INCREASE 535

#define BASE_WALK_SPEED 0
#define SPEED_REGAIN_TIME 1

#define COLOR_RED 0
#define COLOR_BLU 1

#define EFFECT 0
#define GLOW 1

int g_iPowerPlayId = 53;

public void PowerPlay_Call(const int client, const Perk perk, const bool apply){
	if(apply){
		g_iPowerPlayId = perk.Id;
		SetClientPerkCache(client, g_iPowerPlayId);
		SetFloatCache(client, GetBaseSpeed(client), BASE_WALK_SPEED);
		PowerPlay_ApplyPerk(client);
	}else{
		UnsetClientPerkCache(client, g_iPowerPlayId);
		PowerPlay_RemovePerk(client);
	}
}

void PowerPlay_ApplyPerk(const int client){
	SDKHook(client, SDKHook_WeaponCanSwitchTo, PowerPlay_BlockWeaponSwitch);

	int iMeleeWeapon = GetPlayerWeaponSlot(client, 2);
	if(iMeleeWeapon > MaxClients && IsValidEntity(iMeleeWeapon))
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iMeleeWeapon);

	switch(TF2_GetPlayerClass(client)){
		case TFClass_Scout:{
			SDKHook(client, SDKHook_OnTakeDamage, PowerPlay_ResistanceAndSlowdown);
			TF2Attrib_SetByDefIndex(client, ATTRIB_JUMP_HEIGHT, 1.25);
			CreateTimer(0.1, Timer_PowerPlaySlowDownCheck, GetClientUserId(client), TIMER_REPEAT);
		}
		case TFClass_Heavy:{
			SDKHook(client, SDKHook_OnTakeDamage, PowerPlay_Resistance);
		}
		default:{
			SDKHook(client, SDKHook_OnTakeDamage, PowerPlay_Resistance);
			TF2Attrib_SetByDefIndex(client, ATTRIB_DAMAGE_FORCE_INCREASE, 40.0);
		}
	}

	TF2_AddCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_UberBulletResist);
	TF2_AddCondition(client, TFCond_UberBlastResist);
	TF2_AddCondition(client, TFCond_UberFireResist);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly);

	int iMelee = GetPlayerWeaponSlot(client, 2);
	if(iMelee > MaxClients && IsValidEntity(iMelee))
		TF2Attrib_SetByDefIndex(iMelee, ATTRIB_MELEE_RANGE, 1.1);

	TF2Attrib_SetByDefIndex(client, ATTRIB_CANNOT_PICK_UP_INTEL, 1.0);
	TF2Attrib_SetByDefIndex(client, ATTRIB_CAPTURE_VALUE_INCREASE, -GetCaptureValue(client));
	FakeClientCommandEx(client, "dropitem") // in case intel is already picked up

	switch(TF2_GetClientTeam(client)){
		case TFTeam_Blue:{
			SetEntCache(client, CreateParticle(client, "eyeboss_team_blue", true), EFFECT);
			SetIntCache(client, 150, COLOR_RED)
			SetIntCache(client, 255, COLOR_BLU)
		}
		case TFTeam_Red:{
			SetEntCache(client, CreateParticle(client, "eyeboss_team_red", true), EFFECT);
			SetIntCache(client, 255, COLOR_RED)
			SetIntCache(client, 150, COLOR_BLU)
		}
	}

	int iGlow = AttachGlow(client);
	if(iGlow <= MaxClients)
		return;

	SDKHook(client, SDKHook_PostThinkPost, PowerPlay_OnGlowUpdate);
	SetEntCache(client, iGlow, GLOW);
}

void PowerPlay_RemovePerk(const int client){
	KillEntCache(client, EFFECT);
	KillEntCache(client, GLOW);

	SDKUnhook(client, SDKHook_WeaponCanSwitchTo, PowerPlay_BlockWeaponSwitch);
	SDKUnhook(client, SDKHook_PostThinkPost, PowerPlay_OnGlowUpdate);

	switch(TF2_GetPlayerClass(client)){
		case TFClass_Scout:{
			SDKUnhook(client, SDKHook_OnTakeDamage, PowerPlay_ResistanceAndSlowdown);
			TF2Attrib_RemoveByDefIndex(client, ATTRIB_JUMP_HEIGHT);
			SetSpeed(client, GetFloatCache(client, BASE_WALK_SPEED));
		}
		case TFClass_Heavy:{
			SDKUnhook(client, SDKHook_OnTakeDamage, PowerPlay_Resistance);
		}
		default:{
			SDKUnhook(client, SDKHook_OnTakeDamage, PowerPlay_Resistance);
			TF2Attrib_RemoveByDefIndex(client, ATTRIB_DAMAGE_FORCE_INCREASE);
		}
	}

	int iMelee = GetPlayerWeaponSlot(client, 2);
	if(iMelee > MaxClients && IsValidEntity(iMelee))
		TF2Attrib_RemoveByDefIndex(iMelee, ATTRIB_MELEE_RANGE);

	TF2Attrib_RemoveByDefIndex(client, ATTRIB_CANNOT_PICK_UP_INTEL);
	TF2Attrib_RemoveByDefIndex(client, ATTRIB_CAPTURE_VALUE_INCREASE);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_RemoveCondition(client, TFCond_UberBulletResist);
	TF2_RemoveCondition(client, TFCond_UberBlastResist);
	TF2_RemoveCondition(client, TFCond_UberFireResist);
	TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);
}

public void PowerPlay_OnGlowUpdate(int client){
	int iGlow = GetEntCache(client, GLOW);
	if(iGlow == INVALID_ENT_REFERENCE)
		return;

	int iColor[4];
	iColor[0] = GetIntCache(client, COLOR_RED);
	iColor[1] = 150;
	iColor[2] = GetIntCache(client, COLOR_BLU);
	iColor[3] = RoundToNearest(Cosine(GetGameTime() * 12.0) * 60.0 + 195.0);

	SetVariantColor(iColor);
	AcceptEntityInput(iGlow, "SetGlowColor");
}

void PowerPlay_OnAttack(int client){
	if(!CheckClientPerkCache(client, g_iPowerPlayId))
		return;

	TF2_AddCondition(client, TFCond_LostFooting, 1.0);

	int iClients[2];
	iClients[0] = client;

	Handle hMsg = StartMessageEx(g_EarthquakeMsgId, iClients, 1);
	if(hMsg != INVALID_HANDLE){
		BfWriteByte(hMsg, 0);
		BfWriteFloat(hMsg, 10.0);
		BfWriteFloat(hMsg, 3.0);
		BfWriteFloat(hMsg, 0.4);
		EndMessage();
	}
}

public Action PowerPlay_BlockWeaponSwitch(const int client, const int iWeapon){
	return Plugin_Handled;
}

public Action PowerPlay_Resistance(int client, int &iAtk, int &iInflictor, float &fDamage, int &iType){
	fDamage *= 0.025;

	if(iInflictor > MaxClients && IsValidEntity(iInflictor)){
		char sClass[32];
		GetEntityClassname(iInflictor, sClass, sizeof(sClass));

		if(StrEqual(sClass, "obj_sentrygun"))
			iType |= DMG_PREVENT_PHYSICS_FORCE;
	}

	return Plugin_Changed;
}

public Action PowerPlay_ResistanceAndSlowdown(int client, int &iAtk, int &iInflictor, float &fDamage, int &iType){
	float fOriginalDamage = fDamage;

	fDamage *= 0.025;
	iType |= DMG_PREVENT_PHYSICS_FORCE;

	if(fOriginalDamage < 8.0)
		return Plugin_Changed;

	SetFloatCache(client, GetEngineTime() + fOriginalDamage / 50.0, SPEED_REGAIN_TIME);
	SetSpeed(client, GetFloatCache(client, BASE_WALK_SPEED), 0.65);

	return Plugin_Changed;
}

public Action Timer_PowerPlaySlowDownCheck(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iPowerPlayId))
		return Plugin_Stop;

	if(GetEngineTime() > GetFloatCache(client, SPEED_REGAIN_TIME))
		SetSpeed(client, GetFloatCache(client, BASE_WALK_SPEED));

	return Plugin_Continue;
}

#undef ATTRIB_CAPTURE_VALUE_INCREASE
#undef ATTRIB_MELEE_RANGE
#undef ATTRIB_JUMP_HEIGHT
#undef ATTRIB_CANNOT_PICK_UP_INTEL
#undef ATTRIB_DAMAGE_FORCE_INCREASE

#undef BASE_WALK_SPEED
#undef SPEED_REGAIN_TIME

#undef COLOR_RED
#undef COLOR_BLU

#undef EFFECT
#undef GLOW
