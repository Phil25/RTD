/**
* Deadly Voice perk.
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

#define DEADLYVOICE_SOUND_ATTACK "weapons/cow_mangler_explosion_charge_04.wav"

#define LastAttack Float[0]
#define Rate Float[1]
#define Range Float[2]
#define Damage Float[3]

static char g_sDeadlyVoiceParticles[][] = {
	"default", "default",
	"bombinomicon_burningdebris",
	"bombinomicon_burningdebris_halloween"
};

DEFINE_CALL_APPLY(DeadlyVoice)

public void DeadlyVoice_Init(const Perk perk)
{
	PrecacheSound(DEADLYVOICE_SOUND_ATTACK);

	Events.OnVoice(perk, DeadlyVoice_OnVoice);
}

void DeadlyVoice_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].LastAttack = 0.0;
	Cache[client].Rate = perk.GetPrefFloat("rate", 0.8);
	Cache[client].Range = perk.GetPrefFloat("range", 196.0);
	Cache[client].Damage = perk.GetPrefFloat("damage", 72.0);

	PrintToChat(client, "%s %T", CHAT_PREFIX, "RTD2_Perk_Attack", LANG_SERVER, 0x03, 0x01);
}

void DeadlyVoice_OnVoice(const int client)
{
	float fEngineTime = GetEngineTime();
	float fRate = Cache[client].Rate;

	if (fEngineTime < Cache[client].LastAttack + fRate)
		return;

	Cache[client].LastAttack = fEngineTime;

	int iParticle = CreateParticle(client, g_sDeadlyVoiceParticles[GetClientTeam(client)]);
	KillEntIn(iParticle, fRate);

	float fShake[3];
	fShake[0] = GetRandomFloat(-5.0, -25.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fShake);

	float fPos[3];
	GetClientEyePosition(client, fPos);

	DamageRadius(fPos, iParticle, client, Cache[client].Range, Cache[client].Damage, DMG_BLAST, _, _, DeadlyVoice_OnDamage);
	EmitSoundToAll(DEADLYVOICE_SOUND_ATTACK, client);
}

void DeadlyVoice_OnDamage(int client, int iAttacker, float fDamage)
{
	if (!IsFakeClient(client))
		ViewPunchRand(client, 15.0);
}

#undef DEADLYVOICE_SOUND_ATTACK

#undef LastAttack
#undef Rate
#undef Range
#undef Damage
