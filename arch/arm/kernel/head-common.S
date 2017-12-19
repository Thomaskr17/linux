/*
 *  linux/arch/arm/kernel/head-common.S
 *
 *  Copyright (C) 1994-2002 Russell King
 *  Copyright (c) 2003 ARM Limited
 *  All Rights Reserved
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 */
#include <asm/assembler.h>

#define ATAG_CORE 0x54410001			@ ATAG_CORE를 식별할 수 있는 ID
#define ATAG_CORE_SIZE ((2*4 + 3*4) >> 2)	@ 공통헤더(2개 word) + ATAG_CORE(3개 word) = 5 word (20 byte)
#define ATAG_CORE_SIZE_EMPTY ((2*4) >> 2)	@ 비어 있는 ATAG의 경우에도 최하 공통헤더로 이루어진 ATAG_CORE로 이루어져야 한다. 따라서 2 word가 필요하다.

#ifdef CONFIG_CPU_BIG_ENDIAN
#define OF_DT_MAGIC 0xd00dfeed		@ 디바이스 트리를 알리는 매직넘버.
#else
#define OF_DT_MAGIC 0xedfe0dd0		@ DTB는 빅엔디안 형태로 저장되므로 아키첵처 엔디안에 따라 변환하여 인식을 하여야 한다. */
#endif

/*
 * Exception handling. 예외 처리. 
 * Something went wrong and we can't proceed. 뭔가 잘못되어 진행할 수 없습니다.
 * We ought to tell the user, but since we don't have any guarantee that we're even running on the right architecture, we do virtually nothing.
 * 우리는 사용자에게 말해야 하지만 우리가 올바른 아키텍처로 운영되고 있다고 보장 할 수 없기 때문에 사실상 아무 것도하지 않습니다.
 *
 * If CONFIG_DEBUG_LL is set we try to print out something about the error and hope for the best (useful if bootloader fails to pass a proper machine ID for example).
 * CONFIG_DEBUG_LL이 설정되면, 우리는 오류에 관해 뭔가를 출력하고 최선을 희망합니다 (예를 들어 부트 로더가 적절한 컴퓨터 ID를 전달하지 못하는 경우 유용합니다).
 */


	__HEAD



/* Determine validity of the r2 atags pointer. r2 atags 포인터의 유효성을 결정합니다. 
 * The heuristic requires that the pointer be aligned, in the first 16k of physical RAM and that the ATAG_CORE marker is first and present.
 * 경험적 방법은 포인터가 물리적 RAM의 처음 16k에 정렬되어야하며 ATAG_CORE 마커가 처음 및 현재 위치에 있어야합니다.
 * If CONFIG_OF_FLATTREE is selected, then it will also accept a dtb pointer.  
 * CONFIG_OF_FLATTREE가 선택되면 dtb 포인터도 받아들입니다.
 * Future revisions of this function may be more lenient with the physical address and may also be able to move the ATAGS block if necessary.
 * 이 기능의 향후 개정은 실제 주소에보다 관대 할 수 있으며 필요한 경우 ATAGS 블록을 이동할 수도 있습니다.
 *
 * Returns:
 *  r2 either valid atags pointer, valid dtb pointer, or zero
 *  r5, r6 corrupted
 */
//k14AB : http://blog.dasomoli.org/318/
//태그 이름  //값       //크기         //설명
// ATAG_CORE 0x54410001 5 (비었다면 2) 리스트의 시작으로 사용하는 첫번째 태그 
// ATAG_NONE 0x00000000 2 리스트의 끝으로 사용하는 빈 태그 
// .
// .
// .
// ATAG_CMDLINE 0x54410009 2 + ((cmdline의 길이 + 3) / 4) 커널로 전달되는 커맨드 라인 
//
__vet_atags:
	tst	r2, #0x3			@ aligned?
	bne	1f				@ 체크1) align 체크하여 align되어 있지 않으면 에러로 점프.

	ldr	r5, [r2, #0]
#ifdef CONFIG_OF_FLATTREE
	ldr	r6, =OF_DT_MAGIC		@ is it a DTB?
	cmp	r5, r6
	beq	2f				@ 체크2) dtb magic number가 검출되면 정상이라 판단하고 리턴.
