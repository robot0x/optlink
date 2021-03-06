		TITLE	CHKNUL - Copyright (c) SLR Systems 1994

		INCLUDE	MACROS
		INCLUDE	IO_STRUC

		PUBLIC	CHECK_NUL,CHECK_NUL1


		.CODE	PHASE1_TEXT


		ASSUME	EAX:PTR NFN_STRUCT
; returns void
CHECK_NUL	PROC
		;
		;SEE IF [EAX] IS NUL DEVICE..., SET FLAG IF SO...
		;
		CMP	[EAX].NFN_PRIMLEN,0
		JZ	L8$
if	0;fgh_os2
		CMP	[EAX].NFN_EXTLEN,2
		JAE	L9$
endif
		CALL	CHECK_NUL1
		JNZ	L9$
L8$:
		OR	[EAX].NFN_FLAGS,MASK NFN_NUL
L9$:
		RET

CHECK_NUL	ENDP


; returns Z if NUL
CHECK_NUL1	PROC
		;
		;SEE  IF [EAX] PRIMARY NAME IS 'NUL'
		;RETURNS EAX INTACT
		;
		MOV	EDX,[EAX].NFN_PRIMLEN
		MOV	ECX,[EAX].NFN_PATHLEN

		CMP	EDX,3
		JNZ	L9$

		LEA	ECX,[ECX+EAX].NFN_TEXT+1
		PUSH	EAX

		MOV	AL,[ECX-1]
		TO_UPPER
		CMP	AL,'N'
		JNZ	L2$
		MOV	AL,[ECX]
		INC	ECX
		TO_UPPER
		CMP	AL,'U'
		JNZ	L2$
		MOV	AL,[ECX]
		INC	ECX
		TO_UPPER
		CMP	AL,'L'
L2$:
		POP	EAX
L9$:
		RET

CHECK_NUL1	ENDP

		END

