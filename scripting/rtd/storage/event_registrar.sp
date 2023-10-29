#if defined _RTD2_STORAGE_EVENT_REGISTRAR
	#endinput
#endif
#define _RTD2_STORAGE_EVENT_REGISTRAR

#include <sdkhooks>

typedef EREntitySpawned = function void(const int client, const int iEntity);
typedef EREntityClassnameFilter = function bool(const char[] sClassname);
typedef EREntityOwnerRetriever = function int(const int iEntity);
typedef ERConditionChange = function void(const int client, const TFCond eCondition);
typedef ERPlayerAttacked = function void(const int client, const int iVictim, const int iDamage, const int iRemainingHealth);
typedef ERPlayer = function void(const int client);
typedef ERAttackCritCheck = function bool(const int client, const int iWeapon);
typedef ERPlayerRunCmd = function bool(const int client, int& iButtons, float fVel[3], float fAng[3]);
typedef ERUberchargeDeployed = function void(const int client, const int iTarget);
typedef ERSound = function bool(const int client, const char[] sSound);

public int Retriever_OwnerEntity(const int iEnt)
{
	return GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity");
}

public int Retriever_AccountId(const int iEnt)
{
	return AccountIDToClient(GetEntProp(iEnt, Prop_Send, "m_iAccountID"));
}

public bool Classname_DroppedWeapon(const char[] sClassname)
{
	return StrEqual(sClassname, "tf_dropped_weapon");
}

enum SubscriptionType
{
	SubscriptionType_Roller,
	SubscriptionType_Any,
}

enum SubscriptionTypePerk
{
	SubscriptionTypeRoller_Current, // clients who are using the perk
	SubscriptionTypeRoller_Latest, // clients either are using or is the last perk they used
}

enum struct EventRegistrar
{
	ArrayList _OnEntitySpawned;
	ArrayList _OnConditionAdded;
	ArrayList _OnConditionRemoved;
	ArrayList _OnPlayerAttacked;
	ArrayList _OnPlayerDied;
	ArrayList _OnPlayerDisconnected;
	ArrayList _OnAttackCritCheck;
	ArrayList _OnPlayerRunCmd;
	ArrayList _OnUberchargeDeployed;
	ArrayList _OnResupply;
	ArrayList _OnVoice;
	ArrayList _OnSound;

	ArrayList _OnEntitySpawnedSubscribers;

	void Init()
	{
		this._OnEntitySpawned = new ArrayList();
		this._OnConditionAdded = new ArrayList();
		this._OnConditionRemoved = new ArrayList();
		this._OnPlayerAttacked = new ArrayList();
		this._OnPlayerDied = new ArrayList();
		this._OnPlayerDisconnected = new ArrayList();
		this._OnAttackCritCheck = new ArrayList();
		this._OnPlayerRunCmd = new ArrayList();
		this._OnUberchargeDeployed = new ArrayList();
		this._OnResupply = new ArrayList();
		this._OnVoice = new ArrayList();
		this._OnSound = new ArrayList();

		this._OnEntitySpawnedSubscribers = new ArrayList();
	}

	void Cleanup() // TODO: call this on reload
	{
		this._CleanupCallbackArray(this._OnEntitySpawned);
		this._CleanupCallbackArray(this._OnConditionAdded);
		this._CleanupCallbackArray(this._OnConditionRemoved);
		this._CleanupCallbackArray(this._OnPlayerAttacked);
		this._CleanupCallbackArray(this._OnPlayerDied);
		this._CleanupCallbackArray(this._OnPlayerDisconnected);
		this._CleanupCallbackArray(this._OnAttackCritCheck);
		this._CleanupCallbackArray(this._OnPlayerRunCmd);
		this._CleanupCallbackArray(this._OnUberchargeDeployed);
		this._CleanupCallbackArray(this._OnResupply);
		this._CleanupCallbackArray(this._OnVoice);
		this._CleanupCallbackArray(this._OnSound);

		delete this._OnEntitySpawnedSubscribers;
	}

	void _CleanupCallbackArray(ArrayList& list)
	{
		// TODO: implement
	}

	void OnEntitySpawned(const Perk perk, EREntitySpawned hSpawned, EREntityClassnameFilter hFilter, EREntityOwnerRetriever hOwner)
	{
		DataPack hData = new DataPack();
		hData.WriteFunction(hFilter);
		hData.WriteFunction(hOwner);
		hData.WriteCell(perk);
		hData.WriteFunction(hSpawned);

		this._OnEntitySpawnedSubscribers.Push(perk);
		this._OnEntitySpawned.Push(hData);
	}

