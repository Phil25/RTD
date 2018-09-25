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


int g_iDruggedId = 21;
UserMsg g_DruggedMsgId;

void Drugged_Start(){
	g_DruggedMsgId = GetUserMessageId("Fade");
}

public void Drugged_Call(int client, Perk perk, bool apply){
	if(apply) Drugged_ApplyPerk(client, perk);
	else UnsetClientPerkCache(client, g_iDruggedId);
}

void Drugged_ApplyPerk(int client, Perk perk){
	g_iDruggedId = perk.Id;
	SetClientPerkCache(client, g_iDruggedId);
	CreateTimer(perk.GetPrefFloat("interval"), Timer_DrugTick, GetClientUserId(client), TIMER_REPEAT);
}

public Action Timer_DrugTick(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iDruggedId))
		return Plugin_Stop;

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
