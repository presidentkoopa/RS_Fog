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

	static void Apply(int idx)
	{
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
		}
	}

	// Not a look -- an off. Density 0 stops the shader at its first gate.
	static void Off()
	{
		Slab(0.0, 0.0, 16.0, 1.0, 0.0);
		Tendrils(0.0, 160.0, 22.0, 96.0, 0.5, 0.4, 0.2, 0.7);
		F("rsf_grad_mix", 0.0);
	}

	// Ankle-deep, barely moving, follows the floor. The default, and the one
	// that reads as a place rather than as an effect.
	static void GroundMist()
	{
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
		Slab(72.0, 0.55, 30.0, 1.2, 0.4);
		Motion(10.0, 256.0, 0.8, 0.6, 0.013, 0.5, 3.0, 1.6);
		Tendrils(0.45, 152.0, 24.0, 104.0, 0.6, 0.4, 0.25, 0.7);
		RGB("rsf_col", 70, 58, 54);
		RGB("rsf_grad", 190, 90, 40);
		F("rsf_grad_mix", 0.6);
		F("rsf_pickup", 1.0);
	}

	// Over your head. You are inside it, not looking at it.
	static void Deep()
	{
		Slab(512.0, 0.8, 128.0, 1.4, 0.05);
		Motion(28.0, 320.0, 0.6, 0.7, 0.009, 0.6, 2.0, 1.0);
		Tendrils(0.0, 160.0, 22.0, 96.0, 0.5, 0.4, 0.2, 0.7);
		RGB("rsf_col", 118, 126, 140);
		RGB("rsf_grad", 60, 68, 84);
		F("rsf_grad_mix", 0.5);
		F("rsf_pickup", 0.5);
	}
}
