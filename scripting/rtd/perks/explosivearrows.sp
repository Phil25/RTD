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


#define DAMAGE 0
#define FORCE 0
#define RADIUS 0

int g_iExplosiveArrowsId = 54;

public void ExplosiveArrows_Call(int client, Perk perk, bool apply){
	if(apply) ExplosiveArrows_Apply(client, perk);
	else UnsetClientPerkCache(client, g_iExplosiveArrowsId);
}

void ExplosiveArrows_Apply(int client, Perk perk){
	g_iExplosiveArrowsId = perk.Id;
	SetClientPerkCache(client, g_iExplosiveArrowsId);

	SetFloatCache(client, perk.GetPrefFloat("damage"), DAMAGE);
	SetFloatCache(client, perk.GetPrefFloat("force"), FORCE);
	SetFloatCache(client, perk.GetPrefFloat("radius"), RADIUS);
}

void ExplosiveArrows_OnEntityCreated(int iEnt, const char[] sClassname){
	if(ExplosiveArrows_ValidClassname(sClassname))
		SDKHook(iEnt, SDKHook_Spawn, Timer_ExplosiveArrows_ProjectileSpawn);
}

public void Timer_ExplosiveArrows_ProjectileSpawn(int iProjectile){
	int client = GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity");
	if(!IsValidClient(client)) return;

	if(CheckClientPerkCache(client, g_iExplosiveArrowsId))
		SDKHook(iProjectile, SDKHook_StartTouchPost, ExplosiveArrows_ProjectileTouch);
}

public void ExplosiveArrows_ProjectileTouch(int iEntity, int iOther){
	int iExplosion = CreateEntityByName("env_explosion");
	if(!iExplosion) return;

	int client = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");

	DispatchKeyValueFloat(iExplosion, "iMagnitude", GetFloatCache(client, DAMAGE));
	DispatchKeyValueFloat(iExplosion, "DamageForce", GetFloatCache(client, FORCE));
	DispatchKeyValueFloat(iExplosion, "iRadiusOverride", GetFloatCache(client, RADIUS));

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

#undef DAMAGE
#undef FORCE
#undef RADIUS
