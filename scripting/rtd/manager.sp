/**
* Perk manager.
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


/**********************************************************************************\
	Welcome to the perk manager!

	This script is responsible for actually applying and removing perks,
	so after all the logic goes off in the core rtd.sp first.

	If you have a custom perk you want to add: WRITE A MODULE.
	(editing this plugin is bad)
\**********************************************************************************/

#include "rtd/cache.sp"

void ManagePerk(int client, Perk perk, bool bEnable, RTDRemoveReason reason=RTDRemove_WearOff, const char[] sReason=""){
	if(perk.External)
		perk.Call(client, bEnable);
	else perk.CallInternal(client, bEnable);

	if(!bEnable)
		RemovedPerk(client, reason, sReason);
}


/*
	• Editing Forward_OnMapStart() is OPTIONAL
	• This is a forward of OnMapStart() from rtd.sp
*/
void Forward_OnMapStart(){
	Toxic_Start();
	Explode_Start();
	InfiniteAmmo_Start();
	Timebomb_Start();
	Drugged_Start();
	Blind_Start();
	StripToMelee_Start();
	Beacon_Start();
	ForcedTaunt_Start();
	Earthquake_Start();
	Firework_Start();
	DeadlyVoice_Start();
	NecroMash_Start();
	ExtraAmmo_Start();
	FireTimebomb_Start();
	FireBreath_Start();
	SpringShoes_Start();
	BatSwarm_Start();
	HatThrow_Start();
	MadarasWhistle_Start();
	Sickness_Start();
	MercsDieTwice_Start();
	HellsReach_Start();
	CursedProjectiles_Start();
	Vampire_Start();
	PumpkinTrail_Start();
	ACallBeyond_Start();
}


/*
	• Editing Forward_OnClientPutInServer() is OPTIONAL
	• This is a forward of OnClientPutInServer() from rtd.sp
	• ATTENTION: Also occures to every valid client on OnPluginStart()
*/
void Forward_OnClientPutInServer(int client){
	PowerfulHits_OnClientPutInServer(client);
}


/*
	• Editing Forward_OnClientDisconnect() is OPTIONAL
	• This is a forward of OnClientDisconnect() from rtd.sp
*/
void Forward_OnClientDisconnect(int client){
	Godmode_OnClientDisconnect(client);
}


/*
	• Editing Forward_Voice() is OPTIONAL
	• This is a forward of Listener_Voice() from rtd.sp
	• Listener_Voice() fires when a client says something via Voicemenu
	• Client is guaranteed to be valid and alive.
*/
void Forward_Voice(int client){
	SpawnSentry_Voice(client);
	SpawnDispenser_Voice(client);
	DeadlyVoice_Voice(client);
	FireBreath_Voice(client);
	HatThrow_Voice(client);
	BatSwarm_Voice(client);
	MadarasWhistle_Voice(client);
	MercsDieTwice_Voice(client);
	PumpkinTrail_Voice(client);
	ACallBeyond_Voice(client);
}


/*
	• Editing Forward_Sound() is OPTIONAL
	• This is a forward of Listener_Sound() from rtd.sp
	• Listener_Sound() fires when a client emits a sound
	• Client is guaranteed to be valid.
*/
bool Forward_Sound(int client, const char[] sSound){
	bool bAllow = true;
	bAllow &= DrunkWalk_Sound(client, sSound);
	return bAllow;
}


/*
	• Editing Forward_OnEntityCreated() is OPTIONAL
	• This is a forward of OnEntityCreated() from rtd.sp
	• Entity is NOT guaranteed to be valid.
*/
void Forward_OnEntityCreated(int iEntity, const char[] sClassname){
	HomingProjectiles_OnEntityCreated(iEntity, sClassname);
	FastHands_OnEntityCreated(iEntity, sClassname);
	ExplosiveArrows_OnEntityCreated(iEntity, sClassname);
	LongMelee_OnEntityCreated(iEntity, sClassname);
	CursedProjectiles_OnEntityCreated(iEntity, sClassname);
	OverhealBonus_OnEntityCreated(iEntity, sClassname);
}


