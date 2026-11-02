extends Node
# Global event bus. All game systems communicate through these signals so
# scripts never need to hold references to each other.

signal notify(title, text)
signal crop_planted(crop_id)
signal field_plowed
signal plot_watered
signal crop_fertilized
signal crop_harvested(crop_id)
signal crop_sold(crop_id, amount)
signal item_sold(item_id, amount)
signal seed_bought(crop_id)
signal item_bought(item_id)
signal money_earned(amount)
signal money_spent(amount)
signal item_delivered(item_id)
signal fish_caught(fish_id, weight)
signal treasure_found
signal animal_bought(animal_id)
signal animal_fed(species)
signal eggs_collected(count)
signal animal_milked
signal vehicle_bought(vehicle_id)
signal vehicle_entered(vehicle_id)
signal distance_driven(meters)
signal race_finished(race_id, seconds)
signal location_discovered(id)
signal npc_talked(npc_id)
signal player_ate(item_id)
signal player_drank
signal player_slept
signal day_completed(day)
signal week_completed(week)
signal level_up(level)
signal building_built(building_id)
signal building_upgraded(building_id)
signal story_choice_made(id)
signal companion_recruited
signal weather_changed(new_weather)
signal player_died
signal generic(tag, amount)
signal mission_accepted(id)
signal mission_completed(id)
signal mission_failed(id)
signal request_save
signal request_load
signal settings_changed

func _ready():
	# verify every signal used in the game is declared here
	pass
