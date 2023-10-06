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
int g_iBlindId = 22;

void Blind_Start(){
	g_BlindMsgId = GetUserMessageId("Fade");
}

public void Blind_Call(const int client, const Perk perk, const bool apply){
	if(apply){
		g_iBlindId = perk.Id;
		SetClientPerkCache(client, g_iBlindId);
		Blind_ApplyPerk(client, perk.GetPrefCell("alpha"));
	}else{
		UnsetClientPerkCache(client, g_iBlindId);
		Blind_RemovePerk(client);
	}
}

public void Blind_ApplyPerk(int client, int iAlpha){
	SetIntCache(client, iAlpha)
	Blind_SendFade(client, iAlpha);

	int iOtherTeam = GetOppositeTeamOf(client);

	for(int i = 1; i <= MaxClients; ++i)
		if(Blind_IsValidTarget(client, i, iOtherTeam))
			ShowAnnotationFor(client, i, "<!>");
}

public void Blind_RemovePerk(int client){
	Blind_SendFade(client, 0);

	int iOtherTeam = GetOppositeTeamOf(client);

	for(int i = 1; i <= MaxClients; ++i)
		if(Blind_IsValidTarget(client, i, iOtherTeam))
			HideAnnotationFor(client, i);
}

void Blind_PlayerHurt(Handle hEvent){
	int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(!(0 < iAttacker <= MaxClients) || !IsClientInGame(iAttacker))
		return;

	if(!CheckClientPerkCache(iAttacker, g_iBlindId))
		return;

	Blind_SendFade(iAttacker, 0);
	Blind_SendFade(iAttacker, GetIntCache(iAttacker), true);
}

bool Blind_IsValidTarget(int client, int iTarget, int iTargetTeam){
	if(iTarget == client || !IsClientInGame(iTarget))
		return false;

	if(GetClientTeam(iTarget) != iTargetTeam)
		return false;

	return true;
}

void Blind_SendFade(const int client, const int iAlpha, const bool bFast=false){
	int iTargets[2];
	iTargets[0] = client;

	int iDuration = 200 + 1336 * view_as<int>(!bFast);

	Handle hMsg = StartMessageEx(g_BlindMsgId, iTargets, 1);
	BfWriteShort(hMsg, iDuration);
	BfWriteShort(hMsg, iDuration);
	BfWriteShort(hMsg, iAlpha > 0 ? (0x0002 | 0x0008) : (0x0001 | 0x0010));
	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, iAlpha);

	EndMessage();
}
