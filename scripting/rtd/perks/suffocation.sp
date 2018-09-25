/**
* Suffocation perk.
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

#define RATE 0
#define DAMAGE 1

int g_iSuffocationId = 42;

void Suffocation_Perk(int client, Perk perk, bool apply){
	if(apply) Suffocation_ApplyPerk(client, perk);
	else UnsetClientPerkCache(client, g_iSuffocationId);
}

void Suffocation_ApplyPerk(client, Perk perk){
	g_iSuffocationId = perk.Id;
	SetClientPerkCache(client, g_iSuffocationId);

	SetFloatCache(client, perk.GetPrefFloat("rate"), RATE);
	SetFloatCache(client, perk.GetPrefFloat("damage"), DAMAGE);

	CreateTimer(perk.GetPrefFloat("delay"), Timer_Suffocation_Begin, GetClientUserId(client));
}

public Action Timer_Suffocation_Begin(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iSuffocationId))
		return Plugin_Stop;

	SDKHooks_TakeDamage(client, 0, 0, GetFloatCache(client, DAMAGE), DMG_DROWN);
	CreateTimer(GetFloatCache(client, RATE), Timer_Suffocation_Cont, iUserId, TIMER_REPEAT);
	return Plugin_Stop;
}

public Action Timer_Suffocation_Cont(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	if(!CheckClientPerkCache(client, g_iSuffocationId))
		return Plugin_Stop;

	SDKHooks_TakeDamage(client, 0, 0, GetFloatCache(client, DAMAGE), DMG_DROWN);
	return Plugin_Continue;
}

#undef RATE
#undef DAMAGE
