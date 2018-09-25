/**
* Deadly Voice perk.
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

#define LAST_ATTACK 0
#define RATE 1
#define RANGE 2
#define DAMAGE 3

#define DEADLYVOICE_SOUND_ATTACK "weapons/cow_mangler_explosion_charge_04.wav"

char g_sDeadlyVoiceParticles[][] = {
	"default", "default",
	"powerup_supernova_explode_red",
	"powerup_supernova_explode_blue"
};

int g_iDeadlyVoiceId = 36;

void DeadlyVoice_Start(){
	PrecacheSound(DEADLYVOICE_SOUND_ATTACK);
}

void DeadlyVoice_Perk(int client, Perk perk, bool apply){
	if(apply) DeadlyVoice_ApplyPerk(client, perk);
	else UnsetClientPerkCache(client, g_iDeadlyVoiceId);
}

void DeadlyVoice_ApplyPerk(int client, Perk perk){
	g_iDeadlyVoiceId = perk.Id;
	SetClientPerkCache(client, g_iDeadlyVoiceId);

	SetFloatCache(client, 0.0, LAST_ATTACK);
	SetFloatCache(client, perk.GetPrefFloat("rate"), RATE);
	SetFloatCache(client, perk.GetPrefFloat("range"), RANGE);
	SetFloatCache(client, perk.GetPrefFloat("damage"), DAMAGE);

	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Attack", LANG_SERVER, 0x03, 0x01);
}

void DeadlyVoice_Voice(int client){
	if(!CheckClientPerkCache(client, g_iDeadlyVoiceId))
		return;

	float fRate = GetFloatCache(client, RATE);
	float fEngineTime = GetEngineTime();

	if(fEngineTime < GetFloatCache(client, LAST_ATTACK) +fRate)
		return;
	SetFloatCache(client, fEngineTime, LAST_ATTACK);

	int iParticle = CreateParticle(client, g_sDeadlyVoiceParticles[GetClientTeam(client)]);
	KillEntIn(iParticle, fRate);

	float fShake[3];
	fShake[0] = GetRandomFloat(-5.0, -25.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fShake);

	float fPos[3];
	GetClientEyePosition(client, fPos);

	float fRange = GetFloatCache(client, RANGE);
	float fDamage = GetFloatCache(client, DAMAGE);

	DamageRadius(fPos, iParticle, client, fRange, fDamage, DMG_BLAST, _, _, DeadlyVoice_OnDamage);
	EmitSoundToAll(DEADLYVOICE_SOUND_ATTACK, client);
}

void DeadlyVoice_OnDamage(int client, int iAttacker, float fDamage){
	if(IsFakeClient(client))
		return;

	float fPunch[3];
	fPunch[0] = GetRandomFloat(-15.0, 15.0);
	fPunch[1] = GetRandomFloat(-15.0, 15.0);
	fPunch[2] = GetRandomFloat(-15.0, 15.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fPunch);
}

#undef LAST_ATTACK
#undef RATE
#undef RANGE
#undef DAMAGE
