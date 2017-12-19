/*
 *  linux/arch/arm/kernel/head.S
 *
 *  Copyright (C) 1994-2002 Russell King
 *  Copyright (c) 2003 ARM Limited
 *  All Rights Reserved
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 *  Kernel startup code for all 32-bit CPUs
 */
#include <linux/linkage.h>
#include <linux/init.h>

#include <asm/assembler.h>
#include <asm/cp15.h>
#include <asm/domain.h>
#include <asm/ptrace.h>
#include <asm/asm-offsets.h>
#include <asm/memory.h>
#include <asm/thread_info.h>
#include <asm/pgtable.h>

#if defined(CONFIG_DEBUG_LL) && !defined(CONFIG_DEBUG_SEMIHOSTING)
#include CONFIG_DEBUG_LL_INCLUDE
#endif

/*
 * swapper_pg_dir is the virtual address of the initial page table.
 * swapper_pg_dir은 초기 페이지 테이블의 가상 주소입니다.
 * We place the page tables 16K below KERNEL_RAM_VADDR.  
 * 우리는 KERNEL_RAM_VADDR 아래에 페이지 테이블 16K를 놓습니다.
 * Therefore, we must make sure that KERNEL_RAM_VADDR is correctly set.  
 * 따라서 KERNEL_RAM_VADDR이 올바르게 설정되었는지 확인해야합니다.
 * Currently, we expect the least significant 16 bits to be 0x8000, but we could probably relax this restriction to KERNEL_RAM_VADDR >= PAGE_OFFSET + 0x4000.
 * 현재 우리는 16 비트 최하위 비트가 0x8000이라고 예상하지만 이 제한을 KERNEL_RAM_VADDR> = PAGE_OFFSET + 0x4000으로 완화 할 수 있습니다.
 */
//k14AB : ./arch/arm/Makefile:   TEXT_OFFSET := $(textofs-y)
//        ./arch/arm/Makefile:   textofs-y  := 0x00008000
//k14AB : PAGE_OFFSET = 0x80000000, TEXT_OFFSET = 0x8000
#define KERNEL_RAM_VADDR			    @ (PAGE_OFFSET + TEXT_OFFSET) //커널이 위치할 RAM 가상 주소는 PAGE_OFFSET + TEXT_OFFSET을 더한 값이다.
#if (KERNEL_RAM_VADDR & 0xffff) != 0x8000	    @ 이 주소 값의 뒤 16비트가 0x8000이 아닌경우 즉, 32K align이 안되어 있는 경우 컴파일 시 경고를 만들어낸다.
#error KERNEL_RAM_VADDR must start at 0xXXXX8000    @ rpi2: (0x8000_0000 + 0x0000_0800)
#endif

#ifdef CONFIG_ARM_LPAE
	/* LPAE requires an additional page for the PGD */
	/* 리눅스는 32비트 및 64비트 등 모든 아키텍처를 지원하기 위해 최대 4레벨 변환을 사용
	 * 64비트 리눅스 커널을 대비하기 위하여 4단계의 테이블로 관리할 수 있게 확장하였다.
	 * (pgd → pud → pmd → pte 순서)
	 */
#define PG_DIR_SIZE	0x5000			    
#define PMD_ORDER	3
#else
#define PG_DIR_SIZE	0x4000			    @ 커널 설정용 1차 페이지 디렉토리의 사이즈
#define PMD_ORDER	2			    @ 페이지 변환 단계로 ARM 32비트 아키텍처는 LPAE를 사용하면 3단계 변환을 사용하고 그렇지 않으면 2단계 변환을 사용한다.
						    @ rpi2: LPAE 옵션을 사용하지 않았으므로 페이지 변환에 2단계 변환 사용
#endif

//k14AB : KERNEL_RAM_VADDR = 0x80008000, PG_DIR_SIZE = 0x4000
//        swapper_pg_dir = 0x80004000
	.globl	swapper_pg_dir
	.equ	swapper_pg_dir, KERNEL_RAM_VADDR - PG_DIR_SIZE	@ 커널이 시작되는 가상 주소값에서 페이지 디렉토리(pgd) 사이즈를 뺀 값, rpi2: 0x8000_4000

//k14AB : TEXT_OFFSET = 0x8000, PG_DIR_SIZE 0x4000
	.macro	pgtbl, rd, phys			    @ 물리메모리 주소로 페이지테이블의 위치를 계산. r8=0x0000_0000
	add	\rd, \phys, #TEXT_OFFSET	    @ add r4, r8, #0x8000
	sub	\rd, \rd, #PG_DIR_SIZE		    @ sub r4, r4, #0x4000
	.endm					    @ r4에 결과는 0x0000_4000

