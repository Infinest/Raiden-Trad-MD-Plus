; Build params: ------------------------------------------------------------------------------
CHEAT					set 0
AUTO_FIRE_DEFAULT_ON	set 0
; Constants: ---------------------------------------------------------------------------------
	MD_PLUS_OVERLAY_PORT:	equ $0003F7FA
	MD_PLUS_CMD_PORT:		equ $0003F7FE
	MUSIC_INDEX_MAX:		equ	$8			; Number of music track pointers listed at SONG_LIST
	AUTO_FIRE_SETTING:		equ $FFFFE9AE

; Overrides: ---------------------------------------------------------------------------------
	org $312
	if	AUTO_FIRE_DEFAULT_ON
	jmp STARTUP_DETOUR
RETURN_FROM_STARTUP_DETOUR
	endif

	org $2AAE
	jsr SOUND_INIT_DETOUR

	org $2B2A
	jsr SOUND_COMMAND_DETOUR

	if CHEAT
	org $4C3E
	dc.b $F6,$A4
	endif

; Detours: -----------------------------------------------------------------------------------
	org $000FFC00
	if AUTO_FIRE_DEFAULT_ON
STARTUP_DETOUR
	jsr		$AA60
	move.b	#$FF,(AUTO_FIRE_SETTING)		; Turn auto fire ON by default
	jmp		RETURN_FROM_STARTUP_DETOUR
	endif

SOUND_INIT_DETOUR
	move	#$1300,D1						; Put pause command into D1
	jsr		WRITE_MD_PLUS_FUNCTION
	movea.l	#$36800,A1
	rts

SOUND_COMMAND_DETOUR
	swap	D0
	cmpi.b	#$5,D0							; $5 is the command for pause/resume
	bne		NOT_PAUSE_RESUME_COMMAND
	swap	D0
	move.w	#$0014,D1
	sub.b	D0,D1							; If D0.b is $1 it's a pause command. Otherwise it's $0. With a subtract we get the correct corresponding MD+ commands
	lsl.w	#$8,D1							; Left shift D1 by 8 bits so we make $1300 out of $0013 or $1400 out of $0014
	jsr		WRITE_MD_PLUS_FUNCTION
	bra		DETOUR_END
NOT_PAUSE_RESUME_COMMAND
	cmpi.b	#$2,D0							; $2 is the command for stop
	bne		NOT_STOP_COMMAND
	swap	D0
	move	#$1300,D1						; Put pause command into D1
	jsr		WRITE_MD_PLUS_FUNCTION
	bra		DETOUR_END
NOT_STOP_COMMAND
	cmpi.b	#$1,D0							; $1 is the command for play music/sfx
	bne		NOT_PLAY_COMMAND
	swap	D0
	jsr		GET_MUSIC_INDEX
	cmpi	#MUSIC_INDEX_MAX,D1				; If 8 < GET_MUSIC_INDEX the played sound is SFX
	bhi		DETOUR_END						; Therefore, we don't want to play it via MD+
	ori.w	#$1200,D1						; Or play command into upper byte of D1.w
	jsr		WRITE_MD_PLUS_FUNCTION
	moveq	#$0,D0							; Zero out D0 to disable normal FM playback for music tracks
	bra		DETOUR_END
NOT_PLAY_COMMAND
	swap	D0
DETOUR_END
	moveq	#$0,D1
	jsr		$B06C
	rts

; Helper Functions: --------------------------------------------------------------------------
GET_MUSIC_INDEX
	movea.l	#SONG_LIST,A0					; Load address of song list into register A5
	move.l	#$FF,D1							; Make sure D1 is #$0 after first add instruction in loop
GET_INDEX_LOOP
	addi.b	#$1,D1
	cmpi.b	#$FF,(A0,D1)					; If the value equals $FF, we have reached the end of our song list
	beq		LEAVE_LOOP
	cmp.b	(A0,D1),D0						; Check if current value matches the track pointer value
	bne		GET_INDEX_LOOP
LEAVE_LOOP
	addi.b	#$1,D1							; Add one to make sure the track indexes start at 1
	rts

WRITE_MD_PLUS_FUNCTION:
	move.w  #$CD54,(MD_PLUS_OVERLAY_PORT)	; Open interface
	move.w  D1,(MD_PLUS_CMD_PORT)			; Send command to interface
	move.w  #$0000,(MD_PLUS_OVERLAY_PORT)	; Close interface
	rts

; Data: --------------------------------------------------------------------------------------
SONG_LIST
	dc.b $10,$11,$13,$15,$17,$19,$1B,$1D,$FF