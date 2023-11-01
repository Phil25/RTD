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

methodmap Rollers < ArrayList
{
	public Rollers()
	{
		ArrayList data = new ArrayList(7, MAXPLAYERS + 1);

		for (int i = 1; i <= MaxClients; ++i)
			for (int block = 0; block <= 6; ++block)
				data.Set(i, 0, block); // init to false/0/null

		return view_as<Rollers>(data);
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

#undef SET_PROP
#undef GET_PROP

	public int PushToPerkHistory(int client, Perk perk)
	{
		PerkList list = this.GetPerkHistory(client);
		if (!list)
		{
			list = new PerkList();
			this.SetPerkHistory(client, list);
		}

		return list.Push(perk);
	}

	public bool IsInPerkHistory(int client, Perk perk, int iLimit)
	{
		PerkList list = this.GetPerkHistory(client);
		if (!list)
			return false;

		int i = list.Length;
		if (i < iLimit)
			return false;

		iLimit = i -iLimit;
		while (--i >= iLimit)
			if (list.Get(i) == perk)
				return true;

		return false;
	}

	public void ResetPerkHistory(int client)
	{
		PerkList list = this.GetPerkHistory(client);
		if (list)
			list.Clear();
	}

	public void Reset(int client)
	{
		this.SetInRoll(client, false);
		this.SetLastRollTime(client, 0);
		this.SetPerk(client, null);
		this.ResetPerkHistory(client);
	}

	public void ResetPerkHisories()
	{
		for (int i = 1; i <= MaxClients; ++i)
			this.ResetPerkHistory(i);
	}
}
