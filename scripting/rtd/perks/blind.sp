/**
* Blind perk.
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


UserMsg g_BlindMsgId;

void Blind_Start(){
	g_BlindMsgId = GetUserMessageId("Fade");
}

public void Blind_Call(int client, Perk perk, bool apply){
	int iTargets[2];
	iTargets[0] = client;

	Handle hMsg = StartMessageEx(g_BlindMsgId, iTargets, 1);
	BfWriteShort(hMsg, 1536);
	BfWriteShort(hMsg, 1536);
	BfWriteShort(hMsg, apply ? (0x0002 | 0x0008) : (0x0001 | 0x0010));
	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, apply ? perk.GetPrefCell("alpha") : 0);

	EndMessage();
}
