/**
* Drugged perk.
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


bool	g_bIsDrugged[MAXPLAYERS+1]	= {false, ...};
UserMsg g_DruggedMsgId;

void Drugged_Start(){

	g_DruggedMsgId = GetUserMessageId("Fade");

}

void Drugged_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		Drugged_ApplyPerk(client, StringToFloat(sPref));
	
	else
		g_bIsDrugged[client] = false;

}

void Drugged_ApplyPerk(int client, float fInterval){

	CreateTimer(fInterval, Timer_DrugTick, GetClientSerial(client), TIMER_REPEAT);
	g_bIsDrugged[client] = true;

}

public Action Timer_DrugTick(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0) return Plugin_Stop;
	
	if(!g_bIsDrugged[client]){
	
		Drugged_RemovePerk(client);
		return Plugin_Stop;
	
	}
	
	Drugged_Tick(client);
	
	return Plugin_Continue;

}

void Drugged_Tick(int client){
	
	float fPunch[3];
	fPunch[0] = GetRandomFloat(-45.0, 45.0);
	fPunch[1] = GetRandomFloat(-45.0, 45.0);
	fPunch[2] = GetRandomFloat(-45.0, 45.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fPunch);
	
	int iClients[2];
	iClients[0] = client;
	
	Handle hMsg = StartMessageEx(g_DruggedMsgId, iClients, 1);
	BfWriteShort(hMsg, 255);
	BfWriteShort(hMsg, 255);
	BfWriteShort(hMsg, (0x0002));
	BfWriteByte(hMsg, GetRandomInt(0,255));
	BfWriteByte(hMsg, GetRandomInt(0,255));
	BfWriteByte(hMsg, GetRandomInt(0,255));
	BfWriteByte(hMsg, 128);
	
	EndMessage();

}

void Drugged_RemovePerk(int client){
	
	float fAng[3]; GetClientEyeAngles(client, fAng);
	fAng[2] = 0.0;
	
	TeleportEntity(client, NULL_VECTOR, fAng, NULL_VECTOR);
	
	int iClients[2];
	iClients[0] = client;
		
	Handle hMsg = StartMessageEx(g_DruggedMsgId, iClients, 1);
	
	BfWriteShort(hMsg, 1536);
	BfWriteShort(hMsg, 1536);
	BfWriteShort(hMsg, (0x0001 | 0x0010));
	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, 0);
	
	EndMessage();

}
