#Include classMemory.ahk
#Include csgo offsets.ahk
#Include imgui.ahk

#NoEnv
#Persistent
#InstallKeybdHook
#SingleInstance, Force
DetectHiddenWindows, On
SetKeyDelay,-1, -1
SetControlDelay, -1
SetMouseDelay, -1
SendMode Input
SetBatchLines,-1
ListLines, Off
Process, Priority, , H

if !Read_csgo_offsets_from_hazedumper() {
	MsgBox, 48, Error, Failed to get csgo offsets!
    ExitApp
}
if (_ClassMemory.__Class != "_ClassMemory") {
    msgbox class memory not correctly installed. Or the (global class) variable "_ClassMemory" has been overwritten
    ExitApp
}


;Move types
Global MOVETYPE := {}
MOVETYPE.NONE       := 0
MOVETYPE.ISOMETRIC  := 1
MOVETYPE.WALK       := 2
MOVETYPE.STEP       := 3
MOVETYPE.FLY        := 4
MOVETYPE.FLYGRAVITY := 5
MOVETYPE.VPHYSICS   := 6
MOVETYPE.PUSH       := 7
MOVETYPE.NOCLIP     := 8
MOVETYPE.LADDER     := 9
MOVETYPE.OBSERVER   := 10

;Flags
Global FL_ONGROUND    := 1<<0
Global FL_DUCKING     := 1<<1
Global FL_ANIMDUCKING := 1<<2
Global FL_WATERJUMP   := 1<<3
Global FL_ONTRAIN     := 1<<4
Global FL_INRAIN      := 1<<5
Global FL_FROZEN      := 1<<6
Global FL_ATCONTROLS  := 1<<7
Global FL_CLIENT      := 1<<8
Global FL_FAKECLIENT  := 1<<9
Global FL_INWATER     := 1<<10

Class CPlayer {
	__New(entity) {
		csgo.readRaw(entity, ent_struct, m_iCrosshairId+0x4)
		this.entity             := entity
		,this.m_aimPunchAngleX  := NumGet(ent_struct, m_aimPunchAngle, "Float")
		,this.m_aimPunchAngleY  := NumGet(ent_struct, m_aimPunchAngle+0x4, "Float")
		,this.m_bIsScoped       := NumGet(ent_struct, m_bIsScoped, "int")
		,this.m_bSpottedByMask  := NumGet(ent_struct, m_bSpottedByMask, "int")
		,this.m_fFlags          := NumGet(ent_struct, m_fFlags, "int")
		,this.m_flFlashDuration := NumGet(ent_struct, m_flFlashDuration, "Float")
		,this.m_flFlashMaxAlpha := NumGet(ent_struct, m_flFlashMaxAlpha, "Float") 
		,this.m_iCrosshairId    := NumGet(ent_struct, m_iCrosshairId, "int")
		,this.m_iDefaultFOV     := NumGet(ent_struct, m_iDefaultFOV, "int") 
		,this.m_hActiveWeapon   := NumGet(ent_struct, m_hActiveWeapon, "int")
		,this.m_hMyWeapons      := NumGet(ent_struct, m_hMyWeapons, "int")
		,this.m_hViewModel      := NumGet(ent_struct, m_hViewModel, "int")
		,this.m_iShotsFired     := NumGet(ent_struct, m_iShotsFired, "int")
		,this.m_iGlowIndex      := NumGet(ent_struct, m_iGlowIndex, "int")
		,this.m_iHealth         := NumGet(ent_struct, m_iHealth, "int")
		,this.m_iTeamNum        := NumGet(ent_struct, m_iTeamNum, "int")
		,this.m_lifeState       := NumGet(ent_struct, m_lifeState, "int")
		,this.m_nTickBase       := NumGet(ent_struct, m_nTickBase, "int")
		,this.vecVelocity       := Sqrt(NumGet(ent_struct, m_vecVelocity, "Float")**2 + NumGet(ent_struct, m_vecVelocity+0x4, "Float")**2)
		,this.m_bDormant        := NumGet(player_struct, m_bDormant, "int")
	}

	GetViewModel() {
		if !(this.m_hViewModel)
			return false

		return csgo.read(client + dwEntityList + ((this.m_hViewModel & 0xFFF) - 1) * 0x10, "int")
	}

	GetWeapon() {
		if (this.m_hActiveWeapon = -1)
			return false

		pWeapon := csgo.read(client + dwEntityList + ((this.m_hActiveWeapon & 0xFFF) - 1) * 0x10, "int")
		return pWeapon
	}

	GetClassId() {
		return csgo.read(this.entity + 0x8, "Uint", 0x8, 0x1, 0x14)
	}
}