/*
	• Editing Forward_OnPlayerDeath() is OPTIONAL
	• This is a forward of Event_PlayerDeath() from rtd.sp
	• Client is guaranteed to be valid.
	• Actual death, Dead Ringer feign does not count.
*/
void Forward_OnPlayerDeath(int client){
	Godmode_OnPlayerDeath(client);
}


/*
	• Editing Forward_Resupply() is OPTIONAL
	• Client is guaranteed to be valid
*/
void Forward_Resupply(int client){
	Invisibility_Resupply(client);
	StripToMelee_OnResupply(client);
	FastHands_Resupply(client);
	LongMelee_Resupply(client);
	OverhealBonus_Resupply(client);
}


/*
	• Editing Forward_PlayerHurt() is OPTIONAL
	• Client is guaranteed to be valid
*/
void Forward_PlayerHurt(int client, Handle hEvent){
	Godmode_PlayerHurt(client, hEvent);
	Blind_PlayerHurt(client, hEvent);
	ScaryBullets_PlayerHurt(client, hEvent);
	EyeForAnEye_PlayerHurt(hEvent);
	DrugBullets_PlayerHurt(client, hEvent);
	MercsDieTwice_PlayerHurt(client, hEvent);
	Vampire_PlayerHurt(client, hEvent);
}


/*
	• Editing Forward_OnGameFrame() is OPTIONAL
	• It's a forward of OnGameFrame() from rtd.sp
*/
void Forward_OnGameFrame(){
}


/*
	• Editing Forward_OnConditionAdded() is OPTIONAL
	• It's a forward of TF2_OnConditionAdded() from rtd.sp
*/
void Forward_OnConditionAdded(int client, TFCond condition){
	Godmode_OnConditionAdded(client, condition);
	FullRifleCharge_OnConditionAdded(client, condition);
	ForcedTaunt_OnConditionAdded(client, condition);
}


/*
	• Editing Forward_OnConditionRemoved() is OPTIONAL
	• It's a forward of TF2_OnConditionRemoved() from rtd.sp
*/
void Forward_OnConditionRemoved(int client, TFCond condition){
	Godmode_OnConditionRemoved(client, condition);
	FullUbercharge_OnConditionRemoved(client, condition);
	FunnyFeeling_OnConditionRemoved(client, condition);
	ForcedTaunt_OnConditionRemoved(client, condition);
}


/*
	• Editing Forward_OnPlayerRunCmd() is OPTIONAL
	• It's a forward of OnPlayerRunCmd() from rtd.sp
	• Client is guaranteed to be valid.
	• Return TRUE if anything changed.
	• You cannot block it from this forward.
*/
public bool Forward_OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVel[3], float fAng[3], int &iWeapon){
	InfiniteJump_OnPlayerRunCmd(client, iButtons);
	BigHead_OnPlayerRunCmd(client);
	Noclip_OnPlayerRunCmd(client, fVel, fAng)
	if(Cursed_OnPlayerRunCmd(client, iButtons, fVel))
		return true;
	return false;
}


/*
	• Editing Forward_AttackIsCritical() is OPTIONAL
	• Returning true from here means that the next attack is crit.
	• REGARDLESS whether the client is in roll or not.
	• Client is guaranteed to be valid.
	• You cannot block it from this forward.
*/
public bool Forward_AttackIsCritical(int client, int iWeapon, const char[] sWeaponName){
	StrongRecoil_CritCheck(client, iWeapon);
	PowerPlay_OnAttack(client);

	/*
		if(Something_SetCritical(client)
		|| Something2_SetCritical(client)
		|| Something3_SetCritical(client))
			return true;
	*/

	if(LuckySandvich_SetCritical(client))
		return true;
	return false;
}
