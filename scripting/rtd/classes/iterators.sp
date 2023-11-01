/**
* Perk container iterators: PerkContainerIter & PerkListIter
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

PerkContainer g_hPerkContainer = null;

/*
"""Interface""" for iterator pattern for 2 perk containers
* Get(0) - ID
* Get(1) - Perk handle
* Get(2) - Container (if null, indicates this is PerkContainerIter)
*/
methodmap PerkIter < ArrayList
{
	public int Id()
	{
		return this.Get(0);
	}

	public Perk Perk()
	{
		return this.Get(1);
	}

	public PerkList List()
	{
		return this.Get(2);
	}

	public void SetPerk(int iId)
	{
		this.Set(0, iId);
		PerkList list = this.List();

		if (list == null)
		{
			this.Set(1, g_hPerkContainer.GetFromId(iId));
		}
		else
		{
			if (iId >= list.Length || iId < 0)
			{
				this.Set(1, view_as<Perk>(null));
			}
			else
			{
				this.Set(1, list.Get(iId));
			}
		}
	}

	public void Next()
	{
		int iId = this.Id();
		this.SetPerk(++iId);
	}

	public void Prev()
	{
		int iId = this.Id();
		this.SetPerk(--iId);
	}
}

/* prefix ++ operator */
stock PerkIter operator++(PerkIter iter)
{
	iter.Next();
	return iter;
}

/* prefix -- operator */
stock PerkIter operator--(PerkIter iter)
{
	iter.Prev();
	return iter;
}

/* Iterator pattern for perks container */
methodmap PerkContainerIter < PerkIter
{
	public PerkContainerIter(int iId)
	{
		ArrayList list = new ArrayList(_, 3);
		list.Set(0, iId);
		list.Set(1, g_hPerkContainer.GetFromId(iId));
		list.Set(2, view_as<PerkList>(null));

		return view_as<PerkContainerIter>(list);
	}
}

/* Iterator pattern for perks list */
methodmap PerkListIter < PerkIter
{
	public PerkListIter(PerkList list, int iId)
	{
		ArrayList data = new ArrayList(_, 3);
		data.Set(0, iId);

		int iLen = list.Length;
		if (iId >= iLen || iId < 0)
		{
			data.Set(1, view_as<Perk>(null));
		}
		else
		{
			data.Set(1, list.Get(iId));
		}

		data.Set(2, list);
		return view_as<PerkListIter>(data);
	}
}
