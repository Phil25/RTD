/**
* Timebomb perk.
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

#define MODEL_BOMB "models/props_lakeside_event/bomb_temp_hat.mdl"

#define SOUND_TIMEBOMB_TICK "buttons/button17.wav"
#define SOUND_TIMEBOMB_GOFF "weapons/cguard/charging.wav"
#define SOUND_EXPLODE "weapons/explode3.wav"

#define TICKS_SLOW 0.75
#define TICKS_FAST 0.35

#define Resistance Int[0]
#define Damage Float[0]
#define RadiusSquared Float[1]
#define PrimeThreshold Float[2]
#define DetonateThreshold Float[3]
#define Bomb EntSlot_1

static char g_sResistanceMedium[][] = {
	"player/resistance_medium1.wav",
	"player/resistance_medium2.wav",
	"player/resistance_medium3.wav",
	"player/resistance_medium4.wav",
}

DEFINE_CALL_APPLY_REMOVE(Timebomb)

public void Timebomb_Init(const Perk perk)
{
	PrecacheModel(MODEL_BOMB);
	PrecacheSound(SOUND_EXPLODE);
	PrecacheSound(SOUND_TIMEBOMB_TICK);
	PrecacheSound(SOUND_TIMEBOMB_GOFF);

	PrecacheSound(g_sResistanceMedium[0]);
	PrecacheSound(g_sResistanceMedium[1]);
	PrecacheSound(g_sResistanceMedium[2]);
	PrecacheSound(g_sResistanceMedium[3]);
}

void Timebomb_ApplyPerk(const int client, const Perk perk)
{
	float fExplodeTime = GetEngineTime() + GetPerkTime(perk);
	float fRadius = perk.GetPrefFloat("radius", 512.0);

	Cache[client].Resistance = RoundFloat(perk.GetPrefFloat("resistance", 0.75) * 100);
	Cache[client].Damage = perk.GetPrefFloat("damage", 270.0);
	Cache[client].RadiusSquared = fRadius * fRadius;
	Cache[client].PrimeThreshold = fExplodeTime - 3.0;
	Cache[client].DetonateThreshold = fExplodeTime - 1.0;
	Cache[client].SetEnt(Bomb, Timebomb_SpawnBombHead(client));

	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");

	TF2Attrib_SetByDefIndex(client, Attribs.NoHeadshotDeath, 1.0);
	SDKHook(client, SDKHook_OnTakeDamage, Timebomb_OnTakeDamage);

	Cache[client].Repeat(TICKS_SLOW, Timebomb_TickSlow);
}

void Timebomb_RemovePerk(const int client)
{
	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");

	TF2Attrib_RemoveByDefIndex(client, Attribs.NoHeadshotDeath);
	SDKUnhook(client, SDKHook_OnTakeDamage, Timebomb_OnTakeDamage);

	if (GetEngineTime() < Cache[client].DetonateThreshold)
		return;

	float fDamage = Cache[client].Damage;
	float fRadiusSquared = Cache[client].RadiusSquared;

	float fPos[3];
	GetClientAbsOrigin(client, fPos);

	int iPlayerDamage = 0;
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (i == client || !IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		if (!CanPlayerBeHurt(i))
			continue;

		if (!CanEntitySeeTarget(client, i))
			continue;

		float fTargetPos[3];
		GetClientAbsOrigin(i, fTargetPos);

		if (GetVectorDistance(fPos, fTargetPos, true) <= fRadiusSquared)
		{
			iPlayerDamage += RoundToFloor(fDamage);
			SDKHooks_TakeDamage(i, 0, client, fDamage, DMG_PREVENT_PHYSICS_FORCE | DMG_CRUSH | DMG_ALWAYSGIB | DMG_BLAST);
		}
	}

	int iShockwave = CreateParticle(client, "rd_robot_explosion_shockwave");
	KILL_ENT_IN(iShockwave,1.0);

	int iExplosion = CreateParticle(client, "rd_robot_explosion");
	KILL_ENT_IN(iExplosion,1.0);

	PrintToChat(client, CHAT_PREFIX ... " %T", "RTD2_Perk_Timebomb_Damage", LANG_SERVER, 0x03, iPlayerDamage, 0x01);
	EmitSoundToAll(SOUND_EXPLODE, client);

	FakeClientCommandEx(client, "explode");
}

public Action Timebomb_OnTakeDamage(int client, int& iAttacker, int& iInflictor, float& fDamage, int& iType)
{
	fDamage *= float(Cache[client].Resistance) / 100.0;
	EmitSoundToAll(g_sResistanceMedium[GetRandomInt(0, sizeof(g_sResistanceMedium) - 1)], client);

	return Plugin_Changed;
}

public Action Timebomb_TickSlow(const int client)
{
	Timebomb_Beep(client);

	if (GetEngineTime() > Cache[client].PrimeThreshold)
	{
		Cache[client].Repeat(TICKS_FAST, Timebomb_TickFast);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public Action Timebomb_TickFast(const int client)
{
	Timebomb_Beep(client);

	if (GetEngineTime() > Cache[client].DetonateThreshold)
	{
		EmitSoundToAll(SOUND_TIMEBOMB_GOFF, client);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

void Timebomb_Beep(const int client)
{
	EmitSoundToAll(SOUND_TIMEBOMB_TICK, client);
	SendTEParticleAttached(TEParticles.ShockwaveAirLight, Cache[client].GetEnt(Bomb).Index);
}

int Timebomb_SpawnBombHead(const int client)
{
	int iBomb = CreateEntityByName("prop_dynamic");
	if (iBomb <= MaxClients)
		return 0;

	DispatchKeyValue(iBomb, "model", MODEL_BOMB);

	switch (TF2_GetClientTeam(client))
	{
		case TFTeam_Blue:
			DispatchKeyValue(iBomb, "rendercolor", "100 100 255 255");

		case TFTeam_Red:
			DispatchKeyValue(iBomb, "rendercolor", "255 100 100 255");
	}

	DispatchSpawn(iBomb);

	SetVariantString("!activator");
	AcceptEntityInput(iBomb, "SetParent", client, -1, 0);

	switch (Shared[client].ClassForPerk)
	{
		case TFClass_Pyro, TFClass_Engineer:
			SetVariantString("OnUser1 !self,SetParentAttachment,head,0.0,-1");

		default:
			SetVariantString("OnUser1 !self,SetParentAttachment,eyes,0.0,-1");
	}

	AcceptEntityInput(iBomb, "AddOutput");
	AcceptEntityInput(iBomb, "FireUser1");

	return iBomb;
}

#undef MODEL_BOMB

#undef SOUND_TIMEBOMB_TICK
#undef SOUND_TIMEBOMB_GOFF
#undef SOUND_EXPLODE

#undef TICKS_SLOW
#undef TICKS_FAST

#undef Resistance
#undef Damage
#undef RadiusSquared
#undef PrimeThreshold
#undef DetonateThreshold
#undef Bomb
