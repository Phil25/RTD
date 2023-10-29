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

DEFINE_CALL_APPLY(Drugged)

public void Drugged_ApplyPerk(const int client, const Perk perk)
{
	Cache[client].Repeat(perk.GetPrefFloat("interval", 1.0), Drugged_Tick);
}

public Action Drugged_Tick(const int client)
{
	float fPunch[3];
	fPunch[0] = GetRandomFloat(-45.0, 45.0);
	fPunch[1] = GetRandomFloat(-45.0, 45.0);
	fPunch[2] = GetRandomFloat(-45.0, 45.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fPunch);

	int iClients[2];
	iClients[0] = client;

	Handle hMsg = StartMessageEx(UserMessages.Fade, iClients, 1);
	BfWriteShort(hMsg, 255);
	BfWriteShort(hMsg, 255);
	BfWriteShort(hMsg, (0x0002));
	BfWriteByte(hMsg, GetRandomInt(0,255));
	BfWriteByte(hMsg, GetRandomInt(0,255));
	BfWriteByte(hMsg, GetRandomInt(0,255));
	BfWriteByte(hMsg, 128);

	EndMessage();

	return Plugin_Continue;
}
