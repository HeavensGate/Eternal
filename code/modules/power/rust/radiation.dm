//obj/machinery/power/rad_collector

//obj/machinery/power/rad_collector/proc/recieve_pulse(var/pulse_strength)

/obj/machinery/rust/rad_source
	var/mega_energy = 0
	var/time_alive = 0
	var/source_alive = 2
	var/frame
	New()
		..()

	process()
		..()
		//fade away over time
		if(source_alive > 0)
			time_alive++
			source_alive--
		else
			time_alive -= 0.1
			if(time_alive < 0)
				del(src)

		//radiate mobs nearby here every so often
		//
		if(prob(15))
			var/toxrange = 10
			var/toxdamage = 4
			var/radiation = 15
			var/radiationmin = 3
			if (src.mega_energy>200)
				toxdamage = round(((src.mega_energy-150)/50)*4,1)
				radiation = round(((src.mega_energy-150)/50)*5,1)
				radiationmin = round((radiation/5),1)//
			for(var/mob/living/M in view(toxrange, src.loc))
				M.apply_effect(rand(radiationmin,radiation), IRRADIATE)
				toxdamage = (toxdamage - (toxdamage*M.getarmor(null, "rad")))
				M.apply_effect(toxdamage, TOX)



		for(var/obj/machinery/power/rad_collector/R in rad_collectors)
			if(get_dist(R, src) <= 15) // Better than using orange() every process
				R.receive_pulse(mega_energy) //Eh close enough. Probably.
			return

/*
/obj/machinery/rust
	proc/RadiateParticle(var/energy, var/ionizing, var/dir = 0)
		if(!dir)
			RadiateParticleRand(energy, ionizing)
		var/obj/effect/accelerated_particle/particle = new
		particle.set_dir(dir)
		particle.ionizing = ionizing
		if(energy)
			particle.energy = energy
			//particle.invisibility = 2
		//
		return particle

	proc/RadiateParticleRand(var/energy, var/ionizing)
		var/turf/target
		var/particle_range = 3 * round(energy) + rand(3,20)
		if(energy > 1)
			//for penetrating radiation
			for(var/mob/M in range(particle_range))
				var/dist_ratio = particle_range / get_dist(M, src)
				//particles are more likely to hit a person if the person is closer
				// 1/8 = 12.5% (closest)
				// 1/360 = 0.27% (furthest)
				// variation of 12.2%
				if( rand() < (0.25 + dist_ratio * 12.5) )
					target = get_turf(M)
					break
			if(!target)
				target = pick(range(particle_range))
		else
			//for slower, non-penetrating radiation
			for(var/mob/M in view(particle_range))
				var/dist_ratio = particle_range / get_dist(M, src)
				if( rand() < (0.25 + dist_ratio * 12.5) )
					target = get_turf(M)
					break
			if(!target)
				target = pick(view(particle_range))
		var/obj/effect/accelerated_particle/particle = new
		particle.target = target
		particle.ionizing = ionizing
		if(energy)
			particle.energy = energy
			//particle.invisibility = 2
		//
		return particle
*/

/obj/machinery/computer/rust_radiation_monitor
	name = "Radiation Monitor"
	icon_state = "power"
