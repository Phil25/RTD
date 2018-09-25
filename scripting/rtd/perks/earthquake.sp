/**
* Earthquake perk.
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


UserMsg g_EarthquakeMsgId;

void Earthquake_Start(){
	g_EarthquakeMsgId = GetUserMessageId("Shake");
}

public void Earthquake_Call(int client, Perk perk, bool apply){
	if(!apply) return;

	float fAmplitude = perk.GetPrefFloat("amplitude");
	float fFrequency = perk.GetPrefFloat("frequency");

	int iClients[2];
	iClients[0] = client;

	Handle hMsg = StartMessageEx(g_EarthquakeMsgId, iClients, 1);
	if(hMsg != INVALID_HANDLE){
		BfWriteByte(hMsg, 0);
		BfWriteFloat(hMsg, fAmplitude);
		BfWriteFloat(hMsg, fFrequency);
		BfWriteFloat(hMsg, float(GetPerkTimeEx(perk)));
		EndMessage();
	}
}
