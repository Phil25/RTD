/**
* No Gravity perk.
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


float g_fNoGravBaseGravity[MAXPLAYERS+1] = {0.0, ...};

public void NoGravity_Perk(int client, const char[] sPref, bool apply){

	if(apply)
		NoGravity_ApplyPerk(client);
	
	else
		SetEntityGravity(client, g_fNoGravBaseGravity[client]);

}

void NoGravity_ApplyPerk(int client){

	g_fBaseGravity[client] = GetEntityGravity(client);
	SetEntityGravity(client, 0.01);

}
