# Configuration Changelist
These are important changes related to custom RTD configuration.
**You don't have to consider this list if you're NOT customizing perks in any way.**

* Perks are now identified by token, not by ID
	* Token is now the section name.
		* This is not the case in **default** config file, which shouldn't be touched.
	* ID is still present, cannot be changed.
	* ID is added automatically, by the order the perks appear in.

* `"settings"` is not longer a single value.
	* Each setting has its own name.
	* Setting are split into subfields.
		* ex. Fast Hands: instead of `"settings" "2.0, 2.0"`, it is now:
		```
		"settings"
		{
			"attack"	"2.0"
			"reload"	"2.0"
		}
		```
	* **Make sure to update each settings field in your custom config.**
	* This allows you to change individual settings per perk.
	* Defining a setting of incorrect name does not yeild an error.
		* Make sure you typed them in correctly.

* `"class"` field is parsed differently.
	* Doesn't count any other characters than digits.
		* `"1, 2, 5, 8"` is the same as `"12 5 a8"`, or `"1258"`.
		* `"1258"` means Scout, Soldier, Heavy and Medic.
	* If you want all class it **must** be `""`, `"0"`, or `"511"`.
		* Putting a 0 anywhere along with other digits doesn't cut it anymore.

* `"tags"` are now separated by comma, just like weapon classes.

* Added new field: `"call"`.
	* Used to specify which internal function to call during perk's execution.
	* For example, you can make Godmode call Increased Speed instead.
	* You can supply different settings to the same call.
	* You may edit the default config file to add a new perk using a defined call.
		* Editing default config is still **not advised**.
		* Support for adding new perks with config alone may be added in the future.

* Removed cvars: sm\_rtd2\_repeat & sm\_rtd2\_repeatgreat
* Added cvars: sm\_rtd2\_repeat\_player & sm\_rtd2\_repeat\_perk

* Made Timebomb and Fire Timebomb timed perks (were a bit hacked instant-type perks)
	* Ticks setting is specified as their time.
	* Time defaults to 10.
	* Cannot be forcefully removed when the pre-explosion sound is going off.

* (For devs) deprecated the following natives:
	* RTD2\_GetClientPerkId, use RTD2\_GetClientPerk
	* RTD2\_ForcePerk, use RTD2\_Force
	* RTD2\_RollPerk, use RTD2\_Roll
	* RTD2\_RemovePerk, use RTD2\_Remove
	* RTD2\_GetPerkOfString, use RTD2\_FindPerk or RTD2\_FindPerks
	* RTD2\_RegisterPerk, use RTD2\_MakePerk
	* RTD2\_SetPerkByToken, RTD2\_SetPerkById and RTD2\_DefaultCorePerk, use RTD2\_SetPerk\*

**If you have any questions, don't hesitate to ask on the AlliedModder's thread.**
