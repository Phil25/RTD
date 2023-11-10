enum struct UserMessageCache
{
	UserMsg Fade;
	UserMsg ShakeId;

	void Init()
	{
		this.Fade = GetUserMessageId("Fade");
		this.ShakeId = GetUserMessageId("Shake");
	}

	void Shake(const int client, const float fAmplitude, const float fFrequency, const float fDuration, const int iCommand=0)
	{
		int iClients[2];
		iClients[0] = client;

		Handle hMsg = StartMessageEx(this.ShakeId, iClients, 1);
		if (hMsg != INVALID_HANDLE)
		{
			BfWriteByte(hMsg, iCommand);
			BfWriteFloat(hMsg, fAmplitude);
			BfWriteFloat(hMsg, fFrequency);
			BfWriteFloat(hMsg, fDuration);
			EndMessage();
		}
	}

	void StopShake(const int client)
	{
		this.Shake(client, 0.0, 0.0, 0.0, 1);
	}
}

enum struct PropOffsetCache
{
	int WeaponBaseClip;
	int PlayerAmmo;
	int CombatWeaponAmmoType;
	int EnergyBallDamage;

	void Init()
	{
		this.WeaponBaseClip = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
		this.PlayerAmmo = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		this.CombatWeaponAmmoType = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");
		this.EnergyBallDamage = FindSendPropInfo("CTFProjectile_EnergyBall", "m_iDeflected") + 4;
	}
}

enum struct AttachmentPointCache
{
	int Root; // always 0
	int Head;
	int Hat;
	int EyeL;
	int EyeR;
	int Flag;
	int Back;
	int HandL;
	int HandR;
	int FootL;
	int FootR;

	void Init(const TFClassType eClass)
	{
		switch (eClass)
		{
			case TFClass_Scout:
			{
				this.FootL = 4;
				this.FootR = 5;
				this.Back = 7;
				this.Hat = 10;
				this.Head = 12;
				this.EyeL = 13;
				this.EyeR = 14;
				this.HandL = 16;
				this.HandR = 21;
				this.Flag = 22;
			}

			case TFClass_Soldier:
			{
				this.Back = 4;
				this.FootL = 5;
				this.FootR = 6;
				this.Hat = 7;
				this.Head = 8;
				this.EyeL = 9;
				this.EyeR = 10;
				this.HandL = 12;
				this.HandR = 16;
				this.Flag = 17;
			}

			case TFClass_Pyro:
			{
				this.Head = 1;
				this.EyeL = 2;
				this.EyeR = 3;
				this.HandL = 5;
				this.HandR = 11;
				this.Flag = 12;
				this.Back = 21;
				this.FootL = 22;
				this.FootR = 23;
				this.Hat = 24;
			}

			case TFClass_DemoMan:
			{
				this.Back = 3;
				this.FootL = 4;
				this.FootR = 5;
				this.Hat = 6;
				this.Head = 7;
				this.EyeL = 8;
				this.EyeR = 9;
				this.HandL = 12;
				this.HandR = 14;
				this.Flag = 16;
			}

			case TFClass_Heavy:
			{
				this.Back = 4;
				this.FootL = 5;
				this.FootR = 6;
				this.Hat = 7;
				this.Head = 8;
				this.EyeL = 9;
				this.EyeR = 10;
				this.HandL = 11;
				this.HandR = 12;
				this.Flag = 13;
			}

			case TFClass_Engineer:
			{
				this.Back = 1;
				this.FootL = 2;
				this.FootR = 3;
				this.Hat = 4;
				this.Head = 5;
				this.EyeR = 6; // yes, starts with right one
				this.EyeL = 7;
				this.HandL = 8;
				this.HandR = 10;
				this.Flag = 11;
			}

			case TFClass_Medic:
			{
				this.Back = 4;
				this.FootL = 5;
				this.FootR = 6;
				this.Hat = 7;
				this.Head = 8;
				this.EyeL = 9;
				this.EyeR = 10;
				this.HandL = 11;
				this.HandR = 12;
				this.Flag = 13;
			}

			case TFClass_Sniper:
			{
				this.Back = 4;
				this.FootL = 5;
				this.FootR = 6;
				this.Hat = 7;
				this.Head = 8;
				this.EyeL = 9;
				this.EyeR = 10;
				this.HandL = 11;
				this.HandR = 12;
				this.Flag = 13;
			}

			case TFClass_Spy:
			{
				this.Back = 5;
				this.FootL = 6;
				this.FootR = 7;
				this.Hat = 8;
				this.Head = 10;
				this.EyeL = 11;
				this.EyeR = 12;
				this.HandL = 14;
				this.HandR = 19;
				this.Flag = 20;
			}
		}
	}
}

