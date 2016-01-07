#define SOLID 1
#define LIQUID 2
#define GAS 3
#define REAGENTS_OVERDOSE 30
#define REM REAGENTS_EFFECT_MULTIPLIER

//The reaction procs must ALWAYS set src = null, this detaches the proc from the object (the reagent)
//so that it can continue working when the reagent is deleted while the proc is still active.


datum
	reagent
		var/name = "Reagent"
		var/id = "reagent"
		var/description = ""
		var/datum/reagents/holder = null
		var/reagent_state = SOLID
		var/list/data = null
		var/volume = 0
		var/nutriment_factor = 0
		var/custom_metabolism = REAGENTS_METABOLISM
		var/overdose = 0
		var/overdose_dam = 1
		var/scannable = 0 //shows up on health analyzers
		var/glass_icon_state = null
		var/glass_name = null
		var/glass_desc = null
		var/glass_center_of_mass = null
		//var/list/viruses = list()
		var/color = "#000000" // rgb: 0, 0, 0 (does not support alpha channels - yet!)

		proc
			reaction_mob(var/mob/M, var/method=TOUCH, var/volume) //By default we have a chance to transfer some
				if(!istype(M, /mob/living))	return 0
				var/datum/reagent/self = src
				src = null										  //of the reagent to the mob on TOUCHING it.

				if(self.holder)		//for catching rare runtimes
					if(!istype(self.holder.my_atom, /obj/effect/effect/smoke/chem))
						// If the chemicals are in a smoke cloud, do not try to let the chemicals "penetrate" into the mob's system (balance station 13) -- Doohl

						if(method == TOUCH)

							var/chance = 1
							var/block  = 0

							for(var/obj/item/clothing/C in M.get_equipped_items())
								if(C.permeability_coefficient < chance) chance = C.permeability_coefficient
								if(istype(C, /obj/item/clothing/suit/bio_suit))
									// bio suits are just about completely fool-proof - Doohl
									// kind of a hacky way of making bio suits more resistant to chemicals but w/e
									if(prob(75))
										block = 1

								if(istype(C, /obj/item/clothing/head/bio_hood))
									if(prob(75))
										block = 1

							chance = chance * 100

							if(prob(chance) && !block)
								if(M.reagents)
									M.reagents.add_reagent(self.id,self.volume/2)
				return 1

			reaction_obj(var/obj/O, var/volume) //By default we transfer a small part of the reagent to the object
				src = null						//if it can hold reagents. nope!
				//if(O.reagents)
				//	O.reagents.add_reagent(id,volume/3)
				return

			reaction_turf(var/turf/T, var/volume)
				src = null
				return

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(!istype(M, /mob/living))
					return //Noticed runtime errors from pacid trying to damage ghosts, this should fix. --NEO
				if( (overdose > 0) && (volume >= overdose))//Overdosing, wooo
					M.adjustToxLoss(overdose_dam)
				holder.remove_reagent(src.id, custom_metabolism) //By default it slowly disappears.
				return

			on_move(var/mob/M)
				return

			// Called after add_reagents creates a new reagent.
			on_new(var/data)
				return

			// Called when two reagents of the same are mixing. <-- Blatant lies
			on_merge(var/data)
				return

			on_update(var/atom/A)
				return



		blood
			data = new/list("donor"=null,"viruses"=null,"species"="Human","blood_DNA"=null,"blood_type"=null,"blood_colour"= "#A10808","resistances"=null,"trace_chem"=null, "antibodies" = null)
			name = "Blood"
			id = "blood"
			description = "Blood is a constantly circulating fluid in the cardiovascular system of animals with proteins and cells providing the body with nutrition and waste removal."
			reagent_state = LIQUID
			color = "#C80000" // rgb: 200, 0, 0

			glass_icon_state = "glass_red"
			glass_name = "glass of blood"
			glass_desc = "That's a glass of blood. It's viscous, brightly colored, and staining the glass."

			reaction_mob(var/mob/M, var/method=TOUCH, var/volume)
				var/datum/reagent/blood/self = src
				src = null
				if(self.data && self.data["viruses"])
					for(var/datum/disease/D in self.data["viruses"])
						//var/datum/disease/virus = new D.type(0, D, 1)
						// We don't spread.
						if(D.spread_type == SPECIAL || D.spread_type == NON_CONTAGIOUS) continue

						if(method == TOUCH)
							M.contract_disease(D)
						else //injected
							M.contract_disease(D, 1, 0)
				if(self.data && self.data["virus2"] && istype(M, /mob/living/carbon))//infecting...
					var/list/vlist = self.data["virus2"]
					if (vlist.len)
						for (var/ID in vlist)
							var/datum/disease2/disease/V = vlist[ID]

							if(method == TOUCH)
								infect_virus2(M,V.getcopy())
							else
								infect_virus2(M,V.getcopy(),1) //injected, force infection!
				if(self.data && self.data["antibodies"] && istype(M, /mob/living/carbon))//... and curing
					var/mob/living/carbon/C = M
					C.antibodies |= self.data["antibodies"]

			on_merge(var/data)
				if(data["blood_colour"])
					color = data["blood_colour"]
				return ..()

			on_update(var/atom/A)
				if(data["blood_colour"])
					color = data["blood_colour"]
				return ..()

			reaction_turf(var/turf/simulated/T, var/volume)//splash the blood all over the place
				if(!istype(T)) return
				var/datum/reagent/blood/self = src
				src = null
				if(!(volume >= 3)) return

				if(!self.data["donor"] || istype(self.data["donor"], /mob/living/carbon/human))
					blood_splatter(T,self,1)
				else if(istype(self.data["donor"], /mob/living/carbon/monkey))
					var/obj/effect/decal/cleanable/blood/B = blood_splatter(T,self,1)
					if(B) B.blood_DNA["Non-Human DNA"] = "A+"
				else if(istype(self.data["donor"], /mob/living/carbon/alien))
					var/obj/effect/decal/cleanable/blood/B = blood_splatter(T,self,1)
					if(B) B.blood_DNA["UNKNOWN DNA STRUCTURE"] = "X*"
				return

/* Must check the transfering of reagents and their data first. They all can point to one disease datum.

			Del()
				if(src.data["virus"])
					var/datum/disease/D = src.data["virus"]
					D.cure(0)
				..()
*/
		vaccine
			//data must contain virus type
			name = "Vaccine"
			id = "vaccine"
			reagent_state = LIQUID
			color = "#C81040" // rgb: 200, 16, 64

			reaction_mob(var/mob/M, var/method=TOUCH, var/volume)
				var/datum/reagent/vaccine/self = src
				src = null
				if(self.data&&method == INGEST)
					for(var/datum/disease/D in M.viruses)
						if(istype(D, /datum/disease/advance))
							var/datum/disease/advance/A = D
							if(A.GetDiseaseID() == self.data)
								D.cure()
						else
							if(D.type == self.data)
								D.cure()

					M.resistances += self.data
				return

		#define WATER_LATENT_HEAT 19000 // How much heat is removed when applied to a hot turf, in J/unit (19000 makes 120 u of water roughly equivalent to 4L)
		water
			name = "Water"
			id = "water"
			description = "Water is a ubiquitous chemical substance that is composed of hydrogen and oxygen. It is a necessary component to all life."
			reagent_state = LIQUID
			color = "#0064C8" // rgb: 0, 100, 200
			custom_metabolism = 0.01

			glass_icon_state = "glass_clear"
			glass_name = "glass of water"
			glass_desc = "The father of all refreshments."

			reaction_turf(var/turf/simulated/T, var/volume)
				if (!istype(T)) return

				//If the turf is hot enough, remove some heat
				var/datum/gas_mixture/environment = T.return_air()
				var/min_temperature = T0C + 100	//100C, the boiling point of water

				if (environment && environment.temperature > min_temperature) //abstracted as steam or something
					var/removed_heat = between(0, volume*WATER_LATENT_HEAT, -environment.get_thermal_energy_change(min_temperature))
					environment.add_thermal_energy(-removed_heat)
					if (prob(5))
						T.visible_message("\red The water sizzles as it lands on \the [T]!")

				else //otherwise, the turf gets wet
					if(volume >= 3)
						if(T.wet >= 1) return
						T.wet = 1
						if(T.wet_overlay)
							T.overlays -= T.wet_overlay
							T.wet_overlay = null
						T.wet_overlay = image('icons/effects/water.dmi',T,"wet_floor")
						T.overlays += T.wet_overlay

						src = null
						spawn(800)
							if (!istype(T)) return
							if(T.wet >= 2) return
							T.wet = 0
							if(T.wet_overlay)
								T.overlays -= T.wet_overlay
								T.wet_overlay = null

				//Put out fires.
				var/hotspot = (locate(/obj/fire) in T)
				if(hotspot)
					del(hotspot)
					if(environment)
						environment.react() //react at the new temperature

			reaction_obj(var/obj/O, var/volume)
				var/turf/T = get_turf(O)
				var/hotspot = (locate(/obj/fire) in T)
				if(hotspot && !istype(T, /turf/space))
					var/datum/gas_mixture/lowertemp = T.remove_air( T:air:total_moles )
					lowertemp.temperature = max( min(lowertemp.temperature-2000,lowertemp.temperature / 2) ,0)
					lowertemp.react()
					T.assume_air(lowertemp)
					del(hotspot)
				if(istype(O,/obj/item/weapon/reagent_containers/food/snacks/monkeycube))
					var/obj/item/weapon/reagent_containers/food/snacks/monkeycube/cube = O
					if(!cube.wrapped)
						cube.Expand()

			reaction_mob(var/mob/M, var/method=TOUCH, var/volume)
				if (istype(M, /mob/living/carbon/slime))
					var/mob/living/carbon/slime/S = M
					S.apply_water()

		water/holywater
			name = "Holy Water"
			id = "holywater"
			description = "Holy water is an ashen-obsidian-water mix. This solution will alter certain sections of the brain's rationality."
			color = "#E0E8EF" // rgb: 224, 232, 239

			glass_icon_state = "glass_clear"
			glass_name = "glass of holy water"
			glass_desc = "An ashen-obsidian-water mix, this solution will alter certain sections of the brain's rationality."

			on_mob_life(var/mob/living/M as mob)
				if(ishuman(M))
					if((M.mind in ticker.mode.cult) && prob(10))
						M << "\blue A cooling sensation from inside you brings you an untold calmness."
						ticker.mode.remove_cultist(M.mind)
						for(var/mob/O in viewers(M, null))
							O.show_message(text("\blue []'s eyes blink and become clearer.", M), 1) // So observers know it worked.
				holder.remove_reagent(src.id, 10 * REAGENTS_METABOLISM) //high metabolism to prevent extended uncult rolls.
				return

		lube
			name = "Space Lube"
			id = "lube"
			description = "Space Lubricant is a substance introduced between two moving surfaces to reduce the friction and wear between them."
			reagent_state = LIQUID
			color = "#009CA8" // rgb: 0, 156, 168
			overdose = REAGENTS_OVERDOSE

			reaction_turf(var/turf/simulated/T, var/volume)
				if (!istype(T)) return
				src = null
				if(volume >= 1)
					if(T.wet >= 2) return
					T.wet = 2
					spawn(800)
						if (!istype(T)) return
						T.wet = 0
						if(T.wet_overlay)
							T.overlays -= T.wet_overlay
							T.wet_overlay = null
						return

		plasticide
			name = "Plasticide"
			id = "plasticide"
			description = "Plasticide is liquidized plastic previously exposed to temperatures beyond 373.15 Kelvin."
			reagent_state = LIQUID
			color = "#CF3600" // rgb: 207, 54, 0
			custom_metabolism = 0.01

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				// Toxins are really weak, but without being treated, last very long.
				M.adjustToxLoss(0.2)
				..()
				return

		slimetoxin
			name = "Mutation Toxin"
			id = "mutationtoxin"
			description = "Mutation Toxin is a corruptive toxin produced by slimes."
			reagent_state = LIQUID
			color = "#13BC5E" // rgb: 19, 188, 94
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(ishuman(M))
					var/mob/living/carbon/human/human = M
					if(human.species.name != "Slime")
						M << "<span class='danger'>Your flesh rapidly mutates!</span>"
						human.set_species("Slime")
				..()
				return

		aslimetoxin
			name = "Advanced Mutation Toxin"
			id = "amutationtoxin"
			description = "Advanced Mutation Toxin is an advanced corruptive toxin produced by slimes."
			reagent_state = LIQUID
			color = "#13BC5E" // rgb: 19, 188, 94
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(istype(M, /mob/living/carbon) && M.stat != DEAD)
					M << "\red Your flesh rapidly mutates!"
					if(M.monkeyizing)	return
					M.monkeyizing = 1
					M.canmove = 0
					M.icon = null
					M.overlays.Cut()
					M.invisibility = 101
					for(var/obj/item/W in M)
						if(istype(W, /obj/item/weapon/implant))	//TODO: Carn. give implants a dropped() or something
							del(W)
							continue
						W.layer = initial(W.layer)
						W.loc = M.loc
						W.dropped(M)
					var/mob/living/carbon/slime/new_mob = new /mob/living/carbon/slime(M.loc)
					new_mob.a_intent = "hurt"
					new_mob.universal_speak = 1
					if(M.mind)
						M.mind.transfer_to(new_mob)
					else
						new_mob.key = M.key
					del(M)
				..()
				return

		inaprovaline
			name = "Inaprovaline"
			id = "inaprovaline"
			description = "Inaprovaline is a synaptic stimulant and cardios stimulant. It is a mild painkiller and it is used to stabilize critical patients."
			reagent_state = LIQUID
			color = "#00BFFF" // rgb: 200, 165, 220
			overdose = REAGENTS_OVERDOSE*2
			scannable = 1

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(!M) M = holder.my_atom

				if(alien && alien == IS_VOX)
					M.adjustToxLoss(REAGENTS_METABOLISM)
				else
					if(M.losebreath >= 10)
						M.losebreath = max(10, M.losebreath-5)

				holder.remove_reagent(src.id, 0.5 * REAGENTS_METABOLISM)
				return

		space_drugs
			name = "Space drugs"
			id = "space_drugs"
			description = "This is an illegal chemical compound used as a drug for recreational purposes."
			reagent_state = LIQUID
			color = "#60A584" // rgb: 96, 165, 132
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.druggy = max(M.druggy, 15)
				if(isturf(M.loc) && !istype(M.loc, /turf/space))
					if(M.canmove && !M.restrained())
						if(prob(10)) step(M, pick(cardinal))
				if(prob(7)) M.emote(pick("twitch","drool","moan","giggle"))
				holder.remove_reagent(src.id, 0.5 * REAGENTS_METABOLISM)
				return

		serotrotium
			name = "Serotrotium"
			id = "serotrotium"
			description = "Serotrotium is a chemical compound that promotes concentrated production of the serotonin neurotransmitter in humans."
			reagent_state = LIQUID
			color = "#202040" // rgb: 20, 20, 40
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(ishuman(M))
					if(prob(7)) M.emote(pick("twitch","drool","moan","gasp"))
					holder.remove_reagent(src.id, 0.25 * REAGENTS_METABOLISM)
				return

