#define SICKNESS_NEXT_TICK GetURandomFloat()*2.0+2.0
#define SICKNESS_PARTICLE "spell_skeleton_goop_green"

bool g_bHasSickness[MAXPLAYERS+1] = {false, ...};
float g_fSicknessDamageMin = 5.0;
float g_fSicknessDamageMax = 10.0;

char g_sSoundCough[][] = {
	"ambient/voices/cough1.wav",
	"ambient/voices/cough2.wav",
	"ambient/voices/cough3.wav",
	"ambient/voices/cough4.wav"
};

void Sickness_Start(){
	for(int i = 0; i < 4; ++i)
		PrecacheSound(g_sSoundCough[i]);
}

void Sickness_Perk(int client, const char[] sPref, bool apply){
	if(apply) Sickness_ApplyPerk(client, sPref);
	else g_bHasSickness[client] = false;
}

void Sickness_ApplyPerk(client, const char[] sPref){
	Sickness_ProcessSettings(sPref);
	g_bHasSickness[client] = true;
	CreateTimer(SICKNESS_NEXT_TICK, Timer_Sickness_Tick, GetClientUserId(client));
}

public Action Timer_Sickness_Tick(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client || !g_bHasSickness[client])
		return Plugin_Stop;

	EmitSoundToAll(g_sSoundCough[GetRandomInt(0, 3)], client);
	Sickness_Cough(client);

	CreateTimer(0.25, Timer_Sickness_Tick2, iUserId);
	CreateTimer(SICKNESS_NEXT_TICK, Timer_Sickness_Tick, iUserId);
	return Plugin_Stop;
}

public Action Timer_Sickness_Tick2(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(client) Sickness_Cough(client);
	return Plugin_Handled;
}

void Sickness_Cough(int client){
	int iParticle = CreateParticle(client, SICKNESS_PARTICLE);
	SetVariantString("OnUser1 !self:Kill::0.1:1");
	AcceptEntityInput(iParticle, "AddOutput");
	AcceptEntityInput(iParticle, "FireUser1");

	float fDamage = GetRandomFloat(g_fSicknessDamageMin, g_fSicknessDamageMax);
	SDKHooks_TakeDamage(client, client, client, fDamage, DMG_PREVENT_PHYSICS_FORCE);

	float fShake[3];
	fShake[0] = GetRandomFloat(10.0, 15.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fShake);
}

void Sickness_ProcessSettings(const char[] sSettings){
	char[][] sPieces = new char[2][8];
	ExplodeString(sSettings, ",", sPieces, 2, 8);
	g_fSicknessDamageMin = StringToFloat(sPieces[0]);
	g_fSicknessDamageMax = StringToFloat(sPieces[1]);
}
