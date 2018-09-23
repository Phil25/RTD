/**
* Timebomb perk.
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


#define MODEL_BOMB			"models/props_lakeside_event/bomb_temp_hat.mdl"

#define SOUND_TIMEBOMB_TICK	"buttons/button17.wav"
#define SOUND_TIMEBOMB_GOFF	"weapons/cguard/charging.wav"
#define SOUND_EXPLODE		"weapons/explode3.wav"

#define TICK_SLOW			0.75
#define TICK_FAST			0.35

int		iTimebombTicks		= 10;
float	fTimebombRadius		= 512.0;
float	g_fTimebombDamage	= 270.0;

bool	g_bHasTimebomb[MAXPLAYERS+1]			= {false, ...};
int		g_iTimebombClientTicks[MAXPLAYERS+1]	= {0, ...};
float	g_fTimebombClientBeeps[MAXPLAYERS+1]	= {TICK_SLOW, ...};
int		g_iTimebombHead[MAXPLAYERS+1]			= {0, ...};
int		g_iTimebombState[MAXPLAYERS+1]			= {0, ...};
int		g_iTimebombFlame[MAXPLAYERS+1]			= {0, ...};

void Timebomb_Start(){

	PrecacheModel(MODEL_BOMB);
	
	PrecacheSound(SOUND_EXPLODE);
	PrecacheSound(SOUND_TIMEBOMB_TICK);
	PrecacheSound(SOUND_TIMEBOMB_GOFF);

}

void Timebomb_Perk(int client, const char[] sPref, bool apply){

	if(!apply)
		return;
	
	g_bHasTimebomb[client] = true;
	
	Timebomb_ProcessSettings(sPref);
	
	if(g_iTimebombHead[client] <= MaxClients)
		g_iTimebombHead[client] = Timebomb_SpawnBombHead(client);
	
	int iSerial = GetClientSerial(client);
	
	CreateTimer(1.0, Timer_Timebomb_Tick, iSerial, TIMER_REPEAT);
	
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");

}

public Action Timer_Timebomb_Tick(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;
	
	if(!g_bHasTimebomb[client])
		return Plugin_Stop;
	
	g_iTimebombClientTicks[client]++;
	
	if(g_iTimebombHead[client] > MaxClients && IsValidEntity(g_iTimebombHead[client]))
		if(g_iTimebombClientTicks[client] >= RoundToFloor(iTimebombTicks*0.3))
			if(g_iTimebombClientTicks[client] < RoundToFloor(iTimebombTicks*0.7))
				Timebomb_BombState(client, 1);
			else Timebomb_BombState(client, 2);
	
	
	if(g_iTimebombClientTicks[client] == iTimebombTicks-1)
		EmitSoundToAll(SOUND_TIMEBOMB_GOFF, client);
	else if(g_iTimebombClientTicks[client] >= iTimebombTicks){
	
		Timebomb_Explode(client);
		return Plugin_Stop;
	
	}
	
	return Plugin_Continue;

}

public Action Timer_Timebomb_Beep(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;
	
	if(!g_bHasTimebomb[client])
		return Plugin_Stop;
	
	EmitSoundToAll(SOUND_TIMEBOMB_TICK, client);
	
	CreateTimer(g_fTimebombClientBeeps[client], Timer_Timebomb_Beep, GetClientSerial(client));
	
	return Plugin_Stop;

}

void Timebomb_BombState(int client, int iState){

	if(iState == g_iTimebombState[client])
		return;

	switch(iState){
	
		case 1:{
		
			EmitSoundToAll(SOUND_TIMEBOMB_TICK, client);
			g_fTimebombClientBeeps[client] = TICK_SLOW;
			CreateTimer(g_fTimebombClientBeeps[client], Timer_Timebomb_Beep, GetClientSerial(client));
		
		}
		
		case 2:{
		
			g_fTimebombClientBeeps[client] = TICK_FAST;
		
		}
	
	}
	
	SetEntProp(g_iTimebombHead[client], Prop_Send, "m_nSkin", g_iTimebombState[client]+1);
	
	g_iTimebombState[client] = iState;

}

void Timebomb_OnRemovePerk(int client){

	if(g_bHasTimebomb[client])
		Timebomb_Explode(client, true);

}

void Timebomb_Explode(int client, bool bSilent=false){

	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");

	g_iTimebombClientTicks[client]	= 0;
	g_bHasTimebomb[client]			= false;
	g_fTimebombClientBeeps[client]	= TICK_SLOW;
	g_iTimebombState[client]		= 0;

	if(g_iTimebombHead[client] > MaxClients && IsValidEntity(g_iTimebombHead[client]))
		AcceptEntityInput(g_iTimebombHead[client], "Kill");

	if(g_iTimebombFlame[client] > MaxClients && IsValidEntity(g_iTimebombFlame[client]))
		AcceptEntityInput(g_iTimebombFlame[client], "Kill");
	
	g_iTimebombHead[client] = 0;
	g_iTimebombFlame[client] = 0;
	
	if(bSilent)
		return;

	float fDamage, fPos[3]; GetClientAbsOrigin(client, fPos);
	int iPlayerDamage;
	for(int i = 1; i <= MaxClients; i++){
	
		if(i == client || !IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if(!CanPlayerBeHurt(i, client))
			continue;
		
		if(!CanEntitySeeTarget(client, i))
			continue;
		
		float fPosTarget[3];
		GetClientAbsOrigin(i, fPosTarget);
		
		if(GetVectorDistance(fPos, fPosTarget) <= fTimebombRadius){
		
			fDamage = g_fTimebombDamage;
			iPlayerDamage += RoundToFloor(fDamage);
			
			SDKHooks_TakeDamage(i, 0, client, fDamage, DMG_PREVENT_PHYSICS_FORCE|DMG_CRUSH|DMG_ALWAYSGIB|DMG_BLAST);
		
		}
	
	}
	
	int iShockwave = CreateParticle(client, "rd_robot_explosion_shockwave");
	CreateTimer(1.0, Timer_TimebombRemoveTempParticle, EntIndexToEntRef(iShockwave));
	
	int iExplosion = CreateParticle(client, "rd_robot_explosion");
	CreateTimer(1.0, Timer_TimebombRemoveTempParticle, EntIndexToEntRef(iExplosion));
	
	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Timebomb_Damage", LANG_SERVER, 0x03, iPlayerDamage, 0x01);
	EmitSoundToAll(SOUND_EXPLODE, client);
	FakeClientCommandEx(client, "explode");

}

public Action Timer_TimebombRemoveTempParticle(Handle hTimer, int iRef){

	int iEnt = EntRefToEntIndex(iRef);
	
	if(iEnt <= MaxClients)
		return Plugin_Stop;
	
	if(!IsValidEntity(iEnt))
		return Plugin_Stop;
	
	AcceptEntityInput(iEnt, "Kill");
	
	return Plugin_Stop;

}

int Timebomb_SpawnBombHead(int client){

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
	
	g_iTimebombFlame[client] = CreateParticle(client, "burningplayer_corpse", true, "", fOffs);
	
	return iBomb;

}

void Timebomb_ProcessSettings(const char[] sSettings){
	
	char[][] sPieces = new char[3][8];
	ExplodeString(sSettings, ",", sPieces, 3, 8);

	iTimebombTicks		= StringToInt(sPieces[0]);
	fTimebombRadius		= StringToFloat(sPieces[1]);
	g_fTimebombDamage	= StringToFloat(sPieces[2]);

}