/*		silicate
			name = "Silicate"
			id = "silicate"
			description = "A compound that can be used to reinforce glass."
			reagent_state = LIQUID
			color = "#C7FFFF" // rgb: 199, 255, 255

			reaction_obj(var/obj/O, var/volume)
				src = null
				if(istype(O,/obj/structure/window))
					if(O:silicate <= 200)

						O:silicate += volume
						O:health += volume * 3

						if(!O:silicateIcon)
							var/icon/I = icon(O.icon,O.icon_state,O.dir)

							var/r = (volume / 100) + 1
							var/g = (volume / 70) + 1
							var/b = (volume / 50) + 1
							I.SetIntensity(r,g,b)
							O.icon = I
							O:silicateIcon = I
						else
							var/icon/I = O:silicateIcon

							var/r = (volume / 100) + 1
							var/g = (volume / 70) + 1
							var/b = (volume / 50) + 1
							I.SetIntensity(r,g,b)
							O.icon = I
							O:silicateIcon = I

				return*/

		oxygen
			name = "Oxygen"
			id = "oxygen"
			description = "Oxygen is a highly reactive chemical element and oxidizing agent in the form of a transparent, odorless, tasteless, combustible, diatomic gas at room temperature. Makes up 21 percent of breathable air."
			reagent_state = GAS
			color = "#808080" // rgb: 128, 128, 128

			custom_metabolism = 0.01

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(M.stat == 2) return
				if(alien && alien == IS_VOX)
					M.adjustToxLoss(REAGENTS_METABOLISM)
					holder.remove_reagent(src.id, REAGENTS_METABOLISM) //By default it slowly disappears.
					return
				..()

		copper
			name = "Copper"
			id = "copper"
			description = "Copper is a brown, metallic, lustrous, soft, malleable and ductile chemical element solid at room temperature with a very high thermal and electrical conductivity."
			color = "#B97332" // rgb: 185, 115, 50 Brighter brown.

			custom_metabolism = 0.01

		nitrogen
			name = "Nitrogen"
			id = "nitrogen"
			description = "Nitrogen is a transparent, odorless, tasteless, diatomic, chemical element in a gaseous state at room temperature. It can form many compounds and it makes up 78% of breathable air."
			reagent_state = GAS
			color = "#808080" // rgb: 128, 128, 128

			custom_metabolism = 0.01

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(M.stat == 2) return
				if(alien && alien == IS_VOX)
					M.adjustOxyLoss(-2*REM)
					holder.remove_reagent(src.id, REAGENTS_METABOLISM) //By default it slowly disappears.
					return
				..()

		hydrogen
			name = "Hydrogen"
			id = "hydrogen"
			description = "Hydrogen is a colorless, odorless, nonmetallic, tasteless, highly combustible chemical element in the form of a diatomic gas at room temperature."
			reagent_state = GAS
			color = "#808080" // rgb: 128, 128, 128

			custom_metabolism = 0.01

		potassium
			name = "Potassium"
			id = "potassium"
			description = "Potassium is an alkaline chemical element and an easily soluble metal soft enough to cut with a knife. It is highly reactive with water."
			reagent_state = SOLID
			color = "#A0A0A0" // rgb: 160, 160, 160

			custom_metabolism = 0.01

		mercury
			name = "Mercury"
			id = "mercury"
			description = "Mercury is a heavy, silvery, metallic chemical element unique to being a liquid at standard temperature and pressure."
			reagent_state = LIQUID
			color = "#96A0AF" // rgb: 150, 160, 175
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(M.canmove && !M.restrained() && istype(M.loc, /turf/space))
					step(M, pick(cardinal))
				if(prob(5)) M.emote(pick("twitch","drool","moan"))
				M.adjustBrainLoss(2)
				..()
				return

		sulfur
			name = "Sulfur"
			id = "sulfur"
			description = "Sulfur is a yellow, nonmetallic, crystalline chemical element. It is solid at room temperature, crushed to a powder, reactive with nearly all elements, and it is notably odoriferous--responsible for the smell of rotting eggs."
			reagent_state = SOLID
			color = "#F0D3C7" // rgb: 240, 220, 55 Bright yellow.

			custom_metabolism = 0.01

		carbon
			name = "Carbon"
			id = "carbon"
			description = "Carbon is a black, nonmetallic, allotropic chemical element solid at room temperature, abundant in the universe, and found in all organic compounds. It is the chemical basis of all known life."
			reagent_state = SOLID
			color = "#1C1300" // rgb: 30, 20, 0

			custom_metabolism = 0.01

			reaction_turf(var/turf/T, var/volume)
				src = null
				if(!istype(T, /turf/space))
					var/obj/effect/decal/cleanable/dirt/dirtoverlay = locate(/obj/effect/decal/cleanable/dirt, T)
					if (!dirtoverlay)
						dirtoverlay = new/obj/effect/decal/cleanable/dirt(T)
						dirtoverlay.alpha = volume*30
					else
						dirtoverlay.alpha = min(dirtoverlay.alpha+volume*30, 255)

		chlorine
			name = "Chlorine"
			id = "chlorine"
			description = "Chlorine is a yellow-green chemical element in the form of a diatomic gas at room temperature. It is a strong oxidizing agent and it has a characteristic odor."
			reagent_state = GAS
			color = "#C8C864" // rgb: 200, 200, 100 Dull yellow-green.
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.take_organ_damage(1*REM, 0) //Pucky wants to make this deal toxin damage, too.
				..()
				return

		fluorine
			name = "Fluorine"
			id = "fluorine"
			description = "Fluorine is a yellow-green, powerful chemical element in the form of a diatomic gas at room temperature. It is extremely reactive and it reacts with almost every other element.."
			reagent_state = GAS
			color = "#C8E14B" // rgb: 200, 225, 75 Yellow-green.
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.adjustToxLoss(1*REM) //Pucky wants to change this to make it cause more toxin damage and organ damage. This shit's toxic!
				..()
				return

		sodium
			name = "Sodium"
			id = "sodium"
			description = "Sodium is a soft, silver-white, metallic, highly reactive chemical element which is solid at room temperature. It readily reacts with water."
			reagent_state = SOLID
			color = "#E1E1E1" // rgb: 225, 225, 225 More white.

			custom_metabolism = 0.01

		phosphorus
			name = "Phosphorus"
			id = "phosphorus"
			description = "Phosphorus is a maroon, highly reactive chemical element which is solid at room temperature. It is essential as a component of DNA, RNA, and ATP, biological blueprints and energy-carriers. "
			reagent_state = SOLID
			color = "#832828" // rgb: 131, 40, 40

			custom_metabolism = 0.01

		lithium
			name = "Lithium"
			id = "lithium"
			description = "Lithium is a soft, alkaline, silver-white, metallic chemical element. It is the lightest and least dense solid element, no longer used as an antidepressant due to its side effects."
			reagent_state = SOLID
			color = "#C8C8C8" // rgb: 200, 200, 200
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(M.canmove && !M.restrained() && istype(M.loc, /turf/space))
					step(M, pick(cardinal))
				if(prob(5)) M.emote(pick("twitch","drool","moan"))
				..()
				return

		sugar
			name = "Sugar"
			id = "sugar"
			description = "Sugar is an organic compound from the sugarcane plant commonly known as table sugar and sometimes called sucrose. This white, odorless, crystalline powder has a pleasing, sweet taste."
			reagent_state = SOLID
			color = "#FFFFFF" // rgb: 255, 255, 255

			glass_icon_state = "iceglass"
			glass_name = "glass of sugar"
			glass_desc = "The organic compound commonly known as table sugar and sometimes called sucrose. This white, odorless, crystalline powder has a pleasing, sweet taste."

			on_mob_life(var/mob/living/M as mob)
				M.nutrition += 1*REM
				..()
				return


		glycerol
			name = "Glycerol"
			id = "glycerol"
			description = "Glycerol is a simple polyol compound. It is a colorless, odorless, viscous, sweet-tasting liquid easily soluble in water."
			reagent_state = LIQUID
			color = "#808080" // rgb: 128, 128, 128

			custom_metabolism = 0.01

		nitroglycerin
			name = "Nitroglycerin"
			id = "nitroglycerin"
			description = "Nitroglycerin is a nitrite compound. It is a heavy, colorless, oily, explosive liquid most commonly produced by nitrating glycerol with white fuming nitric acid."
			reagent_state = LIQUID
			color = "#808080" // rgb: 128, 128, 128

			custom_metabolism = 0.01

		radium
			name = "Radium"
			id = "radium"
			description = "Radium is an alkaline earth metal. It is extremely radioactive and it is used to produce antibodies in patients with viruses."
			reagent_state = SOLID
			color = "#C7C7C7" // rgb: 199,199,199

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.apply_effect(2*REM,IRRADIATE,0)
				// radium may increase your chances to cure a disease
				if(istype(M,/mob/living/carbon)) // make sure to only use it on carbon mobs
					var/mob/living/carbon/C = M
					if(C.virus2.len)
						for (var/ID in C.virus2)
							var/datum/disease2/disease/V = C.virus2[ID]
							if(prob(5))
								M:antibodies |= V.antigen
								if(prob(50))
									M.radiation += 50 // curing it that way may kill you instead
									var/absorbed
									if(istype(C,/mob/living/carbon))
										var/mob/living/carbon/H = C
										var/datum/organ/internal/diona/nutrients/rad_organ = locate() in H.internal_organs
										if(rad_organ && !rad_organ.is_broken())
											absorbed = 1
									if(!absorbed)
										M.adjustToxLoss(100)
				..()
				return

			reaction_turf(var/turf/T, var/volume)
				src = null
				if(volume >= 3)
					if(!istype(T, /turf/space))
						var/obj/effect/decal/cleanable/greenglow/glow = locate(/obj/effect/decal/cleanable/greenglow, T)
						if(!glow)
							new /obj/effect/decal/cleanable/greenglow(T)
						return


		ryetalyn
			name = "Ryetalyn"
			id = "ryetalyn"
			description = "Ryetalyn can cure all genetic abnomalities via a catalytic process. Only one unit is needed."
			reagent_state = SOLID
			color = "#96C800" // rgb: 150, 200, 0
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom

				var/needs_update = M.mutations.len > 0

				M.mutations = list()
				M.disabilities = 0
				M.sdisabilities = 0

				// Might need to update appearance for hulk etc.
				if(needs_update && ishuman(M))
					var/mob/living/carbon/human/H = M
					H.update_mutations()

				..()
				return

		thermite
			name = "Thermite"
			id = "thermite"
			description = "Thermite is a flammable pyrotechnic composition of metal powder fuel oxidized metal. It undergoes an exothermic reduction-oxidation reaction-a thermite reaction."
			reagent_state = SOLID
			color = "#673910" // rgb: 103, 57, 16

			reaction_turf(var/turf/T, var/volume)
				src = null
				if(volume >= 5)
					if(istype(T, /turf/simulated/wall))
						var/turf/simulated/wall/W = T
						W.thermite = 1
						W.overlays += image('icons/effects/effects.dmi',icon_state = "#673910")
				return

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.adjustFireLoss(1)
				..()
				return

		paracetamol
			name = "Paracetamol"
			id = "paracetamol"
			description = "Paracetamol, commonly known as its brand name, Tylenol, is a simple, mild painkiller."
			reagent_state = LIQUID
			color = "#C8A5DC"
			overdose = 60
			scannable = 1
			custom_metabolism = 0.025 // Lasts 10 minutes for 15 units

			on_mob_life(var/mob/living/M as mob)
				if (volume > overdose)
					M.hallucination = max(M.hallucination, 2)
				..()
				return

		tramadol
			name = "Tramadol"
			id = "tramadol"
			description = "Tramadol, commonly known as its brand name, Ultram, is a simple, yet effective painkiller."
			reagent_state = LIQUID
			color = "#CB68FC" // rgb: 203, 104, 252
			overdose = 30
			scannable = 1
			custom_metabolism = 0.025 // Lasts 10 minutes for 15 units

			on_mob_life(var/mob/living/M as mob)
				if (volume > overdose)
					M.hallucination = max(M.hallucination, 2)
				..()
				return

		oxycodone
			name = "Oxycodone"
			id = "oxycodone"
			description = "Oxycodone, commonly known as its brand name, Oxycontin, is an effective and very addictive painkiller."
			reagent_state = LIQUID
			color = "#800080" // rgb: 128, 104, 128
			overdose = 20
			scannable = 1
			custom_metabolism = 0.25 // Lasts 10 minutes for 15 units

			on_mob_life(var/mob/living/M as mob)
				if (volume > overdose)
					M.druggy = max(M.druggy, 10)
					M.hallucination = max(M.hallucination, 3)
				..()
				return


		virus_food
			name = "Virus Food"
			id = "virusfood"
			description = "Virus food is a mixture of water, milk, and oxygen. Virus cells can use this mixture to reproduce."
			reagent_state = LIQUID
			nutriment_factor = 2 * REAGENTS_METABOLISM
			color = "#899613" // rgb: 137, 150, 19

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.nutrition += nutriment_factor*REM
				..()
				return

		sterilizine
			name = "Sterilizine"
			id = "sterilizine"
			description = "Sterilizine is an antibacterial agent that sterilizes wounds in preparation for surgery."
			reagent_state = LIQUID
			color = "#C8A5DC" // rgb: 200, 165, 220

			//makes you squeaky clean
			reaction_mob(var/mob/living/M, var/method=TOUCH, var/volume)
				if (method == TOUCH)
					M.germ_level -= min(volume*20, M.germ_level)

			reaction_obj(var/obj/O, var/volume)
				O.germ_level -= min(volume*20, O.germ_level)

			reaction_turf(var/turf/T, var/volume)
				T.germ_level -= min(volume*20, T.germ_level)

	/*		reaction_mob(var/mob/living/M, var/method=TOUCH, var/volume)
				src = null
				if (method==TOUCH)
					if(istype(M, /mob/living/carbon/human))
						if(M.health >= -100 && M.health <= 0)
							M.crit_op_stage = 0.0
				if (method==INGEST)
					usr << "The liquid burns as it travels down your throat and esophagus. Do your insides feel squeaky clean, now?"
					M.adjustToxLoss(3)
				return
			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
					M.radiation += 3
					..()
					return
	*/

		iron
			name = "Iron"
			id = "iron"
			description = "Iron is a lustrous, metallic, solid, and sturdy chemical element. It is abundant and used for a variety of purposes."
			reagent_state = SOLID
			color = "#7D7D7D" // rgb: 125, 125, 125
			overdose = REAGENTS_OVERDOSE

		gold
			name = "Gold"
			id = "gold"
			description = "Gold is a dense, soft, shiny metal and the most malleable and ductile metal known."
			reagent_state = SOLID
			color = "#F7C430" // rgb: 247, 196, 48

		silver
			name = "Silver"
			id = "silver"
			description = "Silver is a soft, white, lustrous transition metal. It has the highest electrical conductivity of any element and the highest thermal conductivity of any metal."
			reagent_state = SOLID
			color = "#D0D0D0" // rgb: 208, 208, 208

		uranium
			name ="Uranium"
			id = "uranium"
			description = "Uranium is a silvery-white metallic chemical element in the actinide series. It is weakly radioactive."
			reagent_state = SOLID
			color = "#B8B8C0" // rgb: 184, 184, 192

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.apply_effect(1,IRRADIATE,0)
				..()
				return

			reaction_turf(var/turf/T, var/volume)
				src = null
				if(volume >= 3)
					if(!istype(T, /turf/space))
						var/obj/effect/decal/cleanable/greenglow/glow = locate(/obj/effect/decal/cleanable/greenglow, T)
						if(!glow)
							new /obj/effect/decal/cleanable/greenglow(T)
						return

		aluminum
			name = "Aluminum"
			id = "aluminum"
			description = "Aluminum is a silvery-white and ductile member of the boron group of chemical elements."
			reagent_state = SOLID
			color = "#A8A8A8" // rgb: 168, 168, 168

		silicon
			name = "Silicon"
			id = "silicon"
			description = "Silicon is a tetravalent chemical element in the metalloid group. It is less reactive than carbon."
			reagent_state = SOLID
			color = "#A8A8A8" // rgb: 168, 168, 168

		fuel
			name = "Welding fuel"
			id = "fuel"
			description = "Welding fuel is a flammable liquid used as a fuel for welders."
			reagent_state = LIQUID
			color = "#660000" // rgb: 102, 0, 0
			overdose = REAGENTS_OVERDOSE

			glass_icon_state = "dr_gibb_glass"
			glass_name = "glass of welder fuel"
			glass_desc = "Unless you are an industrial tool, this is probably not safe for consumption."

			reaction_obj(var/obj/O, var/volume)
				var/turf/the_turf = get_turf(O)
				if(!the_turf)
					return //No sense trying to start a fire if you don't have a turf to set on fire. --NEO
				new /obj/effect/decal/cleanable/liquid_fuel(the_turf, volume)
			reaction_turf(var/turf/T, var/volume)
				new /obj/effect/decal/cleanable/liquid_fuel(T, volume)
				return
			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.adjustToxLoss(1)
				..()
				return

		space_cleaner
			name = "Space cleaner"
			id = "cleaner"
			description = "Space cleaner is a chemical compound reinforced with double the amount of sodium hypochloride than its original recipe. It is known for cleaning the most hardy of substances on almost any surface."
			reagent_state = LIQUID
			color = "#A5F0EE" // rgb: 165, 240, 238
			overdose = REAGENTS_OVERDOSE

			reaction_obj(var/obj/O, var/volume)
				if(istype(O,/obj/effect/decal/cleanable))
					del(O)
				else
					if(O)
						O.clean_blood()

			reaction_turf(var/turf/T, var/volume)
				if(volume >= 1)
					if(istype(T, /turf/simulated))
						var/turf/simulated/S = T
						S.dirt = 0
					T.clean_blood()
					for(var/obj/effect/decal/cleanable/C in T.contents)
						src.reaction_obj(C, volume)
						del(C)

					for(var/mob/living/carbon/slime/M in T)
						M.adjustToxLoss(rand(5,10))

			reaction_mob(var/mob/M, var/method=TOUCH, var/volume)
				if(iscarbon(M))
					var/mob/living/carbon/C = M
					if(C.r_hand)
						C.r_hand.clean_blood()
					if(C.l_hand)
						C.l_hand.clean_blood()
					if(C.wear_mask)
						if(C.wear_mask.clean_blood())
							C.update_inv_wear_mask(0)
					if(ishuman(M))
						var/mob/living/carbon/human/H = C
						if(H.head)
							if(H.head.clean_blood())
								H.update_inv_head(0)
						if(H.wear_suit)
							if(H.wear_suit.clean_blood())
								H.update_inv_wear_suit(0)
						else if(H.w_uniform)
							if(H.w_uniform.clean_blood())
								H.update_inv_w_uniform(0)
						if(H.shoes)
							if(H.shoes.clean_blood())
								H.update_inv_shoes(0)
						else
							H.clean_blood(1)
							return
					M.clean_blood()

		leporazine
			name = "Leporazine"
			id = "leporazine"
			description = "Leporazine can be use to stabilize an individuals body temperature."
			reagent_state = LIQUID
			color = "#C8A5DC" // rgb: 200, 165, 220
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(M.bodytemperature > 310)
					M.bodytemperature = max(310, M.bodytemperature - (40 * TEMPERATURE_DAMAGE_COEFFICIENT))
				else if(M.bodytemperature < 311)
					M.bodytemperature = min(310, M.bodytemperature + (40 * TEMPERATURE_DAMAGE_COEFFICIENT))
				..()
				return

		cryptobiolin
			name = "Cryptobiolin"
			id = "cryptobiolin"
			description = "Cryptobiolin is a reagent in the recipe to make Spaceacillin, but it is not a medicine on its own and has undesirable side effects when consumed."
			reagent_state = LIQUID
			color = "#000055" // rgb: 0, 0, 85 More than of these medications had incorrect color rgb labels.
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.make_dizzy(1)
				if(!M.confused) M.confused = 1
				M.confused = max(M.confused, 20)
				holder.remove_reagent(src.id, 0.5 * REAGENTS_METABOLISM)
				..()
				return


		kelotane
			name = "Kelotane"
			id = "kelotane"
			description = "Kelotane is a medication used to treat burns."
			reagent_state = LIQUID
			color = "#FFA800" // rgb: 255, 168, 0
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(M.stat == 2.0)
					return
				if(!M) M = holder.my_atom
				//This needs a diona check but if one is added they won't be able to heal burn damage at all.
				M.heal_organ_damage(0,2*REM)
				..()
				return

		dermaline
			name = "Dermaline"
			id = "dermaline"
			description = "Dermaline is the next step in burn medication. Works twice as good as kelotane and enables the body to repair fourth degree burns deep into the hypodermis of the skin."
			reagent_state = LIQUID
			color = "#FF8000" // rgb: 255, 128, 0
			overdose = REAGENTS_OVERDOSE/2
			scannable = 1

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(M.stat == 2.0) //THE GUY IS **DEAD**! BEREFT OF ALL LIFE HE RESTS IN PEACE etc etc. He does NOT metabolise shit anymore, god DAMN
					return
				if(!M) M = holder.my_atom
				if(!alien || alien != IS_DIONA)
					M.heal_organ_damage(0,3*REM)
				..()
				return

		dexalin
			name = "Dexalin"
			id = "dexalin"
			description = "Dexalin is used in the treatment of oxygen deprivation."
			reagent_state = LIQUID
			color = "#0080FF" // rgb: 0, 128, 255
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(M.stat == 2.0)
					return  //See above, down and around. --Agouri
				if(!M) M = holder.my_atom

				if(alien && alien == IS_VOX)
					M.adjustToxLoss(2*REM)
				else if(!alien || alien != IS_DIONA)
					M.adjustOxyLoss(-2*REM)

				holder.remove_reagent("lexorin", 2*REM)
				..()
				return

		dexalinp
			name = "Dexalin Plus"
			id = "dexalinp"
			description = "Dexalin Plus is used in the treatment of oxygen deprivation. It is highly effective; one unit completely replenishes the lungs."
			reagent_state = LIQUID
			color = "#0040FF" // rgb: 0, 64, 255
			overdose = REAGENTS_OVERDOSE/2
			scannable = 1

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(M.stat == 2.0)
					return
				if(!M) M = holder.my_atom

				if(alien && alien == IS_VOX)
					M.adjustOxyLoss()
				else if(!alien || alien != IS_DIONA)
					M.adjustOxyLoss(-M.getOxyLoss())

				holder.remove_reagent("lexorin", 2*REM)
				..()
				return

		tricordrazine
			name = "Tricordrazine"
			id = "tricordrazine"
			description = "Tricordrazine is a stimulant originally derived from cordrazine. It can be used to treat a wide range of injuries."
			reagent_state = LIQUID
			color = "#8040FF" // rgb: 128, 64, 255
			scannable = 1

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(M.stat == 2.0)
					return
				if(!M) M = holder.my_atom
				if(!alien || alien != IS_DIONA)
					if(M.getOxyLoss()) M.adjustOxyLoss(-1*REM)
					if(M.getBruteLoss() && prob(80)) M.heal_organ_damage(1*REM,0)
					if(M.getFireLoss() && prob(80)) M.heal_organ_damage(0,1*REM)
					if(M.getToxLoss() && prob(80)) M.adjustToxLoss(-1*REM)
				..()
				return

		anti_toxin
			name = "Dylovene"
			id = "anti_toxin"
			description = "Dylovene is an effective broad-spectrum antitoxin."
			reagent_state = LIQUID
			color = "#00A000" // rgb: 0, 160, 0
			scannable = 1

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(!M) M = holder.my_atom
				if(!alien || alien != IS_DIONA)
					M.reagents.remove_all_type(/datum/reagent/toxin, 1*REM, 0, 1)
					M.drowsyness = max(M.drowsyness-2*REM, 0)
					M.hallucination = max(0, M.hallucination - 5*REM)
					M.adjustToxLoss(-2*REM)
				..()
				return

		adminordrazine //An OP chemical for admins
			name = "Adminordrazine"
			id = "adminordrazine"
			description = "Not much is known about this lavender elixir-like beverage except it has a taste guaranteed anyone will enjoy and one drop has magical properties beyond science's and logic's comprehension."
			reagent_state = LIQUID
			color = "#C8A5DC" // rgb: 200, 165, 220

			glass_icon_state = "golden_cup"
			glass_name = "golden cup"
			glass_desc = "The lavender elixir sparkles, swirls and hums quietly; it looks magical beyond your comprehension."

			on_mob_life(var/mob/living/carbon/M as mob)
				if(!M) M = holder.my_atom ///This can even heal dead people.
				M.reagents.remove_all_type(/datum/reagent/toxin, 5*REM, 0, 1)
				M.setCloneLoss(0)
				M.setOxyLoss(0)
				M.radiation = 0
				M.heal_organ_damage(5,5)
				M.adjustToxLoss(-5)
				M.hallucination = 0
				M.setBrainLoss(0)
				M.disabilities = 0
				M.sdisabilities = 0
				M.eye_blurry = 0
				M.eye_blind = 0
				M.SetWeakened(0)
				M.SetStunned(0)
				M.SetParalysis(0)
				M.silent = 0
				M.dizziness = 0
				M.drowsyness = 0
				M.stuttering = 0
				M.confused = 0
				M.sleeping = 0
				M.jitteriness = 0
				for(var/datum/disease/D in M.viruses)
					D.spread = "Remissive"
					D.stage--
					if(D.stage < 1)
						D.cure()
				..()
				return
		synaptizine

			name = "Synaptizine"
			id = "synaptizine"
			description = "Synaptizine is used to treat patients suffering from drug addiction and radiation sickness. However, it is extremely slow-metabolizing and toxic."
			reagent_state = LIQUID
			color = "#99CCFF" // rgb: 153, 204, 255
			custom_metabolism = 0.01
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.drowsyness = max(M.drowsyness-5, 0)
				M.AdjustParalysis(-1)
				M.AdjustStunned(-1)
				M.AdjustWeakened(-1)
				holder.remove_reagent("mindbreaker", 5)
				M.hallucination = max(0, M.hallucination - 10)
				if(prob(60))	M.adjustToxLoss(1)
				..()
				return

		impedrezene
			name = "Impedrezene"
			id = "impedrezene"
			description = "Impedrezene is a narcotic drug that slows mental processing by blocking neurotransmitters, severing neuron pathways, and liquefying brain tissue."
			reagent_state = LIQUID
			color = "#7D4B64" // rgb: 125, 75, 100
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.jitteriness = max(M.jitteriness-5,0)
				if(prob(80)) M.adjustBrainLoss(1*REM)
				if(prob(50)) M.drowsyness = max(M.drowsyness, 3)
				if(prob(10)) M.emote("drool", "giggle")
				..()
				return

		hyronalin
			name = "Hyronalin"
			id = "hyronalin"
			description = "Hyronalin is a slow-metabolizing medicinal drug used to counter the effect of radiation poisoning."
			reagent_state = LIQUID
			color = "#408000" // rgb: 64, 128, 0
			custom_metabolism = 0.05
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.radiation = max(M.radiation-3*REM,0)
				..()
				return

		arithrazine
			name = "Arithrazine"
			id = "arithrazine"
			description = "Arithrazine is an unstable medication used for the most extreme cases of radiation poisoning. Causes very minor damage to all organic and synthetic limbs."
			reagent_state = LIQUID
			color = "#006000" // rgb: 0, 96, 0
			custom_metabolism = 0.05
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(M.stat == 2.0)
					return  //See above, down and around. --Agouri
				if(!M) M = holder.my_atom
				M.radiation = max(M.radiation-7*REM,0)
				M.adjustToxLoss(-1*REM)
				if(prob(15))
					M.take_organ_damage(1, 0)
				..()
				return

		alkysine
			name = "Alkysine"
			id = "alkysine"
			description = "Alkysine is a drug used to lessen the damage to neurological tissue after a catastrophic injury. Can heal brain tissue."
			reagent_state = LIQUID
			color = "#FFFF66" // rgb: 255, 255, 102
			custom_metabolism = 0.05
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.adjustBrainLoss(-3*REM)
				..()
				return

		imidazoline
			name = "Imidazoline"
			id = "imidazoline"
			description = "Imidazoline heals most types of eye damage. It works best when it is squirted into the eyes."
			reagent_state = LIQUID
			color = "#C8C8DC" // rgb: 200, 200, 220
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.eye_blurry = max(M.eye_blurry-5 , 0)
				M.eye_blind = max(M.eye_blind-5 , 0)
				if(ishuman(M))
					var/mob/living/carbon/human/H = M
					var/datum/organ/internal/eyes/E = H.internal_organs_by_name["eyes"]
					if(E && istype(E))
						if(E.damage > 0)
							E.damage = max(E.damage - 1, 0)
				..()
				return

		peridaxon
			name = "Peridaxon"
			id = "peridaxon"
			description = "Peridaxon is used to encourage recovery of internal organs and nervous systems. Medicate cautiously."
			reagent_state = LIQUID
			color = "#561EC3" // rgb: 86, 30, 195
			overdose = 10
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(ishuman(M))
					var/mob/living/carbon/human/H = M

					//Peridaxon heals only non-robotic organs
					for(var/datum/organ/internal/I in H.internal_organs)
						if((I.damage > 0) && (I.robotic != 2))
							I.damage = max(I.damage - 0.20, 0)
				..()
				return

		bicaridine
			name = "Bicaridine"
			id = "bicaridine"
			description = "Bicaridine is an analgesic medication, be used to treat blunt trauma."
			reagent_state = LIQUID
			color = "#C80000" // rgb: 200, 000, 000
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob, var/alien)
				if(M.stat == 2.0)
					return
				if(!M) M = holder.my_atom
				if(alien != IS_DIONA)
					M.heal_organ_damage(2*REM,0)
				..()
				return

		hyperzine
			name = "Hyperzine"
			id = "hyperzine"
			description = "Hyperzine is a highly effective, long-lasting muscle stimulant. Someone on this drug may appear to be on hyperzine.."
			reagent_state = LIQUID
			color = "#FF3300" // rgb: 255, 51, 0
			custom_metabolism = 0.03
			overdose = REAGENTS_OVERDOSE/2

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(prob(5)) M.emote(pick("twitch","blink_r","shiver"))
				..()
				return

		adrenaline
			name = "Adrenaline"
			id = "adrenaline"
			description = "Adrenaline is a hormone used as a drug to treat cardiac arrest and other cardiac dysrhythmias resulting in diminished or absent cardiac output."
			reagent_state = LIQUID
			color = "#808080" // rgb: 128, 128, 128

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.SetParalysis(0)
				M.SetWeakened(0)
				M.adjustToxLoss(rand(3))
				..()
				return

		cryoxadone
			name = "Cryoxadone"
			id = "cryoxadone"
			description = "Cryoxadone is a chemical mixture with properties that heal all types of external damage. Its main limitation is that the target's body temperature must be under 170K for it to metabolize correctly."
			reagent_state = LIQUID
			color = "#8080FF" // rgb: 128, 128, 255
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(M.bodytemperature < 170)
					M.adjustCloneLoss(-1)
					M.adjustOxyLoss(-1)
					M.heal_organ_damage(1,1)
					M.adjustToxLoss(-1)
				..()
				return

		clonexadone
			name = "Clonexadone"
			id = "clonexadone"
			description = "Clonexadone is a chemical mixture with the exact properties of cryoxadone, but it is twice as potent. It can be used to 'finish' the cloning process when used in conjunction with a cryo tube, or rapidly heal many types of external damage."
			reagent_state = LIQUID
			color = "#80BFFF" // rgb: 128, 191, 255
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(M.bodytemperature < 170)
					M.adjustCloneLoss(-3)
					M.adjustOxyLoss(-3)
					M.heal_organ_damage(3,3)
					M.adjustToxLoss(-3)
				..()
				return

		rezadone
			name = "Rezadone"
			id = "rezadone"
			description = "Rezadone is a powder derived from fish toxin. This substance can effectively treat genetic damage in humanoids, though excessive consumption has side effects."
			reagent_state = SOLID
			color = "#669900" // rgb: 102, 153, 0
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(!data) data = 1
				data++
				switch(data)
					if(1 to 15)
						M.adjustCloneLoss(-1)
						M.heal_organ_damage(1,1)
					if(15 to 35)
						M.adjustCloneLoss(-2)
						M.heal_organ_damage(2,1)
						M.status_flags &= ~DISFIGURED
					if(35 to INFINITY)
						M.adjustToxLoss(1)
						M.make_dizzy(5)
						M.make_jittery(5)

				..()
				return

		spaceacillin
			name = "Spaceacillin"
			id = "spaceacillin"
			description = "Spaceacillin is a slow-metabolizing, an all-purpose antiviral, and an all-purpose beta-lactam antibiotic. It treats infections, slows down the progression of viruses and halts transmission of viruses"
			reagent_state = LIQUID
			color = "#C1C1C1" // rgb: 193, 193, 193
			custom_metabolism = 0.01
			overdose = REAGENTS_OVERDOSE
			scannable = 1

			on_mob_life(var/mob/living/M as mob)
				..()
				return


