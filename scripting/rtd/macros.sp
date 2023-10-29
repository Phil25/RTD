#if defined _RTD2_MACROS
  #endinput
#endif
#define _RTD2_MACROS

#define KILL_ENT_IN(%1,%2) \
	SetVariantString("OnUser1 !self:Kill::" ... #%2 ... ":1"); \
	AcceptEntityInput(%1, "AddOutput"); \
	AcceptEntityInput(%1, "FireUser1") // no semicolor, require it's added on caller

#define DEFINE_CALL_APPLY_REMOVE(%1) \
public void %1_Call(const int client, const Perk perk, const bool apply) \
{ \
	if(apply) \
	{ \
		%1_ApplyPerk(client, perk); \
	} \
	else \
	{ \
		%1_RemovePerk(client); \
	} \
}

#define DEFINE_CALL_APPLY(%1) \
public void %1_Call(const int client, const Perk perk, const bool apply) \
{ \
	if(apply) \
	{ \
		%1_ApplyPerk(client, perk); \
	} \
}

#define DEFINE_CALL_EMPTY(%1) \
public void %1_Call(const int client, const Perk perk, const bool apply) \
{ \
}
