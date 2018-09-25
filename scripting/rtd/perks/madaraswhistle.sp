/**
* Madaras Whistle perk.
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


#define DEADLYVOICE_SOUND_ATTACK "weapons/cow_mangler_explosion_charge_04.wav"

#define SOUND_WHISTLE "passtime/whistle.wav"
#define MODEL_GATOR "models/props_island/crocodile/crocodile.mdl"
#define ANIM_GATOR "attack"

#define LAST_ATTACK 0
#define RATE 1
#define DELAY 2
#define RANGE 3

int g_iMadarasWhistleId = 61;

char g_sGatorRumble[][] = {
	"ambient_mp3/lair/crocs_growl1.mp3",
	"ambient_mp3/lair/crocs_growl2.mp3",
	"ambient_mp3/lair/crocs_growl3.mp3",
	"ambient_mp3/lair/crocs_growl4.mp3",
	"ambient_mp3/lair/crocs_growl5.mp3",
};

void MadarasWhistle_Start(){
	PrecacheSound(SOUND_WHISTLE);
	PrecacheModel(MODEL_GATOR);
	for(int i = 0; i < 5; ++i)
		PrecacheSound(g_sGatorRumble[i]);
}

void MadarasWhistle_Perk(int client, Perk perk, bool apply){
	if(apply) MadarasWhistle_ApplyPerk(client, perk);
	else UnsetClientPerkCache(client, g_iMadarasWhistleId);
}

void MadarasWhistle_ApplyPerk(int client, Perk perk){
	g_iMadarasWhistleId = perk.Id;
	SetClientPerkCache(client, g_iMadarasWhistleId);

	SetFloatCache(client, 0.0, LAST_ATTACK);
	SetFloatCache(client, perk.GetPrefFloat("rate"), RATE);
	SetFloatCache(client, perk.GetPrefFloat("delay"), DELAY);
	SetFloatCache(client, perk.GetPrefFloat("range"), RANGE);
	SetIntCache(client, perk.GetPrefCell("damage"));

	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Attack", LANG_SERVER, 0x03, 0x01);
}

void MadarasWhistle_Voice(int client){
	if(!CheckClientPerkCache(client, g_iMadarasWhistleId))
		return;

	float fEngineTime = GetEngineTime();
	if(fEngineTime < GetFloatCache(client, LAST_ATTACK) +GetFloatCache(client, RATE))
		return;

	SetFloatCache(client, fEngineTime, LAST_ATTACK);
	MadarasWhistle_Whistle(client);
}

void MadarasWhistle_Whistle(int client){
	float fPos[3];
	GetClientAbsOrigin(client, fPos);

	EmitSoundToAll(SOUND_WHISTLE, client, _, _, _, _, 180);
	DataPack hPack = new DataPack();

	float fDelay = GetFloatCache(client, DELAY);
	CreateTimer(fDelay, Timer_MadarasWhistle_Whistle, hPack);
	hPack.WriteCell(GetClientUserId(client));
	hPack.WriteFloat(fPos[0]);
	hPack.WriteFloat(fPos[1]);
	hPack.WriteFloat(fPos[2]);

	int iParticle = CreateParticle(client, "waterfall_bottomsplash", false, "", view_as<float>({0.0, 0.0, 0.0}));
	EmitSoundToAll(g_sGatorRumble[GetRandomInt(0, 4)], iParticle);
	KillEntIn(iParticle, fDelay);
}

public Action Timer_MadarasWhistle_Whistle(Handle hTimer, DataPack hPack){
	hPack.Reset();
	int client = GetClientOfUserId(hPack.ReadCell());
	if(!client) return Plugin_Stop;

	float fPos[3];
	fPos[0] = hPack.ReadFloat();
	fPos[1] = hPack.ReadFloat();
	fPos[2] = hPack.ReadFloat();

	delete hPack;
	MadarasWhistle_Summon(client, fPos);
	return Plugin_Stop;
}

void MadarasWhistle_Summon(int client, float fPos[3]){
	int iGator = MadarasWhistle_SpawnGator(fPos);
	if(!iGator) return;

	float fRange = GetFloatCache(client, RANGE);
	float fDamage = float(GetIntCache(client));
	DamageRadius(fPos, iGator, client, fRange, fDamage, DMG_BLAST|DMG_ALWAYSGIB, true);
	KILL_ENT_IN(iGator,1.0)
}

int MadarasWhistle_SpawnGator(float fPos[3]){
	int iGator = CreateEntityByName("prop_dynamic_override");
	if(iGator <= MaxClients || !IsValidEntity(iGator))
		return 0;

	DispatchKeyValue(iGator, "model", MODEL_GATOR);
	DispatchKeyValue(iGator, "modelscale", "2");
	DispatchSpawn(iGator);

	TeleportEntity(iGator, fPos, NULL_VECTOR, NULL_VECTOR);

	SetVariantString(ANIM_GATOR);
	AcceptEntityInput(iGator, "SetAnimation");
	return iGator;
}

#undef LAST_ATTACK
#undef RATE
#undef DELAY
#undef RANGE
