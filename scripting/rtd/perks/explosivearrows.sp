/**
* Explosive Arrows perk.
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

#define Damage Float[0]
#define Force Float[1]
#define Radius Float[2]

DEFINE_CALL_APPLY(ExplosiveArrows)

public void ExplosiveArrows_Init(const Perk perk)
{
	Events.OnEntitySpawned(perk, ExplosiveArrows_OnArrowSpawn, ExplosiveArrows_ValidClassname, Retriever_OwnerEntity);
}

public void ExplosiveArrows_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Damage = perk.GetPrefFloat("damage", 100.0);
	Cache[client].Force = perk.GetPrefFloat("force", 80.0);
	Cache[client].Radius = perk.GetPrefFloat("radius", 100.0);
}

public void ExplosiveArrows_OnArrowSpawn(const int client, const int iArrow)
{
	SDKHook(iArrow, SDKHook_StartTouchPost, ExplosiveArrows_ArrowTouch);
}

public void ExplosiveArrows_ArrowTouch(int iEntity, int iOther)
{
	int iExplosion = CreateEntityByName("env_explosion");
	if (iExplosion <= MaxClients)
		return;

	int client = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");

	DispatchKeyValueFloat(iExplosion, "iMagnitude", Cache[client].Damage);
	DispatchKeyValueFloat(iExplosion, "DamageForce", Cache[client].Force);
	DispatchKeyValueFloat(iExplosion, "iRadiusOverride", Cache[client].Radius);

	DispatchSpawn(iExplosion);
	ActivateEntity(iExplosion);

	SetEntPropEnt(iExplosion, Prop_Data, "m_hOwnerEntity", GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity"));

	float fPos[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPos);

	TeleportEntity(iExplosion, fPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iExplosion, "Explode");
	AcceptEntityInput(iExplosion, "Kill");
}

bool ExplosiveArrows_ValidClassname(const char[] sCls)
{
	return StrEqual(sCls, "tf_projectile_healing_bolt") || StrEqual(sCls, "tf_projectile_arrow");
}

#undef Damage
#undef Force
#undef Radius
