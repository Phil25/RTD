
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

bool	g_bHasExplosiveArrows[MAXPLAYERS+1] = {false, ...};
char	g_sExplosiveArrowsDamage[8] = "100";
char	g_sExplosiveArrowsRadius[8] = "80";
float	g_fExplosiveArrowsForce = 100.0;
Handle	g_hExplosiveArrows = INVALID_HANDLE;

void ExplosiveArrows_Start(){

	g_hExplosiveArrows = CreateArray();

}

void ExplosiveArrows_Perk(int client, const char[] sPref, bool apply){

	ExplosiveArrows_ProcessSettings(sPref);
	g_bHasExplosiveArrows[client] = apply;

}

void ExplosiveArrows_OnEntityCreated(int iEnt, const char[] sClassname){

	if(ExplosiveArrows_ValidClassname(sClassname))
		SDKHook(iEnt, SDKHook_Spawn, Timer_ExplosiveArrows_ProjectileSpawn);

}

public void Timer_ExplosiveArrows_ProjectileSpawn(int iProjectile){
	
	int iLauncher = GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity");
	
	if(iLauncher < 1 || !IsValidClient(iLauncher) || !IsPlayerAlive(iLauncher))
		return;
	
	if(!g_bHasExplosiveArrows[iLauncher])
		return;
	
	if(FindValueInArray(g_hExplosiveArrows, iProjectile) > -1)
		return;
	
	PushArrayCell(g_hExplosiveArrows, iProjectile);
	SDKHook(iProjectile, SDKHook_StartTouchPost, ExplosiveArrows_ProjectileTouch);

}

public void ExplosiveArrows_ProjectileTouch(int iEntity, int iOther){

	int iExplosion = CreateEntityByName("env_explosion");
	RemoveFromArray(g_hExplosiveArrows, FindValueInArray(g_hExplosiveArrows, iEntity));
	
	if(!IsValidEntity(iExplosion))
		return;

	DispatchKeyValue(iExplosion, "iMagnitude", g_sExplosiveArrowsDamage);
	DispatchKeyValue(iExplosion, "iRadiusOverride", g_sExplosiveArrowsRadius);
	DispatchKeyValueFloat(iExplosion, "DamageForce", g_fExplosiveArrowsForce);
	
	DispatchSpawn(iExplosion);
	ActivateEntity(iExplosion);

	SetEntPropEnt(iExplosion, Prop_Data, "m_hOwnerEntity", GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity"));
	
	float fPos[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPos);

	TeleportEntity(iExplosion, fPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iExplosion, "Explode");
	AcceptEntityInput(iExplosion, "Kill");

}

bool ExplosiveArrows_ValidClassname(const char[] sCls){

	if(StrEqual(sCls, "tf_projectile_healing_bolt")
	|| StrEqual(sCls, "tf_projectile_arrow"))
		return true;
	
	return false;

}

void ExplosiveArrows_ProcessSettings(const char[] sSettings){

	char[][] sPieces = new char[3][8];
	ExplodeString(sSettings, ",", sPieces, 3, 8);

	strcopy(g_sExplosiveArrowsDamage, 8, sPieces[0]);
	strcopy(g_sExplosiveArrowsRadius, 8, sPieces[1]);
	g_fExplosiveArrowsForce = StringToFloat(sPieces[3]);

}