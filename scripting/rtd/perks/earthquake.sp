/**
* Earthquake perk.
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

#define Amplitude Float[0]
#define Frequency Float[1]
#define PerkTime Float[2]
#define FinishTime Float[3]

DEFINE_CALL_APPLY_REMOVE(Earthquake)

public void Earthquake_ApplyPerk(const int client, const Perk perk)
{
	float fPerkTime = GetPerkTimeFloat(perk);

	Cache[client].Amplitude = perk.GetPrefFloat("amplitude", 25.0);
	Cache[client].Frequency = perk.GetPrefFloat("frequency", 25.0);
	Cache[client].PerkTime = fPerkTime;
	Cache[client].FinishTime = GetEngineTime() + fPerkTime;

	UserMessages.Shake(client, Cache[client].Amplitude, Cache[client].Frequency, fPerkTime);
}

public void Earthquake_RemovePerk(const int client, const RTDRemoveReason eRemoveReason)
{
	float fRemainingTime = Cache[client].FinishTime - GetEngineTime();
	float fPercentageLeft = fRemainingTime / Cache[client].PerkTime;

	// gracefully end the effect instead of a hard stop
	UserMessages.StopShake(client);
	UserMessages.Shake(client, Cache[client].Amplitude * fPercentageLeft, Cache[client].Frequency, 0.5);
}

#undef Amplitude
#undef Frequency
#undef PerkTime
#undef FinishTime
