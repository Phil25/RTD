/**
* Blind perk.
* Copyright (C) 2023 Filip Tomaszewski
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

#define Alpha Int[0]
#define AnnotationLifetime Float[0]

DEFINE_CALL_APPLY_REMOVE(Blind)

public void Blind_Init(const Perk perk)
{
	Events.OnPlayerAttacked(perk, Blind_OnPlayerAttacked);
}

void Blind_ApplyPerk(const int client, const Perk perk)
{
	int iAlpha = perk.GetPrefCell("alpha", 254);
	Cache[client].Alpha = iAlpha;
	Cache[client].AnnotationLifetime = GetPerkTimeFloat(perk);
	Cache[client].Flags.Reset();

	Blind_SendFade(client, iAlpha);
	Blind_UpdateAnnotations(client);
	SetOverlay(client, ClientOverlay_Stealth);

	Cache[client].Repeat(1.0, Blind_UpdateAnnotationsCheck);
}

void Blind_RemovePerk(const int client)
{
	Blind_SendFade(client, 0);
	Blind_UpdateAnnotations(client, true);
	SetOverlay(client, ClientOverlay_None);
}

public Action Blind_UpdateAnnotationsCheck(const int client)
{
	Blind_UpdateAnnotations(client);
	return Plugin_Continue;
}

void Blind_UpdateAnnotations(const int client, const bool bForceDisable=false)
{
	int iOtherTeam = GetOppositeTeamOf(client);

	for (int i = 1; i <= MaxClients; ++i)
	{
		bool bSet = Cache[client].Flags.Test(i);
		bool bShouldSet = Blind_IsValidTarget(client, i, iOtherTeam) && !bForceDisable;

		if (!bSet && bShouldSet)
		{
			ShowAnnotationFor(client, i, Cache[client].AnnotationLifetime, "<!>");
			Cache[client].Flags.Set(i);
		}
		else if (bSet && !bShouldSet)
		{
			HideAnnotationFor(client, i);
			Cache[client].Flags.Unset(i);
		}
	}
}

public void Blind_OnPlayerAttacked(const int client, const int iVictim, const int iDamage, const int iRemainingHealth)
{
	Blind_SendFade(client, 0);
	Blind_SendFade(client, Cache[client].Alpha, true);
}

bool Blind_IsValidTarget(const int client, const int iTarget, const int iTargetTeam)
{
	if (iTarget == client || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return false;

	if (GetClientTeam(iTarget) != iTargetTeam)
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

void Blind_SendFade(const int client, const int iAlpha, const bool bFast=false)
{
	int iTargets[2];
	iTargets[0] = client;

	int iDuration = 200 + 1336 * view_as<int>(!bFast);

	Handle hMsg = StartMessageEx(UserMessages.Fade, iTargets, 1);
	BfWriteShort(hMsg, iDuration);
	BfWriteShort(hMsg, iDuration);
	BfWriteShort(hMsg, iAlpha > 0 ? (0x0002 | 0x0008) : (0x0001 | 0x0010));
	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, iAlpha);

	EndMessage();
}

#undef Alpha
#undef AnnotationLifetime
