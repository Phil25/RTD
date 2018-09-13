# Configuration Changelist
These are important changes related to custom RTD configuration.
You may not consider this list if you're not customizing perks in any way.

* Perks are now identified by token, not by ID
	* Token is now the section name.
		* This is not the case in **default** config file, which shouldn't be touched.
	* ID is still present, cannot be changed.
	* ID is added automatically, by the order the perks appear in.

* `"class"` field is parsed differently
	* Doesn't count any other characters than digits.
		* `"1, 2, 5, 8"` is the same as `"12 5 a8"`.
	* If you want all class it **must** be `""`, `"0"` or `"511"`.
		* Putting a 0 anywhere along with other digits doesn't cut it anymore.

* You can set custom "good" value to be anything other than 0, 1.
	* This is not advised and will cause problems.
	* I left it because there is no reason whatsoever anyone should do this.

* Removed cvars: sm\_rtd2\_repeat & sm\_rtd2\_repeatgreat
* Added cvars: sm\_rtd2\_repeat\_player & sm\_rtd2\_repeat\_perk

* (For devs) deprecated the following natives:
	* RTD2\_GetClientPerkId, use RTD2\_GetClientPerk
	* RTD2\_ForcePerk, use RTD2\_Force
	* RTD2\_RollPerk, use RTD2\_Roll
	* RTD2\_RemovePerk, use RTD2\_Remove
	* RTD2\_GetPerkOfString, use RTD2\_FindPerk or RTD2\_FindPerks
	* RTD2\_RegisterPerk, use RTD2\_MakePerk
	* RTD2\_SetPerkByToken, RTD2\_SetPerkById and RTD2\_DefaultCorePerk, use RTD2\_SetPerk*

# Required testing

* Perk calls
* Perk group rolls.
* Perk queues.
* Perk menu + translations.
* Registering another perk with same token.
* Entirety of RTDPerk methodmap.
* Perk removing
