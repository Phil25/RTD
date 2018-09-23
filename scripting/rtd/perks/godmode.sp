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

int g_iGodmodeParticle[MAXPLAYERS+1] = {0, ...};
int	g_iPref_Godmode = 0;

void Godmode_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		Godmode_ApplyPerk(client, StringToInt(sPref));
	
	else
		Godmode_RemovePerk(client);

}

void Godmode_ApplyPerk(int client, int iValue){

	float fParticleOffset[3] = {0.0, 0.0, 12.0};

	g_iGodmodeParticle[client] = CreateParticle(client, GODMODE_PARTICLE, _, _, fParticleOffset);

	g_iPref_Godmode = iValue;
	SDKHook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage);

}

void Godmode_RemovePerk(int client){

	if(g_iGodmodeParticle[client] > MaxClients && IsValidEntity(g_iGodmodeParticle[client])){
	
		AcceptEntityInput(g_iGodmodeParticle[client], "Kill");
		g_iGodmodeParticle[client] = 0;
	
	}

	SDKUnhook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage);

}

public Action Godmode_OnTakeDamage(int iVic, int &iAttacker){//, int &iInflictor, float &fDamage, int &iDamageType, int &weapon, float damageForce[3], float damagePosition[3]){

	if(iVic != iAttacker)
		return Plugin_Handled;
	
	if(g_iPref_Godmode > 0)
		return Plugin_Continue;
	
	if(g_iPref_Godmode > -1)
		TF2_AddCondition(iVic, TFCond_Bonked, 0.001);
	
	else
		return Plugin_Handled;
	
	return Plugin_Continue;

}