enum struct AttributesCache
{
	int Damage;
	int VoicePitch;
	int FireRate;
	int ReloadSpeed;
	int MaxHealth;
	int MeleeRange;
	int JumpHeight;
	int PreventJump;
	int NoFallDamage;
	int ForceDamageTaken;
	int OverhealBonus;
	int NoHeadshotDeath;

	void Init()
	{
		this.Damage = 476;
		this.VoicePitch = 2048;
		this.FireRate = 394;
		this.ReloadSpeed = 241;
		this.MaxHealth = 26;
		this.MeleeRange = 264;
		this.JumpHeight = 326;
		this.PreventJump = 819;
		this.NoFallDamage = 275;
		this.ForceDamageTaken = 535;
		this.OverhealBonus = 11;
		this.NoHeadshotDeath = 176;
	}
}

// only for static typing purposes
enum TEParticleId
{
	INVALID_PARTICLE_ID = -1
}

enum TEParticleLingeringId
{
	INVALID_LINGERING_PARTICLE_ID = -1
}

enum struct TEParticlesCache
{
	TEParticleId ExplosionLarge;
	TEParticleId ExplosionLargeShockwave;
	TEParticleId GreenFog;
	TEParticleId GreenBitsTwirl;
	TEParticleId GreenBitsImpact;
	TEParticleId LingeringFogSmall;
	TEParticleId SmokePuff;
	TEParticleId WaterSteam;
	TEParticleId GasPasserImpactBlue;
	TEParticleId GasPasserImpactRed;
	TEParticleId BulletImpactHeavy;
	TEParticleId BulletImpactHeavier;
	TEParticleId IceImpact;
	TEParticleId PickupTrailBlue;
	TEParticleId PickupTrailRed;
	TEParticleId LootExplosion;
	TEParticleId ExplosionWooden;
	TEParticleId ExplosionEmbersOnly;
	TEParticleId ShockwaveFlat;
	TEParticleId ShockwaveAir;
	TEParticleId ShockwaveAirLight;
	TEParticleId SnowBurst;
	TEParticleId ElectrocutedRed;
	TEParticleId ElectrocutedBlue;
	TEParticleId SparkVortexRed;
	TEParticleId SparkVortexBlue;
	TEParticleId PlayerStationarySilhouetteRed;
	TEParticleId PlayerStationarySilhouetteBlue;
	TEParticleId SmallPingWithEmbersRed;
	TEParticleId SmallPingWithEmbersBlue;
	TEParticleId ElectricBurst;

	TEParticleId AsId(const char[] sEffectName)
	{
		return view_as<TEParticleId>(GetEffectIndex(sEffectName));
	}

	void Init()
	{
		this.ExplosionLarge = this.AsId("rd_robot_explosion");
		this.ExplosionLargeShockwave = this.AsId("rd_robot_explosion_shockwave");
		this.GreenFog = this.AsId("merasmus_spawn_fog");
		this.GreenBitsTwirl = this.AsId("merasmus_tp_bits");
		this.GreenBitsImpact = this.AsId("merasmus_shoot_bits");
		this.LingeringFogSmall = this.AsId("god_rays_fog");
		this.SmokePuff = this.AsId("taunt_yeti_flash");
		this.WaterSteam = this.AsId("water_burning_steam");
		this.GasPasserImpactBlue = this.AsId("gas_can_impact_blue");
		this.GasPasserImpactRed = this.AsId("gas_can_impact_red");
		this.BulletImpactHeavy = this.AsId("versus_door_sparks_floaty");
		this.BulletImpactHeavier = this.AsId("versus_door_sparksB");
		this.IceImpact = this.AsId("xms_icicle_impact");
		this.PickupTrailBlue = this.AsId("duck_collect_trail_special_blue");
		this.PickupTrailRed = this.AsId("duck_collect_trail_special_red");
		this.LootExplosion = this.AsId("mvm_loot_explosion");
		this.ExplosionWooden = this.AsId("mvm_pow_gold_seq_firework_mid");
		this.ExplosionEmbersOnly = this.AsId("mvm_tank_destroy_embers");
		this.ShockwaveFlat = this.AsId("Explosion_ShockWave_01");
		this.ShockwaveAir = this.AsId("airburst_shockwave");
		this.ShockwaveAirLight = this.AsId("airburst_shockwave_d");
		this.SnowBurst = this.AsId("xms_snowburst");
		this.ElectrocutedRed = this.AsId("electrocuted_red");
		this.ElectrocutedBlue = this.AsId("electrocuted_blue");
		this.SparkVortexRed = this.AsId("teleportedin_red");
		this.SparkVortexBlue = this.AsId("teleportedin_blue");
		this.PlayerStationarySilhouetteRed = this.AsId("player_sparkles_red");
		this.PlayerStationarySilhouetteBlue = this.AsId("player_sparkles_blue");
		this.SmallPingWithEmbersBlue = this.AsId("powercore_embers_blue");
		this.SmallPingWithEmbersRed = this.AsId("powercore_embers_red");
		this.ElectricBurst = this.AsId("utaunt_lightning_impact_electric");
	}
}

