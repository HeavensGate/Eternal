// Station voidsuits
//Engineering rig
/obj/item/clothing/head/helmet/space/void/engineering
	name = "engineering voidsuit helmet"
	desc = "A special helmet designed for work in a hazardous, low-pressure environment. Has radiation shielding."
	icon_state = "rig0-engineering"
	item_state = "eng_helm"
	armor = list(melee = 40, bullet = 5, laser = 20,energy = 5, bomb = 35, bio = 100, rad = 80)

/obj/item/clothing/suit/space/void/engineering
	name = "engineering voidsuit"
	desc = "A special suit that protects against hazardous, low pressure environments. Has radiation shielding."
	icon_state = "rig-engineering"
	item_state = "eng_voidsuit"
	slowdown = 1
	armor = list(melee = 40, bullet = 5, laser = 20,energy = 5, bomb = 35, bio = 100, rad = 80)
	allowed = list(/obj/item/device/flashlight,/obj/item/weapon/tank,/obj/item/device/suit_cooling_unit,/obj/item/weapon/storage/bag/ore,/obj/item/device/t_scanner,/obj/item/weapon/pickaxe, /obj/item/weapon/rcd)

//Mining rig
/obj/item/clothing/head/helmet/space/void/mining
	name = "mining voidsuit helmet"
	desc = "A special helmet designed for work in a hazardous, low pressure environment. Has reinforced plating."
	icon_state = "rig0-mining"
	item_state = "mining_helm"
	item_color = "mining"
	armor = list(melee = 50, bullet = 5, laser = 20,energy = 5, bomb = 55, bio = 100, rad = 20)
	light_overlay = "helmet_light_dual"

/obj/item/clothing/suit/space/void/mining
	icon_state = "rig-mining"
	name = "mining voidsuit"
	desc = "A special suit that protects against hazardous, low pressure environments. Has reinforced plating."
	item_state = "mining_voidsuit"
	armor = list(melee = 50, bullet = 5, laser = 20,energy = 5, bomb = 55, bio = 100, rad = 20)

//Medical Rig
/obj/item/clothing/head/helmet/space/void/medical
	name = "medical voidsuit helmet"
	desc = "A special helmet designed for work in a hazardous, low pressure environment. Has minor radiation shielding."
	icon_state = "rig0-medical"
	item_state = "medical_helm"
	item_color = "medical"
	armor = list(melee = 30, bullet = 5, laser = 20,energy = 5, bomb = 25, bio = 100, rad = 50)

/obj/item/clothing/suit/space/void/medical
	icon_state = "rig-medical"
	name = "medical voidsuit"
	desc = "A special suit that protects against hazardous, low pressure environments. Has minor radiation shielding."
	item_state = "medical_voidsuit"
	allowed = list(/obj/item/device/flashlight,/obj/item/weapon/tank,/obj/item/device/suit_cooling_unit,/obj/item/weapon/storage/firstaid,/obj/item/device/healthanalyzer,/obj/item/stack/medical)
	armor = list(melee = 30, bullet = 5, laser = 20,energy = 5, bomb = 25, bio = 100, rad = 50)

	//Security
/obj/item/clothing/head/helmet/space/void/security
	name = "security voidsuit helmet"
	desc = "A special helmet designed for work in a hazardous, low pressure environment. Has an additional layer of armor."
	icon_state = "rig0-sec"
	item_state = "sec_helm"
	item_color = "sec"
	armor = list(melee = 60, bullet = 10, laser = 30, energy = 5, bomb = 45, bio = 100, rad = 10)
	siemens_coefficient = 0.7
	light_overlay = "helmet_light_dual"

/obj/item/clothing/suit/space/void/security
	icon_state = "rig-sec"
	name = "security voidsuit"
	desc = "A special suit that protects against hazardous, low pressure environments. Has an additional layer of armor."
	item_state = "sec_voidsuit"
	armor = list(melee = 60, bullet = 10, laser = 30, energy = 5, bomb = 45, bio = 100, rad = 10)
	allowed = list(/obj/item/weapon/gun,/obj/item/device/flashlight,/obj/item/weapon/tank,/obj/item/device/suit_cooling_unit,/obj/item/weapon/melee/baton)
	siemens_coefficient = 0.7

