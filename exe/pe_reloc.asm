		TITLE	PE_RELOC - Copyright (c) SLR Systems 1994

		INCLUDE	MACROS
		INCLUDE	PE_STRUC
		INCLUDE	EXES

		PUBLIC	DO_PE_RELOC,PE_OUTPUT_RELOCS


		.DATA

		EXTERNDEF	TEMP_RECORD:BYTE,FIX2_LD_TYPE:BYTE

		EXTERNDEF	CURN_PAGE_RELOC_GINDEX:DWORD,SEG_PAGE_SIZE_M1:DWORD,NOT_SEG_PAGE_SIZE_M1:DWORD
		EXTERNDEF	LIDATA_RELOCS_START:DWORD,PE_BASE:DWORD,PE_NEXT_OBJECT_RVA:DWORD,FINAL_HIGH_WATER:DWORD
		EXTERNDEF	LIDATA_RELOCS_NEXT:DWORD,PE_FIXUP_OBJECT_GINDEX:DWORD

		EXTERNDEF	PAGE_RELOC_GARRAY:STD_PTR_S,CURN_PAGE_RELOC:PAGE_RELOC_STRUCT,PAGE_RELOC_STUFF:ALLOCS_STRUCT
		EXTERNDEF	PEXEHEADER:PEXE,PE_OBJECT_GARRAY:STD_PTR_S


		.CODE	PASS2_TEXT

		EXTERNDEF	PAGE_RELOC_POOL_GET:PROC,_common_inst_init:proc,CHANGE_PE_OBJECT:PROC,DO_OBJECT_ALIGN:PROC
		EXTERNDEF	MOVE_EAX_TO_FINAL_HIGH_WATER:PROC,_release_minidata:proc,RELEASE_GARRAY:PROC,ERR_ABORT:PROC
		EXTERNDEF	GET_NEW_LOG_BLK:PROC


DO_PE_RELOC	PROC
		;
		;EAX IS BASED ADDRESS TO BE RELOCATED...
		;
		GETT	CL,PE_BASE_FIXED
		MOV	DL,FIX2_LD_TYPE

		OR	CL,CL
		JNZ	L9$

		AND	DL,MASK BIT_LI
		JNZ	L5$

		PUSHM	EDI,ESI

		MOV	ESI,OFF CURN_PAGE_RELOC
		ASSUME	ESI:PTR PAGE_RELOC_STRUCT
		MOV	ECX,PE_BASE

		SUB	EAX,ECX
		MOV	ECX,CURN_PAGE_RELOC._PAGE_RELOC_RVA

		PUSH	EAX
		AND	EAX,0FFFFF000H
		;
		;EAX IS PAGE BOUNDARY OF RVA
		;
		CMP	ECX,EAX
		JZ	L2$

		CALL	INSTALL_RELOC_RVA	;RETURNS DS:SI IS RELOC_RVA PTR
L2$:
		MOV	EDX,[ESI]._PAGE_RELOC_CNT
		MOV	EAX,[ESI]._PAGE_RELOC_SET_LEFT

		INC	EDX
		POP	ECX

		MOV	[ESI]._PAGE_RELOC_CNT,EDX
		AND	ECX,4K-1

		TEST	EAX,EAX
		JZ	L3$			;NEED ANOTHER SET

		DEC	EAX
		MOV	EDI,[ESI]._PAGE_RELOC_SET

		MOV	[ESI]._PAGE_RELOC_SET_LEFT,EAX
		OR	CH,30H			;32-BIT OFFSET

		MOV	BPTR [EAX*2+EDI],CL
		POP	ESI

		MOV	BPTR [EAX*2+EDI+1],CH
		POP	EDI
L9$:
		RET

L5$:
		;
		;LIDATA RECORD...
		;
		MOV	EDX,LIDATA_RELOCS_NEXT

		TEST	EDX,EDX
		JZ	L55$
L51$:
		MOV	[EDX],EBX			;JUST SAVE RECORD OFFSET
		ADD	EDX,4

		MOV	LIDATA_RELOCS_NEXT,EDX

		RET

L55$:
		CALL	GET_NEW_LOG_BLK

		MOV	LIDATA_RELOCS_START,EAX
		MOV	EDX,EAX

		JMP	L51$