/*
 * Kernel startup entry point.
 * ---------------------------
 *
 * This is normally called from the decompressor code.  
 * 이것은 일반적으로 압축 풀기 프로그램 코드에서 호출됩니다.
 * The requirements are: MMU = off, D-cache = off, I-cache = dont care, r0 = 0, r1 = machine nr, r2 = atags or dtb pointer.
 * 요구 사항은 MMU = 꺼짐, D- 캐시 = 꺼짐, I- 캐시 = 걱정하지 않음, r0 = 0, r1 = 컴퓨터 nr, r2 = atags 또는 dtb 포인터입니다.
 *
 * This code is mostly position independent, so if you link the kernel at 0xc0008000, you call this at __pa(0xc0008000).
 * 이 코드는 대부분 위치 독립적이므로 0xc0008000에서 커널을 링크하면 __pa (0xc0008000)에서 호출됩니다.
 *
 * See linux/arch/arm/tools/mach-types for the complete list of machine numbers for r1.
 * r1의 전체 시스템 목록은 linux / arch / arm / tools / mach-types을 참조하십시오.
 *
 * We're trying to keep crap to a minimum; 
 * 우리는 최소한으로 오류를 유지하려고 노력하고 있습니다.
 * DO NOT add any machine specific crap here - that's what the boot loader (or in extreme, well justified circumstances, zImage) is for.
 */
	.arm

	__HEAD					@ 코드가 아래 섹션에 들어가도록 컴파일러에게 지시한다.
						/* ENTRY(stext)는 다음과 같은 코드를 만들어낸다.
						 * .globl stext ;
						 * .align 0 ;
						 * stext:
						 */
ENTRY(stext)					@ #define __HEAD          .section        “.head.text”,”ax”
						/* ARM_BE8(): ARM 아키텍처가 빅엔디안이 지원되는 경우  CONFIG_CPU_ENDIAN_BE8 커널 설정 옵션을 사용하여 빌드하는 경우 
						 * ARM_BE8() 매크로에 들어가는 명령을 실행 시킬 수 있다. 
						 * setend be: 빅엔디안으로 CPU가 동작. (cpsr BE 비트를 1로 설정)
						 * rpi2: 리틀엔디안(ARM_BE8 매크로 동작하지 않음)으로 동작
						 */
 ARM_BE8(setend	be )				@ ensure we are in BE8 mode

 THUMB(	badr	r9, 1f		)		@ Kernel is always entered in ARM.
 THUMB(	bx	r9		)		@ If this is a Thumb-2 kernel,
 THUMB(	.thumb			)		@ switch to Thumb now.
 THUMB(1:			)

#ifdef CONFIG_ARM_VIRT_EXT
	bl	__hyp_stub_install		@ 하이퍼 바이저용 stub 설치
#endif
	@ ensure svc mode and all interrupts masked
	safe_svcmode_maskall r9			@ CPU 모드가 svc 모드가 아닌경우 svc 모드로 진입한다. 모든 인터럽트가 작동하지 않도록 마스크를 설정한다.

//k14AB : http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.ddi0360f/CHDGIJFB.html
	mrc	p15, 0, r9, c0, c0		@ get processor id; MIDR로 cpu id를 읽어온다.
	bl	__lookup_processor_type		@ r5=procinfo r9=cpuid; r9에 cpu id를 갖고 함수를 다녀오면 r5에 검색하여 찾은 프로세서의 proc_info_list 구조체 주소를 담아온다.
						@ rpi2: r9 = __v7_ca7mp_setup: 레이블을 가리키는 주소
	movs	r10, r5				@ invalid processor (r5=0)?; r5 구조체 주소가 0이면 에러를 출력하는 루틴으로 이동한다.

 THUMB( it	eq )				@ force fixup-able long branch encoding
	beq	__error_p			@ yes, error 'p'

#ifdef CONFIG_ARM_LPAE
	mrc	p15, 0, r3, c0, c1, 4		@ read ID_MMFR0; ID_MMFR0.vmsa를 읽어와서 그 값이 5보다 작으면 long-descriptor translation table을 지원하지 않으므로 
						@ __error_lpae 루틴으로 이동하여 에러를 출력한다.
	and	r3, r3, #0xf			@ extract VMSA support
						/* 0b0101 As for 0b0100, and adds support for the Long-descriptor translation table format. -> rpi2: 0x5
						 */
	cmp	r3, #5				@ long-descriptor translation table format?
 THUMB( it	lo )				@ force fixup-able long branch encoding
	blo	__error_lpae			@ only classic page table format
#endif

#ifndef CONFIG_XIP_KERNEL			@ XIP 커널이 아닌 경우
	adr	r3, 2f				@ r3 = 레이블 2f가 가리키는 물리 주소
	ldmia	r3, {r4, r8}			@ r4 = 레이블 2f가 가리키는 주소의 값: . (빌드 시 만들어진 2f 레이블의 가상주소 값); rpi2: PAGE_OFFSET=0x8000_xxxx
						@ r8 = 레이블 2f+4가 가리키는 주소의 값 = PAGE_OFFSET; rpi2: PAGE_OFFSET=0x8000_0000
	sub	r4, r3, r4			@ (PHYS_OFFSET - PAGE_OFFSET); r4 = offset (실행 시 2f 레이블의 물리 주소 – 컴파일 시 만들어진 2f레이블의  가상 주소)
						@ rpi2: r4 = 0x8000_0000 = (0x0000_xxxx – 0x8000_xxxx)
	add	r8, r8, r4			@ PHYS_OFFSET; r8 = PAGE_OFFSET + offset = 물리 시작 주소; rpi2: 0x0000_0000
