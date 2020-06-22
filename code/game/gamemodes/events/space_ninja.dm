/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+++++++++++++++++++++++++++++++++++++//                //++++++++++++++++++++++++++++++++++
======================================SPACE NINJA SETUP====================================
___________________________________________________________________________________________
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

/*
	README:

	Data:

	>> space_ninja.dm << is this file. It contains a variety of procs related to either spawning space ninjas,
	modifying their verbs, various help procs, testing debug-related content, or storing unused procs for later.
	Similar functions should go into this file, along with anything else that may not have an explicit category.
	IMPORTANT: actual ninja suit, gloves, etc, are stored under the appropriate clothing files. If you need to change
	variables or look them up, look there. Easiest way is through the map file browser.

	>> ninja_abilities.dm << contains all the ninja-related powers. Spawning energy swords, teleporting, and the like.
	If more powers are added, or perhaps something related to powers, it should go there. Make sure to describe
	what an ability/power does so it's easier to reference later without looking at the code.
	IMPORTANT: verbs are still somewhat funky to work with. If an argument is specified but is not referenced in a way
	BYOND likes, in the code content, the verb will fail to trigger. Nothing will happen, literally, when clicked.
	This can be bypassed by either referencing the argument properly, or linking to another proc with the argument
	attached. The latter is what I like to do for certain cases--sometimes it's necessary to do that regardless.

	>> ninja_equipment.dm << deals with all the equipment-related procs for a ninja. Primarily it has the suit, gloves,
	and mask. The suit is by far the largest section of code out of the three and includes a lot of code that ties in
	to other functions. This file has gotten kind of large so breaking it up may be in order. I use section hearders.
	IMPORTANT: not much to say here. Follow along with the comments and adding new functions should be a breeze. Also
	know that certain equipment pieces are linked in other files. The energy blade, for example, has special
	functions defined in the appropriate files (airlock, securestorage, etc).

	General Notes:

	I created space ninjas with the expressed purpose of spicing up boring rounds. That is, ninjas are to xenos as marauders are to
	death squads. Ninjas are stealthy, tech-savvy, and powerful. Not to say marauders are all of those things, but a clever ninja
	should have little problem murderampaging their way through just about anything. Short of admin wizards maybe.
	HOWEVER!
	Ninjas also have a fairly great weakness as they require energy to use abilities. If, theoretically, there is a game
	mode based around space ninjas, make sure to account for their energy needs.

	Admin Notes:

	Ninjas are not admin PCs--please do not use them for that purpose. They are another way to participate in the game post-death,
	like pais, xenos, death squads, and cyborgs.
	I'm currently looking for feedback from regular players since beta testing is largely done. I would appreciate if
	you spawned regular players as ninjas when rounds are boring. Or exciting, it's all good as long as there is feedback.
	You can also spawn ninja gear manually if you want to.

	How to do that:
	Make sure your character has a mind.
	Change their assigned_role to "MODE", no quotes. Otherwise, the suit won't initialize.
	Change their special_role to "Ninja", no quotes. Otherwise, the character will be gibbed.
	Spawn ninja gear, put it on, hit initialize. Let the suit do the rest. You are now a space ninja.
	I don't recommend messing with suit variables unless you really know what you're doing.

	Miscellaneous Notes:

	Potential Upgrade Tree:
		Energy Shield:
			Extra Ability
			Syndicate Shield device?
				Works like the force wall spell, except can be kept indefinitely as long as energy remains. Toggled on or off.
				Would block bullets and the like.
		Phase Shift
			Extra Ability
			Advanced Sensors?
				Instead of being unlocked at the start, Phase Shieft would become available once requirements are met.
		Uranium-based Recharger:
			Suit Upgrade
			Unsure
				Instead of losing energy each second, the suit would regain the same amount of energy.
				This would not count in activating stealth and similar.
		Extended Battery Life:
			Suit Upgrade
			Battery of higher capacity
				Already implemented. Replace current battery with one of higher capacity.
		Advanced Cloak-Tech device.
			Suit Upgrade
			Syndicate Cloaking Device?
				Remove cloak failure rate.
*/

//=======//RANDOM EVENT//=======//
/*
Also a dynamic ninja mission generator.
I decided to scrap round-specific objectives since keeping track of them would require some form of tracking.
When I already created about 4 new objectives, this doesn't seem terribly important or needed.
*/

/var/global/toggle_space_ninja = 0//If ninjas can spawn or not.
/var/global/sent_ninja_to_station = 0//If a ninja is already on the station.

var/ninja_selection_id = 1
var/ninja_selection_active = 0
var/ninja_confirmed_selection = 0