///////////////////////////////////////////////////////////////////////////////////////////////////////////////

		nanites
			name = "Nanomachines"
			id = "nanites"
			description = "Nanomachines are construction robots."
			reagent_state = LIQUID
			color = "#535E66" // rgb: 83, 94, 102

			reaction_mob(var/mob/M, var/method=TOUCH, var/volume)
				src = null
				if( (prob(10) && method==TOUCH) || method==INGEST)
					M.contract_disease(new /datum/disease/robotic_transformation(0),1)

		xenomicrobes
			name = "Xenomicrobes"
			id = "xenomicrobes"
			description = "Xenomicrobes are microbes with an entirely alien cellular structure."
			reagent_state = LIQUID
			color = "#535E66" // rgb: 83, 94, 102

			reaction_mob(var/mob/M, var/method=TOUCH, var/volume)
				src = null
				if( (prob(10) && method==TOUCH) || method==INGEST)
					M.contract_disease(new /datum/disease/xeno_transformation(0),1)

		fluorosurfactant//foam precursor
			name = "Fluorosurfactant"
			id = "fluorosurfactant"
			description = "Flurosurfactants are synthetic organofluroine chemical compounds with multiple fluorine atoms. They are surfactants and are effective at lowering surface tension by creating a thick foam."
			reagent_state = LIQUID
			color = "#9E6B38" // rgb: 158, 107, 56

		foaming_agent// Metal foaming agent. This is lithium hydride. Add other recipes (e.g. LiH + H2O -> LiOH + H2) eventually.
			name = "Foaming agent"
			id = "foaming_agent"
			description = "Foaming agent is an agent that yields metallic foam when mixed with light metal and a strong acid."
			reagent_state = SOLID
			color = "#664B63" // rgb: 102, 75, 99

		nicotine
			name = "Nicotine"
			id = "nicotine"
			description = "Nicotine is a potent parasympathomimetic alkaloid found in the roots and leaves in the nightshade family of plants. It is an addictive stimulant drug."
			reagent_state = LIQUID
			color = "#181818" // rgb: 24, 24, 24

		ammonia
			name = "Ammonia"
			id = "ammonia"
			description = "Ammonia is a compound of nitrogen and hydrogen with the formula NH3. It is a colorless gas with a pungent chemical odor. It serves as a precursor to food and fertilizers for terrestrial organismms, or it can be used as a household cleaner."
			reagent_state = GAS
			color = "#404030" // rgb: 64, 64, 48

		ultraglue
			name = "Ultra Glue"
			id = "glue"
			description = "Ultraglue is an extremely powerful bonding agent."
			color = "#FFFFCC" // rgb: 255, 255, 204

		diethylamine
			name = "Diethylamine"
			id = "diethylamine"
			description = "Diethylamine is a secondary amine with the molecular structure of C4H11N. It is a flammable, volatile, corrosive, weakly alkaline liquid, soluble in water and ethanol, and has unpleasant odor."
			reagent_state = LIQUID
			color = "#604030" // rgb: 96, 64, 48

		ethylredoxrazine	// FUCK YOU, ALCOHOL
			name = "Ethylredoxrazine"
			id = "ethylredoxrazine"
			description = "A powerful oxidizer that reacts with ethanol to neutralize alcohol in the bloodstream. "
			reagent_state = SOLID
			color = "#605048" // rgb: 96, 80, 72
			overdose = REAGENTS_OVERDOSE
			scannable = 1
			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.dizziness = 0
				M.drowsyness = 0
				M.stuttering = 0
				M.confused = 0
				M.reagents.remove_all_type(/datum/reagent/ethanol, 1*REM, 0, 1)
				..()
				return

