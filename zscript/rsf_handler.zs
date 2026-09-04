// RS_Fog -- the engine.
//
// A body of mist with a real ceiling you can stand knee deep in and look down
// at. All of the drawing is the engine's -- FogSlabAt in main.fp, which is
// analytic rather than raymarched and is why this is affordable at 90Hz per eye
// at all. What this mod owns is WHEN, HOW MUCH, and WHAT DISTURBS IT.
//
// The engine had every one of these knobs and no way to reach them: no on/off,
// no menu, and nothing connecting the fog to anything that happens in the game.
// A shader that can be shouldered aside by a walking monster is worth nothing
// if no monster ever tells it.
//
// TWO HALVES.
//
// Push() sends the standing settings -- the slab, its surface, tendrils, noise,
// colour. It is clearscope and runs from UiTick as well as WorldTick, so the
// fog changes under the options menu while you are looking at it.
//
// The event hooks are play scope and send DISTURBANCES: one-off events with a
// position and a life, which the engine ages on its own. Those cannot come from
// UI and should not -- they are things that happened in the world.

class RSF_Handler : EventHandler
{
	// Disturbance modes, as documented on Level.FogDisturb.
	const D_DISC   = 0;   // fixed radius, thins the mist -- something wading
	const D_RIPPLE = 1;   // a ring travelling outward
	const D_IGNITE = 2;   // an expanding sphere that adds LIGHT, not density
	const D_GOUT   = 3;   // an expanding disc that ADDS mist -- a vent, a burst

	private int lastPreset;
	private int waderTimer;

	// UI's own copy. See UiTick.
	private ui int uiLastPreset;
	private ui bool uiPresetSeen;

	// ---- lifecycle ---------------------------------------------------------

	override void WorldLoaded(WorldEvent e)
	{
		lastPreset = RSF.GetI("rsf_preset", 1);
		RSF_Presets.Apply(lastPreset);
		Level.ClearFogDisturb();
		Push();
	}

	override void WorldUnloaded(WorldEvent e)
	{
		// The slab is level state, not mod state. Leaving it set means the next
		// map opens inside whatever the last one was wearing.
		if (Level) { Level.ClearFogSlab(); Level.ClearFogDisturb(); }
	}

	override void WorldTick()
	{
		SyncPreset();
		Push();
		PushWake();
		Waders();
	}

	// The playsim stops while the menu is up, so WorldTick alone would freeze
	// the picture exactly while you drag the slider meant to change it. Every
	// fog setter is clearscope for this reason.
	//
	// Disturbances are NOT sent from here. They are events in the world, they
	// carry a position and a life, and firing them off menu ticks would have
	// the mist rippling while the game is paused.
	override void UiTick()
	{
		SyncPreset();
		Push();
	}

	clearscope void SyncPreset()
	{
		int want = RSF.GetI("rsf_preset", 1);
		if (want == RSF.GetI("rsf_preset_applied", -1)) return;
		RSF_Presets.Apply(want);
		RSF.SetI("rsf_preset_applied", want);
	}

	// ---- the standing settings ---------------------------------------------

