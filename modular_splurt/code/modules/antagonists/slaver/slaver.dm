GLOBAL_VAR_INIT(slavers_team_name, "Slave Traders")
GLOBAL_VAR_INIT(slavers_credits_balance, 4000)
GLOBAL_VAR_INIT(slavers_credits_total, 0)
GLOBAL_VAR_INIT(slavers_slaves_sold, 0)
GLOBAL_VAR_INIT(slavers_last_announcement, 0)

/datum/antagonist/slaver
	name = "Slave Trader"
	roundend_category = "slaver"
	antagpanel_category = "Slaver"
	job_rank = ROLE_SLAVER
	antag_moodlet = /datum/mood_event/focused
	threat = 7
	show_to_ghosts = TRUE
	var/datum/team/slavers/slaver_team = new /datum/team/slavers
	var/slaver_outfit = /datum/outfit/slaver
	var/send_to_spawnpoint = TRUE //Should the user be moved to default spawnpoint.

/datum/antagonist/slaver/proc/update_slaver_icons_added(mob/living/M)
	var/datum/atom_hud/antag/slaverhud = GLOB.huds[ANTAG_HUD_SLAVER]
	slaverhud.join_hud(M)
	set_antag_hud(M, "slaver")

/datum/antagonist/slaver/proc/update_slaver_icons_removed(mob/living/M)
	var/datum/atom_hud/antag/slaverhud = GLOB.huds[ANTAG_HUD_SLAVER]
	slaverhud.leave_hud(M)
	set_antag_hud(M, null)

/datum/antagonist/slaver/apply_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	update_slaver_icons_added(M)

/datum/antagonist/slaver/remove_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	update_slaver_icons_removed(M)

/datum/antagonist/slaver/proc/equip_slaver()
	if(!ishuman(owner.current))
		return
	var/mob/living/carbon/human/H = owner.current

	H.equipOutfit(slaver_outfit)
	return TRUE

/datum/antagonist/slaver/greet()
	owner.assigned_role = ROLE_SLAVER
	owner.current.playsound_local(get_turf(owner.current), 'modular_splurt/sound/ambience/antag/slavers.ogg',100,0)
	to_chat(owner, "<B>You are a Slave Trader!</B>")
	spawnText()

/datum/antagonist/slaver/on_gain()
	forge_objectives()
	. = ..()
	equip_slaver()
	if(send_to_spawnpoint)
		move_to_spawnpoint()

	// Can see what players consent to being a victim
	var/datum/atom_hud/H = GLOB.huds[DATA_HUD_ANTAGTARGET]
	H.add_hud_to(owner.current)

// Lose antag status
/datum/antagonist/slaver/farewell()
	// Can no longer see what players consent to being a victim
	var/datum/atom_hud/H = GLOB.huds[DATA_HUD_ANTAGTARGET]
	H.remove_hud_from(owner.current)

/datum/antagonist/slaver/get_team()
	return slaver_team

/datum/antagonist/slaver/proc/forge_objectives()
	objectives |= slaver_team.objectives

/datum/antagonist/slaver/proc/move_to_spawnpoint()
	owner.current.forceMove(GLOB.slaver_start[(0 % GLOB.slaver_start.len) + 1])

/datum/antagonist/slaver/leader/move_to_spawnpoint()
	owner.current.forceMove(pick(GLOB.slaver_leader_start))

/datum/antagonist/slaver/admin_add(datum/mind/new_owner,mob/admin)
	send_to_spawnpoint = FALSE
	new_owner.assigned_role = ROLE_SLAVER
	new_owner.add_antag_datum(src)
	message_admins("[key_name_admin(admin)] has slaver'd [new_owner.current].")
	log_admin("[key_name(admin)] has slaver'd [new_owner.current].")

/datum/antagonist/slaver/get_admin_commands()
	. = ..()
	.["Send to base"] = CALLBACK(src,.proc/admin_send_to_base)