//////////////////////////Poison stuff///////////////////////

		toxin
			name = "Toxin"
			id = "toxin"
			description = "Originally classified as a poisonous substance produced by living cells and organism, synthetic toxicants created by artificial processes are included."
			reagent_state = LIQUID
			color = "#CF3600" // rgb: 207, 54, 0
			var/toxpwr = 0.7 // Toxins are really weak, but without being treated, last very long.
			custom_metabolism = 0.1

			on_mob_life(var/mob/living/M as mob,var/alien)
				if(!M) M = holder.my_atom
				if(toxpwr)
					M.adjustToxLoss(toxpwr*REM)
				if(alien) ..() // Kind of a catch-all for aliens without the liver. Because this does not metabolize 'naturally', only removed by the liver.
				return

		toxin/amatoxin
			name = "Amatoxin"
			id = "amatoxin"
			description = "Amatoxins are a subgroup of eight toxic compounds found in several genera of poisonous mushrooms, one of them is notably of the genus Amanita."
			reagent_state = LIQUID
			color = "#792300" // rgb: 121, 35, 0
			toxpwr = 1

		toxin/mutagen
			name = "Unstable mutagen"
			id = "mutagen"
			description = "Unstable mutagen generates mutations by interrupting DNA-copying mechanisms and breaking down DNA to the point where cells do not repair DNA well enough to make an exact copy."
			reagent_state = LIQUID
			color = "#13BC5E" // rgb: 19, 188, 94
			toxpwr = 0

			reaction_mob(var/mob/living/carbon/M, var/method=TOUCH, var/volume)
				if(!..())	return
				if(!istype(M) || !M.dna)	return  //No robots, AIs, aliens, Ians or other mobs should be affected by this.
				src = null
				if((method==TOUCH && prob(33)) || method==INGEST)
					randmuti(M)
					if(prob(98))	randmutb(M)
					else			randmutg(M)
					domutcheck(M, null)
					M.UpdateAppearance()
				return
			on_mob_life(var/mob/living/carbon/M)
				if(!istype(M))	return
				if(!M) M = holder.my_atom
				M.apply_effect(10,IRRADIATE,0)
				..()
				return

		toxin/phoron
			name = "Phoron"
			id = "phoron"
			description = "Phoron is a highly-valuable, stable form of Tritiated Ethanol that exists both in the universe and Bluespace, simultaneously. It can utilize FTL travel, create scientifically-impossible catalyctic reactions, and it is highly reactive to a myriad of substances. It is currently in its liquid form, but as an ionized gas, it can burn and stay hot for remarkably extensive periods of time."
			reagent_state = LIQUID
			color = "#9D14DB"
			toxpwr = 3

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				holder.remove_reagent("inaprovaline", 2*REM)
				..()
				return
			reaction_obj(var/obj/O, var/volume)
				src = null
				/*if(istype(O,/obj/item/weapon/reagent_containers/food/snacks/egg/slime))
					var/obj/item/weapon/reagent_containers/food/snacks/egg/slime/egg = O
					if (egg.grown)
						egg.Hatch()*/
				if((!O) || (!volume))	return 0
				var/turf/the_turf = get_turf(O)
				the_turf.assume_gas("volatile_fuel", volume, T20C)
			reaction_turf(var/turf/T, var/volume)
				src = null
				T.assume_gas("volatile_fuel", volume, T20C)
				return

		toxin/lexorin
			name = "Lexorin"
			id = "lexorin"
			description = "Lexorin is a narcotic that blocks neuron pathways' signals to the lungs to breathe. It stops respiration and causes tissue damage."
			reagent_state = LIQUID
			color = "#C8A5DC" // rgb: 200, 165, 220
			toxpwr = 0
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(M.stat == 2.0)
					return
				if(!M) M = holder.my_atom
				if(prob(33))
					M.take_organ_damage(1*REM, 0)
				if(M.losebreath < 15)
					M.losebreath++
				..()
				return

		toxin/slimejelly
			name = "Slime Jelly"
			id = "slimejelly"
			description = "Slime jelly is a gooey semi-liquid produced from one of the deadliest lifeforms in existence. Mixed with phoron, it can have a variety of reactions based on the type of slime the jelly came from."
			reagent_state = LIQUID
			color = "#801E28" // rgb: 128, 30, 40
			toxpwr = 0

			on_mob_life(var/mob/living/M as mob)
				if(prob(10))
					M << "\red Your insides are burning!"
					M.adjustToxLoss(rand(20,60)*REM)
				else if(prob(40))
					M.heal_organ_damage(5*REM,0)
				..()
				return

		toxin/cyanide //Fast and Lethal
			name = "Cyanide"
			id = "cyanide"
			description = "Cyanide is a chemical compound from the monovalent cyano group. This organic nitrite is colorless, crystalline, similar to appearance to sugar, highly soluble in water, and one of the most toxic substances known. To some people, it smells like bitter almonds."
			color = "#CF3600" // rgb: 207, 54, 0
			toxpwr = 4
			custom_metabolism = 0.4

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.adjustOxyLoss(4*REM)
				M.sleeping += 1
				..()
				return

		toxin/minttoxin
			name = "Mint Toxin"
			id = "minttoxin"
			description = "Mint toxin is an aggressive fat-busting toxin that derives from a certain kind of mint."
			reagent_state = LIQUID
			color = "#CF3600" // rgb: 207, 54, 0
			toxpwr = 0

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if (FAT in M.mutations)
					M.gib()
				..()
				return

		toxin/carpotoxin
			name = "Carpotoxin"
			id = "carpotoxin"
			description = "Carpotoxin is a deadly neurotoxin naturally found in the tissues of or Space Carp."
			reagent_state = LIQUID
			color = "#003333" // rgb: 0, 51, 51
			toxpwr = 2

		toxin/zombiepowder
			name = "Zombie Powder"
			id = "zombiepowder"
			description = "Stronger than Curare, Zombie Powder is a strong neurotoxin that completely paralyzes the patient; the patient will appear to be in a death-like state, visually and by scanners, but the patient will be aware of his or her surroundings."
			reagent_state = SOLID
			color = "#669900" // rgb: 102, 153, 0
			toxpwr = 0.5

			on_mob_life(var/mob/living/carbon/M as mob)
				if(!M) M = holder.my_atom
				M.status_flags |= FAKEDEATH
				M.adjustOxyLoss(0.5*REM)
				M.Weaken(10)
				M.silent = max(M.silent, 10)
				M.tod = worldtime2text()
				..()
				return

			Del()
				if(holder && ismob(holder.my_atom))
					var/mob/M = holder.my_atom
					M.status_flags &= ~FAKEDEATH
				..()

		toxin/mindbreaker
			name = "Mindbreaker Toxin"
			id = "mindbreaker"
			description = "A more powerful variant of LSD, Mindbreaker Toxin is a powerful hallucinogen that assaults and tricks the mind to generate frightening visual and auditory, and tactile hallucinations."
			reagent_state = LIQUID
			color = "#B31008" // rgb: 139, 166, 233
			toxpwr = 0.5 // Fuck you, chemists. You ingest this shit, you pay for it.
			custom_metabolism = 0.05
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M)
				if(!M) M = holder.my_atom
				M.hallucination += 10
				..()
				return

		//Reagents used for plant fertilizers.
		toxin/fertilizer
			name = "fertilizer"
			id = "fertilizer"
			description = "Fertilizer is a chemical mixture derived from decomposing plant and animal matter and animal dung. It provides nutrition to plants to help them grow."
			reagent_state = LIQUID
			toxpwr = 0.2 //It's not THAT poisonous.
			color = "#664330" // rgb: 102, 67, 48

		toxin/fertilizer/eznutrient
			name = "EZ Nutrient"
			id = "eznutrient"
			description = "Fertilizer is a standard chemical mixture for providing nutrients to plants. Around dead plants, there is a higher chance mushrooms will grow in their place."
			color = "#7A3E1D" // rgb: 122, 62, 29

		toxin/fertilizer/left4zed
			name = "Left-4-Zed"
			description = "Left-4-Zed is a chemical mixture that doubles the chance of a mutation of a plant at the cost of yield and potency chance. Around dead plants, there is a higher chance more deadly mushrooms will grow in their place."
			id = "left4zed"
			color = "#A346A3" // rgb: 163, 70, 163

		toxin/fertilizer/robustharvest
			name = "Robust Harvest"
			id = "robustharvest"
			description = "Robust Harvest is a chemical mixture that mutates a gene in the DNA of plants responsible for the minimum amount of possible produce each harvest, resulting in double the amount of produce harvested. Around dead plants, there is a higher chance psychotropic mushrooms will take their place."
			color = "#800040" // rgb: 128, 0, 64

		toxin/plantbgone
			name = "Plant-B-Gone"
			id = "plantbgone"
			description = "Plant-B-Gone is a brand of herbicide that is very toxic to plants."
			reagent_state = LIQUID
			color = "#49002E" // rgb: 73, 0, 46
			toxpwr = 1

			// Clear off wallrot fungi
			reaction_turf(var/turf/T, var/volume)
				if(istype(T, /turf/simulated/wall))
					var/turf/simulated/wall/W = T
					if(W.rotting)
						W.rotting = 0
						for(var/obj/effect/E in W) if(E.name == "Wallrot") del E

						for(var/mob/O in viewers(W, null))
							O.show_message(text("\blue The fungi are completely dissolved by the solution!"), 1)

			reaction_obj(var/obj/O, var/volume)
				if(istype(O,/obj/effect/alien/weeds/))
					var/obj/effect/alien/weeds/alien_weeds = O
					alien_weeds.health -= rand(15,35) // Kills alien weeds pretty fast
					alien_weeds.healthcheck()
				else if(istype(O,/obj/effect/glowshroom)) //even a small amount is enough to kill it
					del(O)
				else if(istype(O,/obj/effect/plantsegment))
					if(prob(50)) del(O) //Kills kudzu too.
				else if(istype(O,/obj/machinery/portable_atmospherics/hydroponics))
					var/obj/machinery/portable_atmospherics/hydroponics/tray = O

					if(tray.seed)
						tray.health -= rand(30,50)
						if(tray.pestlevel > 0)
							tray.pestlevel -= 2
						if(tray.weedlevel > 0)
							tray.weedlevel -= 3
						tray.toxins += 4
						tray.check_level_sanity()
						tray.update_icon()

			reaction_mob(var/mob/living/M, var/method=TOUCH, var/volume)
				src = null
				if(iscarbon(M))
					var/mob/living/carbon/C = M
					if(!C.wear_mask) // If not wearing a mask
						C.adjustToxLoss(2) // 4 toxic damage per application, doubled for some reason
					if(ishuman(M))
						var/mob/living/carbon/human/H = M
						if(H.dna)
							if(H.species.flags & IS_PLANT) //plantmen take a LOT of damage
								H.adjustToxLoss(50)

		toxin/stoxin
			name = "Soporific"
			id = "stoxin"
			description = "Soporific drugs, more commonly known as sleeping pills or hypnotics, are a class of psychoactive drugs primarily used to induce sleep and to be used to treat insomnia and to assist in surgical anesthesia."
			reagent_state = LIQUID
			color = "#009CA8" // rgb: 232, 149, 204
			toxpwr = 0
			custom_metabolism = 0.1
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(!data) data = 1
				switch(data)
					if(1 to 12)
						if(prob(5))	M.emote("yawn")
					if(12 to 15)
						M.eye_blurry = max(M.eye_blurry, 10)
					if(15 to 49)
						if(prob(50))
							M.Weaken(2)
						M.drowsyness = max(M.drowsyness, 20)
					if(50 to INFINITY)
						M.sleeping = max(M.sleeping, 20)
						M.drowsyness = max(M.drowsyness, 60)
				data++
				..()
				return

		toxin/chloralhydrate
			name = "Chloral Hydrate"
			id = "chloralhydrate"
			description = "Chloral hydrate is an organic, toxic compound with the chemical formula C2H3Cl3O2, used as a strong sedative and hypnotic pharmaceutical drug. Normally a colorless solid, it was pre-dyed blue and pre-liquified for easy identification."
			reagent_state = SOLID
			color = "#000067" // rgb: 0, 0, 103
			toxpwr = 1
			custom_metabolism = 0.1 //Default 0.2
			overdose = 15
			overdose_dam = 5

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(!data) data = 1
				data++
				switch(data)
					if(1)
						M.confused += 2
						M.drowsyness += 2
					if(2 to 20)
						M.Weaken(30)
						M.eye_blurry = max(M.eye_blurry, 10)
					if(20 to INFINITY)
						M.sleeping = max(M.sleeping, 30)
				..()
				return

		toxin/potassium_chloride
			name = "Potassium Chloride"
			id = "potassium_chloride"
			description = "Potassium chloride is a white, odorless, water-soluble metal halide salt with a vitreous-crystal appearance and a taste very similar to sodium chloride. Upon ingestion, it will cause cardiac arrest."
			reagent_state = SOLID
			color = "#FFFFFF" // rgb: 255,255,255
			toxpwr = 0
			overdose = 30

			on_mob_life(var/mob/living/carbon/M as mob)
				var/mob/living/carbon/human/H = M
				if(H.stat != 1)
					if (volume >= overdose)
						if(H.losebreath >= 10)
							H.losebreath = max(10, H.losebreath-10)
						H.adjustOxyLoss(2)
						H.Weaken(10)
				..()
				return

		toxin/potassium_chlorophoride //How is this different from potassium chloride?
			name = "Potassium Chlorophoride"
			id = "potassium_chlorophoride"
			description = "Potassium chlorophoride is a a white, odorless, water-soluble metal halide salt with a vitreous-crystal appearance and a taste vaguely similar to sodium chloride. It is used to stop the heart during surgery." //There was absolutely no difference from this to potassium chloride, so I weakened it to make it 'seem' like a medicine.
			reagent_state = SOLID
			color = "#FFFFFF" // rgb: 255,255,255
			toxpwr = 2
			overdose = 20

			on_mob_life(var/mob/living/carbon/M as mob)
				if(ishuman(M))
					var/mob/living/carbon/human/H = M
					if(H.stat != 1)
						if(H.losebreath >= 5)
							H.losebreath = max(5, M.losebreath-5)
						H.adjustOxyLoss(1)
						H.Weaken(5)
				..()
				return

		toxin/beer2	//disguised as normal beer for use by emagged brobots
			name = "Beer"
			id = "beer2"
			description = "Beer is a mild alcoholic beverage made by brewing malted grains, hops, yeast, and water. The fermentation appears to be incomplete." //If the players manage to analyze this, they deserve to know something is wrong.
			reagent_state = LIQUID
			color = "#664300" // rgb: 102, 67, 0
			custom_metabolism = 0.15 // Sleep toxins should always be consumed pretty fast
			overdose = REAGENTS_OVERDOSE/2

			glass_icon_state = "beerglass"
			glass_name = "glass of beer"
			glass_desc = "A freezing pint of beer"
			glass_center_of_mass = list("x"=16, "y"=8)

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(!data) data = 1
				switch(data)
					if(1)
						M.confused += 2
						M.drowsyness += 2
					if(2 to 50)
						M.sleeping += 1
					if(51 to INFINITY)
						M.sleeping += 1
						M.adjustToxLoss((data - 50)*REM)
				data++
				..()
				return

		toxin/acid
			name = "Sulfuric acid"
			id = "sacid"
			description = "Sulfuric acid is a highly corrosive strong mineral acid with the molecular formula H2SO4. It is a pungent-ethereal, colorless to slightly yellow, viscous liquid which is soluble in water."
			reagent_state = LIQUID
			color = "#DB5008" // rgb: 219, 80, 8  //This should be a white-yellow, but it's orange.
			toxpwr = 1
			var/meltprob = 10

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.take_organ_damage(0, 1*REM)
				..()
				return

			reaction_mob(var/mob/living/M, var/method=TOUCH, var/volume)//magic numbers everywhere
				if(!istype(M, /mob/living))
					return
				if(method == TOUCH)
					if(ishuman(M))
						var/mob/living/carbon/human/H = M

						if(H.head)
							if(prob(meltprob) && !H.head.unacidable)
								H << "<span class='danger'>Your headgear melts away but protects you from the acid!</span>"
								del(H.head)
								H.update_inv_head(0)
								H.update_hair(0)
							else
								H << "<span class='warning'>Your headgear protects you from the acid.</span>"
							return

						if(H.wear_mask)
							if(prob(meltprob) && !H.wear_mask.unacidable)
								H << "<span class='danger'>Your mask melts away but protects you from the acid!</span>"
								del (H.wear_mask)
								H.update_inv_wear_mask(0)
								H.update_hair(0)
							else
								H << "<span class='warning'>Your mask protects you from the acid.</span>"
							return

						if(H.glasses) //Doesn't protect you from the acid but can melt anyways!
							if(prob(meltprob) && !H.glasses.unacidable)
								H << "<span class='danger'>Your glasses melts away!</span>"
								del (H.glasses)
								H.update_inv_glasses(0)

					else if(ismonkey(M))
						var/mob/living/carbon/monkey/MK = M
						if(MK.wear_mask)
							if(!MK.wear_mask.unacidable)
								MK << "<span class='danger'>Your mask melts away but protects you from the acid!</span>"
								del (MK.wear_mask)
								MK.update_inv_wear_mask(0)
							else
								MK << "<span class='warning'>Your mask protects you from the acid.</span>"
							return

					if(!M.unacidable)
						if(istype(M, /mob/living/carbon/human) && volume >= 10)
							var/mob/living/carbon/human/H = M
							var/datum/organ/external/affecting = H.get_organ("head")
							if(affecting)
								if(affecting.take_damage(4*toxpwr, 2*toxpwr))
									H.UpdateDamageIcon()
								if(prob(meltprob)) //Applies disfigurement
									if (!(H.species && (H.species.flags & NO_PAIN)))
										H.emote("scream")
									H.status_flags |= DISFIGURED
						else
							M.take_organ_damage(min(6*toxpwr, volume * toxpwr)) // uses min() and volume to make sure they aren't being sprayed in trace amounts (1 unit != insta rape) -- Doohl
				else
					if(!M.unacidable)
						M.take_organ_damage(min(6*toxpwr, volume * toxpwr))

			reaction_obj(var/obj/O, var/volume)
				if((istype(O,/obj/item) || istype(O,/obj/effect/glowshroom)) && prob(meltprob * 3))
					if(!O.unacidable)
						var/obj/effect/decal/cleanable/molten_item/I = new/obj/effect/decal/cleanable/molten_item(O.loc)
						I.desc = "Looks like this was \an [O] some time ago."
						for(var/mob/M in viewers(5, O))
							M << "\red \the [O] melts."
						del(O)

		toxin/acid/polyacid
			name = "Polytrinic acid"
			id = "pacid"
			description = "Polytrinic acid is a an extremely corrosive chemical substance which can melt almost anything completely to a grey mass of goo."
			reagent_state = LIQUID
			color = "#8E18A9" // rgb: 142, 24, 169
			toxpwr = 2
			meltprob = 30

/////////////////////////Food Reagents////////////////////////////
// Part of the food code. Nutriment is used instead of the old "heal_amt" code. Also is where all the food
// 	condiments, additives, and such go.
		nutriment
			name = "Nutriment"
			id = "nutriment"
			description = "All the vitamins, minerals, and carbohydrates the body needs in pure form."
			reagent_state = SOLID
			nutriment_factor = 15 * REAGENTS_METABOLISM
			color = "#664330" // rgb: 102, 67, 48

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				if(prob(50)) M.heal_organ_damage(1,0)
				M.nutrition += nutriment_factor	// For hunger and fatness
/*
				// If overeaten - vomit and fall down
				// Makes you feel bad but removes reagents and some effect
				// from your body
				if (M.nutrition > 650)
					M.nutrition = rand (250, 400)
					M.weakened += rand(2, 10)
					M.jitteriness += rand(0, 5)
					M.dizziness = max (0, (M.dizziness - rand(0, 15)))
					M.druggy = max (0, (M.druggy - rand(0, 15)))
					M.adjustToxLoss(rand(-15, -5)))
					M.updatehealth()
*/
				..()
				return

		nutriment/protein // Bad for Skrell!
			name = "animal protein"
			description = "Animal protein is protein derived from the skin, flesh, and bones from animals."
			id = "protein"
			color = "#440000" // rgb: 68, 0, 0

			on_mob_life(var/mob/living/M, var/alien)
				if(alien && alien == IS_SKRELL)
					M.adjustToxLoss(0.5)
					M.nutrition -= nutriment_factor
				..()

		nutriment/egg // Also bad for Skrell. Not a child of protein because it might mess up, not sure.
			name = "egg yolk"
			description = "Egg yolk is the nutritious part of the egg that feeds a developing embryo in some animals. This one came from a chicken."
			id = "egg"
			color = "#FF9600" // rgb: 255, 150, 0

			on_mob_life(var/mob/living/M, var/alien)
				if(alien && alien == IS_SKRELL)
					M.adjustToxLoss(0.5)
					M.nutrition -= nutriment_factor
				..()

		lipozine
			name = "Lipozine" // The anti-nutriment.
			id = "lipozine"
			description = "Lipozine is a chemical compound derived from herbs that causes a powerful fat-burning reaction."
			reagent_state = LIQUID
			nutriment_factor = 10 * REAGENTS_METABOLISM
			color = "#BBEDA4" // rgb: 187, 237, 164
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.nutrition = max(M.nutrition - nutriment_factor, 0)
				M.overeatduration = 0
				if(M.nutrition < 0)//Prevent from going into negatives.
					M.nutrition = 0
				..()
				return

		soysauce
			name = "Soysauce"
			id = "soysauce"
			description = "Soysauce is a salty sauce made from the soy plant."
			reagent_state = LIQUID
			nutriment_factor = 2 * REAGENTS_METABOLISM
			color = "#792300" // rgb: 121, 35, 0

		ketchup
			name = "Ketchup"
			id = "ketchup"
			description = "Ketchup is a red, sweet, and tangy condiment made from tomato paste, commonly put on burgers, ketchup "
			reagent_state = LIQUID
			nutriment_factor = 5 * REAGENTS_METABOLISM
			color = "#731008" // rgb: 115, 16, 8

		capsaicin
			name = "Capsaicin Oil"
			id = "capsaicin"
			description = "Capsaicin oil is a colorless oil and an active component of chili peppers which induces a sensation of burning on the tissues of most animals, with avian-like creatures as one of the exceptions."
			reagent_state = LIQUID
			color = "#B31008" // rgb: 179, 16, 8

			on_mob_life(var/mob/living/M as mob)
				if(!M)
					M = holder.my_atom
				if(!data)
					data = 1
				if(ishuman(M))
					var/mob/living/carbon/human/H = M
					if(H.species && !(H.species.flags & (NO_PAIN | IS_SYNTHETIC)) )
						switch(data)
							if(1 to 2)
								H << "\red <b>Your insides feel uncomfortably hot !</b>"
							if(2 to 20)
								if(prob(5))
									H << "\red <b>Your insides feel uncomfortably hot !</b>"
							if(20 to INFINITY)
								H.apply_effect(2,AGONY,0)
								if(prob(5))
									H.visible_message("<span class='warning'>[H] [pick("dry heaves!","coughs!","splutters!")]</span>")
									H << "\red <b>You feel like your insides are burning !</b>"
				else if(istype(M, /mob/living/carbon/slime))
					M.bodytemperature += rand(10,25)
				holder.remove_reagent("frostoil", 5)
				holder.remove_reagent(src.id, FOOD_METABOLISM)
				data++
				..()
				return

		condensedcapsaicin
			name = "Condensed Capsaicin"
			id = "condensedcapsaicin"
			description = "This chemical compound is a more-condensed form of capsaicin as a chemical agent used for self-defense and in police work."
			reagent_state = LIQUID
			color = "#B31008" // rgb: 179, 16, 8

			reaction_mob(var/mob/living/M, var/method=TOUCH, var/volume)
				if(!istype(M, /mob/living))
					return
				if(method == TOUCH)
					if(istype(M, /mob/living/carbon/human))
						var/mob/living/carbon/human/victim = M
						var/mouth_covered = 0
						var/eyes_covered = 0
						var/obj/item/safe_thing = null
						if( victim.wear_mask )
							if ( victim.wear_mask.flags & MASKCOVERSEYES )
								eyes_covered = 1
								safe_thing = victim.wear_mask
							if ( victim.wear_mask.flags & MASKCOVERSMOUTH )
								mouth_covered = 1
								safe_thing = victim.wear_mask
						if( victim.head )
							if ( victim.head.flags & MASKCOVERSEYES )
								eyes_covered = 1
								safe_thing = victim.head
							if ( victim.head.flags & MASKCOVERSMOUTH )
								mouth_covered = 1
								safe_thing = victim.head
						if(victim.glasses)
							eyes_covered = 1
							if ( !safe_thing )
								safe_thing = victim.glasses
						if ( eyes_covered && mouth_covered )
							victim << "\red Your [safe_thing] protects you from the pepperspray!"
							return
						else if ( eyes_covered )	// Reduced effects if partially protected
							victim << "\red Your [safe_thing] protect you from most of the pepperspray!"
							victim.eye_blurry = max(M.eye_blurry, 15)
							victim.eye_blind = max(M.eye_blind, 5)
							victim.Stun(5)
							victim.Weaken(5)
							//victim.Paralyse(10)
							//victim.drop_item()
							return
						else if ( mouth_covered ) // Mouth cover is better than eye cover
							victim << "\red Your [safe_thing] protects your face from the pepperspray!"
							if (!(victim.species && (victim.species.flags & NO_PAIN)))
								victim.emote("scream")
							victim.eye_blurry = max(M.eye_blurry, 5)
							return
						else // Oh dear :D
							if (!(victim.species && (victim.species.flags & NO_PAIN)))
								victim.emote("scream")
							victim << "\red You're sprayed directly in the eyes with pepperspray!"
							victim.eye_blurry = max(M.eye_blurry, 25)
							victim.eye_blind = max(M.eye_blind, 10)
							victim.Stun(5)
							victim.Weaken(5)
							//victim.Paralyse(10)
							//victim.drop_item()

			on_mob_life(var/mob/living/M as mob)
				if(!M)
					M = holder.my_atom
				if(!data)
					data = 1
				if(ishuman(M))
					var/mob/living/carbon/human/H = M
					if(H.species && !(H.species.flags & (NO_PAIN | IS_SYNTHETIC)) )
						switch(data)
							if(1)
								H << "\red <b>You feel like your insides are burning !</b>"
							if(2 to INFINITY)
								H.apply_effect(4,AGONY,0)
								if(prob(5))
									H.visible_message("<span class='warning'>[H] [pick("dry heaves!","coughs!","splutters!")]</span>")
									H << "\red <b>You feel like your insides are burning !</b>"
				else if(istype(M, /mob/living/carbon/slime))
					M.bodytemperature += rand(15,30)
				holder.remove_reagent("frostoil", 5)
				holder.remove_reagent(src.id, FOOD_METABOLISM)
				data++
				..()
				return

		frostoil
			name = "Frost Oil"
			id = "frostoil"
			description = "Frost oil is a special oil extracted from ice peppers that noticeably chills the body."
			reagent_state = LIQUID
			color = "#B31008" // rgb: 139, 166, 233

			on_mob_life(var/mob/living/M as mob)
				if(!M)
					M = holder.my_atom
				M.bodytemperature = max(M.bodytemperature - 10 * TEMPERATURE_DAMAGE_COEFFICIENT, 0)
				if(prob(1))
					M.emote("shiver")
				if(istype(M, /mob/living/carbon/slime))
					M.bodytemperature = max(M.bodytemperature - rand(10,20), 0)
				holder.remove_reagent("capsaicin", 5)
				holder.remove_reagent(src.id, FOOD_METABOLISM)
				..()
				return

			reaction_turf(var/turf/simulated/T, var/volume)
				for(var/mob/living/carbon/slime/M in T)
					M.adjustToxLoss(rand(15,30))

		sodiumchloride
			name = "Table Salt"
			id = "sodiumchloride"
			description = "Table salt is a gritty, crystalline condiment, chemically known as sodium chloride. It is used to season food."
			reagent_state = SOLID
			color = "#FFFFFF" // rgb: 255,255,255
			overdose = REAGENTS_OVERDOSE

		blackpepper
			name = "Black Pepper"
			id = "blackpepper"
			description = "Black pepper is a condiment derived from ground peppercorns. It is used to season food, but it makes people sneeze when inhaled."
			reagent_state = SOLID
			// no color (ie, black)

		coco
			name = "Coco Powder"
			id = "coco"
			description = "Coco powder is a fatty, bitter paste made from ground coco beans."
			reagent_state = SOLID
			nutriment_factor = 5 * REAGENTS_METABOLISM
			color = "#302000" // rgb: 48, 32, 0

			on_mob_life(var/mob/living/M as mob)
				M.nutrition += nutriment_factor
				..()
				return

		hot_coco // there's also drink/hot_coco for whatever reason
			name = "Hot Chocolate"
			id = "hot_coco"
			description = "Hot chocolate is a hot, sweet, chocolaty drink made from ground cocoa beans and sometimes milk."
			reagent_state = LIQUID
			nutriment_factor = 2 * REAGENTS_METABOLISM
			color = "#403010" // rgb: 64, 48, 16

			glass_icon_state  = "chocolateglass"
			glass_name = "glass of hot chocolate"
			glass_desc = "Made with love! And cocoa beans."

			on_mob_life(var/mob/living/M as mob)
				if (M.bodytemperature < 310)//310 is the normal bodytemp. 310.055
					M.bodytemperature = min(310, M.bodytemperature + (5 * TEMPERATURE_DAMAGE_COEFFICIENT))
				M.nutrition += nutriment_factor
				..()
				return

		psilocybin
			name = "Psilocybin"
			id = "psilocybin"
			description = "Psilocybin strong psychotropic derived from certain species of mushroom."
			color = "#E700E7" // rgb: 231, 0, 231
			overdose = REAGENTS_OVERDOSE

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.druggy = max(M.druggy, 30)
				if(!data) data = 1
				switch(data)
					if(1 to 5)
						if (!M.stuttering) M.stuttering = 1
						M.make_dizzy(5)
						if(prob(10)) M.emote(pick("twitch","giggle"))
					if(5 to 10)
						if (!M.stuttering) M.stuttering = 1
						M.make_jittery(10)
						M.make_dizzy(10)
						M.druggy = max(M.druggy, 35)
						if(prob(20)) M.emote(pick("twitch","giggle"))
					if (10 to INFINITY)
						if (!M.stuttering) M.stuttering = 1
						M.make_jittery(20)
						M.make_dizzy(20)
						M.druggy = max(M.druggy, 40)
						if(prob(30)) M.emote(pick("twitch","giggle"))
				holder.remove_reagent(src.id, 0.2)
				data++
				..()
				return

		sprinkles
			name = "Sprinkles"
			id = "sprinkles"
			description = "Sprinkles are multi-colored bits of sugary confections commonly sprinkled on pastries for aesthetics and taste."
			nutriment_factor = 1 * REAGENTS_METABOLISM
			color = "#FF00FF" // rgb: 255, 0, 255

			on_mob_life(var/mob/living/M as mob)
				M.nutrition += nutriment_factor
				/*if(istype(M, /mob/living/carbon/human) && M.job in list("Security Officer", "Head of Security", "Detective", "Warden"))
					if(!M) M = holder.my_atom
					M.heal_organ_damage(1,1)
					M.nutrition += nutriment_factor
					..()
					return
				*/
				..()

