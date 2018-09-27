/**
* Powerful Hits perk.
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

int g_iPowerfulHitsId = 32;

void PowerfulHits_OnClientPutInServer(int client){
	SDKHook(client, SDKHook_OnTakeDamage, PowerfulHits_OnTakeDamage);
}

public void PowerfulHits_Call(int client, Perk perk, bool apply){
	if(apply) PowerfulHits_Apply(client, perk);
	else UnsetClientPerkCache(client, g_iPowerfulHitsId);
}

void PowerfulHits_Apply(int client, Perk perk){
	g_iPowerfulHitsId = perk.Id;
	SetClientPerkCache(client, g_iPowerfulHitsId);
	SetFloatCache(client, perk.GetPrefFloat("multiplier"));
}

public Action PowerfulHits_OnTakeDamage(int client, int &iAtk, int &iInflictor, float &fDmg, int &iType){
	if(client == iAtk) return Plugin_Continue;
	if(!IsValidClient(iAtk)) return Plugin_Continue;
	if(!CheckClientPerkCache(iAtk, g_iPowerfulHitsId))
		return Plugin_Continue;

	fDmg *= GetFloatCache(iAtk);
	return Plugin_Changed;
}
