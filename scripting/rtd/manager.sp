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
	so after all the logic goes off in the core rtd2.sp first.

	If you have a custom perk you want to add: WRITE A MODULE.
	(editing this plugin is bad)
\**********************************************************************************/

void ManagePerk(int client, Perk perk, bool enable, RTDRemoveReason reason=RTDRemove_WearOff, const char[] sReason=""){
	//If the perk effect is NOT in this plugin, execute the function and stop, check if it's not being disabled and just stop right there.
	if(perk.External){
		perk.Call(client, enable);

		if(!enable)	//Check if anything is needing to be printed.
			RemovedPerk(client, reason, sReason);
		return;	//Stop further exectuion of ManagePerk()
	}

	//This is the optional value for perks, found under "settings" in rtd2_perks.cfg
	char sSettings[127];
	perk.GetPref(sSettings, 127);

	//template: case <your_perk_id>:{YourPerk_Function(client, sSettings, enable);}
	int iId = perk.Id;
	switch(iId){
		case 0:	Godmode_Perk			(client, sSettings, enable);
		case 1:	Toxic_Perk				(client, sSettings, enable);
		case 2:	LuckySandvich_Perk		(client, sSettings, enable);
		case 3:	IncreasedSpeed_Perk		(client, sSettings, enable);
		case 4:	Noclip_Perk				(client, sSettings, enable);
		case 5:	LowGravity_Perk			(client, sSettings, enable);
		case 6:	FullUbercharge_Perk		(client, sSettings, enable);
		case 7:	Invisibility_Perk		(client, sSettings, enable);
		case 8:	InfiniteCloak_Perk		(client, sSettings, enable);
		case 9:	Criticals_Perk			(client, sSettings, enable);
		case 10:InfiniteAmmo_Perk		(client, sSettings, enable);
		case 11:ScaryBullets_Perk		(client, sSettings, enable);
		case 12:SpawnSentry_Perk		(client, sSettings, enable);
		case 13:HomingProjectiles_Perk	(client, sSettings, enable);
		case 14:FullRifleCharge_Perk	(client, sSettings, enable);
		case 15:Explode_Perk			(client, sSettings, enable);
		case 16:Snail_Perk				(client, sSettings, enable);
		case 17:Frozen_Perk				(client, sSettings, enable);
		case 18:Timebomb_Perk			(client, sSettings, enable);
		case 19:Ignition_Perk			(client, sSettings, enable);
		case 20:LowHealth_Perk			(client, sSettings, enable);
		case 21:Drugged_Perk			(client, sSettings, enable);
		case 22:Blind_Perk				(client, sSettings, enable);
		case 23:StripToMelee_Perk		(client, sSettings, enable);
		case 24:Beacon_Perk				(client, sSettings, enable);
		case 25:ForcedTaunt_Perk		(client, sSettings, enable);
		case 26:Monochromia_Perk		(client, sSettings, enable);
		case 27:Earthquake_Perk			(client, sSettings, enable);
		case 28:FunnyFeeling_Perk		(client, sSettings, enable);
		case 29:BadSauce_Perk			(client, sSettings, enable);
		case 30:SpawnDispenser_Perk		(client, sSettings, enable);
		case 31:InfiniteJump_Perk		(client, sSettings, enable);
		case 32:PowerfulHits_Perk		(client, sSettings, enable);
		case 33:BigHead_Perk			(client, sSettings, enable);
		case 34:TinyMann_Perk			(client, sSettings, enable);
		case 35:Firework_Perk			(client, sSettings, enable);
		case 36:DeadlyVoice_Perk		(client, sSettings, enable);
		case 37:StrongGravity_Perk		(client, sSettings, enable);
		case 38:EyeForAnEye_Perk		(client, sSettings, enable);
		case 39:Weakened_Perk			(client, sSettings, enable);
		case 40:NecroMash_Perk			(client, sSettings, enable);
		case 41:ExtraAmmo_Perk			(client, sSettings, enable);
		case 42:Suffocation_Perk		(client, sSettings, enable);
		case 43:FastHands_Perk			(client, sSettings, enable);
		case 44:Outline_Perk			(client, sSettings, enable);
		case 45:Vital_Perk				(client, sSettings, enable);
		case 46:NoGravity_Perk			(client, sSettings, enable);
		case 47:TeamCriticals_Perk		(client, sSettings, enable);
		case 48:FireTimebomb_Perk		(client, sSettings, enable);
		case 49:FireBreath_Perk			(client, sSettings, enable);
		case 50:StrongRecoil_Perk		(client, sSettings, enable);
		case 51:Cursed_Perk				(client, sSettings, enable);
		case 52:ExtraThrowables_Perk	(client, sSettings, enable);
		case 53:PowerPlay_Perk			(client, sSettings, enable);
		case 54:ExplosiveArrows_Perk	(client, sSettings, enable);
		case 55:InclineProblem_Perk		(client, sSettings, enable);
		case 56:SpringShoes_Perk		(client, sSettings, enable);
		case 57:Lag_Perk				(client, sSettings, enable);
		case 58:DrugBullets_Perk		(client, sSettings, enable);
		case 59:LongMelee_Perk			(client, sSettings, enable);
		case 60:HatThrow_Perk			(client, sSettings, enable);
		case 61:MadarasWhistle_Perk		(client, sSettings, enable);
		case 62:Sickness_Perk			(client, sSettings, enable);
	}

	if(!enable)
		RemovedPerk(client, reason, sReason);
}


