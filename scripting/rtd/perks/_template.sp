
/*
This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd2.sp instead of this one.

*** HOW TO ADD A PERK ***
A quick note: This tutorial may not be kept up to date; for an updated one, go to the plugin's thread.
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

1. Set up:
	a) Have <perkname>.sp in scripting/rtd.
	b) Add it to the includes in scripting/rtd/#perks.sp.
	c) Add a new section with a correct ID (highest one +1) to the config/rtd2_perks.cfg and set its settings.

2. Edit scripting/rtd/#manager.sp
	a) In a function named ManagePerk() add a new case to the switch() with your perk's ID.
	b) In the added case specify a function which is going to execute from <perkname>.sp with parameters:
		1) @client			- the client the perk should be applied to/removed from
		2) @fSpecialPref	- the optional "special" value in config/rtd2_perks.cfg
		2) @enable			- to specify whether the perk should be applied/removed
	c) OPTIONAL: You can specify a function in your perk which should run at OnMapStart() in the Forward_OnMapStart() function.
		You will need it if you'd want to, for example, precache a sound or loop through existing clients.
	d) OPTIONAL: You can specify a function in your perk which should run at OnPlayerRunCmd() in the Forward_OnPlayerRunCmd() function.
		You can use it if you'd need something to run each frame or on a certain button press.
		NOTE: The forwarded client is guaranteed to be valid BUT NOT GUARANTEED IF THEY ARE ALIVE.

3. Script your perk:
	a) Create a public function in <perkname>.sp with parameters @client, @iPref, @bool:apply as an example below
	   - This is the only function used to transfer info between the core and the include
	   - You don't need to include any includes that are in the rtd2.sp
	b) NOTE: If you need to transfer the iPref to a different function, set it globally but remember to use an unique name
	c) Name it AS SAME AS you named the function in the added case in the switch() in #manager.sp
	d) From there, script the functionality like there's no tomorrow
	e) You are free to use IsValidClient(). It returns false when:
		- An incorrect client index is specified
		- Client is not in game
		- Client is fake (bot)
		- Client is Coaching

4. Compile rtd2.sp and you're good to go!

*/

/*

	THIS IS A TEMPLATE ON ADDING CUSTOM PERKS, FOR A FULL GUIDE INFO, GO TO:
	https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

*/

//Let's have some global variables so our perk could behave in a customized way
char	g_sValue1[32];
int		g_iValue2;
bool	g_bValue3;
float	g_fValue4;

//PerkName_Perk is the only function being called by the base script. You can name it whatever you wish, as long as you'll be able to keep the consistency in other places.
void PerkName_Perk(int client, const char[] sPref, bool bApply){

	if(bApply)
		PerkName_ApplyPerk(client, sPref);
	
	else
		PerkName_RemovePerk(client);

}


//Let's split it into two functions for simplicity's sake.
void PerkName_ApplyPerk(int client, const char[] sPref){

	//We have a string of settings that is getting passed from the base plugin, let's process it.
	PerkName_ProcessSettings(sPref); //NOTE: YOU SHOULDN'T USE THIS IF THERE'S JUST A SINGLE SETTING

	//Enable perk on the client here

}

void PerkName_RemovePerk(int client){

	//Disable perk on the client here

}

//The parameter looks simiilar to this: "X,Y,Z,W" (no spaces, more than a one value, should be separated by a special symbol)
void PerkName_ProcessSettings(const char[] sSettings){ //NOTE: YOU SHOULDN'T USE THIS IF THERE'S JUST A SINGLE SETTING
	
	char sPieces = new char[AMOUNT_OF_SETTINGS][LENGTH_OF_A_SETTING];//Let's set up a buffer to split the settings string into
	ExplodeString(sSettings, ",", sPieces, AMOUNT_OF_SETTINGS, LENGTH_OF_A_SETTING);//Split the string every 'comma' character

	//Do whatever we want with this information, such as assigning it to global variables, for one
	strcopy(sValue1, sizeof(sValue1), sPieces[0]);
	g_iValue2 = StringToInt(sPieces[1]);
	g_bValue3 = StringToInt(sPieces[2]) > 0 ? true : false;
	g_fValue4 = StringToFloat(sPieces[3]);

}