/proc/space_ninja_arrival(assign_key = null, assign_mission = null)

	if(ninja_selection_active)
		to_chat(usr, "<span class='warning'>Ninja selection already in progress. Please wait until it ends.</span>")
		return

	var/datum/game_mode/current_mode = ticker.mode
	var/datum/mind/current_mind

	/*Is the ninja playing for the good or bad guys? Is the ninja helping or hurting the station?
	Their directives also influence behavior. At least in theory.*/
	var/side = pick("face","heel")

	var/antagonist_list[] = list()//The main bad guys. Evil minds that plot destruction.
	var/protagonist_list[] = current_mode.get_living_heads()//The good guys. Mostly Heads. Who are alive.

	var/xeno_list[] = list()//Aliens.
	var/commando_list[] = list()//Commandos.

	//We want the ninja to appear only in certain modes.
//	var/acceptable_modes_list[] = list("traitor","revolution","cult","wizard","changeling","traitorchan","nuclear","malfunction","monkey")  // Commented out for both testing and ninjas
//	if(!(current_mode.config_tag in acceptable_modes_list))
//		return

	/*No longer need to determine what mode it is since bad guys are basically universal.
	And there is now a mode with two types of bad guys.*/

	var/possible_bad_dudes[] = list(current_mode.traitors,current_mode.head_revolutionaries,current_mode.head_revolutionaries,
	                                current_mode.cult,current_mode.wizards,current_mode.changelings,current_mode.syndicates)
	for(var/list in possible_bad_dudes)//For every possible antagonist type.
		for(current_mind in list)//For each mind in that list.
			if(current_mind.current&&current_mind.current.stat!=2)//If they are not destroyed and not dead.
				antagonist_list += current_mind//Add them.

	if(protagonist_list.len)//If the mind is both a protagonist and antagonist.
		for(current_mind in protagonist_list)
			if(current_mind in antagonist_list)
				protagonist_list -= current_mind//We only want it in one list.
