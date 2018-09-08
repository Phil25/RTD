/**
* Helper functions for parsing perk from KV.
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

#if defined _perkparsing_included
	#endinput
#endif
#define _perkparsing_included

/* return flag value based on TF2 classes, 0 or 511 = all class */
int StringToClass(const char[] sClasses){
	int i = -1, iFlags = 0;
	while(sClasses[++i] != '\0')
		iFlags |= ParseClassDigit(sClasses[i]);
	return iFlags == 0 ? 511 : iFlags;
}

ArrayList StringToWeaponClass(const char[] sWeapClass){
	if(FindCharInString(sWeapClass, '0') != -1)
		return null;

	char sWeapClassEsc[127];
	EscapeString(sWeapClass, ' ', '\0', sWeapClassEsc, 127);
	ArrayList list = new ArrayList(32);

	int iSize = CountCharInString(sWeapClassEsc, ',')+1;
	char[][] sPieces = new char[iSize][32];

	ExplodeString(sWeapClassEsc, ",", sPieces, iSize, 64);
	for(int i = 0; i < iSize; i++)
		list.PushString(sPieces[i]);
	return list;
}

ArrayList StringToTags(const char[] sTags){
	ArrayList list = new ArrayList(32);

	int iSize = CountCharInString(sTags, '|')+1;
	char[][] sPieces = new char[iSize][24];

	ExplodeString(sTags, "|", sPieces, iSize, 24);
	for(int i = 0; i < iSize; i++)
		list.PushString(sPieces[i]);
	return list;
}

/* return po2 value based on class */
int ParseClassDigit(char c){
	int d = CharToInt(c);
	return !d ? 0 : 1 << --d;
}

/* return 0 if not a numeric char */
int CharToInt(char c){
	int i = c-'0';
	return i *view_as<int>(0 <= i <= 9);
}

int CountCharInString(const char[] s, char c){
	int i = -1, count = 0;
	while(s[++i] != '\0')
		count += view_as<int>(s[i] == c);
	return count;
}