	clearscope void Push()
	{
		if (!Level) return;

		if (!RSF.GetB("rsf_enabled", true))
		{
			Level.ClearFogSlab();
			return;
		}

		// WHERE THE TOP SITS. Absolute is a fixed world height, which is right
		// for one flooded room and wrong for a level -- walk upstairs and you
		// are above the weather. Following the floor keeps a constant depth of
		// mist underfoot everywhere, which is what "ground mist" actually means.
		double follow = RSF.GetF("rsf_follow", 0.35);
		Level.SetFogFollow(follow, follow);

		// HOW MUCH EACH ROOM GETS. A sky ceiling is outdoors, which every Doom
		// map already marks, so a courtyard and a cellar can want opposite
		// amounts without anything being authored for it. Both 1 is one fog
		// everywhere, which is what it was.
		Level.SetFogZones(
			RSF.GetF("rsf_indoor", 1.0),
			RSF.GetF("rsf_outdoor", 1.0));

		Level.SetFogSlab(
			RSF.GetF("rsf_top", 64.0),
			RSF.GetF("rsf_density", 0.55),
			RSF.GetF("rsf_soft", 24.0),
			RSF.GetF("rsf_scatter", 1.0),
			RSF.RGB("rsf_col"));

		Level.SetFogBottom(
			RSF.GetF("rsf_bottom", -256.0),
			RSF.GetF("rsf_bottom_period", 0.0),
			RSF.GetF("rsf_bottom_roll", 0.0));

		// THE SURFACE MOVES. A flat top reads as a sheet the moment you can see
		// it clearly. Two waves at an angle interfere, and interference is what
		// stops it looking like machinery.
		Level.SetFogSurface(
			RSF.GetF("rsf_surf_amp", 10.0),
			RSF.GetF("rsf_surf_len", 256.0),
			RSF.GetF("rsf_surf_speed", 1.0),
			RSF.GetF("rsf_surf_cross", 0.6));

		Level.SetFogNoise(
			RSF.GetF("rsf_noise_scale", 0.012),
			RSF.GetF("rsf_noise_depth", 0.45),
			RSF.GetF("rsf_drift_x", 3.0),
			RSF.GetF("rsf_drift_y", 1.5));

		Level.SetFogTendrils(
			RSF.GetF("rsf_tend_spacing", 160.0),
			RSF.GetF("rsf_tend_radius", 22.0),
			RSF.GetF("rsf_tend_height", 96.0),
			RSF.GetF("rsf_tend_density", 0.0),
			RSF.GetF("rsf_tend_rise", 0.5),
			RSF.GetF("rsf_tend_spread", 0.4),
			RSF.GetF("rsf_tend_lean", 0.2),
			RSF.GetF("rsf_tend_taper", 0.7));

		Level.SetFogGradient(RSF.RGB("rsf_grad"), RSF.GetF("rsf_grad_mix", 0.0));
		Level.SetFogPickup(RSF.GetF("rsf_pickup", 0.5));
		Level.SetFogBow(
			RSF.GetF("rsf_bow", 0.0),
			RSF.GetF("rsf_bow_width", 48.0),
			RSF.GetF("rsf_bow_thin", 0.6));
		Level.SetFogWakeMotion(
			RSF.GetF("rsf_wake_vel_x", 0.0),
			RSF.GetF("rsf_wake_vel_y", 0.0),
			RSF.GetF("rsf_wake_stretch", 1.6));

		// The funnel. Same mist, different shape, and independent of the slab
		// -- a tornado in clear air is a thing you can ask for.
		if (RSF.GetB("rsf_tornado", false))
		{
			double cx = RSF.GetF("rsf_torn_x", 0.0);
			double cy = RSF.GetF("rsf_torn_y", 0.0);
			Level.SetTornado(cx, cy,
				RSF.GetF("rsf_torn_base", 0.0),
				RSF.GetF("rsf_torn_top", 512.0),
				RSF.GetF("rsf_torn_rbase", 64.0),
				RSF.GetF("rsf_torn_rtop", 256.0),
				RSF.GetF("rsf_torn_density", 0.8));
			Level.SetTornadoMotion(
				RSF.GetF("rsf_torn_swirl", 1.0),
				RSF.GetF("rsf_torn_spin", 1.0),
				RSF.GetF("rsf_torn_twist", 0.5),
				RSF.GetF("rsf_torn_lean", 0.15),
				RSF.GetF("rsf_torn_lean_period", 8.0));
			Level.SetTornadoLook(RSF.RGB("rsf_torn_col"),
				RSF.GetF("rsf_torn_scatter", 1.0));
		}
		else
		{
			Level.SetTornado(0, 0, 0, 0, 0, 0, 0);   // density 0 = off
		}
	}