/*
Malf AIs/silicons aren't added. Monkeys aren't added. Messes with objective completion. Only humans are added.
*/

	//Here we pick a location and spawn the ninja.
	if(ninjastart.len == 0)
		for(var/obj/effect/landmark/L in landmarks_list)
			if(L.name == "carpspawn")
				ninjastart.Add(L)

	var/ninja_key = null
	var/mob/candidate_mob

	if(assign_key)
		ninja_key = assign_key
	else

		var/list/candidates = list()	//list of candidate keys
		for(var/mob/dead/observer/G in player_list)
			if(G.client && !G.client.holder && !G.client.is_afk() && (ROLE_NINJA in G.client.prefs.be_role))
				if(!(G.mind && G.mind.current && G.mind.current.stat != DEAD))
					candidates += G
		if(!candidates.len)	return
		candidates = shuffle(candidates)//Incorporating Donkie's list shuffle

		while(!ninja_key && candidates.len)
			candidate_mob = pick(candidates)
			if(sd_Alert(candidate_mob, "Would you like to spawn as a space ninja?", buttons = list("Yes","No"), duration = 150) == "Yes")
				ninja_key = candidate_mob.ckey
			else
				candidates.Remove(candidate_mob)

		if(!ninja_key)
			return


	if(!candidate_mob)
		for(var/mob/M in player_list)
			if((M.key == ninja_key || M.ckey == ninja_key) && M.client)
				candidate_mob = M
				break

	if(!candidate_mob)
		to_chat(usr, "<span class='warning'>The randomly chosen mob was not found in the second check.</span>")
		return

	ninja_selection_active = 1
	ninja_selection_id++
	var/this_selection_id = ninja_selection_id

	spawn(1)
		if(alert(candidate_mob, "You have been selected to play as a space ninja. Would you like to play as this role? (You have 30 seconds to accept - You will spawn in 30 seconds if you accept)",,"Yes","No")!="Yes")
			to_chat(usr, "<span class='warning'>The selected candidate for space ninja declined.</span>")
			return

		ninja_confirmed_selection = this_selection_id

	spawn(300)
		if(!ninja_selection_active || (this_selection_id != ninja_selection_id ))
			ninja_selection_active = 0
			to_chat(candidate_mob, "<span class='warning'>Sorry, you were too late. You only had 30 seconds to accept.</span>")
			return

		if(ninja_confirmed_selection != ninja_selection_id)
			ninja_selection_active = 0
			to_chat(usr, "<span class='warning'>The ninja did not accept the role in time.</span>")
			return

		ninja_selection_active = 0

		//The ninja will be created on the right spawn point or at late join.
		var/mob/living/carbon/human/new_ninja = create_space_ninja(pick(ninjastart.len ? ninjastart : latejoin))
		new_ninja.key = ninja_key
		new_ninja.wear_suit:randomize_param()//Give them a random set of suit parameters.
		new_ninja.internal = new_ninja.s_store //So the poor ninja has something to breath when they spawn in spess.
		new_ninja.internals.icon_state = "internal1"

		//Now for the rest of the stuff.

		var/datum/mind/ninja_mind = new_ninja.mind//For easier reference.
		var/mission_set = 0//To determine if we need to do further processing.
		//Xenos and deathsquads take precedence over everything else.

		//Unless the xenos are hiding in a locker somewhere, this'll find em.
		for(var/mob/living/carbon/xenomorph/humanoid/xeno in player_list)
			if(istype(xeno))
				xeno_list += xeno

		if(assign_mission)
			new_ninja.mind.store_memory("<B>Mission:</B> <span class='warning'>[assign_mission].</span><br>")
			to_chat(new_ninja, "<span class='notice'>\nYou are an elite mercenary assassin of the Spider Clan, [new_ninja.real_name]. The dreaded <span class='warning'><B>SPACE NINJA</B></span>! You have a variety of abilities at your disposal, thanks to your nano-enhanced cyber armor. Remember your training! \nYour current mission is: <span class='warning'><B>[assign_mission]</B></span></span>")
		else
			if(xeno_list.len>3)//If there are more than three humanoid xenos on the station, time to get dangerous.
				//Here we want the ninja to murder all the queens. The other aliens don't really matter.
				var/xeno_queen_list[] = list()
				for(var/mob/living/carbon/xenomorph/humanoid/queen/xeno_queen in xeno_list)
					if(xeno_queen.mind&&xeno_queen.stat!=2)
						xeno_queen_list += xeno_queen
				if(xeno_queen_list.len&&side=="face")//If there are queen about and the probability is 50.
					for(var/mob/living/carbon/xenomorph/humanoid/queen/xeno_queen in xeno_queen_list)
						var/datum/objective/assassinate/ninja_objective = new
						ninja_objective.owner = ninja_mind
						//We'll do some manual overrides to properly set it up.
						ninja_objective.target = xeno_queen.mind
						ninja_objective.explanation_text = "Kill \the [xeno_queen]."
						ninja_mind.objectives += ninja_objective
					mission_set = 1

			if(sent_strike_team&&side=="heel"&&antagonist_list.len)//If a strike team was sent, murder them all like a champ.
				for(current_mind in antagonist_list)//Search and destroy. Since we already have an antagonist list, they should appear there.
					if(current_mind && current_mind.special_role=="Death Commando")
						commando_list += current_mind
				if(commando_list.len)//If there are living commandos still in play.
					for(var/mob/living/carbon/human/commando in commando_list)
						var/datum/objective/assassinate/ninja_objective = new
						ninja_objective.owner = ninja_mind
						ninja_objective.find_target_by_role(commando.mind.special_role,1)
						ninja_mind.objectives += ninja_objective
					mission_set = 1
		/*
		If there are no antogonists left it could mean one of two things:
			A) The round is about to end. No harm in spawning the ninja here.
			B) The round is still going and ghosts are probably rioting for something to happen.
		In either case, it's a good idea to spawn the ninja with a semi-random set of objectives.
		*/
			if(!mission_set)//If mission was not set.

				var/current_minds[]//List being looked on in the following code.
				var/side_list = side=="face" ? 2 : 1//For logic gating.
				var/hostile_targets[] = list()//The guys actually picked for the assassination or whatever.
				var/friendly_targets[] = list()//The guys the ninja must protect.

				for(var/i=2,i>0,i--)//Two lists.
					current_minds = i==2 ? antagonist_list : protagonist_list//Which list are we looking at?
					for(var/t=3,(current_minds.len&&t>0),t--)//While the list is not empty and targets remain. Also, 3 targets is good.
						current_mind = pick(current_minds)//Pick a random person.
						/*I'm creating a logic gate here based on the ninja affiliation that compares the list being
						looked at to the affiliation. Affiliation is just a number used to compare. Meaning comes from the logic involved.
						If the list being looked at is equal to the ninja's affiliation, add the mind to hostiles.
						If not, add the mind to friendlies. Since it can't be both, it will be added only to one or the other.*/
						hostile_targets += i==side_list ? current_mind : null//Adding null doesn't add anything.
						friendly_targets += i!=side_list ? current_mind : null
						current_minds -= current_mind//Remove the mind so it's not picked again.

				var/objective_list[] = list(1,2,3,4,5,6)//To remove later.
				for(var/i=rand(1,3),i>0,i--)//Want to get a few random objectives. Currently up to 3.
					if(!hostile_targets.len)//Remove appropriate choices from switch list if the target lists are empty.
						objective_list -= 1
						objective_list -= 4
					if(!friendly_targets.len)
						objective_list -= 3
					switch(pick(objective_list))
						if(1)//kill
							current_mind = pick(hostile_targets)

							if(current_mind)
								var/datum/objective/assassinate/ninja_objective = new
								ninja_objective.owner = ninja_mind
								ninja_objective.find_target_by_role((current_mind.special_role ? current_mind.special_role : current_mind.assigned_role),(current_mind.special_role?1:0))//If they have a special role, use that instead to find em.
								ninja_mind.objectives += ninja_objective

							else
								i++

							hostile_targets -= current_mind//Remove them from the list.
						if(2)//Steal
							var/datum/objective/steal/ninja_objective = new
							ninja_objective.owner = ninja_mind
							var/target_item = pick(ninja_objective.possible_items_special)
							ninja_objective.set_target(target_item)
							ninja_mind.objectives += ninja_objective

							objective_list -= 2
						if(3)//Protect. Keeping people alive can be pretty difficult.
							current_mind = pick(friendly_targets)

							if(current_mind)

								var/datum/objective/protect/ninja_objective = new
								ninja_objective.owner = ninja_mind
								ninja_objective.find_target_by_role((current_mind.special_role ? current_mind.special_role : current_mind.assigned_role),(current_mind.special_role?1:0))
								ninja_mind.objectives += ninja_objective

							else
								i++

							friendly_targets -= current_mind
						if(4)//Debrain
							current_mind = pick(hostile_targets)

							if(current_mind)

								var/datum/objective/debrain/ninja_objective = new
								ninja_objective.owner = ninja_mind
								ninja_objective.find_target_by_role((current_mind.special_role ? current_mind.special_role : current_mind.assigned_role),(current_mind.special_role?1:0))
								ninja_mind.objectives += ninja_objective

							else
								i++

							hostile_targets -= current_mind//Remove them from the list.
						if(5)//Download research
							var/datum/objective/download/ninja_objective = new
							ninja_objective.owner = ninja_mind
							ninja_objective.gen_amount_goal()
							ninja_mind.objectives += ninja_objective

							objective_list -= 5
						if(6)//Capture
							var/datum/objective/capture/ninja_objective = new
							ninja_objective.owner = ninja_mind
							ninja_objective.gen_amount_goal()
							ninja_mind.objectives += ninja_objective

							objective_list -= 6

				if(ninja_mind.objectives.len)//If they got some objectives out of that.
					mission_set = 1

			if(!ninja_mind.objectives.len||!mission_set)//If they somehow did not get an objective at this point, time to destroy the station.
				var/nuke_code
				var/temp_code
				for(var/obj/machinery/nuclearbomb/N in poi_list)
					temp_code = text2num(N.r_code)
					if(temp_code)//if it's actually a number. It won't convert any non-numericals.
						nuke_code = N.r_code
						break
				if(nuke_code)//If there is a nuke device in world and we got the code.
					var/datum/objective/nuclear/ninja_objective = new//Fun.
					ninja_objective.owner = ninja_mind
					ninja_objective.explanation_text = "Destroy the station with a nuclear device. The code is [nuke_code]." //Let them know what the code is.

			//Finally add a survival objective since it's usually broad enough for any round type.
			var/datum/objective/survive/ninja_objective = new
			ninja_objective.owner = ninja_mind
			ninja_mind.objectives += ninja_objective

			var/directive = generate_ninja_directive(side)
			to_chat(new_ninja, "<span class='notice'>\nYou are an elite mercenary assassin of the Spider Clan, [new_ninja.real_name]. The dreaded <span class='warning'><B>SPACE NINJA</B></span>! You have a variety of abilities at your disposal, thanks to your nano-enhanced cyber armor. Remember your training (initialize your suit by right clicking on it)! \nYour current directive is: <span class='warning'><B>[directive]</B></span></span>")
			new_ninja.mind.store_memory("<B>Directive:</B> <span class='warning'>[directive]</span><br>")

			var/obj_count = 1
			to_chat(new_ninja, "<span class='notice'>Your current objectives:</span>")
			for(var/datum/objective/objective in ninja_mind.objectives)
				to_chat(new_ninja, "<B>Objective #[obj_count]</B>: [objective.explanation_text]")
				obj_count++

		sent_ninja_to_station = 1//And we're done.
		return new_ninja//Return the ninja in case we need to reference them later.

