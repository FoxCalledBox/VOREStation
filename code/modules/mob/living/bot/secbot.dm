#define SECBOT_WAIT_TIME	3		//Around number*2 real seconds to surrender.
#define SECBOT_THREAT_ARREST 4		//threat level at which we decide to arrest someone
#define SECBOT_THREAT_ATTACK 8		//threat level at which was assume immediate danger and attack right away

/mob/living/bot/secbot
	name = "Securitron"
	desc = "A little security robot.  He looks less than thrilled."
	icon_state = "secbot0"
	maxHealth = 100
	health = 100
	req_one_access = list(access_security, access_forensics_lockers)
	botcard_access = list(access_security, access_sec_doors, access_forensics_lockers, access_maint_tunnels)
	patrol_speed = 2
	target_speed = 3

	var/default_icon_state = "secbot"
	var/idcheck = FALSE // If true, arrests for having weapons without authorization.
	var/check_records = FALSE // If true, arrests people without a record.
	var/check_arrest = TRUE // If true, arrests people who are set to arrest.
	var/arrest_type = FALSE // If true, doesn't handcuff. You monster.
	var/declare_arrests = FALSE // If true, announces arrests over sechuds.
	var/threat = 0 // How much of a threat something is. Set upon acquiring a target.
	var/attacked = FALSE // If true, gives the bot enough threat assessment to attack immediately.

	var/is_ranged = FALSE
	var/awaiting_surrender = 0
	var/can_next_insult = 0			// Uses world.time
	var/stun_strength = 60			// For humans.
	var/xeno_harm_strength = 15 	// How hard to hit simple_mobs.
	var/baton_glow = "#FF6A00"

	var/used_weapon	= /obj/item/weapon/melee/baton	//Weapon used by the bot

	var/list/threat_found_sounds = list('sound/voice/bcriminal.ogg', 'sound/voice/bjustice.ogg', 'sound/voice/bfreeze.ogg')
	var/list/preparing_arrest_sounds = list('sound/voice/bgod.ogg', 'sound/voice/biamthelaw.ogg', 'sound/voice/bsecureday.ogg', 'sound/voice/bradio.ogg', 'sound/voice/bcreep.ogg')
	var/list/fighting_sounds = list('sound/voice/biamthelaw.ogg', 'sound/voice/bradio.ogg', 'sound/voice/bjustice.ogg')
//VOREStation Add - They don't like being pulled. This is going to fuck with slimesky, but meh.
/mob/living/bot/secbot/Life()
	..()
	if(health > 0 && on && pulledby)
		if(isliving(pulledby))
			var/mob/living/L = pulledby
			UnarmedAttack(L)
			say("Do not interfere with active law enforcement routines!")
			global_announcer.autosay("[src] was interfered with in <b>[get_area(src)]</b>, activating defense routines.", "[src]", "Security")
//VOREStation Add End
/mob/living/bot/secbot/beepsky
	name = "Officer Beepsky"
	desc = "It's Officer Beep O'sky! Powered by a potato and a shot of whiskey."
	will_patrol = TRUE

/mob/living/bot/secbot/slime
	name = "Slime Securitron"
	desc = "A little security robot, with a slime baton subsituted for the regular one."
	default_icon_state = "slimesecbot"
	stun_strength = 10 // Slimebatons aren't meant for humans.

	xeno_harm_strength = 9 // Weaker than regular slimesky but they can stun.
	baton_glow = "#33CCFF"
	req_one_access = list(access_research, access_robotics)
	botcard_access = list(access_research, access_robotics, access_xenobiology, access_xenoarch, access_tox, access_tox_storage, access_maint_tunnels)
	used_weapon = /obj/item/weapon/melee/baton/slime
	var/xeno_stun_strength = 5 // How hard to slimebatoned()'d naughty slimes. 5 works out to 2 discipline and 5 weaken.

/mob/living/bot/secbot/slime/slimesky
	name = "Doctor Slimesky"
	desc = "An old friend of Officer Beep O'sky.  He prescribes beatings to rowdy slimes so that real doctors don't need to treat the xenobiologists."

/mob/living/bot/secbot/update_icons()
	if(on && busy)
		icon_state = "[default_icon_state]-c"
	else
		icon_state = "[default_icon_state][on]"

	if(on)
		set_light(2, 1, baton_glow)
	else
		set_light(0)

