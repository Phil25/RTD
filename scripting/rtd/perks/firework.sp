/**
* Firework perk;
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


#define FIREWORK_EXPLOSION	"weapons/flare_detonator_explode.wav"
#define FIREWORK_PARTICLE	"burningplayer_rainbow_flame"

void Firework_Start(){
	PrecacheSound(FIREWORK_EXPLOSION);
}

void Firework_Perk(int client, Perk perk, bool apply){
	if(!apply) return;

	float fPush[3];
	fPush[2] = perk.GetPrefFloat("force");
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fPush);

	int iParticle = CreateParticle(client, FIREWORK_PARTICLE);
	SetEntCache(client, iParticle);
	KILL_ENT_IN(iParticle,0.5)

	CreateTimer(0.5, Timer_Firework_Explode, GetClientUserId(client));
}

public Action Timer_Firework_Explode(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(!client) return Plugin_Stop;

	EmitSoundToAll(FIREWORK_EXPLOSION, client);
	FakeClientCommandEx(client, "explode");
	return Plugin_Stop;
}
