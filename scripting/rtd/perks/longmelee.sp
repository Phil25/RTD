
#define ATTRIB_MELEE_RANGE 264

bool g_bHasLongMelee[MAXPLAYERS+1] = {false, ...};
bool g_bHasLongMelee2[MAXPLAYERS+1] = {false, ...};

void LongMelee_Start(){
	HookEvent("post_inventory_application", LongMelee_Resupply, EventHookMode_Post);
}

void LongMelee_OnEntityCreated(int iEnt, const char[] sClassname){
	if(StrEqual(sClassname, "tf_dropped_weapon"))
		SDKHook(iEnt, SDKHook_SpawnPost, LongMelee_OnDroppedWeaponSpawn);
}

public void LongMelee_OnDroppedWeaponSpawn(int iEnt){
	int client = AccountIDToClient(GetEntProp(iEnt, Prop_Send, "m_iAccountID"));
	if(client && g_bHasLongMelee2[client])
		AcceptEntityInput(iEnt, "Kill");
} 

void LongMelee_Perk(int client, const char[] sPref, bool apply){
	if(apply) LongMelee_ApplyPerk(client, StringToFloat(sPref));
	else LongMelee_RemovePerk(client);
}

void LongMelee_ApplyPerk(int client, float fMulti){
	LongMelee_EditClientWeapons(client, true, fMulti);
	g_bHasLongMelee[client] = true;
	g_bHasLongMelee2[client] = true;
}

void LongMelee_RemovePerk(int client){
	LongMelee_EditClientWeapons(client, false);
	g_bHasLongMelee[client] = false;
	CreateTimer(0.5, Timer_LongMelee_FullUnset, GetClientUserId(client));
}

public Action Timer_LongMelee_FullUnset(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(client) g_bHasLongMelee2[client] = false;
	return Plugin_Stop;
}

void LongMelee_EditClientWeapons(int client, bool apply, float fMulti=0.0){

	int iWeapon = GetPlayerWeaponSlot(client, 2);
	if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
		return;

	if(apply) TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_MELEE_RANGE, fMulti);
	else TF2Attrib_RemoveByDefIndex(iWeapon, ATTRIB_MELEE_RANGE);
}

public void LongMelee_Resupply(Handle hEvent, const char[] sEventName, bool bDontBroadcast){
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client && g_bHasLongMelee[client])
		LongMelee_EditClientWeapons(client, true);
}
