/**
* Used to track rolls of groups, such as @all or @blue
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

#if defined _group_included
	#endinput
#endif
#define _group_included

#include "rtd/parsing.sp"

/*
	Get(0) - perk handle
	Get(1) - is group active (bool)
	Get(2..n) - client serial
*/
methodmap Group < ArrayList{
	public Group(){
		ArrayList data = new ArrayList(_, 2);
		data.Set(0, view_as<Perk>(null));
		data.Set(1, true);
		return view_as<Group>(data);
	}

	property int ClientCount{
		public get(){
			return this.Length -2;
		}
	}

	property bool Active{
		public get(){
			return view_as<bool>(this.Get(1));
		}
		public set(bool bActive){
			this.Set(1, bActive);
		}
	}

	property Perk Perk{
		public get(){
			return view_as<Perk>(this.Get(0));
		}
		public set(Perk perk){
			this.Set(0, perk);
		}
	}

	public int GetClient(int i){
		return GetClientFromSerial(this.Get(i+2));
	}

	public int PushClient(int client){
		return this.Push(GetClientSerial(client));
	}

	public void EraseClient(int client){
		int i = this.Length;
		int iSerial = GetClientSerial(client);

		while(--i >= 2)
			if(this.Get(i) == iSerial){
				this.Erase(i);
				this.Active = i > 2;
				break;
			}
	}
}

ArrayList g_hGroups = null;

Group PrepareGroup(){
	int i = g_hGroups.Length;
	Group group = null;
	while(--i >= 0){
		group = view_as<Group>(g_hGroups.Get(i));
		if(!group.Active){
			group.Active = true;
			break;
		}
	}

	if(i == -1){
		group = new Group();
		g_hGroups.Push(group);
	}

	return group;
}
