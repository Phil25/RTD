/**
* Fire Timebomb perk.
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


#define MODEL_BOMB				"models/props_lakeside_event/bomb_temp_hat.mdl"

#define SOUND_FTIMEBOMB_TICK	"buttons/button17.wav"
#define SOUND_FTIMEBOMB_GOFF	"weapons/cguard/charging.wav"
#define SOUND_FEXPLODE			"misc/halloween/spell_fireball_impact.wav"

#define TICK_SLOW			0.75
#define TICK_FAST			0.35

int		g_iFTimebombTicks	= 10;
float	g_fFTimebombRadius	= 512.0;

bool	g_bHasFTimebomb[MAXPLAYERS+1]			= {false, ...};
int		g_iFTimebombClientTicks[MAXPLAYERS+1]	= {0, ...};
float	g_fFTimebombClientBeeps[MAXPLAYERS+1]	= {TICK_SLOW, ...};
int		g_iFTimebombHead[MAXPLAYERS+1]			= {0, ...};
int		g_iFTimebombState[MAXPLAYERS+1]			= {0, ...};

int		g_iFTimebombFlame[MAXPLAYERS+1]			= {0, ...};

void FireTimebomb_Start(){

	PrecacheModel(MODEL_BOMB);
	
	PrecacheSound(SOUND_FEXPLODE);
	PrecacheSound(SOUND_FTIMEBOMB_TICK);
	PrecacheSound(SOUND_FTIMEBOMB_GOFF);

}

void FireTimebomb_Perk(int client, const char[] sPref, bool apply){

	if(!apply)
		return;
	
	g_bHasFTimebomb[client] = true;
	
	FireTimebomb_ProcessSettings(sPref);
	
	if(g_iFTimebombHead[client] <= MaxClients)
		g_iFTimebombHead[client] = FireTimebomb_SpawnBombHead(client);
	
	int iSerial = GetClientSerial(client);
	
	CreateTimer(1.0, Timer_FireTimebomb_Tick, iSerial, TIMER_REPEAT);
	
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");

}

public Action Timer_FireTimebomb_Tick(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;
	
	if(!g_bHasFTimebomb[client])
		return Plugin_Stop;
	
	g_iFTimebombClientTicks[client]++;
	
	if(g_iFTimebombHead[client] > MaxClients && IsValidEntity(g_iFTimebombHead[client]))
		if(g_iFTimebombClientTicks[client] >= RoundToFloor(g_iFTimebombTicks*0.3))
			if(g_iFTimebombClientTicks[client] < RoundToFloor(g_iFTimebombTicks*0.7))
				FireTimebomb_BombState(client, 1);
			else FireTimebomb_BombState(client, 2);
	
	
	if(g_iFTimebombClientTicks[client] == g_iFTimebombTicks-1)
		EmitSoundToAll(SOUND_FTIMEBOMB_GOFF, client);
	else if(g_iFTimebombClientTicks[client] >= g_iFTimebombTicks){
	
		FireTimebomb_Explode(client);
		return Plugin_Stop;
	
	}
	
	return Plugin_Continue;

}

public Action Timer_FireTimebomb_Beep(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;
	
	if(!g_bHasFTimebomb[client])
		return Plugin_Stop;
	
	EmitSoundToAll(SOUND_FTIMEBOMB_TICK, client);
	
	CreateTimer(g_fFTimebombClientBeeps[client], Timer_FireTimebomb_Beep, GetClientSerial(client));
	
	return Plugin_Stop;

}

void FireTimebomb_BombState(int client, int iState){

	if(iState == g_iFTimebombState[client])
		return;

	switch(iState){
	
		case 1:{
		
			EmitSoundToAll(SOUND_FTIMEBOMB_TICK, client);
			g_fFTimebombClientBeeps[client] = TICK_SLOW;
			CreateTimer(g_fFTimebombClientBeeps[client], Timer_FireTimebomb_Beep, GetClientSerial(client));
		
		}
		
		case 2:{
		
			g_fFTimebombClientBeeps[client] = TICK_FAST;
		
		}
	
	}
	
	SetEntProp(g_iFTimebombHead[client], Prop_Send, "m_nSkin", g_iFTimebombState[client]+1);
	
	g_iFTimebombState[client] = iState;

}

void FireTimebomb_OnRemovePerk(int client){

	if(g_bHasFTimebomb[client])
		FireTimebomb_Explode(client, true);

}

void FireTimebomb_Explode(int client, bool bSilent=false){

	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");

	g_iFTimebombClientTicks[client]	= 0;
	g_bHasFTimebomb[client]			= false;
	g_fFTimebombClientBeeps[client]	= TICK_SLOW;
	g_iFTimebombState[client]		= 0;

	if(g_iFTimebombHead[client] > MaxClients && IsValidEntity(g_iFTimebombHead[client]))
		AcceptEntityInput(g_iFTimebombHead[client], "Kill");

	if(g_iFTimebombFlame[client] > MaxClients && IsValidEntity(g_iFTimebombFlame[client]))
		AcceptEntityInput(g_iFTimebombFlame[client], "Kill");
	
	g_iFTimebombHead[client] = 0;
	g_iFTimebombFlame[client] = 0;
	
	if(bSilent)
		return;

	float fPos[3]; GetClientAbsOrigin(client, fPos);
	int iPlayersIgnited = 0;
	for(int i = 1; i <= MaxClients; i++){
	
		if(i == client || !IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if(!CanPlayerBeHurt(i, client))
			continue;
		
		if(!CanEntitySeeTarget(client, i))
			continue;
		
		float fPosTarget[3];
		GetClientAbsOrigin(i, fPosTarget);
		
		if(GetVectorDistance(fPos, fPosTarget) <= g_fFTimebombRadius){
		
			TF2_IgnitePlayer(i, client);
			iPlayersIgnited++;
		
		}
	
	}
	
	int iExplosion = CreateParticle(client, "bombinomicon_burningdebris");
	CreateTimer(1.0, Timer_FTimebombRemoveTempParticle, EntIndexToEntRef(iExplosion));
	
	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Timebomb_Ignite", LANG_SERVER, 0x03, iPlayersIgnited, 0x01);
	EmitSoundToAll(SOUND_FEXPLODE, client);
	TF2_IgnitePlayer(client, client);

}

public Action Timer_FTimebombRemoveTempParticle(Handle hTimer, int iRef){

	int iEnt = EntRefToEntIndex(iRef);
	
	if(iEnt <= MaxClients)
		return Plugin_Stop;
	
	if(!IsValidEntity(iEnt))
		return Plugin_Stop;
	
	AcceptEntityInput(iEnt, "Kill");
	
	return Plugin_Stop;

}

int FireTimebomb_SpawnBombHead(int client){

	int iBomb = CreateEntityByName("prop_dynamic");
	
	DispatchKeyValue(iBomb, "model", MODEL_BOMB);
	
	DispatchSpawn(iBomb);
	
	SetVariantString("!activator");
	AcceptEntityInput(iBomb, "SetParent", client, -1, 0);
	
	TFClassType clsPlayer = TF2_GetPlayerClass(client);
	
	if(clsPlayer == TFClass_Pyro || clsPlayer == TFClass_Engineer)
		SetVariantString("OnUser1 !self,SetParentAttachment,head,0.0,-1");
	else
		SetVariantString("OnUser1 !self,SetParentAttachment,eyes,0.0,-1");
	
	AcceptEntityInput(iBomb, "AddOutput");
	AcceptEntityInput(iBomb, "FireUser1");
	
	float fOffs[3];
	fOffs[2] = 64.0;
	
	g_iFTimebombFlame[client] = CreateParticle(client, "rockettrail", true, "", fOffs);
	
	return iBomb;

}

void FireTimebomb_ProcessSettings(const char[] sSettings){
	
	char[][] sPieces = new char[2][8];
	ExplodeString(sSettings, ",", sPieces, 2, 8);

	g_iFTimebombTicks	= StringToInt(sPieces[0]);
	g_fFTimebombRadius	= StringToFloat(sPieces[1]);

}