/datum/antagonist/slaver/proc/admin_send_to_base(mob/admin)
	owner.current.forceMove(pick(GLOB.slaver_start))

/datum/antagonist/slaver/leader
	name = "Slave Master"
	slaver_outfit = /datum/outfit/slaver/leader

/datum/antagonist/slaver/leader/greet()
	owner.assigned_role = ROLE_SLAVER_LEADER
	owner.current.playsound_local(get_turf(owner.current), 'modular_splurt/sound/ambience/antag/slavers.ogg',100,0)
	to_chat(owner, "<B>You are the Slave Master!</B>")
	spawnText()
	addtimer(CALLBACK(src, .proc/slavers_name_assign), 1)

/datum/antagonist/slaver/proc/spawnText()
	to_chat(owner, "<br><B>You are tasked with infiltrating the station and kidnapping members of the crew. Once brought back to the hideout, they can be collared and priced using the console.</B>")
	to_chat(owner, "<B>The station can choose whether to pay the ransom, and if they do, you can take the slave to the green floor and use the console to 'export' them back, where the ransom will then be paid to your crew to buy new gear. Make sure you give all of the slave's items back before exporting them.</B>")
	to_chat(owner, "<br><B><span class='adminhelp'>Important:</span> This role does NOT mean you can break server rules. Additionally to avoid round removing people, you can <span class='adminnotice'>only kidnap crew who consent OOC</span>.</B>")
	to_chat(owner, "<B>You have a special HUD that shows consent for each player at the bottom right of their sprite. A tick means you can kidnap them. A cross means do not. A question mark means ask first.</B>")

/datum/antagonist/slaver/leader/proc/slavers_name_assign()
	GLOB.slavers_team_name = ask_name()

/datum/antagonist/slaver/leader/proc/ask_name()
	var/defaultname = GLOB.slavers_team_name
	var/newname = stripped_input(owner.current, "You are the slave master. Please choose a name for your crew.", "Crew name", defaultname)
	if (!newname)
		newname = defaultname
	else
		newname = reject_bad_name(newname)
		if(!newname)
			newname = defaultname

	return capitalize(newname)

/datum/team/slavers
	var/core_objective = /datum/objective/slaver

/datum/team/slavers/proc/update_objectives()
	if(core_objective)
		var/datum/objective/O = new core_objective
		O.team = src
		objectives += O

/datum/team/slavers/roundend_report()
	var/list/parts = list()
	parts += "<span class='header'>Slave Traders:</span>"

	var/text = "<br><span class='header'>The crew were:</span>"
	var/slavesSold = GLOB.slavers_slaves_sold
	var/earnedMoney = GLOB.slavers_credits_total
	var/slavesUnsold = 0

	var/all_dead = TRUE
	for(var/datum/mind/M in members)
		if(considered_alive(M))
			all_dead = FALSE

	for(var/obj/item/electropack/shockcollar/slave/collar in GLOB.tracked_slaves)
		if (isliving(collar.loc))
			slavesUnsold++

	text += "<br>"
	text += printplayerlist(members)
	text += "<br>"
	text += "<b>Slaves sold:</b> [slavesSold]<br>"
	text += "<b>Slaves not sold:</b> [slavesUnsold]<br>"
	text += "<b>Total money earned:</b> [earnedMoney]cr (needed at least 30,000cr)"

	// var/datum/objective/slaver/O = locate() in objectives
	if(GLOB.slavers_credits_total >= 30000 && !all_dead)
		parts += "<span class='greentext'>The slaver crew were successful!</span>"
	else
		parts += "<span class='redtext'>The slaver crew have failed.</span>"

	parts += text

	return "<div class='panel redborder'>[parts.Join("<br>")]</div>"

/proc/is_slaver(mob/M)
	return M && istype(M) && M.mind && M.mind.has_antag_datum(/datum/antagonist/slaver)
