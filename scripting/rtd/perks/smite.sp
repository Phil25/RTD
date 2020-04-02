/**
* Smite perk.
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


public void Smite_Call(int client, Perk perk, bool apply){
	if(!apply) return;

	SDKHooks_TakeDamage(client, client, client, 999.0, DMG_GENERIC);
	RequestFrame(Smite_Post, GetClientUserId(client));

	int[] iStrike = new int[2];
	iStrike[0] = CreateEntityByName("info_target");
	if(iStrike[0] <= MaxClients)
		return;

	KILL_ENT_IN(iStrike[0],0.25)

	iStrike[1] = CreateEntityByName("info_target");
	if(iStrike[1] <= MaxClients)
		return;

	KILL_ENT_IN(iStrike[1],0.25)

	float fPos[3];
	GetClientAbsOrigin(client, fPos);
	fPos[2] += 32.0;
	TeleportEntity(iStrike[0], fPos, NULL_VECTOR, NULL_VECTOR);
	fPos[2] += 1024.0;
	TeleportEntity(iStrike[1], fPos, NULL_VECTOR, NULL_VECTOR);

	int iBeam = ConnectWithBeam(iStrike[1], iStrike[0]);
	KILL_ENT_IN(iBeam,0.5)
}

public void Smite_Post(int iUid){
	int client = GetClientOfUserId(iUid);
	if(!client) return;

	int iRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if(iRagdoll <= MaxClients)
		return;

	int iDissolver = CreateEntityByName("env_entity_dissolver");
	if(iDissolver <= MaxClients)
		return;

	DispatchKeyValue(iDissolver, "dissolvetype", "0");
	DispatchKeyValue(iDissolver, "magnitude", "1");
	DispatchKeyValue(iDissolver, "target", "!activator");
	AcceptEntityInput(iDissolver, "Dissolve", iRagdoll);
	AcceptEntityInput(iDissolver, "Kill");
}
