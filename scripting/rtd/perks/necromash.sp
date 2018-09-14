
/*
	THESE FUNCTIONS ARE ENTIRELY MADE BY Pelipoika IN HIS PLUGIN "Necromasher":
	https://forums.alliedmods.net/showthread.php?p=2300875
	All credits go to him!
*/

bool g_bShouldBeSmashed[MAXPLAYERS+1] = {false, ...};

void NecroMash_Start(){

	PrecacheModel("models/props_halloween/hammer_gears_mechanism.mdl");
	PrecacheModel("models/props_halloween/hammer_mechanism.mdl");
	PrecacheModel("models/props_halloween/bell_button.mdl");
	
	PrecacheSound("misc/halloween/strongman_fast_impact_01.wav");
	PrecacheSound("ambient/explosions/explode_1.wav");
	PrecacheSound("misc/halloween/strongman_fast_whoosh_01.wav");
	PrecacheSound("misc/halloween/strongman_fast_swing_01.wav");
	PrecacheSound("doors/vent_open2.wav");

}

public void NecroMash_Perk(int client, const char[] sPref, bool apply){

	if(!apply)
		return;
	
	if(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") > -1)
		NecroMash_SmashClient(client);
	
	else{
	
		g_bShouldBeSmashed[client] = true;
		CreateTimer(0.1, Timer_NecroMash_Retry, GetClientSerial(client), TIMER_REPEAT);
	
	}

}

public Action Timer_NecroMash_Retry(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;

	if(!g_bShouldBeSmashed[client])
		return Plugin_Stop;
	
	if(GetEntProp(client, Prop_Send, "m_hGroundEntity") < 0)
		return Plugin_Continue;
	
	g_bShouldBeSmashed[client] = false;
	NecroMash_SmashClient(client);
	
	return Plugin_Stop;

}

void NecroMash_SmashClient(int client){

	float flPos[3], flPpos[3], flAngles[3];
	GetClientAbsOrigin(client, flPos);
	GetClientAbsOrigin(client, flPpos);
	GetClientEyeAngles(client, flAngles);
	flAngles[0] = 0.0;
	
	float vForward[3];
	GetAngleVectors(flAngles, vForward, NULL_VECTOR, NULL_VECTOR);
	flPos[0] -= (vForward[0] * 750);
	flPos[1] -= (vForward[1] * 750);
	flPos[2] -= (vForward[2] * 750);
	
	flPos[2] += 350.0;
	int gears = CreateEntityByName("prop_dynamic");
	if(IsValidEntity(gears)){
	
		DispatchKeyValueVector(gears, "origin", flPos);
		DispatchKeyValueVector(gears, "angles", flAngles);
		DispatchKeyValue(gears, "model", "models/props_halloween/hammer_gears_mechanism.mdl");
		DispatchSpawn(gears);
	
	}
	
	int hammer = CreateEntityByName("prop_dynamic");
	if(IsValidEntity(hammer)){
	
		DispatchKeyValueVector(hammer, "origin", flPos);
		DispatchKeyValueVector(hammer, "angles", flAngles);
		DispatchKeyValue(hammer, "model", "models/props_halloween/hammer_mechanism.mdl");
		DispatchSpawn(hammer);
	
	}
	
	int button = CreateEntityByName("prop_dynamic");
	if(IsValidEntity(button)){
	
		flPos[0] += (vForward[0] * 600);
		flPos[1] += (vForward[1] * 600);
		flPos[2] += (vForward[2] * 600);
		
		flPos[2] -= 100.0;
		flAngles[1] += 180.0;
		
		DispatchKeyValueVector(button, "origin", flPos);
		DispatchKeyValueVector(button, "angles", flAngles);
		DispatchKeyValue(button, "model", "models/props_halloween/bell_button.mdl");
		DispatchSpawn(button);
		
		Handle pack;
		CreateDataTimer(1.3, Timer_NecroMash_Hit, pack);
		WritePackFloat(pack, flPpos[0]); //Position of effects
		WritePackFloat(pack, flPpos[1]); //Position of effects
		WritePackFloat(pack, flPpos[2]); //Position of effects
		
		Handle pack2;
		CreateDataTimer(1.0, Timer_NecroMash_Whoosh, pack2);
		WritePackFloat(pack2, flPpos[0]); //Position of effects
		WritePackFloat(pack2, flPpos[1]); //Position of effects
		WritePackFloat(pack2, flPpos[2]); //Position of effects
		
		EmitSoundToAll("misc/halloween/strongman_fast_swing_01.wav", _, _, _, _, _, _, _, flPpos);
	}
	
	SetVariantString("OnUser1 !self:SetAnimation:smash:0:1");
	AcceptEntityInput(gears, "AddOutput");
	AcceptEntityInput(gears, "FireUser1");
	
	SetVariantString("OnUser1 !self:SetAnimation:smash:0:1");
	AcceptEntityInput(hammer, "AddOutput");
	AcceptEntityInput(hammer, "FireUser1");
	
	SetVariantString("OnUser1 !self:SetAnimation:hit:1.3:1");
	AcceptEntityInput(button, "AddOutput");
	AcceptEntityInput(button, "FireUser1");
	
	SetVariantString("OnUser2 !self:Kill::5.0:1");
	AcceptEntityInput(gears, "AddOutput");
	AcceptEntityInput(gears, "FireUser2");
	
	SetVariantString("OnUser2 !self:Kill::5.0:1");
	AcceptEntityInput(hammer, "AddOutput");
	AcceptEntityInput(hammer, "FireUser2");
	
	SetVariantString("OnUser2 !self:Kill::5.0:1");
	AcceptEntityInput(button, "AddOutput");
	AcceptEntityInput(button, "FireUser2");

}

public Action Timer_NecroMash_Hit(Handle timer, any pack){

	ResetPack(pack);
	
	float pos[3];
	pos[0] = ReadPackFloat(pack);
	pos[1] = ReadPackFloat(pack);
	pos[2] = ReadPackFloat(pack);
	
	int shaker = CreateEntityByName("env_shake");
	if(shaker != -1){
	
		DispatchKeyValue(shaker, "amplitude", "10");
		DispatchKeyValue(shaker, "radius", "1500");
		DispatchKeyValue(shaker, "duration", "1");
		DispatchKeyValue(shaker, "frequency", "2.5");
		DispatchKeyValue(shaker, "spawnflags", "4");
		DispatchKeyValueVector(shaker, "origin", pos);
		
		DispatchSpawn(shaker);
		AcceptEntityInput(shaker, "StartShake");
		
		SetVariantString("OnUser1 !self:Kill::1.0:1");
		AcceptEntityInput(shaker, "AddOutput");
		AcceptEntityInput(shaker, "FireUser1");
	
	}
	
	EmitSoundToAll("ambient/explosions/explode_1.wav", _, _, _, _, _, _, _, pos);
	EmitSoundToAll("misc/halloween/strongman_fast_impact_01.wav", _, _, _, _, _, _, _, pos);
	
	float pos2[3], Vec[3], AngBuff[3];
	
	for(int i = 1; i <= MaxClients; i++){
	
		if(IsClientInGame(i) && IsPlayerAlive(i)){
		
			GetClientAbsOrigin(i, pos2);

			if(GetVectorDistance(pos, pos2) <= 500.0){
			
				MakeVectorFromPoints(pos, pos2, Vec);
				GetVectorAngles(Vec, AngBuff);
				AngBuff[0] -= 30.0; 
				GetAngleVectors(AngBuff, Vec, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(Vec, Vec);
				ScaleVector(Vec, 500.0);    
				Vec[2] += 250.0;
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, Vec);
			
			}
			
			if(GetVectorDistance(pos, pos2) <= 60.0)
				SDKHooks_TakeDamage(i, i, i, 999999.0, DMG_CLUB|DMG_ALWAYSGIB|DMG_BLAST);
		
		}
	
	}
	
	pos[2] += 10.0;
	NecroMash_CreateParticle("hammer_impact_button", pos);
	NecroMash_CreateParticle("hammer_bones_kickup", pos);

}

public Action Timer_NecroMash_Whoosh(Handle timer, any pack){

	ResetPack(pack);

	float pos[3];
	pos[0] = ReadPackFloat(pack);
	pos[1] = ReadPackFloat(pack);
	pos[2] = ReadPackFloat(pack);
	
	EmitSoundToAll("misc/halloween/strongman_fast_whoosh_01.wav", _, _, _, _, _, _, _, pos);

}

stock void NecroMash_CreateParticle(char[] particle, float pos[3]){

	int tblidx = FindStringTable("ParticleEffectNames");
	char tmp[256];
	int count = GetStringTableNumStrings(tblidx);
	int stridx = INVALID_STRING_INDEX;
	
	for(int i = 0; i < count; i++){
	
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if(StrEqual(tmp, particle, false)){
            stridx = i;
            break;
        }
	
    }
    
	for(int i = 1; i <= GetMaxClients(); i++){
	
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		TE_Start("TFParticleEffect");
		TE_WriteFloat("m_vecOrigin[0]", pos[0]);
		TE_WriteFloat("m_vecOrigin[1]", pos[1]);
		TE_WriteFloat("m_vecOrigin[2]", pos[2]);
		TE_WriteNum("m_iParticleSystemIndex", stridx);
		TE_WriteNum("entindex", -1);
		TE_WriteNum("m_iAttachType", 2);
		TE_SendToClient(i, 0.0);
	}

}