/*
This proc will give the ninja a directive to follow. They are not obligated to do so but it's a fun roleplay reminder.
Making this random or semi-random will probably not work without it also being incredibly silly.
As such, it's hard-coded for now. No reason for it not to be, really.
*/
/proc/generate_ninja_directive(side)
	var/directive = "[side=="face"?"Nanotrasen":"The Syndicate"] is your employer. "//Let them know which side they're on.
	switch(rand(1,19))
		if(1)
			directive += "The Spider Clan must not be linked to this operation. Remain hidden and covert when possible."
		if(2)
			directive += "[station_name] is financed by an enemy of the Spider Clan. Cause as much structural damage as desired."
		if(3)
			directive += "A wealthy animal rights activist has made a request we cannot refuse. Prioritize saving animal lives whenever possible."
		if(4)
			directive += "The Spider Clan absolutely cannot be linked to this operation. Eliminate witnesses at your discretion."
		if(5)
			directive += "We are currently negotiating with NanoTrasen Central Command. Prioritize saving human lives over ending them."
		if(6)
			directive += "We are engaged in a legal dispute over [station_name]. If a laywer is present on board, force their cooperation in the matter."
		if(7)
			directive += "A financial backer has made an offer we cannot refuse. Implicate Syndicate involvement in the operation."
		if(8)
			directive += "Let no one question the mercy of the Spider Clan. Ensure the safety of all non-essential personnel you encounter."
		if(9)
			directive += "A free agent has proposed a lucrative business deal. Implicate Nanotrasen involvement in the operation."
		if(10)
			directive += "Our reputation is on the line. Harm as few civilians and innocents as possible."
		if(11)
			directive += "Our honor is on the line. Utilize only honorable tactics when dealing with opponents."
		if(12)
			directive += "We are currently negotiating with a Syndicate leader. Disguise assassinations as suicide or other natural causes."
		if(13)
			directive += "Some disgruntled NanoTrasen employees have been supportive of our operations. Be wary of any mistreatment by command staff."
		if(14)
			var/xenorace = pick("Unathi","Tajaran", "Skrellian")
			directive += "A group of [xenorace] radicals have been loyal supporters of the Spider Clan. Favor [xenorace] crew whenever possible."
		if(15)
			directive += "The Spider Clan has recently been accused of religious insensitivity. Attempt to speak with the Chaplain and prove these accusations false."
		if(16)
			directive += "The Spider Clan has been bargaining with a competing prosthetics manufacturer. Try to shine NanoTrasen prosthetics in a bad light."
		if(17)
			directive += "The Spider Clan has recently begun recruiting outsiders. Consider suitable candidates and assess their behavior amongst the crew."
		if(18)
			directive += "A cyborg liberation group has expressed interest in our serves. Prove the Spider Clan merciful towards law-bound synthetics."
		else
			directive += "There are no special supplemental instructions at this time."
	return directive