/*	//removed because of meta bullshit. this is why we can't have nice things.
		syndicream
			name = "Cream filling"
			id = "syndicream"
			description = "Delicious cream filling of a mysterious origin. Tastes criminally good."
			nutriment_factor = 1 * REAGENTS_METABOLISM
			color = "#AB7878" // rgb: 171, 120, 120

			on_mob_life(var/mob/living/M as mob)
				M.nutrition += nutriment_factor
				if(istype(M, /mob/living/carbon/human) && M.mind)
					if(M.mind.special_role)
						if(!M) M = holder.my_atom
						M.heal_organ_damage(1,1)
						M.nutrition += nutriment_factor
						..()
						return
				..()
*/
		cornoil
			name = "Corn Oil"
			id = "cornoil"
			description = "Corn oil is an oil extracted from various types of corn."
			reagent_state = LIQUID
			nutriment_factor = 20 * REAGENTS_METABOLISM
			color = "#302000" // rgb: 48, 32, 0

			on_mob_life(var/mob/living/M as mob)
				M.nutrition += nutriment_factor
				..()
				return
			reaction_turf(var/turf/simulated/T, var/volume)
				if (!istype(T)) return
				src = null
				if(volume >= 3)
					if(T.wet >= 1) return
					T.wet = 1
					if(T.wet_overlay)
						T.overlays -= T.wet_overlay
						T.wet_overlay = null
					T.wet_overlay = image('icons/effects/water.dmi',T,"wet_floor")
					T.overlays += T.wet_overlay

					spawn(800)
						if (!istype(T)) return
						if(T.wet >= 2) return
						T.wet = 0
						if(T.wet_overlay)
							T.overlays -= T.wet_overlay
							T.wet_overlay = null
				var/hotspot = (locate(/obj/fire) in T)
				if(hotspot)
					var/datum/gas_mixture/lowertemp = T.remove_air( T:air:total_moles )
					lowertemp.temperature = max( min(lowertemp.temperature-2000,lowertemp.temperature / 2) ,0)
					lowertemp.react()
					T.assume_air(lowertemp)
					del(hotspot)

		enzyme
			name = "Universal Enzyme"
			id = "enzyme"
			description = "A universal enzyme used in the preparation of certain chemicals and foods."
			reagent_state = LIQUID
			color = "#365E30" // rgb: 54, 94, 48
			overdose = REAGENTS_OVERDOSE

		dry_ramen
			name = "Dry Ramen"
			id = "dry_ramen"
			description = "Dry ramen is an unprepared noodle soup dish made from a block of fried-dried noodles, dried broth, dried vegetables, and chemicals that boils in contact with water."
			reagent_state = SOLID
			nutriment_factor = 1 * REAGENTS_METABOLISM
			color = "#302000" // rgb: 48, 32, 0

			on_mob_life(var/mob/living/M as mob)
				M.nutrition += nutriment_factor
				..()
				return

		hot_ramen
			name = "Hot Ramen"
			id = "hot_ramen"
			description = "Hot Ramen is a prepared noodle dish made from fried noodles, broth, and vegetables, heated up."
			reagent_state = LIQUID
			nutriment_factor = 5 * REAGENTS_METABOLISM
			color = "#302000" // rgb: 48, 32, 0

			on_mob_life(var/mob/living/M as mob)
				M.nutrition += nutriment_factor
				if (M.bodytemperature < 310)//310 is the normal bodytemp. 310.055
					M.bodytemperature = min(310, M.bodytemperature + (10 * TEMPERATURE_DAMAGE_COEFFICIENT))
				..()
				return

		hell_ramen
			name = "Hell Ramen"
			id = "hell_ramen"
			description = "Hell Ramen is a hot prepared noodle dish made from hot ramen and pure capsaicin oil."
			reagent_state = LIQUID
			nutriment_factor = 5 * REAGENTS_METABOLISM
			color = "#302000" // rgb: 48, 32, 0

			on_mob_life(var/mob/living/M as mob)
				M.nutrition += nutriment_factor
				M.bodytemperature += 10 * TEMPERATURE_DAMAGE_COEFFICIENT
				..()
				return

/* We're back to flour bags
		flour
			name = "flour"
			id = "flour"
			description = "This is what you rub all over yourself to pretend to be a ghost."
			reagent_state = SOLID
			nutriment_factor = 1 * REAGENTS_METABOLISM
			color = "#FFFFFF" // rgb: 0, 0, 0

			on_mob_life(var/mob/living/M as mob)
				M.nutrition += nutriment_factor
				..()
				return

			reaction_turf(var/turf/T, var/volume)
				src = null
				if(!istype(T, /turf/space))
					new /obj/effect/decal/cleanable/flour(T)
*/

		rice
			name = "Rice"
			id = "rice"
			description = "Rice is a cereal grain, a seed of the grass species oryza sativa. Chefs use rice in their main courses and side dishes, and rice can even be made into an alcohol called Sake."
			reagent_state = SOLID
			nutriment_factor = 1 * REAGENTS_METABOLISM
			color = "#FFFFFF" // rgb: 0, 0, 0

			on_mob_life(var/mob/living/M as mob)
				M.nutrition += nutriment_factor
				..()
				return

		cherryjelly
			name = "Cherry Jelly"
			id = "cherryjelly"
			description = "Cherry Jelly is a sweet, translucent, viscous substance derived from the fruit preserves of cherries. It is commonly spread on or stuffed in pastries."
			reagent_state = LIQUID
			nutriment_factor = 1 * REAGENTS_METABOLISM
			color = "#801E28" // rgb: 128, 30, 40

			on_mob_life(var/mob/living/M as mob)
				M.nutrition += nutriment_factor
				..()
				return

/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////// DRINKS BELOW, Beer is up there though, along with cola. Cap'n Pete's Cuban Spiced Rum////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////

		drink
			name = "Drink"
			id = "drink"
			description = "A drink is a liquid substance imbibed to quench thirst."
			reagent_state = LIQUID
			nutriment_factor = 1 * REAGENTS_METABOLISM
			color = "#E78108" // rgb: 231, 129, 8
			var/adj_dizzy = 0
			var/adj_drowsy = 0
			var/adj_sleepy = 0
			var/adj_temp = 0

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.nutrition += nutriment_factor
				holder.remove_reagent(src.id, FOOD_METABOLISM)
				// Drinks should be used up faster than other reagents.
				holder.remove_reagent(src.id, FOOD_METABOLISM)
				if (adj_dizzy) M.dizziness = max(0,M.dizziness + adj_dizzy)
				if (adj_drowsy)	M.drowsyness = max(0,M.drowsyness + adj_drowsy)
				if (adj_sleepy) M.sleeping = max(0,M.sleeping + adj_sleepy)
				if (adj_temp)
					if (M.bodytemperature < 310)//310 is the normal bodytemp. 310.055
						M.bodytemperature = min(310, M.bodytemperature + (25 * TEMPERATURE_DAMAGE_COEFFICIENT))

				..()
				return

		drink/orangejuice
			name = "Orange Juice"
			id = "orangejuice"
			description = "Orange juice is a sweet, citrucy beverage made from fresh orange meat and pulp blended into a healthy juice.pulp blended into juice."
			color = "#E78108" // rgb: 231, 129, 8

			glass_icon_state = "glass_orange"
			glass_name = "glass of orange juice"
			glass_desc = "It's a glass of orange juice. Delicious, pulpy, AND rich in Vitamin C, what more do you need?"

			on_mob_life(var/mob/living/M as mob)
				..()
				if(M.getOxyLoss() && prob(30)) M.adjustOxyLoss(-1)
				return

		drink/tomatojuice
			name = "Tomato Juice"
			id = "tomatojuice"
			description = "Tomato juice is a fruity, savory beverage made from the blended meat of fresh tomatoes. It is not usually imbibed on its own."
			color = "#731008" // rgb: 115, 16, 8

			glass_icon_state = "glass_red"
			glass_name = "glass of tomato juice"
			glass_desc = "This looks kind of bland. Maybe the barkeep will make something with it."

			on_mob_life(var/mob/living/M as mob)
				..()
				if(M.getFireLoss() && prob(20)) M.heal_organ_damage(0,1)
				return

		drink/limejuice
			name = "Lime Juice"
			id = "limejuice"
			description = "Lime juice is a sour, citrusy beverage made from the blended meat and pulp from fresh limes. It is not usually imbibed on its own."
			color = "#365E30" // rgb: 54, 94, 48

			glass_icon_state = "glass_green"
			glass_name = "glass of lime juice"
			glass_desc = "It's a glass of sour lime juice. Note the first thing you think of is sour."

			on_mob_life(var/mob/living/M as mob)
				..()
				if(M.getToxLoss() && prob(20)) M.adjustToxLoss(-1*REM)
				return

		drink/carrotjuice
			name = "Carrot Juice"
			id = "carrotjuice"
			description = "Carrot juice is a slightly sweet and savory beverage made from thoroughly blended carrots."
			color = "#FF8C00" // rgb: 255, 140, 0

			glass_icon_state = "carrotjuice"
			glass_name = "glass of carrot juice"
			glass_desc = "It's a glass of carrot juice. It looks refreshing, without the crunchy goodness of a carrot."

			on_mob_life(var/mob/living/M as mob)
				..()
				M.eye_blurry = max(M.eye_blurry-1 , 0)
				M.eye_blind = max(M.eye_blind-1 , 0)
				if(!data) data = 1
				switch(data)
					if(1 to 20)
						//nothing
					if(21 to INFINITY)
						if (prob(data-10))
							M.disabilities &= ~NEARSIGHTED
				data++
				return

		drink/berryjuice
			name = "Berry Juice"
			id = "berryjuice"
			description = "Berry juice is a sweet, fruity beverage made from a blend of red and blue raspberries, blueberries, and strawberries."
			color = "#990066" // rgb: 153, 0, 102

			glass_icon_state = "berryjuice"
			glass_name = "glass of berry juice"
			glass_desc = "It's a glass of sweet berry juice. It looks delicious."

		drink/grapejuice
			name = "Grape Juice"
			id = "grapejuice"
			description = "Grape juice is a fruity beverage made from bunches of grapes blended into a juice which has not yet fermented."
			color = "#863333" // rgb: 134, 51, 51

			glass_icon_state = "grapejuice"
			glass_name = "glass of grape juice"
			glass_desc = "It's a glass of grape juice. Tastes way better than cough syrup."

		drink/grapesoda
			name = "Grape Soda"
			id = "grapesoda"
			description = "Grape soda is a sweet beverage made from grape juice mixed with carbonated water."
			color = "#421C52" // rgb: 98, 57, 53
			adj_drowsy 	= 	-3

			glass_icon_state = "gsodaglass"
			glass_name = "glass of grape soda"
			glass_desc = "Looks like a delicious drank!"

		drink/poisonberryjuice
			name = "Poison Berry Juice"
			id = "poisonberryjuice"
			description = "Poison berry juice is a fruity, toxic, and ironically very tasty beverage made from a blend of different types of poisonous berries. It is darker than its non-poisonous variant, but it mimics its taste and smell just the same."
			color = "#863353" // rgb: 134, 51, 83

			glass_icon_state = "poisonberryjuice"
			glass_name = "glass of berry juice"
			glass_desc = "It's a glass of sweet berry juice. It looks delicious."

			on_mob_life(var/mob/living/M as mob)
				..()
				M.adjustToxLoss(1)
				return

		drink/watermelonjuice
			name = "Watermelon Juice"
			id = "watermelonjuice"
			description = "Watermelon juice is a very refreshing, mild-flavored beverage made from the meat of fresh, juicy watermelons."
			color = "#B83333" // rgb: 184, 51, 51

			glass_icon_state = "glass_red"
			glass_name = "glass of watermelon juice"
			glass_desc = "It's a glass of delicious, refreshing watermelon juice. Low in sugar, mostly water, a perfect diet drink."

		drink/lemonjuice
			name = "Lemon Juice"
			id = "lemonjuice"
			description = "Lemon juice is a very sour, citrusy beverage made from the meat and pulp of lemons. It is not usually imbibed on its own."
			color = "#AFAF00" // rgb: 175, 175, 0

			glass_icon_state = "lemonjuice"
			glass_name = "glass of lemon juice"
			glass_desc = "It's a glass of lemon juice. Your lips pucker just from looking at it."

		drink/banana
			name = "Banana Juice"
			id = "banana"
			description = "Banana juice is a fruity, creamy beverage made from fresh-peeled bananas."
			color = "#FAFAC8" // rgb: 250, 250, 200

			glass_icon_state = "banana"
			glass_name = "glass of banana juice"
			glass_desc = "It's a glass of creamy banana juice. You wonder how a liquid banana is even possible."

		drink/nothing
			name = "Nothing"
			id = "nothing"
			description = "This is an invisible, tasteless, beverage favorited by mimes."

			glass_icon_state = "nothing"
			glass_name = "glass of nothing"
			glass_desc = "Absolutely nothing."

		drink/potato_juice
			name = "Potato Juice"
			id = "potato"
			description = "Potato juice is a starchy vegetable beverage made from fresh-peeled potatoes. It is not usually imbibed on its own."
			nutriment_factor = 2 * FOOD_METABOLISM
			color = "#FAFAAF" // rgb: 250, 250, 175

			glass_icon_state = "glass_brown"
			glass_name = "glass of potato juice"
			glass_desc = "It's a glass of starchy potato juice. What a waste of good potatos."

		drink/milk
			name = "Milk"
			id = "milk"
			description = "Milk is a slightly sweet, opaque, nutritious white liquid produced by the mammary glands of mammals. Some people are allergic to milk."
			color = "#DFDFDF" // rgb: 223, 223, 223

			glass_icon_state = "glass_white"
			glass_name = "glass of milk"
			glass_desc = "It's a glass of milk. White and nutritious goodness, it keeps your bones strong!"

			on_mob_life(var/mob/living/M as mob)
				if(M.getBruteLoss() && prob(20)) M.heal_organ_damage(1,0)
				holder.remove_reagent("capsaicin", 10*REAGENTS_METABOLISM)
				..()
				return

		drink/milk/soymilk
			name = "Soy Milk"
			id = "soymilk"
			description = "Soy milk is a slightly sweet, opaque, opaque, white, plant milk made with soybeans, water, and added nutrients as an imitation of milk for those with milk allergies."
			color = "#DFDFC7" // rgb: 223, 223, 199

			glass_icon_state = "glass_white"
			glass_name = "glass of soy milk"
			glass_desc = "It's a glass of soy milk. White and nutritious soy goodness."

		drink/milk/cream
			name = "Cream"
			id = "cream"
			description = "Cream is a dairy product made from the processed butterfat layer of milk. It  for a variety of recipes. Some people are allergic to this."
			color = "#DFD7AF" // rgb: 223, 215, 175

			glass_icon_state = "glass_white"
			glass_name = "glass of cream"
			glass_desc = "It's a glass of cream. Mmm... Creamy..."

		drink/grenadine
			name = "Grenadine Syrup"
			id = "grenadine"
			description = "Grenadine syrup is a sweet, tangy syrup in made in the modern day with proper pomegranate substitute."
			color = "#FF004F" // rgb: 255, 0, 79

			glass_icon_state = "grenadineglass"
			glass_name = "glass of grenadine syrup"
			glass_desc = "It's a glass of grenadine syrup. It's sweet and tangy; what drink will the barkeep use it for?"
			glass_center_of_mass = list("x"=17, "y"=6)

		drink/hot_coco
			name = "Hot Chocolate"
			id = "hot_coco"
			description = "Hot chocolate is a hot, sweet, chocolaty beverage made from ground cocoa beans and sometimes milk."
			nutriment_factor = 2 * FOOD_METABOLISM
			color = "#403010" // rgb: 64, 48, 16
			adj_temp = 5

			glass_icon_state = "chocolateglass"
			glass_name = "glass of hot chocolate"
			glass_desc = "It's a cup of hot cocoa, made with love... and cocoa beans."

		drink/coffee
			name = "Coffee"
			id = "coffee"
			description = "Coffee is a slightly bitter, caffeinated, brewed beverage prepared from roasted coffee beans of the coffee plant."
			color = "#482000" // rgb: 72, 32, 0
			adj_dizzy = -5
			adj_drowsy = -3
			adj_sleepy = -2
			adj_temp = 25

			glass_icon_state = "hot_coffee"
			glass_name = "cup of coffee"
			glass_desc = "It's a hot cup of coffee. Don't drop it, or you'll send scalding liquid and glass shards everywhere."

			on_mob_life(var/mob/living/M as mob)
				..()
				M.make_jittery(5)
				if(adj_temp > 0)
					holder.remove_reagent("frostoil", 10*REAGENTS_METABOLISM)

				holder.remove_reagent(src.id, 0.1)

		drink/coffee/icecoffee
			name = "Iced Coffee"
			id = "icecoffee"
			description = "Iced coffee is a slightly bitter, caffeinated, brewed beverage made with coffee chilled with a few ice cubes."
			color = "#102838" // rgb: 16, 40, 56
			adj_temp = -5

			glass_icon_state = "icedcoffeeglass"
			glass_name = "glass of iced coffee"
			glass_desc = "It's a glass of iced coffee, a drink to perk you up and refresh you!"

		drink/coffee/soy_latte
			name = "Soy Latte"
			id = "soy_latte"
			description = "A soy latte is a warm, sweet, caffeinated beverage made from soy milk and coffee."
			color = "#664300" // rgb: 102, 67, 0
			adj_sleepy = 0
			adj_temp = 5

			glass_icon_state = "soy_latte"
			glass_name = "glass of soy latte"
			glass_desc = "It's a cup of soy lattee. A nice, refreshing lactose-intolerant-friendly beverage while you are reading."
			glass_center_of_mass = list("x"=15, "y"=9)

			on_mob_life(var/mob/living/M as mob)
				..()
				M.sleeping = 0
				if(M.getBruteLoss() && prob(20)) M.heal_organ_damage(1,0)
				return

		drink/coffee/cafe_latte
			name = "Cafe Latte"
			id = "cafe_latte"
			description = "A cafe latte is a warm, sweet, caffeinated beverage made from steamed milk and coffee."
			color = "#664300" // rgb: 102, 67, 0
			adj_sleepy = 0
			adj_temp = 5

			glass_icon_state = "cafe_latte"
			glass_name = "glass of cafe latte"
			glass_desc = "It's a cup of Cafe Latte. A nice, strong and refreshing beverage while you are reading."
			glass_center_of_mass = list("x"=15, "y"=9)

			on_mob_life(var/mob/living/M as mob)
				..()
				M.sleeping = 0
				if(M.getBruteLoss() && prob(20)) M.heal_organ_damage(1,0)
				return

		drink/tea
			name = "Tea"
			id = "tea"
			description = "Tea is an aromatic, caffeinated beverage commonly prepared by pouring hot or boiling water over cured leaves of the Camellia sinensis. It has antioxidants."
			color = "#101000" // rgb: 16, 16, 0
			adj_dizzy = -2
			adj_drowsy = -1
			adj_sleepy = -3
			adj_temp = 20

			glass_icon_state = "bigteacup"
			glass_name = "cup of tea"
			glass_desc = "Tasty black tea. It has antioxidants, it's good for you!"

			on_mob_life(var/mob/living/M as mob)
				..()
				if(M.getToxLoss() && prob(20))
					M.adjustToxLoss(-1)
				return

		drink/tea/icetea
			name = "Iced Tea"
			id = "icetea"
			description = "Iced tea is tea chilled with a few ice cubes."
			color = "#104038" // rgb: 16, 64, 56
			adj_temp = -5

			glass_icon_state = "icedteaglass"
			glass_name = "glass of iced tea"
			glass_desc = "No relation to a certain rap artist/ actor."
			glass_center_of_mass = list("x"=15, "y"=10)

		drink/cold
			name = "Cold drink"
			adj_temp = -5

		drink/cold/tonic
			name = "Tonic Water"
			id = "tonic"
			description = "Tonic water is a beverage made from water, added-citrus flavorings, and added quinine sulfate as an antimalarial." //Can this act as a mild spaceacillin?
			color = "#664300" // rgb: 102, 67, 0
			adj_dizzy = -5
			adj_drowsy = -3
			adj_sleepy = -2

			glass_icon_state = "glass_clear"
			glass_name = "glass of tonic water"
			glass_desc = "It's a glass of fizzy tonic water. The Quinine tastes funny, but at least it'll keep that Space Malaria away."

		drink/cold/sodawater
			name = "Soda Water"
			id = "sodawater"
			description = "Soda water is carbon dioxide dissolved in water under high pressure."
			color = "#619494" // rgb: 97, 148, 148
			adj_dizzy = -5
			adj_drowsy = -3

			glass_icon_state = "glass_clear"
			glass_name = "glass of soda water"
			glass_desc = "It's a glass of soda water. Bubbly."

		drink/cold/ice
			name = "Ice"
			id = "ice"
			description = "Ice is water frozen to a solid state under temperatures of 273.15 K."
			reagent_state = SOLID
			color = "#619494" // rgb: 97, 148, 148

			glass_icon_state = "iceglass"
			glass_name = "glass of ice"
			glass_desc = "Generally, you're supposed to put something else in there too..."

		drink/cold/space_cola
			name = "Space Cola"
			id = "cola"
			description = "Space cola is a sweetened, carbonated, caffeinated brand of soft drink."
			reagent_state = LIQUID
			color = "#100800" // rgb: 16, 8, 0
			adj_drowsy 	= 	-3

			glass_icon_state  = "glass_brown"
			glass_name = "glass of Space Cola"
			glass_desc = "A glass of refreshing Space Cola"

		drink/cold/nuka_cola
			name = "Nuka Cola"
			id = "nuka_cola"
			description = "Nuka Cola is a caffeinated, non-alcoholic beverage made with cola and uranium."
			color = "#100800" // rgb: 16, 8, 0
			adj_sleepy = -4

			glass_icon_state = "nuka_colaglass"
			glass_name = "glass of Nuka-Cola"
			glass_desc = "Don't cry, Don't raise your eye, It's only nuclear wasteland."
			glass_center_of_mass = list("x"=16, "y"=6)

			on_mob_life(var/mob/living/M as mob)
				M.make_jittery(20)
				M.druggy = max(M.druggy, 30)
				M.dizziness +=5
				M.drowsyness = 0
				..()
				return

		drink/cold/spacemountainwind
			name = "Mountain Wind"
			id = "spacemountainwind"
			description = "Mountain Wind is a clear, sweet, carbonated soft drink."
			color = "#102000" // rgb: 16, 32, 0
			adj_drowsy = -7
			adj_sleepy = -1

			glass_icon_state = "Space_mountain_wind_glass"
			glass_name = "glass of Space Mountain Wind"
			glass_desc = "Space Mountain Wind. As you know, there are no mountains in space, only wind."

		drink/cold/dr_gibb
			name = "Dr. Gibb"
			id = "dr_gibb"
			description = "Dr. Gibb is a sweet brand of a caffeinated soft drink beverage. It is a variant of cola with a blend of 42 different flavors."
			color = "#102000" // rgb: 16, 32, 0
			adj_drowsy = -6

			glass_icon_state = "dr_gibb_glass"
			glass_name = "glass of Dr. Gibb"
			glass_desc = "It's a glass of Dr. Gibb. Not as dangerous as the name might imply."

		drink/cold/space_up
			name = "Space-Up"
			id = "space_up"
			description = "Space-Up is a translucent, sweet brand of soft drink flavored with lemon-lime and 100% natural ingredients."
			color = "#202800" // rgb: 32, 40, 0
			adj_temp = -8

			glass_icon_state = "space-up_glass"
			glass_name = "glass of Space-up"
			glass_desc = "It's a glass of Space-up. It helps keep your cool."

		drink/cold/lemon_lime
			name = "Lemon Lime"
			description = "Lemon lime, known as 'Sour mix' is a sour, tangy bar mixture of lemon and lime juice, sugar, and carbonated water added to flavor beverages."
			id = "lemon_lime"
			color = "#878F00" // rgb: 135, 40, 0
			adj_temp = -8

			glass_icon_state = "lemonlime"
			glass_name = "glass of lemon lime soda"
			glass_desc = "It's a glass of lemon-lime mix, still sour with a hint of sweetness."

		drink/cold/lemonade
			name = "Lemonade"
			description = "Lemonade is a sweet, citrus-flavored beverage made from the sugar, water, and the juice from lemons."
			id = "lemonade"
			color = "#FFFF00" // rgb: 255, 255, 0

			glass_icon_state = "lemonadeglass"
			glass_name = "glass of lemonade"
			glass_desc = "It's a glass of lemonade. You feel nostalgic."

		drink/cold/kiraspecial
			name = "Kira Special"
			description = "Kira Special is a sweet, citrus-flavored, carbonated, non-alcoholic beverage made with orange juice, lime juice, and soda water."
			id = "kiraspecial"
			color = "#CCCC99" // rgb: 204, 204, 153

			glass_icon_state = "kiraspecial"
			glass_name = "glass of Kira Special"
			glass_desc = "It's a fizzy beverage. Long live the guy who everyone had mistaken for a girl. Baka!"
			glass_center_of_mass = list("x"=16, "y"=12)

		drink/cold/brownstar
			name = "Brown Star"
			description = "Brown Star is a citrus-flavored, caffeinated, carbonated, non-alcoholic drink made with orange juice and cola."
			id = "brownstar"
			color = "#9F3400" // rgb: 159, 052, 000
			adj_temp = - 2
			adj_sleepy = - 2

			glass_icon_state = "brownstar"
			glass_name = "glass of Brown Star"
			glass_desc = "It's brown, but it's not what it sounds like..."

		drink/cold/milkshake
			name = "Milkshake"
			description = "A milkshake is a sweet, creamy, slush beverage made with milk, cream, and ice. Too much of this beverage at once will chill the body."
			id = "milkshake"
			color = "#AEE5E4" // rgb" 174, 229, 228
			adj_temp = -9

			glass_icon_state = "milkshake"
			glass_name = "glass of milkshake"
			glass_desc = "Ahh, a cold milkshake, a glorious brainfreezing mixture."
			glass_center_of_mass = list("x"=16, "y"=7)

			on_mob_life(var/mob/living/M as mob)
				if(!M)
					M = holder.my_atom
				if(prob(1))
					M.emote("shiver")
				M.bodytemperature = max(M.bodytemperature - 10 * TEMPERATURE_DAMAGE_COEFFICIENT, 0)
				if(istype(M, /mob/living/carbon/slime))
					M.bodytemperature = max(M.bodytemperature - rand(10,20), 0)
				holder.remove_reagent("capsaicin", 5)
				holder.remove_reagent(src.id, FOOD_METABOLISM)
				..()
				return

		drink/cold/rewriter
			name = "Rewriter"
			description = "Rewriter is a sweet, carbonated, caffeinated soft-drink designed to keep people awake. It is a non-alcoholic beverage made with space mountain wind and coffee."
			id = "rewriter"
			color = "#485000" // rgb:72, 080, 0
			adj_sleepy = -4
			glass_icon_state = "rewriter"
			glass_name = "glass of Rewriter"
			glass_desc = "It's a glass of Rewriter, the secret of the sanctuary of the Libarian..."
			glass_center_of_mass = list("x"=16, "y"=9)

			on_mob_life(var/mob/living/M as mob)
				..()
				M.make_jittery(5)
				return


		doctor_delight
			name = "The Doctor's Delight"
			id = "doctorsdelight"
			description = "The Doctor's Delight is a pink, bubbly, extremely delicious non-alcoholic health drink designed to revitalize the body and have a sweet, tangy, creamy taste to appeal to adults and children. It is made from orange juice, lime juice, tomato juice, cream, and tricordrazine."
			reagent_state = LIQUID
			color = "#FF8CFF" // rgb: 255, 140, 255
			nutriment_factor = 1 * FOOD_METABOLISM
			scannable = 1
			glass_icon_state = "doctorsdelightglass"
			glass_name = "glass of The Doctor's Delight"
			glass_desc = "The Doctor's Delight--the healthiest drink around. Doctors love it, kids love it, and adults love it, too."
			glass_center_of_mass = list("x"=16, "y"=8)

			on_mob_life(var/mob/living/M as mob)
				M:nutrition += nutriment_factor
				holder.remove_reagent(src.id, FOOD_METABOLISM)
				if(!M) M = holder.my_atom
				if(M:getOxyLoss() && prob(60)) M:adjustOxyLoss(-2)
				if(M:getBruteLoss() && prob(60)) M:heal_organ_damage(2,0)
				if(M:getFireLoss() && prob(60)) M:heal_organ_damage(0,2)
				if(M:getToxLoss() && prob(60)) M:adjustToxLoss(-2)
				if(M.dizziness !=0) M.dizziness = max(0,M.dizziness-15)
				if(M.confused !=0) M.confused = max(0,M.confused - 5)
				..()
				return

