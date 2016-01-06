#define ANTIDEPRESSANT_MESSAGE_DELAY 5*60*10

/datum/reagent/antidepressant/methylphenidate
	name = "Methylphenidate"
	id = "methylphenidate"
	description = "Methylphenidate, commonly known as its brand name, Ritalin, is a central nervous system stimulant that is used to treat attention deficit hyperactivity disorder and narcolepsy."
	reagent_state = LIQUID
	color = "#BF80BF" // rgb: 191, 128, 191
	custom_metabolism = 0.01
	data = 0

	on_mob_life(var/mob/living/M as mob)
		if(!M) M = holder.my_atom
		if(src.volume <= 0.1) if(data != -1)
			data = -1
			M << "\red You lose focus..."
		else
			if(world.time > data + ANTIDEPRESSANT_MESSAGE_DELAY)
				data = world.time
				M << "\blue Your mind feels focused and undivided."
		..()
		return

/datum/chemical_reaction/methylphenidate
	name = "Methylphenidate"
	id = "methylphenidate"
	result = "methylphenidate"
	required_reagents = list("mindbreaker" = 1, "hydrogen" = 1)
	result_amount = 3

/datum/reagent/antidepressant/citalopram
	name = "Citalopram"
	id = "citalopram"
	description = "Citalopram, commonly known as its brand name, Celexa, is an antidepressant drug of the selective serotonin reuptake inhibitor class. It is used to treat major depression and sometimes obsessive compulsive disorder."
	reagent_state = LIQUID
	color = "#FF80FF" // rgb: 255, 128, 255
	custom_metabolism = 0.01
	data = 0

	on_mob_life(var/mob/living/M as mob)
		if(!M) M = holder.my_atom
		if(src.volume <= 0.1) if(data != -1)
			data = -1
			M << "\red Your mind feels a little less stable."
		else
			if(world.time > data + ANTIDEPRESSANT_MESSAGE_DELAY)
				data = world.time
				M << "\blue Your mind feels more stable."
		..()
		return

/datum/chemical_reaction/citalopram
	name = "Citalopram"
	id = "citalopram"
	result = "citalopram"
	required_reagents = list("mindbreaker" = 1, "carbon" = 1)
	result_amount = 3


/datum/reagent/antidepressant/paroxetine
	name = "Paroxetine"
	id = "paroxetine"
	description = "Paroxetine, commonly known as its brand name, Paxil, is a very effective antidepressant drug of the selective serotonin reuptake inhibitor class. Paroxetine is used to treat major depression, anxiety disorders, post-traumatic stress disorder, obsessive-compulsive disorder, and premenstrual dysphoric disorder. This medicine has become more powerful over the years; it causes violent withdrawals with horrific hallucinogenic symptoms, so it has become a habit-forming drug."
	reagent_state = LIQUID
	color = "#FF80BF" // rgb: 255, 128, 191
	custom_metabolism = 0.01
	data = 0

	on_mob_life(var/mob/living/M as mob)
		if(!M) M = holder.my_atom
		if(src.volume <= 0.1) if(data != -1)
			data = -1
			M << "\red Your mind feels much less stable..."
		else
			if(world.time > data + ANTIDEPRESSANT_MESSAGE_DELAY)
				data = world.time
				if(prob(90))
					M << "\blue Your mind feels much more stable."
				else
					M << "\red Your mind breaks apart..."
					M.hallucination += 200
		..()
		return

/datum/chemical_reaction/paroxetine
	name = "Paroxetine"
	id = "paroxetine"
	result = "paroxetine"
	required_reagents = list("mindbreaker" = 1, "oxygen" = 1, "inaprovaline" = 1)
	result_amount = 3
