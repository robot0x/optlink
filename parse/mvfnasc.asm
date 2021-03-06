		TITLE	MVFNASC - Copyright (c) SLR Systems 1994

		INCLUDE	MACROS
		INCLUDE	IO_STRUC

		PUBLIC	MOVE_FN_TO_ASCIZ


		.DATA

		EXTERNDEF	ASCIZ:BYTE

		EXTERNDEF	ASCIZ_LEN:DWORD


		.CODE	ROOT_TEXT

MOVE_FN_TO_ASCIZ	PROC
		;
		;MOVE FILNAM [EAX] TO ASCIZ STRING
		;
		ASSUME	EAX:PTR NFN_STRUCT

		PUSHM	EDI,ESI
		MOV	ECX,[EAX].NFN_TOTAL_LENGTH
		MOV	EDI,OFF ASCIZ
		LEA	ESI,[EAX].NFN_TEXT
		MOV	ASCIZ_LEN,ECX		;LENGTH IN BYTES, NOT 0
		OPTI_MOVSB
		MOV	[EDI],ECX
		POPM	ESI,EDI
		RET

MOVE_FN_TO_ASCIZ	ENDP

		END

