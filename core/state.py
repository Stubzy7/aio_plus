
import threading
import time
from core.scaling import (
    screen_width, screen_height, width_multiplier, height_multiplier,
    scale_x, scale_y,
)


class AppState:

    def __init__(self):
        self.lock = threading.Lock()

        self.screen_width = screen_width
        self.screen_height = screen_height
        self.width_multiplier = width_multiplier
        self.height_multiplier = height_multiplier

        self.ark_running = False
        self.gui_visible = True
        self.ark_window = "ArkAscended"
        self.game_width = 0
        self.game_height = 0

        self.run_magic_f_script = False
        self.magic_f_refill_mode = False
        self.magic_f_preset_names: list[str] = []
        self.magic_f_preset_filters: list[list[str]] = []
        self.magic_f_preset_dirs: list[str] = []
        self.magic_f_preset_idx = 1
        self.mf_search_bar_click_ms = 30
        self.mf_filter_settle_ms = 100
        self.mf_transfer_settle_ms = 100
        self.mf_give_filter_list: list[str] = []
        self.mf_take_filter_list: list[str] = []

        self.run_auto_lvl_script = False
        self.auto_lvl_cryo_check = ""

        self.run_claim_and_name_script = False

        self.run_mammoth_script = False

        self.quick_feed_mode = 0

        self.perf_log: list = []

        self.svr_list: list[str] = []
        self.svr_notes: dict[str, str] = {}  # server_num -> note text
        self.svr_note_gui = None

        self.uf_list: list[str] = []
        self.cn_name_list: list[str] = []
        self.ac_simple_filter_list: list[str] = []
        self.ac_timed_filter_list: list[str] = []
        self.ac_grid_filter_list: list[str] = []
        self.pc_custom_filter_list: list[str] = []

        self.run_overcap_script = False
        self.overcap_dedi_target = 0
        self.overcap_start_tick = 0
        self.overcap_accum_ms = 0
        self.overcap_dedi_table = {
            1: 14000, 2: 35000, 3: 35000, 4: 56000,
            5: 77000, 6: 98000, 7: 119000, 8: 140000, 9: 161000,
        }

        self.autoclicking = False
        self.autoclick_interval = 750
        self.autoclick_interval_step = 100
        self.autoclick_min_interval = 50

        self.qh_mode = 0
        self.qh_armed = False
        self.qh_running = False
        self.qh_cryo_after = False
        self.cn_enabled = False
        self.ns_enabled = False
        self.dino_name = ""
        self.qh_click1_x = scale_x(1676)
        self.qh_click1_y = scale_y(380)
        self.qh_click2_x = scale_x(1271)
        self.qh_click2_y = scale_y(1175)
        self.qh_inv_pix_x = scale_x(456)
        self.qh_inv_pix_y = scale_y(217)
        self.qh_log_entries: list = []
        self.qh_click_delay = 1
        self.depo_eggs_active = False
        self.depo_embryo_active = False
        self.depo_cycle: list = []
        self.depo_cycle_idx = 0
        self.qh_empty_pix_x = scale_x(1040)
        self.qh_empty_pix_y = scale_y(736)
        self.qh_empty_color = 0x019C88
        self.qh_empty_tol = 30
        self.qh_egg_slot_x = [scale_x(v) for v in [1488, 1439, 1385, 1336, 1281, 1235, 1180, 1133, 1080, 1032]]
        self.qh_egg_slot_y = [scale_y(v) for v in [732, 733, 732, 733, 732, 732, 733, 732, 733, 733]]

        self.imprint_scanning = False
        self.imprint_auto_mode = False
        self.imprint_inventory_key = ""
        self.imprint_scan_overlay = None
        self.imprint_help_gui = None
        self.imprint_resizing = False
        self.imprint_hide_overlay = False
        self.imprint_log: list = []
        self.imprint_snap_w = 560
        self.imprint_snap_h = 80
        self.imprint_snap_x = (screen_width // 2) - (560 // 2)
        self.imprint_snap_y = (screen_height // 2) - (80 // 2) + 20
        self.imprint_inv_pix_x = scale_x(461)
        self.imprint_inv_pix_y = scale_y(215)
        self.imprint_search_x = scale_x(311)
        self.imprint_search_y = scale_y(261)
        self.imprint_result_x = scale_x(297)
        self.imprint_result_y = scale_y(359)
        self.imprint_all_foods = [
            "cuddle",
            "Amarberry", "Azulberry", "Mejoberry", "Tintoberry",
            "Cianberry", "Magenberry", "Verdberry",
            "Cooked Prime Fish Meat", "Cooked Fish Meat",
            "Cooked Prime Meat", "Cooked Meat Jerky", "Prime Meat Jerky",
            "Cooked Meat", "Kibble",
        ]

        self.run_name_and_spay_script = False
        self.ns_log_entries: list = []
        self.ns_help_gui = None
        self.mf_help_gui = None
        self.ns_radial_x = scale_x(1040)
        self.ns_radial_y = scale_y(861)
        self.ns_alt_radial_x = scale_x(1176)
        self.ns_alt_radial_y = scale_y(948)
        self.ns_alt_click_x = scale_x(1179)
        self.ns_alt_click_y = scale_y(948)
        self.ns_alt2_radial_x = scale_x(1489)
        self.ns_alt2_radial_y = scale_y(523)
        self.ns_alt2_click_x = scale_x(1033)
        self.ns_alt2_click_y = scale_y(764)
        self.ns_spay_x = scale_x(1025)
        self.ns_spay_y = scale_y(561)
        self.ns_admin_pix_x = scale_x(1035)
        self.ns_admin_pix_y = scale_y(508)
        self.ns_admin_spay_x = scale_x(1017)
        self.ns_admin_spay_y = scale_y(780)

        self.drum_pixel_x = round(screen_width * (815 / 1920))
        self.drum_pixel_y = round(screen_height * (920 / 1080))

        self.transfer_to_me_btn_x = scale_x(1917)
        self.transfer_to_me_btn_y = scale_y(264)
        self.transfer_to_other_btn_x = scale_x(550)
        self.transfer_to_other_btn_y = scale_y(265)
        self.my_inv_drop_all_btn_x = scale_x(622)
        self.my_inv_drop_all_btn_y = scale_y(257)
        self.my_inv_crafting_btn_x = scale_x(601)
        self.my_inv_crafting_btn_y = scale_y(187)
        self.my_search_bar_x = scale_x(339)
        self.my_search_bar_y = scale_y(256)
        self.my_first_slot_x = scale_x(286.7)
        self.my_first_slot_y = scale_y(369.3)
        self.their_inv_search_bar_x = scale_x(1678)
        self.their_inv_search_bar_y = scale_y(266)
        self.their_inv_drop_all_btn_x = scale_x(1989)
        self.their_inv_drop_all_btn_y = scale_y(260)

        self.ob_log: list = []
        self.ob_upload_mode = 0
        self.ob_upload_armed = False
        self.ob_upload_running = False
        self.ob_timer_counting = False
        self.ob_upload_filter = ""
        self.ob_status_text = ""
        self.ob_inv_fail_btn_x = scale_x(1241)
        self.ob_inv_fail_btn_y = scale_y(1277)
        self.ob_inv_pix_x = scale_x(1699)
        self.ob_inv_pix_y = scale_y(181)
        self.ob_confirm_pix_x = scale_x(1479)
        self.ob_confirm_pix_y = scale_y(228)
        self.ob_char_trans_pix_x = scale_x(1425)
        self.ob_char_trans_pix_y = scale_y(225)
        self.ob_my_slot1_x = scale_x(300)
        self.ob_my_slot1_y = scale_y(370)
        self.ob_empty_check_x = scale_x(300)
        self.ob_empty_check_y = scale_y(350)
        self.ob_cryo_pix_x = scale_x(279)
        self.ob_cryo_pix_y = scale_y(311)
        self.ob_cryo_unel_pix_x = scale_x(292)
        self.ob_cryo_unel_pix_y = scale_y(317)
        self.ob_cryo_hover_start_x = scale_x(260)
        self.ob_cryo_hover_start_y = scale_y(407)
        self.ob_cryo_hover_end_x = scale_x(217)
        self.ob_cryo_hover_end_y = scale_y(407)
        self.ob_cryo_white_pix_x = scale_x(224)
        self.ob_cryo_white_pix_y = scale_y(305)
        self.ob_item_name_pix_x = scale_x(332)
        self.ob_item_name_pix_y = scale_y(417)
        self.ob_timer_pix_x = scale_x(243)
        self.ob_timer_pix_y = scale_y(413)
        self.ob_dayd_pix_x = scale_x(253)
        self.ob_dayd_pix_y = scale_y(419)
        self.ob_tek_pix_x = scale_x(371)
        self.ob_tek_pix_y = scale_y(401)
        self.ob_tek_pix2_x = scale_x(245)
        self.ob_tek_pix2_y = scale_y(408)
        self.ob_tek_pix3_x = scale_x(233)
        self.ob_tek_pix3_y = scale_y(417)
        self.ob_empty_slot_r = 0x0A
        self.ob_empty_slot_g = 0x4A
        self.ob_empty_slot_b = 0x6B
        self.ob_full_pix_x = scale_x(1045)
        self.ob_full_pix_y = scale_y(512)
        self.ob_max_items_pix_x = scale_x(1045)
        self.ob_max_items_pix_y = scale_y(507)
        self.ob_right_tab_pix_x = scale_x(1703)
        self.ob_right_tab_pix_y = scale_y(181)
        self.ob_upload_tab_x = scale_x(1697)
        self.ob_upload_tab_y = scale_y(181)
        self.ob_upload_ready_pix_x = scale_x(1700)
        self.ob_upload_ready_pix_y = scale_y(183)
        self.ob_refresh_pix_x = scale_x(1292)
        self.ob_refresh_pix_y = scale_y(493)
        self.ob_ov_pix_x = scale_x(1444)
        self.ob_ov_pix_y = scale_y(227)
        self.ob_all_pix_x = scale_x(385)
        self.ob_all_pix_y = scale_y(347)
        self.ob_data_loaded_pix_x = scale_x(1493)
        self.ob_data_loaded_pix_y = scale_y(592)
        self.ob_upload_stall_ms = 8000
        self.ob_hover_away_ms = 10
        self.ob_hover_glide_speed = 0
        self.ob_hover_settle_ms = 10
        self.ob_click_settle_ms = 10
        self.ob_post_refresh_ms = 0
        self.ob_pre_upload_ms = 200
        self.ob_upload_early_exit = False
        self.ob_first_upload = True
        self.ob_init_failed = False
        self.ob_upload_paused = False
        self.ob_active_filter = ""
        self.ob_inv_timeout = 250

        self.ob_char_travel_x = 0
        self.ob_char_travel_y = 0
        self.ob_char_custom_server = ""
        self.ob_char_timer_stage = 0
        self.ob_char_svr_idx = 0

        self.ob_download_armed = False
        self.ob_download_running = False
        self.ob_download_paused = False
        self.ob_down_text = ""
        self.ob_down_slot_x = scale_x(1657)
        self.ob_down_slot_y = scale_y(379)
        self.ob_bar_pix_x = scale_x(1025)
        self.ob_bar_pix_y = scale_y(613)
        self.ob_tooltip_pix_x = scale_x(936)
        self.ob_tooltip_pix_y = scale_y(272)
        self.ob_tooltips_were_on = False
        self.ob_down_item_delay_ms = 1500
        self.ob_down_item_delay_step = 100
        self.ob_down_item_delay_min = 200
        self.ob_down_item_delay_max = 3000
        self.ob_down_bar_settle_ms = 12000

        self.ob_ocr_resizing = False
        self.ob_ocr_target = 0
        self.ob_ocr_overlays = None
        self.ob_ocr_x = [scale_x(v) for v in [270, 640, 1630, 640, 359]]
        self.ob_ocr_y = [scale_y(v) for v in [365, 440, 325, 440, 301]]
        self.ob_ocr_w = [scale_x(v) for v in [80, 640, 150, 640, 624]]
        self.ob_ocr_h = [scale_y(v) for v in [40, 60, 40, 60, 803]]

        self.nf_enabled = False

        self.pin_auto_open = True
        self.pin_log: list = []
        self.pin_poll_count = 0
        self.pin_poll_active = False
        self.pin_poll_start_tick = 0
        self.pin_e_was_held = False
        self.pin_hold_threshold = 300
        self.pin_tol = 30
        self.pin_poll_interval = 25
        self.pin_poll_max_ticks = 94
        self.pin_pix1_x = scale_x(1199)
        self.pin_pix1_y = scale_y(381)
        self.pin_pix2_x = scale_x(1248)
        self.pin_pix2_y = scale_y(407)
        self.pin_pix3_x = scale_x(1103)
        self.pin_pix3_y = scale_y(416)
        self.pin_pix4_x = scale_x(1424)
        self.pin_pix4_y = scale_y(405)
        self.pin_click_x = scale_x(1275)
        self.pin_click_y = scale_y(999)

        self.gmk_mode = "off"

        self.ntfy_key = ""

        self.ini_command_key = "{vkC0}"
        self.ini_custom_command = ""
        self.ini_default_command = (
            "sg.FoliageQuality 0 | sg.TextureQuality 0 | "
            "r.Shading.FurnaceTest.SampleCount 0 | r.VolumetricCloud 0 | "
            "r.VolumetricFog 0 | r.Water.SingleLayer.Reflection 0 | "
            "r.ShadowQuality 0 | r.ContactShadows 0 | r.DepthOfFieldQuality 0 | "
            "r.Fog 0 | r.BloomQuality 0 | r.LightCulling.Quality 0 | "
            "r.SkyAtmosphere 1 | r.Lumen.Reflections.Allow 1 | "
            "r.Lumen.DiffuseIndirect.Allow 1 | r.Shadow.Virtual.Enable 0 | "
            "r.DistanceFieldShadowing 1 | r.Shadow.CSM.MaxCascades 0 | "
            "r.SkylightIntensityMultiplier 99 | grass.SizeScale 0 | "
            "ark.MaxActiveDestroyedMeshGeoCollectionCount 0 | "
            "sg.GlobalIlluminationQuality 1 | r.Nanite.MaxPixelsPerEdge 3 | "
            "r.Tonemapper.Sharpen 3 | r.SkyLight.RealTimeReflectionCapture 0 | "
            "r.EyeAdaptation.BlackHistogramBucketInfluence 0 | "
            "r.Lumen.Reflections.Contrast 0 | r.LightMaxDrawDistanceScale -1 | "
            "r.Lumen.ScreenProbeGather.DirectLighting 1 | r.Color.Grading 0 | "
            "fx.MaxNiagaraGPUParticlesSpawnPerFrame 50 | "
            "Slate.GlobalScrollAmount 120 | r.SkyLightingQuality 1 | "
            "r.VT.EnableFeedback 0 | gamma | r.ScreenPercentage 100 | "
            "grass.DensityScale 0 | stat FPS | r.MinRoughnessOverride 1 | "
            "r.DynamicGlobalIlluminationMethod 1 | r.Streaming.PoolSize 1 | "
            "r.MipMapLODBias 0 | "
            "r.Lumen.ScreenProbeGather.RadianceCache.ProbeResolution 16 | "
            "r.VSync 0 | show InstancedFoliage | show InstancedGrass | "
            "show InstancedStaticMeshes | r.AOOverwriteSceneColor 1 | "
            "Slate.Contrast 1 | sg.ReflectionQuality 0"
        )

        self.black_box_x = scale_x(2319)
        self.black_box_y = scale_y(1372)
        self.overcap_box_x = scale_x(2201)
        self.overcap_box_y = scale_y(1380)
        self.drop_all_x = scale_x(616)
        self.drop_all_y = scale_y(260)
        self.invy_search_x = scale_x(387)
        self.invy_search_y = scale_y(265)
        self.invy_detect_x = scale_x(456)
        self.invy_detect_y = scale_y(217)
        self.sheep_lvl_pixel_x = round(screen_width * (1632 / 2560))
        self.sheep_lvl_pixel_y = round(screen_height * (215 / 1440))
        self.sheep_lvl_click_x = round(screen_width * (1507 / 2560))
        self.sheep_lvl_click_y = round(screen_height * (667 / 1440))
        self.overcapping_toggle = False
        self.sheep_running = False
        self.sheep_auto_lvl_active = False
        self.sheep_mode_active = False
        self.sheep_status_bottom_anchor = 0
        self.sheep_auto_lvl_gui = None
        self.sheep_status_gui = None
        self.sheep_toggle_key = "g"
        self.sheep_overcap_key = "b"
        self.sheep_inventory_key = ""
        self.sheep_auto_lvl_key = "z"
        self.sheep_level_action_key = "z"
        self.sheep_tab_active = False

        self.pc_mode = 0
        self.pc_inv_key = "f"
        self.pc_drop_key = ""
        self.pc_running = False
        self.pc_early_exit = False
        self.pc_f1_abort = False
        self.pc_tooltip_gen = 0       # incremented by _stop_flags to cancel queued tooltips
        self.pc_tab_active = True
        self.pc_storage_scan_base_x = 1347
        self.pc_storage_scan_base_y = 693
        self.pc_storage_scan_base_w = 187
        self.pc_storage_scan_base_h = 93
        self.pc_storage_scan_x = scale_x(1347)
        self.pc_storage_scan_y = scale_y(693)
        self.pc_storage_scan_w = scale_x(187)
        self.pc_storage_scan_h = scale_y(93)
        self.pc_storage_resizing = False
        self.pc_storage_overlay = None
        self.pc_forge_skip_first = False
        self.pc_forge_transfer_all = False
        self.pc_bag_detect_x = round(1398.7 * width_multiplier)
        self.pc_bag_detect_y = round(278.7 * height_multiplier)
        self.pc_bag_detect_color = 0xB2EDFA
        self.pc_bag_detect_tol = 30
        self.pc_is_bag = False
        self.pc_grinder_poly = False
        self.pc_grinder_metal = False
        self.pc_grinder_crystal = False
        self.pc_preset_raw = False
        self.pc_preset_cooked = False
        self.pc_grinder_filter_poly = "Poly"
        self.pc_grinder_filter_metal = "Metal"
        self.pc_grinder_filter_crystal = "Crystal"
        self.pc_poly_filter = "Poly"
        self.pc_metal_filter = "got"
        self.pc_crystal_filter = "Crystal"
        self.pc_raw_filter = "Raw"
        self.pc_cooked_filter = "Cooked"
        self.pc_custom_filter = ""
        self.pc_all_custom_active = False
        self.pc_all_no_filter = False
        self.pc_speed_mode = 1
        self.pc_drop_sleep = 4
        self.pc_cycle_sleep = 15
        self.pc_hover_delay = 20
        self.pc_speed_map = {0: [8, 40, 35], 1: [4, 15, 20], 2: [1, 5, 8]}
        self.pc_speed_names = {0: "Safe", 1: "Fast", 2: "Very Fast"}
        self.pc_start_slot_x = scale_x(1673)
        self.pc_start_slot_y = scale_y(376)
        self.pc_slot_w = scale_x(121)
        self.pc_slot_h = scale_y(121)
        self.pc_columns = 6
        self.pc_rows = 6
        self.pc_search_bar_x = scale_x(1661)
        self.pc_search_bar_y = scale_y(260)
        self.pl_start_slot_x = round(286.7 * width_multiplier)
        self.pl_start_slot_y = round(369.3 * height_multiplier)
        self.pl_slot_w = round(124.8 * width_multiplier)
        self.pl_slot_h = round(125.6 * height_multiplier)
        self.pc_transfer_all_x = scale_x(576)
        self.pc_transfer_all_y = scale_y(273)
        self.pc_inv_detect_x = scale_x(1447)
        self.pc_inv_detect_y = scale_y(226)
        self.pc_player_inv_detect_x = scale_x(1035)
        self.pc_player_inv_detect_y = scale_y(1033)
        self.pc_player_inv_detect_color = 0xBCF4FF
        self.pc_player_inv_detect_tol = 15
        self.pc_tame_detect_x = scale_x(1224)
        self.pc_tame_detect_y = scale_y(299)
        self.pc_tame_detect_color = 0xFFFECD
        self.pc_tame_detect_tol = 15
        self.pc_is_tame = False
        self.pc_oxy_detect_x = scale_x(1145)
        self.pc_oxy_detect_y = scale_y(756)
        self.pc_oxy_detect_color = 0xBAF2FD
        self.pc_oxy_detect_tol = 15
        self.pc_weight_n_x = scale_x(1213)
        self.pc_weight_n_y = scale_y(783)
        self.pc_weight_n_w = scale_x(260)
        self.pc_weight_n_h = scale_y(40)
        self.pc_weight_o_x = scale_x(1180)
        self.pc_weight_o_y = scale_y(823)
        self.pc_weight_o_w = scale_x(293)
        self.pc_weight_o_h = scale_y(47)
        self.pc_weight_ocr_x = self.pc_weight_n_x
        self.pc_weight_ocr_y = self.pc_weight_n_y
        self.pc_weight_ocr_w = self.pc_weight_n_w
        self.pc_weight_ocr_h = self.pc_weight_n_h
        self.pc_f10_step = 0
        self.pc_log_entries: list = []

        self.ac_running = False
        self.ac_early_exit = False
        self.ac_preset_names: list[str] = []
        self.ac_preset_filters: list[str] = []
        self.ac_preset_timer_secs: list[int] = []
        self.ac_preset_idx = 1
        self.ac_mode = ""
        self.ac_tab_active = False
        self.ac_simple_armed = False
        self.ac_timed_armed = False
        self.ac_grid_armed = False
        self.ac_timed_f_pressed = False
        self.ac_timed_restart = False
        self.ac_timed_multi_active = False
        self.ac_timed_deadlines: list = []
        self.ac_grid_restart = False
        self.ac_grid_running = False
        self.last_debug_context = ""
        self.ac_log: list = []
        self.ac_active_filter = ""
        self.ac_active_item_name = ""
        self.ac_active_timer_secs = 120
        self.ac_feed_last_ms = time.monotonic() * 1000
        self.ac_feed_interval_ms = 45 * 60000
        self.ac_craft_tab_x = scale_x(2218)
        self.ac_craft_tab_y = scale_y(183)
        self.ac_search_x = scale_x(1692)
        self.ac_search_y = scale_y(267)
        self.ac_item_r_x = scale_x(1664)
        self.ac_item_r_y = scale_y(379)
        self.ac_craft_btn_x = scale_x(1695)
        self.ac_craft_btn_y = scale_y(506)
        self.ac_extra_clicks = 0
        self.ac_grid_cols = 1
        self.ac_grid_rows = 11
        self.ac_grid_hwalk = 0
        self.ac_grid_vwalk = 850
        self.ac_craft_loop_running = False
        self.ac_ocr_enabled = False
        self.ac_ocr_resizing = False
        self.ac_ocr_overlay = None
        self.ac_ocr_total = 0
        self.ac_ocr_stations = 0
        self.ac_ocr_station_map = {}
        self.ac_ocr_current_station = 0
        self.ac_count_only_active = False
        self.take_all_enabled = False
        self.ac_ocr_snap_x = round(screen_width * 0.68)
        self.ac_ocr_snap_y = round(screen_height * 0.15)
        self.ac_ocr_snap_w = 250
        self.ac_ocr_snap_h = 35

        self.macro_list: list = []
        self.macro_recording = False
        self.macro_playing = False
        self.macro_tuning = False
        self.macro_tab_active = False
        self.macro_active_idx = 0
        self.macro_record_events: list = []
        self.macro_record_target_idx: int | None = None
        self.macro_record_last_tick = 0
        self.macro_record_last_mouse_x = 0
        self.macro_record_last_mouse_y = 0
        self.macro_save_gui = None
        self.macro_repeat_gui = None
        self.macro_detected_mouse = ""
        self.macro_repeat_key_idx = 1
        self.macro_selected_idx = 1
        self.macro_armed = False
        self.macro_popcorn_armed = False
        self.macro_popcorn_macro = None
        self.macro_speed_dirty = False
        self.macro_hotkeys_live = False
        self.macro_log_entries: list = []
        self.mr_key_list: list = []
        self.me_key_list: list = []
        self.macro_edit_gui = None

        self.guided_wiz_gui = None
        self.guided_wiz_step = 0
        self.guided_inv_type = "storage"
        self.guided_filters: list[str] = []
        self.guided_filter_count = 0
        self.guided_recording = False
        self.guided_record_events: list = []
        self.guided_record_last_tick = 0
        self.guided_record_last_mouse_x = 0
        self.guided_record_last_mouse_y = 0
        self.guided_mouse_speed = 0
        self.guided_mouse_settle = 30
        self.guided_inv_load_delay = 1500
        self.guided_re_record_idx = 0
        self.guided_turbo_default = 30
        self.guided_single_item = False
        self.guided_action_type = "record"
        self.guided_take_count = 3
        self.guided_inv_ready_x = scale_x(1627)
        self.guided_inv_ready_y = scale_y(332)
        self.guided_inv_ready_color = 0x79F4FD
        self.guided_inv_ready_tol = 25

        self.combo_wiz_gui = None
        self.combo_running = False
        self.combo_mode = 0
        self.combo_popcorn_filters: list[str] = []
        self.combo_magic_f_filters: list[str] = []
        self.combo_filter_idx = 1
        self.combo_armed = False
        self.combo_take_count = 0
        self.combo_take_filter = ""

        self.pyro_ast_tek_det_x = scale_x(923)
        self.pyro_ast_tek_det_y = scale_y(717)
        self.pyro_ast_tek_clk_x = scale_x(1088)
        self.pyro_ast_tek_clk_y = scale_y(704)
        self.pyro_ast_no_tek_det_x = scale_x(1277)
        self.pyro_ast_no_tek_det_y = scale_y(1073)
        self.pyro_ast_no_tek_clk_x = scale_x(1280)
        self.pyro_ast_no_tek_clk_y = scale_y(904)
        self.pyro_non_tek_det_x = scale_x(1281)
        self.pyro_non_tek_det_y = scale_y(1075)
        self.pyro_non_tek_clk_x = scale_x(1280)
        self.pyro_non_tek_clk_y = scale_y(897)
        self.pyro_non_no_tek_det_x = scale_x(1635)
        self.pyro_non_no_tek_det_y = scale_y(720)
        self.pyro_non_no_tek_clk_x = scale_x(1481)
        self.pyro_non_no_tek_clk_y = scale_y(708)
        self.pyro_mount_click_x = scale_x(1383)
        self.pyro_mount_click_y = scale_y(857)
        self.pyro_throw_check_x = scale_x(1280)
        self.pyro_throw_check_y = scale_y(968)
        self.pyro_ride_confirm_x = scale_x(1415)
        self.pyro_ride_confirm_y = scale_y(959)
        self.pyro_dismount_x = scale_x(1165)
        self.pyro_dismount_y = scale_y(1177)

        self.game_window = "ArkAscended"
        self.sim_cycle_status = "Idle"
        self.incounter = 0
        self.col_tol = 30
        self.mm = 0
        self.rm = 0
        self.sm = 0
        self.wm = 0
        self.jl = 0
        self.nosessions = 0
        self.stuck_state = ""
        self.stuck_count = 0
        self.search_done = False
        self.sim_initial_search_done = False
        self.sim_mode = 1
        self.auto_sim_check = False
        self.server_number = ""
        self.mods_enabled = False
        self.use_last = False
        self.toolbox_enabled = True
        self.sim_log: list = []
        self.sim_last_state = ""
        self.sim_last_colors = ""
        self.sim_cycle_count = 0

        self.main_gui = None
        self.root = None  # tkinter Tk instance


# Singleton
state = AppState()
