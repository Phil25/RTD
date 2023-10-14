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


#define BLIND_ALPHA 0

#define ANNOTATION_LIFETIME 0

UserMsg g_BlindMsgId;
int g_iBlindId = 22;

void Blind_Start(){
	g_BlindMsgId = GetUserMessageId("Fade");
}

public void Blind_Call(const int client, const Perk perk, const bool apply){
	if(apply) Blind_ApplyPerk(client, perk);
	else Blind_RemovePerk(client);
}

void Blind_ApplyPerk(const int client, const Perk perk){
	g_iBlindId = perk.Id;
	SetClientPerkCache(client, g_iBlindId);

	int iAlpha = perk.GetPrefCell("alpha")
	Blind_SendFade(client, iAlpha);
	SetIntCache(client, iAlpha, BLIND_ALPHA);
	SetFloatCache(client, GetPerkTimeFloat(perk), ANNOTATION_LIFETIME);
	Cache(client).ResetClientFlags();

	Blind_UpdateAnnotations(client);
	CreateTimer(1.0, Blind_UpdateAnnotationsCheck, GetClientUserId(client), TIMER_REPEAT);
}

void Blind_RemovePerk(const int client){
	UnsetClientPerkCache(client, g_iBlindId);
	Blind_SendFade(client, 0);
	Blind_UpdateAnnotations(client, true);
}

void Blind_UpdateAnnotations(const int client, const bool bForceDisable=false){
	int iOtherTeam = GetOppositeTeamOf(client);
	Cache mCache = Cache(client);

	for(int i = 1; i <= MaxClients; ++i){
		bool bSet = mCache.TestClientFlag(i);
		bool bShouldSet = Blind_IsValidTarget(client, i, iOtherTeam) && !bForceDisable;

		if(!bSet && bShouldSet){
			ShowAnnotationFor(client, i, GetFloatCache(client, ANNOTATION_LIFETIME), "<!>");
			mCache.SetClientFlag(i);
		}else if(bSet && !bShouldSet){
			HideAnnotationFor(client, i);
			mCache.UnsetClientFlag(i);
		}
	}
}

public Action Blind_UpdateAnnotationsCheck(Handle hTimer, const int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(client == 0 || !CheckClientPerkCache(client, g_iBlindId))
		return Plugin_Stop;

	Blind_UpdateAnnotations(client);
	return Plugin_Continue;
}

void Blind_PlayerHurt(const int client, Handle hEvent){
	int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(!(0 < iAttacker <= MaxClients) || iAttacker == client || !IsClientInGame(iAttacker))
		return;

	if(!CheckClientPerkCache(iAttacker, g_iBlindId))
		return;

	Blind_SendFade(iAttacker, 0);
	Blind_SendFade(iAttacker, GetIntCache(iAttacker, BLIND_ALPHA), true);
}

bool Blind_IsValidTarget(int client, int iTarget, int iTargetTeam){
	if(iTarget == client || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return false;

	if(GetClientTeam(iTarget) != iTargetTeam)
		return false;

	/*
	* Updating annotation position is a client-side functionality. However, the client might not
	* have an up-to-date position of the other player if that player is far away (ex. died and
	* respawned). This causes annotations to linger there in the last known position.
	*
	* We can fix this by manually checking if the Blind player can see the target, meaning their
	* client knows their coordinates. This unfortunately ends up a bit too expensive than it needs
	* be, but it works.
	*/
	return CanEntitySeeTarget(client, iTarget)
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

#undef BLIND_ALPHA
#undef ANNOTATION_LIFETIME