	bool SubscribesToEntitySpawned(const Perk perk)
	{
		for (int i = 0; i < this._OnEntitySpawnedSubscribers.Length; ++i)
			if (this._OnEntitySpawnedSubscribers.Get(i) == perk)
				return true;

		return false;
	}

	bool ClassnameHasSubscribers(const char[] sClassname)
	{
		for (int i = 0; i < this._OnEntitySpawned.Length; ++i)
		{
			DataPack hData = this._OnEntitySpawned.Get(i);
			hData.Reset();

			Call_StartFunction(INVALID_HANDLE, hData.ReadFunction());
			Call_PushString(sClassname);

			bool bFilter;
			Call_Finish(bFilter);

			if (bFilter)
				return true;
		}

		return false;
	}

	void EntitySpawned(const int iEntity)
	{
		char sClassname[64];
		GetEntityClassname(iEntity, sClassname, sizeof(sClassname));

		for (int i = 0; i < this._OnEntitySpawned.Length; ++i)
		{
			DataPack hData = this._OnEntitySpawned.Get(i);
			hData.Reset();

			Call_StartFunction(INVALID_HANDLE, hData.ReadFunction());
			Call_PushString(sClassname);

			bool bFilter;
			Call_Finish(bFilter);

			if (!bFilter)
				continue;

			Call_StartFunction(INVALID_HANDLE, hData.ReadFunction());
			Call_PushCell(iEntity);

			int client;
			Call_Finish(client);

			if (!(1 <= client <= MaxClients && IsClientInGame(client)))
				continue;

			// EntitySpawned registered only for clients in a perk, but this is triggered after the
			// perk ends because of the 0.1 delay. The recent check ensures we get all the entities.
			if (!IsRecentPerk(client, hData.ReadCell()))
				continue;

			Call_StartFunction(INVALID_HANDLE, hData.ReadFunction());
			Call_PushCell(client);
			Call_PushCell(iEntity);
			Call_Finish();
		}
	}

	void OnConditionAdded(const Perk perk, ERConditionChange hCallback, const SubscriptionType eSubType=SubscriptionType_Roller)
	{
		DataPack hData = new DataPack();
		hData.WriteFunction(hCallback);
		hData.WriteCell(eSubType);
		hData.WriteCell(perk);

		this._OnConditionAdded.Push(hData);
	}

	void ConditionAdded(const int client, const TFCond eCondition)
	{
		Perk clientPerk = g_hRollers.GetPerk(client);
		
		for (int i = 0; i < this._OnConditionAdded.Length; ++i)
		{
			DataPack hData = this._OnConditionAdded.Get(i);
			hData.Reset();

			Call_StartFunction(INVALID_HANDLE, hData.ReadFunction());

			if (view_as<SubscriptionType>(hData.ReadCell()) == SubscriptionType_Roller)
			{
				if (clientPerk != hData.ReadCell())
				{
					Call_Cancel();
					continue;
				}
			}

			Call_PushCell(client);
			Call_PushCell(eCondition);
			Call_Finish();
		}
	}

	void OnConditionRemoved(const Perk perk, ERConditionChange hCallback, const SubscriptionType eSubType=SubscriptionType_Roller)
	{
		DataPack hData = new DataPack();
		hData.WriteFunction(hCallback);
		hData.WriteCell(eSubType);
		hData.WriteCell(perk);

		this._OnConditionRemoved.Push(hData);
	}

	void ConditionRemoved(const int client, const TFCond eCondition)
	{
		Perk clientPerk = g_hRollers.GetPerk(client);
		
		for (int i = 0; i < this._OnConditionRemoved.Length; ++i)
		{
			DataPack hData = this._OnConditionRemoved.Get(i);
			hData.Reset();

			Call_StartFunction(INVALID_HANDLE, hData.ReadFunction());

			if (view_as<SubscriptionType>(hData.ReadCell()) == SubscriptionType_Roller)
			{
				if (clientPerk != hData.ReadCell())
				{
					Call_Cancel();
					continue;
				}
			}

			Call_PushCell(client);
			Call_PushCell(eCondition);
			Call_Finish();
		}
	}

	void OnPlayerAttacked(const Perk perk, ERPlayerAttacked hCallback)
	{
		DataPack hData = new DataPack();
		hData.WriteCell(perk);
		hData.WriteFunction(hCallback);

		this._OnPlayerAttacked.Push(hData);
	}

