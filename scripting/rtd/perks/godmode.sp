/**
* Godmode perk.
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


#define GODMODE_PARTICLE "powerup_supernova_ready"

int g_iInGodmode = 0;

public void Godmode_Call(int client, Perk perk, bool bApply){
	if(bApply) Godmode_ApplyPerk(client, perk);
	else Godmode_RemovePerk(client);
}

void Godmode_ApplyPerk(int client, Perk perk){
	float fParticleOffset[3] = {0.0, 0.0, 12.0};

	SetEntCache(client, CreateParticle(client, GODMODE_PARTICLE, _, _, fParticleOffset));

	int iMode = perk.GetPrefCell("mode");
	switch(iMode){
		case -1: // no self damage
			SDKHook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_NoSelf);
		case 0: // pushback only
			SDKHook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_Pushback);
		case 1: // deal self damage
			SDKHook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_Self);
	}

	int iUber = perk.GetPrefCell("uber");
	SetIntCache(client, iUber);
	if(iUber) TF2_AddCondition(client, TFCond_UberchargedCanteen);

	g_iInGodmode |= client;
}

void Godmode_RemovePerk(int client){
	KillEntCache(client);

	SDKUnhook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_NoSelf);
	SDKUnhook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_Pushback);
	SDKUnhook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_Self);

	if(GetIntCacheBool(client))
		TF2_RemoveCondition(client, TFCond_UberchargedCanteen);

	g_iInGodmode &= ~client;
}

public Action Godmode_OnTakeDamage_NoSelf(int client, int &iAttacker){
	return Plugin_Handled;
}

public Action Godmode_OnTakeDamage_Pushback(int client, int &iAttacker){
	if(client != iAttacker)
		return Plugin_Handled;

	TF2_AddCondition(client, TFCond_Bonked, 0.01);
	return Plugin_Continue;
}

public Action Godmode_OnTakeDamage_Self(int client, int &iAttacker){
	return client == iAttacker ? Plugin_Continue : Plugin_Handled;
}