//////////////////////////////////////////////The ten friggen million reagents that get you drunk//////////////////////////////////////////////

		atomicbomb
			name = "Atomic Bomb"
			id = "atomicbomb"
			description = "Atomic Bomb is an alcoholic beverage unique to making one drunk immediately after imbibing. It is made from mixing uranium in a glass of mixing uranium in a glass of B-52.."
			reagent_state = LIQUID
			color = "#666300" // rgb: 102, 99, 0

			glass_icon_state = "atomicbombglass"
			glass_name = "glass of Atomic Bomb"
			glass_desc = "The Atomic Bomb. Nanotrasen cannot take legal responsibility for your actions after imbibing."
			glass_center_of_mass = list("x"=15, "y"=7)

			on_mob_life(var/mob/living/M as mob)
				M.druggy = max(M.druggy, 50)
				M.confused = max(M.confused+2,0)
				M.make_dizzy(10)
				if (!M.stuttering) M.stuttering = 1
				M.stuttering += 3
				if(!data) data = 1
				data++
				switch(data)
					if(51 to 200)
						M.sleeping += 1
					if(201 to INFINITY)
						M.sleeping += 1
						M.adjustToxLoss(2)
				..()
				return

		gargle_blaster
			name = "Pan-Galactic Gargle Blaster"
			id = "gargleblaster"
			description = "A Pan-Galactic Gargle Blaster is a unique psychedelic beverage made from vodka, gin, whiskey, cognac, and lime juice."
			reagent_state = LIQUID
			color = "#664300" // rgb: 102, 67, 0

			glass_icon_state = "gargleblasterglass"
			glass_name = "glass of Pan-Galactic Gargle Blaster"
			glass_desc = "Does... does this mean that Arthur and Ford are on the station? Oh joy."
			glass_center_of_mass = list("x"=17, "y"=6)

			on_mob_life(var/mob/living/M as mob)
				if(!data) data = 1
				data++
				M.dizziness +=6
				switch(data)
					if(15 to 45)
						M.stuttering = max(M.stuttering+3,0)
					if(45 to 55)
						if (prob(50))
							M.confused = max(M.confused+3,0)
					if(55 to 200)
						M.druggy = max(M.druggy, 55)
					if(201 to INFINITY)
						M.adjustToxLoss(2)
				..()

		neurotoxin
			name = "Neurotoxin"
			id = "neurotoxin"
			description = "Neurotoxin is a unique alcoholic beverage made by mixing soporific in a glass of Gargle Blaster. It temporarily incapacitates those who imbibe it."
			reagent_state = LIQUID
			color = "#2E2E61" // rgb: 46, 46, 97

			glass_icon_state = "neurotoxinglass"
			glass_name = "glass of Neurotoxin"
			glass_desc = "The name says it all--a drink that is guaranteed to knock you silly."
			glass_center_of_mass = list("x"=16, "y"=8)

			on_mob_life(var/mob/living/carbon/M as mob)
				if(!M) M = holder.my_atom
				M.weakened = max(M.weakened, 3)
				if(!data) data = 1
				data++
				M.dizziness +=6
				switch(data)
					if(15 to 45)
						M.stuttering = max(M.stuttering+3,0)
					if(45 to 55)
						if (prob(50))
							M.confused = max(M.confused+3,0)
					if(55 to 200)
						M.druggy = max(M.druggy, 55)
					if(201 to INFINITY)
						M.adjustToxLoss(2)
				..()

		hippies_delight
			name = "Hippies' Delight"
			id = "hippiesdelight"
			description = "Hippies' Delight is a unique psychedelic alcoholic beverage made by mixing psilocybin and gargleblaster."
			reagent_state = LIQUID
			color = "#664300" // rgb: 102, 67, 0

			glass_icon_state = "hippiesdelightglass"
			glass_name = "glass of Hippie's Delight"
			glass_desc = "A drink enjoyed by people during the 1960's. Now, with more delight!"
			glass_center_of_mass = list("x"=16, "y"=8)

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.druggy = max(M.druggy, 50)
				if(!data) data = 1
				data++
				switch(data)
					if(1 to 5)
						if (!M.stuttering) M.stuttering = 1
						M.make_dizzy(10)
						if(prob(10)) M.emote(pick("twitch","giggle"))
					if(5 to 10)
						if (!M.stuttering) M.stuttering = 1
						M.make_jittery(20)
						M.make_dizzy(20)
						M.druggy = max(M.druggy, 45)
						if(prob(20)) M.emote(pick("twitch","giggle"))
					if (10 to 200)
						if (!M.stuttering) M.stuttering = 1
						M.make_jittery(40)
						M.make_dizzy(40)
						M.druggy = max(M.druggy, 60)
						if(prob(30)) M.emote(pick("twitch","giggle"))
					if(201 to INFINITY)
						if (!M.stuttering) M.stuttering = 1
						M.make_jittery(60)
						M.make_dizzy(60)
						M.druggy = max(M.druggy, 75)
						if(prob(40)) M.emote(pick("twitch","giggle"))
						if(prob(30)) M.adjustToxLoss(2)
				holder.remove_reagent(src.id, 0.2)
				..()
				return