	void PlayerAttacked(const int client, const int iVictim, const int iDamage, const int iRemainingHealth)
	{
		Perk perk = g_hRollers.GetPerk(client);
		if (perk == null)
			return;
		
		for (int i = 0; i < this._OnPlayerAttacked.Length; ++i)
		{
			DataPack hData = this._OnPlayerAttacked.Get(i);
			hData.Reset();

			if (perk != hData.ReadCell())
				continue;

			Call_StartFunction(INVALID_HANDLE, hData.ReadFunction());
			Call_PushCell(client);
			Call_PushCell(iVictim);
			Call_PushCell(iDamage);
			Call_PushCell(iRemainingHealth);
			Call_Finish();
		}
	}

	void OnPlayerDied(const Perk perk, ERPlayer hCallback, const SubscriptionType eSubType=SubscriptionType_Roller)
	{
		DataPack hData = new DataPack();
		hData.WriteFunction(hCallback);
		hData.WriteCell(eSubType);
		hData.WriteCell(perk);

		this._OnPlayerDied.Push(hData);
	}

	void PlayerDied(const int client)
	{
		Perk clientPerk = g_hRollers.GetPerk(client);
		
		for (int i = 0; i < this._OnPlayerDied.Length; ++i)
		{
			DataPack hData = this._OnPlayerDied.Get(i);
			hData.Reset();

			Call_StartFunction(INVALID_HANDLE, hData.ReadFunction());

			if (view_as<SubscriptionType>(hData.ReadCell()) == SubscriptionType_Roller)
			{
				if (clientPerk != hData.ReadCell())
				{
					Call_Cancel();
					continue;
				}
			}

			Call_PushCell(client);
			Call_Finish();
		}
	}

	void OnPlayerDisconnected(const Perk perk, ERPlayer hCallback, const SubscriptionType eSubType=SubscriptionType_Roller)
	{
		DataPack hData = new DataPack();
		hData.WriteFunction(hCallback);
		hData.WriteCell(eSubType);
		hData.WriteCell(perk);

		this._OnPlayerDisconnected.Push(hData);
	}

	void PlayerDisconnected(const int client)
	{
		Perk clientPerk = g_hRollers.GetPerk(client);
		
		for (int i = 0; i < this._OnPlayerDisconnected.Length; ++i)
		{
			DataPack hData = this._OnPlayerDisconnected.Get(i);
			hData.Reset();

			Call_StartFunction(INVALID_HANDLE, hData.ReadFunction());

			if (view_as<SubscriptionType>(hData.ReadCell()) == SubscriptionType_Roller)
			{
				if (clientPerk != hData.ReadCell())
				{
					Call_Cancel();
					continue;
				}
			}

			Call_PushCell(client);
			Call_Finish();
		}
	}

	void OnAttackCritCheck(const Perk perk, ERAttackCritCheck hCallback, const SubscriptionType eSubType=SubscriptionType_Roller)
	{
		DataPack hData = new DataPack();
		hData.WriteFunction(hCallback);
		hData.WriteCell(eSubType);
		hData.WriteCell(perk);

		this._OnAttackCritCheck.Push(hData);
	}

	bool AttackCritCheck(const int client, const int iWeapon)
	{
		Perk clientPerk = g_hRollers.GetPerk(client);

		bool bShouldCrit = false;

		for (int i = 0; i < this._OnAttackCritCheck.Length; ++i)
		{
			DataPack hData = this._OnAttackCritCheck.Get(i);
			hData.Reset();

			Call_StartFunction(INVALID_HANDLE, hData.ReadFunction());

			if (view_as<SubscriptionType>(hData.ReadCell()) == SubscriptionType_Roller)
			{
				if (clientPerk != hData.ReadCell())
				{
					Call_Cancel();
					continue;
				}
			}

			Call_PushCell(client);
			Call_PushCell(iWeapon);

			bool bResult;
			Call_Finish(bResult);

			bShouldCrit |= bResult;
		}

		return bShouldCrit;
	}

	void OnPlayerRunCmd(const Perk perk, ERPlayerRunCmd hCallback)
	{
		DataPack hData = new DataPack();
		hData.WriteCell(perk);
		hData.WriteFunction(hCallback);

		this._OnPlayerRunCmd.Push(hData);
	}

