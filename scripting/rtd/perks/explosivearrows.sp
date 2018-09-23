/**
* Explosive Arrows perk.
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
	
	if(!IsValidClient(iLauncher) || !IsPlayerAlive(iLauncher))
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