//=======//CURRENT PLAYER VERB//=======//

/client/proc/cmd_admin_ninjafy(mob/M in player_list)
	set category = null
	set name = "Make Space Ninja"

	if(!ticker)
		alert("Wait until the game starts")
		return
	if(!toggle_space_ninja)
		alert("Space Ninjas spawning is disabled.")
		return

	var/confirm = alert(src, "You sure?", "Confirm", "Yes", "No")
	if(confirm != "Yes") return

	if(ishuman(M))
		log_admin("[key_name(src)] turned [M.key] into a Space Ninja.")
		spawn(10)
			M:create_mind_space_ninja()
			M:equip_space_ninja(1)
			if(istype(M:wear_suit, /obj/item/clothing/suit/space/space_ninja))
				M:wear_suit:randomize_param()
				spawn(0)
					M:wear_suit:ninitialize(10,M)
	else
		alert("Invalid mob")

//=======//CURRENT GHOST VERB//=======//

/client/proc/send_space_ninja()
	set category = "Fun"
	set name = "Spawn Space Ninja"
	set desc = "Spawns a space ninja for when you need a teenager with attitude."
	set popup_menu = 0

	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return
	if(!ticker.mode)
		alert("The game hasn't started yet!")
		return
	if(!toggle_space_ninja)
		alert("Space Ninjas spawning is disabled.")
		return
	if(alert("Are you sure you want to send in a space ninja?",,"Yes","No")=="No")
		return

	var/mission
	while(!mission)
		mission = sanitize(input(src, "Please specify which mission the space ninja shall undertake.", "Specify Mission", ""))
		if(!mission)
			if(alert("Error, no mission set. Do you want to exit the setup process?",,"Yes","No")=="Yes")
				return

	var/input = ckey(input("Pick character to spawn as the Space Ninja", "Key", ""))
	if(!input)
		return

	space_ninja_arrival(input, mission)

	message_admins("<span class='notice'>[key_name_admin(usr)] has spawned [input] as a Space Ninja.\nTheir <b>mission</b> is: [mission]</span>")
	log_admin("[key_name(usr)] used Spawn Space Ninja.")

	return