	bool PlayerRunCmd(const int client, int& iButtons, float fVel[3], float fAng[3])
	{
		Perk perk = g_hRollers.GetPerk(client);
		if (perk == null)
			return false;

		for (int i = 0; i < this._OnPlayerRunCmd.Length; ++i)
		{
			DataPack hData = this._OnPlayerRunCmd.Get(i);
			hData.Reset();

			if (perk != hData.ReadCell())
				continue;

			Call_StartFunction(INVALID_HANDLE, hData.ReadFunction());
			Call_PushCell(client);
			Call_PushCellRef(iButtons);
			Call_PushArrayEx(fVel, sizeof(fVel), SM_PARAM_COPYBACK);
			Call_PushArrayEx(fAng, sizeof(fVel), SM_PARAM_COPYBACK);

			bool bResult;
			Call_Finish(bResult);

			// We can return right away, `Events.OnPlayerRunCmd()` does not support subscribing to
			// non-roller players (it shouldn't, calls could get a bit too expensive), this is run
			// for a single player and every player will only ever have a single perk active.
			if (bResult)
				return true;
		}

		return false;
	}

	void OnUberchargeDeployed(const Perk perk, ERUberchargeDeployed hCallback)
	{
		DataPack hData = new DataPack();
		hData.WriteCell(perk);
		hData.WriteFunction(hCallback);

		this._OnUberchargeDeployed.Push(hData);
	}

	void UberchargeDeployed(const int client, const int iTarget)
	{
		Perk perk = g_hRollers.GetPerk(client);
		if (perk == null)
			return;

		for (int i = 0; i < this._OnUberchargeDeployed.Length; ++i)
		{
			DataPack hData = this._OnUberchargeDeployed.Get(i);
			hData.Reset();

			if (perk != hData.ReadCell())
				continue;

			Call_StartFunction(INVALID_HANDLE, hData.ReadFunction());
			Call_PushCell(client);
			Call_PushCell(iTarget);
			Call_Finish();
		}
	}

	void OnResupply(const Perk perk, ERPlayer hCallback, const SubscriptionType eSubType=SubscriptionType_Roller)
	{
		DataPack hData = new DataPack();
		hData.WriteFunction(hCallback);
		hData.WriteCell(eSubType);
		hData.WriteCell(perk);

		this._OnResupply.Push(hData);
	}

	void Resupply(const int client)
	{
		Perk clientPerk = g_hRollers.GetPerk(client);

		for (int i = 0; i < this._OnResupply.Length; ++i)
		{
			DataPack hData = this._OnResupply.Get(i);
			hData.Reset();

			Call_StartFunction(INVALID_HANDLE, hData.ReadFunction());

			if (view_as<SubscriptionType>(hData.ReadCell()) == SubscriptionType_Roller)
			{
				if (clientPerk != hData.ReadCell())
				{
					Call_Cancel();
					continue;
				}
			}

			Call_PushCell(client);
			Call_Finish();
		}
	}

	void OnVoice(const Perk perk, ERPlayer hCallback)
	{
		DataPack hData = new DataPack();
		hData.WriteCell(perk);
		hData.WriteFunction(hCallback);

		this._OnVoice.Push(hData);
	}

	void Voice(const int client)
	{
		Perk perk = g_hRollers.GetPerk(client);
		if (perk == null)
			return;

		for (int i = 0; i < this._OnVoice.Length; ++i)
		{
			DataPack hData = this._OnVoice.Get(i);
			hData.Reset();

			if (perk != hData.ReadCell())
				continue;

			Call_StartFunction(INVALID_HANDLE, hData.ReadFunction());
			Call_PushCell(client);
			Call_Finish();
		}
	}

	void OnSound(const Perk perk, ERSound hCallback)
	{
		DataPack hData = new DataPack();
		hData.WriteCell(perk);
		hData.WriteFunction(hCallback);

		this._OnSound.Push(hData);
	}

	bool Sound(const int client, const char[] sClassname)
	{
		Perk perk = g_hRollers.GetPerk(client);
		if (perk == null)
			return true;

		bool bAllow = true;

		for (int i = 0; i < this._OnSound.Length; ++i)
		{
			DataPack hData = this._OnSound.Get(i);
			hData.Reset();

			if (perk != hData.ReadCell())
				continue;

			Call_StartFunction(INVALID_HANDLE, hData.ReadFunction());
			Call_PushCell(client);
			Call_PushString(sClassname);

			bool bResult = true;
			Call_Finish(bResult);

			bAllow &= bResult;
		}

		return bAllow;
	}
}

EventRegistrar Events;
