/**
* Pumpkin Trail perk.
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

#define SOUND_ACALLBEYOND_CONJURE "misc/flame_engulf.wav"
#define ACALLBEYOND_SIZE 70.0

#define Amount Int[0]
#define Rate Float[0]
#define Damage Float[1]
#define LastAttack Float[2]

static char g_sSoundAirStrikeFire[][] = {
	"weapons/airstrike_fire_01.wav",
	"weapons/airstrike_fire_02.wav",
	"weapons/airstrike_fire_03.wav"
};

DEFINE_CALL_APPLY(ACallBeyond)

public void ACallBeyond_Init(const Perk perk)
{
	PrecacheSound(SOUND_ACALLBEYOND_CONJURE);
	PrecacheSound(g_sSoundAirStrikeFire[0]);
	PrecacheSound(g_sSoundAirStrikeFire[1]);
	PrecacheSound(g_sSoundAirStrikeFire[2]);

	Events.OnVoice(perk, ACallBeyond_OnVoice);
}

public void ACallBeyond_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Amount = perk.GetPrefCell("amount", 6);
	Cache[client].Rate = perk.GetPrefFloat("rate", 3.0);
	Cache[client].Damage = perk.GetPrefFloat("damage", 40.0);
	Cache[client].LastAttack = 0.0;

	PrintToChat(client, CHAT_PREFIX ... " %T", "RTD2_Perk_Attack", LANG_SERVER, 0x03, 0x01);
}

void ACallBeyond_OnVoice(const int client)
{
	float fTime = GetEngineTime();
	if (fTime < Cache[client].LastAttack + Cache[client].Rate)
		return;

	Cache[client].LastAttack = fTime;
	ACallBeyond_SpawnMultiple(client);
}

void ACallBeyond_SpawnMultiple(const int client)
{
	float fPos[3];
	GetClientEyePosition(client, fPos);
	fPos[2] += 80.0;

	CreateEffect(fPos, "eyeboss_tp_vortex", 2.0);
	EmitSoundToAll(SOUND_ACALLBEYOND_CONJURE, client, _, _, _, _, 50);

	int iTeam = GetClientTeam(client);
	int iAmount = Cache[client].Amount;
	float fDamage = Cache[client].Damage;

	for (int i = 0; i < iAmount; ++i)
		ACallBeyond_Spawn(fPos, client, iTeam, fDamage);
}

void ACallBeyond_Spawn(float fOrigPos[3], int client, int iTeam, float fDamage)
{
	int iSpell = CreateEntityByName("tf_projectile_energy_ball");
	if (iSpell <= MaxClients)
		return;

	SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(iSpell, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iSpell, Prop_Send, "m_nSkin", iTeam -2);
	SetEntPropVector(iSpell, Prop_Send, "m_vInitialVelocity", view_as<float>({600.0, 600.0, 600.0}));
	SetEntDataFloat(iSpell, PropOffsets.EnergyBallDamage, fDamage, true);

	DispatchSpawn(iSpell);

	float fPos[3], fAng[3];
	fAng[0] = 270.0;

	for (int i = 0; i < 3; ++i)
	{
		fPos[i] = fOrigPos[i] +GetRandomFloat(-ACALLBEYOND_SIZE, ACALLBEYOND_SIZE);
		fAng[i] += GetRandomFloat(-60.0, 60.0);
	}

	TeleportEntity(iSpell, fPos, fAng, NULL_VECTOR);
	CreateTimer(2.0, Timer_ACallBeyond_PushToHoming, EntIndexToEntRef(iSpell));
	KILL_ENT_IN(iSpell,10.0);
}

public Action Timer_ACallBeyond_PushToHoming(Handle hTimer, const int iRef)
{
	int iSpell = EntRefToEntIndex(iRef);
	if (iSpell <= MaxClients)
		return Plugin_Stop;

	EmitSoundToAll(g_sSoundAirStrikeFire[GetRandomInt(0, 2)], iSpell, _, _, _, _, 250);
	TeleportEntity(iSpell, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, 100.0}));
	Homing_Push(iSpell, _, 4);

	return Plugin_Stop;
}

#undef SOUND_ACALLBEYOND_CONJURE
#undef ACALLBEYOND_SIZE

#undef Amount
#undef Rate
#undef Damage
#undef LastAttack