;glow struct
Global GLOWSTRUCT_nextFreeSlot                   := 0x0 ;int
Global GLOWSTRUCT_entity                         := 0x4 ;int
Global GLOWSTRUCT_glowColor_r                    := 0x8 ;float
Global GLOWSTRUCT_glowColor_g                    := 0xC ;float
Global GLOWSTRUCT_glowColor_b                    := 0x10 ;float
Global GLOWSTRUCT_glowColor_a                    := 0x14 ;float
Global GLOWSTRUCT_glowAlphaCappedByRenderAlpha   := 0x18 ;bool
Global GLOWSTRUCT_glowAlphaFunctionOfMaxVelocity := 0x19 ;float
Global GLOWSTRUCT_glowAlphaMax                   := 0x1D ;float
Global GLOWSTRUCT_glowPulseOverdrive             := 0x21 ;float
Global GLOWSTRUCT_renderWhenOccluded             := 0x28 ;bool
Global GLOWSTRUCT_renderWhenUnoccluded           := 0x29 ;bool
Global GLOWSTRUCT_fullBloomRender                := 0x2A ;bool
Global GLOWSTRUCT_fullBloomStencilTestValue      := 0x2B ;int
Global GLOWSTRUCT_glowStyle                      := 0x30 ;int
Global GLOWSTRUCT_splitScreenSlot                := 0x34 ;int

;glowStyles
Global GLOWSTYLE_DEFAULT    := 0
Global GLOWSTYLE_RIM3D      := 1
Global GLOWSTYLE_EDGE       := 2
Global GLOWSTYLE_EDGE_PULSE := 3

/*
Class GlowObjectDefinition {
	__New(ByRef glowObj ,index) {
		Global glow_struct
		csgo.readRaw(GlowObj+(index*0x38), glow_struct, 0x38)
		this.nextFreeSlot                    := NumGet(glow_struct, GLOWSTRUCT_nextFreeSlot, "int")
		,this.entity                         := NumGet(glow_struct, GLOWSTRUCT_entity, "int")
		,this.glowColor_r                    := NumGet(glow_struct, GLOWSTRUCT_glowColor_r, "float")
		,this.glowColor_g                    := NumGet(glow_struct, GLOWSTRUCT_glowColor_g, "float")
		,this.glowColor_b                    := NumGet(glow_struct, GLOWSTRUCT_glowColor_b, "float")
		,this.glowColor_a                    := NumGet(glow_struct, GLOWSTRUCT_glowColor_a, "float")
		,this.glowAlphaCappedByRenderAlpha   := NumGet(glow_struct, GLOWSTRUCT_glowAlphaCappedByRenderAlpha, "char")
		,this.glowAlphaFunctionOfMaxVelocity := NumGet(glow_struct, GLOWSTRUCT_glowAlphaFunctionOfMaxVelocity, "float")
		,this.glowAlphaMax                   := NumGet(glow_struct, GLOWSTRUCT_glowAlphaMax, "float")
		,this.glowPulseOverdrive             := NumGet(glow_struct, GLOWSTRUCT_glowPulseOverdrive, "float")
		,this.renderWhenOccluded             := NumGet(glow_struct, GLOWSTRUCT_renderWhenOccluded, "char")
		,this.renderWhenUnoccluded           := NumGet(glow_struct, GLOWSTRUCT_renderWhenUnoccluded, "char")
		,this.fullBloomRender                := NumGet(glow_struct, GLOWSTRUCT_fullBloomRender, "char")
		,this.fullBloomStencilTestValue      := NumGet(glow_struct, GLOWSTRUCT_fullBloomStencilTestValue, "int")
		,this.glowStyle                      := NumGet(glow_struct, GLOWSTRUCT_glowStyle, "int")
		,this.splitScreenSlot                := NumGet(glow_struct, GLOWSTRUCT_splitScreenSlot, "int")
		,this.index := index
		,this.glowObj := glowObj
	}
	
	Glow(ByRef r, ByRef g, ByRef b, ByRef a, ByRef rwo, ByRef rwu, ByRef fbr, gs:=0) {
		NumPut(r/255, glow_struct, GLOWSTRUCT_glowColor_r, "float")
		NumPut(g/255, glow_struct, GLOWSTRUCT_glowColor_g, "float")
		NumPut(b/255, glow_struct, GLOWSTRUCT_glowColor_b, "float")
		NumPut(a/255, glow_struct, GLOWSTRUCT_glowColor_a, "float")
		NumPut(rwo, glow_struct, GLOWSTRUCT_renderWhenOccluded, "char")
		NumPut(rwu, glow_struct, GLOWSTRUCT_renderWhenUnoccluded, "char")
		NumPut(fbr, glow_struct, GLOWSTRUCT_fullBloomRender, "char")
		NumPut(gs, glow_struct, GLOWSTRUCT_glowStyle, "int")
		csgo.writeRaw(this.glowObj+(this.index*0x38), &glow_struct, 0x38)
	}
}
*/

