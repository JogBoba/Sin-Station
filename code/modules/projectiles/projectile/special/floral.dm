/obj/item/projectile/energy/floramut
	name = "alpha somatoray"
	icon_state = "energy"
	damage = 0
	damage_type = TRUE
	nodamage = 1
	flag = ENERGY

/obj/item/projectile/energy/floramut/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/C = target
		if(C.dna.species.id == "pod")
			C.randmuti()
			C.randmut()
			C.updateappearance()
			C.domutcheck()

/obj/item/projectile/energy/florayield
	name = "beta somatoray"
	icon_state = "energy2"
	damage = 0
	damage_type = TOX
	nodamage = TRUE
	flag = ENERGY

/obj/item/projectile/energy/florarevolution
	name = "gamma somatorary"
	icon_state = "energy3"
	damage = 0
	damage_type = TOX
	nodamage = TRUE
	flag = ENERGY
