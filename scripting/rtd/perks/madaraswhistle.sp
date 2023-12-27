/**
* Madaras Whistle perk.
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

#define SOUND_WHISTLE "passtime/whistle.wav"
#define MODEL_GATOR "models/props_island/crocodile/crocodile.mdl"
#define ANIM_GATOR "attack"

#define DamageOthers Int[0]
#define DamageSelf Int[1]
#define Rate Float[0]
#define Delay Float[1]
#define Range Float[2]
#define LastAttack Float[3]

static char g_sGatorRumble[][] = {
	"ambient_mp3/lair/crocs_growl1.mp3",
	"ambient_mp3/lair/crocs_growl2.mp3",
	"ambient_mp3/lair/crocs_growl3.mp3",
	"ambient_mp3/lair/crocs_growl4.mp3",
	"ambient_mp3/lair/crocs_growl5.mp3",
};

DEFINE_CALL_APPLY(MadarasWhistle)

public void MadarasWhistle_Init(const Perk perk)
{
	PrecacheSound(SOUND_WHISTLE);
	PrecacheModel(MODEL_GATOR);

	for (int i = 0; i < 5; ++i)
		PrecacheSound(g_sGatorRumble[i]);

	Events.OnVoice(perk, MadarasWhistle_OnVoice);
}

void MadarasWhistle_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].DamageOthers = perk.GetPrefCell("damage", 150);
	Cache[client].DamageSelf = perk.GetPrefCell("selfdamage", 150);
	Cache[client].Rate = perk.GetPrefFloat("rate", 2.0);
	Cache[client].Delay = perk.GetPrefFloat("delay", 1.0);
	Cache[client].Range = perk.GetPrefFloat("range", 100.0);
	Cache[client].LastAttack = 0.0;

	Notify.Attack(client);
}

void MadarasWhistle_OnVoice(const int client)
{
	float fTime = GetEngineTime();
	if (fTime < Cache[client].LastAttack + Cache[client].Rate)
		return;

	Cache[client].LastAttack = fTime;

	float fPos[3];
	GetClientAbsOrigin(client, fPos);

	EmitSoundToAll(SOUND_WHISTLE, client, _, _, _, _, 180);

	DataPack hPack = new DataPack();
	hPack.WriteCell(GetClientUserId(client));
	hPack.WriteFloat(fPos[0]);
	hPack.WriteFloat(fPos[1]);
	hPack.WriteFloat(fPos[2]);

	CreateTimer(Cache[client].Delay, Timer_MadarasWhistle_Attack, hPack, TIMER_DATA_HNDL_CLOSE);

	int iParticle = CreateParticle(client, "waterfall_bottomsplash", false, "", view_as<float>({0.0, 0.0, 0.0}));
	EmitSoundToAll(g_sGatorRumble[GetRandomInt(0, 4)], iParticle);
	KillEntIn(iParticle, Cache[client].Delay);
}

public Action Timer_MadarasWhistle_Attack(Handle hTimer, DataPack hPack)
{
	hPack.Reset();
	int client = GetClientOfUserId(hPack.ReadCell());

	if (!client)
		return Plugin_Stop;

	float fPos[3];
	fPos[0] = hPack.ReadFloat();
	fPos[1] = hPack.ReadFloat();
	fPos[2] = hPack.ReadFloat();

	int iGator = MadarasWhistle_SpawnGator(fPos);
	if (iGator <= MaxClients)
		return Plugin_Stop;

	KILL_ENT_IN(iGator,1.0);

	float fRange = Cache[client].Range;
	float fDamage = float(Cache[client].DamageOthers);
	float fSelfDamage = float(Cache[client].DamageSelf);

	DamageRadius(fPos, iGator, client, fRange, fDamage, DMG_BLAST | DMG_ALWAYSGIB, fSelfDamage);

	return Plugin_Stop;
}

int MadarasWhistle_SpawnGator(float fPos[3])
{
	int iGator = CreateEntityByName("prop_dynamic_override");
	if (iGator <= MaxClients)
		return 0;

	DispatchKeyValue(iGator, "model", MODEL_GATOR);
	DispatchKeyValue(iGator, "modelscale", "2");
	DispatchSpawn(iGator);

	TeleportEntity(iGator, fPos, NULL_VECTOR, NULL_VECTOR);

	SetVariantString(ANIM_GATOR);
	AcceptEntityInput(iGator, "SetAnimation");

	return iGator;
}

#undef SOUND_WHISTLE
#undef MODEL_GATOR
#undef ANIM_GATOR

#undef DamageOthers
#undef DamageSelf
#undef Rate
#undef Delay
#undef Range
#undef LastAttack
