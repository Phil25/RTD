/**
* Fire Breath perk.
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

#define FIREBREATH_SOUND_ATTACK "player/taunt_fire.wav"

#define Rate Float[0]
#define CritChance Float[1]
#define LastAttack Float[2]

DEFINE_CALL_APPLY(FireBreath)

public void FireBreath_Init(const Perk perk)
{
	PrecacheSound(FIREBREATH_SOUND_ATTACK);

	Events.OnVoice(perk, FireBreath_OnVoice);
}

void FireBreath_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Rate = perk.GetPrefFloat("rate", 2.0);
	Cache[client].CritChance = perk.GetPrefFloat("crit", 0.05);
	Cache[client].LastAttack = 0.0;

	Notify.Attack(client);
}

void FireBreath_OnVoice(const int client)
{
	float fTime = GetEngineTime();
	if (fTime < Cache[client].LastAttack + Cache[client].Rate)
		return;

	Cache[client].LastAttack = fTime;

	float fShake[3];
	fShake[0] = GetRandomFloat(-5.0, -25.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fShake);

	FireBreath_Fireball(client);
	EmitSoundToAll(FIREBREATH_SOUND_ATTACK, client);
}

/*
	Code borrowed from: [TF2] Spell casting!
	https://forums.alliedmods.net/showthread.php?p=2054678
*/
void FireBreath_Fireball(const int client)
{
	float fAng[3], fPos[3];
	GetClientEyeAngles(client, fAng);
	GetClientEyePosition(client, fPos);

	int iTeam = GetClientTeam(client);
	int iSpell = CreateEntityByName("tf_projectile_spellfireball");

	if (!IsValidEntity(iSpell))
		return;

	float fVel[3];
	GetAngleVectors(fAng, fVel, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fVel, 1100.0); // speed of a rocket

	SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(iSpell, Prop_Send, "m_bCritical", GetURandomFloat() <= Cache[client].CritChance, 1);
	SetEntProp(iSpell, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iSpell, Prop_Send, "m_nSkin", iTeam - 2);

	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0);

	DispatchSpawn(iSpell);
	TeleportEntity(iSpell, fPos, fAng, fVel);
}

#undef FIREBREATH_SOUND_ATTACK

#undef Rate
#undef CritChance
#undef LastAttack
