/**
* Fire Breath perk.
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


#define FIREBREATH_SOUND_ATTACK "player/taunt_fire.wav"

#define RATE 0
#define CRIT_CHANCE 1
#define LAST_ATTACK 2

int g_iFireBreathId = 49;

void FireBreath_Start(){
	PrecacheSound(FIREBREATH_SOUND_ATTACK);
}

public void FireBreath_Call(int client, Perk perk, bool apply){
	if(apply) FireBreath_ApplyPerk(client, perk);
	else UnsetClientPerkCache(client, g_iFireBreathId);
}

void FireBreath_ApplyPerk(int client, Perk perk){
	g_iFireBreathId = perk.Id;
	SetClientPerkCache(client, g_iFireBreathId);

	SetFloatCache(client, perk.GetPrefFloat("rate"), RATE);
	SetFloatCache(client, perk.GetPrefFloat("crit"), CRIT_CHANCE);
	SetFloatCache(client, 0.0, LAST_ATTACK);

	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Attack", LANG_SERVER, 0x03, 0x01);
}

void FireBreath_Voice(int client){
	if(!CheckClientPerkCache(client, g_iFireBreathId))
		return;

	float fEngineTime = GetEngineTime();
	if(fEngineTime < GetFloatCache(client, LAST_ATTACK) +GetFloatCache(client, RATE))
		return;
	SetFloatCache(client, fEngineTime, LAST_ATTACK);

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

void FireBreath_Fireball(int client){
	float fAng[3], fPos[3];
	GetClientEyeAngles(client, fAng);
	GetClientEyePosition(client, fPos);

	int iTeam	= GetClientTeam(client);
	int iSpell	= CreateEntityByName("tf_projectile_spellfireball");

	if(!IsValidEntity(iSpell))
		return;

	float fVel[3], fBuf[3];
	GetAngleVectors(fAng, fBuf, NULL_VECTOR, NULL_VECTOR);
	fVel[0] = fBuf[0]*1100.0; //Speed of a tf2 rocket.
	fVel[1] = fBuf[1]*1100.0;
	fVel[2] = fBuf[2]*1100.0;

	SetEntPropEnt	(iSpell, Prop_Send, "m_hOwnerEntity",	client);
	bool bCrit = GetURandomFloat() <= GetFloatCache(client, CRIT_CHANCE);
	SetEntProp		(iSpell, Prop_Send, "m_bCritical",		bCrit, 1);
	SetEntProp		(iSpell, Prop_Send, "m_iTeamNum",		iTeam, 1);
	SetEntProp		(iSpell, Prop_Send, "m_nSkin",			iTeam -2);

	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0);

	DispatchSpawn(iSpell);
	TeleportEntity(iSpell, fPos, fAng, fVel);
}

#undef RATE
#undef CRIT_CHANCE
#undef LAST_ATTACK