/mob/living/bot/secbot/attack_hand(var/mob/user)
	user.set_machine(src)
	var/list/dat = list()
	dat += "<TT><B>Automatic Security Unit</B></TT><BR><BR>"
	dat += "Status: <A href='?src=\ref[src];power=1'>[on ? "On" : "Off"]</A><BR>"
	dat += "Behaviour controls are [locked ? "locked" : "unlocked"]<BR>"
	dat += "Maintenance panel is [open ? "opened" : "closed"]"
	if(!locked || issilicon(user))
		dat += "<BR>Check for Weapon Authorization: <A href='?src=\ref[src];operation=idcheck'>[idcheck ? "Yes" : "No"]</A><BR>"
		dat += "Check Security Records: <A href='?src=\ref[src];operation=ignorerec'>[check_records ? "Yes" : "No"]</A><BR>"
		dat += "Check Arrest Status: <A href='?src=\ref[src];operation=ignorearr'>[check_arrest ? "Yes" : "No"]</A><BR>"
		dat += "Operating Mode: <A href='?src=\ref[src];operation=switchmode'>[arrest_type ? "Detain" : "Arrest"]</A><BR>"
		dat += "Report Arrests: <A href='?src=\ref[src];operation=declarearrests'>[declare_arrests ? "Yes" : "No"]</A><BR>"
		if(using_map.bot_patrolling)
			dat += "Auto Patrol: <A href='?src=\ref[src];operation=patrol'>[will_patrol ? "On" : "Off"]</A>"
	var/datum/browser/popup = new(user, "autosec", "Securitron controls")
	popup.set_content(jointext(dat,null))
	popup.open()

/mob/living/bot/secbot/Topic(href, href_list)
	if(..())
		return

	usr.set_machine(src)
	add_fingerprint(usr)

	if((href_list["power"]) && (access_scanner.allowed(usr)))
		if(on)
			turn_off()
		else
			turn_on()
		return

	switch(href_list["operation"])
		if("idcheck")
			idcheck = !idcheck
		if("ignorerec")
			check_records = !check_records
		if("ignorearr")
			check_arrest = !check_arrest
		if("switchmode")
			arrest_type = !arrest_type
		if("patrol")
			will_patrol = !will_patrol
		if("declarearrests")
			declare_arrests = !declare_arrests
	attack_hand(usr)

/mob/living/bot/secbot/emag_act(var/remaining_uses, var/mob/user)
	. = ..()
	if(!emagged)
		if(user)
			to_chat(user, "<span class='notice'>\The [src] buzzes and beeps.</span>")
		emagged = TRUE
		patrol_speed = 3
		target_speed = 4
		return TRUE
	else
		to_chat(user, "<span class='notice'>\The [src] is already corrupt.</span>")

/mob/living/bot/secbot/attackby(var/obj/item/O, var/mob/user)
	var/curhealth = health
	. = ..()
	if(health < curhealth && on == TRUE)
		react_to_attack(user)

/mob/living/bot/secbot/bullet_act(var/obj/item/projectile/P)
	var/curhealth = health
	var/mob/shooter = P.firer
	. = ..()
	//if we already have a target just ignore to avoid lots of checking
	if(!target && health < curhealth && shooter && (shooter in view(world.view, src)))
		react_to_attack(shooter)

/mob/living/bot/secbot/attack_generic(var/mob/attacker)
	if(attacker)
		react_to_attack(attacker)
	..()

/mob/living/bot/secbot/proc/react_to_attack(mob/attacker)
	if(!on)		// We don't want it to react if it's off
		return

	if(!target)
		playsound(src.loc, pick(threat_found_sounds), 50)
		global_announcer.autosay("[src] was attacked by a hostile <b>[target_name(attacker)]</b> in <b>[get_area(src)]</b>.", "[src]", "Security")
	target = attacker
	attacked = TRUE

// Say "freeze!" and demand surrender
/mob/living/bot/secbot/proc/demand_surrender(mob/target, var/threat)
	var/suspect_name = target_name(target)
	if(declare_arrests)
		global_announcer.autosay("[src] is [arrest_type ? "detaining" : "arresting"] a level [threat] suspect <b>[suspect_name]</b> in <b>[get_area(src)]</b>.", "[src]", "Security")
	say("Down on the floor, [suspect_name]! You have [SECBOT_WAIT_TIME*2] seconds to comply.")
	playsound(src.loc, pick(preparing_arrest_sounds), 50)
	// Register to be told when the target moves
	GLOB.moved_event.register(target, src, /mob/living/bot/secbot/proc/target_moved)

// Callback invoked if the registered target moves
/mob/living/bot/secbot/proc/target_moved(atom/movable/moving_instance, atom/old_loc, atom/new_loc)
	if(get_dist(get_turf(src), get_turf(target)) >= 1)
		awaiting_surrender = INFINITY	// Done waiting!
		GLOB.moved_event.unregister(moving_instance, src)