L3$:
		MOV	EAX,32
		CALL	PAGE_RELOC_POOL_GET

		OR	CH,30H
		MOV	EDX,[ESI]._PAGE_RELOC_SET

		SHL	ECX,16
		MOV	[ESI]._PAGE_RELOC_SET,EAX

		MOV	[EAX+28],EDX
		MOV	[EAX+24],ECX

		MOV	EDI,EAX
		MOV	ECX,6

		XOR	EAX,EAX

		REP	STOSD

		MOV	[ESI]._PAGE_RELOC_SET_LEFT,13

		POPM	ESI,EDI

		RET

DO_PE_RELOC	ENDP


INIT_RELOC	PROC	NEAR	PRIVATE
		;
		;
		;
		MOV	EAX,OFF PAGE_RELOC_STUFF
		push	ECX
		push	EAX
		call	_common_inst_init
		add	ESP,4
		pop	ECX

		MOV	EAX,EDI
		JMP	INIT_RELOC_RET

INIT_RELOC	ENDP


INSTALL_RELOC_RVA	PROC	NEAR
		;
		;EAX IS CURRENT PAGE RVA
		;
		;FIRST, STORE OLD ONE
		;
		PUSHM	EDI,EBX

		MOV	EDI,CURN_PAGE_RELOC_GINDEX
		MOV	ECX,SIZE PAGE_RELOC_STRUCT/4

		TEST	EDI,EDI
		JZ	L2$

		CONVERT	EDI,EDI,PAGE_RELOC_GARRAY
		ASSUME	EDI:PTR PAGE_RELOC_STRUCT

		REP	MOVSD

		ASSUME	EDI:NOTHING
L2$:
		;
		;EAX IS ITEM TO STORE... PAGE RVA/4K
		;
		;NOW TRASHES SI...
		;
INIT_RELOC_RET::
		MOV	EBX,PAGE_RELOC_STUFF.ALLO_HASH_TABLE_PTR
		MOV	EDI,EAX

		TEST	EBX,EBX
		JZ	INIT_RELOC

		SHR	EAX,10
		MOV	EDX,PAGE_RELOC_STUFF.ALLO_HASH

		AND	EDX,EAX

		MOV	ESI,[EBX+EDX*4]
		LEA	EBX,[EBX+EDX*4 - PAGE_RELOC_STRUCT._PAGE_RELOC_NEXT_HASH_GINDEX]
NAME_NEXT:
		TEST	ESI,ESI
		JZ	DO1

		MOV	EDX,ESI
		CONVERT	ESI,ESI,PAGE_RELOC_GARRAY
		ASSUME	ESI:PTR PAGE_RELOC_STRUCT
		MOV	EBX,ESI
		ASSUME	EBX:PTR PAGE_RELOC_STRUCT
		;
		;IS IT A MATCH?
		;
		MOV	ECX,[ESI]._PAGE_RELOC_RVA
		MOV	ESI,[ESI]._PAGE_RELOC_NEXT_HASH_GINDEX

		CMP	ECX,EDI
		JNZ	NAME_NEXT

		MOV	EAX,EDX
		JMP	SET_NEW_PAGE_RELOC

DO1:
		ASSUME	EBX:PTR PAGE_RELOC_STRUCT
		;
		;EBX GETS POINTER
		;
		;EDI	IS RVA
		;
		MOV	EAX,SIZE PAGE_RELOC_STRUCT
		CALL	PAGE_RELOC_POOL_GET

		MOV	ECX,EAX
		INSTALL_POINTER_GINDEX	PAGE_RELOC_GARRAY
		MOV	[EBX]._PAGE_RELOC_NEXT_HASH_GINDEX,EAX
		ASSUME	ECX:PTR PAGE_RELOC_STRUCT

		MOV	EDX,LAST_PAGE_RELOC_GINDEX
		MOV	LAST_PAGE_RELOC_GINDEX,EAX

		TEST	EDX,EDX
		JZ	DO_FIRST

		CONVERT	EDX,EDX,PAGE_RELOC_GARRAY
		ASSUME	EDX:PTR PAGE_RELOC_STRUCT

		MOV	[EDX]._PAGE_RELOC_NEXT_GINDEX,EAX
DO_FIRST_RET:
		MOV	EBX,ECX

		MOV	[ECX]._PAGE_RELOC_RVA,EDI
		XOR	ECX,ECX

		MOV	[EBX]._PAGE_RELOC_NEXT_HASH_GINDEX,ECX
		MOV	[EBX]._PAGE_RELOC_NEXT_GINDEX,ECX

		MOV	[EBX]._PAGE_RELOC_SET,ECX
		MOV	[EBX]._PAGE_RELOC_CNT,ECX

		MOV	[EBX]._PAGE_RELOC_SET_LEFT,ECX
