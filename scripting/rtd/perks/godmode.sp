/**
* Godmode perk.
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

#define GODMODE_DOWN_TEXT "(⋆⭒˚｡⋆) ⬇"
#define GODMODE_DOWN_SOUND "misc/doomsday_cap_close_start.wav"
#define GODMODE_WARN_TEXT "<!>"
#define GODMODE_WARN_SOUND "replay/snip.wav"

#define NO_ANNOTATION_COND_1 TFCond_Cloaked
#define NO_ANNOTATION_COND_2 TFCond_Disguised

#define UberMode Int[0]
#define Resistance Float[0]
#define LastDeflect Float[1]
#define AnnotationLifetime Float[2]
#define Effect EntSlot_1

ClientFlags g_eInGodmode;

static char g_sResistanceHeavy[][] = {
	"player/resistance_heavy1.wav",
	"player/resistance_heavy2.wav",
	"player/resistance_heavy3.wav",
	"player/resistance_heavy4.wav",
}

methodmap GodmodeFlags
{
	public GodmodeFlags(const int client=0)
	{
		return view_as<GodmodeFlags>(client);
	}

	public void Add(const int iEnemy)
	{
		int client = view_as<int>(this);
		if (client == iEnemy || this.Contains(iEnemy))
			return;

		Cache[client].Flags.Set(iEnemy);

		if (Cache[client].UberMode)
			return;

		float fLifetime = Cache[client].AnnotationLifetime;

		ShowAnnotationFor(iEnemy, client, fLifetime, GODMODE_DOWN_TEXT, GODMODE_DOWN_SOUND);

		if (TF2_IsPlayerInCondition(iEnemy, NO_ANNOTATION_COND_1) || TF2_IsPlayerInCondition(iEnemy, NO_ANNOTATION_COND_2))
			return;

		ShowAnnotationFor(client, iEnemy, fLifetime, GODMODE_WARN_TEXT, GODMODE_WARN_SOUND);

		int iBeam = ConnectWithBeam(iEnemy, client, 150, 255, 150, 1.0, 1.0, 10.0);
		if (iBeam > MaxClients)
		{
			KILL_ENT_IN(iBeam,0.2);
		}
	}

	public void Remove(const int iEnemy)
	{
		if (!this.Contains(iEnemy))
			return;

		Cache[view_as<int>(this)].Flags.Unset(iEnemy);
		this.RemoveAnnotation(iEnemy);
	}

	public void RemoveForAll(const int iEnemy)
	{
		// NOTE: do not use `this` in this method, it can be called outside an instance

		for (int client = 1; client <= MaxClients; ++client)
			if (g_eInGodmode.Test(client))
				GodmodeFlags(client).Remove(iEnemy);
	}

	public void RemoveAnnotation(const int iEnemy)
	{
		int client = view_as<int>(this);
		if (Cache[client].UberMode)
			return;

		HideAnnotationFor(client, iEnemy);
		HideAnnotationFor(iEnemy, client);
	}

	public void HideAnnotationForAll(const int iEnemy)
	{
		// NOTE: do not use `this` in this method, it can be called outside an instance

		for (int client = 1; client <= MaxClients; ++client)
			if (g_eInGodmode.Test(client) && !Cache[client].UberMode) // checking for enemy unnecesary here
				HideAnnotationFor(client, iEnemy);
	}

	public void ShowAnnotationForAll(const int iEnemy)
	{
		// NOTE: do not use `this` in this method, it can be called outside an instance

		for (int client = 1; client <= MaxClients; ++client)
			if (g_eInGodmode.Test(client) && Cache[client].Flags.Test(iEnemy) && !Cache[client].UberMode)
				ShowAnnotationFor(client, iEnemy, Cache[client].AnnotationLifetime, GODMODE_WARN_TEXT);
	}

	public bool Contains(const int iEnemy)
	{
		return view_as<int>(Cache[view_as<int>(this)].Flags.Test(iEnemy)) > 0;
	}

	public void Reset()
	{
		Cache[view_as<int>(this)].Flags.Reset();
	}
}

DEFINE_CALL_APPLY_REMOVE(Godmode)

public void Godmode_Init(const Perk perk)
{
	for (int i = 0; i < sizeof(g_sResistanceHeavy); ++i)
		PrecacheSound(g_sResistanceHeavy[i]);

	Events.OnConditionAdded(perk, Godmode_OnConditionAdded_Any, SubscriptionType_Any);
	Events.OnConditionRemoved(perk, Godmode_OnConditionRemoved_Any, SubscriptionType_Any);
	Events.OnPlayerAttacked(perk, Godmode_OnPlayerAttacked);
	Events.OnPlayerDied(perk, Godmode_OnPlayerDiedOrDisconnected_Any, SubscriptionType_Any);
	Events.OnPlayerDisconnected(perk, Godmode_OnPlayerDiedOrDisconnected_Any, SubscriptionType_Any);
}

void Godmode_ApplyPerk(const int client, const Perk perk)
{
	g_eInGodmode.Set(client);

	Cache[client].UberMode = perk.GetPrefCell("uber", 0);
	Cache[client].LastDeflect = 0.0;
	Cache[client].Resistance = perk.GetPrefFloat("resistance", 0.3);
	Cache[client].AnnotationLifetime = GetPerkTimeFloat(perk);

	SetOverlay(client, ClientOverlay_Beams);

	int iEffect = CreateProxy(client);
	Cache[client].SetEnt(Effect, iEffect);

	SendTEParticleLingeringAttachedProxyExcept(TEParticlesLingering.WhiteBodyHaze, iEffect, client);
	SendTEParticleLingeringAttachedProxyExcept(TEParticlesLingering.WhiteBodyLights, iEffect, client);

	switch (perk.GetPrefCell("mode", 0))
	{
		case -1: // no self damage
			SDKHook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_NoSelf);

		case 0: // pushback only
			SDKHook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_Pushback);

		case 1: // deal self damage
			SDKHook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_Self);
	}

	if (Cache[client].UberMode)
	{
		TF2_AddCondition(client, TFCond_UberchargedCanteen);
	}
	else
	{
		ApplyPreventCapture(client);
	}

	GodmodeFlags(client).Reset();
	g_eInGodmode.Set(client);
}

void Godmode_RemovePerk(const int client)
{
	g_eInGodmode.Unset(client);

	SetOverlay(client, ClientOverlay_None);

	SDKUnhook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_NoSelf);
	SDKUnhook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_Pushback);
	SDKUnhook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_Self);

	if (Cache[client].UberMode)
		TF2_RemoveCondition(client, TFCond_UberchargedCanteen);

	TF2_RemoveCondition(client, TFCond_UberBulletResist);
	TF2_RemoveCondition(client, TFCond_UberBlastResist);
	TF2_RemoveCondition(client, TFCond_UberFireResist);

	RemovePreventCapture(client);

	GodmodeFlags mGodmodeFlags = GodmodeFlags(client);
	for (int i = 1; i <= MaxClients; ++i)
		if (IsClientInGame(i) && mGodmodeFlags.Contains(i))
			mGodmodeFlags.RemoveAnnotation(i);
}

void Godmode_SpawnDeflectEffect(const int client, const int iType, const float fPos[3])
{
	float fTime = GetEngineTime();
	if (fTime < Cache[client].LastDeflect + 0.1)
		return;

	Cache[client].LastDeflect = fTime;

	if (iType & (DMG_BULLET | DMG_CLUB))
	{
		SendTEParticleWithPriority(TEParticles.BulletImpactHeavy, fPos);
		return;
	}

	if (iType & (DMG_BUCKSHOT))
	{
		float fShotPos[3];
		for (int i = 0; i < 3; ++i){
			fShotPos[0] = fPos[0] + GetRandomFloat(-10.0, 10.0);
			fShotPos[1] = fPos[1] + GetRandomFloat(-10.0, 10.0);
			fShotPos[2] = fPos[2] + GetRandomFloat(-10.0, 10.0);
			SendTEParticleWithPriority(TEParticles.BulletImpactHeavy, fShotPos);
		}
	}
}

Action Godmode_OnTakeDamage_Common(const int client, const int iAttacker, float &fDamage, const int iType, const float fPos[3])
{
	// Attacker could be world or some various hurt entities
	if (1 <= iAttacker <= MaxClients && GodmodeFlags(client).Contains(iAttacker))
	{
		fDamage *= Cache[client].Resistance;
		EmitSoundToAll(g_sResistanceHeavy[GetRandomInt(0, sizeof(g_sResistanceHeavy) - 1)], client);

		return Plugin_Changed;
	}

	Godmode_SpawnDeflectEffect(client, iType, fPos);
	return Plugin_Handled;
}

public Action Godmode_OnTakeDamage_NoSelf(int client, int &iAttacker, int &iInflictor, float &fDamage, int &iType, int &iWeapon, float fForce[3], float fPos[3], int iCustom)
{
	return client == iAttacker ? Plugin_Handled : Godmode_OnTakeDamage_Common(client, iAttacker, fDamage, iType, fPos);
}

public Action Godmode_OnTakeDamage_Pushback(int client, int &iAttacker, int &iInflictor, float &fDamage, int &iType, int &iWeapon, float fForce[3], float fPos[3], int iCustom)
{
	if (client == iAttacker)
	{
		TF2_AddCondition(client, TFCond_Bonked, 0.01);
		return Plugin_Continue;
	}

	return Godmode_OnTakeDamage_Common(client, iAttacker, fDamage, iType, fPos);
}

public Action Godmode_OnTakeDamage_Self(int client, int &iAttacker, int &iInflictor, float &fDamage, int &iType, int &iWeapon, float fForce[3], float fPos[3], int iCustom)
{
	return client == iAttacker ? Plugin_Continue : Godmode_OnTakeDamage_Common(client, iAttacker, fDamage, iType, fPos);
}

public void Godmode_OnConditionAdded_Any(const int client, const TFCond eCondition)
{
	switch (eCondition)
	{
		case NO_ANNOTATION_COND_1, NO_ANNOTATION_COND_2:
			GodmodeFlags().HideAnnotationForAll(client);
	}
}

public void Godmode_OnConditionRemoved_Any(const int client, const TFCond eCondition)
{
	switch (eCondition)
	{
		case NO_ANNOTATION_COND_1, NO_ANNOTATION_COND_2:
			GodmodeFlags().ShowAnnotationForAll(client);
	}
}

public void Godmode_OnPlayerAttacked(const int client, const int iVictim, const int iDamage, const int iRemainingHealth)
{
	GodmodeFlags(client).Add(iVictim);
}

public void Godmode_OnPlayerDiedOrDisconnected_Any(const int client)
{
	GodmodeFlags().RemoveForAll(client);
}

#undef GODMODE_DOWN_TEXT
#undef GODMODE_DOWN_SOUND
#undef GODMODE_WARN_TEXT
#undef GODMODE_WARN_SOUND

#undef NO_ANNOTATION_COND_1
#undef NO_ANNOTATION_COND_2

#undef UberMode
#undef Resistance
#undef LastDeflect
#undef AnnotationLifetime
#undef Effect
