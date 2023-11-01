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
typedef PlayerHurt = function void(const int client, const int iAttacker);

enum struct PlayerCache
{
	int _ClientIndex;
	int Int[4];
	float Float[4];
	Entity _Ent[EntSlot_SIZE];
	EntCleanup _EntCleanup[EntSlot_SIZE];
	ClientFlags Flags;

	int _TimerCount;
	Handle _Timers[2];

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
		int iIndex = this._TimerCount++;
		DataPack hData = new DataPack();

		hData.WriteFunction(hFunc);
		hData.WriteCell(this._ClientIndex);
		hData.WriteCell(iIndex);

		this._Timers[iIndex] = CreateTimer(fInterval, Timer_PerkTimer, hData, TIMER_REPEAT | TIMER_DATA_HNDL_CLOSE);

#if defined DEBUG
		char sCaller[64];
		GetCallerName(sCaller, sizeof(sCaller));
		LogError("[%s] Created timer for %N<%d>: %x", sCaller, this._ClientIndex, this._ClientIndex, this._Timers[iIndex]);
#endif
	}

	void NullifyTimer(const iIndex)
	{
		this._Timers[iIndex] = null;
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
		LogError("Cleaning up timers for %N<%d>: %x, %x", this._ClientIndex, this._ClientIndex, this._Timers[0], this._Timers[1]);
#endif

		delete this._Timers[0];
		delete this._Timers[1];
		this._TimerCount = 0;
	}
}

PlayerCache Cache[MAXPLAYERS + 1];

public Action Timer_PerkTimer(Handle hTimer, DataPack hData)
{
	hData.Reset();
	Call_StartFunction(INVALID_HANDLE, hData.ReadFunction());

	int client = hData.ReadCell();
	Call_PushCell(client);

	int iResult;
	Call_Finish(iResult);

	switch (view_as<Action>(iResult))
	{
		case Plugin_Stop, Plugin_Handled:
			Cache[client].NullifyTimer(hData.ReadCell());
	}

	return view_as<Action>(iResult);
}
