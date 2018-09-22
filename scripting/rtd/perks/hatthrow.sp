
#define MODEL_HAT "models/player/items/all_class/all_domination_Scout.mdl"
#define SOUND_HAT_IMPACT "weapons/loose_cannon_ball_impact.wav"

bool g_bHasHatThrow[MAXPLAYERS+1] = {false, ...};
float g_fHatThrowLastAttack[MAXPLAYERS+1] = {0.0, ...};
float g_fHatThrowDamage = 150.0;
float g_fHatThrowRate = 2.0;

char g_sSoundSwoosh[][] = {
	"passtime/projectile_swoosh3.wav",
	"passtime/projectile_swoosh4.wav"
};

char g_sSoundHatHit[][] = {
	"weapons/demo_charge_hit_flesh1.wav",
	"weapons/demo_charge_hit_flesh2.wav",
	"weapons/demo_charge_hit_flesh3.wav"
};

void HatThrow_Start(){
	PrecacheSound(SOUND_HAT_IMPACT);
	PrecacheSound(g_sSoundSwoosh[0]);
	PrecacheSound(g_sSoundSwoosh[1]);
	PrecacheSound(g_sSoundHatHit[0]);
	PrecacheSound(g_sSoundHatHit[1]);
	PrecacheSound(g_sSoundHatHit[2]);
	PrecacheModel(MODEL_HAT);
}

void HatThrow_Perk(int client, const char[] sPref, bool apply){
	g_bHasHatThrow[client] = apply;
	if(apply){
		HatThrow_ProcessString(sPref);
		PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Attack", LANG_SERVER, 0x03, 0x01);
	}
}

void HatThrow_Voice(int client){
	if(!g_bHasHatThrow[client])
		return;

	float fEngineTime = GetEngineTime();
	if(fEngineTime < g_fHatThrowLastAttack[client] +g_fHatThrowRate)
		return;

	g_fHatThrowLastAttack[client] = fEngineTime;
	HatThrow_Spawn(client);
}

void HatThrow_Spawn(int client){
	int iHat = CreateEntityByName("prop_dynamic");
	if(iHat == -1) return;
	KillIn10(iHat);

	int iRot = CreateEntityByName("func_door_rotating");
	if(iRot == -1) return;
	KillIn10(iRot);

	float fPos[3];
	GetClientEyePosition(client, fPos);

	DispatchKeyValueVector(iHat, "origin", fPos);
	DispatchKeyValueVector(iRot, "origin", fPos);
	DispatchKeyValue(iHat, "model", MODEL_HAT);
	DispatchKeyValue(iHat, "modelscale", "3");
	DispatchKeyValue(iRot, "distance", "99999");
	DispatchKeyValue(iRot, "speed", "2000");
	DispatchKeyValue(iRot, "spawnflags", "4104"); // passable|silent
	DispatchSpawn(iHat);
	DispatchSpawn(iRot);

	SetVariantString("!activator");
	AcceptEntityInput(iHat, "SetParent", iRot, iHat, 0);
	AcceptEntityInput(iRot, "Open");

	CreateTimer(0.1, Timer_HatThrow_Woosh, EntIndexToEntRef(iHat), TIMER_REPEAT);
	HatThrow_Launch(client, iRot);
}

public Action Timer_HatThrow_Woosh(Handle hTimer, int iRef){
	int iEnt = EntRefToEntIndex(iRef);
	if(iEnt <= MaxClients)
		return Plugin_Stop;

	int iSound = GetEntProp(iEnt, Prop_Data, "m_bUsePuntSound");
	EmitSoundToAll(g_sSoundSwoosh[iSound], iEnt, _, _, _, _, 200);
	SetEntProp(iEnt, Prop_Data, "m_bUsePuntSound", !iSound);
	return Plugin_Continue;
}

void HatThrow_Launch(int client, int iHat){
	float fAng[3], fPos[3];
	GetClientEyeAngles(client, fAng);
	GetClientEyePosition(client, fPos);

	int iCarrier = CreateEntityByName("prop_physics_override");
	if(iCarrier == -1) return;
	KillIn10(iCarrier);

	float fVel[3], fBuf[3];
	GetAngleVectors(fAng, fBuf, NULL_VECTOR, NULL_VECTOR);
	fVel[0] = fBuf[0]*1100.0; // rocket speed
	fVel[1] = fBuf[1]*1100.0;
	fVel[2] = fBuf[2]*1100.0;

	SetEntPropEnt(iCarrier, Prop_Send, "m_hOwnerEntity", client);
	DispatchKeyValue(iCarrier, "model", MODEL_HAT);
	DispatchKeyValue(iCarrier, "modelscale", "0");
	DispatchSpawn(iCarrier);

	TeleportEntity(iCarrier, fPos, NULL_VECTOR, fVel);
	SetEntityMoveType(iCarrier, MOVETYPE_FLY);

	SetVariantString("!activator");
	AcceptEntityInput(iHat, "SetParent", iCarrier, iHat, 0);
	SDKHook(iCarrier, SDKHook_StartTouch, Event_HatThrow_OnHatTouch);
}

public Action Event_HatThrow_OnHatTouch(int iHat, int client){
	if(1 <= client <= MaxClients){
		int attacker = GetEntPropEnt(iHat, Prop_Send, "m_hOwnerEntity");
		if(CanPlayerBeHurt(client, attacker))
			SDKHooks_TakeDamage(client, iHat, attacker, g_fHatThrowDamage, DMG_CLUB);

		EmitSoundToAll(g_sSoundHatHit[GetRandomInt(0, 2)], iHat);
	}

	EmitSoundToAll(SOUND_HAT_IMPACT, iHat);

	float fPos[3];
	GetEntPropVector(iHat, Prop_Send, "m_vecOrigin", fPos);
	HatThrow_SpawnCorpse(fPos);

	AcceptEntityInput(iHat, "Kill");
	return Plugin_Handled;
}

void HatThrow_SpawnCorpse(float fPos[3]){
	int iHat = CreateEntityByName("prop_physics_override");
	if(iHat == -1) return;

	DispatchKeyValueVector(iHat, "origin", fPos);
	DispatchKeyValue(iHat, "model", MODEL_HAT);
	DispatchKeyValue(iHat, "modelscale", "3");
	DispatchKeyValue(iHat, "spawnflags", "4"); // debris
	DispatchSpawn(iHat);

	float fAng[3];
	fAng[0] = GetRandomFloat(0.0, 360.0);
	fAng[1] = GetRandomFloat(0.0, 360.0);
	fAng[2] = GetRandomFloat(0.0, 360.0);

	TeleportEntity(iHat, NULL_VECTOR, fAng, NULL_VECTOR);
	SetEntityRenderFx(iHat, RENDERFX_FADE_SLOW);
	KillIn1(iHat);
}

void HatThrow_ProcessString(const char[] sSettings){
	char[][] sPieces = new char[2][8];
	ExplodeString(sSettings, ",", sPieces, 3, 8);
	g_fHatThrowRate		= StringToFloat(sPieces[0]);
	g_fHatThrowDamage	= StringToFloat(sPieces[1]);
}