#else						
						/* XPI 커널인 경우
						 * ldr r9, =PLAT_PHYS_OFFSET, XIP 커널에서는 코드가 ROM(or Nor flash)에서 동작하므로,
						 * adr 방식으로 물리램 주소를 알아올 수 없어서 직접 PLAT_PHYS_OFFSET에 값을 읽어와서 대입한다.
						 */
	ldr	r8, =PLAT_PHYS_OFFSET		@ always constant in this case
#endif

	/*
	 * r1 = machine no, r2 = atags or dtb,
	 * r8 = phys_offset, r9 = cpuid, r10 = procinfo
	 */
	bl	__vet_atags			@ atag또는 dtb가 유효한지 확인한다. 유효하지 않으면 r2=0

#ifdef CONFIG_SMP_ON_UP				@ SMP 커널이 UP(Uni core)에서 동작할 수 있도록 지원하는 설정이다.
	bl	__fixup_smp			@ SMP(Multi core)코드가 UP(Uni core)에서 동작시 해당 코드를 치환(fixup)해주는 루틴
#endif
#ifdef CONFIG_ARM_PATCH_PHYS_VIRT		@ 물리주소를 가상 주소로 변환해주는 함수를 런타임 시 패치할 수 있도록 지원하는 설정이다.
	bl	__fixup_pv_table		@ 커널 빌드 시 설정된 물리메모리의 시작위치가 실제 커널 구동 시 물리메모리의 시작위치가 서로 다를 수 있기 때문에 
						@ pv_offset를 다시 갱신하고 가상메모리와 물리메모리의 주소 변환 함수를 사용하는 코드를 patch하기 위해 필요한 루틴이다.
						@ 디바이스트리 등의 사용으로 빌드된 커널을 재사용하고 메모리 주소 위치만 달라진 시스템에서 구동하기 위해 사용된다.
#endif
	bl	__create_page_tables

	/*
	 * The following calls CPU specific code in a position independent manner.  
	 * 다음은 위치 독립적인 방식으로 CPU 특정 코드를 호출합니다.
	 * See arch/arm/mm/proc-*.S for details.  
	 * r10 = base of xxx_proc_info structure selected by __lookup_processor_type above.
	 *
	 * The processor init function will be called with:
	 *  r1 - machine type
	 *  r2 - boot data (atags/dt) pointer
	 *  r4 - translation table base (low word)
	 *  r5 - translation table base (high word, if LPAE)
	 *  r8 - translation table base 1 (pfn if LPAE)
	 *  r9 - cpuid
	 *  r13 - virtual address for __enable_mmu -> __turn_mmu_on
	 *
	 * On return, the CPU will be ready for the MMU to be turned on,
	 * r0 will hold the CPU control register value, r1, r2, r4, and
	 * r9 will be preserved.  r5 will also be preserved if LPAE.
	 */
	ldr	r13, =__mmap_switched		@ address to jump to after; mmu가 켜진 후 실행될 __mmap_switched 레이블의 가상 주소를 미리 r13에 담아둔다.
						@ mmu has been enabled
	badr	lr, 1f				@ return (PIC) address
#ifdef CONFIG_ARM_LPAE
	mov	r5, #0				@ high TTBR0
	mov	r8, r4, lsr #12			@ TTBR1 is swapper_pg_dir pfn
#else
	mov	r8, r4				@ set TTBR1 to swapper_pg_dir
