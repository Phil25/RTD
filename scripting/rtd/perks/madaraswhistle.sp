#define DEADLYVOICE_SOUND_ATTACK "weapons/cow_mangler_explosion_charge_04.wav"

#define SOUND_WHISTLE "passtime/whistle.wav"
#define MODEL_GATOR "models/props_island/crocodile/crocodile.mdl"
#define ANIM_GATOR "attack"

bool g_bHasMadarasWhistle[MAXPLAYERS+1] = {false, ...};
float g_fMadarasWhistleLastAttack[MAXPLAYERS+1] = {0.0, ...};
float g_fMadarasWhistleRate = 2.0;
float g_fMadarasWhistleRange = 100.0;
float g_fMadarasWhistleDamage = 150.0;

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

void MadarasWhistle_Perk(int client, const char[] sPref, bool apply){
	if(apply) MadarasWhistle_ApplyPerk(client, sPref);
	else MadarasWhistle_RemovePerk(client);
}

void MadarasWhistle_ApplyPerk(int client, const char[] sPref){
	MadarasWhistle_ProcessSettings(sPref);
	g_bHasMadarasWhistle[client] = true;
	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Attack", LANG_SERVER, 0x03, 0x01);
}

void MadarasWhistle_RemovePerk(int client){
	g_bHasMadarasWhistle[client] = false;
}

void MadarasWhistle_Voice(int client){
	if(!g_bHasMadarasWhistle[client]) return;

	float fEngineTime = GetEngineTime();
	if(fEngineTime < g_fMadarasWhistleLastAttack[client] +g_fMadarasWhistleRate)
		return;

	g_fMadarasWhistleLastAttack[client] = fEngineTime;
	MadarasWhistle_Whistle(client);
}

void MadarasWhistle_Whistle(int client){
	float fPos[3];
	GetClientAbsOrigin(client, fPos);

	EmitSoundToAll(SOUND_WHISTLE, client, _, _, _, _, 180);
	DataPack hPack = new DataPack();

	CreateTimer(1.0, Timer_MadarasWhistle_Whistle, hPack);
	hPack.WriteCell(GetClientUserId(client));
	hPack.WriteFloat(fPos[0]);
	hPack.WriteFloat(fPos[1]);
	hPack.WriteFloat(fPos[2]);

	int iParticle = CreateParticle(client, "waterfall_bottomsplash", false, "", view_as<float>({0.0, 0.0, 0.0}));
	EmitSoundToAll(g_sGatorRumble[GetRandomInt(0, 4)], iParticle);
	KillIn1(iParticle);
}

public Action Timer_MadarasWhistle_Whistle(Handle hTimer, DataPack hPack){
	hPack.Reset();
	int client = GetClientOfUserId(hPack.ReadCell());
	if(!client) return Plugin_Stop;

	float fPos[3];
	fPos[0] = hPack.ReadFloat();
	fPos[1] = hPack.ReadFloat();
	fPos[2] = hPack.ReadFloat();

	MadarasWhistle_Summon(client, fPos);
	return Plugin_Stop;
}

void MadarasWhistle_Summon(int client, float fPos[3]){
	int iGator = MadarasWhistle_SpawnGator(fPos);
	if(iGator == 0) return;

	DamageRadius(fPos, iGator, client, g_fMadarasWhistleRange, g_fMadarasWhistleDamage, DMG_BLAST|DMG_ALWAYSGIB, true);
	KillIn1(iGator);
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

void MadarasWhistle_ProcessSettings(const char[] sSettings){
	char[][] sPieces = new char[3][8];
	ExplodeString(sSettings, ",", sPieces, 3, 8);

	g_fMadarasWhistleRate = StringToFloat(sPieces[0]);
	g_fMadarasWhistleRange = StringToFloat(sPieces[1]);
	g_fMadarasWhistleDamage = StringToFloat(sPieces[2]);
}
