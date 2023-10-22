/**
* Cache memory for perks to share.
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


enum struct ClientFlags{
	int iVals[4]; // SM ints are 32 bit, 4 are needed to hold 100 players

	void Set(const int iIndex){
		int iOverflows = iIndex / 32;
		this.iVals[iOverflows] |= 1 << (iIndex - 32 * iOverflows);
	}

	void Unset(const int iIndex){
		int iOverflows = iIndex / 32;
		this.iVals[iOverflows] &= ~(1 << (iIndex - 32 * iOverflows));
	}

	bool Test(const int iIndex){
		int iOverflows = iIndex / 32;
		return view_as<bool>(this.iVals[iOverflows] & (1 << (iIndex - 32 * iOverflows)));
	}

	void Reset(){
		this.iVals[0] = 0;
		this.iVals[1] = 0;
		this.iVals[2] = 0;
		this.iVals[3] = 0;
	}
}

enum TEParticle{
	TEParticle_ExplosionLarge,
	TEParticle_ExplosionLargeShockwave,
	TEParticle_GreenFog,
	TEParticle_GreenBitsTwirl,
	TEParticle_GreenBitsImpact,
	TEParticle_LingeringFogSmall,
	TEParticle_SmokePuff,
	TEParticle_WaterSteam,
	TEParticle_GasPasserImpactBlue,
	TEParticle_GasPasserImpactRed,
	TEParticle_BulletImpactHeavy,
	TEParticle_BulletImpactHeavier,
	TEParticle_IceImpact,
	TEParticle_PickupTrailBlue,
	TEParticle_PickupTrailRed,
	TEParticle_LootExplosion,
	TEParticle_ExplosionWooden,
	TEParticle_ExplosionEmbersOnly,
	TEParticle_ShockwaveFlat,
	TEParticle_ShockwaveBillboard,
	TEParticle_SnowBurst,
	TEParticle_ElectrocutedRed,
	TEParticle_ElectrocutedBlue,
	TEParticle_SparkVortexRed,
	TEParticle_SparkVortexBlue,
	TEParticle_PlayerStationarySilhouetteRed,
	TEParticle_PlayerStationarySilhouetteBlue,
	TEParticle_SmallPingWithEmbersRed,
	TEParticle_SmallPingWithEmbersBlue,
	TEParticle_SIZE,
}

enum TEParticleLingering{
	TEParticle_SnowFlakes,
	TEParticle_IceBodyGlow,
	TEParticle_Frostbite,
	TEParticle_ElectricMist,
	TEParticleLingering_SIZE,
}

enum struct EntMaterial{
	int iLaser;
	int iHalo;
}

enum struct PlayerAttachmentPoint{
	int Root; // always 0
	int Head;
	int Hat;
	int EyeL;
	int EyeR;
	int Flag;
	int Back;
	int HandL;
	int HandR;
	int FootL;
	int FootR;
}

int g_iTEParticleIds[TEParticle_SIZE];
int g_iTEParticleLingeringIds[TEParticleLingering_SIZE];
EntMaterial g_eEntMaterial;
PlayerAttachmentPoint g_ePlayerAttachments[10]; // per class

void Cache_OnMapStart(){
	g_iTEParticleIds[TEParticle_ExplosionLarge] = GetEffectIndex("rd_robot_explosion");
	g_iTEParticleIds[TEParticle_ExplosionLargeShockwave] = GetEffectIndex("rd_robot_explosion_shockwave");
	g_iTEParticleIds[TEParticle_GreenFog] = GetEffectIndex("merasmus_spawn_fog");
	g_iTEParticleIds[TEParticle_GreenBitsTwirl] = GetEffectIndex("merasmus_tp_bits");
	g_iTEParticleIds[TEParticle_GreenBitsImpact] = GetEffectIndex("merasmus_shoot_bits");
	g_iTEParticleIds[TEParticle_LingeringFogSmall] = GetEffectIndex("god_rays_fog");
	g_iTEParticleIds[TEParticle_SmokePuff] = GetEffectIndex("taunt_yeti_flash");
	g_iTEParticleIds[TEParticle_WaterSteam] = GetEffectIndex("water_burning_steam");
	g_iTEParticleIds[TEParticle_GasPasserImpactBlue] = GetEffectIndex("gas_can_impact_blue");
	g_iTEParticleIds[TEParticle_GasPasserImpactRed] = GetEffectIndex("gas_can_impact_red");
	g_iTEParticleIds[TEParticle_BulletImpactHeavy] = GetEffectIndex("versus_door_sparks_floaty");
	g_iTEParticleIds[TEParticle_BulletImpactHeavier] = GetEffectIndex("versus_door_sparksB");
	g_iTEParticleIds[TEParticle_IceImpact] = GetEffectIndex("xms_icicle_impact");
	g_iTEParticleIds[TEParticle_PickupTrailBlue] = GetEffectIndex("duck_collect_trail_special_blue");
	g_iTEParticleIds[TEParticle_PickupTrailRed] = GetEffectIndex("duck_collect_trail_special_red");
	g_iTEParticleIds[TEParticle_LootExplosion] = GetEffectIndex("mvm_loot_explosion");
	g_iTEParticleIds[TEParticle_ExplosionWooden] = GetEffectIndex("mvm_pow_gold_seq_firework_mid");
	g_iTEParticleIds[TEParticle_ExplosionEmbersOnly] = GetEffectIndex("mvm_tank_destroy_embers");
	g_iTEParticleIds[TEParticle_ShockwaveFlat] = GetEffectIndex("Explosion_ShockWave_01");
	g_iTEParticleIds[TEParticle_ShockwaveBillboard] = GetEffectIndex("airburst_shockwave");
	g_iTEParticleIds[TEParticle_SnowBurst] = GetEffectIndex("xms_snowburst");
	g_iTEParticleIds[TEParticle_ElectrocutedRed] = GetEffectIndex("electrocuted_red");
	g_iTEParticleIds[TEParticle_ElectrocutedBlue] = GetEffectIndex("electrocuted_blue");
	g_iTEParticleIds[TEParticle_SparkVortexRed] = GetEffectIndex("teleportedin_red");
	g_iTEParticleIds[TEParticle_SparkVortexBlue] = GetEffectIndex("teleportedin_blue");
	g_iTEParticleIds[TEParticle_PlayerStationarySilhouetteRed] = GetEffectIndex("player_sparkles_red");
	g_iTEParticleIds[TEParticle_PlayerStationarySilhouetteBlue] = GetEffectIndex("player_sparkles_blue");
	g_iTEParticleIds[TEParticle_SmallPingWithEmbersBlue] = GetEffectIndex("powercore_embers_blue");
	g_iTEParticleIds[TEParticle_SmallPingWithEmbersRed] = GetEffectIndex("powercore_embers_red");

	g_iTEParticleLingeringIds[TEParticle_SnowFlakes] = GetEffectIndex("utaunt_ice_snowflakes");
	g_iTEParticleLingeringIds[TEParticle_IceBodyGlow] = GetEffectIndex("utaunt_ice_bodyglow");
	g_iTEParticleLingeringIds[TEParticle_Frostbite] = GetEffectIndex("unusual_eotl_frostbite");
	g_iTEParticleLingeringIds[TEParticle_ElectricMist] = GetEffectIndex("utaunt_electric_mist");

	g_eEntMaterial.iLaser = PrecacheModel("materials/sprites/laser.vmt");
	g_eEntMaterial.iHalo = PrecacheModel("materials/sprites/halo01.vmt");

	g_ePlayerAttachments[TFClass_Scout].FootL = 4;
	g_ePlayerAttachments[TFClass_Scout].FootR = 5;
	g_ePlayerAttachments[TFClass_Scout].Back = 7;
	g_ePlayerAttachments[TFClass_Scout].Hat = 10;
	g_ePlayerAttachments[TFClass_Scout].Head = 12;
	g_ePlayerAttachments[TFClass_Scout].EyeL = 13;
	g_ePlayerAttachments[TFClass_Scout].EyeR = 14;
	g_ePlayerAttachments[TFClass_Scout].HandL = 16;
	g_ePlayerAttachments[TFClass_Scout].HandR = 21;
	g_ePlayerAttachments[TFClass_Scout].Flag = 22;

	g_ePlayerAttachments[TFClass_Soldier].Back = 4;
	g_ePlayerAttachments[TFClass_Soldier].FootL = 5;
	g_ePlayerAttachments[TFClass_Soldier].FootR = 6;
	g_ePlayerAttachments[TFClass_Soldier].Hat = 7;
	g_ePlayerAttachments[TFClass_Soldier].Head = 8;
	g_ePlayerAttachments[TFClass_Soldier].EyeL = 9;
	g_ePlayerAttachments[TFClass_Soldier].EyeR = 10;
	g_ePlayerAttachments[TFClass_Soldier].HandL = 12;
	g_ePlayerAttachments[TFClass_Soldier].HandR = 16;
	g_ePlayerAttachments[TFClass_Soldier].Flag = 17;

	g_ePlayerAttachments[TFClass_Pyro].Head = 1;
	g_ePlayerAttachments[TFClass_Pyro].EyeL = 2;
	g_ePlayerAttachments[TFClass_Pyro].EyeR = 3;
	g_ePlayerAttachments[TFClass_Pyro].HandL = 5;
	g_ePlayerAttachments[TFClass_Pyro].HandR = 11;
	g_ePlayerAttachments[TFClass_Pyro].Flag = 12;
	g_ePlayerAttachments[TFClass_Pyro].Back = 21;
	g_ePlayerAttachments[TFClass_Pyro].FootL = 22;
	g_ePlayerAttachments[TFClass_Pyro].FootR = 23;
	g_ePlayerAttachments[TFClass_Pyro].Hat = 24;

	g_ePlayerAttachments[TFClass_DemoMan].Back = 3;
	g_ePlayerAttachments[TFClass_DemoMan].FootL = 4;
	g_ePlayerAttachments[TFClass_DemoMan].FootR = 5;
	g_ePlayerAttachments[TFClass_DemoMan].Hat = 6;
	g_ePlayerAttachments[TFClass_DemoMan].Head = 7;
	g_ePlayerAttachments[TFClass_DemoMan].EyeL = 8;
	g_ePlayerAttachments[TFClass_DemoMan].EyeR = 9;
	g_ePlayerAttachments[TFClass_DemoMan].HandL = 12;
	g_ePlayerAttachments[TFClass_DemoMan].HandR = 14;
	g_ePlayerAttachments[TFClass_DemoMan].Flag = 16;

	g_ePlayerAttachments[TFClass_Heavy].Back = 4;
	g_ePlayerAttachments[TFClass_Heavy].FootL = 5;
	g_ePlayerAttachments[TFClass_Heavy].FootR = 6;
	g_ePlayerAttachments[TFClass_Heavy].Hat = 7;
	g_ePlayerAttachments[TFClass_Heavy].Head = 8;
	g_ePlayerAttachments[TFClass_Heavy].EyeL = 9;
	g_ePlayerAttachments[TFClass_Heavy].EyeR = 10;
	g_ePlayerAttachments[TFClass_Heavy].HandL = 11;
	g_ePlayerAttachments[TFClass_Heavy].HandR = 12;
	g_ePlayerAttachments[TFClass_Heavy].Flag = 13;

	g_ePlayerAttachments[TFClass_Engineer].Back = 1;
	g_ePlayerAttachments[TFClass_Engineer].FootL = 2;
	g_ePlayerAttachments[TFClass_Engineer].FootR = 3;
	g_ePlayerAttachments[TFClass_Engineer].Hat = 4;
	g_ePlayerAttachments[TFClass_Engineer].Head = 5;
	g_ePlayerAttachments[TFClass_Engineer].EyeR = 6; // yes, starts with right one
	g_ePlayerAttachments[TFClass_Engineer].EyeL = 7;
	g_ePlayerAttachments[TFClass_Engineer].HandL = 8;
	g_ePlayerAttachments[TFClass_Engineer].HandR = 10;
	g_ePlayerAttachments[TFClass_Engineer].Flag = 11;

	g_ePlayerAttachments[TFClass_Medic].Back = 4;
	g_ePlayerAttachments[TFClass_Medic].FootL = 5;
	g_ePlayerAttachments[TFClass_Medic].FootR = 6;
	g_ePlayerAttachments[TFClass_Medic].Hat = 7;
	g_ePlayerAttachments[TFClass_Medic].Head = 8;
	g_ePlayerAttachments[TFClass_Medic].EyeL = 9;
	g_ePlayerAttachments[TFClass_Medic].EyeR = 10;
	g_ePlayerAttachments[TFClass_Medic].HandL = 11;
	g_ePlayerAttachments[TFClass_Medic].HandR = 12;
	g_ePlayerAttachments[TFClass_Medic].Flag = 13;

	g_ePlayerAttachments[TFClass_Sniper].Back = 4;
	g_ePlayerAttachments[TFClass_Sniper].FootL = 5;
	g_ePlayerAttachments[TFClass_Sniper].FootR = 6;
	g_ePlayerAttachments[TFClass_Sniper].Hat = 7;
	g_ePlayerAttachments[TFClass_Sniper].Head = 8;
	g_ePlayerAttachments[TFClass_Sniper].EyeL = 9;
	g_ePlayerAttachments[TFClass_Sniper].EyeR = 10;
	g_ePlayerAttachments[TFClass_Sniper].HandL = 11;
	g_ePlayerAttachments[TFClass_Sniper].HandR = 12;
	g_ePlayerAttachments[TFClass_Sniper].Flag = 13;

	g_ePlayerAttachments[TFClass_Spy].Back = 5;
	g_ePlayerAttachments[TFClass_Spy].FootL = 6;
	g_ePlayerAttachments[TFClass_Spy].FootR = 7;
	g_ePlayerAttachments[TFClass_Spy].Hat = 8;
	g_ePlayerAttachments[TFClass_Spy].Head = 10;
	g_ePlayerAttachments[TFClass_Spy].EyeL = 11;
	g_ePlayerAttachments[TFClass_Spy].EyeR = 12;
	g_ePlayerAttachments[TFClass_Spy].HandL = 14;
	g_ePlayerAttachments[TFClass_Spy].HandR = 19;
	g_ePlayerAttachments[TFClass_Spy].Flag = 20;
}

int GetTEParticleId(const TEParticle eTEParticle){
	return g_iTEParticleIds[eTEParticle];
}

int GetTEParticleLingeringId(const TEParticleLingering eTEParticle){
	return g_iTEParticleLingeringIds[eTEParticle];
}

EntMaterial GetEntMaterial(){
	return g_eEntMaterial;
}

PlayerAttachmentPoint GetPlayerAttachmentPoint(TFClassType eClass){
	return g_ePlayerAttachments[eClass];
}

int g_iClientPerkCache[MAXPLAYERS+1] = {-1, ...}; // Used to check if client has the current perk
int g_iEntCache[MAXPLAYERS+1][3]; // Used throughout perks to store their entities
float g_fCache[MAXPLAYERS+1][4];
int g_iCache[MAXPLAYERS+1][4];
ClientFlags g_eClientFlags[MAXPLAYERS+1];
ArrayList g_aCache[MAXPLAYERS+1] = {null, ...};

methodmap Cache{
	public Cache(const int client){
		return view_as<Cache>(client);
	}

	public void SetClientFlag(const int iIndex){
		g_eClientFlags[view_as<int>(this)].Set(iIndex);
	}

	public void UnsetClientFlag(const int iIndex){
		g_eClientFlags[view_as<int>(this)].Unset(iIndex);
	}

	public bool TestClientFlag(const int iIndex){
		return g_eClientFlags[view_as<int>(this)].Test(iIndex);
	}

	public void ResetClientFlags(){
		g_eClientFlags[view_as<int>(this)].Reset();
	}
}

int GetEntCache(int client, int iBlock=0){
	return EntRefToEntIndex(g_iEntCache[client][iBlock]);
}

int GetEntCacheRef(int client, int iBlock=0){
	return g_iEntCache[client][iBlock];
}

void SetEntCache(int client, int iEnt, int iBlock=0){
	int iCurEnt = EntRefToEntIndex(g_iEntCache[client][iBlock]);
	if(iCurEnt > MaxClients) AcceptEntityInput(iCurEnt, "Kill");
	g_iEntCache[client][iBlock] = EntIndexToEntRef(iEnt);
}

void KillEntCache(int client, int iBlock=0){
	if(g_iEntCache[client][iBlock] == INVALID_ENT_REFERENCE)
		return;

	int iEnt = EntRefToEntIndex(g_iEntCache[client][iBlock]);
	if(iEnt > MaxClients) AcceptEntityInput(iEnt, "Kill");

	g_iEntCache[client][iBlock] = INVALID_ENT_REFERENCE;
}

void SetClientPerkCache(int client, int iPerkId){
	g_iClientPerkCache[client] = iPerkId;
}

void UnsetClientPerkCache(int client, int iPerkId){
	if(g_iClientPerkCache[client] == iPerkId)
		g_iClientPerkCache[client] = -1;
}

bool CheckClientPerkCache(int client, int iPerkId){
	return g_iClientPerkCache[client] == iPerkId;
}

float GetFloatCache(int client, int iBlock=0){
	return g_fCache[client][iBlock];
}

void SetFloatCache(int client, float fVal, int iBlock=0){
	g_fCache[client][iBlock] = fVal;
}

void GetVectorCache(int client, float fVec[3]){
	fVec[0] = GetFloatCache(client, 1);
	fVec[1] = GetFloatCache(client, 2);
	fVec[2] = GetFloatCache(client, 3);
}

void SetVectorCache(int client, float fVec[3]){
	SetFloatCache(client, fVec[0], 1);
	SetFloatCache(client, fVec[1], 2);
	SetFloatCache(client, fVec[2], 3);
}

int GetIntCache(int client, int iBlock=0){
	return g_iCache[client][iBlock];
}

bool GetIntCacheBool(int client, int iBlock=0){
	return view_as<bool>(g_iCache[client][iBlock]);
}

void SetIntCache(int client, int iVal, int iBlock=0){
	g_iCache[client][iBlock] = iVal;
}

ArrayList CreateArrayCache(int client, int iBlockSize=1){
	delete g_aCache[client];
	g_aCache[client] = new ArrayList(iBlockSize);
	return g_aCache[client];
}

ArrayList PrepareArrayCache(int client, int iBlockSize=1){
	if(g_aCache[client] == null || g_aCache[client].BlockSize != iBlockSize)
		return CreateArrayCache(client, iBlockSize);

	g_aCache[client].Clear();
	return g_aCache[client];
}

ArrayList GetArrayCache(int client){
	return g_aCache[client];
}
