/**
* Paranoia perk.
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

#define MODEL_SPY "models/player/spy.mdl"

#define VoiceTick Int[0]
#define VisualTick Int[1]
#define EnemyParticle Int[2]
#define Rotator EntSlot_1
#define Spy EntSlot_2

static char g_sSpyVoices[][] = {
	"vo/taunts/spy_taunts01.mp3", // Promise not to bleed on my suit...
	"vo/taunts/spy_taunts01.mp3", // Promise not to bleed on my suit...
	"vo/taunts/spy_taunts01.mp3", // Promise not to bleed on my suit...
	"vo/taunts/spy_taunts05.mp3", // (whistle)
	"vo/taunts/spy_taunts05.mp3", // (whistle)
	"vo/taunts/spy_taunts05.mp3", // (whistle)
	"vo/taunts/spy_taunts06.mp3", // Peek-a-boo!
	"vo/taunts/spy_taunts10.mp3", // I'm coming for you.
	"vo/taunts/spy_taunts11.mp3", // May I make a suggestion? Run.
	"vo/spy_mvm_resurrect09.mp3", // He he he he.
	"vo/spy_sf13_influx_small05.mp3", // Mhmhm he he.
	"vo/spy_sf13_influx_small06.mp3", // Mhmhmhmmm.
	"vo/spy_meleedare01.mp3", // Let's settle this like gentlemen!
	"vo/spy_meleedare01.mp3", // Let's settle this like gentlemen!
	"vo/spy_meleedare01.mp3", // Let's settle this like gentlemen!
	"vo/spy_meleedare02.mp3", // Queen's rules?
	"vo/spy_meleedare02.mp3", // Queen's rules?
	"vo/spy_meleedare02.mp3", // Queen's rules?
	"vo/spy_laughshort01.mp3",
	"vo/spy_laughshort02.mp3",
	"vo/spy_laughshort03.mp3",
	"vo/spy_laughshort04.mp3",
	"vo/spy_laughshort05.mp3",
	"vo/spy_laughshort06.mp3",
};

static char g_sSpyNoises[][] = {
	"player/spy_cloak.wav",
	"player/spy_disguise.wav",
	"player/spy_uncloak.wav",
	"player/spy_uncloak.wav",
	"player/spy_uncloak.wav",
	"player/spy_uncloak.wav",
	"player/spy_uncloak.wav",
	"player/spy_uncloak_feigndeath.wav",
	"player/spy_uncloak_feigndeath.wav",
	"player/spy_uncloak_feigndeath.wav",
};

static char g_sSpyAnimations[][] = {
	"primary_death_burning",
	"secondrate_sorcery_spy",
	"spy_replay_taunt",
	"taunt05", // spycrab
	"taunt06", // thriller
	"taunt_aerobic_B", // lots of side movement
	"taunt_yeti",
	// below are regular running animations which don't require blending
	"x_runS_PDA",
	"x_runS_PDA",
	"x_runS_PDA",
	"x_runSE_PDA",
	"x_runSE_PDA",
	"x_runSE_PDA",
	"x_runSW_PDA",
	"x_runSW_PDA",
	"x_runSW_PDA",
};

DEFINE_CALL_APPLY(Paranoia)

public void Paranoia_Init(const Perk perk)
{
	PrecacheModel(MODEL_SPY); // does this really need precaching?
}

public void Paranoia_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].VoiceTick = Paranoia_GetTicks();
	Cache[client].VisualTick = Paranoia_GetTicks();

	switch (TF2_GetClientTeam(client))
	{
		case TFTeam_Red:
			Cache[client].EnemyParticle = view_as<int>(TEParticlesLingering.SpyBodyDisguiseBlue);

		case TFTeam_Blue:
			Cache[client].EnemyParticle = view_as<int>(TEParticlesLingering.SpyBodyDisguiseRed);
	}

	int iRot = CreateEntityByName("func_rotating");
	if (iRot > MaxClients)
	{
		DispatchKeyValue(iRot, "solid", "0");
		DispatchKeyValue(iRot, "spawnflags", "1"); // start on
		DispatchKeyValue(iRot, "maxspeed", "50");
		DispatchSpawn(iRot);

		Cache[client].SetEnt(Rotator, iRot);
	}

	int iProp = CreateEntityByName("prop_dynamic");
	if (iProp > MaxClients)
	{
		DispatchKeyValue(iProp, "model", MODEL_SPY);
		SetEntityRenderMode(iProp, RENDER_NONE);
		DispatchSpawn(iProp);

		// Add NOSHADOW flag
		int iFlags = GetEntProp(iProp, Prop_Send, "m_fEffects");
		SetEntProp(iProp, Prop_Send, "m_fEffects", iFlags | 16);

		Cache[client].SetEnt(Spy, iProp);
	}

	Cache[client].Repeat(0.5, Paranoia_Voice);
	Cache[client].Repeat(0.5, Paranoia_Visual);
}

Action Paranoia_Voice(const int client)
{
	if (--Cache[client].VoiceTick > 0)
		return Plugin_Continue;

	Cache[client].VoiceTick = Paranoia_GetTicks();

	Paranoia_EmitSound(client, g_sSpyVoices, sizeof(g_sSpyVoices));

	return Plugin_Continue;
}

Action Paranoia_Visual(const int client)
{
	if (--Cache[client].VisualTick > 0)
		return Plugin_Continue;

	Cache[client].VisualTick = Paranoia_GetTicks();

	Paranoia_EmitSound(client, g_sSpyNoises, sizeof(g_sSpyNoises));

	int iProp = Cache[client].GetEnt(Spy).Index;
	int iRot = Cache[client].GetEnt(Rotator).Index;

	if (iProp <= MaxClients || iRot <= MaxClients)
		return Plugin_Continue;

	float fPos[3];
	GetClientAbsOrigin(client, fPos);

	fPos[0] += GetRandomFloat(100.0, 200.0) * GetRandomSign();
	fPos[1] += GetRandomFloat(100.0, 200.0) * GetRandomSign();

	AcceptEntityInput(iProp, "ClearParent");
	TeleportEntity(iProp, fPos, NULL_VECTOR, NULL_VECTOR);

	SetVariantString(g_sSpyAnimations[GetRandomInt(0, sizeof(g_sSpyAnimations) - 1)]);
	AcceptEntityInput(iProp, "SetAnimation");

	SendTEParticleLingeringAttachedProxyOnly(view_as<TEParticleLingeringId>(Cache[client].EnemyParticle), iProp, client, _, true);

	if (GetRandomInt(0, 1))
		AcceptEntityInput(iRot, "Reverse");

	TeleportToClient(iRot, client);
	Parent(iProp, iRot);

	return Plugin_Continue;
}

void Paranoia_EmitSound(const int client, const char[][] sArray, const int iArrayLength)
{
	int iSource = CreateEntityByName("info_target");
	if (iSource <= MaxClients)
		return;

	KILL_ENT_IN(iSource,0.1);

	DispatchSpawn(iSource);

	float fPos[3];
	GetClientAbsOrigin(client, fPos);

	fPos[0] += GetRandomFloat(-100.0, 100.0);
	fPos[1] += GetRandomFloat(-100.0, 100.0);
	TeleportEntity(iSource, fPos, NULL_VECTOR, NULL_VECTOR);

	EmitSoundToClient(client, sArray[GetRandomInt(0, iArrayLength - 1)], iSource);
}

int Paranoia_GetTicks()
{
	return GetRandomInt(5, 8);
}

#undef MODEL_SPY

#undef VoiceTick
#undef VisualTick
#undef EnemyParticle
#undef Rotator
#undef Spy