/*
	• Editing Forward_OnMapStart() is OPTIONAL
	• This is a forward of OnMapStart() from rtd2.sp
*/
void Forward_OnMapStart(){
	Invisibility_Start();
	InfiniteAmmo_Start();
	HomingProjectiles_Start();
	FullRifleCharge_Start();
	Timebomb_Start();
	Drugged_Start();
	Blind_Start();
	Beacon_Start();
	ForcedTaunt_Start();
	Earthquake_Start();
	ScaryBullets_Start();
	Firework_Start();
	DeadlyVoice_Start();
	EyeForAnEye_Start();
	NecroMash_Start();
	ExtraAmmo_Start();
	FastHands_Start();
	FireTimebomb_Start();
	FireBreath_Start();
	ExplosiveArrows_Start();
	SpringShoes_Start();
	DrugBullets_Start();
	LongMelee_Start();
	HatThrow_Start();
	MadarasWhistle_Start();
	Sickness_Start();
}


/*
	• Editing Forward_OnClientPutInServer() is OPTIONAL
	• This is a forward of OnClientPutInServer() from rtd2.sp
	• ATTENTION: Also occures to every valid client on OnPluginStart()
*/
void Forward_OnClientPutInServer(int client){
	PowerfulHits_OnClientPutInServer(client);
}


/*
	• Editing Forward_Voice() is OPTIONAL
	• This is a forward of Listener_Voice() from rtd2.sp
	• Listener_Voice() fires when a client says something via Voicemenu
	• Client is guaranteed to be valid and alive.
*/
void Forward_Voice(int client){
	SpawnSentry_Voice(client);
	SpawnDispenser_Voice(client);
	DeadlyVoice_Voice(client);
	FireBreath_Voice(client);
	HatThrow_Voice(client);
	MadarasWhistle_Voice(client);
}


/*
	• Editing Forward_OnEntityCreated() is OPTIONAL
	• This is a forward of OnEntityCreated() from rtd2.sp
	• Entity is NOT guaranteed to be valid.
*/
void Forward_OnEntityCreated(int iEntity, const char[] sClassname){
	HomingProjectiles_OnEntityCreated(iEntity, sClassname);
	FastHands_OnEntityCreated(iEntity, sClassname);
	ExplosiveArrows_OnEntityCreated(iEntity, sClassname);
	LongMelee_OnEntityCreated(iEntity, sClassname);
}


/*
	• Editing Forward_OnGameFrame() is OPTIONAL
	• It's a forward of OnGameFrame() from rtd2.sp
*/
void Forward_OnGameFrame(){
	HomingProjectiles_OnGameFrame();
}


/*
	• Editing Forward_OnConditionAdded() is OPTIONAL
	• It's a forward of TF2_OnConditionAdded() from rtd2.sp
*/
void Forward_OnConditionAdded(int client, TFCond condition){
	FullRifleCharge_OnConditionAdded(client, condition);
	ForcedTaunt_OnConditionAdded(client, condition);
}


/*
	• Editing Forward_OnConditionRemoved() is OPTIONAL
	• It's a forward of TF2_OnConditionRemoved() from rtd2.sp
*/
void Forward_OnConditionRemoved(int client, TFCond condition){
	FullUbercharge_OnConditionRemoved(client, condition);
	FunnyFeeling_OnConditionRemoved(client, condition);
	ForcedTaunt_OnConditionRemoved(client, condition);
}


/*
	• Editing Forward_OnPlayerRunCmd() is OPTIONAL
	• It's a forward of OnPlayerRunCmd() from rtd2.sp
	• Client is guaranteed to be valid.
	• Return TRUE if anything changed.
	• You cannot block it from this forward.
*/
public bool Forward_OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVel[3], float fAng[3], int &iWeapon){
	InfiniteJump_OnPlayerRunCmd(client, iButtons);
	BigHead_OnPlayerRunCmd(client);
	if(Cursed_OnPlayerRunCmd(client, iButtons, fVel))
		return true;
	return false;
}


/*
	• Editing Forward_OnRemovePerkPre() is OPTIONAL
	• It fires before a perk is about to be removed.
	• REGARDLESS whether the client is in roll or not.
	• Client is guaranteed to be valid.
	• You cannot block it from this forward.
*/
void Forward_OnRemovePerkPre(int client){
	Timebomb_OnRemovePerk(client);
	FireTimebomb_OnRemovePerk(client);
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