SET_NEW_PAGE_RELOC:
		MOV	ESI,EBX

		MOV	CURN_PAGE_RELOC_GINDEX,EAX
		MOV	EDI,OFF CURN_PAGE_RELOC

		MOV	ECX,SIZE PAGE_RELOC_STRUCT/4
		POP	EBX

		REP	MOVSD

		MOV	ESI,OFF CURN_PAGE_RELOC
		POP	EDI

		RET

DO_FIRST:
		MOV	FIRST_PAGE_RELOC_GINDEX,EAX
		JMP	DO_FIRST_RET

		ASSUME	EBX:NOTHING

INSTALL_RELOC_RVA	ENDP


PE_OUTPUT_RELOCS	PROC
		;
		;
		;
		BITT	PE_BASE_FIXED
		JNZ	L9$

		PUSHM	EDI,ESI,EBX
		CALL	CHANGE_PE_OBJECT
		ASSUME	EAX:PTR PE_OBJECT_STRUCT

		MOV	[EAX]._PEOBJECT_FLAGS,MASK PEL_INIT_DATA_OBJECT + MASK PEH_READABLE

		MOV	DPTR [EAX]._PEOBJECT_NAME,'ler.'

		MOV	DPTR [EAX]._PEOBJECT_NAME+4,'co'

		MOV	ECX,PE_NEXT_OBJECT_RVA
		MOV	ESI,OFF CURN_PAGE_RELOC

		MOV	[EAX]._PEOBJECT_RVA,ECX
		MOV	PEXEHEADER._PEXE_FIXUP_RVA,ECX

		MOV	EDI,CURN_PAGE_RELOC_GINDEX
		MOV	ECX,SIZE PAGE_RELOC_STRUCT/4

		TEST	EDI,EDI
		JZ	L0$
		CONVERT	EDI,EDI,PAGE_RELOC_GARRAY

		REP	MOVSD
L0$:
		CALL	SORT_RELOC_PAGES
		;
		;OUTPUT RELOCS, A PAGE AT A TIME
		;
		MOV	EAX,FINAL_HIGH_WATER
		MOV	ESI,FIRST_PAGE_RELOC_GINDEX

		PUSH	EAX
		JMP	L5$

L9$:
		RET

L1$:
		CONVERT	ESI,ESI,PAGE_RELOC_GARRAY
		ASSUME	ESI:PTR PAGE_RELOC_STRUCT

		MOV	EAX,[ESI]._PAGE_RELOC_CNT	;# OF RELOCS THIS PAGE
		MOV	EDI,OFF TEMP_RECORD

		MOV	EDX,[ESI]._PAGE_RELOC_NEXT_GINDEX
		MOV	ECX,[ESI]._PAGE_RELOC_RVA

		PUSH	EDX
		XOR	EDX,EDX				;LARGEST OFFSET

		LEA	EAX,[EAX*2+11]
		MOV	[EDI],ECX

		AND	AL,0FCH				;INCLUDE DWORD ALIGNMENT
		MOV	ESI,[ESI]._PAGE_RELOC_SET
		ASSUME	ESI:NOTHING

		MOV	[EDI+4],EAX
		ADD	EDI,8
L2$:
		MOV	ECX,14				;MAX 14 THIS SET
		XOR	EAX,EAX
L3$:
		MOV	AX,[ESI]
		ADD	ESI,2

		TEST	EAX,EAX
		JZ	L35$

		MOV	[EDI],AX
		ADD	EDI,2

		CMP	EDX,EAX
		JA	L35$

		MOV	EDX,EAX			;SAVE BIGGEST
		MOV	EBX,EDI			;AND POINTER
L35$:
		DEC	ECX
		JNZ	L3$

		MOV	ESI,[ESI]

		TEST	ESI,ESI
		JNZ	L2$

		MOV	[EDI],CX		;JUST IN CASE FOR DWORD ALIGN
		ADD	EDI,2

		AND	EDI,0FFFFFFFCH
		POP	ESI
		;
		;LARGEST MUST BE LAST
		;
		MOV	CX,[EDI-2]
		MOV	EAX,OFF TEMP_RECORD

		MOV	[EBX-2],CX
		MOV	ECX,DPTR TEMP_RECORD+4

		MOV	[EDI-2],DX
		CALL	MOVE_EAX_TO_FINAL_HIGH_WATER