/mob/living/bot/secbot/resetTarget()
	..()
	GLOB.moved_event.unregister(target, src)
	awaiting_surrender = 0
	attacked = FALSE
	walk_to(src, 0)

/mob/living/bot/secbot/startPatrol()
	if(!locked) // Stop running away when we set you up
		return
	..()

/mob/living/bot/secbot/confirmTarget(var/atom/A)
	if(!..())
		return FALSE
	check_threat(A)
	if(threat >= SECBOT_THREAT_ARREST)
		return TRUE

/mob/living/bot/secbot/lookForTargets()
	for(var/mob/living/M in view(src))
		if(M.stat == DEAD)
			continue
		if(confirmTarget(M))
			target = M
			awaiting_surrender = 0
			say("Level [threat] infraction alert!")
			custom_emote(1, "points at [M.name]!")
			playsound(src.loc, pick(threat_found_sounds), 50)
			return

/mob/living/bot/secbot/handleAdjacentTarget()
	var/mob/living/carbon/human/H = target
	check_threat(target)
	if(awaiting_surrender < SECBOT_WAIT_TIME && istype(H) && !H.lying && threat < SECBOT_THREAT_ATTACK)
		if(awaiting_surrender == 0) // On first tick of awaiting...
			demand_surrender(target, threat)
		++awaiting_surrender
	else
		if(declare_arrests)
			var/action = arrest_type ? "detaining" : "arresting"
			if(!ishuman(target))
				action = "fighting"
			global_announcer.autosay("[src] is [action] a level [threat] [action != "fighting" ? "suspect" : "threat"] <b>[target_name(target)]</b> in <b>[get_area(src)]</b>.", "[src]", "Security")
		UnarmedAttack(target)

// So Beepsky talks while beating up simple mobs.
/mob/living/bot/secbot/proc/insult(var/mob/living/L)
	if(can_next_insult > world.time)
		return
	if(threat >= 10)
		playsound(src.loc, 'sound/voice/binsult.ogg', 75)
		can_next_insult = world.time + 20 SECONDS
	else
		playsound(src.loc, pick(fighting_sounds), 75)
		can_next_insult = world.time + 5 SECONDS


/mob/living/bot/secbot/UnarmedAttack(var/mob/M, var/proximity)
	if(!..())
		return

	if(!istype(M))
		return

	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/cuff = TRUE

		if(!H.lying || H.handcuffed || arrest_type)
			cuff = FALSE
		if(!cuff)
			H.stun_effect_act(0, stun_strength, null)
			playsound(loc, 'sound/weapons/Egloves.ogg', 50, 1, -1)
			do_attack_animation(H)
			busy = TRUE
			update_icons()
			spawn(2)
				busy = FALSE
				update_icons()
			visible_message("<span class='warning'>\The [H] was prodded by \the [src] with a stun baton!</span>")
			insult(H)
		else
			playsound(loc, 'sound/weapons/handcuffs.ogg', 30, 1, -2)
			visible_message("<span class='warning'>\The [src] is trying to put handcuffs on \the [H]!</span>")
			busy = TRUE
			if(do_mob(src, H, 60))
				if(!H.handcuffed)
					if(istype(H.back, /obj/item/weapon/rig) && istype(H.gloves,/obj/item/clothing/gloves/gauntlets/rig))
						H.handcuffed = new /obj/item/weapon/handcuffs/cable(H) // Better to be cable cuffed than stun-locked
					else
						H.handcuffed = new /obj/item/weapon/handcuffs(H)
					H.update_inv_handcuffed()
			busy = FALSE
	else if(istype(M, /mob/living))
		var/mob/living/L = M
		L.adjustBruteLoss(xeno_harm_strength)
		do_attack_animation(M)
		playsound(loc, "swing_hit", 50, 1, -1)
		busy = TRUE
		update_icons()
		spawn(2)
			busy = FALSE
			update_icons()
		visible_message("<span class='warning'>\The [M] was beaten by \the [src] with a stun baton!</span>")
		insult(L)

/mob/living/bot/secbot/slime/UnarmedAttack(var/mob/living/L, var/proximity)
	..()

	if(istype(L, /mob/living/simple_mob/slime/xenobio))
		var/mob/living/simple_mob/slime/xenobio/S = L
		S.slimebatoned(src, xeno_stun_strength)

