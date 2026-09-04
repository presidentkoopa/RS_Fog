// RS_Fog -- presets.
//
// A preset is a batch of CVar writes and nothing else, exactly as in the other
// mods in this family. It owns WHAT the weather looks like. It never touches
// rsf_enabled or the event switches, because those are what the player turns on
// and off, and a preset stamping over them reads as the mod switching itself
// back on.

class RSF_Presets
{
	static void F(String n, double v) { let c = CVar.FindCVar(n); if (c) c.SetFloat(v); }
	static void I(String n, int v)    { let c = CVar.FindCVar(n); if (c) c.SetInt(v); }

	static void RGB(String pre, int r, int g, int b)
	{
		I(pre .. "_r", r); I(pre .. "_g", g); I(pre .. "_b", b);
	}

	// The body of it: where the top sits, how thick, how soft the edge, how
	// much the torch lights it, and how tightly it hugs the floor.
	static void Slab(double top, double density, double soft, double scatter, double follow)
	{
		F("rsf_top", top); F("rsf_density", density);
		F("rsf_soft", soft); F("rsf_scatter", scatter);
		F("rsf_follow", follow);
	}

	// How the surface moves, and how the body churns.
	static void Motion(double amp, double len, double speed, double swell,
		double noiseScale, double noiseDepth, double driftX, double driftY)
	{
		F("rsf_surf_amp", amp); F("rsf_surf_len", len);
		F("rsf_surf_speed", speed); F("rsf_surf_cross", swell);
		F("rsf_noise_scale", noiseScale); F("rsf_noise_depth", noiseDepth);
		F("rsf_drift_x", driftX); F("rsf_drift_y", driftY);
	}

	// Wisps rising out of it. Density 0 = none.
	static void Tendrils(double density, double spacing, double radius, double height,
		double rise, double spread, double lean, double taper)
	{
		F("rsf_tend_density", density); F("rsf_tend_spacing", spacing);
		F("rsf_tend_radius", radius);   F("rsf_tend_height", height);
		F("rsf_tend_rise", rise);       F("rsf_tend_spread", spread);
		F("rsf_tend_lean", lean);       F("rsf_tend_taper", taper);
	}

	// How much fog a room gets by whether it has sky over it. A sky ceiling is
	// outdoors, which is the marker every Doom map already carries. Both 1 is
	// one fog everywhere, which is what it was before.
	static void Zones(double indoor, double outdoor)
	{
		F("rsf_indoor", indoor); F("rsf_outdoor", outdoor);
	}

	// EVERY TERM, NEUTRAL. Called by Apply before the preset runs, so a preset
	// only has to state what it actually cares about and can never wear the
	// leftovers of the one before it.
	//
	// This is the shape GlowInTheDark and Darkness already had and Fog did not,
	// which is exactly how seven presets ended up inheriting an indoor/outdoor
	// split they never asked for: pick Courtyard, switch to Swamp, and Swamp
	// stayed thin indoors with nothing in the menu to explain it.
	static void Base()
	{
		Zones(1.0, 1.0);
		Slab(64.0, 0.55, 24.0, 1.0, 0.35);
		Motion(10.0, 256.0, 1.0, 0.6, 0.012, 0.45, 3.0, 1.5);
		Tendrils(0.0, 160.0, 22.0, 96.0, 0.5, 0.4, 0.2, 0.7);
		RGB("rsf_col", 168, 176, 190);
		RGB("rsf_grad", 0, 0, 0);
		F("rsf_grad_mix", 0.0);
		F("rsf_pickup", 0.5);
		F("rsf_bottom", -256.0);
		F("rsf_bow", 0.0);
	}

	static void Apply(int idx)
	{
		Base();

		switch (idx)
		{
		default:
		case 0: Off();        break;
		case 1: GroundMist(); break;
		case 2: Swamp();      break;
		case 3: Smoke();      break;
		case 4: Toxic();      break;
		case 5: Blizzard();   break;
		case 6: Ember();      break;
		case 7: Deep();       break;
		case 8:  FaintHaze();  break;
		case 9:  LightMist();  break;
		case 10: HeavyMist();  break;
		case 11: Murk();       break;
		case 12: PeaSoup();    break;
		case 13: Cellar();     break;
		case 14: Courtyard();  break;
		case 15: NightAir();   break;
		}
	}

	// Not a look -- an off. Density 0 stops the shader at its first gate.
	static void Off()
	{
		Zones(1.0, 1.0);
		Slab(0.0, 0.0, 16.0, 1.0, 0.0);
		Tendrils(0.0, 160.0, 22.0, 96.0, 0.5, 0.4, 0.2, 0.7);
		F("rsf_grad_mix", 0.0);
	}