//=======//NINJA CREATION PROCS//=======//

/proc/create_space_ninja(obj/spawn_point)
	var/mob/living/carbon/human/new_ninja = new(spawn_point.loc)
	var/ninja_title = pick(ninja_titles)
	var/ninja_name = pick(ninja_names)
	new_ninja.gender = pick(MALE, FEMALE)

	var/datum/preferences/A = new()//Randomize appearance for the ninja.
	A.randomize_appearance_for(new_ninja)
	new_ninja.real_name = "[ninja_title] [ninja_name]"
	new_ninja.dna.ready_dna(new_ninja)
	new_ninja.create_mind_space_ninja()
	new_ninja.equip_space_ninja()
	return new_ninja

/mob/living/carbon/human/proc/create_mind_space_ninja()
	mind_initialize()
	mind.assigned_role = "MODE"
	mind.special_role = "Ninja"

	//ticker.mode.ninjas |= mind
	return 1

/mob/living/carbon/human/proc/equip_space_ninja(safety=0)//Safety in case you need to unequip stuff for existing characters.
	if(safety)
		qdel(w_uniform)
		qdel(wear_suit)
		qdel(wear_mask)
		qdel(head)
		qdel(shoes)
		qdel(gloves)

	var/obj/item/device/radio/R = new /obj/item/device/radio/headset/ninja(src)
	equip_to_slot_or_del(R, SLOT_L_EAR)
	if(gender==FEMALE)
		equip_to_slot_or_del(new /obj/item/clothing/under/color/blackf(src), SLOT_W_UNIFORM)
	else
		equip_to_slot_or_del(new /obj/item/clothing/under/color/black(src), SLOT_W_UNIFORM)
	equip_to_slot_or_del(new /obj/item/clothing/shoes/space_ninja(src), SLOT_SHOES)
	equip_to_slot_or_del(new /obj/item/clothing/suit/space/space_ninja(src), SLOT_WEAR_SUIT)
	equip_to_slot_or_del(new /obj/item/clothing/gloves/space_ninja(src), SLOT_GLOVES)
	equip_to_slot_or_del(new /obj/item/clothing/head/helmet/space/space_ninja(src), SLOT_HEAD)
	equip_to_slot_or_del(new /obj/item/clothing/mask/gas/voice/space_ninja(src), SLOT_WEAR_MASK)
	equip_to_slot_or_del(new /obj/item/device/flashlight(src), SLOT_BELT)
	equip_to_slot_or_del(new /obj/item/weapon/plastique(src), SLOT_R_STORE)
	equip_to_slot_or_del(new /obj/item/weapon/plastique(src), SLOT_L_STORE)
	equip_to_slot_or_del(new /obj/item/weapon/tank/oxygen(src), SLOT_S_STORE)
	var/obj/item/weapon/implant/dexplosive/L = new(src)
	L.imp_in = src
	L.implanted = TRUE
	var/obj/item/organ/external/BP = bodyparts_by_name[BP_HEAD]
	BP.implants += L
	L.part = BP
	return 1

//=======//HELPER PROCS//=======//

//Randomizes suit parameters.
/obj/item/clothing/suit/space/space_ninja/proc/randomize_param()
	s_cost = rand(1,20)
	s_acost = rand(20,100)
	k_cost = rand(100,500)
	k_damage = rand(1,20)
	s_delay = rand(10,100)
	s_bombs = rand(5,20)
	a_boost = rand(1,7)