/mob/living/bot/secbot/explode()
	visible_message("<span class='warning'>[src] blows apart!</span>")
	var/turf/Tsec = get_turf(src)

	var/obj/item/weapon/secbot_assembly/Sa = new /obj/item/weapon/secbot_assembly(Tsec)
	Sa.build_step = 1
	Sa.overlays += image('icons/obj/aibots.dmi', "hs_hole")
	Sa.created_name = name
	new /obj/item/device/assembly/prox_sensor(Tsec)
	new used_weapon(Tsec)
	if(prob(50))
		new /obj/item/robot_parts/l_arm(Tsec)

	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
	s.set_up(3, 1, src)
	s.start()

	new /obj/effect/decal/cleanable/blood/oil(Tsec)
	qdel(src)

/mob/living/bot/secbot/proc/target_name(mob/living/T)
	if(ishuman(T))
		var/mob/living/carbon/human/H = T
		return H.get_id_name("unidentified person")
	return "unidentified lifeform"

/mob/living/bot/secbot/proc/check_threat(var/mob/living/M)
	if(!M || !istype(M) || M.stat == DEAD || src == M)
		threat = 0

	else if(emagged && !M.incapacitated()) //check incapacitated so emagged secbots don't keep attacking the same target forever
		threat = 10

	else
		threat = M.assess_perp(access_scanner, 0, idcheck, check_records, check_arrest) // Set base threat level
		if(attacked)
			threat += SECBOT_THREAT_ATTACK // Increase enough so we can attack immediately in return

//Secbot Construction

/obj/item/clothing/head/helmet/attackby(var/obj/item/device/assembly/signaler/S, mob/user as mob)
	..()
	if(!issignaler(S))
		..()
		return

	if(type != /obj/item/clothing/head/helmet) //Eh, but we don't want people making secbots out of space helmets.
		return

	if(S.secured)
		qdel(S)
		var/obj/item/weapon/secbot_assembly/A = new /obj/item/weapon/secbot_assembly
		user.put_in_hands(A)
		user << "You add the signaler to the helmet."
		user.drop_from_inventory(src)
		qdel(src)
	else
		return

/obj/item/weapon/secbot_assembly
	name = "helmet/signaler assembly"
	desc = "Some sort of bizarre assembly."
	icon = 'icons/obj/aibots.dmi'
	icon_state = "helmet_signaler"
	item_icons = list(
			slot_l_hand_str = 'icons/mob/items/lefthand_hats.dmi',
			slot_r_hand_str = 'icons/mob/items/righthand_hats.dmi',
			)
	item_state = "helmet"
	var/build_step = 0
	var/created_name = "Securitron"

/obj/item/weapon/secbot_assembly/attackby(var/obj/item/W, var/mob/user)
	..()
	if(istype(W, /obj/item/weapon/weldingtool) && !build_step)
		var/obj/item/weapon/weldingtool/WT = W
		if(WT.remove_fuel(0, user))
			build_step = 1
			overlays += image('icons/obj/aibots.dmi', "hs_hole")
			to_chat(user, "You weld a hole in \the [src].")

	else if(isprox(W) && (build_step == 1))
		user.drop_item()
		build_step = 2
		to_chat(user, "You add \the [W] to [src].")
		overlays += image('icons/obj/aibots.dmi', "hs_eye")
		name = "helmet/signaler/prox sensor assembly"
		qdel(W)

	else if((istype(W, /obj/item/robot_parts/l_arm) || istype(W, /obj/item/robot_parts/r_arm) || (istype(W, /obj/item/organ/external/arm) && ((W.name == "robotic right arm") || (W.name == "robotic left arm")))) && build_step == 2)
		user.drop_item()
		build_step = 3
		to_chat(user, "You add \the [W] to [src].")
		name = "helmet/signaler/prox sensor/robot arm assembly"
		overlays += image('icons/obj/aibots.dmi', "hs_arm")
		qdel(W)

	else if(istype(W, /obj/item/weapon/melee/baton) && build_step == 3)
		user.drop_item()
		to_chat(user, "You complete the Securitron! Beep boop.")
		if(istype(W, /obj/item/weapon/melee/baton/slime))
			var/mob/living/bot/secbot/slime/S = new /mob/living/bot/secbot/slime(get_turf(src))
			S.name = created_name
		else
			var/mob/living/bot/secbot/S = new /mob/living/bot/secbot(get_turf(src))
			S.name = created_name
		qdel(W)
		qdel(src)

	else if(istype(W, /obj/item/weapon/pen))
		var/t = sanitizeSafe(input(user, "Enter new robot name", name, created_name), MAX_NAME_LEN)
		if(!t)
			return
		if(!in_range(src, user) && loc != user)
			return
		created_name = t