enum struct TEParticlesLingeringCache
{
	TEParticleLingeringId SnowFlakes;
	TEParticleLingeringId IceBodyGlow;
	TEParticleLingeringId Frostbite;
	TEParticleLingeringId ElectricMist;
	TEParticleLingeringId LightningSwirl;
	TEParticleLingeringId BurningBody;
	TEParticleLingeringId GlowRed;
	TEParticleLingeringId GlowBlue;
	TEParticleLingeringId VortexRed;
	TEParticleLingeringId VortexBlue;
	TEParticleLingeringId ElectricDischargePurple;
	TEParticleLingeringId ElectricDischargeYellow;
	TEParticleLingeringId RisingSparklesYellow;

	TEParticleLingeringId AsId(const char[] sEffectName)
	{
		return view_as<TEParticleLingeringId>(GetEffectIndex(sEffectName));
	}

	void Init()
	{
		this.SnowFlakes = this.AsId("utaunt_ice_snowflakes");
		this.IceBodyGlow = this.AsId("utaunt_ice_bodyglow");
		this.Frostbite = this.AsId("unusual_eotl_frostbite");
		this.ElectricMist = this.AsId("utaunt_electric_mist");
		this.LightningSwirl = this.AsId("utaunt_elebound_yellow_parent");
		this.BurningBody = this.AsId("burningplayer_red");
		this.GlowRed = this.AsId("utaunt_tarotcard_red_glow");
		this.GlowBlue = this.AsId("utaunt_tarotcard_blue_glow");
		this.VortexRed = this.AsId("utaunt_tarotcard_red_wind");
		this.VortexBlue = this.AsId("utaunt_tarotcard_blue_wind");
		this.ElectricDischargePurple = this.AsId("utaunt_electricity_purple_discharge");
		this.ElectricDischargeYellow = this.AsId("utaunt_electricity_discharge");
		this.RisingSparklesYellow = this.AsId("utaunt_arcane_yellow_sparkle");
	}
}

enum struct MaterialsCache
{
	int Laser;
	int Halo;

	void Init()
	{
		this.Laser = PrecacheModel("materials/sprites/laser.vmt");
		this.Halo = PrecacheModel("materials/sprites/halo01.vmt");
	}
}

UserMessageCache UserMessages;
PropOffsetCache PropOffsets;
AttachmentPointCache Attachments[10]; // per class
AttributesCache Attribs;
TEParticlesCache TEParticles;
TEParticlesLingeringCache TEParticlesLingering;
MaterialsCache Materials;

void Storage_Precache()
{
	UserMessages.Init();
	PropOffsets.Init();
	Attachments[TFClass_Scout].Init(TFClass_Scout);
	Attachments[TFClass_Soldier].Init(TFClass_Soldier);
	Attachments[TFClass_Pyro].Init(TFClass_Pyro);
	Attachments[TFClass_DemoMan].Init(TFClass_DemoMan);
	Attachments[TFClass_Heavy].Init(TFClass_Heavy);
	Attachments[TFClass_Engineer].Init(TFClass_Engineer);
	Attachments[TFClass_Medic].Init(TFClass_Medic);
	Attachments[TFClass_Sniper].Init(TFClass_Sniper);
	Attachments[TFClass_Spy].Init(TFClass_Spy);
	Attribs.Init();
	TEParticles.Init();
	TEParticlesLingering.Init();
	Materials.Init();
}