//This proc prevents the suit from being taken off.
/obj/item/clothing/suit/space/space_ninja/proc/lock_suit(mob/living/carbon/human/U, X = FALSE)
	if(X)//If you want to check for icons.
		if(U.mind.protector_role)
			icon_state = U.gender == FEMALE ? "s-ninjakf" : "s-ninjak"
			U.gloves.icon_state = "s-ninjak"
			U.gloves.item_state = "s-ninjak"
		else
			icon_state = U.gender == FEMALE ? "s-ninjanf" : "s-ninjan"
			U.gloves.icon_state = "s-ninjan"
			U.gloves.item_state = "s-ninjan"
	else
		if(U.mind.special_role!="Ninja")
			to_chat(U, "<span class='warning'><B>fÄTaL ÈÈRRoR</B>: 382200-*#00CÖDE <B>RED</B>\nUNAU?HORIZED USÈ DETÈC???eD\nCoMMÈNCING SUB-R0U?IN3 13...\nTÈRMInATING U-U-USÈR...</span>")
			U.gib()
			return 0
		if(!istype(U.head, /obj/item/clothing/head/helmet/space/space_ninja))
			to_chat(U, "<span class='warning'><B>ERROR</B>: 100113</span> UNABLE TO LOCATE HEAD GEAR\nABORTING...")
			return 0
		if(!istype(U.shoes, /obj/item/clothing/shoes/space_ninja))
			to_chat(U, "<span class='warning'><B>ERROR</B>: 122011</span> UNABLE TO LOCATE FOOT GEAR\nABORTING...")
			return 0
		if(!istype(U.gloves, /obj/item/clothing/gloves/space_ninja))
			to_chat(U, "<span class='warning'><B>ERROR</B>: 110223</span> UNABLE TO LOCATE HAND GEAR\nABORTING...")
			return 0

		affecting = U
		canremove = 0
		slowdown = 0
		n_hood = U.head
		n_hood.canremove=0
		n_shoes = U.shoes
		n_shoes.canremove=0
		n_shoes.slowdown--
		n_gloves = U.gloves
		n_gloves.canremove=0

	return TRUE

//This proc allows the suit to be taken off.
/obj/item/clothing/suit/space/space_ninja/proc/unlock_suit()
	affecting = null
	canremove = 1
	slowdown = 1
	icon_state = "s-ninja"
	if(n_hood)//Should be attached, might not be attached.
		n_hood.canremove=1
	if(n_shoes)
		n_shoes.canremove=1
		n_shoes.slowdown++
	if(n_gloves)
		n_gloves.icon_state = "s-ninja"
		n_gloves.item_state = "s-ninja"
		n_gloves.canremove=1
		n_gloves.candrain=0
		n_gloves.draining=0

//Allows the mob to grab a stealth icon.
/mob/proc/NinjaStealthActive(atom/A)//A is the atom which we are using as the overlay.
	invisibility = INVISIBILITY_LEVEL_TWO//Set ninja invis to 2.
	var/icon/opacity_icon = new(A.icon, A.icon_state)
	var/icon/alpha_mask = getIconMask(src)
	var/icon/alpha_mask_2 = new('icons/effects/effects.dmi', "at_shield1")
	alpha_mask.AddAlphaMask(alpha_mask_2)
	opacity_icon.AddAlphaMask(alpha_mask)
	for(var/i=0,i<5,i++)//And now we add it as overlays. It's faster than creating an icon and then merging it.
		var/image/I = image("icon" = opacity_icon, "icon_state" = A.icon_state, "layer" = layer+0.8)//So it's above other stuff but below weapons and the like.
		switch(i)//Now to determine offset so the result is somewhat blurred.
			if(1)
				I.pixel_x -= 1
			if(2)
				I.pixel_x += 1
			if(3)
				I.pixel_y -= 1
			if(4)
				I.pixel_y += 1

		add_overlay(I)//And finally add the overlay.
	add_overlay(image("icon"='icons/effects/effects.dmi',"icon_state" ="electricity","layer" = layer+0.9))

//When ninja steal malfunctions.
/mob/proc/NinjaStealthMalf()
	invisibility = 0//Set ninja invis to 0.
	add_overlay(image("icon"='icons/effects/effects.dmi',"icon_state" ="electricity","layer" = layer+0.9))
	playsound(src, 'sound/effects/stealthoff.ogg', VOL_EFFECTS_MASTER)

//=======//GENERIC VERB MODIFIERS//=======//

/obj/item/clothing/suit/space/space_ninja/proc/grant_equip_verbs()
	verbs -= /obj/item/clothing/suit/space/space_ninja/proc/init
	verbs += /obj/item/clothing/suit/space/space_ninja/proc/deinit
	verbs += /obj/item/clothing/suit/space/space_ninja/proc/spideros
	verbs += /obj/item/clothing/suit/space/space_ninja/proc/stealth
	n_gloves.verbs += /obj/item/clothing/gloves/space_ninja/proc/toggled

	s_initialized = 1

/obj/item/clothing/suit/space/space_ninja/proc/remove_equip_verbs()
	verbs += /obj/item/clothing/suit/space/space_ninja/proc/init
	verbs -= /obj/item/clothing/suit/space/space_ninja/proc/deinit
	verbs -= /obj/item/clothing/suit/space/space_ninja/proc/spideros
	verbs -= /obj/item/clothing/suit/space/space_ninja/proc/stealth
	if(n_gloves)
		n_gloves.verbs -= /obj/item/clothing/gloves/space_ninja/proc/toggled

	s_initialized = 0

