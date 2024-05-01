/**
* Big Head perk.
* Copyright (C) 2023 Filip Tomaszewski
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

#define Scale Float[0]

DEFINE_CALL_APPLY_REMOVE(BigHead)

public void BigHead_Init(const Perk perk)
{
	Events.OnPlayerRunCmd(perk, BigHead_OnPlayerRunCmd);
}

public void BigHead_ApplyPerk(const int client, const Perk perk)
{
	float fScale = perk.GetPrefFloat("scale", 2.5);

	Cache[client].Scale = fScale;

	TF2Attrib_SetByDefIndex(client, Attribs.VoicePitch, 1.0 / Min(fScale, 3.0));
}

public void BigHead_RemovePerk(const int client, const RTDRemoveReason eRemoveReason)
{
	TF2Attrib_RemoveByDefIndex(client, Attribs.VoicePitch);
}

bool BigHead_OnPlayerRunCmd(const int client, int& iButtons, float fVel[3], float fAng[3])
{
	SetEntPropFloat(client, Prop_Send, "m_flHeadScale", Cache[client].Scale);
	return false;
}

#undef Scale
