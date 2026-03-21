#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 2
SetKeyDelay -1, -1
SetMouseDelay -1

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

if (A_ScreenWidth != 2560 || A_ScreenHeight != 1440){
    if (A_ScreenWidth != 1920 || A_ScreenHeight != 1080){
        if (A_ScreenWidth != 3840 || A_ScreenHeight != 2160){
            TrayTip("Non-standard resolution (" A_ScreenWidth "x" A_ScreenHeight ") - running in scaled mode","AIO warning",0x1)
        }
    }
}
if (Round(A_ScreenWidth / A_ScreenHeight * 9) != 16)
    TrayTip("Non-16:9 aspect ratio (" A_ScreenWidth "x" A_ScreenHeight ") — pixel coordinates will be misaligned","AIO warning",0x1)

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; GLOBALS - AIO -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

global ScreenWidth      := A_ScreenWidth
global ScreenHeight     := A_ScreenHeight
global heightmultiplier := A_ScreenHeight / 1440
global widthmultiplier  := A_ScreenWidth  / 2560
global arkRunning       := false
global guiVisible       := true
global runMagicFScript      := false
global magicFRefillMode     := false
global magicFPresetNames    := []
global magicFPresetFilters  := []
global magicFPresetDirs     := []
global magicFPresetIdx      := 1
global mfSearchBarClickMs  := 30
global mfFilterSettleMs    := 100
global mfTransferSettleMs  := 100
if (!FileExist(A_ScriptDir "\AIO_config.ini")) {
    if (FileExist(A_ScriptDir "\AIO_config.default.ini"))
        FileCopy(A_ScriptDir "\AIO_config.default.ini", A_ScriptDir "\AIO_config.ini")
    else {
        IniWrite(30, A_ScriptDir "\AIO_config.ini", "Timings", "SearchBarClickMs")
        IniWrite(100, A_ScriptDir "\AIO_config.ini", "Timings", "FilterSettleMs")
        IniWrite(100, A_ScriptDir "\AIO_config.ini", "Timings", "TransferSettleMs")
    }
}
try mfSearchBarClickMs := Integer(IniRead(A_ScriptDir "\AIO_config.ini", "Timings", "SearchBarClickMs", "30"))
try mfFilterSettleMs   := Integer(IniRead(A_ScriptDir "\AIO_config.ini", "Timings", "FilterSettleMs", "100"))
try mfTransferSettleMs := Integer(IniRead(A_ScriptDir "\AIO_config.ini", "Timings", "TransferSettleMs", "100"))
global runAutoLvlScript     := false
global autoLvlCryoCheck     := ""
global autoLvlCycleSlots    := []
global autoLvlCycleIdx      := 1
global autoLvlCombineChk    := ""
global runClaimAndNameScript := false
global runMammothScript     := false
global quickFeedMode        := 0
global perfLog              := []
global svrList              := []
global svrNoteGui           := ""
global ufList               := []
global cnNameList            := []
global acSimpleFilterList    := []
global acTimedFilterList     := []
global acGridFilterList      := []
global pcCustomFilterList    := []
global mfGiveFilterList      := []
global mfTakeFilterList      := []

global runOvercapScript  := false
global overcapDediTarget := 0
global overcapStartTick  := 0
global overcapAccumMs    := 0
global overcapDediTable  := Map(1,14000, 2,35000, 3,35000, 4,56000, 5,77000, 6,98000, 7,119000, 8,140000, 9,161000)
global autoclicking         := false
global autoclickInterval    := 750
global autoclickIntervalStep := 100
global autoclickMinInterval := 50

; --- Quick Hatch ---
global qhMode       := 0
global qhArmed      := false
global qhRunning    := false
global qhClick1X    := Round(1676 * widthmultiplier)
global qhClick1Y    := Round(380  * heightmultiplier)
global qhClick2X    := Round(1271 * widthmultiplier)
global qhClick2Y    := Round(1175 * heightmultiplier)
global qhInvPixX    := Round(456 * widthmultiplier)
global qhInvPixY    := Round(217 * heightmultiplier)
global qhLogEntries  := []
global qhClickDelay  := 1
global depoEggsActive    := false
global depoEmbryoActive  := false
global depoCycle          := []
global depoCycleIdx       := 0
global qhEmptyPixX   := Round(1040 * widthmultiplier)
global qhEmptyPixY   := Round(736  * heightmultiplier)
global qhEmptyColor  := "0x019C88"
global qhEmptyTol    := 30

global qhEggSlotX := [
    Round(1488 * widthmultiplier),
    Round(1439 * widthmultiplier),
    Round(1385 * widthmultiplier),
    Round(1336 * widthmultiplier),
    Round(1281 * widthmultiplier),
    Round(1235 * widthmultiplier),
    Round(1180 * widthmultiplier),
    Round(1133 * widthmultiplier),
    Round(1080 * widthmultiplier),
    Round(1032 * widthmultiplier)
]
global qhEggSlotY := [
    Round(732 * heightmultiplier),
    Round(733 * heightmultiplier),
    Round(732 * heightmultiplier),
    Round(733 * heightmultiplier),
    Round(732 * heightmultiplier),
    Round(732 * heightmultiplier),
    Round(733 * heightmultiplier),
    Round(732 * heightmultiplier),
    Round(733 * heightmultiplier),
    Round(733 * heightmultiplier)
]

; --- Auto Imprint ---
global imprintScanning   := false
global imprintAutoMode   := false
global imprintInventoryKey := "v"
global imprintScanOverlay := ""
global imprintHelpGui     := ""
global imprintResizing    := false
global imprintHideOverlay := false
global imprintLog         := []

global imprintSnapW := 560
global imprintSnapH := 80
global imprintSnapX := (A_ScreenWidth // 2) - (imprintSnapW // 2)
global imprintSnapY := (A_ScreenHeight // 2) - (imprintSnapH // 2) + 20

global imprintInvPixX  := Round(461 * widthmultiplier)
global imprintInvPixY  := Round(215 * heightmultiplier)
global imprintSearchX  := Round(311 * widthmultiplier)
global imprintSearchY  := Round(261 * heightmultiplier)
global imprintResultX  := Round(297 * widthmultiplier)
global imprintResultY  := Round(359 * heightmultiplier)

global imprintAllFoods := [
    "cuddle",
    "Amarberry", "Azulberry", "Mejoberry", "Tintoberry",
    "Cianberry", "Magenberry", "Verdberry",
    "Cooked Prime Fish Meat", "Cooked Fish Meat",
    "Cooked Prime Meat", "Cooked Meat Jerky", "Prime Meat Jerky",
    "Cooked Meat", "Kibble"
]

; --- Name/Spay ---
global runNameAndSpayScript := false
global nsLogEntries := []
global nsHelpGui   := ""
global mfHelpGui   := ""
global nsRadialX  := Round(1040 * widthmultiplier)
global nsRadialY  := Round(861  * heightmultiplier)
global nsAltRadialX := Round(1176 * widthmultiplier)
global nsAltRadialY := Round(948  * heightmultiplier)
global nsAltClickX  := Round(1179 * widthmultiplier)
global nsAltClickY  := Round(948  * heightmultiplier)
global nsAlt2RadialX := Round(1489 * widthmultiplier)
global nsAlt2RadialY := Round(523  * heightmultiplier)
global nsAlt2ClickX  := Round(1033 * widthmultiplier)
global nsAlt2ClickY  := Round(764  * heightmultiplier)
global nsSpayX    := Round(1025 * widthmultiplier)
global nsSpayY    := Round(561  * heightmultiplier)
global nsAdminPixX := Round(1035 * widthmultiplier)
global nsAdminPixY := Round(508  * heightmultiplier)
global nsAdminSpayX := Round(1017 * widthmultiplier)
global nsAdminSpayY := Round(780  * heightmultiplier)

global DrumPixelX := Round(A_ScreenWidth  * (815  / 1920))
global DrumPixelY := Round(A_ScreenHeight * (920  / 1080))

global transferToMeButtonX    := 1917 * widthmultiplier
global transferToMeButtonY    := 264  * heightmultiplier
global transferToOtherButtonX := 550  * widthmultiplier
global transferToOtherButtonY := 265  * heightmultiplier
global myInvDropAllButtonX    := 622  * widthmultiplier
global myInvDropAllButtonY    := 257  * heightmultiplier
global myInvCraftingButtonX   := 601  * widthmultiplier
global myInvCraftingButtonY   := 187  * heightmultiplier
global mySearchBarX           := 339  * widthmultiplier
global mySearchBarY           := 256  * heightmultiplier
global myFirstSlotX           := 300  * widthmultiplier
global myFirstSlotY           := 370  * heightmultiplier
global theirInvSearchBarX     := 1678 * widthmultiplier
global theirInvSearchBarY     := 266  * heightmultiplier
global theirInvDropAllButtonX := 1989 * widthmultiplier
global theirInvDropAllButtonY := 260  * heightmultiplier

; --- OB Upload ---
global obLog             := []
global obUploadMode      := 0
global obUploadArmed     := false
global obUploadRunning   := false
global obUploadFilter    := ""
global obStatusText      := ""
global obInvFailBtnX    := Round(1241 * widthmultiplier)
global obInvFailBtnY    := Round(1277 * heightmultiplier)
global obInvFailBtnPixX := Round(1241 * widthmultiplier)
global obInvFailBtnPixY := Round(1277 * heightmultiplier)
global obInvPixX         := Round(1699 * widthmultiplier)
global obInvPixY         := Round(181  * heightmultiplier)
global obConfirmPixX     := Round(1479 * widthmultiplier)
global obConfirmPixY     := Round(228  * heightmultiplier)
global obMySlot1X        := Round(300  * widthmultiplier)
global obMySlot1Y        := Round(370  * heightmultiplier)
global obEmptyCheckX     := Round(300  * widthmultiplier)
global obEmptyCheckY     := Round(350  * heightmultiplier)
global obCryoPixX         := Round(279  * widthmultiplier)
global obCryoPixY         := Round(311  * heightmultiplier)
global obCryoUnelPixX     := Round(292  * widthmultiplier)
global obCryoUnelPixY     := Round(317  * heightmultiplier)
global obCryoHoverStartX  := Round(260  * widthmultiplier)
global obCryoHoverStartY  := Round(407  * heightmultiplier)
global obCryoHoverEndX    := Round(217  * widthmultiplier)
global obCryoHoverEndY    := Round(407  * heightmultiplier)
global obCryoWhitePixX    := Round(224  * widthmultiplier)
global obCryoWhitePixY    := Round(305  * heightmultiplier)
global obItemNamePixX     := Round(332  * widthmultiplier)
global obItemNamePixY     := Round(417  * heightmultiplier)
global obTimerPixX        := Round(243  * widthmultiplier)
global obTimerPixY        := Round(413  * heightmultiplier)
global obDaydPixX         := Round(253  * widthmultiplier)
global obDaydPixY         := Round(419  * heightmultiplier)
global obTekPixX          := Round(371  * widthmultiplier)
global obTekPixY          := Round(401  * heightmultiplier)
global obTekPix2X         := Round(245  * widthmultiplier)
global obTekPix2Y         := Round(408  * heightmultiplier)
global obTekPix3X         := Round(233  * widthmultiplier)
global obTekPix3Y         := Round(417  * heightmultiplier)
global obEmptySlotR       := 0x0A
global obEmptySlotG       := 0x4A
global obEmptySlotB       := 0x6B
global obFullPixX         := Round(1045 * widthmultiplier)
global obFullPixY         := Round(512  * heightmultiplier)
global obMaxItemsPixX     := Round(1045 * widthmultiplier)
global obMaxItemsPixY     := Round(507  * heightmultiplier)
global obRightTabPixX     := Round(1703 * widthmultiplier)
global obRightTabPixY     := Round(181  * heightmultiplier)
global obUploadTabX       := Round(1697 * widthmultiplier)
global obUploadTabY       := Round(181  * heightmultiplier)
global obUploadReadyPixX  := Round(1700 * widthmultiplier)
global obUploadReadyPixY  := Round(183  * heightmultiplier)
global obRefreshPixX      := Round(1292 * widthmultiplier)
global obRefreshPixY      := Round(493  * heightmultiplier)
global obOvPixX           := Round(1444 * widthmultiplier)
global obOvPixY           := Round(227  * heightmultiplier)
global obAllPixX          := Round(385  * widthmultiplier)
global obAllPixY          := Round(347  * heightmultiplier)
global obDataLoadedPixX   := Round(1493 * widthmultiplier)
global obDataLoadedPixY   := Round(592  * heightmultiplier)
global obUploadStallMs    := 8000
global obHoverAwayMs      := 10
global obHoverGlideSpeed  := 0
global obHoverSettleMs    := 10
global obClickSettleMs    := 10
global obPostRefreshMs    := 0
global obPreUploadMs      := 200
global obUploadEarlyExit  := false
global obFirstUpload     := true
global obInitFailed       := false
global obUploadPaused     := false
global obActiveFilter     := ""
global obInvTimeout       := 250

; --- OB Upload Character ---
global obCharTravelX      := 0
global obCharTravelY      := 0
global obCharCustomServer := ""
global obCharSvrIdx       := 0
global obCharTimerStage   := 0

; --- OB Download ---
global obDownloadArmed    := false
global obDownloadRunning  := false
global obDownloadPaused   := false
global obDownText         := ""
global obDownSlotX        := Round(1657 * widthmultiplier)
global obDownSlotY        := Round(379  * heightmultiplier)
global obBarPixX          := Round(1025 * widthmultiplier)
global obBarPixY          := Round(613  * heightmultiplier)
global obTooltipPixX      := Round(936  * widthmultiplier)
global obTooltipPixY      := Round(272  * heightmultiplier)
global obTooltipsWereOn   := false
global obDownItemDelayMs   := 1500
global obDownItemDelayStep := 100
global obDownItemDelayMin  := 200
global obDownItemDelayMax  := 3000
global obDownBarSettleMs   := 12000

; --- OB OCR Regions ---
global obOcrResizing   := false
global obOcrTarget     := 0
global obOcrOverlays   := ""
global obOcrX          := [Round(270 * widthmultiplier), Round(640 * widthmultiplier), Round(1630 * widthmultiplier), Round(640 * widthmultiplier), Round(239 * widthmultiplier)]
global obOcrY          := [Round(365 * heightmultiplier), Round(440 * heightmultiplier), Round(325 * heightmultiplier), Round(440 * heightmultiplier), Round(301 * heightmultiplier)]
global obOcrW          := [Round(80  * widthmultiplier), Round(640 * widthmultiplier), Round(150 * widthmultiplier), Round(640 * widthmultiplier), Round(757 * widthmultiplier)]
global obOcrH          := [Round(40  * heightmultiplier), Round(60 * heightmultiplier), Round(40 * heightmultiplier), Round(60 * heightmultiplier), Round(816 * heightmultiplier)]

; --- NVIDIA Filter---
global nfEnabled := false

; --- Auto Pin ---
global pinAutoOpen     := true
global pinLog          := []
global pinPollCount    := 0
global pinPollActive   := false
global pinPollStartTick := 0
global pinEwasHeld     := false
global pinHoldThreshold := 300     
global pinTol          := 30
global pinPollInterval := 16
global pinPollMaxTicks := 94        
global pinPix1X  := Round(1199 * widthmultiplier)
global pinPix1Y  := Round(381  * heightmultiplier)
global pinPix2X  := Round(1248 * widthmultiplier)
global pinPix2Y  := Round(407  * heightmultiplier)
global pinPix3X  := Round(1103 * widthmultiplier)
global pinPix3Y  := Round(416  * heightmultiplier)
global pinPix4X  := Round(1424 * widthmultiplier)
global pinPix4Y  := Round(405  * heightmultiplier)
global pinClickX := Round(1275 * widthmultiplier)
global pinClickY := Round(999  * heightmultiplier)

; --- Grab My Kit ---
global gmkMode := "off"

global ntfykey := readini("ntfy", "key")
if (ntfykey = "Default")
    ntfykey := ""

global iniCommandKey := readini("ini", "commandkey")
if (iniCommandKey = "Default")
    iniCommandKey := "{vkC0}"

global iniCustomCommand := readini("ini", "customcommand")
if (iniCustomCommand = "Default")
    iniCustomCommand := ""


global iniDefaultCommand := "sg.FoliageQuality 0 | sg.TextureQuality 0 | r.Shading.FurnaceTest.SampleCount 0 | r.VolumetricCloud 0 | r.VolumetricFog 0 | r.Water.SingleLayer.Reflection 0 | r.ShadowQuality 0 | r.ContactShadows 0 | r.DepthOfFieldQuality 0 | r.Fog 0 | r.BloomQuality 0 | r.LightCulling.Quality 0 | r.SkyAtmosphere 1 | r.Lumen.Reflections.Allow 1 | r.Lumen.DiffuseIndirect.Allow 1 | r.Shadow.Virtual.Enable 0 | r.DistanceFieldShadowing 1 | r.Shadow.CSM.MaxCascades 0 | r.SkylightIntensityMultiplier 99 | grass.SizeScale 0 | ark.MaxActiveDestroyedMeshGeoCollectionCount 0 | sg.GlobalIlluminationQuality 1 | r.Nanite.MaxPixelsPerEdge 3 | r.Tonemapper.Sharpen 3 | r.SkyLight.RealTimeReflectionCapture 0 | r.EyeAdaptation.BlackHistogramBucketInfluence 0 | r.Lumen.Reflections.Contrast 0 | r.LightMaxDrawDistanceScale -1 | r.Lumen.ScreenProbeGather.DirectLighting 1 | r.Color.Grading 0 | fx.MaxNiagaraGPUParticlesSpawnPerFrame 50 | Slate.GlobalScrollAmount 120 | r.SkyLightingQuality 1 | r.VT.EnableFeedback 0 | gamma | r.ScreenPercentage 100 | grass.DensityScale 0 | stat FPS | r.MinRoughnessOverride 1 | r.DynamicGlobalIlluminationMethod 1 | r.Streaming.PoolSize 1 | r.MipMapLODBias 0 | r.Lumen.ScreenProbeGather.RadianceCache.ProbeResolution 16 | r.VSync 0 | show InstancedFoliage | show InstancedGrass | show InstancedStaticMeshes | r.AOOverwriteSceneColor 1 | Slate.Contrast 1 | sg.ReflectionQuality 0"

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; GLOBALS - SHEEP -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

global sx := A_ScreenWidth
global sy := A_ScreenHeight

global blackBoxX    := Round(2319 * widthmultiplier)
global blackBoxY    := Round(1372 * heightmultiplier)
global overcapBoxX  := Round(2201 * widthmultiplier)
global overcapBoxY  := Round(1380 * heightmultiplier)
global dropAllX     := Round(616  * widthmultiplier)
global dropAllY     := Round(260  * heightmultiplier)
global invySearchX  := Round(387  * widthmultiplier)
global invySearchY  := Round(265  * heightmultiplier)
global invyDetectX  := Round(456 * widthmultiplier)
global invyDetectY  := Round(217 * heightmultiplier)

global sheepLvlPixelX := Round(sx * (1632 / 2560))
global sheepLvlPixelY := Round(sy * (215  / 1440))
global sheepLvlClickX := Round(sx * (1507 / 2560))
global sheepLvlClickY := Round(sy * (667  / 1440))

global overcappingToggle   := false
global sheepRunning        := false
global sheepAutoLvlActive  := false
global sheepModeActive     := false
global sheepStatusBottomAnchor := 0
global sheepAutoLvlGui     := ""
global sheepStatusGui      := ""
global arkWindow           := "ArkAscended"

global sheepToggleKey      := "g"
global sheepOvercapKey     := "b"
global sheepInventoryKey   := ""

;─────────────────────────────────────────────────────────────────────────────
;─────────────────────────────────────────────────────────────────────────────
global pcMode              := 0
global pcInvKey            := "f"
global pcDropKey           := "g"
global pcRunning           := false
global pcEarlyExit         := false
global pcF1Abort           := false
global pcTabActive         := true

global pcStorageScanBaseX  := 1347
global pcStorageScanBaseY  := 693
global pcStorageScanBaseW  := 187
global pcStorageScanBaseH  := 93
global pcStorageScanX      := Round(pcStorageScanBaseX * widthmultiplier)
global pcStorageScanY      := Round(pcStorageScanBaseY * heightmultiplier)
global pcStorageScanW      := Round(pcStorageScanBaseW * widthmultiplier)
global pcStorageScanH      := Round(pcStorageScanBaseH * heightmultiplier)
global pcStorageResizing   := false
global pcStorageOverlay    := ""

global pcForgeSkipFirst    := false
global pcForgeTransferAll  := false
global pcBagDetectX        := Round(1398.7 * widthmultiplier)
global pcBagDetectY        := Round(278.7  * heightmultiplier)
global pcBagDetectColor    := "0xB2EDFA"
global pcBagDetectTol      := 30
global pcIsBag             := false

global pcGrinderPoly       := false
global pcGrinderMetal      := false
global pcGrinderCrystal    := false
global pcPresetRaw         := false
global pcPresetCooked      := false
global pcGrinderFilterPoly    := "Poly"
global pcGrinderFilterMetal   := "Metal"
global pcGrinderFilterCrystal := "Crystal"
global pcPolyFilter    := "Poly"
global pcMetalFilter   := "got"
global pcCrystalFilter := "Crystal"
global pcRawFilter     := "Raw"
global pcCookedFilter  := "Cooked"


global pcCustomFilter      := ""
global pcAllCustomActive   := false
global pcAllNoFilter       := false

global pcSpeedMode         := 1
global pcDropSleep         := 4
global pcCycleSleep        := 15
global pcHoverDelay        := 20
global pcSpeedMap          := Map(0,[8,40,35], 1,[4,15,20], 2,[1,5,8])
global pcSpeedNames        := Map(0,"Safe", 1,"Fast", 2,"Very Fast")

global pcStartSlotX        := Round(1673 * widthmultiplier)
global pcStartSlotY        := Round(376  * heightmultiplier)
global pcSlotW             := Round(121  * widthmultiplier)
global pcSlotH             := Round(121  * heightmultiplier)
global pcColumns           := 6
global pcRows              := 6

global pcSearchBarX        := Round(1661 * widthmultiplier)
global pcSearchBarY        := Round(260  * heightmultiplier)

global plStartSlotX        := Round(286.7 * widthmultiplier)
global plStartSlotY        := Round(369.3 * heightmultiplier)
global plSlotW             := Round(124.8 * widthmultiplier)
global plSlotH             := Round(125.6 * heightmultiplier)

global pcTransferAllX      := Round(576  * widthmultiplier)
global pcTransferAllY      := Round(273  * heightmultiplier)

global pcInvDetectX        := Round(1447 * widthmultiplier)
global pcInvDetectY        := Round(226  * heightmultiplier)

global pcPlayerInvDetectX  := Round(1035 * widthmultiplier)
global pcPlayerInvDetectY  := Round(1033 * heightmultiplier)
global pcPlayerInvDetectColor := 0xBCF4FF
global pcPlayerInvDetectTol := 15

global pcTameDetectX       := Round(1224 * widthmultiplier)
global pcTameDetectY       := Round(299  * heightmultiplier)
global pcTameDetectColor   := 0xFFFECD
global pcTameDetectTol     := 15
global pcIsTame            := false

global pcOxyDetectX        := Round(1145 * widthmultiplier)
global pcOxyDetectY        := Round(756  * heightmultiplier)
global pcOxyDetectColor    := 0xBAF2FD
global pcOxyDetectTol      := 15

global pcWeightNX := Round(1213 * widthmultiplier)
global pcWeightNY := Round(783  * heightmultiplier)
global pcWeightNW := Round(260  * widthmultiplier)
global pcWeightNH := Round(40   * heightmultiplier)
global pcWeightOX := Round(1180 * widthmultiplier)
global pcWeightOY := Round(823  * heightmultiplier)
global pcWeightOW := Round(293  * widthmultiplier)
global pcWeightOH := Round(47   * heightmultiplier)
global pcWeightOcrX := pcWeightNX
global pcWeightOcrY := pcWeightNY
global pcWeightOcrW := pcWeightNW
global pcWeightOcrH := pcWeightNH

global pcSpeedTxt, pcStatusTxt
global pcCustomCard
global pcForgeSkipInd, pcForgeXferInd
global pcPolyInd, pcMetalInd, pcCrystalInd, pcRawInd, pcCookedInd
global pcF10StatusTxt
global pcF10Step := 0
global sheepAutoLvlKey     := "z"
global pcLogEntries        := []
global sheepLevelActionKey := "z"

global sheepTabActive := false

;─────────────────────────────────────────────────────────────────────────────
; AUTO CRAFT GLOBALS
;─────────────────────────────────────────────────────────────────────────────
global acRunning          := false
global acEarlyExit        := false
global acPresetNames      := []
global acPresetFilters    := []
global acPresetTimerSecs  := []
global acPresetIdx        := 1
global acMode             := ""
global acTabActive        := false
global acSimpleArmed      := false
global acTimedArmed       := false
global acGridArmed        := false
global acTimedFPressed    := false
global acTimedRestart     := false
global acTimedMultiActive := false
global acTimedDeadlines   := []
global acGridRestart      := false
global acGridRunning      := false
global lastDebugContext   := ""
global acLog              := []

global acActiveFilter     := ""
global acActiveItemName   := ""
global acActiveTimerSecs  := 120

global acFeedLastMs       := A_TickCount
global acFeedIntervalMs   := 45 * 60000

global acCraftTabX  := Round(2218 * widthmultiplier)
global acCraftTabY  := Round(183  * heightmultiplier)
global acSearchX    := Round(1692 * widthmultiplier)
global acSearchY    := Round(267  * heightmultiplier)
global acItemRX     := Round(1664 * widthmultiplier)
global acItemRY     := Round(379  * heightmultiplier)
global acCraftBtnX  := Round(1695 * widthmultiplier)
global acCraftBtnY  := Round(506  * heightmultiplier)
global acExtraClicks := 0
global acCraftLoopRunning := false

global acSimpleFilterEdit
global acTimedFilterEdit, acTimedSecsEdit
global acGridFilterEdit, acColsEdit, acRowsEdit, acHWalkEdit, acVWalkEdit

; --- Grid OCR storage reading ---
global acOcrEnabled   := false
global acOcrResizing  := false
global acOcrOverlay   := ""
global acOcrTotal     := 0
global acOcrStations  := 0
global acOcrStationMap := Map()
global acOcrCurrentStation := 0
global acCountOnlyActive   := false
global acOcrSnapX     := Round(A_ScreenWidth * 0.68)
global acOcrSnapY     := Round(A_ScreenHeight * 0.15)
global acOcrSnapW     := 250
global acOcrSnapH     := 35

;─────────────────────────────────────────────────────────────────────────────
; MACRO SYSTEM GLOBALS
;─────────────────────────────────────────────────────────────────────────────
global macroList             := []
global macroRecording        := false
global macroPlaying          := false
global macroTuning           := false
global macroTabActive        := false
global macroActiveIdx        := 0
global macroRecordEvents     := []
global macroRecordLastTick   := 0
global macroRecordLastMouseX := 0
global macroRecordLastMouseY := 0
global macroSaveGui          := ""
global macroRepeatGui        := ""
global macroDetectedMouse    := ""
global macroRepeatKeyIdx     := 1
global _macroBgInterval      := 1000
global macroSelectedIdx      := 1
global macroArmed            := false
global macroPopcornArmed     := false
global macroPopcornMacro     := ""
global macroSpeedDirty       := false
global macroHotkeysLive      := false

global macroLogEntries       := []
global mrKeyList             := []
global meKeyList             := []
global macroEditGui          := ""
global macroLV

global guidedWizGui          := ""
global guidedWizStep         := 0
global guidedInvType         := "storage"
global guidedFilters         := []
global guidedFilterCount     := 0
global guidedRecording       := false
global guidedRecordEvents    := []
global guidedRecordLastTick  := 0
global guidedRecordLastMouseX := 0
global guidedRecordLastMouseY := 0
global guidedMouseSpeed      := 0
global guidedMouseSettle     := 30
global guidedInvLoadDelay   := 1500
global guidedReRecordIdx    := 0
global guidedTurboDefault   := 30
global guidedSingleItem     := false
global guidedActionType    := "record"
global guidedTakeCount     := 3

global guidedInvReadyX      := Round(1627 * widthmultiplier)
global guidedInvReadyY      := Round(332  * heightmultiplier)
global guidedInvReadyColor  := "0x79F4FD"
global guidedInvReadyTol    := 25

global comboWizGui           := ""
global comboRunning          := false
global comboMode             := 0
global comboPopcornFilters   := []
global comboMagicFFilters    := []
global comboFilterIdx        := 1
global comboArmed            := false
global comboTakeCount        := 0
global comboTakeFilter       := ""

global pyroAstTekDetX   := Round(923  * widthmultiplier)
global pyroAstTekDetY   := Round(717  * heightmultiplier)
global pyroAstTekClkX   := Round(1088 * widthmultiplier)
global pyroAstTekClkY   := Round(704  * heightmultiplier)
global pyroAstNoTekDetX := Round(1277 * widthmultiplier)
global pyroAstNoTekDetY := Round(1073 * heightmultiplier)
global pyroAstNoTekClkX := Round(1280 * widthmultiplier)
global pyroAstNoTekClkY := Round(904  * heightmultiplier)
global pyroNonTekDetX   := Round(1281 * widthmultiplier)
global pyroNonTekDetY   := Round(1075 * heightmultiplier)
global pyroNonTekClkX   := Round(1280 * widthmultiplier)
global pyroNonTekClkY   := Round(897  * heightmultiplier)
global pyroNonNoTekDetX := Round(1635 * widthmultiplier)
global pyroNonNoTekDetY := Round(720  * heightmultiplier)
global pyroNonNoTekClkX := Round(1481 * widthmultiplier)
global pyroNonNoTekClkY := Round(708  * heightmultiplier)
global pyroMountClickX  := Round(1383 * widthmultiplier)
global pyroMountClickY  := Round(857  * heightmultiplier)
global pyroThrowCheckX  := Round(1280 * widthmultiplier)
global pyroThrowCheckY  := Round(968  * heightmultiplier)
global pyroRideConfirmX := Round(1415 * widthmultiplier)
global pyroRideConfirmY := Round(959  * heightmultiplier)
global pyroDismountX    := Round(1165 * widthmultiplier)
global pyroDismountY    := Round(1177 * heightmultiplier)

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CoordMode("ToolTip", "Screen")
global GameWindow := "ArkAscended"
global GameHeight := 0
global GameWidth  := 0
global simcyclestatus := "Idle"
global incounter  := 0
global coltol     := 30
global MM := 0
global RM := 0
global SM := 0
global WM := 0
global JL := 0
global nosessions := 0
global stuckState := ""
global stuckCount := 0
global searchDone := false
global simInitialSearchDone := false
global simMode := 1
global modsEnabled := false
global useLast := false
global toolboxEnabled := true
global simLog := []
global simLastState := ""
global simLastColors := ""
global simCycleCount := 0

if (WinExist(GameWindow)) {
    WinMove(0, 0, , , GameWindow)
    WinGetPos(&GameX, &GameY, &GameWidth, &GameHeight, GameWindow)
} else {
    MsgBox("Ark Not Detected.")
    ExitApp()
}

col := {
    MainMenu:        "0xffffffff",
    MiddleMenu:      "0xFF86EAFF",
    MiddleMenuAlt:   "0xFFA4F0FF",
    ServerBrowser:   "0xFFC1F5FF",
    ServerBrowserAlt:"0xFF9CB1B7",
    BeLogo:          "0xFFFFFFBC",
    BeLogoAlt:       "0xFFFFFFFF",
    NoSession:       "0xFFC1F5FF",
    Join:            "0xFFFFFFFF",
    ModJoin:         "0xFFFFFFFF",
    ServerFull:      "0xFFC1F5FF",
    Timeout:         "0xFFFF0000",
    WaitJoin:        "0xFF556D69",
    ContentFailed:   "0xFF88DDF2",
    ModMenu:         "0xFF85D8ED",
    SinglePlayer:    "0xFFFFC000"
}

ModJoinOffsetX       := Integer(0.28125               * GameWidth)
ModJoinOffsetY       := Integer(0.86388888888888893   * GameHeight)
ContentFailedOffsetX := Integer(0.53125              * GameWidth)
ContentFailedOffsetY := Integer(0.5120570370         * GameHeight)
WaitingToJoinOffsetX := Integer(0.8640625            * GameWidth)
WaitingToJoinOffsetY := Integer(0.875                * GameHeight)
ModMenuOffsetX       := Integer(0.14270833333333333  * GameWidth)
ModMenuOffsetY       := Integer(0.56388888888888888  * GameHeight)
BeLogoOffsetX        := Integer(0.056250000000000001 * GameWidth)
BeLogoOffsetY        := Integer(0.3037037037037037   * GameHeight)
MiddleMenuOffsetX    := Integer(0.49843749999999998  * GameWidth)
MiddleMenuOffsetY    := Integer(0.89351851851851849  * GameHeight)
ServerBrowserOffsetX := Integer(0.050520833333333334 * GameWidth)
ServerBrowserOffsetY := Integer(0.09166666666666666  * GameHeight)
MainMenuJoinOffsetX  := Integer(0.5828125            * GameWidth)
MainMenuJoinOffsetY  := Integer(0.81111111111111112  * GameHeight)
ServerSearchOffsetX  := Integer(0.8723958333         * GameWidth)
ServerSearchOffsetY  := Integer(0.1805555556         * GameHeight)
ServerJoinOffsetX    := Integer(0.88020833333333337  * GameWidth)
ServerJoinOffsetY    := Integer(0.875                * GameHeight)
BackOffsetX          := Integer(0.0859375            * GameWidth)
BackOffsetY          := Integer(0.8148148148         * GameHeight)
JoinGameOffsetX      := Integer(0.2864583333         * GameWidth)
JoinGameOffsetY      := Integer(0.5092592593         * GameHeight)
ClickSessionOffsetX  := Integer(0.2052083333         * GameWidth)
ClickSessionOffsetY  := Integer(0.3009259259         * GameHeight)
ClickSessionBOffsetX := Integer(0.5052083333         * GameWidth)
ClickSessionBOffsetY := Integer(0.3009259259         * GameHeight)
ServerFullOffsetX    := Integer(0.5666666667         * GameWidth)
ServerFullOffsetY    := Integer(0.3277777778         * GameHeight)
ServerFull2OffsetX   := Integer(0.46354166666666669  * GameWidth)
ServerFull2OffsetY   := Integer(0.3351851851851852   * GameHeight)
ServerFull3OffsetX   := Integer(0.52708333333333335  * GameWidth)
ServerFull3OffsetY   := Integer(0.37037037037037035  * GameHeight)
TimeoutOffsetX       := Integer(0.5489583333         * GameWidth)
TimeoutOffsetY       := Integer(0.3481481481         * GameHeight)
RefreshOffsetX       := Integer(0.4895833333         * GameWidth)
RefreshOffsetY       := Integer(0.8703703704         * GameHeight)
NoSessionsOffsetX    := Integer(0.5447916667         * GameWidth)
NoSessionsOffsetY    := Integer(0.4462962963         * GameHeight)
NoSessConfirmX       := Integer(0.3786458333         * GameWidth)
NoSessConfirmY       := Integer(0.2101851852         * GameHeight)
NoSessRowCheckX      := Integer(0.2083333333         * GameWidth)
NoSessRowCheckY      := Integer(0.2305555556         * GameHeight)
JoinLastOffsetX      := Integer(0.89270833333333333  * GameWidth)
JoinLastOffsetY      := Integer(0.82777777777777772  * GameHeight)
SinglePlayerOffsetX  := Integer(0.76406249999999998  * GameWidth)
SinglePlayerOffsetY  := Integer(0.83981481481481479  * GameHeight)
SPBackOffsetX        := Integer(0.10052083333333334  * GameWidth)
SPBackOffsetY        := Integer(0.88055555555555554  * GameHeight)

states := [
    { name: "ServerFull",        x: ServerFullOffsetX,    y: ServerFullOffsetY,    c: col.ServerFull },
    { name: "ServerFull2",       x: ServerFull2OffsetX,   y: ServerFull2OffsetY,   c: col.ServerFull },
    { name: "ServerFull3",       x: ServerFull3OffsetX,   y: ServerFull3OffsetY,   c: col.ServerFull },
    { name: "ConnectionTimeout", x: TimeoutOffsetX,       y: TimeoutOffsetY,       c: col.Timeout },
    { name: "WaitingToJoin",     x: WaitingToJoinOffsetX, y: WaitingToJoinOffsetY, c: col.WaitJoin },
    { name: "NoSessions",        x: NoSessionsOffsetX,    y: NoSessionsOffsetY,    c: col.NoSession,
                                 x2: ServerBrowserOffsetX, y2: ServerBrowserOffsetY, c2: col.ServerBrowser },
    { name: "ServerSelected",    x: BeLogoOffsetX,        y: BeLogoOffsetY,        c: col.BeLogo,
                                 calt: col.BeLogoAlt,
                                 x2: ServerJoinOffsetX,   y2: ServerJoinOffsetY,   c2: col.Join },
    { name: "ServerBrowser",     x: ServerBrowserOffsetX, y: ServerBrowserOffsetY, c: col.ServerBrowser,
                                 calt: col.ServerBrowserAlt },
    { name: "ModMenu",           x: ModMenuOffsetX,       y: ModMenuOffsetY,       c: col.ModMenu,
                                 x2: ModJoinOffsetX,      y2: ModJoinOffsetY,      c2: col.ModJoin },
    { name: "ContentFailed",     x: ContentFailedOffsetX, y: ContentFailedOffsetY, c: col.ContentFailed },
    { name: "MainMenu",          x: MainMenuJoinOffsetX,  y: MainMenuJoinOffsetY,  c: col.MainMenu },
    { name: "MiddleMenu",        x: MiddleMenuOffsetX,    y: MiddleMenuOffsetY,    c: col.MiddleMenu,
                                 calt: col.MiddleMenuAlt },
    { name: "SinglePlayer",      x: SinglePlayerOffsetX,  y: SinglePlayerOffsetY,  c: col.SinglePlayer }
]

statesB := [
    { name: "ServerFull",        x: ServerFullOffsetX,    y: ServerFullOffsetY,    c: col.ServerFull },
    { name: "ConnectionTimeout", x: TimeoutOffsetX,       y: TimeoutOffsetY,       c: col.Timeout },
    { name: "NoSessions",        x: NoSessionsOffsetX,    y: NoSessionsOffsetY,    c: col.NoSession },
    { name: "ServerSelected",    x: BeLogoOffsetX,        y: BeLogoOffsetY,        c: col.BeLogo,
                                 calt: col.BeLogoAlt,
                                 x2: ServerJoinOffsetX,   y2: ServerJoinOffsetY,   c2: col.Join },
    { name: "ServerBrowser",     x: ServerBrowserOffsetX, y: ServerBrowserOffsetY, c: col.ServerBrowser,
                                 calt: col.ServerBrowserAlt },
    { name: "ModMenu",           x: ModMenuOffsetX,       y: ModMenuOffsetY,       c: col.ModMenu,
                                 x2: ModJoinOffsetX,      y2: ModJoinOffsetY,      c2: col.ModJoin },
    { name: "MainMenu",          x: MainMenuJoinOffsetX,  y: MainMenuJoinOffsetY,  c: col.MainMenu },
    { name: "MiddleMenu",        x: MiddleMenuOffsetX,    y: MiddleMenuOffsetY,    c: col.MiddleMenu }
]

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; DETECT ARK -

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

if (WinExist("ArkAscended")) {
    global arkwindow := "ArkAscended"
    arkRunning := true
} else {
    TrayTip("Run Ark before using this Script!","GG AIO",0x1)
    HideTrayTipTimer(3000)
    ExitApp
}

TrayTip("AIO is running","GG AIO",0x1)
HideTrayTipTimer(5000)

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; BUILD GUI -

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

MainGui := Gui("+AlwaysOnTop")
MainGui.OnEvent("Close", (*) => ExitApp())
MainGui.Title := "GG AIO"
MainGui.BackColor := "000000"

; ── Dark Theme: Owner-drawn buttons ──
global _darkBtns := Map()

DarkBtn(gui, options, text, fg := 0x4444FF, bg := 0x1A1A1A, fontSize := -12, bold := true) {
    btn := gui.Add("Button", options, text)
    DllCall("uxtheme\SetWindowTheme", "Ptr", btn.Hwnd, "Str", "", "Str", "")
    style := DllCall("GetWindowLong", "Ptr", btn.Hwnd, "Int", -16, "Int")
    DllCall("SetWindowLong", "Ptr", btn.Hwnd, "Int", -16, "Int", (style & ~0xF) | 0xB)
    _darkBtns[btn.Hwnd] := {text: text, fg: fg, bg: bg, fontSize: fontSize, bold: bold}
    return btn
}

DarkBtnText(btn, newText) {
    global _darkBtns
    if _darkBtns.Has(btn.Hwnd)
        _darkBtns[btn.Hwnd].text := newText
    btn.Text := newText
    DllCall("InvalidateRect", "Ptr", btn.Hwnd, "Ptr", 0, "Int", 1)
}

global _RED_BGR  := 0x4444FF    ; #FF4444
global _GRAY_BGR := 0xDDDDDD    ; #DDDDDD
global _DK_BG    := 0x1A1A1A    ; #1A1A1A

ModeSelectTab := MainGui.Add("Tab2","x-3 y0 w460 h440 Background000000",["JoinSim","Magic F","AutoLvL","Popcorn","Sheep","Craft","Macro","Misc"])
ModeSelectTab.SetFont("s9 cFFFFFF Bold", "Segoe UI")
ModeSelectTab.OnEvent("Change", OnTabChange)

global _dtTabHwnd := ModeSelectTab.Hwnd
_dtTabStyle := DllCall("GetWindowLong", "Ptr", _dtTabHwnd, "Int", -16, "Int")
DllCall("SetWindowLong", "Ptr", _dtTabHwnd, "Int", -16, "Int", _dtTabStyle | 0x2000)
DllCall("uxtheme\SetWindowTheme", "Ptr", _dtTabHwnd, "Str", "", "Str", "")

OnMessage(0x002B, _GGDrawItem)

_GGDrawItem(wParam, lParam, msg, hwnd) {
    global _dtTabHwnd, _darkBtns
    ctlType := NumGet(lParam, 0, "UInt")
    pSz := A_PtrSize
    hwndOff := (pSz = 8) ? 24 : 20

    if (ctlType = 4) {
        itemHwnd  := NumGet(lParam, hwndOff, "Ptr")
        if !_darkBtns.Has(itemHwnd)
            return
        info := _darkBtns[itemHwnd]
        itemState := NumGet(lParam, 16, "UInt")
        hDC       := NumGet(lParam, hwndOff + pSz, "Ptr")
        rcOff     := hwndOff + pSz * 2
        rcL := NumGet(lParam, rcOff, "Int"), rcT := NumGet(lParam, rcOff + 4, "Int")
        rcR := NumGet(lParam, rcOff + 8, "Int"), rcB := NumGet(lParam, rcOff + 12, "Int")
        isPressed := (itemState & 0x0001)
        bg := isPressed ? 0x333333 : info.bg
        hBr := DllCall("CreateSolidBrush", "UInt", bg, "Ptr")
        rc := Buffer(16, 0)
        NumPut("Int", rcL, rc, 0), NumPut("Int", rcT, rc, 4)
        NumPut("Int", rcR, rc, 8), NumPut("Int", rcB, rc, 12)
        DllCall("FillRect", "Ptr", hDC, "Ptr", rc, "Ptr", hBr)
        DllCall("DeleteObject", "Ptr", hBr)
        hPen := DllCall("CreatePen", "Int", 0, "Int", 1, "UInt", 0x444444, "Ptr")
        hOldPen := DllCall("SelectObject", "Ptr", hDC, "Ptr", hPen, "Ptr")
        hNullBr := DllCall("GetStockObject", "Int", 5, "Ptr")
        hOldBr := DllCall("SelectObject", "Ptr", hDC, "Ptr", hNullBr, "Ptr")
        DllCall("Rectangle", "Ptr", hDC, "Int", rcL, "Int", rcT, "Int", rcR, "Int", rcB)
        DllCall("SelectObject", "Ptr", hDC, "Ptr", hOldPen)
        DllCall("SelectObject", "Ptr", hDC, "Ptr", hOldBr)
        DllCall("DeleteObject", "Ptr", hPen)
        DllCall("SetBkMode", "Ptr", hDC, "Int", 1)
        DllCall("SetTextColor", "Ptr", hDC, "UInt", info.fg)
        weight := info.bold ? 700 : 400
        hFont := DllCall("CreateFont", "Int", info.fontSize, "Int", 0, "Int", 0, "Int", 0, "Int", weight, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 1, "UInt", 0, "UInt", 0, "UInt", 5, "UInt", 0, "Str", "Segoe UI", "Ptr")
        hOldFont := DllCall("SelectObject", "Ptr", hDC, "Ptr", hFont, "Ptr")
        rcDraw := Buffer(16, 0)
        ox := isPressed ? 1 : 0, oy := isPressed ? 1 : 0
        NumPut("Int", rcL + ox, rcDraw, 0), NumPut("Int", rcT + oy, rcDraw, 4)
        NumPut("Int", rcR + ox, rcDraw, 8), NumPut("Int", rcB + oy, rcDraw, 12)
        DllCall("DrawTextW", "Ptr", hDC, "Str", info.text, "Int", -1, "Ptr", rcDraw, "UInt", 0x25)
        DllCall("SelectObject", "Ptr", hDC, "Ptr", hOldFont)
        DllCall("DeleteObject", "Ptr", hFont)
        return true
    }

    if (ctlType = 101) {
        itemHwnd := NumGet(lParam, hwndOff, "Ptr")
        if (itemHwnd != _dtTabHwnd)
            return
        itemID    := NumGet(lParam, 8, "UInt")
        itemState := NumGet(lParam, 16, "UInt")
        hDC       := NumGet(lParam, hwndOff + pSz, "Ptr")
        rcOff     := hwndOff + pSz * 2
        rcL := NumGet(lParam, rcOff, "Int"), rcT := NumGet(lParam, rcOff + 4, "Int")
        rcR := NumGet(lParam, rcOff + 8, "Int"), rcB := NumGet(lParam, rcOff + 12, "Int")
        isSelected := (itemState & 0x0001)
        if (isSelected) {
            bgBGR := 0x222222, fgBGR := 0x4444FF, bdBGR := 0x4444FF
        } else {
            bgBGR := 0x000000, fgBGR := 0x20207A, bdBGR := 0x20207A
        }
        hBr := DllCall("CreateSolidBrush", "UInt", bgBGR, "Ptr")
        rc := Buffer(16, 0)
        NumPut("Int", rcL, rc, 0), NumPut("Int", rcT, rc, 4)
        NumPut("Int", rcR, rc, 8), NumPut("Int", rcB, rc, 12)
        DllCall("FillRect", "Ptr", hDC, "Ptr", rc, "Ptr", hBr)
        DllCall("DeleteObject", "Ptr", hBr)
        hPen := DllCall("CreatePen", "Int", 0, "Int", 1, "UInt", bdBGR, "Ptr")
        hOldPen := DllCall("SelectObject", "Ptr", hDC, "Ptr", hPen, "Ptr")
        hNullBr := DllCall("GetStockObject", "Int", 5, "Ptr")
        hOldBr := DllCall("SelectObject", "Ptr", hDC, "Ptr", hNullBr, "Ptr")
        DllCall("Rectangle", "Ptr", hDC, "Int", rcL, "Int", rcT, "Int", rcR, "Int", rcB)
        DllCall("SelectObject", "Ptr", hDC, "Ptr", hOldPen)
        DllCall("SelectObject", "Ptr", hDC, "Ptr", hOldBr)
        DllCall("DeleteObject", "Ptr", hPen)
        txtBuf := Buffer(256, 0)
        tcItem := Buffer(64, 0)
        NumPut("UInt", 0x0001, tcItem, 0)
        txtOff := (pSz = 8) ? 16 : 12
        NumPut("Ptr", txtBuf.Ptr, tcItem, txtOff)
        NumPut("Int", 128, tcItem, txtOff + pSz)
        SendMessage(0x133C, itemID, tcItem.Ptr, _dtTabHwnd)
        tabText := StrGet(txtBuf.Ptr, "UTF-16")
        DllCall("SetBkMode", "Ptr", hDC, "Int", 1)
        DllCall("SetTextColor", "Ptr", hDC, "UInt", fgBGR)
        hFont := DllCall("CreateFont", "Int", -12, "Int", 0, "Int", 0, "Int", 0, "Int", 700, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 1, "UInt", 0, "UInt", 0, "UInt", 5, "UInt", 0, "Str", "Segoe UI", "Ptr")
        hOldFont := DllCall("SelectObject", "Ptr", hDC, "Ptr", hFont, "Ptr")
        rcDraw := Buffer(16, 0)
        NumPut("Int", rcL, rcDraw, 0), NumPut("Int", rcT, rcDraw, 4)
        NumPut("Int", rcR, rcDraw, 8), NumPut("Int", rcB, rcDraw, 12)
        DllCall("DrawTextW", "Ptr", hDC, "Str", tabText, "Int", -1, "Ptr", rcDraw, "UInt", 0x25)
        DllCall("SelectObject", "Ptr", hDC, "Ptr", hOldFont)
        DllCall("DeleteObject", "Ptr", hFont)
        return true
    }
}

ModeSelectTab.UseTab()

ResText := MainGui.Add("Text","x10 y416 w140","Resolution: " ScreenWidth "x" ScreenHeight)
ResText.SetFont("s8 c888888","Segoe UI")
MainGui.Add("Text","x140 y416 w100 Center","Ctrl+Tab = tabs").SetFont("s8 c888888 Italic","Segoe UI")
MainGui.Add("Text","x240 y416 w80 Center","F4 = Exit").SetFont("s8 c888888 Italic","Segoe UI")
global ApplicationSelect := MainGui.Add("Text","vApplicationDDL x320 y416 w120 Right","")
ApplicationSelect.Text := arkwindow
ApplicationSelect.SetFont("s8 c888888","Segoe UI")

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ModeSelectTab.UseTab(1)

InfoText := MainGui.AddText("x40 y28 w280 h44 center","`nRUN AT STANDARD GAMMA`nSTART ON MAIN MENU OR SERVER LIST")
InfoText.SetFont("s8 bold cFF4444","Segoe UI")

MainGui.Add("Text","x25 y76 w65 h23 +0x200","Server:").SetFont("s9 cDDDDDD","Segoe UI")
global ServerNumberEdit := MainGui.Add("ComboBox","x90 y76 w180 h21 r8 +Limit4", [])
ServerNumberEdit.SetFont("s9 c000000","Segoe UI")
ServerNumberEdit.OnEvent("Change", SvrComboChanged)
svrAddBtn := DarkBtn(MainGui, "x274 y76 w22 h21", "+", _RED_BGR, _DK_BG, -11, true)
svrAddBtn.OnEvent("Click", SvrAddCurrent)
svrDelBtn := DarkBtn(MainGui, "x298 y76 w22 h21", "-", _RED_BGR, _DK_BG, -11, true)
svrDelBtn.OnEvent("Click", SvrRemoveSelected)
svrNoteBtn := DarkBtn(MainGui, "x322 y76 w30 h21", "Note", _RED_BGR, _DK_BG, -10, false)
svrNoteBtn.OnEvent("Click", SvrEditNote)

MainGui.Add("Text","x25 y103 w140 h23 +0x200","Download Mod / Event").SetFont("s9 cDDDDDD","Segoe UI")
MainGui.SetFont("s9 cDDDDDD","Segoe UI")
ModsChk := MainGui.Add("CheckBox","x175 y104 w40 h20","")
ModsChk.OnEvent("Click", SimToggleMods)

MainGui.Add("Text","x25 y126 w123 h23 +0x200","Use Join Last").SetFont("s9 cDDDDDD","Segoe UI")
MainGui.SetFont("s9 cDDDDDD","Segoe UI")
UseLastChk := MainGui.Add("CheckBox","x175 y127 w40 h20","")
UseLastChk.OnEvent("Click", SimToggleUseLast)

MainGui.Add("Text","x25 y149 w123 h23 +0x200","Enable Tooltips").SetFont("s9 cDDDDDD","Segoe UI")
MainGui.SetFont("s9 cDDDDDD","Segoe UI")
ToolBoxChk := MainGui.Add("CheckBox","x175 y150 w40 h20 Checked","")
ToolBoxChk.OnEvent("Click", SimToggleTooltips)

MainGui.SetFont("s9 cDDDDDD","Segoe UI")
SimAChk := MainGui.Add("CheckBox","x30 y175 w55 h20 Checked","Sim A")
SimAChk.OnEvent("Click", SimSelectA)
SimBChk := MainGui.Add("CheckBox","x30 y195 w55 h20","Sim B")
SimBChk.OnEvent("Click", SimSelectB)

StartSimButton := DarkBtn(MainGui, "x130 y177 w90 h28", "Start", _RED_BGR, _DK_BG, -12, true)
StartSimButton.OnEvent("Click", AutoSimButtonToggle)

; ── Delta ──
DllCall("LoadLibrary", "Str", "gdiplus", "Ptr")
_dSI := Buffer(24, 0)
NumPut("UInt", 1, _dSI, 0)
DllCall("gdiplus\GdiplusStartup", "Ptr*", &_dToken := 0, "Ptr", _dSI, "Ptr", 0)
_dR := 85, _dSteps := 32, _dSlide := 0.068, _dOpacity := 1.0
_dA0 := 1.5707963268
_dBmpX := 275, _dBmpY := 105
_dBmpW := 175, _dBmpH := 145
_dCX := 350 - _dBmpX, _dCY := 160 - _dBmpY

DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", _dBmpW, "Int", _dBmpH, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", &_dBmp := 0)
DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", _dBmp, "Ptr*", &_dG := 0)
DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", _dG, "Int", 4)
DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0xFF000000, "Ptr*", &_dBgBr := 0)
DllCall("gdiplus\GdipFillRectangleI", "Ptr", _dG, "Ptr", _dBgBr, "Int", 0, "Int", 0, "Int", _dBmpW, "Int", _dBmpH)
DllCall("gdiplus\GdipDeleteBrush", "Ptr", _dBgBr)

_dP1x := _dCX + _dR * Cos(_dA0)
_dP1y := _dCY + _dR * Sin(_dA0)
_dP2x := _dCX + _dR * Cos(_dA0 + 2.0943951024)
_dP2y := _dCY + _dR * Sin(_dA0 + 2.0943951024)
_dP3x := _dCX + _dR * Cos(_dA0 + 4.1887902048)
_dP3y := _dCY + _dR * Sin(_dA0 + 4.1887902048)

Loop _dSteps {
    _i := A_Index - 1
    _f := _i / (_dSteps - 1)
    _a := Integer((_dOpacity * (1.0 - _f * 0.5)) * 255)
    _a := Max(3, Min(255, _a))
    _pw := Max(0.5, 2.0 - _f * 1.2)
    _dSegs := [[_dP1x,_dP1y,_dP2x,_dP2y],[_dP2x,_dP2y,_dP3x,_dP3y],[_dP3x,_dP3y,_dP1x,_dP1y]]
    for , _s in _dSegs {
        if (_f < 0.10)
            _c := 0x550808
        else if (_f < 0.20)
            _c := 0x771010
        else if (_f < 0.25)
            _c := 0x991818
        else if (_f < 0.35)
            _c := 0xBB2222
        else if (_f < 0.45)
            _c := 0xDD3030
        else if (_f < 0.55)
            _c := 0xFF4040
        else if (_f < 0.65)
            _c := 0xFF5555
        else if (_f < 0.75)
            _c := 0xFF7777
        else if (_f < 0.85)
            _c := 0xFFAAAA
        else
            _c := 0xFFBBBB
        _sc := (_a << 24) | _c
        DllCall("gdiplus\GdipCreatePen1", "UInt", _sc, "Float", _pw, "Int", 2, "Ptr*", &_dPen := 0)
        DllCall("gdiplus\GdipSetPenLineJoin", "Ptr", _dPen, "Int", 0)
        DllCall("gdiplus\GdipDrawLine", "Ptr", _dG, "Ptr", _dPen, "Float", _s[1], "Float", _s[2], "Float", _s[3], "Float", _s[4])
        DllCall("gdiplus\GdipDeletePen", "Ptr", _dPen)
    }
    _n1x := _dP1x + _dSlide * (_dP2x - _dP1x), _n1y := _dP1y + _dSlide * (_dP2y - _dP1y)
    _n2x := _dP2x + _dSlide * (_dP3x - _dP2x), _n2y := _dP2y + _dSlide * (_dP3y - _dP2y)
    _n3x := _dP3x + _dSlide * (_dP1x - _dP3x), _n3y := _dP3y + _dSlide * (_dP1y - _dP3y)
    _dP1x := _n1x, _dP1y := _n1y, _dP2x := _n2x, _dP2y := _n2y, _dP3x := _n3x, _dP3y := _n3y
}

DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", _dBmp, "Ptr*", &_dHBmp := 0, "UInt", 0xFF000000)
DllCall("gdiplus\GdipDeleteGraphics", "Ptr", _dG)
DllCall("gdiplus\GdipDisposeImage", "Ptr", _dBmp)
_dPath := A_Temp "\gg_delta_ee.bmp"
_dDC := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")
_dOldB := DllCall("SelectObject", "Ptr", _dDC, "Ptr", _dHBmp, "Ptr")
_dBIH := Buffer(40, 0)
NumPut("UInt", 40, _dBIH, 0)
NumPut("Int", _dBmpW, _dBIH, 4)
NumPut("Int", _dBmpH, _dBIH, 8)
NumPut("UShort", 1, _dBIH, 12)
NumPut("UShort", 32, _dBIH, 14)
_dDataSz := _dBmpW * _dBmpH * 4
_dPxBuf := Buffer(_dDataSz, 0)
DllCall("GetDIBits", "Ptr", _dDC, "Ptr", _dHBmp, "UInt", 0, "UInt", _dBmpH, "Ptr", _dPxBuf, "Ptr", _dBIH, "UInt", 0)
_dBFH := Buffer(14, 0)
NumPut("UShort", 0x4D42, _dBFH, 0)
NumPut("UInt", 14 + 40 + _dDataSz, _dBFH, 2)
NumPut("UInt", 14 + 40, _dBFH, 10)
_dFile := FileOpen(_dPath, "w")
_dFile.RawWrite(_dBFH, 14)
_dFile.RawWrite(_dBIH, 40)
_dFile.RawWrite(_dPxBuf, _dDataSz)
_dFile.Close()
DllCall("SelectObject", "Ptr", _dDC, "Ptr", _dOldB)
DllCall("DeleteDC", "Ptr", _dDC)
DllCall("DeleteObject", "Ptr", _dHBmp)
MainGui.Add("Picture", "x" _dBmpX " y" _dBmpY " w" _dBmpW " h" _dBmpH, _dPath)
try FileDelete(_dPath)
; ── end delta ──

SimStatusText := MainGui.Add("Text","x25 y210 w300 h18 center","")
SimStatusText.SetFont("s8 c00FF00","Segoe UI")

MainGui.Add("Text","x25 y226 w60 h23 +0x200","Ntfy Key:").SetFont("s9 cDDDDDD","Segoe UI")
ntfyedit  := MainGui.Add("Edit","x90 y226 w100 h20", ntfykey)
ntfyedit.SetFont("s9 c000000","Segoe UI")
saveNTFY  := DarkBtn(MainGui, "x195 y226 w42 h20", "Save", _RED_BGR, _DK_BG, -11, false)
saveNTFY.OnEvent("Click", (*) => (saveini(ntfyedit.Value), updatekey(ntfyedit.Value), ntfyedit.Value := ""))
testntfy  := DarkBtn(MainGui, "x241 y226 w42 h20", "Test", _RED_BGR, _DK_BG, -11, false)
testntfy.OnEvent("Click", (*) => ntfypush("low","Test Button"))
ntfyHelp  := DarkBtn(MainGui, "x287 y226 w22 h20", "?", _RED_BGR, _DK_BG, -11, true)
ntfyHelp.OnEvent("Click", ShowNtfyHelp)

MainGui.Add("Text","x25 y248 w280"," F1 — Show / Hide UI").SetFont("s9 c888888 Italic","Segoe UI")
MainGui.Add("Text","x25 y262 w110"," F2 — Overcap").SetFont("s9 c888888 Italic","Segoe UI")
global overcapDediEdit := MainGui.Add("Edit","x135 y260 w18 h16 +Number","3")
overcapDediEdit.SetFont("s7 c000000","Segoe UI")
overcapDediEdit.OnEvent("Change", OvercapDediEditChanged)
global overcapCountdown := MainGui.Add("Text","x157 y262 w170","")
overcapCountdown.SetFont("s8 c00FF00","Segoe UI")
MainGui.Add("Text","x25 y276 w300"," F3 — Quick Feed  (Raw → Berry → Off)").SetFont("s9 c888888 Italic","Segoe UI")
MainGui.Add("Text","x25 y290 w300"," F5 — Apply INI  (paste custom in Misc)").SetFont("s9 c888888 Italic","Segoe UI")
MainGui.Add("Text","x25 y304 w165"," F6 — Fill OB  (F to upload)").SetFont("s9 c888888 Italic","Segoe UI")
global obStatusText := MainGui.Add("Text","x190 y304 w250","")
obStatusText.SetFont("s8 c00FF00","Segoe UI")
MainGui.Add("Text","x25 y318 w165"," F7 — Empty OB  (F7 at trans)").SetFont("s9 c888888 Italic","Segoe UI")
global obDownText := MainGui.Add("Text","x190 y318 w55","")
obDownText.SetFont("s8 c00FF00","Segoe UI")
MainGui.Add("Text","x25 y332 w185"," F8 — BG Mammoth Drums").SetFont("s9 c888888 Italic","Segoe UI")
MainGui.Add("Text","x25 y346 w185"," F9 — BG Autoclick").SetFont("s9 c888888 Italic","Segoe UI")
MainGui.Add("Text","x25 y360 w160"," F10 — Quick Popcorn").SetFont("s9 c888888 Italic","Segoe UI")
global pcF10StatusTxt := MainGui.Add("Text","x150 y360 w60","")
pcF10StatusTxt.SetFont("s8 c00FF00","Segoe UI")
global pcF10SpeedTxt := MainGui.Add("Text","x5 y0 w0 h0","")
MainGui.Add("Text","x25 y374 w160"," F12 — Grab My Kit").SetFont("s9 c888888 Italic","Segoe UI")
global gmkStatusTxt := MainGui.Add("Text","x150 y374 w60","")
gmkStatusTxt.SetFont("s8 c00FF00","Segoe UI")

; GG foreground layer — Delta + gradient Relief (rendered as bitmap)
; ── GDI+ startup for GG art ──
DllCall("LoadLibrary", "Str", "gdiplus", "Ptr")
_ggSI := Buffer(24, 0)
NumPut("UInt", 1, _ggSI, 0)
DllCall("gdiplus\GdiplusStartup", "Ptr*", &_ggToken := 0, "Ptr", _ggSI, "Ptr", 0)

_ggBmpX := 240, _ggBmpY := 268, _ggBmpW := 210, _ggBmpH := 140

DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", _ggBmpW, "Int", _ggBmpH, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", &_ggBmp := 0)
DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", _ggBmp, "Ptr*", &_ggG := 0)
DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", _ggG, "Int", 4)
DllCall("gdiplus\GdipSetTextRenderingHint", "Ptr", _ggG, "Int", 5)

DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0xFF000000, "Ptr*", &_ggBr := 0)
DllCall("gdiplus\GdipFillRectangleI", "Ptr", _ggG, "Ptr", _ggBr, "Int", 0, "Int", 0, "Int", _ggBmpW, "Int", _ggBmpH)
DllCall("gdiplus\GdipDeleteBrush", "Ptr", _ggBr)

; ── PART 2: GG Relief ──
DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", "Consolas", "Ptr", 0, "Ptr*", &_ggFamily := 0)
DllCall("gdiplus\GdipCreateStringFormat", "Int", 0, "Int", 0, "Ptr*", &_ggFmt := 0)
DllCall("gdiplus\GdipSetStringFormatAlign", "Ptr", _ggFmt, "Int", 0)
_ggFS := 5.5

_ggLines := [
    ["_____/\\\\\\\\\\\\_____/\\\\\\\\\\\\_",                        248, 330, 0xFFFFAAAA],
    [" ___/\\\//////////____/\\\//////////__",                         248, 338, 0xFFFF7777],
    ["  __/\\\______________/\\\_____________",                        248, 346, 0xFFFF5555],
    ["   _\/\\\____/\\\\\\\_\/\\\____/\\\\\\\_",                      248, 354, 0xFFFF4040],
    ["    _\/\\\___\/////\\\_\/\\\___\/////\\\_",                     248, 362, 0xFFDD3030],
    ["     _\/\\\_______\/\\\_\/\\\_______\/\\\_",                    248, 370, 0xFFBB2222],
    ["      _\/\\\_______\/\\\_\/\\\_______\/\\\_",                   248, 378, 0xFF991818],
    ["       _\//\\\\\\\\\\\\/__\//\\\\\\\\\\\\/__",                 248, 386, 0xFF771010],
    ["        __\////////////_____\////////////____",                 248, 394, 0xFF550808]
]
_ggPipes := [
    [245, 338, 0xFFFF7777],
    [245, 346, 0xFFFF5555], [249, 346, 0xFFFF5555],
    [245, 354, 0xFFFF4040], [249, 354, 0xFFFF4040], [253, 354, 0xFFFF4040],
    [245, 362, 0xFFDD3030], [249, 362, 0xFFDD3030], [253, 362, 0xFFDD3030], [257, 362, 0xFFDD3030],
    [245, 370, 0xFFBB2222], [249, 370, 0xFFBB2222], [253, 370, 0xFFBB2222], [257, 370, 0xFFBB2222], [261, 370, 0xFFBB2222],
    [245, 378, 0xFF991818], [249, 378, 0xFF991818], [253, 378, 0xFF991818], [257, 378, 0xFF991818], [261, 378, 0xFF991818], [265, 378, 0xFF991818],
    [245, 386, 0xFF771010], [249, 386, 0xFF771010], [253, 386, 0xFF771010], [257, 386, 0xFF771010], [261, 386, 0xFF771010], [265, 386, 0xFF771010], [269, 386, 0xFF771010],
    [245, 394, 0xFF550808], [249, 394, 0xFF550808], [253, 394, 0xFF550808], [257, 394, 0xFF550808], [261, 394, 0xFF550808], [265, 394, 0xFF550808], [269, 394, 0xFF550808], [273, 394, 0xFF550808]
]
for , _ln in _ggLines {
    DllCall("gdiplus\GdipCreateFont", "Ptr", _ggFamily, "Float", _ggFS, "Int", 1, "Int", 3, "Ptr*", &_ggFont := 0)
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", _ln[4], "Ptr*", &_ggTBr := 0)
    _rc := Buffer(16, 0)
    NumPut("Float", _ln[2] - _ggBmpX, _rc, 0)
    NumPut("Float", _ln[3] - _ggBmpY, _rc, 4)
    NumPut("Float", 300.0, _rc, 8)
    NumPut("Float", 12.0, _rc, 12)
    DllCall("gdiplus\GdipDrawString", "Ptr", _ggG, "WStr", _ln[1], "Int", -1, "Ptr", _ggFont, "Ptr", _rc, "Ptr", _ggFmt, "Ptr", _ggTBr)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", _ggTBr)
    DllCall("gdiplus\GdipDeleteFont", "Ptr", _ggFont)
}
for , _pp in _ggPipes {
    DllCall("gdiplus\GdipCreateFont", "Ptr", _ggFamily, "Float", _ggFS, "Int", 1, "Int", 3, "Ptr*", &_ggFont := 0)
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", _pp[3], "Ptr*", &_ggPBr := 0)
    _rc := Buffer(16, 0)
    NumPut("Float", _pp[1] - _ggBmpX, _rc, 0)
    NumPut("Float", _pp[2] - _ggBmpY, _rc, 4)
    NumPut("Float", 8.0, _rc, 8)
    NumPut("Float", 12.0, _rc, 12)
    DllCall("gdiplus\GdipDrawString", "Ptr", _ggG, "WStr", "|", "Int", -1, "Ptr", _ggFont, "Ptr", _rc, "Ptr", _ggFmt, "Ptr", _ggPBr)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", _ggPBr)
    DllCall("gdiplus\GdipDeleteFont", "Ptr", _ggFont)
}
DllCall("gdiplus\GdipDeleteFontFamily", "Ptr", _ggFamily)
DllCall("gdiplus\GdipDeleteStringFormat", "Ptr", _ggFmt)

; ── Save and add as Picture control ──
DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", _ggBmp, "Ptr*", &_ggHBmp := 0, "UInt", 0xFF000000)
DllCall("gdiplus\GdipDeleteGraphics", "Ptr", _ggG)
DllCall("gdiplus\GdipDisposeImage", "Ptr", _ggBmp)

_ggPath := A_Temp "\gg_delta_bg.bmp"
_ggDC := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")
_ggOld := DllCall("SelectObject", "Ptr", _ggDC, "Ptr", _ggHBmp, "Ptr")
_ggBIH := Buffer(40, 0)
NumPut("UInt", 40, _ggBIH, 0)
NumPut("Int", _ggBmpW, _ggBIH, 4)
NumPut("Int", _ggBmpH, _ggBIH, 8)
NumPut("UShort", 1, _ggBIH, 12)
NumPut("UShort", 32, _ggBIH, 14)
_ggDataSz := _ggBmpW * _ggBmpH * 4
_ggPx := Buffer(_ggDataSz, 0)
DllCall("GetDIBits", "Ptr", _ggDC, "Ptr", _ggHBmp, "UInt", 0, "UInt", _ggBmpH, "Ptr", _ggPx, "Ptr", _ggBIH, "UInt", 0)
_ggBFH := Buffer(14, 0)
NumPut("UShort", 0x4D42, _ggBFH, 0)
NumPut("UInt", 14 + 40 + _ggDataSz, _ggBFH, 2)
NumPut("UInt", 14 + 40, _ggBFH, 10)
_ggF := FileOpen(_ggPath, "w")
_ggF.RawWrite(_ggBFH, 14)
_ggF.RawWrite(_ggBIH, 40)
_ggF.RawWrite(_ggPx, _ggDataSz)
_ggF.Close()
DllCall("SelectObject", "Ptr", _ggDC, "Ptr", _ggOld)
DllCall("DeleteDC", "Ptr", _ggDC)
DllCall("DeleteObject", "Ptr", _ggHBmp)

MainGui.Add("Picture", "x" _ggBmpX " y" _ggBmpY " w" _ggBmpW " h" _ggBmpH, _ggPath)
try FileDelete(_ggPath)
MainGui.SetFont("s9 cDDDDDD", "Segoe UI")



global AutoSimCheck := false
global taskbarWasAutoHide := false
global taskbarChanged := false
PcLog("=== Script started ===")

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ModeSelectTab.UseTab(2)

MainGui.SetFont("s10 bold cFF4444","Segoe UI")
magicGiveText := MainGui.Add("Text","x190 y25 w110 h20 +0x200","Give:")

MainGui.SetFont("s8 Bold cFF4444","Segoe UI")
mfHelpBtn := DarkBtn(MainGui, "x385 y32 w28 h20", "?", _RED_BGR, _DK_BG, -11, true)
mfHelpBtn.OnEvent("Click", MagicFShowHelp)

MainGui.SetFont("s9 cDDDDDD","Segoe UI")
BeerCheckboxGive    := MainGui.Add("CheckBox","x75  y44 w65 h20","Beer")
BerryCheckbox       := MainGui.Add("CheckBox","x150 y44 w65 h20","Berry")
CharcCheckboxGive   := MainGui.Add("CheckBox","x230 y44 w65 h20","Charc")
CookedCheckboxGive  := MainGui.Add("CheckBox","x310 y44 w70 h20","Cooked")
CrystalCheckboxGive := MainGui.Add("CheckBox","x75  y62 w65 h20","Crystal")
DustCheckboxGive    := MainGui.Add("CheckBox","x150 y62 w65 h20","Dust")
FertCheckboxGive    := MainGui.Add("CheckBox","x230 y62 w65 h20","Fert")
FiberCheckboxGive   := MainGui.Add("CheckBox","x310 y62 w65 h20","Fiber")
FlintCheckboxGive   := MainGui.Add("CheckBox","x75  y80 w65 h20","Flint")
HideCheckboxGive    := MainGui.Add("CheckBox","x150 y80 w65 h20","Hide")
HoneyCheckboxGive   := MainGui.Add("CheckBox","x230 y80 w65 h20","Honey")
MetalCheckboxGive   := MainGui.Add("CheckBox","x310 y80 w65 h20","Metal")
NarcCheckboxGive    := MainGui.Add("CheckBox","x75  y98 w72 h20","Narcotic")
OilCheckboxGive     := MainGui.Add("CheckBox","x150 y98 w65 h20","Oil")
PasteCheckboxGive   := MainGui.Add("CheckBox","x230 y98 w65 h20","Paste")
PearlCheckboxGive   := MainGui.Add("CheckBox","x310 y98 w65 h20","Pearl")
PolyCheckboxGive    := MainGui.Add("CheckBox","x75  y116 w65 h20","Poly")
MeatCheckbox        := MainGui.Add("CheckBox","x150 y116 w65 h20","Raw")
SpoiledCheckboxGive := MainGui.Add("CheckBox","x230 y116 w72 h20","Spoiled")
StimCheckboxGive    := MainGui.Add("CheckBox","x310 y116 w65 h20","Stim")
StoneCheckboxGive   := MainGui.Add("CheckBox","x75  y134 w65 h20","Stone")
SulfurCheckboxGive  := MainGui.Add("CheckBox","x150 y134 w65 h20","Sulfur")
ThatchCheckboxGive  := MainGui.Add("CheckBox","x230 y134 w65 h20","Thatch")
WoodCheckboxGive    := MainGui.Add("CheckBox","x310 y134 w65 h20","Wood")
CustomCheckBoxGive  := MainGui.Add("Checkbox","x75  y158 w70 h20","Custom:")
MainGui.SetFont("s9 c000000","Segoe UI")
CustomEditGive      := MainGui.Add("ComboBox","x150 y156 w185 h21 r8",[])
mfGAddBtn := DarkBtn(MainGui, "x337 y156 w13 h21", "+", _RED_BGR, _DK_BG, -9, true)
mfGAddBtn.OnEvent("Click", MfGiveAdd)
mfGDelBtn := DarkBtn(MainGui, "x352 y156 w13 h21", "-", _RED_BGR, _DK_BG, -9, true)
mfGDelBtn.OnEvent("Click", MfGiveRemove)

MainGui.SetFont("s10 bold cFF4444","Segoe UI")
magicTakeText := MainGui.Add("Text","x190 y180 w110 h20 +0x200","Take:")

MainGui.SetFont("s9 cDDDDDD","Segoe UI")
BeerCheckboxTake        := MainGui.Add("Checkbox","x75  y198 w65 h20","Beer")
BerryCheckboxTake       := MainGui.Add("CheckBox","x150 y198 w65 h20","Berry")
CharcCheckboxTake       := MainGui.Add("CheckBox","x230 y198 w65 h20","Charc")
CookedCheckboxTake      := MainGui.Add("Checkbox","x310 y198 w70 h20","Cooked")
CrystalCheckboxTake     := MainGui.Add("CheckBox","x75  y216 w65 h20","Crystal")
DustCheckboxTake        := MainGui.Add("CheckBox","x150 y216 w65 h20","Dust")
FertCheckboxTake        := MainGui.Add("CheckBox","x230 y216 w65 h20","Fert")
FiberCheckboxTake       := MainGui.Add("CheckBox","x310 y216 w65 h20","Fiber")
FlintCheckboxTake       := MainGui.Add("CheckBox","x75  y234 w65 h20","Flint")
HideCheckboxTake        := MainGui.Add("CheckBox","x150 y234 w65 h20","Hide")
HoneyCheckBoxTake       := MainGui.Add("CheckBox","x230 y234 w65 h20","Honey")
MetalCheckboxTake       := MainGui.Add("CheckBox","x310 y234 w65 h20","Metal")
NarcCheckboxTake        := MainGui.Add("CheckBox","x75  y252 w72 h20","Narcotic")
OilCheckboxTake         := MainGui.Add("Checkbox","x150 y252 w65 h20","Oil")
PasteCheckboxTake       := MainGui.Add("CheckBox","x230 y252 w65 h20","Paste")
PearlCheckboxTake       := MainGui.Add("Checkbox","x310 y252 w65 h20","Pearl")
PolycheckboxTake        := MainGui.Add("CheckBox","x75  y270 w65 h20","Poly")
MeatCheckboxTake        := MainGui.Add("CheckBox","x150 y270 w65 h20","Raw")
SpoiledMeatCheckboxTake := MainGui.Add("CheckBox","x230 y270 w72 h20","Spoiled")
StimCheckboxTake        := MainGui.Add("CheckBox","x310 y270 w65 h20","Stim")
StoneCheckboxTake       := MainGui.Add("CheckBox","x75  y288 w65 h20","Stone")
SulfurCheckboxTake      := MainGui.Add("CheckBox","x150 y288 w65 h20","Sulfur")
ThatchCheckboxTake      := MainGui.Add("CheckBox","x230 y288 w65 h20","Thatch")
WoodCheckboxTake        := MainGui.Add("CheckBox","x310 y288 w65 h20","Wood")
CustomCheckBoxTake      := MainGui.Add("Checkbox","x75  y312 w70 h20","Custom:")
MainGui.SetFont("s9 c000000","Segoe UI")
CustomEditTake          := MainGui.Add("ComboBox","x150 y310 w185 h21 r8",[])
mfTAddBtn := DarkBtn(MainGui, "x337 y310 w13 h21", "+", _RED_BGR, _DK_BG, -9, true)
mfTAddBtn.OnEvent("Click", MfTakeAdd)
mfTDelBtn := DarkBtn(MainGui, "x352 y310 w13 h21", "-", _RED_BGR, _DK_BG, -9, true)
mfTDelBtn.OnEvent("Click", MfTakeRemove)

MainGui.SetFont("s8 Bold cDDDDDD","Segoe UI")
mfRefillBtn := DarkBtn(MainGui, "x75 y338 w90 h28", "Take/Refill", _RED_BGR, _DK_BG, -11, true)
mfRefillBtn.OnEvent("Click", MagicFToggleRefill)

MainGui.SetFont("s9 Bold cFF4444","Segoe UI")
ButtonSTARTSTOP    := DarkBtn(MainGui, "x265 y338 w100 h28", "START", _RED_BGR, _DK_BG, -12, true)
ButtonSTARTSTOP.OnEvent("Click", RunMagicF)

MainGui.SetFont("s8 c888888 Italic","Segoe UI")
MainGui.Add("Text","x145 y370 w160 Center","Q = Cycle selected presets")
MainGui.Add("Text","x145 y386 w160 Center","Z = Swap Give ↔ Take")

MagicFToggleRefill(*) {
    global magicFRefillMode, mfRefillBtn, runMagicFScript
    global magicFRefillMode := !magicFRefillMode
    if (magicFRefillMode) {
        mfRefillBtn.Opt("Background0x445544")
        DarkBtnText(mfRefillBtn, "▶ Take/Refill")
    } else {
        mfRefillBtn.Opt("BackgroundDefault")
        DarkBtnText(mfRefillBtn, "Take/Refill")
        if (runMagicFScript) {
            global runMagicFScript := false
            global magicFPresetIdx := 1
            try Hotkey("$z", "Off")
            ToolTip()
        }
    }
}

MagicFShowHelp(*) {
    global mfHelpGui
    if (IsSet(mfHelpGui) && mfHelpGui != "") {
        try mfHelpGui.Destroy()
        global mfHelpGui := ""
    }
    mfHelpGui := Gui("+AlwaysOnTop +Owner", "Magic F Help")
    mfHelpGui.BackColor := "1A1A1A"
    mfHelpGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
    mfHelpGui.Add("Text", "x45 y15 w255", "Quick Guide")
    mfHelpGui.SetFont("s9 cDDDDDD", "Segoe UI")
    mfHelpGui.Add("Text", "x45 y38 w255",
        "Select Give OR Take presets (any amount)`n"
        . "  F at inventory = transfer current preset`n"
        . "  Q = cycle presets  |  Z = swap give↔take`n`n"
        . "Take/Refill:`n"
        . "  Press Take/Refill then select one preset from BOTH Give and Take`n"
        . "  F at inventory = take all, then give all`n"
        . "Custom: type filter text + check Custom`n"
        . "F1 = stop / show UI")
    mfHelpGui.SetFont("s9 cFFFFFF Bold", "Segoe UI")
    closeBtn := mfHelpGui.Add("Button", "x160 y+12 w110 h26", "Got it")
    closeBtn.OnEvent("Click", (*) => mfHelpGui.Destroy())
    mfHelpGui.OnEvent("Close", (*) => mfHelpGui.Destroy())
    mfHelpGui.Show("AutoSize")
}

; ── Give/Take mutual exclusivity ──────────────────────────────────────────────
MagicFClearTake(*) {
    if (magicFRefillMode)
        return
    for cb in [BeerCheckboxTake, BerryCheckboxTake, CharcCheckboxTake, CookedCheckboxTake,
               CrystalCheckboxTake, DustCheckboxTake, FertCheckboxTake, FiberCheckboxTake,
               FlintCheckboxTake, HideCheckboxTake, HoneyCheckBoxTake, MetalCheckboxTake,
               NarcCheckboxTake, OilCheckboxTake, PasteCheckboxTake, PearlCheckboxTake,
               PolycheckboxTake, MeatCheckboxTake, SpoiledMeatCheckboxTake, StimCheckboxTake,
               StoneCheckboxTake, SulfurCheckboxTake, ThatchCheckboxTake,
               WoodCheckboxTake, CustomCheckBoxTake]
        cb.Value := 0
    CustomEditTake.Text := ""
}
MagicFClearGive(*) {
    if (magicFRefillMode)
        return
    for cb in [BeerCheckboxGive, BerryCheckbox, CharcCheckboxGive, CookedCheckboxGive,
               CrystalCheckboxGive, DustCheckboxGive, FertCheckboxGive, FiberCheckboxGive,
               FlintCheckboxGive, HideCheckboxGive, HoneyCheckboxGive, MetalCheckboxGive,
               NarcCheckboxGive, OilCheckboxGive, PasteCheckboxGive, PearlCheckboxGive,
               PolyCheckboxGive, MeatCheckbox, SpoiledCheckboxGive, StimCheckboxGive,
               StoneCheckboxGive, SulfurCheckboxGive, ThatchCheckboxGive,
               WoodCheckboxGive, CustomCheckBoxGive]
        cb.Value := 0
    CustomEditGive.Text := ""
}
for cb in [BeerCheckboxGive, BerryCheckbox, CharcCheckboxGive, CookedCheckboxGive,
           CrystalCheckboxGive, DustCheckboxGive, FertCheckboxGive, FiberCheckboxGive,
           FlintCheckboxGive, HideCheckboxGive, HoneyCheckboxGive, MetalCheckboxGive,
           NarcCheckboxGive, OilCheckboxGive, PasteCheckboxGive, PearlCheckboxGive,
           PolyCheckboxGive, MeatCheckbox, SpoiledCheckboxGive, StimCheckboxGive,
           StoneCheckboxGive, SulfurCheckboxGive, ThatchCheckboxGive,
           WoodCheckboxGive, CustomCheckBoxGive]
    cb.OnEvent("Click", MagicFClearTake)
for cb in [BeerCheckboxTake, BerryCheckboxTake, CharcCheckboxTake, CookedCheckboxTake,
           CrystalCheckboxTake, DustCheckboxTake, FertCheckboxTake, FiberCheckboxTake,
           FlintCheckboxTake, HideCheckboxTake, HoneyCheckBoxTake, MetalCheckboxTake,
           NarcCheckboxTake, OilCheckboxTake, PasteCheckboxTake, PearlCheckboxTake,
           PolycheckboxTake, MeatCheckboxTake, SpoiledMeatCheckboxTake, StimCheckboxTake,
           StoneCheckboxTake, SulfurCheckboxTake, ThatchCheckboxTake,
           WoodCheckboxTake, CustomCheckBoxTake]
    cb.OnEvent("Click", MagicFClearGive)

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ModeSelectTab.UseTab(3)

AutoLvLText := MainGui.AddText("x85 y25 w270 h45 center border","`nChoose the points below then click START`n")
AutoLvLText.SetFont("s8 bold cFF4444","Segoe UI")

MainGui.SetFont("s9 bold cDDDDDD","Segoe UI")
MainGui.Add("Text","vHealthPointText x70 y90 w100 h25 +0x200","Health Points:")
MainGui.SetFont("s9 c000000","Segoe UI")
HealthPointEdit   := MainGui.AddEdit("vHealthPointEdit x155 y90 w60 +Number +Limit4")
HealthPointUpDown := MainGui.AddUpDown("vHealthUpDown Range0-85",0)

MainGui.SetFont("s9 bold cDDDDDD","Segoe UI")
MainGui.Add("Text","vStamPointText x70 y125 w100 h25 +0x200","Stam Points:")
MainGui.SetFont("s9 c000000","Segoe UI")
StamPointEdit   := MainGui.AddEdit("vStamPointEdit x155 y125 w60 +Number +Limit4")
StamPointUpDown := MainGui.AddUpDown("vStamUpDown Range0-85",0)

MainGui.SetFont("s9 bold cDDDDDD","Segoe UI")
MainGui.Add("Text","vFoodPointText x70 y160 w100 h25 +0x200","Food Points:")
MainGui.SetFont("s9 c000000","Segoe UI")
FoodPointEdit   := MainGui.AddEdit("vFoodPointEdit x155 y160 w60 +Number +Limit4")
FoodPointUpDown := MainGui.AddUpDown("vFoodUpDown Range0-85",0)

MainGui.SetFont("s9 bold cDDDDDD","Segoe UI")
MainGui.Add("Text","vWeightPointText x70 y195 w100 h25 +0x200","Weight Points:")
MainGui.SetFont("s9 c000000","Segoe UI")
WeightPointEdit   := MainGui.AddEdit("vWeightPointEdit x155 y195 w60 +Number +Limit4")
WeightPointUpDown := MainGui.AddUpDown("vWeightUpDown Range0-85",0)

MainGui.SetFont("s9 bold cDDDDDD","Segoe UI")
MainGui.Add("Text","vMeleePointText x70 y230 w100 h25 +0x200","Melee Points:")
MainGui.SetFont("s9 c000000","Segoe UI")
MeleePointEdit   := MainGui.AddEdit("vMeleePointEdit x155 y230 w60 +Number +Limit4")
MeleePointUpDown := MainGui.AddUpDown("vMeleeUpDown Range0-85",0)

MainGui.SetFont("s9 cDDDDDD","Segoe UI")
AutoSaddleCheckBox := MainGui.AddCheckbox("x45 y270","Auto Saddle")
NoOxyCheckBox      := MainGui.AddCheckbox("x45 y293","No Oxy")
global autoLvlCombineChk := MainGui.AddCheckbox("x250 y300 w100 h20","Combine")
autoLvlCombineChk.SetFont("s9 cDDDDDD","Segoe UI")
MainGui.SetFont("s9 Bold cFF4444","Segoe UI")
StartAutoLvlButton := DarkBtn(MainGui, "x160 y280 w80 h28", "START", _RED_BGR, _DK_BG, -12, true)
StartAutoLvlButton.OnEvent("Click", RunAutoLvl)
MainGui.SetFont("s9 cDDDDDD","Segoe UI")
global autoLvlCryoCheck := MainGui.AddCheckbox("x250 y284 w15 h20")
MainGui.Add("Text","x268 y284 w45 h20 +0x200","Cryo")

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


;─────────────────────────────────────────────────────────────────────────────
;─────────────────────────────────────────────────────────────────────────────
ModeSelectTab.UseTab(4)

MainGui.SetFont("s8 c555555", "Segoe UI")

; ── HELP BUTTON ──────────────────────────────────
pcHelp := DarkBtn(MainGui, "x370 y28 w32 h18", "?", _RED_BGR, _DK_BG, -10, true)
pcHelp.OnEvent("Click", PcShowHelp)

MainGui.SetFont("s9 cDDDDDD", "Segoe UI")
pcAllNoFilterInd := MainGui.Add("CheckBox", "x32 y50 w120 h20", "All (no filter)")
pcAllNoFilterInd.OnEvent("Click", (*) => PcToggle("AllNoFilter"))

MainGui.SetFont("s9 cDDDDDD", "Segoe UI")
pcPolyInd    := MainGui.Add("CheckBox", "x32  y72 w60 h20", "Poly")
pcPolyInd.OnEvent("Click",    (*) => PcToggle("Poly"))
pcMetalInd   := MainGui.Add("CheckBox", "x98  y72 w65 h20", "Metal")
pcMetalInd.OnEvent("Click",   (*) => PcToggle("Metal"))
pcCrystalInd := MainGui.Add("CheckBox", "x168 y72 w72 h20", "Crystal")
pcCrystalInd.OnEvent("Click", (*) => PcToggle("Crystal"))
pcRawInd     := MainGui.Add("CheckBox", "x246 y72 w55 h20", "Raw")
pcRawInd.OnEvent("Click",     (*) => PcToggle("Raw"))
pcCookedInd  := MainGui.Add("CheckBox", "x306 y72 w72 h20", "Cooked")
pcCookedInd.OnEvent("Click",  (*) => PcToggle("Cooked"))

MainGui.SetFont("s9 cDDDDDD", "Segoe UI")
pcCustomCard := MainGui.Add("Checkbox", "x32 y108 w72 h20", "Custom:")
pcCustomCard.OnEvent("Click", PcCustomCheckToggle)

MainGui.SetFont("s9 c000000", "Segoe UI")
pcCustomEdit := MainGui.Add("ComboBox", "x108 y106 w104 h21 r8", [])
pcCustomEdit.OnEvent("Change", PcCustomFilterChanged)
pcCFAddBtn := DarkBtn(MainGui, "x214 y102 w14 h13", "+", _RED_BGR, _DK_BG, -9, true)
pcCFAddBtn.OnEvent("Click", PcFilterAdd)
pcCFDelBtn := DarkBtn(MainGui, "x214 y116 w14 h13", "-", _RED_BGR, _DK_BG, -9, true)
pcCFDelBtn.OnEvent("Click", PcFilterRemove)

MainGui.SetFont("s8 cDDDDDD", "Segoe UI")
pcForgeXferInd := MainGui.Add("CheckBox", "x245 y102 w110 h18", "Transfer All")
pcForgeXferInd.OnEvent("Click", (*) => PcToggle("ForgeXfer"))
pcForgeSkipInd := MainGui.Add("CheckBox", "x245 y120 w120 h18", "Skip First Slot")
pcForgeSkipInd.OnEvent("Click", (*) => PcToggle("ForgeSkip"))

MainGui.SetFont("s8 c888888", "Segoe UI")
MainGui.Add("Text", "x32 y146 w44 h16", "Speed:")
pcSpeedTxt := MainGui.Add("Text", "x78 y146 w88 h16 cFF4444", "Fast [Z]")

MainGui.SetFont("s8 c888888", "Segoe UI")
MainGui.Add("Text", "x32 y166 w72 h16", "Drop Key:")
pcDropKeyTxt := MainGui.Add("Text", "x98 y166 w60 h16 cFF4444", pcDropKey)

MainGui.SetFont("s9 cDDDDDD", "Segoe UI")
pcCalibrateBtn := DarkBtn(MainGui, "x32 y188 w120 h28", "Set Keys", _RED_BGR, _DK_BG, -12, false)
pcCalibrateBtn.OnEvent("Click", (*) => PcShowSetKeysForm())

MainGui.SetFont("s8 cDDDDDD", "Segoe UI")
pcScanAreaBtn := DarkBtn(MainGui, "x280 y188 w80 h28", "Scan Area", _RED_BGR, _DK_BG, -11, true)
pcScanAreaBtn.OnEvent("Click", PcToggleScanResize)

MainGui.SetFont("s9 Bold cFF4444", "Segoe UI")
pcExecBtn := DarkBtn(MainGui, "x168 y188 w100 h28", "Start", _RED_BGR, _DK_BG, -12, true)
pcExecBtn.OnEvent("Click", (*) => PcExecuteBtn())

MainGui.SetFont("s8 cDDDDDD", "Segoe UI")
MainGui.Add("Text", "x32 y219 w354 h14 Center", "Z = Change drop speed  |  Q = Cycle selected presets")
MainGui.Add("Text", "x32 y233 w354 h14 Center", "Auto-stops when storage empty  |  F1 = Stop")
pcStatusTxt := MainGui.Add("Text", "x32 y249 w354 h14 Center cDDDDDD", "Select a mode then press F at an inventory")

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ModeSelectTab.UseTab(5)

SheepInfoText := MainGui.AddText("x80 y25 w270 h50 center border","`nSet keybinds — defaults are ready to use`nRes: " sx "x" sy)
SheepInfoText.SetFont("s8 bold cFF4444","Segoe UI")

sheepLabelX  := 22
sheepEditX   := 175
sheepBtnX    := 295
sheepRowY    := 95

MainGui.Add("Text","x" sheepLabelX " y" sheepRowY " w145 h24 +0x200","Start / Pause:").SetFont("s9 cDDDDDD","Segoe UI")
global sheepToggleInput := MainGui.Add("Edit","x" sheepEditX " y" (sheepRowY-2) " w100 h24 Center", sheepToggleKey)
sheepToggleInput.SetFont("s9 c000000","Segoe UI")
btnT := DarkBtn(MainGui, "x" sheepBtnX " y" (sheepRowY-2) " w60 h24", "Set", _RED_BGR, _DK_BG, -11, false)
btnT.OnEvent("Click", (*) => SheepDetectKey(sheepToggleInput))

sheepRowY += 30
MainGui.Add("Text","x" sheepLabelX " y" sheepRowY " w145 h24 +0x200","Overcap toggle:").SetFont("s9 cDDDDDD","Segoe UI")
global sheepOvercapInput := MainGui.Add("Edit","x" sheepEditX " y" (sheepRowY-2) " w100 h24 Center", sheepOvercapKey)
sheepOvercapInput.SetFont("s9 c000000","Segoe UI")
btnO := DarkBtn(MainGui, "x" sheepBtnX " y" (sheepRowY-2) " w60 h24", "Set", _RED_BGR, _DK_BG, -11, false)
btnO.OnEvent("Click", (*) => SheepDetectKey(sheepOvercapInput))

sheepRowY += 30
MainGui.Add("Text","x" sheepLabelX " y" sheepRowY " w145 h24 +0x200","Inventory key:").SetFont("s9 cDDDDDD","Segoe UI")
global sheepInventoryInput := MainGui.Add("Edit","x" sheepEditX " y" (sheepRowY-2) " w100 h24 Center", sheepInventoryKey)
sheepInventoryInput.SetFont("s9 c000000","Segoe UI")
btnI := DarkBtn(MainGui, "x" sheepBtnX " y" (sheepRowY-2) " w60 h24", "Set", _RED_BGR, _DK_BG, -11, false)
btnI.OnEvent("Click", (*) => SheepDetectKey(sheepInventoryInput))

sheepRowY += 30
MainGui.Add("Text","x" sheepLabelX " y" sheepRowY " w145 h24 +0x200","Auto LvL toggle:").SetFont("s9 cDDDDDD","Segoe UI")
global sheepAutoLvlInput := MainGui.Add("Edit","x" sheepEditX " y" (sheepRowY-2) " w100 h24 Center", sheepAutoLvlKey)
sheepAutoLvlInput.SetFont("s9 c000000","Segoe UI")
btnA := DarkBtn(MainGui, "x" sheepBtnX " y" (sheepRowY-2) " w60 h24", "Set", _RED_BGR, _DK_BG, -11, false)
btnA.OnEvent("Click", (*) => SheepDetectKey(sheepAutoLvlInput))

MainGui.Add("Text","x" sheepLabelX " y" (sheepRowY+30) " w340","Click 'Set' then press a key to bind").SetFont("s8 c888888 Italic","Segoe UI")
global sheepSaveBtn := DarkBtn(MainGui, "x100 y" (sheepRowY+50) " w220 h28", "Save Settings", _RED_BGR, _DK_BG, -12, true)
sheepSaveBtn.OnEvent("Click", SheepApplyKeys)

MainGui.Add("Text","x" sheepLabelX " y" (sheepRowY+86) " w340 Center","Stack sheep to harvest more than one at a time").SetFont("s8 cFF4444","Segoe UI")
MainGui.Add("Text","x" sheepLabelX " y" (sheepRowY+102) " w340 Center","Look at sheep, press Start/Pause key to begin...").SetFont("s8 c888888 Italic","Segoe UI")

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ModeSelectTab.UseTab(6)

; ── ? help button ─────────────────────────────────────────
acGridHelpBtn := DarkBtn(MainGui, "x357 y30 w32 h18", "?", _RED_BGR, _DK_BG, -11, true)
acGridHelpBtn.OnEvent("Click", AcShowGridHelp)

MainGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
MainGui.Add("Text", "x280 y39 w10 h56 +0x200", "|")

global acTallyBtn := DarkBtn(MainGui, "x293 y30 w52 h18", "Count", _RED_BGR, _DK_BG, -11, true)
acTallyBtn.OnEvent("Click", AcTallyToggle)
MainGui.SetFont("s7 c666666 Italic", "Segoe UI")
MainGui.Add("Text", "x283 y48 w100 h12 Center", "count items crafted")

MainGui.SetFont("s9 bold cFF4444","Segoe UI")
MainGui.Add("Text","x37 y30 w120 h18","Simple Craft")

MainGui.SetFont("s9 cDDDDDD","Segoe UI")
acSimpleSparkBtn := MainGui.Add("CheckBox","x37  y50 w60 h23","spark")
acSimpleGunBtn   := MainGui.Add("CheckBox","x105  y50 w50 h23","gp")
acSimpleElecBtn  := MainGui.Add("CheckBox","x163 y50 w90 h23","electronics")

acSimpleAdvBtn   := MainGui.Add("CheckBox","x37  y73 w50 h23","adv")
acSimplePolyBtn  := MainGui.Add("CheckBox","x95  y73 w60 h23","poly")

MainGui.SetFont("s7 c888888","Segoe UI")
MainGui.Add("Text","x293 y63 w55 h14","Extra clicks")
global acExtraClicksEdit := MainGui.Add("Edit","x307 y77 w25 h18 +Number Center", acExtraClicks)
acExtraClicksEdit.SetFont("s7 c000000","Segoe UI")
acExtraClicksEdit.OnEvent("Change", AcExtraClicksChanged)

AcExtraClicksChanged(*) {
    val := Trim(acExtraClicksEdit.Value)
    if (val = "" || !IsInteger(val))
        return
    global acExtraClicks := Max(0, Integer(val))
    try IniWrite(acExtraClicks, A_ScriptDir "\AIO_config.ini", "Craft", "ExtraClicks")
}

acSimpleSparkBtn.OnEvent("Click", (*) => AcToggleSimple(acSimpleSparkBtn, "rk"))
acSimpleGunBtn.OnEvent("Click",   (*) => AcToggleSimple(acSimpleGunBtn,   "np"))
acSimpleElecBtn.OnEvent("Click",  (*) => AcToggleSimple(acSimpleElecBtn,  "onic"))
acSimpleAdvBtn.OnEvent("Click",   (*) => AcToggleSimple(acSimpleAdvBtn,   "m dv"))
acSimplePolyBtn.OnEvent("Click",  (*) => AcToggleSimple(acSimplePolyBtn,  "poly"))

MainGui.SetFont("s9 cDDDDDD","Segoe UI")
global acSimpleCustomCB := MainGui.Add("CheckBox","x37 y97 w68 h23","Custom:")
MainGui.SetFont("s9 c000000","Segoe UI")
acSimpleFilterEdit := MainGui.Add("ComboBox","x105 y97 w74 h21 r8",[])
acSimpleFilterEdit.SetFont("s9 c000000","Segoe UI")
acSFAddBtn := DarkBtn(MainGui, "x181 y93 w14 h13", "+", _RED_BGR, _DK_BG, -9, true)
acSFAddBtn.OnEvent("Click", (*) => AcFilterAdd("simple"))
acSFDelBtn := DarkBtn(MainGui, "x181 y107 w14 h13", "-", _RED_BGR, _DK_BG, -9, true)
acSFDelBtn.OnEvent("Click", (*) => AcFilterRemove("simple"))
acSimpleStartBtn := DarkBtn(MainGui, "x201 y96 w100 h28", "START", _RED_BGR, _DK_BG, -12, true)
acSimpleStartBtn.OnEvent("Click", AcStartSimple)
MainGui.SetFont("s8 cDDDDDD","Segoe UI")
global acSimpleLoopBtn := MainGui.Add("CheckBox","x201 y73 w55 h23","Loop")
acSimpleLoopBtn.SetFont("s8 cDDDDDD","Segoe UI")

MainGui.Add("Text","x23 y128 w366 h1 +0x10")

MainGui.SetFont("s9 bold cFF4444","Segoe UI")
MainGui.Add("Text","x37 y133 w260 h18","Inventory Timed")

MainGui.SetFont("s9 cDDDDDD","Segoe UI")
acTimedElecBtn  := MainGui.Add("CheckBox","x37  y153 w120 h23","electronics  3:20")
acTimedAdvBtn   := MainGui.Add("CheckBox","x165 y153 w90  h23","adv  2:00")

acTimedPolyBtn  := MainGui.Add("CheckBox","x37  y175 w90  h23","poly  3:30")

acTimedElecBtn.OnEvent("Click",  (*) => AcToggleTimed(acTimedElecBtn, "onic", 200))
acTimedAdvBtn.OnEvent("Click",   (*) => AcToggleTimed(acTimedAdvBtn,  "m dv", 120))
acTimedPolyBtn.OnEvent("Click",  (*) => AcToggleTimed(acTimedPolyBtn, "poly", 210))

MainGui.SetFont("s9 cDDDDDD","Segoe UI")
global acTimedCustomCB := MainGui.Add("CheckBox","x37 y199 w68 h23","Custom:")
MainGui.SetFont("s8 c000000","Segoe UI")
acTimedFilterEdit := MainGui.Add("ComboBox","x105 y199 w74 h21 r8",[])
acTimedFilterEdit.SetFont("s8 c000000","Segoe UI")
acTFAddBtn := DarkBtn(MainGui, "x181 y195 w14 h13", "+", _RED_BGR, _DK_BG, -9, true)
acTFAddBtn.OnEvent("Click", (*) => AcFilterAdd("timed"))
acTFDelBtn := DarkBtn(MainGui, "x181 y209 w14 h13", "-", _RED_BGR, _DK_BG, -9, true)
acTFDelBtn.OnEvent("Click", (*) => AcFilterRemove("timed"))
MainGui.Add("Text","x199 y199 w52 h23 +0x200","Timer (s):")
acTimedSecsEdit := MainGui.Add("Edit","x253 y199 w52 h23","120")
acTimedSecsEdit.SetFont("s8 c000000","Segoe UI")
acTimedStartBtn := DarkBtn(MainGui, "x311 y198 w100 h28", "START", _RED_BGR, _DK_BG, -12, true)
acTimedStartBtn.OnEvent("Click", AcStartTimed)
MainGui.SetFont("s8 cDDDDDD","Segoe UI")
global acTimedLoopBtn := MainGui.Add("CheckBox","x311 y175 w55 h23","Loop")
acTimedLoopBtn.SetFont("s8 cDDDDDD","Segoe UI")

MainGui.Add("Text","x23 y232 w366 h1 +0x10")

MainGui.SetFont("s9 bold cFF4444","Segoe UI")
MainGui.Add("Text","x37 y237 w80 h18","Grid Walk")

MainGui.SetFont("s8 cDDDDDD","Segoe UI")
MainGui.Add("Text","x37 y257 w120 h18 +0x200","How many inventories:")
MainGui.Add("Text","x163 y257 w20 h18 +0x200","↑↓")
acColsEdit := MainGui.Add("Edit","x185 y257 w50 h18","1")
acColsEdit.SetFont("s8 c000000","Segoe UI")
MainGui.Add("Text","x241 y257 w20 h18 +0x200","←→")
acRowsEdit := MainGui.Add("Edit","x263 y257 w50 h18","11")
acRowsEdit.SetFont("s8 c000000","Segoe UI")

global acOcrResizeBtn := DarkBtn(MainGui, "x320 y257 w52 h18", "Resize", _RED_BGR, _DK_BG, -10, false)
acOcrResizeBtn.OnEvent("Click", AcOcrToggleResize)

global acOcrCopyBtn := DarkBtn(MainGui, "x374 y257 w30 h18", "Copy", _RED_BGR, _DK_BG, -10, false)
acOcrCopyBtn.OnEvent("Click", AcOcrCopyTotal)

MainGui.SetFont("s8 cDDDDDD","Segoe UI")
global acOcrEnableCB := MainGui.Add("CheckBox","x320 y278 w70 h18","Count")
acOcrEnableCB.Value := acOcrEnabled
acOcrEnableCB.OnEvent("Click", AcOcrToggleEnabled)

MainGui.Add("Text","x37 y277 w120 h18 +0x200","Walk delay (ms):")
MainGui.Add("Text","x163 y277 w20 h18 +0x200","↑↓")
acHWalkEdit := MainGui.Add("Edit","x185 y277 w50 h18","0")
acHWalkEdit.SetFont("s8 c000000","Segoe UI")
MainGui.Add("Text","x241 y277 w20 h18 +0x200","←→")
acVWalkEdit := MainGui.Add("Edit","x263 y277 w50 h18","850")
acVWalkEdit.SetFont("s8 c000000","Segoe UI")

try {
    _gc := IniRead(A_ScriptDir "\AIO_config.ini", "Grid", "Cols", "1")
    _gr := IniRead(A_ScriptDir "\AIO_config.ini", "Grid", "Rows", "11")
    _gh := IniRead(A_ScriptDir "\AIO_config.ini", "Grid", "HWalk", "0")
    _gv := IniRead(A_ScriptDir "\AIO_config.ini", "Grid", "VWalk", "850")
    acColsEdit.Value := _gc, acRowsEdit.Value := _gr
    acHWalkEdit.Value := _gh, acVWalkEdit.Value := _gv
}
try {
    _ec := IniRead(A_ScriptDir "\AIO_config.ini", "Craft", "ExtraClicks", "0")
    global acExtraClicks := Max(0, Integer(_ec))
    acExtraClicksEdit.Value := acExtraClicks
}
acColsEdit.OnEvent("Change", (*) => IniWrite(acColsEdit.Value, A_ScriptDir "\AIO_config.ini", "Grid", "Cols"))
acRowsEdit.OnEvent("Change", (*) => IniWrite(acRowsEdit.Value, A_ScriptDir "\AIO_config.ini", "Grid", "Rows"))
acHWalkEdit.OnEvent("Change", (*) => IniWrite(acHWalkEdit.Value, A_ScriptDir "\AIO_config.ini", "Grid", "HWalk"))
acVWalkEdit.OnEvent("Change", (*) => IniWrite(acVWalkEdit.Value, A_ScriptDir "\AIO_config.ini", "Grid", "VWalk"))

MainGui.SetFont("s9 cDDDDDD","Segoe UI")
acGridElecBtn  := MainGui.Add("CheckBox","x37  y298 w90 h23","electronics")
acGridAdvBtn   := MainGui.Add("CheckBox","x135 y298 w50 h23","adv")
acGridPolyBtn  := MainGui.Add("CheckBox","x193 y298 w55 h23","poly")

acGridSparkBtn := MainGui.Add("CheckBox","x37  y320 w60 h23","spark")
acGridGunBtn   := MainGui.Add("CheckBox","x105  y320 w50 h23","gp")

acGridElecBtn.OnEvent("Click",  (*) => AcToggleGrid(acGridElecBtn,  "onic"))
acGridAdvBtn.OnEvent("Click",   (*) => AcToggleGrid(acGridAdvBtn,   "m dv"))
acGridPolyBtn.OnEvent("Click",  (*) => AcToggleGrid(acGridPolyBtn,  "poly"))
acGridSparkBtn.OnEvent("Click", (*) => AcToggleGrid(acGridSparkBtn, "rk"))
acGridGunBtn.OnEvent("Click",   (*) => AcToggleGrid(acGridGunBtn,   "np"))

MainGui.SetFont("s9 cDDDDDD","Segoe UI")
global acGridCustomCB := MainGui.Add("CheckBox","x37 y344 w68 h23","Custom:")
MainGui.SetFont("s9 c000000","Segoe UI")
acGridFilterEdit := MainGui.Add("ComboBox","x105 y344 w74 h21 r8",[])
acGridFilterEdit.SetFont("s9 c000000","Segoe UI")
acGFAddBtn := DarkBtn(MainGui, "x181 y340 w14 h13", "+", _RED_BGR, _DK_BG, -9, true)
acGFAddBtn.OnEvent("Click", (*) => AcFilterAdd("grid"))
acGFDelBtn := DarkBtn(MainGui, "x181 y354 w14 h13", "-", _RED_BGR, _DK_BG, -9, true)
acGFDelBtn.OnEvent("Click", (*) => AcFilterRemove("grid"))

acGridStartBtn := DarkBtn(MainGui, "x201 y343 w100 h28", "START", _RED_BGR, _DK_BG, -12, true)
acGridStartBtn.OnEvent("Click", AcStartGrid)

MainGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
MainGui.Add("Text", "x306 y343 w10 h28 +0x200", "|")
MainGui.SetFont("s9 cDDDDDD", "Segoe UI")
global acTakeAllBtn := MainGui.Add("CheckBox", "x318 y348 w100 h18", "Take-All")
MainGui.SetFont("s7 c888888 Italic", "Segoe UI")
MainGui.Add("Text", "x320 y365 w80 h12", "(every mode)")

MainGui.Add("Text","x23 y378 w366 h14 Center","Food/Water (9-0) feeds char every 45 mins in Grid mode").SetFont("s7 c666666 Italic","Segoe UI")




;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ModeSelectTab.UseTab(8)

; --- QUICK HATCH ---
MainGui.SetFont("s9 cDDDDDD", "Segoe UI")
qhAllBtn    := MainGui.Add("CheckBox", "x22  y32 w130 h23", "Quick Hatch (All)")
qhAllBtn.OnEvent("Click", (*) => QhToggleMode(qhAllBtn, 1))
qhSingleBtn := MainGui.Add("CheckBox", "x160 y32 w140 h23", "Quick Hatch (Single)")
qhSingleBtn.OnEvent("Click", (*) => QhToggleMode(qhSingleBtn, 2))

MainGui.SetFont("s9 Bold cFF4444", "Segoe UI")
qhStartBtn  := DarkBtn(MainGui, "x308 y137 w70 h28", "START", _RED_BGR, _DK_BG, -12, true)
qhStartBtn.OnEvent("Click", QhStart)

MainGui.SetFont("s8 c888888 Italic", "Segoe UI")
global qhStatusTxt := MainGui.Add("Text", "x22 y62 w200 h14", "Select a mode then press START")

MainGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
MainGui.Add("Text", "x22 y90 w80", "Claim/Name")
MainGui.SetFont("s9 cDDDDDD", "Segoe UI")
global cnEnableBtn := MainGui.Add("CheckBox", "x105 y90 w15 h20")
cnEnableBtn.OnEvent("Click", (*) => (cnEnableBtn.Value ? nsEnableBtn.Value := 0 : 0))
global depoEmbryoBtn := MainGui.Add("CheckBox", "x135 y90 w110 h20", "Depo Embryo")
depoEmbryoBtn.SetFont("s8 cDDDDDD", "Segoe UI")

MainGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
MainGui.Add("Text", "x22 y114 w80", "Name/Spay")
MainGui.SetFont("s9 cDDDDDD", "Segoe UI")
global nsEnableBtn := MainGui.Add("CheckBox", "x105 y114 w15 h20")
nsEnableBtn.OnEvent("Click", (*) => (nsEnableBtn.Value ? cnEnableBtn.Value := 0 : 0))
global depoEggsBtn := MainGui.Add("CheckBox", "x135 y114 w100 h20", "Depo Eggs")
depoEggsBtn.SetFont("s8 cDDDDDD", "Segoe UI")

MainGui.SetFont("s9 cDDDDDD", "Segoe UI")
MainGui.Add("Text", "x22 y140 w55 h25 +0x200", "Name:").SetFont("s9 bold cDDDDDD", "Segoe UI")
ClaimAndNameEdit := MainGui.Add("ComboBox", "x78 y140 w128 h21 r8", [])
ClaimAndNameEdit.SetFont("s9 c000000", "Segoe UI")
cnAddBtn := DarkBtn(MainGui, "x208 y140 w16 h21", "+", _RED_BGR, _DK_BG, -11, true)
cnAddBtn.OnEvent("Click", CnAddName)
cnDelBtn := DarkBtn(MainGui, "x226 y140 w16 h21", "-", _RED_BGR, _DK_BG, -11, true)
cnDelBtn.OnEvent("Click", CnRemoveName)
global nsCryoBtn := MainGui.Add("CheckBox", "x248 y140 w15 h25")
MainGui.SetFont("s8 cDDDDDD", "Segoe UI")
MainGui.Add("Text", "x265 y140 w35 h25 +0x200", "Cryo")
nsHelpBtn := DarkBtn(MainGui, "x350 y32 w24 h23", "?", _RED_BGR, _DK_BG, -11, true)
nsHelpBtn.OnEvent("Click", NsShowHelp)

MainGui.Add("Text", "x8 y170 w366 h1 +0x10")

; --- INI ---
MainGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
MainGui.Add("Text", "x22 y178 w200", "Apply INI  —  F5")
MainGui.SetFont("s8 c888888", "Segoe UI")
MainGui.Add("Text", "x22 y196 w200", "Pastes INI into command bar")

MainGui.SetFont("s8 cDDDDDD", "Segoe UI")
MainGui.Add("Text", "x22 y216 w55 h20 +0x200", "Cmd Key:")
global iniCmdKeyEdit := MainGui.Add("Edit", "x78 y216 w55 h20", iniCommandKey)
iniCmdKeyEdit.SetFont("s8 c000000", "Segoe UI")
iniSetKeyBtn := DarkBtn(MainGui, "x136 y216 w36 h20", "Set", _RED_BGR, _DK_BG, -11, false)
iniSetKeyBtn.OnEvent("Click", IniDetectCommandKey)
iniSaveCmdBtn := DarkBtn(MainGui, "x175 y216 w44 h20", "Save", _RED_BGR, _DK_BG, -11, false)
iniSaveCmdBtn.OnEvent("Click", IniSaveCommandKey)

MainGui.SetFont("s8 c888888", "Segoe UI")
MainGui.Add("Text", "x22 y240 w200", "Custom INI (blank = default):")
global iniCustomEdit := MainGui.Add("Edit", "x22 y256 w200 h40 +Multi +Wrap", iniCustomCommand)
iniCustomEdit.SetFont("s8 c000000", "Segoe UI")
iniSaveCustomBtn := DarkBtn(MainGui, "x22 y300 w96 h20", "Save Custom INI", _RED_BGR, _DK_BG, -11, true)
iniSaveCustomBtn.OnEvent("Click", IniSaveCustomCommand)

hatchSaveBtn := DarkBtn(MainGui, "x22 y324 w70 h20", "Save Hatch", _RED_BGR, _DK_BG, -11, true)
hatchSaveBtn.OnEvent("Click", SaveHatchSettings)

; --- AUTO PIN / NVIDIA FILTER ---
MainGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
MainGui.Add("Text", "x122 y324 w10 h40 +0x200", "|")
MainGui.SetFont("s9 cDDDDDD", "Segoe UI")
global pinEnableBtn := MainGui.Add("CheckBox", "x136 y324 w80 h20", "Auto Pin")
pinEnableBtn.Value := pinAutoOpen
pinEnableBtn.OnEvent("Click", PinToggle)

MainGui.SetFont("s9 cDDDDDD", "Segoe UI")
global nfEnableBtn := MainGui.Add("CheckBox", "x136 y344 w120 h20", "NVIDIA Filter")
nfEnableBtn.Value := nfEnabled
nfEnableBtn.OnEvent("Click", NFToggle)


PinToggle(*) {
    global pinAutoOpen, pinEnableBtn
    pinAutoOpen := pinEnableBtn.Value
    PinSaveSettings()
}

NFToggle(*) {
    global nfEnabled, nfEnableBtn
    nfEnabled := nfEnableBtn.Value
    IniWrite(nfEnabled ? 1 : 0, A_ScriptDir "\AIO_config.ini", "NVIDIAFilter", "Enabled")
}

NFLoadSetting() {
    global nfEnabled
    try {
        val := IniRead(A_ScriptDir "\AIO_config.ini", "NVIDIAFilter", "Enabled", "0")
        global nfEnabled := (val = "1")
    }
}

; --- AUTO IMPRINT ---
MainGui.Add("Text", "x230 y196 w1 h40 BackgroundFF4444")
MainGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
MainGui.Add("Text", "x242 y178 w190", "Auto Imprint")

global imprintStartBtn := DarkBtn(MainGui, "x242 y200 w100 h26", "Start", _RED_BGR, _DK_BG, -12, true)
imprintStartBtn.OnEvent("Click", ImprintToggleArmed)

imprintHelpBtn := DarkBtn(MainGui, "x344 y200 w24 h26", "?", _RED_BGR, _DK_BG, -11, true)
imprintHelpBtn.OnEvent("Click", ImprintShowHelp)

MainGui.SetFont("s8 cDDDDDD", "Segoe UI")
global imprintHideOverlayCB := MainGui.Add("Checkbox", "x242 y230 w140 h16", "Hide scan outline")
imprintHideOverlayCB.Value := imprintHideOverlay
imprintHideOverlayCB.OnEvent("Click", ImprintOnHideOverlayToggle)

MainGui.Add("Text", "x242 y252 w50 h20 +0x200", "Inv Key:")
global imprintInvKeyEdit := MainGui.Add("Edit", "x296 y252 w28 h20 Limit1", imprintInventoryKey)
imprintInvKeyEdit.SetFont("s8 c000000", "Segoe UI")
imprintInvKeyEdit.OnEvent("Change", ImprintOnInvKeyChange)

global imprintResizeBtn := DarkBtn(MainGui, "x326 y252 w52 h20", "Resize", _RED_BGR, _DK_BG, -10, false)
imprintResizeBtn.OnEvent("Click", ImprintToggleResize)


MainGui.SetFont("s8 c888888 Italic", "Segoe UI")
global imprintStatusTxt := MainGui.Add("Text", "x242 y278 w190 h16", "Press Start then R=read Q=auto")

; --- UPLOAD FILTER LIST ---
MainGui.Add("Text", "x236 y298 w180 h1 +0x10")
MainGui.SetFont("s8 cFF4444 Bold", "Segoe UI")
MainGui.Add("Text", "x242 y304 w100 h14", "Upload Filter")
MainGui.SetFont("s8 cDDDDDD", "Segoe UI")
global nsUploadFilterCB := MainGui.Add("CheckBox", "x342 y302 w15 h18")
nsUploadFilterCB.OnEvent("Click", (*) => IniWrite(nsUploadFilterCB.Value, A_ScriptDir "\AIO_config.ini", "UploadFilters", "Enabled"))
global ufFilterCombo := MainGui.Add("ComboBox", "x242 y322 w128 h21 r8", [])
ufFilterCombo.SetFont("s8 c000000", "Segoe UI")
ufAddBtn := DarkBtn(MainGui, "x374 y322 w18 h21", "+", _RED_BGR, _DK_BG, -11, true)
ufAddBtn.OnEvent("Click", UfAddFilter)
ufDelBtn := DarkBtn(MainGui, "x394 y322 w18 h21", "-", _RED_BGR, _DK_BG, -11, true)
ufDelBtn.OnEvent("Click", UfRemoveFilter)


;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ModeSelectTab.UseTab(7)

MainGui.SetFont("s9 Bold cFF4444", "Segoe UI")
macroGuidedBtn := DarkBtn(MainGui, "x12 y28 w105 h26", "+ Guided", _RED_BGR, _DK_BG, -12, true)
macroGuidedBtn.OnEvent("Click", GuidedStartWizard)

macroRepeatNewBtn := DarkBtn(MainGui, "x121 y28 w105 h26", "+ Key Repeat", _RED_BGR, _DK_BG, -12, true)
macroRepeatNewBtn.OnEvent("Click", MacroShowRepeatDialog)

macroComboBtn := DarkBtn(MainGui, "x230 y28 w180 h26", "+ Popcorn+Magic-F", _RED_BGR, _DK_BG, -12, true)
macroComboBtn.OnEvent("Click", ComboStartWizard)

macroHelpBtn := DarkBtn(MainGui, "x416 y28 w26 h26", "?", _RED_BGR, _DK_BG, -12, true)
macroHelpBtn.OnEvent("Click", MacroShowHelp)

MainGui.SetFont("s8 c000000", "Segoe UI")
macroLV := MainGui.Add("ListView", "x12 y60 w425 h180 -Multi Background1A1A1A", ["Name", "Type", "Key", "Speed"])
macroLV.SetFont("s8 cDDDDDD", "Segoe UI")
SendMessage(0x1024, 0, 0x00DDDDDD, macroLV.Hwnd)
SendMessage(0x1026, 0, 0x001A1A1A, macroLV.Hwnd)
macroLV.ModifyCol(1, 130)
macroLV.ModifyCol(2, 65)
macroLV.ModifyCol(3, 40)
macroLV.ModifyCol(4, 155)
macroLV.OnEvent("Click", MacroLVClick)

MainGui.SetFont("s9 Bold cFF4444", "Segoe UI")
macroPlaySelBtn := DarkBtn(MainGui, "x12 y246 w65 h26", "Start", _RED_BGR, _DK_BG, -11, true)
macroPlaySelBtn.OnEvent("Click", MacroPlaySelected)

macroTuneSelBtn := DarkBtn(MainGui, "x81 y246 w55 h26", "Tune", _RED_BGR, _DK_BG, -11, true)
macroTuneSelBtn.OnEvent("Click", MacroTuneSelected)

MainGui.SetFont("s9 cDDDDDD", "Segoe UI")
macroEditSelBtn := DarkBtn(MainGui, "x140 y246 w55 h26", "Edit", _RED_BGR, _DK_BG, -11, true)
macroEditSelBtn.OnEvent("Click", MacroEditSelected)

macroDeleteSelBtn := DarkBtn(MainGui, "x199 y246 w60 h26", "Delete", _RED_BGR, _DK_BG, -11, true)
macroDeleteSelBtn.OnEvent("Click", MacroDeleteSelected)

MainGui.SetFont("s9 Bold cFF4444", "Segoe UI")
macroUpBtn := DarkBtn(MainGui, "x380 y246 w26 h26", Chr(0x25B2), _RED_BGR, _DK_BG, -11, false)
macroUpBtn.OnEvent("Click", MacroMoveUp)
macroDownBtn := DarkBtn(MainGui, "x410 y246 w26 h26", Chr(0x25BC), _RED_BGR, _DK_BG, -11, false)
macroDownBtn.OnEvent("Click", MacroMoveDown)

MainGui.SetFont("s8 c888888 Italic", "Segoe UI")
MainGui.Add("Text", "x12 y278 w425 h14 Center", "F3/Start to arm  |  F at inventory  |  Q: single/swap  |  Z: next/exit")
MainGui.Add("Text", "x12 y294 w425 h14 Center", "F1 = Stop / UI  |  Only ► macro hotkey is live  |  ? for full help")

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

WinActivate(arkwindow)
MainGui.Show("x177 y330 w450 h432")

for _dbHwnd, _dbInfo in _darkBtns {
    _dbS := DllCall("GetWindowLong", "Ptr", _dbHwnd, "Int", -16, "Int")
    if ((_dbS & 0xF) != 0xB) {
        DllCall("SetWindowLong", "Ptr", _dbHwnd, "Int", -16, "Int", (_dbS & ~0xF) | 0xB)
    }
    DllCall("InvalidateRect", "Ptr", _dbHwnd, "Ptr", 0, "Int", 1)
}

global sheepAutoLvlActive := false
global sheepModeActive    := false
SheepHideAutoLvlGui()
PcLog("Script start: reset Sheep auto-level to off")
OvercapUpdateStatus()
PcApplySpeed()
PcRegisterSpeedHotkeys(false)

try {
    savedInvKey  := IniRead(A_ScriptDir "\AIO_config.ini", "Popcorn", "InvKey",  "")
    savedDropKey := IniRead(A_ScriptDir "\AIO_config.ini", "Popcorn", "DropKey", "")
    if (savedInvKey  != "") {
        pcInvKey  := savedInvKey
        sheepInventoryKey := pcInvKey
        try sheepInventoryInput.Value := pcInvKey
    }
    if (savedDropKey != "")
        pcDropKey := savedDropKey
    savedSpeedMode := IniRead(A_ScriptDir "\AIO_config.ini", "Popcorn", "SpeedMode", 1)
    global pcSpeedMode := Integer(savedSpeedMode)
    savedDropSleep := IniRead(A_ScriptDir "\AIO_config.ini", "Popcorn", "DropSleep", "")
    if (savedDropSleep != "")
        global pcDropSleep := Integer(savedDropSleep)
    savedCycleSleep := IniRead(A_ScriptDir "\AIO_config.ini", "Popcorn", "CycleSleep", "")
    if (savedCycleSleep != "")
        global pcCycleSleep := Integer(savedCycleSleep)
    savedHoverDelay := IniRead(A_ScriptDir "\AIO_config.ini", "Popcorn", "HoverDelay", "")
    if (savedHoverDelay != "")
        global pcHoverDelay := Integer(savedHoverDelay)
    try pcDropKeyTxt.Text := pcDropKey
    savedCustomFilter := IniRead(A_ScriptDir "\AIO_config.ini", "Popcorn", "CustomFilter", "")
    if (savedCustomFilter != "") {
        pcCustomFilter := savedCustomFilter
        try pcCustomEdit.Text := savedCustomFilter
    }
}

LoadHatchSettings()
PinLoadSettings()
PcUpdateUI()
MacroLoadAll()
ImprintLoadConfig()
AcOcrLoadConfig()
OBOcrLoadConfig()
OBCharLoadServer()
SvrLoadList()
UfLoadList()
_ListLoad(cnNameList, ClaimAndNameEdit, "NameList")
if (cnNameList.Length = 0) {
    cnNameList.Push("GG FFA")
    _ListRefresh(cnNameList, ClaimAndNameEdit)
}
ClaimAndNameEdit.Text := cnNameList.Length > 0 ? cnNameList[1] : "GG FFA"
_ListLoad(acSimpleFilterList, acSimpleFilterEdit, "CraftSimpleFilters")
_ListLoad(acTimedFilterList, acTimedFilterEdit, "CraftTimedFilters")
_ListLoad(acGridFilterList, acGridFilterEdit, "CraftGridFilters")
_ListLoad(pcCustomFilterList, pcCustomEdit, "PopcornFilters")
_ListLoad(mfGiveFilterList, CustomEditGive, "MagicFGiveFilters")
_ListLoad(mfTakeFilterList, CustomEditTake, "MagicFTakeFilters")
try {
    ufCBVal := Integer(IniRead(A_ScriptDir "\AIO_config.ini", "UploadFilters", "Enabled", "0"))
    nsUploadFilterCB.Value := ufCBVal
}
NFLoadSetting()
try nfEnableBtn.Value := nfEnabled
PcLoadScanArea()

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; TAB CHANGE HANDLER -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

OnTabChange(ctrl, *) {
    global sheepTabActive, sheepRunning, sheepAutoLvlActive
    global sheepToggleKey, sheepOvercapKey, sheepAutoLvlKey
    global runMammothScript, arkwindow
    global pcTabActive, pcF10Step
    global runAutoLvlScript, gmkMode
    if (!macroPlaying) {
        ToolTip()
        ToolTip(,,,1)
        ToolTip(,,,2)
    }
    if (ctrl.Value != 3 && runAutoLvlScript) {
        global runAutoLvlScript := false
        try Hotkey("$q", "Off")
        DarkBtnText(StartAutoLvlButton, "START")
        if (!macroPlaying)
            ToolTip()
    }
    if (ctrl.Value = 5) {
        global sheepTabActive := true
        SheepUnregisterHotkeys()
        SheepRegisterHotkeys()
        if WinExist(arkwindow) {
            WinActivate(arkwindow)
            Sleep(100)
        }
        if (sheepAutoLvlActive) {
            try {
                SheepShowAutoLvlGui()
            } catch as err {
                PcLog("OnTabChange Sheep: AutoLvl GUI re-show error — " err.Message)
                global sheepAutoLvlGui := ""
                SheepShowAutoLvlGui()
            }
            PcLog("OnTabChange Sheep: re-showed AutoLvl GUI")
        }
    } else {
        global sheepTabActive := false
        if (sheepRunning) {
            SheepStopScript()
        }
        if (sheepAutoLvlActive) {
            SheepStopAutoLvl()
        }
    }
    if (ctrl.Value = 4 || ctrl.Value = 1) {
        global pcTabActive := true
        if (pcF10Step > 0 || pcMode > 0) {
            PcRegisterSpeedHotkeys(true)
            PcShowArmedTooltip()
        }
    } else {
        global pcTabActive := false
        if (pcStorageResizing)
            PcExitScanResize()
        if (pcMode > 0 && pcF10Step = 0) {
            global pcMode := 0
            global pcAllCustomActive := false
            global pcAllNoFilter := false
            global pcGrinderPoly := false, pcGrinderMetal := false, pcGrinderCrystal := false
            global pcPresetRaw := false, pcPresetCooked := false
            PcRegisterSpeedHotkeys(false)
            PcUpdateUI()
            if (!macroPlaying)
                ToolTip()
        }
        if (pcF10Step > 0 && !macroPlaying)
            ToolTip()
    }
    if (ctrl.Value = 2) {
    } else {
        if (runMagicFScript) {
            global runMagicFScript := false
            global magicFPresetIdx := 1
            try Hotkey("$z", "Off")
            if (!macroPlaying)
                ToolTip()
        }
    }
    if (ctrl.Value = 6) {
        global acTabActive := true
    } else {
        global acTabActive := false
        global acCountOnlyActive := false
        try DarkBtnText(acTallyBtn, "Count")
        if (acOcrResizing)
            AcOcrExitResize()
        if (obOcrResizing)
            OBOcrExitResize()
        if (acRunning) {
            global acTimedMultiActive := false
            global acEarlyExit := true
        }
    }
    if (ctrl.Value != 8 && imprintScanning) {
        ImprintStopAll()
        try DarkBtnText(imprintStartBtn, "Start")
        try imprintStatusTxt.Text := "Press Start then R=read Q=auto"
    }
    if (gmkMode != "off")
        ToolTip(GmkBuildTooltip(), 0, 0)
    if (ctrl.Value = 7) {
        global macroTabActive := true
        MacroRegisterHotkeys(true)
    } else if (ctrl.Value = 1) {
        global macroTabActive := false
        if (macroPlaying) {
            activeMacro := macroList.Length >= macroActiveIdx && macroActiveIdx > 0 ? macroList[macroActiveIdx] : ""
            if (activeMacro = "" || (activeMacro.type != "guided" && activeMacro.type != "combo"))
                MacroStopPlay()
        }
        if (macroRecording) {
            global macroRecording := false
            MacroRecordSetHotkeys(false)
            SetTimer(MacroRecordMousePoll, 0)
        }
        if (macroTuning) {
            global macroTuning := false
            global macroPlaying := false
            MacroSaveIfDirty()
        }
        MacroRegisterHotkeys(false)
    } else {
        global macroTabActive := false
        if (macroPlaying) {
            activeMacro := macroList.Length >= macroActiveIdx && macroActiveIdx > 0 ? macroList[macroActiveIdx] : ""
            if (activeMacro = "" || (activeMacro.type != "guided" && activeMacro.type != "combo"))
                MacroStopPlay()
        }
        MacroRegisterHotkeys(false)
        if (macroRecording) {
            global macroRecording := false
            MacroRecordSetHotkeys(false)
            SetTimer(MacroRecordMousePoll, 0)
        }
        if (guidedRecording) {
            global guidedRecording := false
            global guidedReRecordIdx := 0
            GuidedRecordSetHotkeys(false)
            SetTimer(GuidedRecordMousePoll, 0)
        }
        if (macroTuning) {
            global macroTuning := false
            global macroPlaying := false
            MacroSaveIfDirty()
        }
    }
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; INI APPLY FUNCTIONS -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ApplyIni() {
    global iniCommandKey, iniCustomCommand, iniDefaultCommand, arkwindow
    global MainGui, guiVisible

    cmdToRun := (iniCustomCommand != "") ? iniCustomCommand : iniDefaultCommand

    if (!WinExist(arkwindow)) {
        TrayTip(" ARK window not found!","GG AIO",0x1)
        HideTrayTipTimer(2000)
        return
    }

    MainGui.Hide()
    global guiVisible := false

    WinActivate(arkwindow)
    Sleep(300)

    _savedClip := A_Clipboard
    A_Clipboard := cmdToRun
    Send(iniCommandKey)
    Sleep(400)
    Send("^v")
    Sleep(400)
    Send("{Enter}")
    Sleep(500)
    A_Clipboard := _savedClip

    ToolTip(" INI Applied!  |  F1 = Show UI  |  Q = Stop", 0, 0)
    SetTimer(() => ToolTip(), -3000)
}

IniDetectCommandKey(*) {
    global iniCmdKeyEdit
    iniCmdKeyEdit.Value := ""
    iniCmdKeyEdit.Focus()
    ih := InputHook("L10 T10")
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}", "-E")
    ih.Start()
    ToolTip("Press your command bar key...")
    ih.Wait()
    ToolTip()
    if (ih.EndReason = "EndKey") {
        key := ih.EndKey
        if (RegExMatch(key, "^F\d+$") || StrLen(key) = 1)
            iniCmdKeyEdit.Value := "{" key "}"
        else
            iniCmdKeyEdit.Value := "{" key "}"
    } else if (ih.EndReason = "Timeout") {
        ToolTip("Timed out")
        SetTimer(() => ToolTip(), -1500)
    }
}

IniSaveCommandKey(*) {
    global iniCommandKey, iniCmdKeyEdit
    val := Trim(iniCmdKeyEdit.Value)
    if (val = "") {
        ToolTip("Command key cannot be empty!")
        SetTimer(() => ToolTip(), -2000)
        return
    }
    global iniCommandKey := val
    IniWrite(val, A_ScriptDir "\AIO_config.ini", "ini", "commandkey")
    ToolTip("INI command key saved: " val)
    SetTimer(() => ToolTip(), -2000)
}

IniSaveCustomCommand(*) {
    global iniCustomCommand, iniCustomEdit
    val := Trim(iniCustomEdit.Value)
    global iniCustomCommand := val
    IniWrite(val != "" ? val : " ", A_ScriptDir "\AIO_config.ini", "ini", "customcommand")
    ToolTip(val != "" ? "Custom INI saved!" : "Custom INI cleared — using default.")
    SetTimer(() => ToolTip(), -2000)
}

SaveHatchSettings(*) {
    global qhMode, qhAllBtn, qhSingleBtn, cnEnableBtn, nsEnableBtn, nsCryoBtn, ClaimAndNameEdit
    configFile := A_ScriptDir "\AIO_config.ini"
    hm := qhAllBtn.Value ? 1 : (qhSingleBtn.Value ? 2 : 0)
    IniWrite(hm, configFile, "Hatch", "HatchMode")
    IniWrite(cnEnableBtn.Value, configFile, "Hatch", "ClaimNameEnabled")
    IniWrite(nsEnableBtn.Value, configFile, "Hatch", "NameSpayEnabled")
    IniWrite(nsCryoBtn.Value, configFile, "Hatch", "CryoEnabled")
    IniWrite(ClaimAndNameEdit.Text, configFile, "Hatch", "DinoName")
    ToolTip("Hatch settings saved!")
    SetTimer(() => ToolTip(), -2000)
}

LoadHatchSettings() {
    global qhMode, cnEnableBtn, nsEnableBtn, nsCryoBtn, ClaimAndNameEdit
    global qhAllBtn, qhSingleBtn
    configFile := A_ScriptDir "\AIO_config.ini"
    try {
        hm := Integer(IniRead(configFile, "Hatch", "HatchMode", "0"))
        if (hm = 1) {
            global qhMode := 1
            qhAllBtn.Value := 1
            qhSingleBtn.Value := 0
        } else if (hm = 2) {
            global qhMode := 2
            qhAllBtn.Value := 0
            qhSingleBtn.Value := 1
        }
        cn := Integer(IniRead(configFile, "Hatch", "ClaimNameEnabled", "0"))
        cnEnableBtn.Value := cn
        ns := Integer(IniRead(configFile, "Hatch", "NameSpayEnabled", "0"))
        nsEnableBtn.Value := ns
        cryo := Integer(IniRead(configFile, "Hatch", "CryoEnabled", "0"))
        nsCryoBtn.Value := cryo
        name := IniRead(configFile, "Hatch", "DinoName", "")
        if (name != "")
            ClaimAndNameEdit.Text := name
    }
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

readini(cat, key) {
    return IniRead(A_ScriptDir "\AIO_config.ini", cat, key, "Default")
}
saveini(input) {
    if (input = "") {
        return
    }
    IniWrite(input, A_ScriptDir "\AIO_config.ini", "ntfy", "key")
}
updatekey(key) {
    if (key = "") {
        return
    }
    global ntfykey := key
}
ntfypush(priority, input) {
    if (ntfykey = "") {
        return
    }
    try {
        WHR := ComObject("WinHttp.WinHttpRequest.5.1")
        WHR.Open("POST", "https://ntfy.sh/" ntfykey, true)
        WHR.SetRequestHeader("Priority", priority, "Title", "SIM")
        WHR.Send("In Server " input)
    }
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; GUI HELPERS -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

HideTrayTip() {
    TrayTip
}
HideTrayTipTimer(timerinms) {
    SetTimer(HideTrayTip, timerinms)
}

ShowNtfyHelp(*) {
    global ntfyHelpGui
    if (IsSet(ntfyHelpGui) && ntfyHelpGui != "") {
        try ntfyHelpGui.Destroy()
        global ntfyHelpGui := ""
    }
    ntfyHelpGui := Gui("+AlwaysOnTop +Owner", "NTFY Setup")
    ntfyHelpGui.BackColor := "1A1A1A"

    ntfyHelpGui.SetFont("s10 cFF4444 Bold", "Segoe UI")
    ntfyHelpGui.Add("Text", "x15 y15 w325", "Quick Guide")

    ntfyHelpGui.SetFont("s9 cDDDDDD", "Segoe UI")
    ntfyHelpGui.Add("Text", "x15 y40 w325",
        "NTFY can send a notif to your phone when you get in serv"
        . "`n`nInstall NTFY — search NTFY in your phone's app store"
        . "`n`nOpen NTFY and tap `"+`" then type your own unique topic"
        . "`nname  e.g. `"StubzyGG`""
        . "`n`nType that same topic name into the NTFY key field in sim menu"
        . "`n`nClick Test to ensure they match and notifs are working"
        . "`n`nSave and start sim")

    ntfyHelpGui.SetFont("s9 cFFFFFF Bold", "Segoe UI")
    closeBtn := ntfyHelpGui.Add("Button", "x130 y230 w110 h26", "Got it")
    closeBtn.OnEvent("Click", (*) => ntfyHelpGui.Destroy())
    ntfyHelpGui.OnEvent("Close", (*) => ntfyHelpGui.Destroy())

    ntfyHelpGui.Show("AutoSize")
}

PcShowHelp(*) {
    global pcHelpGui
    if (IsSet(pcHelpGui) && pcHelpGui != "") {
        try pcHelpGui.Destroy()
        global pcHelpGui := ""
    }
    pcHelpGui := Gui("+AlwaysOnTop +Owner", "Popcorn Help")
    pcHelpGui.BackColor := "1A1A1A"
    pcHelpGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
    pcHelpGui.Add("Text", "x15 y15 w305", "Quick Guide")
    pcHelpGui.SetFont("s9 cDDDDDD", "Segoe UI")
    pcHelpGui.Add("Text", "x15 y38 w305",
        "Presets: Select any or all presets`n"
        . "  1 preset = Popcorn until Q (Q = stop)`n"
        . "  2+ presets = Q cycles to next last Q = Stop, F1 = Stop/UI`n`n"
        . "All (no filter): drops everything`n"
        . "Custom: Can add custom filter to preset cycle`n"
        . "  Can combine with presets for cycling`n`n"
        . "Transfer All: transfers your inventory on stop`n"
        . "Skip First Slot: skips top-left slot (ele for forges etc)`n`n"
        . "F10:  cycles quick modes`n"
        . "Z:  change drop speed  (Safe / Fast / Very Fast)`n"
        . "Q:  stop (1 preset) / cycle selected presets (2+)`n"
        . "F1:  stop / UI`n`n"
        . "Set Drop/key before first use")
    pcHelpGui.SetFont("s9 cFFFFFF Bold", "Segoe UI")
    closeBtn := pcHelpGui.Add("Button", "x130 y+12 w110 h26", "Got it")
    closeBtn.OnEvent("Click", (*) => pcHelpGui.Destroy())
    pcHelpGui.OnEvent("Close", (*) => pcHelpGui.Destroy())
    pcHelpGui.Show("AutoSize")
}

NsShowHelp(*) {
    global nsHelpGui
    if (IsSet(nsHelpGui) && nsHelpGui != "") {
        try nsHelpGui.Destroy()
        global nsHelpGui := ""
    }
    nsHelpGui := Gui("+AlwaysOnTop +Owner", "Hatch & Name Modes")
    nsHelpGui.BackColor := "1A1A1A"
    nsHelpGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
    nsHelpGui.Add("Text", "x15 y15 w305", "Quick Guide")
    nsHelpGui.SetFont("s8 cDDDDDD Bold", "Segoe UI")
    nsHelpGui.Add("Text", "x15 y33 w305", "Run at standard gamma")

    nsHelpGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
    nsHelpGui.Add("Text", "x15 y55 w305", "Hatch")
    nsHelpGui.SetFont("s9 cDDDDDD", "Segoe UI")
    nsHelpGui.Add("Text", "x15 y73 w305",
        "All: hatches every egg  |  Single: hatches one at a time`n"
        . "F at inventory to hatch")

    nsHelpGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
    nsHelpGui.Add("Text", "x15 y113 w305", "Claim/Name")
    nsHelpGui.SetFont("s9 cDDDDDD", "Segoe UI")
    nsHelpGui.Add("Text", "x15 y131 w305", "E on a tame to name it")

    nsHelpGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
    nsHelpGui.Add("Text", "x15 y153 w305", "Name/Spay")
    nsHelpGui.SetFont("s9 cDDDDDD", "Segoe UI")
    nsHelpGui.Add("Text", "x15 y171 w305", "E on a tame to name/spay")

    nsHelpGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
    nsHelpGui.Add("Text", "x15 y195 w305", "Running Together")
    nsHelpGui.SetFont("s9 cDDDDDD", "Segoe UI")
    nsHelpGui.Add("Text", "x15 y213 w305",
        "Select a hatch mode then press a name mode START`n"
        . "F for hatching, E for naming  |  Q = Stop all")
    nsHelpGui.SetFont("s9 cFFFFFF Bold", "Segoe UI")
    closeBtn := nsHelpGui.Add("Button", "x130 y+12 w110 h26", "Got it")
    closeBtn.OnEvent("Click", (*) => nsHelpGui.Destroy())
    nsHelpGui.OnEvent("Close", (*) => nsHelpGui.Destroy())
    nsHelpGui.Show("AutoSize")
}

TempTooltip(text, x, y, timeinmillis) {
    ToolTip(text, x, y)
    Sleep(timeinmillis)
    ToolTip
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; SHARED INV HELPERS -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

checkTake(box, itemname) {
    if (box.Value = true) {
        ControlClick("x" theirInvSearchBarX " y" theirInvSearchBarY, arkwindow)
        Sleep(mfSearchBarClickMs)
        Send(itemname)
        Sleep(mfFilterSettleMs)
        ControlClick("x" transferToMeButtonX " y" transferToMeButtonY, arkwindow)
        Sleep(mfTransferSettleMs)
    }
}
checkGive(box, itemname) {
    if (box.Value = true) {
        ControlClick("x" mySearchBarX " y" mySearchBarY, arkwindow)
        Sleep(mfSearchBarClickMs)
        Send(itemname)
        Sleep(mfFilterSettleMs)
        ControlClick("x" transferToOtherButtonX " y" transferToOtherButtonY, arkwindow)
        Sleep(mfTransferSettleMs)
    }
}
dropOne(type) {
    Sleep(50)
    ControlClick("x" theirInvSearchBarX " y" theirInvSearchBarY, arkwindow,,,,"NA")
    Sleep(10)
    ControlSend(type,, arkwindow)
    Sleep(100)
    Send("{Enter}")
    Sleep(100)
    ControlClick("x" theirInvDropAllButtonX " y" theirInvDropAllButtonY, arkwindow,,,,"NA")
    Sleep(200)
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; MAGIC F FUNCTIONS -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

RunMagicF(*) {
    global runMagicFScript := true
    global magicFPresetNames := [], magicFPresetFilters := [], magicFPresetDirs := []
    global magicFPresetIdx := 1

    givePairs := [
        [BeerCheckboxGive,    "Beer",     "Beer"],
        [BerryCheckbox,       "Berry",    "berry"],
        [CharcCheckboxGive,   "Charc",    "charc"],
        [CookedCheckboxGive,  "Cooked",   "coo"],
        [CrystalCheckboxGive, "Crystal",  "crystal"],
        [DustCheckboxGive,    "Dust",     "dust"],
        [FertCheckboxGive,    "Fert",     "fert"],
        [FiberCheckboxGive,   "Fiber",    "fiber"],
        [FlintCheckboxGive,   "Flint",    "flint"],
        [HideCheckboxGive,    "Hide",     "hide"],
        [HoneyCheckboxGive,   "Honey",    "honey"],
        [MetalCheckboxGive,   "Metal",    "metal"],
        [NarcCheckboxGive,    "Narcotic", "narco"],
        [OilCheckboxGive,     "Oil",      "oil"],
        [PasteCheckboxGive,   "Paste",    "paste"],
        [PearlCheckboxGive,   "Pearl",    "pearl"],
        [PolyCheckboxGive,    "Poly",     "poly"],
        [MeatCheckbox,        "Raw",      "raw"],
        [SpoiledCheckboxGive, "Spoiled",  "spoiled"],
        [StimCheckboxGive,    "Stim",     "stim"],
        [StoneCheckboxGive,   "Stone",    "stone"],
        [SulfurCheckboxGive,  "Sulfur",   "sulfur"],
        [ThatchCheckboxGive,  "Thatch",   "thatch"],
        [WoodCheckboxGive,    "Wood",     "wood"]
    ]
    if (CustomCheckBoxGive.Value) {
        for , _gf in mfGiveFilterList
            givePairs.Push([CustomCheckBoxGive, "Custom [" _gf "]", _gf])
        _gfCur := Trim(CustomEditGive.Text)
        if (_gfCur != "" && !AcListHas(mfGiveFilterList, _gfCur))
            givePairs.Push([CustomCheckBoxGive, "Custom [" _gfCur "]", _gfCur])
    }

    takePairs := [
        [BeerCheckboxTake,        "Beer",     "Beer"],
        [BerryCheckboxTake,       "Berry",    "berry"],
        [CharcCheckboxTake,       "Charc",    "charc"],
        [CookedCheckboxTake,      "Cooked",   "coo"],
        [CrystalCheckboxTake,     "Crystal",  "crystal"],
        [DustCheckboxTake,        "Dust",     "dust"],
        [FertCheckboxTake,        "Fert",     "fert"],
        [FiberCheckboxTake,       "Fiber",    "fiber"],
        [FlintCheckboxTake,       "Flint",    "flint"],
        [HideCheckboxTake,        "Hide",     "hide"],
        [HoneyCheckBoxTake,       "Honey",    "honey"],
        [MetalCheckboxTake,       "Metal",    "metal"],
        [NarcCheckboxTake,        "Narcotic", "narco"],
        [OilCheckboxTake,         "Oil",      "oil"],
        [PasteCheckboxTake,       "Paste",    "paste"],
        [PearlCheckboxTake,       "Pearl",    "pearl"],
        [PolycheckboxTake,        "Poly",     "poly"],
        [MeatCheckboxTake,        "Raw",      "raw"],
        [SpoiledMeatCheckboxTake, "Spoiled",  "spoiled"],
        [StimCheckboxTake,        "Stim",     "stim"],
        [StoneCheckboxTake,       "Stone",    "stone"],
        [SulfurCheckboxTake,      "Sulfur",   "sulfur"],
        [ThatchCheckboxTake,      "Thatch",   "thatch"],
        [WoodCheckboxTake,        "Wood",     "wood"]
    ]
    if (CustomCheckBoxTake.Value) {
        for , _tf in mfTakeFilterList
            takePairs.Push([CustomCheckBoxTake, "Custom [" _tf "]", _tf])
        _tfCur := Trim(CustomEditTake.Text)
        if (_tfCur != "" && !AcListHas(mfTakeFilterList, _tfCur))
            takePairs.Push([CustomCheckBoxTake, "Custom [" _tfCur "]", _tfCur])
    }

    if (magicFRefillMode) {
        for , p in takePairs {
            if (p[1].Value) {
                magicFPresetNames.Push(p[2])
                magicFPresetFilters.Push(p[3])
                magicFPresetDirs.Push("Take")
            }
        }
        for , p in givePairs {
            if (p[1].Value) {
                magicFPresetNames.Push(p[2])
                magicFPresetFilters.Push(p[3])
                magicFPresetDirs.Push("Give")
            }
        }
    } else {
        for , p in givePairs {
            if (p[1].Value) {
                magicFPresetNames.Push(p[2])
                magicFPresetFilters.Push(p[3])
                magicFPresetDirs.Push("Give")
            }
        }
        for , p in takePairs {
            if (p[1].Value) {
                magicFPresetNames.Push(p[2])
                magicFPresetFilters.Push(p[3])
                magicFPresetDirs.Push("Take")
            }
        }
    }

    MainGui.Hide
    global guiVisible := false
    try Hotkey("$z", MagicFSwapDirection, "On")
    ToolTip(MagicFBuildTooltip(), 0, 0)
}

MagicFBuildTooltip() {
    global magicFPresetNames, magicFPresetDirs, magicFPresetIdx, magicFRefillMode
    if (magicFPresetNames.Length = 0)
        return " Magic F — no presets selected`nF1 = Stop/UI"

    if (magicFRefillMode) {
        takes := [], gives := []
        for i, n in magicFPresetNames {
            if (magicFPresetDirs[i] = "Take")
                takes.Push(n)
            else
                gives.Push(n)
        }
        tt := " Take/Refill:"
        if (takes.Length > 0) {
            tList := ""
            for i, t in takes
                tList .= (i > 1 ? " + " : "") t
            tt .= "`n  Take: " tList
        }
        if (gives.Length > 0) {
            gList := ""
            for i, g in gives
                gList .= (i > 1 ? " + " : "") g
            tt .= "`n  Give: " gList
        }
        tt .= "`nF at inventory  |  F1 = Stop/UI"
        return tt
    }

    cur := magicFPresetNames[magicFPresetIdx]
    dir := magicFPresetDirs[magicFPresetIdx]

    if (magicFPresetNames.Length = 1)
        return " Magic F: " dir " " cur "`nZ = Swap  |  F1 = Stop/UI"

    nextIdx := Mod(magicFPresetIdx, magicFPresetNames.Length) + 1
    nextLabel := "Q → " magicFPresetNames[nextIdx]

    line1 := " Magic F: " dir " " cur "  (" nextLabel ")"
    items := ""
    for i, n in magicFPresetNames {
        arrow := (i = magicFPresetIdx) ? "►" : " "
        items .= arrow " " magicFPresetDirs[i] " " n
        if (i < magicFPresetNames.Length)
            items .= "`n"
    }
    return line1 "`n" items "`nQ = Cycle selected presets  |  Z = Swap  |  F1 = Stop/UI"
}

MagicFSwapDirection(thisHotkey) {
    global magicFPresetDirs, magicFPresetNames
    if (!WinActive(arkwindow)) {
        Send("{" SubStr(thisHotkey, 2) "}")
        return
    }
    if (!runMagicFScript)
        return
    if (magicFRefillMode)
        return
    for i, d in magicFPresetDirs
        magicFPresetDirs[i] := (d = "Give") ? "Take" : "Give"
    magicFPairs := [
        [BeerCheckboxGive,    BeerCheckboxTake],
        [BerryCheckbox,       BerryCheckboxTake],
        [CharcCheckboxGive,   CharcCheckboxTake],
        [CookedCheckboxGive,  CookedCheckboxTake],
        [CrystalCheckboxGive, CrystalCheckboxTake],
        [DustCheckboxGive,    DustCheckboxTake],
        [FertCheckboxGive,    FertCheckboxTake],
        [FiberCheckboxGive,   FiberCheckboxTake],
        [FlintCheckboxGive,   FlintCheckboxTake],
        [HideCheckboxGive,    HideCheckboxTake],
        [HoneyCheckboxGive,   HoneyCheckBoxTake],
        [MetalCheckboxGive,   MetalCheckboxTake],
        [NarcCheckboxGive,    NarcCheckboxTake],
        [OilCheckboxGive,     OilCheckboxTake],
        [PasteCheckboxGive,   PasteCheckboxTake],
        [PearlCheckboxGive,   PearlCheckboxTake],
        [PolyCheckboxGive,    PolycheckboxTake],
        [MeatCheckbox,        MeatCheckboxTake],
        [SpoiledCheckboxGive, SpoiledMeatCheckboxTake],
        [StimCheckboxGive,    StimCheckboxTake],
        [StoneCheckboxGive,   StoneCheckboxTake],
        [SulfurCheckboxGive,  SulfurCheckboxTake],
        [ThatchCheckboxGive,  ThatchCheckboxTake],
        [WoodCheckboxGive,    WoodCheckboxTake],
        [CustomCheckBoxGive,  CustomCheckBoxTake]
    ]
    for , pair in magicFPairs {
        gVal := pair[1].Value
        tVal := pair[2].Value
        pair[1].Value := tVal
        pair[2].Value := gVal
    }
    gText := CustomEditGive.Text
    tText := CustomEditTake.Text
    CustomEditGive.Text := tText
    CustomEditTake.Text := gText
    ToolTip(MagicFBuildTooltip(), 0, 0)
}
magicFpressed() {
    global magicFPresetNames, magicFPresetFilters, magicFPresetDirs, magicFPresetIdx
    global magicFRefillMode

    if (magicFPresetNames.Length = 0)
        return

    waitOpenInvCount := 0
    _nfB1 := 0
    while (!NFPixelWait(1495*widthmultiplier, 226*heightmultiplier, 1490*widthmultiplier, 230*heightmultiplier, "0xFFFFFF", 0, &_nfB1)) {
        Sleep(16)
        waitOpenInvCount++
        if (waitOpenInvCount > 375) {
            return
        }
    }

    if (magicFRefillMode) {
        for i, filter in magicFPresetFilters {
            dir := magicFPresetDirs[i]
            if (dir = "Take") {
                ControlClick("x" theirInvSearchBarX " y" theirInvSearchBarY, arkwindow)
                Sleep(mfSearchBarClickMs)
                Send(filter)
                Sleep(mfFilterSettleMs)
                ControlClick("x" transferToMeButtonX " y" transferToMeButtonY, arkwindow)
                Sleep(mfTransferSettleMs)
            } else {
                ControlClick("x" mySearchBarX " y" mySearchBarY, arkwindow)
                Sleep(mfSearchBarClickMs)
                Send(filter)
                Sleep(mfFilterSettleMs)
                ControlClick("x" transferToOtherButtonX " y" transferToOtherButtonY, arkwindow)
                Sleep(mfTransferSettleMs)
            }
        }
        Send("{Esc}")
        Sleep(mfTransferSettleMs)
        ToolTip(MagicFBuildTooltip(), 0, 0)
        return
    }

    filter := magicFPresetFilters[magicFPresetIdx]
    dir    := magicFPresetDirs[magicFPresetIdx]

    if (dir = "Give") {
        ControlClick("x" mySearchBarX " y" mySearchBarY, arkwindow)
        Sleep(mfSearchBarClickMs)
        Send(filter)
        Sleep(mfFilterSettleMs)
        ControlClick("x" transferToOtherButtonX " y" transferToOtherButtonY, arkwindow)
        Sleep(mfTransferSettleMs)
    } else {
        ControlClick("x" theirInvSearchBarX " y" theirInvSearchBarY, arkwindow)
        Sleep(mfSearchBarClickMs)
        Send(filter)
        Sleep(mfFilterSettleMs)
        ControlClick("x" transferToMeButtonX " y" transferToMeButtonY, arkwindow)
        Sleep(mfTransferSettleMs)
    }

    Send("{Esc}")
    Sleep(mfTransferSettleMs)
    ToolTip(MagicFBuildTooltip(), 0, 0)
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; QUICK FEED FUNCTIONS -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

QuickFeedCycle(*) {
    global quickFeedMode, MainGui, guiVisible, arkwindow

    quickFeedMode := Mod(quickFeedMode + 1, 3)

    if (quickFeedMode = 1) {
        MainGui.Hide()
        global guiVisible := false
        if WinExist(arkwindow)
            WinActivate(arkwindow)
        ToolTip(" Quick Feed — Raw Meat armed`nF at dino to feed  |  F3 = Berry  |  F3 again = Off", 0, 0)
    } else if (quickFeedMode = 2) {
        ToolTip(" Quick Feed — Berry armed`nF at dino to feed  |  F3 = Off", 0, 0)
    } else {
        QuickFeedStop()
    }
}

QuickFeedStop() {
    global quickFeedMode, MainGui, guiVisible
    global quickFeedMode := 0
    ToolTip()
    OBCharRestoreTooltip()
    MainGui.Show("NoActivate")
    global guiVisible := true
}

QuickFeedFPressed() {
    global quickFeedMode, arkwindow
    global mySearchBarX, mySearchBarY
    global transferToOtherButtonX, transferToOtherButtonY
    global widthmultiplier, heightmultiplier

    timeouttimer := 0
    invOpen      := false
    _nfBF := 0
    while (!NFPixelWait(1495*widthmultiplier, 226*heightmultiplier, 1490*widthmultiplier, 230*heightmultiplier, "0xFFFFFF", 0, &_nfBF)) {
        Sleep(16)
        timeouttimer++
        if (timeouttimer > 375)
            return
    }

    filter := (quickFeedMode = 1) ? "raw" : "berry"
    ControlClick("x" mySearchBarX " y" mySearchBarY, arkwindow)
    Sleep(30)
    Send(filter)
    Sleep(100)
    ControlClick("x" transferToOtherButtonX " y" transferToOtherButtonY, arkwindow)
    Sleep(100)
    Send("{Esc}")
    Sleep(100)

    modeStr := (quickFeedMode = 1) ? "Raw Meat" : "Berry"
    nextStr := (quickFeedMode = 1) ? "F3 = Berry" : "F3 = Off"
    ToolTip(" Quick Feed — " modeStr " armed`nF at dino to feed  |  " nextStr, 0, 0)
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

RunAutoLvl(*) {
    global runAutoLvlScript, autoLvlCycleSlots, autoLvlCycleIdx, autoLvlCombineChk
    
    if (runAutoLvlScript) {
        global runAutoLvlScript := false
        try Hotkey("$q", "Off")
        DarkBtnText(StartAutoLvlButton, "START")
        ToolTip()
        return
    }
    
    autoLvlCycleSlots := []
    noOxyDiff := NoOxyCheckBox.Value ? (50 * heightmultiplier) : 0
    
    statDefs := [
        {name: "HP",     edit: HealthPointEdit, clickY: Round(667*heightmultiplier),                    pixX: autoLvlHealthPixX,  pixY: autoLvlHealthPixY},
        {name: "Stam",   edit: StamPointEdit,   clickY: Round(713*heightmultiplier),                    pixX: autoLvlStamPixX,    pixY: autoLvlStamPixY},
        {name: "Food",   edit: FoodPointEdit,    clickY: Round(801*heightmultiplier),                    pixX: autoLvlFoodPixX,    pixY: autoLvlFoodPixY},
        {name: "Weight", edit: WeightPointEdit,  clickY: Round((845*heightmultiplier) - noOxyDiff),      pixX: autoLvlWeightPixX,  pixY: autoLvlWeightPixY},
        {name: "Melee",  edit: MeleePointEdit,   clickY: Round((900*heightmultiplier) - noOxyDiff),      pixX: autoLvlMeleeXPPixX, pixY: autoLvlMeleeXPPixY}
    ]
    
    activeStats := []
    for sd in statDefs {
        if (sd.edit.Value > 0)
            activeStats.Push(sd)
    }
    
    if (activeStats.Length = 0 && !AutoSaddleCheckBox.Value) {
        ToolTip(" No stats set — enter point values first", 0, 0)
        SetTimer(() => ToolTip(), -2000)
        return
    }

    if (activeStats.Length = 0 && AutoSaddleCheckBox.Value) {
        autoLvlCycleSlots.Push({label: "Saddle only", stats: []})
    } else if (autoLvlCombineChk.Value || activeStats.Length = 1) {
        names := []
        for s in activeStats
            names.Push(s.name " +" s.edit.Value)
        slotLabel := ""
        for i, n in names
            slotLabel .= (i > 1 ? " + " : "") n
        autoLvlCycleSlots.Push({label: slotLabel, stats: activeStats})
    } else {
        for s in activeStats {
            autoLvlCycleSlots.Push({label: s.name " +" s.edit.Value, stats: [s]})
        }
    }
    
    global autoLvlCycleIdx := 1
    global runAutoLvlScript := true
    MainGui.Hide
    global guiVisible := false
    DarkBtnText(StartAutoLvlButton, "STOP")
    
    if (autoLvlCycleSlots.Length > 1)
        Hotkey("$q", AutoLvlQCycle, "On")
    
    AutoLvlShowTooltip()
}

AutoLvlQCycle(thisHotkey) {
    global autoLvlCycleSlots, autoLvlCycleIdx, runAutoLvlScript, arkwindow
    if (!runAutoLvlScript || !WinActive(arkwindow)) {
        Send("{q}")
        return
    }
    global autoLvlCycleIdx := Mod(autoLvlCycleIdx, autoLvlCycleSlots.Length) + 1
    AutoLvlShowTooltip()
}

AutoLvlShowTooltip() {
    global autoLvlCycleSlots, autoLvlCycleIdx
    slot := autoLvlCycleSlots[autoLvlCycleIdx]
    slotInfo := slot.label
    cycleInfo := autoLvlCycleSlots.Length > 1
        ? " (" autoLvlCycleIdx "/" autoLvlCycleSlots.Length ")  Q=next"
        : ""
    ToolTip(" AutoLvL: " slotInfo cycleInfo "`nF1 = Stop", 0, 20)
}

global autoLvlHealthPixX  := Round(1075 * widthmultiplier)
global autoLvlHealthPixY  := Round(513  * heightmultiplier)
global autoLvlStamPixX    := Round(1066 * widthmultiplier)
global autoLvlStamPixY    := Round(546  * heightmultiplier)
global autoLvlWeightPixX  := Round(1076 * widthmultiplier)
global autoLvlWeightPixY  := Round(650  * heightmultiplier)
global autoLvlMeleeXPPixX := Round(1112 * widthmultiplier)
global autoLvlMeleeXPPixY := Round(482  * heightmultiplier)
global autoLvlFoodPixX    := Round(1075 * widthmultiplier)
global autoLvlFoodPixY    := Round(608  * heightmultiplier)

global autoLvlStatTimeout := 2000
global autoLvlInvTimeout  := 250

autoLvLFpressed() {
    global autoLvlCryoCheck, autoLvlCycleSlots, autoLvlCycleIdx
    
    if (autoLvlCycleSlots.Length = 0)
        return
    
    slot := autoLvlCycleSlots[autoLvlCycleIdx]
    
    waitOpenInvCount := 0
    autolvlOpenInv   := true
    _nfB2 := 0
    while (!NFPixelWait(1632*widthmultiplier, 215*heightmultiplier, 1633*widthmultiplier, 216*heightmultiplier, "0xFFFFFF", 0, &_nfB2)) {
        Sleep(16)
        waitOpenInvCount++
        if (waitOpenInvCount > autoLvlInvTimeout) {
            autolvlOpenInv := false
            break
        }
    }
    
    if (autolvlOpenInv) {
        for s in slot.stats {
            pts := s.edit.Value
            if (pts <= 0)
                continue
            colBefore := PxGet(s.pixX, s.pixY)
            lvlStat(pts, Round(1507 * widthmultiplier), s.clickY)
            if (!AutoLvlWaitStatChange(s.pixX, s.pixY, colBefore))
                return
        }
        
        if (AutoSaddleCheckBox.Value = true) {
            Sleep(100)
            MouseMove(413*widthmultiplier, 386*heightmultiplier, 0)
            Sleep(100)
            Click
            Sleep(200)
            ControlSend("{e}",, arkwindow)
            Sleep(25)
        }
        ControlSend("{Esc}",, arkwindow)
        if (autoLvlCryoCheck.Value) {
            Sleep(1900)
            Send("{Click}")
        }
        AutoLvlShowTooltip()
    }
}

AutoLvlWaitStatChange(px, py, colBefore) {
    global autoLvlStatTimeout
    deadline := A_TickCount + autoLvlStatTimeout
    loop {
        if (PxGet(px, py) != colBefore)
            return true
        if (A_TickCount >= deadline)
            return false
        Sleep(30)
    }
}

lvlStat(amount, x, y) {
    MouseMove(x, y)
    loop (amount) {
        Click
    }
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; CLAIM AND NAME FUNCTIONS -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

claimAndNameEpressed() {
    global nsCryoBtn, widthmultiplier, heightmultiplier, invyDetectX, invyDetectY
    if (NFIsBright(invyDetectX, invyDetectY))
        return
    waitNameOpenCount := 0
    waitNameOpen      := true
    _nfB3 := 0
    while (!NFPixelWait(1034*widthmultiplier, 665*heightmultiplier, 1036*widthmultiplier, 667*heightmultiplier, "0x94D2EA", 30, &_nfB3)) {
        Sleep(16)
        waitNameOpenCount++
        if (waitNameOpenCount > 94) {
            waitNameOpen := false
            break
        }
    }
    if (waitNameOpen) {
        MouseMove(1241*widthmultiplier, 664*heightmultiplier)
        Click
        Sleep(20)
        Send(ClaimAndNameEdit.Text)
        Sleep(20)
        MouseMove(1122*widthmultiplier, 1014*heightmultiplier)
        Click
        if (nsCryoBtn.Value) {
            Sleep(600)
            Send("{Click}")
        }
    }
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; NAME AND SPAY FUNCTIONS -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

NsLog(msg) {
    global nsLogEntries
    ts := FormatTime("", "HH:mm:ss")
    nsLogEntries.Push(ts " " msg)
    if (nsLogEntries.Length > 50)
        nsLogEntries.RemoveAt(1)
}

nameAndSpayEpressed() {
    global runNameAndSpayScript, arkwindow, widthmultiplier, heightmultiplier
    global nsRadialX, nsRadialY, nsSpayX, nsSpayY, nsAltRadialX, nsAltRadialY, nsAltClickX, nsAltClickY
    global nsAlt2RadialX, nsAlt2RadialY, nsAlt2ClickX, nsAlt2ClickY
    global nsAdminPixX, nsAdminPixY, nsAdminSpayX, nsAdminSpayY
    global nsCryoBtn, invyDetectX, invyDetectY

    if (!runNameAndSpayScript)
        return
    if (NFIsBright(invyDetectX, invyDetectY))
        return

    NsLog("E pressed — starting Name/Spay")
    NsLog("radial=(" nsRadialX "," nsRadialY ")  altDetect=(" nsAltRadialX "," nsAltRadialY ")  altClick=(" nsAltClickX "," nsAltClickY ")")
    NsLog("alt2Detect=(" nsAlt2RadialX "," nsAlt2RadialY ")  alt2Click=(" nsAlt2ClickX "," nsAlt2ClickY ")")
    NsLog("spay=(" nsSpayX "," nsSpayY ")  adminDetect=(" nsAdminPixX "," nsAdminPixY ")  adminSpay=(" nsAdminSpayX "," nsAdminSpayY ")")

    ; ── Step 1:────────────────────────
    NsLog("[1] Waiting for name dialog pixel...")
    waitNameOpenCount := 0
    waitNameOpen      := true
    _nfB4 := 0
    while (!NFPixelWait(1034*widthmultiplier, 665*heightmultiplier, 1036*widthmultiplier, 667*heightmultiplier, "0x94D2EA", 30, &_nfB4)) {
        Sleep(16)
        waitNameOpenCount++
        if (waitNameOpenCount > 94) {
            waitNameOpen := false
            break
        }
    }
    if (waitNameOpen) {
        NsLog("[1] Name dialog found after " waitNameOpenCount " polls — typing name")
        MouseMove(1241*widthmultiplier, 664*heightmultiplier)
        Click
        Sleep(20)
        Send(ClaimAndNameEdit.Text)
        Sleep(20)
        MouseMove(1122*widthmultiplier, 1014*heightmultiplier)
        Click
        NsLog("[1] Name applied: " ClaimAndNameEdit.Text)
    } else {
        NsLog("[1] Name dialog NOT found — timed out after " waitNameOpenCount " polls — aborting")
        return
    }

    if (!runNameAndSpayScript) {
        NsLog("[!] Stopped by Q after naming")
        return
    }

    ; ── Step 2: ─────────
    NsLog("[2] Waiting 600ms before radial wheel...")
    Sleep(600)
    NsLog("[2] Sending E down (hold)")
    Send("{e down}")
    Sleep(300)
    radialLayout := "standard"
    loop 20 {
        if (NFSearchTol(&X, &Y, nsAlt2RadialX, nsAlt2RadialY, nsAlt2RadialX+1, nsAlt2RadialY+1, "0xFFFFFF", 10)) {
            radialLayout := "alt2"
            break
        }
        if (NFSearchTol(&X, &Y, nsAltRadialX, nsAltRadialY, nsAltRadialX+1, nsAltRadialY+1, "0xFFFFFF", 10)) {
            radialLayout := "alt"
            break
        }
        Sleep(20)
    }
    NsLog("[2] Radial wheel open — layout=" radialLayout)

    ; ── Step 3: ───────────────────
    if (radialLayout = "alt") {
        NsLog("[3] Alt radial — clicking (" nsAltClickX "," nsAltClickY ")")
        MouseMove(nsAltClickX, nsAltClickY, 0)
    } else if (radialLayout = "alt2") {
        NsLog("[3] Alt2 radial — clicking (" nsAlt2ClickX "," nsAlt2ClickY ")")
        MouseMove(nsAlt2ClickX, nsAlt2ClickY, 0)
    } else {
        NsLog("[3] Standard radial — clicking (" nsRadialX "," nsRadialY ")")
        MouseMove(nsRadialX, nsRadialY, 0)
    }
    Sleep(100)
    Click
    NsLog("[3] Clicked radial option")
    Sleep(100)

    ; ── Step 4: ──────────
    isAdmin := NFSearchTol(&X, &Y, nsAdminPixX, nsAdminPixY, nsAdminPixX+1, nsAdminPixY+1, "0xFFFFFF", 10)
    if (isAdmin) {
        NsLog("[4] Admin detected — holding at (" nsAdminSpayX "," nsAdminSpayY ") for 5.1s")
        MouseMove(nsAdminSpayX, nsAdminSpayY, 0)
    } else {
        NsLog("[4] Standard confirm — holding at (" nsSpayX "," nsSpayY ") for 5.1s")
        MouseMove(nsSpayX, nsSpayY, 0)
    }
    Sleep(100)
    Click("Down")
    Sleep(5100)
    Click("Up")
    NsLog("[4] Released click after 5.1s hold")

    ; ── Step 5: ─────────────────────────────────────────────────────
    Send("{e up}")
    Sleep(200)
    NsLog("[5] Released E — spay complete")

    ; ── Step 6: ─────────────────────────────────────────
    if (nsCryoBtn.Value) {
        Sleep(300)
        Click
        NsLog("[6] Cryo click sent")
    }
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; QUICK HATCH FUNCTIONS -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

QhLog(msg) {
    global qhLogEntries
    ts := FormatTime("", "HH:mm:ss")
    qhLogEntries.Push(ts " " msg)
    if (qhLogEntries.Length > 50)
        qhLogEntries.RemoveAt(1)
}

QhCountEggs() {
    global qhEggSlotX, qhEggSlotY, qhEmptyColor, qhEmptyTol
    refInt := Integer("0x" SubStr(qhEmptyColor, 3))
    r2 := (refInt >> 16) & 0xFF, g2 := (refInt >> 8) & 0xFF, b2 := refInt & 0xFF
    count := 0
    loop 10 {
        col := PxGet(qhEggSlotX[A_Index], qhEggSlotY[A_Index])
        colInt := Integer("0x" SubStr(col, 3))
        r1 := (colInt >> 16) & 0xFF, g1 := (colInt >> 8) & 0xFF, b1 := colInt & 0xFF
        diff := Abs(r1-r2) + Abs(g1-g2) + Abs(b1-b2)
        if (diff <= qhEmptyTol)
            count++
    }
    return count
}

QhToggleMode(cb, mode) {
    global qhMode, qhArmed, qhStatusTxt, qhAllBtn, qhSingleBtn
    if (qhArmed)
        return
    if (cb.Value) {
        for btn in [qhAllBtn, qhSingleBtn] {
            if (btn != cb)
                btn.Value := 0
        }
        global qhMode := mode
        modeNames := Map(1, "All", 2, "Single")
        qhStatusTxt.Text := "Mode: " modeNames[mode]
    } else {
        global qhMode := 0
        qhStatusTxt.Text := "Select a mode then press START"
    }
}

QhStart(*) {
    global qhMode, qhArmed, qhRunning, MainGui, guiVisible, arkwindow, qhStatusTxt, qhClickDelay
    global cnEnableBtn, nsEnableBtn, runClaimAndNameScript, runNameAndSpayScript, lastDebugContext
    global depoEggsBtn, depoEmbryoBtn, depoEggsActive, depoEmbryoActive, depoCycle, depoCycleIdx

    if (qhArmed || runClaimAndNameScript || runNameAndSpayScript || depoEggsActive || depoEmbryoActive) {
        global qhArmed   := false
        global qhRunning := false
        global runClaimAndNameScript := false
        global runNameAndSpayScript  := false
        global depoEggsActive    := false
        global depoEmbryoActive  := false
        global depoCycle         := []
        global depoCycleIdx      := 0
        qhStatusTxt.Text := "Disarmed"
        qhAllBtn.Value    := 0
        qhSingleBtn.Value := 0
        ToolTip(,,,1)
        ToolTip(,,,2)
        MainGui.Show("NoActivate")
        global guiVisible := true
        return
    }

    hasHatch  := (qhMode > 0)
    hasCN     := cnEnableBtn.Value
    hasNS     := nsEnableBtn.Value
    hasDepoE  := depoEggsBtn.Value
    hasDepoEm := depoEmbryoBtn.Value
    hasDepo   := hasDepoE || hasDepoEm

    if (!hasHatch && !hasCN && !hasNS && !hasDepo) {
        ToolTip(" Select at least one mode!", 0, 0, 1)
        SetTimer(() => ToolTip(,,,1), -1500)
        return
    }

    MainGui.Hide()
    global guiVisible := false

    depoCycle := []
    if (hasDepoE) {
        global depoEggsActive := true
        depoCycle.Push({label: "Eggs", filter: "egg"})
    }
    if (hasDepoEm) {
        global depoEmbryoActive := true
        depoCycle.Push({label: "Embryo", filter: "Embryo"})
    }

    if (hasHatch)
        depoCycle.Push({label: "Hatch", filter: ""})

    if (hasDepo) {
        global depoCycleIdx := 1
        ToolTip(DepoBuildTooltip(), 0, 0, 1)
    }

    if (hasHatch) {
        global qhArmed := true
        if (!hasDepo) {
            modeNames := Map(1, "All", 2, "Single")
            ToolTip(" Quick Hatch — " modeNames[qhMode] "`nPress F at inventory  |  Q = Stop", 0, 0, 1)
        }
    }

    if (hasCN) {
        global runClaimAndNameScript := true
        global runNameAndSpayScript  := false
        global lastDebugContext      := "nameandspay"
        if (!hasDepo) {
            nsY := hasHatch ? 40 : 0
            ToolTip(" Claim/Name`nPress E to Claim/Name  |  F1 = Pause  |  Q = Stop ", 0, nsY, 2)
        }
    } else if (hasNS) {
        global runNameAndSpayScript  := true
        global runClaimAndNameScript := false
        global lastDebugContext      := "nameandspay"
        if (!hasDepo) {
            nsY := hasHatch ? 40 : 0
            ToolTip(" Name/Spay`nPress E to Name/Spay  |  F1 = Pause  |  Q = Stop ", 0, nsY, 2)
        }
    }
}

DepoFPressed() {
    global depoCycle, depoCycleIdx, arkwindow
    global mySearchBarX, mySearchBarY, transferToOtherButtonX, transferToOtherButtonY
    global widthmultiplier, heightmultiplier

    if (depoCycle.Length = 0 || depoCycleIdx < 1 || depoCycleIdx > depoCycle.Length)
        return
    cur := depoCycle[depoCycleIdx]
    if (cur.filter = "")
        return
    if (!WinActive(arkwindow))
        return

    waitCount := 0
    _nfB5 := 0
    while (!NFPixelWait(1495*widthmultiplier, 226*heightmultiplier, 1490*widthmultiplier, 230*heightmultiplier, "0xFFFFFF", 0, &_nfB5)) {
        Sleep(16)
        waitCount++
        if (waitCount > 375)
            return
    }

    ControlClick("x" mySearchBarX " y" mySearchBarY, arkwindow)
    Sleep(30)
    Send(cur.filter)
    Sleep(100)
    ControlClick("x" transferToOtherButtonX " y" transferToOtherButtonY, arkwindow)
    Sleep(100)
    Send("{Esc}")
    Sleep(100)
}

DepoBuildTooltip() {
    global depoCycle, depoCycleIdx, qhMode, qhArmed, runClaimAndNameScript, runNameAndSpayScript
    if (depoCycle.Length = 0 || depoCycleIdx < 1)
        return ""
    parts := []
    for i, step in depoCycle {
        arrow := (i = depoCycleIdx) ? " ► " : "   "
        if (step.filter != "")
            parts.Push(arrow "Depo " step.label " [F=give]")
        else {
            modeNames := Map(1, "All", 2, "Single")
            hatchTT := qhArmed ? "Hatch " modeNames[qhMode] : "Hatch"
            parts.Push(arrow hatchTT " [F=hatch]")
        }
    }
    tt := ""
    for i, p in parts
        tt .= (i > 1 ? "`n" : "") p
    if (runClaimAndNameScript)
        tt .= "`n E = Claim/Name (always on)"
    else if (runNameAndSpayScript)
        tt .= "`n E = Name/Spay (always on)"
    tt .= "`n Q = cycle  |  F1 = stop"
    return tt
}

QhFPressed() {
    global qhMode, qhArmed, qhRunning, qhClick1X, qhClick1Y, qhClick2X, qhClick2Y
    global qhInvPixX, qhInvPixY, qhClickDelay, widthmultiplier, heightmultiplier, arkwindow
    global qhLogEntries
    global qhEmptyPixX, qhEmptyPixY, qhEmptyColor, qhEmptyTol
    global qhEggSlotX, qhEggSlotY

    if (!qhArmed || qhRunning)
        return
    if (!WinActive(arkwindow))
        return
    global qhRunning := true
    _qhStart := A_TickCount

    QhLog("F pressed — mode=" qhMode "  delay=" qhClickDelay "ms  click1=(" qhClick1X "," qhClick1Y ")  click2=(" qhClick2X "," qhClick2Y ")")
    QhLog("Inv pixel=(" qhInvPixX "," qhInvPixY ")  res=" A_ScreenWidth "x" A_ScreenHeight "  wm=" widthmultiplier "  hm=" heightmultiplier)

    Sleep(100)

    colBefore := PxGet(qhInvPixX, qhInvPixY)
    QhLog("Pre-wait color at inv pixel: " colBefore)

    invReady := WaitForPixel(qhInvPixX, qhInvPixY, "0xFFFFFF", 10, 6000, "Screen")

    colAfter := PxGet(qhInvPixX, qhInvPixY)
    QhLog("WaitForPixel result=" invReady "  color after: " colAfter "  +" (A_TickCount - _qhStart) "ms")

    if (invReady) {
        CoordMode("Mouse", "Screen")
        QhLog("Inventory frame open — waiting for contents to load")

        contentTimeout := 100  
        contentLoaded  := false
        loop contentTimeout {
            col1 := PxGet(qhEggSlotX[1], qhEggSlotY[1])
            colE := PxGet(qhEmptyPixX, qhEmptyPixY)
            colInt1 := Integer("0x" SubStr(col1, 3))
            colIntE := Integer("0x" SubStr(colE, 3))
            refInt := Integer("0x" SubStr(qhEmptyColor, 3))
            r2 := (refInt >> 16) & 0xFF, g2 := (refInt >> 8) & 0xFF, b2 := refInt & 0xFF

            r1 := (colInt1 >> 16) & 0xFF, g1 := (colInt1 >> 8) & 0xFF, b1 := colInt1 & 0xFF
            diff1 := Abs(r1-r2) + Abs(g1-g2) + Abs(b1-b2)

            rE := (colIntE >> 16) & 0xFF, gE := (colIntE >> 8) & 0xFF, bE := colIntE & 0xFF
            diffE := Abs(rE-r2) + Abs(gE-g2) + Abs(bE-b2)

            if (diff1 <= qhEmptyTol || diffE <= qhEmptyTol) {
                contentLoaded := true
                QhLog("Contents loaded after " A_Index " polls  slot1=" col1 " emptyPix=" colE)
                break
            }
            Sleep(20)
        }
        if (!contentLoaded)
            QhLog("Contents load timeout — proceeding anyway  slot1=" PxGet(qhEggSlotX[1], qhEggSlotY[1]))

        Sleep(200)

        QhLog("Inventory ready — starting clicks +" (A_TickCount - _qhStart) "ms")

        if (qhMode = 1) {
            clickPairs := 0
            maxPairs   := 200    
            minPairs   := 3      
            QhLog("All mode — emptyPix(" qhEmptyPixX "," qhEmptyPixY ") target=0x019C88 tol=" qhEmptyTol)
            preCol := PxGet(qhEmptyPixX, qhEmptyPixY)
            QhLog("All mode — pre-loop pixel color: " preCol)

            loop {
                if (clickPairs >= maxPairs) {
                    QhLog("All mode — hit safety cap at " maxPairs " pairs")
                    break
                }
                if (!qhRunning) {
                    QhLog("All mode — stopped by Q after " clickPairs " pairs")
                    break
                }

                MouseMove(qhClick1X, qhClick1Y)
                Sleep(qhClickDelay)
                Click
                Sleep(qhClickDelay)
                MouseMove(qhClick2X, qhClick2Y)
                Sleep(qhClickDelay)
                Click
                Sleep(qhClickDelay)
                clickPairs++

                if (clickPairs >= minPairs) {
                    col := PxGet(qhEmptyPixX, qhEmptyPixY)
                    colInt := Integer("0x" SubStr(col, 3))
                    refInt := Integer("0x" SubStr(qhEmptyColor, 3))
                    r1 := (colInt >> 16) & 0xFF, g1 := (colInt >> 8) & 0xFF, b1 := colInt & 0xFF
                    r2 := (refInt >> 16) & 0xFF, g2 := (refInt >> 8) & 0xFF, b2 := refInt & 0xFF
                    diff := Abs(r1-r2) + Abs(g1-g2) + Abs(b1-b2)
                    if (diff > qhEmptyTol) {
                        Sleep(50)
                        col2 := PxGet(qhEmptyPixX, qhEmptyPixY)
                        colInt2 := Integer("0x" SubStr(col2, 3))
                        r3 := (colInt2 >> 16) & 0xFF, g3 := (colInt2 >> 8) & 0xFF, b3 := colInt2 & 0xFF
                        diff2 := Abs(r3-r2) + Abs(g3-g2) + Abs(b3-b2)
                        if (diff2 > qhEmptyTol) {
                            QhLog("All mode — empty confirmed after " clickPairs " pairs  pixel=" col " → " col2)
                            break
                        }
                        QhLog("All mode — false positive at pair " clickPairs " (" col " → " col2 ") — continuing")
                    }
                }
            }
            QhLog("All mode — " clickPairs " click pairs done")
        } else {
            scan1 := QhCountEggs()
            Sleep(50)
            scan2 := QhCountEggs()
            eggCount := Min(scan1, scan2)
            QhLog("Single mode — scan1: " scan1 "  scan2: " scan2 "  using: " eggCount)

            if (eggCount = 0) {
                QhLog("Single mode — no eggs in inventory")
                ToolTip(" No eggs detected", 0, 0, 1)
                SetTimer(() => ToolTip(,,,1), -1500)
            } else {
                MouseMove(qhClick1X, qhClick1Y)
                Sleep(qhClickDelay)
                Click
                Sleep(qhClickDelay)
                MouseMove(qhClick2X, qhClick2Y)
                Sleep(qhClickDelay)
                Click

                remaining := eggCount
                pollCount := 0
                loop 80 {  
                    Sleep(20)
                    pollCount++
                    remaining := QhCountEggs()
                    if (remaining < eggCount)
                        break
                }
                QhLog("Single mode — pre: " eggCount "  post: " remaining "  polls: " pollCount)
                if (remaining > 0)
                    ToolTip(" Single — " remaining " egg" (remaining > 1 ? "s" : "") " remaining`nPress F at inventory  |  Q = Stop", 0, 0, 1)
                else
                    ToolTip(" Single — inventory empty`nPress F at inventory  |  Q = Stop", 0, 0, 1)
            }
        }
        Sleep(100)
        if (NFSearchTol(&px, &py, 1495*widthmultiplier, 226*heightmultiplier, 1490*widthmultiplier, 230*heightmultiplier, "0xFFFFFF")) {
            ControlSend("{f}",, arkwindow)
            QhLog("Sent F to close inventory")
        } else {
            QhLog("Inventory already closed — skipping close")
        }
    } else {
        QhLog("Inventory NOT detected — timed out")
    }

    PerfLogPush("hatch", _qhStart, invReady ? "done" : "timeout")
    global qhRunning := false
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; MAMMOTH DRUMS FUNCTIONS -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ToggleMammothScript(*) {
    global runMammothScript
    if (runMammothScript) {
        StopMammothScript()
    } else {
        StartMammothScript()
    }
}

StartMammothScript() {
    global runMammothScript := true
    ToolTip(" BG Mammoth Drums RUNNING`nF8 = Stop", 0, 0)
    if WinExist(arkWindow)
        WinActivate(arkWindow)
    SetControlDelay(-1)
    ControlClick("x1 y1", arkWindow,,,,"Pos")
    SetTimer(MammothDrumTick, 1840)
}

StopMammothScript() {
    global runMammothScript := false
    SetTimer(MammothDrumTick, 0)
    ToolTip()
    OBCharRestoreTooltip()
}

MammothDrumTick() {
    global runMammothScript, arkWindow
    if (!runMammothScript || !WinExist(arkWindow)) {
        StopMammothScript()
        return
    }
    SetControlDelay(-1)
    ControlClick("x1 y1", arkWindow,,,,"Pos")
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; AUTO PIN FUNCTIONS -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

PinLogMsg(msg) {
    global pinLog
    ts := FormatTime("", "HH:mm:ss.") SubStr(A_TickCount, -2)
    pinLog.Push(ts " " msg)
    if (pinLog.Length > 50)
        pinLog.RemoveAt(1)
}

PinStartPoll() {
    global pinAutoOpen, pinPollActive, pinPollCount, arkwindow, invyDetectX, invyDetectY
    if (!pinAutoOpen)
        return
    if (pinPollActive) {
        SetTimer(PinPollCheck, 0)
        global pinPollActive := false
        PinLogMsg("Poll restarted (new E press)")
    }
    if (!WinActive(arkwindow))
        return
    if (NFIsBright(invyDetectX, invyDetectY))
        return
    if (runMagicFScript && magicFRefillMode)
        return
    if (qhRunning || obUploadRunning || obDownloadRunning || pcRunning || acRunning)
        return

    global pinPollActive := true
    global pinPollCount  := 0
    global pinPollStartTick := A_TickCount
    global pinEwasHeld := false
    PinLogMsg("Poll started (E pressed)")
    SetTimer(PinPollCheck, pinPollInterval)
}

PinPollCheck() {
    global pinPollActive, pinPollCount, pinPollMaxTicks, pinPollInterval
    global pinPix1X, pinPix1Y, pinPix2X, pinPix2Y, pinPix3X, pinPix3Y, pinPix4X, pinPix4Y
    global pinClickX, pinClickY, pinTol
    global arkwindow, pinPollStartTick
    global pinEwasHeld, pinHoldThreshold

    pinPollCount++

    if (!pinEwasHeld && GetKeyState("e", "P")) {
        elapsed := A_TickCount - pinPollStartTick
        if (elapsed > pinHoldThreshold)
            global pinEwasHeld := true
    }

    if (pinPollCount > pinPollMaxTicks) {
        SetTimer(PinPollCheck, 0)
        global pinPollActive := false
        elapsed := A_TickCount - pinPollStartTick
        PinLogMsg("Poll timeout (" elapsed "ms, " pinPollCount " ticks) — no pin screen")
        return
    }

    if (!WinActive(arkwindow)) {
        SetTimer(PinPollCheck, 0)
        global pinPollActive := false
        PinLogMsg("Poll aborted — ARK lost focus")
        return
    }

    try {
        m2 := NFSearchTol(&x, &y, pinPix2X, pinPix2Y, pinPix2X, pinPix2Y, "0xC1F5FF", pinTol)
        if (!m2)
            return
        m3 := NFSearchTol(&x, &y, pinPix3X, pinPix3Y, pinPix3X, pinPix3Y, "0xC1F5FF", pinTol)
        if (!m3)
            return
    } catch {
        return
    }

    if (pinEwasHeld) {
        SetTimer(PinPollCheck, 0)
        global pinPollActive := false
        PinLogMsg("Pin screen detected but E was held >300ms — skipping (manual pin)")
        return
    }

    SetTimer(PinPollCheck, 0)
    global pinPollActive := false
    elapsed := A_TickCount - pinPollStartTick
    PinLogMsg("Pin screen DETECTED after " elapsed "ms (tick " pinPollCount ") — clicking Last Pin")
    Click(pinClickX " " pinClickY)
    PinLogMsg("  clicked (" pinClickX "," pinClickY ")")
}

PinSaveSettings() {
    global pinAutoOpen
    try {
        IniWrite(pinAutoOpen ? 1 : 0, A_ScriptDir "\AIO_config.ini", "AutoPin", "Enabled")
    }
}

PinLoadSettings() {
    global pinAutoOpen, pinEnableBtn
    try {
        saved := IniRead(A_ScriptDir "\AIO_config.ini", "AutoPin", "Enabled", "1")
        global pinAutoOpen := (saved = "1")
        pinEnableBtn.Value := pinAutoOpen
    }
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; GRAB MY KIT FUNCTIONS -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

GmkToggle() {
    global gmkMode, gmkStatusTxt, guiVisible, MainGui, macroPlaying
    global runMagicFScript, quickFeedMode
    global pcF10Step, pcMode, pcRunning, pcF10StatusTxt

    if (gmkMode = "off")
        gmkMode := "take"
    else if (gmkMode = "take")
        gmkMode := "give"
    else
        gmkMode := "off"

    if (gmkMode != "off") {
        if (runMagicFScript) {
            global runMagicFScript := false
            try Hotkey("$z", "Off")
        }
        if (quickFeedMode > 0) {
            global quickFeedMode := 0
        }
        if (macroPlaying)
            MacroStopPlay()
        if (pcF10Step > 0 || pcMode > 0) {
            global pcF10Step := 0
            global pcMode := 0
            global pcRunning := false
            PcRegisterSpeedHotkeys(false)
            PcUpdateUI()
            try pcF10StatusTxt.Text := ""
        }

        mLabel := (gmkMode = "take") ? "TAKE" : "GIVE"
        gmkStatusTxt.Text := mLabel
        if (guiVisible) {
            MainGui.Hide()
            global guiVisible := false
        }
        ToolTip(GmkBuildTooltip(), 0, 0)
    } else {
        gmkStatusTxt.Text := ""
        ToolTip(" Grab My Kit: Off", 0, 0)
        SetTimer(() => (gmkMode != "off" ? 0 : (ToolTip(), OBCharRestoreTooltip())), -1500)
    }
}

GmkBuildTooltip() {
    global gmkMode
    mLabel := (gmkMode = "take") ? "TAKE" : "GIVE"
    action := (gmkMode = "take") ? "F = Take All" : "F = Give All"
    return " Grab My Kit: " mLabel "`n" action "  |  F12 = cycle  |  F1 = UI"
}

GmkFPressed() {
    global gmkMode, arkwindow
    global transferToMeButtonX, transferToMeButtonY
    global transferToOtherButtonX, transferToOtherButtonY
    global widthmultiplier, heightmultiplier
    static busy := false

    if (gmkMode = "off" || busy)
        return

    waitCount := 0
    _nfB6 := 0
    while (!NFPixelWait(1495*widthmultiplier, 226*heightmultiplier, 1490*widthmultiplier, 230*heightmultiplier, "0xFFFFFF", 0, &_nfB6)) {
        Sleep(16)
        waitCount++
        if (waitCount > 375)
            return
    }

    busy := true
    if (gmkMode = "take") {
        ControlClick("x" transferToMeButtonX " y" transferToMeButtonY, arkwindow)
        Sleep(100)
        if (NFSearchTol(&x, &y, 1495*widthmultiplier, 226*heightmultiplier, 1490*widthmultiplier, 230*heightmultiplier, "0xFFFFFF"))
            Send("{f}")
    } else {
        ControlClick("x" transferToOtherButtonX " y" transferToOtherButtonY, arkwindow)
        Sleep(100)
        if (NFSearchTol(&x, &y, 1495*widthmultiplier, 226*heightmultiplier, 1490*widthmultiplier, 230*heightmultiplier, "0xFFFFFF"))
            Send("{f}")
    }
    Sleep(100)
    busy := false
    if (gmkMode != "off")
        ToolTip(GmkBuildTooltip(), 0, 0)
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;
; MACRO SYSTEM FUNCTIONS
;
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

MacroLoadAll() {
    global macroList, macroLV, macroTabActive, macroSelectedIdx
    macroList := []
    configFile := A_ScriptDir "\AIO_config.ini"
    legacyFile := A_ScriptDir "\AIO_macros.ini"
    if (FileExist(legacyFile)) {
        MacroLog("MacroLoad: migrating from AIO_macros.ini")
        configFile := legacyFile
    }
    MacroLog("MacroLoad: looking for " configFile)
    if (!FileExist(configFile)) {
        MacroLog("MacroLoad: INI not found — using defaults")
        MacroEnsureDefaults()
        MacroUpdateListView()
        return
    }
    MacroLog("MacroLoad: INI found")
    try {
        count := Integer(IniRead(configFile, "MacroCount", "Count", "0"))
        global macroSelectedIdx := Integer(IniRead(configFile, "MacroCount", "Selected", "1"))
    } catch as countErr {
        MacroLog("MacroLoad: ERROR reading MacroCount — " countErr.Message)
        MacroEnsureDefaults()
        MacroUpdateListView()
        return
    }
    MacroLog("MacroLoad: count=" count " selected=" macroSelectedIdx)
    loop count {
        idx := A_Index
        sec := "Macro_" idx
        try {
            m := {}
            m.name := IniRead(configFile, sec, "Name", "")
            m.type := IniRead(configFile, sec, "Type", "")
            m.hotkey := IniRead(configFile, sec, "Hotkey", "")
            MacroLog("MacroLoad: [" idx "] name='" m.name "' type=" m.type " hk=" m.hotkey)
            if (m.name = "" || m.type = "")
                continue
            if (m.type = "recorded") {
                m.speedMult := Float(IniRead(configFile, sec, "SpeedMult", "1.0"))
                m.loopEnabled := Integer(IniRead(configFile, sec, "Loop", "0"))
                evtCount := Integer(IniRead(configFile, sec, "EventCount", "0"))
                m.events := []
                loop evtCount {
                    raw := IniRead(configFile, sec, "E" A_Index, "")
                    if (raw = "")
                        continue
                    parts := StrSplit(raw, "|")
                    evt := {}
                    evt.type := parts[1]
                    if (evt.type = "K") {
                        evt.dir := parts[2]
                        evt.key := parts[3]
                        evt.delay := Integer(parts[4])
                    } else if (evt.type = "M") {
                        evt.x := Integer(parts[2])
                        evt.y := Integer(parts[3])
                        evt.delay := Integer(parts[4])
                    } else if (evt.type = "C") {
                        evt.dir := parts[2]
                        evt.btn := parts[3]
                        evt.x := Integer(parts[4])
                        evt.y := Integer(parts[5])
                        evt.delay := Integer(parts[6])
                    }
                    m.events.Push(evt)
                }
            } else if (m.type = "repeat") {
                keysRaw := IniRead(configFile, sec, "RepeatKeys", "")
                if (keysRaw = "")
                    keysRaw := IniRead(configFile, sec, "RepeatKey", "")
                m.repeatKeys := []
                for , part in StrSplit(keysRaw, ",")
                    if (Trim(part) != "")
                        m.repeatKeys.Push(Trim(part))
                m.repeatInterval := Integer(IniRead(configFile, sec, "RepeatInterval", "1000"))
                m.repeatSpam := Integer(IniRead(configFile, sec, "RepeatSpam", "0"))
                pcRaw := IniRead(configFile, sec, "PopcornFilters", "")
                m.popcornFilters := []
                if (pcRaw != "") {
                    for , part in StrSplit(pcRaw, "|")
                        m.popcornFilters.Push(Trim(part) = "<all>" ? "" : Trim(part))
                }
                m.popcornStyle := IniRead(configFile, sec, "PopcornStyle", "all")
                m.popcornDropCount := Integer(IniRead(configFile, sec, "PopcornDropCount", "0"))

            } else if (m.type = "pyro") {
                m.speedMult := Float(IniRead(configFile, sec, "SpeedMult", "1.0"))
            } else if (m.type = "guided") {
                m.speedMult := Float(IniRead(configFile, sec, "SpeedMult", "1.0"))
                m.loopEnabled := Integer(IniRead(configFile, sec, "Loop", "0"))
                m.invType := IniRead(configFile, sec, "InvType", "storage")
                m.mouseSpeed := Integer(IniRead(configFile, sec, "MouseSpeed", "0"))
                m.mouseSettle := Integer(IniRead(configFile, sec, "MouseSettle", "30"))
                m.invLoadDelay := Integer(IniRead(configFile, sec, "InvLoadDelay", "1500"))
                m.turbo := Integer(IniRead(configFile, sec, "Turbo", "0"))
                m.turboDelay := Integer(IniRead(configFile, sec, "TurboDelay", "30"))
                m.playerSearch := Integer(IniRead(configFile, sec, "PlayerSearch", "0"))
                m.popcornAll := Integer(IniRead(configFile, sec, "PopcornAll", "0"))
                filterRaw := IniRead(configFile, sec, "SearchFilters", "")
                m.searchFilters := []
                if (filterRaw != "") {
                    for , part in StrSplit(filterRaw, "|")
                        if (Trim(part) != "")
                            m.searchFilters.Push(Trim(part))
                }
                gAction := IniRead(configFile, sec, "GuidedAction", "")
                if (gAction != "") {
                    m.guidedAction := gAction
                    m.guidedKey := IniRead(configFile, sec, "GuidedKey", "g")
                    m.guidedCount := Integer(IniRead(configFile, sec, "GuidedCount", "0"))
                    m.events := RebuildGuidedEvents(gAction, m.guidedCount, m.guidedKey)
                } else {
                    m.guidedAction := ""
                    m.guidedKey := ""
                    m.guidedCount := 0
                    evtCount := Integer(IniRead(configFile, sec, "EventCount", "0"))
                    m.events := []
                    loop evtCount {
                        raw := IniRead(configFile, sec, "E" A_Index, "")
                        if (raw = "")
                            continue
                        parts := StrSplit(raw, "|")
                        evt := {}
                        evt.type := parts[1]
                        if (evt.type = "K") {
                            evt.dir := parts[2]
                            evt.key := parts[3]
                            evt.delay := Integer(parts[4])
                        } else if (evt.type = "M") {
                            evt.x := Integer(parts[2])
                            evt.y := Integer(parts[3])
                            evt.delay := Integer(parts[4])
                        } else if (evt.type = "C") {
                            evt.dir := parts[2]
                            evt.btn := parts[3]
                            evt.x := Integer(parts[4])
                            evt.y := Integer(parts[5])
                            evt.delay := Integer(parts[6])
                        }
                        m.events.Push(evt)
                    }
                }
            } else if (m.type = "combo") {
                pcRaw := IniRead(configFile, sec, "PopcornFilters", "")
                m.popcornFilters := []
                if (pcRaw != "") {
                    for , part in StrSplit(pcRaw, "|")
                        m.popcornFilters.Push(Trim(part) = "<all>" ? "" : Trim(part))
                }
                mfRaw := IniRead(configFile, sec, "MagicFFilters", "")
                m.magicFFilters := []
                if (mfRaw != "") {
                    for , part in StrSplit(mfRaw, "|")
                        if (Trim(part) != "")
                            m.magicFFilters.Push(Trim(part))
                }
                m.takeCount := Integer(IniRead(configFile, sec, "TakeCount", "0"))
                m.takeFilter := IniRead(configFile, sec, "TakeFilter", "")
            }
            macroList.Push(m)
            MacroLog("MacroLoad: [" idx "] '" m.name "' loaded OK")
        } catch as loadErr {
            MacroLog("MacroLoad: ERROR loading Macro_" idx " '" (IsSet(m) && m.HasProp("name") ? m.name : "?") "' type=" (IsSet(m) && m.HasProp("type") ? m.type : "?") " — " loadErr.Message)
        }
    }
    MacroEnsureDefaults()
    if (FileExist(legacyFile)) {
        MacroSaveAll()
        try FileDelete(legacyFile)
        MacroLog("MacroLoad: migrated to AIO_config.ini, deleted AIO_macros.ini")
    }
    MacroUpdateListView()
}

MacroEnsureDefaults() {
    global macroList
    global pcStartSlotX, pcStartSlotY, pcSlotW, pcSlotH, pcColumns
    hasPyro := false, hasYuty := false, hasCapFlak := false
    for , m in macroList {
        if (m.type = "pyro")
            hasPyro := true
        if (m.type = "repeat" && InStr(m.name, "Yuty"))
            hasYuty := true
        if (m.type = "guided" && InStr(m.name, "Cap of flak"))
            hasCapFlak := true
    }
    changed := false
    if (!hasPyro) {
        m := {}
        m.name := "Pyro"
        m.type := "pyro"
        m.hotkey := "r"
        m.speedMult := 1.0
        macroList.Push(m)
        changed := true
    }
    if (!hasYuty) {
        m := {}
        m.name := "Yuty Fear/Buff"
        m.type := "repeat"
        m.hotkey := "x"
        m.repeatKeys := ["RButton", "c"]
        m.repeatInterval := 0
        m.repeatSpam := 1
        macroList.Push(m)
        changed := true
    }
    if (!hasCapFlak) {
        slotCount := 60
        dropKey := "g"
        events := []
        gridSize := pcColumns * 6
        remaining := slotCount
        while (remaining > 0) {
            slot := 0
            Loop 6 {
                row := A_Index - 1
                Loop pcColumns {
                    col := A_Index - 1
                    slot++
                    if (slot > remaining || slot > gridSize)
                        break
                    x := pcStartSlotX + col * pcSlotW
                    y := pcStartSlotY + row * pcSlotH
                    events.Push({type: "M", x: x, y: y, delay: 0})
                    events.Push({type: "K", dir: "p", key: dropKey, delay: 20})
                }
                if (slot > remaining || slot > gridSize)
                    break
            }
            remaining -= Min(slot, gridSize)
        }
        m := {}
        m.name := "Cap of flak"
        m.type := "guided"
        m.hotkey := "f"
        m.speedMult := 1.0
        m.loopEnabled := true
        m.invType := "storage"
        m.mouseSpeed := 0
        m.mouseSettle := 1
        m.invLoadDelay := 1500
        m.turbo := 1
        m.turboDelay := 1
        m.playerSearch := 0
        m.searchFilters := []
        m.events := events
        macroList.Push(m)
        changed := true
    }
    if (changed)
        MacroSaveAll()
}

MacroSaveAll() {
    global macroList
    configFile := A_ScriptDir "\AIO_config.ini"
    try {
        oldCount := Integer(IniRead(configFile, "MacroCount", "Count", "0"))
    } catch {
        oldCount := 0
    }
    Loop oldCount {
        try IniDelete(configFile, "Macro_" A_Index)
    }
    try IniDelete(configFile, "MacroCount")
    IniWrite(macroList.Length, configFile, "MacroCount", "Count")
    IniWrite(macroSelectedIdx, configFile, "MacroCount", "Selected")
    for i, m in macroList {
        sec := "Macro_" i
        IniWrite(m.name, configFile, sec, "Name")
        IniWrite(m.type, configFile, sec, "Type")
        IniWrite(m.hotkey, configFile, sec, "Hotkey")
        if (m.type = "recorded") {
            IniWrite(Format("{:.3f}", m.speedMult), configFile, sec, "SpeedMult")
            IniWrite(m.loopEnabled ? 1 : 0, configFile, sec, "Loop")
            IniWrite(m.events.Length, configFile, sec, "EventCount")
            for j, evt in m.events {
                if (evt.type = "K")
                    IniWrite(evt.type "|" evt.dir "|" evt.key "|" evt.delay, configFile, sec, "E" j)
                else if (evt.type = "M")
                    IniWrite(evt.type "|" evt.x "|" evt.y "|" evt.delay, configFile, sec, "E" j)
                else if (evt.type = "C")
                    IniWrite(evt.type "|" evt.dir "|" evt.btn "|" evt.x "|" evt.y "|" evt.delay, configFile, sec, "E" j)
            }
        } else if (m.type = "repeat") {
            keysStr := ""
            for ki, kv in m.repeatKeys
                keysStr .= (ki > 1 ? "," : "") kv
            IniWrite(keysStr, configFile, sec, "RepeatKeys")
            IniWrite(m.repeatInterval, configFile, sec, "RepeatInterval")
            IniWrite(m.repeatSpam ? 1 : 0, configFile, sec, "RepeatSpam")
            if (m.HasProp("popcornFilters") && m.popcornFilters.Length > 0) {
                pcParts := []
                for , pf in m.popcornFilters
                    pcParts.Push(pf = "" ? "<all>" : pf)
                pcStr := ""
                for i, p in pcParts
                    pcStr .= (i > 1 ? "|" : "") p
                IniWrite(pcStr, configFile, sec, "PopcornFilters")
            }
            if (m.HasProp("popcornStyle"))
                IniWrite(m.popcornStyle, configFile, sec, "PopcornStyle")
            if (m.HasProp("popcornDropCount"))
                IniWrite(m.popcornDropCount, configFile, sec, "PopcornDropCount")

        } else if (m.type = "pyro") {
            IniWrite(Format("{:.3f}", m.speedMult), configFile, sec, "SpeedMult")
        } else if (m.type = "guided") {
            IniWrite(Format("{:.3f}", m.speedMult), configFile, sec, "SpeedMult")
            IniWrite(m.loopEnabled ? 1 : 0, configFile, sec, "Loop")
            IniWrite(m.HasProp("invType") ? m.invType : "storage", configFile, sec, "InvType")
            IniWrite(m.HasProp("mouseSpeed") ? m.mouseSpeed : 0, configFile, sec, "MouseSpeed")
            IniWrite(m.HasProp("mouseSettle") ? m.mouseSettle : 30, configFile, sec, "MouseSettle")
            IniWrite(m.HasProp("invLoadDelay") ? m.invLoadDelay : 1500, configFile, sec, "InvLoadDelay")
            IniWrite(m.HasProp("turbo") ? m.turbo : 0, configFile, sec, "Turbo")
            IniWrite(m.HasProp("turboDelay") ? m.turboDelay : 30, configFile, sec, "TurboDelay")
            IniWrite(m.HasProp("playerSearch") ? m.playerSearch : 0, configFile, sec, "PlayerSearch")
            IniWrite(m.HasProp("popcornAll") ? m.popcornAll : 0, configFile, sec, "PopcornAll")
            filterStr := ""
            if (m.HasProp("searchFilters")) {
                for fi, fv in m.searchFilters
                    filterStr .= (fi > 1 ? "|" : "") fv
            }
            IniWrite(filterStr, configFile, sec, "SearchFilters")
            if (m.HasProp("guidedAction") && m.guidedAction != "") {
                IniWrite(m.guidedAction, configFile, sec, "GuidedAction")
                IniWrite(m.guidedKey, configFile, sec, "GuidedKey")
                IniWrite(m.guidedCount, configFile, sec, "GuidedCount")
            } else {
                IniWrite(m.events.Length, configFile, sec, "EventCount")
                for j, evt in m.events {
                    if (evt.type = "K")
                        IniWrite(evt.type "|" evt.dir "|" evt.key "|" evt.delay, configFile, sec, "E" j)
                    else if (evt.type = "M")
                        IniWrite(evt.type "|" evt.x "|" evt.y "|" evt.delay, configFile, sec, "E" j)
                    else if (evt.type = "C")
                        IniWrite(evt.type "|" evt.dir "|" evt.btn "|" evt.x "|" evt.y "|" evt.delay, configFile, sec, "E" j)
                }
            }
        } else if (m.type = "combo") {
            pcStr := ""
            if (m.HasProp("popcornFilters")) {
                for fi, fv in m.popcornFilters
                    pcStr .= (fi > 1 ? "|" : "") (fv = "" ? "<all>" : fv)
            }
            IniWrite(pcStr, configFile, sec, "PopcornFilters")
            mfStr := ""
            if (m.HasProp("magicFFilters")) {
                for fi, fv in m.magicFFilters
                    mfStr .= (fi > 1 ? "|" : "") fv
            }
            IniWrite(mfStr, configFile, sec, "MagicFFilters")
            IniWrite(m.HasProp("takeCount") ? m.takeCount : 0, configFile, sec, "TakeCount")
            IniWrite(m.HasProp("takeFilter") ? m.takeFilter : "", configFile, sec, "TakeFilter")
        }
    }
}

MacroUpdateListView() {
    global macroLV, macroList, macroSelectedIdx
    macroLV.Delete()
    if (macroSelectedIdx < 1 && macroList.Length > 0)
        global macroSelectedIdx := 1
    if (macroSelectedIdx > macroList.Length && macroList.Length > 0)
        global macroSelectedIdx := macroList.Length
    for i, m in macroList {
        arrow := (i = macroSelectedIdx) ? "► " : "   "
        typeStr := m.type = "recorded" ? "Recorded" : m.type = "repeat" ? "Repeat" : m.type = "pyro" ? "Pyro" : m.type = "guided" ? "Guided" : m.type = "combo" ? "Combo" : m.type
        keyStr := m.hotkey != "" ? "[" StrUpper(m.hotkey) "]" : ""
        if (m.type = "recorded" || m.type = "guided") {
            speedStr := Format("{:.1f}x", m.speedMult) . (m.loopEnabled ? " Loop" : "")
            if (m.type = "guided" && m.HasProp("turbo") && m.turbo) {
                hasClicks := false
                dropKey := ""
                if (m.HasProp("events")) {
                    for , evt in m.events {
                        if (evt.type = "C")
                            hasClicks := true
                        if (evt.type = "K" && evt.dir = "p" && dropKey = "")
                            dropKey := evt.key
                    }
                }
                if (hasClicks && m.HasProp("playerSearch") && m.playerSearch)
                    speedStr .= " Give"
                else if (hasClicks)
                    speedStr .= " Take"
                else if (dropKey != "")
                    speedStr .= " Drop(" StrUpper(dropKey) ")"
                else
                    speedStr .= " Turbo"
            }
        }
        else if (m.type = "pyro")
            speedStr := Format("{:.1f}x", m.speedMult)
        else if (m.type = "combo") {
            pCount := m.HasProp("popcornFilters") ? m.popcornFilters.Length : 0
            mfCount := m.HasProp("magicFFilters") ? m.magicFFilters.Length : 0
            speedStr := "P:" pCount " M:" mfCount
        } else if (m.type = "repeat") {
            if ((m.HasProp("repeatSpam") && m.repeatSpam) || (m.HasProp("repeatInterval") && m.repeatInterval = 0))
                speedStr := "Hold"
            else if (m.HasProp("repeatInterval"))
                speedStr := Format("{:.1f}s", m.repeatInterval / 1000)
            else
                speedStr := "?"
            if (m.HasProp("repeatKeys") && m.repeatKeys.Length > 1)
                speedStr .= " (" m.repeatKeys.Length "keys)"
            if (m.HasProp("popcornFilters") && m.popcornFilters.Length > 0)
                speedStr .= " +PC"
        } else {
            speedStr := ""
        }
        macroLV.Add("", arrow m.name, typeStr, keyStr, speedStr)
    }
}

MacroLVClick(ctrl, row) {
    global macroSelectedIdx, macroTabActive, macroPlaying
    if (row < 1 || macroPlaying)
        return
    global macroSelectedIdx := row
    MacroRegisterHotkeys(macroTabActive)
}

MacroStartRecord(*) {
    global macroRecording, macroPlaying, macroRecordEvents, macroRecordLastTick
    global macroRecordLastMouseX, macroRecordLastMouseY, macroList
    global MainGui, guiVisible, arkwindow
    if (macroRecording || macroPlaying)
        return
    if (macroList.Length >= 10) {
        ToolTip(" Max 10 macros — delete one first", 0, 0)
        SetTimer(() => ToolTip(), -2000)
        return
    }
    macroRecordEvents := []
    CoordMode("Mouse", "Screen")
    MouseGetPos(&macroRecordLastMouseX, &macroRecordLastMouseY)
    macroRecording := true
    MainGui.Hide()
    global guiVisible := false
    if WinExist(arkwindow)
        WinActivate(arkwindow)
    Sleep(500)
    global macroRecordLastTick := A_TickCount
    MacroRecordSetHotkeys(true)
    SetTimer(MacroRecordMousePoll, 50)
    ToolTip(" RECORDING...  (0 events)`n F1 = Stop & Save", 0, 0)
}

MacroStopRecord() {
    global macroRecording, macroRecordEvents
    if (!macroRecording)
        return false
    global macroRecording := false
    MacroRecordSetHotkeys(false)
    SetTimer(MacroRecordMousePoll, 0)
    ToolTip()
    if (macroRecordEvents.Length = 0) {
        ToolTip(" Recording empty — discarded", 0, 0)
        SetTimer(() => ToolTip(), -2000)
        return true
    }
    MacroShowSaveDialog()
    return true
}

MacroRecordSetHotkeys(enable) {
    f := enable ? "On" : "Off"
    Loop 254 {
        if (A_Index = 112 || A_Index = 115)
            continue
        vk := Format("vk{:X}", A_Index)
        k := GetKeyName(vk)
        if (k != "" && !(k ~= "^(?i:|Control|Alt|Shift|LControl|RControl|LAlt|RAlt|LShift|RShift|LWin|RWin)$"))
            try Hotkey("~*" vk, MacroRecordLogKey, f)
    }
    for , k in StrSplit("NumpadEnter|Home|End|PgUp|PgDn|Left|Right|Up|Down|Delete|Insert", "|") {
        sc := Format("sc{:03X}", GetKeySC(k))
        try Hotkey("~*" sc, MacroRecordLogKey, f)
    }
}

MacroRecordLogKey(thisHotkey) {
    global macroRecording, macroRecordEvents, macroRecordLastTick
    if (!macroRecording)
        return
    Critical()
    vksc := SubStr(thisHotkey, 3)
    k := GetKeyName(vksc)
    if (k = "") {
        Critical("Off")
        return
    }
    k := StrReplace(k, "Control", "Ctrl")
    r := SubStr(k, 2)
    if (r ~= "^(?i:Alt|Ctrl|Shift|Win)$") {
        MacroRecordLogControl(k)
        Critical("Off")
        return
    }
    if (k ~= "^(?i:LButton|RButton|MButton)$") {
        MacroRecordLogMouse(k)
        Critical("Off")
        return
    }
    now := A_TickCount
    delay := now - macroRecordLastTick
    macroRecordLastTick := now
    evt := {}
    evt.type := "K"
    evt.dir := "p"
    evt.key := k
    evt.delay := delay
    macroRecordEvents.Push(evt)
    ToolTip(" RECORDING...  (" macroRecordEvents.Length " events)`n F1 = Stop & Save", 0, 0)
    Critical("Off")
}

MacroRecordLogControl(key) {
    global macroRecording, macroRecordEvents, macroRecordLastTick
    k := InStr(key, "Win") ? key : SubStr(key, 2)
    now := A_TickCount
    delay := now - macroRecordLastTick
    macroRecordLastTick := now
    evt := {}
    evt.type := "K"
    evt.dir := "d"
    evt.key := k
    evt.delay := delay
    macroRecordEvents.Push(evt)
    ToolTip(" RECORDING...  (" macroRecordEvents.Length " events)`n F1 = Stop & Save", 0, 0)
    Critical("Off")
    KeyWait(key)
    Critical()
    now2 := A_TickCount
    delay2 := now2 - macroRecordLastTick
    macroRecordLastTick := now2
    evt2 := {}
    evt2.type := "K"
    evt2.dir := "u"
    evt2.key := k
    evt2.delay := delay2
    macroRecordEvents.Push(evt2)
    ToolTip(" RECORDING...  (" macroRecordEvents.Length " events)`n F1 = Stop & Save", 0, 0)
}

MacroRecordLogMouse(key) {
    global macroRecording, macroRecordEvents, macroRecordLastTick
    global macroRecordLastMouseX, macroRecordLastMouseY
    btn := SubStr(key, 1, 1)
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx, &my)
    now := A_TickCount
    delay := now - macroRecordLastTick
    macroRecordLastTick := now
    macroRecordLastMouseX := mx
    macroRecordLastMouseY := my
    evt := {}
    evt.type := "C"
    evt.dir := "d"
    evt.btn := btn
    evt.x := mx
    evt.y := my
    evt.delay := delay
    macroRecordEvents.Push(evt)
    downIdx := macroRecordEvents.Length
    t1 := A_TickCount
    Critical("Off")
    KeyWait(key)
    Critical()
    t2 := A_TickCount
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx2, &my2)
    delay2 := t2 - macroRecordLastTick
    macroRecordLastTick := t2
    macroRecordLastMouseX := mx2
    macroRecordLastMouseY := my2
    if (Abs(mx2 - mx) + Abs(my2 - my) < 5) {
        if (downIdx <= macroRecordEvents.Length) {
            macroRecordEvents.RemoveAt(downIdx)
        }
        evt3 := {}
        evt3.type := "C"
        evt3.dir := "c"
        evt3.btn := btn
        evt3.x := mx
        evt3.y := my
        evt3.delay := delay
        macroRecordEvents.InsertAt(downIdx, evt3)
    } else {
        evt2 := {}
        evt2.type := "C"
        evt2.dir := "u"
        evt2.btn := btn
        evt2.x := mx2
        evt2.y := my2
        evt2.delay := delay2
        macroRecordEvents.Push(evt2)
    }
    ToolTip(" RECORDING...  (" macroRecordEvents.Length " events)`n F1 = Stop & Save", 0, 0)
}

MacroRecordMousePoll() {
    global macroRecording, macroRecordEvents, macroRecordLastTick
    global macroRecordLastMouseX, macroRecordLastMouseY
    if (!macroRecording)
        return
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx, &my)
    if (Abs(mx - macroRecordLastMouseX) + Abs(my - macroRecordLastMouseY) > 12) {
        now := A_TickCount
        delay := now - macroRecordLastTick
        macroRecordLastTick := now
        macroRecordLastMouseX := mx
        macroRecordLastMouseY := my
        evt := {}
        evt.type := "M"
        evt.x := mx
        evt.y := my
        evt.delay := delay
        macroRecordEvents.Push(evt)
    }
}

MacroShowSaveDialog() {
    global macroSaveGui, macroRecordEvents
    try {
        if (macroSaveGui != "")
            macroSaveGui.Destroy()
    }
    macroSaveGui := Gui("+AlwaysOnTop", "Save Macro")
    macroSaveGui.BackColor := "1A1A1A"
    macroSaveGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
    macroSaveGui.Add("Text", "x15 y15 w220", "Save Recorded Macro")
    macroSaveGui.SetFont("s9 cDDDDDD", "Segoe UI")
    macroSaveGui.Add("Text", "x15 y42 w55 h24 +0x200", "Name:")
    global macroNameEdit := macroSaveGui.Add("Edit", "x75 y42 w165 h24", "")
    macroNameEdit.SetFont("s9 c000000", "Segoe UI")
    macroSaveGui.Add("Text", "x15 y72 w55 h24 +0x200", "Hotkey:")
    global macroHkEdit := macroSaveGui.Add("Edit", "x75 y72 w100 h24 ReadOnly", "")
    macroHkEdit.SetFont("s9 c000000", "Segoe UI")
    macroHkDetect := DarkBtn(macroSaveGui, "x180 y72 w60 h24", "Detect", _RED_BGR, _DK_BG, -11, true)
    macroHkDetect.OnEvent("Click", MacroDetectSaveHotkey)
    global macroLoopChk := macroSaveGui.Add("CheckBox", "x15 y102 w80 h24", "Loop")
    macroLoopChk.SetFont("s9 cDDDDDD", "Segoe UI")
    evtCount := macroRecordEvents.Length
    macroSaveGui.SetFont("s8 c888888", "Segoe UI")
    macroSaveGui.Add("Text", "x100 y104 w140 h20", evtCount " events recorded")
    macroSaveBtn := DarkBtn(macroSaveGui, "x15 y132 w100 h26", "Save", _RED_BGR, _DK_BG, -12, true)
    macroSaveBtn.OnEvent("Click", MacroDoSaveRecorded)
    macroDiscardBtn := DarkBtn(macroSaveGui, "x120 y132 w100 h26", "Discard", 0xDDDDDD, _DK_BG, -12, false)
    macroDiscardBtn.OnEvent("Click", MacroDiscardRecording)
    macroSaveGui.OnEvent("Close", MacroDiscardRecording)
    macroSaveGui.Show("AutoSize " MacroPopupPos(350))
}

MacroDiscardRecording(*) {
    global macroSaveGui, macroRecordEvents
    try macroSaveGui.Destroy()
    global macroSaveGui := ""
    global macroRecordEvents := []
}

MacroDetectSaveHotkey(*) {
    global macroHkEdit, macroDetectedMouse
    macroHkEdit.Value := "press any key or click..."
    global macroDetectedMouse := ""
    MacroDetectStart()
    Sleep(300)
    try Hotkey("~*RButton", MacroDetectRMouse, "On")
    try Hotkey("~*LButton", MacroDetectLMouse, "On")
    try Hotkey("~*MButton", MacroDetectMMouse, "On")
    ih := InputHook("L1 T10")
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{F1}{F4}", "-E")
    ih.Start()
    deadline := A_TickCount + 10000
    while (ih.InProgress && macroDetectedMouse = "" && A_TickCount < deadline)
        Sleep(50)
    ih.Stop()
    try Hotkey("~*RButton", "Off")
    try Hotkey("~*LButton", "Off")
    try Hotkey("~*MButton", "Off")
    MacroDetectEnd()
    if (macroDetectedMouse != "")
        macroHkEdit.Value := StrLower(macroDetectedMouse)
    else if (ih.EndReason = "EndKey")
        macroHkEdit.Value := StrLower(ih.EndKey)
    else
        macroHkEdit.Value := ""
}

MacroDoSaveRecorded(*) {
    global macroSaveGui, macroRecordEvents, macroList, macroTabActive
    global macroNameEdit, macroHkEdit, macroLoopChk
    name := Trim(macroNameEdit.Value)
    hk := Trim(macroHkEdit.Value)
    if (name = "") {
        ToolTip("Enter a name!")
        SetTimer(() => ToolTip(), -1500)
        return
    }
    m := {}
    m.name := name
    m.type := "recorded"
    m.hotkey := (hk != "..." ? hk : "")
    m.speedMult := 1.0
    m.loopEnabled := macroLoopChk.Value
    m.events := []
    for , e in macroRecordEvents
        m.events.Push(e)
    macroList.Push(m)
    MacroSaveAll()
    MacroUpdateListView()
    try macroSaveGui.Destroy()
    global macroSaveGui := ""
    global macroRecordEvents := []
    MacroRegisterHotkeys(macroTabActive)
    ToolTip(" Macro '" name "' saved! (" m.events.Length " events)", 0, 0)
    SetTimer(() => ToolTip(), -2500)
}

MacroShowRepeatDialog(*) {
    global macroRepeatGui, macroList
    if (macroList.Length >= 10) {
        ToolTip(" Max 10 macros — delete one first", 0, 0)
        SetTimer(() => ToolTip(), -2000)
        return
    }
    try {
        if (macroRepeatGui != "")
            macroRepeatGui.Destroy()
    }
    macroRepeatGui := Gui("+AlwaysOnTop", "Key Repeat")
    macroRepeatGui.BackColor := "1A1A1A"
    px := 16
    y := 16
    macroRepeatGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
    macroRepeatGui.Add("Text", "x" px " y" y " w250", "Key Repeat")
    mrHelpBtn := DarkBtn(macroRepeatGui, "x300 y" (y - 2) " w24 h24", "?", _RED_BGR, _DK_BG, -11, true)
    mrHelpBtn.OnEvent("Click", MacroRepeatShowHelp)
    y += 30
    macroRepeatGui.SetFont("s9 cDDDDDD", "Segoe UI")
    macroRepeatGui.Add("Text", "x" px " y" y " w100 h24 +0x200", "Name:")
    global mrNameEdit := macroRepeatGui.Add("Edit", "x130 y" y " w190 h24", "")
    mrNameEdit.SetFont("s9 c000000", "Segoe UI")
    y += 30
    macroRepeatGui.Add("Text", "x" px " y" y " w100 h24 +0x200", "Keys:")
    global mrKeyEdit := macroRepeatGui.Add("Edit", "x130 y" y " w120 h24 ReadOnly", "")
    mrKeyEdit.SetFont("s9 c000000", "Segoe UI")
    mrKeyAdd := DarkBtn(macroRepeatGui, "x260 y" y " w35 h24", "Add", _RED_BGR, _DK_BG, -11, true)
    mrKeyAdd.OnEvent("Click", MacroDetectRepeatKey)
    mrKeyClear := DarkBtn(macroRepeatGui, "x298 y" y " w22 h24", "X", _RED_BGR, _DK_BG, -11, true)
    mrKeyClear.OnEvent("Click", MacroClearRepeatKeys)
    global mrKeyList := []
    y += 24
    macroRepeatGui.SetFont("s8 c888888 Italic", "Segoe UI")
    macroRepeatGui.Add("Text", "x130 y" y " w190 h14", "Q cycles between keys during play")
    y += 22
    macroRepeatGui.SetFont("s9 cDDDDDD", "Segoe UI")
    macroRepeatGui.Add("Text", "x" px " y" y " w110 h24 +0x200", "Interval (ms):")
    global mrIntervalEdit := macroRepeatGui.Add("Edit", "x130 y" y " w65 h24 +Number", "600")
    mrIntervalEdit.SetFont("s9 c000000", "Segoe UI")
    macroRepeatGui.SetFont("s8 c888888", "Segoe UI")
    macroRepeatGui.Add("Text", "x200 y" (y + 2) " w80 h20", "(0 = hold)")
    y += 30
    macroRepeatGui.SetFont("s9 cDDDDDD", "Segoe UI")
    macroRepeatGui.Add("Text", "x" px " y" y " w100 h24 +0x200", "Bind:")
    global mrBindEdit := macroRepeatGui.Add("Edit", "x130 y" y " w80 h24 ReadOnly", "")
    mrBindEdit.SetFont("s9 c000000", "Segoe UI")
    mrBindDetect := DarkBtn(macroRepeatGui, "x215 y" y " w60 h24", "Detect", _RED_BGR, _DK_BG, -11, true)
    mrBindDetect.OnEvent("Click", MacroDetectRepeatBind)
    y += 34
    macroRepeatGui.Add("Progress", "x" px " y" y " w318 h1 Background333333")
    y += 8
    global mrPcVar := 0
    global mrPcCheck := macroRepeatGui.Add("CheckBox", "x" px " y" y " w200 h24", "Popcorn after repeat")
    mrPcCheck.OnEvent("Click", MacroRepeatTogglePc)
    y += 26
    global mrPcFrameY := y
    macroRepeatGui.SetFont("s9 cDDDDDD", "Segoe UI")
    global mrPcDropLbl := macroRepeatGui.Add("Text", "x" (px + 16) " y" y " w100 h24 +0x200", "Drop count:")
    macroRepeatGui.SetFont("s9 c000000", "Segoe UI")
    global mrPcDropEdit := macroRepeatGui.Add("Edit", "x" (130 + 16) " y" y " w60 h24 +Number", "0")
    macroRepeatGui.SetFont("s8 c888888", "Segoe UI")
    global mrPcDropHint := macroRepeatGui.Add("Text", "x" (195 + 16) " y" (y + 2) " w80 h20", "(0 = all)")
    y += 28
    macroRepeatGui.SetFont("s9 cDDDDDD", "Segoe UI")
    global mrPcKeyLbl := macroRepeatGui.Add("Text", "x" (px + 16) " y" y " w100 h24 +0x200", "Drop key:")
    macroRepeatGui.SetFont("s9 Bold cFF4444", "Segoe UI")
    global mrPcKeyVal := macroRepeatGui.Add("Text", "x" (130 + 16) " y" y " w60 h24 +0x200", StrUpper(pcDropKey != "" ? pcDropKey : "?"))
    global mrSaveBtn := DarkBtn(macroRepeatGui, "x" px " y300 w100 h26", "Save", _RED_BGR, _DK_BG, -12, true)
    mrSaveBtn.OnEvent("Click", MacroDoSaveRepeat)
    global mrCancelBtn := DarkBtn(macroRepeatGui, "x200 y300 w100 h26", "Cancel", 0xDDDDDD, _DK_BG, -12, false)
    mrCancelBtn.OnEvent("Click", MacroRepeatCancel)
    macroRepeatGui.OnEvent("Close", MacroRepeatCancel)
    MacroRepeatTogglePc()
    macroRepeatGui.Show("w350 h340 " MacroPopupPos(350))
}



MacroRepeatTogglePc(*) {
    global mrPcCheck, mrPcDropLbl, mrPcDropEdit, mrPcDropHint, mrPcKeyLbl, mrPcKeyVal
    global mrSaveBtn, mrCancelBtn, mrPcFrameY, macroRepeatGui
    show := mrPcCheck.Value
    mrPcDropLbl.Visible := show
    mrPcDropEdit.Visible := show
    mrPcDropHint.Visible := show
    mrPcKeyLbl.Visible := show
    mrPcKeyVal.Visible := show
    if (show) {
        btnY := mrPcFrameY + 66
    } else {
        btnY := mrPcFrameY + 4
    }
    mrSaveBtn.Move(, btnY)
    mrCancelBtn.Move(, btnY)
    macroRepeatGui.Show("w350 h" (btnY + 42) " NoActivate")
}

MacroClearRepeatKeys(*) {
    global mrKeyList, mrKeyEdit
    mrKeyList := []
    mrKeyEdit.Value := ""
}

MacroRepeatCancel(*) {
    global macroRepeatGui
    try macroRepeatGui.Destroy()
    global macroRepeatGui := ""
}

MacroRepeatShowHelp(*) {
    static helpGui := ""
    if IsObject(helpGui) {
        try helpGui.Destroy()
        helpGui := ""
        return
    }
    helpGui := Gui("+AlwaysOnTop +ToolWindow", "Key Repeat Help")
    helpGui.BackColor := "1A1A1A"
    helpGui.SetFont("s9 Bold cFF4444", "Segoe UI")
    helpGui.Add("Text", "x10 y8 w260", "KEY REPEAT")
    helpGui.SetFont("s8 cDDDDDD", "Segoe UI")
    helpGui.Add("Text", "x10 y30 w260",
        "Name it, Add one or more keys.`n"
        "Set interval (ms) between presses.`n"
        "Spam = hold key. Move = walk between.`n"
        "Bind = activation key after arming.`n"
        "Q cycles keys. Z = next macro. F1 = stop.")
    helpGui.OnEvent("Close", (*) => (helpGui.Destroy(), helpGui := ""))
    helpGui.Show("w280 h120 " MacroPopupPos(280))
}

MacroDetectRepeatKey(*) {
    global mrKeyEdit, macroDetectedMouse, mrKeyList
    mrKeyEdit.Value := "press any key or click..."
    global macroDetectedMouse := ""
    MacroDetectStart()
    Sleep(300)
    try Hotkey("~*RButton", MacroDetectRMouse, "On")
    try Hotkey("~*LButton", MacroDetectLMouse, "On")
    try Hotkey("~*MButton", MacroDetectMMouse, "On")
    ih := InputHook("L1 T10")
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{F1}{F4}", "-E")
    ih.Start()
    deadline := A_TickCount + 10000
    while (ih.InProgress && macroDetectedMouse = "" && A_TickCount < deadline)
        Sleep(50)
    ih.Stop()
    try Hotkey("~*RButton", "Off")
    try Hotkey("~*LButton", "Off")
    try Hotkey("~*MButton", "Off")
    MacroDetectEnd()
    newKey := ""
    if (macroDetectedMouse != "")
        newKey := StrLower(macroDetectedMouse)
    else if (ih.EndReason = "EndKey")
        newKey := StrLower(ih.EndKey)
    if (newKey != "") {
        mrKeyList.Push(newKey)
        display := ""
        for i, k in mrKeyList
            display .= (i > 1 ? ", " : "") k
        mrKeyEdit.Value := display
    } else {
        display := ""
        for i, k in mrKeyList
            display .= (i > 1 ? ", " : "") k
        mrKeyEdit.Value := display
    }
}

global macroDetecting := false

MacroDetectStart() {
    global macroDetecting := true
    OnMessage(0x007B, MacroBlockContextMenu)
}

MacroDetectEnd() {
    global macroDetecting := false
    OnMessage(0x007B, MacroBlockContextMenu, 0)
}

MacroBlockContextMenu(wParam, lParam, msg, hwnd) {
    global macroDetecting
    if (macroDetecting)
        return 0
}

MacroDetectRMouse(*) {
    global macroDetectedMouse := "RButton"
}
MacroDetectLMouse(*) {
    global macroDetectedMouse := "LButton"
}
MacroDetectMMouse(*) {
    global macroDetectedMouse := "MButton"
}

MacroDetectRepeatBind(*) {
    global mrBindEdit, macroDetectedMouse
    mrBindEdit.Value := "press any key or click..."
    global macroDetectedMouse := ""
    MacroDetectStart()
    Sleep(300)
    try Hotkey("~*RButton", MacroDetectRMouse, "On")
    try Hotkey("~*LButton", MacroDetectLMouse, "On")
    try Hotkey("~*MButton", MacroDetectMMouse, "On")
    ih := InputHook("L1 T10")
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{F1}{F4}", "-E")
    ih.Start()
    deadline := A_TickCount + 10000
    while (ih.InProgress && macroDetectedMouse = "" && A_TickCount < deadline)
        Sleep(50)
    ih.Stop()
    try Hotkey("~*RButton", "Off")
    try Hotkey("~*LButton", "Off")
    try Hotkey("~*MButton", "Off")
    MacroDetectEnd()
    if (macroDetectedMouse != "")
        mrBindEdit.Value := StrLower(macroDetectedMouse)
    else if (ih.EndReason = "EndKey")
        mrBindEdit.Value := StrLower(ih.EndKey)
    else
        mrBindEdit.Value := ""
}

MacroDoSaveRepeat(*) {
    global macroRepeatGui, macroList, macroTabActive
    global mrNameEdit, mrKeyList, mrIntervalEdit, mrBindEdit, mrPcCheck, mrPcDropEdit
    name := Trim(mrNameEdit.Value)
    if (name = "" || mrKeyList.Length = 0) {
        ToolTip("Name and at least one key required!")
        SetTimer(() => ToolTip(), -1500)
        return
    }
    m := {}
    m.name := name
    m.type := "repeat"
    bindVal := Trim(mrBindEdit.Value)
    m.hotkey := (bindVal != "..." ? bindVal : "")
    m.repeatKeys := []
    for , k in mrKeyList
        m.repeatKeys.Push(k)
    m.repeatInterval := Integer(mrIntervalEdit.Value >= 0 ? mrIntervalEdit.Value : 600)
    m.repeatSpam := (m.repeatInterval = 0) ? 1 : 0
    if (mrPcCheck.Value) {
        dc := Integer(mrPcDropEdit.Value)
        m.popcornFilters := [""]
        m.popcornStyle := (dc = 0) ? "all" : "amount"
        m.popcornDropCount := dc
    } else {
        m.popcornFilters := []
        m.popcornStyle := "all"
        m.popcornDropCount := 0
    }
    try macroRepeatGui.Destroy()
    global macroRepeatGui := ""
    MacroRepeatFinalizeSave(m)
}

MacroRepeatFinalizeSave(m) {
    global macroList, macroTabActive
    macroList.Push(m)
    MacroSaveAll()
    MacroUpdateListView()
    MacroRegisterHotkeys(macroTabActive)
    keyStr := ""
    for i, k in m.repeatKeys
        keyStr .= (i > 1 ? ", " : "") k
    ToolTip(" Key Repeat '" m.name "' saved! [" keyStr "]", 0, 0)
    SetTimer(() => ToolTip(), -2000)
}

MacroPlaySelected(*) {
    global macroList, macroLV, macroPlaying, macroSelectedIdx, macroTabActive, macroArmed
    global MainGui, guiVisible, arkwindow
    if (macroPlaying)
        return
    if (macroSelectedIdx < 1 || macroSelectedIdx > macroList.Length) {
        ToolTip(" Select a macro first", 0, 0)
        SetTimer(() => ToolTip(), -1500)
        return
    }
    global macroArmed := true
    MacroRegisterHotkeys(true)
    MainGui.Hide()
    global guiVisible := false
    if WinExist(arkwindow)
        WinActivate(arkwindow)
    sel := macroList[macroSelectedIdx]
    keyStr := sel.hotkey != "" ? " [" StrUpper(sel.hotkey) "]" : ""
    MacroLog("PlaySelected: armed '" sel.name "' type=" sel.type " hk=" sel.hotkey)
    if (sel.type = "guided") {
        MacroLog("PlaySelected: launching guided thread immediately")
        MacroPlayByIndex(macroSelectedIdx)
    } else if (sel.type = "combo") {
        MacroLog("PlaySelected: launching combo thread immediately")
        MacroPlayByIndex(macroSelectedIdx)
    } else {
        pcHint := (sel.HasProp("popcornFilters") && sel.popcornFilters.Length > 0) ? "`n F = popcorn" : ""
        if (pcHint != "")
            MacroArmPopcornF(macroSelectedIdx)
        ToolTip(" ► " sel.name " armed" keyStr "`n" MacroSpeedHint(sel) pcHint "`n Tap to run  |  Hold for game  |  Z = next  |  F1 = disarm", 0, 0)
    }
}

MacroPlayByIndex(idx) {
    global macroList, macroPlaying, macroActiveIdx, macroSelectedIdx
    global MainGui, guiVisible, arkwindow
    if (macroPlaying || idx < 1 || idx > macroList.Length)
        return
    global macroSelectedIdx := idx
    global macroPlaying := true
    global macroActiveIdx := idx
    MacroDisarmPopcornF()
    m := macroList[idx]
    bgClick := (m.type = "repeat" && m.repeatKeys.Length = 1
                && m.repeatKeys[1] = "lbutton")
    MainGui.Hide()
    global guiVisible := false
    if (!bgClick) {
        if WinExist(arkwindow)
            WinActivate(arkwindow)
        Sleep(200)
    }
    if (m.type = "recorded")
        SetTimer(MacroPlayRecordedThread.Bind(m), -1)
    else if (m.type = "repeat")
        SetTimer(MacroPlayRepeatThread.Bind(m), -1)
    else if (m.type = "pyro")
        SetTimer(MacroPlayPyroThread.Bind(m), -1)
    else if (m.type = "guided")
        SetTimer(GuidedPlayThread.Bind(m), -1)
    else if (m.type = "combo")
        SetTimer(ComboPlayThread.Bind(m), -1)
}

MacroPlayRecordedThread(m) {
    global macroPlaying, macroActiveIdx
    myIdx := macroActiveIdx
    CoordMode("Mouse", "Screen")
    loopCount := 0
    loop {
        loopCount++
        loopStr := m.loopEnabled ? "  (loop " loopCount ")" : ""
        macroTT := " Playing: " m.name loopStr "`n" MacroSpeedHint(m) "`n Z = next macro  |  F1 = Stop"
        ToolTip(macroTT, 0, 0)
        for , evt in m.events {
            if (!macroPlaying) {
                ToolTip()
                return
            }
            scaledDelay := Integer(evt.delay * m.speedMult)
            if (scaledDelay > 0) {
                Sleep(scaledDelay)
                ToolTip(macroTT, 0, 0)
            }
            if (!macroPlaying) {
                ToolTip()
                return
            }
            switch evt.type {
                case "K":
                    switch evt.dir {
                        case "p":
                            kName := StrLen(evt.key) > 1 ? "{" evt.key "}" : evt.key
                            Send(kName)
                        case "d":
                            Send("{" evt.key " Down}")
                        case "u":
                            Send("{" evt.key " Up}")
                    }
                case "M":
                    MouseMove(evt.x, evt.y, 0)
                case "C":
                    switch evt.dir {
                        case "c":
                            MouseMove(evt.x, evt.y, 0)
                            Sleep(5)
                            Click(evt.btn)
                        case "d":
                            MouseMove(evt.x, evt.y, 0)
                            Sleep(5)
                            Click(evt.btn " Down")
                        case "u":
                            MouseMove(evt.x, evt.y, 0)
                            Sleep(5)
                            Click(evt.btn " Up")
                    }
            }
        }
        if (!m.loopEnabled)
            break
        if (!macroPlaying)
            break
    }
    if (macroActiveIdx = myIdx) {
        global macroPlaying := false
        global macroActiveIdx := 0
        MacroSaveIfDirty()
        ToolTip(" " m.name " done`n" MacroSpeedHint(m) "`n " StrUpper(m.hotkey) " = run again  |  Z = next macro  |  F1 = disarm", 0, 0)
    }
}

MacroPlayRepeatThread(m) {
    global macroPlaying, macroActiveIdx, macroRepeatKeyIdx, arkwindow
    global MainGui, guiVisible
    myIdx := macroActiveIdx
    global macroRepeatKeyIdx := 1
    keys := m.repeatKeys
    if (keys.Length = 0) {
        global macroPlaying := false
        global macroActiveIdx := 0
        MacroSaveIfDirty()
        return
    }
    curKey := keys[macroRepeatKeyIdx]
    bgMode := (keys.Length = 1 && keys[1] = "lbutton")

    ; ── BG left-click ──────────────────────────────────
    hasPc := m.HasProp("popcornFilters") && m.popcornFilters.Length > 0
    if (bgMode) {
        bgInterval := m.repeatInterval
        MacroBgClickTooltip(m, bgInterval, m.repeatSpam)
        try Hotkey("$[", MacroBgClickFaster, "On")
        try Hotkey("$]", MacroBgClickSlower, "On")
        global _macroBgInterval := bgInterval

        if (m.repeatSpam) {
            while (macroPlaying) {
                if WinExist(arkwindow) {
                    SetControlDelay(-1)
                    ControlClick("x1 y1", arkwindow,,,,"Pos")
                }
                Sleep(16)
            }
        } else {
            while (macroPlaying) {
                bgInterval := _macroBgInterval
                remaining := bgInterval
                while (remaining > 0 && macroPlaying) {
                    secs := Format("{:.1f}", remaining / 1000)
                    ToolTip(" BG Left Click: " m.name " in " secs "s`n Z = next macro  |  F1 = Stop", 0, 0)
                    step := Min(remaining, 100)
                    Sleep(step)
                    remaining -= step
                }
                if (!macroPlaying)
                    break
                if WinExist(arkwindow) {
                    SetControlDelay(-1)
                    ControlClick("x1 y1", arkwindow,,,,"Pos")
                }

                Sleep(50)
            }
        }

        try Hotkey("$[", "Off")
        try Hotkey("$]", "Off")
        if (macroActiveIdx = myIdx) {
            global macroPlaying := false
            global macroActiveIdx := 0
            MacroSaveIfDirty()
        }
        if (!macroArmed) {
            ToolTip()
            if (!guiVisible) {
                MainGui.Show("NoActivate")
                global guiVisible := true
            }
        }
        return
    }

    ; ── Normal (foreground) ─────────────────────
    hasPc := m.HasProp("popcornFilters") && m.popcornFilters.Length > 0
    if (m.repeatSpam) {
        MacroRepeatBuildTooltip(m, curKey)
        spamTick := 0
        while (macroPlaying) {
            if (macroRepeatKeyIdx > keys.Length)
                global macroRepeatKeyIdx := 1
            curKey := keys[macroRepeatKeyIdx]
            if WinActive(arkwindow) {
                if (curKey = "lbutton")
                    Click("Left")
                else if (curKey = "rbutton")
                    Click("Right")
                else if (curKey = "mbutton")
                    Click("Middle")
                else
                    Send("{" curKey "}")
            }
            spamTick++
            if (hasPc && GetKeyState("f", "P")) {
                while (GetKeyState("f", "P") && macroPlaying)
                    Sleep(50)
                MacroLog("RepeatPlay: F pressed — pausing for popcorn")
                MacroRepeatPopcornSequence(m)
            }
            if (Mod(spamTick, 125) = 0)
                MacroRepeatBuildTooltip(m, curKey)
            Sleep(16)
        }
    } else {
        while (macroPlaying) {
            if (macroRepeatKeyIdx > keys.Length)
                global macroRepeatKeyIdx := 1
            curKey := keys[macroRepeatKeyIdx]
            remaining := m.repeatInterval
            while (remaining > 0 && macroPlaying) {
                curKey := keys[macroRepeatKeyIdx]
                secs := Format("{:.1f}", remaining / 1000)
                moveHint := ""
                qHint := keys.Length > 1 ? "`n Q = next key" : ""
                ToolTip(" " m.name ": " curKey " in " secs "s" moveHint qHint "`n" MacroSpeedHint(m) "`n Z = next macro  |  F1 = Stop", 0, 0)
                step := Min(remaining, 100)
                Sleep(step)
                remaining -= step
            }
            if (!macroPlaying)
                break
            curKey := keys[macroRepeatKeyIdx]
            if WinActive(arkwindow) {
                if (curKey = "lbutton")
                    Click("Left")
                else if (curKey = "rbutton")
                    Click("Right")
                else if (curKey = "mbutton")
                    Click("Middle")
                else
                    Send("{" curKey "}")
            }
            if (hasPc && GetKeyState("f", "P")) {
                while (GetKeyState("f", "P") && macroPlaying)
                    Sleep(50)
                MacroLog("RepeatPlay: F pressed — pausing for popcorn")
                MacroRepeatPopcornSequence(m)
            }

            Sleep(50)
        }
    }
    if (macroActiveIdx = myIdx) {
        global macroPlaying := false
        global macroActiveIdx := 0
        MacroSaveIfDirty()
    }
    ToolTip()
}

MacroRepeatBuildTooltip(m, curKey) {
    global macroRepeatKeyIdx
    keys := m.repeatKeys
    qHint := keys.Length > 1 ? "`n Q = next key" : ""
    keyList := ""
    for i, k in keys {
        arrow := (i = macroRepeatKeyIdx) ? " ► " : "   "
        keyList .= "`n" arrow k
    }
    ToolTip(" Hold: " curKey keyList qHint "`n" MacroSpeedHint(m) "`n Z = next macro  |  F1 = Stop", 0, 0)
}

MacroBgClickTooltip(m, intervalMs, isSpam) {
    mode := isSpam ? "Hold" : "Interval: " intervalMs "ms"
    ToolTip(" BG Left Click: " m.name "  (" mode ")`n Z = next macro  |  F1 = Stop", 0, 0)
}

MacroBgClickSlower(thisHotkey) {
    global _macroBgInterval, autoclickIntervalStep
    global _macroBgInterval := _macroBgInterval + autoclickIntervalStep
}

MacroBgClickFaster(thisHotkey) {
    global _macroBgInterval, autoclickIntervalStep, autoclickMinInterval
    global _macroBgInterval := Max(autoclickMinInterval, _macroBgInterval - autoclickIntervalStep)
}

MacroArmPopcornF(idx) {
    global macroPopcornArmed, macroPopcornMacro, macroList
    global macroPopcornArmed := true
    global macroPopcornMacro := macroList[idx]
    try Hotkey("$f", MacroPopcornFHandler, "On")
    MacroLog("PopcornF: armed for '" macroList[idx].name "'")
}

MacroDisarmPopcornF() {
    global macroPopcornArmed, macroPopcornMacro
    global macroPopcornArmed := false
    global macroPopcornMacro := ""
    try Hotkey("$f", "Off")
}

MacroPopcornFHandler(*) {
    global macroPopcornArmed, macroPopcornMacro, macroPlaying, macroArmed, arkwindow
    if (!macroPopcornArmed || macroPlaying || !macroArmed)
        return
    if (!WinActive(arkwindow)) {
        Send("{f}")
        return
    }
    m := macroPopcornMacro
    if (!IsObject(m)) {
        MacroLog("PopcornF: no macro object — disarming")
        MacroDisarmPopcornF()
        return
    }
    MacroLog("PopcornF: F pressed — running popcorn for '" m.name "'")
    MacroDisarmPopcornF()
    SetTimer(MacroPopcornFThread.Bind(m), -1)
}

MacroPopcornFThread(m) {
    global arkwindow, macroArmed, macroSelectedIdx, macroList
    Send("{f}")
    Sleep(200)
    MacroRepeatPopcornSequence(m)
    if (macroArmed && macroSelectedIdx >= 1 && macroSelectedIdx <= macroList.Length) {
        sel := macroList[macroSelectedIdx]
        if (sel.HasProp("popcornFilters") && sel.popcornFilters.Length > 0)
            MacroArmPopcornF(macroSelectedIdx)
        keyStr := sel.hotkey != "" ? " [" StrUpper(sel.hotkey) "]" : ""
        ToolTip(" ► " sel.name " armed" keyStr "`n" MacroSpeedHint(sel) "`n F = popcorn`n Tap to run  |  Z = next  |  F1 = disarm", 0, 0)
    }
}

MacroRepeatPopcornSequence(m) {
    global pcInvDetectX, pcInvDetectY, pcEarlyExit, pcF1Abort, arkwindow, macroArmed
    pcFilters := m.popcornFilters
    style := m.popcornStyle
    dropCount := (style = "amount") ? m.popcornDropCount : 0
    if (pcFilters.Length = 0)
        pcFilters := [""]
    MacroLog("RepeatPopcorn: starting — style=" style " filters=" pcFilters.Length " dropCount=" dropCount)

    deadline := A_TickCount + 5000
    invOpen := false
    while (A_TickCount < deadline) {
        try {
            if NFSearchTol(&fx, &fy, pcInvDetectX, pcInvDetectY, pcInvDetectX+2, pcInvDetectY+2, 0xFFFFFF, 10) {
                invOpen := true
                break
            }
        }
        Sleep(50)
    }
    if (!invOpen) {
        MacroLog("RepeatPopcorn: inventory never opened — aborting")
        return
    }
    Sleep(200)

    global pcEarlyExit := false
    global pcF1Abort := false

    for i, filt in pcFilters {
        if (pcEarlyExit || pcF1Abort || !macroArmed)
            break
        MacroLog("RepeatPopcorn: filter " i "/" pcFilters.Length " = '" (filt = "" ? "(all)" : filt) "'")
        if (filt != "")
            PcApplyFilter(filt)
        else if (pcFilters.Length > 1)
            PcClearFilter()
        Sleep(200)
        PcRunDropLoop("repeat-pop-" i, dropCount)
    }

    Send("{Escape}")
    Sleep(300)
    MacroLog("RepeatPopcorn: done — inventory closed")
}

MacroPlayPyroThread(m) {
    global macroPlaying, macroActiveIdx, arkwindow
    global pyroAstTekDetX, pyroAstTekDetY, pyroAstTekClkX, pyroAstTekClkY
    global pyroAstNoTekDetX, pyroAstNoTekDetY, pyroAstNoTekClkX, pyroAstNoTekClkY
    global pyroNonTekDetX, pyroNonTekDetY, pyroNonTekClkX, pyroNonTekClkY
    global pyroNonNoTekDetX, pyroNonNoTekDetY, pyroNonNoTekClkX, pyroNonNoTekClkY
    global pyroMountClickX, pyroMountClickY, pyroThrowCheckX, pyroThrowCheckY
    global pyroRideConfirmX, pyroRideConfirmY, pyroDismountX, pyroDismountY
    myIdx := macroActiveIdx
    CoordMode("Mouse", "Screen")
    CoordMode("Pixel", "Screen")
    sp := m.speedMult
    if !WinActive(arkwindow) {
        global macroPlaying := false
        global macroActiveIdx := 0
        MacroSaveIfDirty()
        return
    }
    try dismountCol := PxGet(pyroDismountX, pyroDismountY)
    catch
        dismountCol := ""
    isDismountR := (dismountCol = "0xD45F12")
    isDismountG := false
    if (!isDismountR) {
        r := (Integer("0x" SubStr(dismountCol, 3, 2)))
        g := (Integer("0x" SubStr(dismountCol, 5, 2)))
        b := (Integer("0x" SubStr(dismountCol, 7, 2)))
        isDismountG := (Abs(r - 0xD4) + Abs(g - 0x5F) + Abs(b - 0x12)) < 40
    }
    if (isDismountR || isDismountG) {
        ToolTip(" Pyro: Dismounting...`n Spamming Ctrl+C`n F1 = Stop", 0, 0)
        loop 200 {
            if (!macroPlaying || macroActiveIdx != myIdx) {
                ToolTip()
                return
            }
            if !WinActive(arkwindow)
                break
            Send("^c")
            Sleep(Integer(50 * sp))
            try checkCol := PxGet(pyroDismountX, pyroDismountY)
            catch
                checkCol := ""
            if (checkCol != "0xD45F12") {
                rc := Integer("0x" SubStr(checkCol, 3, 2))
                gc := Integer("0x" SubStr(checkCol, 5, 2))
                bc := Integer("0x" SubStr(checkCol, 7, 2))
                if ((Abs(rc - 0xD4) + Abs(gc - 0x5F) + Abs(bc - 0x12)) >= 40) {
                    ToolTip(" Pyro: Back on shoulder!`n R = mount  |  F1 = disarm", 0, 0)
                    break
                }
            }
        }
        if (macroActiveIdx = myIdx) {
            global macroPlaying := false
            global macroActiveIdx := 0
            MacroSaveIfDirty()
        }
        return
    }
    ToolTip(" Pyro: Mounting...`n Holding R for radial`n F1 = Stop", 0, 0)
    Send("{r Down}")
    Sleep(Integer(450 * sp))
    if (!macroPlaying || macroActiveIdx != myIdx) {
        Send("{r Up}")
        ToolTip()
        return
    }
    firstClickX := 0
    firstClickY := 0
    contextName := ""
    try {
        c1 := PxGet(pyroAstTekDetX, pyroAstTekDetY)
        if (c1 = "0xFFFFFF") {
            firstClickX := pyroAstTekClkX
            firstClickY := pyroAstTekClkY
            contextName := "Asteros + Tek"
        }
    }
    if (contextName = "") {
        try {
            c2 := PxGet(pyroAstNoTekDetX, pyroAstNoTekDetY)
            if (c2 = "0xFFFFFF") {
                firstClickX := pyroAstNoTekClkX
                firstClickY := pyroAstNoTekClkY
                contextName := "Asteros"
            }
        }
    }
    if (contextName = "") {
        try {
            c3 := PxGet(pyroNonTekDetX, pyroNonTekDetY)
            if (c3 = "0xFFFFFF") {
                firstClickX := pyroNonTekClkX
                firstClickY := pyroNonTekClkY
                contextName := "Tek Helm"
            }
        }
    }
    if (contextName = "") {
        try {
            c4 := PxGet(pyroNonNoTekDetX, pyroNonNoTekDetY)
            if (c4 = "0xFFFFFF") {
                firstClickX := pyroNonNoTekClkX
                firstClickY := pyroNonNoTekClkY
                contextName := "No Helm"
            }
        }
    }
    if (contextName = "") {
        ToolTip(" Pyro: No context detected — aborting`n R = retry  |  F1 = disarm", 0, 0)
        Send("{r Up}")
        if (macroActiveIdx = myIdx) {
            global macroPlaying := false
            global macroActiveIdx := 0
            MacroSaveIfDirty()
        }
        return
    }
    ToolTip(" Pyro: " contextName " detected`n Clicking first option...`n F1 = Stop", 0, 0)
    MouseMove(firstClickX, firstClickY, 0)
    Sleep(Integer(50 * sp))
    Click("Left")
    Sleep(Integer(150 * sp))
    if (!macroPlaying || macroActiveIdx != myIdx) {
        Send("{r Up}")
        ToolTip()
        return
    }
    try throwCol := PxGet(pyroThrowCheckX, pyroThrowCheckY)
    catch
        throwCol := ""
    if (throwCol = "0xFFFFFF") {
        ToolTip(" Pyro: THROW detected (enclosed space)`n Aborting — need more room!`n R = retry  |  F1 = disarm", 0, 0)
        Send("{r Up}")
        Sleep(500)
        if (macroActiveIdx = myIdx) {
            global macroPlaying := false
            global macroActiveIdx := 0
            MacroSaveIfDirty()
        }
        return
    }
    try rideCol := PxGet(pyroRideConfirmX, pyroRideConfirmY)
    catch
        rideCol := ""
    if (rideCol = "0xFFFFFF") {
        ToolTip(" Pyro: Ride confirmed! Mounting...`n F1 = Stop", 0, 0)
    }
    MouseMove(pyroMountClickX, pyroMountClickY, 0)
    Sleep(Integer(50 * sp))
    Click("Left")
    Sleep(Integer(100 * sp))
    Send("{r Up}")
    ToolTip(" Pyro: Mounted!`n R = dismount  |  F1 = disarm", 0, 0)
    if (macroActiveIdx = myIdx) {
        global macroPlaying := false
        global macroActiveIdx := 0
        MacroSaveIfDirty()
    }
}

MacroSaveIfDirty() {
    global macroSpeedDirty
    if (macroSpeedDirty) {
        MacroSaveAll()
        global macroSpeedDirty := false
    }
}

MacroStopPlay() {
    global macroPlaying, macroActiveIdx, macroList, macroArmed, comboRunning, macroSpeedDirty, macroPopcornArmed, macroPopcornMacro
    wasIdx := macroActiveIdx
    wasName := (wasIdx > 0 && wasIdx <= macroList.Length) ? macroList[wasIdx].name : "?"
    wasType := (wasIdx > 0 && wasIdx <= macroList.Length) ? macroList[wasIdx].type : "?"
    MacroLog("StopPlay: stopping '" wasName "' type=" wasType " idx=" wasIdx)
    global macroPlaying := false
    global macroActiveIdx := 0
    global macroArmed := false
    MacroDisarmPopcornF()
    if (comboRunning)
        global comboRunning := false
    if (wasIdx > 0 && wasIdx <= macroList.Length) {
        if (macroList[wasIdx].type = "pyro")
            Send("{r Up}")
    }
    ToolTip()
    MacroSaveIfDirty()
}

MacroDeleteSelected(*) {
    global macroList, macroLV, macroTabActive, macroSelectedIdx
    if (macroSelectedIdx < 1 || macroSelectedIdx > macroList.Length)
        return
    row := macroSelectedIdx
    m := macroList[row]
    if (m.type = "pyro") {
        ToolTip(" Can't delete built-in presets", 0, 0)
        SetTimer(() => ToolTip(), -1500)
        return
    }
    name := m.name
    result := MsgBox("Delete '" name "'?", "Delete Macro", "YesNo")
    if (result = "Yes") {
        MacroRegisterHotkeys(false)
        macroList.RemoveAt(row)
        if (macroSelectedIdx >= row && macroSelectedIdx > 1)
            global macroSelectedIdx := macroSelectedIdx - 1
        if (macroSelectedIdx > macroList.Length && macroList.Length > 0)
            global macroSelectedIdx := macroList.Length
        MacroSaveAll()
        MacroUpdateListView()
        MacroRegisterHotkeys(macroTabActive)
    }
}

MacroEditSelected(*) {
    global macroList, macroLV, macroPlaying, macroSelectedIdx
    if (macroPlaying)
        return
    if (macroSelectedIdx < 1 || macroSelectedIdx > macroList.Length) {
        ToolTip(" Select a macro first", 0, 0)
        SetTimer(() => ToolTip(), -1500)
        return
    }
    row := macroSelectedIdx
    m := macroList[row]
    if (m.type = "recorded")
        MacroShowEditRecorded(row)
    else if (m.type = "repeat")
        MacroShowEditRepeat(row)
    else if (m.type = "pyro")
        MacroShowEditRecorded(row)
    else if (m.type = "guided")
        GuidedShowEditDialog(row)
    else if (m.type = "combo")
        ComboShowEditDialog(row)
}

MacroShowEditRecorded(idx) {
    global macroList, macroEditGui
    m := macroList[idx]
    try {
        if (macroEditGui != "")
            macroEditGui.Destroy()
    }
    isPyro := (m.type = "pyro")
    titleStr := isPyro ? "Edit Pyro Preset" : "Edit Recorded Macro"
    global macroEditGui := Gui("+AlwaysOnTop", titleStr)
    macroEditGui.BackColor := "1A1A1A"
    macroEditGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
    macroEditGui.Add("Text", "x15 y15 w220", "Edit: " m.name)
    macroEditGui.SetFont("s9 cDDDDDD", "Segoe UI")
    macroEditGui.Add("Text", "x15 y42 w55 h24 +0x200", "Name:")
    global meNameEdit := macroEditGui.Add("Edit", "x75 y42 w165 h24", m.name)
    meNameEdit.SetFont("s9 c000000", "Segoe UI")
    macroEditGui.Add("Text", "x15 y72 w55 h24 +0x200", "Hotkey:")
    global meHkEdit := macroEditGui.Add("Edit", "x75 y72 w100 h24 ReadOnly", m.hotkey)
    meHkEdit.SetFont("s9 c000000", "Segoe UI")
    meHkDetect := DarkBtn(macroEditGui, "x180 y72 w35 h24", "Set", _RED_BGR, _DK_BG, -11, true)
    meHkDetect.OnEvent("Click", MacroEditDetectHk)
    meHkClear := DarkBtn(macroEditGui, "x218 y72 w22 h24", "X", _RED_BGR, _DK_BG, -11, true)
    meHkClear.OnEvent("Click", (*) => meHkEdit.Value := "")
    macroEditGui.Add("Text", "x15 y102 w55 h24 +0x200", "Speed:")
    global meSpeedEdit := macroEditGui.Add("Edit", "x75 y102 w65 h24", Format("{:.3f}", m.speedMult))
    meSpeedEdit.SetFont("s9 c000000", "Segoe UI")
    macroEditGui.SetFont("s8 cDDDDDD", "Segoe UI")
    macroEditGui.Add("Text", "x145 y102 w40 h24 +0x200", "x mult")
    macroEditGui.SetFont("s9 cDDDDDD", "Segoe UI")
    global meLoopChk := macroEditGui.Add("CheckBox", "x15 y130 w80 h24", "Loop")
    if (isPyro) {
        meLoopChk.Visible := false
        macroEditGui.SetFont("s8 c888888 Italic", "Segoe UI")
        macroEditGui.Add("Text", "x15 y132 w225 h20", "Built-in preset (pixel detection)")
    } else {
        meLoopChk.Value := m.loopEnabled
        macroEditGui.SetFont("s8 c888888", "Segoe UI")
        macroEditGui.Add("Text", "x100 y132 w140 h20", m.events.Length " events")
    }
    macroEditGui.SetFont("s9 cDDDDDD", "Segoe UI")
    meSaveBtn := DarkBtn(macroEditGui, "x15 y160 w100 h26", "Save", _RED_BGR, _DK_BG, -12, true)
    meSaveBtn.OnEvent("Click", MacroDoEditRecorded.Bind(idx))
    meCancelBtn := DarkBtn(macroEditGui, "x120 y160 w100 h26", "Cancel", 0xDDDDDD, _DK_BG, -12, false)
    meCancelBtn.OnEvent("Click", MacroEditCancel)
    macroEditGui.OnEvent("Close", MacroEditCancel)
    macroEditGui.Show("AutoSize " MacroPopupPos(350))
}

MacroEditDetectHk(*) {
    global meHkEdit
    meHkEdit.Value := "..."
    ih := InputHook("L1 T10")
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{F1}{F4}", "-E")
    ih.Start()
    ih.Wait()
    if (ih.EndReason = "EndKey")
        meHkEdit.Value := StrLower(ih.EndKey)
    else
        meHkEdit.Value := ""
}

MacroDoEditRecorded(idx, *) {
    global macroList, macroEditGui, macroTabActive
    global meNameEdit, meHkEdit, meSpeedEdit, meLoopChk
    m := macroList[idx]
    name := Trim(meNameEdit.Value)
    if (name = "") {
        ToolTip("Enter a name!")
        SetTimer(() => ToolTip(), -1500)
        return
    }
    MacroRegisterHotkeys(false)
    hk := Trim(meHkEdit.Value)
    m.name := name
    m.hotkey := (hk != "..." ? hk : "")
    try m.speedMult := Float(meSpeedEdit.Value)
    if (m.type != "pyro")
        m.loopEnabled := meLoopChk.Value
    macroList[idx] := m
    MacroSaveAll()
    MacroUpdateListView()
    MacroRegisterHotkeys(macroTabActive)
    try macroEditGui.Destroy()
    global macroEditGui := ""
    ToolTip(" '" name "' updated", 0, 0)
    SetTimer(() => ToolTip(), -2000)
}

MacroShowEditRepeat(idx) {
    global macroList, macroEditGui
    m := macroList[idx]
    try {
        if (macroEditGui != "")
            macroEditGui.Destroy()
    }
    global macroEditGui := Gui("+AlwaysOnTop", "Edit Key Repeat")
    macroEditGui.BackColor := "1A1A1A"
    px := 16
    y := 16
    macroEditGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
    macroEditGui.Add("Text", "x" px " y" y " w250", "Edit: " m.name)
    meHelpBtn := DarkBtn(macroEditGui, "x300 y" (y - 2) " w24 h24", "?", _RED_BGR, _DK_BG, -11, true)
    meHelpBtn.OnEvent("Click", MacroRepeatShowHelp)
    y += 30
    macroEditGui.SetFont("s9 cDDDDDD", "Segoe UI")
    macroEditGui.Add("Text", "x" px " y" y " w100 h24 +0x200", "Name:")
    global meNameEdit := macroEditGui.Add("Edit", "x130 y" y " w190 h24", m.name)
    meNameEdit.SetFont("s9 c000000", "Segoe UI")
    y += 30
    macroEditGui.Add("Text", "x" px " y" y " w100 h24 +0x200", "Keys:")
    global meKeyList := []
    for , k in m.repeatKeys
        meKeyList.Push(k)
    keyDisplay := ""
    for i, k in meKeyList
        keyDisplay .= (i > 1 ? ", " : "") k
    global meKeyEdit := macroEditGui.Add("Edit", "x130 y" y " w120 h24 ReadOnly", keyDisplay)
    meKeyEdit.SetFont("s9 c000000", "Segoe UI")
    meKeyAdd := DarkBtn(macroEditGui, "x260 y" y " w35 h24", "Add", _RED_BGR, _DK_BG, -11, true)
    meKeyAdd.OnEvent("Click", MacroEditDetectKey)
    meKeyClear := DarkBtn(macroEditGui, "x298 y" y " w22 h24", "X", _RED_BGR, _DK_BG, -11, true)
    meKeyClear.OnEvent("Click", MacroEditClearKeys)
    y += 24
    macroEditGui.SetFont("s8 c888888 Italic", "Segoe UI")
    macroEditGui.Add("Text", "x130 y" y " w190 h14", "Q cycles between keys during play")
    y += 22
    macroEditGui.SetFont("s9 cDDDDDD", "Segoe UI")
    macroEditGui.Add("Text", "x" px " y" y " w110 h24 +0x200", "Interval (ms):")
    _editInterval := (m.HasProp("repeatSpam") && m.repeatSpam) ? 0 : m.repeatInterval
    global meIntervalEdit := macroEditGui.Add("Edit", "x130 y" y " w65 h24 +Number", String(_editInterval))
    meIntervalEdit.SetFont("s9 c000000", "Segoe UI")
    macroEditGui.SetFont("s8 c888888", "Segoe UI")
    macroEditGui.Add("Text", "x200 y" (y + 2) " w80 h20", "(0 = hold)")
    y += 30
    macroEditGui.SetFont("s9 cDDDDDD", "Segoe UI")
    macroEditGui.Add("Text", "x" px " y" y " w100 h24 +0x200", "Bind:")
    global meBindEdit := macroEditGui.Add("Edit", "x130 y" y " w80 h24 ReadOnly", m.hotkey)
    meBindEdit.SetFont("s9 c000000", "Segoe UI")
    meBindDetect := DarkBtn(macroEditGui, "x215 y" y " w60 h24", "Set", _RED_BGR, _DK_BG, -11, true)
    meBindDetect.OnEvent("Click", MacroEditDetectBind)
    meBindClear := DarkBtn(macroEditGui, "x280 y" y " w22 h24", "X", _RED_BGR, _DK_BG, -11, true)
    meBindClear.OnEvent("Click", (*) => meBindEdit.Value := "")
    y += 34
    macroEditGui.Add("Progress", "x" px " y" y " w318 h1 Background333333")
    y += 8
    _hasPc := (m.HasProp("popcornFilters") && m.popcornFilters.Length > 0)
    global mePcVar := _hasPc ? 1 : 0
    global mePcCheck := macroEditGui.Add("CheckBox", "x" px " y" y " w200 h24", "Popcorn after repeat")
    mePcCheck.Value := _hasPc ? 1 : 0
    mePcCheck.OnEvent("Click", MacroEditRepeatTogglePc)
    y += 26
    global mePcFrameY := y
    macroEditGui.SetFont("s9 cDDDDDD", "Segoe UI")
    global mePcDropLbl := macroEditGui.Add("Text", "x" (px + 16) " y" y " w100 h24 +0x200", "Drop count:")
    macroEditGui.SetFont("s9 c000000", "Segoe UI")
    _dcVal := (m.HasProp("popcornDropCount")) ? String(m.popcornDropCount) : "0"
    global mePcDropEdit := macroEditGui.Add("Edit", "x" (130 + 16) " y" y " w60 h24 +Number", _dcVal)
    macroEditGui.SetFont("s8 c888888", "Segoe UI")
    global mePcDropHint := macroEditGui.Add("Text", "x" (195 + 16) " y" (y + 2) " w80 h20", "(0 = all)")
    y += 28
    macroEditGui.SetFont("s9 cDDDDDD", "Segoe UI")
    global mePcKeyLbl := macroEditGui.Add("Text", "x" (px + 16) " y" y " w100 h24 +0x200", "Drop key:")
    macroEditGui.SetFont("s9 Bold cFF4444", "Segoe UI")
    global mePcKeyVal := macroEditGui.Add("Text", "x" (130 + 16) " y" y " w60 h24 +0x200", StrUpper(pcDropKey != "" ? pcDropKey : "?"))
    global meSaveBtn := DarkBtn(macroEditGui, "x" px " y300 w100 h26", "Save", _RED_BGR, _DK_BG, -12, true)
    meSaveBtn.OnEvent("Click", MacroDoEditRepeat.Bind(idx))
    global meCancelBtn := DarkBtn(macroEditGui, "x200 y300 w100 h26", "Cancel", 0xDDDDDD, _DK_BG, -12, false)
    meCancelBtn.OnEvent("Click", MacroEditCancel)
    macroEditGui.OnEvent("Close", MacroEditCancel)
    MacroEditRepeatTogglePc()
    macroEditGui.Show("w350 h340 " MacroPopupPos(350))
}

MacroEditRepeatTogglePc(*) {
    global mePcCheck, mePcDropLbl, mePcDropEdit, mePcDropHint, mePcKeyLbl, mePcKeyVal
    global meSaveBtn, meCancelBtn, mePcFrameY, macroEditGui
    show := mePcCheck.Value
    mePcDropLbl.Visible := show
    mePcDropEdit.Visible := show
    mePcDropHint.Visible := show
    mePcKeyLbl.Visible := show
    mePcKeyVal.Visible := show
    if (show) {
        btnY := mePcFrameY + 66
    } else {
        btnY := mePcFrameY + 4
    }
    meSaveBtn.Move(, btnY)
    meCancelBtn.Move(, btnY)
    macroEditGui.Show("w350 h" (btnY + 42) " NoActivate")
}

MacroEditDetectKey(*) {
    global meKeyEdit, macroDetectedMouse, meKeyList
    meKeyEdit.Value := "press any key or click..."
    global macroDetectedMouse := ""
    MacroDetectStart()
    Sleep(300)
    try Hotkey("~*RButton", MacroDetectRMouse, "On")
    try Hotkey("~*LButton", MacroDetectLMouse, "On")
    try Hotkey("~*MButton", MacroDetectMMouse, "On")
    ih := InputHook("L1 T10")
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{F1}{F4}", "-E")
    ih.Start()
    deadline := A_TickCount + 10000
    while (ih.InProgress && macroDetectedMouse = "" && A_TickCount < deadline)
        Sleep(50)
    ih.Stop()
    try Hotkey("~*RButton", "Off")
    try Hotkey("~*LButton", "Off")
    try Hotkey("~*MButton", "Off")
    MacroDetectEnd()
    newKey := ""
    if (macroDetectedMouse != "")
        newKey := StrLower(macroDetectedMouse)
    else if (ih.EndReason = "EndKey")
        newKey := StrLower(ih.EndKey)
    if (newKey != "")
        meKeyList.Push(newKey)
    display := ""
    for i, k in meKeyList
        display .= (i > 1 ? ", " : "") k
    meKeyEdit.Value := display
}

MacroEditClearKeys(*) {
    global meKeyList, meKeyEdit
    meKeyList := []
    meKeyEdit.Value := ""
}



MacroEditDetectBind(*) {
    global meBindEdit, macroDetectedMouse
    meBindEdit.Value := "press any key or click..."
    global macroDetectedMouse := ""
    MacroDetectStart()
    Sleep(300)
    try Hotkey("~*RButton", MacroDetectRMouse, "On")
    try Hotkey("~*LButton", MacroDetectLMouse, "On")
    try Hotkey("~*MButton", MacroDetectMMouse, "On")
    ih := InputHook("L1 T10")
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{F1}{F4}", "-E")
    ih.Start()
    deadline := A_TickCount + 10000
    while (ih.InProgress && macroDetectedMouse = "" && A_TickCount < deadline)
        Sleep(50)
    ih.Stop()
    try Hotkey("~*RButton", "Off")
    try Hotkey("~*LButton", "Off")
    try Hotkey("~*MButton", "Off")
    MacroDetectEnd()
    if (macroDetectedMouse != "")
        meBindEdit.Value := StrLower(macroDetectedMouse)
    else if (ih.EndReason = "EndKey")
        meBindEdit.Value := StrLower(ih.EndKey)
    else
        meBindEdit.Value := ""
}

MacroDoEditRepeat(idx, *) {
    global macroList, macroEditGui, macroTabActive
    global meNameEdit, meKeyList, meIntervalEdit, meBindEdit, mePcCheck, mePcDropEdit
    name := Trim(meNameEdit.Value)
    if (name = "" || meKeyList.Length = 0) {
        ToolTip("Name and at least one key required!")
        SetTimer(() => ToolTip(), -1500)
        return
    }
    MacroRegisterHotkeys(false)
    m := macroList[idx]
    m.name := name
    bindVal := Trim(meBindEdit.Value)
    m.hotkey := (bindVal != "..." ? bindVal : "")
    m.repeatKeys := []
    for , k in meKeyList
        m.repeatKeys.Push(k)
    m.repeatInterval := Integer(meIntervalEdit.Value >= 0 ? meIntervalEdit.Value : 600)
    m.repeatSpam := (m.repeatInterval = 0) ? 1 : 0
    if (mePcCheck.Value) {
        dc := Integer(mePcDropEdit.Value)
        m.popcornFilters := [""]
        m.popcornStyle := (dc = 0) ? "all" : "amount"
        m.popcornDropCount := dc
    } else {
        m.popcornFilters := []
        m.popcornStyle := "all"
        m.popcornDropCount := 0
    }
    macroList[idx] := m
    MacroSaveAll()
    MacroUpdateListView()
    MacroRegisterHotkeys(macroTabActive)
    try macroEditGui.Destroy()
    global macroEditGui := ""
    ToolTip(" '" name "' updated", 0, 0)
    SetTimer(() => ToolTip(), -2000)
}

MacroEditCancel(*) {
    global macroEditGui
    try macroEditGui.Destroy()
    global macroEditGui := ""
}

MacroMoveUp(*) {
    global macroList, macroLV, macroTabActive, macroSelectedIdx
    row := macroSelectedIdx
    if (row <= 1)
        return
    MacroRegisterHotkeys(false)
    temp := macroList[row]
    macroList[row] := macroList[row - 1]
    macroList[row - 1] := temp
    if (macroSelectedIdx = row)
        global macroSelectedIdx := row - 1
    else if (macroSelectedIdx = row - 1)
        global macroSelectedIdx := row
    MacroSaveAll()
    MacroUpdateListView()
    macroLV.Modify(row - 1, "Focus Select")
    MacroRegisterHotkeys(macroTabActive)
}

MacroMoveDown(*) {
    global macroList, macroLV, macroTabActive, macroSelectedIdx
    row := macroSelectedIdx
    if (row = 0 || row >= macroList.Length)
        return
    MacroRegisterHotkeys(false)
    temp := macroList[row]
    macroList[row] := macroList[row + 1]
    macroList[row + 1] := temp
    if (macroSelectedIdx = row)
        global macroSelectedIdx := row + 1
    else if (macroSelectedIdx = row + 1)
        global macroSelectedIdx := row
    MacroSaveAll()
    MacroUpdateListView()
    macroLV.Modify(row + 1, "Focus Select")
    MacroRegisterHotkeys(macroTabActive)
}

MacroZCycle(*) {
    global macroList, macroPlaying, macroSelectedIdx, macroTabActive, macroArmed, arkwindow
    if (!WinActive(arkwindow))
        return
    if (macroList.Length = 0)
        return
    if (!macroArmed && !macroPlaying)
        return
    if (MacroIsBusy())
        return
    if (macroPlaying)
        MacroStopPlay()
    global macroSelectedIdx := macroSelectedIdx + 1
    if (macroSelectedIdx > macroList.Length)
        global macroSelectedIdx := 1
    global macroArmed := true
    MacroRegisterHotkeys(true)
    sel := macroList[macroSelectedIdx]
    keyStr := sel.hotkey != "" ? " [" StrUpper(sel.hotkey) "]" : ""
    MacroLog("ZCycle: → #" macroSelectedIdx " '" sel.name "' type=" sel.type)
    ToolTip(" ► " sel.name keyStr "`n Press hotkey to run  |  Z = next  |  F1 = Stop", 0, 0)
}

MacroTuneSelected(*) {
    global macroList, macroLV, macroPlaying, macroTuning, macroSelectedIdx
    global MainGui, guiVisible
    if (macroPlaying)
        return
    if (macroSelectedIdx < 1 || macroSelectedIdx > macroList.Length) {
        ToolTip(" Select a recorded macro first", 0, 0)
        SetTimer(() => ToolTip(), -1500)
        return
    }
    row := macroSelectedIdx
    m := macroList[row]
    if (m.type != "recorded" && m.type != "guided") {
        ToolTip(" Tuning works on recorded/guided macros", 0, 0)
        SetTimer(() => ToolTip(), -1500)
        return
    }
    global macroTuning := true
    MainGui.Hide()
    global guiVisible := false
    SetTimer(MacroTuneLoop.Bind(row), -1)
}

MacroTuneLoop(idx) {
    global macroList, macroPlaying, macroTuning, arkwindow
    m := macroList[idx]
    tuneLow := 0.05
    tuneHigh := m.speedMult
    tuneCurrent := (tuneLow + tuneHigh) / 2
    iteration := 0
    isGuided := (m.type = "guided")
    mouseSpd := isGuided && m.HasProp("mouseSpeed") ? m.mouseSpeed : 0
    settle := isGuided && m.HasProp("mouseSettle") ? m.mouseSettle : 5
    while (macroTuning && iteration < 10) {
        iteration++
        ToolTip(" TUNING: " m.name "`n Speed: " Format("{:.2f}x", tuneCurrent) "  (run " iteration ")`n Playing...", 0, 0)
        if WinExist(arkwindow)
            WinActivate(arkwindow)
        Sleep(500)
        global macroPlaying := true
        CoordMode("Mouse", "Screen")
        for , evt in m.events {
            if (!macroTuning || !macroPlaying) {
                global macroPlaying := false
                global macroTuning := false
                ToolTip()
                return
            }
            scaledDelay := Integer(evt.delay * tuneCurrent)
            if (evt.type = "M") {
                MouseMove(evt.x, evt.y, mouseSpd)
                if (settle > 0)
                    Sleep(settle)
            } else {
                if (scaledDelay > 0)
                    Sleep(scaledDelay)
            }
            if (!macroTuning || !macroPlaying) {
                global macroPlaying := false
                global macroTuning := false
                ToolTip()
                return
            }
            switch evt.type {
                case "K":
                    switch evt.dir {
                        case "p":
                            kName := StrLen(evt.key) > 1 ? "{" evt.key "}" : evt.key
                            Send(kName)
                        case "d":
                            Send("{" evt.key " Down}")
                        case "u":
                            Send("{" evt.key " Up}")
                    }
                case "C":
                    switch evt.dir {
                        case "c":
                            MouseMove(evt.x, evt.y, mouseSpd)
                            if (settle > 0)
                                Sleep(settle)
                            Click(evt.btn)
                        case "d":
                            MouseMove(evt.x, evt.y, mouseSpd)
                            if (settle > 0)
                                Sleep(settle)
                            Click(evt.btn " Down")
                        case "u":
                            MouseMove(evt.x, evt.y, mouseSpd)
                            if (settle > 0)
                                Sleep(settle)
                            Click(evt.btn " Up")
                    }
            }
        }
        global macroPlaying := false
        if (!macroTuning) {
            ToolTip()
            return
        }
        ToolTip(" TUNING: " m.name "  at " Format("{:.2f}x", tuneCurrent) "`n Did it work?`n Y = Pass  |  N = Fail  |  F1 = Done", 0, 0)
        ih := InputHook("L1 T60")
        ih.KeyOpt("{All}", "E")
        ih.Start()
        ih.Wait()
        if (!macroTuning) {
            ToolTip()
            return
        }
        key := ih.EndKey
        if (key = "y") {
            tuneHigh := tuneCurrent
            tuneCurrent := (tuneLow + tuneCurrent) / 2
        } else if (key = "n") {
            tuneLow := tuneCurrent
            tuneCurrent := (tuneCurrent + tuneHigh) / 2
        } else {
            break
        }
        if (tuneHigh - tuneLow < 0.03)
            break
    }
    m.speedMult := tuneHigh
    macroList[idx] := m
    MacroSaveAll()
    MacroUpdateListView()
    global macroTuning := false
    ToolTip(" Tuning done: " m.name " = " Format("{:.2f}x", tuneHigh), 0, 0)
    SetTimer(() => ToolTip(), -3000)
}

MacroRegisterHotkeys(enable) {
    global macroList, macroSelectedIdx, macroTabActive, macroHotkeysLive, macroArmed
    global pcMode, pcF10Step
    global macroHotkeysLive := enable
    MacroDisarmPopcornF()
    if (enable) {
        if (pcMode = 0 && pcF10Step = 0)
            try Hotkey("$z", MacroZCycle, "On")
        if (macroTabActive) {
            try Hotkey("$[", MacroSpeedUp, "On")
            try Hotkey("$]", MacroSpeedDown, "On")
        }
    } else {
        try Hotkey("$z", "Off")
        try Hotkey("$[", "Off")
        try Hotkey("$]", "Off")
    }
    for i, m in macroList {
        if (m.hotkey != "" && m.hotkey != "..." && m.hotkey != "q" && m.hotkey != "f") {
            if (m.hotkey = "r" && imprintScanning)
                continue
            try Hotkey("$" m.hotkey, "Off")
            try Hotkey("~$" m.hotkey, "Off")
        }
    }
    if (enable && macroList.Length > 0) {
        if (macroSelectedIdx < 1 || macroSelectedIdx > macroList.Length)
            global macroSelectedIdx := 1
        sel := macroList[macroSelectedIdx]
        if (sel.hotkey != "" && sel.hotkey != "..." && sel.hotkey != "q" && sel.hotkey != "f" && !(sel.hotkey = "r" && imprintScanning)) {
            prefix := (macroArmed && sel.type = "pyro") ? "$" : "~$"
            try Hotkey(prefix sel.hotkey, MacroHotkeyHandler.Bind(macroSelectedIdx), "On")
        }
    }
    MacroUpdateListView()
}

MacroBlockAllHotkeys() {
    global macroList, macroHotkeysLive
    global macroHotkeysLive := false
    try Hotkey("$z", "Off")
    try Hotkey("$[", "Off")
    try Hotkey("$]", "Off")
    for i, m in macroList {
        if (m.hotkey != "" && m.hotkey != "..." && m.hotkey != "q" && m.hotkey != "f") {
            if (m.hotkey = "r" && imprintScanning)
                continue
            try Hotkey("$" m.hotkey, "Off")
            try Hotkey("~$" m.hotkey, "Off")
        }
    }
}

MacroSpeedDown(*) {
    global macroList, macroSelectedIdx, macroTabActive, macroPlaying, macroSpeedDirty
    if (!macroTabActive || macroList.Length = 0)
        return
    if (macroSelectedIdx < 1 || macroSelectedIdx > macroList.Length)
        return
    m := macroList[macroSelectedIdx]
    if (!m.HasProp("speedMult"))
        return
    newSpeed := m.speedMult + 0.05
    if (newSpeed > 2.00)
        newSpeed := 2.00
    m.speedMult := Round(newSpeed, 3)
    macroList[macroSelectedIdx] := m
    global macroSpeedDirty := true
    if (!macroPlaying)
        MacroUpdateListView()
    bar := MacroSpeedBar(m.speedMult)
    ToolTip(" ► " m.name "  " Format("{:.2f}x", m.speedMult) "  SLOWER`n " bar, 0, 0)
    SetTimer(() => ToolTip(), -3000)
}

MacroSpeedUp(*) {
    global macroList, macroSelectedIdx, macroTabActive, macroPlaying, macroSpeedDirty
    if (!macroTabActive || macroList.Length = 0)
        return
    if (macroSelectedIdx < 1 || macroSelectedIdx > macroList.Length)
        return
    m := macroList[macroSelectedIdx]
    if (!m.HasProp("speedMult"))
        return
    newSpeed := m.speedMult - 0.05
    if (newSpeed < 0.10)
        newSpeed := 0.10
    m.speedMult := Round(newSpeed, 3)
    macroList[macroSelectedIdx] := m
    global macroSpeedDirty := true
    if (!macroPlaying)
        MacroUpdateListView()
    bar := MacroSpeedBar(m.speedMult)
    ToolTip(" ► " m.name "  " Format("{:.2f}x", m.speedMult) "  FASTER`n " bar, 0, 0)
    SetTimer(() => ToolTip(), -3000)
}

MacroSpeedBar(sp) {
    filled := Round((sp - 0.10) / (2.00 - 0.10) * 20)
    if (filled < 0)
        filled := 0
    if (filled > 20)
        filled := 20
    bar := "["
    loop filled
        bar .= "█"
    loop (20 - filled)
        bar .= "░"
    bar .= "]"
    return bar
}

MacroSpeedHint(m) {
    sp := m.HasProp("speedMult") ? m.speedMult : 1.0
    return " Speed: " Format("{:.1f}x", sp)
}

MacroShowHelp(*) {
    global macroHelpGui
    try {
        if (macroHelpGui != "")
            macroHelpGui.Destroy()
    }
    global macroHelpGui := Gui("+AlwaysOnTop", "Macro Help")
    macroHelpGui.BackColor := "1A1A1A"
    macroHelpGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    macroHelpGui.Add("Text", "x15 y10 w350 Center", "Macro Tab — Help")
    macroHelpGui.SetFont("s9 Bold cFF4444", "Segoe UI")
    macroHelpGui.Add("Text", "x15 y38 w350", "CONTROLS")
    macroHelpGui.SetFont("s8 cDDDDDD", "Segoe UI")
    macroHelpGui.Add("Text", "x15 y55 w350", "F3 / Start → arm selected macro")
    macroHelpGui.Add("Text", "x15 y70 w350", "F → run at inventory  |  Q → cycle / single item")
    macroHelpGui.Add("Text", "x15 y85 w350", "Z → next macro  |  F1 → stop & show UI")
    macroHelpGui.SetFont("s9 Bold cFF4444", "Segoe UI")
    macroHelpGui.Add("Text", "x15 y108 w350", "COMBO (Popcorn+MagicF)")
    macroHelpGui.SetFont("s8 cDDDDDD", "Segoe UI")
    macroHelpGui.Add("Text", "x15 y125 w350", "F → open inv & drop  |  R → close inv")
    macroHelpGui.Add("Text", "x15 y140 w350", "Q → swap Popcorn ↔ MagicF  |  Z → exit")
    macroHelpGui.SetFont("s9 c888888", "Segoe UI")
    btnClose := DarkBtn(macroHelpGui, "x130 y168 w120 h26", "Close", 0xDDDDDD, _DK_BG, -12, false)
    btnClose.OnEvent("Click", (*) => macroHelpGui.Destroy())
    macroHelpGui.OnEvent("Close", (*) => macroHelpGui.Destroy())
    macroHelpGui.Show("AutoSize " MacroPopupPos(350))
}
global macroHelpGui := ""

MacroIsBusy() {
    global qhRunning, obUploadRunning, obDownloadRunning, pcRunning, acRunning
    global runClaimAndNameScript, runNameAndSpayScript, runMagicFScript
    global pcMode, pcF10Step, AutoSimCheck, gmkMode
    return (qhRunning || obUploadRunning || obDownloadRunning || pcRunning || acRunning || runClaimAndNameScript || runNameAndSpayScript || runMagicFScript || comboRunning || pcMode > 0 || pcF10Step > 0 || AutoSimCheck || gmkMode != "off")
}

MacroPopupPos(dlgW := 350) {
    px := 177 + 450 + 10
    py := 330
    if (px + dlgW > A_ScreenWidth)
        px := Max(0, 177 - dlgW - 10)
    return "x" px " y" py
}

MacroDialogOpen() {
    global guidedWizGui, macroEditGui, comboWizGui, macroSaveGui, macroRepeatGui, macroHelpGui
    for , g in [guidedWizGui, macroEditGui, comboWizGui, macroSaveGui, macroRepeatGui, macroHelpGui] {
        if (g != "") {
            try {
                if WinActive("ahk_id " g.Hwnd)
                    return true
            }
        }
    }
    return false
}

MacroHotkeyHandler(idx, thisHotkey) {
    global macroPlaying, macroTabActive, macroSelectedIdx, macroArmed, macroActiveIdx, arkwindow
    global MainGui, guiVisible, macroList, macroHotkeysLive
    sel := macroList[idx]

    if (!macroHotkeysLive || MacroDialogOpen()) {
        if (MacroDialogOpen())
            Send("{" SubStr(thisHotkey, 2) "}")
        return
    }

    isArk := WinActive(arkwindow)
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mhx, &mhy)
    mouseOnMain := (mhx >= 0 && mhx < A_ScreenWidth && mhy >= 0 && mhy < A_ScreenHeight)
    if (!isArk && !guiVisible && !mouseOnMain) {
        if (macroArmed && sel.type = "pyro")
            Send("{" sel.hotkey "}")
        return
    }
    if (idx != macroSelectedIdx)
        return
    if (macroPlaying) {
        if ((sel.type = "repeat" || sel.type = "recorded") && idx = macroActiveIdx) {
            MacroStopPlay()
            global macroArmed := true
            MacroRegisterHotkeys(true)
            keyStr := sel.hotkey != "" ? " [" StrUpper(sel.hotkey) "]" : ""
            _pcH := (sel.type = "repeat" && sel.HasProp("popcornFilters") && sel.popcornFilters.Length > 0) ? "`n F = popcorn" : ""
            if (_pcH != "")
                MacroArmPopcornF(idx)
            ToolTip(" ► " sel.name " armed" keyStr "`n" MacroSpeedHint(sel) _pcH "`n Tap to run  |  Z = next  |  F1 = disarm", 0, 0)
        }
        return
    }
    if (MacroIsBusy()) {
        ToolTip(" Macro paused — another function is running`n Will resume when done", 0, 0)
        SetTimer(() => ToolTip(), -2000)
        return
    }
    if (guiVisible) {
        if (sel.type = "guided" || sel.type = "combo")
            return
        if (sel.type = "pyro")
            return
        MainGui.Hide()
        global guiVisible := false
        global macroArmed := true
        MacroRegisterHotkeys(true)
        if WinExist(arkwindow)
            WinActivate(arkwindow)
        keyStr := sel.hotkey != "" ? " [" StrUpper(sel.hotkey) "]" : ""
        MacroLog("HotkeyHandler: armed from GUI — '" sel.name "' type=" sel.type)
        if (sel.type = "guided") {
            MacroLog("HotkeyHandler: launching guided thread immediately from GUI arm")
            MacroPlayByIndex(idx)
        } else if (sel.type = "combo") {
            MacroLog("HotkeyHandler: launching combo thread immediately from GUI arm")
            MacroPlayByIndex(idx)
        } else {
            ToolTip(" ► " sel.name " armed" keyStr "`n" MacroSpeedHint(sel) "`n Tap to run  |  Hold for game  |  Z = next  |  F1 = disarm", 0, 0)
            SetTimer(() => ToolTip(), -3000)
        }
        return
    }
    if (!macroArmed)
        return
    if (sel.type = "pyro") {
        hk := sel.hotkey
        deadline := A_TickCount + 250
        while (A_TickCount < deadline) {
            if (!GetKeyState(hk, "P")) {
                MacroPlayByIndex(idx)
                return
            }
            Sleep(10)
        }
        Send("{" hk " Down}")
        KeyWait(hk)
        Send("{" hk " Up}")
        return
    }
    if (sel.type = "guided" || sel.type = "combo") {
        MacroLog("HotkeyHandler: " sel.type " '" sel.name "' triggered — staying armed, launching play")
        MacroPlayByIndex(idx)
        return
    }
    global macroArmed := false
    MacroRegisterHotkeys(true)
    MacroPlayByIndex(idx)
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; GUIDED RECORDING WIZARD

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

GuidedStartWizard(*) {
    global guidedWizGui, macroList, macroPlaying, macroRecording, guidedRecording, macroHotkeysLive
    if (macroPlaying || macroRecording || guidedRecording)
        return
    if (macroList.Length >= 10) {
        ToolTip(" Max 10 macros — delete one first", 0, 0)
        SetTimer(() => ToolTip(), -2000)
        return
    }
    MacroBlockAllHotkeys()
    GuidedShowSinglePage()
}

GuidedShowSinglePage() {
    global guidedWizGui, guidedInvType, guidedActionType, pcDropKey
    try {
        if (guidedWizGui != "")
            guidedWizGui.Destroy()
    }
    guidedWizGui := Gui("+AlwaysOnTop", "Guided Macro")
    guidedWizGui.BackColor := "1A1A1A"
    guidedWizGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    guidedWizGui.Add("Text", "x16 y16 w250", "Guided Macro")
    gHelpBtn := DarkBtn(guidedWizGui, "x300 y14 w24 h24", "?", _RED_BGR, _DK_BG, -11, true)
    gHelpBtn.OnEvent("Click", GuidedShowSinglePageHelp)

    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x16 y44 w100 h24 +0x200", "Inventory:")
    global guidedSpInvDDL := guidedWizGui.Add("DropDownList", "x130 y44 w190", ["Vault", "Player Inventory", "Crafting"])
    guidedSpInvDDL.Value := 1
    guidedSpInvDDL.SetFont("s9 c000000", "Segoe UI")
    guidedSpInvDDL.OnEvent("Change", GuidedSpUpdateFields)

    guidedWizGui.SetFont("s8 c888888 Italic", "Segoe UI")
    global guidedSpCraftHint := guidedWizGui.Add("Text", "x130 y19 w200", "drop/take — craft tab to craft")
    guidedSpCraftHint.Visible := false

    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x16 y72 w100 h24 +0x200", "Action:")
    global guidedSpActionDDL := guidedWizGui.Add("DropDownList", "x130 y72 w190", ["Popcorn", "Take"])
    guidedSpActionDDL.Value := 1
    guidedSpActionDDL.SetFont("s9 c000000", "Segoe UI")
    guidedSpActionDDL.OnEvent("Change", GuidedSpUpdateFields)

    guidedWizGui.Add("Progress", "x16 y104 w318 h1 Background333333")

    fieldY := 112
    global guidedSpTakeLbls := []
    global guidedSpTakeEdits := []
    global guidedSpTakeHints := []

    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedSpTakeLbls.Push(guidedWizGui.Add("Text", "x16 y" fieldY " w100 h24 +0x200", "Count:"))
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedSpCountEdit := guidedWizGui.Add("Edit", "x130 y" fieldY " w60 h24 +Number", "0")
    guidedSpCountEdit.OnEvent("Change", GuidedSpUpdateName)
    guidedSpTakeEdits.Push(guidedSpCountEdit)
    guidedWizGui.SetFont("s8 c888888 Italic", "Segoe UI")
    guidedSpTakeHints.Push(guidedWizGui.Add("Text", "x195 y" (fieldY+4) " w120", "(0 = all)"))
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedSpTakeLbls.Push(guidedWizGui.Add("Text", "x16 y" (fieldY+28) " w110 h24 +0x200", "Search filter:"))
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedSpTakeFilterEdit := guidedWizGui.Add("Edit", "x130 y" (fieldY+28) " w190 h24", "")
    guidedSpTakeEdits.Push(guidedSpTakeFilterEdit)
    guidedWizGui.SetFont("s8 c888888", "Segoe UI")
    guidedSpTakeHints.Push(guidedWizGui.Add("Text", "x130 y" (fieldY+52) " w190", "(blank = no filter)"))

    global guidedSpPcLbls := []
    global guidedSpPcEdits := []
    global guidedSpPcHints := []

    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedSpPcLbls.Push(guidedWizGui.Add("Text", "x16 y" fieldY " w100 h24 +0x200", "Drop count:"))
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedSpDropCountEdit := guidedWizGui.Add("Edit", "x130 y" fieldY " w60 h24 +Number", "0")
    guidedSpDropCountEdit.OnEvent("Change", GuidedSpUpdateName)
    guidedSpPcEdits.Push(guidedSpDropCountEdit)
    guidedWizGui.SetFont("s8 c888888 Italic", "Segoe UI")
    guidedSpPcHints.Push(guidedWizGui.Add("Text", "x195 y" (fieldY+4) " w120", "(0 = all)"))
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedSpPcLbls.Push(guidedWizGui.Add("Text", "x16 y" (fieldY+28) " w100 h24 +0x200", "Drop key:"))
    guidedWizGui.SetFont("s9 Bold cFF4444", "Segoe UI")
    dropKeyStr := (pcDropKey != "" ? StrUpper(pcDropKey) : "?")
    global guidedSpDropKeyLbl := guidedWizGui.Add("Text", "x130 y" (fieldY+28) " w60 h24 +0x200", dropKeyStr)
    guidedSpPcLbls.Push(guidedSpDropKeyLbl)
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedSpPcLbls.Push(guidedWizGui.Add("Text", "x16 y" (fieldY+56) " w110 h24 +0x200", "Search filter:"))
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedSpPcFilterEdit := guidedWizGui.Add("Edit", "x130 y" (fieldY+56) " w190 h24", "")
    guidedSpPcEdits.Push(guidedSpPcFilterEdit)
    guidedWizGui.SetFont("s8 c888888", "Segoe UI")
    guidedSpPcHints.Push(guidedWizGui.Add("Text", "x130 y" (fieldY+80) " w190", "(blank = no filter)"))

    global guidedSpBottomSep := guidedWizGui.Add("Progress", "x16 y200 w318 h1 Background333333")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    global guidedSpNameLbl := guidedWizGui.Add("Text", "x16 y208 w55 h24 +0x200", "Name:")
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedSpNameEdit := guidedWizGui.Add("Edit", "x75 y208 w245 h24", "")
    global guidedSpSaveBtn := DarkBtn(guidedWizGui, "x16 y240 w100 h26", "Save", _RED_BGR, _DK_BG, -12, true)
    guidedSpSaveBtn.OnEvent("Click", GuidedSpSave)
    global guidedSpCancelBtn := DarkBtn(guidedWizGui, "x200 y240 w100 h26", "Cancel", 0xDDDDDD, _DK_BG, -12, false)
    guidedSpCancelBtn.OnEvent("Click", GuidedCancel)
    guidedWizGui.OnEvent("Close", GuidedCancel)

    GuidedSpUpdateFields()
    guidedWizGui.Show("w350 h280 " MacroPopupPos(350))
}

GuidedSpUpdateFields(*) {
    global guidedSpInvDDL, guidedSpActionDDL
    global guidedSpTakeLbls, guidedSpTakeEdits, guidedSpTakeHints
    global guidedSpPcLbls, guidedSpPcEdits, guidedSpPcHints
    global guidedSpBottomSep, guidedSpNameLbl, guidedSpNameEdit
    global guidedSpSaveBtn, guidedSpCancelBtn, guidedWizGui, guidedSpCraftHint

    invIdx := guidedSpInvDDL.Value
    isPlayer := (invIdx = 2)
    isCrafting := (invIdx = 3)
    guidedSpCraftHint.Visible := isCrafting

    curAction := guidedSpActionDDL.Value
    if (isPlayer) {
        guidedSpActionDDL.Delete()
        guidedSpActionDDL.Add(["Give", "Popcorn"])
    } else {
        guidedSpActionDDL.Delete()
        guidedSpActionDDL.Add(["Popcorn", "Take"])
    }
    guidedSpActionDDL.Value := curAction > 0 ? Min(curAction, 2) : 1

    actionIdx := guidedSpActionDDL.Value
    if (isPlayer) {
        isTake := (actionIdx = 1)
        isPopcorn := (actionIdx = 2)
    } else {
        isPopcorn := (actionIdx = 1)
        isTake := (actionIdx = 2)
    }

    for , c in guidedSpTakeLbls
        c.Visible := isTake
    for , c in guidedSpTakeEdits
        c.Visible := isTake
    for , c in guidedSpTakeHints
        c.Visible := isTake
    for , c in guidedSpPcLbls
        c.Visible := isPopcorn
    for , c in guidedSpPcEdits
        c.Visible := isPopcorn
    for , c in guidedSpPcHints
        c.Visible := isPopcorn

    if (isTake)
        bottomY := 112 + 66 + 4
    else
        bottomY := 112 + 100 + 4

    guidedSpBottomSep.Move(, bottomY)
    guidedSpNameLbl.Move(, bottomY + 8)
    guidedSpNameEdit.Move(, bottomY + 8)
    guidedSpSaveBtn.Move(, bottomY + 40)
    guidedSpCancelBtn.Move(, bottomY + 40)
    dlgH := bottomY + 76
    GuidedSpUpdateName()
    guidedWizGui.Show("w350 h" dlgH " NoActivate")
    DllCall("RedrawWindow", "Ptr", guidedWizGui.Hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0107)
}

GuidedSpUpdateName(*) {
    global guidedSpInvDDL, guidedSpActionDDL, guidedSpNameEdit
    global guidedSpCountEdit, guidedSpDropCountEdit
    invIdx := guidedSpInvDDL.Value
    isPlayer := (invIdx = 2)
    actionIdx := guidedSpActionDDL.Value
    invNames := ["Vault", "Player", "Crafting"]
    if (isPlayer) {
        actionNames := ["Give", "Popcorn"]
        isTake := (actionIdx = 1)
    } else {
        actionNames := ["Popcorn", "Take"]
        isTake := (actionIdx = 2)
    }
    countVal := ""
    if (isTake) {
        try countVal := guidedSpCountEdit.Value
    } else {
        try countVal := guidedSpDropCountEdit.Value
    }
    unitStr := (countVal != "" && countVal != "0") ? " " countVal : ""
    guidedSpNameEdit.Value := invNames[invIdx] " " actionNames[actionIdx] unitStr
}

GuidedShowSinglePageHelp(*) {
    static hGui := ""
    if IsObject(hGui) {
        try hGui.Destroy()
        hGui := ""
        return
    }
    hGui := Gui("+AlwaysOnTop +ToolWindow", "Guided Macro Help")
    hGui.BackColor := "1A1A1A"
    hGui.SetFont("s9 Bold cFF4444", "Segoe UI")
    hGui.Add("Text", "x10 y8 w280", "GUIDED MACRO")
    hGui.SetFont("s8 cDDDDDD", "Segoe UI")
    hGui.Add("Text", "x10 y30 w280",
        "Pick inventory type and action.`n"
        "Take: click + T each slot (transfers items).`n"
        "Popcorn: hover + drop key (discards items).`n"
        "Give: player inv → other inv (skip implant).`n"
        "Record: manually record clicks/keys.`n`n"
        "Use search filter to target specific items.`n"
        "Leave blank to affect all items in grid.`n"
        "F at inventory to run. Z = next. F1 = stop.")
    hGui.OnEvent("Close", (*) => (hGui.Destroy(), hGui := ""))
    hGui.Show("w300 h200 " MacroPopupPos(300))
}

GuidedSpSave(*) {
    global guidedWizGui, guidedSpInvDDL, guidedSpActionDDL, guidedSpNameEdit
    global guidedSpCountEdit, guidedSpTakeFilterEdit
    global guidedSpDropCountEdit, guidedSpPcFilterEdit
    global guidedInvType, guidedActionType
    global pcDropKey

    invMap := Map(1, "vault", 2, "player", 3, "crafting")
    global guidedInvType := invMap.Has(guidedSpInvDDL.Value) ? invMap[guidedSpInvDDL.Value] : "vault"

    isPlayer := (guidedSpInvDDL.Value = 2)
    actionIdx := guidedSpActionDDL.Value
    actionMap := isPlayer ? Map(1, "give", 2, "popcorn") : Map(1, "popcorn", 2, "take")
    global guidedActionType := actionMap.Has(actionIdx) ? actionMap[actionIdx] : "popcorn"

    if (guidedActionType = "popcorn") {
        savedDrop := ""
        try savedDrop := IniRead(A_ScriptDir "\AIO_config.ini", "Popcorn", "DropKey", "")
        if (savedDrop = "") {
            guidedWizGui.Destroy()
            global guidedWizGui := ""
            GuidedShowDropKeyPrompt("popcorn")
            return
        }
    }

    if (guidedActionType = "take") {
        global guidedTakeCount := Integer(guidedSpCountEdit.Value)
        global guidedTakeEdit := guidedSpCountEdit
        global guidedTakeFilterEdit := guidedSpTakeFilterEdit
        global guidedTakeNameEdit := guidedSpNameEdit
        GuidedTakeSave()
    } else if (guidedActionType = "give") {
        global guidedGiveEdit := guidedSpCountEdit
        global guidedGiveFilterEdit := guidedSpTakeFilterEdit
        global guidedGiveNameEdit := guidedSpNameEdit
        GuidedGiveSave()
    } else if (guidedActionType = "popcorn") {
        global guidedPcSlotsEdit := guidedSpDropCountEdit
        global guidedPcDropKeyEdit := {Value: pcDropKey}
        global guidedPcFilterEdit := guidedSpPcFilterEdit
        global guidedPcNameEdit := guidedSpNameEdit
        GuidedPopcornSave()
    }
}

GuidedShowStep1() {
    global guidedWizGui, guidedInvType
    try {
        if (guidedWizGui != "")
            guidedWizGui.Destroy()
    }
    guidedWizGui := Gui("+AlwaysOnTop", "Guided Macro — Step 1")
    guidedWizGui.BackColor := "1A1A1A"
    guidedWizGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y15 w320 Center", "What type of inventory?")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y45 w320", "Select the inventory you will interact with.")
    guidedWizGui.Add("Text", "x15 y65 w320", "This ensures stable pixel detection on open.")
    global guidedInvDDL := guidedWizGui.Add("DropDownList", "x15 y95 w200", ["Vault/Forge/non-craft.", "Player Inventory", "Crafting"])
    guidedInvDDL.Value := 1
    guidedInvDDL.SetFont("s9 c000000", "Segoe UI")
    btnNext := DarkBtn(guidedWizGui, "x15 y135 w100 h28", "Next →", _RED_BGR, _DK_BG, -12, true)
    btnNext.OnEvent("Click", GuidedStep1Next)
    btnCancel := DarkBtn(guidedWizGui, "x120 y135 w100 h28", "Cancel", 0xDDDDDD, _DK_BG, -12, false)
    btnCancel.OnEvent("Click", GuidedCancel)
    guidedWizGui.OnEvent("Close", GuidedCancel)
    guidedWizGui.Show("AutoSize " MacroPopupPos(350))
}

GuidedStep1Next(*) {
    global guidedWizGui, guidedInvType, guidedInvDDL
    invTypes := Map(1, "vault", 2, "player", 3, "crafting")
    global guidedInvType := invTypes.Has(guidedInvDDL.Value) ? invTypes[guidedInvDDL.Value] : "storage"
    guidedWizGui.Destroy()
    global guidedWizGui := ""
    GuidedShowActionStep()
}

GuidedShowActionStep() {
    global guidedWizGui, guidedActionType, guidedInvType
    global guidedActionType := "take"
    guidedWizGui := Gui("+AlwaysOnTop", "Guided Macro — Action Type")
    guidedWizGui.BackColor := "1A1A1A"
    guidedWizGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y15 w320 Center", "What should this macro do?")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    if (guidedInvType = "player") {
        guidedWizGui.Add("Text", "x15 y45 w320", "Give: transfer from player 6x6 into other inv (click + T).")
        guidedWizGui.Add("Text", "x15 y65 w320", "Popcorn: drop items from grid slots (drop key).")
        guidedWizGui.Add("Text", "x15 y85 w320", "Record: manually record clicks & keys.")
        global guidedActionDDL := guidedWizGui.Add("DropDownList", "x15 y115 w200", ["Give", "Popcorn", "Record"])
        guidedActionDDL.Value := 1
        guidedActionDDL.SetFont("s9 c000000", "Segoe UI")
        btnNext := DarkBtn(guidedWizGui, "x15 y155 w100 h28", "Next →", _RED_BGR, _DK_BG, -12, true)
        btnNext.OnEvent("Click", GuidedActionStepNext)
        btnCancel := DarkBtn(guidedWizGui, "x120 y155 w100 h28", "Cancel", 0xDDDDDD, _DK_BG, -12, false)
    } else {
        guidedWizGui.Add("Text", "x15 y45 w320", "Popcorn: drop items from grid slots (drop key).")
        guidedWizGui.Add("Text", "x15 y65 w320", "Take: transfer items from grid slots (click + T).")
        guidedWizGui.Add("Text", "x15 y85 w320", "Record: manually record clicks & keys.")
        global guidedActionDDL := guidedWizGui.Add("DropDownList", "x15 y115 w200", ["Popcorn", "Take", "Record"])
        guidedActionDDL.Value := 1
        guidedActionDDL.SetFont("s9 c000000", "Segoe UI")
        btnNext := DarkBtn(guidedWizGui, "x15 y155 w100 h28", "Next →", _RED_BGR, _DK_BG, -12, true)
        btnNext.OnEvent("Click", GuidedActionStepNext)
        btnCancel := DarkBtn(guidedWizGui, "x120 y155 w100 h28", "Cancel", 0xDDDDDD, _DK_BG, -12, false)
    }
    btnCancel.OnEvent("Click", GuidedCancel)
    guidedWizGui.OnEvent("Close", GuidedCancel)
    guidedWizGui.Show("AutoSize " MacroPopupPos(350))
}

GuidedActionStepNext(*) {
    global guidedWizGui, guidedActionType, guidedActionDDL, guidedInvType, pcDropKey
    if (guidedInvType = "player")
        actionMap := Map(1, "give", 2, "popcorn", 3, "record")
    else
        actionMap := Map(1, "popcorn", 2, "take", 3, "record")
    global guidedActionType := actionMap.Has(guidedActionDDL.Value) ? actionMap[guidedActionDDL.Value] : "popcorn"
    if (guidedActionType = "popcorn") {
        guidedWizGui.Destroy()
        global guidedWizGui := ""
        savedDrop := ""
        try savedDrop := IniRead(A_ScriptDir "\AIO_config.ini", "Popcorn", "DropKey", "")
        if (savedDrop != "") {
            GuidedShowPopcornStep()
        } else {
            GuidedShowDropKeyPrompt("popcorn")
        }
        return
    }
    guidedWizGui.Destroy()
    global guidedWizGui := ""
    if (guidedActionType = "take")
        GuidedShowTakeStep()
    else if (guidedActionType = "popcorn")
        GuidedShowPopcornStep()
    else if (guidedActionType = "give")
        GuidedShowGiveStep()
    else
        GuidedShowStep2()
}

GuidedShowDropKeyPrompt(nextAction) {
    global guidedWizGui, pcDropKey
    guidedWizGui := Gui("+AlwaysOnTop", "Set Drop Key")
    guidedWizGui.BackColor := "1A1A1A"
    guidedWizGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y15 w300 Center", "Confirm Your Drop Key")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y45 w300", "Must match your ARK drop keybind.")
    guidedWizGui.Add("Text", "x15 y63 w300", "Change if needed, then press Confirm.")
    guidedWizGui.Add("Text", "x15 y95 w80 h24 +0x200", "Drop key:")
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedDropKeyEdit := guidedWizGui.Add("Edit", "x100 y95 w60 h24 Center", pcDropKey)
    guidedWizGui.SetFont("s8 c888888 Italic", "Segoe UI")
    guidedWizGui.Add("Text", "x165 y99 w130", "default: g")
    btnOk := DarkBtn(guidedWizGui, "x15 y130 w100 h28", "Confirm", _RED_BGR, _DK_BG, -12, true)
    btnOk.OnEvent("Click", GuidedDropKeyConfirm.Bind(nextAction))
    btnCancel := DarkBtn(guidedWizGui, "x120 y130 w100 h28", "Cancel", 0xDDDDDD, _DK_BG, -12, false)
    btnCancel.OnEvent("Click", GuidedCancel)
    guidedWizGui.OnEvent("Close", GuidedCancel)
    guidedWizGui.Show("AutoSize " MacroPopupPos(350))
}

GuidedDropKeyConfirm(nextAction, *) {
    global guidedWizGui, guidedDropKeyEdit, pcDropKey
    newKey := Trim(guidedDropKeyEdit.Value)
    if (newKey = "") {
        ToolTip("Enter a drop key!")
        SetTimer(() => ToolTip(), -1500)
        return
    }
    global pcDropKey := newKey
    try IniWrite(pcDropKey, A_ScriptDir "\AIO_config.ini", "Popcorn", "DropKey")
    MacroLog("DropKey set to: " pcDropKey)
    guidedWizGui.Destroy()
    global guidedWizGui := ""
    if (nextAction = "popcorn")
        GuidedShowPopcornStep()
    else if (nextAction = "combo")
        ComboShowSinglePage()
}

GuidedShowTakeStep() {
    global guidedWizGui, guidedTakeCount
    global guidedTakeCount := 3
    guidedWizGui := Gui("+AlwaysOnTop", "Guided Macro — Take Setup")
    guidedWizGui.BackColor := "1A1A1A"
    guidedWizGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y15 w340 Center", "Take — Transfer items from grid slots")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y45 w340", "Uses the 6x6 inventory grid (same as popcorn).")
    guidedWizGui.Add("Text", "x15 y65 w340", "Clicks each slot and presses T to transfer.")
    guidedWizGui.Add("Text", "x15 y90 w170 h24 +0x200", "Items to transfer:")
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedTakeEdit := guidedWizGui.Add("Edit", "x190 y90 w40 h24 +Number", "3")
    guidedWizGui.SetFont("s8 c888888 Italic", "Segoe UI")
    guidedWizGui.Add("Text", "x235 y94 w120", ">36 loops the grid")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y120 w110 h24 +0x200", "Search filter:")
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedTakeFilterEdit := guidedWizGui.Add("Edit", "x130 y120 w150 h24", "")
    guidedWizGui.SetFont("s8 c888888 Italic", "Segoe UI")
    guidedWizGui.Add("Text", "x285 y124 w60", "blank = all")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y148 w55 h24 +0x200", "Name:")
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedTakeNameEdit := guidedWizGui.Add("Edit", "x75 y148 w205 h24", "")
    btnSave := DarkBtn(guidedWizGui, "x15 y182 w100 h28", "Save", _RED_BGR, _DK_BG, -12, true)
    btnSave.OnEvent("Click", GuidedTakeSave)
    btnCancel := DarkBtn(guidedWizGui, "x120 y182 w100 h28", "Cancel", 0xDDDDDD, _DK_BG, -12, false)
    btnCancel.OnEvent("Click", GuidedCancel)
    guidedWizGui.OnEvent("Close", GuidedCancel)
    guidedWizGui.Show("AutoSize " MacroPopupPos(350))
}

GuidedTakeSave(*) {
    global guidedWizGui, guidedInvType, guidedTakeEdit, guidedTakeFilterEdit, guidedTakeNameEdit
    global macroList, macroTabActive, macroSelectedIdx
    global pcStartSlotX, pcStartSlotY, pcSlotW, pcSlotH, pcColumns

    name := Trim(guidedTakeNameEdit.Value)
    if (name = "") {
        ToolTip("Enter a name!")
        SetTimer(() => ToolTip(), -1500)
        return
    }
    slotCount := Integer(guidedTakeEdit.Value)
    if (slotCount < 1)
        slotCount := pcColumns * 6
    transferKey := "t"
    filter := Trim(guidedTakeFilterEdit.Value)

    gridSize := pcColumns * 6
    events := []
    remaining := slotCount
    while (remaining > 0) {
        slot := 0
        Loop 6 {
            row := A_Index - 1
            Loop pcColumns {
                col := A_Index - 1
                slot++
                if (slot > remaining || slot > gridSize)
                    break
                x := pcStartSlotX + col * pcSlotW
                y := pcStartSlotY + row * pcSlotH
                if (events.Length > 0)
                    events.Push({type: "M", x: x, y: y, delay: 0})
                events.Push({type: "C", dir: "c", btn: "L", x: x, y: y, delay: 100})
                events.Push({type: "K", dir: "p", key: transferKey, delay: 60})
            }
            if (slot > remaining || slot > gridSize)
                break
        }
        remaining -= Min(slot, gridSize)
    }

    m := {}
    m.name := name
    m.type := "guided"
    m.hotkey := "f"
    m.speedMult := 1.0
    m.loopEnabled := false
    m.invType := guidedInvType
    m.mouseSpeed := 0
    m.mouseSettle := 1
    m.invLoadDelay := 1500
    m.turbo := 1
    m.turboDelay := 1
    m.guidedAction := "take"
    m.guidedKey := transferKey
    m.guidedCount := slotCount
    m.searchFilters := []
    if (filter != "")
        m.searchFilters.Push(filter)
    m.events := events
    macroList.Push(m)
    global macroSelectedIdx := macroList.Length
    MacroSaveAll()
    MacroUpdateListView()
    try guidedWizGui.Destroy()
    global guidedWizGui := ""
    MacroRegisterHotkeys(macroTabActive)
    MacroLog("GuidedTakeSave: '" name "' — " slotCount " slots, key=" transferKey " filter=" (filter = "" ? "(none)" : filter) " events=" events.Length)
    ToolTip(" Take macro '" name "' saved! (" slotCount " slots, " events.Length " events)", 0, 0)
    SetTimer(() => ToolTip(), -3000)
}

GuidedShowGiveStep() {
    global guidedWizGui
    guidedWizGui := Gui("+AlwaysOnTop", "Guided Macro — Give Setup")
    guidedWizGui.BackColor := "1A1A1A"
    guidedWizGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y15 w340 Center", "Give — Transfer from player inventory")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y45 w340", "Uses the player 6x6 grid (left side inventory).")
    guidedWizGui.Add("Text", "x15 y63 w340", "Clicks each slot and presses T to transfer out.")
    guidedWizGui.SetFont("s9 cFFAA00", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y86 w340", "First slot skipped without a search filter (implant).")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y112 w170 h24 +0x200", "Items to transfer:")
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedGiveEdit := guidedWizGui.Add("Edit", "x190 y112 w40 h24 +Number", "36")
    guidedWizGui.SetFont("s8 c888888 Italic", "Segoe UI")
    guidedWizGui.Add("Text", "x235 y116 w120", ">36 loops the grid")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y142 w110 h24 +0x200", "Search filter:")
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedGiveFilterEdit := guidedWizGui.Add("Edit", "x130 y142 w150 h24", "")
    guidedWizGui.SetFont("s8 c888888 Italic", "Segoe UI")
    guidedWizGui.Add("Text", "x285 y146 w60", "blank = all")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y170 w55 h24 +0x200", "Name:")
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedGiveNameEdit := guidedWizGui.Add("Edit", "x75 y170 w205 h24", "")
    btnSave := DarkBtn(guidedWizGui, "x15 y204 w100 h28", "Save", _RED_BGR, _DK_BG, -12, true)
    btnSave.OnEvent("Click", GuidedGiveSave)
    btnCancel := DarkBtn(guidedWizGui, "x120 y204 w100 h28", "Cancel", 0xDDDDDD, _DK_BG, -12, false)
    btnCancel.OnEvent("Click", GuidedCancel)
    guidedWizGui.OnEvent("Close", GuidedCancel)
    guidedWizGui.Show("AutoSize " MacroPopupPos(350))
}

GuidedGiveSave(*) {
    global guidedWizGui, guidedInvType, guidedGiveEdit, guidedGiveFilterEdit, guidedGiveNameEdit
    global macroList, macroTabActive, macroSelectedIdx
    global plStartSlotX, plStartSlotY, plSlotW, plSlotH

    name := Trim(guidedGiveNameEdit.Value)
    if (name = "") {
        ToolTip("Enter a name!")
        SetTimer(() => ToolTip(), -1500)
        return
    }
    slotCount := Integer(guidedGiveEdit.Value)
    if (slotCount < 1)
        slotCount := pcColumns * 6
    transferKey := "t"
    filter := Trim(guidedGiveFilterEdit.Value)
    hasFilter := (filter != "")
    skipFirst := !hasFilter

    events := []
    remaining := slotCount
    while (remaining > 0) {
        slot := 0
        clicked := 0
        Loop 6 {
            row := A_Index - 1
            Loop 6 {
                col := A_Index - 1
                slot++
                if (skipFirst && slot = 1)
                    continue
                if (clicked >= remaining)
                    break
                x := plStartSlotX + col * plSlotW
                y := plStartSlotY + row * plSlotH
                if (events.Length > 0)
                    events.Push({type: "M", x: x, y: y, delay: 0})
                events.Push({type: "C", dir: "c", btn: "L", x: x, y: y, delay: 100})
                events.Push({type: "K", dir: "p", key: transferKey, delay: 60})
                clicked++
            }
            if (clicked >= remaining)
                break
        }
        remaining -= clicked
    }

    m := {}
    m.name := name
    m.type := "guided"
    m.hotkey := "f"
    m.speedMult := 1.0
    m.loopEnabled := false
    m.invType := guidedInvType
    m.mouseSpeed := 0
    m.mouseSettle := 1
    m.invLoadDelay := 500
    m.turbo := 1
    m.turboDelay := 1
    m.playerSearch := true
    m.guidedAction := "give"
    m.guidedKey := transferKey
    m.guidedCount := slotCount
    m.searchFilters := []
    if (filter != "")
        m.searchFilters.Push(filter)
    m.events := events
    macroList.Push(m)
    global macroSelectedIdx := macroList.Length
    MacroSaveAll()
    MacroUpdateListView()
    try guidedWizGui.Destroy()
    global guidedWizGui := ""
    MacroRegisterHotkeys(macroTabActive)
    MacroLog("GuidedGiveSave: '" name "' — " slotCount " slots, key=" transferKey " filter=" (filter = "" ? "(none)" : filter) " skipFirst=" skipFirst " events=" events.Length)
    ToolTip(" Give macro '" name "' saved! (" slotCount " slots, " events.Length " events)", 0, 0)
    SetTimer(() => ToolTip(), -3000)
}

GuidedShowPopcornStep() {
    global guidedWizGui, pcDropKey
    guidedWizGui := Gui("+AlwaysOnTop", "Guided Macro — Popcorn Setup")
    guidedWizGui.BackColor := "1A1A1A"
    guidedWizGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y15 w340 Center", "Popcorn — Drop items from grid slots")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y45 w340", "Uses the 6x6 inventory grid. Hovers each slot")
    guidedWizGui.Add("Text", "x15 y63 w340", "and presses your drop key to discard items.")
    guidedWizGui.Add("Text", "x15 y90 w170 h24 +0x200", "Items to drop:")
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedPcSlotsEdit := guidedWizGui.Add("Edit", "x190 y90 w40 h24 +Number", "36")
    guidedWizGui.SetFont("s8 c888888 Italic", "Segoe UI")
    guidedWizGui.Add("Text", "x235 y94 w120", ">36 loops the grid")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y120 w80 h24 +0x200", "Drop key:")
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedPcDropKeyEdit := guidedWizGui.Add("Edit", "x100 y120 w40 h24 Center", pcDropKey)
    guidedWizGui.SetFont("s8 c888888 Italic", "Segoe UI")
    guidedWizGui.Add("Text", "x145 y124 w150", "must match ARK keybind")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y150 w110 h24 +0x200", "Search filter:")
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedPcFilterEdit := guidedWizGui.Add("Edit", "x130 y150 w150 h24", "")
    guidedWizGui.SetFont("s8 c888888 Italic", "Segoe UI")
    guidedWizGui.Add("Text", "x285 y154 w60", "blank = all")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y178 w55 h24 +0x200", "Name:")
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedPcNameEdit := guidedWizGui.Add("Edit", "x75 y178 w205 h24", "")
    btnSave := DarkBtn(guidedWizGui, "x15 y212 w100 h28", "Save", _RED_BGR, _DK_BG, -12, true)
    btnSave.OnEvent("Click", GuidedPopcornSave)
    btnCancel := DarkBtn(guidedWizGui, "x120 y212 w100 h28", "Cancel", 0xDDDDDD, _DK_BG, -12, false)
    btnCancel.OnEvent("Click", GuidedCancel)
    guidedWizGui.OnEvent("Close", GuidedCancel)
    guidedWizGui.Show("AutoSize " MacroPopupPos(350))
}

GuidedPopcornSave(*) {
    global guidedWizGui, guidedInvType, guidedPcSlotsEdit, guidedPcDropKeyEdit, guidedPcFilterEdit, guidedPcNameEdit
    global macroList, macroTabActive, macroSelectedIdx, pcDropKey
    global pcStartSlotX, pcStartSlotY, pcSlotW, pcSlotH, pcColumns

    name := Trim(guidedPcNameEdit.Value)
    if (name = "") {
        ToolTip("Enter a name!")
        SetTimer(() => ToolTip(), -1500)
        return
    }
    rawCount := Integer(guidedPcSlotsEdit.Value)
    dropKey := Trim(guidedPcDropKeyEdit.Value)
    if (dropKey = "")
        dropKey := "g"
    global pcDropKey := dropKey
    try IniWrite(pcDropKey, A_ScriptDir "\AIO_config.ini", "Popcorn", "DropKey")
    filter := Trim(guidedPcFilterEdit.Value)

    events := []
    if (rawCount > 0) {
        gridSize := pcColumns * 6
        remaining := rawCount
        while (remaining > 0) {
            slot := 0
            Loop 6 {
                row := A_Index - 1
                Loop pcColumns {
                    col := A_Index - 1
                    slot++
                    if (slot > remaining || slot > gridSize)
                        break
                    x := pcStartSlotX + col * pcSlotW
                    y := pcStartSlotY + row * pcSlotH
                    events.Push({type: "M", x: x, y: y, delay: 0})
                    events.Push({type: "K", dir: "p", key: dropKey, delay: 20})
                }
                if (slot > remaining || slot > gridSize)
                    break
            }
            remaining -= Min(slot, gridSize)
        }
    }

    m := {}
    m.name := name
    m.type := "guided"
    m.hotkey := "f"
    m.speedMult := 1.0
    m.loopEnabled := true
    m.invType := guidedInvType
    m.mouseSpeed := 0
    m.mouseSettle := 1
    m.invLoadDelay := 1500
    m.turbo := 1
    m.turboDelay := 1
    m.popcornAll := (rawCount = 0) ? 1 : 0
    m.guidedAction := "popcorn"
    m.guidedKey := dropKey
    m.guidedCount := rawCount
    m.searchFilters := []
    if (filter != "")
        m.searchFilters.Push(filter)
    m.events := events
    macroList.Push(m)
    global macroSelectedIdx := macroList.Length
    MacroSaveAll()
    MacroUpdateListView()
    try guidedWizGui.Destroy()
    global guidedWizGui := ""
    MacroRegisterHotkeys(macroTabActive)
    MacroLog("GuidedPopcornSave: '" name "' — " rawCount " slots, dropKey=" dropKey " filter=" (filter = "" ? "(none)" : filter) " events=" events.Length)
    ToolTip(" Popcorn macro '" name "' saved! (" rawCount " slots, " events.Length " events)", 0, 0)
    SetTimer(() => ToolTip(), -3000)
}

GuidedShowStep2() {
    global guidedWizGui, guidedFilterCount
    guidedWizGui := Gui("+AlwaysOnTop", "Guided Macro — Step 2")
    guidedWizGui.BackColor := "1A1A1A"
    guidedWizGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y15 w320 Center", "How many search filters?")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y45 w320", "Your recorded actions will replay once per filter.")
    guidedWizGui.Add("Text", "x15 y65 w320", "Enter 0 for no search filter (raw recording).")
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedCountEdit := guidedWizGui.Add("Edit", "x15 y95 w60 h24 +Number", "1")
    btnNext := DarkBtn(guidedWizGui, "x15 y135 w100 h28", "Next →", _RED_BGR, _DK_BG, -12, true)
    btnNext.OnEvent("Click", GuidedStep2Next)
    btnBack := DarkBtn(guidedWizGui, "x120 y135 w100 h28", "← Back", 0xDDDDDD, _DK_BG, -12, false)
    btnBack.OnEvent("Click", GuidedStep2Back)
    guidedWizGui.OnEvent("Close", GuidedCancel)
    guidedWizGui.Show("AutoSize " MacroPopupPos(350))
}

GuidedStep2Back(*) {
    global guidedWizGui
    try guidedWizGui.Destroy()
    global guidedWizGui := ""
    GuidedShowStep1()
}

GuidedStep2Next(*) {
    global guidedWizGui, guidedFilterCount, guidedCountEdit
    val := Integer(guidedCountEdit.Value)
    if (val < 0)
        val := 0
    if (val > 20)
        val := 20
    global guidedFilterCount := val
    guidedWizGui.Destroy()
    global guidedWizGui := ""
    if (val > 0)
        GuidedShowStep3()
    else {
        global guidedFilters := []
        GuidedShowStep4()
    }
}

GuidedShowStep3() {
    global guidedWizGui, guidedFilterCount, guidedFilters
    global guidedFilters := []
    guidedWizGui := Gui("+AlwaysOnTop", "Guided Macro — Step 3")
    guidedWizGui.BackColor := "1A1A1A"
    guidedWizGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y15 w320 Center", "Enter search filter" (guidedFilterCount > 1 ? "s" : ""))
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y40 w320", "Type the text for each filter (order = priority).")
    global guidedFilterEdits := []
    yPos := 68
    loop guidedFilterCount {
        guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
        guidedWizGui.Add("Text", "x15 y" yPos " w80 h24 +0x200", "Filter " A_Index ":")
        guidedWizGui.SetFont("s9 c000000", "Segoe UI")
        ed := guidedWizGui.Add("Edit", "x100 y" yPos " w200 h24", "")
        guidedFilterEdits.Push(ed)
        yPos += 30
    }
    btnNext := DarkBtn(guidedWizGui, "x15 y" yPos " w100 h28", "Next →", _RED_BGR, _DK_BG, -12, true)
    btnNext.OnEvent("Click", GuidedStep3Next)
    btnBack := DarkBtn(guidedWizGui, "x120 y" yPos " w100 h28", "← Back", 0xDDDDDD, _DK_BG, -12, false)
    btnBack.OnEvent("Click", GuidedStep3Back)
    guidedWizGui.OnEvent("Close", GuidedCancel)
    guidedWizGui.Show("AutoSize " MacroPopupPos(350))
}

GuidedStep3Back(*) {
    global guidedWizGui
    try guidedWizGui.Destroy()
    global guidedWizGui := ""
    GuidedShowStep2()
}

GuidedStep3Next(*) {
    global guidedWizGui, guidedFilters, guidedFilterEdits
    global guidedFilters := []
    for , ed in guidedFilterEdits {
        val := Trim(ed.Value)
        if (val != "")
            guidedFilters.Push(val)
    }
    if (guidedFilters.Length = 0) {
        ToolTip("Enter at least one filter or go back and set 0")
        SetTimer(() => ToolTip(), -2000)
        return
    }
    guidedWizGui.Destroy()
    global guidedWizGui := ""
    GuidedShowStep4()
}

GuidedShowStep4() {
    global guidedWizGui, guidedInvType, guidedFilters
    guidedWizGui := Gui("+AlwaysOnTop", "Guided Macro — Step 4")
    guidedWizGui.BackColor := "1A1A1A"
    guidedWizGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y15 w340 Center", "Ready to Record")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    invLabel := StrTitle(guidedInvType)
    filterLabel := guidedFilters.Length > 0 ? guidedFilters.Length " filter(s)" : "no filter"
    guidedWizGui.Add("Text", "x15 y45 w340", "Inventory: " invLabel "  |  " filterLabel)
    guidedWizGui.Add("Text", "x15 y70 w340", "1) Click Start — we will activate ARK for you")
    guidedWizGui.Add("Text", "x15 y90 w340", "2) Press F to open inventory, then do your actions")
    guidedWizGui.Add("Text", "x15 y110 w340", "3) Press F1 when done recording")
    guidedWizGui.SetFont("s8 c888888 Italic", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y135 w340", "We auto-strip the F open/close and mouse travel.")
    guidedWizGui.Add("Text", "x15 y150 w340", "Just record slot clicks and key presses inside inv.")
    btnStart := DarkBtn(guidedWizGui, "x15 y178 w120 h28", "Start Recording", _RED_BGR, _DK_BG, -12, true)
    btnStart.OnEvent("Click", GuidedBeginRecord)
    btnBack := DarkBtn(guidedWizGui, "x140 y178 w100 h28", "← Back", 0xDDDDDD, _DK_BG, -12, false)
    btnBack.OnEvent("Click", GuidedStep4Back)
    guidedWizGui.OnEvent("Close", GuidedCancel)
    guidedWizGui.Show("AutoSize " MacroPopupPos(350))
}

GuidedStep4Back(*) {
    global guidedWizGui, guidedFilterCount
    try guidedWizGui.Destroy()
    global guidedWizGui := ""
    if (guidedFilterCount > 0)
        GuidedShowStep3()
    else
        GuidedShowStep2()
}

GuidedCancel(*) {
    global guidedWizGui, guidedRecording, guidedReRecordIdx, macroTabActive
    if (guidedRecording) {
        global guidedRecording := false
        global guidedReRecordIdx := 0
        GuidedRecordSetHotkeys(false)
        SetTimer(GuidedRecordMousePoll, 0)
    }
    try guidedWizGui.Destroy()
    global guidedWizGui := ""
    MacroRegisterHotkeys(macroTabActive)
}

GuidedBeginRecord(*) {
    global guidedWizGui, guidedRecording, guidedRecordEvents, guidedRecordLastTick
    global guidedRecordLastMouseX, guidedRecordLastMouseY
    global MainGui, guiVisible, arkwindow
    try guidedWizGui.Destroy()
    global guidedWizGui := ""
    global guidedRecordEvents := []
    CoordMode("Mouse", "Screen")
    MouseGetPos(&guidedRecordLastMouseX, &guidedRecordLastMouseY)
    global guidedRecording := true
    MainGui.Hide()
    global guiVisible := false
    MacroLog("GuidedRecord: START  invType=" guidedInvType "  filters=" guidedFilters.Length)
    MacroRegisterHotkeys(false)
    if WinExist(arkwindow)
        WinActivate(arkwindow)
    Sleep(500)
    global guidedRecordLastTick := A_TickCount
    GuidedRecordSetHotkeys(true)
    SetTimer(GuidedRecordMousePoll, 50)
    GuidedRecordTooltip()
}

GuidedRecordTooltip() {
    global guidedRecordEvents, guidedReRecordIdx
    mode := guidedReRecordIdx > 0 ? "RE-RECORDING" : "GUIDED RECORDING"
    ToolTip(" " mode "...  (" guidedRecordEvents.Length " events)`n F1 = Stop & Save", 0, 0)
}

GuidedRecordSetHotkeys(enable) {
    f := enable ? "On" : "Off"
    Loop 254 {
        if (A_Index = 112 || A_Index = 115)
            continue
        vk := Format("vk{:X}", A_Index)
        k := GetKeyName(vk)
        if (k != "" && !(k ~= "^(?i:|Control|Alt|Shift|LControl|RControl|LAlt|RAlt|LShift|RShift|LWin|RWin)$"))
            try Hotkey("~*" vk, GuidedRecordLogKey, f)
    }
    for , k in StrSplit("NumpadEnter|Home|End|PgUp|PgDn|Left|Right|Up|Down|Delete|Insert", "|") {
        sc := Format("sc{:03X}", GetKeySC(k))
        try Hotkey("~*" sc, GuidedRecordLogKey, f)
    }
}

GuidedRecordLogKey(thisHotkey) {
    global guidedRecording, guidedRecordEvents, guidedRecordLastTick
    if (!guidedRecording)
        return
    Critical()
    vksc := SubStr(thisHotkey, 3)
    k := GetKeyName(vksc)
    if (k = "") {
        Critical("Off")
        return
    }
    k := StrReplace(k, "Control", "Ctrl")
    r := SubStr(k, 2)
    if (r ~= "^(?i:Alt|Ctrl|Shift|Win)$") {
        GuidedRecordLogControl(k)
        Critical("Off")
        return
    }
    if (k ~= "^(?i:LButton|RButton|MButton)$") {
        GuidedRecordLogMouse(k)
        Critical("Off")
        return
    }
    now := A_TickCount
    delay := now - guidedRecordLastTick
    guidedRecordLastTick := now
    evt := {}
    evt.type := "K"
    evt.dir := "p"
    evt.key := k
    evt.delay := delay
    guidedRecordEvents.Push(evt)
    GuidedRecordTooltip()
    Critical("Off")
}

GuidedRecordLogControl(key) {
    global guidedRecording, guidedRecordEvents, guidedRecordLastTick
    k := InStr(key, "Win") ? key : SubStr(key, 2)
    now := A_TickCount
    delay := now - guidedRecordLastTick
    guidedRecordLastTick := now
    evt := {}
    evt.type := "K"
    evt.dir := "d"
    evt.key := k
    evt.delay := delay
    guidedRecordEvents.Push(evt)
    GuidedRecordTooltip()
    Critical("Off")
    KeyWait(key)
    Critical()
    now2 := A_TickCount
    delay2 := now2 - guidedRecordLastTick
    guidedRecordLastTick := now2
    evt2 := {}
    evt2.type := "K"
    evt2.dir := "u"
    evt2.key := k
    evt2.delay := delay2
    guidedRecordEvents.Push(evt2)
    GuidedRecordTooltip()
}

GuidedRecordLogMouse(key) {
    global guidedRecording, guidedRecordEvents, guidedRecordLastTick
    global guidedRecordLastMouseX, guidedRecordLastMouseY
    btn := SubStr(key, 1, 1)
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx, &my)
    now := A_TickCount
    delay := now - guidedRecordLastTick
    guidedRecordLastTick := now
    guidedRecordLastMouseX := mx
    guidedRecordLastMouseY := my
    evt := {}
    evt.type := "C"
    evt.dir := "d"
    evt.btn := btn
    evt.x := mx
    evt.y := my
    evt.delay := delay
    guidedRecordEvents.Push(evt)
    downIdx := guidedRecordEvents.Length
    t1 := A_TickCount
    Critical("Off")
    KeyWait(key)
    Critical()
    t2 := A_TickCount
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx2, &my2)
    delay2 := t2 - guidedRecordLastTick
    guidedRecordLastTick := t2
    guidedRecordLastMouseX := mx2
    guidedRecordLastMouseY := my2
    if (Abs(mx2 - mx) + Abs(my2 - my) < 5) {
        if (downIdx <= guidedRecordEvents.Length) {
            guidedRecordEvents.RemoveAt(downIdx)
        }
        evt3 := {}
        evt3.type := "C"
        evt3.dir := "c"
        evt3.btn := btn
        evt3.x := mx
        evt3.y := my
        evt3.delay := delay
        guidedRecordEvents.InsertAt(downIdx, evt3)
    } else {
        evt2 := {}
        evt2.type := "C"
        evt2.dir := "u"
        evt2.btn := btn
        evt2.x := mx2
        evt2.y := my2
        evt2.delay := delay2
        guidedRecordEvents.Push(evt2)
    }
    GuidedRecordTooltip()
}

GuidedRecordMousePoll() {
    global guidedRecording, guidedRecordEvents, guidedRecordLastTick
    global guidedRecordLastMouseX, guidedRecordLastMouseY
    if (!guidedRecording)
        return
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx, &my)
    if (Abs(mx - guidedRecordLastMouseX) + Abs(my - guidedRecordLastMouseY) > 12) {
        now := A_TickCount
        delay := now - guidedRecordLastTick
        guidedRecordLastTick := now
        guidedRecordLastMouseX := mx
        guidedRecordLastMouseY := my
        evt := {}
        evt.type := "M"
        evt.x := mx
        evt.y := my
        evt.delay := 0
        guidedRecordEvents.Push(evt)
    }
}

GuidedStopRecord() {
    global guidedRecording, guidedRecordEvents
    if (!guidedRecording)
        return false
    global guidedRecording := false
    GuidedRecordSetHotkeys(false)
    SetTimer(GuidedRecordMousePoll, 0)
    ToolTip()
    MacroLog("GuidedRecord: STOPPED  events=" guidedRecordEvents.Length)
    MacroRegisterHotkeys(macroTabActive)
    if (guidedRecordEvents.Length = 0) {
        MacroLog("GuidedRecord: empty — discarded")
        ToolTip(" Recording empty — discarded", 0, 0)
        SetTimer(() => ToolTip(), -2000)
        return true
    }
    GuidedShowSaveDialog()
    return true
}

GuidedShowSaveDialog() {
    global guidedWizGui, guidedRecordEvents, guidedInvType, guidedFilters, guidedMouseSpeed
    try {
        if (guidedWizGui != "")
            guidedWizGui.Destroy()
    }
    GuidedCleanRecordedEvents()
    guidedWizGui := Gui("+AlwaysOnTop", "Save Guided Macro")
    guidedWizGui.BackColor := "1A1A1A"
    guidedWizGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y15 w300", "Save Guided Macro")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    invLabel := StrTitle(guidedInvType)
    filterLabel := guidedFilters.Length > 0 ? guidedFilters.Length " filter(s)" : "no filter"
    guidedWizGui.Add("Text", "x15 y38 w300", invLabel " | " filterLabel " | " guidedRecordEvents.Length " events (cleaned)")
    guidedWizGui.Add("Text", "x15 y62 w55 h24 +0x200", "Name:")
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedNameEdit := guidedWizGui.Add("Edit", "x75 y62 w200 h24", "")
    guidedWizGui.SetFont("s9 c888888 Italic", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y92 w300", "Trigger: F at inventory (auto — no hotkey needed)")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    global guidedLoopChk := guidedWizGui.Add("CheckBox", "x15 y114 w55 h24", "Loop")
    global guidedTurboChk := guidedWizGui.Add("CheckBox", "x75 y114 w65 h24 Checked", "Turbo")
    guidedTurboChk.OnEvent("Click", GuidedTurboToggleSave)
    guidedWizGui.Add("Text", "x145 y114 w55 h24 +0x200", "gap ms:")
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedTurboEdit := guidedWizGui.Add("Edit", "x200 y114 w35 h24 +Number", "1")
    guidedWizGui.SetFont("s8 c888888 Italic", "Segoe UI")
    guidedWizGui.Add("Text", "x240 y118 w60", "max delay")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y142 w70 h24 +0x200", "Settle (ms):")
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedSettleEdit := guidedWizGui.Add("Edit", "x88 y142 w35 h24 +Number", "1")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x130 y142 w70 h24 +0x200", "Mouse spd:")
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedMouseEdit := guidedWizGui.Add("Edit", "x205 y142 w30 h24 +Number", "0")
    guidedWizGui.SetFont("s8 c888888 Italic", "Segoe UI")
    guidedWizGui.Add("Text", "x240 y146 w60", "0=instant")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y170 w105 h24 +0x200", "Inv load (ms):")
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global guidedLoadEdit := guidedWizGui.Add("Edit", "x125 y170 w50 h24 +Number", "1500")
    guidedWizGui.SetFont("s8 c888888 Italic", "Segoe UI")
    guidedWizGui.Add("Text", "x180 y174 w130", "wait for slots to populate")
    btnSave := DarkBtn(guidedWizGui, "x15 y202 w100 h28", "Save", _RED_BGR, _DK_BG, -12, true)
    btnSave.OnEvent("Click", GuidedDoSave)
    btnDiscard := DarkBtn(guidedWizGui, "x120 y202 w100 h28", "Discard", 0xDDDDDD, _DK_BG, -12, false)
    btnDiscard.OnEvent("Click", GuidedCancel)
    guidedWizGui.OnEvent("Close", GuidedCancel)
    guidedWizGui.Show("AutoSize " MacroPopupPos(350))
}

GuidedCleanRecordedEvents() {
    global guidedRecordEvents
    if (guidedRecordEvents.Length = 0)
        return
    stripped := 0
    while (guidedRecordEvents.Length > 0) {
        e := guidedRecordEvents[1]
        if (e.type = "K" && (e.key = "f" || e.key = "F" || e.key = "Escape")) {
            guidedRecordEvents.RemoveAt(1)
            stripped++
        } else if (e.type = "M") {
            guidedRecordEvents.RemoveAt(1)
            stripped++
        } else
            break
    }
    while (guidedRecordEvents.Length > 0) {
        e := guidedRecordEvents[guidedRecordEvents.Length]
        if (e.type = "M") {
            guidedRecordEvents.RemoveAt(guidedRecordEvents.Length)
            stripped++
        } else if (e.type = "K" && (e.key = "f" || e.key = "F" || e.key = "Escape")) {
            guidedRecordEvents.RemoveAt(guidedRecordEvents.Length)
            stripped++
        } else
            break
    }
    cleaned := []
    i := 1
    while (i <= guidedRecordEvents.Length) {
        e := guidedRecordEvents[i]
        if (e.type = "M") {
            lastM := e
            while (i + 1 <= guidedRecordEvents.Length && guidedRecordEvents[i + 1].type = "M") {
                i++
                lastM := guidedRecordEvents[i]
                stripped++
            }
            cleaned.Push(lastM)
        } else if (e.type = "C" && e.dir = "d") {
            hasUp := false
            if (i + 1 <= guidedRecordEvents.Length) {
                nxt := guidedRecordEvents[i + 1]
                if (nxt.type = "C" && nxt.dir = "u")
                    hasUp := true
            }
            if (!hasUp) {
                converted := {}
                converted.type := "C"
                converted.dir := "c"
                converted.btn := e.btn
                converted.x := e.x
                converted.y := e.y
                converted.delay := e.delay
                cleaned.Push(converted)
                MacroLog("GuidedClean: converted orphan C-down to C-click at (" e.x "," e.y ")")
            } else {
                cleaned.Push(e)
            }
        } else {
            cleaned.Push(e)
        }
        i++
    }
    global guidedRecordEvents := cleaned
    MacroLog("GuidedClean: stripped " stripped " events (leading F/mouse, trailing F/Esc/mouse, collapsed mouse, orphan C-down)")
}

GuidedTurboToggleSave(*) {
    global guidedTurboChk, guidedTurboEdit, guidedSettleEdit, guidedMouseEdit
    if (guidedTurboChk.Value) {
        guidedTurboEdit.Value := "1"
        guidedSettleEdit.Value := "1"
        guidedMouseEdit.Value := "0"
    } else {
        guidedTurboEdit.Value := "30"
        guidedSettleEdit.Value := "30"
        guidedMouseEdit.Value := "0"
    }
}

GuidedTurboToggleEdit(*) {
    global geTurboChk, geTurboEdit, geSettleEdit, geMouseEdit
    if (geTurboChk.Value) {
        geTurboEdit.Value := "1"
        geSettleEdit.Value := "1"
        geMouseEdit.Value := "0"
    } else {
        geTurboEdit.Value := "30"
        geSettleEdit.Value := "30"
        geMouseEdit.Value := "0"
    }
}

GuidedDoSave(*) {
    global guidedWizGui, guidedRecordEvents, guidedFilters, guidedInvType
    global guidedNameEdit, guidedLoopChk, guidedMouseEdit, guidedSettleEdit, guidedLoadEdit
    global guidedTurboChk, guidedTurboEdit
    global macroList, macroTabActive, macroSelectedIdx
    name := Trim(guidedNameEdit.Value)
    if (name = "") {
        ToolTip("Enter a name!")
        SetTimer(() => ToolTip(), -1500)
        return
    }
    m := {}
    m.name := name
    m.type := "guided"
    m.hotkey := "f"
    m.speedMult := 1.0
    m.loopEnabled := guidedLoopChk.Value
    m.invType := guidedInvType
    m.mouseSpeed := Integer(guidedMouseEdit.Value)
    m.mouseSettle := Integer(guidedSettleEdit.Value)
    m.invLoadDelay := Integer(guidedLoadEdit.Value)
    m.turbo := guidedTurboChk.Value ? 1 : 0
    m.turboDelay := Integer(guidedTurboEdit.Value)
    m.searchFilters := []
    for , f in guidedFilters
        m.searchFilters.Push(f)
    m.events := []
    for , e in guidedRecordEvents
        m.events.Push(e)
    macroList.Push(m)
    global macroSelectedIdx := macroList.Length
    MacroSaveAll()
    MacroUpdateListView()
    try guidedWizGui.Destroy()
    global guidedWizGui := ""
    global guidedRecordEvents := []
    MacroRegisterHotkeys(macroTabActive)
    MacroLog("GuidedSave: '" name "' saved — " m.events.Length " events, " m.searchFilters.Length " filters, hk=" m.hotkey)
    ToolTip(" Guided macro '" name "' saved! (" m.events.Length " events, " m.searchFilters.Length " filters)", 0, 0)
    SetTimer(() => ToolTip(), -3000)
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; GUIDED PLAYBACK

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

GuidedPlayThread(m) {
    global macroPlaying, macroActiveIdx, macroArmed, arkwindow, guidedSingleItem, guiVisible, gmkMode
    global pcInvDetectX, pcInvDetectY, guidedInvReadyX, guidedInvReadyY, guidedInvReadyColor, guidedInvReadyTol
    global pcSearchBarX, pcSearchBarY, pcStartSlotX, pcStartSlotY
    myIdx := macroActiveIdx
    CoordMode("Mouse", "Screen")
    CoordMode("Pixel", "Screen")
    mouseSpd := m.HasProp("mouseSpeed") ? m.mouseSpeed : 0
    settle := m.HasProp("mouseSettle") ? m.mouseSettle : 30
    filters := m.HasProp("searchFilters") ? m.searchFilters : []
    global guidedSingleItem := false

    MacroLog("GuidedPlay: START persistent '" m.name "' filters=" filters.Length " events=" m.events.Length " mouseSpd=" mouseSpd " settle=" settle "ms load=" (m.HasProp("invLoadDelay") ? m.invLoadDelay : 1500) "ms")

    GuidedShowArmedTooltip(m)

    while (macroPlaying) {
        if (MacroDialogOpen()) {
            Sleep(100)
            continue
        }

        CoordMode("Mouse", "Screen")
        MouseGetPos(&gmhx, &gmhy)
        mouseOnArk := (gmhx >= 0 && gmhx < A_ScreenWidth && gmhy >= 0 && gmhy < A_ScreenHeight)

        if (GetKeyState("q", "P") && mouseOnArk) {
            while (GetKeyState("q", "P") && macroPlaying)
                Sleep(50)
            global guidedSingleItem := !guidedSingleItem
            MacroLog("GuidedPlay: Q → single item mode " (guidedSingleItem ? "ON" : "OFF"))
            GuidedShowArmedTooltip(m)
        }

        if (GetKeyState("f", "P") && mouseOnArk && gmkMode = "off" && WinActive(arkwindow)) {
            invAlreadyOpen := false
            try invAlreadyOpen := NFSearchTol(&iox, &ioy, pcInvDetectX, pcInvDetectY, pcInvDetectX+2, pcInvDetectY+2, "0xFFFFFF", 10)
            catch
                invAlreadyOpen := false
            if (invAlreadyOpen) {
                while (GetKeyState("f", "P") && macroPlaying)
                    Sleep(50)
                continue
            }
            while (GetKeyState("f", "P") && macroPlaying)
                Sleep(50)
            MacroLog("GuidedPlay: F pressed — waiting for inventory")
            invFound := false
            start := A_TickCount
            loop {
                if (!macroPlaying)
                    break
                try {
                    if NFSearchTol(&px, &py, pcInvDetectX, pcInvDetectY, pcInvDetectX+2, pcInvDetectY+2, "0xFFFFFF", 10) {
                        invFound := true
                        break
                    }
                }
                if (A_TickCount - start > 5000)
                    break
                Sleep(50)
            }
            if (!invFound) {
                MacroLog("GuidedPlay: inventory TIMEOUT")
                ToolTip(" Inventory not detected — press F at an inventory`n F1 = Stop", 0, 0)
                SetTimer(() => GuidedShowArmedTooltip(m), -2000)
                continue
            }
            MacroLog("GuidedPlay: inventory detected after " (A_TickCount - start) "ms")

            usePlBar := m.HasProp("playerSearch") && m.playerSearch

            if (usePlBar) {
                Sleep(50)
                MacroLog("GuidedPlay: playerSearch — skipping slot-ready wait")
            } else {
                loadDelay := m.HasProp("invLoadDelay") ? m.invLoadDelay : 1500
                readyStart := A_TickCount
                slotsReady := false
                loop {
                    if (!macroPlaying)
                        break
                    try {
                        if NFSearchTol(&rpx, &rpy, guidedInvReadyX, guidedInvReadyY, guidedInvReadyX+2, guidedInvReadyY+2, guidedInvReadyColor, guidedInvReadyTol) {
                            slotsReady := true
                            break
                        }
                    }
                    if (A_TickCount - readyStart > loadDelay)
                        break
                    Sleep(16)
                }
                readyMs := A_TickCount - readyStart
                if (slotsReady) {
                    MacroLog("GuidedPlay: slots READY after " readyMs "ms — settling 150ms")
                    Sleep(150)
                } else
                    MacroLog("GuidedPlay: slots TIMEOUT after " readyMs "ms — proceeding")
            }

            if (filters.Length = 1) {
                GuidedApplySearchFilter(filters[1], usePlBar)
            } else if (filters.Length > 1) {
                GuidedApplySearchFilter(filters[1], usePlBar)
            } else {
            }

            if (m.HasProp("popcornAll") && m.popcornAll && m.events.Length = 0) {
                MacroLog("GuidedPlay: popcornAll — running drop loop")
                GuidedPopcornAllLoop()
                MacroLog("GuidedPlay: popcornAll drop loop done")
            } else {
                turboOn := m.HasProp("turbo") && m.turbo
                modeLabel := guidedSingleItem ? "SINGLE" : (turboOn ? "FAST" : "FULL")
                MacroLog("GuidedPlay: replaying (" modeLabel ") " m.events.Length " events")
                if (guidedSingleItem)
                    GuidedReplaySingle(m, mouseSpd)
                else if (turboOn)
                    GuidedReplayFastTransfer(m, mouseSpd)
                else
                    GuidedReplayEvents(m, mouseSpd)
                MacroLog("GuidedPlay: replay done")
            }

            if (macroPlaying) {
                MacroLog("GuidedPlay: closing inventory")
                Send("{Escape}")
                closeStart := A_TickCount
                loop {
                    Sleep(50)
                    if (A_TickCount - closeStart > 2000)
                        break
                    try {
                        if !NFSearchTol(&cpx, &cpy, pcInvDetectX, pcInvDetectY, pcInvDetectX+2, pcInvDetectY+2, "0xFFFFFF", 10)
                            break
                    } catch
                        break
                }
                closeMs := A_TickCount - closeStart
                MacroLog("GuidedPlay: inventory closed after " closeMs "ms")
            }

            GuidedShowArmedTooltip(m)
        }

        Sleep(50)
    }

    MacroLog("GuidedPlay: STOPPED")
    global guidedSingleItem := false
    if (macroActiveIdx = myIdx) {
        global macroPlaying := false
        global macroActiveIdx := 0
        MacroSaveIfDirty()
    }
    ToolTip()
}

GuidedReplaySingle(m, mouseSpd) {
    global macroPlaying
    CoordMode("Mouse", "Screen")
    settle := m.HasProp("mouseSettle") ? m.mouseSettle : 30
    turbo := m.HasProp("turbo") ? m.turbo : 0
    turboDelay := m.HasProp("turboDelay") ? m.turboDelay : 30
    clickToKeyGap := 60

    MacroLog("GuidedReplaySingle: finding first transfer unit")
    clickDone := false
    keyDone := false
    for evtIdx, evt in m.events {
        if (!macroPlaying)
            return
        if (evt.type = "M") {
            MouseMove(evt.x, evt.y, mouseSpd)
            if (settle > 0)
                Sleep(settle)
            MacroLog("GuidedReplaySingle: [" evtIdx "] M move(" evt.x "," evt.y ")")
        } else if (evt.type = "C" && !clickDone) {
            useDelay := turbo ? Min(Integer(evt.delay * m.speedMult), turboDelay) : Integer(evt.delay * m.speedMult)
            if (useDelay > 0)
                Sleep(useDelay)
            if (!macroPlaying)
                return
            MouseMove(evt.x, evt.y, mouseSpd)
            if (settle > 0)
                Sleep(settle)
            Click(evt.HasProp("dir") && evt.dir = "d" ? evt.btn " Down" : evt.HasProp("dir") && evt.dir = "u" ? evt.btn " Up" : evt.btn)
            MacroLog("GuidedReplaySingle: [" evtIdx "] C click " evt.btn " (" evt.x "," evt.y ")")
            clickDone := true
        } else if (evt.type = "K" && clickDone && !keyDone) {
            Sleep(clickToKeyGap)
            if (!macroPlaying)
                return
            kName := StrLen(evt.key) > 1 ? "{" evt.key "}" : evt.key
            Send(kName)
            MacroLog("GuidedReplaySingle: [" evtIdx "] K press '" evt.key "' (c2k=" clickToKeyGap ")")
            keyDone := true
        }
        if (clickDone && keyDone)
            break
    }
    MacroLog("GuidedReplaySingle: done — 1 item transferred")
}

GuidedShowArmedTooltip(m) {
    global macroArmed, guidedSingleItem
    if (!macroArmed)
        return
    keyStr := m.hotkey != "" ? " [" StrUpper(m.hotkey) "]" : ""
    filters := m.HasProp("searchFilters") ? m.searchFilters : []
    settle := m.HasProp("mouseSettle") ? m.mouseSettle : 30
    if (m.HasProp("playerSearch") && m.playerSearch) {
        actionLabel := "Give"
    } else {
        hasClicks := false
        if (m.HasProp("events")) {
            for , evt in m.events {
                if (evt.type = "C") {
                    hasClicks := true
                    break
                }
            }
        }
        actionLabel := hasClicks ? "Take" : "Drop"
    }
    modeStr := guidedSingleItem ? "SINGLE (1 item)" : actionLabel " (" m.events.Length " events)"
    filterHint := ""
    if (filters.Length > 0) {
        filterHint := "`n Filters: "
        for i, f in filters
            filterHint .= (i > 1 ? ", " : "") f
    }
    ToolTip(" ► " m.name " — " modeStr filterHint "`n" MacroSpeedHint(m) "`n F = run  |  Q = toggle single/full  |  Z = next macro  |  F1 = Stop", 0, 0)
}

GuidedApplySearchFilter(filter, usePlayerBar := false) {
    global arkwindow, pcSearchBarX, pcSearchBarY, pcStartSlotX, pcStartSlotY
    global mySearchBarX, mySearchBarY, plStartSlotX, plStartSlotY
    if (filter = "")
        return
    if !WinExist(arkwindow) {
        MacroLog("GuidedApplyFilter: ARK not found")
        return
    }
    sbX := usePlayerBar ? mySearchBarX : pcSearchBarX
    sbY := usePlayerBar ? mySearchBarY : pcSearchBarY
    slX := usePlayerBar ? plStartSlotX : pcStartSlotX
    slY := usePlayerBar ? plStartSlotY : pcStartSlotY
    MacroLog("GuidedApplyFilter: applying [" filter "] searchBar=(" sbX "," sbY ") playerBar=" usePlayerBar)
    WinActivate(arkwindow)
    Sleep(usePlayerBar ? 30 : 80)
    ControlClick("x" sbX " y" sbY, arkwindow,,,,"NA")
    Sleep(usePlayerBar ? 50 : 120)
    _savedClip := A_Clipboard
    A_Clipboard := filter
    SendInput("^a")
    Sleep(usePlayerBar ? 20 : 30)
    SendInput("^v")
    Sleep(usePlayerBar ? 120 : 250)
    A_Clipboard := _savedClip
    ControlClick("x" slX " y" slY, arkwindow,,,,"NA")
    Sleep(usePlayerBar ? 50 : 120)
    MacroLog("GuidedApplyFilter: [" filter "] applied")
}

RebuildGuidedEvents(action, count, key) {
    global pcStartSlotX, pcStartSlotY, pcSlotW, pcSlotH, pcColumns
    global plStartSlotX, plStartSlotY, plSlotW, plSlotH
    if (action = "give") {
        startX := plStartSlotX
        startY := plStartSlotY
        slotW := plSlotW
        slotH := plSlotH
        cols := 6
    } else {
        startX := pcStartSlotX
        startY := pcStartSlotY
        slotW := pcSlotW
        slotH := pcSlotH
        cols := pcColumns
    }
    gridSize := cols * 6
    events := []
    if (count <= 0)
        return events
    remaining := count
    while (remaining > 0) {
        slot := 0
        clicked := 0
        Loop 6 {
            row := A_Index - 1
            Loop cols {
                col := A_Index - 1
                slot++
                if (slot > remaining || slot > gridSize)
                    break
                x := startX + col * slotW
                y := startY + row * slotH
                if (action = "take" || action = "give") {
                    if (events.Length > 0)
                        events.Push({type: "M", x: x, y: y, delay: 0})
                    events.Push({type: "C", dir: "c", btn: "L", x: x, y: y, delay: 100})
                    events.Push({type: "K", dir: "p", key: key, delay: 60})
                } else {
                    events.Push({type: "M", x: x, y: y, delay: 0})
                    events.Push({type: "K", dir: "p", key: key, delay: 20})
                }
                clicked++
            }
            if (slot > remaining || slot > gridSize)
                break
        }
        remaining -= Min(clicked, gridSize)
    }
    return events
}

GuidedPopcornAllLoop() {
    global macroPlaying, pcStartSlotX, pcStartSlotY, pcSlotW, pcSlotH
    global pcColumns, pcRows, pcDropKey, pcDropSleep, pcHoverDelay, pcCycleSleep
    global pcEarlyExit, pcF1Abort
    CoordMode("Mouse", "Screen")
    global pcEarlyExit := false
    global pcF1Abort := false
    PcRunDropLoop("guided-pc", 0)
    MacroLog("GuidedPopcornAll: drop loop done")
}

GuidedReplayFastTransfer(m, mouseSpd) {
    global macroPlaying, pcDropSleep, pcHoverDelay, pcColumns
    CoordMode("Mouse", "Screen")

    slots := []
    for , evt in m.events {
        if (evt.type = "C" && (evt.dir = "c" || evt.dir = "d")) {
            slots.Push({x: evt.x, y: evt.y})
        }
    }

    transferKey := ""
    for , evt in m.events {
        if (evt.type = "K" && evt.dir = "p") {
            transferKey := evt.key
            break
        }
    }
    if (transferKey = "")
        transferKey := "t"

    if (slots.Length > 0) {
        isGive := m.HasProp("playerSearch") && m.playerSearch
        giveMulti := isGive && slots.Length > 1
        xferLabel := isGive ? "GIVE" : "TAKE"
        MacroLog("GuidedFastXfer: " xferLabel " mode — " slots.Length " slots, key=" transferKey)
        for i, slot in slots {
            if (!macroPlaying)
                return
            MouseMove(slot.x, slot.y, mouseSpd)
            Sleep(giveMulti ? 80 : 50)
            Click()
            Sleep(giveMulti ? 50 : 30)
            if (!macroPlaying)
                return
            kName := StrLen(transferKey) > 1 ? "{" transferKey "}" : transferKey
            Send(kName)
            MacroLog("GuidedFastXfer: [" i "] click+" transferKey " (" slot.x "," slot.y ")")
            if (i < slots.Length)
                Sleep(giveMulti ? 130 : 100)
        }
        MacroLog("GuidedFastXfer: DONE " slots.Length " items")
        return
    }

    dropSlots := []
    for , evt in m.events {
        if (evt.type = "M") {
            dropSlots.Push({x: evt.x, y: evt.y})
        }
    }

    if (dropSlots.Length > 0) {
        MacroLog("GuidedFastXfer: POPCORN mode — " dropSlots.Length " slots, key=" transferKey)
        for i, slot in dropSlots {
            if (!macroPlaying)
                return
            MouseMove(slot.x, slot.y, mouseSpd)
            Sleep(50)
            Click()
            Sleep(30)
            if (!macroPlaying)
                return
            Send("{" transferKey "}")
            if (i < dropSlots.Length)
                Sleep(50)
        }
        MacroLog("GuidedFastXfer: DONE " dropSlots.Length " drops")
        return
    }

    MacroLog("GuidedFastXfer: no slots found — falling back to generic replay")
    GuidedReplayEvents(m, mouseSpd)
}

GuidedReplayEvents(m, mouseSpd) {
    global macroPlaying
    CoordMode("Mouse", "Screen")
    evtTotal := m.events.Length
    settle := m.HasProp("mouseSettle") ? m.mouseSettle : 30
    hk := m.HasProp("hotkey") ? m.hotkey : ""

    cleaned := []
    skippedHk := 0
    collapsedM := 0
    i := 1
    while (i <= evtTotal) {
        evt := m.events[i]
        if (cleaned.Length = 0 && evt.type = "K" && evt.dir = "p" && StrLower(evt.key) = StrLower(hk)) {
            skippedHk++
            i++
            continue
        }
        if (evt.type = "M") {
            lastM := evt
            runCount := 1
            while (i + 1 <= evtTotal && m.events[i + 1].type = "M") {
                i++
                lastM := m.events[i]
                runCount++
            }
            if (runCount > 1)
                collapsedM += runCount - 1
            cleaned.Push(lastM)
        } else {
            cleaned.Push(evt)
        }
        i++
    }

    turbo := m.HasProp("turbo") ? m.turbo : 0
    turboDelay := m.HasProp("turboDelay") ? m.turboDelay : 30
    clickToKeyGap := 100
    keyToClickGap := 200

    MacroLog("GuidedReplay: START " evtTotal " raw → " cleaned.Length " clean  skippedHk=" skippedHk "  collapsedM=" collapsedM "  mouseSpd=" mouseSpd "  settle=" settle "ms  speedMult=" Format("{:.2f}", m.speedMult) "  turbo=" turbo " gap=" turboDelay " c2k=" clickToKeyGap " k2c=" keyToClickGap)

    prevType := "K"
    for evtIdx, evt in cleaned {
        if (!macroPlaying) {
            MacroLog("GuidedReplay: stopped at event " evtIdx "/" cleaned.Length)
            return
        }
        rawDelay := Integer(evt.delay * m.speedMult)
        turboTag := ""
        if (turbo) {
            if (prevType = "C" && evt.type = "K") {
                useDelay := clickToKeyGap
                turboTag := " (turbo c2k)"
            } else if (prevType = "K" && evt.type = "C") {
                useDelay := keyToClickGap
                turboTag := " (turbo k2c)"
            } else if (prevType = "K" && evt.type = "M") {
                useDelay := 0
                turboTag := ""
            } else {
                useDelay := Min(rawDelay, turboDelay)
                if (useDelay < rawDelay)
                    turboTag := " (turbo cap " turboDelay ")"
            }
        } else {
            useDelay := rawDelay
        }
        if (evt.type = "C")
            prevType := "C"
        else if (evt.type = "K")
            prevType := "K"
        if (evt.type = "M") {
            MouseMove(evt.x, evt.y, mouseSpd)
            if (settle > 0)
                Sleep(settle)
            MacroLog("GuidedReplay: [" evtIdx "] M move(" evt.x "," evt.y ") settle=" settle)
        } else if (evt.type = "K") {
            if (useDelay > 0)
                Sleep(useDelay)
            if (!macroPlaying)
                return
            switch evt.dir {
                case "p":
                    kName := StrLen(evt.key) > 1 ? "{" evt.key "}" : evt.key
                    Send(kName)
                    MacroLog("GuidedReplay: [" evtIdx "] K press '" evt.key "' delay=" useDelay turboTag)
                case "d":
                    Send("{" evt.key " Down}")
                    MacroLog("GuidedReplay: [" evtIdx "] K down '" evt.key "' delay=" useDelay turboTag)
                case "u":
                    Send("{" evt.key " Up}")
                    MacroLog("GuidedReplay: [" evtIdx "] K up '" evt.key "' delay=" useDelay turboTag)
            }
        } else if (evt.type = "C") {
            if (!macroPlaying)
                return
            switch evt.dir {
                case "c":
                    MouseMove(evt.x, evt.y, mouseSpd)
                    hoverWait := useDelay > settle ? useDelay : settle
                    if (hoverWait > 0)
                        Sleep(hoverWait)
                    Click(evt.btn)
                    MacroLog("GuidedReplay: [" evtIdx "] C click " evt.btn " (" evt.x "," evt.y ") hover=" hoverWait turboTag)
                case "d":
                    MouseMove(evt.x, evt.y, mouseSpd)
                    hoverWait := useDelay > settle ? useDelay : settle
                    if (hoverWait > 0)
                        Sleep(hoverWait)
                    Click(evt.btn " Down")
                    MacroLog("GuidedReplay: [" evtIdx "] C down " evt.btn " (" evt.x "," evt.y ") hover=" hoverWait turboTag)
                case "u":
                    MouseMove(evt.x, evt.y, mouseSpd)
                    hoverWait := useDelay > settle ? useDelay : settle
                    if (hoverWait > 0)
                        Sleep(hoverWait)
                    Click(evt.btn " Up")
                    MacroLog("GuidedReplay: [" evtIdx "] C up " evt.btn " (" evt.x "," evt.y ") hover=" hoverWait turboTag)
            }
        }
    }
    MacroLog("GuidedReplay: DONE " cleaned.Length " events played")
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; POPCORN + MAGIC-F COMBO WIZARD

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ComboStartWizard(*) {
    global comboWizGui, macroList, macroPlaying, pcDropKey
    if (macroPlaying)
        return
    if (macroList.Length >= 10) {
        ToolTip(" Max 10 macros — delete one first", 0, 0)
        SetTimer(() => ToolTip(), -2000)
        return
    }
    MacroBlockAllHotkeys()
    if (pcDropKey = "") {
        global pcDropKey := "g"
    }
    savedDrop := ""
    try savedDrop := IniRead(A_ScriptDir "\AIO_config.ini", "Popcorn", "DropKey", "")
    if (savedDrop != "") {
        ComboShowSinglePage()
    } else {
        GuidedShowDropKeyPrompt("combo")
    }
}

ComboShowSinglePage() {
    global comboWizGui, comboPopcornFilters, comboMagicFFilters
    global comboTakeCount, comboTakeFilter
    try {
        if (comboWizGui != "")
            comboWizGui.Destroy()
    }
    comboWizGui := Gui("+AlwaysOnTop", "Link: Popcorn + Magic F")
    comboWizGui.BackColor := "1A1A1A"
    y := 16
    comboWizGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    comboWizGui.Add("Text", "x16 y" y " w250", "Link: Popcorn + Magic F")
    cHelpBtn := DarkBtn(comboWizGui, "x300 y" (y - 2) " w24 h24", "?", _RED_BGR, _DK_BG, -11, true)
    cHelpBtn.OnEvent("Click", ComboShowSinglePageHelp)
    y += 34
    comboWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    comboWizGui.Add("Text", "x16 y" y " w120 h24 +0x200", "Popcorn filters:")
    comboWizGui.SetFont("s9 c000000", "Segoe UI")
    global comboSpPcEdit := comboWizGui.Add("Edit", "x140 y" y " w190 h24", "")
    y += 26
    comboWizGui.SetFont("s8 c888888 Italic", "Segoe UI")
    comboWizGui.Add("Text", "x140 y" y " w190", "comma-separated (empty = all)")
    y += 20
    comboWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    comboWizGui.Add("Text", "x16 y" y " w120 h24 +0x200", "Magic F filters:")
    comboWizGui.SetFont("s9 c000000", "Segoe UI")
    global comboSpMfEdit := comboWizGui.Add("Edit", "x140 y" y " w190 h24", "")
    y += 26
    comboWizGui.SetFont("s8 c888888 Italic", "Segoe UI")
    comboWizGui.Add("Text", "x140 y" y " w190", "comma-separated")
    y += 26
    comboWizGui.Add("Progress", "x16 y" y " w318 h1 Background333333")
    y += 10
    comboWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    comboWizGui.Add("Text", "x16 y" y " w55 h24 +0x200", "Name:")
    comboWizGui.SetFont("s9 c000000", "Segoe UI")
    global comboSpNameEdit := comboWizGui.Add("Edit", "x140 y" y " w190 h24", "PC+MF")
    y += 28
    saveBtn := DarkBtn(comboWizGui, "x16 y" y " w100 h26", "Save", _RED_BGR, _DK_BG, -12, true)
    saveBtn.OnEvent("Click", ComboSpSave)
    cancelBtn := DarkBtn(comboWizGui, "x200 y" y " w100 h26", "Cancel", 0xDDDDDD, _DK_BG, -12, false)
    cancelBtn.OnEvent("Click", ComboCancel)
    comboWizGui.OnEvent("Close", ComboCancel)
    comboWizGui.Show("w350 h" (y + 36) " " MacroPopupPos(350))
}

ComboShowSinglePageHelp(*) {
    static hGui := ""
    if IsObject(hGui) {
        try hGui.Destroy()
        hGui := ""
        return
    }
    hGui := Gui("+AlwaysOnTop +ToolWindow", "Combo Help")
    hGui.BackColor := "1A1A1A"
    hGui.SetFont("s9 Bold cFF4444", "Segoe UI")
    hGui.Add("Text", "x10 y8 w280", "POPCORN + MAGIC F")
    hGui.SetFont("s8 cDDDDDD", "Segoe UI")
    hGui.Add("Text", "x10 y30 w280",
        "Two-phase macro: Popcorn then Magic F.`n`n"
        "Popcorn: F at inventory → drops items.`n"
        "Magic F: F at trough → filter + give.`n"
        "Q swaps between phases. Z exits.`n`n"
        "Use multiple filters separated by commas.`n"
        "Leave Popcorn empty to drop all items.`n"
        "Each filter runs one full grid pass.")
    hGui.OnEvent("Close", (*) => (hGui.Destroy(), hGui := ""))
    hGui.Show("w300 h200 " MacroPopupPos(300))
}

ComboSpSave(*) {
    global comboWizGui, comboSpPcEdit, comboSpMfEdit, comboSpNameEdit
    global comboPopcornFilters, comboMagicFFilters, comboTakeCount, comboTakeFilter
    global macroList, macroTabActive, macroSelectedIdx

    name := Trim(comboSpNameEdit.Value)
    if (name = "") {
        ToolTip("Enter a name!")
        SetTimer(() => ToolTip(), -1500)
        return
    }

    pcRaw := comboSpPcEdit.Value
    pcFilters := []
    for , part in StrSplit(pcRaw, ",") {
        v := Trim(part)
        if (v != "")
            pcFilters.Push(v)
    }
    if (pcFilters.Length = 0)
        pcFilters.Push("")

    mfRaw := comboSpMfEdit.Value
    mfFilters := []
    for , part in StrSplit(mfRaw, ",") {
        v := Trim(part)
        if (v != "")
            mfFilters.Push(v)
    }

    m := {}
    m.name := name
    m.type := "combo"
    m.hotkey := ""
    m.popcornFilters := pcFilters
    m.magicFFilters := mfFilters
    m.takeCount := 0
    m.takeFilter := ""

    macroList.Push(m)
    global macroSelectedIdx := macroList.Length
    MacroSaveAll()
    MacroUpdateListView()
    try comboWizGui.Destroy()
    global comboWizGui := ""
    MacroRegisterHotkeys(macroTabActive)
    ToolTip(" Combo '" name "' saved! (P:" pcFilters.Length " M:" mfFilters.Length ")", 0, 0)
    SetTimer(() => ToolTip(), -3000)
}

ComboShowStep1() {
    global comboWizGui
    try {
        if (comboWizGui != "")
            comboWizGui.Destroy()
    }
    comboWizGui := Gui("+AlwaysOnTop", "Popcorn+Magic-F — Step 1")
    comboWizGui.BackColor := "1A1A1A"
    comboWizGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    comboWizGui.Add("Text", "x15 y15 w350 Center", "Popcorn Filters")
    comboWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    comboWizGui.Add("Text", "x15 y40 w350", "How many items to popcorn? (0 = all, no filter)")
    comboWizGui.Add("Text", "x15 y60 w350", "Q cycles through them. When done, Z swaps to Magic F.")
    comboWizGui.SetFont("s9 c000000", "Segoe UI")
    comboWizGui.Add("Text", "x15 y90 w80 h24 +0x200 cDDDDDD", "Count:")
    global comboPC_CountEdit := comboWizGui.Add("Edit", "x100 y90 w50 h24 +Number", "0")
    btnNext := DarkBtn(comboWizGui, "x15 y125 w100 h28", "Next →", _RED_BGR, _DK_BG, -12, true)
    btnNext.OnEvent("Click", ComboStep1Next)
    btnCancel := DarkBtn(comboWizGui, "x120 y125 w100 h28", "Cancel", 0xDDDDDD, _DK_BG, -12, false)
    btnCancel.OnEvent("Click", ComboCancel)
    comboWizGui.OnEvent("Close", ComboCancel)
    comboWizGui.Show("AutoSize " MacroPopupPos(380))
}

ComboStep1Next(*) {
    global comboWizGui, comboPC_CountEdit, comboPopcornFilters
    pcCount := Integer(comboPC_CountEdit.Value)
    if (pcCount < 0) pcCount := 0
    if (pcCount > 10) pcCount := 10
    try comboWizGui.Hide()
    if (pcCount = 0) {
        global comboPopcornFilters := [""]
        ComboShowStep3()
    } else {
        ComboShowStep2(pcCount)
    }
}

ComboShowStep2(pcCount) {
    global comboWizGui
    comboWizGui := Gui("+AlwaysOnTop", "Popcorn+Magic-F — Step 2")
    comboWizGui.BackColor := "1A1A1A"
    comboWizGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    comboWizGui.Add("Text", "x15 y15 w350 Center", "Popcorn Filter Names")
    comboWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    comboWizGui.Add("Text", "x15 y40 w350", "Type search text for each filter. Blank = all items.")
    global comboPcEdits := []
    yPos := 68
    loop pcCount {
        comboWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
        comboWizGui.Add("Text", "x15 y" yPos " w80 h24 +0x200", "Pop " A_Index ":")
        comboWizGui.SetFont("s9 c000000", "Segoe UI")
        ed := comboWizGui.Add("Edit", "x100 y" yPos " w220 h24", "")
        comboPcEdits.Push(ed)
        yPos += 30
    }
    btnNext := DarkBtn(comboWizGui, "x15 y" yPos " w100 h28", "Next →", _RED_BGR, _DK_BG, -12, true)
    btnNext.OnEvent("Click", ComboStep2Next)
    btnBack := DarkBtn(comboWizGui, "x120 y" yPos " w100 h28", "← Back", 0xDDDDDD, _DK_BG, -12, false)
    btnBack.OnEvent("Click", ComboStep2Back)
    comboWizGui.OnEvent("Close", ComboCancel)
    comboWizGui.Show("AutoSize " MacroPopupPos(380))
}

ComboStep2Back(*) {
    global comboWizGui
    try comboWizGui.Destroy()
    global comboWizGui := ""
    ComboShowStep1()
}

ComboStep2Next(*) {
    global comboWizGui, comboPcEdits, comboPopcornFilters
    global comboPopcornFilters := []
    for , ed in comboPcEdits {
        comboPopcornFilters.Push(Trim(ed.Value))
    }
    try comboWizGui.Hide()
    ComboShowStep3()
}

ComboShowStep3() {
    global comboWizGui
    try {
        if (comboWizGui != "")
            comboWizGui.Destroy()
    }
    comboWizGui := Gui("+AlwaysOnTop", "Popcorn+Magic-F — Step 3")
    comboWizGui.BackColor := "1A1A1A"
    comboWizGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    comboWizGui.Add("Text", "x15 y15 w350 Center", "Magic F Give Filters")
    comboWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    comboWizGui.Add("Text", "x15 y40 w350", "How many items to Magic F Give? (0 = skip Magic F)")
    comboWizGui.SetFont("s9 c000000", "Segoe UI")
    comboWizGui.Add("Text", "x15 y68 w80 h24 +0x200 cDDDDDD", "Count:")
    global comboMF_CountEdit := comboWizGui.Add("Edit", "x100 y68 w50 h24 +Number", "1")
    btnNext := DarkBtn(comboWizGui, "x15 y105 w100 h28", "Next →", _RED_BGR, _DK_BG, -12, true)
    btnNext.OnEvent("Click", ComboStep3Next)
    btnBack := DarkBtn(comboWizGui, "x120 y105 w100 h28", "← Back", 0xDDDDDD, _DK_BG, -12, false)
    btnBack.OnEvent("Click", ComboStep3Back)
    comboWizGui.OnEvent("Close", ComboCancel)
    comboWizGui.Show("AutoSize " MacroPopupPos(380))
}

ComboStep3Back(*) {
    global comboWizGui, comboPopcornFilters
    try comboWizGui.Hide()
    ComboShowStep2(comboPopcornFilters.Length)
}

ComboStep3Next(*) {
    global comboWizGui, comboMF_CountEdit
    mfCount := Integer(comboMF_CountEdit.Value)
    if (mfCount < 1) mfCount := 1
    if (mfCount > 10) mfCount := 10
    try comboWizGui.Hide()
    ComboShowStep4(mfCount)
}

ComboShowStep4(mfCount) {
    global comboWizGui
    try {
        if (comboWizGui != "")
            comboWizGui.Destroy()
    }
    comboWizGui := Gui("+AlwaysOnTop", "Popcorn+Magic-F — Step 4")
    comboWizGui.BackColor := "1A1A1A"
    comboWizGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    comboWizGui.Add("Text", "x15 y15 w350 Center", "Magic F Give Filter Names")
    comboWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    comboWizGui.Add("Text", "x15 y40 w350", "Type the search text for each Magic F give filter.")
    global comboMfEdits := []
    yPos := 68
    loop mfCount {
        comboWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
        comboWizGui.Add("Text", "x15 y" yPos " w80 h24 +0x200", "Give " A_Index ":")
        comboWizGui.SetFont("s9 c000000", "Segoe UI")
        ed := comboWizGui.Add("Edit", "x100 y" yPos " w220 h24", "")
        comboMfEdits.Push(ed)
        yPos += 30
    }
    btnNext := DarkBtn(comboWizGui, "x15 y" yPos " w100 h28", "Next →", _RED_BGR, _DK_BG, -12, true)
    btnNext.OnEvent("Click", ComboStep4Next)
    btnBack := DarkBtn(comboWizGui, "x120 y" yPos " w100 h28", "← Back", 0xDDDDDD, _DK_BG, -12, false)
    btnBack.OnEvent("Click", ComboStep4Back)
    comboWizGui.OnEvent("Close", ComboCancel)
    comboWizGui.Show("AutoSize " MacroPopupPos(380))
}

ComboStep4Back(*) {
    global comboWizGui
    try comboWizGui.Hide()
    ComboShowStep3()
}

ComboStep4Next(*) {
    global comboWizGui, comboMfEdits, comboMagicFFilters
    global comboMagicFFilters := []
    for , ed in comboMfEdits {
        val := Trim(ed.Value)
        if (val != "")
            comboMagicFFilters.Push(val)
    }
    if (comboMagicFFilters.Length = 0) {
        ToolTip("Enter at least one Magic F filter!")
        SetTimer(() => ToolTip(), -2000)
        return
    }
    try comboWizGui.Hide()
    global comboTakeCount := 0
    global comboTakeFilter := ""
    ComboShowSaveDialog()
}

ComboShowStep5() {
    global comboWizGui
    try {
        if (comboWizGui != "")
            comboWizGui.Destroy()
    }
    comboWizGui := Gui("+AlwaysOnTop", "Popcorn+Magic-F — Step 5")
    comboWizGui.BackColor := "1A1A1A"
    comboWizGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    comboWizGui.Add("Text", "x15 y15 w350 Center", "Take Mode (optional)")
    comboWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    comboWizGui.Add("Text", "x15 y40 w350", "F at vault → take N items → close. Set 0 to skip.")
    comboWizGui.Add("Text", "x15 y60 w350", "Q cycles: Popcorn → Magic F → Take → Popcorn")
    comboWizGui.Add("Text", "x15 y90 w100 h24 +0x200", "Items per F:")
    comboWizGui.SetFont("s9 c000000", "Segoe UI")
    global comboTakeCountEdit := comboWizGui.Add("Edit", "x120 y90 w40 h24 +Number", "0")
    comboWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    comboWizGui.Add("Text", "x15 y120 w100 h24 +0x200", "Search filter:")
    comboWizGui.SetFont("s9 c000000", "Segoe UI")
    global comboTakeFilterEdit := comboWizGui.Add("Edit", "x120 y120 w200 h24", "")
    comboWizGui.SetFont("s8 c888888 Italic", "Segoe UI")
    comboWizGui.Add("Text", "x15 y148 w320", "Blank = take from first slots. Filter = search then take.")
    btnNext := DarkBtn(comboWizGui, "x15 y175 w100 h28", "Next →", _RED_BGR, _DK_BG, -12, true)
    btnNext.OnEvent("Click", ComboStep5Next)
    btnBack := DarkBtn(comboWizGui, "x120 y175 w100 h28", "← Back", 0xDDDDDD, _DK_BG, -12, false)
    btnBack.OnEvent("Click", ComboStep5Back)
    comboWizGui.OnEvent("Close", ComboCancel)
    comboWizGui.Show("AutoSize " MacroPopupPos(380))
}

ComboStep5Back(*) {
    global comboWizGui, comboMagicFFilters
    try comboWizGui.Hide()
    ComboShowStep4(comboMagicFFilters.Length)
}

ComboStep5Next(*) {
    global comboWizGui, comboTakeCountEdit, comboTakeFilterEdit
    global comboTakeCount := Integer(comboTakeCountEdit.Value)
    global comboTakeFilter := Trim(comboTakeFilterEdit.Value)
    if (comboTakeCount < 0)
        global comboTakeCount := 0
    if (comboTakeCount > 36)
        global comboTakeCount := 36
    try comboWizGui.Hide()
    ComboShowSaveDialog()
}

ComboShowSaveDialog() {
    global comboWizGui, comboPopcornFilters, comboMagicFFilters, comboTakeCount, comboTakeFilter
    try {
        if (comboWizGui != "")
            comboWizGui.Destroy()
    }
    comboWizGui := Gui("+AlwaysOnTop", "Save Popcorn+Magic-F Combo")
    comboWizGui.BackColor := "1A1A1A"
    comboWizGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    comboWizGui.Add("Text", "x15 y15 w300 Center", "Save Combo Macro")
    comboWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    pcList := ""
    for i, f in comboPopcornFilters
        pcList .= (i > 1 ? ", " : "") (f = "" ? "(all)" : f)
    mfList := ""
    for i, f in comboMagicFFilters
        mfList .= (i > 1 ? ", " : "") f
    comboWizGui.Add("Text", "x15 y40 w300", "Popcorn: " pcList)
    mfLabel := comboMagicFFilters.Length > 0 ? mfList : "(none)"
    comboWizGui.Add("Text", "x15 y58 w300", "Magic F: " mfLabel)
    comboWizGui.Add("Text", "x15 y82 w55 h24 +0x200", "Name:")
    comboWizGui.SetFont("s9 c000000", "Segoe UI")
    global comboNameEdit := comboWizGui.Add("Edit", "x75 y82 w200 h24", "")
    comboWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    comboWizGui.Add("Text", "x15 y112 w55 h24 +0x200", "Hotkey:")
    comboWizGui.SetFont("s9 c000000", "Segoe UI")
    global comboHkEdit := comboWizGui.Add("Edit", "x75 y112 w100 h24 ReadOnly", "")
    comboHkDetect := DarkBtn(comboWizGui, "x180 y112 w75 h24", "Detect", _RED_BGR, _DK_BG, -11, true)
    comboHkDetect.OnEvent("Click", ComboDetectHotkey)
    btnSave := DarkBtn(comboWizGui, "x15 y148 w100 h28", "Save", _RED_BGR, _DK_BG, -12, true)
    btnSave.OnEvent("Click", ComboDoSave)
    btnDiscard := DarkBtn(comboWizGui, "x120 y148 w100 h28", "Cancel", 0xDDDDDD, _DK_BG, -12, false)
    btnDiscard.OnEvent("Click", ComboCancel)
    comboWizGui.OnEvent("Close", ComboCancel)
    comboWizGui.Show("AutoSize " MacroPopupPos(380))
}

ComboDetectHotkey(*) {
    global comboHkEdit
    comboHkEdit.Value := "..."
    ih := InputHook("L1 T10")
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{F1}{F4}", "-E")
    ih.Start()
    ih.Wait()
    if (ih.EndReason = "EndKey")
        comboHkEdit.Value := StrLower(ih.EndKey)
    else
        comboHkEdit.Value := ""
}

ComboDoSave(*) {
    global comboWizGui, comboPopcornFilters, comboMagicFFilters, comboTakeCount, comboTakeFilter
    global comboNameEdit, comboHkEdit
    global macroList, macroTabActive, macroSelectedIdx
    name := Trim(comboNameEdit.Value)
    hk := Trim(comboHkEdit.Value)
    if (name = "") {
        ToolTip("Enter a name!")
        SetTimer(() => ToolTip(), -1500)
        return
    }
    m := {}
    m.name := name
    m.type := "combo"
    m.hotkey := (hk != "..." ? hk : "")
    m.popcornFilters := []
    for , f in comboPopcornFilters
        m.popcornFilters.Push(f)
    m.magicFFilters := []
    for , f in comboMagicFFilters
        m.magicFFilters.Push(f)
    m.takeCount := comboTakeCount
    m.takeFilter := comboTakeFilter
    macroList.Push(m)
    global macroSelectedIdx := macroList.Length
    MacroSaveAll()
    MacroUpdateListView()
    try comboWizGui.Destroy()
    global comboWizGui := ""
    MacroRegisterHotkeys(macroTabActive)
    tkLabel := comboTakeCount > 0 ? " take:" comboTakeCount : ""
    MacroLog("ComboSave: '" name "' saved — pop:" comboPopcornFilters.Length " mf:" comboMagicFFilters.Length tkLabel " hk=" m.hotkey)
    ToolTip(" Combo '" name "' saved! (Pop:" comboPopcornFilters.Length " MF:" comboMagicFFilters.Length tkLabel ")", 0, 0)
    SetTimer(() => ToolTip(), -3000)
}

ComboCancel(*) {
    global comboWizGui, comboRunning
    if (comboRunning) {
        global comboRunning := false
    }
    try comboWizGui.Destroy()
    global comboWizGui := ""
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; COMBO PLAYBACK (Popcorn + Magic-F)

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ComboPlayThread(m) {
    global macroPlaying, macroActiveIdx, arkwindow, comboRunning, comboMode, comboFilterIdx, guiVisible, gmkMode
    global pcInvDetectX, pcInvDetectY
    global pcSearchBarX, pcSearchBarY, pcStartSlotX, pcStartSlotY
    global theirInvSearchBarX, theirInvSearchBarY, theirInvDropAllButtonX, theirInvDropAllButtonY
    global transferToMeButtonX, transferToMeButtonY
    global pcDropKey, pcCycleSleep, pcInvKey
    myIdx := macroActiveIdx
    CoordMode("Mouse", "Screen")
    CoordMode("Pixel", "Screen")

    global comboRunning := true
    global comboMode := 1
    global comboFilterIdx := 1
    pcFilters := m.popcornFilters
    mfFilters := m.magicFFilters
    if (pcFilters.Length = 0)
        pcFilters := [""]
    if (mfFilters.Length = 0)
        mfFilters := [""]

    MacroLog("ComboPlay: START '" m.name "' pcFilters=" pcFilters.Length " mfFilters=" mfFilters.Length)

    firstEntry := true

    while (macroPlaying && comboRunning) {

        if (comboMode = 1) {

            if (!macroPlaying || !comboRunning)
                break
            curFilter := pcFilters[comboFilterIdx]
            filterLabel := curFilter = "" ? "(all)" : curFilter
            MacroLog("ComboPlay: POPCORN mode  filterIdx=" comboFilterIdx " filter=" filterLabel)
            ToolTip(ComboBuildTooltip(m, "popcorn", comboFilterIdx, pcFilters, mfFilters), 0, 0)

            if (firstEntry) {
                firstEntry := false
                try invOpen := WinActive(arkwindow) && NFSearchTol(&fpx, &fpy, pcInvDetectX, pcInvDetectY, pcInvDetectX+2, pcInvDetectY+2, "0xFFFFFF", 10)
                catch
                    invOpen := false
                if (invOpen) {
                    MacroLog("ComboPlay: inventory already open — popcorning")
                    if (curFilter != "")
                        ComboApplyTheirFilter(curFilter)
                    ComboPopcornDropLoop(m, pcFilters, mfFilters)
                }
            }

            while (macroPlaying && comboRunning && comboMode = 1) {
                if (MacroDialogOpen()) {
                    Sleep(100)
                    continue
                }
                if (GetKeyState("q", "P")) {
                    while (GetKeyState("q", "P") && macroPlaying)
                        Sleep(50)
                    try invIsOpen := NFSearchTol(&qpx, &qpy, pcInvDetectX, pcInvDetectY, pcInvDetectX+2, pcInvDetectY+2, "0xFFFFFF", 10)
                    catch
                        invIsOpen := false
                    if (invIsOpen) {
                        Send("{Escape}")
                        Sleep(300)
                    }
                    global comboMode := 2
                    global comboFilterIdx := 1
                    MacroLog("ComboPlay: Q → swapped to MAGIC F")
                    ToolTip(ComboBuildTooltip(m, "magicf", comboFilterIdx, pcFilters, mfFilters), 0, 0)
                    break
                }
                if (GetKeyState("r", "P")) {
                    while (GetKeyState("r", "P") && macroPlaying)
                        Sleep(50)
                    try invIsOpen := NFSearchTol(&rpx, &rpy, pcInvDetectX, pcInvDetectY, pcInvDetectX+2, pcInvDetectY+2, "0xFFFFFF", 10)
                    catch
                        invIsOpen := false
                    if (invIsOpen) {
                        MacroLog("ComboPlay: R → closing inventory, staying popcorn")
                        Send("{Escape}")
                        Sleep(300)
                    }
                    ToolTip(ComboBuildTooltip(m, "popcorn", comboFilterIdx, pcFilters, mfFilters), 0, 0)
                }
                if (GetKeyState("z", "P")) {
                    while (GetKeyState("z", "P") && macroPlaying)
                        Sleep(50)
                    MacroLog("ComboPlay: Z → exiting combo")
                    global comboRunning := false
                    break
                }
                CoordMode("Mouse", "Screen")
                MouseGetPos(&cmhx, &cmhy)
                comboMouseOk := (cmhx >= 0 && cmhx < A_ScreenWidth && cmhy >= 0 && cmhy < A_ScreenHeight)
                if (GetKeyState("f", "P") && comboMouseOk && gmkMode = "off" && WinActive(arkwindow)) {
                    comboInvOpen := false
                    try comboInvOpen := NFSearchTol(&ciox, &cioy, pcInvDetectX, pcInvDetectY, pcInvDetectX+2, pcInvDetectY+2, "0xFFFFFF", 10)
                    catch
                        comboInvOpen := false
                    if (comboInvOpen) {
                        while (GetKeyState("f", "P") && macroPlaying)
                            Sleep(50)
                        continue
                    }
                    while (GetKeyState("f", "P") && macroPlaying)
                        Sleep(50)
                    MacroLog("ComboPlay: F pressed — waiting for inventory")
                    Sleep(100)
                    if (!ComboWaitForInv(3000)) {
                        MacroLog("ComboPlay: inventory TIMEOUT")
                        ToolTip(" Inventory not detected — try again`n" ComboBuildTooltip(m, "popcorn", comboFilterIdx, pcFilters, mfFilters), 0, 0)
                    } else {
                        curFilter := pcFilters[comboFilterIdx]
                        if (curFilter != "") {
                            MacroLog("ComboPlay: applying filter [" curFilter "]")
                            ComboApplyTheirFilter(curFilter)
                        } else {
                            MacroLog("ComboPlay: no filter — dropping all")
                        }
                        ComboPopcornDropLoop(m, pcFilters, mfFilters)
                    }
                }
                Sleep(50)
            }

        } else if (comboMode = 2) {

            if (!macroPlaying || !comboRunning)
                break
            curFilter := mfFilters[comboFilterIdx]
            filterLabel := curFilter = "" ? "(all)" : curFilter
            MacroLog("ComboPlay: MAGIC F mode (armed)  filterIdx=" comboFilterIdx " filter=" filterLabel)
            ToolTip(ComboBuildTooltip(m, "magicf", comboFilterIdx, pcFilters, mfFilters), 0, 0)

            while (macroPlaying && comboRunning && comboMode = 2) {
                if (MacroDialogOpen()) {
                    Sleep(100)
                    continue
                }
                if (GetKeyState("q", "P")) {
                    while (GetKeyState("q", "P") && macroPlaying)
                        Sleep(50)
                    global comboMode := 1
                    global comboFilterIdx := 1
                    MacroLog("ComboPlay: Q → swapped to POPCORN")
                    ToolTip(ComboBuildTooltip(m, "popcorn", comboFilterIdx, pcFilters, mfFilters), 0, 0)
                    break
                }
                if (GetKeyState("r", "P")) {
                    while (GetKeyState("r", "P") && macroPlaying)
                        Sleep(50)
                    if (mfFilters.Length > 1) {
                        global comboFilterIdx := comboFilterIdx >= mfFilters.Length ? 1 : comboFilterIdx + 1
                        MacroLog("ComboPlay: R → MF filter #" comboFilterIdx)
                        ToolTip(ComboBuildTooltip(m, "magicf", comboFilterIdx, pcFilters, mfFilters), 0, 0)
                    }
                }
                if (GetKeyState("z", "P")) {
                    while (GetKeyState("z", "P") && macroPlaying)
                        Sleep(50)
                    MacroLog("ComboPlay: Z → exiting combo")
                    global comboRunning := false
                    break
                }
                CoordMode("Mouse", "Screen")
                MouseGetPos(&cmhx, &cmhy)
                comboMouseOk := (cmhx >= 0 && cmhx < A_ScreenWidth && cmhy >= 0 && cmhy < A_ScreenHeight)
                if (GetKeyState("f", "P") && comboMouseOk && gmkMode = "off" && WinActive(arkwindow)) {
                    comboInvOpen := false
                    try comboInvOpen := NFSearchTol(&ciox, &cioy, pcInvDetectX, pcInvDetectY, pcInvDetectX+2, pcInvDetectY+2, "0xFFFFFF", 10)
                    catch
                        comboInvOpen := false
                    if (comboInvOpen) {
                        while (GetKeyState("f", "P") && macroPlaying)
                            Sleep(50)
                        continue
                    }
                    while (GetKeyState("f", "P") && macroPlaying)
                        Sleep(50)
                    MacroLog("ComboPlay: F pressed — waiting for inventory (MF give)")
                    Sleep(100)
                    if (!ComboWaitForInv(3000)) {
                        MacroLog("ComboPlay: MF inventory TIMEOUT")
                        ToolTip(" Inventory not detected — try again`n" ComboBuildTooltip(m, "magicf", comboFilterIdx, pcFilters, mfFilters), 0, 0)
                    } else {
                        curFilter := mfFilters[comboFilterIdx]
                        MacroLog("ComboPlay: MF filter #" comboFilterIdx " [" (curFilter = "" ? "(all)" : curFilter) "] → Transfer All")
                        ComboApplyMyFilter(curFilter)
                        ComboMagicFGive()
                        MacroLog("ComboPlay: MF give done — closing inv")
                        Send("{Escape}")
                        Sleep(300)
                        ToolTip(ComboBuildTooltip(m, "magicf", comboFilterIdx, pcFilters, mfFilters), 0, 0)
                    }
                }
                Sleep(50)
            }
        }
    }

    MacroLog("ComboPlay: STOPPED")
    global comboRunning := false
    global comboMode := 0
    global comboFilterIdx := 1
    if (macroActiveIdx = myIdx) {
        global macroPlaying := false
        global macroActiveIdx := 0
        MacroSaveIfDirty()
        ToolTip(" " m.name " stopped", 0, 0)
        SetTimer(() => ToolTip(), -2000)
    }
}

ComboWaitForInv(maxMs := 3000) {
    global pcInvDetectX, pcInvDetectY
    start := A_TickCount
    loop {
        if NFSearchTol(&px, &py, pcInvDetectX, pcInvDetectY, pcInvDetectX+2, pcInvDetectY+2, "0xFFFFFF", 10)
            return true
        if (A_TickCount - start > maxMs)
            return false
        Sleep(50)
    }
}

ComboApplyTheirFilter(filter) {
    global arkwindow, theirInvSearchBarX, theirInvSearchBarY, pcStartSlotX, pcStartSlotY
    if (filter = "" || !WinExist(arkwindow))
        return
    WinActivate(arkwindow)
    Sleep(80)
    ControlClick("x" theirInvSearchBarX " y" theirInvSearchBarY, arkwindow,,,,"NA")
    Sleep(120)
    _savedClip := A_Clipboard
    A_Clipboard := filter
    SendInput("^a")
    Sleep(30)
    SendInput("^v")
    Sleep(250)
    A_Clipboard := _savedClip
    ControlClick("x" pcStartSlotX " y" pcStartSlotY, arkwindow,,,,"NA")
    Sleep(200)
}

ComboApplyMyFilter(filter) {
    global arkwindow, mySearchBarX, mySearchBarY
    if (filter = "" || !WinExist(arkwindow))
        return
    ControlClick("x" mySearchBarX " y" mySearchBarY, arkwindow)
    Sleep(30)
    Send(filter)
    Sleep(100)
}

ComboPopcornDropLoop(m, pcFilters, mfFilters) {
    global macroPlaying, comboRunning, comboMode, comboFilterIdx, arkwindow
    global pcDropKey, pcStartSlotX, pcStartSlotY, pcSlotW, pcSlotH, pcColumns, pcRows
    global pcDropSleep, pcHoverDelay
    if (!macroPlaying || !comboRunning || !WinExist(arkwindow))
        return
    startIdx := comboFilterIdx
    Loop pcFilters.Length {
        fi := startIdx + A_Index - 1
        if (fi > pcFilters.Length)
            break
        if (!macroPlaying || !comboRunning)
            return
        global comboFilterIdx := fi
        curFilter := pcFilters[fi]
        if (fi > startIdx) {
            if (curFilter != "") {
                MacroLog("ComboPlay: auto-cycling to filter #" fi " [" curFilter "]")
                ComboApplyTheirFilter(curFilter)
            } else {
                MacroLog("ComboPlay: auto-cycling to filter #" fi " (all)")
                PcClearFilter()
            }
        }
        ToolTip(ComboBuildTooltip(m, "dropping", comboFilterIdx, pcFilters, mfFilters), 0, 0)
        MacroLog("ComboPlay: drop grid filter #" fi " rows=" pcRows " cols=" pcColumns)
        passNum := 0
        ocrFails := 0
        stallCount := 0
        lastStorage := -99
        filterDone := false
        while (macroPlaying && comboRunning) {
            passNum++
            Loop pcRows {
                row := A_Index - 1
                Loop pcColumns {
                    col := A_Index - 1
                    if (!macroPlaying || !comboRunning)
                        return
                    if (GetKeyState("r", "P")) {
                        while (GetKeyState("r", "P") && macroPlaying)
                            Sleep(50)
                        MacroLog("ComboPlay: R → closing inv from drop grid (pass " passNum ")")
                        Send("{Escape}")
                        Sleep(300)
                        ToolTip(ComboBuildTooltip(m, "popcorn", comboFilterIdx, pcFilters, mfFilters), 0, 0)
                        return
                    }
                    if (!WinActive(arkwindow))
                        continue
                    x := pcStartSlotX + col * pcSlotW
                    y := pcStartSlotY + row * pcSlotH
                    DllCall("SetCursorPos", "int", x, "int", y)
                    if (row = 0)
                        Sleep(pcHoverDelay)
                    PcFastKey(pcDropKey)
                    if (pcDropSleep > 0)
                        Sleep(pcDropSleep)
                }
            }
            MacroLog("ComboPlay: drop grid pass " passNum " done (filter #" fi ")")
            if (passNum >= 2) {
                chk := PcCheckStorageEmpty()
                MacroLog("ComboPlay: drop pass " passNum " OCR=" chk)
                if (chk = 0) {
                    MacroLog("ComboPlay: storage empty after pass " passNum " — filter #" fi " done")
                    filterDone := true
                    break
                }
                if (chk = -1) {
                    ocrFails++
                    if (ocrFails >= 6) {
                        MacroLog("ComboPlay: 6 OCR fails — assuming filter #" fi " done")
                        filterDone := true
                        break
                    }
                } else {
                    ocrFails := 0
                    if (chk = lastStorage) {
                        stallCount++
                        if (stallCount >= 3) {
                            MacroLog("ComboPlay: stalled at " chk " for 3 passes — filter #" fi " done or drop cap")
                            filterDone := true
                            break
                        }
                    } else {
                        lastStorage := chk
                        stallCount := 0
                    }
                }
            }
            Sleep(5)
        }
        if (!filterDone)
            break
    }
    Send("{Escape}")
    Sleep(300)
    ToolTip(ComboBuildTooltip(m, "popcorn", comboFilterIdx, pcFilters, mfFilters), 0, 0)
}

ComboMagicFGive() {
    global macroPlaying, comboRunning, arkwindow
    global transferToOtherButtonX, transferToOtherButtonY
    if (!macroPlaying || !comboRunning || !WinExist(arkwindow))
        return
    ControlClick("x" transferToOtherButtonX " y" transferToOtherButtonY, arkwindow)
    Sleep(100)
}

ComboBuildTooltip(m, phase, idx, pcFilters, mfFilters) {
    tt := " ═══ " m.name " ═══"
    if (phase = "popcorn") {
        cur := idx <= pcFilters.Length ? (pcFilters[idx] = "" ? "(all)" : pcFilters[idx]) : "?"
        tt .= "`n MODE: POPCORN  [" cur "]"
        if (pcFilters.Length > 1) {
            tt .= "`n Filters: "
            for i, f in pcFilters {
                label := f = "" ? "(all)" : f
                tt .= (i = idx ? "►" label "◄" : label) (i < pcFilters.Length ? " → " : "")
            }
        }
        tt .= "`n`n F = open inv & drop  |  Q = → Magic F"
        tt .= "`n R = close inv  |  Z = exit combo  |  F1 = Stop"
    } else if (phase = "dropping") {
        cur := idx <= pcFilters.Length ? (pcFilters[idx] = "" ? "(all)" : pcFilters[idx]) : "?"
        tt .= "`n DROPPING  [" cur "]"
        tt .= "`n`n R = close inv & stop  |  F1 = Stop"
    } else if (phase = "magicf") {
        cur := idx <= mfFilters.Length ? (mfFilters[idx] = "" ? "(all)" : mfFilters[idx]) : "?"
        tt .= "`n MODE: MAGIC F GIVE  [" cur "]"
        if (mfFilters.Length > 1) {
            tt .= "`n Filters: "
            for i, f in mfFilters {
                label := f = "" ? "(all)" : f
                tt .= (i = idx ? "►" label "◄" : label) (i < mfFilters.Length ? " → " : "")
            }
        }
        tt .= "`n`n F = open inv & give (auto-close)"
        rHint := mfFilters.Length > 1 ? "  |  R = next filter" : ""
        tt .= "`n Q = → Popcorn" rHint "  |  Z = exit  |  F1 = Stop"
    }
    return tt
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; GUIDED & COMBO EDIT DIALOGS

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

GuidedShowEditDialog(idx) {
    global macroList, macroEditGui, macroTabActive
    MacroBlockAllHotkeys()
    m := macroList[idx]
    try {
        if (macroEditGui != "")
            macroEditGui.Destroy()
    }
    macroEditGui := Gui("+AlwaysOnTop", "Edit Guided Macro")
    macroEditGui.BackColor := "1A1A1A"
    macroEditGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    macroEditGui.Add("Text", "x15 y15 w300", "Edit: " m.name)
    macroEditGui.SetFont("s9 cDDDDDD", "Segoe UI")
    invLabel := m.HasProp("invType") ? StrTitle(m.invType) : "Storage"
    fCount := m.HasProp("searchFilters") ? m.searchFilters.Length : 0
    eCount := m.HasProp("events") ? m.events.Length : 0
    macroEditGui.Add("Text", "x15 y38 w300", invLabel " | " fCount " filter(s) | " eCount " events")
    macroEditGui.Add("Text", "x15 y62 w55 h24 +0x200", "Name:")
    macroEditGui.SetFont("s9 c000000", "Segoe UI")
    global geNameEdit := macroEditGui.Add("Edit", "x75 y62 w200 h24", m.name)
    macroEditGui.SetFont("s9 c888888 Italic", "Segoe UI")
    macroEditGui.Add("Text", "x15 y92 w300", "Trigger: F at inventory (auto)")
    macroEditGui.SetFont("s9 cDDDDDD", "Segoe UI")
    global geLoopChk := macroEditGui.Add("CheckBox", "x15 y114 w55 h24 " (m.loopEnabled ? "Checked" : ""), "Loop")
    global geTurboChk := macroEditGui.Add("CheckBox", "x75 y114 w65 h24 " ((m.HasProp("turbo") && m.turbo) ? "Checked" : ""), "Turbo")
    geTurboChk.OnEvent("Click", GuidedTurboToggleEdit)
    macroEditGui.Add("Text", "x145 y114 w55 h24 +0x200", "gap ms:")
    macroEditGui.SetFont("s9 c000000", "Segoe UI")
    global geTurboEdit := macroEditGui.Add("Edit", "x200 y114 w35 h24 +Number", String(m.HasProp("turboDelay") ? m.turboDelay : 30))
    macroEditGui.SetFont("s8 c888888 Italic", "Segoe UI")
    macroEditGui.Add("Text", "x240 y118 w60", "max delay")
    macroEditGui.SetFont("s9 cDDDDDD", "Segoe UI")
    macroEditGui.Add("Text", "x15 y142 w70 h24 +0x200", "Settle (ms):")
    macroEditGui.SetFont("s9 c000000", "Segoe UI")
    global geSettleEdit := macroEditGui.Add("Edit", "x88 y142 w35 h24 +Number", String(m.HasProp("mouseSettle") ? m.mouseSettle : 30))
    macroEditGui.SetFont("s9 cDDDDDD", "Segoe UI")
    macroEditGui.Add("Text", "x130 y142 w70 h24 +0x200", "Mouse spd:")
    macroEditGui.SetFont("s9 c000000", "Segoe UI")
    global geMouseEdit := macroEditGui.Add("Edit", "x205 y142 w30 h24 +Number", String(m.HasProp("mouseSpeed") ? m.mouseSpeed : 0))
    macroEditGui.SetFont("s8 c888888 Italic", "Segoe UI")
    macroEditGui.Add("Text", "x240 y146 w60", "0=instant")
    macroEditGui.SetFont("s9 cDDDDDD", "Segoe UI")
    macroEditGui.Add("Text", "x15 y170 w105 h24 +0x200", "Inv load (ms):")
    macroEditGui.SetFont("s9 c000000", "Segoe UI")
    global geLoadEdit := macroEditGui.Add("Edit", "x125 y170 w50 h24 +Number", String(m.HasProp("invLoadDelay") ? m.invLoadDelay : 1500))
    macroEditGui.SetFont("s8 c888888 Italic", "Segoe UI")
    macroEditGui.Add("Text", "x180 y174 w130", "wait for slots to populate")
    geRerecordBtn := DarkBtn(macroEditGui, "x15 y202 w140 h28", "Re-record Actions", _RED_BGR, _DK_BG, -12, true)
    geRerecordBtn.OnEvent("Click", GuidedReRecord.Bind(idx))
    macroEditGui.SetFont("s8 c888888 Italic", "Segoe UI")
    macroEditGui.Add("Text", "x160 y208 w150", "keeps settings, new recording")
    geSaveBtn := DarkBtn(macroEditGui, "x15 y238 w100 h28", "Save", _RED_BGR, _DK_BG, -12, true)
    geSaveBtn.OnEvent("Click", GuidedEditSave.Bind(idx))
    geCancelBtn := DarkBtn(macroEditGui, "x120 y238 w100 h28", "Cancel", 0xDDDDDD, _DK_BG, -12, false)
    geCancelBtn.OnEvent("Click", (*) => GuidedEditClose())
    macroEditGui.OnEvent("Close", (*) => GuidedEditClose())
    macroEditGui.Show("AutoSize " MacroPopupPos(350))
}

GuidedReRecord(idx, *) {
    global macroList, macroEditGui, macroTabActive
    global geNameEdit, geLoopChk, geMouseEdit, geSettleEdit, geLoadEdit
    global geTurboChk, geTurboEdit
    global guidedRecording, guidedRecordEvents, guidedRecordLastTick
    global guidedRecordLastMouseX, guidedRecordLastMouseY
    global guidedReRecordIdx, guidedWizGui
    global MainGui, guiVisible, arkwindow
    global pcStartSlotX, pcStartSlotY, pcSlotW, pcSlotH, pcColumns
    m := macroList[idx]
    name := Trim(geNameEdit.Value)
    if (name != "")
        m.name := name
    m.hotkey := "f"
    m.loopEnabled := geLoopChk.Value
    m.turbo := geTurboChk.Value ? 1 : 0
    m.turboDelay := Integer(geTurboEdit.Value)
    m.mouseSpeed := Integer(geMouseEdit.Value)
    m.mouseSettle := Integer(geSettleEdit.Value)
    m.invLoadDelay := Integer(geLoadEdit.Value)
    macroList[idx] := m
    MacroSaveAll()
    try macroEditGui.Destroy()
    global macroEditGui := ""

    hasClicks := false
    hasMoves := false
    dropKey := ""
    if (m.HasProp("events")) {
        for , evt in m.events {
            if (evt.type = "C")
                hasClicks := true
            if (evt.type = "M")
                hasMoves := true
            if (evt.type = "K" && evt.dir = "p" && dropKey = "")
                dropKey := evt.key
        }
    }

    isTake := hasClicks && (dropKey = "t" || dropKey = "T")
    isGive := isTake && m.HasProp("playerSearch") && m.playerSearch
    if (isGive)
        isTake := false
    isPopcorn := !hasClicks && hasMoves && dropKey != "" && dropKey != "t" && dropKey != "T"

    if (isTake || isPopcorn || isGive) {
        slotCount := 0
        if (m.HasProp("events")) {
            if (isTake || isGive) {
                for , evt in m.events
                    if (evt.type = "C")
                        slotCount++
            } else {
                for , evt in m.events
                    if (evt.type = "M")
                        slotCount++
            }
        }
        filter := ""
        if (m.HasProp("searchFilters") && m.searchFilters.Length > 0)
            filter := m.searchFilters[1]
        reMode := isGive ? "give" : (isTake ? "take" : "popcorn")
        GuidedShowReRecordSetup(idx, reMode, slotCount, dropKey, filter)
        return
    }

    global guidedReRecordIdx := idx
    global guidedRecordEvents := []
    CoordMode("Mouse", "Screen")
    MouseGetPos(&guidedRecordLastMouseX, &guidedRecordLastMouseY)
    global guidedRecording := true
    MainGui.Hide()
    global guiVisible := false
    MacroLog("GuidedReRecord: START for '" m.name "' idx=" idx " (old events=" m.events.Length ")")
    MacroRegisterHotkeys(false)
    if WinExist(arkwindow)
        WinActivate(arkwindow)
    Sleep(500)
    global guidedRecordLastTick := A_TickCount
    GuidedRecordSetHotkeys(true)
    SetTimer(GuidedRecordMousePoll, 50)
    ToolTip(" RE-RECORDING: " m.name " (0 events)`n Open inventory and perform actions`n F1 = Stop & Save", 0, 0)
}

GuidedShowReRecordSetup(idx, mode, slotCount, dropKey, filter) {
    global guidedWizGui, macroList, pcDropKey
    global pcStartSlotX, pcStartSlotY, pcSlotW, pcSlotH, pcColumns, macroTabActive
    m := macroList[idx]
    try {
        if (guidedWizGui != "")
            guidedWizGui.Destroy()
    }
    MacroBlockAllHotkeys()
    if (mode = "give")
        title := "Adjust Give — " m.name
    else
        title := mode = "take" ? "Adjust Take — " m.name : "Adjust Popcorn — " m.name
    guidedWizGui := Gui("+AlwaysOnTop", title)
    guidedWizGui.BackColor := "1A1A1A"
    guidedWizGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    if (mode = "give")
        guidedWizGui.Add("Text", "x15 y15 w300 Center", "Adjust Give Slots")
    else
        guidedWizGui.Add("Text", "x15 y15 w300 Center", mode = "take" ? "Adjust Take Slots" : "Adjust Popcorn Slots")
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    guidedWizGui.Add("Text", "x15 y45 w100 h24 +0x200", "Items:")
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global geReRecSlotEdit := guidedWizGui.Add("Edit", "x120 y45 w50 h24 +Number", String(slotCount))
    guidedWizGui.SetFont("s8 c888888 Italic", "Segoe UI")
    guidedWizGui.Add("Text", "x175 y49 w130", ">36 loops the grid")
    if (mode = "popcorn") {
        guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
        guidedWizGui.Add("Text", "x15 y75 w100 h24 +0x200", "Drop key:")
        guidedWizGui.SetFont("s9 c000000", "Segoe UI")
        global geReRecDropEdit := guidedWizGui.Add("Edit", "x120 y75 w40 h24 Center", dropKey)
    } else {
        global geReRecDropEdit := ""
    }
    guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
    if (mode = "give") {
        guidedWizGui.SetFont("s9 cFFAA00", "Segoe UI")
        guidedWizGui.Add("Text", "x15 y75 w300", "First slot skipped without a search filter (implant).")
        guidedWizGui.SetFont("s9 cDDDDDD", "Segoe UI")
        filterY := 100
    } else {
        filterY := mode = "popcorn" ? 105 : 75
    }
    guidedWizGui.Add("Text", "x15 y" filterY " w100 h24 +0x200", "Search filter:")
    guidedWizGui.SetFont("s9 c000000", "Segoe UI")
    global geReRecFilterEdit := guidedWizGui.Add("Edit", "x120 y" filterY " w150 h24", filter)
    guidedWizGui.SetFont("s8 c888888 Italic", "Segoe UI")
    guidedWizGui.Add("Text", "x275 y" (filterY + 4) " w40", "blank=all")
    btnY := filterY + 35
    btnSave := DarkBtn(guidedWizGui, "x15 y" btnY " w100 h28", "Save", _RED_BGR, _DK_BG, -12, true)
    btnSave.OnEvent("Click", GuidedReRecordSetupSave.Bind(idx, mode))
    btnCancel := DarkBtn(guidedWizGui, "x120 y" btnY " w100 h28", "Cancel", 0xDDDDDD, _DK_BG, -12, false)
    btnCancel.OnEvent("Click", GuidedCancel)
    guidedWizGui.OnEvent("Close", GuidedCancel)
    guidedWizGui.Show("AutoSize " MacroPopupPos(350))
}

GuidedReRecordSetupSave(idx, mode, *) {
    global guidedWizGui, macroList, macroTabActive, macroSelectedIdx
    global geReRecSlotEdit, geReRecDropEdit, geReRecFilterEdit
    global pcStartSlotX, pcStartSlotY, pcSlotW, pcSlotH, pcColumns, pcDropKey
    global plStartSlotX, plStartSlotY, plSlotW, plSlotH
    m := macroList[idx]

    slotCount := Integer(geReRecSlotEdit.Value)
    if (slotCount < 1)
        slotCount := 1

    if (mode = "popcorn") {
        dropKey := geReRecDropEdit != "" ? Trim(geReRecDropEdit.Value) : pcDropKey
        if (dropKey = "")
            dropKey := "g"
        global pcDropKey := dropKey
        try IniWrite(pcDropKey, A_ScriptDir "\AIO_config.ini", "Popcorn", "DropKey")
    } else {
        dropKey := "t"
    }

    filter := Trim(geReRecFilterEdit.Value)

    if (mode = "give") {
        skipFirst := (filter = "")
        gCols := 6
        events := []
        remaining := slotCount
        while (remaining > 0) {
            slot := 0
            clicked := 0
            Loop 6 {
                row := A_Index - 1
                Loop gCols {
                    col := A_Index - 1
                    slot++
                    if (skipFirst && slot = 1)
                        continue
                    if (clicked >= remaining)
                        break
                    x := plStartSlotX + col * plSlotW
                    y := plStartSlotY + row * plSlotH
                    if (events.Length > 0)
                        events.Push({type: "M", x: x, y: y, delay: 0})
                    events.Push({type: "C", dir: "c", btn: "L", x: x, y: y, delay: 100})
                    events.Push({type: "K", dir: "p", key: dropKey, delay: 60})
                    clicked++
                }
                if (clicked >= remaining)
                    break
            }
            remaining -= clicked
        }
        m.playerSearch := true
    } else {
        gridSize := pcColumns * 6
        events := []
        remaining := slotCount
        while (remaining > 0) {
            slot := 0
            Loop 6 {
                row := A_Index - 1
                Loop pcColumns {
                    col := A_Index - 1
                    slot++
                    if (slot > remaining || slot > gridSize)
                        break
                    x := pcStartSlotX + col * pcSlotW
                    y := pcStartSlotY + row * pcSlotH
                    if (mode = "take") {
                        if (events.Length > 0)
                            events.Push({type: "M", x: x, y: y, delay: 0})
                        events.Push({type: "C", dir: "c", btn: "L", x: x, y: y, delay: 100})
                        events.Push({type: "K", dir: "p", key: dropKey, delay: 60})
                    } else {
                        events.Push({type: "M", x: x, y: y, delay: 0})
                        events.Push({type: "K", dir: "p", key: dropKey, delay: 20})
                    }
                }
                if (slot > remaining || slot > gridSize)
                    break
            }
            remaining -= Min(slot, gridSize)
        }
    }

    m.searchFilters := []
    if (filter != "")
        m.searchFilters.Push(filter)
    m.events := events
    m.loopEnabled := mode = "popcorn" ? true : m.loopEnabled
    macroList[idx] := m
    MacroSaveAll()
    MacroUpdateListView()
    try guidedWizGui.Destroy()
    global guidedWizGui := ""
    MacroRegisterHotkeys(macroTabActive)
    MacroLog("GuidedReRecSetup: '" m.name "' " mode " → " slotCount " items, " events.Length " events")
    ToolTip(" Updated '" m.name "' — " slotCount " items (" events.Length " events)", 0, 0)
    SetTimer(() => ToolTip(), -3000)
}

GuidedReRecordStop() {
    global guidedRecording, guidedRecordEvents, guidedReRecordIdx
    global macroList, macroTabActive, macroSelectedIdx, macroArmed
    if (!guidedRecording)
        return false
    global guidedRecording := false
    savedReRecIdx := guidedReRecordIdx
    global guidedReRecordIdx := 0
    GuidedRecordSetHotkeys(false)
    SetTimer(GuidedRecordMousePoll, 0)
    ToolTip()
    MacroLog("GuidedReRecord: STOPPED  events=" guidedRecordEvents.Length)
    MacroRegisterHotkeys(macroTabActive)
    if (guidedRecordEvents.Length = 0) {
        MacroLog("GuidedReRecord: empty — keeping old events")
        ToolTip(" Re-recording empty — old events kept", 0, 0)
        SetTimer(() => ToolTip(), -2000)
        return true
    }
    GuidedCleanRecordedEvents()
    if (guidedRecordEvents.Length = 0) {
        MacroLog("GuidedReRecord: all cleaned — keeping old events")
        ToolTip(" Re-recording cleaned to nothing — old events kept", 0, 0)
        SetTimer(() => ToolTip(), -2000)
        return true
    }
    idx := savedReRecIdx
    if (idx < 1 || idx > macroList.Length) {
        MacroLog("GuidedReRecord: invalid idx=" idx " — discarding")
        ToolTip(" Re-record error — macro not found", 0, 0)
        SetTimer(() => ToolTip(), -2000)
        return true
    }
    m := macroList[idx]
    oldCount := m.events.Length
    m.events := []
    for , e in guidedRecordEvents
        m.events.Push(e)
    macroList[idx] := m
    MacroSaveAll()
    MacroUpdateListView()
    global guidedRecordEvents := []
    MacroLog("GuidedReRecord: replaced " oldCount " → " m.events.Length " events for '" m.name "'")
    ToolTip(" Re-recorded '" m.name "' — " m.events.Length " events (was " oldCount ")`n F1 = Show UI  |  F at inventory = run", 0, 0)
    SetTimer(() => ToolTip(), -4000)
    global macroSelectedIdx := idx
    global macroArmed := true
    MacroRegisterHotkeys(macroTabActive)
    return true
}

GuidedEditClose() {
    global macroEditGui, macroTabActive
    try macroEditGui.Destroy()
    MacroRegisterHotkeys(macroTabActive)
}

GuidedEditSave(idx, *) {
    global macroList, macroEditGui, macroTabActive
    global geNameEdit, geLoopChk, geMouseEdit, geSettleEdit, geLoadEdit
    global geTurboChk, geTurboEdit
    m := macroList[idx]
    name := Trim(geNameEdit.Value)
    if (name = "") {
        ToolTip("Enter a name!")
        SetTimer(() => ToolTip(), -1500)
        return
    }
    m.name := name
    m.hotkey := "f"
    m.loopEnabled := geLoopChk.Value
    m.turbo := geTurboChk.Value ? 1 : 0
    m.turboDelay := Integer(geTurboEdit.Value)
    m.mouseSpeed := Integer(geMouseEdit.Value)
    m.mouseSettle := Integer(geSettleEdit.Value)
    m.invLoadDelay := Integer(geLoadEdit.Value)
    macroList[idx] := m
    MacroSaveAll()
    MacroUpdateListView()
    MacroRegisterHotkeys(macroTabActive)
    try macroEditGui.Destroy()
    ToolTip(" Guided macro updated!", 0, 0)
    SetTimer(() => ToolTip(), -2000)
}

ComboShowEditDialog(idx) {
    global macroList, macroEditGui, macroTabActive
    MacroBlockAllHotkeys()
    m := macroList[idx]
    try {
        if (macroEditGui != "")
            macroEditGui.Destroy()
    }
    macroEditGui := Gui("+AlwaysOnTop", "Edit Combo Macro")
    macroEditGui.BackColor := "1A1A1A"
    macroEditGui.SetFont("s10 Bold cFF4444", "Segoe UI")
    macroEditGui.Add("Text", "x15 y15 w340 Center", "Edit: " m.name)
    macroEditGui.SetFont("s9 cDDDDDD", "Segoe UI")
    macroEditGui.Add("Text", "x15 y40 w55 h24 +0x200", "Name:")
    macroEditGui.SetFont("s9 c000000", "Segoe UI")
    global ceNameEdit := macroEditGui.Add("Edit", "x75 y40 w240 h24", m.name)
    macroEditGui.SetFont("s9 cDDDDDD", "Segoe UI")
    macroEditGui.Add("Text", "x15 y70 w55 h24 +0x200", "Hotkey:")
    macroEditGui.SetFont("s9 c000000", "Segoe UI")
    global ceHkEdit := macroEditGui.Add("Edit", "x75 y70 w100 h24 ReadOnly", m.hotkey)
    ceHkDetect := DarkBtn(macroEditGui, "x180 y70 w75 h24", "Detect", _RED_BGR, _DK_BG, -11, true)
    ceHkDetect.OnEvent("Click", (*) => ComboEditDetectHk())
    macroEditGui.SetFont("s9 Bold cFF4444", "Segoe UI")
    macroEditGui.Add("Text", "x15 y102 w200", "Popcorn Filters:")
    macroEditGui.SetFont("s9 c000000", "Segoe UI")
    pcStr := ""
    if (m.HasProp("popcornFilters")) {
        for i, f in m.popcornFilters
            pcStr .= (i > 1 ? "|" : "") (f = "" ? "<all>" : f)
    }
    global cePcEdit := macroEditGui.Add("Edit", "x15 y122 w300 h24", pcStr)
    macroEditGui.SetFont("s8 c888888 Italic", "Segoe UI")
    macroEditGui.Add("Text", "x15 y148 w300", "Separate with |  blank or <all> = no filter")
    macroEditGui.SetFont("s9 Bold cFF4444", "Segoe UI")
    macroEditGui.Add("Text", "x15 y168 w200", "Magic F Give Filters:")
    macroEditGui.SetFont("s9 c000000", "Segoe UI")
    mfStr := ""
    if (m.HasProp("magicFFilters")) {
        for i, f in m.magicFFilters
            mfStr .= (i > 1 ? "|" : "") f
    }
    global ceMfEdit := macroEditGui.Add("Edit", "x15 y188 w300 h24", mfStr)
    macroEditGui.SetFont("s8 c888888 Italic", "Segoe UI")
    macroEditGui.Add("Text", "x15 y214 w300", "Separate with | (e.g. flak|riot)")
    ceSaveBtn := DarkBtn(macroEditGui, "x15 y240 w100 h28", "Save", _RED_BGR, _DK_BG, -12, true)
    ceSaveBtn.OnEvent("Click", ComboEditSave.Bind(idx))
    ceCancelBtn := DarkBtn(macroEditGui, "x120 y240 w100 h28", "Cancel", 0xDDDDDD, _DK_BG, -12, false)
    ceCancelBtn.OnEvent("Click", (*) => GuidedEditClose())
    macroEditGui.OnEvent("Close", (*) => GuidedEditClose())
    macroEditGui.Show("AutoSize " MacroPopupPos(350))
}

ComboEditDetectHk() {
    global ceHkEdit
    ceHkEdit.Value := "..."
    ih := InputHook("L1 T10")
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{F1}{F4}", "-E")
    ih.Start()
    ih.Wait()
    if (ih.EndReason = "EndKey")
        ceHkEdit.Value := StrLower(ih.EndKey)
    else
        ceHkEdit.Value := ""
}

ComboEditSave(idx, *) {
    global macroList, macroEditGui, macroTabActive
    global ceNameEdit, ceHkEdit, cePcEdit, ceMfEdit
    m := macroList[idx]
    name := Trim(ceNameEdit.Value)
    hk := Trim(ceHkEdit.Value)
    if (name = "") {
        ToolTip("Enter a name!")
        SetTimer(() => ToolTip(), -1500)
        return
    }
    m.name := name
    m.hotkey := (hk != "..." ? hk : "")
    m.popcornFilters := []
    for , part in StrSplit(cePcEdit.Value, "|") {
        val := Trim(part)
        m.popcornFilters.Push(val = "<all>" ? "" : val)
    }
    m.magicFFilters := []
    for , part in StrSplit(ceMfEdit.Value, "|")
        if (Trim(part) != "")
            m.magicFFilters.Push(Trim(part))
    macroList[idx] := m
    MacroSaveAll()
    MacroUpdateListView()
    MacroRegisterHotkeys(macroTabActive)
    try macroEditGui.Destroy()
    ToolTip(" Combo macro updated!", 0, 0)
    SetTimer(() => ToolTip(), -2000)
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

IsColorSimilar(color1, color2, tolerance := coltol) {
    r1 := color1 >> 16 & 0xFF
    g1 := color1 >> 8  & 0xFF
    b1 := color1       & 0xFF
    r2 := color2 >> 16 & 0xFF
    g2 := color2 >> 8  & 0xFF
    b2 := color2       & 0xFF
    return (Abs(r1-r2) + Abs(g1-g2) + Abs(b1-b2)) <= tolerance
}

GetPixelARGB(capture, x, y) {
    color := DllCall("GetPixel","Ptr",capture.dc,"Int",x,"Int",y,"UInt")
    r := (color & 0xFF)
    g := (color & 0xFF00)   >> 8
    b := (color & 0xFF0000) >> 16
    return Format("0xFF{:02X}{:02X}{:02X}", r, g, b)
}

CaptureWindow(windowTitle) {
    hwnd := WinExist(windowTitle)
    if !hwnd {
        MsgBox("Window not found!")
        return 0
    }
    WinGetPos(&wx, &wy, &ww, &wh, hwnd)
    hdcWindow  := DllCall("GetWindowDC","Ptr",hwnd)
    hdcMem     := DllCall("CreateCompatibleDC","Ptr",hdcWindow)
    hBitmap    := DllCall("CreateCompatibleBitmap","Ptr",hdcWindow,"Int",ww,"Int",wh)
    hOldBitmap := DllCall("SelectObject","Ptr",hdcMem,"Ptr",hBitmap)
    if !DllCall("PrintWindow","Ptr",hwnd,"Ptr",hdcMem,"Uint",2) {
        MsgBox("Screenshot failed!")
        return 0
    }
    DllCall("ReleaseDC","Ptr",hwnd,"Ptr",hdcWindow)
    return { dc: hdcMem, bitmap: hBitmap, oldBitmap: hOldBitmap }
}

ReleaseCapture(img) {
    DllCall("SelectObject","Ptr",img.dc,"Ptr",img.oldBitmap)
    DllCall("DeleteDC","Ptr",img.dc)
    DllCall("DeleteObject","Ptr",img.bitmap)
    DllCall("DeleteObject","Ptr",img.oldBitmap)
}

HexToInt(hexStr) {
    return Integer("0x" SubStr(hexStr, 3))
}

SimLogMsg(msg) {
    global simLog
    ts := FormatTime("", "HH:mm:ss")
    simLog.Push(ts " " msg)
    if (simLog.Length > 100)
        simLog.RemoveAt(1)
}

SimSelectA(*) {
    global simMode := 1
    SimAChk.Value := 1
    SimBChk.Value := 0
}
SimSelectB(*) {
    global simMode := 2
    SimBChk.Value := 1
    SimAChk.Value := 0
}

SimToggleMods(*) {
    global modsEnabled := ModsChk.Value ? true : false
}
SimToggleUseLast(*) {
    global useLast := UseLastChk.Value ? true : false
}
SimToggleTooltips(*) {
    global toolboxEnabled := ToolBoxChk.Value ? true : false
}

CheckState() {
    global simLastColors, simLastState
    img    := CaptureWindow(GameWindow)
    result := ""
    colorDump := ""
    for index, item in states {
        color := GetPixelARGB(img, item.x, item.y)
        colorDump .= item.name "=" color " "

        match := (color = item.c)
        if (!match && item.HasProp("calt"))
            match := (color = item.calt)

        if (!match) {
            c1 := HexToInt(color)
            c2 := HexToInt(item.c)
            match := IsColorSimilar(c1, c2)
            if (!match && item.HasProp("calt"))
                match := IsColorSimilar(c1, HexToInt(item.calt))
        }

        if (match) {
            if (item.name = "NoSessions") {
                confirmColor := GetPixelARGB(img, NoSessConfirmX, NoSessConfirmY)
                if (!IsColorSimilar(HexToInt(confirmColor), HexToInt("0xFFFFFFFF")))
                    continue
                rowColor := GetPixelARGB(img, NoSessRowCheckX, NoSessRowCheckY)
                rowInt := HexToInt(rowColor)
                rowR := (rowInt >> 16) & 0xFF, rowG := (rowInt >> 8) & 0xFF, rowB := rowInt & 0xFF
                if ((rowR + rowG + rowB) > 150)
                    continue
                beColor := GetPixelARGB(img, BeLogoOffsetX, BeLogoOffsetY)
                if (beColor = col.BeLogo || IsColorSimilar(HexToInt(beColor), HexToInt(col.BeLogo)))
                    continue
            }
            if (item.HasProp("x2") && item.HasProp("y2") && item.HasProp("c2")) {
                color2 := GetPixelARGB(img, item.x2, item.y2)
                if (color2 = item.c2 || IsColorSimilar(HexToInt(color2), HexToInt(item.c2))) {
                    result := item.name
                    break
                }
            } else {
                result := item.name
                break
            }
        }
    }
    colorDump .= "NoSessConfirm=" GetPixelARGB(img, NoSessConfirmX, NoSessConfirmY) " "
    colorDump .= "NoSessRow=" GetPixelARGB(img, NoSessRowCheckX, NoSessRowCheckY) " "
    colorDump .= "BeLogo=" GetPixelARGB(img, BeLogoOffsetX, BeLogoOffsetY) " "
    simLastColors := colorDump
    simLastState := result != "" ? result : "Unknown"
    ReleaseCapture(img)
    return result
}

; SIM B:
CheckStateB() {
    global simLastColors, simLastState
    img    := CaptureWindow(GameWindow)
    result := ""
    colorDump := ""
    for index, item in statesB {
        color := GetPixelARGB(img, item.x, item.y)
        colorDump .= item.name "=" color " "

        match := (color = item.c)
        if (!match && item.HasProp("calt"))
            match := (color = item.calt)

        if (match) {
            if (item.HasProp("x2") && item.HasProp("y2") && item.HasProp("c2")) {
                color2 := GetPixelARGB(img, item.x2, item.y2)
                if (color2 = item.c2) {
                    result := item.name
                    break
                }
            } else {
                result := item.name
                break
            }
        }
    }
    simLastColors := colorDump
    simLastState := result != "" ? result : "Unknown"
    ReleaseCapture(img)
    return result
}

ClickWindow(x, y) {
    ControlClick("x" x " y" y, GameWindow, , , , "Pos")
}
SendWindow(input) {
    ControlSend(input,, GameWindow)
}
SendWindowText(input) {
    ControlSendText(input,, GameWindow)
}

UpdateSimStatus(text) {
    SimStatusText.Value := text
    if (toolboxEnabled) {
        ToolTip("Simming for: " ServerNumberEdit.Text " | " text, 0, 0)
    }
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SimLoop() {
    global simCycleCount, simMode
    if (!AutoSimCheck) {
        Exit()
    }
    simCycleCount++
    if (simMode = 2)
        SimLoopB()
    else
        SimLoopA()
}

; ── SIM A — full error handling ──────────────────────────────
SimLoopA() {
    global simCycleCount, stuckState, stuckCount
    state := CheckState()
    if (state != "WaitingToJoin") {
        global WM := 0
    }

    if (state = stuckState && state != "" && state != "WaitingToJoin") {
        stuckCount++
    } else {
        global stuckState := state
        global stuckCount := 0
    }
    if (stuckCount >= 150 && state != "WaitingToJoin" && state != "") {
        SimLogMsg("[" simCycleCount "] STUCK RECOVERY — state '" state "' repeated " stuckCount " times, clicking Back")
        UpdateSimStatus("Stuck in " state " — recovering")
        ClickWindow(BackOffsetX, BackOffsetY)
        Sleep(500)
        ClickWindow(BackOffsetX, BackOffsetY)
        Sleep(500)
        global stuckCount := 0
        global nosessions := 0
        global SM := 0
        global MM := 0
        return
    }

    switch state {
        case "SinglePlayer":
            SimLogMsg("[" simCycleCount "] SinglePlayer — backing out")
            UpdateSimStatus("SinglePlayer - backing out")
            ClickWindow(SPBackOffsetX, SPBackOffsetY)
            Sleep(250)
        case "ServerFull", "ServerFull2", "ServerFull3":
            WinGetPos(&X2, &Y2,,, GameWindow)
            if (X2 = 0 && Y2 = 0) {
                WinMove(1, 0,,, GameWindow)
                global incounter := 0
            }
            SimLogMsg("[" simCycleCount "] " state " — Enter + Back")
            UpdateSimStatus("Server Full - retrying")
            SendWindow("{Enter}")
            Sleep(100)
            ClickWindow(BackOffsetX, BackOffsetY)
            Sleep(500)
            global JL := 0
            global SM := 0
        case "ConnectionTimeout":
            SimLogMsg("[" simCycleCount "] ConnectionTimeout — Enter + double Back")
            UpdateSimStatus("Connection Timeout - backing out")
            SendWindow("{Enter}")
            Sleep(100)
            ClickWindow(BackOffsetX, BackOffsetY)
            Sleep(500)
            ClickWindow(BackOffsetX, BackOffsetY)
            Sleep(500)
            global JL := 0
            global SM := 0
        case "ServerSelected":
            if (!simInitialSearchDone && !useLast) {
                SimLogMsg("[" simCycleCount "] ServerSelected but initial search not done — searching first")
                UpdateSimStatus("Server Selected - searching first")
                ClickWindow(ServerSearchOffsetX, ServerSearchOffsetY)
                Sleep(100)
                SendWindow("{Ctrl down}a{Ctrl up}")
                Sleep(100)
                SendWindow("{BackSpace}")
                Sleep(100)
                SendWindowText(ServerNumberEdit.Text)
                Sleep(200)
                ClickWindow(ClickSessionOffsetX, ClickSessionOffsetY)
                global simInitialSearchDone := true
                return
            }
            SimLogMsg("[" simCycleCount "] ServerSelected — clicking Join")
            UpdateSimStatus("Server Selected - joining")
            ClickWindow(ServerJoinOffsetX, ServerJoinOffsetY)
        case "NoSessions":
            nosessions++
            UpdateSimStatus("No Sessions (" nosessions "/50)")
            if (Mod(nosessions, 25) = 0)
                SimLogMsg("[" simCycleCount "] NoSessions — count=" nosessions)
            if (nosessions > 50) {
                SimLogMsg("[" simCycleCount "] NoSessions — refreshing")
                ClickWindow(RefreshOffsetX, RefreshOffsetY)
                global nosessions := 0
            }
        case "WaitingToJoin":
            global WM
            WM++
            UpdateSimStatus("Waiting To Join (" WM "/180)")
            if (Mod(WM, 30) = 0)
                SimLogMsg("[" simCycleCount "] WaitingToJoin — WM=" WM "/180")
            if (WM >= 180) {
                SimLogMsg("[" simCycleCount "] WaitingToJoin — timeout, backing out")
                ClickWindow(BackOffsetX, BackOffsetY)
                WM := 0
            }
            Sleep(500)
        case "ServerBrowser":
            global SM
            SM++
            UpdateSimStatus("Server Browser - waiting (" SM "/40)")
            if (SM >= 40 || !simInitialSearchDone) {
                SM := 0
                if (useLast) {
                    global JL
                    JL++
                    SimLogMsg("[" simCycleCount "] ServerBrowser — JoinLast (" JL "/40)")
                    UpdateSimStatus("Server Browser - Join Last (" JL "/40)")
                    if (JL >= 40) {
                        SimLogMsg("[" simCycleCount "] ServerBrowser — JoinLast failed 40 times, backing out")
                        ClickWindow(BackOffsetX, BackOffsetY)
                        Sleep(500)
                        global JL := 0
                    } else {
                        ClickWindow(JoinLastOffsetX, JoinLastOffsetY)
                        Sleep(500)
                    }
                    global simInitialSearchDone := true
                } else {
                    SimLogMsg("[" simCycleCount "] ServerBrowser — search + click session")
                    UpdateSimStatus("Server Browser - searching")
                    ClickWindow(ServerSearchOffsetX, ServerSearchOffsetY)
                    Sleep(100)
                    SendWindow("{Ctrl down}a{Ctrl up}")
                    Sleep(100)
                    SendWindow("{BackSpace}")
                    Sleep(100)
                    SendWindowText(ServerNumberEdit.Text)
                    Sleep(200)
                    ClickWindow(ClickSessionOffsetX, ClickSessionOffsetY)
                    global simInitialSearchDone := true
                }
            }
        case "ModMenu":
            SimLogMsg("[" simCycleCount "] ModMenu — clicking join")
            UpdateSimStatus("Mod Menu - clicking join")
            ClickWindow(ModJoinOffsetX, ModJoinOffsetY)
        case "ContentFailed":
            SimLogMsg("[" simCycleCount "] ContentFailed — Esc")
            UpdateSimStatus("Content Failed - escaping")
            SendWindow("{Esc}")
            Sleep(2000)
        case "MainMenu":
            SimLogMsg("[" simCycleCount "] MainMenu — clicking Play")
            UpdateSimStatus("Main Menu - clicking Play")
            ClickWindow(MainMenuJoinOffsetX, MainMenuJoinOffsetY)
            Sleep(1250)
        case "MiddleMenu":
            SimLogMsg("[" simCycleCount "] MiddleMenu — clicking JoinGame")
            UpdateSimStatus("Middle Menu - joining")
            ClickWindow(JoinGameOffsetX, JoinGameOffsetY)
            Sleep(250)
        default:
            WinGetPos(&X, &Y,,, GameWindow)
            if (X = 0 && Y = 0) {
                incounter++
                UpdateSimStatus("Maybe In Server: " incounter "/50")
                if (Mod(incounter, 25) = 0)
                    SimLogMsg("[" simCycleCount "] Unknown state — maybe in? " incounter "/50 winpos=(" X "," Y ")")
                if (incounter >= 50) {
                    SimLogMsg("[" simCycleCount "] IN SERVER — success after " simCycleCount " cycles")
                    SetTimer(SimLoop, 0)
                    global AutoSimCheck := false
                    global JL := 0
                    DarkBtnText(StartSimButton, "Start")
                    global simcyclestatus := "Idle"
                    SimStatusText.Value := ""
                    TaskbarRestore()
                    ntfypush("max", ServerNumberEdit.Text)
                    ToolTip()
                    MainGui.Hide
                    global guiVisible := false
                    WinActivate(GameWindow)
                }
            } else {
                global incounter := 0
            }
    }
}

; ── SIM B ─────────────────────
SimLoopB() {
    global simCycleCount, stuckState, stuckCount
    state := CheckStateB()

    if (state = stuckState && state != "") {
        stuckCount++
    } else {
        global stuckState := state
        global stuckCount := 0
    }
    if (stuckCount >= 150 && state != "") {
        SimLogMsg("[" simCycleCount "] B STUCK RECOVERY — state '" state "' repeated " stuckCount " times, clicking Back")
        UpdateSimStatus("Stuck in " state " — recovering")
        ClickWindow(BackOffsetX, BackOffsetY)
        Sleep(500)
        ClickWindow(BackOffsetX, BackOffsetY)
        Sleep(500)
        global stuckCount := 0
        global nosessions := 0
        return
    }

    switch state {
        case "ServerFull":
            WinGetPos(&X2, &Y2,,, GameWindow)
            if (X2 = 0 && Y2 = 0) {
                WinMove(1, 0,,, GameWindow)
                global incounter := 0
            }
            SimLogMsg("[" simCycleCount "] B ServerFull — Enter + Back")
            UpdateSimStatus("Server Full")
            SendWindow("{Enter}")
            Sleep(100)
            ClickWindow(BackOffsetX, BackOffsetY)
        case "ConnectionTimeout":
            SimLogMsg("[" simCycleCount "] B ConnectionTimeout — Enter + double Back")
            UpdateSimStatus("Connection Timeout")
            SendWindow("{Enter}")
            Sleep(100)
            ClickWindow(BackOffsetX, BackOffsetY)
            Sleep(500)
            ClickWindow(BackOffsetX, BackOffsetY)
        case "ServerSelected":
            if (!simInitialSearchDone && !useLast) {
                SimLogMsg("[" simCycleCount "] B ServerSelected but initial search not done — searching first")
                UpdateSimStatus("Server Selected - searching first")
                ClickWindow(ServerSearchOffsetX, ServerSearchOffsetY)
                Sleep(100)
                SendWindow("{Ctrl down}a{Ctrl up}")
                Sleep(100)
                SendWindow("{BackSpace}")
                Sleep(100)
                SendWindowText(ServerNumberEdit.Text)
                Sleep(200)
                ClickWindow(ClickSessionBOffsetX, ClickSessionBOffsetY)
                global simInitialSearchDone := true
                return
            }
            SimLogMsg("[" simCycleCount "] B ServerSelected — clicking Join")
            UpdateSimStatus("Server Selected")
            ClickWindow(ServerJoinOffsetX, ServerJoinOffsetY)
        case "ServerBrowser":
            SimLogMsg("[" simCycleCount "] B ServerBrowser — searching")
            if (!useLast) {
                UpdateSimStatus("Server Browser - searching")
                ClickWindow(ServerSearchOffsetX, ServerSearchOffsetY)
                Sleep(100)
                SendWindow("{Ctrl down}a{Ctrl up}")
                Sleep(100)
                SendWindow("{BackSpace}")
                Sleep(100)
                SendWindowText(ServerNumberEdit.Text)
                Sleep(200)
                ClickWindow(ClickSessionBOffsetX, ClickSessionBOffsetY)
                global simInitialSearchDone := true
            } else {
                UpdateSimStatus("Server Browser - Join Last")
                ClickWindow(JoinLastOffsetX, JoinLastOffsetY)
                global simInitialSearchDone := true
            }
        case "ModMenu":
            SimLogMsg("[" simCycleCount "] B ModMenu — clicking join")
            UpdateSimStatus("Mod Menu")
            ClickWindow(ModJoinOffsetX, ModJoinOffsetY)
        case "MainMenu":
            SimLogMsg("[" simCycleCount "] B MainMenu — clicking Play")
            UpdateSimStatus("Main Menu")
            ClickWindow(MainMenuJoinOffsetX, MainMenuJoinOffsetY)
            Sleep(1250)
        case "MiddleMenu":
            SimLogMsg("[" simCycleCount "] B MiddleMenu — clicking JoinGame")
            UpdateSimStatus("Middle Menu")
            ClickWindow(JoinGameOffsetX, JoinGameOffsetY)
            Sleep(250)
        case "NoSessions":
            nosessions++
            UpdateSimStatus("No Sessions (" nosessions "/50)")
            if (nosessions <= 50)
                return
            SimLogMsg("[" simCycleCount "] B NoSessions — refreshing")
            ClickWindow(RefreshOffsetX, RefreshOffsetY)
            global nosessions := 0
        default:
            WinGetPos(&X, &Y,,, GameWindow)
            if (X = 0 && Y = 0) {
                incounter++
                UpdateSimStatus("Maybe In Server: " incounter "/50")
                if (incounter >= 50) {
                    SimLogMsg("[" simCycleCount "] B IN SERVER — success after " simCycleCount " cycles")
                    SetTimer(SimLoop, 0)
                    global AutoSimCheck := false
                    global JL := 0
                    DarkBtnText(StartSimButton, "Start")
                    global simcyclestatus := "Idle"
                    SimStatusText.Value := ""
                    TaskbarRestore()
                    ntfypush("max", ServerNumberEdit.Text)
                    ToolTip()
                    MainGui.Hide
                    global guiVisible := false
                    WinActivate(GameWindow)
                }
            } else {
                global incounter := 0
            }
    }
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

TaskbarGetState() {
    abdSize := A_PtrSize = 8 ? 48 : 36
    abd := Buffer(abdSize, 0)
    NumPut("UInt", abdSize, abd, 0)
    hWnd := DllCall("FindWindow", "Str", "Shell_TrayWnd", "Ptr", 0, "Ptr")
    NumPut("Ptr", hWnd, abd, A_PtrSize = 8 ? 8 : 4)
    return DllCall("Shell32\SHAppBarMessage", "UInt", 0x04, "Ptr", abd, "UInt")
}

TaskbarSetState(state) {
    abdSize := A_PtrSize = 8 ? 48 : 36
    abd := Buffer(abdSize, 0)
    NumPut("UInt", abdSize, abd, 0)
    hWnd := DllCall("FindWindow", "Str", "Shell_TrayWnd", "Ptr", 0, "Ptr")
    NumPut("Ptr", hWnd, abd, A_PtrSize = 8 ? 8 : 4)
    NumPut("Ptr", state, abd, A_PtrSize = 8 ? 40 : 32)
    DllCall("Shell32\SHAppBarMessage", "UInt", 0x0A, "Ptr", abd)
}

TaskbarAutoHide() {
    global taskbarWasAutoHide, taskbarChanged
    curState := TaskbarGetState()
    taskbarWasAutoHide := (curState & 0x01) ? true : false
    if (!taskbarWasAutoHide) {
        TaskbarSetState(curState | 0x01)
        taskbarChanged := true
    }
}

TaskbarRestore() {
    global taskbarChanged
    if (taskbarChanged) {
        TaskbarSetState(0x02)
        taskbarChanged := false
    }
}

OnExit((*) => TaskbarRestore())

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

AutoSimButtonToggle(*) {
    global AutoSimCheck := !AutoSimCheck
    if (AutoSimCheck) {
        global MM := 0
        global RM := 0
        global SM := 0
        global WM := 0
        global JL := 0
        global nosessions := 0
        global incounter  := 0
        global simCycleCount := 0
        global searchDone := false
        global simInitialSearchDone := false
        global stuckState := ""
        global stuckCount := 0
        global simLog := []
        WinGetPos(&gx, &gy, &gw, &gh, GameWindow)
        SimLogMsg("=== SIM STARTED (SIM " (simMode = 1 ? "A" : "B") ") ===")
        SimLogMsg("Server: " ServerNumberEdit.Text "  UseLast: " useLast "  Mods: " modsEnabled)
        SimLogMsg("GameWindow: " gw "x" gh " at (" gx "," gy ")  Screen: " A_ScreenWidth "x" A_ScreenHeight)
        if (simMode = 1)
            SimLogMsg("Tolerance: " coltol)
        TaskbarAutoHide()
        WinMove(1, 0,,, GameWindow)
        DarkBtnText(StartSimButton, "Stop")
        global simcyclestatus := "Running"
        SetTimer(SimLoop, 10)
        SimLoop()
        if (toolboxEnabled) {
            ToolTip("Simming for: " ServerNumberEdit.Text " | Starting...", 0, 0)
        }
    } else {
        WinMove(0, 0,,, GameWindow)
        TaskbarRestore()
        SetTimer(SimLoop, 0)
        global JL := 0
        DarkBtnText(StartSimButton, "Start")
        global simcyclestatus := "Idle"
        SimStatusText.Value := ""
        if (toolboxEnabled) {
            ToolTip("Sim Stopped", 0, 0)
            SetTimer(() => ToolTip(), -2000)
        }
    }
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; SHEEP — KEY DETECTION -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SheepDetectKey(ctrl, *) {
    ctrl.Value := ""
    ctrl.Focus()
    ih := InputHook("L1 T10")
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}", "-E")
    ih.Start()
    ToolTip("Press a key...")
    ih.Wait()
    ToolTip()
    if (ih.EndReason = "EndKey") {
        ctrl.Value := ih.EndKey
    } else if (ih.EndReason = "Timeout") {
        ctrl.Value := ""
        ToolTip("Timed out")
        SetTimer(() => ToolTip(), -1500)
    }
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; SHEEP — REG / UNREG HOTKEYS -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SheepRegisterHotkeys() {
    global sheepToggleKey, sheepOvercapKey, sheepAutoLvlKey
    try Hotkey("$" sheepToggleKey,  SheepHotkeyToggle,  "On")
    try Hotkey("$" sheepOvercapKey, SheepHotkeyOvercap, "On")
    try Hotkey("$" sheepAutoLvlKey, SheepHotkeyAutoLvl, "On")
}

SheepUnregisterHotkeys() {
    global sheepToggleKey, sheepOvercapKey, sheepAutoLvlKey
    try Hotkey("$" sheepToggleKey,  "Off")
    try Hotkey("$" sheepOvercapKey, "Off")
    try Hotkey("$" sheepAutoLvlKey, "Off")
}

SheepHotkeyToggle(thisHotkey) {
    global sheepTabActive, arkWindow
    if (!sheepTabActive || !WinActive(arkWindow)) {
        Send("{" SubStr(thisHotkey, 2) "}")
        return
    }
    SheepToggleScript()
}
SheepHotkeyOvercap(thisHotkey) {
    global sheepTabActive, arkWindow
    if (!sheepTabActive || !WinActive(arkWindow)) {
        Send("{" SubStr(thisHotkey, 2) "}")
        return
    }
    SheepToggleOvercap()
}
SheepHotkeyAutoLvl(thisHotkey) {
    global sheepTabActive, arkWindow, sheepAutoLvlActive, sheepModeActive, guiVisible, MainGui
    global sheepLevelActionKey, sheepAutoLvlKey, ModeSelectTab
    arkActive := WinActive(arkWindow)
    PcLog("Sheep Z pressed: tabActive=" sheepTabActive " arkActive=" arkActive " autoLvl=" sheepAutoLvlActive " modeActive=" sheepModeActive " — " (arkActive ? "toggling" : "typing z"))
    if (!arkActive || (!sheepTabActive && !sheepModeActive)) {
        Send("{" SubStr(thisHotkey, 2) "}")
        return
    }
    sheepAutoLvlActive := !sheepAutoLvlActive
    if (sheepAutoLvlActive) {
        global sheepModeActive := true
        if (sheepLevelActionKey != sheepAutoLvlKey)
            try Hotkey("$" sheepLevelActionKey, SheepDoAutoLevel, "On")
        if (guiVisible) {
            MainGui.Hide()
            global guiVisible := false
            PcLog("SheepAutoLvl: hid main GUI")
        }
        try {
            SheepShowAutoLvlGui()
        } catch as err {
            PcLog("SheepAutoLvl: GUI show error — " err.Message " — re-creating")
            global sheepAutoLvlGui := ""
            SheepShowAutoLvlGui()
        }
        if WinExist(arkWindow) {
            WinActivate(arkWindow)
            Sleep(100)
            PcLog("SheepAutoLvl: activated ARK")
        }
        ToolTip("Sheep Auto LvL ON  |  " sheepAutoLvlKey " = Toggle", 0, 20)
    } else {
        global sheepModeActive := false
        if (sheepLevelActionKey != sheepAutoLvlKey)
            try Hotkey("$" sheepLevelActionKey, "Off")
        SheepHideAutoLvlGui()
        if (!guiVisible) {
            MainGui.Show("NoActivate")
            global guiVisible := true
            try ModeSelectTab.Value := 5
            PcLog("SheepAutoLvl: showed main GUI on Sheep tab")
        }
        if WinExist(arkWindow) {
            WinActivate(arkWindow)
            Sleep(100)
        }
        ToolTip()
    }
    PcLog("SheepAutoLvl: toggle complete — autoLvl now=" sheepAutoLvlActive " modeActive=" sheepModeActive)
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; SHEEP — APPLY / SAVE SETTINGS -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SheepApplyKeys(ctrl, info) {
    global sheepToggleKey, sheepOvercapKey, sheepInventoryKey, sheepAutoLvlKey
    global sheepToggleInput, sheepOvercapInput, sheepInventoryInput, sheepAutoLvlInput

    newToggle    := Trim(sheepToggleInput.Value)
    newOvercap   := Trim(sheepOvercapInput.Value)
    newInventory := Trim(sheepInventoryInput.Value)
    newAutoLvl   := Trim(sheepAutoLvlInput.Value)

    if (newToggle == "" || newOvercap == "" || newInventory == "" || newAutoLvl == "") {
        ToolTip("All key fields must be filled!")
        SetTimer(() => ToolTip(), -2000)
        return
    }

    SheepUnregisterHotkeys()

    global sheepToggleKey    := newToggle
    global sheepOvercapKey   := newOvercap
    global sheepInventoryKey := newInventory
    global sheepAutoLvlKey   := newAutoLvl

    SheepRegisterHotkeys()

    ToolTip("Sheep settings saved!`nStart/Pause: " sheepToggleKey
        "`nOvercap: " sheepOvercapKey
        "`nInventory: " sheepInventoryKey
        "`nAuto LvL: " sheepAutoLvlKey)
    SetTimer(() => ToolTip(), -3000)
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; SHEEP — TOGGLE SCRIPT -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SheepToggleScript() {
    global sheepRunning, sheepAutoLvlActive, MainGui, guiVisible, sheepInventoryKey

    if (sheepRunning) {
        SheepStopScript()
    } else {
        savedInv := ""
        try savedInv := IniRead(A_ScriptDir "\AIO_config.ini", "Popcorn", "InvKey", "")
        if (sheepInventoryKey = "" && savedInv = "") {
            PcShowSetKeysPrompt()
            return
        }
        global sheepRunning := true
        MainGui.Hide()
        global guiVisible := false
        SheepShowStatusGui()
        if WinExist(arkWindow)
            WinActivate(arkWindow)
        ToolTip("Sheep STARTED")
        SetTimer(() => ToolTip(), -1500)
        SetTimer(SheepStartLoop, -1)
    }
}

SheepStopScript() {
    global sheepRunning := false
    global MainGui, guiVisible
    Click("Up")
    Sleep(200)
    SheepDropAll(true)
    SheepHideStatusGui()
    MainGui.Show("NoActivate")
    global guiVisible := true
    if WinExist(arkWindow)
        WinActivate(arkWindow)
    ToolTip("Sheep PAUSED")
    SetTimer(() => ToolTip(), -1500)
}

SheepToggleOvercap() {
    global overcappingToggle
    overcappingToggle := !overcappingToggle
    ToolTip(overcappingToggle ? "Overcapping: ON" : "Overcapping: OFF")
    SetTimer(() => ToolTip(), -1500)
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; SHEEP — AUTO LVL TOGGLE -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SheepToggleAutoLvl() {
    global sheepAutoLvlActive, sheepLevelActionKey, sheepAutoLvlKey, sheepRunning, MainGui, guiVisible
    sheepAutoLvlActive := !sheepAutoLvlActive
    if (sheepAutoLvlActive) {
        if (sheepLevelActionKey != sheepAutoLvlKey)
            Hotkey("$" sheepLevelActionKey, SheepDoAutoLevel, "On")
        MainGui.Hide()
        global guiVisible := false
        SheepShowAutoLvlGui()
        if WinExist(arkWindow)
            WinActivate(arkWindow)
        ToolTip("Sheep Auto LvL ON  |  " sheepAutoLvlKey " = Toggle", 0, 20)
    } else {
        ToolTip()
        if (sheepLevelActionKey != sheepAutoLvlKey)
            try Hotkey("$" sheepLevelActionKey, "Off")
        SheepHideAutoLvlGui()
        MainGui.Show("NoActivate")
        global guiVisible := true
        if WinExist(arkWindow)
            WinActivate(arkWindow)
    }
}

SheepStopAutoLvl() {
    global sheepAutoLvlActive := false
    global sheepModeActive    := false
    global sheepLevelActionKey, sheepAutoLvlKey, guiVisible
    if (sheepLevelActionKey != sheepAutoLvlKey)
        try Hotkey("$" sheepLevelActionKey, "Off")
    SheepHideAutoLvlGui()
    ToolTip()
    MainGui.Show("NoActivate")
    global guiVisible := true
    if WinExist(arkWindow)
        WinActivate(arkWindow)
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; SHEEP — AUTO LVL ACTION -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SheepDoAutoLevel(thisHotkey) {
    global sheepAutoLvlActive, arkWindow, sheepLvlPixelX, sheepLvlPixelY
    global sheepLvlClickX, sheepLvlClickY, sheepLevelActionKey

    if (!sheepAutoLvlActive || !WinActive(arkWindow)) {
        Send("{" sheepLevelActionKey "}")
        return
    }

    ControlSend(sheepLevelActionKey,, arkWindow)

    waitCount := 0
    loop {
        if NFSearchTol(&px, &py,
            sheepLvlPixelX, sheepLvlPixelY,
            sheepLvlPixelX + 1, sheepLvlPixelY + 1,
            "0xFFFFFF")
            break
        Sleep(50)
        waitCount++
        if (waitCount > 30)
            return
    }

    MouseMove(sheepLvlClickX, sheepLvlClickY)
    Loop 70
        Click()

    ControlSend("{Esc}",, arkWindow)
}

SheepAutoLvlFPressed() {
    global sheepAutoLvlActive, arkWindow, sheepLvlPixelX, sheepLvlPixelY
    global sheepLvlClickX, sheepLvlClickY

    if (!sheepAutoLvlActive || !WinActive(arkWindow))
        return

    waitCount := 0
    loop {
        if NFSearchTol(&px, &py,
            sheepLvlPixelX, sheepLvlPixelY,
            sheepLvlPixelX + 1, sheepLvlPixelY + 1,
            "0xFFFFFF")
            break
        Sleep(50)
        waitCount++
        if (waitCount > 30)
            return
    }

    MouseMove(sheepLvlClickX, sheepLvlClickY)
    Loop 70
        Click()

    ControlSend("{Esc}",, arkWindow)
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; SHEEP — AUTO LVL GUI -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SheepShowAutoLvlGui() {
    global sheepAutoLvlGui, sheepAutoLvlKey, sheepLevelActionKey
    global sheepStatusBottomAnchor, sx, sy

    if (sheepAutoLvlGui != "")
        try sheepAutoLvlGui.Destroy()

    sheepAutoLvlGui := Gui("+AlwaysOnTop -Caption", "SheepAutoLvL")
    sheepAutoLvlGui.BackColor := "1A1A1A"

    sheepAutoLvlGui.SetFont("s10 cFF4444 Bold", "Segoe UI")
    sheepAutoLvlGui.Add("Text", "x8 y8 w120", "Auto LvL Running")

    sheepAutoLvlGui.SetFont("s9 c00FF00", "Segoe UI")
    sheepAutoLvlGui.Add("Text", "x8 y+6 w120", "Press " StrUpper(sheepLevelActionKey))

    sheepAutoLvlGui.SetFont("s8 cFF4444 Italic", "Segoe UI")
    sheepAutoLvlGui.Add("Text", "x8 y+5 w140", sheepAutoLvlKey " = Toggle")

    sheepAutoLvlGui.SetFont("s8 c888888", "Segoe UI")
    sheepAutoLvlGui.Add("Text", "x8 y+5 w100", "Res: " sx "x" sy)

    sheepAutoLvlGui.Show("x-9999 y-9999 AutoSize NoActivate")
    sheepAutoLvlGui.GetPos(,, &guiW, &guiH)

    if (sheepStatusBottomAnchor == 0)
        sheepStatusBottomAnchor := 364 + guiH
    newY := Max(0, sheepStatusBottomAnchor - guiH + 65)

    sheepAutoLvlGui.Move(0, newY)
    sheepAutoLvlGui.Show("x0 y" newY " NoActivate")
    PcLog("SheepShowAutoLvlGui: shown at y=" newY)
}

SheepHideAutoLvlGui() {
    global sheepAutoLvlGui
    if (sheepAutoLvlGui != "") {
        try sheepAutoLvlGui.Destroy()
        global sheepAutoLvlGui := ""
    }
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; SHEEP — STATUS GUI -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SheepShowStatusGui() {
    global sheepStatusGui, sheepToggleKey, sheepStatusBottomAnchor, sx, sy

    if (sheepStatusGui != "")
        try sheepStatusGui.Destroy()

    sheepStatusGui := Gui("+AlwaysOnTop -Caption", "SheepStatus")
    sheepStatusGui.BackColor := "1A1A1A"

    sheepStatusGui.SetFont("s10 cFF4444 Bold", "Segoe UI")
    sheepStatusGui.Add("Text", "x8 y8 w115", "🐑 SheepV2 Running")

    sheepStatusGui.SetFont("s9 c00FF00", "Segoe UI")
    sheepStatusGui.Add("Text", "x8 y+6 w115", "Start/Pause: " sheepToggleKey)

    sheepStatusGui.SetFont("s8 cFF4444 Italic", "Segoe UI")

    sheepStatusGui.SetFont("s8 c888888", "Segoe UI")
    sheepStatusGui.Add("Text", "x8 y+5 w100", "Res: " sx "x" sy)

    sheepStatusGui.Show("x-9999 y-9999 AutoSize NoActivate")
    sheepStatusGui.GetPos(,, &guiW, &guiH)

    if (sheepStatusBottomAnchor == 0)
        sheepStatusBottomAnchor := 364 + guiH
    newY := Max(0, sheepStatusBottomAnchor - guiH + 65)

    sheepStatusGui.Move(0, newY)
    sheepStatusGui.Show("x0 y" newY " NoActivate")
}

SheepHideStatusGui() {
    global sheepStatusGui
    if (sheepStatusGui != "") {
        try sheepStatusGui.Destroy()
        global sheepStatusGui := ""
    }
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; SHEEP — MAIN LOOP -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SheepStartLoop() {
    global overcappingToggle, blackBoxX, blackBoxY
    global overcapBoxX, overcapBoxY, sheepRunning, arkWindow

    if WinExist(arkWindow)
        WinActivate(arkWindow)
    Sleep(150)

    Loop {
        if (!sheepRunning) {
            Click("Up")
            return
        }
        Click("Down")
        checkX := overcappingToggle ? overcapBoxX : blackBoxX
        checkY := overcappingToggle ? overcapBoxY : blackBoxY
        ColorBB := PxGet(checkX, checkY)
        if (ColorBB == "0x000000") {
            Click("Up")
            Sleep(500)
            if (!sheepRunning)
                return
            SheepDropAll()
            Loop {
                if (!sheepRunning) {
                    Click("Up")
                    return
                }
                Sleep(200)
                if (NFNotBlack(checkX, checkY))
                    break
            }
            Sleep(500)
        }
        Sleep(50)
    }
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; SHEEP — INVENTORY HELPERS -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SheepWaitForInventory(isFinalDrop := false) {
    global sheepRunning, invyDetectX, invyDetectY
    waitCount := 0
    Loop {
        if (!sheepRunning && !isFinalDrop)
            return false
        if (NFIsBright(invyDetectX, invyDetectY)) {
            return true
        }
        Sleep(50)
        waitCount++
        if (waitCount >= 100) {
            return false
        }
    }
}

SheepDropAll(isFinalDrop := false) {
    global sheepInventoryKey, sheepRunning
    if (!sheepRunning && !isFinalDrop)
        return
    Send("{" sheepInventoryKey "}")
    if (!SheepWaitForInventory(isFinalDrop))
        return
    SheepClickInventorySearch()
    Sleep(300)
    if (!sheepRunning && !isFinalDrop)
        return
    Send("t")
    Sleep(200)
    SheepClickDropAll()
    Sleep(150)
    Send("{" sheepInventoryKey "}")
    Sleep(150)
}

SheepClickDropAll() {
    global dropAllX, dropAllY
    MouseMove(dropAllX, dropAllY)
    Click()
}

SheepClickInventorySearch() {
    global invySearchX, invySearchY
    MouseMove(invySearchX, invySearchY)
    Click()
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

PxGet(x, y) {
    return PixelGetColor(x, y)
}

PxSearch(&fX, &fY, x1, y1, x2, y2, color, tol := 0) {
    return PixelSearch(&fX, &fY, x1, y1, x2, y2, color, tol)
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; NVIDIA FILTER HELPERS (per-step calibration) -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

NFColorDist(c1, c2) {
    r1 := (c1 >> 16) & 0xFF, g1 := (c1 >> 8) & 0xFF, b1 := c1 & 0xFF
    r2 := (c2 >> 16) & 0xFF, g2 := (c2 >> 8) & 0xFF, b2 := c2 & 0xFF
    return Max(Abs(r1 - r2), Abs(g1 - g2), Abs(b1 - b2))
}

NFChanged(x, y, baseline, tol := 25) {
    c := PxGet(x, y)
    return NFColorDist(baseline, c) > tol
}

NFPixelWait(x, y, x2, y2, color, tol, &baseline) {
    global nfEnabled
    if (!nfEnabled)
        return PxSearch(&_x, &_y, x, y, x2, y2, color, tol)
    if (PxSearch(&_x, &_y, x, y, x2, y2, color, Min(tol + 45, 120)))
        return true
    if (baseline = 0)
        baseline := PxGet(x, y)
    return NFChanged(x, y, baseline)
}

NFIsBright(x, y, threshold := 200) {
    global nfEnabled
    c := PxGet(x, y)
    r := (c >> 16) & 0xFF, g := (c >> 8) & 0xFF, b := c & 0xFF
    if (!nfEnabled)
        return (r > threshold && g > threshold && b > threshold)
    return ((r + g + b) // 3 > Max(threshold - 50, 120))
}

NFColorBright(c, threshold := 200) {
    global nfEnabled
    r := (c >> 16) & 0xFF, g := (c >> 8) & 0xFF, b := c & 0xFF
    if (!nfEnabled)
        return (r > threshold && g > threshold && b > threshold)
    return ((r + g + b) // 3 > Max(threshold - 50, 120))
}

NFHasContent(x, y, emptyBaseline, tol := 35) {
    c := PxGet(x, y)
    return NFColorDist(c, emptyBaseline) > tol
}

NFT(base, direction := 1) {
    global nfEnabled
    if (!nfEnabled)
        return base
    return Max(0, Min(255, base - (direction * 35)))
}

NFNotBlack(x, y, threshold := 15) {
    c := PxGet(x, y)
    r := (c >> 16) & 0xFF, g := (c >> 8) & 0xFF, b := c & 0xFF
    return ((r + g + b) > threshold)
}

NFSearchTol(&fX, &fY, x1, y1, x2, y2, color, tol := 0) {
    global nfEnabled
    return PxSearch(&fX, &fY, x1, y1, x2, y2, color, nfEnabled ? Min(tol + 45, 120) : tol)
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; OB UPLOAD FUNCTIONS -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

OBSetStatus(msg) {
    global obStatusText
    try obStatusText.Value := msg
    ToolTip(" Auto Upload — " msg "`nF6 = next mode  |  F1 = Show UI  |  Q = Stop", 0, 20)
}

OBWaitInvClose(reason) {
    global obLog, obUploadArmed, obUploadMode, obConfirmPixX, obConfirmPixY
    modeLabel := (obUploadMode = 1) ? "Cryos" : (obUploadMode = 2) ? "Tek+Cryos" : "Upload Char"
    OBSetStatus(reason " — manage items, close inv when ready")
    obLog.Push("Polling obConfirmPix for inv close (" reason ")")
    timeout := 600
    while (obUploadArmed && timeout > 0) {
        try {
            if !NFSearchTol(&px, &py, obConfirmPixX, obConfirmPixY, obConfirmPixX, obConfirmPixY, "0xFFFFFF", 15) {
                obLog.Push("Inv closed detected — ready for F")
                OBSetStatus("Press F at transmitter (" modeLabel ")")
                ToolTip(" Press F at transmitter (" modeLabel ")`n F1 = cancel", 0, 0)
                return
            }
        }
        Sleep(200)
        timeout--
    }
    if (timeout <= 0) {
        obLog.Push("Inv close poll timed out (120s)")
        OBSetStatus("Press F at transmitter (" modeLabel ")")
        ToolTip(" Press F at transmitter (" modeLabel ")`n F1 = cancel", 0, 0)
    }
}

OBStopAll(hideGui := true) {
    global obUploadMode := 0
    global obUploadArmed := false
    global obUploadRunning := false
    global obUploadPaused := false
    global obActiveFilter := ""
    global obUploadFilter := ""
    global obCharTimerStage := 0
    OBCharUnregisterSvrKeys()
    try obStatusText.Value := ""
    ToolTip()
    ToolTip(,,,2)
    if (hideGui) {
        MainGui.Hide()
        global guiVisible := false
    }
}

OBUploadCycle() {
    global obUploadMode, obUploadArmed, obUploadRunning, obUploadPaused, arkwindow, guiVisible
    global pcF10Step, pcMode, pcRunning
    global nsUploadFilterCB, ufList
    global svrList, obCharSvrIdx

    if (pcMode > 0 || pcF10Step > 0) {
        global pcF10Step := 0
        global pcMode    := 0
        global pcRunning := false
        PcRegisterSpeedHotkeys(false)
        PcUpdateUI()
        PcLog("OBUploadCycle: popcorn disabled to avoid F conflict")
        ToolTip(" Switched to OB Upload — popcorn off", 0, 0)
        SetTimer(() => ToolTip(), -1500)
    }

    if (obUploadRunning) {
        if (obUploadPaused) {
            global obUploadPaused := false
            OBSetStatus("Resumed...")
            ToolTip()
        } else {
            global obUploadPaused := true
            ToolTip(" OB Upload PAUSED`nF6 = resume", 10, 20)
        }
        return
    }

    global obUploadMode := Mod(obUploadMode + 1, 4)

    if (obUploadMode = 0) {
        OBStopAll(false)
        return
    }

    if WinExist(arkwindow)
        WinActivate(arkwindow)

    if (obUploadMode = 1) {
        global obUploadFilter := "cryop"
        global obUploadArmed := true
        ufNote := ""
        if (nsUploadFilterCB.Value && ufList.Length > 0) {
            filterStrs := []
            for f in ufList
                filterStrs.Push(f)
            ufNote := " — Filters: " UfJoin(filterStrs, ", ")
        }
        OBSetStatus("Cryos" ufNote)
    } else if (obUploadMode = 2) {
        global obUploadFilter := "Tek"
        global obUploadArmed := true
        OBSetStatus("Tek+Cryos")
    } else if (obUploadMode = 3) {
        global obUploadArmed := true
        global obCharTimerStage := 0
        global obCharSvrIdx := 0
        nextSvr := ""
        try nextSvr := ServerNumberEdit.Text
        if (nextSvr != "") {
            for i, entry in svrList {
                if (entry.num = nextSvr) {
                    global obCharSvrIdx := i
                    break
                }
            }
        }
        customSvr := ""
        if (nextSvr != "" && nextSvr != "2386")
            customSvr := nextSvr
        if (customSvr = "")
            nextLabel := "2386"
        else
            nextLabel := customSvr
        note := ""
        if (obCharSvrIdx > 0 && obCharSvrIdx <= svrList.Length && svrList[obCharSvrIdx].note != "")
            note := " (" svrList[obCharSvrIdx].note ")"
        OBSetStatus("Upload Char → " nextLabel note)
        OBCharRegisterSvrKeys()
    }
}

OBFPressed() {
    global obUploadArmed, obUploadMode, obUploadFilter, obLog, obUploadPaused
    global nsUploadFilterCB, ufList, obUploadEarlyExit
    _obStart := A_TickCount

    if (!obUploadArmed)
        return

    global obUploadArmed := false

    if (obUploadMode = 1) {
        MainGui.Hide()
        global guiVisible := false
        global obUploadRunning := true
        global obInitFailed := false
        obLog := []
        global obFirstUpload := true

        useFilterList := (nsUploadFilterCB.Value && ufList.Length > 0)

        if (useFilterList) {
            obLog.Push("=== CRYO run " FormatTime(, "yyyy-MM-dd HH:mm:ss") " filters=" ufList.Length " startTick=" _obStart " ===")
            if (OBCheckUploadTimer(ufList[1]))
                return
            for fi, uf in ufList {
                if (obUploadEarlyExit)
                    break
                global obUploadRunning := true
                global obFirstUpload := (fi = 1)
                skipNav := (fi > 1)
                skipClear := true
                OBSetStatus("Cryos " fi "/" ufList.Length " [" uf "]")
                obLog.Push("[UF " fi "/" ufList.Length "] filter='" uf "' skipNav=" skipNav)
                found := OBRunUpload(uf, "Uploading " uf, uf " done", true, false, skipNav, skipClear, "cryop")
                if (obInitFailed) {
                    global obUploadRunning := false
                    global obUploadArmed := true
                    OBSetStatus("Not at transmitter — F to retry")
                    ToolTip(" OB Upload [Cryos]: Not at transmitter`nF at OB to retry  |  F6 = cycle  |  F1 = UI", 0, 0)
                    PerfLogPush("ob_cryo", _obStart, "failed")
                    return
                }
                obLog.Push("[UF " fi "/" ufList.Length "] result=" (found ? "found items" : "no items"))
                if (obUploadEarlyExit) {
                    obLog.Push("[UF] stopped by user at filter " fi)
                    break
                }
            }
            OBClearFilter()
        } else {
            obLog.Push("=== CRYO run " FormatTime(, "yyyy-MM-dd HH:mm:ss") " filter=cryop startTick=" _obStart " ===")
            if (OBCheckUploadTimer("cryop"))
                return
            OBRunUpload("cryop", "Uploading cryos", "Cryos done", false)
            if (obInitFailed) {
                global obUploadRunning := false
                global obUploadArmed := true
                OBSetStatus("Not at transmitter — F to retry")
                ToolTip(" OB Upload [Cryos]: Not at transmitter`nF at OB to retry  |  F6 = cycle  |  F1 = UI", 0, 0)
                PerfLogPush("ob_cryo", _obStart, "failed")
                return
            }
        }
        OBTooltipRestore()
        OBStopAll()
        PerfLogPush("ob_cryo", _obStart, "done")

    } else if (obUploadMode = 2) {
        MainGui.Hide()
        global guiVisible := false
        global obInitFailed := false
        obLog := []
        global obFirstUpload := true
        obLog.Push("=== TEK+CRYO run " FormatTime(, "yyyy-MM-dd HH:mm:ss") " ===")
        global obUploadRunning := true
        if (OBCheckUploadTimer())
            return
        tekFilters := ["ek et", "ek che", "ek ot", "ek leg", "ek sw", "ek fl"]
        tekLabels  := ["Tek helmet+gauntlets", "Tek chest", "Tek boots", "Tek leggings", "Tek sword", "Tek rifle"]
        anyTekFound := false
        for i, tf in tekFilters {
            if (obUploadPaused) {
                OBSetStatus("PAUSED — F6 to resume")
                while (obUploadPaused && obUploadRunning)
                    Sleep(100)
                if (!obUploadRunning)
                    break
                if (obActiveFilter != "") {
                    A_Clipboard := obActiveFilter
                    MouseMove(mySearchBarX, mySearchBarY, 0)
                    Sleep(30)
                    Click
                    Sleep(60)
                    Send("^a")
                    Sleep(20)
                    Send("^v")
                    Sleep(150)
                    MouseMove(myFirstSlotX, myFirstSlotY, 0)
                    Sleep(80)
                }
                OBSetStatus("Resuming...")
            }
            global obUploadRunning := true
            global obUploadEarlyExit := false
            skipNav  := (i > 1)
            skipClear := true
            OBSetStatus("Tek " i "/6 [" tf "]: " tekLabels[i] "...")
            obLog.Push("[TEK " i "/6] filter='" tf "' skipNav=" skipNav " skipClear=" skipClear)
            found := OBRunUpload(tf, "Uploading " tekLabels[i], tekLabels[i] " done", true, false, skipNav, skipClear)
            if (obInitFailed) {
                global obUploadRunning := false
                global obUploadArmed := true
                OBSetStatus("Not at transmitter — F to retry")
                ToolTip(" OB Upload [Tek+Cryos]: Not at transmitter`nF at OB to retry  |  F6 = cycle  |  F1 = UI", 0, 0)
                return
            }
            obLog.Push("[TEK " i "/6] result=" (found?"found items":"no items found"))
            if (found)
                anyTekFound := true
            if (obUploadEarlyExit) {
                obLog.Push("[TEK] stopped by user (Q) at filter " i)
                break
            }
        }
        obLog.Push("[TEK] phase complete. anyTekFound=" (anyTekFound?"yes":"no"))
        if (obUploadEarlyExit) {
            obLog.Push("[TEK+CRYO] stopped by user — skipping cryo phase")
            global obUploadEarlyExit := false
            OBTooltipRestore()
            OBStopAll()
            PerfLogPush("ob_tek_cryo", _obStart, "early")
            return
        }
        if (!anyTekFound)
            OBSetStatus("No tek found — moving to cryos")
        Sleep(400)
        global obUploadRunning := true
        global obUploadEarlyExit := false
        obLog.Push("[CRYO] starting cryo phase")
        A_Clipboard := "cryop"
        cryoFound := OBRunUpload("cryop", "Uploading cryos", "Cryos done", true, true, true)
        obLog.Push("[CRYO] result=" (cryoFound?"found items":"no cryos found"))
        if (!cryoFound) {
            OBSetStatus("No cryos found")
            Sleep(2000)
        }
        OBTooltipRestore()
        OBStopAll()
        PerfLogPush("ob_tek_cryo", _obStart, "done")

    } else if (obUploadMode = 3) {
        MainGui.Hide()
        global guiVisible := false
        global obUploadRunning := true
        OBCharUnregisterSvrKeys()
        obLog := []
        obLog.Push("=== UPLOAD CHARACTER " FormatTime(, "yyyy-MM-dd HH:mm:ss") " ===")
        OBSetStatus("Upload Character — waiting for transmitter screen")
        SetTimer(OBUploadCharacterThread, -1)
    }
}

OBUploadCharacterThread() {
    global obUploadRunning, obUploadArmed, obLog, arkwindow
    global obCharTravelX, obCharTravelY
    global obConfirmPixX, obConfirmPixY
    global ServerSearchOffsetX, ServerSearchOffsetY
    global ClickSessionOffsetX, ClickSessionOffsetY
    global ServerJoinOffsetX, ServerJoinOffsetY
    global ServerNumberEdit, GameWindow, GameWidth, GameHeight
    global widthmultiplier, heightmultiplier
    global obCharCustomServer
    global nfEnabled, obUploadMode

    global obCharTravelX := Round(1271 * widthmultiplier)
    global obCharTravelY := Round(1060 * heightmultiplier)

    if (GameWidth = 0 || GameHeight = 0) {
        if WinExist(GameWindow)
            WinGetPos(,, &GameWidth, &GameHeight, GameWindow)
    }

    CoordMode("Pixel", "Screen")
    CoordMode("Mouse", "Screen")

    serverNum := ""
    try serverNum := ServerNumberEdit.Text
    customSvr := ""

    if (serverNum != "" && serverNum != "2386") {
        customSvr := serverNum
        if (obCharCustomServer != serverNum) {
            global obCharCustomServer := serverNum
            OBCharSaveServerSilent()
        }
    }

    if (customSvr = "") {
        serverNum := "2386"
    } else {
        serverNum := customSvr
    }
    obLog.Push("Server: " serverNum "  custom=" obCharCustomServer)

    OBSetStatus("Waiting for transmitter...")
    waitCount := 0
    found := false
    while (obUploadRunning && waitCount < 250) {
        try {
            if (NFSearchTol(&px, &py, obConfirmPixX, obConfirmPixY, obConfirmPixX, obConfirmPixY, "0xFFFFFF", 15)) {
                found := true
                break
            }
        }
        Sleep(16)
        waitCount++
    }

    if (!found) {
        obLog.Push("Transmitter not detected — timeout (" (waitCount * 16) "ms)")
        global obUploadArmed := true
        global obUploadRunning := false
        OBSetStatus("Not at transmitter — F to retry")
        OBCharRegisterSvrKeys()
        ToolTip(" Upload Character: transmitter not detected`nF to retry  |  ↑↓ cycle  |  F6 = cycle  |  F1 = UI", 0, 0)
        return
    }
    obLog.Push("Transmitter detected after " (waitCount * 16) "ms  pixel=(" obConfirmPixX "," obConfirmPixY ")")

    if (obCharTimerStage = 0) {
        try {
            scanX := obOcrX[5]
            scanY := obOcrY[5]
            scanW := obOcrW[5]
            scanH := obOcrH[5]
            tOcr := OCR.FromRect(scanX, scanY, scanW, scanH, {scale: 2}).Text
            obLog.Push("Timer OCR (" scanX "," scanY " " scanW "x" scanH "): [" SubStr(tOcr, 1, 200) "]")
            maxSec := 0
            startPos := 1
            while RegExMatch(tOcr, "(\d{1,2}):(\d{2})", &tMatch, startPos) {
                mins := Integer(tMatch[1])
                secs := Integer(tMatch[2])
                if (mins <= 15 && secs < 60) {
                    total := mins * 60 + secs
                    if (total > maxSec)
                        maxSec := total
                }
                startPos := tMatch.Pos + tMatch.Len
            }
            if (maxSec > 0) {
                global obCharTimerStage := 1
                tm := maxSec // 60
                ts := Mod(maxSec, 60)
                obLog.Push("Timer " tm ":" Format("{:02}", ts) " — closing transmitter, re-armed")
                Send("{Escape}")
                Sleep(200)
                modeLabel := "Upload Char"
                global obUploadRunning := false
                global obUploadArmed := true
                OBSetStatus("Upload timer: " tm ":" Format("{:02}", ts) " — F to manage items (" modeLabel ")")
                ToolTip(" F to manage items  |  F1 = cancel", 0, 0)
                ToolTip(" Upload timer: " tm ":" Format("{:02}", ts), 0, 40, 2)
                return
            }
        } catch as ocrErr {
            obLog.Push("Timer OCR failed: " ocrErr.Message)
        }
    } else if (obCharTimerStage = 1) {
        obLog.Push("Stage 1 — inv management, polling for inv close")
        global obCharTimerStage := 2
        global obUploadRunning := false
        global obUploadArmed := true
        SetTimer(OBWaitInvClose.Bind("Timer items"), -1)
        return
    } else {
        obLog.Push("Stage 2 — re-checking timer before Travel")
        try {
            scanX := obOcrX[5]
            scanY := obOcrY[5]
            scanW := obOcrW[5]
            scanH := obOcrH[5]
            tOcr := OCR.FromRect(scanX, scanY, scanW, scanH, {scale: 2}).Text
            obLog.Push("Re-check OCR: [" SubStr(tOcr, 1, 200) "]")
            maxSec := 0
            startPos := 1
            while RegExMatch(tOcr, "(\d{1,2}):(\d{2})", &tMatch, startPos) {
                mins := Integer(tMatch[1])
                secs := Integer(tMatch[2])
                if (mins <= 15 && secs < 60) {
                    total := mins * 60 + secs
                    if (total > maxSec)
                        maxSec := total
                }
                startPos := tMatch.Pos + tMatch.Len
            }
            if (maxSec > 0) {
                global obCharTimerStage := 1
                tm := maxSec // 60
                ts := Mod(maxSec, 60)
                obLog.Push("Timer still active " tm ":" Format("{:02}", ts) " — back to stage 1")
                Send("{Escape}")
                Sleep(200)
                modeLabel := "Upload Char"
                global obUploadRunning := false
                global obUploadArmed := true
                OBSetStatus("Timer " tm ":" Format("{:02}", ts) " still active — F to manage items (" modeLabel ")")
                ToolTip(" Timer still active — F to manage items  |  F1 = cancel", 0, 0)
                ToolTip(" Upload timer: " tm ":" Format("{:02}", ts), 0, 40, 2)
                return
            }
            obLog.Push("No timer — proceeding to Travel")
        } catch as ocrErr {
            obLog.Push("Re-check OCR failed: " ocrErr.Message)
        }
    }

    OBSetStatus("Clicking Travel to Another Server...")
    Sleep(200)
    try travelCol := PxGet(obCharTravelX, obCharTravelY)
    catch
        travelCol := "?"
    obLog.Push("Travel target (" obCharTravelX "," obCharTravelY ") color=" travelCol "  wm=" widthmultiplier " hm=" heightmultiplier)
    DllCall("SetCursorPos", "int", obCharTravelX, "int", obCharTravelY)
    Sleep(50)
    Click()
    Sleep(500)
    obLog.Push("Clicked Travel button")

    obcBrowserX := Round(1299 * widthmultiplier)
    obcBrowserY := Round(157  * heightmultiplier)
    obcSearchX  := Round(1927 * widthmultiplier)
    obcSearchY  := Round(245  * heightmultiplier)
    obcSessionX := Round(1316 * widthmultiplier)
    obcSessionY := Round(419  * heightmultiplier)
    obcJoinX    := Round(2180 * widthmultiplier)
    obcJoinY    := Round(1189 * heightmultiplier)

    OBSetStatus("Waiting for server browser...")
    browserFound := false
    bWait := 0
    while (obUploadRunning && bWait < 375) {
        try {
            if (NFSearchTol(&bpx, &bpy, obcBrowserX, obcBrowserY, obcBrowserX, obcBrowserY, "0xC1F5FF", 15)) {
                browserFound := true
                break
            }
        }
        Sleep(16)
        bWait++
    }
    obLog.Push("Browser wait: " (bWait * 16) "ms  found=" browserFound "  pixel=(" obcBrowserX "," obcBrowserY ")")

    if (!browserFound) {
        try bCol := PxGet(obcBrowserX, obcBrowserY)
        catch
            bCol := "?"
        obLog.Push("Browser timeout — color at pixel=" bCol)
        OBSetStatus("Browser timeout")
        Sleep(2000)
        OBStopAll()
        return
    }

    if (!obUploadRunning)
        return

    OBSetStatus("Searching for server " serverNum "...")
    Sleep(300)
    DllCall("SetCursorPos", "int", obcSearchX, "int", obcSearchY)
    Sleep(50)
    Click()
    Sleep(100)
    Send("^a")
    Sleep(50)
    Send("{Delete}")
    Sleep(50)
    SendText(serverNum)
    Sleep(300)
    obLog.Push("Searched for: " serverNum "  searchBar=(" obcSearchX "," obcSearchY ")")

    obcBeLogoX := Round(235 * widthmultiplier)
    obcBeLogoY := Round(427 * heightmultiplier)
    DllCall("SetCursorPos", "int", 0, "int", 0)
    Sleep(50)
    try preBeCol := PxGet(obcBeLogoX, obcBeLogoY)
    catch
        preBeCol := "?"
    obLog.Push("BE logo pixel (" obcBeLogoX "," obcBeLogoY ") pre-color=" preBeCol)
    OBSetStatus("Waiting for server to load...")
    beFound := false
    beWait := 0
    lastSample := 0
    while (obUploadRunning && beWait < 250) {
        try {
            beCol := PxGet(obcBeLogoX, obcBeLogoY)
            if (beWait - lastSample >= 30) {
                obLog.Push("BE sample @" (beWait * 16) "ms: " beCol)
                lastSample := beWait
            }
            r := Integer("0x" SubStr(beCol, 3, 2))
            g := Integer("0x" SubStr(beCol, 5, 2))
            b := Integer("0x" SubStr(beCol, 7, 2))
            if (r > NFT(100, 1) && g > NFT(200, 1) && b > NFT(230, 1)) {
                beFound := true
                obLog.Push("BE detected (color match): " beCol " @" (beWait * 16) "ms")
                break
            }
            if (nfEnabled && preBeCol != "?" && beWait > 10) {
                preParsed := IsInteger(preBeCol) ? preBeCol : Integer(preBeCol)
                curParsed := IsInteger(beCol) ? beCol : Integer(beCol)
                if (NFColorDist(preParsed, curParsed) > 40) {
                    beFound := true
                    obLog.Push("BE detected (change from " preBeCol "): " beCol " @" (beWait * 16) "ms")
                    break
                }
            }
        }
        Sleep(16)
        beWait++
    }
    obLog.Push("BE logo wait: " (beWait * 16) "ms  found=" beFound "  pixel=(" obcBeLogoX "," obcBeLogoY ")")

    if (!beFound) {
        try beTimeoutCol := PxGet(obcBeLogoX, obcBeLogoY)
        catch
            beTimeoutCol := "?"
        obLog.Push("Server list timeout — BE logo not found — color now=" beTimeoutCol)
        OBSetStatus("Server list timeout")
        Sleep(2000)
        OBStopAll()
        return
    }
    Sleep(200)

    OBSetStatus("Clicking session...")
    DllCall("SetCursorPos", "int", obcSessionX, "int", obcSessionY)
    Sleep(50)
    Click()
    Sleep(500)
    DllCall("SetCursorPos", "int", obcSessionX, "int", obcSessionY)
    Sleep(50)
    Click()
    Sleep(300)
    obLog.Push("Clicked session x2 (" obcSessionX "," obcSessionY ")")

    joinConfirmed := false
    itemsBlocked := false
    joinAttempts := 0
    while (obUploadRunning && joinAttempts < 30) {
        joinAttempts++
        ToolTip()  
        DllCall("SetCursorPos", "int", obcJoinX, "int", obcJoinY)
        Sleep(50)
        Click()
        Sleep(600)
        try {
            jText := OCR.FromRect(0, 0, A_ScreenWidth, A_ScreenHeight, {scale: 1}).Text
            jLower := StrLower(jText)
            if (InStr(jLower, "items not allowed") || InStr(jLower, "not ready for upload") || InStr(jLower, "can not be transferred")) {
                itemsBlocked := true
                obLog.Push("Items Not Allowed popup detected after " joinAttempts " attempts: [" SubStr(jText, 1, 200) "]")
                break
            }
            if (InStr(jText, "Joining") || InStr(jText, "joining")) {
                joinConfirmed := true
                obLog.Push("Join confirmed by OCR after " joinAttempts " attempts: [" jText "]")
                break
            }
        }
        if (Mod(joinAttempts, 3) = 0) {
            obLog.Push("Join not confirmed after " joinAttempts " — re-clicking session")
            DllCall("SetCursorPos", "int", obcSessionX, "int", obcSessionY)
            Sleep(50)
            Click()
            Sleep(500)
            DllCall("SetCursorPos", "int", obcSessionX, "int", obcSessionY)
            Sleep(50)
            Click()
            Sleep(300)
        } else {
            Sleep(300)
        }
    }

    if (itemsBlocked) {
        obLog.Push("Exiting transmitter (Esc x2)")
        Send("{Escape}")
        Sleep(300)
        Send("{Escape}")
        Sleep(300)
        global obUploadRunning := false
        global obUploadArmed := true
        global obUploadMode := 3
        global obCharTimerStage := 1
        OBSetStatus("Items Not Allowed — F to manage items")
        return
    }

    if (!joinConfirmed) {
        obLog.Push("Join not confirmed by OCR after " joinAttempts " attempts — re-arming (server NOT marked as last dest)")
        global obUploadRunning := false
        global obUploadArmed := true
        global obUploadMode := 3
        global obCharTimerStage := 0
        OBSetStatus("Join failed — press F at transmitter to retry")
        ToolTip(" Join failed — server not marked`n Press F at transmitter to retry", 0, 0)
        SetTimer(() => ToolTip(), -4000)
        return
    }
    Sleep(1000)

    global obUploadRunning := false
    global obUploadArmed := false
    global obUploadMode := 0
    OBCharUnregisterSvrKeys()
    obLog.Push("Upload Char complete → server " serverNum " — mode OFF")
    OBSetStatus("")
    ToolTip(,,,2)
    ToolTip(" Upload Char done → " serverNum "`n F6 to re-enable  |  F1 = UI", 0, 0)
    SetTimer(() => ToolTip(), -3000)
}

OBCharSaveServer(*) {
    global obCharCustomServer, ServerNumberEdit
    val := Trim(ServerNumberEdit.Text)
    if (val != "" && val != "2386") {
        global obCharCustomServer := val
        IniWrite(val, A_ScriptDir "\AIO_config.ini", "UploadChar", "CustomServer")
        ToolTip(" Saved server: " val " (F6 alternates with 2386)", 0, 0)
    } else {
        ToolTip(" Enter a server other than 2386 to save", 0, 0)
    }
    SetTimer(() => ToolTip(), -2000)
}

OBCharSaveServerSilent() {
    global obCharCustomServer
    if (obCharCustomServer != "")
        IniWrite(obCharCustomServer, A_ScriptDir "\AIO_config.ini", "UploadChar", "CustomServer")
}

OBCharRestoreTooltip() {
    global obUploadMode, obUploadArmed, obUploadRunning, guiVisible
    global obCharCustomServer, ServerNumberEdit, svrList
    if (obUploadMode != 3 || !obUploadArmed || obUploadRunning || guiVisible)
        return
    nextSvr := ""
    try nextSvr := ServerNumberEdit.Text
    customSvr := ""
    if (nextSvr != "" && nextSvr != "2386")
        customSvr := nextSvr
    if (customSvr = "")
        nextLabel := "2386"
    else
        nextLabel := customSvr
    note := ""
    for entry in svrList {
        if (entry.num = nextSvr && entry.note != "") {
            note := " (" entry.note ")"
            break
        }
    }
    ToolTip(" Upload Char armed → " nextLabel note "`n ↑↓ cycle servers  |  F at transmitter  |  F6 = cycle/off", 0, 0)
}

OBCharLoadServer() {
    global obCharCustomServer, ServerNumberEdit
    try {
        saved := IniRead(A_ScriptDir "\AIO_config.ini", "UploadChar", "CustomServer", "")
        if (saved != "") {
            global obCharCustomServer := saved
            try ServerNumberEdit.Text := saved
        }
    }
}

OBCharRegisterSvrKeys() {
    try Hotkey("$Up", OBCharSvrUp, "On")
    try Hotkey("$Down", OBCharSvrDown, "On")
}

OBCharUnregisterSvrKeys() {
    try Hotkey("$Up", "Off")
    try Hotkey("$Down", "Off")
}

OBCharSvrUp(*) {
    global arkwindow
    if (!WinActive(arkwindow)) {
        Send("{Up}")
        return
    }
    OBCharSvrCycle(-1)
}

OBCharSvrDown(*) {
    global arkwindow
    if (!WinActive(arkwindow)) {
        Send("{Down}")
        return
    }
    OBCharSvrCycle(1)
}

OBCharSvrCycle(dir) {
    global svrList, ServerNumberEdit, obCharSvrIdx
    if (svrList.Length = 0) {
        ToolTip(" No servers in list — add via Tab 1", 0, 0)
        SetTimer(() => ToolTip(), -1500)
        return
    }
    global obCharSvrIdx := obCharSvrIdx + dir
    if (obCharSvrIdx < 1)
        global obCharSvrIdx := svrList.Length
    if (obCharSvrIdx > svrList.Length)
        global obCharSvrIdx := 1
    entry := svrList[obCharSvrIdx]
    try ServerNumberEdit.Text := entry.num
    OBCharSaveServerSilent()
    nextSvr := entry.num
    customSvr := ""
    if (nextSvr != "" && nextSvr != "2386")
        customSvr := nextSvr
    if (customSvr = "")
        nextLabel := "2386"
    else
        nextLabel := customSvr
    note := (entry.note != "") ? " (" entry.note ")" : ""
    OBSetStatus("Upload Char → " nextLabel note)
    ToolTip(" Upload Char armed → " nextLabel note "`n ↑↓ cycle servers  |  F at transmitter  |  F6 = cycle/off", 0, 0)
}

; ── Server List ──────────────────────────────────────────────────────────────

SvrComboChanged(*) {
    global svrList, ServerNumberEdit
    sel := ServerNumberEdit.Text
    if (sel = "")
        return
    if RegExMatch(sel, "^(\d+)", &m) {
        num := m[1]
        if (InStr(sel, " - "))
            ServerNumberEdit.Text := num
        OBCharSaveServerSilent()
    }
}

SvrAddCurrent(*) {
    global svrList, ServerNumberEdit
    num := Trim(ServerNumberEdit.Text)
    if (num = "" || !RegExMatch(num, "^\d+$")) {
        ToolTip(" Enter a server number first", 0, 0)
        SetTimer(() => ToolTip(), -1500)
        return
    }
    for entry in svrList {
        if (entry.num = num) {
            ToolTip(" Server " num " already in list", 0, 0)
            SetTimer(() => ToolTip(), -1500)
            return
        }
    }
    svrList.Push({num: num, note: ""})
    SvrSaveList()
    SvrRefreshDDL()
    ToolTip(" Added server " num, 0, 0)
    SetTimer(() => ToolTip(), -1500)
}

SvrRemoveSelected(*) {
    global svrList, ServerNumberEdit
    num := Trim(ServerNumberEdit.Text)
    if (num = "")
        return
    found := 0
    for i, entry in svrList {
        if (entry.num = num) {
            found := i
            break
        }
    }
    if (found = 0) {
        ToolTip(" Server " num " not in list", 0, 0)
        SetTimer(() => ToolTip(), -1500)
        return
    }
    svrList.RemoveAt(found)
    SvrSaveList()
    SvrRefreshDDL()
    ToolTip(" Removed server " num, 0, 0)
    SetTimer(() => ToolTip(), -1500)
}

SvrEditNote(*) {
    global svrList, ServerNumberEdit, svrNoteGui
    num := Trim(ServerNumberEdit.Text)
    if (num = "")
        return
    found := 0
    for i, entry in svrList {
        if (entry.num = num) {
            found := i
            break
        }
    }
    if (found = 0) {
        ToolTip(" Add server first with +", 0, 0)
        SetTimer(() => ToolTip(), -1500)
        return
    }
    if (IsSet(svrNoteGui) && svrNoteGui != "") {
        try svrNoteGui.Destroy()
        global svrNoteGui := ""
    }
    svrNoteGui := Gui("+AlwaysOnTop +Owner", "Server Note")
    svrNoteGui.BackColor := "1A1A1A"
    svrNoteGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
    svrNoteGui.Add("Text", "x20 y15 w230", "Note for server " num)
    svrNoteGui.SetFont("s9 c000000", "Segoe UI")
    noteEdit := svrNoteGui.Add("Edit", "x20 y40 w230 h24", svrList[found].note)
    svrNoteGui.SetFont("s9 cFFFFFF Bold", "Segoe UI")
    saveBtn := svrNoteGui.Add("Button", "x70 y72 w80 h26", "Save")
    cancelBtn := svrNoteGui.Add("Button", "x155 y72 w80 h26", "Cancel")
    _found := found
    saveBtn.OnEvent("Click", (*) => SvrNoteSave(_found, noteEdit.Value))
    cancelBtn.OnEvent("Click", (*) => svrNoteGui.Destroy())
    svrNoteGui.OnEvent("Close", (*) => svrNoteGui.Destroy())
    svrNoteGui.Show("AutoSize")
}

SvrNoteSave(idx, noteVal) {
    global svrList, ServerNumberEdit, svrNoteGui
    svrList[idx].note := noteVal
    SvrSaveList()
    SvrRefreshDDL()
    ServerNumberEdit.Text := svrList[idx].num
    try svrNoteGui.Destroy()
}

SvrRefreshDDL() {
    global svrList, ServerNumberEdit
    items := []
    for entry in svrList {
        label := entry.num
        if (entry.note != "")
            label .= " - " entry.note
        items.Push(label)
    }
    ServerNumberEdit.Delete()
    ServerNumberEdit.Add(items)
}

SvrSaveList() {
    global svrList
    configFile := A_ScriptDir "\AIO_config.ini"
    try IniDelete(configFile, "Servers")
    IniWrite(svrList.Length, configFile, "Servers", "Count")
    loop svrList.Length {
        e := svrList[A_Index]
        IniWrite(e.num, configFile, "Servers", "Num" A_Index)
        IniWrite(e.note, configFile, "Servers", "Note" A_Index)
    }
}

SvrLoadList() {
    global svrList, ServerNumberEdit
    configFile := A_ScriptDir "\AIO_config.ini"
    svrList := []
    try {
        cnt := Integer(IniRead(configFile, "Servers", "Count", "0"))
        loop cnt {
            num := IniRead(configFile, "Servers", "Num" A_Index, "")
            note := IniRead(configFile, "Servers", "Note" A_Index, "")
            if (num != "")
                svrList.Push({num: num, note: note})
        }
    }
    SvrRefreshDDL()
}

; ── UPLOAD FILTER LIST MANAGEMENT ────────────────────────────────────────────

UfAddFilter(*) {
    global ufList, ufFilterCombo
    val := Trim(ufFilterCombo.Text)
    if (val = "")
        return
    for entry in ufList {
        if (entry = val) {
            ToolTip(" Filter already in list", 0, 0)
            SetTimer(() => ToolTip(), -1500)
            return
        }
    }
    ufList.Push(val)
    UfSaveList()
    UfRefreshDDL()
    ufFilterCombo.Text := val
    ToolTip(" Added filter: " val, 0, 0)
    SetTimer(() => ToolTip(), -1500)
}

UfRemoveFilter(*) {
    global ufList, ufFilterCombo
    val := Trim(ufFilterCombo.Text)
    if (val = "")
        return
    found := 0
    for i, entry in ufList {
        if (entry = val) {
            found := i
            break
        }
    }
    if (found = 0) {
        ToolTip(" Filter not in list", 0, 0)
        SetTimer(() => ToolTip(), -1500)
        return
    }
    ufList.RemoveAt(found)
    UfSaveList()
    UfRefreshDDL()
    ufFilterCombo.Text := ""
    ToolTip(" Removed filter: " val, 0, 0)
    SetTimer(() => ToolTip(), -1500)
}

UfRefreshDDL() {
    global ufList, ufFilterCombo
    items := []
    for entry in ufList
        items.Push(entry)
    ufFilterCombo.Delete()
    ufFilterCombo.Add(items)
}

UfSaveList() {
    global ufList, nsUploadFilterCB
    configFile := A_ScriptDir "\AIO_config.ini"
    try IniDelete(configFile, "UploadFilters")
    IniWrite(nsUploadFilterCB.Value, configFile, "UploadFilters", "Enabled")
    IniWrite(ufList.Length, configFile, "UploadFilters", "Count")
    loop ufList.Length
        IniWrite(ufList[A_Index], configFile, "UploadFilters", "Filter" A_Index)
}

UfLoadList() {
    global ufList
    configFile := A_ScriptDir "\AIO_config.ini"
    ufList := []
    try {
        cnt := Integer(IniRead(configFile, "UploadFilters", "Count", "0"))
        loop cnt {
            f := IniRead(configFile, "UploadFilters", "Filter" A_Index, "")
            if (f != "")
                ufList.Push(f)
        }
    }
    UfRefreshDDL()
}


; ── DROPDOWN LIST HELPERS ────────────────────────────────────────────

AcListHas(list, val) {
    for , v in list
        if (v = val)
            return true
    return false
}

_ListAdd(list, combo, section) {
    val := Trim(combo.Text)
    if (val = "")
        return
    if (AcListHas(list, val)) {
        ToolTip(" Already in list", 0, 0)
        SetTimer(() => ToolTip(), -1500)
        return
    }
    list.Push(val)
    _ListSave(list, section)
    _ListRefresh(list, combo)
    combo.Text := val
    ToolTip(" Added: " val, 0, 0)
    SetTimer(() => ToolTip(), -1500)
}

_ListRemove(list, combo, section) {
    val := Trim(combo.Text)
    if (val = "")
        return
    found := 0
    for i, v in list {
        if (v = val) {
            found := i
            break
        }
    }
    if (found = 0) {
        ToolTip(" Not in list", 0, 0)
        SetTimer(() => ToolTip(), -1500)
        return
    }
    list.RemoveAt(found)
    _ListSave(list, section)
    _ListRefresh(list, combo)
    combo.Text := ""
    ToolTip(" Removed: " val, 0, 0)
    SetTimer(() => ToolTip(), -1500)
}

_ListRefresh(list, combo) {
    items := []
    for , v in list
        items.Push(v)
    combo.Delete()
    combo.Add(items)
}

_ListSave(list, section) {
    configFile := A_ScriptDir "\AIO_config.ini"
    try IniDelete(configFile, section)
    IniWrite(list.Length, configFile, section, "Count")
    loop list.Length
        IniWrite(list[A_Index], configFile, section, "Item" A_Index)
}

_ListLoad(list, combo, section) {
    configFile := A_ScriptDir "\AIO_config.ini"
    list.Length := 0
    try {
        cnt := Integer(IniRead(configFile, section, "Count", "0"))
        loop cnt {
            v := IniRead(configFile, section, "Item" A_Index, "")
            if (v != "")
                list.Push(v)
        }
    }
    _ListRefresh(list, combo)
}

; ── Name List ──
CnAddName(*) {
    global cnNameList, ClaimAndNameEdit
    _ListAdd(cnNameList, ClaimAndNameEdit, "NameList")
}
CnRemoveName(*) {
    global cnNameList, ClaimAndNameEdit
    _ListRemove(cnNameList, ClaimAndNameEdit, "NameList")
}

; ── Craft Filter Lists ──
AcFilterAdd(which) {
    global acSimpleFilterList, acSimpleFilterEdit
    global acTimedFilterList, acTimedFilterEdit
    global acGridFilterList, acGridFilterEdit
    if (which = "simple")
        _ListAdd(acSimpleFilterList, acSimpleFilterEdit, "CraftSimpleFilters")
    else if (which = "timed")
        _ListAdd(acTimedFilterList, acTimedFilterEdit, "CraftTimedFilters")
    else if (which = "grid")
        _ListAdd(acGridFilterList, acGridFilterEdit, "CraftGridFilters")
}
AcFilterRemove(which) {
    global acSimpleFilterList, acSimpleFilterEdit
    global acTimedFilterList, acTimedFilterEdit
    global acGridFilterList, acGridFilterEdit
    if (which = "simple")
        _ListRemove(acSimpleFilterList, acSimpleFilterEdit, "CraftSimpleFilters")
    else if (which = "timed")
        _ListRemove(acTimedFilterList, acTimedFilterEdit, "CraftTimedFilters")
    else if (which = "grid")
        _ListRemove(acGridFilterList, acGridFilterEdit, "CraftGridFilters")
}

; ── Popcorn Filter List ──
PcFilterAdd(*) {
    global pcCustomFilterList, pcCustomEdit
    _ListAdd(pcCustomFilterList, pcCustomEdit, "PopcornFilters")
}
PcFilterRemove(*) {
    global pcCustomFilterList, pcCustomEdit
    _ListRemove(pcCustomFilterList, pcCustomEdit, "PopcornFilters")
}

; ── Magic F Filter Lists ──
MfGiveAdd(*) {
    global mfGiveFilterList, CustomEditGive
    _ListAdd(mfGiveFilterList, CustomEditGive, "MagicFGiveFilters")
}
MfGiveRemove(*) {
    global mfGiveFilterList, CustomEditGive
    _ListRemove(mfGiveFilterList, CustomEditGive, "MagicFGiveFilters")
}
MfTakeAdd(*) {
    global mfTakeFilterList, CustomEditTake
    _ListAdd(mfTakeFilterList, CustomEditTake, "MagicFTakeFilters")
}
MfTakeRemove(*) {
    global mfTakeFilterList, CustomEditTake
    _ListRemove(mfTakeFilterList, CustomEditTake, "MagicFTakeFilters")
}

UfJoin(arr, sep) {
    result := ""
    for i, v in arr {
        if (i > 1)
            result .= sep
        result .= v
    }
    return result
}

OBCheckUploadTimer(filter := "") {
    global obLog, obUploadRunning, obUploadArmed, obUploadMode
    global MainGui, guiVisible
    global obConfirmPixX, obConfirmPixY
    global obOcrX, obOcrY, obOcrW, obOcrH
    global widthmultiplier, heightmultiplier
    global mySearchBarX, mySearchBarY, arkwindow
    if (guiVisible) {
        MainGui.Hide()
        global guiVisible := false
    }
    ToolTip()
    ToolTip(,,,1)
    ToolTip(,,,2)

    invOpen := false
    invWait := 0
    while (obUploadRunning && invWait < 250) {
        try {
            if (NFSearchTol(&px, &py, obConfirmPixX, obConfirmPixY, obConfirmPixX, obConfirmPixY, "0xFFFFFF", 15)) {
                invOpen := true
                break
            }
        }
        Sleep(16)
        invWait++
    }
    if (!invOpen) {
        obLog.Push("Timer check: inventory not detected (" (invWait * 16) "ms) — skipping")
        return false
    }
    Sleep(200)

    if (filter != "") {
        obLog.Push("Timer check: filtering [" filter "]")
        ControlClick("x" mySearchBarX " y" mySearchBarY, arkwindow)
        Sleep(30)
        Send(filter)
        Sleep(400)
    }
    scanX := obOcrX[5]
    scanY := obOcrY[5]
    scanW := obOcrW[5]
    scanH := obOcrH[5]
    timerSec := 0
    try {
        tOcr := OCR.FromRect(scanX, scanY, scanW, scanH, {scale: 2}).Text
        obLog.Push("Timer OCR (" scanX "," scanY " " scanW "x" scanH "): [" SubStr(tOcr, 1, 200) "]")
        maxSec := 0
        startPos := 1
        while RegExMatch(tOcr, "(\d{1,2}):(\d{2})", &tMatch, startPos) {
            mins := Integer(tMatch[1])
            secs := Integer(tMatch[2])
            if (mins <= 15 && secs < 60) {
                total := mins * 60 + secs
                if (total > maxSec)
                    maxSec := total
            }
            startPos := tMatch.Pos + tMatch.Len
        }
        if (maxSec > 0) {
            timerSec := maxSec + 3
            obLog.Push("Upload timer found: " (maxSec // 60) ":" Format("{:02}", Mod(maxSec, 60)) " + 3s buffer = " timerSec "s")
        }
    } catch as ocrErr {
        obLog.Push("Timer OCR failed: " ocrErr.Message)
    }

    if (timerSec > 0) {
        Send("{Escape}")
        Sleep(200)
        obLog.Push("Timer active — closing inv, countdown " timerSec "s")
        while (timerSec > 0 && obUploadRunning) {
            m := timerSec // 60
            s := Mod(timerSec, 60)
            ToolTip(" Upload timer: " m ":" Format("{:02}", s) "`n Waiting to upload...  |  F1 = cancel", 0, 0)
            Sleep(1000)
            timerSec--
        }
        ToolTip()
        if (!obUploadRunning)
            return true
        global obUploadRunning := false
        global obUploadArmed := true
        modeLabel := (obUploadMode = 1) ? "Cryos" : (obUploadMode = 2) ? "Tek+Cryos" : "Upload Char"
        ToolTip(" Timer done — F at transmitter (" modeLabel ")`n F6 = cycle  |  F1 = UI", 0, 0)
        obLog.Push("Timer expired — re-armed (" modeLabel ")")
        return true
    }
    if (filter != "") {
        obLog.Push("Timer check: no timer on [" filter "] — proceeding")
    }
    return false
}

OBRunUpload(filter, startMsg, doneMsg, checkEmpty, closeOnDone := true, skipNav := false, skipClear := false, detectAs := "") {
    global obUploadRunning, obInvPixX, obInvPixY, obInvTimeout, obLog, obInitFailed
    global obRightTabPixX, obRightTabPixY
    global obConfirmPixX, obConfirmPixY
    global obUploadTabX, obUploadTabY, obUploadReadyPixX, obUploadReadyPixY
    global mySearchBarX, mySearchBarY, myFirstSlotX, myFirstSlotY
    global obFailCloseX, obFailCloseY
    global obFullPixX, obFullPixY
    global obMaxItemsPixX, obMaxItemsPixY
    global obCryoPixX, obCryoPixY, obCryoWhitePixX, obCryoWhitePixY
    global obTekPixX, obTekPixY
    global obEmptySlotR, obEmptySlotG, obEmptySlotB
    global obUploadStallMs, obUploadEarlyExit
    global obHoverAwayMs, obHoverGlideSpeed, obHoverSettleMs, obClickSettleMs, obPostRefreshMs, obPreUploadMs
    global obCryoHoverStartX, obCryoHoverStartY, obCryoHoverEndX, obCryoHoverEndY
    global arkwindow

    global obUploadEarlyExit := false
    global obInitFailed := false
    detectFilter := (detectAs != "") ? detectAs : filter

    if (!skipNav) {
        OBSetStatus("Waiting for OB inventory...")
        waitCount := 0
        loop {
            if (!obUploadRunning)
                return false
            if (NFSearchTol(&X, &Y, obConfirmPixX, obConfirmPixY, obConfirmPixX, obConfirmPixY, "0xFFFFFF", 15))
                break
            Sleep(16)
            waitCount++
            if (waitCount > 250) {
                OBSetStatus("Not at transmitter — re-arming")
                global obInitFailed := true
                return false
            }
        }

        OBSetStatus("Waiting for inventory to load...")
        OBTooltipOff()
        waitCount := 0
        _nfB7 := 0
        while (!NFPixelWait(obRightTabPixX, obRightTabPixY, obRightTabPixX+1, obRightTabPixY+1, "0x5D94A0", 25, &_nfB7)) {
            Sleep(16)
            waitCount++
            if (waitCount = 125)
                OBSetStatus("Waiting for OB tab (lag)...")
            if (waitCount > 625) {
                actualCol := PxGet(obRightTabPixX, obRightTabPixY)
                OBSetStatus("Timeout — right tab pixel: " Format("0x{:06X}", actualCol))
                Sleep(3000)
                return false
            }
        }

        ControlClick("x" obRightTabPixX " y" obRightTabPixY, arkwindow,,,,"NA")
        Sleep(100)
        OBSetStatus("Opening upload tab...")
        ControlClick("x" obUploadTabX " y" obUploadTabY, arkwindow,,,,"NA")

        waitCount := 0
        _nfB8 := 0
        while (!NFPixelWait(obUploadReadyPixX, obUploadReadyPixY, obUploadReadyPixX+1, obUploadReadyPixY+1, "0xBCF4FF", 20, &_nfB8)) {
            Sleep(16)
            waitCount++
            if (waitCount = 125)
                OBSetStatus("Waiting for upload tab (lag)...")
            if (waitCount > 625) {
                OBSetStatus("Timeout — upload tab not detected")
                Sleep(2500)
                return false
            }
        }
    } else {
        waitCount := 0
        while (!OBOverlayClear() && waitCount < 313) {
            waitCount++
            Sleep(16)
        }
        Sleep(300)
        waitCount := 0
        _nfB9 := 0
        while (!NFPixelWait(obUploadReadyPixX, obUploadReadyPixY, obUploadReadyPixX+1, obUploadReadyPixY+1, "0xBCF4FF", 20, &_nfB9)) {
            Sleep(16)
            waitCount++
            if (waitCount > obInvTimeout) {
                OBSetStatus("Timeout — upload tab not visible (lag?)")
                Sleep(2500)
                return false
            }
        }
    }

    if (!IsSet(obLog) || Type(obLog) != "Array")
        obLog := []
    obLog.Push("--- OBRunUpload(" filter ") " FormatTime(, "HH:mm:ss") " ---")
    obLog.Push("[1] Upload tab confirmed open")

    ; ── Wait for data to fully load ──────────────────────────────────────
    global obDataLoadedPixX, obDataLoadedPixY
    dataWaitStart := A_TickCount
    dataLoaded := false
    ToolTip(" Waiting for Ark data to load before uploading", 0, 0)
    OBSetStatus("Waiting for Ark data to load...")
    loop 500 {  
        if (!obUploadRunning) {
            ToolTip()
            return false
        }
        dc := PxGet(obDataLoadedPixX, obDataLoadedPixY)
        dr := (dc >> 16) & 0xFF
        dg := (dc >> 8)  & 0xFF
        db := dc         & 0xFF
        if (dr > 130 && dr < 190 && dg > 180 && dg < 230 && db > 195 && db < 245) {
            dataLoaded := true
            break
        }
        Sleep(16)
    }
    dataWaitMs := A_TickCount - dataWaitStart
    ToolTip()
    if (dataLoaded) {
        obLog.Push("[1b] ARK data loaded after " dataWaitMs "ms  pix(" obDataLoadedPixX "," obDataLoadedPixY ")=0x" Format("{:06X}", PxGet(obDataLoadedPixX, obDataLoadedPixY)))
    } else {
        obLog.Push("[1b] ARK data load TIMEOUT after " dataWaitMs "ms  pix(" obDataLoadedPixX "," obDataLoadedPixY ")=0x" Format("{:06X}", PxGet(obDataLoadedPixX, obDataLoadedPixY)))
        OBSetStatus("Data load timeout — aborting")
        Sleep(2000)
        return false
    }

    global obActiveFilter := filter

    MouseMove(mySearchBarX, mySearchBarY, 0)
    Sleep(50)
    Click
    Sleep(80)
    if (filter != "") {
        A_Clipboard := filter
        Send("^a")
        Sleep(20)
        Send("^v")
    } else {
        Send("^a")
        Sleep(20)
        Send("{Delete}")
    }
    Sleep(150)
    obLog.Push("[2] Filter applied: '" filter "' — search bar typed")

    MouseMove(myFirstSlotX - 30, myFirstSlotY, 0)
    Sleep(60)
    MouseMove(myFirstSlotX, myFirstSlotY, 0)
    Sleep(150)
    Click
    MouseMove(myFirstSlotX - 150, myFirstSlotY, 0)
    Sleep(150)
    obLog.Push("[3] Clicked slot 1 to defocus, moved mouse away, waiting for icon to settle")

    itemCheck := OBItemPresent(detectFilter)
    obLog.Push("[4] OBItemPresent check: " (itemCheck ? "FOUND" : "NOT FOUND"))
    obLog.Push("    weightPix (" obItemNamePixX "," obItemNamePixY "): 0x" Format("{:06X}", PxGet(obItemNamePixX, obItemNamePixY)) "  (need G>160 && B>220)")
    obLog.Push("    timerPix  (" obTimerPixX "," obTimerPixY "): 0x" Format("{:06X}", PxGet(obTimerPixX, obTimerPixY)) "  (need R>160 G>120 B<80)")
    obLog.Push("    daydPix   (" obDaydPixX "," obDaydPixY "): 0x" Format("{:06X}", PxGet(obDaydPixX, obDaydPixY)) "  (need R>160 G>120 B<80)")
    obLog.Push("    overlayClear: " (OBOverlayClear() ? "YES" : "NO") "  ovPix (" obOvPixX "," obOvPixY "): 0x" Format("{:06X}", PxGet(obOvPixX, obOvPixY)))

    if (!itemCheck) {
        if (checkEmpty) {
            obLog.Push("[5] checkEmpty=true — returning false silently")
            return false
        }
        diagCol   := PxGet(obCryoPixX,       obCryoPixY)
        diagColN  := PxGet(obCryoPixX,       obCryoPixY - 5)
        diagColS  := PxGet(obCryoPixX,       obCryoPixY + 5)
        diagColE  := PxGet(obCryoPixX + 5,   obCryoPixY)
        diagColW  := PxGet(obCryoPixX - 5,   obCryoPixY)
        diagSlot  := PxGet(myFirstSlotX,     myFirstSlotY)
        diagInv   := PxGet(obInvPixX,         obInvPixY)
        diagTab   := PxGet(obUploadReadyPixX, obUploadReadyPixY)
        diagRef   := PxGet(obRefreshPixX,     obRefreshPixY)

        debugLog := ""
        debugLog .= "AIO — OB Upload Debug Log`n"
        debugLog .= "==============================`n"
        debugLog .= "Timestamp:      " FormatTime(, "yyyy-MM-dd HH:mm:ss") "`n"
        debugLog .= "Filter:         " filter "`n"
        debugLog .= "Resolution:     " A_ScreenWidth "x" A_ScreenHeight "`n"
        debugLog .= "Width mult:     " widthmultiplier "`n"
        debugLog .= "Height mult:    " heightmultiplier "`n"
        debugLog .= "`n"
        debugLog .= "STEP LOG`n"
        for i, v in obLog
            debugLog .= "  " v "`n"
        debugLog .= "`n"
        debugLog .= "CRYO PIXEL READINGS`n"
        debugLog .= "Pixel (" obCryoPixX "," obCryoPixY "): " diagCol "`n"
        debugLog .= "North  (-5y):   " diagColN "`n"
        debugLog .= "South  (+5y):   " diagColS "`n"
        debugLog .= "East   (+5x):   " diagColE "`n"
        debugLog .= "West   (-5x):   " diagColW "`n"
        debugLog .= "`n"
        debugLog .= "OTHER PIXELS`n"
        debugLog .= "Slot 1 (" myFirstSlotX "," myFirstSlotY "):      " diagSlot "`n"
        debugLog .= "Inv open (" obInvPixX "," obInvPixY "):   " diagInv "`n"
        debugLog .= "Upload tab (" obUploadReadyPixX "," obUploadReadyPixY "): " diagTab " (expect ~0xBCF4FF)`n"
        debugLog .= "Refresh overlay (" obRefreshPixX "," obRefreshPixY "): " diagRef " (dark=loading, light=ready)`n"
        debugLog .= "`n"
        debugLog .= "THRESHOLD (cryo 0x5EC1F5)`n"
        debugLog .= "Expects: R 70-120  G 160-220  B>220`n"
        {
            r := (diagCol >> 16) & 0xFF
            g := (diagCol >> 8)  & 0xFF
            b := diagCol         & 0xFF
            debugLog .= "Got: R=" r "  G=" g "  B=" b "`n"
            debugLog .= "Pass? " (r > 70 && r < 120 && g > 160 && g < 220 && b > 220 ? "YES" : "NO") "`n"
        }
        debugLog .= "`n— End of log —"

        A_Clipboard := debugLog
        OBSetStatus("No cryo found — debug log copied to clipboard")
        Sleep(4000)
        OBClearFilter()
        return false
    }

    obLog.Push("[5] Items confirmed present — starting upload loop")
    OBSetStatus(startMsg)
    global obUploadRunning := true
    lastUploadTick := A_TickCount
    runStartTick := A_TickCount
    uploadCount := 0
    isTekFilter := (detectFilter = "ek et" || detectFilter = "ek che" || detectFilter = "ek gg" || detectFilter = "ek ot" || detectFilter = "ek leg" || detectFilter = "ek sw" || detectFilter = "ek fl")

    loop {
        if (!obUploadRunning)
            break

        if (obUploadPaused) {
            OBSetStatus("PAUSED — F6 to resume")
            while (obUploadPaused && obUploadRunning)
                Sleep(100)
            if (!obUploadRunning)
                break
            if (obActiveFilter != "") {
                A_Clipboard := obActiveFilter
                MouseMove(mySearchBarX, mySearchBarY, 0)
                Sleep(30)
                Click
                Sleep(60)
                Send("^a")
                Sleep(20)
                Send("^v")
                Sleep(150)
                MouseMove(myFirstSlotX, myFirstSlotY, 0)
                Sleep(80)
            }
            OBSetStatus("Resuming...")
        }
        if (!obUploadRunning)
            break

        ; ── Click slot and upload ────────────────────────────────────────────────
        if (obFirstUpload) {
            Sleep(300)
            global obFirstUpload := false
            obLog.Push("[first-T] extra 300ms settle before very first upload")
        }
        MouseMove(myFirstSlotX, myFirstSlotY, 0)
        Click
        Sleep(obClickSettleMs)
        Sleep(obPreUploadMs)
        Send("t")

        refreshWait := 0
        overlayAppeared := false
        while (refreshWait < 8) {
            if (!OBOverlayClear()) {
                overlayAppeared := true
                break
            }
            if (refreshWait = 4 && OBCheckInvFailed()) {
                obLog.Push("[!] Inv failed popup in T-wait — dismissed")
                Sleep(300)
                overlayAppeared := false
                break
            }
            Sleep(50)
            refreshWait++
        }

        if (!overlayAppeared) {
            Sleep(300)
            reCheck := OBItemPresent(detectFilter)
            obLog.Push("[T#" uploadCount+1 "] no overlay — re-check=" (reCheck?"FOUND":"EMPTY") " +" (A_TickCount - runStartTick) "ms")
            if (reCheck) {
                retryWait := 0
                while (!OBOverlayClear() && retryWait < 60) {
                    Sleep(50)
                    retryWait++
                }
                obLog.Push("[T#" uploadCount+1 "] retry — waited " retryWait*50 "ms for overlay clear")
                continue
            }
            Sleep(500)
            reCheck2 := OBItemPresent(detectFilter)
            if (reCheck2) {
                obLog.Push("[T#" uploadCount+1 "] no overlay — late re-check2=FOUND +" (A_TickCount - runStartTick) "ms — retrying")
                retryWait2 := 0
                while (!OBOverlayClear() && retryWait2 < 60) {
                    Sleep(50)
                    retryWait2++
                }
                continue
            }
            refSnap := PxGet(obRefreshPixX, obRefreshPixY)
            namSnap := PxGet(obItemNamePixX, obItemNamePixY)
            obLog.Push("[T#" uploadCount+1 "] no overlay after T — slot empty. ref="
                Format("0x{:06X}", refSnap) " timer=" Format("0x{:06X}", namSnap))
            break
        }
        obLog.Push("[T#" uploadCount+1 "] +" (A_TickCount - runStartTick) "ms  upload confirmed via overlay")

        if (overlayAppeared) {
            clearWait := 0
            overlayStuck := false
            while (!OBOverlayClear() && clearWait < 900) {
                if (clearWait = 60)
                    OBSetStatus("Waiting — inventory refreshing...")
                else if (clearWait = 140)
                    OBSetStatus("Still refreshing — possible lag...")
                else if (clearWait = 300)
                    OBSetStatus("Refreshing 15s — heavy lag or ARK issue...")
                else if (clearWait = 600)
                    OBSetStatus("Refreshing 30s — may be stuck...")
                if (Mod(clearWait, 20) = 0 && OBCheckInvFailed()) {
                    OBSetStatus("Inv failed popup — dismissed, retrying...")
                    obLog.Push("[!] Refreshing Inventory Failed popup detected and dismissed at clearWait=" clearWait)
                    Sleep(500)
                    MouseMove(myFirstSlotX, myFirstSlotY, 0)
                    Click
                    Sleep(obClickSettleMs)
                    Send("t")
                    clearWait := 0
                }
                if (Mod(clearWait, 20) = 0) {
                    _mc := PxGet(obMaxItemsPixX, obMaxItemsPixY)
                    _mr := (_mc >> 16) & 0xFF, _mg := (_mc >> 8) & 0xFF, _mb := _mc & 0xFF
                    if (_mr > NFT(200, 1) && _mg < NFT(40, -1) && _mb < NFT(40, -1)) {
                        obLog.Push("[!] Max items popup during refresh at clearWait=" clearWait)
                        OBSetStatus("Max Items Reached")
                        ToolTip(" Max Items Reached", 0, 0)
                        Sleep(500)
                        ControlClick("x" obMaxItemsPixX " y" obMaxItemsPixY, arkwindow,,,,"NA")
                        Sleep(300)
                        ToolTip()
                        global obUploadRunning := false
                        break
                    }
                }
                clearWait++
                Sleep(50)
            }
            if (clearWait >= 900) {
                obLog.Push("[!] Stuck in Refreshing Inventory after 45s — bailing")
                OBSetStatus("Stuck in refresh 45s — stopping")
                Sleep(2500)
                global obUploadRunning := false
                OBClearFilter()
                OBSetStatus(doneMsg " (refresh stuck)")
                Sleep(1200)
                return true
            }
        }

        maxCol := PxGet(obMaxItemsPixX, obMaxItemsPixY)
        maxR := (maxCol >> 16) & 0xFF
        maxG := (maxCol >> 8)  & 0xFF
        maxB :=  maxCol        & 0xFF
        if (maxR > NFT(200, 1) && maxG < NFT(40, -1) && maxB < NFT(40, -1)) {
            obLog.Push("[!] Max items reached after " uploadCount " items — pixel 0x" Format("{:06X}", maxCol))
            OBSetStatus("Max Items Reached")
            ToolTip(" Max Items Reached", 0, 0)
            Sleep(500)
            ControlClick("x" obMaxItemsPixX " y" obMaxItemsPixY, arkwindow,,,,"NA")
            Sleep(300)
            ToolTip()
            break
        }

        obFullCol := PxGet(obFullPixX, obFullPixY)
        if (((obFullCol >> 16) & 0xFF) > NFT(200, 1) && ((obFullCol >> 8) & 0xFF) < NFT(30, -1) && (obFullCol & 0xFF) < NFT(30, -1)) {
            obLog.Push("[!] OB full detected after " uploadCount " items")
            OBSetStatus("OB full — stopping")
            Sleep(2000)
            break
        }

        if (obUploadEarlyExit) {
            OBSetStatus("Q pressed — waiting for refresh to clear...")
            earlyWait := 0
            while (!OBOverlayClear() && earlyWait < 200) {
                earlyWait++
                Sleep(50)
            }
            global obUploadEarlyExit := false
            OBSetStatus("Stopped by Q — " uploadCount " items uploaded")
            Sleep(1500)
            break
        }

        Sleep(30)
        uploadCount++

        refreshClearWait := 0
        while (!OBOverlayClear() && refreshClearWait < 60) {
            if (!obUploadRunning)
                break
            refreshClearWait++
            Sleep(50)
        }
        Sleep(50)

        Sleep(obPostRefreshMs)

        ; ── Post-upload slot check ───────────────────────────────────────────
        if (!OBOverlayClear()) {
            Sleep(50)
            if (!OBOverlayClear())
                Sleep(100)
        }
        check1 := OBItemPresent(detectFilter)
        if (isTekFilter) {
            obLog.Push("[slot#" uploadCount "] tek check1=" (check1?"FOUND":"EMPTY") " +" (A_TickCount - runStartTick) "ms")
        } else {
            wc  := PxGet(obItemNamePixX, obItemNamePixY)
            tc  := PxGet(obTimerPixX,    obTimerPixY)
            dc  := PxGet(obDaydPixX,     obDaydPixY)
            wng := (wc >> 8)  & 0xFF
            wnb :=  wc        & 0xFF
            tnr := (tc >> 16) & 0xFF
            tng := (tc >> 8)  & 0xFF
            tnb :=  tc        & 0xFF
            dnr := (dc >> 16) & 0xFF
            dng := (dc >> 8)  & 0xFF
            dnb :=  dc        & 0xFF
            ovOk := OBOverlayClear()
            obLog.Push("[slot#" uploadCount "] filter=" filter " check1=" (check1?"FOUND":"EMPTY") " +" (A_TickCount - runStartTick) "ms")
            obLog.Push("  weight(" obItemNamePixX "," obItemNamePixY ")=0x" Format("{:06X}",wc) " G=" wng " B=" wnb " (need G>160 B>220) pass=" (wng>160&&wnb>220?"YES":"no"))
            obLog.Push("  timer (" obTimerPixX    "," obTimerPixY    ")=0x" Format("{:06X}",tc) " R=" tnr " G=" tng " B=" tnb " (need R>160 G>120 B<80) pass=" (tnr>160&&tng>120&&tnb<80?"YES":"no"))
            obLog.Push("  dayd (" obDaydPixX      "," obDaydPixY     ")=0x" Format("{:06X}",dc) " R=" dnr " G=" dng " B=" dnb " (need R>160 G>120 B<80) pass=" (dnr>160&&dng>120&&dnb<80?"YES":"no"))
            obLog.Push("  overlayClear=" (ovOk?"YES":"NO") " ovPix=0x" Format("{:06X}", PxGet(obOvPixX, obOvPixY)))
        }

        if (check1) {
            lastUploadTick := A_TickCount
        } else {
            if (isTekFilter) {
                obLog.Push("[slot#" uploadCount "] TEK pixel confirmed empty — done")
                obLog.Push("[6] Upload loop done after " uploadCount " items")
                break
            }
            wTmp := PxGet(obItemNamePixX, obItemNamePixY)
            tTmp := PxGet(obTimerPixX, obTimerPixY)
            wR := (wTmp >> 16) & 0xFF
            wG := (wTmp >> 8)  & 0xFF
            wB :=  wTmp        & 0xFF
            tR := (tTmp >> 16) & 0xFF
            tG := (tTmp >> 8)  & 0xFF
            tB :=  tTmp        & 0xFF
            looksGenuinelyEmpty := (wR < NFT(50, -1) && wG < NFT(100, -1) && wB < NFT(130, -1) && tR < NFT(50, -1) && tG < NFT(100, -1) && tB < NFT(130, -1))
            if (looksGenuinelyEmpty) {
                obLog.Push("[slot#" uploadCount "] EMPTY (dark blue confirmed) w=0x" Format("{:06X}",wTmp) " t=0x" Format("{:06X}",tTmp))
                obLog.Push("[6] Upload loop done after " uploadCount " items")
                break
            }
            obLog.Push("[slot#" uploadCount "] check1 EMPTY but not dark blue — polling for render...")
            renderWait := 0
            slotRendered := false
            while (renderWait < 30) {
                if (!obUploadRunning)
                    break
                Sleep(100)
                if (OBItemPresent(detectFilter)) {
                    slotRendered := true
                    obLog.Push("[slot#" uploadCount "] slot rendered after " (renderWait+1)*100 "ms")
                    break
                }
                renderWait++
            }
            if (slotRendered) {
                lastUploadTick := A_TickCount
            } else {
                check2 := OBItemPresent(detectFilter)
                Sleep(150)
                check3 := OBItemPresent(detectFilter)
                wc2 := PxGet(obItemNamePixX, obItemNamePixY)
                tc2 := PxGet(obTimerPixX,    obTimerPixY)
                obLog.Push("[slot#" uploadCount "] final recheck: c2=" (check2?"FOUND":"EMPTY") " c3=" (check3?"FOUND":"EMPTY") " w=0x" Format("{:06X}",wc2) " t=0x" Format("{:06X}",tc2))
                if (!check2 && !check3) {
                    wFinal := PxGet(obItemNamePixX, obItemNamePixY)
                    tFinal := PxGet(obTimerPixX,    obTimerPixY)
                    wfR := (wFinal >> 16) & 0xFF, wfG := (wFinal >> 8) & 0xFF, wfB := wFinal & 0xFF
                    tfR := (tFinal >> 16) & 0xFF, tfG := (tFinal >> 8) & 0xFF, tfB := tFinal & 0xFF
                    stillNotEmpty := !(wfR < NFT(50, -1) && wfG < NFT(100, -1) && wfB < NFT(130, -1) && tfR < NFT(50, -1) && tfG < NFT(100, -1) && tfB < NFT(130, -1))
                    if (stillNotEmpty) {
                        obLog.Push("[slot#" uploadCount "] STILL not dark blue after render wait — re-applying filter to force refresh")
                        OBClearFilter()
                        Sleep(200)
                        MouseMove(mySearchBarX, mySearchBarY, 0)
                        Sleep(50)
                        Click
                        Sleep(80)
                        A_Clipboard := filter
                        Send("^a")
                        Sleep(20)
                        Send("^v")
                        Sleep(300)
                        MouseMove(myFirstSlotX, myFirstSlotY, 0)
                        Sleep(100)
                        Click
                        MouseMove(myFirstSlotX - 150, myFirstSlotY, 0)
                        Sleep(300)
                        if (OBItemPresent(detectFilter)) {
                            obLog.Push("[slot#" uploadCount "] filter re-apply found items — continuing upload loop")
                            lastUploadTick := A_TickCount
                        } else {
                            obLog.Push("[6] Upload loop done after " uploadCount " items — confirmed empty after filter re-apply")
                            break
                        }
                    } else {
                        obLog.Push("[6] Upload loop done after " uploadCount " items — confirmed empty after render wait")
                        break
                    }
                }
                lastUploadTick := A_TickCount
            }
        }

        if (A_TickCount - lastUploadTick > obUploadStallMs) {
            obLog.Push("[6] Stall timeout after " uploadCount " items — OB may be full or item not moving")
            OBSetStatus("Stalled — OB may be full")
            Sleep(2000)
            break
        }
    }

    global obUploadRunning := false
    if (!skipClear)
        OBClearFilter()
    if (closeOnDone) {
        Send("{Escape}")
        Sleep(300)
    }
    finalLog := "AIO OB Upload Log`n==============================`n"
    finalLog .= "Result:   " doneMsg "`n"
    finalLog .= "Filter:   " filter "`n"
    finalLog .= "Uploaded: " uploadCount "`n"
    finalLog .= "Time:     " FormatTime(, "yyyy-MM-dd HH:mm:ss") "`n"
    finalLog .= "Res:      " A_ScreenWidth "x" A_ScreenHeight "`n`nSTEP LOG`n"
    for i, v in obLog
        finalLog .= "  " v "`n"
    finalLog .= "`nFINAL PIXELS`n"
    finalLog .= "WeightTxt (" obItemNamePixX "," obItemNamePixY "): " Format("0x{:06X}", PxGet(obItemNamePixX, obItemNamePixY)) "`n"
    finalLog .= "Refresh  (" obRefreshPixX "," obRefreshPixY "):  " Format("0x{:06X}", PxGet(obRefreshPixX, obRefreshPixY)) "`n"
    finalLog .= "InvOpen  (" obInvPixX "," obInvPixY "):  " Format("0x{:06X}", PxGet(obInvPixX, obInvPixY)) "`n"
    finalLog .= "UpldTab  (" obUploadReadyPixX "," obUploadReadyPixY "): " Format("0x{:06X}", PxGet(obUploadReadyPixX, obUploadReadyPixY)) "`n"
    finalLog .= "OBFull   (" obFullPixX "," obFullPixY "):  " Format("0x{:06X}", PxGet(obFullPixX, obFullPixY)) "`n"
    finalLog .= "`n--- End of log ---"
    A_Clipboard := finalLog

    OBSetStatus(doneMsg)
    Sleep(1200)
    return true
}

; ── OBOverlayClear() ─────────────────────────────────────────────────────
; ── Tooltip toggle helpers ────────────────────────────────────────────────────
OBTooltipOff() {
    global obTooltipPixX, obTooltipPixY, obTooltipsWereOn, arkwindow, obLog
    if (!IsSet(obLog) || Type(obLog) != "Array")
        obLog := []
    col := PxGet(obTooltipPixX, obTooltipPixY)
    r := (col >> 16) & 0xFF
    g := (col >> 8)  & 0xFF
    b :=  col        & 0xFF
    obLog.Push("[TOOLTIP] pixel (" obTooltipPixX "," obTooltipPixY "): 0x" Format("{:06X}", col) " R=" r " G=" g " B=" b)
    if (g > NFT(200, 1) && b > NFT(240, 1)) {
        global obTooltipsWereOn := true
        obLog.Push("[TOOLTIP] was ON — clicking off")
        ControlClick("x" obTooltipPixX " y" obTooltipPixY, arkwindow,,,,"NA Pos")
        Sleep(120)
        col2 := PxGet(obTooltipPixX, obTooltipPixY)
        g2 := (col2 >> 8) & 0xFF
        b2 :=  col2       & 0xFF
        obLog.Push("[TOOLTIP] after click: 0x" Format("{:06X}", col2) " — " ((g2 > NFT(200, 1) && b2 > NFT(240, 1)) ? "STILL ON (click failed!)" : "OFF ok"))
    } else {
        global obTooltipsWereOn := false
        obLog.Push("[TOOLTIP] was already OFF — no action")
    }
}

OBTooltipRestore() {
    global obTooltipPixX, obTooltipPixY, obTooltipsWereOn, arkwindow, obLog
    if (obTooltipsWereOn) {
        obLog.Push("[TOOLTIP] restoring ON")
        ControlClick("x" obTooltipPixX " y" obTooltipPixY, arkwindow,,,,"NA Pos")
        Sleep(120)
        global obTooltipsWereOn := false
    }
}

OBCheckInvFailed() {
    global obInvFailBtnPixX, obInvFailBtnPixY, obInvFailBtnX, obInvFailBtnY, arkwindow
    col := PxGet(obInvFailBtnPixX, obInvFailBtnPixY)
    r := (col >> 16) & 0xFF
    g := (col >> 8)  & 0xFF
    b :=  col        & 0xFF
    if (NFColorBright(col, 220)) {
        ControlClick("x" obInvFailBtnX " y" obInvFailBtnY, arkwindow,,,,,"NA")
        Sleep(300)
        return true
    }
    return false
}

OBOverlayClear() {
    global obOvPixX, obOvPixY
    col := PxGet(obOvPixX, obOvPixY)
    r := (col >> 16) & 0xFF
    return (r > NFT(180, 1))
}

OBItemPresent(filter) {
    global obCryoPixX, obCryoPixY, obCryoUnelPixX, obCryoUnelPixY, obCryoWhitePixX, obCryoWhitePixY
    global obTimerPixX, obTimerPixY, obDaydPixX, obDaydPixY
    global obTekPixX, obTekPixY, obTekPix2X, obTekPix2Y, obTekPix3X, obTekPix3Y
    global obEmptySlotR, obEmptySlotG, obEmptySlotB
    global myFirstSlotX, myFirstSlotY

    if (filter = "cryop") {
        refreshWaitIP := 0
        while (!OBOverlayClear() && refreshWaitIP < 60) {
            if (!obUploadRunning)
                return false
            Sleep(50)
            refreshWaitIP++
        }
        nc := PxGet(obItemNamePixX, obItemNamePixY)
        nr := (nc >> 16) & 0xFF
        ng := (nc >> 8)  & 0xFF
        nb := nc         & 0xFF
        if (ng > NFT(160, 1) && nb > NFT(220, 1))
            return true
        tc := PxGet(obTimerPixX, obTimerPixY)
        tr := (tc >> 16) & 0xFF
        tg := (tc >> 8)  & 0xFF
        tb := tc         & 0xFF
        if (tr > NFT(160, 1) && tg > NFT(120, 1) && tb < NFT(80, -1))
            return true
        Sleep(30)
        nc2 := PxGet(obItemNamePixX, obItemNamePixY)
        nr2 := (nc2 >> 16) & 0xFF
        ng2 := (nc2 >> 8)  & 0xFF
        nb2 := nc2         & 0xFF
        if (ng2 > NFT(160, 1) && nb2 > NFT(220, 1))
            return true
        tc2 := PxGet(obTimerPixX, obTimerPixY)
        tr2 := (tc2 >> 16) & 0xFF
        tg2 := (tc2 >> 8)  & 0xFF
        tb2 := tc2         & 0xFF
        if (tr2 > NFT(160, 1) && tg2 > NFT(120, 1) && tb2 < NFT(80, -1))
            return true
        dc2 := PxGet(obDaydPixX, obDaydPixY)
        dr2 := (dc2 >> 16) & 0xFF
        dg2 := (dc2 >> 8)  & 0xFF
        db2 := dc2         & 0xFF
        if (dr2 > NFT(160, 1) && dg2 > NFT(120, 1) && db2 < NFT(80, -1))
            return true
        return false
    } else if (filter = "ek et" || filter = "ek che" || filter = "ek gg" || filter = "ek ot" || filter = "ek leg" || filter = "ek sw" || filter = "ek fl") {
        global obLog
        refreshWaitTek := 0
        while (!OBOverlayClear() && refreshWaitTek < 60) {
            if (!obUploadRunning)
                return false
            Sleep(50)
            refreshWaitTek++
        }
        tekPixX := Round(251 * widthmultiplier)
        tekPixY := Round(331 * heightmultiplier)
        tc := PxGet(tekPixX, tekPixY)
        tr := (tc >> 16) & 0xFF
        tg := (tc >> 8)  & 0xFF
        tb :=  tc        & 0xFF
        isTek := (tg > NFT(210, 1) && tb > NFT(210, 1) && tg > tr)
        obLog.Push("[TEK-CHECK] tekPix(=" tekPixX "," tekPixY ")=0x" Format("{:06X}", tc) " R=" tr " G=" tg " B=" tb " → " (isTek ? "FOUND" : "empty"))
        return isTek

    } else {
        global obAllPixX, obAllPixY
        col := PxGet(obAllPixX, obAllPixY)
        r := (col >> 16) & 0xFF
        g := (col >> 8)  & 0xFF
        b := col         & 0xFF
        if (r > NFT(90, 1) && r < NFT(140, -1) && g > NFT(110, 1) && g < NFT(165, -1) && b > NFT(110, 1) && b < NFT(165, -1) && Abs(g - b) < NFT(15, -1))
            return true
        return false
    }
}

OBClearFilter() {
    global mySearchBarX, mySearchBarY, arkwindow
    ControlClick("x" mySearchBarX " y" mySearchBarY, arkwindow)
    Sleep(40)
    Send("^a")
    Sleep(20)
    Send("{Delete}")
    Sleep(100)
}

OBSlotIsEmpty(color, emptyRef) {
    r := (color >> 16) & 0xFF
    g := (color >> 8)  & 0xFF
    b := color         & 0xFF
    return (r < NFT(50, -1) && g < NFT(50, -1) && b < NFT(50, -1))
}

OBGetEmptySlotColor() {
    return 0x0A4A6B
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

OBDownSetStatus(msg) {
    global obDownText
    try obDownText.Value := msg
    ToolTip(" Auto Empty OB — " msg "`nF1 = Show UI  |  Q = Stop", 0, 20)
}

OBDownStopAll(hideGui := true) {
    global obDownloadArmed := false
    global obDownloadRunning := false
    global obDownloadPaused := false
    try obDownText.Value := ""
    ToolTip()
    if (hideGui) {
        MainGui.Hide()
        global guiVisible := false
    }
}

OBDownloadCycle() {
    global obDownloadArmed, obDownloadRunning, obDownloadPaused, arkwindow, guiVisible
    global pcF10Step, pcMode, pcRunning

    if (pcMode > 0 || pcF10Step > 0) {
        global pcF10Step := 0
        global pcMode    := 0
        global pcRunning := false
        PcRegisterSpeedHotkeys(false)
        PcUpdateUI()
        PcLog("OBDownloadCycle: popcorn disabled to avoid F conflict")
        ToolTip(" Switched to OB Download — popcorn off", 0, 0)
        SetTimer(() => ToolTip(), -1500)
    }

    if (obDownloadRunning) {
        global obDownloadRunning := false
        global obDownloadPaused  := false
        ToolTip(" Downloading stopped", 10, 20)
        SetTimer(() => ToolTip(), -2000)
        return
    }

    if (obDownloadArmed) {
        OBDownStopAll(false)
        return
    }

    if WinExist(arkwindow)
        WinActivate(arkwindow)

    global obDownloadRunning := true

    MainGui.Hide()
    global guiVisible := false
    Send("{F}")
    OBRunDownload()
}

OBDownFPressed() {
    global obDownloadArmed
    if (!obDownloadArmed)
        return
    global obDownloadArmed := false
    MainGui.Hide()
    global guiVisible := false
    OBRunDownload()
}

OBRunDownload() {
    global obDownloadRunning, obInvPixX, obInvPixY, obInvTimeout, obLog
    global obDownloadPaused
    global obRightTabPixX, obRightTabPixY
    global obConfirmPixX, obConfirmPixY
    global obUploadTabX, obUploadTabY
    global obUploadReadyPixX, obUploadReadyPixY
    global obDownSlotX, obDownSlotY, obDownItemDelayMs, obDownItemDelayMax
    global obBarPixX, obBarPixY, obDownBarSettleMs
    global obRefreshPixX, obRefreshPixY
    global arkwindow

    navStartTime := A_TickCount

    OBDownSetStatus("Waiting for OB inventory...")
    waitCount := 0
    loop {
        if (!obDownloadRunning) {
            return
        }
        if (NFSearchTol(&X, &Y, obConfirmPixX, obConfirmPixY, obConfirmPixX, obConfirmPixY, "0xFFFFFF", 15))
            break
        Sleep(16)
        waitCount++
        if (waitCount > 250) {
            global obDownloadRunning := false
            OBDownSetStatus("Not at transmitter — F7 to retry")
            ToolTip(" OB Download: Not at transmitter`nF7 to retry  |  F1 = UI", 0, 0)
            return
        }
    }

    OBDownSetStatus("Waiting for inventory")
    OBTooltipOff()
    waitCount := 0
    _nfB10 := 0
    while (!NFPixelWait(obRightTabPixX, obRightTabPixY, obRightTabPixX+1, obRightTabPixY+1, "0x5D94A0", 25, &_nfB10)) {
        Sleep(16)
        waitCount++
        if (waitCount = 125)
            OBDownSetStatus("Waiting for OB tab (lag)...")
        if (waitCount > 625) {
            actualCol := PxGet(obRightTabPixX, obRightTabPixY)
            OBDownSetStatus("Timeout — right tab pixel: " Format("0x{:06X}", actualCol))
            Sleep(1500)
            OBDownStopAll()
            return
        }
    }
    ControlClick("x" obRightTabPixX " y" obRightTabPixY, arkwindow,,,,"NA")
    Sleep(100)

    ControlClick("x" obUploadTabX " y" obUploadTabY, arkwindow,,,,"NA")

    waitCount := 0
    _nfB11 := 0
    while (!NFPixelWait(obUploadReadyPixX, obUploadReadyPixY, obUploadReadyPixX+1, obUploadReadyPixY+1, "0xBCF4FF", 20, &_nfB11)) {
        if (!obDownloadRunning)
            return
        Sleep(16)
        waitCount++
        if (waitCount > obInvTimeout) {
            OBDownSetStatus("Timeout — upload tab not detected")
            Sleep(1500)
            OBDownStopAll()
            return
        }
    }

    OBDownSetStatus("Waiting for Ark data to load...")
    global obDataLoadedPixX, obDataLoadedPixY
    dataWaitStart := A_TickCount
    dataLoaded := false
    loop 500 {
        if (!obDownloadRunning)
            return
        dc := PxGet(obDataLoadedPixX, obDataLoadedPixY)
        dr := (dc >> 16) & 0xFF
        dg := (dc >> 8)  & 0xFF
        db := dc         & 0xFF
        if (dr > 130 && dr < 190 && dg > 180 && dg < 230 && db > 195 && db < 245) {
            dataLoaded := true
            break
        }
        Sleep(16)
    }
    if (!dataLoaded) {
        obLog := []
        obLog.Push("=== DOWNLOAD run " FormatTime(, "yyyy-MM-dd HH:mm:ss") " ===")
        obLog.Push("[DL] ARK data load TIMEOUT after " (A_TickCount - dataWaitStart) "ms")
        OBDownSetStatus("Data load timeout")
        Sleep(2000)
        OBDownStopAll()
        PerfLogPush("ob_download", navStartTime, "data_timeout")
        return
    }

    OBDownSetStatus("Downloading OB")
    itemsDownloaded := 0
    obLog := []
    obLog.Push("=== DOWNLOAD run " FormatTime(, "yyyy-MM-dd HH:mm:ss") " ===")
    obLog.Push("[DL] ARK data loaded after " (A_TickCount - dataWaitStart) "ms")

    OBDownSetStatus("Loading items...")
    firstFound := false
    Loop 20 {
        if (!obDownloadRunning)
            break
        barCol := PxGet(obBarPixX, obBarPixY)
        br := (barCol >> 16) & 0xFF
        bg := (barCol >> 8)  & 0xFF
        bb := barCol         & 0xFF
        if (br < NFT(30, -1) && bg > NFT(150, 1) && bb > NFT(130, 1)) {
            firstFound := true
            break
        }
        Sleep(300)
    }
    if (!firstFound) {
        obLog.Push("[DL] no items loaded after 6s — ARK data load error")
        OBDownSetStatus("Data load error")
        ToolTip(" Data load error — ARK issue`n Try opening another transmitter", 0, 0)
        Sleep(500)
        Send("{Escape}")
        Sleep(3000)
        ToolTip()
        OBDownStopAll()
        PerfLogPush("ob_download", navStartTime, "data_error")
        return
    }

    OBDownSetStatus("Reading item count...")
    MouseMove(Round(960 * widthmultiplier), Round(200 * heightmultiplier), 0)
    Sleep(500)

    barCount1 := OBBarCountItems()
    Sleep(200)
    barCount2 := OBBarCountItems()
    obLog.Push("[DL] bar count: " barCount1 " → " barCount2)

    if (barCount1 = barCount2 && barCount1 >= 0) {
        initCount := barCount1
        obLog.Push("[DL] bar count confirmed: " initCount)
    } else {
        obLog.Push("[DL] bar count mismatch — falling back to OCR")
        initCount := -1
        lastRead := -1
        countAttempt := 0
        while (countAttempt < 5) {
            thisRead := OBOcrDownloadCount()
            obLog.Push("[DL] OCR attempt " (countAttempt+1) ": " thisRead)
            if (thisRead >= 0 && thisRead = lastRead) {
                initCount := thisRead
                obLog.Push("[DL] OCR confirmed: " initCount)
                break
            }
            lastRead := thisRead
            countAttempt++
            Sleep(300)
        }
        if (initCount = -1 && lastRead >= 0) {
            initCount := lastRead
            obLog.Push("[DL] OCR no match — using last valid: " initCount)
        }
    }

    if (initCount = 0) {
        OBDownSetStatus("OB empty (0/50) — nothing to download")
        obLog.Push("[DL] 0/50 — aborting")
        Sleep(2000)
        OBDownStopAll()
        return
    }
    if (initCount = -1) {
        obLog.Push("[DL] all counts failed — proceeding with max 50")
        initCount := 50
    }

    dlStartTime := A_TickCount
    navMs := dlStartTime - navStartTime
    obLog.Push("[NAV] overhead " navMs "ms (" Round(navMs/1000,1) "s)")
    obLog.Push("[DL] target: " initCount " items")

    remaining := (initCount > 0) ? initCount : 50

    loop {
        if (!obDownloadRunning) {
            OBDownSetStatus("Downloading stopped")
            break
        }
        if (remaining <= 0) {
            obLog.Push("[DL] all " initCount " items downloaded")
            OBDownSetStatus("All items downloaded (" itemsDownloaded ")")
            break
        }

        itemStartTime := A_TickCount

        tealWait := 0
        loop {
            if (!obDownloadRunning) {
                OBDownSetStatus("Downloading stopped")
                break 2
            }
            barCol := PxGet(obBarPixX, obBarPixY)
            bg := (barCol >> 8) & 0xFF
            bb :=  barCol       & 0xFF
            if (bg > NFT(150, 1) && bb > NFT(130, 1))
                break
            if (tealWait = 0)
                OBDownSetStatus("Waiting for slot to load... (" remaining " left)")
            if (tealWait >= 500) {
                obLog.Push("[DL] no teal after 8s — done (" itemsDownloaded " items)")
                OBDownSetStatus("All items downloaded (" itemsDownloaded ")")
                remaining := 0
                break 2
            }
            tealWait++
            Sleep(16)
        }

        MouseMove(obDownSlotX, obDownSlotY, 0)
        Sleep(20)
        Click
        Sleep(30)
        ControlSend("t", , arkwindow)

        overlaySeen := false
        dlWait := 0
        loop 63 {
            if (!obDownloadRunning)
                break
            if (!OBOverlayClear()) {
                overlaySeen := true
                break
            }
            if (dlWait = 19 && OBCheckInvFailed()) {
                obLog.Push("[DL#" itemsDownloaded+1 "] Inv failed popup in T-wait — dismissed")
                Sleep(300)
                break
            }
            dlWait++
            Sleep(16)
        }

        if (!overlaySeen) {
            itemMs := A_TickCount - itemStartTime
            obLog.Push("[DL#" itemsDownloaded+1 "] no overlay after T — retrying (" itemMs "ms)")
            OBDownSetStatus("No response — retrying... (" remaining " left)")
            Sleep(300)
            continue
        }

        itemsDownloaded++
        remaining--
        OBDownSetStatus("Downloading " itemsDownloaded "/" initCount " (" remaining " left)")

        clearWait := 0
        while (!OBOverlayClear() && obDownloadRunning) {
            if (Mod(clearWait, 63) = 0 && OBCheckInvFailed()) {
                OBDownSetStatus("Inv failed popup — dismissed, retrying...")
                obLog.Push("[DL#" itemsDownloaded "] Refreshing Inventory Failed popup — dismissed")
                Sleep(500)
                MouseMove(obDownSlotX, obDownSlotY, 0)
                Click
                Sleep(30)
                ControlSend("t", , arkwindow)
                clearWait := 0
            }
            clearWait++
            if (clearWait = 500)
                obLog.Push("[DL#" itemsDownloaded "] overlay taking 8s — server lag")
            Sleep(16)
        }
        if (!obDownloadRunning) {
            OBDownSetStatus("Downloading stopped")
            break
        }

        itemMs := A_TickCount - itemStartTime
        obLog.Push("[DL#" itemsDownloaded "] " itemMs "ms (" remaining " left)")
    }

    Sleep(500)

    obClosePixX := Round(1812 * widthmultiplier)
    obClosePixY := Round(216  * heightmultiplier)
    closeWait := 0
    loop {
        if (NFSearchTol(&X, &Y, obClosePixX, obClosePixY, obClosePixX+1, obClosePixY+1, "0xFFFFFF", 10)) {
            ControlSend("f", , arkwindow)
            break
        }
        closeWait++
        if (closeWait > 250) {
            ControlSend("f", , arkwindow)
            break
        }
        Sleep(20)
    }

    global obDownloadRunning := false
    dlElapsed := Round((A_TickCount - dlStartTime) / 1000, 1)
    dlPerMin  := (dlElapsed > 0) ? Round(itemsDownloaded / (dlElapsed / 60), 1) : 0
    navMs2    := dlStartTime - navStartTime
    totalS    := Round((A_TickCount - navStartTime) / 1000, 1)
    obLog.Push("=== DONE: " itemsDownloaded " items in " dlElapsed "s (" dlPerMin "/min) ===")
    obLog.Push("[NAV] overhead was " Round(navMs2/1000,1) "s | total from F7: " totalS "s")

    OBTooltipRestore()
    OBDownStopAll()
    PerfLogPush("ob_download", navStartTime, "done")
}

OBOcrToggleResize(idx) {
    global obOcrResizing, obOcrTarget
    global acOcrResizing, imprintResizing
    if (acOcrResizing) {
        ToolTip(" Exit Craft OCR resize first", 0, 0)
        SetTimer(() => ToolTip(), -1500)
        return
    }
    if (IsSet(imprintResizing) && imprintResizing) {
        ToolTip(" Exit Imprint resize first", 0, 0)
        SetTimer(() => ToolTip(), -1500)
        return
    }
    if (obOcrResizing) {
        OBOcrExitResize()
        return
    }
    obOcrResizing := true
    obOcrTarget := idx
    label := (idx = 3) ? "Dn Count" : "Timer"
    ToolTip(" OB OCR [" label "]: WASD=move  Arrows=size  Enter=done", 0, 0)
    OBOcrShowOverlay()
    try Hotkey("$Up",    OBOcrSizeUp,    "On")
    try Hotkey("$Down",  OBOcrSizeDown,  "On")
    try Hotkey("$Left",  OBOcrSizeLeft,  "On")
    try Hotkey("$Right", OBOcrSizeRight, "On")
    try Hotkey("$w",     OBOcrMoveUp,    "On")
    try Hotkey("$s",     OBOcrMoveDown,  "On")
    try Hotkey("$a",     OBOcrMoveLeft,  "On")
    try Hotkey("$d",     OBOcrMoveRight, "On")
    try Hotkey("$Enter", OBOcrResizeDone,"On")
}

OBOcrExitResize() {
    global obOcrResizing, obOcrTarget
    if (!obOcrResizing)
        return
    obOcrResizing := false
    obOcrTarget := 0
    try Hotkey("$Up",    "Off")
    try Hotkey("$Down",  "Off")
    try Hotkey("$Left",  "Off")
    try Hotkey("$Right", "Off")
    try Hotkey("$w",     "Off")
    try Hotkey("$s",     "Off")
    try Hotkey("$a",     "Off")
    try Hotkey("$d",     "Off")
    try Hotkey("$Enter", "Off")
    OBOcrHideOverlay()
    OBOcrUpdateSizeTxt()
    OBOcrSaveConfig()
    ToolTip()
}

OBOcrResizeDone(*) {
    OBOcrExitResize()
}

OBOcrSizeUp(*) {
    global obOcrH, obOcrTarget
    i := obOcrTarget
    if (i < 1)
        return
    obOcrH[i] := Max(20, obOcrH[i] + 10)
    OBOcrShowOverlay()
    OBOcrUpdateSizeTxt()
}
OBOcrSizeDown(*) {
    global obOcrH, obOcrTarget
    i := obOcrTarget
    if (i < 1)
        return
    obOcrH[i] := Max(20, obOcrH[i] - 10)
    OBOcrShowOverlay()
    OBOcrUpdateSizeTxt()
}
OBOcrSizeRight(*) {
    global obOcrW, obOcrTarget
    i := obOcrTarget
    if (i < 1)
        return
    obOcrW[i] := Max(40, obOcrW[i] + 20)
    OBOcrShowOverlay()
    OBOcrUpdateSizeTxt()
}
OBOcrSizeLeft(*) {
    global obOcrW, obOcrTarget
    i := obOcrTarget
    if (i < 1)
        return
    obOcrW[i] := Max(40, obOcrW[i] - 20)
    OBOcrShowOverlay()
    OBOcrUpdateSizeTxt()
}
OBOcrMoveUp(*) {
    global obOcrY, obOcrTarget
    i := obOcrTarget
    if (i < 1)
        return
    obOcrY[i] := Max(0, obOcrY[i] - 10)
    OBOcrShowOverlay()
}
OBOcrMoveDown(*) {
    global obOcrY, obOcrH, obOcrTarget
    i := obOcrTarget
    if (i < 1)
        return
    obOcrY[i] := Min(A_ScreenHeight - obOcrH[i], obOcrY[i] + 10)
    OBOcrShowOverlay()
}
OBOcrMoveLeft(*) {
    global obOcrX, obOcrTarget
    i := obOcrTarget
    if (i < 1)
        return
    obOcrX[i] := Max(0, obOcrX[i] - 10)
    OBOcrShowOverlay()
}
OBOcrMoveRight(*) {
    global obOcrX, obOcrW, obOcrTarget
    i := obOcrTarget
    if (i < 1)
        return
    obOcrX[i] := Min(A_ScreenWidth - obOcrW[i], obOcrX[i] + 10)
    OBOcrShowOverlay()
}

OBOcrUpdateSizeTxt() {
    global obOcrTarget, obOcrX, obOcrY, obOcrW, obOcrH
}

; ── OB OCR — Overlay ────────────────────────────────────────────────────────

OBOcrShowOverlay() {
    global obOcrOverlays, obOcrTarget, obOcrX, obOcrY, obOcrW, obOcrH, obOcrResizing
    OBOcrHideOverlay()
    if (!obOcrResizing || obOcrTarget < 1)
        return
    i := obOcrTarget
    b := 2
    clr := (i = 5) ? "FF4444" : "00FFFF"
    x := obOcrX[i], y := obOcrY[i], w := obOcrW[i], h := obOcrH[i]
    strips := [
        [x-b, y-b, w+b*2, b],
        [x-b, y+h, w+b*2, b],
        [x-b, y,   b,     h],
        [x+w, y,   b,     h]
    ]
    obOcrOverlays := []
    for s in strips {
        g := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x20")
        g.BackColor := clr
        WinSetTransparent(200, g)
        g.Show("x" s[1] " y" s[2] " w" s[3] " h" s[4] " NoActivate")
        obOcrOverlays.Push(g)
    }
}

OBOcrHideOverlay() {
    global obOcrOverlays
    if IsObject(obOcrOverlays) {
        for g in obOcrOverlays
            try g.Destroy()
        obOcrOverlays := ""
    }
}

; ── OB OCR — INI Persistence (Dn Count + Timer) ─────────────────────────────

OBOcrSaveConfig() {
    global obOcrX, obOcrY, obOcrW, obOcrH
    configFile := A_ScriptDir "\AIO_config.ini"
    IniWrite(obOcrX[3], configFile, "OBDnCount", "X")
    IniWrite(obOcrY[3], configFile, "OBDnCount", "Y")
    IniWrite(obOcrW[3], configFile, "OBDnCount", "W")
    IniWrite(obOcrH[3], configFile, "OBDnCount", "H")
    IniWrite(obOcrX[5], configFile, "OBTimer", "X")
    IniWrite(obOcrY[5], configFile, "OBTimer", "Y")
    IniWrite(obOcrW[5], configFile, "OBTimer", "W")
    IniWrite(obOcrH[5], configFile, "OBTimer", "H")
}

OBOcrLoadConfig() {
    global obOcrX, obOcrY, obOcrW, obOcrH
    configFile := A_ScriptDir "\AIO_config.ini"
    if !FileExist(configFile)
        return
    try {
        sx := IniRead(configFile, "OBDnCount", "X", "")
        sy := IniRead(configFile, "OBDnCount", "Y", "")
        sw := IniRead(configFile, "OBDnCount", "W", "")
        sh := IniRead(configFile, "OBDnCount", "H", "")
        if (sx != "")
            obOcrX[3] := Integer(sx)
        if (sy != "")
            obOcrY[3] := Integer(sy)
        if (sw != "" && Integer(sw) >= 40)
            obOcrW[3] := Integer(sw)
        if (sh != "" && Integer(sh) >= 20)
            obOcrH[3] := Integer(sh)
    }
    try {
        tx := IniRead(configFile, "OBTimer", "X", "")
        ty := IniRead(configFile, "OBTimer", "Y", "")
        tw := IniRead(configFile, "OBTimer", "W", "")
        th := IniRead(configFile, "OBTimer", "H", "")
        if (tx != "")
            obOcrX[5] := Integer(tx)
        if (ty != "")
            obOcrY[5] := Integer(ty)
        if (tw != "" && Integer(tw) >= 40)
            obOcrW[5] := Integer(tw)
        if (th != "" && Integer(th) >= 20)
            obOcrH[5] := Integer(th)
    }
    OBOcrUpdateSizeTxt()
}

; OB OCR — Detection Helpers
; ══════════════════════════════════════════════════════════════════════════════

OBOcrSlotHasItems() {
    global obOcrX, obOcrY, obOcrW, obOcrH, obLog
    try {
        txt := OCR.FromRect(obOcrX[1], obOcrY[1], obOcrW[1], obOcrH[1], {scale: 3}).Text
        hasNum := RegExMatch(txt, "\d")
        obLog.Push("[OCR-UpSlot] '" SubStr(txt, 1, 60) "' hasNum=" (hasNum ? "YES" : "NO"))
        return (hasNum > 0)
    } catch as e {
        obLog.Push("[OCR-UpSlot] FAIL: " e.Message)
        return false
    }
}

OBOcrUploadBusy() {
    global obOcrX, obOcrY, obOcrW, obOcrH, obLog
    try {
        txt := OCR.FromRect(obOcrX[2], obOcrY[2], obOcrW[2], obOcrH[2], {scale: 2}).Text
        lower := StrLower(txt)
        busy := (InStr(lower, "upload") || InStr(lower, "refresh"))
        return busy
    } catch as e {
        obLog.Push("[OCR-UpPopup] FAIL: " e.Message)
        return false
    }
}

OBBarCountItems() {
    global obBarPixY, widthmultiplier
    baseStart := 1025
    basePerSlot := 10.04
    scanY := obBarPixY
    loop 51 {
        slot := 51 - A_Index  ; 50, 49, 48... 0
        checkX := Round((baseStart + slot * basePerSlot) * widthmultiplier)
        try {
            col := PxGet(checkX, scanY)
            g := (col >> 8) & 0xFF
            b := col & 0xFF
            r := (col >> 16) & 0xFF
            if (r < 30 && g > 100 && b > 80) {
                return slot
            }
        }
    }
    return 0
}

OBOcrDownloadCount() {
    global obOcrX, obOcrY, obOcrW, obOcrH, obLog
    try {
        txt := OCR.FromRect(obOcrX[3], obOcrY[3], obOcrW[3], obOcrH[3], {scale: 3}).Text
        obLog.Push("[OCR-DnCount] '" SubStr(txt, 1, 60) "'")
        if RegExMatch(txt, "(\d+)\s*/\s*\d+", &m)
            return Integer(m[1])
        return -1
    } catch as e {
        obLog.Push("[OCR-DnCount] FAIL: " e.Message)
        return -1
    }
}

OBOcrDownloadBusy() {
    global obOcrX, obOcrY, obOcrW, obOcrH, obLog
    try {
        txt := OCR.FromRect(obOcrX[4], obOcrY[4], obOcrW[4], obOcrH[4], {scale: 2}).Text
        lower := StrLower(txt)
        busy := InStr(lower, "download")
        return busy
    } catch as e {
        obLog.Push("[OCR-DnPopup] FAIL: " e.Message)
        return false
    }
}

; ── OB OCR — Upload Wait Helper ──────────────────────────────────────────────
OBOcrWaitPopupClear(maxMs := 45000) {
    global obUploadRunning, obLog
    start := A_TickCount
    pollCount := 0
    loop {
        if (!obUploadRunning)
            return false
        if (!OBOcrUploadBusy()) {
            if (pollCount > 0)
                obLog.Push("[OCR-UpPopup] cleared after " (A_TickCount - start) "ms (" pollCount " polls)")
            return true
        }
        pollCount++
        if (A_TickCount - start > maxMs) {
            obLog.Push("[OCR-UpPopup] TIMEOUT after " maxMs "ms — still busy")
            return false
        }
        Sleep(100)
    }
}

; ── OB OCR — Download Wait Helper ────────────────────────────────────────────
OBOcrWaitDnPopupClear(maxMs := 30000) {
    global obDownloadRunning, obLog
    start := A_TickCount
    pollCount := 0
    loop {
        if (!obDownloadRunning)
            return false
        if (!OBOcrDownloadBusy()) {
            if (pollCount > 0)
                obLog.Push("[OCR-DnPopup] cleared after " (A_TickCount - start) "ms (" pollCount " polls)")
            return true
        }
        pollCount++
        if (A_TickCount - start > maxMs) {
            obLog.Push("[OCR-DnPopup] TIMEOUT after " maxMs "ms")
            return false
        }
        Sleep(100)
    }
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; OVERCAP FUNCTIONS -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

OvercapDediMs(n) {
    global overcapDediTable
    if (overcapDediTable.Has(n))
        return overcapDediTable[n]
    lastKnown := 9
    secondLast := 8
    msPerDedi := overcapDediTable[lastKnown] - overcapDediTable[secondLast]
    return overcapDediTable[lastKnown] + ((n - lastKnown) * msPerDedi)
}

ToggleOvercapScript(*) {
    global runOvercapScript
    if (runOvercapScript) {
        StopOvercapScript()
    } else {
        StartOvercapScript()
    }
}

StartOvercapScript() {
    global runOvercapScript := true
    global overcapStartTick := A_TickCount
    global overcapDediTarget, overcapAccumMs
    global overcapDediEdit, overcapCountdown

    global overcapDediTarget := Integer(overcapDediEdit.Value)

    if (overcapDediTarget > 0) {
        targetSec := OvercapDediMs(overcapDediTarget) // 1000
        ToolTip(" Overcap RUNNING " overcapDediTarget " dedi (" targetSec ".00s)`nF2 = Pause  |  Q = Stop", 0, 0)
        overcapCountdown.Value := "Overcapping " overcapDediTarget " Dedis  " targetSec ".00s"
    } else {
        ToolTip(" Overcap RUNNING — free mode`nF2 = Pause  |  Q = Stop", 0, 0)
        overcapCountdown.Value := "running — free"
    }

    if WinExist(arkWindow)
        WinActivate(arkWindow)
    SetTimer(OvercapLoop, 50)
    SetTimer(OvercapTimerCheck, 100)
}

StopOvercapScript() {
    global runOvercapScript := false
    global overcapAccumMs, overcapStartTick, overcapCountdown
    SetTimer(OvercapLoop, 0)
    SetTimer(OvercapTimerCheck, 0)
    if (overcapStartTick > 0)
        global overcapAccumMs += A_TickCount - overcapStartTick
    global overcapStartTick := 0
    ToolTip()
    OBCharRestoreTooltip()
    overcapCountdown.Value := ""
}

OvercapLoop() {
    global runOvercapScript
    if (!runOvercapScript)
        return
    Sleep(10)
    Send("{1}")
    Sleep(10)
    Send("{2}")
    Sleep(10)
    Send("{3}")
}

OvercapTimerCheck() {
    global runOvercapScript, overcapDediTarget
    global overcapStartTick, overcapAccumMs, overcapCountdown
    if (!runOvercapScript || overcapDediTarget = 0)
        return
    elapsed   := overcapAccumMs + (A_TickCount - overcapStartTick)
    target    := OvercapDediMs(overcapDediTarget)
    remaining := Max(0, target - elapsed)
    remSec    := remaining // 1000
    remMs     := Mod(remaining, 1000) // 10
    overcapCountdown.Value := "Overcapping " overcapDediTarget " Dedis  " remSec "." Format("{:02}", remMs) "s"
    ToolTip(" Overcap RUNNING " overcapDediTarget " dedi  (" remSec "." Format("{:02}", remMs) "s left)`nF2 = Pause  |  Q = Stop", 0, 0)
    if (elapsed >= target) {
        StopOvercapScript()
        overcapCountdown.Value := overcapDediTarget " Dedis done"
        ToolTip(" Overcap done  " overcapDediTarget " dedi complete!", 0, 0)
        SetTimer(() => ToolTip(), -3000)
        SetTimer(() => (overcapCountdown.Value := ""), -4000)
    }
}

OvercapUpdateStatus(*) {
}

OvercapDediEditChanged(*) {
    global overcapDediEdit, overcapCountdown, runOvercapScript
    val := Integer(overcapDediEdit.Value)
    if (val <= 0) {
        if (!runOvercapScript)
            overcapCountdown.Value := ""
        return
    }
    targetSec := OvercapDediMs(val) // 1000
    if (runOvercapScript) {
        ToolTip(" Overcap RUNNING " val " dedi`nF2 = Pause  |  Q = Stop", 0, 0)
    }
    overcapCountdown.Value := "~" targetSec "s for " val " dedi"

}


;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


; POPCORN — FUNCTIONS

PcFastKey(key) {
    SendInput("{" key "}")
}

; ── Inventory detection ───────────────────────────────────────────────────────
PcWaitForInventory(maxMs := 5000) {
    global pcInvDetectX, pcInvDetectY
    start := A_TickCount
    loop {
        if NFSearchTol(&px, &py, pcInvDetectX, pcInvDetectY, pcInvDetectX+2, pcInvDetectY+2, "0xFFFFFF", 10)
            return true
        if (A_TickCount - start > maxMs)
            return false
        Sleep(16)
    }
}

PcFPressed() {
    _pcStart := A_TickCount
    PcLog("FPressed: mode=" pcMode "  running=" pcRunning)
    if !WinExist(arkwindow) {
        PcLog("FPressed: ARK window not found")
        return
    }
    fHeld := A_TickCount
    while (GetKeyState("f", "P")) {
        Sleep(16)
        if (A_TickCount - fHeld > 2000)
            break
    }
    fHeldMs := A_TickCount - fHeld
    if (fHeldMs > 600) {
        PcLog("FPressed: F held " fHeldMs "ms — likely game action, aborting")
        PerfLogPush("popcorn", _pcStart, "held")
        return
    }
    invAlready := false
    try invAlready := NFSearchTol(&ax, &ay, pcInvDetectX, pcInvDetectY, pcInvDetectX+2, pcInvDetectY+2, "0xFFFFFF", 10)
    if (invAlready) {
        PcLog("FPressed: inventory already open before F — skipping (E-opened?)")
        PerfLogPush("popcorn", _pcStart, "skipped")
        return
    }
    PcLog("FPressed: waiting for inventory pixel")
    if (!PcWaitForInventory(6000)) {
        PcLog("FPressed: inventory pixel not found within 6s — aborting +" (A_TickCount - _pcStart) "ms")
        PerfLogPush("popcorn", _pcStart, "timeout")
        return
    }
    PcLog("FPressed: inventory pixel detected +" (A_TickCount - _pcStart) "ms")
    PerfLogPush("popcorn", _pcStart, "launched")
    savedInv := ""
    savedDrop := ""
    try savedInv  := IniRead(A_ScriptDir "\AIO_config.ini", "Popcorn", "InvKey",  "")
    try savedDrop := IniRead(A_ScriptDir "\AIO_config.ini", "Popcorn", "DropKey", "")
    if (savedDrop = "") {
        PcShowSetKeysPrompt()
        return
    }
    global pcRunning := true
    MainGui.Hide()
    global guiVisible := false
    if (pcMode > 0)
        PcRegisterSpeedHotkeys(true)
    PcUpdateUI()
    SetTimer(PcRunCurrentMode, -1)
}

; ── Search filter ─────────────────────────────────────
PcApplyFilter(filter) {
    global pcSearchBarX, pcSearchBarY, pcStartSlotX, pcStartSlotY, arkwindow
    if (filter = "")
        return
    if !WinExist(arkwindow)
        return
    WinActivate(arkwindow)
    Sleep(80)
    ControlClick("x" pcSearchBarX " y" pcSearchBarY, arkwindow,,,,"NA")
    Sleep(120)
    _savedClip := A_Clipboard
    A_Clipboard := filter
    SendInput("^a")
    Sleep(30)
    SendInput("^v")
    Sleep(250)
    A_Clipboard := _savedClip
    ControlClick("x" pcStartSlotX " y" pcStartSlotY, arkwindow,,,,"NA")
    Sleep(120)
    PcLog("ApplyFilter: [" filter "] applied")
}

PcClearFilter() {
    global pcSearchBarX, pcSearchBarY, arkwindow
    if !WinExist(arkwindow)
        return
    WinActivate(arkwindow)
    Sleep(60)
    ControlClick("x" pcSearchBarX " y" pcSearchBarY, arkwindow,,,,"NA")
    Sleep(80)
    SendInput("^a")
    Sleep(20)
    SendInput("{Delete}")
    Sleep(150)
    ControlClick("x" pcStartSlotX " y" pcStartSlotY, arkwindow,,,,"NA")
    Sleep(100)
    PcLog("ClearFilter: done")
}



PcCustomFilterChanged(ctrl, *) {
    global pcCustomFilter := ctrl.Text
    try IniWrite(ctrl.Text, A_ScriptDir "\AIO_config.ini", "Popcorn", "CustomFilter")
    if (pcMode > 0)
        ToolTip(PcBuildTooltip(), 0, 0)
}

PcCustomFilterClear(*) {
    global pcCustomFilter := ""
    try pcCustomEdit.Text := ""
}

; ── Transfer All ─────────────────────────────────
PcTransferAll() {
    global pcTransferAllX, pcTransferAllY, arkwindow
    Sleep(80)
    ControlClick("x" pcTransferAllX " y" pcTransferAllY, arkwindow,,,,"NA")
    Sleep(100)
}

PcCheckStorageEmpty() {
    global pcStorageScanX, pcStorageScanY, pcStorageScanW, pcStorageScanH, pcIsBag
    sx := pcStorageScanX
    sy := pcStorageScanY
    sw := pcStorageScanW
    sh := pcStorageScanH
    attempts := 0
    while (attempts < 3) {
        attempts++
        try {
            sText := OCR.FromRect(sx, sy, sw, sh, {scale: 3}).Text
            cleaned := RegExReplace(sText, "[oO]", "0")
            cleaned := RegExReplace(cleaned, "[Il|]", "1")
            cleaned := RegExReplace(cleaned, "s(?=\d)", "5")
            cleaned := RegExReplace(cleaned, "\d+\.\d+\s*/?\s*\d*\.?\d*", "")
            cleaned := RegExReplace(cleaned, "\s+", " ")
            if RegExMatch(cleaned, "(-?\d+)\s*/\s*(\d+)", &sMatch) {
                val := Integer(sMatch[1])
                maxVal := Integer(sMatch[2])
                if (val < 0)
                    val := 0
                if (val = 0 && StrLen(sMatch[1]) > 1) {
                    PcLog("StorageCheck: suspicious 0 from [" sMatch[1] "] (" StrLen(sMatch[1]) " digits) — retrying")
                    Sleep(80)
                    continue
                }
                if (maxVal >= 6 && maxVal <= 999) {
                    PcLog("StorageCheck (" sx "," sy "): [" sText "] → " val "/" maxVal "  (attempt " attempts ")")
                    return val
                }
            }
            if RegExMatch(cleaned, "(\d+)\s*/\s*[-—–]+", &bagMatch) {
                val := Integer(bagMatch[1])
                if (val < 0)
                    val := 0
                PcLog("StorageCheck (" sx "," sy "): [" sText "] → " val "/-- (bag)  (attempt " attempts ")")
                return val
            }
            if (!pcIsBag && attempts >= 2 && RegExMatch(cleaned, "^\s*/", )) {
                PcLog("StorageCheck: bare slash after " attempts " attempts — assuming 0")
                return 0
            }
        } catch as e {
            PcLog("StorageCheck: OCR failed attempt " attempts " — " e.Message)
        }
        Sleep(80)
    }
    PcLog("StorageCheck: no valid reading after " attempts " attempts raw=[" sText "] cleaned=[" cleaned "]" (pcIsBag ? " (bag)" : ""))
    return -1
}

PcToggleScanResize(*) {
    global pcStorageResizing, pcScanAreaBtn
    if (pcStorageResizing) {
        PcExitScanResize()
        return
    }
    global pcStorageResizing := true
    DarkBtnText(pcScanAreaBtn, "Done")
    PcShowStorageOverlay()
    try Hotkey("$w", PcScanMoveUp, "On")
    try Hotkey("$s", PcScanMoveDown, "On")
    try Hotkey("$a", PcScanMoveLeft, "On")
    try Hotkey("$d", PcScanMoveRight, "On")
    try Hotkey("$Up", PcScanGrowH, "On")
    try Hotkey("$Down", PcScanShrinkH, "On")
    try Hotkey("$Right", PcScanGrowW, "On")
    try Hotkey("$Left", PcScanShrinkW, "On")
    try Hotkey("$Enter", PcScanResizeDone, "On")
    ToolTip(" Storage scan area: WASD=move  Arrows=resize  Enter=done", 0, 0)
}

PcExitScanResize() {
    global pcStorageResizing, pcScanAreaBtn
    global pcStorageScanX, pcStorageScanY, pcStorageScanW, pcStorageScanH
    pcStorageResizing := false
    DarkBtnText(pcScanAreaBtn, "Scan Area")
    try Hotkey("$w", "Off")
    try Hotkey("$s", "Off")
    try Hotkey("$a", "Off")
    try Hotkey("$d", "Off")
    try Hotkey("$Up", "Off")
    try Hotkey("$Down", "Off")
    try Hotkey("$Right", "Off")
    try Hotkey("$Left", "Off")
    try Hotkey("$Enter", "Off")
    PcHideStorageOverlay()
    ToolTip()
    PcSaveScanArea()
    PcLog("ScanResize: saved (" pcStorageScanX "," pcStorageScanY " " pcStorageScanW "x" pcStorageScanH ")")
}

PcScanResizeDone(*) {
    PcExitScanResize()
}

PcScanMoveUp(*) {
    global pcStorageScanY := Max(0, pcStorageScanY - 10)
    PcShowStorageOverlay()
}
PcScanMoveDown(*) {
    global pcStorageScanY := pcStorageScanY + 10
    PcShowStorageOverlay()
}
PcScanMoveLeft(*) {
    global pcStorageScanX := Max(0, pcStorageScanX - 10)
    PcShowStorageOverlay()
}
PcScanMoveRight(*) {
    global pcStorageScanX := pcStorageScanX + 10
    PcShowStorageOverlay()
}
PcScanGrowW(*) {
    global pcStorageScanW := pcStorageScanW + 10
    PcShowStorageOverlay()
}
PcScanShrinkW(*) {
    global pcStorageScanW := Max(20, pcStorageScanW - 10)
    PcShowStorageOverlay()
}
PcScanGrowH(*) {
    global pcStorageScanH := pcStorageScanH + 10
    PcShowStorageOverlay()
}
PcScanShrinkH(*) {
    global pcStorageScanH := Max(10, pcStorageScanH - 10)
    PcShowStorageOverlay()
}

PcShowStorageOverlay() {
    global pcStorageOverlay, pcStorageScanX, pcStorageScanY, pcStorageScanW, pcStorageScanH
    PcHideStorageOverlay()
    b := 2
    x := pcStorageScanX, y := pcStorageScanY, w := pcStorageScanW, h := pcStorageScanH
    strips := [
        {x: x,     y: y,     w: w, h: b},
        {x: x,     y: y+h-b, w: w, h: b},
        {x: x,     y: y,     w: b, h: h},
        {x: x+w-b, y: y,     w: b, h: h}
    ]
    guis := []
    for s in strips {
        g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        g.BackColor := "FF4444"
        g.Show("x" s.x " y" s.y " w" s.w " h" s.h " NoActivate")
        guis.Push(g)
    }
    sizeGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
    sizeGui.BackColor := "1A1A1A"
    sizeGui.SetFont("s8 cFF4444", "Segoe UI")
    sizeGui.Add("Text", "x2 y0 w200", "(" x "," y ") " w "x" h)
    sizeGui.Show("x" x " y" (y - 18) " NoActivate")
    guis.Push(sizeGui)
    global pcStorageOverlay := guis
}

PcHideStorageOverlay() {
    global pcStorageOverlay
    if (pcStorageOverlay != "") {
        for g in pcStorageOverlay
            try g.Destroy()
        global pcStorageOverlay := ""
    }
}

PcSaveScanArea() {
    global pcStorageScanX, pcStorageScanY, pcStorageScanW, pcStorageScanH
    global pcStorageScanBaseX, pcStorageScanBaseY, pcStorageScanBaseW, pcStorageScanBaseH
    global widthmultiplier, heightmultiplier
    pcStorageScanBaseX := Round(pcStorageScanX / widthmultiplier)
    pcStorageScanBaseY := Round(pcStorageScanY / heightmultiplier)
    pcStorageScanBaseW := Round(pcStorageScanW / widthmultiplier)
    pcStorageScanBaseH := Round(pcStorageScanH / heightmultiplier)
    try {
        IniWrite(pcStorageScanBaseX, A_ScriptDir "\AIO_config.ini", "Popcorn", "ScanBaseX")
        IniWrite(pcStorageScanBaseY, A_ScriptDir "\AIO_config.ini", "Popcorn", "ScanBaseY")
        IniWrite(pcStorageScanBaseW, A_ScriptDir "\AIO_config.ini", "Popcorn", "ScanBaseW")
        IniWrite(pcStorageScanBaseH, A_ScriptDir "\AIO_config.ini", "Popcorn", "ScanBaseH")
    }
}

PcLoadScanArea() {
    global pcStorageScanX, pcStorageScanY, pcStorageScanW, pcStorageScanH
    global pcStorageScanBaseX, pcStorageScanBaseY, pcStorageScanBaseW, pcStorageScanBaseH
    global widthmultiplier, heightmultiplier
    try {
        v := IniRead(A_ScriptDir "\AIO_config.ini", "Popcorn", "ScanBaseX", "")
        if (v != "")
            pcStorageScanBaseX := Integer(v)
        v := IniRead(A_ScriptDir "\AIO_config.ini", "Popcorn", "ScanBaseY", "")
        if (v != "")
            pcStorageScanBaseY := Integer(v)
        v := IniRead(A_ScriptDir "\AIO_config.ini", "Popcorn", "ScanBaseW", "")
        if (v != "")
            pcStorageScanBaseW := Integer(v)
        v := IniRead(A_ScriptDir "\AIO_config.ini", "Popcorn", "ScanBaseH", "")
        if (v != "")
            pcStorageScanBaseH := Integer(v)
    }
    pcStorageScanX := Round(pcStorageScanBaseX * widthmultiplier)
    pcStorageScanY := Round(pcStorageScanBaseY * heightmultiplier)
    pcStorageScanW := Round(pcStorageScanBaseW * widthmultiplier)
    pcStorageScanH := Round(pcStorageScanBaseH * heightmultiplier)
}

; ── 6×6 grid ─────────────────────────────────────────────────────
PcPopcornGrid(skipFirst := false, isFinalCycle := true, maxDrops := 0, dropsSoFar := 0) {
    global pcStartSlotX, pcStartSlotY, pcSlotW, pcSlotH
    global pcColumns, pcRows, pcDropSleep, pcDropKey, pcEarlyExit, pcHoverDelay, pcF1Abort
    PcLog("Grid: dropKey=" pcDropKey "  dropSleep=" pcDropSleep "  hoverDelay=" pcHoverDelay "  skipFirst=" skipFirst "  isFinal=" isFinalCycle (maxDrops ? "  maxDrops=" maxDrops " soFar=" dropsSoFar : ""))
    dropCount := 0
    Loop pcRows {
        row := A_Index - 1
        Loop pcColumns {
            col := A_Index - 1
            if (skipFirst && row = 0 && col = 0)
                continue
            if (GetKeyState("F1", "P")) {
                global pcEarlyExit := true
                global pcF1Abort   := true
            }
            if (GetKeyState("q", "P") && !pcF1Abort)
                global pcEarlyExit := true
            if (pcEarlyExit || pcF1Abort)
                return "early"
            x := pcStartSlotX + col * pcSlotW
            y := pcStartSlotY + row * pcSlotH
            DllCall("SetCursorPos","int",x,"int",y)
            if (isFinalCycle && row = 0)
                Sleep(pcHoverDelay)
            PcFastKey(pcDropKey)
            dropCount++
            if (maxDrops && (dropsSoFar + dropCount) >= maxDrops) {
                PcLog("Grid: max_drops reached (" (dropsSoFar + dropCount) "/" maxDrops ")")
                return "max_reached"
            }
            if (pcDropSleep > 0)
                Sleep(pcDropSleep)
        }
    }
    PcLog("Grid: done — " dropCount " drops fired")
    return "done"
}

PcIsTameInventory() {
    global pcPlayerInvDetectX, pcPlayerInvDetectY, pcPlayerInvDetectColor, pcPlayerInvDetectTol
    global pcTameDetectX, pcTameDetectY, pcTameDetectColor, pcTameDetectTol
    try pc := PxGet(pcPlayerInvDetectX, pcPlayerInvDetectY)
    catch
        pc := 0
    pr := (pc >> 16) & 0xFF, pg := (pc >> 8) & 0xFF, pb := pc & 0xFF
    epr := (pcPlayerInvDetectColor >> 16) & 0xFF
    epg := (pcPlayerInvDetectColor >> 8) & 0xFF
    epb := pcPlayerInvDetectColor & 0xFF
    if (Abs(pr - epr) <= pcPlayerInvDetectTol && Abs(pg - epg) <= pcPlayerInvDetectTol && Abs(pb - epb) <= pcPlayerInvDetectTol) {
        PcLog("TameDetect: PLAYER inv at (" pcPlayerInvDetectX "," pcPlayerInvDetectY ") color=0x" Format("{:06X}", pc) " — not tame")
        return false
    }
    try tc := PxGet(pcTameDetectX, pcTameDetectY)
    catch
        tc := 0
    tr := (tc >> 16) & 0xFF, tg := (tc >> 8) & 0xFF, tb := tc & 0xFF
    etr := (pcTameDetectColor >> 16) & 0xFF
    etg := (pcTameDetectColor >> 8) & 0xFF
    etb := pcTameDetectColor & 0xFF
    matched := (Abs(tr - etr) <= pcTameDetectTol && Abs(tg - etg) <= pcTameDetectTol && Abs(tb - etb) <= pcTameDetectTol)
    if (matched)
        PcLog("TameDetect: TAME at (" pcTameDetectX "," pcTameDetectY ") color=0x" Format("{:06X}", tc))
    return matched
}

PcSelectWeightRegion() {
    global pcOxyDetectX, pcOxyDetectY, pcOxyDetectColor, pcOxyDetectTol
    global pcWeightNX, pcWeightNY, pcWeightNW, pcWeightNH
    global pcWeightOX, pcWeightOY, pcWeightOW, pcWeightOH
    global pcWeightOcrX, pcWeightOcrY, pcWeightOcrW, pcWeightOcrH
    try color := PxGet(pcOxyDetectX, pcOxyDetectY)
    catch
        color := 0
    r := (color >> 16) & 0xFF, g := (color >> 8) & 0xFF, b := color & 0xFF
    er := (pcOxyDetectColor >> 16) & 0xFF
    eg := (pcOxyDetectColor >> 8) & 0xFF
    eb := pcOxyDetectColor & 0xFF
    hasOxy := (Abs(r - er) <= pcOxyDetectTol && Abs(g - eg) <= pcOxyDetectTol && Abs(b - eb) <= pcOxyDetectTol)
    if (hasOxy) {
        pcWeightOcrX := pcWeightOX, pcWeightOcrY := pcWeightOY
        pcWeightOcrW := pcWeightOW, pcWeightOcrH := pcWeightOH
        PcLog("OxyDetect: HAS oxy — using has-oxy weight region")
    } else {
        pcWeightOcrX := pcWeightNX, pcWeightOcrY := pcWeightNY
        pcWeightOcrW := pcWeightNW, pcWeightOcrH := pcWeightNH
        PcLog("OxyDetect: NO oxy — using no-oxy weight region")
    }
}

PcCheckWeight() {
    global pcWeightOcrX, pcWeightOcrY, pcWeightOcrW, pcWeightOcrH
    attempts := 0
    while (attempts < 3) {
        attempts++
        try {
            ocrText := OCR.FromRect(pcWeightOcrX, pcWeightOcrY, pcWeightOcrW, pcWeightOcrH, {scale: 3}).Text
            cleaned := RegExReplace(ocrText, "[oO]", "0")
            cleaned := RegExReplace(cleaned, "[Il|]", "1")
            cleaned := RegExReplace(cleaned, "s(?=\d)", "5")
            if RegExMatch(cleaned, "(\d+\.?\d*)\s*/\s*(\d+\.?\d*)", &m) {
                val := Float(m[1])
                PcLog("WeightOCR: " val "/" m[2] " raw=[" ocrText "]")
                return val
            }
            PcLog("WeightOCR: no match raw=[" ocrText "] cleaned=[" cleaned "]")
        } catch as e {
            PcLog("WeightOCR: FAIL attempt " attempts " — " e.Message)
        }
        Sleep(80)
    }
    PcLog("WeightOCR: no valid reading after " attempts " attempts -> -1")
    return -1.0
}

PcWaitWeightStable(timeoutS := 5.0) {
    last := PcCheckWeight()
    start := A_TickCount
    while ((A_TickCount - start) / 1000 < timeoutS) {
        Sleep(250)
        cur := PcCheckWeight()
        if (cur < 0)
            continue
        if (last >= 0 && Abs(cur - last) < 0.1) {
            PcLog("WeightStable: settled at " cur " after " (A_TickCount - start) "ms")
            return cur
        }
        last := cur
    }
    PcLog("WeightStable: timeout after " timeoutS "s, last=" last)
    return last
}

PcRunDropLoop(label, maxDrops := 0) {
    global pcIsTame, pcForgeSkipFirst, pcEarlyExit, pcF1Abort, pcCycleSleep, pcRows, pcColumns
    isTame := PcIsTameInventory()
    global pcIsTame := isTame
    if (isTame)
        return PcDropLoopTame(label, maxDrops)
    return PcDropLoopStorage(label, maxDrops)
}

PcDropLoopTame(label, maxDrops := 0) {
    global pcForgeSkipFirst, pcEarlyExit, pcF1Abort, pcCycleSleep, pcRows, pcColumns
    PcSelectWeightRegion()
    PcLog("DropLoop(tame): " label " — starting" (maxDrops ? " maxDrops=" maxDrops : ""))
    passNum := 0
    zeroCount := 0
    totalDrops := 0
    while (!pcEarlyExit && !pcF1Abort) {
        passNum++
        result := PcPopcornGrid(pcForgeSkipFirst, , maxDrops, totalDrops)
        gridDrops := pcRows * pcColumns
        if (maxDrops)
            gridDrops := Min(gridDrops, maxDrops - totalDrops)
        totalDrops += gridDrops
        if (result = "max_reached") {
            PcLog("DropLoop(tame): max_drops reached after pass " passNum)
            break
        }
        if (pcEarlyExit || pcF1Abort) {
            PcLog("DropLoop(tame): pass " passNum " — early exit")
            break
        }
        cur := PcCheckWeight()
        PcLog("DropLoop(tame): pass " passNum " weight=" cur)
        if (cur >= 0 && cur < 20.1) {
            zeroCount++
            if (zeroCount >= 2) {
                PcLog("DropLoop(tame): weight<=20 (saddle only) — done")
                PcPopcornTopRow()
                break
            }
        } else {
            zeroCount := 0
        }
        Sleep(pcCycleSleep)
    }
    PcLog("DropLoop(tame): " label " ended after " passNum " passes, " totalDrops " drops")
    return passNum
}

PcDropLoopStorage(label, maxDrops := 0) {
    global pcForgeSkipFirst, pcEarlyExit, pcF1Abort, pcCycleSleep, pcRows, pcColumns
    passNum := 0
    totalDrops := 0
    stallCount := 0
    lastStorage := -99
    while (!pcEarlyExit && !pcF1Abort) {
        passNum++
        PcPopcornGrid(pcForgeSkipFirst, , maxDrops, totalDrops)
        gridDrops := pcRows * pcColumns
        if (maxDrops)
            gridDrops := Min(gridDrops, maxDrops - totalDrops)
        totalDrops += gridDrops
        if (pcEarlyExit || pcF1Abort)
            break
        if (passNum > 1) {
            chk := PcCheckStorageEmpty()
            if (chk = 0) {
                PcLog("DropLoopStorage: storage=0 after pass " passNum " — top row cleanup")
                PcPopcornTopRow()
                break
            }
            if (chk = lastStorage) {
                stallCount++
                if (stallCount >= 3) {
                    PcLog("DropLoopStorage: stalled at " chk " for 3 passes — filter done or drop cap")
                    break
                }
            } else {
                lastStorage := chk
                stallCount := 0
            }
        }
        Sleep(pcCycleSleep)
    }
    PcLog("DropLoopStorage: " label " ended after " passNum " passes")
    return passNum
}

PcPopcornTopRow() {
    global pcStartSlotX, pcStartSlotY, pcSlotW
    global pcColumns, pcDropKey, pcDropSleep
    Loop pcColumns {
        col := A_Index - 1
        x := pcStartSlotX + col * pcSlotW
        DllCall("SetCursorPos", "int", x, "int", pcStartSlotY)
        PcFastKey(pcDropKey)
        if (pcDropSleep > 0)
            Sleep(pcDropSleep)
    }
    PcLog("TopRow: " pcColumns " drops fired")
}

; ── Speed control ─────────────────────────────────────────────────────────────
PcApplySpeed() {
    global pcSpeedMode, pcSpeedMap, pcDropSleep, pcCycleSleep, pcHoverDelay
    s := pcSpeedMap[pcSpeedMode]
    global pcDropSleep  := s[1]
    global pcCycleSleep := s[2]
    global pcHoverDelay := s[3]
}

PcSaveSpeedToINI() {
    global pcSpeedMode, pcDropSleep, pcCycleSleep, pcHoverDelay
    try IniWrite(pcSpeedMode,   A_ScriptDir "\AIO_config.ini", "Popcorn", "SpeedMode")
    try IniWrite(pcDropSleep,   A_ScriptDir "\AIO_config.ini", "Popcorn", "DropSleep")
    try IniWrite(pcCycleSleep,  A_ScriptDir "\AIO_config.ini", "Popcorn", "CycleSleep")
    try IniWrite(pcHoverDelay,  A_ScriptDir "\AIO_config.ini", "Popcorn", "HoverDelay")
}

PcAdjustDropSleep(delta) {
    global pcDropSleep
    step := 2
    pcDropSleep := Max(1, pcDropSleep + (delta * step))
    PcSaveSpeedToINI()
    try pcSpeedTxt.Text := pcSpeedNames[pcSpeedMode] " [Z]"
    ToolTip("Drop sleep: " pcDropSleep "ms  (±" step "ms)", 0, 0)
    SetTimer(() => ToolTip(), -1500)
    PcLog("DropSleep adjusted to " pcDropSleep " (step=" step ")")
}

; ── Status text ───────────────────────────────────────────────────────────────
PcSetStatus(msg) {
    try pcStatusTxt.Text := msg
}

PcUpdateF10Speed() {
    global pcMode, pcSpeedMode, pcSpeedNames, pcF10SpeedTxt, pcSpeedTxt
    speedColors := Map(0,"FFAA00", 1,"FF4444", 2,"FF2222")
    if (pcMode > 0) {
        pcF10SpeedTxt.Text := pcSpeedNames[pcSpeedMode]
        pcF10SpeedTxt.Opt("c" speedColors[pcSpeedMode])
        try pcSpeedTxt.Text := pcSpeedNames[pcSpeedMode] " [Z]"
    } else {
        pcF10SpeedTxt.Text := ""
    }
}

PcLog(msg) {
    global pcLogEntries
    ts := FormatTime("", "HH:mm:ss")
    pcLogEntries.Push(ts " | " msg)
    if (pcLogEntries.Length > 80)
        pcLogEntries.RemoveAt(1)
}

MacroLog(msg) {
    global macroLogEntries
    ts := FormatTime("", "HH:mm:ss")
    macroLogEntries.Push(ts " | " msg)
    if (macroLogEntries.Length > 80)
        macroLogEntries.RemoveAt(1)
}

CraftLog(msg) {
    global acLog
    ts := FormatTime("", "HH:mm:ss")
    acLog.Push(ts " | " msg)
    if (acLog.Length > 80)
        acLog.RemoveAt(1)
}

; ── UI refresh ────────────────────────────────────────────────────────────────
PcUpdateUI() {
    global pcF10Step
    try {

        if (pcF10Step = 0) {
            try pcF10StatusTxt.Text := ""
            try pcF10SpeedTxt.Text  := ""
        }

        pcCustomCard.Value := pcAllCustomActive ? 1 : 0
        pcAllNoFilterInd.Value := pcAllNoFilter ? 1 : 0

        pcForgeSkipInd.Value := pcForgeSkipFirst   ? 1 : 0
        pcForgeXferInd.Value := pcForgeTransferAll ? 1 : 0

        pcPolyInd.Value    := pcGrinderPoly    ? 1 : 0
        pcMetalInd.Value   := pcGrinderMetal   ? 1 : 0
        pcCrystalInd.Value := pcGrinderCrystal ? 1 : 0
        pcRawInd.Value     := pcPresetRaw      ? 1 : 0
        pcCookedInd.Value  := pcPresetCooked   ? 1 : 0

        if (pcF10Step > 0 || pcMode > 0) {
            speedColors := Map(0,"FFAA00", 1,"FF4444", 2,"FF2222")
            pcSpeedTxt.Text := pcSpeedNames[pcSpeedMode] " [Z]"
            pcSpeedTxt.Opt("c" speedColors[pcSpeedMode])
        } else {
            pcSpeedTxt.Text := ""
        }

        DarkBtnText(pcExecBtn, pcRunning ? "Stop" : "Start")
    }
}

; ── Mode selection / toggle ───────────────────────────────────────────────────

PcCustomCheckToggle(ctrl, *) {
    global pcAllCustomActive := ctrl.Value ? true : false
    if (pcAllCustomActive) {
        global pcAllNoFilter := false
    }
    anyPreset := pcGrinderPoly || pcGrinderMetal || pcGrinderCrystal || pcPresetRaw || pcPresetCooked
    anyActive := anyPreset || pcAllCustomActive || pcAllNoFilter
    if (anyActive && pcMode = 0) {
        global pcMode := 3
        PcRegisterSpeedHotkeys(true)
    } else if (!anyActive) {
        global pcMode := 0
        PcRegisterSpeedHotkeys(false)
    }
    PcUpdateUI()
    if (pcMode > 0)
        ToolTip(PcBuildTooltip(), 0, 0)
    else
        ToolTip()
}

PcBuildTooltip() {
    global pcMode, pcGrinderPoly, pcGrinderMetal, pcGrinderCrystal
    global pcPresetRaw, pcPresetCooked, pcCustomFilter, pcAllCustomActive
    global pcForgeTransferAll, pcForgeSkipFirst, pcSpeedNames, pcSpeedMode
    global pcAllNoFilter

    if (pcMode = 0)
        return ""

    parts := []
    if (pcAllNoFilter)
        parts.Push("All (no filter)")
    if (pcGrinderPoly)
        parts.Push("Poly")
    if (pcGrinderMetal)
        parts.Push("Metal")
    if (pcGrinderCrystal)
        parts.Push("Crystal")
    if (pcPresetRaw)
        parts.Push("Raw")
    if (pcPresetCooked)
        parts.Push("Cooked")

    if (pcAllCustomActive) {
        for , _pf in pcCustomFilterList
            parts.Push("Custom [" _pf "]")
        if (pcCustomFilter != "" && !AcListHas(pcCustomFilterList, pcCustomFilter))
            parts.Push("Custom [" pcCustomFilter "]")
    }

    if (parts.Length > 0) {
        desc := ""
        for i, p in parts
            desc .= (i > 1 ? " + " : "") p
    } else {
        desc := "Nothing selected"
    }

    flags := []
    if (pcForgeTransferAll)
        flags.Push("Transfer All")
    if (pcForgeSkipFirst)
        flags.Push("Skip 1st")

    line1 := " Popcorn: " desc
    if (flags.Length > 0) {
        flagStr := ""
        for i, f in flags
            flagStr .= (i > 1 ? ", " : "") f
        line1 .= "  (" flagStr ")"
    }

    line2 := "Speed: " pcSpeedNames[pcSpeedMode] "  |  Z = Change drop speed"

    if (parts.Length > 1)
        line3 := "F to start  |  Q = Cycle presets  |  F1 = Stop/UI"
    else
        line3 := "F to start  |  Q = Stop  |  F1 = Stop/UI"

    return line1 "`n" line2 "`n" line3
}

PcToggle(which) {
    switch which {
        case "ForgeSkip":   global pcForgeSkipFirst    := !pcForgeSkipFirst
        case "ForgeXfer":   global pcForgeTransferAll  := !pcForgeTransferAll
        case "AllNoFilter": global pcAllNoFilter       := !pcAllNoFilter
        case "Poly":        global pcGrinderPoly       := !pcGrinderPoly
        case "Metal":       global pcGrinderMetal      := !pcGrinderMetal
        case "Crystal":     global pcGrinderCrystal    := !pcGrinderCrystal
        case "Raw":         global pcPresetRaw         := !pcPresetRaw
        case "Cooked":      global pcPresetCooked      := !pcPresetCooked
    }

    if (which = "AllNoFilter" && pcAllNoFilter) {
        global pcGrinderPoly := false, pcGrinderMetal := false, pcGrinderCrystal := false
        global pcPresetRaw := false, pcPresetCooked := false
        global pcAllCustomActive := false
    }
    anyPreset := pcGrinderPoly || pcGrinderMetal || pcGrinderCrystal || pcPresetRaw || pcPresetCooked
    if (anyPreset && which != "AllNoFilter")
        global pcAllNoFilter := false

    anyActive := anyPreset || pcAllCustomActive || pcAllNoFilter
    if (anyActive && pcMode = 0) {
        global pcMode := 3
        PcRegisterSpeedHotkeys(true)
    } else if (!anyActive) {
        global pcMode := 0
        PcRegisterSpeedHotkeys(false)
    }
    PcUpdateUI()
    if (pcMode > 0)
        ToolTip(PcBuildTooltip(), 0, 0)
    else
        ToolTip()
}

; ── Execute button handler ────────────────────────────────────────────────────
PcExecuteBtn() {
    if (pcRunning) {
        global pcEarlyExit := true
        PcSetStatus("Stopping...")
        return
    }
    if (pcMode = 0) {
        if (pcGrinderPoly || pcGrinderMetal || pcGrinderCrystal || pcPresetRaw || pcPresetCooked || pcAllCustomActive || pcAllNoFilter)
            global pcMode := 3
        else {
            PcSetStatus("Select a mode first")
            return
        }
    }
    savedDrop := ""
    savedInv  := ""
    try savedDrop := IniRead(A_ScriptDir "\AIO_config.ini", "Popcorn", "DropKey", "")
    try savedInv  := IniRead(A_ScriptDir "\AIO_config.ini", "Popcorn", "InvKey",  "")
    if (savedDrop = "") {
        PcShowSetKeysPrompt()
        return
    }
    if !WinExist(arkwindow) {
        PcSetStatus("ARK window not found")
        return
    }
    if (pcMode = 3)
        try IniWrite(pcCustomFilter, A_ScriptDir "\AIO_config.ini", "Popcorn", "CustomFilter")

    modeNames := Map(3,"Transfer")
    modeName  := modeNames.Has(pcMode) ? modeNames[pcMode] : "Popcorn"
    PcSetStatus(modeName " — press F at an inventory")
    if (pcF10Step > 0)
        ToolTip(PcBuildF10Tooltip(), 0, 0)
    else
        ToolTip(PcBuildTooltip(), 0, 0)
    MainGui.Hide()
    global guiVisible := false
    WinActivate(arkwindow)
}

PcRunCurrentMode() {
    SetKeyDelay(-1, -1)
    SetMouseDelay(-1)
    global pcF1Abort := false
    PcLog("RunCurrentMode: mode=" pcMode)
    if WinExist(arkwindow) {
        WinActivate(arkwindow)
        Sleep(150)
        PcLog("RunCurrentMode: ARK activated — 150ms settle")
    }
    global pcIsBag := false
    try {
        if NFSearchTol(&bx, &by, pcBagDetectX, pcBagDetectY, pcBagDetectX+2, pcBagDetectY+2, pcBagDetectColor, pcBagDetectTol) {
            global pcIsBag := true
            PcLog("RunCurrentMode: bag/cache detected at (" pcBagDetectX "," pcBagDetectY ")")
        }
    }
    global pcIsTame := false
    if (pcF10Step > 0)
        ToolTip(PcBuildF10Tooltip(), 0, 0)
    else
        ToolTip(PcBuildTooltip(), 0, 0)

    isTame := PcIsTameInventory()
    global pcIsTame := isTame
    if (isTame) {
        PcLog("RunCurrentMode: TAME inventory — using weight-based drop loop")
        PcDropLoopTame("tame-unified")
    } else {
        PcUnifiedRun()
    }
    global pcRunning   := false
    global pcEarlyExit := false
    global pcF1Abort   := false
    PcLog("RunCurrentMode: finished — mode staying active (F10 to change/off)")
    PcUpdateUI()
    if (pcF10Step > 0 || pcMode > 0) {
        PcRegisterSpeedHotkeys(true)
        PcShowArmedTooltip()
    } else {
        PcRegisterSpeedHotkeys(false)
        ToolTip()
    }
}

; ── Mode implementations ──────────────────────────────────────────────────────

PcUnifiedRun() {
    global pcEarlyExit, pcForgeTransferAll, pcForgeSkipFirst, pcCycleSleep
    global pcGrinderPoly, pcGrinderMetal, pcGrinderCrystal, pcPresetRaw, pcPresetCooked
    global pcCustomFilter, pcAllCustomActive, pcAllNoFilter
    stalled := false

    filters := []
    labels  := []
    isClearFilter := []
    if (pcAllNoFilter) {
        filters.Push(""), labels.Push("All (no filter)"), isClearFilter.Push(true)
    }
    if (pcGrinderPoly) {
        filters.Push(pcGrinderFilterPoly), labels.Push("Poly"), isClearFilter.Push(false)
    }
    if (pcGrinderMetal) {
        filters.Push(pcGrinderFilterMetal), labels.Push("Metal"), isClearFilter.Push(false)
    }
    if (pcGrinderCrystal) {
        filters.Push(pcGrinderFilterCrystal), labels.Push("Crystal"), isClearFilter.Push(false)
    }
    if (pcPresetRaw) {
        filters.Push(pcRawFilter), labels.Push("Raw"), isClearFilter.Push(false)
    }
    if (pcPresetCooked) {
        filters.Push(pcCookedFilter), labels.Push("Cooked"), isClearFilter.Push(false)
    }
    if (pcAllCustomActive) {
        for , _pf in pcCustomFilterList {
            filters.Push(_pf), labels.Push("Custom [" _pf "]"), isClearFilter.Push(false)
        }
        if (pcCustomFilter != "" && !AcListHas(pcCustomFilterList, pcCustomFilter)) {
            filters.Push(pcCustomFilter), labels.Push("Custom [" pcCustomFilter "]"), isClearFilter.Push(false)
        }
    }

    Sleep(50)

    if (filters.Length > 1) {
        PcLog("UnifiedRun: START multi-step  count=" filters.Length "  skipFirst=" pcForgeSkipFirst "  xferAll=" pcForgeTransferAll)
        for i, f in filters {
            if (pcF1Abort) {
                PcLog("UnifiedRun: F1 abort before step " i)
                break
            }
            global pcEarlyExit := false
            if (i > 1) {
                while (GetKeyState("q", "P") && !pcF1Abort)
                    Sleep(50)
                Sleep(50)
                if (pcF1Abort) {
                    PcLog("UnifiedRun: F1 abort during KeyWait for step " i)
                    break
                }
                PcLog("UnifiedRun: KeyWait+debounce done for step " i)
            }
            remaining := filters.Length - i
            nextLabel := remaining > 0 ? labels[i + 1] : ""
            PcLog("UnifiedRun: step " i " [" f "] for " labels[i] "  (" remaining " remaining)")
            PcSetStatus(labels[i] (remaining > 0 ? "  (Q → " nextLabel ")" : "  (auto-stop on empty)"))
            if (isClearFilter[i])
                PcClearFilter()
            else
                PcApplyFilter(f)

            ToolTip(PcBuildTooltip(), 0, 0)
            passNum := 0
            ocrFails := 0
            lastStorage := -99
            stallCount := 0
            while (!pcEarlyExit && !pcF1Abort) {
                passNum++
                PcPopcornGrid(pcForgeSkipFirst)
                if (pcEarlyExit || pcF1Abort)
                    break
                if (passNum > 1) {
                    chk := PcCheckStorageEmpty()
                    if (chk = 0) {
                        PcLog("UnifiedRun: storage=0 after pass " passNum " — top row cleanup")
                        PcPopcornTopRow()
                        break
                    }
                    if (chk = -1) {
                        ocrFails++
                        if (ocrFails >= 6) {
                            PcLog("UnifiedRun: 6 consecutive OCR fails after pass " passNum " — assuming empty")
                            PcPopcornTopRow()
                            break
                        }
                    } else {
                        ocrFails := 0
                        if (chk = lastStorage) {
                            stallCount++
                            if (stallCount >= 3) {
                                PcLog("UnifiedRun: storage stalled at " chk " for 3 passes after pass " passNum " — ground cap hit")
                                stalled := true
                                break
                            }
                        } else {
                            lastStorage := chk
                            stallCount := 0
                        }
                    }
                }
                Sleep(pcCycleSleep)
            }
            PcLog("UnifiedRun: " labels[i] " ended after " passNum " passes" (stalled ? " (stalled)" : ""))
            stalled := false
            if (pcF1Abort)
                break
        }
        PcLog("UnifiedRun: all steps done")

    } else if (filters.Length = 1) {
        PcLog("UnifiedRun: START single [" labels[1] "]  skipFirst=" pcForgeSkipFirst "  xferAll=" pcForgeTransferAll)
        PcSetStatus(labels[1] " — dropping")
        if (isClearFilter[1])
            PcClearFilter()
        else
            PcApplyFilter(filters[1])
        passNum := 0
        ocrFails := 0
        lastStorage := -99
        stallCount := 0
        while (!pcEarlyExit && !pcF1Abort) {
            passNum++
            PcPopcornGrid(pcForgeSkipFirst)
            if (pcEarlyExit || pcF1Abort)
                break
            if (passNum > 1) {
                chk := PcCheckStorageEmpty()
                if (chk = 0) {
                    PcLog("UnifiedRun: storage=0 after pass " passNum " — top row cleanup")
                    PcPopcornTopRow()
                    break
                }
                if (chk = -1) {
                    ocrFails++
                    if (ocrFails >= 6) {
                        PcLog("UnifiedRun: 6 consecutive OCR fails after pass " passNum " — assuming empty")
                        PcPopcornTopRow()
                        break
                    }
                } else {
                    ocrFails := 0
                    if (chk = lastStorage) {
                        stallCount++
                        if (stallCount >= 3) {
                            PcLog("UnifiedRun: storage stalled at " chk " for 3 passes after pass " passNum " — ground cap hit")
                            stalled := true
                            break
                        }
                    } else {
                        lastStorage := chk
                        stallCount := 0
                    }
                }
            }
            Sleep(pcCycleSleep)
        }
        PcLog("UnifiedRun: " labels[1] " ended after " passNum " passes")

    } else {
        PcLog("UnifiedRun: START fallback all mode  skipFirst=" pcForgeSkipFirst "  xferAll=" pcForgeTransferAll)
        if (pcCustomFilter != "" || pcCustomFilterList.Length > 0) {
            _fallbackFilter := pcCustomFilter != "" ? pcCustomFilter : (pcCustomFilterList.Length > 0 ? pcCustomFilterList[1] : "")
            if (_fallbackFilter != "") {
                PcApplyFilter(_fallbackFilter)
                PcLog("UnifiedRun: fallback applied filter [" _fallbackFilter "]")
            }
        } else {
            PcClearFilter()
        }
        passNum := 0
        ocrFails := 0
        lastStorage := -99
        stallCount := 0
        PcSetStatus("Dropping")
        while (!pcEarlyExit && !pcF1Abort) {
            passNum++
            PcPopcornGrid(pcForgeSkipFirst)
            if (pcEarlyExit || pcF1Abort)
                break
            if (passNum > 1) {
                chk := PcCheckStorageEmpty()
                if (chk = 0) {
                    PcLog("UnifiedRun: storage=0 after pass " passNum " — top row cleanup")
                    PcPopcornTopRow()
                    break
                }
                if (chk = -1) {
                    ocrFails++
                    if (ocrFails >= 6) {
                        PcLog("UnifiedRun: 6 consecutive OCR fails after pass " passNum " — assuming empty")
                        PcPopcornTopRow()
                        break
                    }
                } else {
                    ocrFails := 0
                    if (chk = lastStorage) {
                        stallCount++
                        if (stallCount >= 3) {
                            PcLog("UnifiedRun: storage stalled at " chk " for 3 passes after pass " passNum " — ground cap hit")
                            stalled := true
                            break
                        }
                    } else {
                        lastStorage := chk
                        stallCount := 0
                    }
                }
            }
            Sleep(pcCycleSleep)
        }
        PcLog("UnifiedRun: loop ended after " passNum " passes")
    }

    if (pcF1Abort) {
        PcLog("UnifiedRun: F1 abort — skipping cleanup")
        PcSetStatus("Paused")
        PcLog("UnifiedRun: PAUSED")
        return
    }

    if (stalled) {
        Sleep(100)
        if (pcIsBag) {
            PcLog("UnifiedRun: bag stalled — skipping close")
        } else {
            PcLog("UnifiedRun: closing inventory (stalled — pick up & depo, then F to continue)")
            Send("{f}")
            Sleep(200)
        }
        PcSetStatus("Stalled — pick up items, F to continue")
        PcLog("UnifiedRun: STALLED")
        return
    }

    if (pcForgeTransferAll && !pcIsBag) {
        PcSetStatus("Transferring all...")
        PcLog("UnifiedRun: applying Transfer All")
        PcTransferAll()
    }

    Sleep(100)
    if (pcIsBag) {
        PcLog("UnifiedRun: bag — skipping close (auto-despawns at 0)")
    } else {
        PcLog("UnifiedRun: closing inventory")
        Send("{f}")
        Sleep(200)
    }
    PcSetStatus("Done")
    PcLog("UnifiedRun: DONE")
}

; ── Calibration ───────────────────────────────────────────────────────────────
PcShowSetKeysPrompt() {
    promptGui := Gui("+AlwaysOnTop -MinimizeBox", "Keys Not Set")
    promptGui.BackColor := "1A1A1A"
    promptGui.SetFont("s10 cDDDDDD", "Segoe UI")
    promptGui.Add("Text", "x20 y20 w300 h20 Center", "Set your keys before continuing")
    promptGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
    btnOK := promptGui.Add("Button", "x20 y58 w150 h28", "Set Keys Now")
    promptGui.SetFont("s9 c888888", "Segoe UI")
    btnLater := promptGui.Add("Button", "x180 y58 w140 h28", "Do It Later")
    btnOK.OnEvent("Click", PcPromptOK)
    btnLater.OnEvent("Click", (*) => promptGui.Destroy())
    promptGui.Show("w340 h100")

    PcPromptOK(*) {
        promptGui.Destroy()
        PcShowSetKeysForm()
    }
}

PcShowSetKeysForm() {
    global pcInvKey, pcDropKey
    formGui := Gui("+AlwaysOnTop -MinimizeBox", "Set Keys")
    formGui.BackColor := "1A1A1A"

    formGui.SetFont("s9 c888888", "Segoe UI")
    formGui.Add("Text", "x20 y20 w120 h22 +0x200", "Inventory key:")
    formGui.SetFont("s9 c000000", "Segoe UI")
    invEdit := formGui.Add("Edit", "x148 y20 w60 h22 Center", pcInvKey)
    formGui.SetFont("s9 cFF4444", "Segoe UI")
    btnDetectInv := formGui.Add("Button", "x218 y20 w90 h22", "Set")
    formGui.SetFont("s8 c666666 Italic", "Segoe UI")
    formGui.Add("Text", "x20 y44 w288 h16", "(will save for sheep mode)")

    formGui.SetFont("s9 c888888", "Segoe UI")
    formGui.Add("Text", "x20 y66 w120 h22 +0x200", "Drop key:")
    formGui.SetFont("s9 c000000", "Segoe UI")
    dropEdit := formGui.Add("Edit", "x148 y66 w60 h22 Center", pcDropKey)
    formGui.SetFont("s9 cFF4444", "Segoe UI")
    btnDetectDrop := formGui.Add("Button", "x218 y66 w90 h22", "Set")
    formGui.SetFont("s8 c666666 Italic", "Segoe UI")
    formGui.Add("Text", "x20 y90 w288 h16", "(what you popcorn with)")

    formGui.SetFont("s9 cDDDDDD", "Segoe UI")
    formGui.Add("Text", "x20 y114 w288 h16 Center", "Click Set then press a key to bind")

    formGui.SetFont("s9 Bold cFF4444", "Segoe UI")
    btnSave   := formGui.Add("Button", "x20  y140 w140 h28", "Save")
    formGui.SetFont("s9 c888888", "Segoe UI")
    btnCancel := formGui.Add("Button", "x168 y140 w140 h28", "Cancel")

    btnDetectInv.OnEvent("Click",  (*) => PcDetectKeyIntoEdit(invEdit))
    btnDetectDrop.OnEvent("Click", (*) => PcDetectKeyIntoEdit(dropEdit))
    btnCancel.OnEvent("Click",     (*) => formGui.Destroy())
    btnSave.OnEvent("Click", PcSaveKeysFromForm)

    formGui.Show("w328 h182")

    PcSaveKeysFromForm(*) {
        ToolTip()
        newInv  := Trim(invEdit.Value)
        newDrop := Trim(dropEdit.Value)
        if (newInv = "" || newDrop = "") {
            MsgBox("Both keys must be filled in.", "Set Keys", "OK Icon!")
            return
        }
        global pcInvKey  := newInv
        global pcDropKey := newDrop
        global sheepInventoryKey := newInv
        try sheepInventoryInput.Value := newInv
        try pcDropKeyTxt.Text := newDrop
        try IniWrite(newInv,  A_ScriptDir "\AIO_config.ini", "Popcorn", "InvKey")
        try IniWrite(newDrop, A_ScriptDir "\AIO_config.ini", "Popcorn", "DropKey")
        PcSetStatus("Keys saved   Inv=" newInv "   Drop=" newDrop)
        formGui.Destroy()
        ModeSelectTab.Value := 4
        MainGui.Show()
    }
}

PcDetectKeyIntoEdit(ctrl) {
    ctrl.Value := ""
    ctrl.Focus()
    ih := InputHook("L1 T10")
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}", "-E")
    ih.KeyOpt("{LButton}{RButton}{MButton}{WheelUp}{WheelDown}", "-E")
    ih.Start()
    ToolTip("Press a key...", 0, 0)
    ih.Wait()
    ToolTip()
    if (ih.EndReason = "EndKey" && ih.EndKey != "")
        ctrl.Value := ih.EndKey
}

PcCalibrate() {
    global pcInvKey, pcDropKey, sheepInventoryKey

    PcWaitKey(line1, line2) {
        kwGui := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox", "Set Keys")
        kwGui.BackColor := "1A1A1A"
        kwGui.SetFont("s10 cDDDDDD Bold", "Segoe UI")
        kwGui.Add("Text", "x20 y18 w300 Center", line1)
        kwGui.SetFont("s9 c888888", "Segoe UI")
        kwGui.Add("Text", "x20 y42 w300 Center", line2)
        kwGui.SetFont("s9 c555555 Italic", "Segoe UI")
        kwGui.Add("Text", "x20 y64 w300 Center", "Press the key now  (20s timeout)")
        kwGui.Show("w340 h95")
        kwGui.Flash()

        ih := InputHook("T20")
        ih.KeyOpt("{All}", "E")
        ih.KeyOpt("{LButton}{RButton}{MButton}{WheelUp}{WheelDown}", "-E")
        ih.KeyOpt("{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}", "-E")
        ih.Start()
        ih.Wait()
        kwGui.Destroy()

        if (ih.EndReason = "Timeout" || ih.EndKey = "")
            return ""
        return ih.EndKey
    }

    ; ── Step 1: Inventory key ────────────────────────────────────────────────
    PcSetStatus("Open your inventory in ARK — we'll detect the key")
    newInvKey := PcWaitKey("Step 1 of 2  —  Inventory key", "Press the key you use to open your inventory")
    if (newInvKey = "") {
        PcSetStatus("Timed out — keys unchanged")
        MsgBox("Key detection timed out. Keys were not changed.", "Set Keys — Failed", "OK Icon!")
        MainGui.Show()
        return
    }

    ; ── Step 2: Drop key ────────────────────────────────────────────────────
    PcSetStatus("Now drop any item in ARK — we'll detect the drop key")
    newDropKey := PcWaitKey("Step 2 of 2  —  Drop key", "Press the key you use to drop items  (default G)")
    if (newDropKey = "") {
        PcSetStatus("Timed out — keys unchanged")
        MsgBox("Key detection timed out. Keys were not changed.", "Set Keys — Failed", "OK Icon!")
        MainGui.Show()
        return
    }

    global pcInvKey  := newInvKey
    global pcDropKey := newDropKey

    global sheepInventoryKey := pcInvKey
    try sheepInventoryInput.Value := pcInvKey

    try pcDropKeyTxt.Text := pcDropKey

    try {
        IniWrite(pcInvKey,  A_ScriptDir "\AIO_config.ini", "Popcorn", "InvKey")
        IniWrite(pcDropKey, A_ScriptDir "\AIO_config.ini", "Popcorn", "DropKey")
    }
    PcSetStatus("Keys saved   Inv=" pcInvKey "   Drop=" pcDropKey)
    MsgBox("Keys saved!`n`nInventory key:  " pcInvKey "`nDrop key:  " pcDropKey, "Set Keys — Saved", "OK Iconi")
    MainGui.Show()
}

; ════════════════════════════════════════════════════════════════════════════
; AUTO CRAFT FUNCTIONS
; ════════════════════════════════════════════════════════════════════════════

; ── Preset helpers ────────────────────────────────────────────────────────────
AcToggleSimple(cb, filter) {
    global acTimedElecBtn, acTimedAdvBtn, acTimedPolyBtn, acTimedFilterEdit, acTimedCustomCB
    global acGridElecBtn, acGridAdvBtn, acGridPolyBtn, acGridSparkBtn, acGridGunBtn, acGridFilterEdit, acGridCustomCB
    for btn in [acTimedElecBtn, acTimedAdvBtn, acTimedPolyBtn]
        btn.Value := 0
    acTimedFilterEdit.Text := ""
    acTimedCustomCB.Value := 0
    for btn in [acGridElecBtn, acGridAdvBtn, acGridPolyBtn, acGridSparkBtn, acGridGunBtn]
        btn.Value := 0
    acGridFilterEdit.Text := ""
    acGridCustomCB.Value := 0
}

AcToggleTimed(cb, filter, secs) {
    global acTimedSecsEdit
    if (cb.Value)
        acTimedSecsEdit.Value := secs
    global acSimpleSparkBtn, acSimpleGunBtn, acSimpleElecBtn, acSimpleAdvBtn, acSimplePolyBtn, acSimpleFilterEdit, acSimpleCustomCB
    global acGridElecBtn, acGridAdvBtn, acGridPolyBtn, acGridSparkBtn, acGridGunBtn, acGridFilterEdit, acGridCustomCB
    for btn in [acSimpleSparkBtn, acSimpleGunBtn, acSimpleElecBtn, acSimpleAdvBtn, acSimplePolyBtn]
        btn.Value := 0
    acSimpleFilterEdit.Text := ""
    acSimpleCustomCB.Value := 0
    for btn in [acGridElecBtn, acGridAdvBtn, acGridPolyBtn, acGridSparkBtn, acGridGunBtn]
        btn.Value := 0
    acGridFilterEdit.Text := ""
    acGridCustomCB.Value := 0
}

AcToggleGrid(cb, filter) {
    global acSimpleSparkBtn, acSimpleGunBtn, acSimpleElecBtn, acSimpleAdvBtn, acSimplePolyBtn, acSimpleFilterEdit, acSimpleCustomCB
    global acTimedElecBtn, acTimedAdvBtn, acTimedPolyBtn, acTimedFilterEdit, acTimedCustomCB
    for btn in [acSimpleSparkBtn, acSimpleGunBtn, acSimpleElecBtn, acSimpleAdvBtn, acSimplePolyBtn]
        btn.Value := 0
    acSimpleFilterEdit.Text := ""
    acSimpleCustomCB.Value := 0
    for btn in [acTimedElecBtn, acTimedAdvBtn, acTimedPolyBtn]
        btn.Value := 0
    acTimedFilterEdit.Text := ""
    acTimedCustomCB.Value := 0
}

AcBuildSimplePresets() {
    global acPresetNames := [], acPresetFilters := [], acPresetIdx := 1
    global acSimpleSparkBtn, acSimpleGunBtn, acSimpleElecBtn, acSimpleAdvBtn, acSimplePolyBtn
    global acSimpleFilterEdit
    pairs := [
        [acSimpleSparkBtn, "sparkpowder", "rk"],
        [acSimpleGunBtn,   "gunpowder",   "np"],
        [acSimpleElecBtn,  "electronics", "onic"],
        [acSimpleAdvBtn,   "advanced",    "m dv"],
        [acSimplePolyBtn,  "polymer",     "poly"]
    ]
    for , p in pairs {
        if (p[1].Value) {
            acPresetNames.Push(p[2])
            acPresetFilters.Push(p[3])
        }
    }
    for , _sf in acSimpleFilterList {
        if (acSimpleCustomCB.Value) {
            acPresetNames.Push("Custom [" _sf "]")
            acPresetFilters.Push(_sf)
        }
    }
    _sfCur := Trim(acSimpleFilterEdit.Text)
    if (acSimpleCustomCB.Value && _sfCur != "" && !AcListHas(acSimpleFilterList, _sfCur)) {
        acPresetNames.Push("Custom [" _sfCur "]")
        acPresetFilters.Push(_sfCur)
    }
}

AcBuildTimedPresets() {
    global acPresetNames := [], acPresetFilters := [], acPresetTimerSecs := [], acPresetIdx := 1
    global acTimedElecBtn, acTimedAdvBtn, acTimedPolyBtn
    global acTimedFilterEdit, acTimedSecsEdit
    pairs := [
        [acTimedElecBtn, "electronics", "onic", 200],
        [acTimedAdvBtn,  "advanced",    "m dv", 120],
        [acTimedPolyBtn, "polymer",     "poly", 210]
    ]
    for , p in pairs {
        if (p[1].Value) {
            acPresetNames.Push(p[2])
            acPresetFilters.Push(p[3])
            acPresetTimerSecs.Push(p[4])
        }
    }
    _tfSecs := IsNumber(acTimedSecsEdit.Value) ? Integer(acTimedSecsEdit.Value) : 120
    for , _tf in acTimedFilterList {
        if (acTimedCustomCB.Value) {
            acPresetNames.Push("Custom [" _tf "]")
            acPresetFilters.Push(_tf)
            acPresetTimerSecs.Push(_tfSecs)
        }
    }
    _tfCur := Trim(acTimedFilterEdit.Text)
    if (acTimedCustomCB.Value && _tfCur != "" && !AcListHas(acTimedFilterList, _tfCur)) {
        acPresetNames.Push("Custom [" _tfCur "]")
        acPresetFilters.Push(_tfCur)
        acPresetTimerSecs.Push(_tfSecs)
    }
}

AcBuildGridPresets() {
    global acPresetNames := [], acPresetFilters := [], acPresetIdx := 1
    global acGridElecBtn, acGridAdvBtn, acGridPolyBtn, acGridSparkBtn, acGridGunBtn
    global acGridFilterEdit
    pairs := [
        [acGridElecBtn,  "electronics", "onic"],
        [acGridAdvBtn,   "advanced",    "m dv"],
        [acGridPolyBtn,  "polymer",     "poly"],
        [acGridSparkBtn, "sparkpowder", "rk"],
        [acGridGunBtn,   "gunpowder",   "np"]
    ]
    for , p in pairs {
        if (p[1].Value) {
            acPresetNames.Push(p[2])
            acPresetFilters.Push(p[3])
        }
    }
    for , _gf in acGridFilterList {
        if (acGridCustomCB.Value) {
            acPresetNames.Push("Custom [" _gf "]")
            acPresetFilters.Push(_gf)
        }
    }
    _gfCur := Trim(acGridFilterEdit.Text)
    if (acGridCustomCB.Value && _gfCur != "" && !AcListHas(acGridFilterList, _gfCur)) {
        acPresetNames.Push("Custom [" _gfCur "]")
        acPresetFilters.Push(_gfCur)
    }
}

AcBuildCraftTooltip(mode) {
    global acPresetNames, acPresetIdx
    if (acPresetNames.Length = 0)
        return " AutoCraft: no presets selected"

    cur := acPresetNames[acPresetIdx]

    if (acPresetNames.Length = 1)
        return " " mode ": " cur "`nF at inventory  |  F1 = Stop"

    nextIdx := Mod(acPresetIdx, acPresetNames.Length) + 1
    nextLabel := acPresetNames[nextIdx]

    items := ""
    for i, n in acPresetNames {
        arrow := (i = acPresetIdx) ? "►" : " "
        items .= arrow " " n
        if (i < acPresetNames.Length)
            items .= "`n"
    }
    return " " mode ": " cur "  (Q → " nextLabel ")`n" items "`nF at inventory  |  F1 = Stop"
}

AcGetCurrentFilter() {
    global acPresetFilters, acPresetIdx
    if (acPresetFilters.Length = 0)
        return ""
    return acPresetFilters[acPresetIdx]
}

AcDoCraftAlreadyOpen(filter) {
    global arkwindow, widthmultiplier, heightmultiplier, acGridRunning, acExtraClicks
    CraftLog("DoCraftAlreadyOpen: waiting for inventory pixel, filter=[" filter "]")
    if !AcWaitForInventory() {
        CraftLog("DoCraftAlreadyOpen: pixel not found — aborting")
        if (!acGridRunning)
            ToolTip(" AutoCraft: waiting for inventory…", 0, 0)
        Sleep(500)
        return false
    }
    CraftLog("DoCraftAlreadyOpen: pixel found — proceeding")
    AcTakeAllIfEnabled(filter)
    CoordMode("Mouse","Screen")
    Click Round(1692*widthmultiplier) "," Round(267*heightmultiplier)
    Sleep(80)
    SendInput("{Ctrl Down}a{Ctrl Up}")
    Sleep(40)
    SendInput(filter)
    Sleep(150)
    Click Round(1664*widthmultiplier) "," Round(379*heightmultiplier)
    Sleep(50)
    Loop (16 + acExtraClicks) {
        Send("{a}")
        Sleep(30)
    }
    Sleep(50)
    if (acOcrEnabled && acGridRunning) {
        Sleep(200)
        AcOcrReadStorage()
    }
    ControlSend("{F}", , arkwindow)
    Sleep(300)
    return true
}
; ── Pixel wait helper ────────────────────────────────────────────────
WaitForPixel(x, y, color, tolerance := 10, timeoutMs := 6000, cMode := "Client") {
    CoordMode("Pixel", cMode)
    interval  := 16
    maxPolls  := timeoutMs // interval
    waitCount := 0
    _nfB12 := 0
    while (!NFPixelWait(x-2, y-2, x+2, y+2, color, tolerance, &_nfB12)) {
        Sleep(interval)
        waitCount++
        if (waitCount > maxPolls) {
            CoordMode("Pixel", "Client")
            return false
        }
    }
    CoordMode("Pixel", "Client")
    return true
}

AcWaitForInventory() {
    global widthmultiplier, heightmultiplier
    px1 := Round(1943 * widthmultiplier)
    py1 := Round(215  * heightmultiplier)
    diagCol := PxGet(px1, py1)
    CraftLog("WaitForInv: color at (" px1 "," py1 ") = " diagCol)
    result := WaitForPixel(px1, py1, "0xFFFFFF", 10, 6000, "Screen")
    if (!result) {
        diagCol2 := PxGet(px1, py1)
        CraftLog("WaitForInv: TIMEOUT — color now = " diagCol2)
    }
    return result
}

; ── Food/Water ────────────────────────────────────
AcFeedIfDue() {
    global acFeedLastMs, acFeedIntervalMs, arkwindow
    if (A_TickCount - acFeedLastMs < acFeedIntervalMs)
        return
    ControlSend("9", , arkwindow)
    Sleep(150)
    ControlSend("0", , arkwindow)
    Sleep(150)
    global acFeedLastMs := A_TickCount
}

AcTakeAllIfEnabled(filter) {
    global acTakeAllBtn, arkwindow, theirInvSearchBarX, theirInvSearchBarY, transferToMeButtonX, transferToMeButtonY
    if (!acTakeAllBtn.Value)
        return
    CraftLog("TakeAll: transferring [" filter "] to me")
    CoordMode("Mouse", "Screen")
    ControlClick("x" theirInvSearchBarX " y" theirInvSearchBarY, arkwindow)
    Sleep(30)
    Send(filter)
    Sleep(100)
    ControlClick("x" transferToMeButtonX " y" transferToMeButtonY, arkwindow)
    Sleep(150)
}

; ── Core craft action ────────────────────────
AcDoCraft(filter) {
    global arkwindow, widthmultiplier, heightmultiplier, acGridRunning, acExtraClicks
    _acStart := A_TickCount
    CraftLog("DoCraft: sending F, filter=[" filter "]")
    ControlSend("{F}", , arkwindow)
    if !AcWaitForInventory() {
        CraftLog("DoCraft: pixel not found — aborting +" (A_TickCount - _acStart) "ms")
        PerfLogPush("craft", _acStart, "timeout")
        if (!acGridRunning)
            ToolTip(" AutoCraft: waiting for inventory…", 0, 0)
        Sleep(500)
        return false
    }
    CraftLog("DoCraft: pixel found +" (A_TickCount - _acStart) "ms")
    AcTakeAllIfEnabled(filter)
    CoordMode("Mouse","Screen")
    Click Round(1692*widthmultiplier) "," Round(267*heightmultiplier)
    Sleep(80)
    SendInput("{Ctrl Down}a{Ctrl Up}")
    Sleep(40)
    SendInput(filter)
    Sleep(150)
    Click Round(1664*widthmultiplier) "," Round(379*heightmultiplier)
    Sleep(50)
    Loop (16 + acExtraClicks) {
        Send("{a}")
        Sleep(30)
    }
    Sleep(50)
    if (acOcrEnabled && acGridRunning) {
        Sleep(200)
        AcOcrReadStorage()
    }
    ControlSend("{F}", , arkwindow)
    Sleep(300)
    CraftLog("DoCraft: complete +" (A_TickCount - _acStart) "ms")
    PerfLogPush("craft", _acStart, "done")
    return true
}

; ── SIMPLE CRAFT ─────────────
AcStartSimple(*) {
    global acSimpleArmed, acTabActive, acSimpleFilterEdit
    AcBuildSimplePresets()
    if (acPresetNames.Length = 0) {
        ToolTip(" AutoCraft: choose a preset or enter a filter first", 0, 0)
        SetTimer(() => ToolTip(), -2000)
        return
    }
    global acSimpleArmed := !acSimpleArmed
    if (acSimpleArmed) {
        MainGui.Hide()
        global guiVisible := false
        ToolTip(AcBuildCraftTooltip("Simple"), 0, 0)
    } else {
        ToolTip()
        MainGui.Show()
        global guiVisible := true
    }
}

AcDoSimpleCraft() {
    global acSimpleFilterEdit, acTabActive, acSimpleArmed, acSimpleLoopBtn
    global acCraftLoopRunning, acRunning, acEarlyExit, acExtraClicks
    global acPresetNames, acPresetIdx
    global arkwindow, widthmultiplier, heightmultiplier
    if (!acSimpleArmed || !acTabActive)
        return
    filter := AcGetCurrentFilter()
    if (filter = "")
        return
    if (acSimpleLoopBtn.Value) {
        global acRunning := true
        global acEarlyExit := false
        global acCraftLoopRunning := true
        isMulti := (acPresetNames.Length > 1)
        stopKey := isMulti ? "Z" : "Q"
        if (isMulti)
            try Hotkey("$z", AcCraftLoopZStop, "On")
        CraftLog("SimpleLoop: sending F, filter=[" filter "] multi=" isMulti)
        ControlSend("{F}", , arkwindow)
        if !AcWaitForInventory() {
            CraftLog("SimpleLoop: inventory not found — aborting")
            global acRunning := false
            global acCraftLoopRunning := false
            if (isMulti)
                try Hotkey("$z", "Off")
            ToolTip(" AutoCraft: waiting for inventory…", 0, 0)
            Sleep(500)
            return
        }
        CoordMode("Mouse","Screen")
        Click Round(1692*widthmultiplier) "," Round(267*heightmultiplier)
        Sleep(80)
        SendInput("{Ctrl Down}a{Ctrl Up}")
        Sleep(40)
        SendInput(filter)
        Sleep(150)
        Click Round(1664*widthmultiplier) "," Round(379*heightmultiplier)
        Sleep(50)
        itemName := acPresetNames[acPresetIdx]
        ToolTip(" AutoCraft Loop: " itemName "`n" stopKey " = Stop", 0, 0)
        while (!acEarlyExit) {
            Loop (16 + acExtraClicks) {
                if (acEarlyExit)
                    break
                Send("{a}")
                Sleep(30)
            }
            Sleep(200)
        }
        ControlSend("{F}", , arkwindow)
        Sleep(300)
        CraftLog("SimpleLoop: stopped by " stopKey)
        if (isMulti)
            try Hotkey("$z", "Off")
        global acRunning := false
        global acEarlyExit := false
        global acCraftLoopRunning := false
        global acSimpleArmed := false
        ToolTip()
        MainGui.Show()
        global guiVisible := true
    } else {
        AcDoCraft(filter)
    }
}

AcCraftLoopZStop(thisHotkey) {
    global acCraftLoopRunning, acEarlyExit
    if (!acCraftLoopRunning)
        return
    global acEarlyExit := true
}

; ── SINGLE INVENTORY TIMED ───────────────────────────────────────────────────
AcStartTimed(*) {
    global acRunning, acEarlyExit, acTimedArmed, acTimedFilterEdit, acTimedSecsEdit
    global acActiveFilter, acActiveItemName, acActiveTimerSecs
    global acSimpleArmed, acGridArmed, acTimedFPressed
    global MainGui, guiVisible

    AcBuildTimedPresets()
    if (acPresetNames.Length = 0) {
        ToolTip(" AutoCraft: choose a preset or enter a filter first", 0, 0)
        SetTimer(() => ToolTip(), -2000)
        return
    }

    filter := AcGetCurrentFilter()
    secs := IsNumber(acTimedSecsEdit.Value) ? Integer(acTimedSecsEdit.Value) : 120
    global acActiveFilter    := filter
    global acActiveTimerSecs := secs
    global acActiveItemName  := acPresetNames[acPresetIdx]

    global acTimedFPressed := false
    if (acRunning) {
        global acTimedRestart := true   
        global acEarlyExit    := true
    } else {
        global acEarlyExit    := false
        global acTimedArmed   := false
        global acSimpleArmed  := false
        global acGridArmed    := false
        global acGridRunning  := false
        global acTimedArmed   := true
        MainGui.Hide()
        global guiVisible := false
        ToolTip(AcBuildCraftTooltip("Timed"), 0, 0)
    }
}

AcTimedLoop() {
    global acRunning, acEarlyExit, acActiveFilter, acActiveItemName, acActiveTimerSecs
    global acTimedArmed, acTimedFPressed, acTimedRestart
    global acPresetNames, acPresetFilters, acPresetTimerSecs, acPresetIdx
    global acTimedMultiActive, acTimedDeadlines
    global arkwindow, MainGui, guiVisible
    global acTimedLoopBtn, acCraftLoopRunning, acExtraClicks, widthmultiplier, heightmultiplier

    if (acTimedLoopBtn.Value) {
        global acCraftLoopRunning := true
        isMulti := (acPresetNames.Length > 1)
        stopKey := isMulti ? "Z" : "Q"
        if (isMulti)
            try Hotkey("$z", AcCraftLoopZStop, "On")
        CraftLog("TimedLoop(loop): crafting " acActiveItemName " filter=[" acActiveFilter "] multi=" isMulti)
        ControlSend("{F}", , arkwindow)
        if !AcWaitForInventory() {
            CraftLog("TimedLoop(loop): inventory not found — aborting")
            global acRunning := false
            global acCraftLoopRunning := false
            if (isMulti)
                try Hotkey("$z", "Off")
            ToolTip(" AutoCraft: waiting for inventory…", 0, 0)
            Sleep(500)
            return
        }
        CoordMode("Mouse","Screen")
        Click Round(1692*widthmultiplier) "," Round(267*heightmultiplier)
        Sleep(80)
        SendInput("{Ctrl Down}a{Ctrl Up}")
        Sleep(40)
        SendInput(acActiveFilter)
        Sleep(150)
        Click Round(1664*widthmultiplier) "," Round(379*heightmultiplier)
        Sleep(50)
        ToolTip(" AutoCraft Loop: " acActiveItemName "`n" stopKey " = Stop", 0, 0)
        while (!acEarlyExit) {
            Loop (16 + acExtraClicks) {
                if (acEarlyExit)
                    break
                Send("{a}")
                Sleep(30)
            }
            Sleep(200)
        }
        ControlSend("{F}", , arkwindow)
        Sleep(300)
        CraftLog("TimedLoop(loop): stopped by " stopKey)
        if (isMulti)
            try Hotkey("$z", "Off")
        global acRunning := false
        global acEarlyExit := false
        global acCraftLoopRunning := false
        ToolTip()
        MainGui.Show()
        global guiVisible := true
        return
    }

    if (acPresetNames.Length > 1) {
        AcTimedMultiLoop()
        return
    }

    ; ── Single preset: existing behavior ──────────────────────────────────────
    CraftLog("TimedLoop: crafting " acActiveItemName " filter=[" acActiveFilter "]")
    AcDoCraftAlreadyOpen(acActiveFilter)
    CraftLog("TimedLoop: craft done")

    if (acEarlyExit) {
        global acRunning   := false
        global acEarlyExit := false
        if (acTimedRestart) {
            global acTimedRestart  := false
            global acTimedArmed    := true
            global acTimedFPressed := false
            ToolTip(AcBuildCraftTooltip("Timed"), 0, 0)
        } else {
            ToolTip()
            MainGui.Show()
            global guiVisible := true
        }
        return
    }

    global acTimedFPressed := false
    deadline := A_TickCount + (acActiveTimerSecs * 1000)
    while (!acEarlyExit) {
        if (acTimedFPressed) {
            global acTimedFPressed := false
            CraftLog("TimedLoop: F pressed — crafting " acActiveItemName)
            AcDoCraftAlreadyOpen(acActiveFilter)
            if (acEarlyExit)
                break
            if (A_TickCount >= deadline)
                deadline := A_TickCount + (acActiveTimerSecs * 1000)
        }
        remaining := Ceil((deadline - A_TickCount) / 1000)
        if (remaining <= 0)
            status := "READY"
        else {
            m := remaining // 60
            s := Mod(remaining, 60)
            status := m ":" (s < 10 ? "0" : "") s
        }
        ToolTip("► " acActiveItemName "  " status "`nQ = Stop  |  F = Craft  |  F1 = Stop", 0, 0)
        Sleep(250)
    }

    global acRunning   := false
    global acEarlyExit := false
    if (acTimedRestart) {
        global acTimedRestart  := false
        global acTimedArmed    := true
        global acTimedFPressed := false
        ToolTip(AcBuildCraftTooltip("Timed"), 0, 0)
    } else {
        ToolTip()
        MainGui.Show()
        global guiVisible := true
    }
}

; ── Multi-preset timed loop ───────────────────────────────────────────────────
AcTimedMultiLoop() {
    global acRunning, acEarlyExit, acTimedArmed, acTimedFPressed, acTimedRestart
    global acPresetNames, acPresetFilters, acPresetTimerSecs, acPresetIdx
    global acTimedMultiActive, acTimedDeadlines
    global arkwindow, MainGui, guiVisible

    global acTimedMultiActive := true

    global acTimedDeadlines := []
    for i in acPresetNames
        acTimedDeadlines.Push(0)

    idx := acPresetIdx
    CraftLog("TimedMulti: crafting " acPresetNames[idx] " filter=[" acPresetFilters[idx] "]")
    AcDoCraftAlreadyOpen(acPresetFilters[idx])
    CraftLog("TimedMulti: craft done")

    if (acEarlyExit) {
        AcTimedMultiCleanup()
        return
    }

    acTimedDeadlines[idx] := A_TickCount + (acPresetTimerSecs[idx] * 1000)

    ; ── Persistent timer display loop ─────────────────────────────────────────
    global acTimedFPressed := false
    while (!acEarlyExit) {
        if (acTimedFPressed) {
            global acTimedFPressed := false
            idx := acPresetIdx
            CraftLog("TimedMulti: F pressed — crafting " acPresetNames[idx])
            AcDoCraftAlreadyOpen(acPresetFilters[idx])
            if (acEarlyExit)
                break

            if (acTimedDeadlines[idx] = 0 || A_TickCount >= acTimedDeadlines[idx])
                acTimedDeadlines[idx] := A_TickCount + (acPresetTimerSecs[idx] * 1000)
        }

        tt := ""
        for i, name in acPresetNames {
            arrow := (i = acPresetIdx) ? "►" : "  "
            if (acTimedDeadlines[i] = 0) {
                status := "--:--"
            } else {
                remaining := Ceil((acTimedDeadlines[i] - A_TickCount) / 1000)
                if (remaining <= 0) {
                    status := "READY"
                } else {
                    m := remaining // 60
                    s := Mod(remaining, 60)
                    status := m ":" (s < 10 ? "0" : "") s
                }
            }
            tt .= arrow " " name "  " status "`n"
        }
        tt .= "Q = Cycle  |  F = Craft  |  F1 = Stop"
        ToolTip(tt, 0, 0)

        pollEnd := A_TickCount + 250
        while (A_TickCount < pollEnd && !acEarlyExit) {
            if (GetKeyState("q", "P") && WinActive(arkwindow)) {
                global acPresetIdx := Mod(acPresetIdx, acPresetNames.Length) + 1
                while (GetKeyState("q", "P"))
                    Sleep(20)
                break
            }
            Sleep(30)
        }
    }

    AcTimedMultiCleanup()
}

AcTimedMultiCleanup() {
    global acRunning, acEarlyExit, acTimedArmed, acTimedFPressed
    global acTimedRestart, acTimedMultiActive
    global MainGui, guiVisible

    global acTimedMultiActive := false
    global acRunning   := false
    global acEarlyExit := false

    if (acTimedRestart) {
        global acTimedRestart  := false
        global acTimedArmed    := true
        global acTimedFPressed := false
        ToolTip(AcBuildCraftTooltip("Timed"), 0, 0)
    } else {
        ToolTip()
        MainGui.Show()
        global guiVisible := true
    }
}

; ── GRID WALK ────────────────────────────────────────────────────────────────
AcStartGrid(*) {
    global acRunning, acEarlyExit, acGridArmed, acGridFilterEdit
    global acColsEdit, acRowsEdit, acHWalkEdit, acVWalkEdit
    global acSimpleArmed, acTimedArmed, acGridRestart
    global MainGui, guiVisible

    AcBuildGridPresets()
    if (acPresetNames.Length = 0) {
        ToolTip(" AutoCraft: choose a preset or enter a filter first", 0, 0)
        SetTimer(() => ToolTip(), -2000)
        return
    }

    global acSimpleArmed      := false
    global acTimedArmed       := false
    global acCountOnlyActive  := false
    try DarkBtnText(acTallyBtn, "Count")
    if (acOcrResizing)
        AcOcrExitResize()

    if (acRunning) {
        global acGridRestart := true   
        global acEarlyExit   := true
    } else {
        global acEarlyExit   := false
        global acGridArmed   := true
        global acFeedLastMs  := A_TickCount
        MainGui.Hide()
        global guiVisible := false
        ToolTip(AcBuildCraftTooltip("Grid"), 0, 0)
    }
}

AcGridLoop() {
    global acRunning, acEarlyExit, acGridFilterEdit
    global acColsEdit, acRowsEdit, acHWalkEdit, acVWalkEdit
    global arkwindow, MainGui, guiVisible
    global acPresetNames, acPresetFilters, acPresetIdx

    filter := AcGetCurrentFilter()
    rows   := IsNumber(acColsEdit.Value)  ? Integer(acColsEdit.Value)  : 1   ; ↑↓ = forward rows (W/S)
    cols   := IsNumber(acRowsEdit.Value)  ? Integer(acRowsEdit.Value)  : 1   ; ←→ = side cols (A/D)
    vWalk  := IsNumber(acHWalkEdit.Value) ? Integer(acHWalkEdit.Value) : 850  ; ↑↓ walk delay
    hWalk  := IsNumber(acVWalkEdit.Value) ? Integer(acVWalkEdit.Value) : 850  ; ←→ walk delay
    backRatio := 1.53
    firstCraft := true
    AcOcrResetTotal()

    while (acRunning && !acEarlyExit) {
        stationIdx := 0
        r := 0
        while (r < rows && !acEarlyExit) {
            if (Mod(r, 2) = 0) {
                c := cols - 1
                while (c >= 0 && !acEarlyExit) {
                    filter := AcGetCurrentFilter()
                    global acOcrCurrentStation := stationIdx
                    if (firstCraft) {
                        AcDoCraftAlreadyOpen(filter)
                        firstCraft := false
                    } else {
                        AcDoCraft(filter)
                    }
                    stationIdx++
                    ToolTip(AcBuildCraftTooltip("Grid"), 0, 0)
                    AcFeedIfDue()
                    if (c > 0 && !acEarlyExit)
                        AcGridMove("{A down}", "{A up}", hWalk)
                    c--
                }
            } else {
                c := 0
                while (c < cols && !acEarlyExit) {
                    filter := AcGetCurrentFilter()
                    global acOcrCurrentStation := stationIdx
                    AcDoCraft(filter)
                    stationIdx++
                    ToolTip(AcBuildCraftTooltip("Grid"), 0, 0)
                    AcFeedIfDue()
                    if (c < cols - 1 && !acEarlyExit)
                        AcGridMove("{D down}", "{D up}", hWalk)
                    c++
                }
            }
            if (r < rows - 1 && !acEarlyExit)
                AcGridMove("{W down}", "{W up}", vWalk)
            r++
        }
        if (!acEarlyExit) {
            endedLeft := Mod(rows, 2) = 1
            if (endedLeft)
                Loop cols - 1
                    AcGridMove("{D down}", "{D up}", hWalk)
            if (rows > 1)
                AcGridMove("{S down}", "{S up}", Round(vWalk * (rows - 1) * backRatio))
        }
    }

    global acRunning     := false
    global acEarlyExit   := false
    global acGridRunning := false
    if (acGridRestart) {
        global acGridRestart := false
        global acGridRunning := true
        global acGridArmed   := true
        global acFeedLastMs  := A_TickCount
        AcOcrResetTotal()
        ToolTip(AcBuildCraftTooltip("Grid"), 0, 0)
    } else {
        ToolTip()
        ToolTip(,,,2)
        MainGui.Show()
        global guiVisible := true
    }
}

AcGridMove(kDown, kUp, delay) {
    global arkwindow, acEarlyExit
    if (acEarlyExit)
        return
    ControlSend(kDown, , arkwindow)
    Sleep(delay)
    ControlSend(kUp, , arkwindow)
    Sleep(150)
}

; ── Count Only mode ──────────────────────────────────────────────────────────
AcCountOnlyFPressed() {
    global arkwindow, acOcrTotal, acOcrStations, acCountOnlyActive
    if !WinExist(arkwindow)
        return
    WinActivate(arkwindow)
    Sleep(150)
    if !AcWaitForInventory() {
        CraftLog("CountOnly: inv pixel not found — skipping")
        return
    }
    Sleep(200)
    AcOcrReadStorageCountOnly()
    ToolTip(" Count Only: " acOcrStations " stations  |  Total: " AcOcrFormatTotal(), 0, 0)
    CraftLog("CountOnly: " acOcrStations " stations, total=" acOcrTotal)
}

AcOcrFormatTotal() {
    global acOcrTotal
    displayTotal := Floor(acOcrTotal)
    if (displayTotal >= 1000) {
        formatted := RegExReplace(String(displayTotal), "(\d)(?=(\d{3})+$)", "$1,")
    } else {
        formatted := String(displayTotal)
    }
    if (displayTotal >= 1000000) {
        mVal := Round(displayTotal / 1000000, 1)
        formatted .= " (" mVal "m)"
    }
    return formatted
}

AcOcrCopyTotal(*) {
    global acOcrTotal, acOcrStations
    formatted := AcOcrFormatTotal()
    A_Clipboard := formatted "  (" acOcrStations " stations)"
    ToolTip(" Copied: " formatted, 0, 0)
    SetTimer(() => ToolTip(), -1500)
}

; ── Grid OCR — overlay ────────────────────────────────────────────────────────
AcOcrShowOverlay() {
    global acOcrOverlay, acOcrSnapX, acOcrSnapY, acOcrSnapW, acOcrSnapH, acOcrResizing
    AcOcrHideOverlay()
    if (!acOcrResizing)
        return
    b := 2
    x := acOcrSnapX, y := acOcrSnapY, w := acOcrSnapW, h := acOcrSnapH
    strips := [
        [x-b, y-b, w+b*2, b],
        [x-b, y+h, w+b*2, b],
        [x-b, y,   b,     h],
        [x+w, y,   b,     h]
    ]
    acOcrOverlay := []
    for s in strips {
        g := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x20")
        g.BackColor := "00FFFF"
        WinSetTransparent(200, g)
        g.Show("x" s[1] " y" s[2] " w" s[3] " h" s[4] " NoActivate")
        acOcrOverlay.Push(g)
    }
}

AcOcrHideOverlay() {
    global acOcrOverlay
    if IsObject(acOcrOverlay) {
        for g in acOcrOverlay
            try g.Destroy()
        acOcrOverlay := ""
    }
}

; ── Grid OCR — enable checkbox ────────────────────────────────────────────────
AcOcrToggleEnabled(*) {
    global acOcrEnabled, acOcrEnableCB, acTallyBtn, acCountOnlyActive
    acOcrEnabled := acOcrEnableCB.Value
    if (acOcrEnabled && acCountOnlyActive) {
        global acCountOnlyActive := false
        DarkBtnText(acTallyBtn, "Count")
    }
    AcOcrSaveConfig()
}

AcTallyToggle(*) {
    global acCountOnlyActive, acTallyBtn, acOcrEnabled, acOcrEnableCB
    global acSimpleArmed, acTimedArmed, acGridArmed, acGridRunning
    global acRunning, acEarlyExit
    global acCountOnlyActive := !acCountOnlyActive
    if (acCountOnlyActive) {
        DarkBtnText(acTallyBtn, "Stop")
        acOcrEnabled := false
        acOcrEnableCB.Value := 0
        global acSimpleArmed := false
        global acTimedArmed  := false
        global acGridArmed   := false
        if (acRunning) {
            global acEarlyExit := true
        }
        AcOcrResetTotal()
        ToolTip(" Count: F at each inventory  |  Count again to stop", 0, 0)
        SetTimer(() => ToolTip(), -3000)
    } else {
        DarkBtnText(acTallyBtn, "Count")
        ToolTip(,,,2)
    }
}

; ── Grid OCR — resize mode ────────────────────────────────────────────────────
AcOcrToggleResize(*) {
    global acOcrResizing, acOcrResizeBtn
    if (acOcrResizing) {
        AcOcrExitResize()
        return
    }
    acOcrResizing := true
    DarkBtnText(acOcrResizeBtn, "Done")
    ToolTip(" OCR Resize: WASD=move  Arrows=size  Enter=done", 0, 0)
    AcOcrShowOverlay()
    try Hotkey("$Up",    AcOcrSizeUp,    "On")
    try Hotkey("$Down",  AcOcrSizeDown,  "On")
    try Hotkey("$Left",  AcOcrSizeLeft,  "On")
    try Hotkey("$Right", AcOcrSizeRight, "On")
    try Hotkey("$w",     AcOcrMoveUp,    "On")
    try Hotkey("$s",     AcOcrMoveDown,  "On")
    try Hotkey("$a",     AcOcrMoveLeft,  "On")
    try Hotkey("$d",     AcOcrMoveRight, "On")
    try Hotkey("$Enter", AcOcrResizeDone,"On")
}

AcOcrExitResize() {
    global acOcrResizing, acOcrResizeBtn
    acOcrResizing := false
    DarkBtnText(acOcrResizeBtn, "Resize")
    try Hotkey("$Up",    "Off")
    try Hotkey("$Down",  "Off")
    try Hotkey("$Left",  "Off")
    try Hotkey("$Right", "Off")
    try Hotkey("$w",     "Off")
    try Hotkey("$s",     "Off")
    try Hotkey("$a",     "Off")
    try Hotkey("$d",     "Off")
    try Hotkey("$Enter", "Off")
    AcOcrHideOverlay()
    AcOcrUpdateSizeTxt()
    AcOcrSaveConfig()
    ToolTip()
}

AcOcrResizeDone(*) {
    AcOcrExitResize()
}

AcOcrSizeUp(*) {
    global acOcrSnapH
    acOcrSnapH := Max(20, acOcrSnapH + 10)
    AcOcrShowOverlay()
    AcOcrUpdateSizeTxt()
}
AcOcrSizeDown(*) {
    global acOcrSnapH
    acOcrSnapH := Max(20, acOcrSnapH - 10)
    AcOcrShowOverlay()
    AcOcrUpdateSizeTxt()
}
AcOcrSizeRight(*) {
    global acOcrSnapW
    acOcrSnapW := Max(40, acOcrSnapW + 20)
    AcOcrShowOverlay()
    AcOcrUpdateSizeTxt()
}
AcOcrSizeLeft(*) {
    global acOcrSnapW
    acOcrSnapW := Max(40, acOcrSnapW - 20)
    AcOcrShowOverlay()
    AcOcrUpdateSizeTxt()
}
AcOcrMoveUp(*) {
    global acOcrSnapY
    acOcrSnapY := Max(0, acOcrSnapY - 10)
    AcOcrShowOverlay()
}
AcOcrMoveDown(*) {
    global acOcrSnapY
    acOcrSnapY := Min(A_ScreenHeight - acOcrSnapH, acOcrSnapY + 10)
    AcOcrShowOverlay()
}
AcOcrMoveLeft(*) {
    global acOcrSnapX
    acOcrSnapX := Max(0, acOcrSnapX - 10)
    AcOcrShowOverlay()
}
AcOcrMoveRight(*) {
    global acOcrSnapX
    acOcrSnapX := Min(A_ScreenWidth - acOcrSnapW, acOcrSnapX + 10)
    AcOcrShowOverlay()
}

AcOcrUpdateSizeTxt() {
    global acOcrResizeBtn, acOcrSnapW, acOcrSnapH, acOcrSnapX, acOcrSnapY, acOcrResizing
    if (acOcrResizing)
        try DarkBtnText(acOcrResizeBtn, acOcrSnapW "x" acOcrSnapH)
}

; ── Grid OCR — INI persistence ────────────────────────────────────────────────
AcOcrSaveConfig() {
    global acOcrEnabled, acOcrSnapX, acOcrSnapY, acOcrSnapW, acOcrSnapH
    configFile := A_ScriptDir "\AIO_config.ini"
    IniWrite(acOcrEnabled ? 1 : 0, configFile, "GridOCR", "Enabled")
    IniWrite(acOcrSnapX, configFile, "GridOCR", "X")
    IniWrite(acOcrSnapY, configFile, "GridOCR", "Y")
    IniWrite(acOcrSnapW, configFile, "GridOCR", "W")
    IniWrite(acOcrSnapH, configFile, "GridOCR", "H")
}

AcOcrLoadConfig() {
    global acOcrEnabled, acOcrSnapX, acOcrSnapY, acOcrSnapW, acOcrSnapH
    global acOcrEnableCB
    configFile := A_ScriptDir "\AIO_config.ini"
    if FileExist(configFile) {
        try {
            v := IniRead(configFile, "GridOCR", "Enabled", "0")
            acOcrEnabled := (v = "1")
            sx := IniRead(configFile, "GridOCR", "X", "")
            sy := IniRead(configFile, "GridOCR", "Y", "")
            sw := IniRead(configFile, "GridOCR", "W", "")
            sh := IniRead(configFile, "GridOCR", "H", "")
            if (sx != "")
                acOcrSnapX := Integer(sx)
            if (sy != "")
                acOcrSnapY := Integer(sy)
            if (sw != "" && Integer(sw) >= 40)
                acOcrSnapW := Integer(sw)
            if (sh != "" && Integer(sh) >= 20)
                acOcrSnapH := Integer(sh)
        }
    }
    try acOcrEnableCB.Value := acOcrEnabled
    AcOcrUpdateSizeTxt()
}

; ── Grid OCR — read storage count ─────────────────────────────────────────────
AcOcrReadStorage() {
    global acOcrSnapX, acOcrSnapY, acOcrSnapW, acOcrSnapH
    global acOcrTotal, acOcrStations, acOcrStationMap, acOcrCurrentStation

    slotCount := AcOcrReadSlots()
    if (slotCount < 0)
        return

    sKey := acOcrCurrentStation
    if (acOcrStationMap.Has(sKey)) {
        prevSlots := acOcrStationMap[sKey]
        delta := slotCount - prevSlots
        if (delta < 0)
            delta := 0
        acOcrStationMap[sKey] := slotCount
        items := delta * 100
        acOcrTotal += items
        CraftLog("GridOCR: station " sKey " slots=" slotCount " prev=" prevSlots " delta=" delta " ×100=" items " → total=" acOcrTotal)
    } else {
        acOcrStationMap[sKey] := slotCount
        items := slotCount * 100
        acOcrTotal += items
        acOcrStations++
        CraftLog("GridOCR: station " sKey " slots=" slotCount " (first visit) ×100=" items " → total=" acOcrTotal " stations=" acOcrStations)
    }
    AcOcrUpdateCountTooltip()
}

AcOcrReadStorageCountOnly() {
    global acOcrSnapX, acOcrSnapY, acOcrSnapW, acOcrSnapH
    global acOcrTotal, acOcrStations

    slotCount := AcOcrReadSlots()
    if (slotCount < 0)
        return

    items := slotCount * 100
    acOcrTotal += items
    acOcrStations++
    CraftLog("CountOnly: station #" acOcrStations " slots=" slotCount " ×100=" items " → total=" acOcrTotal)
    AcOcrUpdateCountTooltip()
}

AcOcrReadSlots() {
    global acOcrSnapX, acOcrSnapY, acOcrSnapW, acOcrSnapH
    attempts := 0
    bestVal := -1
    while (attempts < 3) {
        attempts++
        try {
            ocrText := OCR.FromRect(acOcrSnapX, acOcrSnapY, acOcrSnapW, acOcrSnapH, {scale: 3}).Text
            cleaned := RegExReplace(ocrText, "[oO]", "0")
            cleaned := RegExReplace(cleaned, "[Il|]", "1")
            cleaned := RegExReplace(cleaned, "s(?=\d)", "5")
            cleaned := RegExReplace(cleaned, ",", "")
            if RegExMatch(cleaned, "(-?\d+)\s*/\s*(\d+)", &m) {
                val := Integer(m[1])
                if (val < 0)
                    val := 0
                if (val = 0 && StrLen(m[1]) > 1) {
                    CraftLog("GridOCR: suspicious 0 from [" m[1] "] (" StrLen(m[1]) " digits) — retrying  raw=[" ocrText "]")
                    Sleep(80)
                    continue
                }
                CraftLog("GridOCR: raw=[" ocrText "] cleaned=[" cleaned "] val=" val "/" m[2] " attempt " attempts)
                return val
            }
            if RegExMatch(cleaned, "(\d+)", &m) {
                val := Integer(m[1])
                CraftLog("GridOCR: raw=[" ocrText "] cleaned=[" cleaned "] val=" val " (no slash) attempt " attempts)
                return val
            }
            CraftLog("GridOCR: no number found raw=[" ocrText "] cleaned=[" cleaned "] attempt " attempts)
        } catch as e {
            CraftLog("GridOCR: OCR failed attempt " attempts " — " e.Message)
        }
        Sleep(100)
    }
    CraftLog("GridOCR: no valid reading after " attempts " attempts")
    return -1
}

AcOcrUpdateCountTooltip() {
    global acOcrTotal, acOcrStations, acOcrEnabled
    if (!acOcrEnabled) {
        ToolTip(,,,2)
        return
    }
    displayTotal := Floor(acOcrTotal)
    if (displayTotal >= 1000) {
        formatted := RegExReplace(String(displayTotal), "(\d)(?=(\d{3})+$)", "$1,")
    } else {
        formatted := String(displayTotal)
    }
    if (displayTotal >= 1000000) {
        mVal := Round(displayTotal / 1000000, 1)
        formatted .= " (" mVal "m)"
    }
    ToolTip(" Storage: " formatted "  (" acOcrStations " stations)", 0, 58, 2)
}

AcOcrResetTotal() {
    global acOcrTotal := 0
    global acOcrStations := 0
    global acOcrStationMap := Map()
    global acOcrCurrentStation := 0
}

; ── Grid Walk help popup ──────────────────────────────────────────────────────
AcShowGridHelp(*) {
    global acHelpGui
    if (IsSet(acHelpGui) && acHelpGui != "") {
        try acHelpGui.Destroy()
        global acHelpGui := ""
    }
    acHelpGui := Gui("+AlwaysOnTop +Owner", "Craft Help")
    acHelpGui.BackColor := "1A1A1A"

    acHelpGui.SetFont("s10 cFF4444 Bold", "Segoe UI")
    acHelpGui.Add("Text", "x15 y15 w315", "Quick Guide")

    acHelpGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
    acHelpGui.Add("Text", "x15 y40 w315", "Simple Craft")
    acHelpGui.SetFont("s9 cFFFFFF", "Segoe UI")
    acHelpGui.Add("Text", "x15 y+2 w315", "Pick preset or type filter → START → F on inventory")

    acHelpGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
    acHelpGui.Add("Text", "x15 y+10 w315", "Inventory Timed")
    acHelpGui.SetFont("s9 cFFFFFF", "Segoe UI")
    acHelpGui.Add("Text", "x15 y+2 w315", "Same as Simple but crafts on a timer with countdown")

    acHelpGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
    acHelpGui.Add("Text", "x15 y+10 w315", "Grid Walk")
    acHelpGui.SetFont("s9 cFFFFFF", "Segoe UI")
    acHelpGui.Add("Text", "x15 y+2 w315",
        "Start at bottom-right inventory`n"
        . "↑↓ = rows of inventories in front of you  |  ←→ = amount of inventories in your row (incl. start pos)`n"
        . "Walk delay = ms to move between inventories`n"
        . "Try 850 for both to get an idea`n`n"
        . "Use ladder to lock your camera`n"
        . "Default setings to run Megalabs at rivercrafting ↑↓ 1 row, ←→ 11 inventories, walk ↑↓ 0, ←→ 850")

    acHelpGui.SetFont("s9 cFF4444 Bold", "Segoe UI")
    acHelpGui.Add("Text", "x15 y+10 w315", "Take-All")
    acHelpGui.SetFont("s9 cFFFFFF", "Segoe UI")
    acHelpGui.Add("Text", "x15 y+2 w315", "Transfers matching items from their inv before each craft")

    acHelpGui.SetFont("s9 cFFFFFF Bold", "Segoe UI")
    closeBtn := acHelpGui.Add("Button", "x130 y+14 w110 h26", "Got it")
    closeBtn.OnEvent("Click", (*) => acHelpGui.Destroy())
    acHelpGui.OnEvent("Close", (*) => acHelpGui.Destroy())
    acHelpGui.Show("AutoSize")
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; HOTKEYS -

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

^Tab:: {
    global ModeSelectTab, guiVisible, MainGui
    if (!guiVisible) {
        MainGui.Show("NoActivate")
        global guiVisible := true
    }
    currentTab := ModeSelectTab.Value
    newTab := Mod(currentTab, 8) + 1
    ModeSelectTab.Value := newTab
    tabNames := ["JoinSim", "Magic F", "AutoLvL", "Popcorn", "Sheep", "Craft", "Macro", "Misc"]
    ToolTip(" Tab: " tabNames[newTab], 0, 0)
    SetTimer(() => ToolTip(), -1500)
}

^+Tab:: {
    global ModeSelectTab, guiVisible, MainGui
    if (!guiVisible) {
        MainGui.Show("NoActivate")
        global guiVisible := true
    }
    currentTab := ModeSelectTab.Value
    newTab := Mod(currentTab - 2, 8) + 1
    ModeSelectTab.Value := newTab
    tabNames := ["JoinSim", "Magic F", "AutoLvL", "Popcorn", "Sheep", "Craft", "Macro", "Misc"]
    ToolTip(" Tab: " tabNames[newTab], 0, 0)
    SetTimer(() => ToolTip(), -1500)
}

$[:: {
    global obDownloadRunning, obDownItemDelayMs, obDownItemDelayMin, obDownItemDelayStep, obLog
    if (!obDownloadRunning)
        return
    obDownItemDelayMs := Max(obDownItemDelayMin, obDownItemDelayMs - obDownItemDelayStep)
    msg := "[SPEED] interval → " obDownItemDelayMs "ms (faster)"
    obLog.Push(msg)
    OBDownSetStatus("Interval: " obDownItemDelayMs "ms (faster)")
}

$]:: {
    global obDownloadRunning, obDownItemDelayMs, obDownItemDelayMax, obDownItemDelayStep, obLog
    if (!obDownloadRunning)
        return
    obDownItemDelayMs := Min(obDownItemDelayMax, obDownItemDelayMs + obDownItemDelayStep)
    msg := "[SPEED] interval → " obDownItemDelayMs "ms (slower)"
    obLog.Push(msg)
    OBDownSetStatus("Interval: " obDownItemDelayMs "ms (slower)")
}


$F4:: {
    if (autoclicking) {
        global autoclicking := false
        SetTimer(AutoclickLoop, 0)
        try Hotkey("$[", "Off")
        try Hotkey("$]", "Off")
        ToolTip()
    }
    TrayTip(" AIO stopped running"," AIO++")
    HideTrayTipTimer(2000)
    ExitApp
}

$F2:: {
    ToggleOvercapScript()
}

$F5:: {
    global lastDebugContext := "ini"
    ApplyIni()
}

$F3:: {
    if (macroTabActive) {
        MacroPlaySelected()
        return
    }
    if (macroArmed || macroPlaying) {
        if (macroPlaying)
            MacroStopPlay()
        global macroArmed := false
        MacroRegisterHotkeys(false)
        MainGui.Show("x177 y330")
        global guiVisible := true
        ToolTip()
        return
    }
    global lastDebugContext := "feed"
    QuickFeedCycle()
}

$F1:: {
    if (guidedRecording) {
        if (guidedReRecordIdx > 0)
            GuidedReRecordStop()
        else
            GuidedStopRecord()
        return
    }
    if (macroRecording) {
        MacroStopRecord()
        return
    }
    if (comboRunning) {
        global comboRunning := false
    }
    if (macroPlaying) {
        MacroStopPlay()
    }
    if (macroTuning) {
        global macroTuning := false
        global macroPlaying := false
        MacroSaveIfDirty()
    }
    if (!guiVisible) {
        global pcEarlyExit := true
        global pcF1Abort   := true
        if (pcMode > 0 || pcF10Step > 0) {
            global pcMode := 0
            global pcF10Step := 0
            global pcAllCustomActive := false
            global pcAllNoFilter := false
            global pcGrinderPoly := false, pcGrinderMetal := false, pcGrinderCrystal := false
            global pcPresetRaw := false, pcPresetCooked := false
            PcRegisterSpeedHotkeys(false)
            try pcF10StatusTxt.Text := ""
            try pcF10SpeedTxt.Text  := ""
            PcUpdateUI()
        }
        if (AutoSimCheck) {
            global AutoSimCheck := false
            SetTimer(SimLoop, 0)
            global JL := 0
            DarkBtnText(StartSimButton, "Start")
            global simcyclestatus := "Idle"
            SimStatusText.Value := ""
            TaskbarRestore()
        }
        if (autoclicking) {
            global autoclicking := false
            SetTimer(AutoclickLoop, 0)
            try Hotkey("$[", "Off")
            try Hotkey("$]", "Off")
        }
        if (pinPollActive) {
            SetTimer(PinPollCheck, 0)
            global pinPollActive := false
        }
        global runMagicFScript       := false
        global magicFPresetIdx       := 1
        global gmkMode               := "off"
        try gmkStatusTxt.Text        := ""
        try Hotkey("$z", "Off")
        global acSimpleArmed         := false
        global acTimedArmed          := false
        global acGridArmed           := false
        global acGridRunning         := false
        global acCountOnlyActive     := false
        try DarkBtnText(acTallyBtn, "Count")
        global acPresetIdx           := 1
        global acTimedMultiActive    := false
        if (acOcrResizing)
            AcOcrExitResize()
        ToolTip(,,,2)
        if (acRunning) {
            global acEarlyExit := true
            global acRunning   := false
            global acCraftLoopRunning := false
        }
        global runAutoLvlScript      := false
        try Hotkey("$q", "Off")
        try DarkBtnText(StartAutoLvlButton, "START")
        global runClaimAndNameScript := false
        global runNameAndSpayScript  := false
        ImprintStopAll()
        try DarkBtnText(imprintStartBtn, "Start")
        try imprintStatusTxt.Text := "Press Start then R=read Q=auto"
        global qhArmed               := false
        global qhRunning             := false
        global qhMode                := 0
        global depoEggsActive        := false
        global depoEmbryoActive      := false
        global depoCycle              := []
        global depoCycleIdx           := 0
        try qhAllBtn.Value           := 0
        try qhSingleBtn.Value        := 0
        try Hotkey("$[", "Off")
        try Hotkey("$]", "Off")
        global quickFeedMode         := 0
        global overcapAccumMs        := 0
        OBStopAll(false)
        OBDownStopAll(false)
        if (runOvercapScript)
            StopOvercapScript()
        if (runMammothScript)
            StopMammothScript()
        if (macroPlaying)
            MacroStopPlay()
        if (macroTuning) {
            global macroTuning := false
            global macroPlaying := false
            MacroSaveIfDirty()
        }
        global macroArmed := false
        MacroDisarmPopcornF()
        MacroRegisterHotkeys(ModeSelectTab.Value = 1 || ModeSelectTab.Value = 7)
        MainGui.Show("x177 y330")
        Sleep(100)
        MouseMove(177 + 225, 330 + 204, 0)
        ToolTip()
        ToolTip(,,,1)
        ToolTip(,,,2)
        global guiVisible := true
    } else {
        if (obUploadMode = 3 && obUploadArmed) {
            global guiVisible := false
            MainGui.Hide()
            nextSvr := ""
            try nextSvr := ServerNumberEdit.Text
            customSvr := ""
            if (nextSvr != "" && nextSvr != "2386")
                customSvr := nextSvr
            if (customSvr = "")
                nextLabel := "2386"
            else
                nextLabel := customSvr
            note := ""
            for entry in svrList {
                if (entry.num = nextSvr && entry.note != "") {
                    note := " (" entry.note ")"
                    break
                }
            }
            ToolTip(" Upload Char armed → " nextLabel note "`n ↑↓ cycle servers  |  F at transmitter  |  F6 = cycle/off", 0, 0)
            OBCharRegisterSvrKeys()
            return
        }
        global macroArmed := false
        MacroRegisterHotkeys(false)
        global guiVisible := false
        MainGui.Hide
        if (gmkMode != "off")
            ToolTip(GmkBuildTooltip(), 0, 0)
    }
}

~$F:: {
    if (!WinActive(arkwindow))
        return
    if (macroHotkeysLive && macroArmed && macroSelectedIdx >= 1 && macroSelectedIdx <= macroList.Length) {
        sel := macroList[macroSelectedIdx]
        if (sel.hotkey = "f" && sel.type != "guided" && sel.type != "combo") {
            MacroHotkeyHandler(macroSelectedIdx, "~$f")
            return
        }
    }
    if (acCountOnlyActive && !acRunning) {
        global lastDebugContext := "craft"
        SetTimer(AcCountOnlyFPressed, -1)
        return
    }
    if (acSimpleArmed && acTabActive && !acRunning) {
        global lastDebugContext := "craft"
        AcDoSimpleCraft()
        return
    }
    if (acTimedArmed) {
        global lastDebugContext := "craft"
        global acTimedArmed := false
        global acRunning    := true
        global acTimedFPressed := false
        CraftLog("F pressed — Inventory Timed armed, launching loop")
        SetTimer(AcTimedLoop, -1)
        return
    }
    if (acRunning && acActiveFilter != "" && !acGridArmed) {
        global acTimedFPressed := true
        return
    }
    if (acGridArmed) {
        global lastDebugContext := "craft"
        global acGridArmed := false
        global acGridRunning := true
        global acRunning   := true
        CraftLog("F pressed — Grid Walk armed, launching loop")
        ToolTip(AcBuildCraftTooltip("Grid"), 0, 0)
        SetTimer(AcGridLoop, -1)
        return
    }
    if (runMagicFScript) {
        global lastDebugContext := "magicf"
        magicFpressed()
    } else if (quickFeedMode > 0) {
        global lastDebugContext := "feed"
        QuickFeedFPressed()
    } else if (gmkMode != "off") {
        global lastDebugContext := "gmk"
        GmkFPressed()
    } else if (runAutoLvlScript) {
        global lastDebugContext := "autolvl"
        autoLvLFpressed()
    } else if (depoCycleIdx > 0 && depoCycle.Length > 0 && depoCycle[depoCycleIdx].filter != "") {
        global lastDebugContext := "depo"
        DepoFPressed()
    } else if (qhArmed) {
        global lastDebugContext := "quickhatch"
        QhFPressed()
    } else if (sheepAutoLvlActive) {
        global lastDebugContext := "sheep"
        SheepAutoLvlFPressed()
    } else if (obUploadArmed) {
        global lastDebugContext := "ob_upload"
        OBFPressed()
    } else if (obDownloadArmed) {
        global lastDebugContext := "ob_download"
        OBDownFPressed()
    } else if (pcMode > 0 && !pcRunning && (pcTabActive || pcF10Step > 0) && !sheepRunning && !sheepAutoLvlActive) {
        global lastDebugContext := "popcorn"
        PcFPressed()
    }
}

~$E:: {
    if (!WinActive(arkwindow))
        return
    if (runNameAndSpayScript) {
        global lastDebugContext := "nameandspay"
        nameAndSpayEpressed()
    } else if (runClaimAndNameScript) {
        claimAndNameEpressed()
    }
    if (!(A_PriorHotkey = A_ThisHotkey && A_TimeSincePriorHotkey < 300))
        PinStartPoll()
}

$F6:: {
    global lastDebugContext := "ob_upload"
    OBUploadCycle()
}

$F7:: {
    global lastDebugContext := "ob_download"
    OBDownloadCycle()
}

~F8:: {
    if (ModeSelectTab.Value = 1 || true) {
        ToggleMammothScript()
    }
}

$F9:: {
    global lastDebugContext := "autoclick"
    global autoclicking, autoclickInterval, guiVisible, arkwindow, pcRunning, pcF10Step
    global autoclicking := !autoclicking
    if (autoclicking) {
        if !WinExist(arkwindow) {
            MsgBox("ARK window not found. Start the game first.", "BG Autoclick", "OK Icon!")
            global autoclicking := false
            return
        }
        if (pcRunning) {
            global pcEarlyExit := true
            global pcF10Step   := 0
            global pcMode      := 0
            PcRegisterSpeedHotkeys(false)
            PcSetStatus("Stopped for autoclicker")
            Sleep(400)
        }
        MainGui.Hide()
        global guiVisible := false
        WinActivate(arkwindow)
        AutoclickUpdateTooltip()
        SetTimer(AutoclickLoop, autoclickInterval)
        try Hotkey("$[", AutoclickSlower, "On")
        try Hotkey("$]", AutoclickFaster, "On")
        PcLog("Autoclicker: started at " autoclickInterval "ms")
    } else {
        SetTimer(AutoclickLoop, 0)
        try Hotkey("$[", "Off")
        try Hotkey("$]", "Off")
        ToolTip(" AUTOCLICK Off", 0, 0)
        SetTimer(() => (ToolTip(), OBCharRestoreTooltip()), -1500)
        if (!guiVisible) {
            MainGui.Show("NoActivate")
            global guiVisible := true
        }
        PcLog("Autoclicker: stopped")
    }
}

$F10:: {
    global lastDebugContext := "popcorn"
    PcF10Cycle()
}

; ── F10 Popcorn cycle ────────────────────────────

AutoclickLoop() {
    global autoclicking, arkwindow
    if (!autoclicking || !WinExist(arkwindow))
        return
    SetControlDelay(-1)
    ControlClick("x1 y1", arkwindow, , "Left", , "Pos")
}

AutoclickUpdateTooltip() {
    global autoclickInterval
    ToolTip(" AUTOCLICK ON  (Interval: " autoclickInterval "ms)`n[ = Slower   ] = Faster`nF9 = Stop", 0, 0)
}

AutoclickSlower(thisHotkey) {
    global autoclicking, autoclickInterval, autoclickIntervalStep
    global autoclickInterval := autoclickInterval + autoclickIntervalStep
    if (autoclicking) {
        SetTimer(AutoclickLoop, 0)
        SetTimer(AutoclickLoop, autoclickInterval)
        AutoclickUpdateTooltip()
    }
}

AutoclickFaster(thisHotkey) {
    global autoclicking, autoclickInterval, autoclickIntervalStep, autoclickMinInterval
    global autoclickInterval := Max(autoclickMinInterval, autoclickInterval - autoclickIntervalStep)
    if (autoclicking) {
        SetTimer(AutoclickLoop, 0)
        SetTimer(AutoclickLoop, autoclickInterval)
        AutoclickUpdateTooltip()
    }
}
PcShowArmedTooltip() {
    global pcF10Step, pcMode
    if (pcF10Step > 0)
        ToolTip(PcBuildF10Tooltip(), 0, 0)
    else if (pcMode > 0)
        ToolTip(PcBuildTooltip(), 0, 0)
    else
        ToolTip()
}

PcBuildF10Tooltip() {
    global pcF10Step, pcSpeedNames, pcSpeedMode
    static f10Names := Map(
        1, "All (no filter)",
        2, "Transfer"
    )
    if (!f10Names.Has(pcF10Step))
        return ""

    line1 := " F10 Quick: " f10Names[pcF10Step] "  |  F at inventory  |  Q = Stop  |  F1 = Stop/UI"
    line2 := "Z = Change drop speed  |  Speed: " pcSpeedNames[pcSpeedMode]
    return line1 "`n" line2
}

PcF10Cycle() {
    global pcF10Step, pcMode, pcCustomFilter, pcForgeTransferAll
    global pcGrinderPoly, pcGrinderMetal, pcGrinderCrystal, pcPresetRaw, pcPresetCooked
    global obUploadArmed, obUploadRunning, obDownloadArmed, obDownloadRunning
    global gmkMode, gmkStatusTxt

    savedDrop := ""
    try savedDrop := IniRead(A_ScriptDir "\AIO_config.ini", "Popcorn", "DropKey", "")
    if (savedDrop = "" && pcF10Step = 0) {
        PcShowSetKeysPrompt()
        return
    }

    if (obUploadArmed || obUploadRunning)
        OBStopAll(false)
    if (obDownloadArmed || obDownloadRunning)
        OBDownStopAll(false)
    if (gmkMode != "off") {
        global gmkMode := "off"
        try gmkStatusTxt.Value := ""
    }

    global pcF10Step := Mod(pcF10Step + 1, 3)
    global pcGrinderPoly := false, pcGrinderMetal := false, pcGrinderCrystal := false
    global pcPresetRaw := false, pcPresetCooked := false
    global pcAllCustomActive := false, pcAllNoFilter := false

    switch pcF10Step {
        case 0:
            global pcMode := 0, pcCustomFilter := ""
            try pcF10StatusTxt.Text := ""
            try pcF10SpeedTxt.Text  := ""
            ToolTip(" Popcorning Off", 0, 0)
            SetTimer(() => ToolTip(), -1500)
        case 1:
            global pcMode := 3, pcCustomFilter := ""
            global pcForgeTransferAll := false
            try pcF10StatusTxt.Text := "All"
            PcUpdateF10Speed()
            PcShowArmedTooltip()
        case 2:
            global pcMode := 3, pcCustomFilter := ""
            global pcForgeTransferAll := true
            try pcF10StatusTxt.Text := "+Transfer"
            PcUpdateF10Speed()
            PcShowArmedTooltip()
    }
    PcRegisterSpeedHotkeys(pcF10Step != 0)
    PcUpdateUI()
}

PcRegisterSpeedHotkeys(enable) {
    global autoclicking
    if (enable) {
        try Hotkey("$z", PcHotkeySpeed, "On")
        if (!autoclicking) {
            try Hotkey("$[", PcHotkeyBracketLeft, "On")
            try Hotkey("$]", PcHotkeyBracketRight, "On")
        }
    } else {
        try Hotkey("$z", "Off")
        if (!autoclicking) {
            try Hotkey("$[", "Off")
            try Hotkey("$]", "Off")
        }
    }
}

; ── Popcorn hotkeys ────────────────────────────────────────────────────────────

PcHotkeySpeed(thisHotkey) {
    global pcSpeedMode, pcSpeedNames, pcSpeedTxt, pcF10SpeedTxt, arkwindow, MainGui
    if (!WinActive(arkwindow) && !WinActive("ahk_id " MainGui.Hwnd)) {
        Send("{" SubStr(thisHotkey, 2) "}")
        return
    }
    PcLog("Z speed cycle: " pcSpeedMode " → " Mod(pcSpeedMode+1,3))
    pcSpeedMode := Mod(pcSpeedMode + 1, 3)
    PcApplySpeed()
    PcSaveSpeedToINI()
    pcSpeedTxt.Text    := pcSpeedNames[pcSpeedMode] " [Z]"
    pcF10SpeedTxt.Text := pcSpeedNames[pcSpeedMode]
    speedColors := Map(0,"FFAA00", 1,"FF4444", 2,"FF2222")
    pcF10SpeedTxt.Opt("c" speedColors[pcSpeedMode])
    PcShowArmedTooltip()
}

PcHotkeyBracketLeft(thisHotkey) {
    if (!WinActive(arkwindow) && !WinActive("ahk_id " MainGui.Hwnd)) {
        Send("[")
        return
    }
    PcAdjustDropSleep(-1)
}

PcHotkeyBracketRight(thisHotkey) {
    if (!WinActive(arkwindow) && !WinActive("ahk_id " MainGui.Hwnd)) {
        Send("]" )
        return
    }
    PcAdjustDropSleep(1)
}


~$Q:: {
    stoppedAny := false

    if (imprintScanning) {
        ImprintToggleAutoMode()
        return
    }

    if (macroHotkeysLive && macroPlaying && macroActiveIdx > 0 && macroActiveIdx <= macroList.Length) {
        activeMacro := macroList[macroActiveIdx]
        if (activeMacro.type = "repeat" && activeMacro.repeatKeys.Length > 1) {
            global macroRepeatKeyIdx := Mod(macroRepeatKeyIdx, activeMacro.repeatKeys.Length) + 1
            curKey := activeMacro.repeatKeys[macroRepeatKeyIdx]
            if (activeMacro.repeatSpam || activeMacro.repeatInterval = 0)
                MacroRepeatBuildTooltip(activeMacro, curKey)
            return
        }
    }

    if (macroHotkeysLive && !macroPlaying && !MacroIsBusy() && macroSelectedIdx > 0 && macroSelectedIdx <= macroList.Length) {
        selMacro := macroList[macroSelectedIdx]
        if (selMacro.hotkey = "q") {
            isArk := WinActive(arkwindow)
            isGui := guiVisible
            if (!isArk && !isGui)
                return
            if (isGui) {
                MainGui.Hide()
                global guiVisible := false
                global macroArmed := true
                MacroRegisterHotkeys(true)
                if WinExist(arkwindow)
                    WinActivate(arkwindow)
                ToolTip(" ► " selMacro.name " armed [Q]`n" MacroSpeedHint(selMacro) "`n Tap to run  |  Hold for game  |  Z = next  |  F1 = disarm", 0, 0)
                SetTimer(() => ToolTip(), -3000)
            } else if (macroArmed) {
                global macroArmed := false
                MacroRegisterHotkeys(true)
                MacroPlayByIndex(macroSelectedIdx)
            }
            return
        }
    }

    if (depoEggsActive || depoEmbryoActive) {
        if (depoCycle.Length > 1) {
            global depoCycleIdx := Mod(depoCycleIdx, depoCycle.Length) + 1
            ToolTip(DepoBuildTooltip(), 0, 0, 1)
        }
        return
    }

    if (qhArmed) {
        global qhArmed   := false
        global qhRunning := false
        global qhMode    := 0
        ToolTip(,,,1)
        qhAllBtn.Value    := 0
        qhSingleBtn.Value := 0
        qhStatusTxt.Text := "Select a mode then press START"
        stoppedAny := true
    }
    if (runClaimAndNameScript) {
        global runClaimAndNameScript := false
        ToolTip(,,,2)
        stoppedAny := true
    }
    if (runNameAndSpayScript) {
        global runNameAndSpayScript := false
        Send("{e up}")
        Click("Up")
        ToolTip(,,,2)
        stoppedAny := true
    }
    if (stoppedAny) {
        MainGui.Show()
        global guiVisible := true
        return
    }
    if (acSimpleArmed || acTimedArmed || acGridArmed) {
        global acPresetIdx, acPresetNames
        if (acPresetNames.Length > 1) {
            acPresetIdx := Mod(acPresetIdx, acPresetNames.Length) + 1
            mode := acSimpleArmed ? "Simple" : acTimedArmed ? "Timed" : "Grid"
            ToolTip(AcBuildCraftTooltip(mode), 0, 0)
        }
        return
    }
    if (acRunning) {
        if (acTimedMultiActive) {
            return
        }
        if (acCraftLoopRunning && acPresetNames.Length > 1) {
            return
        }
        if (acGridRunning) {
            if (acPresetNames.Length > 1) {
                global acPresetIdx := Mod(acPresetIdx, acPresetNames.Length) + 1
                CraftLog("Q-cycle → preset #" acPresetIdx " [" acPresetNames[acPresetIdx] "]")
                ToolTip(AcBuildCraftTooltip("Grid"), 0, 0)
            }
            return
        }
        global acEarlyExit     := true
        global acTimedFPressed := false
        global acTimedRestart  := false
        global acGridRestart   := false
        ToolTip(" AutoCraft: stopping…", 0, 0)
        return
    }
    if (obUploadRunning) {
        global obUploadPaused  := false
        global obUploadRunning := false
        global obUploadEarlyExit := true
        return
    }
    if (obDownloadRunning || obDownloadArmed) {
        global obDownloadRunning := false
        global obDownloadArmed  := false
        ToolTip()
        MainGui.Show()
        global guiVisible := true
        return
    }
    if (runMagicFScript) {
        if (magicFRefillMode)
            return
        global magicFPresetIdx, magicFPresetNames
        if (magicFPresetNames.Length > 1) {
            magicFPresetIdx := Mod(magicFPresetIdx, magicFPresetNames.Length) + 1
            ToolTip(MagicFBuildTooltip(), 0, 0)
        }
        return
    }
    if (runMammothScript) {
        StopMammothScript()
        return
    }
    if (runOvercapScript) {
        StopOvercapScript()
        return
    }
    if (autoclicking) {
        global autoclicking := false
        SetTimer(AutoclickLoop, 0)
        try Hotkey("$[", "Off")
        try Hotkey("$]", "Off")
        ToolTip()
        MainGui.Show()
        global guiVisible := true
        return
    }
}

$F12:: {
    GmkToggle()
}

_DebugPx(label, x, y) {
    try c := PixelGetColor(x, y)
    catch
        c := 0
    r := (c >> 16) & 0xFF
    g := (c >> 8) & 0xFF
    b := c & 0xFF
    return "  " label " (" x "," y "): 0x" Format("{:06X}", c) "  R=" r " G=" g " B=" b "`n"
}

PerfLogPush(module, startTick, outcome := "done") {
    global perfLog
    elapsed := A_TickCount - startTick
    perfLog.Push({module: module, time: FormatTime(, "HH:mm:ss"), elapsed: elapsed, outcome: outcome})
    if (perfLog.Length > 50)
        perfLog.RemoveAt(1)
}

_DebugPxCheck(label, x, y, expect, tol := 30) {
    try c := PixelGetColor(x, y)
    catch
        c := 0
    r := (c >> 16) & 0xFF, g := (c >> 8) & 0xFF, b := c & 0xFF
    er := (expect >> 16) & 0xFF, eg := (expect >> 8) & 0xFF, eb := expect & 0xFF
    dist := Abs(r - er) + Abs(g - eg) + Abs(b - eb)
    pass := (dist <= tol) ? "PASS" : "FAIL"
    return "  " label " (" x "," y "): 0x" Format("{:06X}", c) "  R=" r " G=" g " B=" b "  [expect 0x" Format("{:06X}", expect) " dist=" dist " " pass "]`n"
}

F11:: {
    global obLog, acLog, acSimpleArmed, acTimedArmed, acGridArmed, acRunning
    global acActiveItemName, acActiveFilter, lastDebugContext, ModeSelectTab
    global quickFeedMode, autoclicking, autoclickInterval, pcMode, pcRunning, pcLogEntries
    global qhLogEntries, qhMode, qhArmed, qhRunning, qhClick1X, qhClick1Y, qhClick2X, qhClick2Y
    global nfEnabled, perfLog
    global qhInvPixX, qhInvPixY, qhClickDelay, widthmultiplier, heightmultiplier
    global qhEmptyPixX, qhEmptyPixY, qhEmptyColor, qhEmptyTol
    global qhEggSlotX, qhEggSlotY
    global nsLogEntries, nsRadialX, nsRadialY, nsSpayX, nsSpayY, runNameAndSpayScript
    global simLog, simLastState, simLastColors, simCycleCount, AutoSimCheck
    global MM, RM, SM, WM, JL, nosessions, incounter, coltol, stuckState, stuckCount, simMode

    ctx := lastDebugContext
    if (ctx = "") {
        tab := ModeSelectTab.Value
        ctx := (tab = 1) ? "joinsim"
              : (tab = 2) ? "magicf"
              : (tab = 3) ? "autolvl"
              : (tab = 4) ? "popcorn"
              : (tab = 5) ? "sheep"
              : (tab = 6) ? "craft"
              : (tab = 7) ? "macro"
              : (tab = 8) ? "quickhatch"
              : "misc"
    }

    ts  := FormatTime("", "HH:mm:ss")
    out := "AIO — Debug  [" ctx "]  " ts "`n==============================`n"

    if (acOcrTotal > 0) {
        dT := Floor(acOcrTotal)
        fT := RegExReplace(String(dT), "(\d)(?=(\d{3})+$)", "$1,")
        if (dT >= 1000000)
            fT .= " (" Round(dT / 1000000, 1) "m)"
        out .= "Last Grid Count: " fT "  (" acOcrStations " stations)`n`n"
    }

    if (ctx = "joinsim") {
        out .= "Sim: " (AutoSimCheck ? "RUNNING" : "OFF") "  Mode: SIM " (simMode = 1 ? "A" : "B") "  State: " simLastState "  Cycles: " simCycleCount "`n"
        WinGetPos(&gx, &gy, &gw, &gh, GameWindow)
        out .= "GameWindow: " gw "x" gh " at (" gx "," gy ")  Screen: " A_ScreenWidth "x" A_ScreenHeight "`n"
        out .= "Tolerance: " coltol "  UseLast: " useLast "  Mods: " modsEnabled "`n"
        out .= "Counters: MM=" MM " RM=" RM " SM=" SM " WM=" WM " JL=" JL " nosessions=" nosessions " in=" incounter "`n"
        out .= "Stuck: state='" stuckState "' count=" stuckCount "`n`n"
        if (simLastColors != "") {
            out .= "=== LAST COLOR SCAN ===`n"
            for item in StrSplit(simLastColors, " ") {
                if (item != "")
                    out .= " " item "`n"
            }
            out .= "`n"
        }
        if (simLog.Length > 0) {
            out .= "=== SIM LOG ===`n"
            for i, v in simLog
                out .= " " v "`n"
        } else
            out .= "(no sim log entries)`n"
    }

    else if (ctx = "craft" || acRunning || acTimedArmed || acGridArmed || acSimpleArmed || acCountOnlyActive) {
        global acPresetNames, acPresetFilters, acPresetIdx
        craftState := acCountOnlyActive ? "Count Only active (" acOcrStations " stations, " acOcrTotal " items)"
                    : acSimpleArmed  ? "Simple armed"
                    : acTimedArmed   ? "Inventory Timed armed — " acActiveItemName
                    : acGridArmed    ? "Grid Walk armed"
                    : acRunning      ? "Running — " acActiveItemName
                    : "idle"
        out .= "State : " craftState "`n"
        out .= "Filter: " (acActiveFilter != "" ? acActiveFilter : "—") "`n"
        if (acPresetNames.Length > 0) {
            out .= "Presets (" acPresetNames.Length "):  current=#" acPresetIdx "`n"
            for i, n in acPresetNames {
                arrow := (i = acPresetIdx) ? " ► " : "   "
                out .= arrow n " [" acPresetFilters[i] "]`n"
            }
        }
        out .= "GridOCR: " (acOcrEnabled ? "ON" : "OFF") "  region=(" acOcrSnapX "," acOcrSnapY " " acOcrSnapW "x" acOcrSnapH ")"
        out .= "  total=" acOcrTotal "  stations=" acOcrStations "`n"
        if (acOcrTotal > 0) {
            dTotal := Floor(acOcrTotal)
            fmtTotal := RegExReplace(String(dTotal), "(\d)(?=(\d{3})+$)", "$1,")
            if (dTotal >= 1000000)
                fmtTotal .= " (" Round(dTotal / 1000000, 1) "m)"
            out .= "Last Grid Count: " fmtTotal "  (" acOcrStations " stations scanned)`n"
        }
        out .= "`n"
        if (IsSet(acLog) && acLog.Length > 0) {
            out .= "=== CRAFT LOG ===`n"
            for i, v in acLog
                out .= " " v "`n"
        } else
            out .= "(no craft log entries)`n"
    }

    else if (ctx = "popcorn") {
        global pcGrinderPoly, pcGrinderMetal, pcGrinderCrystal, pcPresetRaw, pcPresetCooked
        global pcAllCustomActive, pcCustomFilter, pcForgeTransferAll, pcForgeSkipFirst
        global pcF10Step, pcSpeedMode, pcSpeedNames, pcEarlyExit

        presets := ""
        if (pcGrinderPoly)    presets .= "Poly "
        if (pcGrinderMetal)   presets .= "Metal "
        if (pcGrinderCrystal) presets .= "Crystal "
        if (pcPresetRaw)      presets .= "Raw "
        if (pcPresetCooked)   presets .= "Cooked "
        if (presets = "") presets := "(none)"

        out .= "Popcorn mode: " pcMode "  running: " pcRunning "  earlyExit: " pcEarlyExit "`n"
        out .= "Presets: " presets "`n"
        out .= "All (no filter): " (pcAllNoFilter ? "ON" : "OFF") "`n"
        out .= "Custom: " (pcAllCustomActive ? "ON" : "OFF") "  filter: [" pcCustomFilter "]`n"
        out .= "TransferAll: " pcForgeTransferAll "  SkipFirst: " pcForgeSkipFirst "`n"
        out .= "Speed: " pcSpeedNames[pcSpeedMode] "  F10 step: " pcF10Step "  isBag: " pcIsBag "`n`n"
        if (IsSet(pcLogEntries) && pcLogEntries.Length > 0) {
            out .= "=== POPCORN LOG ===`n"
            for i, v in pcLogEntries
                out .= " " v "`n"
        } else
            out .= "(no popcorn log entries)`n"
    }

    else if (ctx = "ob_upload" || ctx = "ob_download") {
        if (IsSet(obLog) && obLog.Length > 0) {
            out .= "=== OB LOG ===`n"
            for i, v in obLog
                out .= " " v "`n"
        } else
            out .= "(no OB log entries)`n"
    }

    else if (ctx = "feed") {
        modeStr := quickFeedMode = 0 ? "Off" : quickFeedMode = 1 ? "Raw Meat" : "Berry"
        out .= "Quick Feed mode: " modeStr "`n"
    }

    else if (ctx = "autoclick") {
        out .= "Autoclicker: " (autoclicking ? "ON — interval " autoclickInterval "ms" : "OFF") "`n"
    }

    else if (ctx = "quickhatch") {
        modeStr := qhMode = 0 ? "None" : qhMode = 1 ? "All" : "Single"
        out .= "Quick Hatch mode: " modeStr "  armed: " qhArmed "  running: " qhRunning "`n"
        out .= "Click1: (" qhClick1X "," qhClick1Y ")  Click2: (" qhClick2X "," qhClick2Y ")`n"
        out .= "InvPix: (" qhInvPixX "," qhInvPixY ")  wm: " widthmultiplier "  hm: " heightmultiplier "  delay: " qhClickDelay "ms`n"
        out .= "EmptyPix: (" qhEmptyPixX "," qhEmptyPixY ")  color: " qhEmptyColor "  tol: " qhEmptyTol "`n"
        slotStr := ""
        loop 10 {
            if (A_Index > 1)
                slotStr .= ", "
            slotStr .= A_Index ":(" qhEggSlotX[A_Index] "," qhEggSlotY[A_Index] ")"
        }
        out .= "EggSlots: " slotStr "`n`n"
        if (IsSet(qhLogEntries) && qhLogEntries.Length > 0) {
            out .= "=== QUICK HATCH LOG ===`n"
            for i, v in qhLogEntries
                out .= " " v "`n"
        } else
            out .= "(no quick hatch log entries)`n"
    }

    else if (ctx = "nameandspay") {
        out .= "Name/Spay: " (runNameAndSpayScript ? "ON" : "OFF") "`n"
        ufStr := ""
        for i, f in ufList
            ufStr .= (i > 1 ? ", " : "") f
        out .= "Cryo: " nsCryoBtn.Value "  UploadFilter: " nsUploadFilterCB.Value " [" ufStr "]`n"
        out .= "RadialPix: (" nsRadialX "," nsRadialY ")  SpayPix: (" nsSpayX "," nsSpayY ")`n"
        out .= "wm: " widthmultiplier "  hm: " heightmultiplier "`n`n"
        if (IsSet(nsLogEntries) && nsLogEntries.Length > 0) {
            out .= "=== NAME AND SPAY LOG ===`n"
            for i, v in nsLogEntries
                out .= " " v "`n"
        } else
            out .= "(no name and spay log entries)`n"
    }

    else if (ctx = "magicf") {
        global magicFPresetNames, magicFPresetFilters, magicFPresetDirs, magicFPresetIdx
        out .= "Magic F: " (runMagicFScript ? "ARMED" : "OFF") "`n"
        if (magicFPresetNames.Length > 0) {
            out .= "Presets (" magicFPresetNames.Length "):  current=#" magicFPresetIdx "`n"
            for i, n in magicFPresetNames {
                arrow := (i = magicFPresetIdx) ? " ► " : "   "
                out .= arrow magicFPresetDirs[i] " " n " [" magicFPresetFilters[i] "]`n"
            }
        } else {
            out .= "(no presets built)`n"
        }
    }

    else if (ctx = "gmk") {
        out .= "Grab My Kit: " gmkMode "`n"
    }

    else if (ctx = "autolvl") {
        out .= "AutoLvL — check tooltip for current state`n"
        out .= "runAutoLvlScript: " runAutoLvlScript "`n"
    }

    else if (ctx = "ini") {
        out .= "F5 — ApplyIni was last used`n"
        out .= "INI path: " A_ScriptDir "\GameUserSettings.ini`n"
    }

    else if (ctx = "macro") {
        global macroList, macroSelectedIdx, macroPlaying, macroArmed, macroActiveIdx
        global macroRecording, guidedRecording, comboRunning, comboMode, comboFilterIdx
        global macroLogEntries, macroTabActive
        selName := (macroSelectedIdx >= 1 && macroSelectedIdx <= macroList.Length) ? macroList[macroSelectedIdx].name : "(none)"
        selType := (macroSelectedIdx >= 1 && macroSelectedIdx <= macroList.Length) ? macroList[macroSelectedIdx].type : ""
        out .= "Selected: #" macroSelectedIdx " " selName " [" selType "]`n"
        out .= "Armed: " macroArmed "  Playing: " macroPlaying "  ActiveIdx: " macroActiveIdx "`n"
        out .= "Recording: " macroRecording "  GuidedRecording: " guidedRecording "  SingleItem: " guidedSingleItem "`n"
        out .= "ComboRunning: " comboRunning "  ComboMode: " comboMode "  ComboFilterIdx: " comboFilterIdx "`n"
        out .= "TabActive: " macroTabActive "  HotkeysLive: " macroHotkeysLive "`n"
        out .= "Macros (" macroList.Length "):`n"
        for i, m in macroList {
            arrow := (i = macroSelectedIdx) ? " ► " : "   "
            extra := ""
            if (m.type = "guided") {
                fCount := m.HasProp("searchFilters") ? m.searchFilters.Length : 0
                eCount := m.HasProp("events") ? m.events.Length : 0
                mSpd := m.HasProp("mouseSpeed") ? m.mouseSpeed : 0
                mSet := m.HasProp("mouseSettle") ? m.mouseSettle : 30
                mLoad := m.HasProp("invLoadDelay") ? m.invLoadDelay : 1500
                mTurbo := m.HasProp("turbo") && m.turbo ? "ON(" (m.HasProp("turboDelay") ? m.turboDelay : 30) ")" : "off"
                extra := " inv:" (m.HasProp("invType") ? m.invType : "?") " filters:" fCount " events:" eCount " mouse:" mSpd " settle:" mSet " load:" mLoad " turbo:" mTurbo
            } else if (m.type = "combo") {
                pCount := m.HasProp("popcornFilters") ? m.popcornFilters.Length : 0
                mfCount := m.HasProp("magicFFilters") ? m.magicFFilters.Length : 0
                extra := " pop:" pCount " mf:" mfCount
                if (m.HasProp("popcornFilters") && m.popcornFilters.Length > 0) {
                    pList := ""
                    for fi, fv in m.popcornFilters
                        pList .= (fi > 1 ? "," : "") fv
                    extra .= " [" pList "]"
                }
                if (m.HasProp("magicFFilters") && m.magicFFilters.Length > 0) {
                    mList := ""
                    for fi, fv in m.magicFFilters
                        mList .= (fi > 1 ? "," : "") fv
                    extra .= " → [" mList "]"
                }
            } else if (m.type = "recorded") {
                eCount := m.HasProp("events") ? m.events.Length : 0
                extra := " events:" eCount " spd:" Format("{:.2f}", m.speedMult) (m.loopEnabled ? " LOOP" : "")
            }
            out .= arrow m.name " (" m.type ") hk:" (m.hotkey != "" ? m.hotkey : "-") extra "`n"
        }
        out .= "InvDetect pixel: (" pcInvDetectX "," pcInvDetectY ")  InvReady pixel: (" guidedInvReadyX "," guidedInvReadyY ") " guidedInvReadyColor " tol=" guidedInvReadyTol "`n"
        out .= "`n"
        if (macroLogEntries.Length > 0) {
            out .= "=== MACRO LOG ===`n"
            for i, v in macroLogEntries
                out .= " " v "`n"
        } else
            out .= "(no macro log entries)`n"
    }

    else {
        out .= "No hotkey used yet — open a tab or press a hotkey first`n"
        out .= "Active tab: " ModeSelectTab.Value "`n"
    }

    out .= "`n=== AUTO IMPRINT ===`n"
    out .= "Scanning: " (imprintScanning ? "YES" : "no") "  AutoMode: " (imprintAutoMode ? "YES" : "no") "`n"
    out .= "InvKey: " imprintInventoryKey "  Snap: (" imprintSnapX "," imprintSnapY " " imprintSnapW "x" imprintSnapH ")`n"
    out .= "InvPix: (" imprintInvPixX "," imprintInvPixY ")  Search: (" imprintSearchX "," imprintSearchY ")  Result: (" imprintResultX "," imprintResultY ")`n"
    if (imprintLog.Length > 0) {
        out .= "--- LOG ---`n"
        for i, v in imprintLog
            out .= " " v "`n"
    } else
        out .= "(no imprint log)`n"

    out .= "`n=== AUTO PIN ===`n"
    out .= "Enabled: " (pinAutoOpen ? "ON" : "OFF") "  Polling: " (pinPollActive ? "YES" : "no") "`n"
    out .= "Pixels (scaled): (" pinPix1X "," pinPix1Y ") (" pinPix2X "," pinPix2Y ") (" pinPix3X "," pinPix3Y ") (" pinPix4X "," pinPix4Y ")`n"
    out .= "Click target: (" pinClickX "," pinClickY ")  tol: " pinTol "`n"
    if (pinLog.Length > 0) {
        for i, v in pinLog
            out .= " " v "`n"
    } else
        out .= "(no pin log entries)`n"

    out .= "`n=== NVIDIA FILTER (Per-Step Calibration) ===`n"
    out .= "Enabled: " (nfEnabled ? "ON" : "OFF") "`n"
    if (nfEnabled)
        out .= "Mode: change-detection for waits, wider tolerance for checks, widened ranges`n"

    out .= "`n=== ALL PIXEL COORDINATES BY MODE ===`n"
    out .= "Resolution: " A_ScreenWidth "x" A_ScreenHeight "  wMult: " widthmultiplier "  hMult: " heightmultiplier "`n`n"

    out .= "--- Shared (inv detect / search bar) ---`n"
    out .= _DebugPxCheck("invyDetect", invyDetectX, invyDetectY, 0xFFFFFF)
    out .= _DebugPx("searchBar", mySearchBarX, mySearchBarY)
    out .= _DebugPx("firstSlot", myFirstSlotX, myFirstSlotY)
    out .= _DebugPxCheck("invOpen", Round(1495*widthmultiplier), Round(226*heightmultiplier), 0xFFFFFF)
    out .= _DebugPxCheck("cryoDetect", Round(1034*widthmultiplier), Round(665*heightmultiplier), 0x94D2EA, 60)

    out .= "`n--- AutoLvL ---`n"
    out .= _DebugPx("healthPix", autoLvlHealthPixX, autoLvlHealthPixY)
    out .= _DebugPx("stamPix", autoLvlStamPixX, autoLvlStamPixY)
    out .= _DebugPx("foodPix", autoLvlFoodPixX, autoLvlFoodPixY)
    out .= _DebugPx("weightPix", autoLvlWeightPixX, autoLvlWeightPixY)
    out .= _DebugPx("meleeXPPix", autoLvlMeleeXPPixX, autoLvlMeleeXPPixY)
    out .= _DebugPxCheck("lvlInvOpen", Round(1632*widthmultiplier), Round(215*heightmultiplier), 0xFFFFFF)

    out .= "`n--- Name/Spay ---`n"
    out .= _DebugPxCheck("radial", nsRadialX, nsRadialY, 0xFFFFFF)
    out .= _DebugPxCheck("altRadial", nsAltRadialX, nsAltRadialY, 0xFFFFFF)
    out .= _DebugPxCheck("alt2Radial", nsAlt2RadialX, nsAlt2RadialY, 0xFFFFFF)
    out .= _DebugPxCheck("adminPix", nsAdminPixX, nsAdminPixY, 0xFFFFFF)
    out .= _DebugPx("spayPix", nsSpayX, nsSpayY)

    out .= "`n--- Quick Hatch ---`n"
    out .= _DebugPx("qhInvPix", qhInvPixX, qhInvPixY)
    out .= _DebugPxCheck("qhEmptyPix", qhEmptyPixX, qhEmptyPixY, Integer("0x" SubStr(qhEmptyColor, 3)), 40)
    loop Min(qhEggSlotX.Length, 6) {
        out .= _DebugPx("eggSlot" A_Index, qhEggSlotX[A_Index], qhEggSlotY[A_Index])
    }

    out .= "`n--- Auto Pin ---`n"
    out .= _DebugPxCheck("pinPix1", pinPix1X, pinPix1Y, 0xC1F5FF, 60)
    out .= _DebugPxCheck("pinPix2", pinPix2X, pinPix2Y, 0xC1F5FF, 60)
    out .= _DebugPxCheck("pinPix3", pinPix3X, pinPix3Y, 0xC1F5FF, 60)
    out .= _DebugPxCheck("pinPix4", pinPix4X, pinPix4Y, 0xC1F5FF, 60)

    out .= "`n--- Macros (Guided/Combo) ---`n"
    out .= _DebugPxCheck("pcInvDetect", pcInvDetectX, pcInvDetectY, 0xFFFFFF)
    out .= _DebugPxCheck("guidedInvReady", guidedInvReadyX, guidedInvReadyY, Integer("0x" SubStr(guidedInvReadyColor, 3)), 40)

    out .= "`n--- Macros (Pyro) ---`n"
    out .= _DebugPx("dismount", pyroDismountX, pyroDismountY)
    out .= _DebugPx("astTekDet", pyroAstTekDetX, pyroAstTekDetY)
    out .= _DebugPx("astNoTekDet", pyroAstNoTekDetX, pyroAstNoTekDetY)
    out .= _DebugPx("nonTekDet", pyroNonTekDetX, pyroNonTekDetY)
    out .= _DebugPx("nonNoTekDet", pyroNonNoTekDetX, pyroNonNoTekDetY)
    out .= _DebugPx("throwCheck", pyroThrowCheckX, pyroThrowCheckY)
    out .= _DebugPx("rideConfirm", pyroRideConfirmX, pyroRideConfirmY)

    out .= "`n--- OB Upload ---`n"
    out .= _DebugPxCheck("confirm", obConfirmPixX, obConfirmPixY, 0xFFFFFF)
    out .= _DebugPx("rightTab (sel=BCF4FF unsel=5D94A0)", obRightTabPixX, obRightTabPixY)
    out .= _DebugPxCheck("uploadReady", obUploadReadyPixX, obUploadReadyPixY, 0xBCF4FF, 40)
    out .= _DebugPx("itemName", obItemNamePixX, obItemNamePixY)
    out .= _DebugPx("timer", obTimerPixX, obTimerPixY)
    out .= _DebugPx("dayd", obDaydPixX, obDaydPixY)
    out .= _DebugPx("cryoPix", obCryoPixX, obCryoPixY)
    out .= _DebugPx("overlay", obOvPixX, obOvPixY)
    out .= _DebugPx("obFull", obFullPixX, obFullPixY)
    out .= _DebugPxCheck("maxItems", obMaxItemsPixX, obMaxItemsPixY, 0xFF0000, 60)
    out .= _DebugPx("refresh", obRefreshPixX, obRefreshPixY)
    out .= _DebugPx("tooltip", obTooltipPixX, obTooltipPixY)
    out .= _DebugPx("invFailBtn", obInvFailBtnPixX, obInvFailBtnPixY)
    out .= _DebugPx("invOpen", obInvPixX, obInvPixY)
    out .= _DebugPx("allPix", obAllPixX, obAllPixY)
    out .= _DebugPx("tekPix", Round(251*widthmultiplier), Round(331*heightmultiplier))
    out .= _DebugPx("dataLoaded", obDataLoadedPixX, obDataLoadedPixY)

    out .= "`n--- OB Download ---`n"
    out .= _DebugPx("barPix (teal)", obBarPixX, obBarPixY)
    out .= "  barCount: " OBBarCountItems() "/50`n"
    out .= _DebugPxCheck("closePix", Round(1812*widthmultiplier), Round(216*heightmultiplier), 0xFFFFFF)

    out .= "`n--- Imprint ---`n"
    out .= _DebugPxCheck("imprintInvPix", imprintInvPixX, imprintInvPixY, 0xFFFFFF)
    out .= _DebugPx("imprintSearch", imprintSearchX, imprintSearchY)
    out .= _DebugPx("imprintResult", imprintResultX, imprintResultY)

    out .= "`n--- Bag/Cache Detection ---`n"
    out .= _DebugPxCheck("bagDetect", pcBagDetectX, pcBagDetectY, Integer("0x" SubStr(pcBagDetectColor, 3)), pcBagDetectTol)

    out .= "`n--- Grid OCR ---`n"
    out .= "  enabled=" (acOcrEnabled ? "ON" : "OFF") "  region=(" acOcrSnapX "," acOcrSnapY " " acOcrSnapW "x" acOcrSnapH ")`n"
    out .= "  total=" acOcrTotal "  stations=" acOcrStations "  tracked=" acOcrStationMap.Count "`n"

    out .= "`n=== PERF SUMMARY (last " perfLog.Length " ops) ===`n"
    if (perfLog.Length = 0) {
        out .= "  (no operations logged yet)`n"
    } else {
        loop perfLog.Length {
            i := perfLog.Length - A_Index + 1
            e := perfLog[i]
            out .= "  " e.time " " e.module " — " e.elapsed "ms [" e.outcome "]`n"
        }
    }

    A_Clipboard := out
    ToolTip("Debug copied  [" ctx "]", 0, 0)
    SetTimer(() => (ToolTip(), OBCharRestoreTooltip()), -2000)
}

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; AUTO IMPRINT

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ImprintLoadConfig() {
    global imprintInventoryKey, imprintInvKeyEdit
    global imprintSnapW, imprintSnapH, imprintSnapX, imprintSnapY
    global imprintHideOverlay, imprintHideOverlayCB
    configFile := A_ScriptDir "\AIO_config.ini"
    if FileExist(configFile) {
        saved := IniRead(configFile, "Imprint", "InventoryKey", "v")
        if (saved != "")
            imprintInventoryKey := saved
        savedW := IniRead(configFile, "Imprint", "ScanW", "")
        savedH := IniRead(configFile, "Imprint", "ScanH", "")
        if (savedW != "" && Integer(savedW) >= 40)
            imprintSnapW := Integer(savedW)
        if (savedH != "" && Integer(savedH) >= 20)
            imprintSnapH := Integer(savedH)
        imprintSnapX := (A_ScreenWidth // 2) - (imprintSnapW // 2)
        imprintSnapY := (A_ScreenHeight // 2) - (imprintSnapH // 2) + 20
        savedHide := IniRead(configFile, "Imprint", "HideOverlay", "0")
        imprintHideOverlay := (savedHide = "1")
    }
    try imprintInvKeyEdit.Value := imprintInventoryKey
    try imprintHideOverlayCB.Value := imprintHideOverlay
    ImprintUpdateSizeTxt()
}

ImprintSaveConfig() {
    global imprintInventoryKey, imprintHideOverlay
    configFile := A_ScriptDir "\AIO_config.ini"
    IniWrite(imprintInventoryKey, configFile, "Imprint", "InventoryKey")
    IniWrite(imprintHideOverlay ? 1 : 0, configFile, "Imprint", "HideOverlay")
}

ImprintOnHideOverlayToggle(*) {
    global imprintHideOverlay, imprintHideOverlayCB, imprintScanning
    imprintHideOverlay := imprintHideOverlayCB.Value
    ImprintSaveConfig()
    if (imprintHideOverlay && imprintScanning)
        ImprintHideScanOverlay()
    else if (!imprintHideOverlay && imprintScanning)
        ImprintShowScanOverlay()
}

ImprintOnInvKeyChange(*) {
    global imprintInventoryKey, imprintInvKeyEdit
    val := imprintInvKeyEdit.Value
    if (val != "") {
        imprintInventoryKey := SubStr(val, 1, 1)
        ImprintSaveConfig()
    }
}

ImprintToggleArmed(*) {
    global imprintScanning, imprintAutoMode, imprintStartBtn, imprintStatusTxt
    global MainGui, guiVisible, arkwindow
    if (imprintScanning) {
        ImprintStopAll()
        DarkBtnText(imprintStartBtn, "Start")
        imprintStatusTxt.Text := "Press Start then R=read Q=auto"
        return
    }
    imprintScanning := true
    imprintAutoMode := false
    try Hotkey("~$r", ImprintRHotkey, "On")
    ImprintShowScanOverlay()
    DarkBtnText(imprintStartBtn, "Stop")
    imprintStatusTxt.Text := "ARMED — R=read  Q=auto"
    MainGui.Hide()
    global guiVisible := false
    ToolTip("IMPRINT ARMED — R read | Q auto-scan`nF1 = stop", 10, 10)
}

ImprintStopAll() {
    global imprintScanning, imprintAutoMode, imprintResizing
    imprintScanning := false
    imprintAutoMode := false
    try Hotkey("~$r", "Off")
    if (imprintResizing)
        ImprintExitResize()
    ImprintHideScanOverlay()
    ToolTip()
}

ImprintRHotkey(*) {
    global imprintScanning, imprintAutoMode
    if (imprintScanning && !imprintAutoMode)
        ImprintOnReadAndProcess()
}

ImprintToggleAutoMode() {
    global imprintScanning, imprintAutoMode
    if (!imprintScanning)
        return
    if (imprintAutoMode) {
        imprintAutoMode := false
        ToolTip("Auto-scan OFF`nARMED — R read | Q auto-scan", 10, 10)
        return
    }
    imprintAutoMode := true
    ToolTip("Auto-scan ON — scanning...", 10, 10)
    ImprintAutoScanLoop()
}

ImprintAutoScanLoop() {
    global imprintScanning, imprintAutoMode
    global imprintSnapX, imprintSnapY, imprintSnapW, imprintSnapH, imprintAllFoods

    while (imprintScanning && imprintAutoMode) {
        try {
            ocrText := OCR.FromRect(imprintSnapX, imprintSnapY, imprintSnapW, imprintSnapH, {scale: 3}).Text
        } catch {
            Sleep(150)
            continue
        }

        matched := ""
        for foodName in imprintAllFoods {
            if InStr(ocrText, foodName) {
                matched := foodName
                break
            }
        }

        if (matched != "") {
            ImLog("Auto-scan OCR: [" ocrText "] → matched [" matched "]")
            ToolTip("Detected: " matched, 10, 10)
            ImprintProcessFood(matched, ocrText)
            if (imprintScanning && imprintAutoMode) {
                ImprintShowScanOverlay()
                Loop 2 {
                    remaining := Format("{:.1f}", (3 - A_Index) * 0.5)
                    ToolTip(matched " -> Hotbar 0 — Feed now!`nResuming in " remaining "s...", 10, 10)
                    Sleep(500)
                    if (!imprintScanning || !imprintAutoMode)
                        break
                }
                if (imprintScanning && imprintAutoMode)
                    ToolTip("Auto-scan ON — scanning...", 10, 10)
            }
        }

        Sleep(150)
    }

    if (imprintScanning && !imprintAutoMode)
        ToolTip("Auto-scan OFF`nARMED — R read | Q auto-scan", 10, 10)
}

ImprintOnReadAndProcess() {
    global imprintScanning
    global imprintSnapX, imprintSnapY, imprintSnapW, imprintSnapH, imprintAllFoods

    if (!imprintScanning)
        return

    ToolTip("Reading...", 10, 10)
    ImLog("Manual read triggered")
    try {
        ocrText := OCR.FromRect(imprintSnapX, imprintSnapY, imprintSnapW, imprintSnapH, {scale: 3}).Text
    } catch as ocrErr {
        ImLog("OCR FAILED: " ocrErr.Message)
        ToolTip("OCR failed — try again`nARMED — R read | Q auto-scan", 10, 10)
        return
    }

    ImLog("OCR text: [" ocrText "]")
    matched := ""
    for foodName in imprintAllFoods {
        if InStr(ocrText, foodName) {
            matched := foodName
            break
        }
    }

    if (matched = "") {
        ImLog("No match in: [" ocrText "]")
        ToolTip("No food found: [" ocrText "]`nARMED — R read | Q auto-scan", 10, 10)
        return
    }

    ToolTip("Detected: " matched, 10, 10)
    ImLog("Manual OCR: [" ocrText "] → matched [" matched "]")
    ImprintProcessFood(matched, ocrText)

    if (imprintScanning) {
        ImprintShowScanOverlay()
        ToolTip("Done: " matched "`nARMED — R read | Q auto-scan", 10, 10)
    }
}

ImHasFeedPrompt(text, foodName) {
    if (text = "" || !InStr(text, "Feed") || !InStr(text, foodName))
        return false
    t := StrLower(text)
    if (InStr(t, "[e]") || InStr(t, "(e)") || InStr(t, "ie]") || InStr(t, "[e") || InStr(t, "e]") || InStr(t, " e "))
        return true
    return false
}

ImprintProcessFood(foodName, ocrText := "") {
    global imprintInventoryKey, arkwindow, imprintLog
    global imprintInvPixX, imprintInvPixY, imprintSearchX, imprintSearchY, imprintResultX, imprintResultY
    global imprintSnapX, imprintSnapY, imprintSnapW, imprintSnapH
    global mySearchBarX, mySearchBarY
    global widthmultiplier, heightmultiplier

    if (foodName = "cuddle") {
        ImLog("Cuddle detected — pressing E")
        Send("{e}")
        Sleep(200)
        return
    }

    CoordMode("Pixel", "Screen")
    CoordMode("Mouse", "Screen")

    if (ocrText != "" && ImHasFeedPrompt(ocrText, foodName)) {
        ImLog("[E] Feed [" foodName "] already visible — pressing E directly")
        Send("{e}")
        Sleep(200)
        return
    }

    ImLog("Opening inventory (key=" imprintInventoryKey ") for [" foodName "]")
    Send("{" imprintInventoryKey "}")
    Sleep(50)

    inventoryOpen := false
    waitCount := 0
    _nfB13 := 0
    while (!NFPixelWait(imprintInvPixX-1, imprintInvPixY-1, imprintInvPixX+1, imprintInvPixY+1, "0xFFFFFF", 10, &_nfB13)) {
        Sleep(16)
        waitCount++
        if (waitCount > 250)
            break
    }
    inventoryOpen := (waitCount <= 250)
    waitMs := waitCount * 16
    ImLog("Inv wait: " waitMs "ms  open=" inventoryOpen "  pixel=(" imprintInvPixX "," imprintInvPixY ")")

    if (!inventoryOpen) {
        ImLog("FAIL: inventory timeout")
        ToolTip("[FAIL] Inventory timeout", 10, 10)
        SetTimer(() => ToolTip(), -4000)
        return
    }

    Sleep(200)
    invStillOpen := false
    try invStillOpen := NFSearchTol(&px2, &py2, imprintInvPixX-1, imprintInvPixY-1, imprintInvPixX+1, imprintInvPixY+1, "0xFFFFFF", 10)
    ImLog("Pre-click verify: inv still open=" invStillOpen)
    if (!invStillOpen) {
        ImLog("FAIL: inventory closed during settle")
        ToolTip("[FAIL] Inventory closed", 10, 10)
        SetTimer(() => ToolTip(), -4000)
        return
    }

    ImLog("ControlClick search bar (" mySearchBarX "," mySearchBarY ")")
    ControlClick("x" mySearchBarX " y" mySearchBarY, arkwindow)
    Sleep(30)
    ImLog("Typing [" foodName "]")
    Send(foodName)
    Sleep(400)

    ImLog("Click first slot (" imprintResultX "," imprintResultY ") + hotbar 0")
    DllCall("SetCursorPos", "int", imprintResultX, "int", imprintResultY)
    Sleep(50)
    Click()
    Sleep(30)
    Send("0")
    Sleep(200)

    ImLog("Closing inv, waiting for [E] feed prompt")
    Send("{Escape}")
    closeWait := 0
    while (closeWait < 125) {
        try {
            if !NFSearchTol(&cx, &cy, imprintInvPixX-1, imprintInvPixY-1, imprintInvPixX+1, imprintInvPixY+1, "0xFFFFFF", 10)
                break
        }
        Sleep(16)
        closeWait++
    }
    ImLog("Inv closed after " (closeWait * 16) "ms, scanning for [E] prompt")

    feedReady := false
    scanWait := 0
    while (scanWait < 10) {
        try {
            eText := OCR.FromRect(imprintSnapX, imprintSnapY, imprintSnapW, imprintSnapH, {scale: 3}).Text
            if (ImHasFeedPrompt(eText, foodName)) {
                feedReady := true
                ImLog("[E] Feed [" foodName "] detected: [" eText "]")
                break
            }
        }
        Sleep(16)
        scanWait++
    }

    if (!feedReady)
        ImLog("Feed prompt not found after " scanWait " scans — pressing E anyway")

    Send("{e}")
    Sleep(100)
    ImLog("Done processing [" foodName "]")
}

ImLog(msg) {
    global imprintLog
    ts := FormatTime(, "HH:mm:ss")
    imprintLog.Push(ts " " msg)
    if (imprintLog.Length > 50)
        imprintLog.RemoveAt(1)
}

ImprintShowScanOverlay() {
    global imprintScanOverlay, imprintSnapX, imprintSnapY, imprintSnapW, imprintSnapH
    global imprintHideOverlay, imprintResizing
    ImprintHideScanOverlay()
    if (imprintHideOverlay && !imprintResizing)
        return
    b := 1
    x := imprintSnapX, y := imprintSnapY, w := imprintSnapW, h := imprintSnapH
    strips := [
        [x-b, y-b, w+b*2, b],
        [x-b, y+h, w+b*2, b],
        [x-b, y,   b,     h],
        [x+w, y,   b,     h]
    ]
    imprintScanOverlay := []
    for s in strips {
        g := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x20")
        g.BackColor := "FF0000"
        WinSetTransparent(200, g)
        g.Show("x" s[1] " y" s[2] " w" s[3] " h" s[4] " NoActivate")
        imprintScanOverlay.Push(g)
    }
}

ImprintHideScanOverlay() {
    global imprintScanOverlay
    if IsObject(imprintScanOverlay) {
        for g in imprintScanOverlay
            try g.Destroy()
        imprintScanOverlay := ""
    }
}

ImprintShowHelp(*) {
    global imprintHelpGui
    if IsObject(imprintHelpGui) {
        try imprintHelpGui.Destroy()
        imprintHelpGui := ""
        return
    }
    imprintHelpGui := Gui("+AlwaysOnTop +ToolWindow", "Auto Imprint Help")
    imprintHelpGui.BackColor := "1A1A1A"
    imprintHelpGui.SetFont("s9 Bold cFF4444", "Segoe UI")
    imprintHelpGui.Add("Text", "x10 y8 w280", "AUTO IMPRINT — HOW TO USE")
    imprintHelpGui.SetFont("s8 cDDDDDD", "Segoe UI")
    imprintHelpGui.Add("Text", "x10 y30 w280",
        "1) Set your Inventory key in the edit field`n"
        "2) Click Start to arm the scanner`n"
        "3) Look at the baby's imprint tooltip in-game`n"
        "4) Press R to read + process the food request`n"
        "   OR press Q to toggle auto-scan mode`n`n"
        "Auto-scan continuously reads the screen center`n"
        "for imprint food names, opens your inventory,`n"
        "searches for it, moves it to hotbar slot 0,`n"
        "then waits 1s before resuming.`n`n"
        "F1 = stop and return to AIO UI`n"
        "Q while armed = toggle auto-scan on/off`n"
        "R while armed = single manual read")
    imprintHelpGui.SetFont("s8 c888888 Italic", "Segoe UI")
    imprintHelpGui.Add("Text", "x10 y220 w280", "Scan area: center of screen (" imprintSnapW "x" imprintSnapH ")")
    imprintHelpGui.OnEvent("Close", (*) => (imprintHelpGui.Destroy(), imprintHelpGui := ""))
    imprintHelpGui.Show("w300 h246")
}

ImprintToggleResize(*) {
    global imprintResizing, imprintResizeBtn, imprintStatusTxt
    if (imprintResizing) {
        ImprintExitResize()
        return
    }
    imprintResizing := true
    DarkBtnText(imprintResizeBtn, "Done")
    imprintStatusTxt.Text := "RESIZE: arrows +-20  Enter=done"
    ImprintShowScanOverlay()
    try Hotkey("$Up", ImprintResizeUp, "On")
    try Hotkey("$Down", ImprintResizeDown, "On")
    try Hotkey("$Left", ImprintResizeLeft, "On")
    try Hotkey("$Right", ImprintResizeRight, "On")
    try Hotkey("$Enter", ImprintResizeDone, "On")
}

ImprintExitResize() {
    global imprintResizing, imprintResizeBtn, imprintStatusTxt
    global imprintSnapW, imprintSnapH
    imprintResizing := false
    DarkBtnText(imprintResizeBtn, "Resize")
    imprintStatusTxt.Text := "Press Start then R=read Q=auto"
    try Hotkey("$Up", "Off")
    try Hotkey("$Down", "Off")
    try Hotkey("$Left", "Off")
    try Hotkey("$Right", "Off")
    try Hotkey("$Enter", "Off")
    ImprintHideScanOverlay()
    ImprintUpdateSizeTxt()
    ImprintSaveScanSize()
}

ImprintResizeDone(*) {
    ImprintExitResize()
}

ImprintResizeUp(*) {
    global imprintSnapH, imprintSnapY
    imprintSnapH := Max(20, imprintSnapH + 20)
    imprintSnapY := (A_ScreenHeight // 2) - (imprintSnapH // 2) + 20
    ImprintShowScanOverlay()
    ImprintUpdateSizeTxt()
}

ImprintResizeDown(*) {
    global imprintSnapH, imprintSnapY
    imprintSnapH := Max(20, imprintSnapH - 20)
    imprintSnapY := (A_ScreenHeight // 2) - (imprintSnapH // 2) + 20
    ImprintShowScanOverlay()
    ImprintUpdateSizeTxt()
}

ImprintResizeRight(*) {
    global imprintSnapW, imprintSnapX
    imprintSnapW := Max(40, imprintSnapW + 20)
    imprintSnapX := (A_ScreenWidth // 2) - (imprintSnapW // 2)
    ImprintShowScanOverlay()
    ImprintUpdateSizeTxt()
}

ImprintResizeLeft(*) {
    global imprintSnapW, imprintSnapX
    imprintSnapW := Max(40, imprintSnapW - 20)
    imprintSnapX := (A_ScreenWidth // 2) - (imprintSnapW // 2)
    ImprintShowScanOverlay()
    ImprintUpdateSizeTxt()
}

ImprintUpdateSizeTxt() {
}

ImprintSaveScanSize() {
    global imprintSnapW, imprintSnapH
    configFile := A_ScriptDir "\AIO_config.ini"
    IniWrite(imprintSnapW, configFile, "Imprint", "ScanW")
    IniWrite(imprintSnapH, configFile, "Imprint", "ScanH")
}


;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; EMBEDDED OCR LIBRARY (Windows.Media.Ocr UWP wrapper)

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

class OCR {
    static Version => "2.0.0"
    static IID_IRandomAccessStream := "{905A0FE1-BC53-11DF-8C49-001E4FC686DA}"
         , IID_IPicture            := "{7BF80980-BF32-101A-8BBB-00AA00300CAB}"
         , IID_IAsyncInfo          := "{00000036-0000-0000-C000-000000000046}"
         , IID_IAsyncOperation_OcrResult        := "{c7d7118e-ae36-59c0-ac76-7badee711c8b}"
         , IID_IAsyncOperation_SoftwareBitmap   := "{c4a10980-714b-5501-8da2-dbdacce70f73}"
         , IID_IAsyncOperation_BitmapDecoder    := "{aa94d8e9-caef-53f6-823d-91b6e8340510}"
         , IID_IAsyncOperationCompletedHandler_OcrResult        := "{989c1371-444a-5e7e-b197-9eaaf9d2829a}"
         , IID_IAsyncOperationCompletedHandler_SoftwareBitmap   := "{b699b653-33ed-5e2d-a75f-02bf90e32619}"
         , IID_IAsyncOperationCompletedHandler_BitmapDecoder    := "{bb6514f2-3cfb-566f-82bc-60aabd302d53}"
         , IID_IPdfDocumentStatics := "{433A0B5F-C007-4788-90F2-08143D922599}"
         , Vtbl_GetDecoder := {bmp:6, jpg:7, jpeg:7, png:8, tiff:9, gif:10, jpegxr:11, ico:12}
         , PerformanceMode := 0
         , DisplayImage := 0

    class IBase {
        __OCR := OCR
        __New(ptr?) {
            if IsSet(ptr) {
                if !ptr
                    throw ValueError('Invalid IUnknown interface pointer', -2, this.__Class)
                else if IsObject(ptr) {
                    if ptr.HasProp("Relative")
                        this.DefineProp("Relative", {value: ptr.Relative})
                    ptr := 0
                }
            }
            this.DefineProp("ptr", {Value:ptr ?? 0})
        }
        __Delete() => this.ptr ? ObjRelease(this.ptr) : 0
    }

    static __New() {
        this.LanguageFactory := this.CreateClass("Windows.Globalization.Language", ILanguageFactory := "{9B0252AC-0C27-44F8-B792-9793FB66C63E}")
        this.SoftwareBitmapFactory := this.CreateClass("Windows.Graphics.Imaging.SoftwareBitmap", "{c99feb69-2d62-4d47-a6b3-4fdb6a07fdf8}")
        this.BitmapTransform := this.CreateClass("Windows.Graphics.Imaging.BitmapTransform")
        this.BitmapDecoderStatics := this.CreateClass("Windows.Graphics.Imaging.BitmapDecoder", IBitmapDecoderStatics := "{438CCB26-BCEF-4E95-BAD6-23A822E58D01}")
        this.BitmapEncoderStatics := this.CreateClass("Windows.Graphics.Imaging.BitmapEncoder", IBitmapDecoderStatics := "{a74356a7-a4e4-4eb9-8e40-564de7e1ccb2}")
        this.SoftwareBitmapStatics := this.CreateClass("Windows.Graphics.Imaging.SoftwareBitmap", ISoftwareBitmapStatics := "{df0385db-672f-4a9d-806e-c2442f343e86}")
        this.OcrEngineStatics := this.CreateClass("Windows.Media.Ocr.OcrEngine", IOcrEngineStatics := "{5BFFA85A-3384-3540-9940-699120D428A8}")
        ComCall(6, this.OcrEngineStatics, "uint*", &MaxImageDimension:=0)   ; MaxImageDimension
        this.MaxImageDimension := MaxImageDimension
        DllCall("Dwmapi\DwmIsCompositionEnabled", "Int*", &compositionEnabled:=0)
        this.CAPTUREBLT := compositionEnabled ? 0 : 0x40000000
        /*  // Based on code by AHK forums user Xtra
            unsigned int Convert_GrayScale(unsigned int bitmap[], unsigned int w, unsigned int h, unsigned int Stride)
            {
                unsigned int a, r, g, b, gray, ARGB;
                unsigned int x, y, offset = Stride/4;
                for (y = 0; y < h * offset; y += offset) {
                    for (x = 0; x < w; ++x) {
                        ARGB = bitmap[x+y];
                        a = ARGB & 0xFF000000;
                        r = (ARGB & 0x00FF0000) >> 16;
                        g = (ARGB & 0x0000FF00) >> 8;
                        b = (ARGB & 0x000000FF);
                        gray = ((300 * r) + (590 * g) + (110 * b)) >> 10;
                        bitmap[x+y] = (gray << 16) | (gray << 8) | gray | a;
                    }
                }
                return 0;
            }
         */
        this.GrayScaleMCode := this.MCode((A_PtrSize = 4) 
        ? "2,x86:VVdWU4PsCIt8JCiLdCQki0QkIMHvAg+v94k0JIX2dH+FwHR7jTS9AAAAAIl0JASLdCQcjRyGMfaNtCYAAAAAkItEJByNDLCNtCYAAAAAZpCLEYPBBInQD7buwegQae1OAgAAD7bAacAsAQAAAegPtuqB4gAAAP9r7W4B6MHoConFCcLB4AjB5RAJ6gnQiUH8Odl1vAH+A1wkBDs0JHKhg8QIMcBbXl9dww==" 
        : "2,x64:V1ZTQcHpAkSJxkiJy0GJ00EPr/GF9nRnRTHAhdJ0YJBEicEPH0QAAInIg8EBTI0Ug0GLEonQD7b+wegQaf9OAgAAD7bAacAsAQAAAfgPtvqB4gAAAP9r/24B+MHoConHCcLB4AjB5xAJ+gnCQYkSRDnZdbRFAchFActBOfByoTHAW15fww==")
        /*
            unsigned int Invert_Colors(unsigned int bitmap[], unsigned int w, unsigned int h, unsigned int Stride)
            {
                unsigned int a, r, g, b, gray, ARGB;
                unsigned int x, y, offset = Stride/4;
                for (y = 0; y < h * offset; y += offset) {
                    for (x = 0; x < w; ++x) {
                        ARGB = bitmap[x+y];
                        a = ARGB & 0xFF000000;
                        r = (ARGB & 0x00FF0000) >> 16;
                        g = (ARGB & 0x0000FF00) >> 8;
                        b = (ARGB & 0x000000FF);
                        bitmap[x+y] = ((255-r) << 16) | ((255-g) << 8) | (255-b) | a;
                    }
                }
                return 0;
            }
        */
        this.InvertColorsMCode := this.MCode((A_PtrSize = 4)
        ? "2,x86:VVdWU4PsCItsJCiLfCQki0QkIMHtAg+v/Yk8JIX/dGeFwHRjjTytAAAAAIl8JASLfCQcjTSHMf+NtCYAAAAAkItEJByNDLiNtCYAAAAAZpCLEYPBBInQidOB4v8AAP/30PfTgPL/JQAA/wCB4wD/AAAJ2AnQiUH8OfF11AHvA3QkBDs8JHK5g8QIMcBbXl9dww=="
        : "2,x64:V1ZTQcHpAkSJx0iJzonTQQ+v+YX/dFNFMcCF0nRMZpBEicEPH0QAAInIg8EBTI0chkGLE4nQQYnSgeL/AAD/99BB99KA8v8lAAD/AEGB4gD/AABECdAJ0EGJAznLdclFAchEActBOfhytjHAW15fww==")
        /*
            unsigned int Convert_Monochrome(unsigned int bitmap[], unsigned int w, unsigned int h, unsigned int Stride, unsigned int threshold)
            {
                unsigned int a, r, g, b, ARGB;
                unsigned int x, y, offset = Stride / 4;
                for (y = 0; y < h * offset; y += offset) {
                    for (x = 0; x < w; ++x) {
                        ARGB = bitmap[x + y];
                        a = ARGB & 0xFF000000;
                        r = (ARGB & 0x00FF0000) >> 16;
                        g = (ARGB & 0x0000FF00) >> 8;
                        b = (ARGB & 0x000000FF);
                        unsigned int luminance = (77 * r + 150 * g + 29 * b) >> 8;
                        bitmap[x + y] = (luminance > threshold) ? 0xFFFFFFFF : 0xFF000000;
                    }
                }
                return 0;
            }
        */
        this.MonochromeMCode := this.MCode((A_PtrSize = 4)
        ? "2,x86:VVdWU4PsDIt0JCyLTCQoi0QkJIt8JDDB7gIPr86JNCSJTCQEhcl0aYXAdGXB5gIx7Yl0JAiLdCQgjTSGjXQmAItEJCCNDKiNtCYAAAAAZpCLEYnTD7bGD7bSwesQacCWAAAAD7bba9Ida9tNAdgB0MHoCDn4dinHAf////+DwQQ58XXMAywkA3QkCDlsJAR3r4PEDDHAW15fXcONdCYAkMcBAAAA/4PBBDnxdaMDLCQDdCQIOWwkBHeG69U="
        : "2,x64:VVdWU4t0JEhBwekCRInHSInLQYnTQQ+v+YX/dFyF0nRYRTHADx9AAESJwQ8fRAAAichMjRSDQYsSidUPtsYPttLB7RBpwJYAAABAD7bta9Ida+1NAegB0MHoCDnwdiGDwQFBxwL/////QTnLdcJFAchFActEOcd3rzHAW15fXcODwQFBxwIAAAD/RDnZdaFFAchFActEOcd3juvd")
    }

    /**
     * Returns an OCR results object for an IRandomAccessStream.
     * Images of other types should be first converted to this format (eg from file, from bitmap).
     * @param RandomAccessStreamOrSoftwareBitmap Pointer or an object containing a ptr to a RandomAccessStream or SoftwareBitmap
     * @param {String} lang OCR language. Default is first from available languages.
     * @param {Integer|Object} transform Either a scale factor number, or an object {scale:Float, grayscale:Boolean, invertcolors:Boolean, monochrome:0-255, rotate: 0 | 90 | 180 | 270, flip: 0 | "x" | "y"}
     * @param {String} decoder Optional bitmap codec name to decode RandomAccessStream. Default is automatic detection.
     *  Possible values are gif, ico, jpeg, jpegxr, png, tiff, bmp.
     * @returns {OCR.Result} 
     */
    static Call(RandomAccessStreamOrSoftwareBitmap, Options:=0) {
        local SoftwareBitmap := 0, RandomAccessStream := 0, lang:="FirstFromAvailableLanguages", width, height, x := 0, y := 0, w := 0, h := 0, scale, grayscale, invertcolors, monochrome, OcrResult := this.Result(), Result, transform := 0, decoder := 0
        this.__ExtractTransformParameters(Options, &transform)
        scale := transform.scale, grayscale := transform.grayscale, invertcolors := transform.invertcolors, monochrome := transform.monochrome, rotate := transform.rotate, flip := transform.flip
        this.__ExtractNamedParameters(Options, "x", &x, "y", &y, "w", &w, "h", &h, "language", &lang, "lang", &lang, "decoder", &decoder)
        this.LoadLanguage(lang)
        local customRegion := x || y || w || h

        try SoftwareBitmap := ComObjQuery(RandomAccessStreamOrSoftwareBitmap, "{689e0708-7eef-483f-963f-da938818e073}") ; ISoftwareBitmap
        if SoftwareBitmap {
            ComCall(8, SoftwareBitmap, "uint*", &width:=0)   ; get_PixelWidth
            ComCall(9, SoftwareBitmap, "uint*", &height:=0)   ; get_PixelHeight
            this.ImageWidth := width, this.ImageHeight := height
            if (Floor(width*scale) > this.MaxImageDimension) or (Floor(height*scale) > this.MaxImageDimension)
               throw ValueError("Image is too big - " width "x" height ".`nIt should be maximum - " this.MaxImageDimension " pixels (with scale applied)")
            if scale != 1 || customRegion || rotate || flip
                SoftwareBitmap := this.TransformSoftwareBitmap(SoftwareBitmap, &width, &height, scale, rotate, flip, x?, y?, w?, h?)
            goto SoftwareBitmapCommon
        }
        RandomAccessStream := RandomAccessStreamOrSoftwareBitmap

        if decoder {
            ComCall(this.Vtbl_GetDecoder.%decoder%, this.BitmapDecoderStatics, "ptr", DecoderGUID:=Buffer(16))
            ComCall(15, this.BitmapDecoderStatics, "ptr", DecoderGUID, "ptr", RandomAccessStream, "ptr*", BitmapDecoder:=ComValue(13,0))   ; CreateAsync
        } else
            ComCall(14, this.BitmapDecoderStatics, "ptr", RandomAccessStream, "ptr*", BitmapDecoder:=ComValue(13,0))   ; CreateAsync
            this.WaitForAsync(&BitmapDecoder)

        BitmapFrame := ComObjQuery(BitmapDecoder, IBitmapFrame := "{72A49A1C-8081-438D-91BC-94ECFC8185C6}")
        ComCall(12, BitmapFrame, "uint*", &width:=0)   ; get_PixelWidth
        ComCall(13, BitmapFrame, "uint*", &height:=0)   ; get_PixelHeight
        if (width > this.MaxImageDimension) or (height > this.MaxImageDimension)
           throw ValueError("Image is too big - " width "x" height ".`nIt should be maximum - " this.MaxImageDimension " pixels")

        BitmapFrameWithSoftwareBitmap := ComObjQuery(BitmapDecoder, IBitmapFrameWithSoftwareBitmap := "{FE287C9A-420C-4963-87AD-691436E08383}")
        OcrResult.ImageWidth := width, OcrResult.ImageHeight := height
        if !(customRegion || rotate || flip) && (width < 40 || height < 40 || scale != 1) {
            scale := scale = 1 ? 40.0 / Min(width, height) : scale
            ComCall(7, this.BitmapTransform, "int", width := Floor(width*scale)) ; put_ScaledWidth
            ComCall(9, this.BitmapTransform, "int", height := Floor(height*scale)) ; put_ScaledHeight
            ComCall(8, BitmapFrame, "uint*", &BitmapPixelFormat:=0) ; get_BitmapPixelFormat
            ComCall(9, BitmapFrame, "uint*", &BitmapAlphaMode:=0) ; get_BitmapAlphaMode
            ComCall(8, BitmapFrameWithSoftwareBitmap, "uint", BitmapPixelFormat, "uint", BitmapAlphaMode, "ptr", this.BitmapTransform, "uint", IgnoreExifOrientation := 0, "uint", DoNotColorManage := 0, "ptr*", SoftwareBitmap:=this.IBase()) ; GetSoftwareBitmapAsync
        } else {
            ComCall(6, BitmapFrameWithSoftwareBitmap, "ptr*", SoftwareBitmap:=this.IBase())   ; GetSoftwareBitmapAsync
        }
        this.WaitForAsync(&SoftwareBitmap)
        if customRegion || rotate || flip || scale != 1
            SoftwareBitmap := this.TransformSoftwareBitmap(SoftwareBitmap, &width, &height, scale, rotate, flip, x?, y?, w?, h?)

        SoftwareBitmapCommon:

        if (grayscale || invertcolors || monochrome || this.DisplayImage) {
            ComCall(15, SoftwareBitmap, "int", 2, "ptr*", &BitmapBuffer := 0) ; LockBuffer
            MemoryBuffer := ComObjQuery(BitmapBuffer, "{fbc4dd2a-245b-11e4-af98-689423260cf8}")
            ComCall(6, MemoryBuffer, "ptr*", &MemoryBufferReference := 0) ; CreateReference
            BufferByteAccess := ComObjQuery(MemoryBufferReference, "{5b0d3235-4dba-4d44-865e-8f1d0e4fd04d}")
            ComCall(3, BufferByteAccess, "ptr*", &SoftwareBitmapByteBuffer:=0, "uint*", &BufferSize:=0) ; GetBuffer
           
            if grayscale
                DllCall(this.GrayScaleMCode, "ptr", SoftwareBitmapByteBuffer, "uint", width, "uint", height, "uint", (width*4+3) // 4 * 4, "cdecl uint")

            if monochrome
                DllCall(this.MonochromeMCode, "ptr", SoftwareBitmapByteBuffer, "uint", width, "uint", height, "uint", (width*4+3) // 4 * 4, "uint", monochrome, "cdecl uint")
            
            if invertcolors
                DllCall(this.InvertColorsMCode, "ptr", SoftwareBitmapByteBuffer, "uint", width, "uint", height, "uint", (width*4+3) // 4 * 4, "cdecl uint")
    
            if this.DisplayImage {
                local hdc := DllCall("GetDC", "ptr", 0, "ptr"), bi := Buffer(40, 0), hbm
                NumPut("uint", 40, "int", width, "int", -height, "ushort", 1, "ushort", 32, bi)
                hbm := DllCall("CreateDIBSection", "ptr", hdc, "ptr", bi, "uint", 0, "ptr*", &ppvBits:=0, "ptr", 0, "uint", 0, "ptr")
                DllCall("ntdll\memcpy", "ptr", ppvBits, "ptr", SoftwareBitmapByteBuffer, "uint", BufferSize, "cdecl")
                DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdc, "Int")
                this.DisplayHBitmap(hbm)
            }
            
            BufferByteAccess := "", ObjRelease(MemoryBufferReference), MemoryBuffer := "", ObjRelease(BitmapBuffer) ; Release in correct order
        }

        ComCall(6, this.OcrEngine, "ptr", SoftwareBitmap, "ptr*", Result:=ComValue(13,0))   ; RecognizeAsync
        this.WaitForAsync(&Result)
        OcrResult.Ptr := Result.Ptr, ObjAddRef(OcrResult.ptr)

        ; Cleanup
        if RandomAccessStream is this.IBase
            this.CloseIClosable(RandomAccessStream)
        if SoftwareBitmap is this.IBase
            this.CloseIClosable(SoftwareBitmap)

        if scale != 1 || x != 0 || y != 0
            this.NormalizeCoordinates(OcrResult, scale, x, y)

        return OcrResult
    }

    static ClearAllHighlights() => this.Result.Prototype.Highlight("clearall")

    class Result extends OCR.Common {
        ; Gets the recognized text.
        Text {
            get {
                ComCall(8, this, "ptr*", &hAllText:=0)   ; get_Text
                buf := DllCall("Combase.dll\WindowsGetStringRawBuffer", "ptr", hAllText, "uint*", &length:=0, "ptr")
                this.DefineProp("Text", {Value:StrGet(buf, "UTF-16")})
                this.__OCR.DeleteHString(hAllText)
                return this.Text
            }
        }

        ; Gets the clockwise rotation of the recognized text, in degrees, around the center of the image.
        TextAngle {
            get => (ComCall(7, this, "double*", &value:=0), value)
        }

        ; Returns all Line objects for the result.
        Lines {
            get {
                ComCall(6, this, "ptr*", LinesList:=ComValue(13, 0)) ; get_Lines
                ComCall(7, LinesList, "int*", &count:=0) ; count
                lines := []
                loop count {
                    ComCall(6, LinesList, "int", A_Index-1, "ptr*", Line:=this.__OCR.Line(this)) 
                    lines.Push(Line)
                }
                this.DefineProp("Lines", {Value:lines})
                return lines
            }
        }

        ; Returns all Word objects for the result. Equivalent to looping over all the Lines and getting the Words.
        Words {
            get {
                local words := [], line, word
                for line in this.Lines
                    for word in line.Words
                        words.Push(word)
                this.DefineProp("Words", {Value:words})
                return words
            }
        }

        BoundingRect {
            get => this.DefineProp("BoundingRect", {Value:this.__OCR.WordsBoundingRect(this.Words*)}).BoundingRect
        }

        /**
         * Finds a string in the search results, and returns a new Result object.
         * If the match is partial then the result will contain the whole word: in "hello world" searching "wo" will return "world".
         * To force a full word search instead of a partial search, use IgnoreLinebreaks:True 
         *  and add a space to the beginning and end: " hello "
         * To search multi-line matches, set IgnoreLinebreaks:True and use a linebreak in the needle: "hello`nworld"
         * @param Needle The string to find. 
         * @param Options Extra search options object, which can contain the following properties:
         *  CaseSense: False (this is ignored if a custom SearchFunc is used)
         *  IgnoreLinebreaks: False (if this is True, then linebreaks are converted to whitespaces, otherwise remain `n)
         *  AllowOverlap: False (if True then the needle can overlap itself)
         *  i: 1 (which occurrence of the needle to find)
         *  x, y, w, h: defines the search area inside the result object
         *  SearchFunc: default is InStr, but if a custom function is provided then it needs to return
         *      the needle location in the haystack, and accept arguments (Haystack, Needle, &FoundMatch)
         *      This can used for example to perform a RegEx search by providing RegExMatch
         * @returns {Object} 
         */
        FindString(Needle, Options := "") => this.__FindString(Needle, Options, 0)

        /**
         * Finds all strings matching the needle in the search results. Returns an array of Result objects.
         * @param Needle The string to find. 
         * @param Options See Result.FindString. {CaseSense: False, IgnoreLinebreaks: False, AllowOverlap: false, i: 1, x, y, w, h, SearchFunc}
         *  If i is specified then the result object will contains matches starting from i.
         * @returns {Array} 
         */
        FindStrings(Needle, Options := "") => this.__FindString(Needle, Options, true)

        __FindString(Needle, Options, All) {
            local CaseSense := false, IgnoreLinebreaks := false, AllowOverlap := false, i := 1, SearchFunc, x, y, w, h
            local currentHaystack, fullHaystackLinebreaks := "`n", offset := 0, line, counter := 0, x1, y1, x2, y2, result, results := [], word

            if !(Needle is String)
                throw TypeError("Needle is required to be a string, not type " Type(Needle), -1)
            if Trim(Needle, " `t`n`r") == ""
                throw ValueError("Needle cannot be an empty string", -1)

            this.__OCR.__ExtractNamedParameters(Options, "CaseSense", &CaseSense, "IgnoreLinebreaks", &IgnoreLinebreaks, "AllowOverlap", &AllowOverlap, "i", &i, "SearchFunc", &SearchFunc, "x", &x, "y", &y, "w", &w, "h", &h)

            if !IsSet(SearchFunc)
                SearchFunc := (haystack, needle, &foundstr) => (pos := InStr(haystack, needle, casesense), foundstr := SubStr(haystack, pos, StrLen(needle)), pos)

            if (IsSet(x) || IsSet(y) || IsSet(w) || IsSet(h)) {
                x1 := x ?? -100000, y1 := y ?? -100000, x2 := IsSet(w) ? x + w : 100000, y2 := IsSet(h) ? y + h : 100000 
            }

            tokenizedHaystack := [IgnoreLinebreaks ? " " : "`n"]
            for Line in this.Lines {
                fullHaystackLinebreaks .= line.Text "`n"
                for Word in Line.Words
                    tokenizedHaystack.Push(Word, " ")
                tokenizedHaystack.Pop()
                tokenizedHaystack.Push(IgnoreLinebreaks ? " " : "`n")
            }

            fullHaystackNoLinebreaks := StrReplace(fullHaystackLinebreaks, "`n", " ") ; Make sure the words are in the same order as the tokenized version
            fullHaystack := IgnoreLinebreaks ? fullHaystackNoLinebreaks : fullHaystackLinebreaks

            Needle := RegExReplace(StrReplace(Needle, "`t", " "), " +", " ")

            fullFirst := SubStr(Needle, 1, 1) ~= "[ \n]", fullLast := SubStr(Needle, -1, 1) ~= "[ \n]"

            currentHaystack := fullHaystack
            Loop {
                if !(loc := SearchFunc(currentHaystack, Needle, &foundNeedle))
                    break

                if IsObject(foundNeedle)
                    foundNeedle := foundNeedle[]

                foundLen := AllowOverlap ? 1 : StrLen(foundNeedle)
                currentHaystack := SubStr(currentHaystack, loc + foundLen) ; Remove the match from the haystack, allowing overlap
                offset += loc + foundLen - 1

                if ++counter < i
                    continue

                tokenizedNeedle := []
                ; Tokenize the needle
                for wsNeedle in wsSplit := StrSplit(foundNeedle, " ") {
                    for lbNeedle in lbSplit := StrSplit(wsNeedle, "`n") {
                        tokenizedNeedle.Push(lbNeedle, "`n")
                    }
                    if lbSplit.Length
                        tokenizedNeedle.Pop()
                    tokenizedNeedle.Push(" ")
                }
                tokenizedNeedle.Pop()
                
                preceding := SubStr(fullHaystackNoLinebreaks, 1, offset - foundLen)
                ; Find first Word location
                StrReplace(preceding, " ",,, &startingWord:=0)
                startingWord := startingWord*2 + fullFirst - 1 ; Substracted 1 to allow subsequent loop to just add A_Index

                foundNeedle := "", foundWords := [], foundLines := [], line := this.__OCR.Line(this), line.DefineProp("Words", {value:[]}), line.DefineProp("Text", {value:""})
                Loop tokenizedNeedle.Length {
                    word := tokenizedHaystack[startingWord + A_Index]
                    if (word == "`n") {
                        foundNeedle .= line.Text
                        line.Text := RTrim(line.Text), foundLines.Push(line)
                        line := this.__OCR.Line(this), line.DefineProp("Words", {value:[]}), line.DefineProp("Text", {value:""})
                    }
                    if !IsObject(word)
                        continue
                    If IsSet(x1) && (word.x < x1 || word.y < y1 || word.x+word.w > x2 || word.y+word.h > y2) {
                        counter--
                        continue 2
                    }
                    line.Words.Push(word), line.Text .= word.Text " "
                    foundWords.Push(word)
                }
                if line.Text {
                    foundNeedle .= line.Text
                    line.Text := RTrim(line.Text), foundLines.Push(line)
                }

                result := this.Clone(), ObjAddRef(this.ptr)
                result.DefineProp("BoundingRect", {value: this.__OCR.WordsBoundingRect(foundWords*)})
                result.DefineProp("Lines", {value: foundLines})
                result.DefineProp("Words", {value: foundWords})
                result.DefineProp("Text", {value: foundNeedle})
                if All {
                    results.Push(result)
                } else
                    return result
            }
            if All
                return results

            throw TargetError('The target string "' Needle '" was not found', -1)
        }
    
        /**
         * Filters out all the words that do not satisfy the callback function and returns a new OCR.Result object
         * @param {Object} callback The callback function that accepts a OCR.Word object.
         * If the callback returns 0 then the word is filtered out (rejected), otherwise is kept.
         * @returns {OCR.Result}
         */
        Filter(callback) {
            if !HasMethod(callback)
                throw ValueError("Filter callback must be a function", -1)
            local result := this.Clone(), line, croppedLines := [], croppedText := "", croppedWords := [], lineText := "", word
            ObjAddRef(result.ptr)
            for line in result.Lines {
                croppedWords := [], lineText := ""
                for word in line.Words {
                    if callback(word)
                        croppedWords.Push(word), lineText .= word.Text " "
                }
                if croppedWords.Length {
                    line := this.__OCR.Line()
                    line.DefineProp("Text", {value:Trim(lineText)})
                    line.DefineProp("Words", {value:croppedWords})
                    croppedLines.Push(line)
                    croppedText .= lineText
                }
            }
            result.DefineProp("Lines", {Value:croppedLines})
            result.DefineProp("Text", {Value:Trim(croppedText)})
            result.DefineProp("Words", this.__OCR.Result.Prototype.GetOwnPropDesc("Words"))
            return result
        }
    
        /**
         * Crops the result object to contain only results from an area defined by points (x1,y1) and (x2,y2).
         * Note that these coordinates are relative to the result object, not to the screen.
         * @param {Integer} x1 x coordinate of the top left corner of the search area
         * @param {Integer} y1 y coordinate of the top left corner of the search area
         * @param {Integer} x2 x coordinate of the bottom right corner of the search area
         * @param {Integer} y2 y coordinate of the bottom right corner of the search area
         * @returns {OCR.Result}
         */
        Crop(x1:=-100000, y1:=-100000, x2:=100000, y2:=100000) => this.Filter((word) => word.x >= x1 && word.y >= y1 && (word.x+word.w) <= x2 && (word.y+word.h) <= y2)
    }
    class Line extends OCR.Common {
        ; Gets the recognized text for the line.
        Text {
            get {
                ComCall(7, this, "ptr*", &hText:=0)   ; get_Text
                buf := DllCall("Combase.dll\WindowsGetStringRawBuffer", "ptr", hText, "uint*", &length:=0, "ptr")
                text := StrGet(buf, "UTF-16")
                this.__OCR.DeleteHString(hText)
                this.DefineProp("Text", {Value:text})
                return text
            }
        }

        ; Gets the Word objects for the line
        Words {
            get {
                ComCall(6, this, "ptr*", WordsList:=ComValue(13, 0))   ; get_Words
                ComCall(7, WordsList, "int*", &WordsCount:=0)   ; Words count
                words := []
                loop WordsCount {
                   ComCall(6, WordsList, "int", A_Index-1, "ptr*", Word:=this.__OCR.Word(this))
                   words.Push(Word)
                }
                this.DefineProp("Words", {Value:words})
                return words
            }
        }

        BoundingRect {
            get => this.DefineProp("BoundingRect", {Value:this.__OCR.WordsBoundingRect(this.Words*)}).BoundingRect
        }
    }

    class Word extends OCR.Common {
        ; Gets the recognized text for the word
        Text {
            get {
                ComCall(7, this, "ptr*", &hText:=0)   ; get_Text
                buf := DllCall("Combase.dll\WindowsGetStringRawBuffer", "ptr", hText, "uint*", &length:=0, "ptr")
                text := StrGet(buf, "UTF-16")
                this.__OCR.DeleteHString(hText)
                this.DefineProp("Text", {Value:text})
                return text
            }
        }

        /**
         * Gets the bounding rectangle of the text in {x,y,w,h} format. 
         * The bounding rectangles coordinate system will be dependant on the image capture method.
         * For example, if the image was captured as a rectangle from the screen, then the coordinates
         * will be relative to the left top corner of the screen.
         */
        BoundingRect {
            get {
                ComCall(6, this, "ptr", RECT := Buffer(16, 0))   
                this.DefineProp("x", {Value:Integer(NumGet(RECT, 0, "float"))})
                , this.DefineProp("y", {Value:Integer(NumGet(RECT, 4, "float"))})
                , this.DefineProp("w", {Value:Integer(NumGet(RECT, 8, "float"))})
                , this.DefineProp("h", {Value:Integer(NumGet(RECT, 12, "float"))})
                return this.DefineProp("BoundingRect", {Value:{x:this.x, y:this.y, w:this.w, h:this.h}}).BoundingRect
            }
        }
    }

    class Common extends OCR.IBase {
        x {
            get => this.BoundingRect.x
        } 
        y {
            get => this.BoundingRect.y
        }
        w {
            get => this.BoundingRect.w
        }
        h {
            get => this.BoundingRect.h
        }
    
        /**
         * Highlights the object on the screen with a red box
         * @param {number} showTime Default is 2 seconds.
         * * Unset - if highlighting exists then removes the highlighting, otherwise pauses for 2 seconds
         * * 0 - Indefinite highlighting
         * * Positive integer (eg 2000) - will highlight and pause for the specified amount of time in ms
         * * Negative integer - will highlight for the specified amount of time in ms, but script execution will continue
         * * "clear" - removes the highlighting unconditionally
         * * "clearall" - remove highlightings from all OCR objects
         * @param {string} color The color of the highlighting. Default is red.
         * @param {number} d The border thickness of the highlighting in pixels. Default is 2.
         * @returns {OCR.Result}
         */
        Highlight(showTime?, color:="Red", d:=2) {
            static Guis := Map()
            local x, y, w, h, key, oObj, GuiObj, iw, ih
            if IsSet(showTime) {
                if showTime = "clearall" {
                    for key, oObj in Guis { 
                        try oObj.GuiObj.Destroy()
                        SetTimer(oObj.TimerObj, 0)
                    }
                    Guis := Map()
                    return this
                } else if showTime = "clear" {
                    if Guis.Has(this) {
                        try Guis[this].GuiObj.Destroy()
                        SetTimer(Guis[this].TimerObj, 0)
                        Guis.Delete(this)
                    }
                    return this
                }
            }
    
            if !IsSet(showTime) {
                if Guis.Has(this) {
                    try Guis[this].GuiObj.Destroy()
                    SetTimer(Guis[this].TimerObj, 0)
                    Guis.Delete(this)
                    return this
                } else
                    showTime := 2000
            }
    
            x := this.x, y := this.y, w := this.w, h := this.h
            if this.HasProp("Relative") {
                if this.Relative.HasProp("CoordMode") {
                    if this.Relative.CoordMode = "Client"
                        WinGetClientPos(&rX, &rY,,, this.Relative.hWnd), x += rX, y += rY
                    else if this.Relative.CoordMode = "Window"
                        WinGetPos(&rX, &rY,,, this.Relative.hWnd), x += rX, y += rY
                }
                x += this.Relative.HasProp("x") ? this.Relative.x : 0
                y += this.Relative.HasProp("y") ? this.Relative.y : 0
            }
    
            if !Guis.Has(this) {
                Guis[this] := {}
                Guis[this].GuiObj := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000")
                Guis[this].TimerObj := ObjBindMethod(this, "Highlight", "clear")
            }
            GuiObj := Guis[this].GuiObj
            GuiObj.BackColor := color
            iw:= w+d, ih:= h+d, w:=w+d*2, h:=h+d*2, x:=x-d, y:=y-d
            WinSetRegion("0-0 " w "-0 " w "-" h " 0-" h " 0-0 " d "-" d " " iw "-" d " " iw "-" ih " " d "-" ih " " d "-" d, GuiObj.Hwnd)
            GuiObj.Show("NA x" . x . " y" . y . " w" . w . " h" . h)
    
            if showTime > 0 {
                Sleep(showTime)
                this.Highlight()
            } else if showTime < 0
                SetTimer(Guis[this].TimerObj, -Abs(showTime))
            return this
        }
        ClearHighlight() => this.Highlight("clear")
    
        /**
         * Clicks an object
         * If this object (the one Click is called from) contains a "Relative" property (this is
         * added by default with OCR.FromWindow) containing a hWnd property, then that window will be activated,
         * otherwise the Relative objects x/y properties values will be added to the x and y coordinates as offsets.
         */
        Click(WhichButton?, ClickCount?, DownOrUp?) {
            local x := this.x, y := this.y, w := this.w, h := this.h, mode := "Screen", hwnd
            if this.HasProp("Relative") {
                if this.Relative.HasProp("CoordMode") {
                    if this.Relative.CoordMode = "Window"
                        mode := "Window", hwnd := this.Relative.Hwnd
                    else if this.Relative.CoordMode = "Client"
                        mode := "Client", hwnd := this.Relative.Hwnd
                    if IsSet(hwnd) && !WinActive(hwnd) {
                        WinActivate(hwnd)
                        WinWaitActive(hwnd,,1)
                    }
                }
                x += this.Relative.HasProp("x") ? this.Relative.x : 0
                y += this.Relative.HasProp("y") ? this.Relative.y : 0
            }
            oldCoordMode := A_CoordModeMouse
            CoordMode "Mouse", mode
            Click(x+w//2, y+h//2, WhichButton?, ClickCount?, DownOrUp?)
            CoordMode "Mouse", oldCoordMode
        }
    
        /**
         * ControlClicks an object.
         * If the result object originates from OCR.FromWindow which captured only the client area,
         * then the result object will contain correct coordinates for the ControlClick. 
         * Coordinates will be adjusted to Client area from the CoordMode that the OCR happened in.
         * Otherwise, if additionally a WinTitle is provided then the coordinates are treated as Screen 
         * coordinates and converted to Client coordinates.
         * @param WinTitle If WinTitle is set, then the coordinates stored in Obj will be converted to
         * client coordinates and ControlClicked.
         */
        ControlClick(WinTitle?, WinText?, WhichButton?, ClickCount?, Options?, ExcludeTitle?, ExcludeText?) {
            local x := this.x, y := this.y, w := this.w, h := this.h, hWnd
            if this.HasProp("Relative") {
                x += this.Relative.HasProp("x") ? this.Relative.x : 0
                y += this.Relative.HasProp("y") ? this.Relative.y : 0
            }
            if this.HasProp("Relative") && this.Relative.HasProp("CoordMode") && (this.Relative.CoordMode = "Client" || this.Relative.CoordMode = "Window") {
                mode := this.Relative.CoordMode, hWnd := this.Relative.hWnd
                if mode = "Window" {
                    RECT := Buffer(16, 0), pt := Buffer(8, 0)
                    DllCall("user32\GetWindowRect", "Ptr", hWnd, "Ptr", RECT)
                    winX := NumGet(RECT, 0, "Int"), winY := NumGet(RECT, 4, "Int")
                    NumPut("int", winX+x, "int", winY+y, pt)
                    DllCall("user32\ScreenToClient", "Ptr", hWnd, "Ptr", pt)
                    x := NumGet(pt,0,"int"), y := NumGet(pt,4,"int")
                }
            } else if IsSet(WinTitle) {
                hWnd := WinExist(WinTitle, WinText?, ExcludeTitle?, ExcludeText?)
                pt := Buffer(8), NumPut("int",x,pt), NumPut("int", y,pt,4)
                DllCall("ScreenToClient", "Int", Hwnd, "Ptr", pt)
                x := NumGet(pt,0,"int"), y := NumGet(pt,4,"int")
            } else
                throw TargetError("ControlClick needs to be called either after a OCR.FromWindow result or with a WinTitle argument")
                
            ControlClick("X" (x+w//2) " Y" (y+h//2), hWnd,, WhichButton?, ClickCount?, Options?)
        }
    
        OffsetCoordinates(offsetX?, offsetY?) {
            if !IsSet(offsetX) || !IsSet(offsetY) {
                if this.HasOwnProp("Relative") {
                    offsetX := this.Relative.HasProp("x") ? this.Relative.X : 0
                    offsetY := this.Relative.HasProp("y") ? this.Relative.Y : 0
                } else
                    throw Error("No Relative property found",, -1)
            }
            if offsetX = 0 && offsetY = 0
                return this
            local word
            for word in this.Words
                word.x += offsetX, word.y += offsetY, word.BoundingRect := {X:word.x, Y:word.y, W:word.w, H:word.h}
            return this
        }
    }

    /**
     * Returns an OCR results object for an image file. Locations of the words will be relative to
     * the top left corner of the image.
     * @param FileName Either full or relative (to A_WorkingDir) path to the file.
     * @param lang OCR language. Default is first from available languages.
     * @param transform Either a scale factor number, or an object {scale:Float, grayscale:Boolean, invertcolors:Boolean, monochrome:0-255, rotate: 0 | 90 | 180 | 270, flip: 0 | "x" | "y"}
     * @returns {OCR.Result} 
     */
    static FromFile(FileName, Options:=0) {
        if !(fe := FileExist(FileName)) or InStr(fe, "D")
            throw TargetError("File `"" FileName "`" doesn't exist", -1)
        GUID := this.CLSIDFromString(this.IID_IRandomAccessStream)
        DllCall("ShCore\CreateRandomAccessStreamOnFile", "wstr", FileName, "uint", Read := 0, "ptr", GUID, "ptr*", IRandomAccessStream:=this.IBase())
        if IsObject(Options) && !Options.HasProp("Decoder")
            Options.Decoder := this.Vtbl_GetDecoder.HasOwnProp(ext := StrSplit(FileName, ".")[-1]) ? ext : ""
        return this(IRandomAccessStream, Options)
    }

    /**
     * Returns an array of OCR results objects for a PDF file. Locations of the words will be relative to
     * the top left corner of the PDF page.
     * @param FileName Either full or relative (to A_WorkingDir) path to the file.
     * @param Options Optional: OCR options {lang, scale, grayscale, invertcolors, rotate, flip, x, y, w, h, decoder}. 
     * @param Start Optional: Page number to start from. Default is first page.
     * @param End Optional: Page number to end with (included). Default is last page.
     * @param Password Optional: PDF password.
     * @returns {OCR.Result} 
     */
    static FromPDF(FileName, Options:=0, Start:=1, End?, Password:="") {
        this.__ExtractNamedParameters(Options, "lang", &lang, "start", &Start, "end", &End, "password", &Password)
        if !(fe := FileExist(FileName)) or InStr(fe, "D")
            throw TargetError("File `"" FileName "`" doesn't exist", -1)

        DllCall("ShCore\CreateRandomAccessStreamOnFile", "wstr", FileName, "uint", Read := 0, "ptr", GUID := this.CLSIDFromString(this.IID_IRandomAccessStream), "ptr*", IRandomAccessStream:=ComValue(13,0))
        PdfDocument := this.__OpenPdfDocument(IRandomAccessStream, Password)
        this.CloseIClosable(IRandomAccessStream)
        if !IsSet(End) {
            ComCall(7, PdfDocument, "uint*", &End:=0) 
            if !End
                throw Error("Unable to get PDF page count", -1)
        }
        local results := []
        Loop (End+1-Start)
            results.Push(this.FromPDFPage(PdfDocument, Start+(A_Index-1), Options))
        return results
    }

    static GetPdfPageCount(FileName, Password:="") {
        DllCall("ShCore\CreateRandomAccessStreamOnFile", "wstr", FileName, "uint", Read := 0, "ptr", GUID := this.CLSIDFromString(this.IID_IRandomAccessStream), "ptr*", IRandomAccessStream:=ComValue(13,0))
        PdfDocument := this.__OpenPdfDocument(IRandomAccessStream, Password)
        this.CloseIClosable(IRandomAccessStream)
        ComCall(7, PdfDocument, "uint*", &PageCount:=0) 
        if !PageCount
            throw Error("Unable to get PDF page count", -1)
        
        return PageCount
    }

    static GetPdfPageProperties(FileName, Page, Password:="") {
        DllCall("ShCore\CreateRandomAccessStreamOnFile", "wstr", FileName, "uint", Read := 0, "ptr", GUID := this.CLSIDFromString(this.IID_IRandomAccessStream), "ptr*", IRandomAccessStream:=ComValue(13,0))
        PdfDocument := this.__OpenPdfDocument(IRandomAccessStream, Password)
        this.CloseIClosable(IRandomAccessStream)
        ComCall(6, PdfDocument, "uint", Page-1, "ptr*", PdfPage:=ComValue(13, 0)) 
        ComCall(10, PdfPage, "ptr*", Size:=Buffer(8, 0)) 
        ComCall(12, PdfPage, "uint*", &Rotation:=0)
        ComCall(12, PdfPage, "float*", &PreferredZoom:=0)
        return {Width: NumGet(Size, 0, "float"), Height: NumGet(size, 4, "float"), Rotation: Rotation*90, PreferredZoom:PreferredZoom}
    }

    /**
     * Returns an OCR result object for a PDF page. Locations of the words will be relative to
     * the top left corner of the PDF page.
     * @param FileName Either full or relative (to A_WorkingDir) path to the file.
     * @param Page The page number to OCR.
     * @param Options Optional: OCR options {lang, scale, grayscale, invertcolors, rotate, flip, x, y, w, h, decoder}. 
     * @param Password Optional: PDF password.
     * @returns {OCR.Result} 
     */
    static FromPDFPage(FileName, Page, Options:=0, Password:="") {
        local scale := 1, x := 0, y := 0, w := 0, h := 0
        if IsObject(Options)
            Options := Options.Clone()
        this.__ExtractNamedParameters(Options, "Password", &Password, "scale", &scale, "x", &x, "y", &y, "w", &w, "h", &h)
        if FileName is String {
            if !(fe := FileExist(FileName)) or InStr(fe, "D")
                throw TargetError("File `"" FileName "`" doesn't exist", -1)
            GUID := this.CLSIDFromString(this.IID_IRandomAccessStream)
            DllCall("ShCore\CreateRandomAccessStreamOnFile", "wstr", FileName, "uint", Read := 0, "ptr", GUID, "ptr*", IRandomAccessStream:=ComValue(13, 0))
            PdfDocument := this.__OpenPdfDocument(IRandomAccessStream, Password)
        } else
            PdfDocument := FileName
        ComCall(6, PdfDocument, "uint", Page-1, "ptr*", PdfPage:=ComValue(13, 0)) 
        InMemoryRandomAccessStream := this.CreateClass("Windows.Storage.Streams.InMemoryRandomAccessStream")
        PdfPageRenderOptions := this.CreateClass("Windows.Data.Pdf.PdfPageRenderOptions")
        ComCall(15, PdfPageRenderOptions, "uint", true) 
        if x || y || w || h {
            rect := Buffer(16, 0), NumPut("float", x, "float", y, "float", w, "float", h, rect)
            ComCall(7, PdfPageRenderOptions, "ptr", rect) 
            Options.w := Options.w*scale, Options.h := Options.h*scale
            Options.DeleteProp("x"), Options.DeleteProp("y"), Options.DeleteProp("w"), Options.DeleteProp("h")
        }
        if (scale != 1) {
            ComCall(10, PdfPage, "ptr", Size:=Buffer(8, 0)) 
            ComCall(9, PdfPageRenderOptions, "uint", Floor((w || NumGet(size, 0, "float"))*scale)) 
            ComCall(11, PdfPageRenderOptions, "uint", Floor((h || NumGet(size, 4, "float"))*scale)) 
            Options.DeleteProp("scale")
        }
        ComCall(7, PdfPage, "ptr", InMemoryRandomAccessStream, "ptr", PdfPageRenderOptions, "ptr*", asyncInfo:=ComValue(13, 0)) 
        this.WaitForAsync(&asyncInfo)
        if FileName is String
            this.CloseIClosable(IRandomAccessStream)
        PdfPage := "", PdfDocument := "", IRandomAccessStream := ""
        OcrResult := this(InMemoryRandomAccessStream, Options)
        if scale != 1
            this.NormalizeCoordinates(OcrResult, scale)
        return OcrResult
    }

    /**
     * Returns an OCR results object for a given window. Locations of the words will be relative
     * using the CoordMode from A_CoordModePixel (default is Client). 
     * The window from where the image was captured is stored in Result.Relative.hWnd
     * Additionally, Result.Relative.CoordMode is stored (the A_CoordModePixel at the time of OCR).
     * @param WinTitle A window title or other criteria identifying the target window.
     * @param Options Optional: OCR options {lang, scale, grayscale, invertcolors, rotate, flip, x, y, w, h, decoder}. 
     * Additionally for FromWindow the options may include:
     *      mode:  Different methods of capturing the window. 
     *        0 = uses GetDC with BitBlt
     *        1 = same as 0 but window transparency is turned off beforehand with WinSetTransparent
     *        2 = uses PrintWindow. 
     *        3 = same as 1 but window transparency is turned off beforehand with WinSetTransparent
     *        4 = uses PrintWindow with undocumented PW_RENDERFULLCONTENT flag, allowing capture of hardware-accelerated windows
     *        5 = uses Direct3D11 from UWP Windows.Graphics.Capture (slowest option, but may work with games) 
     *             This may draw a yellow border around the target window in older Windows versions.
     * @param WinText Additional window criteria.
     * @param ExcludeTitle Additional window criteria.
     * @param ExcludeText Additional window criteria.
     * @returns {OCR.Result} 
     */
    static FromWindow(WinTitle:="", Options:=0, WinText:="", ExcludeTitle:="", ExcludeText:="") {
        local result, coordsmode := A_CoordModePixel, onlyClientArea := coordsMode = "Client", mode := 4, X := 0, Y := 0, W := 0, H := 0, sX, sY, hBitMap, hwnd, customRect := 0, transform := 0
        if !Options && Type(WinTitle) = "Object"
            Options := WinTitle, WinTitle := ""
        if IsObject(Options)
            Options := Options.Clone()
        this.__ExtractTransformParameters(Options, &transform)
        this.__ExtractNamedParameters(Options, "x", &x, "y", &y, "w", &w, "width", &w, "h", &h, "height", &h, "mode", &mode, "WinTitle", &WinTitle, "WinText", &WinText, "ExcludeTitle", &ExcludeTitle, "ExcludeText", &ExcludeText)
        this.__DeleteProps(Options, "x", "y", "w", "width", "h", "height", "scale", "mode")
        if (x !=0 || y != 0 || w != 0 || h != 0)
            customRect := 1
        if !(hWnd := WinExist(WinTitle, WinText, ExcludeTitle, ExcludeText))
            throw TargetError("Target window not found", -1)
        if DllCall("IsIconic", "uptr", hwnd)
            DllCall("ShowWindow", "uptr", hwnd, "int", 4)
        if mode < 4 && mode&1 {
            oldStyle := WinGetExStyle(hwnd), i := 0
            WinSetTransparent(255, hwnd)
            While (WinGetTransparent(hwnd) != 255 && ++i < 30)
                Sleep 100
        }

        WinGetPos(&wX, &wY, &wW, &wH, hWnd)
        If onlyClientArea {
            WinGetClientPos(&cX, &cY, &cW, &cH, hWnd)
            W := W || cW, H := H || cH, sX := X + cX, sY := Y + cY  
        } else {
            W := W || wW, H := H || wH, sX := X + wX, sY := Y + wY
        }

        if mode = 5 {
            /*
                If we are capturing the whole window, then WinGetPos/MouseGetPos might include hidden borders.
                Eg (0,0) might be (-11, -11) for Direct3D, meaning (11,11) by WinGetPos is (0,0) for Direct3D.
                These offsets are calculated and stored in offsetX, offsetY, and if only the window
                area is captured then the result object coordinates are adjusted accordingly.

                If the SoftwareBitmap needs to be transformed in any way (eg scale or custom rect is
                provided) then we need to offset coordinates and possibly width/height as well.

            */
            SoftwareBitmap := this.CreateDirect3DSoftwareBitmapFromWindow(hWnd)

            local sbW := SoftwareBitmap.W, sbH := SoftwareBitmap.H, sbX := SoftwareBitmap.X, sbY := SoftwareBitmap.Y
            local offsetX := 0, offsetY := 0

            if transform.scale != 1 || transform.rotate || transform.flip || customRect || onlyClientArea {
                local tX := X, tY := Y, tW := W, tH := H
                if onlyClientArea
                    tX -= SoftwareBitmap.X-cX, tY -= SoftwareBitmap.Y-cY
                else
                    tX -= SoftwareBitmap.X-wX, tY -= SoftwareBitmap.Y-wY
                if tX < 0 
                    tW += tX, offsetX := -tX, tX := 0
                if tY < 0
                    tH += tY, offsetY := -tY, tY := 0
                tW := Min(sbW-tX, tW), tH := Min(sbH-tY, tH)

                SoftwareBitmap := this.TransformSoftwareBitmap(SoftwareBitmap, &sbW, &sbH, transform.scale, transform.rotate, transform.flip, tX, tY, tW, tH)
                this.__DeleteProps(Options, "scale", "rotate", "flip")
            } else
                offsetX := sbX-wX, offsetY := sbY-wY
            result := this(SoftwareBitmap, Options)
        } else {
            hBitMap := this.CreateHBitmap(X, Y, W, H, {hWnd:hWnd, onlyClientArea:onlyClientArea, mode:(mode//2)}, transform.scale)
            if mode&1
                WinSetExStyle(oldStyle, hwnd)
            SoftwareBitmap := this.HBitmapToSoftwareBitmap(hBitMap,, transform)
            this.__DeleteProps(Options, "invertcolors", "grayscale", "monochrome")
            result := this(SoftwareBitmap, Options)
        }

        result.Relative := {CoordMode:coordsmode, hWnd:hWnd}
        if coordsmode = "Screen"
            x += sX, y += sY
        this.NormalizeCoordinates(result, transform.scale, x, y)
        if mode = 5 && !onlyClientArea
            result.OffsetCoordinates(offsetX, offsetY)
        return result
    }

    /**
     * Returns an OCR results object for the specified monitor. Locations of the words will be relative to
     * the primary screen (CoordMode "Screen"), even if a secondary monitor is being captured.
     * @param Monitor Optional: The monitor from which to get the desktop area. Default is primary monitor.
     *   If screen scaling between monitors differs, then use DllCall("SetThreadDpiAwarenessContext", "ptr", -3)
     * @param Options Optional: OCR options {lang, scale, grayscale, invertcolors, rotate, flip, x, y, w, h, decoder}. 
     * @returns {OCR.Result} 
     */
    static FromMonitor(Monitor?, Options:=0) {
        if !Options && IsSet(Monitor) && IsObject(Monitor)
            Options := Monitor, Monitor := unset
        this.__ExtractNamedParameters(Options, "Monitor", &Monitor)
        MonitorGet(monitor?, &Left, &Top, &Right, &Bottom)
        return this.FromRect(Left, Top, Right-Left, Bottom-Top, Options)
    }

    /**
     * Returns an OCR results object for the whole virtual screen. Locations of the words will be relative to
     * the primary screen (CoordMode "Screen").
     * @param Options Optional: OCR options {lang, scale, grayscale, invertcolors, rotate, flip, x, y, w, h, decoder}. 
     *   If screen scaling between monitors differs, then use DllCall("SetThreadDpiAwarenessContext", "ptr", -3)
     * @returns {OCR.Result}
     */
    static FromDesktop(Options:=0) => this.FromRect(SysGet(76), SysGet(77), SysGet(78), SysGet(79), Options)

    /**
     * Returns an OCR results object for a region of the screen. Locations of the words will be relative
     * to the screen.
     * @param x Screen x coordinate
     * @param y Screen y coordinate
     * @param w Region width. Maximum is OCR.MaxImageDimension
     * @param h Region height. Maximum is OCR.MaxImageDimension
     * @param Options OCR options {lang, scale, grayscale, invertcolors, rotate, flip, x, y, w, h, decoder}. 
     * @returns {OCR.Result} 
     */
    static FromRect(x, y, w, h, Options:=0) {
        local transform := 0, result
        if IsObject(Options)
            Options := Options.Clone()
        this.__ExtractTransformParameters(Options, &transform)
        this.__DeleteProps(Options, "scale", "invertcolors", "grayscale")
        local scale := transform.scale
            , hBitmap := this.CreateHBitmap(X, Y, W, H,, scale)
            , SoftwareBitmap := this.HBitmapToSoftwareBitmap(hBitmap,, transform)
            , result := this(SoftwareBitmap, Options)
        return this.NormalizeCoordinates(result, scale, x, y)
    }

    /**
     * Returns an OCR results object from a bitmap. Locations of the words will be relative
     * to the top left corner of the bitmap.
     * @param Bitmap A pointer to a GDIP Bitmap object, or HBITMAP, or an object with a ptr property
     *  set to one of the two.
     * @param Options OCR options {lang, scale, grayscale, invertcolors, rotate, flip, x, y, w, h, decoder}. 
     * @param hDC Optional: a device context for the bitmap. If omitted then the screen DC is used.
     * @returns {OCR.Result} 
     */
    static FromBitmap(Bitmap, Options:=0, hDC?) {
        local result, pDC, hBitmap, hBM2, oBM, oBM2, pBitmapInfo := Buffer(32, 0), W, H, scale, transform := 0
        if IsObject(Options)
            Options := Options.Clone()
        this.__ExtractTransformParameters(Options, &transform)
        scale := transform.scale
        this.__ExtractNamedParameters(Options, "hDC", &hDC)
        this.__DeleteProps(Options, "scale", "invertcolors", "grayscale")
        if !DllCall("GetObject", "ptr", Bitmap, "int", pBitmapInfo.Size, "ptr", pBitmapInfo) {
            DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "UPtr", Bitmap, "UPtr*", &hBitmap:=0, "Int", 0xffffffff)
            DllCall("GetObject", "ptr", hBitmap, "int", pBitmapInfo.Size, "ptr", pBitmapInfo)
            Bitmap := 0 
        } else
            hBitmap := Bitmap

        W := NumGet(pBitmapInfo, 4, "int"), H := NumGet(pBitmapInfo, 8, "int")

        if scale != 1 || (W && H && (W < 40 || H < 40)) {
            sW := Ceil(W * scale), sH := Ceil(H * scale)

            hDC := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")
            , oBM := DllCall("SelectObject", "Ptr", hDC, "Ptr", hBitmap, "Ptr")
            , pDC := DllCall("CreateCompatibleDC", "Ptr", hDC, "Ptr")
            , hBM2 := DllCall("CreateCompatibleBitmap", "Ptr", hDC, "Int", Max(40, sW), "Int", Max(40, sH), "Ptr")
            , oBM2 := DllCall("SelectObject", "Ptr", pDC, "Ptr", hBM2, "Ptr")
            if sW < 40 || sH < 40 
                DllCall("StretchBlt", "Ptr", pDC, "Int", 0, "Int", 0, "Int", Max(40,sW), "Int", Max(40,sH), "Ptr", hDC, "Int", 0, "Int", 0, "Int", 1, "Int", 1, "UInt", 0x00CC0020 | this.CAPTUREBLT) 
            PrevStretchBltMode := DllCall("SetStretchBltMode", "Ptr", PDC, "Int", 3, "Int") 
            , DllCall("StretchBlt", "Ptr", pDC, "Int", 0, "Int", 0, "Int", sW, "Int", sH, "Ptr", hDC, "Int", 0, "Int", 0, "Int", W, "Int", H, "UInt", 0x00CC0020 | this.CAPTUREBLT) 
            , DllCall("SetStretchBltMode", "Ptr", PDC, "Int", PrevStretchBltMode)
            , DllCall("SelectObject", "Ptr", pDC, "Ptr", oBM2)
            , DllCall("SelectObject", "Ptr", hDC, "Ptr", oBM)
            , DllCall("DeleteDC", "Ptr", hDC)
            SoftwareBitmap := this.HBitmapToSoftwareBitmap(hBM2, pDC, transform)
            result := this(SoftwareBitmap, Options)
            this.NormalizeCoordinates(result, scale)
            DllCall("DeleteDC", "Ptr", pDC)
            , DllCall("DeleteObject", "UPtr", hBM2)
            goto End
        }
        result := this(this.HBitmapToSoftwareBitmap(hBitmap, hDC?, transform), Options)
        End:
        if !Bitmap
            DllCall("DeleteObject", "UPtr", hBitmap)
        return result
    } 

    /**
     * Returns all available languages as a string, where the languages are separated by newlines.
     * @returns {String} 
     */
    static GetAvailableLanguages() {
        ComCall(7, this.OcrEngineStatics, "ptr*", &LanguageList := 0)   
        ComCall(7, LanguageList, "int*", &count := 0)   
        Loop count {
            ComCall(6, LanguageList, "int", A_Index - 1, "ptr*", &Language := 0)   
            ComCall(6, Language, "ptr*", &hText := 0)
            buf := DllCall("Combase.dll\WindowsGetStringRawBuffer", "ptr", hText, "uint*", &length := 0, "ptr")
            text .= StrGet(buf, "UTF-16") "`n"
            this.DeleteHString(hText)
            ObjRelease(Language)
        }
        ObjRelease(LanguageList)
        return text
    }

    /**
     * Loads a new language which will be used with subsequent OCR calls.
     * @param {string} lang OCR language. Default is first from available languages.
     * @returns {void} 
     */
    static LoadLanguage(lang:="FirstFromAvailableLanguages") {
        local hString, Language:=ComValue(13, 0), OcrEngine:=ComValue(13, 0)
        if this.HasOwnProp("CurrentLanguage") && this.HasOwnProp("OcrEngine") && this.CurrentLanguage = lang
            return
        if HasMethod(lang)
            lang := lang()
        if (lang = "FirstFromAvailableLanguages")
            ComCall(10, this.OcrEngineStatics, "ptr*", OcrEngine)   
        else {
            hString := this.CreateHString(lang)
            , ComCall(6, this.LanguageFactory, "ptr", hString, "ptr*", Language)   
            , this.DeleteHString(hString)
            , ComCall(9, this.OcrEngineStatics, "ptr", Language, "ptr*", OcrEngine)   
        }
        if (OcrEngine.ptr = 0)
            Throw Error(lang = "FirstFromAvailableLanguages" ? "Failed to use FirstFromAvailableLanguages for OCR:`nmake sure the primary language pack has OCR capabilities installed.`n`nAlternatively try `"en-us`" as the language." : "Can not use language `"" lang "`" for OCR, please install language pack.")
        this.OcrEngine := OcrEngine, this.CurrentLanguage := lang
    }

    /**
     * Returns a bounding rectangle {x,y,w,h} for the provided Word objects
     * @param words Word object arguments (at least 1)
     * @returns {Object}
     */
    static WordsBoundingRect(words*) {
        if !words.Length
            throw ValueError("This function requires at least one argument", -1)
        local X1 := 100000000, Y1 := 100000000, X2 := -100000000, Y2 := -100000000, word
        for word in words {
            X1 := Min(word.x, X1), Y1 := Min(word.y, Y1), X2 := Max(word.x+word.w, X2), Y2 := Max(word.y+word.h, Y2)
        }
        return {X:X1, Y:Y1, W:X2-X1, H:Y2-Y1, X2:X2, Y2:Y2}
    }
    
    /**
     * Waits text to appear on screen. If the method is successful, then Func's return value is returned.
     * Otherwise nothing is returned.
     * @param needle The searched text
     * @param {number} timeout Timeout in milliseconds. Less than 0 is indefinite wait (default)
     * @param func The function to be called for the OCR. Default is OCR.FromDesktop
     * @param casesense Text comparison case-sensitivity
     * @param comparefunc A custom string compare/search function, that accepts two arguments: haystack and needle.
     *      Default is InStr. If a custom function is used, then casesense is ignored.
     * @returns {OCR.Result} 
     */
    static WaitText(needle, timeout:=-1, func?, casesense:=False, comparefunc?) {
        local endTime := A_TickCount+timeout, result, line, total
        if !IsSet(func)
            func := this.FromDesktop
        if !IsSet(comparefunc)
            comparefunc := InStr.Bind(,,casesense)
        While timeout > 0 ? (A_TickCount < endTime) : 1 {
            result := func(), total := ""
            for line in result.Lines
                total .= line.Text "`n"
            if comparefunc(Trim(total, "`n"), needle)
                return result
        }
        return
    }

    /**
     * Returns word clusters using a two-dimensional DBSCAN algorithm
     * @param objs An array of objects (Words, Lines etc) to cluster. Must have x, y, w, h and Text properties.
     * @param eps_x Optional epsilon value for x-axis. Default is infinite.
     * This is unused if compareFunc is provided.
     * @param eps_y Optional epsilon value for y-axis. Default is median height of objects divided by two.
     * This is unused if compareFunc is provided.
     * @param minPts Optional minimum cluster size.
     * @param compareFunc Optional comparison function to judge the minimum distance between objects
     * to consider it a cluster. Must accept two objects to compare.
     * Default comparison function determines whether the difference of middle y-coordinates of 
     * the objects are less than epsilon-y, and whether objects are less than eps_x apart on the x-axis.
     * 
     * Eg `(p1, p2) => ((Abs(p1.y+p1.h-p2.y) < 5 || Abs(p2.y+p2.h-p1.y) < 5) && ((p1.x >= p2.x && p1.x <= (p2.x+p2.w)) || ((p1.x+p1.w) >= p2.x && (p1.x+p1.w) <= (p2.x+p2.w))))`
     * will cluster objects if they are located on top of eachother on the x-axis, and less than 5 pixels
     * apart in the y-axis.
     * @param noise If provided, then will be set to an array of clusters that didn't satisfy minPts
     * @returns {Array} Array of objects with {x,y,w,h,Text,Words} properties
     */
    static Cluster(objs, eps_x:=-1, eps_y:=-1, minPts:=1, compareFunc?, &noise?) {
        local clusters := [], start := 0, cluster, word
        visited := Map(), clustered := Map(), C := [], c_n := 0, sum := 0, noise := IsSet(noise) && (noise is Array) ? noise : []
        if !IsObject(objs) || !(objs is Array)
            throw ValueError("objs argument must be an Array", -1)
        if !objs.Length
            return []
        if IsSet(compareFunc) && !HasMethod(compareFunc)
            throw ValueError("compareFunc must be a valid function", -1)

        if !IsSet(compareFunc) {
            if (eps_y < 0) {
                for point in objs
                    sum += point.h
                eps_y := (sum // objs.Length) // 2
            }
            compareFunc := (p1, p2) => Abs(p1.y+p1.h//2-p2.y-p2.h//2)<eps_y && (eps_x < 0 || (Abs(p1.x+p1.w-p2.x)<eps_x || Abs(p1.x-p2.x-p2.w)<eps_x))
        }

        for point in objs {
            visited[point] := 1, neighbourPts := [], RegionQuery(point)
            if !clustered.Has(point) {
                C.Push([]), c_n += 1, C[c_n].Push(point), clustered[point] := 1
                ExpandCluster(point)
            }
            if C[c_n].Length < minPts
                noise.Push(C[c_n]), C.RemoveAt(c_n), c_n--
        }

        for cluster in C {
            this.SortArray(cluster,,"x")
            br := this.Common(), br.DefineProp("BoundingRect", {value:this.WordsBoundingRect(cluster*)}), br.DefineProp("Words", {value:cluster}), br.DefineProp("Text", {value: ""})
            for word in cluster
                br.Text .= word.Text " "
            br.Text := RTrim(br.Text)
            clusters.Push(br)
        }
        this.SortArray(clusters,,"y")
        return clusters

        ExpandCluster(P) {
            local point
            for point in neighbourPts {
                if !visited.Has(point) {
                    visited[point] := 1, RegionQuery(point)
                    if !clustered.Has(point)
                        C[c_n].Push(point), clustered[point] := 1
                }
            }
        }

        RegionQuery(P) {
            local point
            for point in objs
                if !visited.Has(point)
                    if compareFunc(P, point)
                        neighbourPts.Push(point)
        }
    }

    /**
     * Sorts an array in-place, optionally by object keys or using a callback function.
     * @param arr The array to be sorted
     * @param OptionsOrCallback Optional: either a callback function, or one of the following:
     * 
     *     N => array is considered to consist of only numeric values. This is the default option.
     *     C, C1 or COn => case-sensitive sort of strings
     *     C0 or COff => case-insensitive sort of strings
     * 
     *     The callback function should accept two parameters elem1 and elem2 and return an integer:
     *     Return integer < 0 if elem1 less than elem2
     *     Return 0 is elem1 is equal to elem2
     *     Return > 0 if elem1 greater than elem2
     * @param Key Optional: Omit it if you want to sort a array of primitive values (strings, numbers etc).
     *     If you have an array of objects, specify here the key by which contents the object will be sorted.
     * @returns {Array}
     */
    static SortArray(arr, optionsOrCallback:="N", key?) {
        static sizeofFieldType := 16 
        if HasMethod(optionsOrCallback)
            pCallback := CallbackCreate(CustomCompare.Bind(optionsOrCallback), "F Cdecl", 2), optionsOrCallback := ""
        else {
            if InStr(optionsOrCallback, "N")
                pCallback := CallbackCreate(IsSet(key) ? NumericCompareKey.Bind(key) : NumericCompare, "F CDecl", 2)
            if RegExMatch(optionsOrCallback, "i)C(?!0)|C1|COn")
                pCallback := CallbackCreate(IsSet(key) ? StringCompareKey.Bind(key,,True) : StringCompare.Bind(,,True), "F CDecl", 2)
            if RegExMatch(optionsOrCallback, "i)C0|COff")
                pCallback := CallbackCreate(IsSet(key) ? StringCompareKey.Bind(key) : StringCompare, "F CDecl", 2)
            if InStr(optionsOrCallback, "Random")
                pCallback := CallbackCreate(RandomCompare, "F CDecl", 2)
            if !IsSet(pCallback)
                throw ValueError("No valid options provided!", -1)
        }
        mFields := NumGet(ObjPtr(arr) + (8 + (VerCompare(A_AhkVersion, "<2.1-") > 0 ? 3 : 5)*A_PtrSize), "Ptr") ; in v2.0: 0 is VTable. 2 is mBase, 3 is mFields, 4 is FlatVector, 5 is mLength and 6 is mCapacity
        DllCall("msvcrt.dll\qsort", "Ptr", mFields, "UInt", arr.Length, "UInt", sizeofFieldType, "Ptr", pCallback, "Cdecl")
        CallbackFree(pCallback)
        if RegExMatch(optionsOrCallback, "i)R(?!a)")
            this.ReverseArray(arr)
        if InStr(optionsOrCallback, "U")
            arr := this.Unique(arr)
        return arr

        CustomCompare(compareFunc, pFieldType1, pFieldType2) => (ValueFromFieldType(pFieldType1, &fieldValue1), ValueFromFieldType(pFieldType2, &fieldValue2), compareFunc(fieldValue1, fieldValue2))
        NumericCompare(pFieldType1, pFieldType2) => (ValueFromFieldType(pFieldType1, &fieldValue1), ValueFromFieldType(pFieldType2, &fieldValue2), fieldValue1 - fieldValue2)
        NumericCompareKey(key, pFieldType1, pFieldType2) => (ValueFromFieldType(pFieldType1, &fieldValue1), ValueFromFieldType(pFieldType2, &fieldValue2), fieldValue1.%key% - fieldValue2.%key%)
        StringCompare(pFieldType1, pFieldType2, casesense := False) => (ValueFromFieldType(pFieldType1, &fieldValue1), ValueFromFieldType(pFieldType2, &fieldValue2), StrCompare(fieldValue1 "", fieldValue2 "", casesense))
        StringCompareKey(key, pFieldType1, pFieldType2, casesense := False) => (ValueFromFieldType(pFieldType1, &fieldValue1), ValueFromFieldType(pFieldType2, &fieldValue2), StrCompare(fieldValue1.%key% "", fieldValue2.%key% "", casesense))
        RandomCompare(pFieldType1, pFieldType2) => (Random(0, 1) ? 1 : -1)

        ValueFromFieldType(pFieldType, &fieldValue?) {
            static SYM_STRING := 0, PURE_INTEGER := 1, PURE_FLOAT := 2, SYM_MISSING := 3, SYM_OBJECT := 5
            switch SymbolType := NumGet(pFieldType + 8, "Int") {
                case PURE_INTEGER: fieldValue := NumGet(pFieldType, "Int64") 
                case PURE_FLOAT: fieldValue := NumGet(pFieldType, "Double") 
                case SYM_STRING: fieldValue := StrGet(NumGet(pFieldType, "Ptr")+2*A_PtrSize)
                case SYM_OBJECT: fieldValue := ObjFromPtrAddRef(NumGet(pFieldType, "Ptr")) 
                case SYM_MISSING: return		
            }
        }
    }
    static ReverseArray(arr) {
        local len := arr.Length + 1, max := (len // 2), i := 0
        while ++i <= max
            temp := arr[len - i], arr[len - i] := arr[i], arr[i] := temp
        return arr
    }
    static UniqueArray(arr) {
        local unique := Map()
        for v in arr
            unique[v] := 1
        return [unique*]
    }

    static FlattenArray(arr) {
        local r := []
        for v in arr {
            if v is Array
                r.Push(this.FlattenArray(v)*)
            else
                r.Push(v)
        }
        return r
    }

    static TransformSoftwareBitmap(SoftwareBitmap, &sbW, &sbH, scale:=1, rotate:=0, flip:=0, X?, Y?, W?, H?) {
        InMemoryRandomAccessStream := this.SoftwareBitmapToRandomAccessStream(SoftwareBitmap)

        ComCall(this.Vtbl_GetDecoder.png, this.BitmapDecoderStatics, "ptr", DecoderGUID:=Buffer(16))
        ComCall(15, this.BitmapDecoderStatics, "ptr", DecoderGUID, "ptr", InMemoryRandomAccessStream, "ptr*", BitmapDecoder:=ComValue(13,0))   
        this.WaitForAsync(&BitmapDecoder)

        BitmapFrameWithSoftwareBitmap := ComObjQuery(BitmapDecoder, IBitmapFrameWithSoftwareBitmap := "{FE287C9A-420C-4963-87AD-691436E08383}")
        BitmapFrame := ComObjQuery(BitmapDecoder, IBitmapFrame := "{72A49A1C-8081-438D-91BC-94ECFC8185C6}")

        BitmapTransform := this.CreateClass("Windows.Graphics.Imaging.BitmapTransform")

        if IsSet(W) && W
            sbW := Min(sbW, W)
        if IsSet(H) && H
            sbH := Min(sbH, H)
        local sW := Floor(sbW*scale), sH := Floor(sbH*scale), intermediate
        if scale != 1 {
            ComCall(7, BitmapTransform, "uint", sW) 
            ComCall(9, BitmapTransform, "uint", sH) 
        }
        if rotate {
            ComCall(15, BitmapTransform, "uint", rotate//90) 
            if rotate = 90 || rotate = 270
                intermediate := sW, sW := sH, sH := intermediate
        }
        if flip
            ComCall(13, BitmapTransform, "uint", flip) 

        if (IsSet(X) && X != 0) || (IsSet(Y) && Y != 0) || IsSet(W) || IsSet(H)  {
            bounds := Buffer(16,0), NumPut("int", Floor(X*scale), "int", Floor(Y*scale), "int", Floor(sbW*scale), "int", Floor(sbH*scale), bounds)
            ComCall(17, BitmapTransform, "ptr", bounds) 
        }
        ComCall(8, BitmapFrame, "uint*", &BitmapPixelFormat:=0) 
        ComCall(9, BitmapFrame, "uint*", &BitmapAlphaMode:=0) 
        ComCall(8, BitmapFrameWithSoftwareBitmap, "uint", BitmapPixelFormat, "uint", BitmapAlphaMode, "ptr", BitmapTransform, "uint", IgnoreExifOrientation := 0, "uint", DoNotColorManage := 0, "ptr*", SoftwareBitmap:=ComValue(13,0)) ; GetSoftwareBitmapTransformedAsync

        this.WaitForAsync(&SoftwareBitmap)
        this.CloseIClosable(InMemoryRandomAccessStream)
        sbW := sW, sbH := sH
        return SoftwareBitmap
    }

    static CreateDIBSection(w, h, hdc?, bpp:=32, &ppvBits:=0) {
        local hdc2 := IsSet(hdc) ? hdc : DllCall("GetDC", "Ptr", 0, "UPtr")
        , bi := Buffer(40, 0), hbm
        NumPut("int", 40, "int", w, "int", h, "ushort", 1, "ushort", bpp, "int", 0, bi)
        hbm := DllCall("CreateDIBSection", "uint", hdc2, "ptr" , bi, "uint" , 0, "uint*", &ppvBits:=0, "uint" , 0, "uint" , 0)
        if !IsSet(hdc)
            DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdc2)
        return hbm
    }

    /**
     * Creates an hBitmap of a region of the screen or a specific window
     * @param X Captured rectangle X coordinate. This is relative to the screen unless hWnd is specified,
     *  in which case it may be relative to the window/client
     * @param Y Captured rectangle Y coordinate.
     * @param W Captured rectangle width.
     * @param H Captured rectangle height.
     * @param {Integer|Object} hWnd Window handle which to capture. Coordinates will be relative to the window. 
     *  hWnd may also be an object {hWnd, onlyClientArea, mode} where onlyClientArea:1 means the client area will be captured instead of the whole window (and X, Y will also be relative to client)
     *  mode 0 uses GetDC + StretchBlt, mode 1 uses PrintWindow, mode 2 uses PrintWindow with undocumented PW_RENDERFULLCONTENT flag. 
     *  Default is mode 2.
     * @param {Integer} scale 
     * @returns {OCR.IBase} 
     */
    static CreateHBitmap(X, Y, W, H, hWnd:=0, scale:=1) {
        local sW := Ceil(W*scale), sH := Ceil(H*scale), onlyClientArea := 0, mode := 2, HDC, obm, hbm, pdc, hbm2
        if hWnd {
            if IsObject(hWnd)
                onlyClientArea := hWnd.HasOwnProp("onlyClientArea") ? hWnd.onlyClientArea : onlyClientArea, mode := hWnd.HasOwnProp("mode") ? hWnd.mode : mode, hWnd := hWnd.hWnd
            HDC := DllCall("GetDCEx", "Ptr", hWnd, "Ptr", 0, "Int", 2|!onlyClientArea, "Ptr")
            if mode > 0 {
                PDC := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")
                HBM := DllCall("CreateCompatibleBitmap", "Ptr", HDC, "Int", Max(40,X+W), "Int", Max(40,Y+H), "Ptr")
                , OBM := DllCall("SelectObject", "Ptr", PDC, "Ptr", HBM, "Ptr")
                , DllCall("PrintWindow", "Ptr", hWnd, "Ptr", PDC, "UInt", (mode=2?2:0)|!!onlyClientArea)
                if scale != 1 || X != 0 || Y != 0 {
                    PDC2 := DllCall("CreateCompatibleDC", "Ptr", PDC, "Ptr")
                    , HBM2 := DllCall("CreateCompatibleBitmap", "Ptr", PDC, "Int", Max(40,sW), "Int", Max(40,sH), "Ptr")
                    , OBM2 := DllCall("SelectObject", "Ptr", PDC2, "Ptr", HBM2, "Ptr")
                    , PrevStretchBltMode := DllCall("SetStretchBltMode", "Ptr", PDC, "Int", 3, "Int") ; COLORONCOLOR
                    , DllCall("StretchBlt", "Ptr", PDC2, "Int", 0, "Int", 0, "Int", sW, "Int", sH, "Ptr", PDC, "Int", X, "Int", Y, "Int", W, "Int", H, "UInt", 0x00CC0020 | this.CAPTUREBLT) ; SRCCOPY
                    , DllCall("SetStretchBltMode", "Ptr", PDC, "Int", PrevStretchBltMode)
                    , DllCall("SelectObject", "Ptr", PDC2, "Ptr", obm2)
                    , DllCall("DeleteDC", "Ptr", PDC)
                    , DllCall("DeleteObject", "UPtr", HBM)
                    , hbm := hbm2, pdc := pdc2
                }
                DllCall("SelectObject", "Ptr", PDC, "Ptr", OBM)
                , DllCall("DeleteDC", "Ptr", HDC)
                , oHBM := this.IBase(HBM), oHBM.DC := PDC
                return oHBM.DefineProp("__Delete", {call:(this, *)=>(DllCall("DeleteObject", "Ptr", this), DllCall("DeleteDC", "Ptr", this.DC))})
            }
        } else {
            HDC := DllCall("GetDC", "Ptr", 0, "Ptr")
        }
        PDC := DllCall("CreateCompatibleDC", "Ptr", HDC, "Ptr")
        , HBM := DllCall("CreateCompatibleBitmap", "Ptr", HDC, "Int", Max(40,sW), "Int", Max(40,sH), "Ptr")
        , OBM := DllCall("SelectObject", "Ptr", PDC, "Ptr", HBM, "Ptr")
        if sW < 40 || sH < 40 
            DllCall("StretchBlt", "Ptr", PDC, "Int", 0, "Int", 0, "Int", Max(40,sW), "Int", Max(40,sH), "Ptr", HDC, "Int", X, "Int", Y, "Int", 1, "Int", 1, "UInt", 0x00CC0020 | this.CAPTUREBLT) ; SRCCOPY. 
        PrevStretchBltMode := DllCall("SetStretchBltMode", "Ptr", PDC, "Int", 3, "Int") ; COLORONCOLOR
        , DllCall("StretchBlt", "Ptr", PDC, "Int", 0, "Int", 0, "Int", sW, "Int", sH, "Ptr", HDC, "Int", X, "Int", Y, "Int", W, "Int", H, "UInt", 0x00CC0020 | this.CAPTUREBLT) ; SRCCOPY
        , DllCall("SetStretchBltMode", "Ptr", PDC, "Int", PrevStretchBltMode)
        , DllCall("SelectObject", "Ptr", PDC, "Ptr", OBM)
        , DllCall("DeleteDC", "Ptr", HDC)
        , oHBM := this.IBase(HBM), oHBM.DC := PDC
        return oHBM.DefineProp("__Delete", {call:(this, *)=>(DllCall("DeleteObject", "Ptr", this), DllCall("DeleteDC", "Ptr", this.DC))})
    }

    static CreateDirect3DSoftwareBitmapFromWindow(hWnd) {
        static init := 0, DXGIDevice, Direct3DDevice, Direct3D11CaptureFramePoolStatics, GraphicsCaptureItemInterop, GraphicsCaptureItemGUID, D3D_Device, D3D_Context
        local x, y, w, h, rect
        if !init {
            DllCall("LoadLibrary","str","DXGI")
            DllCall("LoadLibrary","str","D3D11")
            DllCall("LoadLibrary","str","Dwmapi")
            DllCall("D3D11\D3D11CreateDevice", "ptr", 0, "int", D3D_DRIVER_TYPE_HARDWARE := 1, "ptr", 0, "uint", D3D11_CREATE_DEVICE_BGRA_SUPPORT := 0x20, "ptr", 0, "uint", 0, "uint", D3D11_SDK_VERSION := 7, "ptr*", D3D_Device:=ComValue(13, 0), "ptr*", 0, "ptr*", D3D_Context:=ComValue(13, 0))
            DXGIDevice := ComObjQuery(D3D_Device, IID_IDXGIDevice := "{54ec77fa-1377-44e6-8c32-88fd5f44c84c}")
            DllCall("D3D11\CreateDirect3D11DeviceFromDXGIDevice", "ptr", DXGIDevice, "ptr*", GraphicsDevice:=ComValue(13, 0))
            Direct3DDevice := ComObjQuery(GraphicsDevice, IDirect3DDevice := "{A37624AB-8D5F-4650-9D3E-9EAE3D9BC670}")
            Direct3D11CaptureFramePoolStatics := this.CreateClass("Windows.Graphics.Capture.Direct3D11CaptureFramePool", IDirect3D11CaptureFramePoolStatics := "{7784056a-67aa-4d53-ae54-1088d5a8ca21}")
            GraphicsCaptureItemStatics := this.CreateClass("Windows.Graphics.Capture.GraphicsCaptureItem", IGraphicsCaptureItemStatics := "{A87EBEA5-457C-5788-AB47-0CF1D3637E74}")
            GraphicsCaptureItemInterop := ComObjQuery(GraphicsCaptureItemStatics, IGraphicsCaptureItemInterop := "{3628E81B-3CAC-4C60-B7F4-23CE0E0C3356}")
            GraphicsCaptureItemGUID := Buffer(16,0)
            DllCall("ole32\CLSIDFromString", "wstr", IGraphicsCaptureItem := "{79c3f95b-31f7-4ec2-a464-632ef5d30760}", "ptr", GraphicsCaptureItemGUID)
            init := 1
        }

        DllCall("Dwmapi.dll\DwmGetWindowAttribute", "ptr", hWnd, "uint", DWMWA_EXTENDED_FRAME_BOUNDS := 9, "ptr", rect := Buffer(16,0), "uint", 16)
        x := NumGet(rect, 0, "int"), y := NumGet(rect, 4, "int"), w := NumGet(rect, 8, "int") - x, h := NumGet(rect, 12, "int") - y
        ComCall(6, Direct3D11CaptureFramePoolStatics, "ptr", Direct3DDevice, "int", B8G8R8A8UIntNormalized := 87, "int", numberOfBuffers := 2, "int64", (h << 32) | w, "ptr*", Direct3D11CaptureFramePool:=ComValue(13, 0))   ; Direct3D11CaptureFramePool.Create
        if ComCall(3, GraphicsCaptureItemInterop, "ptr", hWnd, "ptr", GraphicsCaptureItemGUID, "ptr*", GraphicsCaptureItem:=ComValue(13, 0), "uint") {   ; IGraphicsCaptureItemInterop::CreateForWindow
            this.CloseIClosable(Direct3D11CaptureFramePool)
            throw Error("Failed to capture GraphicsItem of window",, -1)
        }
        ComCall(10, Direct3D11CaptureFramePool, "ptr", GraphicsCaptureItem, "ptr*", GraphicsCaptureSession:=ComValue(13, 0))   ; Direct3D11CaptureFramePool.CreateCaptureSession

        GraphicsCaptureSession2 := ComObjQuery(GraphicsCaptureSession, IGraphicsCaptureSession2 := "{2c39ae40-7d2e-5044-804e-8b6799d4cf9e}")
        ComCall(7, GraphicsCaptureSession2, "int", 0)   ; GraphicsCaptureSession.IsCursorCaptureEnabled put

        if (Integer(StrSplit(A_OSVersion, ".")[3]) >= 20348) { ; hide border
            GraphicsCaptureSession3 := ComObjQuery(GraphicsCaptureSession, IGraphicsCaptureSession3 := "{f2cdd966-22ae-5ea1-9596-3a289344c3be}")
            ComCall(7, GraphicsCaptureSession3, "int", 0)   ; GraphicsCaptureSession.IsBorderRequired put
        }
        ComCall(6, GraphicsCaptureSession)   ; GraphicsCaptureSession.StartCapture
        Loop {
            ComCall(7, Direct3D11CaptureFramePool, "ptr*", Direct3D11CaptureFrame:=ComValue(13, 0))   ; Direct3D11CaptureFramePool.TryGetNextFrame
            if (Direct3D11CaptureFrame.ptr != 0)
                break
        }
        ComCall(6, Direct3D11CaptureFrame, "ptr*", Direct3DSurface:=ComValue(13, 0))   ; Direct3D11CaptureFrame.Surface

        ComCall(11, this.SoftwareBitmapStatics, "ptr", Direct3DSurface, "ptr*", SoftwareBitmap:=ComValue(13, 0)) ; SoftwareBitmap::CreateCopyFromSurfaceAsync
        this.WaitForAsync(&SoftwareBitmap)

        this.CloseIClosable(Direct3D11CaptureFramePool)
        this.CloseIClosable(GraphicsCaptureSession)
        if GraphicsCaptureSession2 {
            this.CloseIClosable(GraphicsCaptureSession2)
        }
        if IsSet(GraphicsCaptureSession3) {
            this.CloseIClosable(GraphicsCaptureSession3)
        }
        this.CloseIClosable(Direct3D11CaptureFrame)
        this.CloseIClosable(Direct3DSurface)

        SoftwareBitmap.x := x, SoftwareBitmap.y := y, SoftwareBitmap.w := w, SoftwareBitmap.h := h
        return SoftwareBitmap
    }

    static HBitmapToRandomAccessStream(hBitmap) {
        static PICTYPE_BITMAP := 1
             , BSOS_DEFAULT   := 0
             , sz := 8 + A_PtrSize*2
        local PICTDESC, riid, size, pIRandomAccessStream
             
        DllCall("Ole32\CreateStreamOnHGlobal", "Ptr", 0, "UInt", true, "Ptr*", pIStream:=ComValue(13,0), "UInt")
        , PICTDESC := Buffer(sz, 0)
        , NumPut("uint", sz, "uint", PICTYPE_BITMAP, "ptr", IsInteger(hBitmap) ? hBitmap : hBitmap.ptr, PICTDESC)
        , riid := this.CLSIDFromString(this.IID_IPicture)
        , DllCall("OleAut32\OleCreatePictureIndirect", "Ptr", PICTDESC, "Ptr", riid, "UInt", 0, "Ptr*", pIPicture:=ComValue(13,0), "UInt")
        , ComCall(15, pIPicture, "Ptr", pIStream, "UInt", true, "uint*", &size:=0, "UInt") ; IPicture::SaveAsFile
        , riid := this.CLSIDFromString(this.IID_IRandomAccessStream)
        , DllCall("ShCore\CreateRandomAccessStreamOverStream", "Ptr", pIStream, "UInt", BSOS_DEFAULT, "Ptr", riid, "Ptr*", pIRandomAccessStream:=ComValue(13, 0), "UInt")
        Return pIRandomAccessStream
    }

    static HBitmapToSoftwareBitmap(hBitmap, hDC?, transform?) {
        local bi := Buffer(40, 0), W, H, BitmapBuffer, MemoryBuffer, MemoryBufferReference, BufferByteAccess, BufferSize
        hDC := (hBitmap is OCR.IBase ? hBitmap.DC : (hDC ?? dhDC := DllCall("GetDC", "Ptr", 0, "UPtr")))

        NumPut("uint", 40, bi, 0)
        DllCall("GetDIBits", "ptr", hDC, "ptr", hBitmap, "uint", 0, "uint", 0, "ptr", 0, "ptr", bi, "uint", 0)
        W := NumGet(bi, 4, "int"), H := NumGet(bi, 8, "int")

        ComCall(7, this.SoftwareBitmapFactory, "int", 87, "int", W, "int", H, "int", 0, "ptr*", SoftwareBitmap := ComValue(13,0)) ; CreateWithAlpha: Bgra8 & Premultiplied
        ComCall(15, SoftwareBitmap, "int", 2, "ptr*", &BitmapBuffer := 0) ; LockBuffer
        MemoryBuffer := ComObjQuery(BitmapBuffer, "{fbc4dd2a-245b-11e4-af98-689423260cf8}")
        ComCall(6, MemoryBuffer, "ptr*", &MemoryBufferReference := 0) ; CreateReference
        BufferByteAccess := ComObjQuery(MemoryBufferReference, "{5b0d3235-4dba-4d44-865e-8f1d0e4fd04d}")
        ComCall(3, BufferByteAccess, "ptr*", &SoftwareBitmapByteBuffer:=0, "uint*", &BufferSize:=0) ; GetBuffer

        NumPut("short", 32, "short", 0, bi, 14), NumPut("int", -H, bi, 8) ; Negative height to get correctly oriented image
        DllCall("GetDIBits", "ptr", hDC, "ptr", hBitmap, "uint", 0, "uint", H, "ptr", SoftwareBitmapByteBuffer, "ptr", bi, "uint", 0)
        if IsSet(transform) {
            if (transform.HasProp("grayscale") && transform.grayscale)
                DllCall(this.GrayScaleMCode, "ptr", SoftwareBitmapByteBuffer, "uint", w, "uint", h, "uint", (w*4+3) // 4 * 4, "cdecl uint")
            if (transform.HasProp("monochrome") && transform.monochrome)
                DllCall(this.MonochromeMCode, "ptr", SoftwareBitmapByteBuffer, "uint", w, "uint", h, "uint", (w*4+3) // 4 * 4, "uint", transform.monochrome, "cdecl uint")
            if (transform.HasProp("invertcolors") && transform.invertcolors)
                DllCall(this.InvertColorsMCode, "ptr", SoftwareBitmapByteBuffer, "uint", w, "uint", h, "uint", (w*4+3) // 4 * 4, "cdecl uint")
        }
        
        if IsSet(dhDC)
            DllCall("DeleteDC", "ptr", dhDC)
        if BufferByteAccess.HasMethod("Dispose")
            BufferByteAccess.Dispose()
        if MemoryBuffer.HasMethod("Dispose")
            MemoryBuffer.Dispose()
        BufferByteAccess := "", ObjRelease(MemoryBufferReference), MemoryBuffer := "", ObjRelease(BitmapBuffer) ; Release in correct order

        return SoftwareBitmap
    }

    static MCode(mcode) {
        static e := Map('1', 4, '2', 1), c := (A_PtrSize=8) ? "x64" : "x86"
        if (!regexmatch(mcode, "^([0-9]+),(" c ":|.*?," c ":)([^,]+)", &m))
          return
        if (!DllCall("crypt32\CryptStringToBinary", "str", m.3, "uint", 0, "uint", e[m.1], "ptr", 0, "uint*", &s := 0, "ptr", 0, "ptr", 0))
          return
        p := DllCall("GlobalAlloc", "uint", 0, "ptr", s, "ptr")
        if (c="x64")
          DllCall("VirtualProtect", "ptr", p, "ptr", s, "uint", 0x40, "uint*", &op := 0)
        if (DllCall("crypt32\CryptStringToBinary", "str", m.3, "uint", 0, "uint", e[m.1], "ptr", p, "uint*", &s, "ptr", 0, "ptr", 0))
          return p
        DllCall("GlobalFree", "ptr", p)
      }

    static DisplayHBitmap(hBitmap) {
        local gImage := Gui("-DPIScale"), W, H
        , hPic := gImage.Add("Text", "0xE w640 h640")
        SendMessage(0x172, 0, hBitmap,, hPic.hWnd)
        hPic.GetPos(,,&W, &H)
        gImage.Show("w" (W+20) " H" (H+20))
        WinWaitClose gImage
    }

    static SoftwareBitmapToRandomAccessStream(SoftwareBitmap) {
        InMemoryRandomAccessStream := this.CreateClass("Windows.Storage.Streams.InMemoryRandomAccessStream")
        ComCall(8, this.BitmapEncoderStatics, "ptr", encoderId := Buffer(16, 0)) ; IBitmapEncoderStatics::PngEncoderId
        ComCall(13, this.BitmapEncoderStatics, "ptr", encoderId, "ptr", InMemoryRandomAccessStream, "ptr*", BitmapEncoder:=ComValue(13,0)) ; IBitmapEncoderStatics::CreateAsync
        this.WaitForAsync(&BitmapEncoder)
        BitmapEncoderWithSoftwareBitmap := ComObjQuery(BitmapEncoder, "{686cd241-4330-4c77-ace4-0334968b1768}")
        ComCall(6, BitmapEncoderWithSoftwareBitmap, "ptr", SoftwareBitmap) ; SetSoftwareBitmap
        ComCall(19, BitmapEncoder, "ptr*", asyncAction:=ComValue(13,0)) ; FlushAsync
        this.WaitForAsync(&asyncAction)
        ComCall(11, InMemoryRandomAccessStream, "int64", 0) ; Seek to beginning
        return InMemoryRandomAccessStream
    }

    static CreateClass(str, interface?) {
        local hString := this.CreateHString(str), result
        if !IsSet(interface) {
            result := DllCall("Combase.dll\RoActivateInstance", "ptr", hString, "ptr*", cls:=ComValue(13, 0), "uint")
        } else {
            GUID := this.CLSIDFromString(interface)
            result := DllCall("Combase.dll\RoGetActivationFactory", "ptr", hString, "ptr", GUID, "ptr*", cls:=ComValue(13, 0), "uint")
        }
        if (result != 0) {
            if (result = 0x80004002)
                throw Error("No such interface supported", -1, interface)
            else if (result = 0x80040154)
                throw Error("Class not registered", -1)
            else
                throw Error(result)
        }
        this.DeleteHString(hString)
        return cls
    }
    
    static CreateHString(str) => (DllCall("Combase.dll\WindowsCreateString", "wstr", str, "uint", StrLen(str), "ptr*", &hString:=0), hString)
    
    static DeleteHString(hString) => DllCall("Combase.dll\WindowsDeleteString", "ptr", hString)
    
    static WaitForAsync(&obj) {
        local AsyncInfo := ComObjQuery(obj, this.IID_IAsyncInfo), status, ErrorCode
        Loop {
            ComCall(7, AsyncInfo, "uint*", &status:=0)   ; IAsyncInfo.Status
            if (status != 0) {
                if (status != 1) {
                    ComCall(8, ASyncInfo, "uint*", &ErrorCode:=0)   ; IAsyncInfo.ErrorCode
                    throw Error("AsyncInfo failed with status error " ErrorCode, -1)
                }
                break
            }
            Sleep this.PerformanceMode ? -1 : 0
        }
        ComCall(8, obj, "ptr*", ObjectResult:=this.IBase())   ; GetResults
        obj := ObjectResult
    }

    static CloseIClosable(pClosable) {
        static IClosable := "{30D5A829-7FA4-4026-83BB-D75BAE4EA99E}"
        local Close := ComObjQuery(pClosable, IClosable)
        ComCall(6, Close)   ; Close
    }

    static CLSIDFromString(IID) {
        local CLSID := Buffer(16), res
        if res := DllCall("ole32\CLSIDFromString", "WStr", IID, "Ptr", CLSID, "UInt")
           throw Error("CLSIDFromString failed. Error: " . Format("{:#x}", res))
        Return CLSID
    }

    static NormalizeCoordinates(result, scale, x:=0, y:=0) {
        local word
        if (scale == 1 && x == 0 && y == 0)
            return result
        for word in result.Words
            word.x := Integer(word.x / scale)+x, word.y := Integer(word.y / scale)+y, word.w := Integer(word.w / scale), word.h := Integer(word.h / scale), word.BoundingRect := {X:word.x, Y:word.y, W:word.w, H:word.h}
        return result
    }
    
    static __OpenPdfDocument(IRandomAccessStream, Password:="") {
        PdfDocumentStatics := this.CreateClass("Windows.Data.Pdf.PdfDocument", this.IID_IPdfDocumentStatics)
        ComCall(8, PdfDocumentStatics, "ptr", IRandomAccessStream, "ptr*", PdfDocument:=ComValue(13, 0)) ; LoadFromStreamAsync
        this.WaitForAsync(&PdfDocument)
        return PdfDocument
    }

    static __ExtractNamedParameters(obj, params*) {
        local i := 0
        if !IsObject(obj) || Type(obj) != "Object"
            return 0
        Loop params.Length // 2 {
            name := params[++i], value := params[++i]
            if obj.HasProp(name)
                %value% := obj.%name%
        }
        return 1
    }

    static __ExtractTransformParameters(obj, &transform) {
        local scale := 1, grayscale := 0, invertcolors := 0, monochrome := 0, rotate := 0, flip := 0
        if IsObject(obj)
            this.__ExtractNamedParameters(obj, "scale", &scale, "grayscale", &grayscale, "invertcolors", &invertcolors, "monochrome", &monochrome, "rotate", &rotate, "flip", &flip, "transform", &transform)

        if IsSet(transform) && IsObject(transform) {
            for prop in ["scale", "grayscale", "invertcolors", "monochrome", "rotate", "flip"]
                if !transform.HasProp(prop)
                    transform.%prop% := %prop%
        } else
            transform := {scale:scale, grayscale:grayscale, invertcolors:invertcolors, monochrome:monochrome, rotate:rotate, flip:flip}
    
        transform.flip := transform.flip = "y" ? 1 : transform.flip = "x" ? 2 : transform.flip
    }

    static __DeleteProps(obj, props*) {
        if IsObject(obj)
            for prop in props
                obj.DeleteProp(prop)
    }

    /**
     * Converts coordinates between screen, window and client.
     * @param X X-coordinate to convert
     * @param Y Y-coordinate to convert
     * @param outX Variable where to store the converted X-coordinate
     * @param outY Variable where to store the converted Y-coordinate
     * @param relativeFrom CoordMode where to convert from. Default is A_CoordModeMouse.
     * @param relativeTo CoordMode where to convert to. Default is Screen.
     * @param winTitle A window title or other criteria identifying the target window. 
     * @param winText If present, this parameter must be a substring from a single text element of the target window.
     * @param excludeTitle Windows whose titles include this value will not be considered.
     * @param excludeText Windows whose text include this value will not be considered.
     */
    static ConvertWinPos(X, Y, &outX, &outY, relativeFrom:="", relativeTo:="screen", winTitle?, winText?, excludeTitle?, excludeText?) {
        relativeFrom := relativeFrom || A_CoordModeMouse
        if relativeFrom = relativeTo {
            outX := X, outY := Y
            return
        }
        local hWnd := WinExist(winTitle?, winText?, excludeTitle?, excludeText?)

        switch relativeFrom, 0 {
            case "screen", "s":
                if relativeTo = "window" || relativeTo = "w" {
                    DllCall("user32\GetWindowRect", "Int", hWnd, "Ptr", RECT := Buffer(16))
                    outX := X-NumGet(RECT, 0, "Int"), outY := Y-NumGet(RECT, 4, "Int")
                } else { 
                    pt := Buffer(8), NumPut("int",X,pt), NumPut("int",Y,pt,4)
                    DllCall("ScreenToClient", "Int", hWnd, "Ptr", pt)
                    outX := NumGet(pt,0,"int"), outY := NumGet(pt,4,"int")
                }
            case "window", "w":
                WinGetPos(&outX, &outY,,,hWnd)
                outX += X, outY += Y
                if relativeTo = "client" || relativeTo = "c" {
                    ; screen to client
                    pt := Buffer(8), NumPut("int",outX,pt), NumPut("int",outY,pt,4)
                    DllCall("ScreenToClient", "Int", hWnd, "Ptr", pt)
                    outX := NumGet(pt,0,"int"), outY := NumGet(pt,4,"int")
                }
            case "client", "c":
                pt := Buffer(8), NumPut("int",X,pt), NumPut("int",Y,pt,4)
                DllCall("ClientToScreen", "Int", hWnd, "Ptr", pt)
                outX := NumGet(pt,0,"int"), outY := NumGet(pt,4,"int")
                if relativeTo = "window" || relativeTo = "w" { ; screen to window
                    DllCall("user32\GetWindowRect", "Int", hWnd, "Ptr", RECT := Buffer(16))
                    outX -= NumGet(RECT, 0, "Int"), outY -= NumGet(RECT, 4, "Int")
                }
        }
    }
}