/obj/item/clothing/suit/space/space_ninja/proc/grant_ninja_verbs()
	verbs += /obj/item/clothing/suit/space/space_ninja/proc/ninjashift
	verbs += /obj/item/clothing/suit/space/space_ninja/proc/ninjasmoke
	verbs += /obj/item/clothing/suit/space/space_ninja/proc/ninjaboost
	verbs += /obj/item/clothing/suit/space/space_ninja/proc/ninjapulse
	verbs += /obj/item/clothing/suit/space/space_ninja/proc/ninjablade
	verbs += /obj/item/clothing/suit/space/space_ninja/proc/ninjastar
	verbs += /obj/item/clothing/suit/space/space_ninja/proc/ninjanet

	s_initialized=1
	slowdown=0

/obj/item/clothing/suit/space/space_ninja/proc/remove_ninja_verbs()
	verbs -= /obj/item/clothing/suit/space/space_ninja/proc/ninjashift
	verbs -= /obj/item/clothing/suit/space/space_ninja/proc/ninjaboost
	verbs -= /obj/item/clothing/suit/space/space_ninja/proc/ninjapulse
	verbs -= /obj/item/clothing/suit/space/space_ninja/proc/ninjablade
	verbs -= /obj/item/clothing/suit/space/space_ninja/proc/ninjastar
	verbs -= /obj/item/clothing/suit/space/space_ninja/proc/ninjanet

//=======//KAMIKAZE VERBS//=======//

/obj/item/clothing/suit/space/space_ninja/proc/grant_kamikaze(mob/living/carbon/U)
	verbs -= /obj/item/clothing/suit/space/space_ninja/proc/ninjashift
	verbs -= /obj/item/clothing/suit/space/space_ninja/proc/ninjanet
	verbs += /obj/item/clothing/suit/space/space_ninja/proc/ninjaslayer
	verbs += /obj/item/clothing/suit/space/space_ninja/proc/ninjawalk
	verbs += /obj/item/clothing/suit/space/space_ninja/proc/ninjamirage

	verbs -= /obj/item/clothing/suit/space/space_ninja/proc/stealth

	kamikaze = 1

	icon_state = U.gender==FEMALE ? "s-ninjakf" : "s-ninjak"
	if(n_gloves)
		n_gloves.icon_state = "s-ninjak"
		n_gloves.item_state = "s-ninjak"
		n_gloves.candrain = 0
		n_gloves.draining = 0
		n_gloves.verbs -= /obj/item/clothing/gloves/space_ninja/proc/toggled

	cancel_stealth()

	U << browse(null, "window=spideros")
	to_chat(U, "<span class='warning'>Do or Die, <b>LET'S ROCK!!</b></span>")

/obj/item/clothing/suit/space/space_ninja/proc/remove_kamikaze(mob/living/carbon/U)
	if(kamikaze)
		verbs += /obj/item/clothing/suit/space/space_ninja/proc/ninjashift
		verbs += /obj/item/clothing/suit/space/space_ninja/proc/ninjapulse
		verbs += /obj/item/clothing/suit/space/space_ninja/proc/ninjastar
		verbs -= /obj/item/clothing/suit/space/space_ninja/proc/ninjaslayer
		verbs -= /obj/item/clothing/suit/space/space_ninja/proc/ninjawalk
		verbs -= /obj/item/clothing/suit/space/space_ninja/proc/ninjamirage

		verbs += /obj/item/clothing/suit/space/space_ninja/proc/stealth
		if(n_gloves)
			n_gloves.verbs -= /obj/item/clothing/gloves/space_ninja/proc/toggled

		U.incorporeal_move = 0
		kamikaze = 0
		k_unlock = 0
		to_chat(U, "<span class='notice'>Disengaging mode...\n</span><b>CODE NAME</b>: <span class='warning'><b>KAMIKAZE</b></span>")

//=======//AI VERBS//=======//

/obj/item/clothing/suit/space/space_ninja/proc/grant_AI_verbs()
	verbs += /obj/item/clothing/suit/space/space_ninja/proc/ai_hack_ninja
	verbs += /obj/item/clothing/suit/space/space_ninja/proc/ai_return_control

	s_busy = 0
	s_control = 0

/obj/item/clothing/suit/space/space_ninja/proc/remove_AI_verbs()
	verbs -= /obj/item/clothing/suit/space/space_ninja/proc/ai_hack_ninja
	verbs -= /obj/item/clothing/suit/space/space_ninja/proc/ai_return_control

	s_control = 1
