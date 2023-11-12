/**
* Cursed Projectiles perk.
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

#define CURSED_PROJECTILES_TRANSFORM "halloween_ghost_flash"
#define SOUND_COURSE_PROJECTILE "misc/halloween/merasmus_disappear.wav"

#define Delay Float[0]

DEFINE_CALL_APPLY(CursedProjectiles)

public void CursedProjectiles_Init(const Perk perk)
{
	PrecacheSound(SOUND_COURSE_PROJECTILE);

	Events.OnEntitySpawned(perk, CursedProjectiles_OnProjectileSpawn, Homing_AptClass, Retriever_OwnerEntity);
}

void CursedProjectiles_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Delay = perk.GetPrefFloat("delay", 1.0);
}

public void CursedProjectiles_OnProjectileSpawn(const int client, const int iProjectile)
{
	// 0.1 -- must match the delay between entity creation and spawn, hardcoded in main plugin part
	CreateTimer(Cache[client].Delay - 0.1, Timer_CursedProjectiles_Turn, EntIndexToEntRef(iProjectile));
}

public Action Timer_CursedProjectiles_Turn(Handle hTimer, int iRef)
{
	int iProjectile = EntRefToEntIndex(iRef);
	if (iProjectile <= MaxClients || !IsValidEntity(iProjectile))
		return Plugin_Stop;

	int client = GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity");
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	CursedProjectiles_Turn(iProjectile, client);
	return Plugin_Stop;
}

void CursedProjectiles_Turn(const int iOriginalProjectile, const int client)
{
	float fPos[3], fVel[3];
	GetEntPropVector(iOriginalProjectile, Prop_Send, "m_vecOrigin", fPos);
	GetEntPropVector(iOriginalProjectile, Prop_Send, "m_vInitialVelocity", fVel);

	int iLauncher = GetEntPropEnt(iOriginalProjectile, Prop_Send, "m_hOriginalLauncher");

	AcceptEntityInput(iOriginalProjectile, "Kill");

	int iProjectile = CursedProjectiles_Spawn(client, iLauncher, fPos, fVel);
	if (iProjectile <= MaxClients)
		return;

	KILL_ENT_IN(iProjectile,3.0);
	Homing_Push(iProjectile, HOMING_SELF_ORIG);

	CreateEffect(fPos, CURSED_PROJECTILES_TRANSFORM);
	EmitSoundToAll(SOUND_COURSE_PROJECTILE, iProjectile);

	SDKHook(iProjectile, SDKHook_StartTouchPost, CursedProjectiles_ProjectileTouch);
}

int CursedProjectiles_Spawn(int client, int iLauncher, float fPos[3], float fVel[3])
{
	int iProjectile = CreateEntityByName("tf_projectile_spellfireball");
	if (iProjectile <= MaxClients)
		return 0;

	SetEntPropEnt(iProjectile, Prop_Send, "m_hOriginalLauncher", iLauncher);
	SetEntPropVector(iProjectile, Prop_Send, "m_vInitialVelocity", fVel);
	TeleportEntity(iProjectile, fPos, NULL_VECTOR, NULL_VECTOR);

	int iTeam = GetOppositeTeamOf(client);
	SetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity", 0);
	SetEntProp(iProjectile, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iProjectile, Prop_Send, "m_nSkin", iTeam - 2);

	DispatchSpawn(iProjectile);
	return iProjectile;
}

public void CursedProjectiles_ProjectileTouch(int iProjectile, int client)
{
	if (GetLauncher(iProjectile) != client)
		return;

	if (!IsValidClient(client))
		return;

	float fPos[3];
	GetClientAbsOrigin(client, fPos);
	CreateExplosion(fPos, 100.0, 1.0);
}

#undef CURSED_PROJECTILES_TRANSFORM
#undef SOUND_COURSE_PROJECTILE

#undef Delay
