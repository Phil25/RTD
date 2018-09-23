/**
* Deadly Voice perk.
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


#define DEADLYVOICE_SOUND_ATTACK "weapons/cow_mangler_explosion_charge_04.wav"

char	g_sDeadlyVoiceParticles[][] = {
	"default", "default",
	"powerup_supernova_explode_red",
	"powerup_supernova_explode_blue"
};

bool	g_bHasDeadlyVoice[MAXPLAYERS+1] 		= {false, ...};
int		g_iDeadlyVoiceParticle[MAXPLAYERS+1]	= {0, ...};
float	g_fDeadlyVoiceLastAttack[MAXPLAYERS+1]	= {0.0, ...};

float	g_fDeadlyVoiceRate	= 1.0;
float	g_fDeadlyVoiceRange	= 128.0;
float	g_fDeadlyVoiceDamage= 72.0;

void DeadlyVoice_Start(){

	PrecacheSound(DEADLYVOICE_SOUND_ATTACK);

}

void DeadlyVoice_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		DeadlyVoice_ApplyPerk(client, sPref);
	else
		DeadlyVoice_RemovePerk(client);

}

void DeadlyVoice_ApplyPerk(int client, const char[] sPref){

	DeadlyVoice_ProcessSettings(sPref);
	
	g_bHasDeadlyVoice[client] = true;
	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Attack", LANG_SERVER, 0x03, 0x01);

}

void DeadlyVoice_RemovePerk(int client){

	g_bHasDeadlyVoice[client] = false;

}

void DeadlyVoice_Voice(int client){

	if(!g_bHasDeadlyVoice[client]) return;
	
	float fEngineTime = GetEngineTime();
	
	if(fEngineTime < g_fDeadlyVoiceLastAttack[client] +g_fDeadlyVoiceRate)
		return;
	
	g_fDeadlyVoiceLastAttack[client] = fEngineTime;
	
	if(g_iDeadlyVoiceParticle[client] < 1)
		g_iDeadlyVoiceParticle[client] = CreateParticle(client, g_sDeadlyVoiceParticles[GetClientTeam(client)]);
	
	float fShake[3];
	fShake[0] = GetRandomFloat(-5.0, -25.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fShake);
	
	DeadlyVoice_HurtSurroundings(client);
	EmitSoundToAll(DEADLYVOICE_SOUND_ATTACK, client);
	
	CreateTimer(g_fDeadlyVoiceRate, Timer_DeadlyVoice_DestroyParticle, GetClientSerial(client));

}

public Action Timer_DeadlyVoice_DestroyParticle(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);

	if(g_iDeadlyVoiceParticle[client] > MaxClients && IsValidEntity(g_iDeadlyVoiceParticle[client])){
	
		AcceptEntityInput(g_iDeadlyVoiceParticle[client], "Kill");
		g_iDeadlyVoiceParticle[client] = 0;
	
	}
	
	return Plugin_Stop;

}

void DeadlyVoice_HurtSurroundings(client){

	if(!IsClientInGame(client)) return;
	
	float fClientPos[3];
	GetClientAbsOrigin(client, fClientPos);
	
	for(int i = 1; i <= MaxClients; i++){
	
		if(!DeadlyVoice_IsValidTargetFor(client, i)) continue;
		
		float fTargetPos[3];
		GetClientAbsOrigin(i, fTargetPos);
		
		float fDistance = GetVectorDistance(fClientPos, fTargetPos);
		if(fDistance < g_fDeadlyVoiceRange){
		
			DeadlyVoice_ShakeScreen(i);
			SDKHooks_TakeDamage(i, 0, client, g_fDeadlyVoiceDamage, DMG_BLAST);
		
		}
	
	}

}

void DeadlyVoice_ShakeScreen(int client){

	if(IsFakeClient(client))	return;
	
	float vec[3];
	vec[0] = GetRandomFloat(-15.0, 15.0);
	vec[1] = GetRandomFloat(-15.0, 15.0);
	vec[2] = GetRandomFloat(-15.0, 15.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", vec);

}

stock bool DeadlyVoice_IsValidTargetFor(int client, int target){

	if(client == target)
		return false;
	
	if(!IsClientInGame(target))
		return false;
		
	if(!IsPlayerAlive(target))
		return false;
	
	if(!CanEntitySeeTarget(client, target))
		return false;
	
	return CanPlayerBeHurt(target, client);

}

void DeadlyVoice_ProcessSettings(const char[] sSettings){

	char[][] sPieces = new char[3][8];
	ExplodeString(sSettings, ",", sPieces, 3, 8);

	g_fDeadlyVoiceRate		= StringToFloat(sPieces[0]);
	g_fDeadlyVoiceRange		= StringToFloat(sPieces[1]);
	g_fDeadlyVoiceDamage	= StringToFloat(sPieces[2]);

}