;GlobalVars
Global realtime          := 0x0 ;float
Global framecount        := 0x4 ;int
Global absoluteFrameTime := 0x8 ;float
Global currenttime       := 0x10 ;float
Global frametime         := 0x14 ;float
Global maxClients        := 0x18 ;int
Global tickCount         := 0x1C ;int
Global intervalPerTick   := 0x20 ;float

Class GlobalVars {
	__New() {
		csgo.readRaw(engine + dwGlobalVars, globalvars_struct, intervalPerTick+0x4)
		this.realtime           := NumGet(globalvars_struct, realtime, "float")
		,this.framecount        := NumGet(globalvars_struct, framecount, "int")
		,this.absoluteFrameTime := NumGet(globalvars_struct, absoluteFrameTime, "float")
		,this.currenttime       := NumGet(globalvars_struct, currenttime, "float")
		,this.frametime         := NumGet(globalvars_struct, frametime, "float")
		,this.maxClients        := NumGet(globalvars_struct, maxClients, "int")
		,this.tickCount         := NumGet(globalvars_struct, tickCount, "int")
		,this.intervalPerTick   := NumGet(globalvars_struct, intervalPerTick, "float")
	}
}


;classid
Global ClassId := {}
ClassId.AK47 := 1
ClassId.BaseAnimating := 2
ClassId.GrenadeProjectile := 9
ClassId.WeaponWorldModel := 23
ClassId.BreachCharge := 28
ClassId.BreachChargeProjectile := 29
ClassId.BumpMine := 32
ClassId.BumpMineProjectile := 33
ClassId.C4 := 34
ClassId.Chicken := 36
ClassId.Player := 40
ClassId.PlayerResource := 41
ClassId.Ragdoll := 42
ClassId.Deagle := 46
ClassId.DecoyGrenade := 47
ClassId.DecoyProjectile := 48
ClassId.Drone := 49
ClassId.Dronegun := 50
ClassId.PropDynamic := 52
ClassId.EconEntity := 53
ClassId.EconWearable := 54
ClassId.Flashbang := 77
ClassId.HEGrenade := 96
ClassId.Hostage := 97
ClassId.Inferno := 100
ClassId.Healthshot := 104
ClassId.Cash := 105
ClassId.Knife := 107
ClassId.KnifeGG := 108
ClassId.MolotovGrenade := 113
ClassId.MolotovProjectile := 114
ClassId.PropPhysicsMultiplayer := 123
ClassId.AmmoBox := 125
ClassId.LootCrate := 126
ClassId.RadarJammer := 127
ClassId.WeaponUpgrade := 128
ClassId.PlantedC4 := 129
ClassId.PropDoorRotating := 143
ClassId.SensorGrenade := 152
ClassId.SensorGrenadeProjectile := 153
ClassId.SmokeGrenade := 156
ClassId.SmokeGrenadeProjectile := 157
ClassId.Snowball := 159
ClassId.SnowballPile := 160
ClassId.SnowballProjectile := 161
ClassId.Tablet := 172
ClassId.Aug := 232
ClassId.Awp := 233
ClassId.Elite := 239
ClassId.FiveSeven := 241
ClassId.G3sg1 := 242
ClassId.Glock := 245
ClassId.P2000 := 246
ClassId.P250 := 258
ClassId.Scar20 := 261
ClassId.Sg553 := 265
ClassId.Ssg08 := 267
ClassId.Tec9 := 269
ClassId.World := 275



