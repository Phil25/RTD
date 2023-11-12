/**
* Heavy Rockets perk.
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

DEFINE_CALL_EMPTY(HeavyRockets)

// Do not save in client cache -- it might be overridden by a different perk while rocket is alive.
static int g_iHeavyRocketsSharpness = 8;

public void HeavyRockets_Init(const Perk perk)
{
	g_iHeavyRocketsSharpness = ClampInt(perk.GetPrefCell("sharpness", 8), 1, 100);

	Events.OnEntitySpawned(perk, HeavyRockets_OnRocketSpawned, HeavyRockets_ClassFilter, Retriever_OwnerEntity);
}

void HeavyRockets_OnRocketSpawned(const int client, const int iRocket)
{
	// Timer mechanics limit this to around 0.1ish, except for the initial call
	CreateTimer(0.0, Timer_HeavyRockets_Think, EntIndexToEntRef(iRocket), TIMER_REPEAT);
}

Action Timer_HeavyRockets_Think(Handle hTimer, const int iRef)
{
	int iRocket = EntRefToEntIndex(iRef);
	if (iRocket <= MaxClients)
		return Plugin_Stop;

	float fPos[3];
	GetEntPropVector(iRocket, Prop_Send, "m_vecOrigin", fPos);

	fPos[2] -= 100.0;
	Homing_TurnToTarget(fPos, iRocket, g_iHeavyRocketsSharpness);

	return Plugin_Continue;
}

bool HeavyRockets_ClassFilter(const char[] sClassname)
{
	return StrEqual(sClassname, "tf_projectile_rocket");
}