	// Ankle-deep, barely moving, follows the floor. The default, and the one
	// that reads as a place rather than as an effect.
	static void GroundMist()
	{
		Zones(1.0, 1.0);
		Slab(56.0, 0.45, 28.0, 1.0, 0.35);
		Motion(8.0, 288.0, 0.7, 0.6, 0.010, 0.40, 2.5, 1.2);
		Tendrils(0.0, 160.0, 22.0, 96.0, 0.5, 0.4, 0.2, 0.7);
		RGB("rsf_col", 168, 176, 190);
		F("rsf_grad_mix", 0.0);
		F("rsf_pickup", 0.55);
	}

	// Waist-high, heavy, with wisps standing out of it. Slow.
	static void Swamp()
	{
		Zones(1.0, 1.0);
		Slab(112.0, 0.7, 40.0, 1.1, 0.3);
		Motion(16.0, 224.0, 0.45, 0.75, 0.014, 0.55, 1.5, 0.8);
		Tendrils(0.5, 128.0, 26.0, 132.0, 0.35, 0.5, 0.3, 0.65);
		RGB("rsf_col", 132, 150, 128);
		RGB("rsf_grad", 90, 110, 92);
		F("rsf_grad_mix", 0.45);
		F("rsf_pickup", 0.4);
	}

	// Head-height and churning, lit hard by the torch. Reads as a fire that
	// already happened.
	static void Smoke()
	{
		Zones(1.0, 1.0);
		Slab(176.0, 0.62, 56.0, 1.5, 0.2);
		Motion(22.0, 176.0, 1.4, 0.8, 0.020, 0.75, 6.0, 3.5);
		Tendrils(0.35, 200.0, 34.0, 180.0, 0.9, 0.6, 0.45, 0.5);
		RGB("rsf_col", 92, 92, 96);
		RGB("rsf_grad", 40, 40, 44);
		F("rsf_grad_mix", 0.55);
		F("rsf_pickup", 0.7);
	}

	// Thin, bright and sick. Picks up the room's glow hard, so it goes whatever
	// colour the lighting is -- which is the point.
	static void Toxic()
	{
		Zones(1.0, 1.0);
		Slab(88.0, 0.5, 32.0, 1.3, 0.35);
		Motion(12.0, 208.0, 1.1, 0.65, 0.016, 0.5, 4.0, 2.0);
		Tendrils(0.4, 144.0, 20.0, 120.0, 0.7, 0.45, 0.25, 0.6);
		RGB("rsf_col", 150, 200, 120);
		RGB("rsf_grad", 190, 230, 90);
		F("rsf_grad_mix", 0.5);
		F("rsf_pickup", 0.95);
	}

	// Thick, fast, and driven sideways. The drift is what sells it.
	static void Blizzard()
	{
		Zones(1.0, 1.0);
		Slab(320.0, 0.5, 96.0, 1.6, 0.1);
		Motion(6.0, 128.0, 2.4, 0.4, 0.026, 0.35, 22.0, 9.0);
		Tendrils(0.0, 160.0, 22.0, 96.0, 0.5, 0.4, 0.2, 0.7);
		RGB("rsf_col", 216, 224, 236);
		F("rsf_grad_mix", 0.0);
		F("rsf_pickup", 0.25);
	}

	// Low, dark, and hot underneath. Nearly all of its colour comes from
	// whatever is glowing nearby.
	static void Ember()
	{
		Zones(1.0, 1.0);
		Slab(72.0, 0.55, 30.0, 1.2, 0.4);
		Motion(10.0, 256.0, 0.8, 0.6, 0.013, 0.5, 3.0, 1.6);
		Tendrils(0.45, 152.0, 24.0, 104.0, 0.6, 0.4, 0.25, 0.7);
		RGB("rsf_col", 70, 58, 54);
		RGB("rsf_grad", 190, 90, 40);
		F("rsf_grad_mix", 0.6);
		F("rsf_pickup", 1.0);
	}

	// ---- the density ladder ------------------------------------------------
	//
	// Five settings of the same fog, differing in how much of it there is and
	// nothing else. The point is to be able to say "this, but less" without
	// changing the character of the room.

	// Barely there. You would not notice it until you looked down a corridor.
	static void FaintHaze()
	{
		Zones(1.0, 1.0);
		Slab(40.0, 0.14, 24.0, 0.8, 0.4);
		Motion(5.0, 320.0, 0.5, 0.5, 0.008, 0.30, 1.5, 0.8);
		Tendrils(0.0, 160.0, 22.0, 96.0, 0.5, 0.4, 0.2, 0.7);
		RGB("rsf_col", 180, 186, 196);
		F("rsf_grad_mix", 0.0);
		F("rsf_pickup", 0.45);
	}

	// Reads clearly, still shows you the room.
	static void LightMist()
	{
		Zones(1.0, 1.0);
		Slab(64.0, 0.32, 28.0, 1.0, 0.35);
		Motion(8.0, 288.0, 0.7, 0.6, 0.010, 0.38, 2.5, 1.2);
		Tendrils(0.0, 160.0, 22.0, 96.0, 0.5, 0.4, 0.2, 0.7);
		RGB("rsf_col", 172, 180, 192);
		F("rsf_grad_mix", 0.0);
		F("rsf_pickup", 0.5);
	}