Process, Wait, csgo.exe
Global csgo := new _ClassMemory("ahk_exe csgo.exe", "", hProcessCopy)
Global client := csgo.getModuleBaseAddress("client.dll")
Global engine := csgo.getModuleBaseAddress("engine.dll")
Global materialsystem := csgo.getModuleBaseAddress("materialsystem.dll")

;pattern := csgo.hexStringToPattern("A0 ?? ?? 0B 08")
;Global smokecount := csgo.modulePatternScan("client.dll", pattern*) + 0xC









DllCall("QueryPerformanceFrequency", "Int64*", freq)
ShootBefore := ShootAfter := 0


Global enable_glow := 0
Global enable_glow_enemy := 0
Global glow_enemy_color := 0xFFC22CCF
Global glow_enemy_color_a := 0
Global glow_enemy_color_r := 0
Global glow_enemy_color_g := 0
Global glow_enemy_color_b := 0
Global enable_glow_team := 0
Global glow_team_color := 0xFF00C800 ;ARGB
Global glow_team_color_a := 0
Global glow_team_color_r := 0
Global glow_team_color_g := 0
Global glow_team_color_b := 0
Global glow_weapon_color := 0xF0F0F0FF

Global enable_chams := 0
Global enable_chams_enemy := 0
Global chams_enemy_color := 0x00FFFFFF
Global chams_enemy_color_r := 0
Global chams_enemy_color_b := 0
Global chams_enemy_color_b := 0
Global enable_chams_team := 0
Global chams_team_color := 0x00FFFFFF
Global chams_team_color_r := 0
Global chams_team_color_g := 0
Global chams_team_color_b := 0
Global enable_chams_local := 0
Global chams_local_color := 0x00FFFFFF
Global chams_local_color_r := 0
Global chams_local_color_g := 0
Global chams_local_color_b := 0

Global fov_changer_value := 90

;Global aspect_ratio_value := 1.777777

Global enable_dont_render := 1


