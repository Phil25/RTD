/**
* Pumpkin Trail perk.
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

#define SOUND_CONJURE "misc/flame_engulf.wav"

#define RATE 0
#define DAMAGE 1
#define LAST_ATTACK 2

int g_iACallBeyondId = 71;

void ACallBeyond_Start(){
	PrecacheSound(SOUND_CONJURE);
}

public void ACallBeyond_Call(int client, Perk perk, bool apply){
	if(apply) ACallBeyond_ApplyPerk(client, perk);
	else UnsetClientPerkCache(client, g_iACallBeyondId);
}

public void ACallBeyond_ApplyPerk(int client, Perk perk){
	g_iACallBeyondId = perk.Id;
	SetClientPerkCache(client, g_iACallBeyondId);

	SetFloatCache(client, perk.GetPrefFloat("rate"), RATE);
	SetFloatCache(client, perk.GetPrefFloat("damage"), DAMAGE);
	SetFloatCache(client, 0.0, LAST_ATTACK);

	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Attack", LANG_SERVER, 0x03, 0x01);
}

void ACallBeyond_Voice(int client){
	if(!CheckClientPerkCache(client, g_iACallBeyondId))
		return;

	float fTime = GetEngineTime();
	if(fTime < GetFloatCache(client, LAST_ATTACK) +GetFloatCache(client, RATE))
		return;

	SetFloatCache(client, fTime, LAST_ATTACK);
	ACallBeyond_SpawnMultiple(client);
}

void ACallBeyond_SpawnMultiple(int client){
	float fPos[3];
	GetClientEyePosition(client, fPos);
	fPos[2] += 100.0;

	CreateEffect(fPos, "ghost_smoke", 2.0);
	EmitSoundToAll(SOUND_CONJURE, client, _, _, _, _, 50);

	int iTeam = GetClientTeam(client);
	ACallBeyond_Spawn(fPos, -1.0, -1.0, client, iTeam);
	ACallBeyond_Spawn(fPos, 1.0, -1.0, client, iTeam);
	ACallBeyond_Spawn(fPos, -1.0, 1.0, client, iTeam);
	ACallBeyond_Spawn(fPos, 1.0, 1.0, client, iTeam);
}

void ACallBeyond_Spawn(float fPos[3], float fX, float fY, int client, int iTeam){
	int iSpell = CreateEntityByName("tf_projectile_spellfireball");
	if(iSpell <= MaxClients)
		return;

	SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(iSpell, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iSpell, Prop_Send, "m_nSkin", iTeam -2);
	SetEntPropVector(iSpell, Prop_Send, "m_vInitialVelocity", view_as<float>({1100.0, 1100.0, 1100.0}));

	DispatchSpawn(iSpell);

	fPos[0] += fX *100.0;
	fPos[1] += fY *100.0;
	TeleportEntity(iSpell, fPos, NULL_VECTOR, NULL_VECTOR);
	fPos[0] -= fX *100.0;
	fPos[1] -= fY *100.0;

	Homing_Push(iSpell);
	KILL_ENT_IN(iSpell,5.0)
}

#undef RATE
#undef DAMAGE
#undef LAST_ATTACK