L5$:
		TEST	ESI,ESI
		JNZ	L1$

		POP	ECX
		MOV	EAX,FINAL_HIGH_WATER

		SUB	EAX,ECX
		MOV	ESI,PE_FIXUP_OBJECT_GINDEX

		MOV	PEXEHEADER._PEXE_FIXUP_SIZE,EAX

		DO_FILE_ALIGN_EAX

		CONVERT	ESI,ESI,PE_OBJECT_GARRAY
		ASSUME	ESI:PTR PE_OBJECT_STRUCT

		MOV	[ESI]._PEOBJECT_VSIZE,EAX
		MOV	ECX,PEXEHEADER._PEXE_FIXUP_RVA

		ADD	EAX,ECX
		CALL	DO_OBJECT_ALIGN

		MOV	PE_NEXT_OBJECT_RVA,EAX
		POP	EBX

		POPM	ESI,EDI

		MOV	EAX,OFF PAGE_RELOC_STUFF
		push	EAX
		call	_release_minidata
		add	ESP,4

		MOV	EAX,OFF PAGE_RELOC_GARRAY
		JMP	RELEASE_GARRAY

PE_OUTPUT_RELOCS	ENDP


SORT_RELOC_PAGES	PROC	NEAR
		;
		;SORT THESE PLEASE...  THEY MIGHT BE SORTED ALREADY...
		;
		PUSHM	EDI,ESI,EBX
		XOR	ECX,ECX

		MOV	ESI,FIRST_PAGE_RELOC_GINDEX
		MOV	LAST_PAGE_RELOC_GINDEX,ECX

		MOV	FIRST_PAGE_RELOC_GINDEX,ECX
L1$:
		TEST	ESI,ESI
		JZ	L9$

		XOR	ECX,ECX
		MOV	EDX,ESI

		CONVERT	ESI,ESI,PAGE_RELOC_GARRAY
		ASSUME	ESI:PTR PAGE_RELOC_STRUCT

		MOV	EBX,[ESI]._PAGE_RELOC_RVA
		MOV	EDI,LAST_PAGE_RELOC_GINDEX
L2$:
		TEST	EDI,EDI
		JZ	INSERT_FRONT
		
		MOV	ECX,EDI
		CONVERT	EDI,EDI,PAGE_RELOC_GARRAY
		ASSUME	EDI:PTR PAGE_RELOC_STRUCT
		MOV	EAX,[EDI]._PAGE_RELOC_RVA

		CMP	EAX,EBX
		JB	INSERT_AFTER

		MOV	EDI,[EDI]._PAGE_RELOC_PREV_GINDEX
		JMP	L2$

L9$:
		POPM	EBX,ESI,EDI

		RET

INSERT_AFTER:
		;
		;EDX:ESI IS GUY TO STICK IN LIST AFTER ECX:EDI
		;
		MOV	EAX,[EDI]._PAGE_RELOC_NEXT_GINDEX
		MOV	[EDI]._PAGE_RELOC_NEXT_GINDEX,EDX
IA_1:
		MOV	[ESI]._PAGE_RELOC_PREV_GINDEX,ECX
		MOV	EBX,[ESI]._PAGE_RELOC_NEXT_GINDEX

		MOV	[ESI]._PAGE_RELOC_NEXT_GINDEX,EAX
		MOV	ESI,EBX

		TEST	EAX,EAX
		JNZ	NOT_LAST

		MOV	LAST_PAGE_RELOC_GINDEX,EDX
		JMP	L1$

NOT_LAST:

		CONVERT	EAX,EAX,PAGE_RELOC_GARRAY
		ASSUME	EAX:PTR PAGE_RELOC_STRUCT

		MOV	[EAX]._PAGE_RELOC_PREV_GINDEX,EDX
		JMP	L1$

INSERT_FRONT:
		;
		;EDX:ESI IS GUY TO STICK AT FRONT OF LIST
		;
		MOV	EAX,FIRST_PAGE_RELOC_GINDEX
		MOV	FIRST_PAGE_RELOC_GINDEX,EDX		;I AM FIRST

		XOR	ECX,ECX
		JMP	IA_1

SORT_RELOC_PAGES	ENDP


		.DATA?

FIRST_PAGE_RELOC_GINDEX	DD	?
LAST_PAGE_RELOC_GINDEX	DD	?


		END

