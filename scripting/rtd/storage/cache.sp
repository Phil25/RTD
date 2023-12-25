enum struct ClientFlags
{
	int iVals[4]; // SM ints are 32 bit, 4 are needed to hold 100 players

	void Set(const int iIndex)
	{
		int iOverflows = iIndex / 32;
		this.iVals[iOverflows] |= 1 << (iIndex - 32 * iOverflows);
	}

	void Unset(const int iIndex)
	{
		int iOverflows = iIndex / 32;
		this.iVals[iOverflows] &= ~(1 << (iIndex - 32 * iOverflows));
	}

	bool Test(const int iIndex)
	{
		int iOverflows = iIndex / 32;
		return view_as<bool>(this.iVals[iOverflows] & (1 << (iIndex - 32 * iOverflows)));
	}

	void Reset()
	{
		this.iVals[0] = 0;
		this.iVals[1] = 0;
		this.iVals[2] = 0;
		this.iVals[3] = 0;
	}
}

methodmap Entity
{
	public Entity(const int iIndex)
	{
		return view_as<Entity>(EntIndexToEntRef(iIndex));
	}

	public bool IsValid()
	{
		return this.Index > MaxClients;
	}

	public void Kill()
	{
		if (this.IsValid())
			AcceptEntityInput(this.Index, "Kill");
	}

	property int Index
	{
		public get()
		{
			return EntRefToEntIndex(view_as<int>(this));
		}
	}

	property int Reference
	{
		public get()
		{
			return view_as<int>(this);
		}
	}
}

enum EntSlot
{
	EntSlot_1,
	EntSlot_2,
	EntSlot_3,
	EntSlot_SIZE,
}

enum EntCleanup
{
	EntCleanup_Auto,
	EntCleanup_None,
}

typedef PerkRepeater = function Action(const int client);
typedef PerkDelay = function void(const int client);
typedef PlayerHurt = function void(const int client, const int iAttacker);

enum struct PlayerCache
{
	int _ClientIndex;
	int Int[4];
	float Float[4];
	Entity _Ent[EntSlot_SIZE];
	EntCleanup _EntCleanup[EntSlot_SIZE];
	ClientFlags Flags;

	DataPack _TimerData[2];

	void Init(const int client)
	{
		this._ClientIndex = client;
	}

	Entity GetEnt(const EntSlot eSlot)
	{
		return this._Ent[eSlot];
	}

	void SetEnt(const EntSlot eSlot, const int iEntIndex, const EntCleanup eCleanup=EntCleanup_Auto)
	{
		this.GetEnt(eSlot).Kill();
		this._Ent[eSlot] = Entity(iEntIndex);
		this._EntCleanup[eSlot] = eCleanup;
	}

	void KillEnt(const EntSlot eSlot)
	{
		this.GetEnt(eSlot).Kill();
	}

	void LeakEnt(const EntSlot eSlot)
	{
		this._Ent[eSlot] = Entity(0);
	}

	void Repeat(const float fInterval, PerkRepeater hFunc)
	{
		int iDataIndex = this._PreparePerkTimerDataPack();
		this._TimerData[iDataIndex].WriteFunction(hFunc);

		this._CreatePerkTimer(fInterval, Timer_PerkTimer, iDataIndex, TIMER_REPEAT);
	}

	void Delay(const float fDelay, PerkDelay hFunc)
	{
		int iDataIndex = this._PreparePerkTimerDataPack();
		this._TimerData[iDataIndex].WriteFunction(hFunc);

		this._CreatePerkTimer(fDelay, Timer_PerkDelay, iDataIndex);
	}

	int _PreparePerkTimerDataPack()
	{
		int i = this._FindTimerDataIndex();

		this._TimerData[i] = new DataPack();
		this._TimerData[i].WriteCell(i);
		this._TimerData[i].WriteCell(this._ClientIndex);

		return i;
	}

	void _CreatePerkTimer(const float fTime, Timer hFunc, const int iDataIndex, const int iFlags=0)
	{
		CreateTimer(fTime, hFunc, this._TimerData[iDataIndex], iFlags | TIMER_DATA_HNDL_CLOSE);

#if defined DEBUG
		char sCaller[64];
		GetCallerName(sCaller, sizeof(sCaller), 2);
		LogError("[%s] Created timer for %N<%d>: %x", sCaller, this._ClientIndex, this._ClientIndex, this._TimerData[iDataIndex]);
#endif
	}

	void _NullifyTimerData(const int iIndex)
	{
		// If already nullified the timer was either not used in the first place, or somehow was
		// nullified before its corresponding perk ended but after having been marked for stopping.
		if (this._TimerData[iIndex] == null)
			return;

		this._TimerData[iIndex].Reset();
		this._TimerData[iIndex].WriteCell(-1);

		// Purposefully leak the timer and its DataPack handles. Deleting a timer manually here
		// sometimes errors out as if it were destroyed inside the callback, which is illegal. This
		// way, the first cell of the DataPack will instruct the timer to kill itself lazily.
		this._TimerData[iIndex] = null;
	}

