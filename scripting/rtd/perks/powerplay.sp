/**
* PowerPlay perk.
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


public void PowerPlay_Call(int client, Perk perk, bool apply){
	if(apply) PowerPlay_ApplyPerk(client);
	else PowerPlay_RemovePerk(client);
}

public void PowerPlay_ApplyPerk(int client){
	if(TF2_IsPlayerInCondition(client, TFCond_Taunting)){ // Fix for issue #9
		TF2_RemoveCondition(client, TFCond_Taunting);
		CreateTimer(0.0, Timer_PowerPlay_ApplyConditions, GetClientUserId(client));
	}else PowerPlay_ApplyConditions(client);
}

public Action Timer_PowerPlay_ApplyConditions(Handle hTimer, int iUserId){
	int client = GetClientOfUserId(iUserId);
	if(client) PowerPlay_ApplyConditions(client);
	return Plugin_Stop;
}

void PowerPlay_ApplyConditions(int client){
	TF2_AddCondition(client, TFCond_UberchargedCanteen);
	TF2_AddCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_UberBulletResist);
	TF2_AddCondition(client, TFCond_UberBlastResist);
	TF2_AddCondition(client, TFCond_UberFireResist);
	TF2_AddCondition(client, TFCond_MegaHeal);
	TF2_SetPlayerPowerPlay(client, true);
}

void PowerPlay_RemovePerk(int client){
	TF2_RemoveCondition(client, TFCond_UberchargedCanteen);
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_RemoveCondition(client, TFCond_UberBulletResist);
	TF2_RemoveCondition(client, TFCond_UberBlastResist);
	TF2_RemoveCondition(client, TFCond_UberFireResist);
	TF2_RemoveCondition(client, TFCond_MegaHeal);
	TF2_SetPlayerPowerPlay(client, false);
}
