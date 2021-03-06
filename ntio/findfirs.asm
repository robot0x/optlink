		TITLE	FINDFIRST - Copyright (C) SLR Systems 1994

		INCLUDE	MACROS
		INCLUDE	IO_STRUC
		INCLUDE	WIN32DEF

		PUBLIC	DO_FINDFIRST,DO_FINDNEXT,CLOSE_FINDNEXT


		.DATA

		EXTERNDEF	ASCIZ:BYTE,DTA:BYTE


		.CODE	PHASE1_TEXT

		EXTERNDEF	MOVE_FN_TO_ASCIZ:PROC,_parse_filename:proc

; Return: C not found, NC found

DO_FINDFIRST	PROC
		;
		;EAX IS NFN STRUCTURE, FIND FIRST MATCHING FILE AND PUT IT IN
		;EAX
		;
		PUSH	ESI
		MOV	ESI,EAX
		ASSUME	ESI:PTR NFN_STRUCT

		ADD	EAX,NFN_STRUCT.NFN_TEXT
		PUSH	OFF WIN32FINDDATA

		PUSH	EAX
		CALL	FindFirstFile

		MOV	FINDNEXT_HANDLE,EAX

		CMP	EAX,INVALID_HANDLE_VALUE
		JNZ	DF_1

		CMP	ESP,-1
		POP	ESI

		RET

DO_FINDFIRST	ENDP

; Return: C not found, NC found

DO_FINDNEXT	PROC
		;
		;
		;
		PUSH	ESI
		MOV	ESI,EAX

		MOV	EAX,FINDNEXT_HANDLE
		PUSH	OFF WIN32FINDDATA

		PUSH	EAX
		CALL	FindNextFile

		TEST	EAX,EAX
		JZ	L9$		; failed
DF_1::
		MOV	EAX,WIN32FINDDATA.NFILESIZELOW
		MOV	ECX,OFF WIN32FINDDATA.CFILENAME

		MOV	[ESI].NFN_FILE_LENGTH,EAX
		LEA	EDX,[ESI].NFN_TEXT

;		MOV	ECX,OFF DTA+30
		ADD	EDX,[ESI].NFN_PATHLEN
		;
		;MOVE TILL 0
		;
L1$:
		MOV	AL,[ECX]
		INC	ECX

		MOV	[EDX],AL
		INC	EDX

		OR	AL,AL
		JNZ	L1$

		XOR	EAX,EAX
		LEA	ECX,[ESI].NFN_TEXT+1

		MOV	[EDX],EAX
		SUB	EDX,ECX

		MOV	EAX,ESI
		MOV	[ESI].NFN_TOTAL_LENGTH,EDX

		push	EAX
		call	_parse_filename
		add	ESP,4

		OR	[ESI].NFN_FLAGS,MASK NFN_TIME_VALID+MASK NFN_AMBIGUOUS
D_F_FAIL:
		POP	ESI

		RET

L9$:
		CMP	ESP,-1
		JMP	D_F_FAIL

DO_FINDNEXT	ENDP


CLOSE_FINDNEXT	PROC

		MOV	ECX,INVALID_HANDLE_VALUE
		MOV	EAX,FINDNEXT_HANDLE

		CMP	EAX,ECX
		JZ	L9$

		PUSH	EAX
		MOV	FINDNEXT_HANDLE,ECX

		CALL	FindClose
L9$:
		RET

CLOSE_FINDNEXT	ENDP


		.DATA?

WIN32FINDDATA	WIN32_FIND_DATA<>


		.DATA

FINDNEXT_HANDLE	DD	INVALID_HANDLE_VALUE


		END