	int _FindTimerDataIndex()
	{
		for (int i = 0; i < sizeof(this._TimerData); ++i)
			if (this._TimerData[i] == null)
				return i;

		// This should never happen
		LogError("Internal error: could not find available timer index");
		return -1;
	}

	void Cleanup()
	{
		switch (this._EntCleanup[EntSlot_1])
		{
			case EntCleanup_Auto: this.KillEnt(EntSlot_1);
			case EntCleanup_None: this.LeakEnt(EntSlot_1);
		}

		switch (this._EntCleanup[EntSlot_2])
		{
			case EntCleanup_Auto: this.KillEnt(EntSlot_2);
			case EntCleanup_None: this.LeakEnt(EntSlot_2);
		}

		switch (this._EntCleanup[EntSlot_3])
		{
			case EntCleanup_Auto: this.KillEnt(EntSlot_3);
			case EntCleanup_None: this.LeakEnt(EntSlot_3);
		}

#if defined DEBUG
		LogError("Cleaning up timers for %N<%d>: %x, %x", this._ClientIndex, this._ClientIndex, this._TimerData[0], this._TimerData[1]);
#endif

		this._NullifyTimerData(0);
		this._NullifyTimerData(1);
	}
}

enum CritBoost
{
	CritBoost_Mini = 1,
	CritBoost_Full = 2,
}

enum struct SharedCache
{
	int MaxHealth;
	TFClassType ClassForPerk;
	int _CritBoosted;
	float TempPowerPlayTimePoint;

	float MaxHealthFloat()
	{
		return float(this.MaxHealth);
	}

	bool IsCritBoosted(const int client)
	{
		return this._CritBoosted > 0;
	}

	void AddCritBoost(const int client, const CritBoost eCritBoost)
	{
		this._CritBoosted += view_as<int>(eCritBoost);

		if (this._CritBoosted == 1)
		{
			TF2_AddCondition(client, TFCond_Buffed);
			return;
		}

		if (eCritBoost == CritBoost_Mini)
			TF2_RemoveCondition(client, TFCond_Buffed);

		TF2_AddCondition(client, TFCond_CritOnFirstBlood);
	}

	void RemoveCritBoost(const int client, const CritBoost eCritBoost)
	{
		this._CritBoosted -= view_as<int>(eCritBoost);

		if (this._CritBoosted < 0)
		{
			this._CritBoosted = 0;
			return;
		}

		switch (this._CritBoosted)
		{
			case 0:
			{
				TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
				TF2_RemoveCondition(client, TFCond_Buffed);
			}

			case 1:
			{
				TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
				TF2_AddCondition(client, TFCond_Buffed);
			}
		}
	}
}

PlayerCache Cache[MAXPLAYERS + 1];
SharedCache Shared[MAXPLAYERS + 1];

// should not be necessary but acts as extra failsafe in case an error happens elsewhere
bool ValidatePerkTimerClient(const int client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
		return true;

	LogError("Internal error: client \"%L\" is not in game or not alive", client);
	return false;
}

public Action Timer_PerkTimer(Handle hTimer, DataPack hData)
{
	hData.Reset();
	int iIndex = hData.ReadCell();

	// timer marked for deletion
	if (iIndex == -1)
		return Plugin_Stop;

	int client = hData.ReadCell();
	if (!ValidatePerkTimerClient(client))
	{
		Cache[client]._NullifyTimerData(iIndex);
		return Plugin_Stop;
	}

	Call_StartFunction(INVALID_HANDLE, hData.ReadFunction());
	Call_PushCell(client);

	int iResult;
	Call_Finish(iResult);

	switch (view_as<Action>(iResult))
	{
		case Plugin_Stop, Plugin_Handled:
			Cache[client]._NullifyTimerData(iIndex);
	}

	return view_as<Action>(iResult);
}

public Action Timer_PerkDelay(Handle hTimer, DataPack hData)
{
	hData.Reset();
	int iIndex = hData.ReadCell();

	// timer marked for deletion
	if (iIndex == -1)
		return Plugin_Stop;

	int client = hData.ReadCell();
	if (!ValidatePerkTimerClient(client))
	{
		Cache[client]._NullifyTimerData(iIndex);
		return Plugin_Stop;
	}

	Call_StartFunction(INVALID_HANDLE, hData.ReadFunction());
	Call_PushCell(client);
	Call_Finish();

	Cache[client]._NullifyTimerData(iIndex);
	return Plugin_Stop;
}
