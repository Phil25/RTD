/**
* Fire Breath perk.
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

int g_iBatSwarmId = 69;

public void BatSwarm_Call(int client, Perk perk, bool apply){
	if(apply) BatSwarm_ApplyPerk(client, perk);
	else UnsetClientPerkCache(client, g_iBatSwarmId);
}

void BatSwarm_ApplyPerk(int client, Perk perk){
	g_iBatSwarmId = perk.Id;
	SetClientPerkCache(client, g_iBatSwarmId);

	SetFloatCache(client, perk.GetPrefFloat("lifetime"));
	SetIntCache(client, perk.GetPrefCell("amount"));

	CreateTimer(perk.GetPrefFloat("rate"), Timer_BatSwarm_SpawnBats, GetClientUserId(client), TIMER_REPEAT);
}

public Action Timer_BatSwarm_SpawnBats(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iBatSwarmId))
		return Plugin_Stop;

	float fPos[3], fAng[3], fVel[3];
	GetClientEyePosition(client, fPos);
	int iAmount = GetIntCache(client);

	while(--iAmount >= 0)
		BatSwarm_SpawnBats(client, GetFloatCache(client), fPos, fAng, fVel);
	return Plugin_Continue;
}

void BatSwarm_SpawnBats(int client, float fLifetime, float fPos[3], float fAng[3], float fVel[3]){
	int iBats = CreateEntityByName("tf_projectile_spellbats");
	if(iBats <= MaxClients) return;

	SetEntPropEnt(iBats, Prop_Send, "m_hOwnerEntity", client);

	int iTeam = GetClientTeam(client);
	SetEntProp(iBats, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iBats, Prop_Send, "m_nSkin", iTeam -2);

	DispatchSpawn(iBats);

	fAng[0] = GetURandomFloat() *360.0;
	fAng[1] = GetURandomFloat() *360.0;

	GetAngleVectors(fAng, fVel, NULL_VECTOR, NULL_VECTOR);
	fVel[0] *= 500.0;
	fVel[1] *= 500.0;
	fVel[2] *= 500.0;

	TeleportEntity(iBats, fPos, fAng, fVel);
	KillEntIn(iBats, fLifetime);
}
