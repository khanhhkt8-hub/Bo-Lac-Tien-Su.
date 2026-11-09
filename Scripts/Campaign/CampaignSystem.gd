extends Node
## Campaign: 10 regions x 10 stages x 10 challenge variants.
## A stage opens only after its barbarian camp is defeated in all 10 variants.

signal progress_changed(region: int, stage: int, cleared_modes: int)
signal stage_unlocked(region: int, stage: int)
signal campaign_completed

const REGION_COUNT := 10
const STAGES_PER_REGION := 10
const MODES_PER_STAGE := 10
const SAVE_PATH := "user://bo_lac_campaign.cfg"

var current_region: int = 1
var current_stage: int = 1
var cleared_modes: Dictionary = {}

func _ready() -> void:
	load_progress()

func is_mode_unlocked(region: int, stage: int, mode: int) -> bool:
	if region < 1 or region > REGION_COUNT or stage < 1 or stage > STAGES_PER_REGION:
		return false
	if mode < 1 or mode > MODES_PER_STAGE:
		return false
	if region == 1 and stage == 1:
		return true
	return _stage_is_unlocked(region, stage)

func _stage_is_unlocked(region: int, stage: int) -> bool:
	if region == 1 and stage == 1:
		return true
	if stage > 1:
		return _stage_is_cleared(region, stage - 1)
	if region > 1:
		return _stage_is_cleared(region - 1, STAGES_PER_REGION)
	return false

func is_mode_cleared(region: int, stage: int, mode: int) -> bool:
	return bool(cleared_modes.get(_key(region, stage, mode), false))

func record_barbarian_camp_victory(region: int, stage: int, mode: int) -> bool:
	if not is_mode_unlocked(region, stage, mode):
		return false
	cleared_modes[_key(region, stage, mode)] = true
	var count := get_cleared_mode_count(region, stage)
	current_region = region
	current_stage = stage
	if count == MODES_PER_STAGE:
		if region == REGION_COUNT and stage == STAGES_PER_REGION:
			campaign_completed.emit()
		elif stage < STAGES_PER_REGION:
			stage_unlocked.emit(region, stage + 1)
		else:
			stage_unlocked.emit(region + 1, 1)
	save_progress()
	progress_changed.emit(region, stage, count)
	return true

func get_cleared_mode_count(region: int, stage: int) -> int:
	var count := 0
	for mode in range(1, MODES_PER_STAGE + 1):
		if is_mode_cleared(region, stage, mode):
			count += 1
	return count

func _stage_is_cleared(region: int, stage: int) -> bool:
	return get_cleared_mode_count(region, stage) == MODES_PER_STAGE

func _key(region: int, stage: int, mode: int) -> String:
	return "%d_%d_%d" % [region, stage, mode]

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("campaign", "current_region", current_region)
	config.set_value("campaign", "current_stage", current_stage)
	config.set_value("campaign", "cleared_modes", cleared_modes)
	config.save(SAVE_PATH)

func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	current_region = int(config.get_value("campaign", "current_region", 1))
	current_stage = int(config.get_value("campaign", "current_stage", 1))
	cleared_modes = config.get_value("campaign", "cleared_modes", {})