/*boozepwr chart
1-2 = non-toxic alcohol
3 = medium-toxic
4 = the hard stuff
5 = potent mixes
<6 = deadly toxic
*/

		ethanol
			name = "Ethanol" //Parent class for all alcoholic reagents.
			id = "ethanol"
			description = "Ethanol is neurotoxic, psychoactive drug and it is the type of alcohol found in alcoholic beverages produced by the fermentation of sugars by yeasts. It is a volatile, flammable, colorless liquid with a slight chemical odor."
			reagent_state = LIQUID
			nutriment_factor = 0 //So alcohol can fill you up! If they want to.
			color = "#808080" // rgb: 128, 128, 128
			var/boozepwr = 5 //higher numbers mean the booze will have an effect faster.
			var/dizzy_adj = 3
			var/adj_drowsy = 0
			var/adj_sleepy = 0
			var/slurr_adj = 3
			var/confused_adj = 2
			var/slur_start = 90			//amount absorbed after which mob starts slurring
			var/confused_start = 150	//amount absorbed after which mob starts confusing directions
			var/blur_start = 300	//amount absorbed after which mob starts getting blurred vision
			var/pass_out = 400	//amount absorbed after which mob starts passing out

			glass_icon_state = "glass_clear"
			glass_name = "glass of ethanol"
			glass_desc = "This is the type of alcohol found in alcoholic beverages in its pure form."

			on_mob_life(var/mob/living/M as mob, var/alien)
				M:nutrition += nutriment_factor
				holder.remove_reagent(src.id, (alien ? FOOD_METABOLISM : ALCOHOL_METABOLISM)) // Catch-all for creatures without livers.

				if (adj_drowsy)	M.drowsyness = max(0,M.drowsyness + adj_drowsy)
				if (adj_sleepy) M.sleeping = max(0,M.sleeping + adj_sleepy)

				if(!src.data || (!isnum(src.data)  && src.data.len)) data = 1   //if it doesn't exist we set it.  if it's a list we're going to set it to 1 as well.  This is to
				src.data += boozepwr						//avoid a runtime error associated with drinking blood mixed in drinks (demon's blood).

				var/d = data

				// make all the beverages work together
				for(var/datum/reagent/ethanol/A in holder.reagent_list)
					if(A != src && isnum(A.data)) d += A.data

				if(alien && alien == IS_SKRELL) //Skrell get very drunk very quickly.
					d*=5

				M.dizziness += dizzy_adj.
				if(d >= slur_start && d < pass_out)
					if (!M:slurring) M:slurring = 1
					M:slurring += slurr_adj
				if(d >= confused_start && prob(33))
					if (!M:confused) M:confused = 1
					M.confused = max(M:confused+confused_adj,0)
				if(d >= blur_start)
					M.eye_blurry = max(M.eye_blurry, 10)
					M:drowsyness  = max(M:drowsyness, 0)
				if(d >= pass_out)
					M:paralysis = max(M:paralysis, 20)
					M:drowsyness  = max(M:drowsyness, 30)
					if(ishuman(M))
						var/mob/living/carbon/human/H = M
						var/datum/organ/internal/liver/L = H.internal_organs_by_name["liver"]
						if (!L)
							H.adjustToxLoss(5)
						else if(istype(L))
							L.take_damage(0.1, 1)
						H.adjustToxLoss(0.1)
				..()
				return

			reaction_obj(var/obj/O, var/volume)
				if(istype(O,/obj/item/weapon/paper))
					var/obj/item/weapon/paper/paperaffected = O
					paperaffected.clearpaper()
					usr << "The solution dissolves the ink on the paper."
				if(istype(O,/obj/item/weapon/book))
					if(istype(O,/obj/item/weapon/book/tome))
						usr << "The solution does nothing. Whatever this is, it isn't normal ink."
						return
					if(volume >= 5)
						var/obj/item/weapon/book/affectedbook = O
						affectedbook.dat = null
						usr << "The solution dissolves the ink on the book."
					else
						usr << "It wasn't enough..."
				return

		ethanol/beer
			name = "Beer"
			id = "beer"
			description = "Beer is a mild alcoholic beverage made from brewing malted grains, hops, yeast, and water."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 1
			nutriment_factor = 1 * FOOD_METABOLISM

			glass_icon_state = "beerglass"
			glass_name = "glass of beer"
			glass_desc = "It's a freezing pint of beer."
			glass_center_of_mass = list("x"=16, "y"=8)

			on_mob_life(var/mob/living/M as mob)
				M:jitteriness = max(M:jitteriness-3,0)
				..()
				return

		ethanol/kahlua
			name = "Kahlua"
			id = "kahlua"
			description = "Kahlua is a coffee-flavored sugar-based liqueur from Mexico, flavored with rum, corn syrup, and vanilla beans."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 1.5
			dizzy_adj = -5
			adj_drowsy = -3
			adj_sleepy = -2

			glass_icon_state = "kahluaglass"
			glass_name = "glass of RR coffee liquor"
			glass_desc = "DAMN, THIS THING LOOKS ROBUST!"
			glass_center_of_mass = list("x"=15, "y"=7)

			on_mob_life(var/mob/living/M as mob)
				M.make_jittery(5)
				..()
				return

		ethanol/whiskey
			name = "Whiskey"
			id = "whiskey"
			description = "Whiskey is a distilled moderately-alcoholic beverage made from fermented grain mash."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 2
			dizzy_adj = 4

			glass_icon_state = "whiskeyglass"
			glass_name = "glass of whiskey"
			glass_desc = "The silky, smokey whiskey goodness inside the glass makes the drink look very classy."
			glass_center_of_mass = list("x"=16, "y"=12)

		ethanol/specialwhiskey
			name = "Special Blend Whiskey"
			id = "specialwhiskey"
			description = "This is a highly-prized, rich, special blend of whiskey with a deeper amber color, a more bold, sweet flavor, and an extra luxuriously silky-smooth finish."
			color = "#4B2300" // rgb: 75, 35, 0
			boozepwr = 2
			dizzy_adj = 4
			slur_start = 30		//amount absorbed after which mob starts slurring

			glass_icon_state = "whiskeyglass"
			glass_name = "glass of special blend whiskey"
			glass_desc = "Just when you thought regular station whiskey was good... This silky, amber goodness has to come along and ruin everything."
			glass_center_of_mass = list("x"=16, "y"=12)

		ethanol/thirteenloko
			name = "Thirteen Loko"
			id = "thirteenloko"
			description = "Thirteen Loko is a potent, moderately- alcoholic, caffeinated beverage made from coffee and alcohol. Someone who drinks this will appear to be on a hyperzine trip."
			color = "#102000" // rgb: 16, 32, 0
			boozepwr = 2
			nutriment_factor = 1 * FOOD_METABOLISM

			glass_icon_state = "thirteen_loko_glass"
			glass_name = "glass of Thirteen Loko"
			glass_desc = "This is a glass of Thirteen Loko, it appears to be of the highest quality. The drink, not the glass."

			on_mob_life(var/mob/living/M as mob)
				M:drowsyness = max(0,M:drowsyness-7)
				if (M.bodytemperature > 310)
					M.bodytemperature = max(310, M.bodytemperature - (5 * TEMPERATURE_DAMAGE_COEFFICIENT))
				M.make_jittery(5)
				..()
				return

		ethanol/vodka
			name = "Vodka"
			id = "vodka"
			description = "Vodka is a distilled moderately-alcoholic beverage primarily orignating from Russia, made from fermented cereal grains, potatoes, and sometimes fruits and sugar."
			color = "#0064C8" // rgb: 0, 100, 200
			boozepwr = 2

			glass_icon_state = "ginvodkaglass"
			glass_name = "glass of vodka"
			glass_desc = "The glass contain wodka. Xynta."
			glass_center_of_mass = list("x"=16, "y"=12)

			on_mob_life(var/mob/living/M as mob)
				M.radiation = max(M.radiation-1,0)
				..()
				return

		ethanol/bilk
			name = "Bilk"
			id = "bilk"
			description = "Bilk is a mild alcoholic beverage made by mixing beer and milk."
			color = "#895C4C" // rgb: 137, 92, 76
			boozepwr = 1
			nutriment_factor = 2 * FOOD_METABOLISM

			glass_icon_state = "glass_brown"
			glass_name = "glass of bilk"
			glass_desc = "A brew of milk and beer, for those alcoholics who fear osteoporosis."

		ethanol/threemileisland
			name = "Three Mile Island Iced Tea"
			id = "threemileisland"
			description = "Three Mile Island Iced Tea is a potent, psychedelic, alcoholic beverage made by mixing uranium in a glass of Long Island Iced Tea."
			color = "#666340" // rgb: 102, 99, 64
			boozepwr = 5

			glass_icon_state = "threemileislandglass"
			glass_name = "glass of Three Mile Island iced tea"
			glass_desc = "A glass of this is sure to prevent a meltdown."
			glass_center_of_mass = list("x"=16, "y"=2)

			on_mob_life(var/mob/living/M as mob)
				M.druggy = max(M.druggy, 50)
				..()
				return

		ethanol/gin
			name = "Gin"
			id = "gin"
			description = "Gin is a mild alcoholic beverage. It is a distilled spirit whose flavor derives from juniper berries."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 1
			dizzy_adj = 3

			glass_icon_state = "ginvodkaglass"
			glass_name = "glass of gin"
			glass_desc = "A crystal clear glass of Griffeater gin."
			glass_center_of_mass = list("x"=16, "y"=12)

		ethanol/Tequila
			name = "Tequila"
			id = "tequila"
			description = "Tequila is moderately-alcoholic beverage originally from Mexico, from the blue agave plant."
			color = "#FFFF91" // rgb: 255, 255, 145
			boozepwr = 2

			glass_icon_state = "tequilaglass"
			glass_name = "glass of Tequila"
			glass_desc = "Now all that's missing is the weird colored shades!"
			glass_center_of_mass = list("x"=16, "y"=12)

		ethanol/vermouth
			name = "Vermouth"
			id = "vermouth"
			description = "Vermouth is a mild alcoholic beverage. It is an aromatized, fortified wine flavored with botanicals."
			color = "#91FF91" // rgb: 145, 255, 145
			boozepwr = 1.5

			glass_icon_state = "vermouthglass"
			glass_name = "glass of vermouth"
			glass_desc = "You wonder why you're even drinking this straight."
			glass_center_of_mass = list("x"=16, "y"=12)

		ethanol/wine
			name = "Wine"
			id = "wine"
			description = "Wine is a mild alcoholic beverage made from distilled grape juice."
			color = "#7E4043" // rgb: 126, 64, 67
			boozepwr = 1.5
			dizzy_adj = 2
			slur_start = 65			//amount absorbed after which mob starts slurring
			confused_start = 145	//amount absorbed after which mob starts confusing directions

			glass_icon_state = "wineglass"
			glass_name = "glass of wine"
			glass_desc = "A very classy looking drink."
			glass_center_of_mass = list("x"=15, "y"=7)

		ethanol/cognac
			name = "Cognac"
			id = "cognac"
			description = "Cognac is a moderately-alcoholic variety of brandy named after the city of Cognac in France."
			color = "#AB3C05" // rgb: 171, 60, 5
			boozepwr = 1.5
			dizzy_adj = 4
			confused_start = 115	//amount absorbed after which mob starts confusing directions

			glass_icon_state = "cognacglass"
			glass_name = "glass of cognac"
			glass_desc = "Damn, you feel like some kind of French aristocrat just by holding this."
			glass_center_of_mass = list("x"=16, "y"=6)

		ethanol/hooch
			name = "Hooch"
			id = "hooch"
			description = "Named after the slang word for illicit whiskey, Hooch is a toxic, moderately-alcoholic beverage made by mixing sugar, pure ethanol and welder fuel."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 2
			dizzy_adj = 6
			slurr_adj = 5
			slur_start = 35			//amount absorbed after which mob starts slurring
			confused_start = 90	//amount absorbed after which mob starts confusing directions

			glass_icon_state = "glass_brown2"
			glass_name = "glass of Hooch"
			glass_desc = "You've really hit rock bottom now... your liver packed its bags and left last night."

		ethanol/ale
			name = "Ale"
			id = "ale"
			description = "Ale is a type of beer brewed using a warm fermentation method resulting in a sweet, full-bodied and fruity taste. It is mild alcoholic."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 1

			glass_icon_state = "aleglass"
			glass_name = "glass of ale"
			glass_desc = "A freezing pint of delicious ale."
			glass_center_of_mass = list("x"=16, "y"=8)

		ethanol/absinthe
			name = "Absinthe"
			id = "absinthe"
			description = "Absinthe is a green, distilled, strong beverage. It is an anise-flavored spirit derived from botanicals, including the flowers and leaves of Artemisia absinthium, green anise, sweet fennel, and other medicinal and culinary herbs."
			color = "#33EE00" // rgb: 51, 238, 0
			boozepwr = 4
			dizzy_adj = 5
			slur_start = 15
			confused_start = 30

			glass_icon_state = "absintheglass"
			glass_name = "glass of absinthe"
			glass_desc = "Wormwood, anise, and sweet fennel, oh my."
			glass_center_of_mass = list("x"=16, "y"=5)

		ethanol/pwine
			name = "Poison Wine"
			id = "pwine"
			description = "Poison wine is a jet black, mild alcoholic beverage. It has a fluid akin to blood's consistency with an oily, viscous, purple, toxic substance that mimics the taste of wine."
			color = "#000000" // rgb: 0, 0, 0 SHOCKER
			boozepwr = 1
			dizzy_adj = 1
			slur_start = 1
			confused_start = 1

			glass_icon_state = "pwineglass"
			glass_name = "glass of ???"
			glass_desc = "A black ichor with an oily purple sheen on top."
			glass_center_of_mass = list("x"=16, "y"=5)

			on_mob_life(var/mob/living/M as mob)
				if(!M) M = holder.my_atom
				M.druggy = max(M.druggy, 50)
				if(!data) data = 1
				data++
				switch(data)
					if(1 to 25)
						if (!M.stuttering) M.stuttering = 1
						M.make_dizzy(1)
						M.hallucination = max(M.hallucination, 3)
						if(prob(1)) M.emote(pick("twitch","giggle"))
					if(25 to 75)
						if (!M.stuttering) M.stuttering = 1
						M.hallucination = max(M.hallucination, 10)
						M.make_jittery(2)
						M.make_dizzy(2)
						M.druggy = max(M.druggy, 45)
						if(prob(5)) M.emote(pick("twitch","giggle"))
					if (75 to 150)
						if (!M.stuttering) M.stuttering = 1
						M.hallucination = max(M.hallucination, 60)
						M.make_jittery(4)
						M.make_dizzy(4)
						M.druggy = max(M.druggy, 60)
						if(prob(10)) M.emote(pick("twitch","giggle"))
						if(prob(30)) M.adjustToxLoss(2)
					if (150 to 300)
						if (!M.stuttering) M.stuttering = 1
						M.hallucination = max(M.hallucination, 60)
						M.make_jittery(4)
						M.make_dizzy(4)
						M.druggy = max(M.druggy, 60)
						if(prob(10)) M.emote(pick("twitch","giggle"))
						if(prob(30)) M.adjustToxLoss(2)
						if(prob(5)) if(ishuman(M))
							var/mob/living/carbon/human/H = M
							var/datum/organ/internal/heart/L = H.internal_organs_by_name["heart"]
							if (L && istype(L))
								L.take_damage(5, 0)
					if (300 to INFINITY)
						if(ishuman(M))
							var/mob/living/carbon/human/H = M
							var/datum/organ/internal/heart/L = H.internal_organs_by_name["heart"]
							if (L && istype(L))
								L.take_damage(100, 0)
				holder.remove_reagent(src.id, FOOD_METABOLISM)

		ethanol/rum //No more deadrum.
			name = "Rum"
			id = "rum"
			description = "Rum is a sweet, smooth, mild distilled alcoholic beverage made from molasses or sugarcane juice by fermentation and distillation, then aged in oak barrels."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 1.5

			glass_icon_state = "rumglass"
			glass_name = "glass of rum"
			glass_desc = "Fifteen men in a dead man's chest. Yo, ho, ho, and a bottle o' rum!"
			glass_center_of_mass = list("x"=16, "y"=12)

			on_mob_life(var/mob/living/M as mob)
				..()
				M.dizziness +=5
				return

		ethanol/sake
			name = "Sake"
			id = "sake"
			description = "Sake is a Japanese rice wine, a moderately- alcoholic beverage made by fermenting polished rice that had bran removed."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 2

			glass_icon_state = "ginvodkaglass"
			glass_name = "glass of sake"
			glass_desc = "It's a glass of sake."
			glass_center_of_mass = list("x"=16, "y"=12)

