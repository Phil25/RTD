/**
* Hat Throw perk.
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

#define MODEL_HAT "models/player/items/all_class/all_domination_Scout.mdl"
#define SOUND_HAT_IMPACT "weapons/loose_cannon_ball_impact.wav"

#define LastAttack Float[0]
#define Rate Float[1]
#define Speed Float[2]
#define Damage Float[3]

static char g_sSoundSwoosh[][] = {
	"passtime/projectile_swoosh3.wav",
	"passtime/projectile_swoosh4.wav"
};

static char g_sSoundHatHit[][] = {
	"weapons/demo_charge_hit_flesh1.wav",
	"weapons/demo_charge_hit_flesh2.wav",
	"weapons/demo_charge_hit_flesh3.wav"
};

DEFINE_CALL_APPLY(HatThrow)

public void HatThrow_Init(const Perk perk)
{
	PrecacheModel(MODEL_HAT);
	PrecacheSound(SOUND_HAT_IMPACT);
	PrecacheSound(g_sSoundSwoosh[0]);
	PrecacheSound(g_sSoundSwoosh[1]);
	PrecacheSound(g_sSoundHatHit[0]);
	PrecacheSound(g_sSoundHatHit[1]);
	PrecacheSound(g_sSoundHatHit[2]);

	Events.OnVoice(perk, HatThrow_OnVoice);
}

void HatThrow_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].LastAttack = 0.0;
	Cache[client].Rate = perk.GetPrefFloat("rate", 2.0);
	Cache[client].Speed = perk.GetPrefFloat("speed", 1100.0);
	Cache[client].Damage = perk.GetPrefFloat("damage", 150.0);

	Notify.Attack(client);
}

void HatThrow_OnVoice(const int client)
{
	float fTime = GetEngineTime();
	if (fTime < Cache[client].LastAttack + Cache[client].Rate)
		return;

	Cache[client].LastAttack = fTime;

	int iHat = CreateEntityByName("prop_dynamic");
	if (iHat <= MaxClients)
		return;

	KILL_ENT_IN(iHat,10.0);

	int iRot = CreateEntityByName("func_door_rotating");
	if (iRot <= MaxClients)
		return;

	KILL_ENT_IN(iRot,10.0);

	float fPos[3];
	GetClientEyePosition(client, fPos);

	DispatchKeyValueVector(iHat, "origin", fPos);
	DispatchKeyValueVector(iRot, "origin", fPos);
	DispatchKeyValue(iHat, "model", MODEL_HAT);
	DispatchKeyValue(iHat, "modelscale", "3");
	DispatchKeyValue(iRot, "distance", "99999");
	DispatchKeyValue(iRot, "speed", "2000");
	DispatchKeyValue(iRot, "spawnflags", "4104"); // passable | silent
	DispatchSpawn(iHat);
	DispatchSpawn(iRot);

	SetVariantString("!activator");
	AcceptEntityInput(iHat, "SetParent", iRot, iHat, 0);
	AcceptEntityInput(iRot, "Open");

	CreateTimer(0.1, Timer_HatThrow_Woosh, EntIndexToEntRef(iHat), TIMER_REPEAT);
	HatThrow_Launch(client, iRot);
}

public Action Timer_HatThrow_Woosh(Handle hTimer, const int iRef)
{
	int iEnt = EntRefToEntIndex(iRef);
	if (iEnt <= MaxClients)
		return Plugin_Stop;

	int iSound = GetEntProp(iEnt, Prop_Data, "m_bUsePuntSound");
	EmitSoundToAll(g_sSoundSwoosh[iSound], iEnt, _, _, _, _, 200);

	SetEntProp(iEnt, Prop_Data, "m_bUsePuntSound", !iSound);

	return Plugin_Continue;
}

void HatThrow_Launch(const int client, const int iHat)
{
	float fAng[3], fPos[3];
	GetClientEyeAngles(client, fAng);
	GetClientEyePosition(client, fPos);

	int iCarrier = CreateEntityByName("prop_physics_override");
	if (iCarrier <= MaxClients)
		return;

	KILL_ENT_IN(iCarrier,10.0);

	float fVel[3];
	GetAngleVectors(fAng, fVel, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fVel, Cache[client].Speed);

	SetEntPropEnt(iCarrier, Prop_Send, "m_hOwnerEntity", client);
	DispatchKeyValue(iCarrier, "model", MODEL_HAT);
	DispatchKeyValue(iCarrier, "modelscale", "0");
	DispatchSpawn(iCarrier);

	TeleportEntity(iCarrier, fPos, NULL_VECTOR, fVel);
	SetEntityMoveType(iCarrier, MOVETYPE_FLY);

	SetVariantString("!activator");
	AcceptEntityInput(iHat, "SetParent", iCarrier, iHat, 0);

	SDKHook(iCarrier, SDKHook_StartTouch, Event_HatThrow_OnHatTouch);
}

public Action Event_HatThrow_OnHatTouch(int iHat, int client)
{
	if (1 <= client <= MaxClients)
	{
		int iAttacker = GetEntPropEnt(iHat, Prop_Send, "m_hOwnerEntity");
		if (iAttacker && CanPlayerBeHurt(client, iAttacker))
			TakeDamage(client, iHat, iAttacker, Cache[iAttacker].Damage, DMG_CLUB);

		EmitSoundToAll(g_sSoundHatHit[GetRandomInt(0, 2)], iHat);
	}

	EmitSoundToAll(SOUND_HAT_IMPACT, iHat);

	float fPos[3];
	GetEntPropVector(iHat, Prop_Send, "m_vecOrigin", fPos);
	HatThrow_SpawnCorpse(fPos);

	AcceptEntityInput(iHat, "KillHierarchy");

	return Plugin_Handled;
}

void HatThrow_SpawnCorpse(float fPos[3])
{
	int iHat = CreateEntityByName("prop_physics_override");
	if(iHat <= MaxClients)
		return;

	DispatchKeyValueVector(iHat, "origin", fPos);
	DispatchKeyValue(iHat, "model", MODEL_HAT);
	DispatchKeyValue(iHat, "modelscale", "3");
	DispatchKeyValue(iHat, "spawnflags", "4"); // debris
	DispatchSpawn(iHat);

	float fAng[3];
	fAng[0] = GetRandomFloat(0.0, 360.0);
	fAng[1] = GetRandomFloat(0.0, 360.0);
	fAng[2] = GetRandomFloat(0.0, 360.0);

	TeleportEntity(iHat, NULL_VECTOR, fAng, NULL_VECTOR);
	SetEntityRenderFx(iHat, RENDERFX_FADE_SLOW);
	KILL_ENT_IN(iHat,1.0);
}

#undef MODEL_HAT
#undef SOUND_HAT_IMPACT

#undef LastAttack
#undef Rate
#undef Speed
#undef Damage