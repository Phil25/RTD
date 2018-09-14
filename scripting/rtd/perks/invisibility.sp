
/*
This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd2.sp instead of this one.

*** HOW TO ADD A PERK ***
A quick note: This tutorial may not be kept up to date; for an updated one, go to the plugin's thread.

1. Set up:
	a) Have <perkname>.sp in scripting/rtd.
	b) Add it to the includes in scripting/rtd/#perks.sp.
	c) Add a new section with a correct ID (highest one +1) to the config/rtd2_perks.cfg and set its settings.

2. Edit scripting/rtd/#manager.sp
	a) In a function named ManagePerk() add a new case to the switch() with your perk's ID.
	b) In the added case specify a function which is going to execute from <perkname>.sp with parameters:
		1) @client			- the client the perk should be applied to/removed from
		2) @fSpecialPref	- the optional "special" value in config/rtd2_perks.cfg
		2) @enable			- to specify whether the perk should be applied/removed
	c) OPTIONAL: You can specify a function in your perk which should run at OnMapStart() in the Forward_OnMapStart() function.
		You will need it if you'd want to, for example, precache a sound or loop through existing clients.
	d) OPTIONAL: You can specify a function in your perk which should run at OnPlayerRunCmd() in the Forward_OnPlayerRunCmd() function.
		You can use it if you'd need something to run each frame or on a certain button press.
		NOTE: The forwarded client is guaranteed to be valid BUT NOT GUARANTEED IF THEY ARE ALIVE.

3. Script your perk:
	a) Create a public function in <perkname>.sp with parameters @client, @iPref, @bool:apply as an example below
	   - This is the only function used to transfer info between the core and the include
	   - You don't need to include any includes that are in the rtd2.sp
	b) NOTE: If you need to transfer the iPref to a different function, set it globally but remember to use an unique name
	c) Name it AS SAME AS you named the function in the added case in the switch() in #manager.sp
	d) From there, script the functionality like there's no tomorrow
	e) You are free to use IsValidClient(). It returns false when:
		- An incorrect client index is specified
		- Client is not in game
		- Client is fake (bot)
		- Client is Coaching

4. Compile rtd2.sp and you're good to go!

*/

/*
	IF YOU TELL ME HOW TO GET THE INSIDE OF THE B.A.S.E. JUMPER TO DISAPPEAR I WILL LOVE YOU FOREVER
*/

int		g_iBaseAlpha[MAXPLAYERS+1]	= {255, ...};
bool	g_bBaseSentry[MAXPLAYERS+1]	= {true, ...};
bool	g_bHasInvis[MAXPLAYERS+1]	= {false, ...};
int		g_iInvisValue				= 0;

void Invisibility_Start(){

	HookEvent("post_inventory_application", Event_Invisibility_Resupply, EventHookMode_Post);

}

void Invisibility_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		Invisibility_ApplyPerk(client, StringToInt(sPref));

	else
		Invisibility_RemovePerk(client);

}

void Invisibility_ApplyPerk(int client, int iValue){

	g_bHasInvis[client]		= true;
	g_iInvisValue			= iValue;
	
	g_iBaseAlpha[client]	= GetEntityAlpha(client);
	g_bBaseSentry[client]	= (GetEntityFlags(client) & FL_NOTARGET) ? true : false;
	
	Invisibility_Set(client, iValue);
	
	SetSentryTarget(client, false);

}

void Invisibility_RemovePerk(int client){

	g_bHasInvis[client]		= false;
	
	Invisibility_Set(client, g_iBaseAlpha[client]);
	
	SetSentryTarget(client, g_bBaseSentry[client]);

}

void Invisibility_Set(int client, int iValue){
	
	if(GetEntityRenderMode(client) == RENDER_NORMAL)
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	
	SetEntityAlpha(client, iValue);
	
	int iWeapon = 0;
	for(int i = 0; i < 5; i++){
	
		iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;
		
		if(GetEntityRenderMode(iWeapon) == RENDER_NORMAL)
			SetEntityRenderMode(iWeapon, RENDER_TRANSCOLOR);
		
		SetEntityAlpha(iWeapon, iValue);
	
	}
	
	char sClass[24];
	for(int i = MaxClients+1; i < GetMaxEntities(); i++){
	
		if(!IsCorrectWearable(client, i, sClass, sizeof(sClass))) continue;
		
		if(GetEntityRenderMode(i) == RENDER_NORMAL)
			SetEntityRenderMode(i, RENDER_TRANSCOLOR);
		
		SetEntityAlpha(i, iValue);
	
	}

}

public void Event_Invisibility_Resupply(Handle hEvent, const char[] sEventName, bool bDontBroadcast){

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client == 0)				return;
	if(!g_bHasInvis[client])	return;
	
	Invisibility_Set(client, g_iInvisValue);

}

stock int GetEntityAlpha(int iEntity){

	return GetEntData(iEntity, GetEntSendPropOffs(iEntity, "m_clrRender") + 3, 1);

}

stock void SetEntityAlpha(int iEntity, int iValue){

	SetEntData(iEntity, GetEntSendPropOffs(iEntity, "m_clrRender") + 3, iValue, 1, true);

}

bool IsCorrectWearable(int client, int i, char[] sClass, iBufferSize){

	if(!IsValidEntity(i))
		return false;

	GetEdictClassname(i, sClass, iBufferSize);
	if(StrContains(sClass, "tf_wearable", false) < 0 && StrContains(sClass, "tf_powerup", false) < 0)
		return false;
	
	if(GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") != client)
		return false;
	
	return true;

}

void SetSentryTarget(int client, bool bTarget){

	int iFlags = GetEntityFlags(client);	
	if(bTarget)
		SetEntityFlags(client, iFlags &~ FL_NOTARGET);
	else
		SetEntityFlags(client, iFlags | FL_NOTARGET);

}
