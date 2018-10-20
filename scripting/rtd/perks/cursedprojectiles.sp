/**
* Cursed Projectiles perk.
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

#define CURSED_PROJECTILES_TRANSFORM "halloween_ghost_flash"
#define SOUND_COURSE_PROJECTILE "misc/halloween/merasmus_disappear.wav"

int g_iCursedProjectilesId = 67;

void CursedProjectiles_Start(){
	PrecacheSound(SOUND_COURSE_PROJECTILE);
}

public void CursedProjectiles_Call(int client, Perk perk, bool apply){
	if(apply) CursedProjectiles_ApplyPerk(client, perk);
	else UnsetClientPerkCache(client, g_iCursedProjectilesId);
}

void CursedProjectiles_ApplyPerk(int client, Perk perk){
	g_iCursedProjectilesId = perk.Id;
	SetClientPerkCache(client, g_iCursedProjectilesId);
	SetFloatCache(client, perk.GetPrefFloat("delay"));
}

void CursedProjectiles_OnEntityCreated(int iEnt, const char[] sClassname){
	if(Homing_AptClass(sClassname))
		SDKHook(iEnt, SDKHook_SpawnPost, CursedProjectiles_OnSpawn);
}

public void CursedProjectiles_OnSpawn(int iEnt){
	int client = GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity");
	if(IsValidClient(client) && CheckClientPerkCache(client, g_iCursedProjectilesId))
		CreateTimer(GetFloatCache(client), Timer_CursedProjectiles_Turn, EntIndexToEntRef(iEnt));
}

public Action Timer_CursedProjectiles_Turn(Handle hTimer, int iRef){
	int iProjectile = EntRefToEntIndex(iRef);
	if(iProjectile <= MaxClients || !IsValidEntity(iProjectile))
		return Plugin_Stop;

	int client = GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity");
	if(!IsValidClient(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iCursedProjectilesId))
		return Plugin_Stop;

	CursedProjectiles_Turn(iProjectile, client);
	return Plugin_Stop;
}

void CursedProjectiles_Turn(int iProjectile, int client){
	float fPos[3], fVel[3];

	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", fPos);
	GetEntPropVector(iProjectile, Prop_Send, "m_vInitialVelocity", fVel);
	int iLauncher = GetEntPropEnt(iProjectile, Prop_Send, "m_hOriginalLauncher");

	AcceptEntityInput(iProjectile, "Kill");
	iProjectile = CursedProjectiles_Spawn(client, iLauncher, fPos, fVel);
	if(!iProjectile) return;

	KILL_ENT_IN(iProjectile,3.0)
	Homing_Push(iProjectile, HOMING_SELF_ORIG);

	CreateEffect(fPos, CURSED_PROJECTILES_TRANSFORM);
	EmitSoundToAll(SOUND_COURSE_PROJECTILE, iProjectile);

	SDKHook(iProjectile, SDKHook_StartTouchPost, CursedProjectiles_ProjectileTouch);
}

int CursedProjectiles_Spawn(int client, int iLauncher, float fPos[3], float fVel[3]){
	int iProjectile = CreateEntityByName("tf_projectile_spellfireball");
	if(!iProjectile) return 0;

	SetEntPropEnt(iProjectile, Prop_Send, "m_hOriginalLauncher", iLauncher);
	SetEntPropVector(iProjectile, Prop_Send, "m_vInitialVelocity", fVel);
	TeleportEntity(iProjectile, fPos, NULL_VECTOR, NULL_VECTOR);

	int iTeam = GetOppositeTeamOf(client);
	SetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity", 0);
	SetEntProp(iProjectile, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iProjectile, Prop_Send, "m_nSkin", iTeam -2);

	DispatchSpawn(iProjectile);
	return iProjectile;
}

public void CursedProjectiles_ProjectileTouch(int iProjectile, int client){
	if(GetLauncher(iProjectile) != client) return;
	if(!IsValidClient(client)) return;

	float fPos[3];
	GetClientAbsOrigin(client, fPos);
	CreateExplosion(fPos, 100.0, 1.0);
}