#endif
	ldr	r12, [r10, #PROCINFO_INITFUNC]	@ PROCINFO_INITFUNC= 16 (16번째 바이트를 가리킨다)
	add	r12, r12, r10			@ rpi2: r10 = __v7_ca7mp_proc_info, r10+16 = __v7_ca7mp_setup
						@ 위와 같이 알 수 없는 주소(변동되는 함수 포인터) 또는 멀리 있는 곳의 주소로 이동을 하려할 때에는 
						@ ARM 명령의 제약으로 인해 b 또는 bl 명령을 사용할 수 없다. 
						@ 이러한 경우 직접 pc 레지스터를 조작하는 방법으로 이동(b)할 수 있고 서브루틴 콜 형식(bl)으로 사용할 때에는 
						@ 미리 lr 레지스터에 복귀를 원하는 주소를 넣어줘야 한다.
						@ __v7_ca7mp_setup; ARMv7의 TLB, 캐시를 초기화하고 MMU를 on 한다.
	ret	r12
1:	b	__enable_mmu			@ MMU를 가동하기전에 임시로 1차 페이지 테이블을 만들어 사용한다.
						@ MMU가 켜진 후부터 페이지 변환이 이루어져 커널을 빌드 시 사용했었던 가상 주소를 사용하는데 
						@ 이 루틴이 종료될 때 __mmap_switched 루틴으로 복귀한다.
ENDPROC(stext)
	.ltorg
#ifndef CONFIG_XIP_KERNEL
2:	.long	.
	.long	PAGE_OFFSET       @ 0x80000000
#endif

/*
 * Setup the initial page tables. 초기 페이지 테이블을 설정하십시오. 
 * We only setup the barest amount which are required to get the kernel running, which generally means mapping in the kernel code.
 * 우리는 커널을 실행 시키는데 필요한 barest 양만 설정합니다. 이것은 일반적으로 커널 코드에서의 매핑을 의미합니다.
 *
 * r8 = phys_offset, r9 = cpuid, r10 = procinfo
 *
 * Returns:
 *  r0, r3, r5-r7 corrupted
 *  r4 = physical page table address
 */
__create_page_tables:
//k14AB :  r4 = PAGE_OFFSET(r8) + TEXT_OFFSET - PG_DIR_SIZE
//eg) 0x80004000 = 0x80000000      + 0x8000      - 0x4000     
	pgtbl	r4, r8				@ page table address

	/*
	 * Clear the swapper page table
	 */
	mov	r0, r4
	mov	r3, #0
	add	r6, r0, #PG_DIR_SIZE
1:	str	r3, [r0], #4
	str	r3, [r0], #4
	str	r3, [r0], #4
	str	r3, [r0], #4
	teq	r0, r6
	bne	1b

#ifdef CONFIG_ARM_LPAE
	/*
	 * Build the PGD table (first level) to point to the PMD table. A PGD
	 * entry is 64-bit wide.
	 */
	mov	r0, r4
	add	r3, r4, #0x1000			@ first PMD table address
	orr	r3, r3, #3			@ PGD block type
	mov	r6, #4				@ PTRS_PER_PGD
	mov	r7, #1 << (55 - 32)		@ L_PGD_SWAPPER
1:
#ifdef CONFIG_CPU_ENDIAN_BE8
	str	r7, [r0], #4			@ set top PGD entry bits
	str	r3, [r0], #4			@ set bottom PGD entry bits
#else
	str	r3, [r0], #4			@ set bottom PGD entry bits
	str	r7, [r0], #4			@ set top PGD entry bits
#endif
	add	r3, r3, #0x1000			@ next PMD table
	subs	r6, r6, #1
	bne	1b

	add	r4, r4, #0x1000			@ point to the PMD tables
#ifdef CONFIG_CPU_ENDIAN_BE8
	add	r4, r4, #4			@ we only write the bottom word
#endif
#endif

//k14AB : r8 = phys_offset, r9 = cpuid, r10 = procinfo
//        r7 = ALT_SMP(.long   PMD_TYPE_SECT | PMD_SECT_AP_WRITE | PMD_SECT_AP_READ | \
//                             PMD_SECT_AF | PMD_FLAGS_SMP | \mm_mmuflags)
//        r7 = 0000 0000 0000 0001 0001 1100 0000 1110

	ldr	r7, [r10, #PROCINFO_MM_MMUFLAGS] @ mm_mmuflags

	/*
	 * Create identity mapping to cater for __enable_mmu.
	 * This identity mapping will be removed by paging_init().
	 */
	adr	r0, __turn_mmu_on_loc
	ldmia	r0, {r3, r5, r6}
	sub	r0, r0, r3			@ virt->phys offset
	add	r5, r5, r0			@ phys __turn_mmu_on
	add	r6, r6, r0			@ phys __turn_mmu_on_end
	mov	r5, r5, lsr #SECTION_SHIFT
	mov	r6, r6, lsr #SECTION_SHIFT

//k14AB :  r4 = PAGE_OFFSET(r8) + TEXT_OFFSET - PG_DIR_SIZE
//eg) 0x80004000 = 0x80000000      + 0x8000      - 0x4000     

1:	orr	r3, r7, r5, lsl #SECTION_SHIFT	@ flags + kernel base
	str	r3, [r4, r5, lsl #PMD_ORDER]	@ identity mapping
	cmp	r5, r6
	addlo	r5, r5, #1			@ next section
	blo	1b

	/*
	 * Map our RAM from the start to the end of the kernel .bss section.
	 */

//k14AB : r8 = phys_offset eg) 0x80000000, r7 = mm_mmuflags
//k14AB : r4 = 페이지 변환테이블 시작주소
//           = PAGE_OFFSET(r8)0x80000000 + TEXT_OFFSET - PG_DIR_SIZE

	add	r0, r4, #PAGE_OFFSET >> (SECTION_SHIFT - PMD_ORDER)
	ldr	r6, =(_end - 1)
	orr	r3, r8, r7
	add	r6, r4, r6, lsr #(SECTION_SHIFT - PMD_ORDER)
1:	str	r3, [r0], #1 << PMD_ORDER
	add	r3, r3, #1 << SECTION_SHIFT
	cmp	r0, r6
	bls	1b

#ifdef CONFIG_XIP_KERNEL
	/*
	 * Map the kernel image separately as it is not located in RAM.
	 */
#define XIP_START XIP_VIRT_ADDR(CONFIG_XIP_PHYS_ADDR)
	mov	r3, pc
	mov	r3, r3, lsr #SECTION_SHIFT
	orr	r3, r7, r3, lsl #SECTION_SHIFT
	add	r0, r4,  #(XIP_START & 0xff000000) >> (SECTION_SHIFT - PMD_ORDER)
	str	r3, [r0, #((XIP_START & 0x00f00000) >> SECTION_SHIFT) << PMD_ORDER]!
	ldr	r6, =(_edata_loc - 1)
	add	r0, r0, #1 << PMD_ORDER
	add	r6, r4, r6, lsr #(SECTION_SHIFT - PMD_ORDER)
1:	cmp	r0, r6
	add	r3, r3, #1 << SECTION_SHIFT
	strls	r3, [r0], #1 << PMD_ORDER
	bls	1b
#endif

	/*
	 * Then map boot params address in r2 if specified.
	 * We map 2 sections in case the ATAGs/DTB crosses a section boundary.
	 */
//k14AB : r8 = phys_offset eg) 0x80000000, r7 = mm_mmuflags
//k14AB : r4 = 페이지 변환테이블 시작주소
//           = PAGE_OFFSET(r8) + TEXT_OFFSET - PG_DIR_SIZE
	mov	r0, r2, lsr #SECTION_SHIFT
	movs	r0, r0, lsl #SECTION_SHIFT
	subne	r3, r0, r8
	addne	r3, r3, #PAGE_OFFSET
	addne	r3, r4, r3, lsr #(SECTION_SHIFT - PMD_ORDER)
	orrne	r6, r7, r0
	strne	r6, [r3], #1 << PMD_ORDER
	addne	r6, r6, #1 << SECTION_SHIFT
	strne	r6, [r3]

#if defined(CONFIG_ARM_LPAE) && defined(CONFIG_CPU_ENDIAN_BE8)
	sub	r4, r4, #4			@ Fixup page table pointer
						@ for 64-bit descriptors
#endif

#ifdef CONFIG_DEBUG_LL
#if !defined(CONFIG_DEBUG_ICEDCC) && !defined(CONFIG_DEBUG_SEMIHOSTING)
	/*
	 * Map in IO space for serial debugging.
	 * This allows debug messages to be output
	 * via a serial console before paging_init.
	 */
	addruart r7, r3, r0

	mov	r3, r3, lsr #SECTION_SHIFT
	mov	r3, r3, lsl #PMD_ORDER

	add	r0, r4, r3
	mov	r3, r7, lsr #SECTION_SHIFT
	ldr	r7, [r10, #PROCINFO_IO_MMUFLAGS] @ io_mmuflags
	orr	r3, r7, r3, lsl #SECTION_SHIFT
#ifdef CONFIG_ARM_LPAE
	mov	r7, #1 << (54 - 32)		@ XN
#ifdef CONFIG_CPU_ENDIAN_BE8
	str	r7, [r0], #4
	str	r3, [r0], #4
#else
	str	r3, [r0], #4
	str	r7, [r0], #4
#endif
#else
	orr	r3, r3, #PMD_SECT_XN
	str	r3, [r0], #4
#endif

#else /* CONFIG_DEBUG_ICEDCC || CONFIG_DEBUG_SEMIHOSTING */
	/* we don't need any serial debugging mappings */
	ldr	r7, [r10, #PROCINFO_IO_MMUFLAGS] @ io_mmuflags
#endif

#if defined(CONFIG_ARCH_NETWINDER) || defined(CONFIG_ARCH_CATS)
	/*
	 * If we're using the NetWinder or CATS, we also need to map
	 * in the 16550-type serial port for the debug messages
	 */
	add	r0, r4, #0xff000000 >> (SECTION_SHIFT - PMD_ORDER)
	orr	r3, r7, #0x7c000000
	str	r3, [r0]
#endif
#ifdef CONFIG_ARCH_RPC
	/*
	 * Map in screen at 0x02000000 & SCREEN2_BASE
	 * Similar reasons here - for debug.  This is
	 * only for Acorn RiscPC architectures.
	 */
	add	r0, r4, #0x02000000 >> (SECTION_SHIFT - PMD_ORDER)
	orr	r3, r7, #0x02000000
	str	r3, [r0]
	add	r0, r4, #0xd8000000 >> (SECTION_SHIFT - PMD_ORDER)
	str	r3, [r0]
#endif
#endif
#ifdef CONFIG_ARM_LPAE
	sub	r4, r4, #0x1000		@ point to the PGD table
#endif
	ret	lr
ENDPROC(__create_page_tables)
	.ltorg
	.align
__turn_mmu_on_loc:
	.long	.                       @ r3
	.long	__turn_mmu_on           @ r5
	.long	__turn_mmu_on_end       @ r6

#if defined(CONFIG_SMP)
	.text
	.arm
ENTRY(secondary_startup_arm)
 THUMB(	badr	r9, 1f		)	@ Kernel is entered in ARM.
 THUMB(	bx	r9		)	@ If this is a Thumb-2 kernel,
 THUMB(	.thumb			)	@ switch to Thumb now.
 THUMB(1:			)
ENTRY(secondary_startup)
	/*
	 * Common entry point for secondary CPUs.
	 *
	 * Ensure that we're in SVC mode, and IRQs are disabled.  Lookup
	 * the processor type - there is no need to check the machine type
	 * as it has already been validated by the primary processor.
	 */

 ARM_BE8(setend	be)				@ ensure we are in BE8 mode

#ifdef CONFIG_ARM_VIRT_EXT
	bl	__hyp_stub_install_secondary
#endif
	safe_svcmode_maskall r9

	mrc	p15, 0, r9, c0, c0		@ get processor id
	bl	__lookup_processor_type
	movs	r10, r5				@ invalid processor?
	moveq	r0, #'p'			@ yes, error 'p'
 THUMB( it	eq )		@ force fixup-able long branch encoding
	beq	__error_p

	/*
	 * Use the page tables supplied from  __cpu_up.
	 */
	adr	r4, __secondary_data
	ldmia	r4, {r5, r7, r12}		@ address to jump to after
	sub	lr, r4, r5			@ mmu has been enabled
	add	r3, r7, lr
	ldrd	r4, [r3, #0]			@ get secondary_data.pgdir
ARM_BE8(eor	r4, r4, r5)			@ Swap r5 and r4 in BE:
ARM_BE8(eor	r5, r4, r5)			@ it can be done in 3 steps
ARM_BE8(eor	r4, r4, r5)			@ without using a temp reg.
	ldr	r8, [r3, #8]			@ get secondary_data.swapper_pg_dir
	badr	lr, __enable_mmu		@ return address
	mov	r13, r12			@ __secondary_switched address
	ldr	r12, [r10, #PROCINFO_INITFUNC]
	add	r12, r12, r10			@ initialise processor
						@ (return control reg)
	ret	r12
ENDPROC(secondary_startup)
ENDPROC(secondary_startup_arm)

	/*
	 * r6  = &secondary_data
	 */
ENTRY(__secondary_switched)
	ldr	sp, [r7, #12]			@ get secondary_data.stack
	mov	fp, #0
	b	secondary_start_kernel
ENDPROC(__secondary_switched)

	.align

	.type	__secondary_data, %object
__secondary_data:
	.long	.
	.long	secondary_data
	.long	__secondary_switched
#endif /* defined(CONFIG_SMP) */



/*
 * Setup common bits before finally enabling the MMU.  
 * 마지막으로 MMU를 활성화하기 전에 공통 비트를 설정하십시오.
 * Essentially this is just loading the page table pointer and domain access registers. 
 * 본질적으로 이는 페이지 테이블 포인터와 도메인 액세스 레지스터를 로드하는 것입니다.
 * All these registers need to be preserved by the processor setup function (or set in the case of r0)
 * 이 모든 레지스터는 프로세서 설정 기능 (또는 r0의 경우 설정)에 의해 보존되어야합니다.
 *
 *  r0  = cp#15 control register
 *  r1  = machine ID
 *  r2  = atags or dtb pointer
 *  r4  = TTBR pointer (low word)
 *  r5  = TTBR pointer (high word if LPAE)
 *  r9  = processor ID
 *  r13 = *virtual* address to jump to upon completion
 */
__enable_mmu:
#if defined(CONFIG_ALIGNMENT_TRAP) && __LINUX_ARM_ARCH__ < 6
	orr	r0, r0, #CR_A
#else
	bic	r0, r0, #CR_A
#endif
#ifdef CONFIG_CPU_DCACHE_DISABLE
	bic	r0, r0, #CR_C
#endif
#ifdef CONFIG_CPU_BPREDICT_DISABLE
	bic	r0, r0, #CR_Z
#endif
#ifdef CONFIG_CPU_ICACHE_DISABLE
	bic	r0, r0, #CR_I
#endif
#ifdef CONFIG_ARM_LPAE
	mcrr	p15, 0, r4, r5, c2		@ load TTBR0
#else

//k14AB : http://jake.dothome.co.kr/pte/
//
	mov	r5, #DACR_INIT
	mcr	p15, 0, r5, c3, c0, 0		@ load domain access register
	mcr	p15, 0, r4, c2, c0, 0		@ load page table pointer
#endif
	b	__turn_mmu_on
ENDPROC(__enable_mmu)

/*
 * Enable the MMU.  This completely changes the structure of the visible
 * memory space.  You will not be able to trace execution through this.
 * If you have an enquiry about this, *please* check the linux-arm-kernel
 * mailing list archives BEFORE sending another post to the list.
 *
 *  r0  = cp#15 control register
 *  r1  = machine ID
 *  r2  = atags or dtb pointer
 *  r9  = processor ID
 *  r13 = *virtual* address to jump to upon completion
 *
 * other registers depend on the function called upon completion
 */
	.align	5
	.pushsection	.idmap.text, "ax"
ENTRY(__turn_mmu_on)
	mov	r0, r0
	instr_sync
	mcr	p15, 0, r0, c1, c0, 0		@ write control reg
	mrc	p15, 0, r3, c0, c0, 0		@ read id reg
	instr_sync
	mov	r3, r3
	mov	r3, r13
	ret	r3
__turn_mmu_on_end:
ENDPROC(__turn_mmu_on)
	.popsection


#ifdef CONFIG_SMP_ON_UP
	__HEAD
__fixup_smp:
	and	r3, r9, #0x000f0000	@ architecture version
	teq	r3, #0x000f0000		@ CPU ID supported?
	bne	__fixup_smp_on_up	@ no, assume UP

	bic	r3, r9, #0x00ff0000
	bic	r3, r3, #0x0000000f	@ mask 0xff00fff0
	mov	r4, #0x41000000
	orr	r4, r4, #0x0000b000
	orr	r4, r4, #0x00000020	@ val 0x4100b020
	teq	r3, r4			@ ARM 11MPCore?
	reteq	lr			@ yes, assume SMP

	mrc	p15, 0, r0, c0, c0, 5	@ read MPIDR
	and	r0, r0, #0xc0000000	@ multiprocessing extensions and
	teq	r0, #0x80000000		@ not part of a uniprocessor system?
	bne    __fixup_smp_on_up	@ no, assume UP

	@ Core indicates it is SMP. Check for Aegis SOC where a single
	@ Cortex-A9 CPU is present but SMP operations fault.
	mov	r4, #0x41000000
	orr	r4, r4, #0x0000c000
	orr	r4, r4, #0x00000090
	teq	r3, r4			@ Check for ARM Cortex-A9
	retne	lr			@ Not ARM Cortex-A9,

	@ If a future SoC *does* use 0x0 as the PERIPH_BASE, then the
	@ below address check will need to be #ifdef'd or equivalent
	@ for the Aegis platform.
	mrc	p15, 4, r0, c15, c0	@ get SCU base address
	teq	r0, #0x0		@ '0' on actual UP A9 hardware
	beq	__fixup_smp_on_up	@ So its an A9 UP
	ldr	r0, [r0, #4]		@ read SCU Config
ARM_BE8(rev	r0, r0)			@ byteswap if big endian
	and	r0, r0, #0x3		@ number of CPUs
	teq	r0, #0x0		@ is 1?
	retne	lr

__fixup_smp_on_up:
	adr	r0, 1f
	ldmia	r0, {r3 - r5}
	sub	r3, r0, r3
	add	r4, r4, r3
	add	r5, r5, r3
	b	__do_fixup_smp_on_up
ENDPROC(__fixup_smp)

//k14AB : arch/arm/include/asm/assembler.h
//        section .alt.smp.init
//
	.align
1:	.word	.                        @ r3
	.word	__smpalt_begin           @ r4
	.word	__smpalt_end             @ r5

	.pushsection .data
	.globl	smp_on_up
smp_on_up:
	ALT_SMP(.long	1)
	ALT_UP(.long	0)
	.popsection
#endif

	.text
__do_fixup_smp_on_up:
	cmp	r4, r5
	reths	lr
	ldmia	r4!, {r0, r6}
//k14AB : arch/arm/include/asm/assembler.h
//ex)     r0 = .long 9998b = ALT_SMP(.long 1) 의 주소,
//        r6 = ALT_UP(.long 0),
//        r3 = virtTOphys(delta)
//        ALT_SMP(sssss) 에 ALT_UP(uuuu)를 저장
 ARM(	str	r6, [r0, r3]	)
 THUMB(	add	r0, r0, r3	)
#ifdef __ARMEB__
 THUMB(	mov	r6, r6, ror #16	)	@ Convert word order for big-endian.
#endif
 THUMB(	strh	r6, [r0], #2	)	@ For Thumb-2, store as two halfwords
 THUMB(	mov	r6, r6, lsr #16	)	@ to be robust against misaligned r3.
 THUMB(	strh	r6, [r0]	)
	b	__do_fixup_smp_on_up
ENDPROC(__do_fixup_smp_on_up)

ENTRY(fixup_smp)
	stmfd	sp!, {r4 - r6, lr}
	mov	r4, r0
	add	r5, r0, r1
	mov	r3, #0
	bl	__do_fixup_smp_on_up
	ldmfd	sp!, {r4 - r6, pc}
ENDPROC(fixup_smp)

#ifdef __ARMEB__
#define LOW_OFFSET	0x4
#define HIGH_OFFSET	0x0
#else
#define LOW_OFFSET	0x0
#define HIGH_OFFSET	0x4
#endif

#ifdef CONFIG_ARM_PATCH_PHYS_VIRT

/* __fixup_pv_table - patch the stub instructions with the delta between
 * PHYS_OFFSET and PAGE_OFFSET, which is assumed to be 16MiB aligned and
 * can be expressed by an immediate shifter operand. The stub instruction
 * has a form of '(add|sub) rd, rn, #imm'.
 */
	__HEAD
__fixup_pv_table:
	adr	r0, 1f
	ldmia	r0, {r3-r7}
	mvn	ip, #0
	subs	r3, r0, r3	@ PHYS_OFFSET - PAGE_OFFSET
	add	r4, r4, r3	@ adjust table start address
	add	r5, r5, r3	@ adjust table end address
	add	r6, r6, r3	@ adjust __pv_phys_pfn_offset address
	add	r7, r7, r3	@ adjust __pv_offset address
//k14AB : r0 = (PAGE_OFFSET(0x80000000) - delta)(r8) >> 12(PAGE_SHIFT)
	mov	r0, r8, lsr #PAGE_SHIFT	@ convert to PFN
	str	r0, [r6]	@ save computed PHYS_OFFSET to __pv_phys_pfn_offset
	strcc	ip, [r7, #HIGH_OFFSET]	@ save to __pv_offset high bits
//k14AB : 0h xx00 0000 => 0h 0000 00xx  == r6
//        kernel/head.S는 compressed/head.S 에서 128M align 맞췄음
	mov	r6, r3, lsr #24	@ constant for add/sub instructions
	teq	r3, r6, lsl #24 @ must be 16MiB aligned
THUMB(	it	ne		@ cross section branch )
	bne	__error
//k14AB : r3 = 1f의 주소 - . = delta 값
	str	r3, [r7, #LOW_OFFSET]	@ save to __pv_offset low bits
	b	__fixup_a_pv_table
ENDPROC(__fixup_pv_table)

//k14AB : arch/arm/include/asm/memory.h
//
	.align
1:	.long	.                    @ r3
	.long	__pv_table_begin     @ r4
	.long	__pv_table_end       @ r5
2:	.long	__pv_phys_pfn_offset @ r6
	.long	__pv_offset          @ r7

	.text
__fixup_a_pv_table:
/*k14AB :
3:	.quad	__pv_offset 위치에 delta 값
 ====>  .long   __pv_offset + 0 (low)      : delta
        .long   __pv_offset + 4 (high)     : 0, (-1)0xffffffff
 */
	adr	r0, 3f
	ldr	r6, [r0]
	add	r6, r6, r3
//k14AB : delta 값이 "-"인경우 0xffff ffff, 아니면 0 
	ldr	r0, [r6, #HIGH_OFFSET]	@ pv_offset high word
	ldr	r6, [r6, #LOW_OFFSET]	@ pv_offset low word
//k14AB : r6 = delta >> 24 => 0xHH000000 -> 0x000000HH
	mov	r6, r6, lsr #24
//k14AB : delta 값이 "-"인경우 0xffff ffff + 1 = 0
	cmn	r0, #1
#ifdef CONFIG_THUMB2_KERNEL
	moveq	r0, #0x200000	@ set bit 21, mov to mvn instruction
	lsls	r6, #24
	beq	2f
	clz	r7, r6
	lsr	r6, #24
	lsl	r6, r7
	bic	r6, #0x0080
	lsrs	r7, #1
	orrcs	r6, #0x0080
	orr	r6, r6, r7, lsl #12
	orr	r6, #0x4000
	b	2f
1:	add     r7, r3
	ldrh	ip, [r7, #2]
ARM_BE8(rev16	ip, ip)
	tst	ip, #0x4000
	and	ip, #0x8f00
	orrne	ip, r6	@ mask in offset bits 31-24
	orreq	ip, r0	@ mask in offset bits 7-0
ARM_BE8(rev16	ip, ip)
	strh	ip, [r7, #2]
	bne	2f
	ldrh	ip, [r7]
ARM_BE8(rev16	ip, ip)
	bic	ip, #0x20
	orr	ip, ip, r0, lsr #16
ARM_BE8(rev16	ip, ip)
	strh	ip, [r7]
2:	cmp	r4, r5
	ldrcc	r7, [r4], #4	@ use branch for delay slot
	bcc	1b
	bx	lr
#else
#ifdef CONFIG_CPU_ENDIAN_BE8
	moveq	r0, #0x00004000	@ set bit 22, mov to mvn instruction
#else
	moveq	r0, #0x400000	@ set bit 22, mov to mvn instruction
#endif
	b	2f
//k14AB : r3 = delta
1:	ldr	ip, [r7, r3]
#ifdef CONFIG_CPU_ENDIAN_BE8
	@ in BE8, we load data in BE, but instructions still in LE
	bic	ip, ip, #0xff000000
	tst	ip, #0x000f0000	@ check the rotation field
	orrne	ip, ip, r6, lsl #24 @ mask in offset bits 31-24
	biceq	ip, ip, #0x00004000 @ clear bit 22
	orreq	ip, ip, r0      @ mask in offset bits 7-0
#else
	bic	ip, ip, #0x000000ff
	tst	ip, #0xf00	@ check the rotation field
//k14AB : r6 = delta >> 24 => 0xHH000000 -> 0x000000HH
	orrne	ip, ip, r6	@ mask in offset bits 31-24
	biceq	ip, ip, #0x400000	@ clear bit 22
//k14AB : delta 값이 "-"인경우 r0 = 0x400000 => mvn(1111)
//                   "+" 이면  r0 = 0        => mov(1101)
	orreq	ip, ip, r0	@ mask in offset bits 7-0
#endif
	str	ip, [r7, r3]
//k14AB : __pv_table_begin     @ r4
//k14AB : __pv_table_end       @ r5
//
//1:    add     t, x __PV_BITS_31_24  === ip
//
//__pv_table_begin             === r4
//      .pushsection .pv_table, "a"
//      .long  1b              === r7 = 1b
//      .popsection
//__pv_table_end               === r5
//
//
2:	cmp	r4, r5
	ldrcc	r7, [r4], #4	@ use branch for delay slot
	bcc	1b
	ret	lr
#endif
ENDPROC(__fixup_a_pv_table)

	.align
3:	.long __pv_offset

ENTRY(fixup_pv_table)
	stmfd	sp!, {r4 - r7, lr}
	mov	r3, #0			@ no offset
	mov	r4, r0			@ r0 = table start
	add	r5, r0, r1		@ r1 = table size
	bl	__fixup_a_pv_table
	ldmfd	sp!, {r4 - r7, pc}
ENDPROC(fixup_pv_table)

	.data
	.globl	__pv_phys_pfn_offset
	.type	__pv_phys_pfn_offset, %object
__pv_phys_pfn_offset:
	.word	0
	.size	__pv_phys_pfn_offset, . -__pv_phys_pfn_offset

	.globl	__pv_offset
	.type	__pv_offset, %object
__pv_offset:
	.quad	0
	.size	__pv_offset, . -__pv_offset
#endif

#include "head-common.S"