	// Knee to waist, definitely weather. The reasonable middle.
	static void HeavyMist()
	{
		Zones(1.0, 1.0);
		Slab(104.0, 0.58, 36.0, 1.1, 0.3);
		Motion(14.0, 256.0, 0.8, 0.65, 0.013, 0.48, 3.5, 1.8);
		Tendrils(0.3, 150.0, 24.0, 110.0, 0.5, 0.45, 0.25, 0.65);
		RGB("rsf_col", 164, 172, 186);
		RGB("rsf_grad", 120, 130, 148);
		F("rsf_grad_mix", 0.35);
		F("rsf_pickup", 0.55);
	}

	// Over your head and hard to see through. Fights you.
	static void Murk()
	{
		Zones(1.0, 1.0);
		Slab(240.0, 0.95, 72.0, 1.3, 0.15);
		Motion(20.0, 288.0, 0.65, 0.7, 0.011, 0.55, 3.0, 1.5);
		Tendrils(0.35, 170.0, 28.0, 150.0, 0.55, 0.5, 0.3, 0.6);
		RGB("rsf_col", 140, 146, 158);
		RGB("rsf_grad", 82, 88, 102);
		F("rsf_grad_mix", 0.5);
		F("rsf_pickup", 0.6);
	}

	// Completely murky. You navigate by the glow and by sound.
	static void PeaSoup()
	{
		Zones(1.0, 1.0);
		Slab(640.0, 1.45, 160.0, 1.6, 0.05);
		Motion(26.0, 340.0, 0.5, 0.75, 0.009, 0.62, 2.0, 1.0);
		Tendrils(0.0, 160.0, 22.0, 96.0, 0.5, 0.4, 0.2, 0.7);
		RGB("rsf_col", 126, 132, 142);
		RGB("rsf_grad", 70, 74, 84);
		F("rsf_grad_mix", 0.55);
		F("rsf_pickup", 0.65);
	}

	// ---- rooms that know what they are --------------------------------------
	//
	// These three set the indoor/outdoor split as part of the look. A sky
	// ceiling is outdoors, so they work on any map without it being authored
	// for them, and a window shows you weather you are not standing in --
	// the far wall outside fogs as outdoor, the near wall does not.

	// Damp that pools inside and burns off in the open.
	static void Cellar()
	{
		Zones(1.35, 0.15);
		Slab(72.0, 0.55, 30.0, 1.1, 0.45);
		Motion(9.0, 224.0, 0.45, 0.6, 0.012, 0.45, 1.5, 0.8);
		Tendrils(0.4, 140.0, 22.0, 104.0, 0.4, 0.45, 0.25, 0.7);
		RGB("rsf_col", 150, 156, 160);
		RGB("rsf_grad", 96, 104, 110);
		F("rsf_grad_mix", 0.4);
		F("rsf_pickup", 0.5);
	}

	// Weather outside, dry indoors. Step through a door and it stops.
	static void Courtyard()
	{
		Zones(0.12, 1.25);
		Slab(128.0, 0.6, 44.0, 1.2, 0.3);
		Motion(15.0, 300.0, 1.0, 0.7, 0.012, 0.45, 7.0, 3.0);
		Tendrils(0.0, 160.0, 22.0, 96.0, 0.5, 0.4, 0.2, 0.7);
		RGB("rsf_col", 176, 184, 200);
		F("rsf_grad_mix", 0.0);
		F("rsf_pickup", 0.5);
	}

	// Heavy night air outside, a thin haze indoors -- not nothing, so a room
	// with a window does not read as two unrelated places.
	static void NightAir()
	{
		Zones(0.3, 1.5);
		Slab(320.0, 0.75, 88.0, 1.35, 0.2);
		Motion(18.0, 360.0, 0.6, 0.7, 0.010, 0.5, 5.0, 2.5);
		Tendrils(0.25, 190.0, 26.0, 140.0, 0.5, 0.5, 0.3, 0.6);
		RGB("rsf_col", 120, 132, 156);
		RGB("rsf_grad", 64, 74, 96);
		F("rsf_grad_mix", 0.5);
		F("rsf_pickup", 0.6);
	}

	// Over your head. You are inside it, not looking at it.
	static void Deep()
	{
		Zones(1.0, 1.0);
		Slab(512.0, 0.8, 128.0, 1.4, 0.05);
		Motion(28.0, 320.0, 0.6, 0.7, 0.009, 0.6, 2.0, 1.0);
		Tendrils(0.0, 160.0, 22.0, 96.0, 0.5, 0.4, 0.2, 0.7);
		RGB("rsf_col", 118, 126, 140);
		RGB("rsf_grad", 60, 68, 84);
		F("rsf_grad_mix", 0.5);
		F("rsf_pickup", 0.5);
	}
}
