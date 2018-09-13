/**
* Roller class defines clients who interact with the plugin.
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

#if defined _rollers_included
	#endinput
#endif
#define _rollers_included

methodmap Rollers < ArrayList{
	public Rollers(){
		return view_as<Rollers>(new ArrayList(8, MAXPLAYERS+1));
	}

#define GET_PROP(%1,%2,%3) \
	public %1 Get%2(int client){ \
		return view_as<%1>(this.Get(client, %3));}

#define SET_PROP(%1,%2,%3) \
	public %1 Set%2(int client, %1 val){ \
		this.Set(client, val, %3);}

	GET_PROP(bool,InRoll,0)
	SET_PROP(bool,InRoll,0)

	GET_PROP(int,LastRollTime,1)
	SET_PROP(int,LastRollTime,1)

	GET_PROP(int,EndRollTime,2)
	SET_PROP(int,EndRollTime,2)

	GET_PROP(PerkList,PerkHistory,3)
	SET_PROP(PerkList,PerkHistory,3)

	GET_PROP(Perk,Perk,4)
	SET_PROP(Perk,Perk,4)

	GET_PROP(Handle,Timer,5)
	SET_PROP(Handle,Timer,5)

	GET_PROP(Handle,Hud,6)
	SET_PROP(Handle,Hud,6)

	GET_PROP(Group,Group,7)
	SET_PROP(Group,Group,7)

#undef SET_PROP
#undef GET_PROP

	public int PushToPerkHistory(int client, Perk perk){
		PerkList list = this.GetPerkHistory(client);
		if(list == null){
			list = new PerkList();
			this.SetPerkHistory(client, list);
		}
		list.Push(perk);
	}

	public bool IsInPerkHistory(int client, Perk perk, int iLimit){
		PerkList list = this.GetPerkHistory(client);
		if(!list) return false;

		int i = list.Length;
		if(i < iLimit) return false;

		iLimit = i -iLimit;
		while(--i >= iLimit)
			if(list.Get(i) == perk)
				return true;
		return false;
	}

	public void ResetPerkHistory(int client){
		delete this.GetPerkHistory(client);
		this.SetPerkHistory(client, null);
	}

	public void Reset(int client){
		this.SetInRoll(client, false);
		this.SetLastRollTime(client, 0);
		this.SetPerk(client, null);
		this.ResetPerkHistory(client);
	}

	public void ResetPerkHisories(){
		for(int i = 1; i <= MaxClients; ++i)
			this.ResetPerkHistory(i);
	}
}
