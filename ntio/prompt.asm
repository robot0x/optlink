		TITLE	PROMPT - Copyright (C) SLR Systems 1994

		INCLUDE	MACROS
		INCLUDE	IO_STRUC
		INCLUDE	WIN32DEF

		PUBLIC	PROPER_PROMPT,ISSUE_PROMPT,GET_STDIN


		.DATA

		EXTERNDEF	TEMP_RECORD:BYTE,OUTBUF:BYTE

		EXTERNDEF	CURN_COUNT:DWORD,FILESTUFF_PTR:DWORD,CURN_INPTR:DWORD,STDIN:DWORD


		.CODE	FILEPARSE_TEXT

		EXTERNDEF	AX_MESOUT:PROC,DO_DEFAULTS:PROC,MOVE_PATH_PRIM_EXT:PROC,MESOUT:PROC,FORCE_SIGNON:PROC
		EXTERNDEF	LOUTALL_CON:PROC,_err_abort:proc


PROPER_PROMPT	PROC
		;
		;
		;
		CALL	ISSUE_PROMPT
;		MOV	EDX,OFF TEMP_RECORD
;		MOV	BPTR [EDX],250
;		MOV	AH,0AH
;		INT21
;		LEA	ECX,[EDX+2]

		CALL	GET_STDIN

		PUSH	EAX			;ALLOCATE PLACE TO STORE RESULT
		MOV	EDX,OFF TEMP_RECORD+4

		MOV	ECX,ESP
		PUSH	EDX

		PUSH	0			;OVERLAPPED
		PUSH	ECX			;PLACE TO STORE RESULT

		PUSH	MAX_RECORD_LEN		;# OF CHARS TO READ
		PUSH	EDX			;READ BUFFER

		PUSH	EAX			;HANDLE
		CALL	ReadFile

		TEST	EAX,EAX
		JZ	L9$

		POP	ECX
		POP	EAX

		MOV	DPTR TEMP_RECORD,EAX
		MOV	CURN_INPTR,ECX

		INC	EAX

		MOV	CURN_COUNT,EAX

		MOV	DPTR [ECX+EAX-3],1A0A0DH

		RET

L9$::
		MOV	AL,0
		push	EAX
		call	_err_abort


PROPER_PROMPT	ENDP


GET_STDIN	PROC
		;
		;
		;
		MOV	EAX,STDIN

		CMP	EAX,INVALID_HANDLE_VALUE
		JNZ	L1$

		PUSH	STD_INPUT_HANDLE
		CALL	GetStdHandle

		MOV	STDIN,EAX
		CMP	EAX,INVALID_HANDLE_VALUE

		JZ	L9$
L1$:
		RET

GET_STDIN	ENDP


ISSUE_PROMPT	PROC
		;
		;
		;
		CALL	FORCE_SIGNON
if	fg_plink
		BITT	CMDLINE_FREEFORMAT
		JNZ	L1$
endif
		CALL	DO_PRINT_DEFAULTS
if	fg_plink
		JMP	L2$
L1$:
		MOV	EAX,OFF PLINK_PROMPT_MSG
		CALL	MESOUT
L2$:
endif
		RET

ISSUE_PROMPT	ENDP

if	fg_plink
PLINK_PROMPT_MSG	DB	2,'->'
endif


DPD_VARS	STRUC

MY_FILNAM_BP	NFN_STRUCT<>

DPD_VARS	ENDS


FIX		MACRO	X

X		EQU	([EBP].DPD_VARS.(X&_BP))

		ENDM

FIX	MY_FILNAM


DO_PRINT_DEFAULTS	PROC	NEAR
		;
		;
		;
		PUSH	EBP
		LEA	EBP,[ESP - SIZEOF DPD_VARS]
		SUB	ESP,SIZEOF DPD_VARS

		XOR	EAX,EAX
		PUSHM	EDI,ESI,EBX
		MOV	MY_FILNAM.NFN_PATHLEN,EAX
		MOV	MY_FILNAM.NFN_PRIMLEN,EAX
		MOV	MY_FILNAM.NFN_EXTLEN,EAX
		MOV	DPTR MY_FILNAM.NFN_FLAGS,EAX
		MOV	MY_FILNAM.NFN_TOTAL_LENGTH,EAX

		MOV	EAX,FILESTUFF_PTR
		LEA	ECX,MY_FILNAM
		CALL	DO_DEFAULTS		;SET IN FILNAM

		MOV	EBX,FILESTUFF_PTR

		MOV	ESI,[EBX].CMDLINE_STRUCT.CMD_PMSG
		XOR	ECX,ECX
		MOV	EDI,OFF OUTBUF
		MOV	CL,[ESI]
		INC	ESI
		REP	MOVSB
		MOV	BPTR [EDI],'('
		LEA	EAX,[EDI+1]
		LEA	ECX,MY_FILNAM
		CALL	MOVE_PATH_PRIM_EXT

		MOV	WPTR [EAX],':)'
		LEA	ECX,[EAX+2]
		MOV	EAX,OFF OUTBUF
		SUB	ECX,EAX
		CALL	LOUTALL_CON
		POPM	EBX,ESI,EDI
		LEA	ESP,[EBP + SIZEOF DPD_VARS]
		POP	EBP
		RET

DO_PRINT_DEFAULTS	ENDP


		END

