#if defined _perkparsing_included
	#endinput
#endif
#define _perkparsing_included

int ClassStringToFlags(const char[] sClasses){
	int i = -1, iFlags = 0;
	while(sClasses[++i] != '\0'){
		iFlags |= CharToInt(sClasses[i]);
	}
	return iFlags;
}

int CharToInt(char c){
	int i = c-'0';
	return i *view_as<int>(0 <= i <= 9);
}