//Atmospherics Rig (BS12)
/obj/item/clothing/head/helmet/space/void/atmos
	desc = "A special helmet designed for work in a hazardous, low pressure environments. Has improved thermal protection and minor radiation shielding."
	name = "atmospherics voidsuit helmet"
	icon_state = "rig0-atmos"
	item_state = "atmos_helm"
	item_color = "atmos"
	armor = list(melee = 40, bullet = 5, laser = 20,energy = 5, bomb = 35, bio = 100, rad = 50)
	max_heat_protection_temperature = FIRE_HELMET_MAX_HEAT_PROTECTION_TEMPERATURE
	light_overlay = "helmet_light_dual"

/obj/item/clothing/suit/space/void/atmos
	desc = "A special suit that protects against hazardous, low pressure environments. Has improved thermal protection and minor radiation shielding."
	icon_state = "rig-atmos"
	name = "atmos voidsuit"
	item_state = "atmos_voidsuit"
	armor = list(melee = 40, bullet = 5, laser = 20,energy = 5, bomb = 35, bio = 100, rad = 50)
	max_heat_protection_temperature = FIRESUIT_MAX_HEAT_PROTECTION_TEMPERATURE

// Machine Hardsuits. Yee.
/obj/item/clothing/head/helmet/space/void/machine
	name = "Liquid cooled helmet"
	desc = "Looks almost like a useless metal box. Does a head even fit in this thing?"
	armor = list(melee = 40, bullet = 5, laser = 20,energy = 5, bomb = 35, bio = 100, rad = 50)
	max_heat_protection_temperature = SPACE_SUIT_MAX_HEAT_PROTECTION_TEMPERATURE
	species_restricted = list("Machine")
	slowdown = 1

/obj/item/clothing/head/helmet/space/void/machine/blue
	icon_state = "rig0-ipcblue"  //Sprites by Miss Teddybears
	item_state = "rig0-ipcblue"
	item_color = "ipcblue"

/obj/item/clothing/head/helmet/space/void/machine/merc
	icon_state = "rig0-ipcsyndie"  //Sprites by Miss Teddybears, Modified by 5crownix
	item_state = "rig0-ipcsyndie"
	item_color = "ipcsyndie"

/obj/item/clothing/head/helmet/space/void/machine/miner
	icon_state = "rig0-ipcminer"  //Sprites by Miss Teddybears, Modified by 5crownix
	item_state = "rig0-ipcminer"
	item_color = "ipcminer"

/obj/item/clothing/suit/space/void/machine
	name = "Liquid cooled voidsuit"
	desc = "A heavy chassis with ports lining the inside. Would not recommend being inside if you don't have anywhere to plug in."
	armor = list(melee = 40, bullet = 5, laser = 20,energy = 5, bomb = 35, bio = 100, rad = 50)
	allowed = list(/obj/item/device/flashlight,/obj/item/weapon/tank,/obj/item/weapon/storage/bag/ore,/obj/item/device/t_scanner,/obj/item/weapon/pickaxe, /obj/item/weapon/rcd)
	heat_protection = UPPER_TORSO|LOWER_TORSO|LEGS|FEET|ARMS|HANDS
	max_heat_protection_temperature = SPACE_SUIT_MAX_HEAT_PROTECTION_TEMPERATURE
	species_restricted = list("Machine")
	slowdown = 1

/obj/item/clothing/suit/space/void/machine/blue
	icon_state = "rig-ipcblue"  //Sprites by Miss Teddybears
	item_state = "rig-ipcblue"

/obj/item/clothing/suit/space/void/machine/syndie
	icon_state = "rig-ipcsyndie"  //Sprites by Miss Teddybears, Modified by 5crownix
	item_state = "rig-ipcsyndie"

/obj/item/clothing/suit/space/void/machine/miner
	icon_state = "rig-ipcminer"  //Sprites by Miss Teddybears, Modified by 5crownix
	item_state = "rig-ipcminer"