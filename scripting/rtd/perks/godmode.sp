/**
* Godmode perk.
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


#define GODMODE_PARTICLE "powerup_supernova_ready"

#define GODMODE_DOWN_TEXT "(⋆⭒˚｡⋆) ⬇"
#define GODMODE_DOWN_SOUND "misc/doomsday_cap_close_start.wav"
#define GODMODE_WARN_TEXT "<!>"
#define GODMODE_WARN_SOUND "replay/snip.wav"

#define UBER_MODE 0

#define GODMODE_RESISTANCE 0
#define LAST_DEFLECT_TIME 1
#define ANNOTATION_LIFETIME 2

ClientFlags g_eInGodmode;
int g_iGodmodeId = 0;

methodmap GodmodeFlags{
	public GodmodeFlags(const int client=0){
		return view_as<GodmodeFlags>(client);
	}

	public void Add(const int iEnemy){
		int client = view_as<int>(this);
		if(client == iEnemy || this.Contains(iEnemy))
			return;

		Cache(client).SetClientFlag(iEnemy);

		if(GetIntCache(client, UBER_MODE))
			return;

		ShowAnnotationFor(iEnemy, client, GetFloatCache(client, ANNOTATION_LIFETIME), GODMODE_DOWN_TEXT, GODMODE_DOWN_SOUND);

		if(TF2_IsPlayerInCondition(iEnemy, TFCond_Cloaked) || TF2_IsPlayerInCondition(iEnemy, TFCond_Disguised))
			return;

		ShowAnnotationFor(client, iEnemy, GetFloatCache(client, ANNOTATION_LIFETIME), GODMODE_WARN_TEXT, GODMODE_WARN_SOUND);

		int iBeam = ConnectWithBeam(iEnemy, client, 150, 255, 150, 1.0, 1.0, 10.0);
		if(iBeam > MaxClients){
			KILL_ENT_IN(iBeam,0.2)
		}
	}

	public void Remove(const int iEnemy){
		if(!this.Contains(iEnemy))
			return;

		Cache(view_as<int>(this)).UnsetClientFlag(iEnemy);
		this.RemoveAnnotation(iEnemy);
	}

	public void RemoveForAll(const int iEnemy){
		for(int client = 1; client <= MaxClients; ++client)
			if(CheckClientPerkCache(client, g_iGodmodeId))
				GodmodeFlags(client).Remove(iEnemy);
	}

	public void RemoveAnnotation(const int iEnemy){
		int client = view_as<int>(this);
		if(GetIntCache(client, UBER_MODE))
			return;

		HideAnnotationFor(client, iEnemy);
		HideAnnotationFor(iEnemy, client);
	}

	public void HideAnnotationForAll(const int iEnemy){
		for(int client = 1; client <= MaxClients; ++client)
			if(CheckClientPerkCache(client, g_iGodmodeId) && !GetIntCache(client, UBER_MODE)) // checking for enemy unnecesary here
				HideAnnotationFor(client, iEnemy);
	}

	public void ShowAnnotationForAll(const int iEnemy){
		for(int client = 1; client <= MaxClients; ++client)
			if(CheckClientPerkCache(client, g_iGodmodeId) && this.Contains(iEnemy) && !GetIntCache(client, UBER_MODE))
				ShowAnnotationFor(client, iEnemy, GetFloatCache(client, ANNOTATION_LIFETIME), GODMODE_WARN_TEXT);
	}

	public bool Contains(const int iEnemy){
		return Cache(view_as<int>(this)).TestClientFlag(iEnemy);
	}

	public void Reset(){
		Cache(view_as<int>(this)).ResetClientFlags();
	}
}

public void Godmode_Call(int client, Perk perk, bool bApply){
	if(bApply) Godmode_ApplyPerk(client, perk);
	else Godmode_RemovePerk(client);
}

void Godmode_ApplyPerk(int client, Perk perk){
	g_iGodmodeId = perk.Id;
	SetClientPerkCache(client, g_iGodmodeId);
	SetFloatCache(client, 0.0, LAST_DEFLECT_TIME);
	SetFloatCache(client, perk.GetPrefFloat("resistance"), GODMODE_RESISTANCE);
	SetFloatCache(client, GetPerkTimeFloat(perk), ANNOTATION_LIFETIME);

	float fParticleOffset[3] = {0.0, 0.0, 12.0};
	SetEntCache(client, CreateParticle(client, GODMODE_PARTICLE, _, _, fParticleOffset));

	int iMode = perk.GetPrefCell("mode");
	switch(iMode){
		case -1: // no self damage
			SDKHook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_NoSelf);
		case 0: // pushback only
			SDKHook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_Pushback);
		case 1: // deal self damage
			SDKHook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_Self);
	}

	int iUber = perk.GetPrefCell("uber");
	SetIntCache(client, iUber, UBER_MODE);

	if(iUber){
		TF2_AddCondition(client, TFCond_UberchargedCanteen);
	}else{
		TF2_AddCondition(client, TFCond_UberBulletResist);
		TF2_AddCondition(client, TFCond_UberBlastResist);
		TF2_AddCondition(client, TFCond_UberFireResist);
		ApplyPreventCapture(client);
	}

	GodmodeFlags(client).Reset();
	g_eInGodmode.Set(client);
}

void Godmode_RemovePerk(int client){
	UnsetClientPerkCache(client, g_iGodmodeId);

	KillEntCache(client);

	SDKUnhook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_NoSelf);
	SDKUnhook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_Pushback);
	SDKUnhook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_Self);

	if(GetIntCacheBool(client, UBER_MODE))
		TF2_RemoveCondition(client, TFCond_UberchargedCanteen);

	TF2_RemoveCondition(client, TFCond_UberBulletResist);
	TF2_RemoveCondition(client, TFCond_UberBlastResist);
	TF2_RemoveCondition(client, TFCond_UberFireResist);

	RemovePreventCapture(client);

	GodmodeFlags mGodmodeFlags = GodmodeFlags(client);
	for(int i = 1; i <= MaxClients; ++i)
		if(IsClientInGame(i) && mGodmodeFlags.Contains(i))
			mGodmodeFlags.RemoveAnnotation(i);

	g_eInGodmode.Unset(client);
}

void Godmode_SpawnDeflectEffect(int client, int iType, float fPos[3]){
	float fTime = GetEngineTime();
	if(fTime < GetFloatCache(client, LAST_DEFLECT_TIME) + 0.1)
		return;

	SetFloatCache(client, fTime, LAST_DEFLECT_TIME);

	if(iType & (DMG_BULLET | DMG_CLUB)){
		SendTEParticleWithPriority(TEParticle_BulletImpactHeavy, fPos);
		return;
	}

	if(iType & (DMG_BUCKSHOT)){
		float fShotPos[3];
		for(int i = 0; i < 3; ++i){
			fShotPos[0] = fPos[0] + GetRandomFloat(-10.0, 10.0);
			fShotPos[1] = fPos[1] + GetRandomFloat(-10.0, 10.0);
			fShotPos[2] = fPos[2] + GetRandomFloat(-10.0, 10.0);
			SendTEParticleWithPriority(TEParticle_BulletImpactHeavy, fShotPos);
		}
	}
}

Action Godmode_OnTakeDamage_Common(const int client, const int iAttacker, float &fDamage, const int iType, float fPos[3]){
	// Attacker could be world or some various hurt entities
	if(1 <= iAttacker <= MaxClients && GodmodeFlags(client).Contains(iAttacker)){
		fDamage *= GetFloatCache(client, GODMODE_RESISTANCE);
		return Plugin_Changed;
	}

	Godmode_SpawnDeflectEffect(client, iType, fPos);
	return Plugin_Handled;
}

public Action Godmode_OnTakeDamage_NoSelf(int client, int &iAttacker, int &iInflictor, float &fDamage, int &iType, int &iWeapon, float fForce[3], float fPos[3], int iCustom){
	return client == iAttacker ? Plugin_Handled : Godmode_OnTakeDamage_Common(client, iAttacker, fDamage, iType, fPos);
}

public Action Godmode_OnTakeDamage_Pushback(int client, int &iAttacker, int &iInflictor, float &fDamage, int &iType, int &iWeapon, float fForce[3], float fPos[3], int iCustom){
	if(client == iAttacker){
		TF2_AddCondition(client, TFCond_Bonked, 0.01);
		return Plugin_Continue;
	}

	return Godmode_OnTakeDamage_Common(client, iAttacker, fDamage, iType, fPos);
}

public Action Godmode_OnTakeDamage_Self(int client, int &iAttacker, int &iInflictor, float &fDamage, int &iType, int &iWeapon, float fForce[3], float fPos[3], int iCustom){
	return client == iAttacker ? Plugin_Continue : Godmode_OnTakeDamage_Common(client, iAttacker, fDamage, iType, fPos);
}

void Godmode_OnClientDisconnect(const int client){
	GodmodeFlags().RemoveForAll(client);
}

void Godmode_OnPlayerDeath(const int client){
	GodmodeFlags().RemoveForAll(client);
}

void Godmode_OnConditionAdded(const int client, const TFCond condition){
	switch(condition){
		case TFCond_Cloaked, TFCond_Disguised:
			GodmodeFlags().HideAnnotationForAll(client);
	}
}

void Godmode_OnConditionRemoved(const int client, const TFCond condition){
	switch(condition){
		case TFCond_Cloaked, TFCond_Disguised:
			GodmodeFlags().ShowAnnotationForAll(client);
	}
}

void Godmode_PlayerHurt(const int client, Handle hEvent){
	int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(0 < iAttacker <= MaxClients && CheckClientPerkCache(iAttacker, g_iGodmodeId))
		GodmodeFlags(iAttacker).Add(client);
}

#undef GODMODE_DOWN_TEXT
#undef GODMODE_DOWN_SOUND
#undef GODMODE_WARN_TEXT
#undef GODMODE_WARN_SOUND

#undef UBER_MODE

#undef GODMODE_RESISTANCE
#undef LAST_DEFLECT_TIME
#undef ANNOTATION_LIFETIME