/////////////////////////////////////////////////////////////////cocktail entities//////////////////////////////////////////////


		ethanol/goldschlager
			name = "Goldschlager"
			id = "goldschlager"
			description = "Goldschlager is a moderately-alcoholic beverage. It is a Swiss cinnamon schnapps with very thin flakes of gold floating inside."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 3

			glass_icon_state = "ginvodkaglass"
			glass_name = "glass of Goldschlager"
			glass_desc = "A glass of 100 proof that teen girls will drink anything with gold in it."
			glass_center_of_mass = list("x"=16, "y"=12)

		ethanol/patron
			name = "Patron"
			id = "patron"
			description = "Patron is a moderately-alcoholic beverage. It is a brand of Tequila with very thin flakes of silver floating inside."
			color = "#585840" // rgb: 88, 88, 64
			boozepwr = 2

			glass_icon_state = "patronglass"
			glass_name = "glass of Patron"
			glass_desc = "Drinking patron in the bar with all the subpar ladies."
			glass_center_of_mass = list("x"=7, "y"=8)

		ethanol/gintonic
			name = "Gin and Tonic"
			id = "gintonic"
			description = "Gin and Tonic is a mild alcoholic beverage made by mixing gin in a glass of tonic water."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 1

			glass_icon_state = "gintonicglass"
			glass_name = "glass of gin and tonic"
			glass_desc = "A mild but still great cocktail. Drink up, like a true Englishman, and bid the Space Malaria goodbye!"
			glass_center_of_mass = list("x"=16, "y"=7)

		ethanol/cuba_libre
			name = "Cuba Libre"
			id = "cubalibre"
			description = "Cuba Libre is a mild alcoholic beverage made by mixing cola in a glass of rum."
			color = "#3E1B00" // rgb: 62, 27, 0
			boozepwr = 1.5

			glass_icon_state = "cubalibreglass"
			glass_name = "glass of Cuba Libre"
			glass_desc = "A classic mix of rum and cola."
			glass_center_of_mass = list("x"=16, "y"=8)

		ethanol/whiskey_cola
			name = "Whiskey Cola"
			id = "whiskeycola"
			description = "Whiskey Cola is a moderately-alcoholic beverage made by mixing cola in a glass of whiskey."
			color = "#3E1B00" // rgb: 62, 27, 0
			boozepwr = 2

			glass_icon_state = "whiskeycolaglass"
			glass_name = "glass of whiskey cola"
			glass_desc = "An innocent-looking mixture of cola and Whiskey. Delicious."
			glass_center_of_mass = list("x"=16, "y"=9)

		ethanol/martini
			name = "Classic Martini"
			id = "martini"
			description = "A Martini is a moderately-alcoholic beverage made by mixing vermouth in a glass of gin."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 2

			glass_icon_state = "martiniglass"
			glass_name = "glass of classic martini"
			glass_desc = "Damn, the bartender even stirred it... Hey, where's the olive?"
			glass_center_of_mass = list("x"=17, "y"=8)

		ethanol/vodkamartini
			name = "Vodka Martini"
			id = "vodkamartini"
			description = "Vodka Martini is a strong alcoholic beverage made by mixing vodka in a glass of martini."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 4

			glass_icon_state = "martiniglass"
			glass_name = "glass of vodka martini"
			glass_desc ="A bastardisation of the classic martini. Still great."
			glass_center_of_mass = list("x"=17, "y"=8)

		ethanol/white_russian
			name = "White Russian"
			id = "whiterussian"
			description = "White Russian is a moderately-alcoholic beverage made by mixing cream in a glass of Black Russian."
			color = "#A68340" // rgb: 166, 131, 64
			boozepwr = 3

			glass_icon_state = "whiterussianglass"
			glass_name = "glass of White Russian"
			glass_desc = "A very nice looking drink. But that's just, like, your opinion, man."
			glass_center_of_mass = list("x"=16, "y"=9)

		ethanol/screwdrivercocktail
			name = "Screwdriver"
			id = "screwdrivercocktail"
			description = "A Screwdriver Cocktail is a moderately-alcoholic beverage made by mixing orange juice in a glass of vodka."
			color = "#A68310" // rgb: 166, 131, 16
			boozepwr = 3

			glass_icon_state = "screwdriverglass"
			glass_name = "glass of Screwdriver"
			glass_desc = "A simple, yet superb mixture of Vodka and orange juice. Just the thing for the tired engineer."
			glass_center_of_mass = list("x"=15, "y"=10)

		ethanol/booger
			name = "Booger"
			id = "booger"
			description = "Booger is a green, slimy, and mild alcoholic beverage made by mixing cream, a banana, rum, and watermelon juice."
			color = "#8CFF8C" // rgb: 140, 255, 140
			boozepwr = 1.5

			glass_icon_state = "booger"
			glass_name = "glass of Booger"
			glass_desc = "Eww, it's all slimy..."

		ethanol/bloody_mary
			name = "Bloody Mary"
			id = "bloodymary"
			description = "A Bloody Mary is a red, vegetable-based, moderately-alcoholic beverage made by mixing vodka and lime juice in a glass of tomato juice."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 3

			glass_icon_state = "bloodymaryglass"
			glass_name = "glass of Bloody Mary"
			glass_desc = "Tomato juice, mixed with Vodka and a lil' bit of lime. It's even garnished with a celery stick."

		ethanol/brave_bull
			name = "Brave Bull"
			id = "bravebull"
			description = "Brave Bull is a moderately-alcoholic beverage made by mixing kahula in a glass of tequila."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 3

			glass_icon_state = "bravebullglass"
			glass_name = "glass of Brave Bull"
			glass_desc = "Tequila and coffee liquor, brought together in a mouthwatering mixture. Drink up."
			glass_center_of_mass = list("x"=15, "y"=8)

		ethanol/Tequila_sunrise
			name = "Tequila Sunrise"
			id = "tequilasunrise"
			description = "Tequila Sunrise is fruity, moderately- alcoholic beverage made by mixing orange juice in a glass of tequila."
			color = "#FFE48C" // rgb: 255, 228, 140
			boozepwr = 2

			glass_icon_state = "tequilasunriseglass"
			glass_name = "glass of Tequila Sunrise"
			glass_desc = "Oh great, now you feel nostalgic about sunrises back on Terra..."

		ethanol/toxins_special
			name = "Toxins Special"
			id = "phoronspecial"
			description = "Toxins Special is a potent, spicy, hot alcoholic beverage made by mixing vermouth, rum, and phoron. Despite its name, the phoron neutralized in the drink and it only heats up body temperatures."
			reagent_state = LIQUID
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 5

			glass_icon_state = "toxinsspecialglass"
			glass_name = "glass of Toxins Special"
			glass_desc = "Whoa, this thing is on FIRE!"

			on_mob_life(var/mob/living/M as mob)
				if (M.bodytemperature < 330)
					M.bodytemperature = min(330, M.bodytemperature + (15 * TEMPERATURE_DAMAGE_COEFFICIENT)) //310 is the normal bodytemp. 310.055
				..()
				return

		ethanol/beepsky_smash
			name = "Beepsky Smash"
			id = "beepskysmash"
			description = "Beepsky Smash is a strong alcoholic beverage made by mixing lime juice, whiskey and iron. It stuns the drinker."
			reagent_state = LIQUID
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 4

			glass_icon_state = "beepskysmashglass"
			glass_name = "Beepsky Smash"
			glass_desc = "Heavy, hot and strong, just like the iron fist of the LAW."
			glass_center_of_mass = list("x"=18, "y"=10)

			on_mob_life(var/mob/living/M as mob)
				M.Stun(2)
				..()
				return

		ethanol/irish_cream
			name = "Irish Cream"
			id = "irishcream"
			description = "Irish Cream is an alcoholic beverage made by mixing cream in a glass of whiskey."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 2

			glass_icon_state = "irishcreamglass"
			glass_name = "glass of Irish cream"
			glass_desc = "It's cream, mixed with whiskey. What else would you expect from the Irish?"
			glass_center_of_mass = list("x"=16, "y"=9)

		ethanol/manly_dorf
			name = "The Manly Dorf"
			id = "manlydorf"
			description = "The Manly Dorf is an alcoholic beverage made by mixing beer in a glass of ale."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 2

			glass_icon_state = "manlydorfglass"
			glass_name = "glass of The Manly Dorf"
			glass_desc = "A manly concoction made from ale and beer. Intended for true men only."

		ethanol/longislandicedtea
			name = "Long Island Iced Tea"
			id = "longislandicedtea"
			description = "Long Island Iced Tea is a strong alcoholic beverage made by mixing vodka, gin, tequila and Cuba Libre."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 4

			glass_icon_state = "longislandicedteaglass"
			glass_name = "glass of Long Island iced tea"
			glass_desc = "The liquor cabinet brought together in a delicious mix. Intended for middle-aged alcoholic women only."
			glass_center_of_mass = list("x"=16, "y"=8)

		ethanol/moonshine
			name = "Moonshine"
			id = "moonshine"
			description = "Moonshine is a strong, high-proof distilled spirit free of imperfections and toxins that made this drink illegal in the past."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 4

			glass_icon_state = "glass_clear"
			glass_name = "glass of moonshine"
			glass_desc = "The good stuff. What was it made from, this time?"

		ethanol/b52
			name = "B-52"
			id = "b52"
			description = "A B-52 is a strong alcoholic beverage made by mixing Irish cream, cognac, and Kahlua."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 4

			glass_icon_state = "b52glass"
			glass_name = "glass of B-52"
			glass_desc = "Kahlua, Irish cream, and congac. You will get bombed."

		ethanol/irishcoffee
			name = "Irish Coffee"
			id = "irishcoffee"
			description = "Irish Coffee is a moderately-alcoholic beverage made by mixing Irish cream and coffee."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 3

			glass_icon_state = "irishcoffeeglass"
			glass_name = "glass of Irish coffee"
			glass_desc = "Coffee and alcohol. More fun than a Mimosa to drink in the morning."
			glass_center_of_mass = list("x"=15, "y"=10)

		ethanol/margarita
			name = "Margarita"
			id = "margarita"
			description = "A Margarita is a moderately-alcoholic beverage made by mixing lime juice in a glass of tequila."
			color = "#8CFF8C" // rgb: 140, 255, 140
			boozepwr = 3

			glass_icon_state = "margaritaglass"
			glass_name = "glass of margarita"
			glass_desc = "On the rocks with salt on the rim. Arriba~!"
			glass_center_of_mass = list("x"=16, "y"=8)

		ethanol/black_russian
			name = "Black Russian"
			id = "blackrussian"
			description = "A Black Russian is a moderately-alcoholic beverage made by mixing Kahlua in a glass of vodka."
			color = "#360000" // rgb: 54, 0, 0
			boozepwr = 3

			glass_icon_state = "blackrussianglass"
			glass_name = "glass of Black Russian"
			glass_desc = "For the lactose-intolerant. Still as classy as a White Russian."
			glass_center_of_mass = list("x"=16, "y"=9)

		ethanol/manhattan
			name = "Manhattan"
			id = "manhattan"
			description = "A Manhattan is a moderately-alcoholic beverage made by mixing vermouth in a glass of whiskey."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 3

			glass_icon_state = "manhattanglass"
			glass_name = "glass of Manhattan"
			glass_desc = "The Detective's undercover drink of choice. He never could stomach gin..."
			glass_center_of_mass = list("x"=17, "y"=8)

		ethanol/manhattan_proj
			name = "Manhattan Project"
			id = "manhattan_proj"
			description = "A Manhattan Project is a potent, psychedelic, alcoholic beverage. It is a Manhattan infused with uranium."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 5

			glass_icon_state = "proj_manhattanglass"
			glass_name = "glass of Manhattan Project"
			glass_desc = "A scienitst drink of choice, for thinking how to blow up the station."
			glass_center_of_mass = list("x"=17, "y"=8)

			on_mob_life(var/mob/living/M as mob)
				M.druggy = max(M.druggy, 30)
				..()
				return

		ethanol/whiskeysoda
			name = "Whiskey Soda"
			id = "whiskeysoda"
			description = "Whiskey Soda is a moderately-alcoholic beverage made by mixing soda water in a glass of whiskey."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 3

			glass_icon_state = "whiskeysodaglass2"
			glass_name = "glass of whiskey soda"
			glass_desc = "Ultimate refreshment."
			glass_center_of_mass = list("x"=16, "y"=9)

		ethanol/antifreeze
			name = "Anti-freeze"
			id = "antifreeze"
			description = "An Anti-freeze is a strong alcoholic beverage designed to raise body temperatures. It is made from ice and cream in a glass of vodka."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 4

			glass_icon_state = "antifreeze"
			glass_name = "glass of Anti-freeze"
			glass_desc = "The ultimate refreshment."
			glass_center_of_mass = list("x"=16, "y"=8)

			on_mob_life(var/mob/living/M as mob)
				if (M.bodytemperature < 330)
					M.bodytemperature = min(330, M.bodytemperature + (20 * TEMPERATURE_DAMAGE_COEFFICIENT)) //310 is the normal bodytemp. 310.055
				..()
				return

		ethanol/barefoot
			name = "Barefoot"
			id = "barefoot"
			description = "Barefoot is a fruity, mild alcoholic beverage made by mixing berry juice, cream, and vermouth. "
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 1.5

			glass_icon_state = "b&p"
			glass_name = "glass of Barefoot"
			glass_desc = "Barefoot and pregnant."
			glass_center_of_mass = list("x"=17, "y"=8)

		ethanol/snowwhite
			name = "Snow White"
			id = "snowwhite"
			description = "Snow White is a mild alcoholic beverage made by mixing beer and lime juice."
			color = "#FFFFFF" // rgb: 255, 255, 255
			boozepwr = 1.5

			glass_icon_state = "snowwhite"
			glass_name = "glass of Snow White"
			glass_desc = "A cold refreshment, white as its name."
			glass_center_of_mass = list("x"=16, "y"=8)

		ethanol/melonliquor
			name = "Melon Liquor"
			id = "melonliquor"
			description = "Melon Liquor is a mild, green, relatively sweet and fruity 46 proof liquor."
			color = "#138808" // rgb: 19, 136, 8
			boozepwr = 1

			glass_icon_state = "emeraldglass"
			glass_name = "glass of melon liquor"
			glass_desc = "A relatively sweet and fruity 46 proof liquor."
			glass_center_of_mass = list("x"=16, "y"=5)

		ethanol/bluecuracao
			name = "Blue Curacao"
			id = "bluecuracao"
			description = "Blue Curacao is an exotically blue, fruity, mild liquor, distilled from oranges."
			color = "#0000CD" // rgb: 0, 0, 205
			boozepwr = 1.5

			glass_icon_state = "curacaoglass"
			glass_name = "glass of blue curacao"
			glass_desc = "An exotically blue, fruity drink, distilled from oranges. It's beautiful to look at."
			glass_center_of_mass = list("x"=16, "y"=5)

		ethanol/suidream
			name = "Sui Dream"
			id = "suidream"
			description = "Sui Dream is a fruity, very mild alcoholic beverage made by mixing Space-Up, Melon Liquor, and Blue Curacao."
			color = "#00A86B" // rgb: 0, 168, 107
			boozepwr = 0.5

			glass_icon_state = "sdreamglass"
			glass_name = "glass of Sui Dream"
			glass_desc = "A froofy, fruity, and sweet mixed drink. Understanding the name only brings shame."
			glass_center_of_mass = list("x"=16, "y"=5)

		ethanol/demonsblood
			name = "Demons Blood"
			id = "demonsblood"
			description = "Demons' Blood is a dark red, blood-based, moderately-alcoholic beverage made by mixing rum, Mountain Wind, blood, and Dr. Gibb."
			color = "#820000" // rgb: 130, 0, 0
			boozepwr = 3

			glass_icon_state = "demonsblood"
			glass_name = "glass of Demons' Blood"
			glass_desc = "Just looking at this thing makes the hair at the back of your neck stand up."
			glass_center_of_mass = list("x"=16, "y"=2)

		ethanol/vodkatonic
			name = "Vodka and Tonic"
			id = "vodkatonic"
			description = "Vodka and Tonic is a moderately-alcoholic beverage made by mixing tonic water in a glass of vodka."
			color = "#0064C8" // rgb: 0, 100, 200
			boozepwr = 3
			dizzy_adj = 4
			slurr_adj = 3

			glass_icon_state = "vodkatonicglass"
			glass_name = "glass of vodka and tonic"
			glass_desc = "For when a gin and tonic isn't Russian enough."
			glass_center_of_mass = list("x"=16, "y"=7)

		ethanol/ginfizz
			name = "Gin Fizz"
			id = "ginfizz"
			description = "Gin Fizz is a dry-tasting, carbondated, mild alcoholic beverage made by mixing lime juice and soda water in a glass of gin."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 1.5
			dizzy_adj = 4
			slurr_adj = 3

			glass_icon_state = "ginfizzglass"
			glass_name = "glass of gin fizz"
			glass_desc = "Refreshingly lemony, deliciously dry."
			glass_center_of_mass = list("x"=16, "y"=7)

		ethanol/bahama_mama
			name = "Bahama Mama"
			id = "bahama_mama"
			description = "Bahama Mama is a tropical moderately-alcoholic cocktail made from rum, orange juice, lime juice and ice."
			color = "#FF7F3B" // rgb: 255, 127, 59
			boozepwr = 2

			glass_icon_state = "bahama_mama"
			glass_name = "glass of Bahama Mama"
			glass_desc = "Tropical cocktail"
			glass_center_of_mass = list("x"=16, "y"=5)

		ethanol/singulo
			name = "Singulo"
			id = "singulo"
			description = "Singulo, nicknamed the 'blue-space beverage', is a potent alcoholic beverage mimicking the Gravitational Singularity. It is made from mixing vodka, wine, and radium."
			color = "#2E6671" // rgb: 46, 102, 113
			boozepwr = 5
			dizzy_adj = 15
			slurr_adj = 15

			glass_icon_state = "singulo"
			glass_name = "glass of Singulo"
			glass_desc = "A blue-space beverage. Looks like Lord Singuloth."
			glass_center_of_mass = list("x"=17, "y"=4)

		ethanol/sbiten
			name = "Sbiten"
			id = "sbiten"
			description = "Sbiten is a very pungent, spicy, moderately-alcoholic beverage made by mixing capsaicin oil in a glass of vodka."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 3

			glass_icon_state = "sbitenglass"
			glass_name = "glass of Sbiten"
			glass_desc = "A spicy mix of Vodka and Spice. Very hot."
			glass_center_of_mass = list("x"=17, "y"=8)

			on_mob_life(var/mob/living/M as mob)
				if (M.bodytemperature < 360)
					M.bodytemperature = min(360, M.bodytemperature + (50 * TEMPERATURE_DAMAGE_COEFFICIENT)) //310 is the normal bodytemp. 310.055
				..()
				return

		ethanol/devilskiss
			name = "Devils Kiss"
			id = "devilskiss"
			description = "Devil's Kiss is a red, blood-based, moderately-alcoholic beverage made by mixing blood, Kahlua, and rum."
			color = "#A68310" // rgb: 166, 131, 16
			boozepwr = 3

			glass_icon_state = "devilskiss"
			glass_name = "glass of Devil's Kiss"
			glass_desc = "Creepy time!"
			glass_center_of_mass = list("x"=16, "y"=8)

		ethanol/red_mead
			name = "Red Mead"
			id = "red_mead"
			description = "Red Mead is a red, blood-based, mild alcoholic beverage made by mixing blood and mead."
			color = "#C73C00" // rgb: 199, 60, 0
			boozepwr = 1.5

			glass_icon_state = "red_meadglass"
			glass_name = "glass of red mead"
			glass_desc = "A true Viking's beverage, though its color is strange."
			glass_center_of_mass = list("x"=17, "y"=10)

		ethanol/mead
			name = "Mead"
			id = "mead"
			description = "Mead is a sweet, golden, mild alcoholic beverage made with fermented honey and water, flavored with various fruit, spices, grains, or hops. "
			reagent_state = LIQUID
			color = "#FFC800" // rgb: 255, 200, 0
			boozepwr = 1.5
			nutriment_factor = 1 * FOOD_METABOLISM

			glass_icon_state = "meadglass"
			glass_name = "glass of mead"
			glass_desc = "A Viking's beverage, though a cheap one."
			glass_center_of_mass = list("x"=17, "y"=10)

		ethanol/iced_beer
			name = "Iced Beer"
			id = "iced_beer"
			description = "Iced Beer is a mild alcoholic beverage made by mixing a beer chilled with ice."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 1

			glass_icon_state = "iced_beerglass"
			glass_name = "glass of iced beer"
			glass_desc = "A beer so frosty, the air around it freezes."
			glass_center_of_mass = list("x"=16, "y"=7)

			on_mob_life(var/mob/living/M as mob)
				if(M.bodytemperature > 270)
					M.bodytemperature = max(270, M.bodytemperature - (20 * TEMPERATURE_DAMAGE_COEFFICIENT)) //310 is the normal bodytemp. 310.055
				..()
				return

		ethanol/grog
			name = "Grog"
			id = "grog"
			description = "Grog is a very mild alcoholic beverage made by mixing watered-down rum."
			reagent_state = LIQUID
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 0.5

			glass_icon_state = "grogglass"
			glass_name = "glass of grog"
			glass_desc = "A fine and cepa drink for Space."

		ethanol/aloe
			name = "Aloe"
			id = "aloe"
			description = "Aloe is a green, creamy, moderately-alcoholic beverage made by mixing cream, watermelon juice, and whiskey."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 3

			glass_icon_state = "aloe"
			glass_name = "glass of Aloe"
			glass_desc = "Very, very, very good."
			glass_center_of_mass = list("x"=17, "y"=8)

		ethanol/andalusia
			name = "Andalusia"
			id = "andalusia"
			description = "Andalusia is a moderately-alcoholic beverage made by mixing rum, whiskey, and lemon juice."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 3

			glass_icon_state = "andalusia"
			glass_name = "glass of Andalusia"
			glass_desc = "A nice, strange named drink."
			glass_center_of_mass = list("x"=16, "y"=9)

		ethanol/alliescocktail
			name = "Allies Cocktail"
			id = "alliescocktail"
			description = "Allies Cocktail is a moderately-alcoholic beverage made by mixing vodka in a glass of martini."
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 2

			glass_icon_state = "alliescocktail"
			glass_name = "glass of Allies cocktail"
			glass_desc = "A drink made from your allies."
			glass_center_of_mass = list("x"=17, "y"=8)

		ethanol/acid_spit
			name = "Acid Spit"
			id = "acidspit"
			description = "Acid Spit is an acidic, mild alcoholic beverage made by mixing sulphuric acid mixed with wine."
			reagent_state = LIQUID
			color = "#365000" // rgb: 54, 80, 0
			boozepwr = 1.5

			glass_icon_state = "acidspitglass"
			glass_name = "glass of Acid Spit"
			glass_desc = "Did somebody spit acid in this?"
			glass_center_of_mass = list("x"=16, "y"=7)

		ethanol/amasec
			name = "Amasec"
			id = "amasec"
			description = "Amasec is the official drink of the NanoTrasen Gun-Club. It is a moderately- alcoholic beverage made by mixing iron, wine, and vodka."
			reagent_state = LIQUID
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 2

			glass_icon_state = "amasecglass"
			glass_name = "glass of Amasec"
			glass_desc = "Always handy before COMBAT!!!"
			glass_center_of_mass = list("x"=16, "y"=9)

		ethanol/changelingsting
			name = "Changeling Sting"
			id = "changelingsting"
			description = "Changeling Sting is an acidic, potent alcoholic beverage made by mixing lime juice and lemon juice in a glass of Screwdriver."
			color = "#2E6671" // rgb: 46, 102, 113
			boozepwr = 5

			glass_icon_state = "changelingsting"
			glass_name = "glass of Changeling Sting"
			glass_desc = "Note the word 'sting' in the name."

		ethanol/irishcarbomb
			name = "Irish Car Bomb"
			id = "irishcarbomb"
			description = "An Irish Car Bomb is a moderately-alcoholic beverage made by mixing coffee and cream."
			color = "#2E6671" // rgb: 46, 102, 113
			boozepwr = 3
			dizzy_adj = 5

			glass_icon_state = "irishcarbomb"
			glass_name = "glass of Irish Car Bomb"
			glass_desc = "An irish car bomb."
			glass_center_of_mass = list("x"=16, "y"=8)

		ethanol/syndicatebomb
			name = "Syndicate Bomb"
			id = "syndicatebomb"
			description = "Syndicate Bomb is a potent beverage made by mixing cola, beer, and whiskey."
			color = "#2E6671" // rgb: 46, 102, 113
			boozepwr = 5

			glass_icon_state = "syndicatebomb"
			glass_name = "glass of Syndicate Bomb"
			glass_desc = "Beer, cola, and whiskey. Shouldn't hurt."
			glass_center_of_mass = list("x"=16, "y"=4)

		ethanol/erikasurprise
			name = "Erika Surprise"
			id = "erikasurprise"
			description = "A green, moderately-alcoholic beverage made by mixing ale, lime juice, whiskey, a banana, and ice."
			color = "#2E6671" // rgb: 46, 102, 113
			boozepwr = 3

			glass_icon_state = "erikasurprise"
			glass_name = "glass of Erika Surprise"
			glass_desc = "The surprise is, it's green!"
			glass_center_of_mass = list("x"=16, "y"=9)

		ethanol/driestmartini
			name = "Driest Martini"
			id = "driestmartini"
			description = "A Driest Martini is a very dry-tasting alcoholic beverage made by mixing a martini and a glass of nothing."
			nutriment_factor = 1 * FOOD_METABOLISM
			color = "#2E6671" // rgb: 46, 102, 113
			boozepwr = 4

			glass_icon_state = "driestmartiniglass"
			glass_name = "glass of Driest Martini"
			glass_desc = "Only for the experienced. You think you see sand floating in the glass."
			glass_center_of_mass = list("x"=17, "y"=8)

		ethanol/bananahonk
			name = "Banana Mama"
			id = "bananahonk"
			description = "Banana Mama is a sweet, creamy, strong alcoholic beverage made by mixing cream, sugar, and a banana."
			nutriment_factor = 1 * REAGENTS_METABOLISM
			color = "#FFFF91" // rgb: 255, 255, 140
			boozepwr = 4

			glass_icon_state = "bananahonkglass"
			glass_name = "glass of Banana Honk"
			glass_desc = "A drink from Banana Heaven."
			glass_center_of_mass = list("x"=16, "y"=8)

		ethanol/silencer
			name = "Silencer"
			id = "silencer"
			description = "A Silencer is a strong alcoholic beverage made by mixing cream, sugar, and a glass of nothing."
			nutriment_factor = 1 * FOOD_METABOLISM
			color = "#664300" // rgb: 102, 67, 0
			boozepwr = 4

			glass_icon_state = "silencerglass"
			glass_name = "glass of Silencer"
			glass_desc = "A drink from mime Heaven."
			glass_center_of_mass = list("x"=16, "y"=9)

			on_mob_life(var/mob/living/M as mob)
				if(!data) data = 1
				data++
				M.dizziness +=10
				if(data >= 55 && data <115)
					if (!M.stuttering) M.stuttering = 1
					M.stuttering += 10
				else if(data >= 115 && prob(33))
					M.confused = max(M.confused+15,15)
				..()
				return

		ethanol/bluemotorcycle
			name = "Blue Motorcycle A.M.F Cocktail"
			id = "bluemotorcycle"
			description = "Blue Motorcycle is a potent blue cocktail. It is a concoction of a mixture of vodka, tequila, rum, gin, Blue Curacao, Space-up, and Lemon-Lime, then chilled with ice."
			nutriment_factor = 2 * FOOD_METABOLISM //Lots of alcohol, lots of calories.
			color = "#00E1FF" // rgb: 0, 225, 255
			boozepwr = 5 //This has five types of alcohol in it. You won't finish two drinks without suffering heavy consequences.
			dizzy_adj =5
			slurr_adj = 5
			slur_start = 15
			confused_start = 30

			glass_icon_state = "amfglass"
			glass_name = "glass of Blue Motorcycle A.M.F Cocktail"
			glass_desc = "Adios, my friend."
			glass_center_of_mass = list("x"=16, "y"=7)


// Undefine the alias for REAGENTS_EFFECT_MULTIPLER
#undef REM