#endif
	cmp	r5, #ATAG_CORE_SIZE		@ is first tag ATAG_CORE?; 체크3) ATAG_CORE가 처음에 오는지 사이즈 및 ATAG_CORE 태그 코드 매치 확인하여 맞으면 ATAG가 맞다고 판단하고 리턴.
	cmpne	r5, #ATAG_CORE_SIZE_EMPTY	@ ATAG_CORE_SIZE: 5; ATAG_CORE: 0x54410001 
	bne	1f
	ldr	r5, [r2, #4]
	ldr	r6, =ATAG_CORE
	cmp	r5, r6
	bne	1f

2:	ret	lr				@ atag/dtb pointer is ok

1:	mov	r2, #0				@ r2=0을 담고 리턴(에러)
	ret	lr
ENDPROC(__vet_atags)

/*
 * The following fragment of code is executed with the MMU on in MMU mode, and uses absolute addresses; this is not position independent.
 * 다음 코드 단편은 MMU 모드에서 MMU on으로 실행되고 절대 주소를 사용합니다. 이것은 독립적인 위치가 아닙니다.
 *
 *  r0  = cp#15 control register
 *  r1  = machine ID
 *  r2  = atags/dtb pointer
 *  r9  = processor ID
 */
	__INIT
__mmap_switched:
	adr	r3, __mmap_switched_data

	ldmia	r3!, {r4, r5, r6, r7}
	cmp	r4, r5				@ Copy data segment if needed
1:	cmpne	r5, r6
	ldrne	fp, [r4], #4
	strne	fp, [r5], #4
	bne	1b

	mov	fp, #0				@ Clear BSS (and zero fp)
1:	cmp	r6, r7
	strcc	fp, [r6],#4
	bcc	1b

 ARM(	ldmia	r3, {r4, r5, r6, r7, sp})
 THUMB(	ldmia	r3, {r4, r5, r6, r7}	)
 THUMB(	ldr	sp, [r3, #16]		)
	str	r9, [r4]			@ Save processor ID
	str	r1, [r5]			@ Save machine type
	str	r2, [r6]			@ Save atags pointer
	cmp	r7, #0
	strne	r0, [r7]			@ Save control register values
	b	start_kernel
ENDPROC(__mmap_switched)

	.align	2
	.type	__mmap_switched_data, %object
__mmap_switched_data:
	.long	__data_loc			@ r4
	.long	_sdata				@ r5
	.long	__bss_start			@ r6
	.long	_end				@ r7
	.long	processor_id			@ r4
	.long	__machine_arch_type		@ r5
	.long	__atags_pointer			@ r6
#ifdef CONFIG_CPU_CP15
	.long	cr_alignment			@ r7
#else
	.long	0				@ r7
#endif
	.long	init_thread_union + THREAD_START_SP @ sp
	.size	__mmap_switched_data, . - __mmap_switched_data

/*
 * This provides a C-API version of __lookup_processor_type
 */
ENTRY(lookup_processor_type)
	stmfd	sp!, {r4 - r6, r9, lr}
	mov	r9, r0
	bl	__lookup_processor_type
	mov	r0, r5
	ldmfd	sp!, {r4 - r6, r9, pc}
ENDPROC(lookup_processor_type)

	__FINIT					@ 해당 매크로엔 .previous 지시자가 담겨있다. 현재 사용하고 있는 섹션 이전에 사용했던 섹션으로 변경된다.
	.text

/*
 * Read processor ID register (CP#15, CR0), and look up in the linker-built supported processor list.  
 * 프로세서 ID 레지스터 (CP # 15, CR0)를 읽고 링커가 지원하는 프로세서 목록을 조회합니다.
 * Note that we can't use the absolute addresses for the __proc_info lists since we aren't running with the MMU on (and therefore, we are not in the correct address space).  
 * __proc_info 목록에 절대 주소를 사용할 수는 없으므로 MMU를 실행하고 있지 않으므로 (따라서 주소 공간이 올바르지 않습니다.)
 * We have to calculate the offset. 오프셋을 계산해야합니다.
 *
 *	r9 = cpuid
 * Returns:
 *	r3, r4, r6 corrupted
 *	r5 = proc_info pointer in physical address space
 *	r9 = cpuid (preserved)
 */
__lookup_processor_type:

//k14AB : add   r3, pc, #OFFSET
/* K14AB: 2017년 11월 25일 20:52:38
 * ------------------------------
 * @r3 : physical address
 * @r4 : virtual address
 * r4(각 arch cpu value) 랑 r9(cpuid) 비교 하는 loop 
 * 
 */
	adr	r3, __lookup_processor_type_data    @ rpi2: 0x8000_0000 (물리 주소 – 가상 주소)
	ldmia	r3, {r4 - r6}
	sub	r3, r3, r4			@ get offset between virt&phys
	add	r5, r5, r3			@ convert virt addresses to	    @ r5: __proc_info_begin 물리 주소
	add	r6, r6, r3			@ physical address space	    @ r6: __proc_info_end 물리 주소

1:	ldmia	r5, {r3, r4}			@ value, mask			    @ 루프의 시작으로 proc_info_list 구조체의 첫 부분에 있는 cpu value와 cpu mask를 읽어서 r3, r4에 잃어온다.
	and	r4, r4, r9			@ mask wanted bits
	teq	r3, r4
	beq	2f								    @ cpu를 판별하여 일치하면 2f 레이블로 이동하고 리턴한다.

	add	r5, r5, #PROC_INFO_SZ		@ sizeof(proc_info_list)	    @ r5를 구조체 사이즈만큼 증가시킨다. #PROC_INFO_SZ = 52, 구조체 proc_info_list와 동일한 사이즈
//k14AB : (__proc_info_begin + #SZ)(r5) __proc_info_end(r6)

	cmp	r5, r6								    @ r5가 아직 r6보다 작으면 1f 레이블로 이동하여 루프를 돈다.
	blo	1b
	mov	r5, #0				@ unknown processor
2:	ret	lr
ENDPROC(__lookup_processor_type)

/*
 * Look in <asm/procinfo.h> for information about the __proc_info structure.
 */
	.align	2
	.type	__lookup_processor_type_data, %object
__lookup_processor_type_data:
	.long	.                         @ r4
	.long	__proc_info_begin         @ r5
	.long	__proc_info_end           @ r6
	.size	__lookup_processor_type_data, . - __lookup_processor_type_data

__error_lpae:
#ifdef CONFIG_DEBUG_LL
	adr	r0, str_lpae
	bl 	printascii
	b	__error
str_lpae: .asciz "\nError: Kernel with LPAE support, but CPU does not support LPAE.\n"
#else
	b	__error
#endif
	.align
ENDPROC(__error_lpae)

__error_p:
#ifdef CONFIG_DEBUG_LL
	adr	r0, str_p1
	bl	printascii
	mov	r0, r9
	bl	printhex8
	adr	r0, str_p2
	bl	printascii
	b	__error
str_p1:	.asciz	"\nError: unrecognized/unsupported processor variant (0x"
str_p2:	.asciz	").\n"
	.align
#endif
ENDPROC(__error_p)

__error:
#ifdef CONFIG_ARCH_RPC
/*
 * Turn the screen red on a error - RiscPC only.
 */
	mov	r0, #0x02000000
	mov	r3, #0x11
	orr	r3, r3, r3, lsl #8
	orr	r3, r3, r3, lsl #16
	str	r3, [r0], #4
	str	r3, [r0], #4
	str	r3, [r0], #4
	str	r3, [r0], #4
#endif
1:	mov	r0, r0
	b	1b
ENDPROC(__error)