;_ImGui_EnableViewports()
hwnd := _ImGui_GUICreate("CS:GO Ahk External Hack Settings", 720, 540, (A_ScreenWidth-720)//2, (A_ScreenHeight-540)//2)
winshow, ahk_id %hwnd%
Global rc
VarSetCapacity(rc, 16)
DllCall("GetClientRect", "Uint", hwnd, "Uint", &rc)

SetFormat, integer, H

Loop {
	DllCall("QueryPerformanceCounter", "Int64*", LoopBefore)
	if !(enable_dont_render & !WinActive("CS:GO Ahk External Hack Settings"))
		settings_gui()
	IsInGame := IsInGame()
	Global LocalPlayer := new CPlayer(GetLocalPlayer())
	if (IsInGame && LocalPlayer.entity) {
		
		MaxPlayer := GetMaxPlayer()
		,glowObj := GetGlowObj()

		if (enable_glow) {
			csgo.writeBytes(client + force_update_spectator_glow, "EB")
		} else {
			csgo.writeBytes(client + force_update_spectator_glow, "74")
		}

		SplitARGBColor(glow_enemy_color, glow_enemy_color_a, glow_enemy_color_r, glow_enemy_color_g, glow_enemy_color_b)
		SplitARGBColor(glow_team_color, glow_team_color_a, glow_team_color_r, glow_team_color_g, glow_team_color_b)
		
		csgo.readRaw(client + dwEntityList, EntityList, (MaxPlayer+1)*0x10)
		Loop % MaxPlayer {
			dwEntity := new CPlayer(NumGet(EntityList, A_index*0x10, "Uint"))

			if (dwEntity.entity=0 || dwEntity.entity=LocalPlayer.entity || dwEntity.m_lifeState || dwEntity.m_bDormant)
				Continue

			csgo.readRaw(glowObj+(dwEntity.m_iGlowIndex*0x38), glow_struct, 0x38)
			if (LocalPlayer.m_iTeamNum != dwEntity.m_iTeamNum)  {
				if (enable_glow && enable_glow_enemy) {
					Glow(glowObj, dwEntity.m_iGlowIndex, glow_struct, glow_enemy_color_r, glow_enemy_color_g, glow_enemy_color_b, glow_enemy_color_a, 1, 0, enable_glow_enemy_fullbloom, 0)
				} else {
					Glow(glowObj, dwEntity.m_iGlowIndex, glow_struct, 0, 0, 0, 0, 0, 0, 0, 0)
				}

				if (enable_chams && enable_chams_enemy) {
					SplitRGBColor(chams_enemy_color, chams_enemy_color_r, chams_enemy_color_g, chams_enemy_color_b)
					chams(dwEntity.entity, chams_enemy_color_r, chams_enemy_color_g, chams_enemy_color_b)
				} else {
					chams(dwEntity.entity, 255, 255, 255)
				}
				if (enable_radar_reveal && dwEntity.m_bSpotted!=2) {
					csgo.write(dwEntity.entity + m_bSpotted, 2, "Char")
				}
			} else {
				if (enable_glow && enable_glow_team) {
					Glow(glowObj, dwEntity.m_iGlowIndex, glow_struct, glow_team_color_r, glow_team_color_g, glow_team_color_b, glow_team_color_a, 1, 0, enable_glow_team_fullbloom, 0)
				} else {
					Glow(glowObj, dwEntity.m_iGlowIndex, glow_struct, 0, 0, 0, 0, 0, 0, 0, 0)
				}
				if (enable_chams && enable_chams_team) {
					SplitRGBColor(chams_team_color, chams_team_color_r, chams_team_color_g, chams_team_color_b)
					chams(dwEntity.entity, chams_team_color_r, chams_team_color_g, chams_team_color_b)
				} else {
					chams(dwEntity.entity, 255, 255, 255)
				}
			}
		}

		if (enable_chams && enable_chams_local) {
			SplitRGBColor(chams_local_color, chams_local_color_r, chams_local_color_g, chams_local_color_b)
			chams(LocalPlayer.GetViewModel(), chams_local_color_r, chams_local_color_g, chams_local_color_b)
		} else {
			chams(LocalPlayer.GetViewModel(), 255, 255, 255)
		}

		SetFloat(engine + model_ambient_min, enable_model_brightness ? model_brightness_value:0) ;model brightness

		csgo.write(LocalPlayer.entity + m_iDefaultFOV, enable_fov_changer ? fov_changer_value:90, "Uint") ;fov changer

		csgo.write(LocalPlayer.entity + m_flFlashMaxAlpha, enable_anti_flash ? 0:255, "Float") ;anti flash


		
		if (enable_auto_bhop && GetKeyState("Space") && WinActive("ahk_exe csgo.exe") && !IsMouseEnable() && (LocalPlayer.m_fFlags & FL_ONGROUND)) { ;auto bhop
			csgo.write(client + dwForceJump, 6, "Int")
		}
		
		WeaponIndex := GetWeaponIndex(LocalPlayer.GetWeapon())
		DllCall("QueryPerformanceCounter", "Int64*", ShootAfter)
		if (enable_auto_pistol && GetKeyState("LButton") && WinActive("ahk_exe csgo.exe") && !IsMouseEnable() && (WeaponIndex=30 || WeaponIndex=36 || WeaponIndex=32 || WeaponIndex=4 || WeaponIndex=3 || WeaponIndex=2 || WeaponIndex=1 || WeaponIndex=61) && ((ShootAfter-ShootBefore)/freq*1000)>=30) {
			csgo.write(client + dwForceAttack, 6, "Uint")
			DllCall("QueryPerformanceCounter", "Int64*", ShootBefore)
		}
		
		if (rcs_value) {
			RCS(rcs_value)
		}




	} else {
		Sleep 10
	}

	DllCall("QueryPerformanceCounter", "Int64*", LoopAfter)
	LoopTimer := (LoopAfter - LoopBefore) / freq * 1000
}


GetMaxPlayer() {
	Return csgo.read(engine + dwClientState, "Uint", dwClientState_MaxPlayer)
}

GetLocalPlayer() {
	Return csgo.read(client + dwLocalPlayer, "Uint")
}

GetLocalPlayerID() {
	Return csgo.read(engine + dwClientState, "Uint", dwClientState_GetLocalPlayer)
}

GetWeaponIndex(dwEntity) {
	Return csgo.read(dwEntity + m_iItemDefinitionIndex, "Uint")
}

GetViewAngles() {
	csgo.readRaw(engine + dwClientState, ViewAngles, 0x8, dwClientState_ViewAngles)
	Return [NumGet(ViewAngles, 0x0, "Float"), NumGet(ViewAngles, 0x4, "Float")]
}

GetEntity(index) {
	Return csgo.read(client + dwEntityList + index * 0x10, "Uint")
}

IsInGame() {
	Return csgo.read(engine + dwClientState, "Uint", dwClientState_State)=6
}

IsMouseEnable() {
	Return !((csgo.read(client + dwMouseEnablePtr + 0x30, "Uint") ^ dwMouseEnablePtr) & 0xF)
}

SetFloat(ByRef Address, value) {
	VarSetCapacity(v, 0x4)
	NumPut(value, v, 0, "Float")
	thisPtr := Address - 0x2C
	,xored := NumGet(v, 0, "Int") ^ thisPtr
	csgo.write(Address, xored, "int")
}

SetInt(ByRef Address, value) {
	VarSetCapacity(v, 0x4)
	NumPut(value, v, 0, "Int")
	thisPtr := Address - 0x30
	,xored := NumGet(v, 0, "Int") ^ thisPtr
	csgo.write(Address, xored, "int")
}

ForceJump(value) {
	csgo.write(client + dwForceJump, value, "int")
}

GetGlowObj() {
	Return csgo.read(client + dwGlowObjectManager, "int")
}
/*
Glow(ByRef glowObj,ByRef glowInd, ByRef struct) {
	csgo.writeRaw(glowObj+(glowInd*0x38), &struct, 16)
	csgo.write(glowObj+(glowInd*0x38)+0x28,  NumGet(struct, 0x10, "Char"), "Char")
	csgo.write(glowObj+(glowInd*0x38)+0x29, 0, "Char")
	csgo.write(glowObj+(glowInd*0x38)+0x2A,  NumGet(struct, 0x11, "Char"), "Char")
}
*/

Glow(ByRef glowObj, ByRef index, ByRef struct, ByRef r, ByRef g, ByRef b, ByRef a, ByRef rwo, ByRef rwu, ByRef fbr, ByRef gs:=0) {
	NumPut(r/255, struct, GLOWSTRUCT_glowColor_r, "float")
	NumPut(g/255, struct, GLOWSTRUCT_glowColor_g, "float")
	NumPut(b/255, struct, GLOWSTRUCT_glowColor_b, "float")
	NumPut(a/255, struct, GLOWSTRUCT_glowColor_a, "float")
	NumPut(rwo, struct, GLOWSTRUCT_renderWhenOccluded, "char")
	NumPut(rwu, struct, GLOWSTRUCT_renderWhenUnoccluded, "char")
	NumPut(fbr, struct, GLOWSTRUCT_fullBloomRender, "char")
	NumPut(gs, struct, GLOWSTRUCT_glowStyle, "int")
	csgo.writeRaw(glowObj+(index*0x38), &struct, 0x38)
}

chams(ByRef dwEntity, r, g, b) {
	csgo.write(dwEntity + m_clrRender, (b<<16)+(g<<8)+r, "Int")
}

RCS(value:=0) {
	static NewViewAngles := [0, 0]
	static OldPunchAngles := [0, 0]
	if (LocalPlayer.m_iShotsFired>1) {
		CurrentViewAngles := GetViewAngles()
		,NewViewAngles[1] := (CurrentViewAngles[1] + OldPunchAngles[1] * 2 * (value/100)) - (LocalPlayer.m_aimPunchAngleX * 2 * (value/100))
	    ,NewViewAngles[2] := (CurrentViewAngles[2] + OldPunchAngles[2] * 2 * (value/100)) - (LocalPlayer.m_aimPunchAngleY * 2 * (value/100))

	    ,NewViewAngles[1] := (NewViewAngles[1]>89) ? 89:NewViewAngles[1]
	    ,NewViewAngles[1] := (NewViewAngles[1]<-89) ? -89:NewViewAngles[1]

	    while (NewViewAngles[2]>180)
	    	NewViewAngles[2] -= 360

	    while (NewViewAngles[2]<-180)
	    	NewViewAngles[2] += 360

	    

	    OldPunchAngles[1] := LocalPlayer.m_aimPunchAngleX
	    ,OldPunchAngles[2] := LocalPlayer.m_aimPunchAngleY

	    VarSetCapacity(ViewAngles, 0x8)
	    NumPut(NewViewAngles[1], ViewAngles, 0x0, "Float")
	    NumPut(NewViewAngles[2], ViewAngles, 0x4, "Float")
	    csgo.writeRaw(engine + dwClientState, &ViewAngles, 0x8, dwClientState_ViewAngles)
	} else {
		OldPunchAngles[1] := LocalPlayer.m_aimPunchAngleX
		,OldPunchAngles[2] := LocalPlayer.m_aimPunchAngleY
	}
}

SendPacket(value) {
	csgo.write(engine + dwbSendPackets, value, "Char")
}

SplitRGBColor(RGBColor, ByRef Red, ByRef Green, ByRef Blue) {
    Red    := RGBColor >> 16 & 0xFF
    ,Green := RGBColor >> 8 & 0xFF
    ,Blue  := RGBColor & 0xFF
}

SplitARGBColor(ARGBColor, ByRef Alpha, ByRef Red, ByRef Green, ByRef Blue) {
	Alpha := ARGBColor >> 24 & 0xFF
    ,Red    := ARGBColor >> 16 & 0xFF
    ,Green := ARGBColor >> 8 & 0xFF
    ,Blue  := ARGBColor & 0xFF
}

settings_gui() {
	Global
	if !_ImGui_PeekMsg()
		ExitApp
	_ImGui_BeginFrame()
	_ImGui_Begin("Setting")
	_ImGui_SetWindowPos(0, 0)
	_ImGui_SetWindowSize(NumGet(rc, 8, "int"), NumGet(rc, 12, "int"))

	_ImGui_BeginTabBar("setting tab")
	/*
	if _ImGui_BeginTabItem("aimbot") {
		_ImGui_NewLine()
		_ImGui_Columns(2)

		_ImGui_Text("coming soon")




	_ImGui_EndTabItem()
	}
	*/

	if _ImGui_BeginTabItem("visuals") {
		_ImGui_NewLine()
		_ImGui_Columns(2)

		_ImGui_Checkbox("Glow", enable_glow)
		_ImGui_BeginChild("glow_child", 320, 112, 1)
			_ImGui_Checkbox("Enemy", enable_glow_enemy)
			_ImGui_SameLine()
			_ImGui_Checkbox("Enemy FullBloom", enable_glow_enemy_fullbloom)
			_ImGui_ColorEdit("enemy color", glow_enemy_color)

			_ImGui_Checkbox("Team", enable_glow_team)
			_ImGui_SameLine()
			_ImGui_Checkbox("Team FullBloom", enable_glow_team_fullbloom)
			_ImGui_ColorEdit("team color", glow_team_color)
			/*
			_ImGui_Checkbox("Weapon", enable_glow_weapon)
			_ImGui_SameLine()
			_ImGui_Checkbox("Weapon FullBloom", enable_glow_weapon_fullbloom)
			_ImGui_ColorEdit("weapon color", glow_weapon_color)
			*/
		_ImGui_EndChild()

		_ImGui_Checkbox("Chams", enable_chams)
		_ImGui_BeginChild("chams_child", 320, 162, 1)
			_ImGui_Checkbox("Enemy", enable_chams_enemy)
			_ImGui_ColorEdit("enemy color", chams_enemy_color)

			_ImGui_Checkbox("Team", enable_chams_team)
			_ImGui_ColorEdit("team color", chams_team_color)

			_ImGui_Checkbox("Local", enable_chams_local)
			_ImGui_ColorEdit("local color", chams_local_color)
		_ImGui_EndChild()

		_ImGui_Checkbox("Model Brightness", enable_model_brightness)
		_ImGui_BeginChild("model_brightness_child", 320, 37, 1)
			_ImGui_SliderFloat("brightness", model_brightness_value, 0, 100)
		_ImGui_EndChild()

		_ImGui_NextColumn()
		_ImGui_Checkbox("FOV Changer", enable_fov_changer)
		_ImGui_BeginChild("FOV_Changer_child", 320, 37, 1)
			_ImGui_SliderInt("FOV", fov_changer_value, 30, 150)
		_ImGui_EndChild()

		_ImGui_Checkbox("Anti Flash", enable_anti_flash)

		_ImGui_Checkbox("Radar reveal", enable_radar_reveal)

	_ImGui_EndTabItem()
	}
	_ImGui_Columns(1)
	if _ImGui_BeginTabItem("misc") {
		_ImGui_NewLine()
		_ImGui_Columns(2)
		
		_ImGui_Checkbox("Auto Bhop", enable_auto_bhop)

		_ImGui_Checkbox("Auto Pistol", enable_auto_pistol)

		_ImGui_SliderInt("RCS", rcs_value, 0, 100)


	_ImGui_EndTabItem()
	}
	_ImGui_Columns(1)
	if _ImGui_BeginTabItem("debug") {
		_ImGui_NewLine()
		_ImGui_Checkbox("Don't draw the settings window when in the background", enable_dont_render)

		_ImGui_Text("LocalPlayer : " . LocalPlayer.entity)
		_ImGui_Text("current weapon entity : " . LocalPlayer.GetWeapon())
		_ImGui_Text("current weapon index : " . GetWeaponIndex(LocalPlayer.GetWeapon()))
		_ImGui_Text("m_iShotsFired : " . LocalPlayer.m_iShotsFired)

		GlobalVar := new GlobalVars()

		_ImGui_Text("fps : " . 1/GlobalVar.absoluteFrameTime)
		_ImGui_Text("maxClients : " . GlobalVar.maxClients)
		_ImGui_Text("tick : " . 1/GlobalVar.intervalPerTick)

		_ImGui_Text("glow object count : " . csgo.read(client + dwGlowObjectManager + 4, "int"))
		
		_ImGui_Text("Loop timer : " . LoopTimer . " ms")

		

		

	}
	_ImGui_EndTabBar()

	



	_ImGui_End()
	_ImGui_EndFrame(0xFF000000)
}
