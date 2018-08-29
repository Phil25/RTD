#include "rtd/perk_class.sp"


PerkContainer g_hPerks = null;

public void OnPluginStart(){
	ParseEffects();
}

bool ParseEffects(){
	if(g_hPerks == null)
		g_hPerks = new PerkContainer();
	g_hPerks.Clear();

	char sPath[255];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/rtd2_perks.default.cfg");
	return FileExists(sPath) && g_hPerks.ParseFile(sPath);
}
