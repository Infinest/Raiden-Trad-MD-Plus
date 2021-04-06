; Build params: ------------------------------------------------------------------------------
CHEAT	set 0
; Constants: ---------------------------------------------------------------------------------
	MD_PLUS_OVERLAY_PORT:	equ $0003F7FA
	MD_PLUS_CMD_PORT:		equ $0003F7FE
	SOUND_INDEX:			equ $000007C4
	MUSIC_INDEX_MAX:		equ	$8						; Number of music track pointers listed at SONG_LIST

; Overrides: ---------------------------------------------------------------------------------
	;org $2B2A
	;jsr SOUND_COMMAND_DETOUR
	
	org $78E
	jsr SOUND_TEST_MUSIC_DETOUR
	nop

	org $79E
	jsr SOUND_TEST_STOP_DETOUR

	org $A9E
	jsr INGAME_MUSIC_INIT_DETOUR

	org $D3C
	jsr PLAY_GAME_OVER_MUSIC_DETOUR

	org $2AAE
	jsr SOUND_INIT_DETOUR

	org $2B08
	jsr	PAUSE_MUSIC_DETOUR

	org $2B12
	jsr RESUME_MUSIC_DETOUR

	org $3B08
	jsr INGAME_MUSIC_CHANGE_DETOUR

	if CHEAT
	org $4C3E
	dc.b $F6,$A4
	endif

; Detours: -----------------------------------------------------------------------------------
	org $000FFC00

SOUND_TEST_MUSIC_DETOUR
	move	#$1300,D1
	jsr		WRITE_MD_PLUS_FUNCTION						; Make sure cd audio playback stops when another track/sfx is played
	jsr		GET_MUSIC_INDEX
	cmpi	#MUSIC_INDEX_MAX,D1							; If 8 < GET_MUSIC_INDEX the played sound is SFX
	bhi		SOUNT_TEST_DO_NOT_PLAY_VIA_MD_PLUS			; Therefore, we don't want to play it via MD+
	ori.w	#$1200,D1
	jsr		WRITE_MD_PLUS_FUNCTION
	moveq	#$0,D0										; Zero out D0 to disable normal FM playback
SOUNT_TEST_DO_NOT_PLAY_VIA_MD_PLUS
	jsr		$2B1C
	move	#$2500,SR
	rts

SOUND_TEST_STOP_DETOUR
	move	#$1300,D1									; Put pause command into D1
	jsr		WRITE_MD_PLUS_FUNCTION
	move.l	#$20000,D0
	rts

INGAME_MUSIC_INIT_DETOUR
	move.w	($FFFFE918),D0
	jsr		GET_MUSIC_INDEX
	cmpi	#MUSIC_INDEX_MAX,D1							; If 8 < GET_MUSIC_INDEX the played sound is SFX
	bhi		INGAME_MUSIC_INIT_DO_NOT_PLAY_VIA_MD_PLUS	; Therefore, we don't want to play it via MD+
	ori.w	#$1200,D1
	jsr		WRITE_MD_PLUS_FUNCTION
	moveq	#$0,D0										; Zero out D0 to disable normal FM playback
INGAME_MUSIC_INIT_DO_NOT_PLAY_VIA_MD_PLUS
	rts

PLAY_GAME_OVER_MUSIC_DETOUR
	move.l	#$10013,D0
	jsr		GET_MUSIC_INDEX
	ori.w	#$1200,D1
	jsr		WRITE_MD_PLUS_FUNCTION
	moveq	#$0,D0										; Zero out D0 to disable normal FM playback
	rts

SOUND_INIT_DETOUR
	move	#$1300,D1									; Put pause command into D1
	jsr		WRITE_MD_PLUS_FUNCTION
	movea.l	#$36800,A1
	rts

PAUSE_MUSIC_DETOUR
	move	#$1300,D1									; Put pause command into D1
	jsr		WRITE_MD_PLUS_FUNCTION
	move.l	#$50001,D0
	rts

RESUME_MUSIC_DETOUR
	move	#$1400,D1									; Put resume command into D1
	jsr		WRITE_MD_PLUS_FUNCTION
	move.l	#$50000,D0
	rts

INGAME_MUSIC_CHANGE_DETOUR
	move.b	D1,D0
	jsr		GET_MUSIC_INDEX
	cmpi	#MUSIC_INDEX_MAX,D1							; If 8 < GET_MUSIC_INDEX the played sound is SFX
	bhi		INGAME_MUSIC_CHANGE_DO_NOT_PLAY_VIA_MD_PLUS	; Therefore, we don't want to play it via MD+
	ori.w	#$1200,D1									; Or play command into D1
	jsr		WRITE_MD_PLUS_FUNCTION
	moveq	#$0,D0										; Zero out D0 to disable normal FM playback
INGAME_MUSIC_CHANGE_DO_NOT_PLAY_VIA_MD_PLUS
	move	#$2700,SR
	rts

; Helper Functions: --------------------------------------------------------------------------
GET_MUSIC_INDEX
	movea.l	#SONG_LIST,A5								; Load address of song list into register A5
	move.l	#$FF,D1										; Make sure D1 is #$0 after first add instruction in loop
GET_INDEX_LOOP
	addi.b	#$1,D1
	cmpi.b	#$FF,(A5,D1)								; If the value equals $FF, we have reached the end of our song list
	beq		LEAVE_LOOP
	cmp.b	(A5,D1),D0									; Check if current value matches the track pointer value
	bne		GET_INDEX_LOOP
LEAVE_LOOP
	addi.b	#$1,D1										; Add one to make sure the track indexes start at 1
	rts

WRITE_MD_PLUS_FUNCTION:
	move.w  #$CD54,(MD_PLUS_OVERLAY_PORT)				; Open interface
	move.w  D1,(MD_PLUS_CMD_PORT)						; Send command to interface
	move.w  #$0000,(MD_PLUS_OVERLAY_PORT)				; Close interface
	rts

; Data: --------------------------------------------------------------------------------------
SONG_LIST
	dc.b $10,$11,$13,$15,$17,$19,$1B,$1D,$FF