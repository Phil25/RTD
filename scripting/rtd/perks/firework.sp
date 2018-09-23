/**
* Firework perk;
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


#define FIREWORK_EXPLOSION	"weapons/flare_detonator_explode.wav"
#define FIREWORK_PARTICLE	"burningplayer_rainbow_flame"

int g_iFireworkParticle[MAXPLAYERS+1] = {-1, ...};

void Firework_Start(){

	PrecacheSound(FIREWORK_EXPLOSION);

}

void Firework_Perk(int client, const char[] sPref, bool apply){

	if(!apply)
		if(g_iFireworkParticle[client] > MaxClients && IsValidEntity(g_iFireworkParticle[client])){
			AcceptEntityInput(g_iFireworkParticle[client], "Kill");
			g_iFireworkParticle[client] = -1;
		}

	float fPush[3];
	fPush[2] = StringToFloat(sPref);

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fPush);
	
	if(g_iFireworkParticle[client] < 0)
		g_iFireworkParticle[client] = CreateParticle(client, FIREWORK_PARTICLE);
	
	CreateTimer(0.5, Timer_Firework_Explode, GetClientSerial(client));

}

public Action Timer_Firework_Explode(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);

	EmitSoundToAll(FIREWORK_EXPLOSION, client);
	
	int iParticle = g_iFireworkParticle[client];
	if(iParticle > MaxClients && IsValidEntity(iParticle))
		AcceptEntityInput(iParticle, "Kill");
	g_iFireworkParticle[client] = -1;

	FakeClientCommandEx(client, "explode");
	
	return Plugin_Stop;

}