	// ---- what happens in it ------------------------------------------------

	// The player's own wake: one lagging point that thins the mist where you
	// just walked. Play scope, because it reads where the player is.
	void PushWake()
	{
		if (!RSF.GetB("rsf_enabled", true) || !RSF.GetB("rsf_wake", true)) return;
		let pmo = players[consoleplayer].mo;
		if (!pmo) return;
		Level.SetFogWake(pmo.pos,
			RSF.GetF("rsf_wake_radius", 56.0),
			RSF.GetF("rsf_wake_strength", 0.8));
	}

	// Things wading through it. The shader can be shouldered aside by anything
	// that moves; until now nothing told it.
	//
	// THROTTLED HARD, and this is the whole reason it is not per-actor per-tic.
	// There are 32 disturbance slots and they recycle oldest-first, so a room
	// of thirty monsters each pushing one every tic means every slot is a tenth
	// of a second old and nothing has time to read as a wake. One monster per
	// tic, round-robin by distance, leaves each disturbance alive long enough
	// to be seen.
	void Waders()
	{
		if (!RSF.GetB("rsf_enabled", true) || !RSF.GetB("rsf_waders", true)) return;
		if (--waderTimer > 0) return;
		waderTimer = max(RSF.GetI("rsf_wader_every", 6), 1);

		let pmo = players[consoleplayer].mo;
		if (!pmo) return;

		double best = RSF.GetF("rsf_wader_range", 1024.0);
		Actor pick = null;

		let it = ThinkerIterator.Create("Actor");
		Actor a;
		while (a = Actor(it.Next()))
		{
			if (!a || !a.bIsMonster || a.health <= 0) continue;
			if (a.vel.xy.Length() < 1.0) continue;     // standing still parts no mist
			double d = (a.pos.xy - pmo.pos.xy).Length();
			if (d < best) { best = d; pick = a; }
		}

		if (pick)
			Level.FogDisturb(pick.pos.x, pick.pos.y, pick.pos.z,
				pick.radius * 2.2, 0.7, 0.0, 0.6, D_DISC);
	}

	// An explosion lights the mist rather than clearing it. IGNITE adds light
	// and no density, which is why it works in a room with the fog switched
	// off -- and it is the one disturbance mode that does.
	override void WorldThingDied(WorldEvent e)
	{
		if (!RSF.GetB("rsf_enabled", true)) return;
		if (!e || !e.Thing) return;
		if (!RSF.GetB("rsf_death_ripple", true)) return;

		Actor t = e.Thing;
		if (!t.bIsMonster) return;

		// A ring travelling outward from the body. Big things make big rings.
		double r = clamp(GetDefaultByType(t.GetClass()).Height * 3.0, 64.0, 512.0);
		Level.FogDisturb(t.pos.x, t.pos.y, t.floorz, r,
			RSF.GetF("rsf_death_strength", 0.8),
			RSF.GetF("rsf_death_speed", 220.0),
			RSF.GetF("rsf_death_life", 0.9), D_RIPPLE);
	}

	// Anything exploding lights the mist from inside.
	override void WorldThingDamaged(WorldEvent e)
	{
		if (!RSF.GetB("rsf_enabled", true) || !RSF.GetB("rsf_ignite", true)) return;
		if (!e || !e.Thing || !e.DamageIsRadius) return;
		if (e.Damage < RSF.GetI("rsf_ignite_min", 20)) return;

		Level.FogDisturb(e.DamagePosition.x, e.DamagePosition.y, e.DamagePosition.z,
			RSF.GetF("rsf_ignite_radius", 192.0),
			RSF.GetF("rsf_ignite_strength", 1.0),
			RSF.GetF("rsf_ignite_speed", 320.0),
			RSF.GetF("rsf_ignite_life", 0.5), D_IGNITE);
	}
}
