/datum/unarmed_attack/bite/sharp //eye teeth
	attack_verb = list("bit", "chomped on", "crunched on")
	attack_sound = 'sound/weapons/bite.ogg'
	shredding = 0
	damage = 5
	sharp = 1
	edge = 1

/datum/unarmed_attack/diona
	attack_verb = list("lashed", "bludgeoned", "whipped")
	attack_noun = list("tendril")
	damage = 5

/datum/unarmed_attack/claws
	attack_verb = list("scratched", "raked", "slashed")
	attack_noun = list("claws")
	attack_sound = 'sound/weapons/slice.ogg'
	miss_sound = 'sound/weapons/slashmiss.ogg'
	damage = 5
	sharp = 1
	edge = 1

/datum/unarmed_attack/claws/show_attack(var/mob/living/carbon/human/user, var/mob/living/carbon/human/target, var/zone, var/attack_damage)
	var/skill = user.skills["combat"]
	var/datum/organ/external/affecting = target.get_organ(zone)

	if(!skill)	skill = 1
	attack_damage = Clamp(attack_damage, 1, 5)

	if(target == user)
		user.visible_message("<span class='danger'>[user] [pick(attack_verb)] \himself in the [affecting.display_name]!</span>")
		return 0

	switch(zone)
		if("head", "mouth", "eyes")
			// ----- HEAD ----- //
			switch(attack_damage)
				if(1 to 2)
					user.visible_message("<span class='danger'>[user] scratched [target] across \his cheek!</span>")
				if(3 to 4)
					user.visible_message("<span class='danger'>[user] [pick(attack_verb)] [target]'s [pick("head", "neck")]!</span>") //'with spread claws' sounds a little bit odd, just enough that conciseness is better here I think
				if(5)
					user.visible_message(pick(
						"<span class='danger'>[user] rakes \his [pick(attack_noun)] across [target]'s face!</span>",
						"<span class='danger'>[user] tears \his [pick(attack_noun)] into [target]'s face!</span>",
						))
		else
			// ----- BODY ----- //
			switch(attack_damage)
				if(1 to 2)	user.visible_message("<span class='danger'>[user] scratched [target]'s [affecting.display_name]!</span>")
				if(3 to 4)	user.visible_message("<span class='danger'>[user] [pick(attack_verb)] [pick("", "", "the side of")] [target]'s [affecting.display_name]!</span>")
				if(5)		user.visible_message("<span class='danger'>[user] tears \his [pick(attack_noun)] [pick("deep into", "into", "across")] [target]'s [affecting.display_name]!</span>")

/datum/unarmed_attack/claws/strong
	attack_verb = list("mangled", "mauled", "gored")
	damage = 10
	shredding = 1

/datum/unarmed_attack/bite/strong
	attack_verb = list("harshly chomped", "fiercely crunched", "deeply bit")
	damage = 15
	shredding = 1

/datum/unarmed_attack/slime_glomp
	attack_verb = list("glomped", "pounced", "tackled")
	attack_noun = list("body")
	damage = 0

/datum/unarmed_attack/slime_glomp/apply_effects()
	//Todo, maybe have a chance of causing an electrical shock?
	return

/datum/unarmed_attack/dig
	attack_verb = list("raked", "dug", "gouged")
	attack_noun = ("claws")
	attack_sound = 'sound/weapons/slice.ogg'
	miss_sound = 'sound/weapons/slashmiss.ogg'
	sharp = 1
	edge = 1

/datum/unarmed_attack/dig/is_usable(var/mob/living/carbon/human/user, var/mob/living/carbon/human/target, var/zone)

	if (user.legcuffed)
		return 0

	if(!istype(target))
		return 0

	if (!user.lying && (target.lying || (zone in list("l_foot", "r_foot"))))
		if(target.grabbed_by == user && target.lying)
			return 0
		var/datum/organ/external/E = user.organs_by_name["l_foot"]
		if(E && !(E.status & ORGAN_DESTROYED))
			return 1

		E = user.organs_by_name["r_foot"]
		if(E && !(E.status & ORGAN_DESTROYED))
			return 1

		return 0

/datum/unarmed_attack/dig/show_attack(var/mob/living/carbon/human/user, var/mob/living/carbon/human/target, var/zone, var/attack_damage)
	var/datum/organ/external/affecting = target.get_organ(zone)
	var/organ = affecting.display_name

	attack_damage = Clamp(attack_damage, 1, 5)

	switch(attack_damage)
		if(1 to 4)
			user.visible_message("<span class='danger'>[pick("[user] stomped on", "[user] slammed \his foot")] and dug sharp [pick(attack_noun)] [pick("inside")] [target]'s [organ]!</span>")
		if(5)
			user.visible_message("<span class='danger'>[pick("[user] landed a powerful stomp", "[user] stomped down hard", "[user] slammed \his foot")] and [pick(attack_verb)] sharp [pick(attack_noun)] [pick("deep into", "deep down", "deep inside")] [target]'s [organ]!</span>")
