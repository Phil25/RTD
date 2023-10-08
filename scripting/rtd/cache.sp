/**
* Cache memory for perks to share.
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


enum struct ClientFlags{
	int iVals[4]; // SM ints are 32 bit, 4 are needed to hold 100 players

	void Set(const int iIndex){
		int iOverflows = iIndex / 32;
		this.iVals[iOverflows] |= 1 << (iIndex - 32 * iOverflows);
	}

	void Unset(const int iIndex){
		int iOverflows = iIndex / 32;
		this.iVals[iOverflows] &= ~(1 << (iIndex - 32 * iOverflows));
	}

	bool Test(const int iIndex){
		int iOverflows = iIndex / 32;
		return view_as<bool>(this.iVals[iOverflows] & (1 << (iIndex - 32 * iOverflows)));
	}

	void Reset(){
		this.iVals[0] = 0;
		this.iVals[1] = 0;
		this.iVals[2] = 0;
		this.iVals[3] = 0;
	}
}

int g_iClientPerkCache[MAXPLAYERS+1] = {-1, ...}; // Used to check if client has the current perk
int g_iEntCache[MAXPLAYERS+1][2]; // Used throughout perks to store their entities
float g_fCache[MAXPLAYERS+1][4];
int g_iCache[MAXPLAYERS+1][4];
ClientFlags g_eClientFlags[MAXPLAYERS+1];
ArrayList g_aCache[MAXPLAYERS+1] = {null, ...};

methodmap Cache{
	public Cache(const int client){
		return view_as<Cache>(client);
	}

	public void SetClientFlag(const int iIndex){
		g_eClientFlags[view_as<int>(this)].Set(iIndex);
	}

	public void UnsetClientFlag(const int iIndex){
		g_eClientFlags[view_as<int>(this)].Unset(iIndex);
	}

	public bool TestClientFlag(const int iIndex){
		return g_eClientFlags[view_as<int>(this)].Test(iIndex);
	}

	public void ResetClientFlags(){
		g_eClientFlags[view_as<int>(this)].Reset();
	}
}

int GetEntCache(int client, int iBlock=0){
	return EntRefToEntIndex(g_iEntCache[client][iBlock]);
}

void SetEntCache(int client, int iEnt, int iBlock=0){
	int iCurEnt = EntRefToEntIndex(g_iEntCache[client][iBlock]);
	if(iCurEnt > MaxClients) AcceptEntityInput(iCurEnt, "Kill");
	g_iEntCache[client][iBlock] = EntIndexToEntRef(iEnt);
}

void KillEntCache(int client, int iBlock=0){
	if(g_iEntCache[client][iBlock] == INVALID_ENT_REFERENCE)
		return;

	int iEnt = EntRefToEntIndex(g_iEntCache[client][iBlock]);
	if(iEnt > MaxClients) AcceptEntityInput(iEnt, "Kill");

	g_iEntCache[client][iBlock] = INVALID_ENT_REFERENCE;
}

void SetClientPerkCache(int client, int iPerkId){
	g_iClientPerkCache[client] = iPerkId;
}

void UnsetClientPerkCache(int client, int iPerkId){
	if(g_iClientPerkCache[client] == iPerkId)
		g_iClientPerkCache[client] = -1;
}

bool CheckClientPerkCache(int client, int iPerkId){
	return g_iClientPerkCache[client] == iPerkId;
}

float GetFloatCache(int client, int iBlock=0){
	return g_fCache[client][iBlock];
}

void SetFloatCache(int client, float fVal, int iBlock=0){
	g_fCache[client][iBlock] = fVal;
}

void GetVectorCache(int client, float fVec[3]){
	fVec[0] = GetFloatCache(client, 1);
	fVec[1] = GetFloatCache(client, 2);
	fVec[2] = GetFloatCache(client, 3);
}

void SetVectorCache(int client, float fVec[3]){
	SetFloatCache(client, fVec[0], 1);
	SetFloatCache(client, fVec[1], 2);
	SetFloatCache(client, fVec[2], 3);
}

int GetIntCache(int client, int iBlock=0){
	return g_iCache[client][iBlock];
}

bool GetIntCacheBool(int client, int iBlock=0){
	return view_as<bool>(g_iCache[client][iBlock]);
}

void SetIntCache(int client, int iVal, int iBlock=0){
	g_iCache[client][iBlock] = iVal;
}

ArrayList CreateArrayCache(int client, int iBlockSize=1){
	delete g_aCache[client];
	g_aCache[client] = new ArrayList(iBlockSize);
	return g_aCache[client];
}

ArrayList PrepareArrayCache(int client, int iBlockSize=1){
	if(g_aCache[client] == null || g_aCache[client].BlockSize != iBlockSize)
		return CreateArrayCache(client, iBlockSize);

	g_aCache[client].Clear();
	return g_aCache[client];
}

ArrayList GetArrayCache(int client){
	return g_aCache[client];
}
