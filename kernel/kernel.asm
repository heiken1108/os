
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b8010113          	addi	sp,sp,-1152 # 80008b80 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	9f070713          	addi	a4,a4,-1552 # 80008a40 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	0fe78793          	addi	a5,a5,254 # 80006160 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbc94f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	f1e78793          	addi	a5,a5,-226 # 80000fca <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:

//
// user write()s to the console go here.
//
int consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
    int i;

    for (i = 0; i < n; i++)
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    {
        char c;
        if (either_copyin(&c, user_src, src + i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	6f8080e7          	jalr	1784(ra) # 80002822 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
            break;
        uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	792080e7          	jalr	1938(ra) # 800008cc <uartputc>
    for (i = 0; i < n; i++)
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
    }

    return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
    for (i = 0; i < n; i++)
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// copy (up to) a whole input line to dst.
// user_dist indicates whether dst is a user
// or kernel address.
//
int consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	711d                	addi	sp,sp,-96
    80000166:	ec86                	sd	ra,88(sp)
    80000168:	e8a2                	sd	s0,80(sp)
    8000016a:	e4a6                	sd	s1,72(sp)
    8000016c:	e0ca                	sd	s2,64(sp)
    8000016e:	fc4e                	sd	s3,56(sp)
    80000170:	f852                	sd	s4,48(sp)
    80000172:	f456                	sd	s5,40(sp)
    80000174:	f05a                	sd	s6,32(sp)
    80000176:	ec5e                	sd	s7,24(sp)
    80000178:	1080                	addi	s0,sp,96
    8000017a:	8aaa                	mv	s5,a0
    8000017c:	8a2e                	mv	s4,a1
    8000017e:	89b2                	mv	s3,a2
    uint target;
    int c;
    char cbuf;

    target = n;
    80000180:	00060b1b          	sext.w	s6,a2
    acquire(&cons.lock);
    80000184:	00011517          	auipc	a0,0x11
    80000188:	9fc50513          	addi	a0,a0,-1540 # 80010b80 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	b9e080e7          	jalr	-1122(ra) # 80000d2a <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    80000194:	00011497          	auipc	s1,0x11
    80000198:	9ec48493          	addi	s1,s1,-1556 # 80010b80 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	a7c90913          	addi	s2,s2,-1412 # 80010c18 <cons+0x98>
    while (n > 0)
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
        while (cons.r == cons.w)
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
            if (killed(myproc()))
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	aa8080e7          	jalr	-1368(ra) # 80001c5c <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	4b0080e7          	jalr	1200(ra) # 8000266c <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
            sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	1fa080e7          	jalr	506(ra) # 800023c4 <sleep>
        while (cons.r == cons.w)
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	9a270713          	addi	a4,a4,-1630 # 80010b80 <cons>
    800001e6:	0017869b          	addiw	a3,a5,1
    800001ea:	08d72c23          	sw	a3,152(a4)
    800001ee:	07f7f693          	andi	a3,a5,127
    800001f2:	9736                	add	a4,a4,a3
    800001f4:	01874703          	lbu	a4,24(a4)
    800001f8:	00070b9b          	sext.w	s7,a4

        if (c == C('D'))
    800001fc:	4691                	li	a3,4
    800001fe:	06db8463          	beq	s7,a3,80000266 <consoleread+0x102>
            }
            break;
        }

        // copy the input byte to the user-space buffer.
        cbuf = c;
    80000202:	fae407a3          	sb	a4,-81(s0)
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	faf40613          	addi	a2,s0,-81
    8000020c:	85d2                	mv	a1,s4
    8000020e:	8556                	mv	a0,s5
    80000210:	00002097          	auipc	ra,0x2
    80000214:	5bc080e7          	jalr	1468(ra) # 800027cc <either_copyout>
    80000218:	57fd                	li	a5,-1
    8000021a:	00f50763          	beq	a0,a5,80000228 <consoleread+0xc4>
            break;

        dst++;
    8000021e:	0a05                	addi	s4,s4,1
        --n;
    80000220:	39fd                	addiw	s3,s3,-1

        if (c == '\n')
    80000222:	47a9                	li	a5,10
    80000224:	f8fb90e3          	bne	s7,a5,800001a4 <consoleread+0x40>
            // a whole line has arrived, return to
            // the user-level read().
            break;
        }
    }
    release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	95850513          	addi	a0,a0,-1704 # 80010b80 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	bae080e7          	jalr	-1106(ra) # 80000dde <release>

    return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
                release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	94250513          	addi	a0,a0,-1726 # 80010b80 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	b98080e7          	jalr	-1128(ra) # 80000dde <release>
                return -1;
    8000024e:	557d                	li	a0,-1
}
    80000250:	60e6                	ld	ra,88(sp)
    80000252:	6446                	ld	s0,80(sp)
    80000254:	64a6                	ld	s1,72(sp)
    80000256:	6906                	ld	s2,64(sp)
    80000258:	79e2                	ld	s3,56(sp)
    8000025a:	7a42                	ld	s4,48(sp)
    8000025c:	7aa2                	ld	s5,40(sp)
    8000025e:	7b02                	ld	s6,32(sp)
    80000260:	6be2                	ld	s7,24(sp)
    80000262:	6125                	addi	sp,sp,96
    80000264:	8082                	ret
            if (n < target)
    80000266:	0009871b          	sext.w	a4,s3
    8000026a:	fb677fe3          	bgeu	a4,s6,80000228 <consoleread+0xc4>
                cons.r--;
    8000026e:	00011717          	auipc	a4,0x11
    80000272:	9af72523          	sw	a5,-1622(a4) # 80010c18 <cons+0x98>
    80000276:	bf4d                	j	80000228 <consoleread+0xc4>

0000000080000278 <consputc>:
{
    80000278:	1141                	addi	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	addi	s0,sp,16
    if (c == BACKSPACE)
    80000280:	10000793          	li	a5,256
    80000284:	00f50a63          	beq	a0,a5,80000298 <consputc+0x20>
        uartputc_sync(c);
    80000288:	00000097          	auipc	ra,0x0
    8000028c:	572080e7          	jalr	1394(ra) # 800007fa <uartputc_sync>
}
    80000290:	60a2                	ld	ra,8(sp)
    80000292:	6402                	ld	s0,0(sp)
    80000294:	0141                	addi	sp,sp,16
    80000296:	8082                	ret
        uartputc_sync('\b');
    80000298:	4521                	li	a0,8
    8000029a:	00000097          	auipc	ra,0x0
    8000029e:	560080e7          	jalr	1376(ra) # 800007fa <uartputc_sync>
        uartputc_sync(' ');
    800002a2:	02000513          	li	a0,32
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	554080e7          	jalr	1364(ra) # 800007fa <uartputc_sync>
        uartputc_sync('\b');
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	54a080e7          	jalr	1354(ra) # 800007fa <uartputc_sync>
    800002b8:	bfe1                	j	80000290 <consputc+0x18>

00000000800002ba <consoleintr>:
// uartintr() calls this for input character.
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void consoleintr(int c)
{
    800002ba:	1101                	addi	sp,sp,-32
    800002bc:	ec06                	sd	ra,24(sp)
    800002be:	e822                	sd	s0,16(sp)
    800002c0:	e426                	sd	s1,8(sp)
    800002c2:	e04a                	sd	s2,0(sp)
    800002c4:	1000                	addi	s0,sp,32
    800002c6:	84aa                	mv	s1,a0
    acquire(&cons.lock);
    800002c8:	00011517          	auipc	a0,0x11
    800002cc:	8b850513          	addi	a0,a0,-1864 # 80010b80 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	a5a080e7          	jalr	-1446(ra) # 80000d2a <acquire>

    switch (c)
    800002d8:	47d5                	li	a5,21
    800002da:	0af48663          	beq	s1,a5,80000386 <consoleintr+0xcc>
    800002de:	0297ca63          	blt	a5,s1,80000312 <consoleintr+0x58>
    800002e2:	47a1                	li	a5,8
    800002e4:	0ef48763          	beq	s1,a5,800003d2 <consoleintr+0x118>
    800002e8:	47c1                	li	a5,16
    800002ea:	10f49a63          	bne	s1,a5,800003fe <consoleintr+0x144>
    {
    case C('P'): // Print process list.
        procdump();
    800002ee:	00002097          	auipc	ra,0x2
    800002f2:	58a080e7          	jalr	1418(ra) # 80002878 <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002f6:	00011517          	auipc	a0,0x11
    800002fa:	88a50513          	addi	a0,a0,-1910 # 80010b80 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	ae0080e7          	jalr	-1312(ra) # 80000dde <release>
}
    80000306:	60e2                	ld	ra,24(sp)
    80000308:	6442                	ld	s0,16(sp)
    8000030a:	64a2                	ld	s1,8(sp)
    8000030c:	6902                	ld	s2,0(sp)
    8000030e:	6105                	addi	sp,sp,32
    80000310:	8082                	ret
    switch (c)
    80000312:	07f00793          	li	a5,127
    80000316:	0af48e63          	beq	s1,a5,800003d2 <consoleintr+0x118>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    8000031a:	00011717          	auipc	a4,0x11
    8000031e:	86670713          	addi	a4,a4,-1946 # 80010b80 <cons>
    80000322:	0a072783          	lw	a5,160(a4)
    80000326:	09872703          	lw	a4,152(a4)
    8000032a:	9f99                	subw	a5,a5,a4
    8000032c:	07f00713          	li	a4,127
    80000330:	fcf763e3          	bltu	a4,a5,800002f6 <consoleintr+0x3c>
            c = (c == '\r') ? '\n' : c;
    80000334:	47b5                	li	a5,13
    80000336:	0cf48763          	beq	s1,a5,80000404 <consoleintr+0x14a>
            consputc(c);
    8000033a:	8526                	mv	a0,s1
    8000033c:	00000097          	auipc	ra,0x0
    80000340:	f3c080e7          	jalr	-196(ra) # 80000278 <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000344:	00011797          	auipc	a5,0x11
    80000348:	83c78793          	addi	a5,a5,-1988 # 80010b80 <cons>
    8000034c:	0a07a683          	lw	a3,160(a5)
    80000350:	0016871b          	addiw	a4,a3,1
    80000354:	0007061b          	sext.w	a2,a4
    80000358:	0ae7a023          	sw	a4,160(a5)
    8000035c:	07f6f693          	andi	a3,a3,127
    80000360:	97b6                	add	a5,a5,a3
    80000362:	00978c23          	sb	s1,24(a5)
            if (c == '\n' || c == C('D') || cons.e - cons.r == INPUT_BUF_SIZE)
    80000366:	47a9                	li	a5,10
    80000368:	0cf48563          	beq	s1,a5,80000432 <consoleintr+0x178>
    8000036c:	4791                	li	a5,4
    8000036e:	0cf48263          	beq	s1,a5,80000432 <consoleintr+0x178>
    80000372:	00011797          	auipc	a5,0x11
    80000376:	8a67a783          	lw	a5,-1882(a5) # 80010c18 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
        while (cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	7fa70713          	addi	a4,a4,2042 # 80010b80 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	7ea48493          	addi	s1,s1,2026 # 80010b80 <cons>
        while (cons.e != cons.w &&
    8000039e:	4929                	li	s2,10
    800003a0:	f4f70be3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    800003a4:	37fd                	addiw	a5,a5,-1
    800003a6:	07f7f713          	andi	a4,a5,127
    800003aa:	9726                	add	a4,a4,s1
        while (cons.e != cons.w &&
    800003ac:	01874703          	lbu	a4,24(a4)
    800003b0:	f52703e3          	beq	a4,s2,800002f6 <consoleintr+0x3c>
            cons.e--;
    800003b4:	0af4a023          	sw	a5,160(s1)
            consputc(BACKSPACE);
    800003b8:	10000513          	li	a0,256
    800003bc:	00000097          	auipc	ra,0x0
    800003c0:	ebc080e7          	jalr	-324(ra) # 80000278 <consputc>
        while (cons.e != cons.w &&
    800003c4:	0a04a783          	lw	a5,160(s1)
    800003c8:	09c4a703          	lw	a4,156(s1)
    800003cc:	fcf71ce3          	bne	a4,a5,800003a4 <consoleintr+0xea>
    800003d0:	b71d                	j	800002f6 <consoleintr+0x3c>
        if (cons.e != cons.w)
    800003d2:	00010717          	auipc	a4,0x10
    800003d6:	7ae70713          	addi	a4,a4,1966 # 80010b80 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
            cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	82f72c23          	sw	a5,-1992(a4) # 80010c20 <cons+0xa0>
            consputc(BACKSPACE);
    800003f0:	10000513          	li	a0,256
    800003f4:	00000097          	auipc	ra,0x0
    800003f8:	e84080e7          	jalr	-380(ra) # 80000278 <consputc>
    800003fc:	bded                	j	800002f6 <consoleintr+0x3c>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    800003fe:	ee048ce3          	beqz	s1,800002f6 <consoleintr+0x3c>
    80000402:	bf21                	j	8000031a <consoleintr+0x60>
            consputc(c);
    80000404:	4529                	li	a0,10
    80000406:	00000097          	auipc	ra,0x0
    8000040a:	e72080e7          	jalr	-398(ra) # 80000278 <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000040e:	00010797          	auipc	a5,0x10
    80000412:	77278793          	addi	a5,a5,1906 # 80010b80 <cons>
    80000416:	0a07a703          	lw	a4,160(a5)
    8000041a:	0017069b          	addiw	a3,a4,1
    8000041e:	0006861b          	sext.w	a2,a3
    80000422:	0ad7a023          	sw	a3,160(a5)
    80000426:	07f77713          	andi	a4,a4,127
    8000042a:	97ba                	add	a5,a5,a4
    8000042c:	4729                	li	a4,10
    8000042e:	00e78c23          	sb	a4,24(a5)
                cons.w = cons.e;
    80000432:	00010797          	auipc	a5,0x10
    80000436:	7ec7a523          	sw	a2,2026(a5) # 80010c1c <cons+0x9c>
                wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	7de50513          	addi	a0,a0,2014 # 80010c18 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	fe6080e7          	jalr	-26(ra) # 80002428 <wakeup>
    8000044a:	b575                	j	800002f6 <consoleintr+0x3c>

000000008000044c <consoleinit>:

void consoleinit(void)
{
    8000044c:	1141                	addi	sp,sp,-16
    8000044e:	e406                	sd	ra,8(sp)
    80000450:	e022                	sd	s0,0(sp)
    80000452:	0800                	addi	s0,sp,16
    initlock(&cons.lock, "cons");
    80000454:	00008597          	auipc	a1,0x8
    80000458:	bbc58593          	addi	a1,a1,-1092 # 80008010 <etext+0x10>
    8000045c:	00010517          	auipc	a0,0x10
    80000460:	72450513          	addi	a0,a0,1828 # 80010b80 <cons>
    80000464:	00001097          	auipc	ra,0x1
    80000468:	836080e7          	jalr	-1994(ra) # 80000c9a <initlock>

    uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	33e080e7          	jalr	830(ra) # 800007aa <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000474:	00241797          	auipc	a5,0x241
    80000478:	8a478793          	addi	a5,a5,-1884 # 80240d18 <devsw>
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	ce870713          	addi	a4,a4,-792 # 80000164 <consoleread>
    80000484:	eb98                	sd	a4,16(a5)
    devsw[CONSOLE].write = consolewrite;
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	c7a70713          	addi	a4,a4,-902 # 80000100 <consolewrite>
    8000048e:	ef98                	sd	a4,24(a5)
}
    80000490:	60a2                	ld	ra,8(sp)
    80000492:	6402                	ld	s0,0(sp)
    80000494:	0141                	addi	sp,sp,16
    80000496:	8082                	ret

0000000080000498 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000498:	7179                	addi	sp,sp,-48
    8000049a:	f406                	sd	ra,40(sp)
    8000049c:	f022                	sd	s0,32(sp)
    8000049e:	ec26                	sd	s1,24(sp)
    800004a0:	e84a                	sd	s2,16(sp)
    800004a2:	1800                	addi	s0,sp,48
    char buf[16];
    int i;
    uint x;

    if (sign && (sign = xx < 0))
    800004a4:	c219                	beqz	a2,800004aa <printint+0x12>
    800004a6:	08054763          	bltz	a0,80000534 <printint+0x9c>
        x = -xx;
    else
        x = xx;
    800004aa:	2501                	sext.w	a0,a0
    800004ac:	4881                	li	a7,0
    800004ae:	fd040693          	addi	a3,s0,-48

    i = 0;
    800004b2:	4701                	li	a4,0
    do
    {
        buf[i++] = digits[x % base];
    800004b4:	2581                	sext.w	a1,a1
    800004b6:	00008617          	auipc	a2,0x8
    800004ba:	b8a60613          	addi	a2,a2,-1142 # 80008040 <digits>
    800004be:	883a                	mv	a6,a4
    800004c0:	2705                	addiw	a4,a4,1
    800004c2:	02b577bb          	remuw	a5,a0,a1
    800004c6:	1782                	slli	a5,a5,0x20
    800004c8:	9381                	srli	a5,a5,0x20
    800004ca:	97b2                	add	a5,a5,a2
    800004cc:	0007c783          	lbu	a5,0(a5)
    800004d0:	00f68023          	sb	a5,0(a3)
    } while ((x /= base) != 0);
    800004d4:	0005079b          	sext.w	a5,a0
    800004d8:	02b5553b          	divuw	a0,a0,a1
    800004dc:	0685                	addi	a3,a3,1
    800004de:	feb7f0e3          	bgeu	a5,a1,800004be <printint+0x26>

    if (sign)
    800004e2:	00088c63          	beqz	a7,800004fa <printint+0x62>
        buf[i++] = '-';
    800004e6:	fe070793          	addi	a5,a4,-32
    800004ea:	00878733          	add	a4,a5,s0
    800004ee:	02d00793          	li	a5,45
    800004f2:	fef70823          	sb	a5,-16(a4)
    800004f6:	0028071b          	addiw	a4,a6,2

    while (--i >= 0)
    800004fa:	02e05763          	blez	a4,80000528 <printint+0x90>
    800004fe:	fd040793          	addi	a5,s0,-48
    80000502:	00e784b3          	add	s1,a5,a4
    80000506:	fff78913          	addi	s2,a5,-1
    8000050a:	993a                	add	s2,s2,a4
    8000050c:	377d                	addiw	a4,a4,-1
    8000050e:	1702                	slli	a4,a4,0x20
    80000510:	9301                	srli	a4,a4,0x20
    80000512:	40e90933          	sub	s2,s2,a4
        consputc(buf[i]);
    80000516:	fff4c503          	lbu	a0,-1(s1)
    8000051a:	00000097          	auipc	ra,0x0
    8000051e:	d5e080e7          	jalr	-674(ra) # 80000278 <consputc>
    while (--i >= 0)
    80000522:	14fd                	addi	s1,s1,-1
    80000524:	ff2499e3          	bne	s1,s2,80000516 <printint+0x7e>
}
    80000528:	70a2                	ld	ra,40(sp)
    8000052a:	7402                	ld	s0,32(sp)
    8000052c:	64e2                	ld	s1,24(sp)
    8000052e:	6942                	ld	s2,16(sp)
    80000530:	6145                	addi	sp,sp,48
    80000532:	8082                	ret
        x = -xx;
    80000534:	40a0053b          	negw	a0,a0
    if (sign && (sign = xx < 0))
    80000538:	4885                	li	a7,1
        x = -xx;
    8000053a:	bf95                	j	800004ae <printint+0x16>

000000008000053c <panic>:
    if (locking)
        release(&pr.lock);
}

void panic(char *s, ...)
{
    8000053c:	711d                	addi	sp,sp,-96
    8000053e:	ec06                	sd	ra,24(sp)
    80000540:	e822                	sd	s0,16(sp)
    80000542:	e426                	sd	s1,8(sp)
    80000544:	1000                	addi	s0,sp,32
    80000546:	84aa                	mv	s1,a0
    80000548:	e40c                	sd	a1,8(s0)
    8000054a:	e810                	sd	a2,16(s0)
    8000054c:	ec14                	sd	a3,24(s0)
    8000054e:	f018                	sd	a4,32(s0)
    80000550:	f41c                	sd	a5,40(s0)
    80000552:	03043823          	sd	a6,48(s0)
    80000556:	03143c23          	sd	a7,56(s0)
    pr.locking = 0;
    8000055a:	00010797          	auipc	a5,0x10
    8000055e:	6e07a323          	sw	zero,1766(a5) # 80010c40 <pr+0x18>
    printf("panic: ");
    80000562:	00008517          	auipc	a0,0x8
    80000566:	ab650513          	addi	a0,a0,-1354 # 80008018 <etext+0x18>
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	02e080e7          	jalr	46(ra) # 80000598 <printf>
    printf(s);
    80000572:	8526                	mv	a0,s1
    80000574:	00000097          	auipc	ra,0x0
    80000578:	024080e7          	jalr	36(ra) # 80000598 <printf>
    printf("\n");
    8000057c:	00008517          	auipc	a0,0x8
    80000580:	b8450513          	addi	a0,a0,-1148 # 80008100 <digits+0xc0>
    80000584:	00000097          	auipc	ra,0x0
    80000588:	014080e7          	jalr	20(ra) # 80000598 <printf>
    panicked = 1; // freeze uart output from other CPUs
    8000058c:	4785                	li	a5,1
    8000058e:	00008717          	auipc	a4,0x8
    80000592:	46f72123          	sw	a5,1122(a4) # 800089f0 <panicked>
    for (;;)
    80000596:	a001                	j	80000596 <panic+0x5a>

0000000080000598 <printf>:
{
    80000598:	7131                	addi	sp,sp,-192
    8000059a:	fc86                	sd	ra,120(sp)
    8000059c:	f8a2                	sd	s0,112(sp)
    8000059e:	f4a6                	sd	s1,104(sp)
    800005a0:	f0ca                	sd	s2,96(sp)
    800005a2:	ecce                	sd	s3,88(sp)
    800005a4:	e8d2                	sd	s4,80(sp)
    800005a6:	e4d6                	sd	s5,72(sp)
    800005a8:	e0da                	sd	s6,64(sp)
    800005aa:	fc5e                	sd	s7,56(sp)
    800005ac:	f862                	sd	s8,48(sp)
    800005ae:	f466                	sd	s9,40(sp)
    800005b0:	f06a                	sd	s10,32(sp)
    800005b2:	ec6e                	sd	s11,24(sp)
    800005b4:	0100                	addi	s0,sp,128
    800005b6:	8a2a                	mv	s4,a0
    800005b8:	e40c                	sd	a1,8(s0)
    800005ba:	e810                	sd	a2,16(s0)
    800005bc:	ec14                	sd	a3,24(s0)
    800005be:	f018                	sd	a4,32(s0)
    800005c0:	f41c                	sd	a5,40(s0)
    800005c2:	03043823          	sd	a6,48(s0)
    800005c6:	03143c23          	sd	a7,56(s0)
    locking = pr.locking;
    800005ca:	00010d97          	auipc	s11,0x10
    800005ce:	676dad83          	lw	s11,1654(s11) # 80010c40 <pr+0x18>
    if (locking)
    800005d2:	020d9b63          	bnez	s11,80000608 <printf+0x70>
    if (fmt == 0)
    800005d6:	040a0263          	beqz	s4,8000061a <printf+0x82>
    va_start(ap, fmt);
    800005da:	00840793          	addi	a5,s0,8
    800005de:	f8f43423          	sd	a5,-120(s0)
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++)
    800005e2:	000a4503          	lbu	a0,0(s4)
    800005e6:	14050f63          	beqz	a0,80000744 <printf+0x1ac>
    800005ea:	4981                	li	s3,0
        if (c != '%')
    800005ec:	02500a93          	li	s5,37
        switch (c)
    800005f0:	07000b93          	li	s7,112
    consputc('x');
    800005f4:	4d41                	li	s10,16
        consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f6:	00008b17          	auipc	s6,0x8
    800005fa:	a4ab0b13          	addi	s6,s6,-1462 # 80008040 <digits>
        switch (c)
    800005fe:	07300c93          	li	s9,115
    80000602:	06400c13          	li	s8,100
    80000606:	a82d                	j	80000640 <printf+0xa8>
        acquire(&pr.lock);
    80000608:	00010517          	auipc	a0,0x10
    8000060c:	62050513          	addi	a0,a0,1568 # 80010c28 <pr>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	71a080e7          	jalr	1818(ra) # 80000d2a <acquire>
    80000618:	bf7d                	j	800005d6 <printf+0x3e>
        panic("null fmt");
    8000061a:	00008517          	auipc	a0,0x8
    8000061e:	a0e50513          	addi	a0,a0,-1522 # 80008028 <etext+0x28>
    80000622:	00000097          	auipc	ra,0x0
    80000626:	f1a080e7          	jalr	-230(ra) # 8000053c <panic>
            consputc(c);
    8000062a:	00000097          	auipc	ra,0x0
    8000062e:	c4e080e7          	jalr	-946(ra) # 80000278 <consputc>
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++)
    80000632:	2985                	addiw	s3,s3,1
    80000634:	013a07b3          	add	a5,s4,s3
    80000638:	0007c503          	lbu	a0,0(a5)
    8000063c:	10050463          	beqz	a0,80000744 <printf+0x1ac>
        if (c != '%')
    80000640:	ff5515e3          	bne	a0,s5,8000062a <printf+0x92>
        c = fmt[++i] & 0xff;
    80000644:	2985                	addiw	s3,s3,1
    80000646:	013a07b3          	add	a5,s4,s3
    8000064a:	0007c783          	lbu	a5,0(a5)
    8000064e:	0007849b          	sext.w	s1,a5
        if (c == 0)
    80000652:	cbed                	beqz	a5,80000744 <printf+0x1ac>
        switch (c)
    80000654:	05778a63          	beq	a5,s7,800006a8 <printf+0x110>
    80000658:	02fbf663          	bgeu	s7,a5,80000684 <printf+0xec>
    8000065c:	09978863          	beq	a5,s9,800006ec <printf+0x154>
    80000660:	07800713          	li	a4,120
    80000664:	0ce79563          	bne	a5,a4,8000072e <printf+0x196>
            printint(va_arg(ap, int), 16, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	85ea                	mv	a1,s10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e1e080e7          	jalr	-482(ra) # 80000498 <printint>
            break;
    80000682:	bf45                	j	80000632 <printf+0x9a>
        switch (c)
    80000684:	09578f63          	beq	a5,s5,80000722 <printf+0x18a>
    80000688:	0b879363          	bne	a5,s8,8000072e <printf+0x196>
            printint(va_arg(ap, int), 10, 1);
    8000068c:	f8843783          	ld	a5,-120(s0)
    80000690:	00878713          	addi	a4,a5,8
    80000694:	f8e43423          	sd	a4,-120(s0)
    80000698:	4605                	li	a2,1
    8000069a:	45a9                	li	a1,10
    8000069c:	4388                	lw	a0,0(a5)
    8000069e:	00000097          	auipc	ra,0x0
    800006a2:	dfa080e7          	jalr	-518(ra) # 80000498 <printint>
            break;
    800006a6:	b771                	j	80000632 <printf+0x9a>
            printptr(va_arg(ap, uint64));
    800006a8:	f8843783          	ld	a5,-120(s0)
    800006ac:	00878713          	addi	a4,a5,8
    800006b0:	f8e43423          	sd	a4,-120(s0)
    800006b4:	0007b903          	ld	s2,0(a5)
    consputc('0');
    800006b8:	03000513          	li	a0,48
    800006bc:	00000097          	auipc	ra,0x0
    800006c0:	bbc080e7          	jalr	-1092(ra) # 80000278 <consputc>
    consputc('x');
    800006c4:	07800513          	li	a0,120
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	bb0080e7          	jalr	-1104(ra) # 80000278 <consputc>
    800006d0:	84ea                	mv	s1,s10
        consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006d2:	03c95793          	srli	a5,s2,0x3c
    800006d6:	97da                	add	a5,a5,s6
    800006d8:	0007c503          	lbu	a0,0(a5)
    800006dc:	00000097          	auipc	ra,0x0
    800006e0:	b9c080e7          	jalr	-1124(ra) # 80000278 <consputc>
    for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e4:	0912                	slli	s2,s2,0x4
    800006e6:	34fd                	addiw	s1,s1,-1
    800006e8:	f4ed                	bnez	s1,800006d2 <printf+0x13a>
    800006ea:	b7a1                	j	80000632 <printf+0x9a>
            if ((s = va_arg(ap, char *)) == 0)
    800006ec:	f8843783          	ld	a5,-120(s0)
    800006f0:	00878713          	addi	a4,a5,8
    800006f4:	f8e43423          	sd	a4,-120(s0)
    800006f8:	6384                	ld	s1,0(a5)
    800006fa:	cc89                	beqz	s1,80000714 <printf+0x17c>
            for (; *s; s++)
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	d90d                	beqz	a0,80000632 <printf+0x9a>
                consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b76080e7          	jalr	-1162(ra) # 80000278 <consputc>
            for (; *s; s++)
    8000070a:	0485                	addi	s1,s1,1
    8000070c:	0004c503          	lbu	a0,0(s1)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x16a>
    80000712:	b705                	j	80000632 <printf+0x9a>
                s = "(null)";
    80000714:	00008497          	auipc	s1,0x8
    80000718:	90c48493          	addi	s1,s1,-1780 # 80008020 <etext+0x20>
            for (; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x16a>
            consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b54080e7          	jalr	-1196(ra) # 80000278 <consputc>
            break;
    8000072c:	b719                	j	80000632 <printf+0x9a>
            consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b48080e7          	jalr	-1208(ra) # 80000278 <consputc>
            consputc(c);
    80000738:	8526                	mv	a0,s1
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b3e080e7          	jalr	-1218(ra) # 80000278 <consputc>
            break;
    80000742:	bdc5                	j	80000632 <printf+0x9a>
    if (locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1ce>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
        release(&pr.lock);
    80000766:	00010517          	auipc	a0,0x10
    8000076a:	4c250513          	addi	a0,a0,1218 # 80010c28 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	670080e7          	jalr	1648(ra) # 80000dde <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b0>

0000000080000778 <printfinit>:
        ;
}

void printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
    initlock(&pr.lock, "pr");
    80000782:	00010497          	auipc	s1,0x10
    80000786:	4a648493          	addi	s1,s1,1190 # 80010c28 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8ae58593          	addi	a1,a1,-1874 # 80008038 <etext+0x38>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	506080e7          	jalr	1286(ra) # 80000c9a <initlock>
    pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	87e58593          	addi	a1,a1,-1922 # 80008058 <digits+0x18>
    800007e2:	00010517          	auipc	a0,0x10
    800007e6:	46650513          	addi	a0,a0,1126 # 80010c48 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	4b0080e7          	jalr	1200(ra) # 80000c9a <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	4d8080e7          	jalr	1240(ra) # 80000cde <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	1e27a783          	lw	a5,482(a5) # 800089f0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dfe5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f513          	zext.b	a0,s1
    8000082c:	100007b7          	lui	a5,0x10000
    80000830:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	54a080e7          	jalr	1354(ra) # 80000d7e <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008797          	auipc	a5,0x8
    8000084a:	1b27b783          	ld	a5,434(a5) # 800089f8 <uart_tx_r>
    8000084e:	00008717          	auipc	a4,0x8
    80000852:	1b273703          	ld	a4,434(a4) # 80008a00 <uart_tx_w>
    80000856:	06f70a63          	beq	a4,a5,800008ca <uartstart+0x84>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	3d8a0a13          	addi	s4,s4,984 # 80010c48 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	18048493          	addi	s1,s1,384 # 800089f8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	18098993          	addi	s3,s3,384 # 80008a00 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	02077713          	andi	a4,a4,32
    80000890:	c705                	beqz	a4,800008b8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000892:	01f7f713          	andi	a4,a5,31
    80000896:	9752                	add	a4,a4,s4
    80000898:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000089c:	0785                	addi	a5,a5,1
    8000089e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a0:	8526                	mv	a0,s1
    800008a2:	00002097          	auipc	ra,0x2
    800008a6:	b86080e7          	jalr	-1146(ra) # 80002428 <wakeup>
    
    WriteReg(THR, c);
    800008aa:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ae:	609c                	ld	a5,0(s1)
    800008b0:	0009b703          	ld	a4,0(s3)
    800008b4:	fcf71ae3          	bne	a4,a5,80000888 <uartstart+0x42>
  }
}
    800008b8:	70e2                	ld	ra,56(sp)
    800008ba:	7442                	ld	s0,48(sp)
    800008bc:	74a2                	ld	s1,40(sp)
    800008be:	7902                	ld	s2,32(sp)
    800008c0:	69e2                	ld	s3,24(sp)
    800008c2:	6a42                	ld	s4,16(sp)
    800008c4:	6aa2                	ld	s5,8(sp)
    800008c6:	6121                	addi	sp,sp,64
    800008c8:	8082                	ret
    800008ca:	8082                	ret

00000000800008cc <uartputc>:
{
    800008cc:	7179                	addi	sp,sp,-48
    800008ce:	f406                	sd	ra,40(sp)
    800008d0:	f022                	sd	s0,32(sp)
    800008d2:	ec26                	sd	s1,24(sp)
    800008d4:	e84a                	sd	s2,16(sp)
    800008d6:	e44e                	sd	s3,8(sp)
    800008d8:	e052                	sd	s4,0(sp)
    800008da:	1800                	addi	s0,sp,48
    800008dc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008de:	00010517          	auipc	a0,0x10
    800008e2:	36a50513          	addi	a0,a0,874 # 80010c48 <uart_tx_lock>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	444080e7          	jalr	1092(ra) # 80000d2a <acquire>
  if(panicked){
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	1027a783          	lw	a5,258(a5) # 800089f0 <panicked>
    800008f6:	e7c9                	bnez	a5,80000980 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008717          	auipc	a4,0x8
    800008fc:	10873703          	ld	a4,264(a4) # 80008a00 <uart_tx_w>
    80000900:	00008797          	auipc	a5,0x8
    80000904:	0f87b783          	ld	a5,248(a5) # 800089f8 <uart_tx_r>
    80000908:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    8000090c:	00010997          	auipc	s3,0x10
    80000910:	33c98993          	addi	s3,s3,828 # 80010c48 <uart_tx_lock>
    80000914:	00008497          	auipc	s1,0x8
    80000918:	0e448493          	addi	s1,s1,228 # 800089f8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000091c:	00008917          	auipc	s2,0x8
    80000920:	0e490913          	addi	s2,s2,228 # 80008a00 <uart_tx_w>
    80000924:	00e79f63          	bne	a5,a4,80000942 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85ce                	mv	a1,s3
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	a98080e7          	jalr	-1384(ra) # 800023c4 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093703          	ld	a4,0(s2)
    80000938:	609c                	ld	a5,0(s1)
    8000093a:	02078793          	addi	a5,a5,32
    8000093e:	fee785e3          	beq	a5,a4,80000928 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00010497          	auipc	s1,0x10
    80000946:	30648493          	addi	s1,s1,774 # 80010c48 <uart_tx_lock>
    8000094a:	01f77793          	andi	a5,a4,31
    8000094e:	97a6                	add	a5,a5,s1
    80000950:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000954:	0705                	addi	a4,a4,1
    80000956:	00008797          	auipc	a5,0x8
    8000095a:	0ae7b523          	sd	a4,170(a5) # 80008a00 <uart_tx_w>
  uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee8080e7          	jalr	-280(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	476080e7          	jalr	1142(ra) # 80000dde <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret
    for(;;)
    80000980:	a001                	j	80000980 <uartputc+0xb4>

0000000080000982 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000982:	1141                	addi	sp,sp,-16
    80000984:	e422                	sd	s0,8(sp)
    80000986:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000988:	100007b7          	lui	a5,0x10000
    8000098c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000990:	8b85                	andi	a5,a5,1
    80000992:	cb81                	beqz	a5,800009a2 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000994:	100007b7          	lui	a5,0x10000
    80000998:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000099c:	6422                	ld	s0,8(sp)
    8000099e:	0141                	addi	sp,sp,16
    800009a0:	8082                	ret
    return -1;
    800009a2:	557d                	li	a0,-1
    800009a4:	bfe5                	j	8000099c <uartgetc+0x1a>

00000000800009a6 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009a6:	1101                	addi	sp,sp,-32
    800009a8:	ec06                	sd	ra,24(sp)
    800009aa:	e822                	sd	s0,16(sp)
    800009ac:	e426                	sd	s1,8(sp)
    800009ae:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b0:	54fd                	li	s1,-1
    800009b2:	a029                	j	800009bc <uartintr+0x16>
      break;
    consoleintr(c);
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	906080e7          	jalr	-1786(ra) # 800002ba <consoleintr>
    int c = uartgetc();
    800009bc:	00000097          	auipc	ra,0x0
    800009c0:	fc6080e7          	jalr	-58(ra) # 80000982 <uartgetc>
    if(c == -1)
    800009c4:	fe9518e3          	bne	a0,s1,800009b4 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009c8:	00010497          	auipc	s1,0x10
    800009cc:	28048493          	addi	s1,s1,640 # 80010c48 <uart_tx_lock>
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	358080e7          	jalr	856(ra) # 80000d2a <acquire>
  uartstart();
    800009da:	00000097          	auipc	ra,0x0
    800009de:	e6c080e7          	jalr	-404(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009e2:	8526                	mv	a0,s1
    800009e4:	00000097          	auipc	ra,0x0
    800009e8:	3fa080e7          	jalr	1018(ra) # 80000dde <release>
}
    800009ec:	60e2                	ld	ra,24(sp)
    800009ee:	6442                	ld	s0,16(sp)
    800009f0:	64a2                	ld	s1,8(sp)
    800009f2:	6105                	addi	sp,sp,32
    800009f4:	8082                	ret

00000000800009f6 <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    800009f6:	1101                	addi	sp,sp,-32
    800009f8:	ec06                	sd	ra,24(sp)
    800009fa:	e822                	sd	s0,16(sp)
    800009fc:	e426                	sd	s1,8(sp)
    800009fe:	e04a                	sd	s2,0(sp)
    80000a00:	1000                	addi	s0,sp,32
    struct run *r;
    r = (struct run *)pa;
    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    80000a02:	03451793          	slli	a5,a0,0x34
    80000a06:	ebbd                	bnez	a5,80000a7c <kfree+0x86>
    80000a08:	84aa                	mv	s1,a0
    80000a0a:	00241797          	auipc	a5,0x241
    80000a0e:	4a678793          	addi	a5,a5,1190 # 80241eb0 <end>
    80000a12:	06f56563          	bltu	a0,a5,80000a7c <kfree+0x86>
    80000a16:	47c5                	li	a5,17
    80000a18:	07ee                	slli	a5,a5,0x1b
    80000a1a:	06f57163          	bgeu	a0,a5,80000a7c <kfree+0x86>
        panic("kfree");
    
    acquire(&kmem.lock);
    80000a1e:	00010517          	auipc	a0,0x10
    80000a22:	26250513          	addi	a0,a0,610 # 80010c80 <kmem>
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	304080e7          	jalr	772(ra) # 80000d2a <acquire>
    int pn = (uint64)r / PGSIZE;
    80000a2e:	00c4d793          	srli	a5,s1,0xc
    80000a32:	2781                	sext.w	a5,a5
    if (refcnt[pn] < 1) {
    80000a34:	00279693          	slli	a3,a5,0x2
    80000a38:	00010717          	auipc	a4,0x10
    80000a3c:	26870713          	addi	a4,a4,616 # 80010ca0 <refcnt>
    80000a40:	9736                	add	a4,a4,a3
    80000a42:	4318                	lw	a4,0(a4)
    80000a44:	04e05463          	blez	a4,80000a8c <kfree+0x96>
        panic("kfree panic");
    } 
    refcnt[pn] -= 1;
    80000a48:	377d                	addiw	a4,a4,-1
    80000a4a:	0007091b          	sext.w	s2,a4
    80000a4e:	078a                	slli	a5,a5,0x2
    80000a50:	00010697          	auipc	a3,0x10
    80000a54:	25068693          	addi	a3,a3,592 # 80010ca0 <refcnt>
    80000a58:	97b6                	add	a5,a5,a3
    80000a5a:	c398                	sw	a4,0(a5)
    int tmp = refcnt[pn];
    release(&kmem.lock);
    80000a5c:	00010517          	auipc	a0,0x10
    80000a60:	22450513          	addi	a0,a0,548 # 80010c80 <kmem>
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	37a080e7          	jalr	890(ra) # 80000dde <release>

    if (tmp > 0) {
    80000a6c:	03205863          	blez	s2,80000a9c <kfree+0xa6>

    acquire(&kmem.lock);
    r->next = kmem.freelist;
    kmem.freelist = r;
    release(&kmem.lock);
}
    80000a70:	60e2                	ld	ra,24(sp)
    80000a72:	6442                	ld	s0,16(sp)
    80000a74:	64a2                	ld	s1,8(sp)
    80000a76:	6902                	ld	s2,0(sp)
    80000a78:	6105                	addi	sp,sp,32
    80000a7a:	8082                	ret
        panic("kfree");
    80000a7c:	00007517          	auipc	a0,0x7
    80000a80:	5e450513          	addi	a0,a0,1508 # 80008060 <digits+0x20>
    80000a84:	00000097          	auipc	ra,0x0
    80000a88:	ab8080e7          	jalr	-1352(ra) # 8000053c <panic>
        panic("kfree panic");
    80000a8c:	00007517          	auipc	a0,0x7
    80000a90:	5dc50513          	addi	a0,a0,1500 # 80008068 <digits+0x28>
    80000a94:	00000097          	auipc	ra,0x0
    80000a98:	aa8080e7          	jalr	-1368(ra) # 8000053c <panic>
    memset(pa, 1, PGSIZE);
    80000a9c:	6605                	lui	a2,0x1
    80000a9e:	4585                	li	a1,1
    80000aa0:	8526                	mv	a0,s1
    80000aa2:	00000097          	auipc	ra,0x0
    80000aa6:	384080e7          	jalr	900(ra) # 80000e26 <memset>
    acquire(&kmem.lock);
    80000aaa:	00010917          	auipc	s2,0x10
    80000aae:	1d690913          	addi	s2,s2,470 # 80010c80 <kmem>
    80000ab2:	854a                	mv	a0,s2
    80000ab4:	00000097          	auipc	ra,0x0
    80000ab8:	276080e7          	jalr	630(ra) # 80000d2a <acquire>
    r->next = kmem.freelist;
    80000abc:	01893783          	ld	a5,24(s2)
    80000ac0:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000ac2:	00993c23          	sd	s1,24(s2)
    release(&kmem.lock);
    80000ac6:	854a                	mv	a0,s2
    80000ac8:	00000097          	auipc	ra,0x0
    80000acc:	316080e7          	jalr	790(ra) # 80000dde <release>
    80000ad0:	b745                	j	80000a70 <kfree+0x7a>

0000000080000ad2 <freerange>:
{
    80000ad2:	7139                	addi	sp,sp,-64
    80000ad4:	fc06                	sd	ra,56(sp)
    80000ad6:	f822                	sd	s0,48(sp)
    80000ad8:	f426                	sd	s1,40(sp)
    80000ada:	f04a                	sd	s2,32(sp)
    80000adc:	ec4e                	sd	s3,24(sp)
    80000ade:	e852                	sd	s4,16(sp)
    80000ae0:	e456                	sd	s5,8(sp)
    80000ae2:	e05a                	sd	s6,0(sp)
    80000ae4:	0080                	addi	s0,sp,64
    p = (char *)PGROUNDUP((uint64)pa_start);
    80000ae6:	6785                	lui	a5,0x1
    80000ae8:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000aec:	953a                	add	a0,a0,a4
    80000aee:	777d                	lui	a4,0xfffff
    80000af0:	00e574b3          	and	s1,a0,a4
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000af4:	97a6                	add	a5,a5,s1
    80000af6:	02f5ea63          	bltu	a1,a5,80000b2a <freerange+0x58>
    80000afa:	892e                	mv	s2,a1
        refcnt[(uint64)p / PGSIZE] = 1;
    80000afc:	00010b17          	auipc	s6,0x10
    80000b00:	1a4b0b13          	addi	s6,s6,420 # 80010ca0 <refcnt>
    80000b04:	4a85                	li	s5,1
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b06:	6a05                	lui	s4,0x1
    80000b08:	6989                	lui	s3,0x2
        refcnt[(uint64)p / PGSIZE] = 1;
    80000b0a:	00c4d793          	srli	a5,s1,0xc
    80000b0e:	078a                	slli	a5,a5,0x2
    80000b10:	97da                	add	a5,a5,s6
    80000b12:	0157a023          	sw	s5,0(a5)
        kfree(p);
    80000b16:	8526                	mv	a0,s1
    80000b18:	00000097          	auipc	ra,0x0
    80000b1c:	ede080e7          	jalr	-290(ra) # 800009f6 <kfree>
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b20:	87a6                	mv	a5,s1
    80000b22:	94d2                	add	s1,s1,s4
    80000b24:	97ce                	add	a5,a5,s3
    80000b26:	fef972e3          	bgeu	s2,a5,80000b0a <freerange+0x38>
}
    80000b2a:	70e2                	ld	ra,56(sp)
    80000b2c:	7442                	ld	s0,48(sp)
    80000b2e:	74a2                	ld	s1,40(sp)
    80000b30:	7902                	ld	s2,32(sp)
    80000b32:	69e2                	ld	s3,24(sp)
    80000b34:	6a42                	ld	s4,16(sp)
    80000b36:	6aa2                	ld	s5,8(sp)
    80000b38:	6b02                	ld	s6,0(sp)
    80000b3a:	6121                	addi	sp,sp,64
    80000b3c:	8082                	ret

0000000080000b3e <kinit>:
{
    80000b3e:	1141                	addi	sp,sp,-16
    80000b40:	e406                	sd	ra,8(sp)
    80000b42:	e022                	sd	s0,0(sp)
    80000b44:	0800                	addi	s0,sp,16
    initlock(&kmem.lock, "kmem");
    80000b46:	00007597          	auipc	a1,0x7
    80000b4a:	53258593          	addi	a1,a1,1330 # 80008078 <digits+0x38>
    80000b4e:	00010517          	auipc	a0,0x10
    80000b52:	13250513          	addi	a0,a0,306 # 80010c80 <kmem>
    80000b56:	00000097          	auipc	ra,0x0
    80000b5a:	144080e7          	jalr	324(ra) # 80000c9a <initlock>
    freerange(end, (void *)PHYSTOP);
    80000b5e:	45c5                	li	a1,17
    80000b60:	05ee                	slli	a1,a1,0x1b
    80000b62:	00241517          	auipc	a0,0x241
    80000b66:	34e50513          	addi	a0,a0,846 # 80241eb0 <end>
    80000b6a:	00000097          	auipc	ra,0x0
    80000b6e:	f68080e7          	jalr	-152(ra) # 80000ad2 <freerange>
    MAX_PAGES = FREE_PAGES;
    80000b72:	00008797          	auipc	a5,0x8
    80000b76:	e967b783          	ld	a5,-362(a5) # 80008a08 <FREE_PAGES>
    80000b7a:	00008717          	auipc	a4,0x8
    80000b7e:	e8f73b23          	sd	a5,-362(a4) # 80008a10 <MAX_PAGES>
}
    80000b82:	60a2                	ld	ra,8(sp)
    80000b84:	6402                	ld	s0,0(sp)
    80000b86:	0141                	addi	sp,sp,16
    80000b88:	8082                	ret

0000000080000b8a <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
    struct run *r;

    acquire(&kmem.lock);
    80000b94:	00010497          	auipc	s1,0x10
    80000b98:	0ec48493          	addi	s1,s1,236 # 80010c80 <kmem>
    80000b9c:	8526                	mv	a0,s1
    80000b9e:	00000097          	auipc	ra,0x0
    80000ba2:	18c080e7          	jalr	396(ra) # 80000d2a <acquire>
    r = kmem.freelist;
    80000ba6:	6c84                	ld	s1,24(s1)

    if (r) {
    80000ba8:	c4a5                	beqz	s1,80000c10 <kalloc+0x86>
        int pn = (uint64)r / PGSIZE;
    80000baa:	00c4d793          	srli	a5,s1,0xc
    80000bae:	2781                	sext.w	a5,a5
        if (refcnt[pn]) {
    80000bb0:	00279693          	slli	a3,a5,0x2
    80000bb4:	00010717          	auipc	a4,0x10
    80000bb8:	0ec70713          	addi	a4,a4,236 # 80010ca0 <refcnt>
    80000bbc:	9736                	add	a4,a4,a3
    80000bbe:	4318                	lw	a4,0(a4)
    80000bc0:	e321                	bnez	a4,80000c00 <kalloc+0x76>
            panic("refcnt kalloc");
        }
        kmem.freelist = r->next;
    80000bc2:	6098                	ld	a4,0(s1)
    80000bc4:	00010517          	auipc	a0,0x10
    80000bc8:	0bc50513          	addi	a0,a0,188 # 80010c80 <kmem>
    80000bcc:	ed18                	sd	a4,24(a0)
        refcnt[pn] = 1;
    80000bce:	078a                	slli	a5,a5,0x2
    80000bd0:	00010717          	auipc	a4,0x10
    80000bd4:	0d070713          	addi	a4,a4,208 # 80010ca0 <refcnt>
    80000bd8:	97ba                	add	a5,a5,a4
    80000bda:	4705                	li	a4,1
    80000bdc:	c398                	sw	a4,0(a5)
    }

    release(&kmem.lock);
    80000bde:	00000097          	auipc	ra,0x0
    80000be2:	200080e7          	jalr	512(ra) # 80000dde <release>

    if (r) 
        memset((char *)r, 5, PGSIZE); // fill with junk
    80000be6:	6605                	lui	a2,0x1
    80000be8:	4595                	li	a1,5
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	23a080e7          	jalr	570(ra) # 80000e26 <memset>
    
        
    return (void *)r;
}
    80000bf4:	8526                	mv	a0,s1
    80000bf6:	60e2                	ld	ra,24(sp)
    80000bf8:	6442                	ld	s0,16(sp)
    80000bfa:	64a2                	ld	s1,8(sp)
    80000bfc:	6105                	addi	sp,sp,32
    80000bfe:	8082                	ret
            panic("refcnt kalloc");
    80000c00:	00007517          	auipc	a0,0x7
    80000c04:	48050513          	addi	a0,a0,1152 # 80008080 <digits+0x40>
    80000c08:	00000097          	auipc	ra,0x0
    80000c0c:	934080e7          	jalr	-1740(ra) # 8000053c <panic>
    release(&kmem.lock);
    80000c10:	00010517          	auipc	a0,0x10
    80000c14:	07050513          	addi	a0,a0,112 # 80010c80 <kmem>
    80000c18:	00000097          	auipc	ra,0x0
    80000c1c:	1c6080e7          	jalr	454(ra) # 80000dde <release>
    if (r) 
    80000c20:	bfd1                	j	80000bf4 <kalloc+0x6a>

0000000080000c22 <inc>:

void inc(uint64 phyadr) {
    80000c22:	1101                	addi	sp,sp,-32
    80000c24:	ec06                	sd	ra,24(sp)
    80000c26:	e822                	sd	s0,16(sp)
    80000c28:	e426                	sd	s1,8(sp)
    80000c2a:	1000                	addi	s0,sp,32
    80000c2c:	84aa                	mv	s1,a0
    acquire(&kmem.lock);
    80000c2e:	00010517          	auipc	a0,0x10
    80000c32:	05250513          	addi	a0,a0,82 # 80010c80 <kmem>
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	0f4080e7          	jalr	244(ra) # 80000d2a <acquire>
    int pn = phyadr / PGSIZE;
    if (phyadr > PHYSTOP || refcnt[pn] < 1) {
    80000c3e:	4745                	li	a4,17
    80000c40:	076e                	slli	a4,a4,0x1b
    80000c42:	04976463          	bltu	a4,s1,80000c8a <inc+0x68>
    80000c46:	00c4d793          	srli	a5,s1,0xc
    80000c4a:	2781                	sext.w	a5,a5
    80000c4c:	00279693          	slli	a3,a5,0x2
    80000c50:	00010717          	auipc	a4,0x10
    80000c54:	05070713          	addi	a4,a4,80 # 80010ca0 <refcnt>
    80000c58:	9736                	add	a4,a4,a3
    80000c5a:	4318                	lw	a4,0(a4)
    80000c5c:	02e05763          	blez	a4,80000c8a <inc+0x68>
        panic("increase ref cnt");
    }
    refcnt[pn]++;
    80000c60:	078a                	slli	a5,a5,0x2
    80000c62:	00010697          	auipc	a3,0x10
    80000c66:	03e68693          	addi	a3,a3,62 # 80010ca0 <refcnt>
    80000c6a:	97b6                	add	a5,a5,a3
    80000c6c:	2705                	addiw	a4,a4,1
    80000c6e:	c398                	sw	a4,0(a5)
    release(&kmem.lock);
    80000c70:	00010517          	auipc	a0,0x10
    80000c74:	01050513          	addi	a0,a0,16 # 80010c80 <kmem>
    80000c78:	00000097          	auipc	ra,0x0
    80000c7c:	166080e7          	jalr	358(ra) # 80000dde <release>
}
    80000c80:	60e2                	ld	ra,24(sp)
    80000c82:	6442                	ld	s0,16(sp)
    80000c84:	64a2                	ld	s1,8(sp)
    80000c86:	6105                	addi	sp,sp,32
    80000c88:	8082                	ret
        panic("increase ref cnt");
    80000c8a:	00007517          	auipc	a0,0x7
    80000c8e:	40650513          	addi	a0,a0,1030 # 80008090 <digits+0x50>
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	8aa080e7          	jalr	-1878(ra) # 8000053c <panic>

0000000080000c9a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c9a:	1141                	addi	sp,sp,-16
    80000c9c:	e422                	sd	s0,8(sp)
    80000c9e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000ca0:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000ca2:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000ca6:	00053823          	sd	zero,16(a0)
}
    80000caa:	6422                	ld	s0,8(sp)
    80000cac:	0141                	addi	sp,sp,16
    80000cae:	8082                	ret

0000000080000cb0 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000cb0:	411c                	lw	a5,0(a0)
    80000cb2:	e399                	bnez	a5,80000cb8 <holding+0x8>
    80000cb4:	4501                	li	a0,0
  return r;
}
    80000cb6:	8082                	ret
{
    80000cb8:	1101                	addi	sp,sp,-32
    80000cba:	ec06                	sd	ra,24(sp)
    80000cbc:	e822                	sd	s0,16(sp)
    80000cbe:	e426                	sd	s1,8(sp)
    80000cc0:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000cc2:	6904                	ld	s1,16(a0)
    80000cc4:	00001097          	auipc	ra,0x1
    80000cc8:	f7c080e7          	jalr	-132(ra) # 80001c40 <mycpu>
    80000ccc:	40a48533          	sub	a0,s1,a0
    80000cd0:	00153513          	seqz	a0,a0
}
    80000cd4:	60e2                	ld	ra,24(sp)
    80000cd6:	6442                	ld	s0,16(sp)
    80000cd8:	64a2                	ld	s1,8(sp)
    80000cda:	6105                	addi	sp,sp,32
    80000cdc:	8082                	ret

0000000080000cde <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000cde:	1101                	addi	sp,sp,-32
    80000ce0:	ec06                	sd	ra,24(sp)
    80000ce2:	e822                	sd	s0,16(sp)
    80000ce4:	e426                	sd	s1,8(sp)
    80000ce6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ce8:	100024f3          	csrr	s1,sstatus
    80000cec:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cf0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cf2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cf6:	00001097          	auipc	ra,0x1
    80000cfa:	f4a080e7          	jalr	-182(ra) # 80001c40 <mycpu>
    80000cfe:	5d3c                	lw	a5,120(a0)
    80000d00:	cf89                	beqz	a5,80000d1a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d02:	00001097          	auipc	ra,0x1
    80000d06:	f3e080e7          	jalr	-194(ra) # 80001c40 <mycpu>
    80000d0a:	5d3c                	lw	a5,120(a0)
    80000d0c:	2785                	addiw	a5,a5,1
    80000d0e:	dd3c                	sw	a5,120(a0)
}
    80000d10:	60e2                	ld	ra,24(sp)
    80000d12:	6442                	ld	s0,16(sp)
    80000d14:	64a2                	ld	s1,8(sp)
    80000d16:	6105                	addi	sp,sp,32
    80000d18:	8082                	ret
    mycpu()->intena = old;
    80000d1a:	00001097          	auipc	ra,0x1
    80000d1e:	f26080e7          	jalr	-218(ra) # 80001c40 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d22:	8085                	srli	s1,s1,0x1
    80000d24:	8885                	andi	s1,s1,1
    80000d26:	dd64                	sw	s1,124(a0)
    80000d28:	bfe9                	j	80000d02 <push_off+0x24>

0000000080000d2a <acquire>:
{
    80000d2a:	1101                	addi	sp,sp,-32
    80000d2c:	ec06                	sd	ra,24(sp)
    80000d2e:	e822                	sd	s0,16(sp)
    80000d30:	e426                	sd	s1,8(sp)
    80000d32:	1000                	addi	s0,sp,32
    80000d34:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d36:	00000097          	auipc	ra,0x0
    80000d3a:	fa8080e7          	jalr	-88(ra) # 80000cde <push_off>
  if(holding(lk))
    80000d3e:	8526                	mv	a0,s1
    80000d40:	00000097          	auipc	ra,0x0
    80000d44:	f70080e7          	jalr	-144(ra) # 80000cb0 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d48:	4705                	li	a4,1
  if(holding(lk))
    80000d4a:	e115                	bnez	a0,80000d6e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d4c:	87ba                	mv	a5,a4
    80000d4e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d52:	2781                	sext.w	a5,a5
    80000d54:	ffe5                	bnez	a5,80000d4c <acquire+0x22>
  __sync_synchronize();
    80000d56:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d5a:	00001097          	auipc	ra,0x1
    80000d5e:	ee6080e7          	jalr	-282(ra) # 80001c40 <mycpu>
    80000d62:	e888                	sd	a0,16(s1)
}
    80000d64:	60e2                	ld	ra,24(sp)
    80000d66:	6442                	ld	s0,16(sp)
    80000d68:	64a2                	ld	s1,8(sp)
    80000d6a:	6105                	addi	sp,sp,32
    80000d6c:	8082                	ret
    panic("acquire");
    80000d6e:	00007517          	auipc	a0,0x7
    80000d72:	33a50513          	addi	a0,a0,826 # 800080a8 <digits+0x68>
    80000d76:	fffff097          	auipc	ra,0xfffff
    80000d7a:	7c6080e7          	jalr	1990(ra) # 8000053c <panic>

0000000080000d7e <pop_off>:

void
pop_off(void)
{
    80000d7e:	1141                	addi	sp,sp,-16
    80000d80:	e406                	sd	ra,8(sp)
    80000d82:	e022                	sd	s0,0(sp)
    80000d84:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d86:	00001097          	auipc	ra,0x1
    80000d8a:	eba080e7          	jalr	-326(ra) # 80001c40 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d8e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d92:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d94:	e78d                	bnez	a5,80000dbe <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d96:	5d3c                	lw	a5,120(a0)
    80000d98:	02f05b63          	blez	a5,80000dce <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d9c:	37fd                	addiw	a5,a5,-1
    80000d9e:	0007871b          	sext.w	a4,a5
    80000da2:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000da4:	eb09                	bnez	a4,80000db6 <pop_off+0x38>
    80000da6:	5d7c                	lw	a5,124(a0)
    80000da8:	c799                	beqz	a5,80000db6 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000daa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000dae:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000db2:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret
    panic("pop_off - interruptible");
    80000dbe:	00007517          	auipc	a0,0x7
    80000dc2:	2f250513          	addi	a0,a0,754 # 800080b0 <digits+0x70>
    80000dc6:	fffff097          	auipc	ra,0xfffff
    80000dca:	776080e7          	jalr	1910(ra) # 8000053c <panic>
    panic("pop_off");
    80000dce:	00007517          	auipc	a0,0x7
    80000dd2:	2fa50513          	addi	a0,a0,762 # 800080c8 <digits+0x88>
    80000dd6:	fffff097          	auipc	ra,0xfffff
    80000dda:	766080e7          	jalr	1894(ra) # 8000053c <panic>

0000000080000dde <release>:
{
    80000dde:	1101                	addi	sp,sp,-32
    80000de0:	ec06                	sd	ra,24(sp)
    80000de2:	e822                	sd	s0,16(sp)
    80000de4:	e426                	sd	s1,8(sp)
    80000de6:	1000                	addi	s0,sp,32
    80000de8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000dea:	00000097          	auipc	ra,0x0
    80000dee:	ec6080e7          	jalr	-314(ra) # 80000cb0 <holding>
    80000df2:	c115                	beqz	a0,80000e16 <release+0x38>
  lk->cpu = 0;
    80000df4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000df8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000dfc:	0f50000f          	fence	iorw,ow
    80000e00:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e04:	00000097          	auipc	ra,0x0
    80000e08:	f7a080e7          	jalr	-134(ra) # 80000d7e <pop_off>
}
    80000e0c:	60e2                	ld	ra,24(sp)
    80000e0e:	6442                	ld	s0,16(sp)
    80000e10:	64a2                	ld	s1,8(sp)
    80000e12:	6105                	addi	sp,sp,32
    80000e14:	8082                	ret
    panic("release");
    80000e16:	00007517          	auipc	a0,0x7
    80000e1a:	2ba50513          	addi	a0,a0,698 # 800080d0 <digits+0x90>
    80000e1e:	fffff097          	auipc	ra,0xfffff
    80000e22:	71e080e7          	jalr	1822(ra) # 8000053c <panic>

0000000080000e26 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e26:	1141                	addi	sp,sp,-16
    80000e28:	e422                	sd	s0,8(sp)
    80000e2a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e2c:	ca19                	beqz	a2,80000e42 <memset+0x1c>
    80000e2e:	87aa                	mv	a5,a0
    80000e30:	1602                	slli	a2,a2,0x20
    80000e32:	9201                	srli	a2,a2,0x20
    80000e34:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000e38:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e3c:	0785                	addi	a5,a5,1
    80000e3e:	fee79de3          	bne	a5,a4,80000e38 <memset+0x12>
  }
  return dst;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e4e:	ca05                	beqz	a2,80000e7e <memcmp+0x36>
    80000e50:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000e54:	1682                	slli	a3,a3,0x20
    80000e56:	9281                	srli	a3,a3,0x20
    80000e58:	0685                	addi	a3,a3,1
    80000e5a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e5c:	00054783          	lbu	a5,0(a0)
    80000e60:	0005c703          	lbu	a4,0(a1)
    80000e64:	00e79863          	bne	a5,a4,80000e74 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e68:	0505                	addi	a0,a0,1
    80000e6a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e6c:	fed518e3          	bne	a0,a3,80000e5c <memcmp+0x14>
  }

  return 0;
    80000e70:	4501                	li	a0,0
    80000e72:	a019                	j	80000e78 <memcmp+0x30>
      return *s1 - *s2;
    80000e74:	40e7853b          	subw	a0,a5,a4
}
    80000e78:	6422                	ld	s0,8(sp)
    80000e7a:	0141                	addi	sp,sp,16
    80000e7c:	8082                	ret
  return 0;
    80000e7e:	4501                	li	a0,0
    80000e80:	bfe5                	j	80000e78 <memcmp+0x30>

0000000080000e82 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e82:	1141                	addi	sp,sp,-16
    80000e84:	e422                	sd	s0,8(sp)
    80000e86:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e88:	c205                	beqz	a2,80000ea8 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e8a:	02a5e263          	bltu	a1,a0,80000eae <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e8e:	1602                	slli	a2,a2,0x20
    80000e90:	9201                	srli	a2,a2,0x20
    80000e92:	00c587b3          	add	a5,a1,a2
{
    80000e96:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e98:	0585                	addi	a1,a1,1
    80000e9a:	0705                	addi	a4,a4,1
    80000e9c:	fff5c683          	lbu	a3,-1(a1)
    80000ea0:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000ea4:	fef59ae3          	bne	a1,a5,80000e98 <memmove+0x16>

  return dst;
}
    80000ea8:	6422                	ld	s0,8(sp)
    80000eaa:	0141                	addi	sp,sp,16
    80000eac:	8082                	ret
  if(s < d && s + n > d){
    80000eae:	02061693          	slli	a3,a2,0x20
    80000eb2:	9281                	srli	a3,a3,0x20
    80000eb4:	00d58733          	add	a4,a1,a3
    80000eb8:	fce57be3          	bgeu	a0,a4,80000e8e <memmove+0xc>
    d += n;
    80000ebc:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000ebe:	fff6079b          	addiw	a5,a2,-1
    80000ec2:	1782                	slli	a5,a5,0x20
    80000ec4:	9381                	srli	a5,a5,0x20
    80000ec6:	fff7c793          	not	a5,a5
    80000eca:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000ecc:	177d                	addi	a4,a4,-1
    80000ece:	16fd                	addi	a3,a3,-1
    80000ed0:	00074603          	lbu	a2,0(a4)
    80000ed4:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000ed8:	fee79ae3          	bne	a5,a4,80000ecc <memmove+0x4a>
    80000edc:	b7f1                	j	80000ea8 <memmove+0x26>

0000000080000ede <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000ede:	1141                	addi	sp,sp,-16
    80000ee0:	e406                	sd	ra,8(sp)
    80000ee2:	e022                	sd	s0,0(sp)
    80000ee4:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000ee6:	00000097          	auipc	ra,0x0
    80000eea:	f9c080e7          	jalr	-100(ra) # 80000e82 <memmove>
}
    80000eee:	60a2                	ld	ra,8(sp)
    80000ef0:	6402                	ld	s0,0(sp)
    80000ef2:	0141                	addi	sp,sp,16
    80000ef4:	8082                	ret

0000000080000ef6 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000ef6:	1141                	addi	sp,sp,-16
    80000ef8:	e422                	sd	s0,8(sp)
    80000efa:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000efc:	ce11                	beqz	a2,80000f18 <strncmp+0x22>
    80000efe:	00054783          	lbu	a5,0(a0)
    80000f02:	cf89                	beqz	a5,80000f1c <strncmp+0x26>
    80000f04:	0005c703          	lbu	a4,0(a1)
    80000f08:	00f71a63          	bne	a4,a5,80000f1c <strncmp+0x26>
    n--, p++, q++;
    80000f0c:	367d                	addiw	a2,a2,-1
    80000f0e:	0505                	addi	a0,a0,1
    80000f10:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f12:	f675                	bnez	a2,80000efe <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f14:	4501                	li	a0,0
    80000f16:	a809                	j	80000f28 <strncmp+0x32>
    80000f18:	4501                	li	a0,0
    80000f1a:	a039                	j	80000f28 <strncmp+0x32>
  if(n == 0)
    80000f1c:	ca09                	beqz	a2,80000f2e <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f1e:	00054503          	lbu	a0,0(a0)
    80000f22:	0005c783          	lbu	a5,0(a1)
    80000f26:	9d1d                	subw	a0,a0,a5
}
    80000f28:	6422                	ld	s0,8(sp)
    80000f2a:	0141                	addi	sp,sp,16
    80000f2c:	8082                	ret
    return 0;
    80000f2e:	4501                	li	a0,0
    80000f30:	bfe5                	j	80000f28 <strncmp+0x32>

0000000080000f32 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f32:	1141                	addi	sp,sp,-16
    80000f34:	e422                	sd	s0,8(sp)
    80000f36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f38:	87aa                	mv	a5,a0
    80000f3a:	86b2                	mv	a3,a2
    80000f3c:	367d                	addiw	a2,a2,-1
    80000f3e:	00d05963          	blez	a3,80000f50 <strncpy+0x1e>
    80000f42:	0785                	addi	a5,a5,1
    80000f44:	0005c703          	lbu	a4,0(a1)
    80000f48:	fee78fa3          	sb	a4,-1(a5)
    80000f4c:	0585                	addi	a1,a1,1
    80000f4e:	f775                	bnez	a4,80000f3a <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f50:	873e                	mv	a4,a5
    80000f52:	9fb5                	addw	a5,a5,a3
    80000f54:	37fd                	addiw	a5,a5,-1
    80000f56:	00c05963          	blez	a2,80000f68 <strncpy+0x36>
    *s++ = 0;
    80000f5a:	0705                	addi	a4,a4,1
    80000f5c:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000f60:	40e786bb          	subw	a3,a5,a4
    80000f64:	fed04be3          	bgtz	a3,80000f5a <strncpy+0x28>
  return os;
}
    80000f68:	6422                	ld	s0,8(sp)
    80000f6a:	0141                	addi	sp,sp,16
    80000f6c:	8082                	ret

0000000080000f6e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f6e:	1141                	addi	sp,sp,-16
    80000f70:	e422                	sd	s0,8(sp)
    80000f72:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f74:	02c05363          	blez	a2,80000f9a <safestrcpy+0x2c>
    80000f78:	fff6069b          	addiw	a3,a2,-1
    80000f7c:	1682                	slli	a3,a3,0x20
    80000f7e:	9281                	srli	a3,a3,0x20
    80000f80:	96ae                	add	a3,a3,a1
    80000f82:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f84:	00d58963          	beq	a1,a3,80000f96 <safestrcpy+0x28>
    80000f88:	0585                	addi	a1,a1,1
    80000f8a:	0785                	addi	a5,a5,1
    80000f8c:	fff5c703          	lbu	a4,-1(a1)
    80000f90:	fee78fa3          	sb	a4,-1(a5)
    80000f94:	fb65                	bnez	a4,80000f84 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f96:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f9a:	6422                	ld	s0,8(sp)
    80000f9c:	0141                	addi	sp,sp,16
    80000f9e:	8082                	ret

0000000080000fa0 <strlen>:

int
strlen(const char *s)
{
    80000fa0:	1141                	addi	sp,sp,-16
    80000fa2:	e422                	sd	s0,8(sp)
    80000fa4:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000fa6:	00054783          	lbu	a5,0(a0)
    80000faa:	cf91                	beqz	a5,80000fc6 <strlen+0x26>
    80000fac:	0505                	addi	a0,a0,1
    80000fae:	87aa                	mv	a5,a0
    80000fb0:	86be                	mv	a3,a5
    80000fb2:	0785                	addi	a5,a5,1
    80000fb4:	fff7c703          	lbu	a4,-1(a5)
    80000fb8:	ff65                	bnez	a4,80000fb0 <strlen+0x10>
    80000fba:	40a6853b          	subw	a0,a3,a0
    80000fbe:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000fc0:	6422                	ld	s0,8(sp)
    80000fc2:	0141                	addi	sp,sp,16
    80000fc4:	8082                	ret
  for(n = 0; s[n]; n++)
    80000fc6:	4501                	li	a0,0
    80000fc8:	bfe5                	j	80000fc0 <strlen+0x20>

0000000080000fca <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000fca:	1141                	addi	sp,sp,-16
    80000fcc:	e406                	sd	ra,8(sp)
    80000fce:	e022                	sd	s0,0(sp)
    80000fd0:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000fd2:	00001097          	auipc	ra,0x1
    80000fd6:	c5e080e7          	jalr	-930(ra) # 80001c30 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000fda:	00008717          	auipc	a4,0x8
    80000fde:	a3e70713          	addi	a4,a4,-1474 # 80008a18 <started>
  if(cpuid() == 0){
    80000fe2:	c139                	beqz	a0,80001028 <main+0x5e>
    while(started == 0)
    80000fe4:	431c                	lw	a5,0(a4)
    80000fe6:	2781                	sext.w	a5,a5
    80000fe8:	dff5                	beqz	a5,80000fe4 <main+0x1a>
      ;
    __sync_synchronize();
    80000fea:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000fee:	00001097          	auipc	ra,0x1
    80000ff2:	c42080e7          	jalr	-958(ra) # 80001c30 <cpuid>
    80000ff6:	85aa                	mv	a1,a0
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0f850513          	addi	a0,a0,248 # 800080f0 <digits+0xb0>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	598080e7          	jalr	1432(ra) # 80000598 <printf>
    kvminithart();    // turn on paging
    80001008:	00000097          	auipc	ra,0x0
    8000100c:	0d8080e7          	jalr	216(ra) # 800010e0 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001010:	00002097          	auipc	ra,0x2
    80001014:	aec080e7          	jalr	-1300(ra) # 80002afc <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001018:	00005097          	auipc	ra,0x5
    8000101c:	188080e7          	jalr	392(ra) # 800061a0 <plicinithart>
  }

  scheduler();        
    80001020:	00001097          	auipc	ra,0x1
    80001024:	282080e7          	jalr	642(ra) # 800022a2 <scheduler>
    consoleinit();
    80001028:	fffff097          	auipc	ra,0xfffff
    8000102c:	424080e7          	jalr	1060(ra) # 8000044c <consoleinit>
    printfinit();
    80001030:	fffff097          	auipc	ra,0xfffff
    80001034:	748080e7          	jalr	1864(ra) # 80000778 <printfinit>
    printf("\n");
    80001038:	00007517          	auipc	a0,0x7
    8000103c:	0c850513          	addi	a0,a0,200 # 80008100 <digits+0xc0>
    80001040:	fffff097          	auipc	ra,0xfffff
    80001044:	558080e7          	jalr	1368(ra) # 80000598 <printf>
    printf("xv6 kernel is booting\n");
    80001048:	00007517          	auipc	a0,0x7
    8000104c:	09050513          	addi	a0,a0,144 # 800080d8 <digits+0x98>
    80001050:	fffff097          	auipc	ra,0xfffff
    80001054:	548080e7          	jalr	1352(ra) # 80000598 <printf>
    printf("\n");
    80001058:	00007517          	auipc	a0,0x7
    8000105c:	0a850513          	addi	a0,a0,168 # 80008100 <digits+0xc0>
    80001060:	fffff097          	auipc	ra,0xfffff
    80001064:	538080e7          	jalr	1336(ra) # 80000598 <printf>
    kinit();         // physical page allocator
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	ad6080e7          	jalr	-1322(ra) # 80000b3e <kinit>
    kvminit();       // create kernel page table
    80001070:	00000097          	auipc	ra,0x0
    80001074:	326080e7          	jalr	806(ra) # 80001396 <kvminit>
    kvminithart();   // turn on paging
    80001078:	00000097          	auipc	ra,0x0
    8000107c:	068080e7          	jalr	104(ra) # 800010e0 <kvminithart>
    procinit();      // process table
    80001080:	00001097          	auipc	ra,0x1
    80001084:	ad8080e7          	jalr	-1320(ra) # 80001b58 <procinit>
    trapinit();      // trap vectors
    80001088:	00002097          	auipc	ra,0x2
    8000108c:	a4c080e7          	jalr	-1460(ra) # 80002ad4 <trapinit>
    trapinithart();  // install kernel trap vector
    80001090:	00002097          	auipc	ra,0x2
    80001094:	a6c080e7          	jalr	-1428(ra) # 80002afc <trapinithart>
    plicinit();      // set up interrupt controller
    80001098:	00005097          	auipc	ra,0x5
    8000109c:	0f2080e7          	jalr	242(ra) # 8000618a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800010a0:	00005097          	auipc	ra,0x5
    800010a4:	100080e7          	jalr	256(ra) # 800061a0 <plicinithart>
    binit();         // buffer cache
    800010a8:	00002097          	auipc	ra,0x2
    800010ac:	2f6080e7          	jalr	758(ra) # 8000339e <binit>
    iinit();         // inode table
    800010b0:	00003097          	auipc	ra,0x3
    800010b4:	994080e7          	jalr	-1644(ra) # 80003a44 <iinit>
    fileinit();      // file table
    800010b8:	00004097          	auipc	ra,0x4
    800010bc:	90a080e7          	jalr	-1782(ra) # 800049c2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010c0:	00005097          	auipc	ra,0x5
    800010c4:	1e8080e7          	jalr	488(ra) # 800062a8 <virtio_disk_init>
    userinit();      // first user process
    800010c8:	00001097          	auipc	ra,0x1
    800010cc:	e6c080e7          	jalr	-404(ra) # 80001f34 <userinit>
    __sync_synchronize();
    800010d0:	0ff0000f          	fence
    started = 1;
    800010d4:	4785                	li	a5,1
    800010d6:	00008717          	auipc	a4,0x8
    800010da:	94f72123          	sw	a5,-1726(a4) # 80008a18 <started>
    800010de:	b789                	j	80001020 <main+0x56>

00000000800010e0 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010e0:	1141                	addi	sp,sp,-16
    800010e2:	e422                	sd	s0,8(sp)
    800010e4:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010e6:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    800010ea:	00008797          	auipc	a5,0x8
    800010ee:	9367b783          	ld	a5,-1738(a5) # 80008a20 <kernel_pagetable>
    800010f2:	83b1                	srli	a5,a5,0xc
    800010f4:	577d                	li	a4,-1
    800010f6:	177e                	slli	a4,a4,0x3f
    800010f8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010fa:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800010fe:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001102:	6422                	ld	s0,8(sp)
    80001104:	0141                	addi	sp,sp,16
    80001106:	8082                	ret

0000000080001108 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001108:	7139                	addi	sp,sp,-64
    8000110a:	fc06                	sd	ra,56(sp)
    8000110c:	f822                	sd	s0,48(sp)
    8000110e:	f426                	sd	s1,40(sp)
    80001110:	f04a                	sd	s2,32(sp)
    80001112:	ec4e                	sd	s3,24(sp)
    80001114:	e852                	sd	s4,16(sp)
    80001116:	e456                	sd	s5,8(sp)
    80001118:	e05a                	sd	s6,0(sp)
    8000111a:	0080                	addi	s0,sp,64
    8000111c:	84aa                	mv	s1,a0
    8000111e:	89ae                	mv	s3,a1
    80001120:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001122:	57fd                	li	a5,-1
    80001124:	83e9                	srli	a5,a5,0x1a
    80001126:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001128:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000112a:	04b7f263          	bgeu	a5,a1,8000116e <walk+0x66>
    panic("walk");
    8000112e:	00007517          	auipc	a0,0x7
    80001132:	fda50513          	addi	a0,a0,-38 # 80008108 <digits+0xc8>
    80001136:	fffff097          	auipc	ra,0xfffff
    8000113a:	406080e7          	jalr	1030(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000113e:	060a8663          	beqz	s5,800011aa <walk+0xa2>
    80001142:	00000097          	auipc	ra,0x0
    80001146:	a48080e7          	jalr	-1464(ra) # 80000b8a <kalloc>
    8000114a:	84aa                	mv	s1,a0
    8000114c:	c529                	beqz	a0,80001196 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000114e:	6605                	lui	a2,0x1
    80001150:	4581                	li	a1,0
    80001152:	00000097          	auipc	ra,0x0
    80001156:	cd4080e7          	jalr	-812(ra) # 80000e26 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000115a:	00c4d793          	srli	a5,s1,0xc
    8000115e:	07aa                	slli	a5,a5,0xa
    80001160:	0017e793          	ori	a5,a5,1
    80001164:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001168:	3a5d                	addiw	s4,s4,-9 # ff7 <_entry-0x7ffff009>
    8000116a:	036a0063          	beq	s4,s6,8000118a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000116e:	0149d933          	srl	s2,s3,s4
    80001172:	1ff97913          	andi	s2,s2,511
    80001176:	090e                	slli	s2,s2,0x3
    80001178:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000117a:	00093483          	ld	s1,0(s2)
    8000117e:	0014f793          	andi	a5,s1,1
    80001182:	dfd5                	beqz	a5,8000113e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001184:	80a9                	srli	s1,s1,0xa
    80001186:	04b2                	slli	s1,s1,0xc
    80001188:	b7c5                	j	80001168 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000118a:	00c9d513          	srli	a0,s3,0xc
    8000118e:	1ff57513          	andi	a0,a0,511
    80001192:	050e                	slli	a0,a0,0x3
    80001194:	9526                	add	a0,a0,s1
}
    80001196:	70e2                	ld	ra,56(sp)
    80001198:	7442                	ld	s0,48(sp)
    8000119a:	74a2                	ld	s1,40(sp)
    8000119c:	7902                	ld	s2,32(sp)
    8000119e:	69e2                	ld	s3,24(sp)
    800011a0:	6a42                	ld	s4,16(sp)
    800011a2:	6aa2                	ld	s5,8(sp)
    800011a4:	6b02                	ld	s6,0(sp)
    800011a6:	6121                	addi	sp,sp,64
    800011a8:	8082                	ret
        return 0;
    800011aa:	4501                	li	a0,0
    800011ac:	b7ed                	j	80001196 <walk+0x8e>

00000000800011ae <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800011ae:	57fd                	li	a5,-1
    800011b0:	83e9                	srli	a5,a5,0x1a
    800011b2:	00b7f463          	bgeu	a5,a1,800011ba <walkaddr+0xc>
    return 0;
    800011b6:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800011b8:	8082                	ret
{
    800011ba:	1141                	addi	sp,sp,-16
    800011bc:	e406                	sd	ra,8(sp)
    800011be:	e022                	sd	s0,0(sp)
    800011c0:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011c2:	4601                	li	a2,0
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	f44080e7          	jalr	-188(ra) # 80001108 <walk>
  if(pte == 0)
    800011cc:	c105                	beqz	a0,800011ec <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800011ce:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800011d0:	0117f693          	andi	a3,a5,17
    800011d4:	4745                	li	a4,17
    return 0;
    800011d6:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011d8:	00e68663          	beq	a3,a4,800011e4 <walkaddr+0x36>
}
    800011dc:	60a2                	ld	ra,8(sp)
    800011de:	6402                	ld	s0,0(sp)
    800011e0:	0141                	addi	sp,sp,16
    800011e2:	8082                	ret
  pa = PTE2PA(*pte);
    800011e4:	83a9                	srli	a5,a5,0xa
    800011e6:	00c79513          	slli	a0,a5,0xc
  return pa;
    800011ea:	bfcd                	j	800011dc <walkaddr+0x2e>
    return 0;
    800011ec:	4501                	li	a0,0
    800011ee:	b7fd                	j	800011dc <walkaddr+0x2e>

00000000800011f0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011f0:	715d                	addi	sp,sp,-80
    800011f2:	e486                	sd	ra,72(sp)
    800011f4:	e0a2                	sd	s0,64(sp)
    800011f6:	fc26                	sd	s1,56(sp)
    800011f8:	f84a                	sd	s2,48(sp)
    800011fa:	f44e                	sd	s3,40(sp)
    800011fc:	f052                	sd	s4,32(sp)
    800011fe:	ec56                	sd	s5,24(sp)
    80001200:	e85a                	sd	s6,16(sp)
    80001202:	e45e                	sd	s7,8(sp)
    80001204:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001206:	c639                	beqz	a2,80001254 <mappages+0x64>
    80001208:	8aaa                	mv	s5,a0
    8000120a:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    8000120c:	777d                	lui	a4,0xfffff
    8000120e:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001212:	fff58993          	addi	s3,a1,-1
    80001216:	99b2                	add	s3,s3,a2
    80001218:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000121c:	893e                	mv	s2,a5
    8000121e:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001222:	6b85                	lui	s7,0x1
    80001224:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001228:	4605                	li	a2,1
    8000122a:	85ca                	mv	a1,s2
    8000122c:	8556                	mv	a0,s5
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	eda080e7          	jalr	-294(ra) # 80001108 <walk>
    80001236:	cd1d                	beqz	a0,80001274 <mappages+0x84>
    if(*pte & PTE_V)
    80001238:	611c                	ld	a5,0(a0)
    8000123a:	8b85                	andi	a5,a5,1
    8000123c:	e785                	bnez	a5,80001264 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000123e:	80b1                	srli	s1,s1,0xc
    80001240:	04aa                	slli	s1,s1,0xa
    80001242:	0164e4b3          	or	s1,s1,s6
    80001246:	0014e493          	ori	s1,s1,1
    8000124a:	e104                	sd	s1,0(a0)
    if(a == last)
    8000124c:	05390063          	beq	s2,s3,8000128c <mappages+0x9c>
    a += PGSIZE;
    80001250:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001252:	bfc9                	j	80001224 <mappages+0x34>
    panic("mappages: size");
    80001254:	00007517          	auipc	a0,0x7
    80001258:	ebc50513          	addi	a0,a0,-324 # 80008110 <digits+0xd0>
    8000125c:	fffff097          	auipc	ra,0xfffff
    80001260:	2e0080e7          	jalr	736(ra) # 8000053c <panic>
      panic("mappages: remap");
    80001264:	00007517          	auipc	a0,0x7
    80001268:	ebc50513          	addi	a0,a0,-324 # 80008120 <digits+0xe0>
    8000126c:	fffff097          	auipc	ra,0xfffff
    80001270:	2d0080e7          	jalr	720(ra) # 8000053c <panic>
      return -1;
    80001274:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001276:	60a6                	ld	ra,72(sp)
    80001278:	6406                	ld	s0,64(sp)
    8000127a:	74e2                	ld	s1,56(sp)
    8000127c:	7942                	ld	s2,48(sp)
    8000127e:	79a2                	ld	s3,40(sp)
    80001280:	7a02                	ld	s4,32(sp)
    80001282:	6ae2                	ld	s5,24(sp)
    80001284:	6b42                	ld	s6,16(sp)
    80001286:	6ba2                	ld	s7,8(sp)
    80001288:	6161                	addi	sp,sp,80
    8000128a:	8082                	ret
  return 0;
    8000128c:	4501                	li	a0,0
    8000128e:	b7e5                	j	80001276 <mappages+0x86>

0000000080001290 <kvmmap>:
{
    80001290:	1141                	addi	sp,sp,-16
    80001292:	e406                	sd	ra,8(sp)
    80001294:	e022                	sd	s0,0(sp)
    80001296:	0800                	addi	s0,sp,16
    80001298:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000129a:	86b2                	mv	a3,a2
    8000129c:	863e                	mv	a2,a5
    8000129e:	00000097          	auipc	ra,0x0
    800012a2:	f52080e7          	jalr	-174(ra) # 800011f0 <mappages>
    800012a6:	e509                	bnez	a0,800012b0 <kvmmap+0x20>
}
    800012a8:	60a2                	ld	ra,8(sp)
    800012aa:	6402                	ld	s0,0(sp)
    800012ac:	0141                	addi	sp,sp,16
    800012ae:	8082                	ret
    panic("kvmmap");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e8050513          	addi	a0,a0,-384 # 80008130 <digits+0xf0>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	284080e7          	jalr	644(ra) # 8000053c <panic>

00000000800012c0 <kvmmake>:
{
    800012c0:	1101                	addi	sp,sp,-32
    800012c2:	ec06                	sd	ra,24(sp)
    800012c4:	e822                	sd	s0,16(sp)
    800012c6:	e426                	sd	s1,8(sp)
    800012c8:	e04a                	sd	s2,0(sp)
    800012ca:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800012cc:	00000097          	auipc	ra,0x0
    800012d0:	8be080e7          	jalr	-1858(ra) # 80000b8a <kalloc>
    800012d4:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800012d6:	6605                	lui	a2,0x1
    800012d8:	4581                	li	a1,0
    800012da:	00000097          	auipc	ra,0x0
    800012de:	b4c080e7          	jalr	-1204(ra) # 80000e26 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012e2:	4719                	li	a4,6
    800012e4:	6685                	lui	a3,0x1
    800012e6:	10000637          	lui	a2,0x10000
    800012ea:	100005b7          	lui	a1,0x10000
    800012ee:	8526                	mv	a0,s1
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	fa0080e7          	jalr	-96(ra) # 80001290 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012f8:	4719                	li	a4,6
    800012fa:	6685                	lui	a3,0x1
    800012fc:	10001637          	lui	a2,0x10001
    80001300:	100015b7          	lui	a1,0x10001
    80001304:	8526                	mv	a0,s1
    80001306:	00000097          	auipc	ra,0x0
    8000130a:	f8a080e7          	jalr	-118(ra) # 80001290 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000130e:	4719                	li	a4,6
    80001310:	004006b7          	lui	a3,0x400
    80001314:	0c000637          	lui	a2,0xc000
    80001318:	0c0005b7          	lui	a1,0xc000
    8000131c:	8526                	mv	a0,s1
    8000131e:	00000097          	auipc	ra,0x0
    80001322:	f72080e7          	jalr	-142(ra) # 80001290 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001326:	00007917          	auipc	s2,0x7
    8000132a:	cda90913          	addi	s2,s2,-806 # 80008000 <etext>
    8000132e:	4729                	li	a4,10
    80001330:	80007697          	auipc	a3,0x80007
    80001334:	cd068693          	addi	a3,a3,-816 # 8000 <_entry-0x7fff8000>
    80001338:	4605                	li	a2,1
    8000133a:	067e                	slli	a2,a2,0x1f
    8000133c:	85b2                	mv	a1,a2
    8000133e:	8526                	mv	a0,s1
    80001340:	00000097          	auipc	ra,0x0
    80001344:	f50080e7          	jalr	-176(ra) # 80001290 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001348:	4719                	li	a4,6
    8000134a:	46c5                	li	a3,17
    8000134c:	06ee                	slli	a3,a3,0x1b
    8000134e:	412686b3          	sub	a3,a3,s2
    80001352:	864a                	mv	a2,s2
    80001354:	85ca                	mv	a1,s2
    80001356:	8526                	mv	a0,s1
    80001358:	00000097          	auipc	ra,0x0
    8000135c:	f38080e7          	jalr	-200(ra) # 80001290 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001360:	4729                	li	a4,10
    80001362:	6685                	lui	a3,0x1
    80001364:	00006617          	auipc	a2,0x6
    80001368:	c9c60613          	addi	a2,a2,-868 # 80007000 <_trampoline>
    8000136c:	040005b7          	lui	a1,0x4000
    80001370:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001372:	05b2                	slli	a1,a1,0xc
    80001374:	8526                	mv	a0,s1
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	f1a080e7          	jalr	-230(ra) # 80001290 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000137e:	8526                	mv	a0,s1
    80001380:	00000097          	auipc	ra,0x0
    80001384:	742080e7          	jalr	1858(ra) # 80001ac2 <proc_mapstacks>
}
    80001388:	8526                	mv	a0,s1
    8000138a:	60e2                	ld	ra,24(sp)
    8000138c:	6442                	ld	s0,16(sp)
    8000138e:	64a2                	ld	s1,8(sp)
    80001390:	6902                	ld	s2,0(sp)
    80001392:	6105                	addi	sp,sp,32
    80001394:	8082                	ret

0000000080001396 <kvminit>:
{
    80001396:	1141                	addi	sp,sp,-16
    80001398:	e406                	sd	ra,8(sp)
    8000139a:	e022                	sd	s0,0(sp)
    8000139c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000139e:	00000097          	auipc	ra,0x0
    800013a2:	f22080e7          	jalr	-222(ra) # 800012c0 <kvmmake>
    800013a6:	00007797          	auipc	a5,0x7
    800013aa:	66a7bd23          	sd	a0,1658(a5) # 80008a20 <kernel_pagetable>
}
    800013ae:	60a2                	ld	ra,8(sp)
    800013b0:	6402                	ld	s0,0(sp)
    800013b2:	0141                	addi	sp,sp,16
    800013b4:	8082                	ret

00000000800013b6 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013b6:	715d                	addi	sp,sp,-80
    800013b8:	e486                	sd	ra,72(sp)
    800013ba:	e0a2                	sd	s0,64(sp)
    800013bc:	fc26                	sd	s1,56(sp)
    800013be:	f84a                	sd	s2,48(sp)
    800013c0:	f44e                	sd	s3,40(sp)
    800013c2:	f052                	sd	s4,32(sp)
    800013c4:	ec56                	sd	s5,24(sp)
    800013c6:	e85a                	sd	s6,16(sp)
    800013c8:	e45e                	sd	s7,8(sp)
    800013ca:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013cc:	03459793          	slli	a5,a1,0x34
    800013d0:	e795                	bnez	a5,800013fc <uvmunmap+0x46>
    800013d2:	8a2a                	mv	s4,a0
    800013d4:	892e                	mv	s2,a1
    800013d6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013d8:	0632                	slli	a2,a2,0xc
    800013da:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800013de:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013e0:	6b05                	lui	s6,0x1
    800013e2:	0735e263          	bltu	a1,s3,80001446 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013e6:	60a6                	ld	ra,72(sp)
    800013e8:	6406                	ld	s0,64(sp)
    800013ea:	74e2                	ld	s1,56(sp)
    800013ec:	7942                	ld	s2,48(sp)
    800013ee:	79a2                	ld	s3,40(sp)
    800013f0:	7a02                	ld	s4,32(sp)
    800013f2:	6ae2                	ld	s5,24(sp)
    800013f4:	6b42                	ld	s6,16(sp)
    800013f6:	6ba2                	ld	s7,8(sp)
    800013f8:	6161                	addi	sp,sp,80
    800013fa:	8082                	ret
    panic("uvmunmap: not aligned");
    800013fc:	00007517          	auipc	a0,0x7
    80001400:	d3c50513          	addi	a0,a0,-708 # 80008138 <digits+0xf8>
    80001404:	fffff097          	auipc	ra,0xfffff
    80001408:	138080e7          	jalr	312(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    8000140c:	00007517          	auipc	a0,0x7
    80001410:	d4450513          	addi	a0,a0,-700 # 80008150 <digits+0x110>
    80001414:	fffff097          	auipc	ra,0xfffff
    80001418:	128080e7          	jalr	296(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    8000141c:	00007517          	auipc	a0,0x7
    80001420:	d4450513          	addi	a0,a0,-700 # 80008160 <digits+0x120>
    80001424:	fffff097          	auipc	ra,0xfffff
    80001428:	118080e7          	jalr	280(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    8000142c:	00007517          	auipc	a0,0x7
    80001430:	d4c50513          	addi	a0,a0,-692 # 80008178 <digits+0x138>
    80001434:	fffff097          	auipc	ra,0xfffff
    80001438:	108080e7          	jalr	264(ra) # 8000053c <panic>
    *pte = 0;
    8000143c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001440:	995a                	add	s2,s2,s6
    80001442:	fb3972e3          	bgeu	s2,s3,800013e6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001446:	4601                	li	a2,0
    80001448:	85ca                	mv	a1,s2
    8000144a:	8552                	mv	a0,s4
    8000144c:	00000097          	auipc	ra,0x0
    80001450:	cbc080e7          	jalr	-836(ra) # 80001108 <walk>
    80001454:	84aa                	mv	s1,a0
    80001456:	d95d                	beqz	a0,8000140c <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001458:	6108                	ld	a0,0(a0)
    8000145a:	00157793          	andi	a5,a0,1
    8000145e:	dfdd                	beqz	a5,8000141c <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001460:	3ff57793          	andi	a5,a0,1023
    80001464:	fd7784e3          	beq	a5,s7,8000142c <uvmunmap+0x76>
    if(do_free){
    80001468:	fc0a8ae3          	beqz	s5,8000143c <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000146c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000146e:	0532                	slli	a0,a0,0xc
    80001470:	fffff097          	auipc	ra,0xfffff
    80001474:	586080e7          	jalr	1414(ra) # 800009f6 <kfree>
    80001478:	b7d1                	j	8000143c <uvmunmap+0x86>

000000008000147a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000147a:	1101                	addi	sp,sp,-32
    8000147c:	ec06                	sd	ra,24(sp)
    8000147e:	e822                	sd	s0,16(sp)
    80001480:	e426                	sd	s1,8(sp)
    80001482:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001484:	fffff097          	auipc	ra,0xfffff
    80001488:	706080e7          	jalr	1798(ra) # 80000b8a <kalloc>
    8000148c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000148e:	c519                	beqz	a0,8000149c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001490:	6605                	lui	a2,0x1
    80001492:	4581                	li	a1,0
    80001494:	00000097          	auipc	ra,0x0
    80001498:	992080e7          	jalr	-1646(ra) # 80000e26 <memset>
  return pagetable;
}
    8000149c:	8526                	mv	a0,s1
    8000149e:	60e2                	ld	ra,24(sp)
    800014a0:	6442                	ld	s0,16(sp)
    800014a2:	64a2                	ld	s1,8(sp)
    800014a4:	6105                	addi	sp,sp,32
    800014a6:	8082                	ret

00000000800014a8 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800014a8:	7179                	addi	sp,sp,-48
    800014aa:	f406                	sd	ra,40(sp)
    800014ac:	f022                	sd	s0,32(sp)
    800014ae:	ec26                	sd	s1,24(sp)
    800014b0:	e84a                	sd	s2,16(sp)
    800014b2:	e44e                	sd	s3,8(sp)
    800014b4:	e052                	sd	s4,0(sp)
    800014b6:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800014b8:	6785                	lui	a5,0x1
    800014ba:	04f67863          	bgeu	a2,a5,8000150a <uvmfirst+0x62>
    800014be:	8a2a                	mv	s4,a0
    800014c0:	89ae                	mv	s3,a1
    800014c2:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800014c4:	fffff097          	auipc	ra,0xfffff
    800014c8:	6c6080e7          	jalr	1734(ra) # 80000b8a <kalloc>
    800014cc:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014ce:	6605                	lui	a2,0x1
    800014d0:	4581                	li	a1,0
    800014d2:	00000097          	auipc	ra,0x0
    800014d6:	954080e7          	jalr	-1708(ra) # 80000e26 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014da:	4779                	li	a4,30
    800014dc:	86ca                	mv	a3,s2
    800014de:	6605                	lui	a2,0x1
    800014e0:	4581                	li	a1,0
    800014e2:	8552                	mv	a0,s4
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	d0c080e7          	jalr	-756(ra) # 800011f0 <mappages>
  memmove(mem, src, sz);
    800014ec:	8626                	mv	a2,s1
    800014ee:	85ce                	mv	a1,s3
    800014f0:	854a                	mv	a0,s2
    800014f2:	00000097          	auipc	ra,0x0
    800014f6:	990080e7          	jalr	-1648(ra) # 80000e82 <memmove>
}
    800014fa:	70a2                	ld	ra,40(sp)
    800014fc:	7402                	ld	s0,32(sp)
    800014fe:	64e2                	ld	s1,24(sp)
    80001500:	6942                	ld	s2,16(sp)
    80001502:	69a2                	ld	s3,8(sp)
    80001504:	6a02                	ld	s4,0(sp)
    80001506:	6145                	addi	sp,sp,48
    80001508:	8082                	ret
    panic("uvmfirst: more than a page");
    8000150a:	00007517          	auipc	a0,0x7
    8000150e:	c8650513          	addi	a0,a0,-890 # 80008190 <digits+0x150>
    80001512:	fffff097          	auipc	ra,0xfffff
    80001516:	02a080e7          	jalr	42(ra) # 8000053c <panic>

000000008000151a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000151a:	1101                	addi	sp,sp,-32
    8000151c:	ec06                	sd	ra,24(sp)
    8000151e:	e822                	sd	s0,16(sp)
    80001520:	e426                	sd	s1,8(sp)
    80001522:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001524:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001526:	00b67d63          	bgeu	a2,a1,80001540 <uvmdealloc+0x26>
    8000152a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000152c:	6785                	lui	a5,0x1
    8000152e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001530:	00f60733          	add	a4,a2,a5
    80001534:	76fd                	lui	a3,0xfffff
    80001536:	8f75                	and	a4,a4,a3
    80001538:	97ae                	add	a5,a5,a1
    8000153a:	8ff5                	and	a5,a5,a3
    8000153c:	00f76863          	bltu	a4,a5,8000154c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001540:	8526                	mv	a0,s1
    80001542:	60e2                	ld	ra,24(sp)
    80001544:	6442                	ld	s0,16(sp)
    80001546:	64a2                	ld	s1,8(sp)
    80001548:	6105                	addi	sp,sp,32
    8000154a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000154c:	8f99                	sub	a5,a5,a4
    8000154e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001550:	4685                	li	a3,1
    80001552:	0007861b          	sext.w	a2,a5
    80001556:	85ba                	mv	a1,a4
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	e5e080e7          	jalr	-418(ra) # 800013b6 <uvmunmap>
    80001560:	b7c5                	j	80001540 <uvmdealloc+0x26>

0000000080001562 <uvmalloc>:
  if(newsz < oldsz)
    80001562:	0ab66563          	bltu	a2,a1,8000160c <uvmalloc+0xaa>
{
    80001566:	7139                	addi	sp,sp,-64
    80001568:	fc06                	sd	ra,56(sp)
    8000156a:	f822                	sd	s0,48(sp)
    8000156c:	f426                	sd	s1,40(sp)
    8000156e:	f04a                	sd	s2,32(sp)
    80001570:	ec4e                	sd	s3,24(sp)
    80001572:	e852                	sd	s4,16(sp)
    80001574:	e456                	sd	s5,8(sp)
    80001576:	e05a                	sd	s6,0(sp)
    80001578:	0080                	addi	s0,sp,64
    8000157a:	8aaa                	mv	s5,a0
    8000157c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000157e:	6785                	lui	a5,0x1
    80001580:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001582:	95be                	add	a1,a1,a5
    80001584:	77fd                	lui	a5,0xfffff
    80001586:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000158a:	08c9f363          	bgeu	s3,a2,80001610 <uvmalloc+0xae>
    8000158e:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001590:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001594:	fffff097          	auipc	ra,0xfffff
    80001598:	5f6080e7          	jalr	1526(ra) # 80000b8a <kalloc>
    8000159c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000159e:	c51d                	beqz	a0,800015cc <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800015a0:	6605                	lui	a2,0x1
    800015a2:	4581                	li	a1,0
    800015a4:	00000097          	auipc	ra,0x0
    800015a8:	882080e7          	jalr	-1918(ra) # 80000e26 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800015ac:	875a                	mv	a4,s6
    800015ae:	86a6                	mv	a3,s1
    800015b0:	6605                	lui	a2,0x1
    800015b2:	85ca                	mv	a1,s2
    800015b4:	8556                	mv	a0,s5
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	c3a080e7          	jalr	-966(ra) # 800011f0 <mappages>
    800015be:	e90d                	bnez	a0,800015f0 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015c0:	6785                	lui	a5,0x1
    800015c2:	993e                	add	s2,s2,a5
    800015c4:	fd4968e3          	bltu	s2,s4,80001594 <uvmalloc+0x32>
  return newsz;
    800015c8:	8552                	mv	a0,s4
    800015ca:	a809                	j	800015dc <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800015cc:	864e                	mv	a2,s3
    800015ce:	85ca                	mv	a1,s2
    800015d0:	8556                	mv	a0,s5
    800015d2:	00000097          	auipc	ra,0x0
    800015d6:	f48080e7          	jalr	-184(ra) # 8000151a <uvmdealloc>
      return 0;
    800015da:	4501                	li	a0,0
}
    800015dc:	70e2                	ld	ra,56(sp)
    800015de:	7442                	ld	s0,48(sp)
    800015e0:	74a2                	ld	s1,40(sp)
    800015e2:	7902                	ld	s2,32(sp)
    800015e4:	69e2                	ld	s3,24(sp)
    800015e6:	6a42                	ld	s4,16(sp)
    800015e8:	6aa2                	ld	s5,8(sp)
    800015ea:	6b02                	ld	s6,0(sp)
    800015ec:	6121                	addi	sp,sp,64
    800015ee:	8082                	ret
      kfree(mem);
    800015f0:	8526                	mv	a0,s1
    800015f2:	fffff097          	auipc	ra,0xfffff
    800015f6:	404080e7          	jalr	1028(ra) # 800009f6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015fa:	864e                	mv	a2,s3
    800015fc:	85ca                	mv	a1,s2
    800015fe:	8556                	mv	a0,s5
    80001600:	00000097          	auipc	ra,0x0
    80001604:	f1a080e7          	jalr	-230(ra) # 8000151a <uvmdealloc>
      return 0;
    80001608:	4501                	li	a0,0
    8000160a:	bfc9                	j	800015dc <uvmalloc+0x7a>
    return oldsz;
    8000160c:	852e                	mv	a0,a1
}
    8000160e:	8082                	ret
  return newsz;
    80001610:	8532                	mv	a0,a2
    80001612:	b7e9                	j	800015dc <uvmalloc+0x7a>

0000000080001614 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001614:	7179                	addi	sp,sp,-48
    80001616:	f406                	sd	ra,40(sp)
    80001618:	f022                	sd	s0,32(sp)
    8000161a:	ec26                	sd	s1,24(sp)
    8000161c:	e84a                	sd	s2,16(sp)
    8000161e:	e44e                	sd	s3,8(sp)
    80001620:	e052                	sd	s4,0(sp)
    80001622:	1800                	addi	s0,sp,48
    80001624:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001626:	84aa                	mv	s1,a0
    80001628:	6905                	lui	s2,0x1
    8000162a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000162c:	4985                	li	s3,1
    8000162e:	a829                	j	80001648 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001630:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001632:	00c79513          	slli	a0,a5,0xc
    80001636:	00000097          	auipc	ra,0x0
    8000163a:	fde080e7          	jalr	-34(ra) # 80001614 <freewalk>
      pagetable[i] = 0;
    8000163e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001642:	04a1                	addi	s1,s1,8
    80001644:	03248163          	beq	s1,s2,80001666 <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001648:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000164a:	00f7f713          	andi	a4,a5,15
    8000164e:	ff3701e3          	beq	a4,s3,80001630 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001652:	8b85                	andi	a5,a5,1
    80001654:	d7fd                	beqz	a5,80001642 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001656:	00007517          	auipc	a0,0x7
    8000165a:	b5a50513          	addi	a0,a0,-1190 # 800081b0 <digits+0x170>
    8000165e:	fffff097          	auipc	ra,0xfffff
    80001662:	ede080e7          	jalr	-290(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    80001666:	8552                	mv	a0,s4
    80001668:	fffff097          	auipc	ra,0xfffff
    8000166c:	38e080e7          	jalr	910(ra) # 800009f6 <kfree>
}
    80001670:	70a2                	ld	ra,40(sp)
    80001672:	7402                	ld	s0,32(sp)
    80001674:	64e2                	ld	s1,24(sp)
    80001676:	6942                	ld	s2,16(sp)
    80001678:	69a2                	ld	s3,8(sp)
    8000167a:	6a02                	ld	s4,0(sp)
    8000167c:	6145                	addi	sp,sp,48
    8000167e:	8082                	ret

0000000080001680 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001680:	1101                	addi	sp,sp,-32
    80001682:	ec06                	sd	ra,24(sp)
    80001684:	e822                	sd	s0,16(sp)
    80001686:	e426                	sd	s1,8(sp)
    80001688:	1000                	addi	s0,sp,32
    8000168a:	84aa                	mv	s1,a0
  if(sz > 0)
    8000168c:	e999                	bnez	a1,800016a2 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000168e:	8526                	mv	a0,s1
    80001690:	00000097          	auipc	ra,0x0
    80001694:	f84080e7          	jalr	-124(ra) # 80001614 <freewalk>
}
    80001698:	60e2                	ld	ra,24(sp)
    8000169a:	6442                	ld	s0,16(sp)
    8000169c:	64a2                	ld	s1,8(sp)
    8000169e:	6105                	addi	sp,sp,32
    800016a0:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016a2:	6785                	lui	a5,0x1
    800016a4:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800016a6:	95be                	add	a1,a1,a5
    800016a8:	4685                	li	a3,1
    800016aa:	00c5d613          	srli	a2,a1,0xc
    800016ae:	4581                	li	a1,0
    800016b0:	00000097          	auipc	ra,0x0
    800016b4:	d06080e7          	jalr	-762(ra) # 800013b6 <uvmunmap>
    800016b8:	bfd9                	j	8000168e <uvmfree+0xe>

00000000800016ba <uvmcopy>:
{
  pte_t *pte;
  uint64 phyadr, i;
  uint flags;

  for (i = 0; i < sz; i += PGSIZE) {
    800016ba:	ca55                	beqz	a2,8000176e <uvmcopy+0xb4>
{
    800016bc:	7139                	addi	sp,sp,-64
    800016be:	fc06                	sd	ra,56(sp)
    800016c0:	f822                	sd	s0,48(sp)
    800016c2:	f426                	sd	s1,40(sp)
    800016c4:	f04a                	sd	s2,32(sp)
    800016c6:	ec4e                	sd	s3,24(sp)
    800016c8:	e852                	sd	s4,16(sp)
    800016ca:	e456                	sd	s5,8(sp)
    800016cc:	e05a                	sd	s6,0(sp)
    800016ce:	0080                	addi	s0,sp,64
    800016d0:	8b2a                	mv	s6,a0
    800016d2:	8aae                	mv	s5,a1
    800016d4:	8a32                	mv	s4,a2
  for (i = 0; i < sz; i += PGSIZE) {
    800016d6:	4901                	li	s2,0
    if (!(pte = walk(old, i, 0))) {
    800016d8:	4601                	li	a2,0
    800016da:	85ca                	mv	a1,s2
    800016dc:	855a                	mv	a0,s6
    800016de:	00000097          	auipc	ra,0x0
    800016e2:	a2a080e7          	jalr	-1494(ra) # 80001108 <walk>
    800016e6:	c121                	beqz	a0,80001726 <uvmcopy+0x6c>
      panic("uvmcopy: pte should exist");
    } else if (!(*pte & PTE_V)) {
    800016e8:	6118                	ld	a4,0(a0)
    800016ea:	00177793          	andi	a5,a4,1
    800016ee:	c7a1                	beqz	a5,80001736 <uvmcopy+0x7c>
      panic("uvmcopy: page not present");
    }
      
    phyadr = PTE2PA(*pte);
    800016f0:	00a75993          	srli	s3,a4,0xa
    800016f4:	09b2                	slli	s3,s3,0xc
    *pte &= ~PTE_W;
    800016f6:	ffb77493          	andi	s1,a4,-5
    800016fa:	e104                	sd	s1,0(a0)
    flags = PTE_FLAGS(*pte);

    inc(phyadr);
    800016fc:	854e                	mv	a0,s3
    800016fe:	fffff097          	auipc	ra,0xfffff
    80001702:	524080e7          	jalr	1316(ra) # 80000c22 <inc>
    
    if (mappages(new, i, PGSIZE, (uint64)phyadr, flags) != 0) {
    80001706:	3fb4f713          	andi	a4,s1,1019
    8000170a:	86ce                	mv	a3,s3
    8000170c:	6605                	lui	a2,0x1
    8000170e:	85ca                	mv	a1,s2
    80001710:	8556                	mv	a0,s5
    80001712:	00000097          	auipc	ra,0x0
    80001716:	ade080e7          	jalr	-1314(ra) # 800011f0 <mappages>
    8000171a:	e515                	bnez	a0,80001746 <uvmcopy+0x8c>
  for (i = 0; i < sz; i += PGSIZE) {
    8000171c:	6785                	lui	a5,0x1
    8000171e:	993e                	add	s2,s2,a5
    80001720:	fb496ce3          	bltu	s2,s4,800016d8 <uvmcopy+0x1e>
    80001724:	a81d                	j	8000175a <uvmcopy+0xa0>
      panic("uvmcopy: pte should exist");
    80001726:	00007517          	auipc	a0,0x7
    8000172a:	a9a50513          	addi	a0,a0,-1382 # 800081c0 <digits+0x180>
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	e0e080e7          	jalr	-498(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    80001736:	00007517          	auipc	a0,0x7
    8000173a:	aaa50513          	addi	a0,a0,-1366 # 800081e0 <digits+0x1a0>
    8000173e:	fffff097          	auipc	ra,0xfffff
    80001742:	dfe080e7          	jalr	-514(ra) # 8000053c <panic>
      uvmunmap(new, 0, i / PGSIZE, 1);
    80001746:	4685                	li	a3,1
    80001748:	00c95613          	srli	a2,s2,0xc
    8000174c:	4581                	li	a1,0
    8000174e:	8556                	mv	a0,s5
    80001750:	00000097          	auipc	ra,0x0
    80001754:	c66080e7          	jalr	-922(ra) # 800013b6 <uvmunmap>
      return -1;
    80001758:	557d                	li	a0,-1
    }
  }
  return 0;
  
}
    8000175a:	70e2                	ld	ra,56(sp)
    8000175c:	7442                	ld	s0,48(sp)
    8000175e:	74a2                	ld	s1,40(sp)
    80001760:	7902                	ld	s2,32(sp)
    80001762:	69e2                	ld	s3,24(sp)
    80001764:	6a42                	ld	s4,16(sp)
    80001766:	6aa2                	ld	s5,8(sp)
    80001768:	6b02                	ld	s6,0(sp)
    8000176a:	6121                	addi	sp,sp,64
    8000176c:	8082                	ret
  return 0;
    8000176e:	4501                	li	a0,0
}
    80001770:	8082                	ret

0000000080001772 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001772:	1141                	addi	sp,sp,-16
    80001774:	e406                	sd	ra,8(sp)
    80001776:	e022                	sd	s0,0(sp)
    80001778:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000177a:	4601                	li	a2,0
    8000177c:	00000097          	auipc	ra,0x0
    80001780:	98c080e7          	jalr	-1652(ra) # 80001108 <walk>
  if(pte == 0)
    80001784:	c901                	beqz	a0,80001794 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001786:	611c                	ld	a5,0(a0)
    80001788:	9bbd                	andi	a5,a5,-17
    8000178a:	e11c                	sd	a5,0(a0)
}
    8000178c:	60a2                	ld	ra,8(sp)
    8000178e:	6402                	ld	s0,0(sp)
    80001790:	0141                	addi	sp,sp,16
    80001792:	8082                	ret
    panic("uvmclear");
    80001794:	00007517          	auipc	a0,0x7
    80001798:	a6c50513          	addi	a0,a0,-1428 # 80008200 <digits+0x1c0>
    8000179c:	fffff097          	auipc	ra,0xfffff
    800017a0:	da0080e7          	jalr	-608(ra) # 8000053c <panic>

00000000800017a4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017a4:	c6bd                	beqz	a3,80001812 <copyout+0x6e>
{
    800017a6:	715d                	addi	sp,sp,-80
    800017a8:	e486                	sd	ra,72(sp)
    800017aa:	e0a2                	sd	s0,64(sp)
    800017ac:	fc26                	sd	s1,56(sp)
    800017ae:	f84a                	sd	s2,48(sp)
    800017b0:	f44e                	sd	s3,40(sp)
    800017b2:	f052                	sd	s4,32(sp)
    800017b4:	ec56                	sd	s5,24(sp)
    800017b6:	e85a                	sd	s6,16(sp)
    800017b8:	e45e                	sd	s7,8(sp)
    800017ba:	e062                	sd	s8,0(sp)
    800017bc:	0880                	addi	s0,sp,80
    800017be:	8b2a                	mv	s6,a0
    800017c0:	8c2e                	mv	s8,a1
    800017c2:	8a32                	mv	s4,a2
    800017c4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017c6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017c8:	6a85                	lui	s5,0x1
    800017ca:	a015                	j	800017ee <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017cc:	9562                	add	a0,a0,s8
    800017ce:	0004861b          	sext.w	a2,s1
    800017d2:	85d2                	mv	a1,s4
    800017d4:	41250533          	sub	a0,a0,s2
    800017d8:	fffff097          	auipc	ra,0xfffff
    800017dc:	6aa080e7          	jalr	1706(ra) # 80000e82 <memmove>

    len -= n;
    800017e0:	409989b3          	sub	s3,s3,s1
    src += n;
    800017e4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800017e6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017ea:	02098263          	beqz	s3,8000180e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017ee:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017f2:	85ca                	mv	a1,s2
    800017f4:	855a                	mv	a0,s6
    800017f6:	00000097          	auipc	ra,0x0
    800017fa:	9b8080e7          	jalr	-1608(ra) # 800011ae <walkaddr>
    if(pa0 == 0)
    800017fe:	cd01                	beqz	a0,80001816 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001800:	418904b3          	sub	s1,s2,s8
    80001804:	94d6                	add	s1,s1,s5
    80001806:	fc99f3e3          	bgeu	s3,s1,800017cc <copyout+0x28>
    8000180a:	84ce                	mv	s1,s3
    8000180c:	b7c1                	j	800017cc <copyout+0x28>
  }
  return 0;
    8000180e:	4501                	li	a0,0
    80001810:	a021                	j	80001818 <copyout+0x74>
    80001812:	4501                	li	a0,0
}
    80001814:	8082                	ret
      return -1;
    80001816:	557d                	li	a0,-1
}
    80001818:	60a6                	ld	ra,72(sp)
    8000181a:	6406                	ld	s0,64(sp)
    8000181c:	74e2                	ld	s1,56(sp)
    8000181e:	7942                	ld	s2,48(sp)
    80001820:	79a2                	ld	s3,40(sp)
    80001822:	7a02                	ld	s4,32(sp)
    80001824:	6ae2                	ld	s5,24(sp)
    80001826:	6b42                	ld	s6,16(sp)
    80001828:	6ba2                	ld	s7,8(sp)
    8000182a:	6c02                	ld	s8,0(sp)
    8000182c:	6161                	addi	sp,sp,80
    8000182e:	8082                	ret

0000000080001830 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001830:	caa5                	beqz	a3,800018a0 <copyin+0x70>
{
    80001832:	715d                	addi	sp,sp,-80
    80001834:	e486                	sd	ra,72(sp)
    80001836:	e0a2                	sd	s0,64(sp)
    80001838:	fc26                	sd	s1,56(sp)
    8000183a:	f84a                	sd	s2,48(sp)
    8000183c:	f44e                	sd	s3,40(sp)
    8000183e:	f052                	sd	s4,32(sp)
    80001840:	ec56                	sd	s5,24(sp)
    80001842:	e85a                	sd	s6,16(sp)
    80001844:	e45e                	sd	s7,8(sp)
    80001846:	e062                	sd	s8,0(sp)
    80001848:	0880                	addi	s0,sp,80
    8000184a:	8b2a                	mv	s6,a0
    8000184c:	8a2e                	mv	s4,a1
    8000184e:	8c32                	mv	s8,a2
    80001850:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001852:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001854:	6a85                	lui	s5,0x1
    80001856:	a01d                	j	8000187c <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001858:	018505b3          	add	a1,a0,s8
    8000185c:	0004861b          	sext.w	a2,s1
    80001860:	412585b3          	sub	a1,a1,s2
    80001864:	8552                	mv	a0,s4
    80001866:	fffff097          	auipc	ra,0xfffff
    8000186a:	61c080e7          	jalr	1564(ra) # 80000e82 <memmove>

    len -= n;
    8000186e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001872:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001874:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001878:	02098263          	beqz	s3,8000189c <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000187c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001880:	85ca                	mv	a1,s2
    80001882:	855a                	mv	a0,s6
    80001884:	00000097          	auipc	ra,0x0
    80001888:	92a080e7          	jalr	-1750(ra) # 800011ae <walkaddr>
    if(pa0 == 0)
    8000188c:	cd01                	beqz	a0,800018a4 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000188e:	418904b3          	sub	s1,s2,s8
    80001892:	94d6                	add	s1,s1,s5
    80001894:	fc99f2e3          	bgeu	s3,s1,80001858 <copyin+0x28>
    80001898:	84ce                	mv	s1,s3
    8000189a:	bf7d                	j	80001858 <copyin+0x28>
  }
  return 0;
    8000189c:	4501                	li	a0,0
    8000189e:	a021                	j	800018a6 <copyin+0x76>
    800018a0:	4501                	li	a0,0
}
    800018a2:	8082                	ret
      return -1;
    800018a4:	557d                	li	a0,-1
}
    800018a6:	60a6                	ld	ra,72(sp)
    800018a8:	6406                	ld	s0,64(sp)
    800018aa:	74e2                	ld	s1,56(sp)
    800018ac:	7942                	ld	s2,48(sp)
    800018ae:	79a2                	ld	s3,40(sp)
    800018b0:	7a02                	ld	s4,32(sp)
    800018b2:	6ae2                	ld	s5,24(sp)
    800018b4:	6b42                	ld	s6,16(sp)
    800018b6:	6ba2                	ld	s7,8(sp)
    800018b8:	6c02                	ld	s8,0(sp)
    800018ba:	6161                	addi	sp,sp,80
    800018bc:	8082                	ret

00000000800018be <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018be:	c2dd                	beqz	a3,80001964 <copyinstr+0xa6>
{
    800018c0:	715d                	addi	sp,sp,-80
    800018c2:	e486                	sd	ra,72(sp)
    800018c4:	e0a2                	sd	s0,64(sp)
    800018c6:	fc26                	sd	s1,56(sp)
    800018c8:	f84a                	sd	s2,48(sp)
    800018ca:	f44e                	sd	s3,40(sp)
    800018cc:	f052                	sd	s4,32(sp)
    800018ce:	ec56                	sd	s5,24(sp)
    800018d0:	e85a                	sd	s6,16(sp)
    800018d2:	e45e                	sd	s7,8(sp)
    800018d4:	0880                	addi	s0,sp,80
    800018d6:	8a2a                	mv	s4,a0
    800018d8:	8b2e                	mv	s6,a1
    800018da:	8bb2                	mv	s7,a2
    800018dc:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018de:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018e0:	6985                	lui	s3,0x1
    800018e2:	a02d                	j	8000190c <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018e4:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018e8:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018ea:	37fd                	addiw	a5,a5,-1
    800018ec:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018f0:	60a6                	ld	ra,72(sp)
    800018f2:	6406                	ld	s0,64(sp)
    800018f4:	74e2                	ld	s1,56(sp)
    800018f6:	7942                	ld	s2,48(sp)
    800018f8:	79a2                	ld	s3,40(sp)
    800018fa:	7a02                	ld	s4,32(sp)
    800018fc:	6ae2                	ld	s5,24(sp)
    800018fe:	6b42                	ld	s6,16(sp)
    80001900:	6ba2                	ld	s7,8(sp)
    80001902:	6161                	addi	sp,sp,80
    80001904:	8082                	ret
    srcva = va0 + PGSIZE;
    80001906:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000190a:	c8a9                	beqz	s1,8000195c <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000190c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001910:	85ca                	mv	a1,s2
    80001912:	8552                	mv	a0,s4
    80001914:	00000097          	auipc	ra,0x0
    80001918:	89a080e7          	jalr	-1894(ra) # 800011ae <walkaddr>
    if(pa0 == 0)
    8000191c:	c131                	beqz	a0,80001960 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000191e:	417906b3          	sub	a3,s2,s7
    80001922:	96ce                	add	a3,a3,s3
    80001924:	00d4f363          	bgeu	s1,a3,8000192a <copyinstr+0x6c>
    80001928:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000192a:	955e                	add	a0,a0,s7
    8000192c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001930:	daf9                	beqz	a3,80001906 <copyinstr+0x48>
    80001932:	87da                	mv	a5,s6
    80001934:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001936:	41650633          	sub	a2,a0,s6
    while(n > 0){
    8000193a:	96da                	add	a3,a3,s6
    8000193c:	85be                	mv	a1,a5
      if(*p == '\0'){
    8000193e:	00f60733          	add	a4,a2,a5
    80001942:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdbd150>
    80001946:	df59                	beqz	a4,800018e4 <copyinstr+0x26>
        *dst = *p;
    80001948:	00e78023          	sb	a4,0(a5)
      dst++;
    8000194c:	0785                	addi	a5,a5,1
    while(n > 0){
    8000194e:	fed797e3          	bne	a5,a3,8000193c <copyinstr+0x7e>
    80001952:	14fd                	addi	s1,s1,-1
    80001954:	94c2                	add	s1,s1,a6
      --max;
    80001956:	8c8d                	sub	s1,s1,a1
      dst++;
    80001958:	8b3e                	mv	s6,a5
    8000195a:	b775                	j	80001906 <copyinstr+0x48>
    8000195c:	4781                	li	a5,0
    8000195e:	b771                	j	800018ea <copyinstr+0x2c>
      return -1;
    80001960:	557d                	li	a0,-1
    80001962:	b779                	j	800018f0 <copyinstr+0x32>
  int got_null = 0;
    80001964:	4781                	li	a5,0
  if(got_null){
    80001966:	37fd                	addiw	a5,a5,-1
    80001968:	0007851b          	sext.w	a0,a5
}
    8000196c:	8082                	ret

000000008000196e <cowfault>:

int cowfault(pagetable_t pagetable, uint64 viradr)
{
  if (viradr >= MAXVA) {
    8000196e:	57fd                	li	a5,-1
    80001970:	83e9                	srli	a5,a5,0x1a
    80001972:	06b7e863          	bltu	a5,a1,800019e2 <cowfault+0x74>
{
    80001976:	7179                	addi	sp,sp,-48
    80001978:	f406                	sd	ra,40(sp)
    8000197a:	f022                	sd	s0,32(sp)
    8000197c:	ec26                	sd	s1,24(sp)
    8000197e:	e84a                	sd	s2,16(sp)
    80001980:	e44e                	sd	s3,8(sp)
    80001982:	1800                	addi	s0,sp,48
    return -1;
  }
    
  pte_t *pte = walk(pagetable, viradr, 0);
    80001984:	4601                	li	a2,0
    80001986:	fffff097          	auipc	ra,0xfffff
    8000198a:	782080e7          	jalr	1922(ra) # 80001108 <walk>
    8000198e:	89aa                	mv	s3,a0
  if (!pte || !(*pte & PTE_U) || !(*pte & PTE_V)) {
    80001990:	c939                	beqz	a0,800019e6 <cowfault+0x78>
    80001992:	610c                	ld	a1,0(a0)
    80001994:	0115f713          	andi	a4,a1,17
    80001998:	47c5                	li	a5,17
    8000199a:	04f71863          	bne	a4,a5,800019ea <cowfault+0x7c>
    return -1;
  }
  uint64 phyadr1 = PTE2PA(*pte);
    8000199e:	81a9                	srli	a1,a1,0xa
    800019a0:	00c59913          	slli	s2,a1,0xc
  uint64 phyadr2 = (uint64)kalloc();
    800019a4:	fffff097          	auipc	ra,0xfffff
    800019a8:	1e6080e7          	jalr	486(ra) # 80000b8a <kalloc>
    800019ac:	84aa                	mv	s1,a0
  if (!phyadr2) {
    800019ae:	c121                	beqz	a0,800019ee <cowfault+0x80>
    return -1;
  }
  memmove((void *)phyadr2, (void *)phyadr1, PGSIZE);
    800019b0:	6605                	lui	a2,0x1
    800019b2:	85ca                	mv	a1,s2
    800019b4:	fffff097          	auipc	ra,0xfffff
    800019b8:	4ce080e7          	jalr	1230(ra) # 80000e82 <memmove>
  *pte = PA2PTE(phyadr2) | PTE_U | PTE_V | PTE_W | PTE_X | PTE_R;
    800019bc:	80b1                	srli	s1,s1,0xc
    800019be:	04aa                	slli	s1,s1,0xa
    800019c0:	01f4e493          	ori	s1,s1,31
    800019c4:	0099b023          	sd	s1,0(s3) # 1000 <_entry-0x7ffff000>
  kfree((void *)phyadr1);
    800019c8:	854a                	mv	a0,s2
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	02c080e7          	jalr	44(ra) # 800009f6 <kfree>
  return 0;
    800019d2:	4501                	li	a0,0
    800019d4:	70a2                	ld	ra,40(sp)
    800019d6:	7402                	ld	s0,32(sp)
    800019d8:	64e2                	ld	s1,24(sp)
    800019da:	6942                	ld	s2,16(sp)
    800019dc:	69a2                	ld	s3,8(sp)
    800019de:	6145                	addi	sp,sp,48
    800019e0:	8082                	ret
    return -1;
    800019e2:	557d                	li	a0,-1
    800019e4:	8082                	ret
    return -1;
    800019e6:	557d                	li	a0,-1
    800019e8:	b7f5                	j	800019d4 <cowfault+0x66>
    800019ea:	557d                	li	a0,-1
    800019ec:	b7e5                	j	800019d4 <cowfault+0x66>
    return -1;
    800019ee:	557d                	li	a0,-1
    800019f0:	b7d5                	j	800019d4 <cowfault+0x66>

00000000800019f2 <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    800019f2:	715d                	addi	sp,sp,-80
    800019f4:	e486                	sd	ra,72(sp)
    800019f6:	e0a2                	sd	s0,64(sp)
    800019f8:	fc26                	sd	s1,56(sp)
    800019fa:	f84a                	sd	s2,48(sp)
    800019fc:	f44e                	sd	s3,40(sp)
    800019fe:	f052                	sd	s4,32(sp)
    80001a00:	ec56                	sd	s5,24(sp)
    80001a02:	e85a                	sd	s6,16(sp)
    80001a04:	e45e                	sd	s7,8(sp)
    80001a06:	e062                	sd	s8,0(sp)
    80001a08:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a0a:	8792                	mv	a5,tp
    int id = r_tp();
    80001a0c:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    80001a0e:	0022fa97          	auipc	s5,0x22f
    80001a12:	292a8a93          	addi	s5,s5,658 # 80230ca0 <cpus>
    80001a16:	00779713          	slli	a4,a5,0x7
    80001a1a:	00ea86b3          	add	a3,s5,a4
    80001a1e:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7fdbd150>
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
    80001a22:	0721                	addi	a4,a4,8
    80001a24:	9aba                	add	s5,s5,a4
                c->proc = p;
    80001a26:	8936                	mv	s2,a3
                // check if we are still the right scheduler (or if schedset changed)
                if (sched_pointer != &rr_scheduler)
    80001a28:	00007c17          	auipc	s8,0x7
    80001a2c:	f50c0c13          	addi	s8,s8,-176 # 80008978 <sched_pointer>
    80001a30:	00000b97          	auipc	s7,0x0
    80001a34:	fc2b8b93          	addi	s7,s7,-62 # 800019f2 <rr_scheduler>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001a38:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001a3c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001a40:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++)
    80001a44:	0022f497          	auipc	s1,0x22f
    80001a48:	68c48493          	addi	s1,s1,1676 # 802310d0 <proc>
            if (p->state == RUNNABLE)
    80001a4c:	498d                	li	s3,3
                p->state = RUNNING;
    80001a4e:	4b11                	li	s6,4
        for (p = proc; p < &proc[NPROC]; p++)
    80001a50:	00235a17          	auipc	s4,0x235
    80001a54:	080a0a13          	addi	s4,s4,128 # 80236ad0 <tickslock>
    80001a58:	a81d                	j	80001a8e <rr_scheduler+0x9c>
                {
                    release(&p->lock);
    80001a5a:	8526                	mv	a0,s1
    80001a5c:	fffff097          	auipc	ra,0xfffff
    80001a60:	382080e7          	jalr	898(ra) # 80000dde <release>
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
}
    80001a64:	60a6                	ld	ra,72(sp)
    80001a66:	6406                	ld	s0,64(sp)
    80001a68:	74e2                	ld	s1,56(sp)
    80001a6a:	7942                	ld	s2,48(sp)
    80001a6c:	79a2                	ld	s3,40(sp)
    80001a6e:	7a02                	ld	s4,32(sp)
    80001a70:	6ae2                	ld	s5,24(sp)
    80001a72:	6b42                	ld	s6,16(sp)
    80001a74:	6ba2                	ld	s7,8(sp)
    80001a76:	6c02                	ld	s8,0(sp)
    80001a78:	6161                	addi	sp,sp,80
    80001a7a:	8082                	ret
            release(&p->lock);
    80001a7c:	8526                	mv	a0,s1
    80001a7e:	fffff097          	auipc	ra,0xfffff
    80001a82:	360080e7          	jalr	864(ra) # 80000dde <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80001a86:	16848493          	addi	s1,s1,360
    80001a8a:	fb4487e3          	beq	s1,s4,80001a38 <rr_scheduler+0x46>
            acquire(&p->lock);
    80001a8e:	8526                	mv	a0,s1
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	29a080e7          	jalr	666(ra) # 80000d2a <acquire>
            if (p->state == RUNNABLE)
    80001a98:	4c9c                	lw	a5,24(s1)
    80001a9a:	ff3791e3          	bne	a5,s3,80001a7c <rr_scheduler+0x8a>
                p->state = RUNNING;
    80001a9e:	0164ac23          	sw	s6,24(s1)
                c->proc = p;
    80001aa2:	00993023          	sd	s1,0(s2) # 1000 <_entry-0x7ffff000>
                swtch(&c->context, &p->context);
    80001aa6:	06048593          	addi	a1,s1,96
    80001aaa:	8556                	mv	a0,s5
    80001aac:	00001097          	auipc	ra,0x1
    80001ab0:	fbe080e7          	jalr	-66(ra) # 80002a6a <swtch>
                if (sched_pointer != &rr_scheduler)
    80001ab4:	000c3783          	ld	a5,0(s8)
    80001ab8:	fb7791e3          	bne	a5,s7,80001a5a <rr_scheduler+0x68>
                c->proc = 0;
    80001abc:	00093023          	sd	zero,0(s2)
    80001ac0:	bf75                	j	80001a7c <rr_scheduler+0x8a>

0000000080001ac2 <proc_mapstacks>:
{
    80001ac2:	7139                	addi	sp,sp,-64
    80001ac4:	fc06                	sd	ra,56(sp)
    80001ac6:	f822                	sd	s0,48(sp)
    80001ac8:	f426                	sd	s1,40(sp)
    80001aca:	f04a                	sd	s2,32(sp)
    80001acc:	ec4e                	sd	s3,24(sp)
    80001ace:	e852                	sd	s4,16(sp)
    80001ad0:	e456                	sd	s5,8(sp)
    80001ad2:	e05a                	sd	s6,0(sp)
    80001ad4:	0080                	addi	s0,sp,64
    80001ad6:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    80001ad8:	0022f497          	auipc	s1,0x22f
    80001adc:	5f848493          	addi	s1,s1,1528 # 802310d0 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001ae0:	8b26                	mv	s6,s1
    80001ae2:	00006a97          	auipc	s5,0x6
    80001ae6:	51ea8a93          	addi	s5,s5,1310 # 80008000 <etext>
    80001aea:	04000937          	lui	s2,0x4000
    80001aee:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001af2:	00235a17          	auipc	s4,0x235
    80001af6:	fdea0a13          	addi	s4,s4,-34 # 80236ad0 <tickslock>
        char *pa = kalloc();
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	090080e7          	jalr	144(ra) # 80000b8a <kalloc>
    80001b02:	862a                	mv	a2,a0
        if (pa == 0)
    80001b04:	c131                	beqz	a0,80001b48 <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001b06:	416485b3          	sub	a1,s1,s6
    80001b0a:	858d                	srai	a1,a1,0x3
    80001b0c:	000ab783          	ld	a5,0(s5)
    80001b10:	02f585b3          	mul	a1,a1,a5
    80001b14:	2585                	addiw	a1,a1,1
    80001b16:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b1a:	4719                	li	a4,6
    80001b1c:	6685                	lui	a3,0x1
    80001b1e:	40b905b3          	sub	a1,s2,a1
    80001b22:	854e                	mv	a0,s3
    80001b24:	fffff097          	auipc	ra,0xfffff
    80001b28:	76c080e7          	jalr	1900(ra) # 80001290 <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001b2c:	16848493          	addi	s1,s1,360
    80001b30:	fd4495e3          	bne	s1,s4,80001afa <proc_mapstacks+0x38>
}
    80001b34:	70e2                	ld	ra,56(sp)
    80001b36:	7442                	ld	s0,48(sp)
    80001b38:	74a2                	ld	s1,40(sp)
    80001b3a:	7902                	ld	s2,32(sp)
    80001b3c:	69e2                	ld	s3,24(sp)
    80001b3e:	6a42                	ld	s4,16(sp)
    80001b40:	6aa2                	ld	s5,8(sp)
    80001b42:	6b02                	ld	s6,0(sp)
    80001b44:	6121                	addi	sp,sp,64
    80001b46:	8082                	ret
            panic("kalloc");
    80001b48:	00006517          	auipc	a0,0x6
    80001b4c:	6c850513          	addi	a0,a0,1736 # 80008210 <digits+0x1d0>
    80001b50:	fffff097          	auipc	ra,0xfffff
    80001b54:	9ec080e7          	jalr	-1556(ra) # 8000053c <panic>

0000000080001b58 <procinit>:
{
    80001b58:	7139                	addi	sp,sp,-64
    80001b5a:	fc06                	sd	ra,56(sp)
    80001b5c:	f822                	sd	s0,48(sp)
    80001b5e:	f426                	sd	s1,40(sp)
    80001b60:	f04a                	sd	s2,32(sp)
    80001b62:	ec4e                	sd	s3,24(sp)
    80001b64:	e852                	sd	s4,16(sp)
    80001b66:	e456                	sd	s5,8(sp)
    80001b68:	e05a                	sd	s6,0(sp)
    80001b6a:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001b6c:	00006597          	auipc	a1,0x6
    80001b70:	6ac58593          	addi	a1,a1,1708 # 80008218 <digits+0x1d8>
    80001b74:	0022f517          	auipc	a0,0x22f
    80001b78:	52c50513          	addi	a0,a0,1324 # 802310a0 <pid_lock>
    80001b7c:	fffff097          	auipc	ra,0xfffff
    80001b80:	11e080e7          	jalr	286(ra) # 80000c9a <initlock>
    initlock(&wait_lock, "wait_lock");
    80001b84:	00006597          	auipc	a1,0x6
    80001b88:	69c58593          	addi	a1,a1,1692 # 80008220 <digits+0x1e0>
    80001b8c:	0022f517          	auipc	a0,0x22f
    80001b90:	52c50513          	addi	a0,a0,1324 # 802310b8 <wait_lock>
    80001b94:	fffff097          	auipc	ra,0xfffff
    80001b98:	106080e7          	jalr	262(ra) # 80000c9a <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001b9c:	0022f497          	auipc	s1,0x22f
    80001ba0:	53448493          	addi	s1,s1,1332 # 802310d0 <proc>
        initlock(&p->lock, "proc");
    80001ba4:	00006b17          	auipc	s6,0x6
    80001ba8:	68cb0b13          	addi	s6,s6,1676 # 80008230 <digits+0x1f0>
        p->kstack = KSTACK((int)(p - proc));
    80001bac:	8aa6                	mv	s5,s1
    80001bae:	00006a17          	auipc	s4,0x6
    80001bb2:	452a0a13          	addi	s4,s4,1106 # 80008000 <etext>
    80001bb6:	04000937          	lui	s2,0x4000
    80001bba:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001bbc:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001bbe:	00235997          	auipc	s3,0x235
    80001bc2:	f1298993          	addi	s3,s3,-238 # 80236ad0 <tickslock>
        initlock(&p->lock, "proc");
    80001bc6:	85da                	mv	a1,s6
    80001bc8:	8526                	mv	a0,s1
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	0d0080e7          	jalr	208(ra) # 80000c9a <initlock>
        p->state = UNUSED;
    80001bd2:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001bd6:	415487b3          	sub	a5,s1,s5
    80001bda:	878d                	srai	a5,a5,0x3
    80001bdc:	000a3703          	ld	a4,0(s4)
    80001be0:	02e787b3          	mul	a5,a5,a4
    80001be4:	2785                	addiw	a5,a5,1
    80001be6:	00d7979b          	slliw	a5,a5,0xd
    80001bea:	40f907b3          	sub	a5,s2,a5
    80001bee:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001bf0:	16848493          	addi	s1,s1,360
    80001bf4:	fd3499e3          	bne	s1,s3,80001bc6 <procinit+0x6e>
}
    80001bf8:	70e2                	ld	ra,56(sp)
    80001bfa:	7442                	ld	s0,48(sp)
    80001bfc:	74a2                	ld	s1,40(sp)
    80001bfe:	7902                	ld	s2,32(sp)
    80001c00:	69e2                	ld	s3,24(sp)
    80001c02:	6a42                	ld	s4,16(sp)
    80001c04:	6aa2                	ld	s5,8(sp)
    80001c06:	6b02                	ld	s6,0(sp)
    80001c08:	6121                	addi	sp,sp,64
    80001c0a:	8082                	ret

0000000080001c0c <copy_array>:
{
    80001c0c:	1141                	addi	sp,sp,-16
    80001c0e:	e422                	sd	s0,8(sp)
    80001c10:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001c12:	00c05c63          	blez	a2,80001c2a <copy_array+0x1e>
    80001c16:	87aa                	mv	a5,a0
    80001c18:	9532                	add	a0,a0,a2
        dst[i] = src[i];
    80001c1a:	0007c703          	lbu	a4,0(a5)
    80001c1e:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001c22:	0785                	addi	a5,a5,1
    80001c24:	0585                	addi	a1,a1,1
    80001c26:	fea79ae3          	bne	a5,a0,80001c1a <copy_array+0xe>
}
    80001c2a:	6422                	ld	s0,8(sp)
    80001c2c:	0141                	addi	sp,sp,16
    80001c2e:	8082                	ret

0000000080001c30 <cpuid>:
{
    80001c30:	1141                	addi	sp,sp,-16
    80001c32:	e422                	sd	s0,8(sp)
    80001c34:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c36:	8512                	mv	a0,tp
}
    80001c38:	2501                	sext.w	a0,a0
    80001c3a:	6422                	ld	s0,8(sp)
    80001c3c:	0141                	addi	sp,sp,16
    80001c3e:	8082                	ret

0000000080001c40 <mycpu>:
{
    80001c40:	1141                	addi	sp,sp,-16
    80001c42:	e422                	sd	s0,8(sp)
    80001c44:	0800                	addi	s0,sp,16
    80001c46:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001c48:	2781                	sext.w	a5,a5
    80001c4a:	079e                	slli	a5,a5,0x7
}
    80001c4c:	0022f517          	auipc	a0,0x22f
    80001c50:	05450513          	addi	a0,a0,84 # 80230ca0 <cpus>
    80001c54:	953e                	add	a0,a0,a5
    80001c56:	6422                	ld	s0,8(sp)
    80001c58:	0141                	addi	sp,sp,16
    80001c5a:	8082                	ret

0000000080001c5c <myproc>:
{
    80001c5c:	1101                	addi	sp,sp,-32
    80001c5e:	ec06                	sd	ra,24(sp)
    80001c60:	e822                	sd	s0,16(sp)
    80001c62:	e426                	sd	s1,8(sp)
    80001c64:	1000                	addi	s0,sp,32
    push_off();
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	078080e7          	jalr	120(ra) # 80000cde <push_off>
    80001c6e:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001c70:	2781                	sext.w	a5,a5
    80001c72:	079e                	slli	a5,a5,0x7
    80001c74:	0022f717          	auipc	a4,0x22f
    80001c78:	02c70713          	addi	a4,a4,44 # 80230ca0 <cpus>
    80001c7c:	97ba                	add	a5,a5,a4
    80001c7e:	6384                	ld	s1,0(a5)
    pop_off();
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	0fe080e7          	jalr	254(ra) # 80000d7e <pop_off>
}
    80001c88:	8526                	mv	a0,s1
    80001c8a:	60e2                	ld	ra,24(sp)
    80001c8c:	6442                	ld	s0,16(sp)
    80001c8e:	64a2                	ld	s1,8(sp)
    80001c90:	6105                	addi	sp,sp,32
    80001c92:	8082                	ret

0000000080001c94 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001c94:	1141                	addi	sp,sp,-16
    80001c96:	e406                	sd	ra,8(sp)
    80001c98:	e022                	sd	s0,0(sp)
    80001c9a:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	fc0080e7          	jalr	-64(ra) # 80001c5c <myproc>
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	13a080e7          	jalr	314(ra) # 80000dde <release>

    if (first)
    80001cac:	00007797          	auipc	a5,0x7
    80001cb0:	cc47a783          	lw	a5,-828(a5) # 80008970 <first.1>
    80001cb4:	eb89                	bnez	a5,80001cc6 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001cb6:	00001097          	auipc	ra,0x1
    80001cba:	e5e080e7          	jalr	-418(ra) # 80002b14 <usertrapret>
}
    80001cbe:	60a2                	ld	ra,8(sp)
    80001cc0:	6402                	ld	s0,0(sp)
    80001cc2:	0141                	addi	sp,sp,16
    80001cc4:	8082                	ret
        first = 0;
    80001cc6:	00007797          	auipc	a5,0x7
    80001cca:	ca07a523          	sw	zero,-854(a5) # 80008970 <first.1>
        fsinit(ROOTDEV);
    80001cce:	4505                	li	a0,1
    80001cd0:	00002097          	auipc	ra,0x2
    80001cd4:	cf4080e7          	jalr	-780(ra) # 800039c4 <fsinit>
    80001cd8:	bff9                	j	80001cb6 <forkret+0x22>

0000000080001cda <allocpid>:
{
    80001cda:	1101                	addi	sp,sp,-32
    80001cdc:	ec06                	sd	ra,24(sp)
    80001cde:	e822                	sd	s0,16(sp)
    80001ce0:	e426                	sd	s1,8(sp)
    80001ce2:	e04a                	sd	s2,0(sp)
    80001ce4:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001ce6:	0022f917          	auipc	s2,0x22f
    80001cea:	3ba90913          	addi	s2,s2,954 # 802310a0 <pid_lock>
    80001cee:	854a                	mv	a0,s2
    80001cf0:	fffff097          	auipc	ra,0xfffff
    80001cf4:	03a080e7          	jalr	58(ra) # 80000d2a <acquire>
    pid = nextpid;
    80001cf8:	00007797          	auipc	a5,0x7
    80001cfc:	c8878793          	addi	a5,a5,-888 # 80008980 <nextpid>
    80001d00:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001d02:	0014871b          	addiw	a4,s1,1
    80001d06:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001d08:	854a                	mv	a0,s2
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	0d4080e7          	jalr	212(ra) # 80000dde <release>
}
    80001d12:	8526                	mv	a0,s1
    80001d14:	60e2                	ld	ra,24(sp)
    80001d16:	6442                	ld	s0,16(sp)
    80001d18:	64a2                	ld	s1,8(sp)
    80001d1a:	6902                	ld	s2,0(sp)
    80001d1c:	6105                	addi	sp,sp,32
    80001d1e:	8082                	ret

0000000080001d20 <proc_pagetable>:
{
    80001d20:	1101                	addi	sp,sp,-32
    80001d22:	ec06                	sd	ra,24(sp)
    80001d24:	e822                	sd	s0,16(sp)
    80001d26:	e426                	sd	s1,8(sp)
    80001d28:	e04a                	sd	s2,0(sp)
    80001d2a:	1000                	addi	s0,sp,32
    80001d2c:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	74c080e7          	jalr	1868(ra) # 8000147a <uvmcreate>
    80001d36:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001d38:	c121                	beqz	a0,80001d78 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d3a:	4729                	li	a4,10
    80001d3c:	00005697          	auipc	a3,0x5
    80001d40:	2c468693          	addi	a3,a3,708 # 80007000 <_trampoline>
    80001d44:	6605                	lui	a2,0x1
    80001d46:	040005b7          	lui	a1,0x4000
    80001d4a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d4c:	05b2                	slli	a1,a1,0xc
    80001d4e:	fffff097          	auipc	ra,0xfffff
    80001d52:	4a2080e7          	jalr	1186(ra) # 800011f0 <mappages>
    80001d56:	02054863          	bltz	a0,80001d86 <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d5a:	4719                	li	a4,6
    80001d5c:	05893683          	ld	a3,88(s2)
    80001d60:	6605                	lui	a2,0x1
    80001d62:	020005b7          	lui	a1,0x2000
    80001d66:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d68:	05b6                	slli	a1,a1,0xd
    80001d6a:	8526                	mv	a0,s1
    80001d6c:	fffff097          	auipc	ra,0xfffff
    80001d70:	484080e7          	jalr	1156(ra) # 800011f0 <mappages>
    80001d74:	02054163          	bltz	a0,80001d96 <proc_pagetable+0x76>
}
    80001d78:	8526                	mv	a0,s1
    80001d7a:	60e2                	ld	ra,24(sp)
    80001d7c:	6442                	ld	s0,16(sp)
    80001d7e:	64a2                	ld	s1,8(sp)
    80001d80:	6902                	ld	s2,0(sp)
    80001d82:	6105                	addi	sp,sp,32
    80001d84:	8082                	ret
        uvmfree(pagetable, 0);
    80001d86:	4581                	li	a1,0
    80001d88:	8526                	mv	a0,s1
    80001d8a:	00000097          	auipc	ra,0x0
    80001d8e:	8f6080e7          	jalr	-1802(ra) # 80001680 <uvmfree>
        return 0;
    80001d92:	4481                	li	s1,0
    80001d94:	b7d5                	j	80001d78 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d96:	4681                	li	a3,0
    80001d98:	4605                	li	a2,1
    80001d9a:	040005b7          	lui	a1,0x4000
    80001d9e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001da0:	05b2                	slli	a1,a1,0xc
    80001da2:	8526                	mv	a0,s1
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	612080e7          	jalr	1554(ra) # 800013b6 <uvmunmap>
        uvmfree(pagetable, 0);
    80001dac:	4581                	li	a1,0
    80001dae:	8526                	mv	a0,s1
    80001db0:	00000097          	auipc	ra,0x0
    80001db4:	8d0080e7          	jalr	-1840(ra) # 80001680 <uvmfree>
        return 0;
    80001db8:	4481                	li	s1,0
    80001dba:	bf7d                	j	80001d78 <proc_pagetable+0x58>

0000000080001dbc <proc_freepagetable>:
{
    80001dbc:	1101                	addi	sp,sp,-32
    80001dbe:	ec06                	sd	ra,24(sp)
    80001dc0:	e822                	sd	s0,16(sp)
    80001dc2:	e426                	sd	s1,8(sp)
    80001dc4:	e04a                	sd	s2,0(sp)
    80001dc6:	1000                	addi	s0,sp,32
    80001dc8:	84aa                	mv	s1,a0
    80001dca:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001dcc:	4681                	li	a3,0
    80001dce:	4605                	li	a2,1
    80001dd0:	040005b7          	lui	a1,0x4000
    80001dd4:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001dd6:	05b2                	slli	a1,a1,0xc
    80001dd8:	fffff097          	auipc	ra,0xfffff
    80001ddc:	5de080e7          	jalr	1502(ra) # 800013b6 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001de0:	4681                	li	a3,0
    80001de2:	4605                	li	a2,1
    80001de4:	020005b7          	lui	a1,0x2000
    80001de8:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001dea:	05b6                	slli	a1,a1,0xd
    80001dec:	8526                	mv	a0,s1
    80001dee:	fffff097          	auipc	ra,0xfffff
    80001df2:	5c8080e7          	jalr	1480(ra) # 800013b6 <uvmunmap>
    uvmfree(pagetable, sz);
    80001df6:	85ca                	mv	a1,s2
    80001df8:	8526                	mv	a0,s1
    80001dfa:	00000097          	auipc	ra,0x0
    80001dfe:	886080e7          	jalr	-1914(ra) # 80001680 <uvmfree>
}
    80001e02:	60e2                	ld	ra,24(sp)
    80001e04:	6442                	ld	s0,16(sp)
    80001e06:	64a2                	ld	s1,8(sp)
    80001e08:	6902                	ld	s2,0(sp)
    80001e0a:	6105                	addi	sp,sp,32
    80001e0c:	8082                	ret

0000000080001e0e <freeproc>:
{
    80001e0e:	1101                	addi	sp,sp,-32
    80001e10:	ec06                	sd	ra,24(sp)
    80001e12:	e822                	sd	s0,16(sp)
    80001e14:	e426                	sd	s1,8(sp)
    80001e16:	1000                	addi	s0,sp,32
    80001e18:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001e1a:	6d28                	ld	a0,88(a0)
    80001e1c:	c509                	beqz	a0,80001e26 <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001e1e:	fffff097          	auipc	ra,0xfffff
    80001e22:	bd8080e7          	jalr	-1064(ra) # 800009f6 <kfree>
    p->trapframe = 0;
    80001e26:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001e2a:	68a8                	ld	a0,80(s1)
    80001e2c:	c511                	beqz	a0,80001e38 <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001e2e:	64ac                	ld	a1,72(s1)
    80001e30:	00000097          	auipc	ra,0x0
    80001e34:	f8c080e7          	jalr	-116(ra) # 80001dbc <proc_freepagetable>
    p->pagetable = 0;
    80001e38:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001e3c:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001e40:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001e44:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001e48:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001e4c:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001e50:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001e54:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001e58:	0004ac23          	sw	zero,24(s1)
}
    80001e5c:	60e2                	ld	ra,24(sp)
    80001e5e:	6442                	ld	s0,16(sp)
    80001e60:	64a2                	ld	s1,8(sp)
    80001e62:	6105                	addi	sp,sp,32
    80001e64:	8082                	ret

0000000080001e66 <allocproc>:
{
    80001e66:	1101                	addi	sp,sp,-32
    80001e68:	ec06                	sd	ra,24(sp)
    80001e6a:	e822                	sd	s0,16(sp)
    80001e6c:	e426                	sd	s1,8(sp)
    80001e6e:	e04a                	sd	s2,0(sp)
    80001e70:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001e72:	0022f497          	auipc	s1,0x22f
    80001e76:	25e48493          	addi	s1,s1,606 # 802310d0 <proc>
    80001e7a:	00235917          	auipc	s2,0x235
    80001e7e:	c5690913          	addi	s2,s2,-938 # 80236ad0 <tickslock>
        acquire(&p->lock);
    80001e82:	8526                	mv	a0,s1
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	ea6080e7          	jalr	-346(ra) # 80000d2a <acquire>
        if (p->state == UNUSED)
    80001e8c:	4c9c                	lw	a5,24(s1)
    80001e8e:	cf81                	beqz	a5,80001ea6 <allocproc+0x40>
            release(&p->lock);
    80001e90:	8526                	mv	a0,s1
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	f4c080e7          	jalr	-180(ra) # 80000dde <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001e9a:	16848493          	addi	s1,s1,360
    80001e9e:	ff2492e3          	bne	s1,s2,80001e82 <allocproc+0x1c>
    return 0;
    80001ea2:	4481                	li	s1,0
    80001ea4:	a889                	j	80001ef6 <allocproc+0x90>
    p->pid = allocpid();
    80001ea6:	00000097          	auipc	ra,0x0
    80001eaa:	e34080e7          	jalr	-460(ra) # 80001cda <allocpid>
    80001eae:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001eb0:	4785                	li	a5,1
    80001eb2:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	cd6080e7          	jalr	-810(ra) # 80000b8a <kalloc>
    80001ebc:	892a                	mv	s2,a0
    80001ebe:	eca8                	sd	a0,88(s1)
    80001ec0:	c131                	beqz	a0,80001f04 <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001ec2:	8526                	mv	a0,s1
    80001ec4:	00000097          	auipc	ra,0x0
    80001ec8:	e5c080e7          	jalr	-420(ra) # 80001d20 <proc_pagetable>
    80001ecc:	892a                	mv	s2,a0
    80001ece:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001ed0:	c531                	beqz	a0,80001f1c <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001ed2:	07000613          	li	a2,112
    80001ed6:	4581                	li	a1,0
    80001ed8:	06048513          	addi	a0,s1,96
    80001edc:	fffff097          	auipc	ra,0xfffff
    80001ee0:	f4a080e7          	jalr	-182(ra) # 80000e26 <memset>
    p->context.ra = (uint64)forkret;
    80001ee4:	00000797          	auipc	a5,0x0
    80001ee8:	db078793          	addi	a5,a5,-592 # 80001c94 <forkret>
    80001eec:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001eee:	60bc                	ld	a5,64(s1)
    80001ef0:	6705                	lui	a4,0x1
    80001ef2:	97ba                	add	a5,a5,a4
    80001ef4:	f4bc                	sd	a5,104(s1)
}
    80001ef6:	8526                	mv	a0,s1
    80001ef8:	60e2                	ld	ra,24(sp)
    80001efa:	6442                	ld	s0,16(sp)
    80001efc:	64a2                	ld	s1,8(sp)
    80001efe:	6902                	ld	s2,0(sp)
    80001f00:	6105                	addi	sp,sp,32
    80001f02:	8082                	ret
        freeproc(p);
    80001f04:	8526                	mv	a0,s1
    80001f06:	00000097          	auipc	ra,0x0
    80001f0a:	f08080e7          	jalr	-248(ra) # 80001e0e <freeproc>
        release(&p->lock);
    80001f0e:	8526                	mv	a0,s1
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	ece080e7          	jalr	-306(ra) # 80000dde <release>
        return 0;
    80001f18:	84ca                	mv	s1,s2
    80001f1a:	bff1                	j	80001ef6 <allocproc+0x90>
        freeproc(p);
    80001f1c:	8526                	mv	a0,s1
    80001f1e:	00000097          	auipc	ra,0x0
    80001f22:	ef0080e7          	jalr	-272(ra) # 80001e0e <freeproc>
        release(&p->lock);
    80001f26:	8526                	mv	a0,s1
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	eb6080e7          	jalr	-330(ra) # 80000dde <release>
        return 0;
    80001f30:	84ca                	mv	s1,s2
    80001f32:	b7d1                	j	80001ef6 <allocproc+0x90>

0000000080001f34 <userinit>:
{
    80001f34:	1101                	addi	sp,sp,-32
    80001f36:	ec06                	sd	ra,24(sp)
    80001f38:	e822                	sd	s0,16(sp)
    80001f3a:	e426                	sd	s1,8(sp)
    80001f3c:	1000                	addi	s0,sp,32
    p = allocproc();
    80001f3e:	00000097          	auipc	ra,0x0
    80001f42:	f28080e7          	jalr	-216(ra) # 80001e66 <allocproc>
    80001f46:	84aa                	mv	s1,a0
    initproc = p;
    80001f48:	00007797          	auipc	a5,0x7
    80001f4c:	aea7b023          	sd	a0,-1312(a5) # 80008a28 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001f50:	03400613          	li	a2,52
    80001f54:	00007597          	auipc	a1,0x7
    80001f58:	a3c58593          	addi	a1,a1,-1476 # 80008990 <initcode>
    80001f5c:	6928                	ld	a0,80(a0)
    80001f5e:	fffff097          	auipc	ra,0xfffff
    80001f62:	54a080e7          	jalr	1354(ra) # 800014a8 <uvmfirst>
    p->sz = PGSIZE;
    80001f66:	6785                	lui	a5,0x1
    80001f68:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80001f6a:	6cb8                	ld	a4,88(s1)
    80001f6c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001f70:	6cb8                	ld	a4,88(s1)
    80001f72:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f74:	4641                	li	a2,16
    80001f76:	00006597          	auipc	a1,0x6
    80001f7a:	2c258593          	addi	a1,a1,706 # 80008238 <digits+0x1f8>
    80001f7e:	15848513          	addi	a0,s1,344
    80001f82:	fffff097          	auipc	ra,0xfffff
    80001f86:	fec080e7          	jalr	-20(ra) # 80000f6e <safestrcpy>
    p->cwd = namei("/");
    80001f8a:	00006517          	auipc	a0,0x6
    80001f8e:	2be50513          	addi	a0,a0,702 # 80008248 <digits+0x208>
    80001f92:	00002097          	auipc	ra,0x2
    80001f96:	450080e7          	jalr	1104(ra) # 800043e2 <namei>
    80001f9a:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    80001f9e:	478d                	li	a5,3
    80001fa0:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001fa2:	8526                	mv	a0,s1
    80001fa4:	fffff097          	auipc	ra,0xfffff
    80001fa8:	e3a080e7          	jalr	-454(ra) # 80000dde <release>
}
    80001fac:	60e2                	ld	ra,24(sp)
    80001fae:	6442                	ld	s0,16(sp)
    80001fb0:	64a2                	ld	s1,8(sp)
    80001fb2:	6105                	addi	sp,sp,32
    80001fb4:	8082                	ret

0000000080001fb6 <growproc>:
{
    80001fb6:	1101                	addi	sp,sp,-32
    80001fb8:	ec06                	sd	ra,24(sp)
    80001fba:	e822                	sd	s0,16(sp)
    80001fbc:	e426                	sd	s1,8(sp)
    80001fbe:	e04a                	sd	s2,0(sp)
    80001fc0:	1000                	addi	s0,sp,32
    80001fc2:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001fc4:	00000097          	auipc	ra,0x0
    80001fc8:	c98080e7          	jalr	-872(ra) # 80001c5c <myproc>
    80001fcc:	84aa                	mv	s1,a0
    sz = p->sz;
    80001fce:	652c                	ld	a1,72(a0)
    if (n > 0)
    80001fd0:	01204c63          	bgtz	s2,80001fe8 <growproc+0x32>
    else if (n < 0)
    80001fd4:	02094663          	bltz	s2,80002000 <growproc+0x4a>
    p->sz = sz;
    80001fd8:	e4ac                	sd	a1,72(s1)
    return 0;
    80001fda:	4501                	li	a0,0
}
    80001fdc:	60e2                	ld	ra,24(sp)
    80001fde:	6442                	ld	s0,16(sp)
    80001fe0:	64a2                	ld	s1,8(sp)
    80001fe2:	6902                	ld	s2,0(sp)
    80001fe4:	6105                	addi	sp,sp,32
    80001fe6:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001fe8:	4691                	li	a3,4
    80001fea:	00b90633          	add	a2,s2,a1
    80001fee:	6928                	ld	a0,80(a0)
    80001ff0:	fffff097          	auipc	ra,0xfffff
    80001ff4:	572080e7          	jalr	1394(ra) # 80001562 <uvmalloc>
    80001ff8:	85aa                	mv	a1,a0
    80001ffa:	fd79                	bnez	a0,80001fd8 <growproc+0x22>
            return -1;
    80001ffc:	557d                	li	a0,-1
    80001ffe:	bff9                	j	80001fdc <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002000:	00b90633          	add	a2,s2,a1
    80002004:	6928                	ld	a0,80(a0)
    80002006:	fffff097          	auipc	ra,0xfffff
    8000200a:	514080e7          	jalr	1300(ra) # 8000151a <uvmdealloc>
    8000200e:	85aa                	mv	a1,a0
    80002010:	b7e1                	j	80001fd8 <growproc+0x22>

0000000080002012 <ps>:
{
    80002012:	715d                	addi	sp,sp,-80
    80002014:	e486                	sd	ra,72(sp)
    80002016:	e0a2                	sd	s0,64(sp)
    80002018:	fc26                	sd	s1,56(sp)
    8000201a:	f84a                	sd	s2,48(sp)
    8000201c:	f44e                	sd	s3,40(sp)
    8000201e:	f052                	sd	s4,32(sp)
    80002020:	ec56                	sd	s5,24(sp)
    80002022:	e85a                	sd	s6,16(sp)
    80002024:	e45e                	sd	s7,8(sp)
    80002026:	e062                	sd	s8,0(sp)
    80002028:	0880                	addi	s0,sp,80
    8000202a:	84aa                	mv	s1,a0
    8000202c:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    8000202e:	00000097          	auipc	ra,0x0
    80002032:	c2e080e7          	jalr	-978(ra) # 80001c5c <myproc>
    if (count == 0)
    80002036:	120b8063          	beqz	s7,80002156 <ps+0x144>
    void *result = (void *)myproc()->sz;
    8000203a:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    8000203e:	003b951b          	slliw	a0,s7,0x3
    80002042:	0175053b          	addw	a0,a0,s7
    80002046:	0025151b          	slliw	a0,a0,0x2
    8000204a:	00000097          	auipc	ra,0x0
    8000204e:	f6c080e7          	jalr	-148(ra) # 80001fb6 <growproc>
    80002052:	10054463          	bltz	a0,8000215a <ps+0x148>
    struct user_proc loc_result[count];
    80002056:	003b9a13          	slli	s4,s7,0x3
    8000205a:	9a5e                	add	s4,s4,s7
    8000205c:	0a0a                	slli	s4,s4,0x2
    8000205e:	00fa0793          	addi	a5,s4,15
    80002062:	8391                	srli	a5,a5,0x4
    80002064:	0792                	slli	a5,a5,0x4
    80002066:	40f10133          	sub	sp,sp,a5
    8000206a:	8a8a                	mv	s5,sp
    struct proc *p = proc + (start * sizeof(proc));
    8000206c:	007e97b7          	lui	a5,0x7e9
    80002070:	02f484b3          	mul	s1,s1,a5
    80002074:	0022f797          	auipc	a5,0x22f
    80002078:	05c78793          	addi	a5,a5,92 # 802310d0 <proc>
    8000207c:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    8000207e:	00235797          	auipc	a5,0x235
    80002082:	a5278793          	addi	a5,a5,-1454 # 80236ad0 <tickslock>
    80002086:	0cf4fc63          	bgeu	s1,a5,8000215e <ps+0x14c>
        if (localCount == count)
    8000208a:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    8000208e:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    80002090:	8c3e                	mv	s8,a5
    80002092:	a069                	j	8000211c <ps+0x10a>
            loc_result[localCount].state = UNUSED;
    80002094:	00399793          	slli	a5,s3,0x3
    80002098:	97ce                	add	a5,a5,s3
    8000209a:	078a                	slli	a5,a5,0x2
    8000209c:	97d6                	add	a5,a5,s5
    8000209e:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    800020a2:	8526                	mv	a0,s1
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	d3a080e7          	jalr	-710(ra) # 80000dde <release>
    if (localCount < count)
    800020ac:	0179f963          	bgeu	s3,s7,800020be <ps+0xac>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    800020b0:	00399793          	slli	a5,s3,0x3
    800020b4:	97ce                	add	a5,a5,s3
    800020b6:	078a                	slli	a5,a5,0x2
    800020b8:	97d6                	add	a5,a5,s5
    800020ba:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    800020be:	84da                	mv	s1,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    800020c0:	00000097          	auipc	ra,0x0
    800020c4:	b9c080e7          	jalr	-1124(ra) # 80001c5c <myproc>
    800020c8:	86d2                	mv	a3,s4
    800020ca:	8656                	mv	a2,s5
    800020cc:	85da                	mv	a1,s6
    800020ce:	6928                	ld	a0,80(a0)
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	6d4080e7          	jalr	1748(ra) # 800017a4 <copyout>
}
    800020d8:	8526                	mv	a0,s1
    800020da:	fb040113          	addi	sp,s0,-80
    800020de:	60a6                	ld	ra,72(sp)
    800020e0:	6406                	ld	s0,64(sp)
    800020e2:	74e2                	ld	s1,56(sp)
    800020e4:	7942                	ld	s2,48(sp)
    800020e6:	79a2                	ld	s3,40(sp)
    800020e8:	7a02                	ld	s4,32(sp)
    800020ea:	6ae2                	ld	s5,24(sp)
    800020ec:	6b42                	ld	s6,16(sp)
    800020ee:	6ba2                	ld	s7,8(sp)
    800020f0:	6c02                	ld	s8,0(sp)
    800020f2:	6161                	addi	sp,sp,80
    800020f4:	8082                	ret
            loc_result[localCount].parent_id = p->parent->pid;
    800020f6:	5b9c                	lw	a5,48(a5)
    800020f8:	fef92e23          	sw	a5,-4(s2)
        release(&p->lock);
    800020fc:	8526                	mv	a0,s1
    800020fe:	fffff097          	auipc	ra,0xfffff
    80002102:	ce0080e7          	jalr	-800(ra) # 80000dde <release>
        localCount++;
    80002106:	2985                	addiw	s3,s3,1
    80002108:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    8000210c:	16848493          	addi	s1,s1,360
    80002110:	f984fee3          	bgeu	s1,s8,800020ac <ps+0x9a>
        if (localCount == count)
    80002114:	02490913          	addi	s2,s2,36
    80002118:	fb3b83e3          	beq	s7,s3,800020be <ps+0xac>
        acquire(&p->lock);
    8000211c:	8526                	mv	a0,s1
    8000211e:	fffff097          	auipc	ra,0xfffff
    80002122:	c0c080e7          	jalr	-1012(ra) # 80000d2a <acquire>
        if (p->state == UNUSED)
    80002126:	4c9c                	lw	a5,24(s1)
    80002128:	d7b5                	beqz	a5,80002094 <ps+0x82>
        loc_result[localCount].state = p->state;
    8000212a:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    8000212e:	549c                	lw	a5,40(s1)
    80002130:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    80002134:	54dc                	lw	a5,44(s1)
    80002136:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    8000213a:	589c                	lw	a5,48(s1)
    8000213c:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    80002140:	4641                	li	a2,16
    80002142:	85ca                	mv	a1,s2
    80002144:	15848513          	addi	a0,s1,344
    80002148:	00000097          	auipc	ra,0x0
    8000214c:	ac4080e7          	jalr	-1340(ra) # 80001c0c <copy_array>
        if (p->parent != 0) // init
    80002150:	7c9c                	ld	a5,56(s1)
    80002152:	f3d5                	bnez	a5,800020f6 <ps+0xe4>
    80002154:	b765                	j	800020fc <ps+0xea>
        return result;
    80002156:	4481                	li	s1,0
    80002158:	b741                	j	800020d8 <ps+0xc6>
        return result;
    8000215a:	4481                	li	s1,0
    8000215c:	bfb5                	j	800020d8 <ps+0xc6>
        return result;
    8000215e:	4481                	li	s1,0
    80002160:	bfa5                	j	800020d8 <ps+0xc6>

0000000080002162 <fork>:
{
    80002162:	7139                	addi	sp,sp,-64
    80002164:	fc06                	sd	ra,56(sp)
    80002166:	f822                	sd	s0,48(sp)
    80002168:	f426                	sd	s1,40(sp)
    8000216a:	f04a                	sd	s2,32(sp)
    8000216c:	ec4e                	sd	s3,24(sp)
    8000216e:	e852                	sd	s4,16(sp)
    80002170:	e456                	sd	s5,8(sp)
    80002172:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    80002174:	00000097          	auipc	ra,0x0
    80002178:	ae8080e7          	jalr	-1304(ra) # 80001c5c <myproc>
    8000217c:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    8000217e:	00000097          	auipc	ra,0x0
    80002182:	ce8080e7          	jalr	-792(ra) # 80001e66 <allocproc>
    80002186:	10050c63          	beqz	a0,8000229e <fork+0x13c>
    8000218a:	8a2a                	mv	s4,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    8000218c:	048ab603          	ld	a2,72(s5)
    80002190:	692c                	ld	a1,80(a0)
    80002192:	050ab503          	ld	a0,80(s5)
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	524080e7          	jalr	1316(ra) # 800016ba <uvmcopy>
    8000219e:	04054863          	bltz	a0,800021ee <fork+0x8c>
    np->sz = p->sz;
    800021a2:	048ab783          	ld	a5,72(s5)
    800021a6:	04fa3423          	sd	a5,72(s4)
    *(np->trapframe) = *(p->trapframe);
    800021aa:	058ab683          	ld	a3,88(s5)
    800021ae:	87b6                	mv	a5,a3
    800021b0:	058a3703          	ld	a4,88(s4)
    800021b4:	12068693          	addi	a3,a3,288
    800021b8:	0007b803          	ld	a6,0(a5)
    800021bc:	6788                	ld	a0,8(a5)
    800021be:	6b8c                	ld	a1,16(a5)
    800021c0:	6f90                	ld	a2,24(a5)
    800021c2:	01073023          	sd	a6,0(a4)
    800021c6:	e708                	sd	a0,8(a4)
    800021c8:	eb0c                	sd	a1,16(a4)
    800021ca:	ef10                	sd	a2,24(a4)
    800021cc:	02078793          	addi	a5,a5,32
    800021d0:	02070713          	addi	a4,a4,32
    800021d4:	fed792e3          	bne	a5,a3,800021b8 <fork+0x56>
    np->trapframe->a0 = 0;
    800021d8:	058a3783          	ld	a5,88(s4)
    800021dc:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    800021e0:	0d0a8493          	addi	s1,s5,208
    800021e4:	0d0a0913          	addi	s2,s4,208
    800021e8:	150a8993          	addi	s3,s5,336
    800021ec:	a00d                	j	8000220e <fork+0xac>
        freeproc(np);
    800021ee:	8552                	mv	a0,s4
    800021f0:	00000097          	auipc	ra,0x0
    800021f4:	c1e080e7          	jalr	-994(ra) # 80001e0e <freeproc>
        release(&np->lock);
    800021f8:	8552                	mv	a0,s4
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	be4080e7          	jalr	-1052(ra) # 80000dde <release>
        return -1;
    80002202:	597d                	li	s2,-1
    80002204:	a059                	j	8000228a <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    80002206:	04a1                	addi	s1,s1,8
    80002208:	0921                	addi	s2,s2,8
    8000220a:	01348b63          	beq	s1,s3,80002220 <fork+0xbe>
        if (p->ofile[i])
    8000220e:	6088                	ld	a0,0(s1)
    80002210:	d97d                	beqz	a0,80002206 <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    80002212:	00003097          	auipc	ra,0x3
    80002216:	842080e7          	jalr	-1982(ra) # 80004a54 <filedup>
    8000221a:	00a93023          	sd	a0,0(s2)
    8000221e:	b7e5                	j	80002206 <fork+0xa4>
    np->cwd = idup(p->cwd);
    80002220:	150ab503          	ld	a0,336(s5)
    80002224:	00002097          	auipc	ra,0x2
    80002228:	9da080e7          	jalr	-1574(ra) # 80003bfe <idup>
    8000222c:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    80002230:	4641                	li	a2,16
    80002232:	158a8593          	addi	a1,s5,344
    80002236:	158a0513          	addi	a0,s4,344
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	d34080e7          	jalr	-716(ra) # 80000f6e <safestrcpy>
    pid = np->pid;
    80002242:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    80002246:	8552                	mv	a0,s4
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	b96080e7          	jalr	-1130(ra) # 80000dde <release>
    acquire(&wait_lock);
    80002250:	0022f497          	auipc	s1,0x22f
    80002254:	e6848493          	addi	s1,s1,-408 # 802310b8 <wait_lock>
    80002258:	8526                	mv	a0,s1
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	ad0080e7          	jalr	-1328(ra) # 80000d2a <acquire>
    np->parent = p;
    80002262:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    80002266:	8526                	mv	a0,s1
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	b76080e7          	jalr	-1162(ra) # 80000dde <release>
    acquire(&np->lock);
    80002270:	8552                	mv	a0,s4
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	ab8080e7          	jalr	-1352(ra) # 80000d2a <acquire>
    np->state = RUNNABLE;
    8000227a:	478d                	li	a5,3
    8000227c:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    80002280:	8552                	mv	a0,s4
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	b5c080e7          	jalr	-1188(ra) # 80000dde <release>
}
    8000228a:	854a                	mv	a0,s2
    8000228c:	70e2                	ld	ra,56(sp)
    8000228e:	7442                	ld	s0,48(sp)
    80002290:	74a2                	ld	s1,40(sp)
    80002292:	7902                	ld	s2,32(sp)
    80002294:	69e2                	ld	s3,24(sp)
    80002296:	6a42                	ld	s4,16(sp)
    80002298:	6aa2                	ld	s5,8(sp)
    8000229a:	6121                	addi	sp,sp,64
    8000229c:	8082                	ret
        return -1;
    8000229e:	597d                	li	s2,-1
    800022a0:	b7ed                	j	8000228a <fork+0x128>

00000000800022a2 <scheduler>:
{
    800022a2:	1101                	addi	sp,sp,-32
    800022a4:	ec06                	sd	ra,24(sp)
    800022a6:	e822                	sd	s0,16(sp)
    800022a8:	e426                	sd	s1,8(sp)
    800022aa:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    800022ac:	00006497          	auipc	s1,0x6
    800022b0:	6cc48493          	addi	s1,s1,1740 # 80008978 <sched_pointer>
    800022b4:	609c                	ld	a5,0(s1)
    800022b6:	9782                	jalr	a5
    while (1)
    800022b8:	bff5                	j	800022b4 <scheduler+0x12>

00000000800022ba <sched>:
{
    800022ba:	7179                	addi	sp,sp,-48
    800022bc:	f406                	sd	ra,40(sp)
    800022be:	f022                	sd	s0,32(sp)
    800022c0:	ec26                	sd	s1,24(sp)
    800022c2:	e84a                	sd	s2,16(sp)
    800022c4:	e44e                	sd	s3,8(sp)
    800022c6:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    800022c8:	00000097          	auipc	ra,0x0
    800022cc:	994080e7          	jalr	-1644(ra) # 80001c5c <myproc>
    800022d0:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	9de080e7          	jalr	-1570(ra) # 80000cb0 <holding>
    800022da:	c53d                	beqz	a0,80002348 <sched+0x8e>
    800022dc:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    800022de:	2781                	sext.w	a5,a5
    800022e0:	079e                	slli	a5,a5,0x7
    800022e2:	0022f717          	auipc	a4,0x22f
    800022e6:	9be70713          	addi	a4,a4,-1602 # 80230ca0 <cpus>
    800022ea:	97ba                	add	a5,a5,a4
    800022ec:	5fb8                	lw	a4,120(a5)
    800022ee:	4785                	li	a5,1
    800022f0:	06f71463          	bne	a4,a5,80002358 <sched+0x9e>
    if (p->state == RUNNING)
    800022f4:	4c98                	lw	a4,24(s1)
    800022f6:	4791                	li	a5,4
    800022f8:	06f70863          	beq	a4,a5,80002368 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022fc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002300:	8b89                	andi	a5,a5,2
    if (intr_get())
    80002302:	ebbd                	bnez	a5,80002378 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002304:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    80002306:	0022f917          	auipc	s2,0x22f
    8000230a:	99a90913          	addi	s2,s2,-1638 # 80230ca0 <cpus>
    8000230e:	2781                	sext.w	a5,a5
    80002310:	079e                	slli	a5,a5,0x7
    80002312:	97ca                	add	a5,a5,s2
    80002314:	07c7a983          	lw	s3,124(a5)
    80002318:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    8000231a:	2581                	sext.w	a1,a1
    8000231c:	059e                	slli	a1,a1,0x7
    8000231e:	05a1                	addi	a1,a1,8
    80002320:	95ca                	add	a1,a1,s2
    80002322:	06048513          	addi	a0,s1,96
    80002326:	00000097          	auipc	ra,0x0
    8000232a:	744080e7          	jalr	1860(ra) # 80002a6a <swtch>
    8000232e:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    80002330:	2781                	sext.w	a5,a5
    80002332:	079e                	slli	a5,a5,0x7
    80002334:	993e                	add	s2,s2,a5
    80002336:	07392e23          	sw	s3,124(s2)
}
    8000233a:	70a2                	ld	ra,40(sp)
    8000233c:	7402                	ld	s0,32(sp)
    8000233e:	64e2                	ld	s1,24(sp)
    80002340:	6942                	ld	s2,16(sp)
    80002342:	69a2                	ld	s3,8(sp)
    80002344:	6145                	addi	sp,sp,48
    80002346:	8082                	ret
        panic("sched p->lock");
    80002348:	00006517          	auipc	a0,0x6
    8000234c:	f0850513          	addi	a0,a0,-248 # 80008250 <digits+0x210>
    80002350:	ffffe097          	auipc	ra,0xffffe
    80002354:	1ec080e7          	jalr	492(ra) # 8000053c <panic>
        panic("sched locks");
    80002358:	00006517          	auipc	a0,0x6
    8000235c:	f0850513          	addi	a0,a0,-248 # 80008260 <digits+0x220>
    80002360:	ffffe097          	auipc	ra,0xffffe
    80002364:	1dc080e7          	jalr	476(ra) # 8000053c <panic>
        panic("sched running");
    80002368:	00006517          	auipc	a0,0x6
    8000236c:	f0850513          	addi	a0,a0,-248 # 80008270 <digits+0x230>
    80002370:	ffffe097          	auipc	ra,0xffffe
    80002374:	1cc080e7          	jalr	460(ra) # 8000053c <panic>
        panic("sched interruptible");
    80002378:	00006517          	auipc	a0,0x6
    8000237c:	f0850513          	addi	a0,a0,-248 # 80008280 <digits+0x240>
    80002380:	ffffe097          	auipc	ra,0xffffe
    80002384:	1bc080e7          	jalr	444(ra) # 8000053c <panic>

0000000080002388 <yield>:
{
    80002388:	1101                	addi	sp,sp,-32
    8000238a:	ec06                	sd	ra,24(sp)
    8000238c:	e822                	sd	s0,16(sp)
    8000238e:	e426                	sd	s1,8(sp)
    80002390:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80002392:	00000097          	auipc	ra,0x0
    80002396:	8ca080e7          	jalr	-1846(ra) # 80001c5c <myproc>
    8000239a:	84aa                	mv	s1,a0
    acquire(&p->lock);
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	98e080e7          	jalr	-1650(ra) # 80000d2a <acquire>
    p->state = RUNNABLE;
    800023a4:	478d                	li	a5,3
    800023a6:	cc9c                	sw	a5,24(s1)
    sched();
    800023a8:	00000097          	auipc	ra,0x0
    800023ac:	f12080e7          	jalr	-238(ra) # 800022ba <sched>
    release(&p->lock);
    800023b0:	8526                	mv	a0,s1
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	a2c080e7          	jalr	-1492(ra) # 80000dde <release>
}
    800023ba:	60e2                	ld	ra,24(sp)
    800023bc:	6442                	ld	s0,16(sp)
    800023be:	64a2                	ld	s1,8(sp)
    800023c0:	6105                	addi	sp,sp,32
    800023c2:	8082                	ret

00000000800023c4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800023c4:	7179                	addi	sp,sp,-48
    800023c6:	f406                	sd	ra,40(sp)
    800023c8:	f022                	sd	s0,32(sp)
    800023ca:	ec26                	sd	s1,24(sp)
    800023cc:	e84a                	sd	s2,16(sp)
    800023ce:	e44e                	sd	s3,8(sp)
    800023d0:	1800                	addi	s0,sp,48
    800023d2:	89aa                	mv	s3,a0
    800023d4:	892e                	mv	s2,a1
    struct proc *p = myproc();
    800023d6:	00000097          	auipc	ra,0x0
    800023da:	886080e7          	jalr	-1914(ra) # 80001c5c <myproc>
    800023de:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	94a080e7          	jalr	-1718(ra) # 80000d2a <acquire>
    release(lk);
    800023e8:	854a                	mv	a0,s2
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	9f4080e7          	jalr	-1548(ra) # 80000dde <release>

    // Go to sleep.
    p->chan = chan;
    800023f2:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    800023f6:	4789                	li	a5,2
    800023f8:	cc9c                	sw	a5,24(s1)

    sched();
    800023fa:	00000097          	auipc	ra,0x0
    800023fe:	ec0080e7          	jalr	-320(ra) # 800022ba <sched>

    // Tidy up.
    p->chan = 0;
    80002402:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	9d6080e7          	jalr	-1578(ra) # 80000dde <release>
    acquire(lk);
    80002410:	854a                	mv	a0,s2
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	918080e7          	jalr	-1768(ra) # 80000d2a <acquire>
}
    8000241a:	70a2                	ld	ra,40(sp)
    8000241c:	7402                	ld	s0,32(sp)
    8000241e:	64e2                	ld	s1,24(sp)
    80002420:	6942                	ld	s2,16(sp)
    80002422:	69a2                	ld	s3,8(sp)
    80002424:	6145                	addi	sp,sp,48
    80002426:	8082                	ret

0000000080002428 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002428:	7139                	addi	sp,sp,-64
    8000242a:	fc06                	sd	ra,56(sp)
    8000242c:	f822                	sd	s0,48(sp)
    8000242e:	f426                	sd	s1,40(sp)
    80002430:	f04a                	sd	s2,32(sp)
    80002432:	ec4e                	sd	s3,24(sp)
    80002434:	e852                	sd	s4,16(sp)
    80002436:	e456                	sd	s5,8(sp)
    80002438:	0080                	addi	s0,sp,64
    8000243a:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    8000243c:	0022f497          	auipc	s1,0x22f
    80002440:	c9448493          	addi	s1,s1,-876 # 802310d0 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    80002444:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    80002446:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    80002448:	00234917          	auipc	s2,0x234
    8000244c:	68890913          	addi	s2,s2,1672 # 80236ad0 <tickslock>
    80002450:	a811                	j	80002464 <wakeup+0x3c>
            }
            release(&p->lock);
    80002452:	8526                	mv	a0,s1
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	98a080e7          	jalr	-1654(ra) # 80000dde <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000245c:	16848493          	addi	s1,s1,360
    80002460:	03248663          	beq	s1,s2,8000248c <wakeup+0x64>
        if (p != myproc())
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	7f8080e7          	jalr	2040(ra) # 80001c5c <myproc>
    8000246c:	fea488e3          	beq	s1,a0,8000245c <wakeup+0x34>
            acquire(&p->lock);
    80002470:	8526                	mv	a0,s1
    80002472:	fffff097          	auipc	ra,0xfffff
    80002476:	8b8080e7          	jalr	-1864(ra) # 80000d2a <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    8000247a:	4c9c                	lw	a5,24(s1)
    8000247c:	fd379be3          	bne	a5,s3,80002452 <wakeup+0x2a>
    80002480:	709c                	ld	a5,32(s1)
    80002482:	fd4798e3          	bne	a5,s4,80002452 <wakeup+0x2a>
                p->state = RUNNABLE;
    80002486:	0154ac23          	sw	s5,24(s1)
    8000248a:	b7e1                	j	80002452 <wakeup+0x2a>
        }
    }
}
    8000248c:	70e2                	ld	ra,56(sp)
    8000248e:	7442                	ld	s0,48(sp)
    80002490:	74a2                	ld	s1,40(sp)
    80002492:	7902                	ld	s2,32(sp)
    80002494:	69e2                	ld	s3,24(sp)
    80002496:	6a42                	ld	s4,16(sp)
    80002498:	6aa2                	ld	s5,8(sp)
    8000249a:	6121                	addi	sp,sp,64
    8000249c:	8082                	ret

000000008000249e <reparent>:
{
    8000249e:	7179                	addi	sp,sp,-48
    800024a0:	f406                	sd	ra,40(sp)
    800024a2:	f022                	sd	s0,32(sp)
    800024a4:	ec26                	sd	s1,24(sp)
    800024a6:	e84a                	sd	s2,16(sp)
    800024a8:	e44e                	sd	s3,8(sp)
    800024aa:	e052                	sd	s4,0(sp)
    800024ac:	1800                	addi	s0,sp,48
    800024ae:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024b0:	0022f497          	auipc	s1,0x22f
    800024b4:	c2048493          	addi	s1,s1,-992 # 802310d0 <proc>
            pp->parent = initproc;
    800024b8:	00006a17          	auipc	s4,0x6
    800024bc:	570a0a13          	addi	s4,s4,1392 # 80008a28 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024c0:	00234997          	auipc	s3,0x234
    800024c4:	61098993          	addi	s3,s3,1552 # 80236ad0 <tickslock>
    800024c8:	a029                	j	800024d2 <reparent+0x34>
    800024ca:	16848493          	addi	s1,s1,360
    800024ce:	01348d63          	beq	s1,s3,800024e8 <reparent+0x4a>
        if (pp->parent == p)
    800024d2:	7c9c                	ld	a5,56(s1)
    800024d4:	ff279be3          	bne	a5,s2,800024ca <reparent+0x2c>
            pp->parent = initproc;
    800024d8:	000a3503          	ld	a0,0(s4)
    800024dc:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    800024de:	00000097          	auipc	ra,0x0
    800024e2:	f4a080e7          	jalr	-182(ra) # 80002428 <wakeup>
    800024e6:	b7d5                	j	800024ca <reparent+0x2c>
}
    800024e8:	70a2                	ld	ra,40(sp)
    800024ea:	7402                	ld	s0,32(sp)
    800024ec:	64e2                	ld	s1,24(sp)
    800024ee:	6942                	ld	s2,16(sp)
    800024f0:	69a2                	ld	s3,8(sp)
    800024f2:	6a02                	ld	s4,0(sp)
    800024f4:	6145                	addi	sp,sp,48
    800024f6:	8082                	ret

00000000800024f8 <exit>:
{
    800024f8:	7179                	addi	sp,sp,-48
    800024fa:	f406                	sd	ra,40(sp)
    800024fc:	f022                	sd	s0,32(sp)
    800024fe:	ec26                	sd	s1,24(sp)
    80002500:	e84a                	sd	s2,16(sp)
    80002502:	e44e                	sd	s3,8(sp)
    80002504:	e052                	sd	s4,0(sp)
    80002506:	1800                	addi	s0,sp,48
    80002508:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    8000250a:	fffff097          	auipc	ra,0xfffff
    8000250e:	752080e7          	jalr	1874(ra) # 80001c5c <myproc>
    80002512:	89aa                	mv	s3,a0
    if (p == initproc)
    80002514:	00006797          	auipc	a5,0x6
    80002518:	5147b783          	ld	a5,1300(a5) # 80008a28 <initproc>
    8000251c:	0d050493          	addi	s1,a0,208
    80002520:	15050913          	addi	s2,a0,336
    80002524:	02a79363          	bne	a5,a0,8000254a <exit+0x52>
        panic("init exiting");
    80002528:	00006517          	auipc	a0,0x6
    8000252c:	d7050513          	addi	a0,a0,-656 # 80008298 <digits+0x258>
    80002530:	ffffe097          	auipc	ra,0xffffe
    80002534:	00c080e7          	jalr	12(ra) # 8000053c <panic>
            fileclose(f);
    80002538:	00002097          	auipc	ra,0x2
    8000253c:	56e080e7          	jalr	1390(ra) # 80004aa6 <fileclose>
            p->ofile[fd] = 0;
    80002540:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    80002544:	04a1                	addi	s1,s1,8
    80002546:	01248563          	beq	s1,s2,80002550 <exit+0x58>
        if (p->ofile[fd])
    8000254a:	6088                	ld	a0,0(s1)
    8000254c:	f575                	bnez	a0,80002538 <exit+0x40>
    8000254e:	bfdd                	j	80002544 <exit+0x4c>
    begin_op();
    80002550:	00002097          	auipc	ra,0x2
    80002554:	092080e7          	jalr	146(ra) # 800045e2 <begin_op>
    iput(p->cwd);
    80002558:	1509b503          	ld	a0,336(s3)
    8000255c:	00002097          	auipc	ra,0x2
    80002560:	89a080e7          	jalr	-1894(ra) # 80003df6 <iput>
    end_op();
    80002564:	00002097          	auipc	ra,0x2
    80002568:	0f8080e7          	jalr	248(ra) # 8000465c <end_op>
    p->cwd = 0;
    8000256c:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    80002570:	0022f497          	auipc	s1,0x22f
    80002574:	b4848493          	addi	s1,s1,-1208 # 802310b8 <wait_lock>
    80002578:	8526                	mv	a0,s1
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	7b0080e7          	jalr	1968(ra) # 80000d2a <acquire>
    reparent(p);
    80002582:	854e                	mv	a0,s3
    80002584:	00000097          	auipc	ra,0x0
    80002588:	f1a080e7          	jalr	-230(ra) # 8000249e <reparent>
    wakeup(p->parent);
    8000258c:	0389b503          	ld	a0,56(s3)
    80002590:	00000097          	auipc	ra,0x0
    80002594:	e98080e7          	jalr	-360(ra) # 80002428 <wakeup>
    acquire(&p->lock);
    80002598:	854e                	mv	a0,s3
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	790080e7          	jalr	1936(ra) # 80000d2a <acquire>
    p->xstate = status;
    800025a2:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    800025a6:	4795                	li	a5,5
    800025a8:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    800025ac:	8526                	mv	a0,s1
    800025ae:	fffff097          	auipc	ra,0xfffff
    800025b2:	830080e7          	jalr	-2000(ra) # 80000dde <release>
    sched();
    800025b6:	00000097          	auipc	ra,0x0
    800025ba:	d04080e7          	jalr	-764(ra) # 800022ba <sched>
    panic("zombie exit");
    800025be:	00006517          	auipc	a0,0x6
    800025c2:	cea50513          	addi	a0,a0,-790 # 800082a8 <digits+0x268>
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	f76080e7          	jalr	-138(ra) # 8000053c <panic>

00000000800025ce <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800025ce:	7179                	addi	sp,sp,-48
    800025d0:	f406                	sd	ra,40(sp)
    800025d2:	f022                	sd	s0,32(sp)
    800025d4:	ec26                	sd	s1,24(sp)
    800025d6:	e84a                	sd	s2,16(sp)
    800025d8:	e44e                	sd	s3,8(sp)
    800025da:	1800                	addi	s0,sp,48
    800025dc:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800025de:	0022f497          	auipc	s1,0x22f
    800025e2:	af248493          	addi	s1,s1,-1294 # 802310d0 <proc>
    800025e6:	00234997          	auipc	s3,0x234
    800025ea:	4ea98993          	addi	s3,s3,1258 # 80236ad0 <tickslock>
    {
        acquire(&p->lock);
    800025ee:	8526                	mv	a0,s1
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	73a080e7          	jalr	1850(ra) # 80000d2a <acquire>
        if (p->pid == pid)
    800025f8:	589c                	lw	a5,48(s1)
    800025fa:	01278d63          	beq	a5,s2,80002614 <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    800025fe:	8526                	mv	a0,s1
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	7de080e7          	jalr	2014(ra) # 80000dde <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002608:	16848493          	addi	s1,s1,360
    8000260c:	ff3491e3          	bne	s1,s3,800025ee <kill+0x20>
    }
    return -1;
    80002610:	557d                	li	a0,-1
    80002612:	a829                	j	8000262c <kill+0x5e>
            p->killed = 1;
    80002614:	4785                	li	a5,1
    80002616:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    80002618:	4c98                	lw	a4,24(s1)
    8000261a:	4789                	li	a5,2
    8000261c:	00f70f63          	beq	a4,a5,8000263a <kill+0x6c>
            release(&p->lock);
    80002620:	8526                	mv	a0,s1
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	7bc080e7          	jalr	1980(ra) # 80000dde <release>
            return 0;
    8000262a:	4501                	li	a0,0
}
    8000262c:	70a2                	ld	ra,40(sp)
    8000262e:	7402                	ld	s0,32(sp)
    80002630:	64e2                	ld	s1,24(sp)
    80002632:	6942                	ld	s2,16(sp)
    80002634:	69a2                	ld	s3,8(sp)
    80002636:	6145                	addi	sp,sp,48
    80002638:	8082                	ret
                p->state = RUNNABLE;
    8000263a:	478d                	li	a5,3
    8000263c:	cc9c                	sw	a5,24(s1)
    8000263e:	b7cd                	j	80002620 <kill+0x52>

0000000080002640 <setkilled>:

void setkilled(struct proc *p)
{
    80002640:	1101                	addi	sp,sp,-32
    80002642:	ec06                	sd	ra,24(sp)
    80002644:	e822                	sd	s0,16(sp)
    80002646:	e426                	sd	s1,8(sp)
    80002648:	1000                	addi	s0,sp,32
    8000264a:	84aa                	mv	s1,a0
    acquire(&p->lock);
    8000264c:	ffffe097          	auipc	ra,0xffffe
    80002650:	6de080e7          	jalr	1758(ra) # 80000d2a <acquire>
    p->killed = 1;
    80002654:	4785                	li	a5,1
    80002656:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    80002658:	8526                	mv	a0,s1
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	784080e7          	jalr	1924(ra) # 80000dde <release>
}
    80002662:	60e2                	ld	ra,24(sp)
    80002664:	6442                	ld	s0,16(sp)
    80002666:	64a2                	ld	s1,8(sp)
    80002668:	6105                	addi	sp,sp,32
    8000266a:	8082                	ret

000000008000266c <killed>:

int killed(struct proc *p)
{
    8000266c:	1101                	addi	sp,sp,-32
    8000266e:	ec06                	sd	ra,24(sp)
    80002670:	e822                	sd	s0,16(sp)
    80002672:	e426                	sd	s1,8(sp)
    80002674:	e04a                	sd	s2,0(sp)
    80002676:	1000                	addi	s0,sp,32
    80002678:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    8000267a:	ffffe097          	auipc	ra,0xffffe
    8000267e:	6b0080e7          	jalr	1712(ra) # 80000d2a <acquire>
    k = p->killed;
    80002682:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    80002686:	8526                	mv	a0,s1
    80002688:	ffffe097          	auipc	ra,0xffffe
    8000268c:	756080e7          	jalr	1878(ra) # 80000dde <release>
    return k;
}
    80002690:	854a                	mv	a0,s2
    80002692:	60e2                	ld	ra,24(sp)
    80002694:	6442                	ld	s0,16(sp)
    80002696:	64a2                	ld	s1,8(sp)
    80002698:	6902                	ld	s2,0(sp)
    8000269a:	6105                	addi	sp,sp,32
    8000269c:	8082                	ret

000000008000269e <wait>:
{
    8000269e:	715d                	addi	sp,sp,-80
    800026a0:	e486                	sd	ra,72(sp)
    800026a2:	e0a2                	sd	s0,64(sp)
    800026a4:	fc26                	sd	s1,56(sp)
    800026a6:	f84a                	sd	s2,48(sp)
    800026a8:	f44e                	sd	s3,40(sp)
    800026aa:	f052                	sd	s4,32(sp)
    800026ac:	ec56                	sd	s5,24(sp)
    800026ae:	e85a                	sd	s6,16(sp)
    800026b0:	e45e                	sd	s7,8(sp)
    800026b2:	e062                	sd	s8,0(sp)
    800026b4:	0880                	addi	s0,sp,80
    800026b6:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    800026b8:	fffff097          	auipc	ra,0xfffff
    800026bc:	5a4080e7          	jalr	1444(ra) # 80001c5c <myproc>
    800026c0:	892a                	mv	s2,a0
    acquire(&wait_lock);
    800026c2:	0022f517          	auipc	a0,0x22f
    800026c6:	9f650513          	addi	a0,a0,-1546 # 802310b8 <wait_lock>
    800026ca:	ffffe097          	auipc	ra,0xffffe
    800026ce:	660080e7          	jalr	1632(ra) # 80000d2a <acquire>
        havekids = 0;
    800026d2:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    800026d4:	4a15                	li	s4,5
                havekids = 1;
    800026d6:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800026d8:	00234997          	auipc	s3,0x234
    800026dc:	3f898993          	addi	s3,s3,1016 # 80236ad0 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    800026e0:	0022fc17          	auipc	s8,0x22f
    800026e4:	9d8c0c13          	addi	s8,s8,-1576 # 802310b8 <wait_lock>
    800026e8:	a0d1                	j	800027ac <wait+0x10e>
                    pid = pp->pid;
    800026ea:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800026ee:	000b0e63          	beqz	s6,8000270a <wait+0x6c>
    800026f2:	4691                	li	a3,4
    800026f4:	02c48613          	addi	a2,s1,44
    800026f8:	85da                	mv	a1,s6
    800026fa:	05093503          	ld	a0,80(s2)
    800026fe:	fffff097          	auipc	ra,0xfffff
    80002702:	0a6080e7          	jalr	166(ra) # 800017a4 <copyout>
    80002706:	04054163          	bltz	a0,80002748 <wait+0xaa>
                    freeproc(pp);
    8000270a:	8526                	mv	a0,s1
    8000270c:	fffff097          	auipc	ra,0xfffff
    80002710:	702080e7          	jalr	1794(ra) # 80001e0e <freeproc>
                    release(&pp->lock);
    80002714:	8526                	mv	a0,s1
    80002716:	ffffe097          	auipc	ra,0xffffe
    8000271a:	6c8080e7          	jalr	1736(ra) # 80000dde <release>
                    release(&wait_lock);
    8000271e:	0022f517          	auipc	a0,0x22f
    80002722:	99a50513          	addi	a0,a0,-1638 # 802310b8 <wait_lock>
    80002726:	ffffe097          	auipc	ra,0xffffe
    8000272a:	6b8080e7          	jalr	1720(ra) # 80000dde <release>
}
    8000272e:	854e                	mv	a0,s3
    80002730:	60a6                	ld	ra,72(sp)
    80002732:	6406                	ld	s0,64(sp)
    80002734:	74e2                	ld	s1,56(sp)
    80002736:	7942                	ld	s2,48(sp)
    80002738:	79a2                	ld	s3,40(sp)
    8000273a:	7a02                	ld	s4,32(sp)
    8000273c:	6ae2                	ld	s5,24(sp)
    8000273e:	6b42                	ld	s6,16(sp)
    80002740:	6ba2                	ld	s7,8(sp)
    80002742:	6c02                	ld	s8,0(sp)
    80002744:	6161                	addi	sp,sp,80
    80002746:	8082                	ret
                        release(&pp->lock);
    80002748:	8526                	mv	a0,s1
    8000274a:	ffffe097          	auipc	ra,0xffffe
    8000274e:	694080e7          	jalr	1684(ra) # 80000dde <release>
                        release(&wait_lock);
    80002752:	0022f517          	auipc	a0,0x22f
    80002756:	96650513          	addi	a0,a0,-1690 # 802310b8 <wait_lock>
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	684080e7          	jalr	1668(ra) # 80000dde <release>
                        return -1;
    80002762:	59fd                	li	s3,-1
    80002764:	b7e9                	j	8000272e <wait+0x90>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002766:	16848493          	addi	s1,s1,360
    8000276a:	03348463          	beq	s1,s3,80002792 <wait+0xf4>
            if (pp->parent == p)
    8000276e:	7c9c                	ld	a5,56(s1)
    80002770:	ff279be3          	bne	a5,s2,80002766 <wait+0xc8>
                acquire(&pp->lock);
    80002774:	8526                	mv	a0,s1
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	5b4080e7          	jalr	1460(ra) # 80000d2a <acquire>
                if (pp->state == ZOMBIE)
    8000277e:	4c9c                	lw	a5,24(s1)
    80002780:	f74785e3          	beq	a5,s4,800026ea <wait+0x4c>
                release(&pp->lock);
    80002784:	8526                	mv	a0,s1
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	658080e7          	jalr	1624(ra) # 80000dde <release>
                havekids = 1;
    8000278e:	8756                	mv	a4,s5
    80002790:	bfd9                	j	80002766 <wait+0xc8>
        if (!havekids || killed(p))
    80002792:	c31d                	beqz	a4,800027b8 <wait+0x11a>
    80002794:	854a                	mv	a0,s2
    80002796:	00000097          	auipc	ra,0x0
    8000279a:	ed6080e7          	jalr	-298(ra) # 8000266c <killed>
    8000279e:	ed09                	bnez	a0,800027b8 <wait+0x11a>
        sleep(p, &wait_lock); // DOC: wait-sleep
    800027a0:	85e2                	mv	a1,s8
    800027a2:	854a                	mv	a0,s2
    800027a4:	00000097          	auipc	ra,0x0
    800027a8:	c20080e7          	jalr	-992(ra) # 800023c4 <sleep>
        havekids = 0;
    800027ac:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800027ae:	0022f497          	auipc	s1,0x22f
    800027b2:	92248493          	addi	s1,s1,-1758 # 802310d0 <proc>
    800027b6:	bf65                	j	8000276e <wait+0xd0>
            release(&wait_lock);
    800027b8:	0022f517          	auipc	a0,0x22f
    800027bc:	90050513          	addi	a0,a0,-1792 # 802310b8 <wait_lock>
    800027c0:	ffffe097          	auipc	ra,0xffffe
    800027c4:	61e080e7          	jalr	1566(ra) # 80000dde <release>
            return -1;
    800027c8:	59fd                	li	s3,-1
    800027ca:	b795                	j	8000272e <wait+0x90>

00000000800027cc <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027cc:	7179                	addi	sp,sp,-48
    800027ce:	f406                	sd	ra,40(sp)
    800027d0:	f022                	sd	s0,32(sp)
    800027d2:	ec26                	sd	s1,24(sp)
    800027d4:	e84a                	sd	s2,16(sp)
    800027d6:	e44e                	sd	s3,8(sp)
    800027d8:	e052                	sd	s4,0(sp)
    800027da:	1800                	addi	s0,sp,48
    800027dc:	84aa                	mv	s1,a0
    800027de:	892e                	mv	s2,a1
    800027e0:	89b2                	mv	s3,a2
    800027e2:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800027e4:	fffff097          	auipc	ra,0xfffff
    800027e8:	478080e7          	jalr	1144(ra) # 80001c5c <myproc>
    if (user_dst)
    800027ec:	c08d                	beqz	s1,8000280e <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    800027ee:	86d2                	mv	a3,s4
    800027f0:	864e                	mv	a2,s3
    800027f2:	85ca                	mv	a1,s2
    800027f4:	6928                	ld	a0,80(a0)
    800027f6:	fffff097          	auipc	ra,0xfffff
    800027fa:	fae080e7          	jalr	-82(ra) # 800017a4 <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    800027fe:	70a2                	ld	ra,40(sp)
    80002800:	7402                	ld	s0,32(sp)
    80002802:	64e2                	ld	s1,24(sp)
    80002804:	6942                	ld	s2,16(sp)
    80002806:	69a2                	ld	s3,8(sp)
    80002808:	6a02                	ld	s4,0(sp)
    8000280a:	6145                	addi	sp,sp,48
    8000280c:	8082                	ret
        memmove((char *)dst, src, len);
    8000280e:	000a061b          	sext.w	a2,s4
    80002812:	85ce                	mv	a1,s3
    80002814:	854a                	mv	a0,s2
    80002816:	ffffe097          	auipc	ra,0xffffe
    8000281a:	66c080e7          	jalr	1644(ra) # 80000e82 <memmove>
        return 0;
    8000281e:	8526                	mv	a0,s1
    80002820:	bff9                	j	800027fe <either_copyout+0x32>

0000000080002822 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002822:	7179                	addi	sp,sp,-48
    80002824:	f406                	sd	ra,40(sp)
    80002826:	f022                	sd	s0,32(sp)
    80002828:	ec26                	sd	s1,24(sp)
    8000282a:	e84a                	sd	s2,16(sp)
    8000282c:	e44e                	sd	s3,8(sp)
    8000282e:	e052                	sd	s4,0(sp)
    80002830:	1800                	addi	s0,sp,48
    80002832:	892a                	mv	s2,a0
    80002834:	84ae                	mv	s1,a1
    80002836:	89b2                	mv	s3,a2
    80002838:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    8000283a:	fffff097          	auipc	ra,0xfffff
    8000283e:	422080e7          	jalr	1058(ra) # 80001c5c <myproc>
    if (user_src)
    80002842:	c08d                	beqz	s1,80002864 <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    80002844:	86d2                	mv	a3,s4
    80002846:	864e                	mv	a2,s3
    80002848:	85ca                	mv	a1,s2
    8000284a:	6928                	ld	a0,80(a0)
    8000284c:	fffff097          	auipc	ra,0xfffff
    80002850:	fe4080e7          	jalr	-28(ra) # 80001830 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    80002854:	70a2                	ld	ra,40(sp)
    80002856:	7402                	ld	s0,32(sp)
    80002858:	64e2                	ld	s1,24(sp)
    8000285a:	6942                	ld	s2,16(sp)
    8000285c:	69a2                	ld	s3,8(sp)
    8000285e:	6a02                	ld	s4,0(sp)
    80002860:	6145                	addi	sp,sp,48
    80002862:	8082                	ret
        memmove(dst, (char *)src, len);
    80002864:	000a061b          	sext.w	a2,s4
    80002868:	85ce                	mv	a1,s3
    8000286a:	854a                	mv	a0,s2
    8000286c:	ffffe097          	auipc	ra,0xffffe
    80002870:	616080e7          	jalr	1558(ra) # 80000e82 <memmove>
        return 0;
    80002874:	8526                	mv	a0,s1
    80002876:	bff9                	j	80002854 <either_copyin+0x32>

0000000080002878 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002878:	715d                	addi	sp,sp,-80
    8000287a:	e486                	sd	ra,72(sp)
    8000287c:	e0a2                	sd	s0,64(sp)
    8000287e:	fc26                	sd	s1,56(sp)
    80002880:	f84a                	sd	s2,48(sp)
    80002882:	f44e                	sd	s3,40(sp)
    80002884:	f052                	sd	s4,32(sp)
    80002886:	ec56                	sd	s5,24(sp)
    80002888:	e85a                	sd	s6,16(sp)
    8000288a:	e45e                	sd	s7,8(sp)
    8000288c:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    8000288e:	00006517          	auipc	a0,0x6
    80002892:	87250513          	addi	a0,a0,-1934 # 80008100 <digits+0xc0>
    80002896:	ffffe097          	auipc	ra,0xffffe
    8000289a:	d02080e7          	jalr	-766(ra) # 80000598 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    8000289e:	0022f497          	auipc	s1,0x22f
    800028a2:	98a48493          	addi	s1,s1,-1654 # 80231228 <proc+0x158>
    800028a6:	00234917          	auipc	s2,0x234
    800028aa:	38290913          	addi	s2,s2,898 # 80236c28 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028ae:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    800028b0:	00006997          	auipc	s3,0x6
    800028b4:	a0898993          	addi	s3,s3,-1528 # 800082b8 <digits+0x278>
        printf("%d <%s %s", p->pid, state, p->name);
    800028b8:	00006a97          	auipc	s5,0x6
    800028bc:	a08a8a93          	addi	s5,s5,-1528 # 800082c0 <digits+0x280>
        printf("\n");
    800028c0:	00006a17          	auipc	s4,0x6
    800028c4:	840a0a13          	addi	s4,s4,-1984 # 80008100 <digits+0xc0>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028c8:	00006b97          	auipc	s7,0x6
    800028cc:	b08b8b93          	addi	s7,s7,-1272 # 800083d0 <states.0>
    800028d0:	a00d                	j	800028f2 <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    800028d2:	ed86a583          	lw	a1,-296(a3)
    800028d6:	8556                	mv	a0,s5
    800028d8:	ffffe097          	auipc	ra,0xffffe
    800028dc:	cc0080e7          	jalr	-832(ra) # 80000598 <printf>
        printf("\n");
    800028e0:	8552                	mv	a0,s4
    800028e2:	ffffe097          	auipc	ra,0xffffe
    800028e6:	cb6080e7          	jalr	-842(ra) # 80000598 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800028ea:	16848493          	addi	s1,s1,360
    800028ee:	03248263          	beq	s1,s2,80002912 <procdump+0x9a>
        if (p->state == UNUSED)
    800028f2:	86a6                	mv	a3,s1
    800028f4:	ec04a783          	lw	a5,-320(s1)
    800028f8:	dbed                	beqz	a5,800028ea <procdump+0x72>
            state = "???";
    800028fa:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028fc:	fcfb6be3          	bltu	s6,a5,800028d2 <procdump+0x5a>
    80002900:	02079713          	slli	a4,a5,0x20
    80002904:	01d75793          	srli	a5,a4,0x1d
    80002908:	97de                	add	a5,a5,s7
    8000290a:	6390                	ld	a2,0(a5)
    8000290c:	f279                	bnez	a2,800028d2 <procdump+0x5a>
            state = "???";
    8000290e:	864e                	mv	a2,s3
    80002910:	b7c9                	j	800028d2 <procdump+0x5a>
    }
}
    80002912:	60a6                	ld	ra,72(sp)
    80002914:	6406                	ld	s0,64(sp)
    80002916:	74e2                	ld	s1,56(sp)
    80002918:	7942                	ld	s2,48(sp)
    8000291a:	79a2                	ld	s3,40(sp)
    8000291c:	7a02                	ld	s4,32(sp)
    8000291e:	6ae2                	ld	s5,24(sp)
    80002920:	6b42                	ld	s6,16(sp)
    80002922:	6ba2                	ld	s7,8(sp)
    80002924:	6161                	addi	sp,sp,80
    80002926:	8082                	ret

0000000080002928 <schedls>:

void schedls()
{
    80002928:	1141                	addi	sp,sp,-16
    8000292a:	e406                	sd	ra,8(sp)
    8000292c:	e022                	sd	s0,0(sp)
    8000292e:	0800                	addi	s0,sp,16
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    80002930:	00006517          	auipc	a0,0x6
    80002934:	9a050513          	addi	a0,a0,-1632 # 800082d0 <digits+0x290>
    80002938:	ffffe097          	auipc	ra,0xffffe
    8000293c:	c60080e7          	jalr	-928(ra) # 80000598 <printf>
    printf("====================================\n");
    80002940:	00006517          	auipc	a0,0x6
    80002944:	9b850513          	addi	a0,a0,-1608 # 800082f8 <digits+0x2b8>
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	c50080e7          	jalr	-944(ra) # 80000598 <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    80002950:	00006717          	auipc	a4,0x6
    80002954:	08873703          	ld	a4,136(a4) # 800089d8 <available_schedulers+0x10>
    80002958:	00006797          	auipc	a5,0x6
    8000295c:	0207b783          	ld	a5,32(a5) # 80008978 <sched_pointer>
    80002960:	04f70663          	beq	a4,a5,800029ac <schedls+0x84>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    80002964:	00006517          	auipc	a0,0x6
    80002968:	9c450513          	addi	a0,a0,-1596 # 80008328 <digits+0x2e8>
    8000296c:	ffffe097          	auipc	ra,0xffffe
    80002970:	c2c080e7          	jalr	-980(ra) # 80000598 <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002974:	00006617          	auipc	a2,0x6
    80002978:	06c62603          	lw	a2,108(a2) # 800089e0 <available_schedulers+0x18>
    8000297c:	00006597          	auipc	a1,0x6
    80002980:	04c58593          	addi	a1,a1,76 # 800089c8 <available_schedulers>
    80002984:	00006517          	auipc	a0,0x6
    80002988:	9ac50513          	addi	a0,a0,-1620 # 80008330 <digits+0x2f0>
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	c0c080e7          	jalr	-1012(ra) # 80000598 <printf>
    }
    printf("\n*: current scheduler\n\n");
    80002994:	00006517          	auipc	a0,0x6
    80002998:	9a450513          	addi	a0,a0,-1628 # 80008338 <digits+0x2f8>
    8000299c:	ffffe097          	auipc	ra,0xffffe
    800029a0:	bfc080e7          	jalr	-1028(ra) # 80000598 <printf>
}
    800029a4:	60a2                	ld	ra,8(sp)
    800029a6:	6402                	ld	s0,0(sp)
    800029a8:	0141                	addi	sp,sp,16
    800029aa:	8082                	ret
            printf("[*]\t");
    800029ac:	00006517          	auipc	a0,0x6
    800029b0:	97450513          	addi	a0,a0,-1676 # 80008320 <digits+0x2e0>
    800029b4:	ffffe097          	auipc	ra,0xffffe
    800029b8:	be4080e7          	jalr	-1052(ra) # 80000598 <printf>
    800029bc:	bf65                	j	80002974 <schedls+0x4c>

00000000800029be <schedset>:

void schedset(int id)
{
    800029be:	1141                	addi	sp,sp,-16
    800029c0:	e406                	sd	ra,8(sp)
    800029c2:	e022                	sd	s0,0(sp)
    800029c4:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    800029c6:	e90d                	bnez	a0,800029f8 <schedset+0x3a>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    800029c8:	00006797          	auipc	a5,0x6
    800029cc:	0107b783          	ld	a5,16(a5) # 800089d8 <available_schedulers+0x10>
    800029d0:	00006717          	auipc	a4,0x6
    800029d4:	faf73423          	sd	a5,-88(a4) # 80008978 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    800029d8:	00006597          	auipc	a1,0x6
    800029dc:	ff058593          	addi	a1,a1,-16 # 800089c8 <available_schedulers>
    800029e0:	00006517          	auipc	a0,0x6
    800029e4:	99850513          	addi	a0,a0,-1640 # 80008378 <digits+0x338>
    800029e8:	ffffe097          	auipc	ra,0xffffe
    800029ec:	bb0080e7          	jalr	-1104(ra) # 80000598 <printf>
}
    800029f0:	60a2                	ld	ra,8(sp)
    800029f2:	6402                	ld	s0,0(sp)
    800029f4:	0141                	addi	sp,sp,16
    800029f6:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    800029f8:	00006517          	auipc	a0,0x6
    800029fc:	95850513          	addi	a0,a0,-1704 # 80008350 <digits+0x310>
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	b98080e7          	jalr	-1128(ra) # 80000598 <printf>
        return;
    80002a08:	b7e5                	j	800029f0 <schedset+0x32>

0000000080002a0a <getProc>:

struct proc *getProc(int pid)
{
    80002a0a:	7179                	addi	sp,sp,-48
    80002a0c:	f406                	sd	ra,40(sp)
    80002a0e:	f022                	sd	s0,32(sp)
    80002a10:	ec26                	sd	s1,24(sp)
    80002a12:	e84a                	sd	s2,16(sp)
    80002a14:	e44e                	sd	s3,8(sp)
    80002a16:	1800                	addi	s0,sp,48
    80002a18:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002a1a:	0022e497          	auipc	s1,0x22e
    80002a1e:	6b648493          	addi	s1,s1,1718 # 802310d0 <proc>
    80002a22:	00234997          	auipc	s3,0x234
    80002a26:	0ae98993          	addi	s3,s3,174 # 80236ad0 <tickslock>
    {
        acquire(&p->lock);
    80002a2a:	8526                	mv	a0,s1
    80002a2c:	ffffe097          	auipc	ra,0xffffe
    80002a30:	2fe080e7          	jalr	766(ra) # 80000d2a <acquire>
        if (p->pid == pid)
    80002a34:	589c                	lw	a5,48(s1)
    80002a36:	01278d63          	beq	a5,s2,80002a50 <getProc+0x46>
        {
            release(&p->lock);
            return p;
        }
        release(&p->lock);
    80002a3a:	8526                	mv	a0,s1
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	3a2080e7          	jalr	930(ra) # 80000dde <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002a44:	16848493          	addi	s1,s1,360
    80002a48:	ff3491e3          	bne	s1,s3,80002a2a <getProc+0x20>
    }
    return 0;
    80002a4c:	4481                	li	s1,0
    80002a4e:	a031                	j	80002a5a <getProc+0x50>
            release(&p->lock);
    80002a50:	8526                	mv	a0,s1
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	38c080e7          	jalr	908(ra) # 80000dde <release>
    80002a5a:	8526                	mv	a0,s1
    80002a5c:	70a2                	ld	ra,40(sp)
    80002a5e:	7402                	ld	s0,32(sp)
    80002a60:	64e2                	ld	s1,24(sp)
    80002a62:	6942                	ld	s2,16(sp)
    80002a64:	69a2                	ld	s3,8(sp)
    80002a66:	6145                	addi	sp,sp,48
    80002a68:	8082                	ret

0000000080002a6a <swtch>:
    80002a6a:	00153023          	sd	ra,0(a0)
    80002a6e:	00253423          	sd	sp,8(a0)
    80002a72:	e900                	sd	s0,16(a0)
    80002a74:	ed04                	sd	s1,24(a0)
    80002a76:	03253023          	sd	s2,32(a0)
    80002a7a:	03353423          	sd	s3,40(a0)
    80002a7e:	03453823          	sd	s4,48(a0)
    80002a82:	03553c23          	sd	s5,56(a0)
    80002a86:	05653023          	sd	s6,64(a0)
    80002a8a:	05753423          	sd	s7,72(a0)
    80002a8e:	05853823          	sd	s8,80(a0)
    80002a92:	05953c23          	sd	s9,88(a0)
    80002a96:	07a53023          	sd	s10,96(a0)
    80002a9a:	07b53423          	sd	s11,104(a0)
    80002a9e:	0005b083          	ld	ra,0(a1)
    80002aa2:	0085b103          	ld	sp,8(a1)
    80002aa6:	6980                	ld	s0,16(a1)
    80002aa8:	6d84                	ld	s1,24(a1)
    80002aaa:	0205b903          	ld	s2,32(a1)
    80002aae:	0285b983          	ld	s3,40(a1)
    80002ab2:	0305ba03          	ld	s4,48(a1)
    80002ab6:	0385ba83          	ld	s5,56(a1)
    80002aba:	0405bb03          	ld	s6,64(a1)
    80002abe:	0485bb83          	ld	s7,72(a1)
    80002ac2:	0505bc03          	ld	s8,80(a1)
    80002ac6:	0585bc83          	ld	s9,88(a1)
    80002aca:	0605bd03          	ld	s10,96(a1)
    80002ace:	0685bd83          	ld	s11,104(a1)
    80002ad2:	8082                	ret

0000000080002ad4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002ad4:	1141                	addi	sp,sp,-16
    80002ad6:	e406                	sd	ra,8(sp)
    80002ad8:	e022                	sd	s0,0(sp)
    80002ada:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002adc:	00006597          	auipc	a1,0x6
    80002ae0:	92458593          	addi	a1,a1,-1756 # 80008400 <states.0+0x30>
    80002ae4:	00234517          	auipc	a0,0x234
    80002ae8:	fec50513          	addi	a0,a0,-20 # 80236ad0 <tickslock>
    80002aec:	ffffe097          	auipc	ra,0xffffe
    80002af0:	1ae080e7          	jalr	430(ra) # 80000c9a <initlock>
}
    80002af4:	60a2                	ld	ra,8(sp)
    80002af6:	6402                	ld	s0,0(sp)
    80002af8:	0141                	addi	sp,sp,16
    80002afa:	8082                	ret

0000000080002afc <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002afc:	1141                	addi	sp,sp,-16
    80002afe:	e422                	sd	s0,8(sp)
    80002b00:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b02:	00003797          	auipc	a5,0x3
    80002b06:	5ce78793          	addi	a5,a5,1486 # 800060d0 <kernelvec>
    80002b0a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b0e:	6422                	ld	s0,8(sp)
    80002b10:	0141                	addi	sp,sp,16
    80002b12:	8082                	ret

0000000080002b14 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002b14:	1141                	addi	sp,sp,-16
    80002b16:	e406                	sd	ra,8(sp)
    80002b18:	e022                	sd	s0,0(sp)
    80002b1a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b1c:	fffff097          	auipc	ra,0xfffff
    80002b20:	140080e7          	jalr	320(ra) # 80001c5c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b24:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b28:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b2a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002b2e:	00004697          	auipc	a3,0x4
    80002b32:	4d268693          	addi	a3,a3,1234 # 80007000 <_trampoline>
    80002b36:	00004717          	auipc	a4,0x4
    80002b3a:	4ca70713          	addi	a4,a4,1226 # 80007000 <_trampoline>
    80002b3e:	8f15                	sub	a4,a4,a3
    80002b40:	040007b7          	lui	a5,0x4000
    80002b44:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002b46:	07b2                	slli	a5,a5,0xc
    80002b48:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b4a:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b4e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002b50:	18002673          	csrr	a2,satp
    80002b54:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b56:	6d30                	ld	a2,88(a0)
    80002b58:	6138                	ld	a4,64(a0)
    80002b5a:	6585                	lui	a1,0x1
    80002b5c:	972e                	add	a4,a4,a1
    80002b5e:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b60:	6d38                	ld	a4,88(a0)
    80002b62:	00000617          	auipc	a2,0x0
    80002b66:	13460613          	addi	a2,a2,308 # 80002c96 <usertrap>
    80002b6a:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002b6c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b6e:	8612                	mv	a2,tp
    80002b70:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b72:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b76:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b7a:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b7e:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b82:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b84:	6f18                	ld	a4,24(a4)
    80002b86:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b8a:	6928                	ld	a0,80(a0)
    80002b8c:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b8e:	00004717          	auipc	a4,0x4
    80002b92:	50e70713          	addi	a4,a4,1294 # 8000709c <userret>
    80002b96:	8f15                	sub	a4,a4,a3
    80002b98:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002b9a:	577d                	li	a4,-1
    80002b9c:	177e                	slli	a4,a4,0x3f
    80002b9e:	8d59                	or	a0,a0,a4
    80002ba0:	9782                	jalr	a5
}
    80002ba2:	60a2                	ld	ra,8(sp)
    80002ba4:	6402                	ld	s0,0(sp)
    80002ba6:	0141                	addi	sp,sp,16
    80002ba8:	8082                	ret

0000000080002baa <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002baa:	1101                	addi	sp,sp,-32
    80002bac:	ec06                	sd	ra,24(sp)
    80002bae:	e822                	sd	s0,16(sp)
    80002bb0:	e426                	sd	s1,8(sp)
    80002bb2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002bb4:	00234497          	auipc	s1,0x234
    80002bb8:	f1c48493          	addi	s1,s1,-228 # 80236ad0 <tickslock>
    80002bbc:	8526                	mv	a0,s1
    80002bbe:	ffffe097          	auipc	ra,0xffffe
    80002bc2:	16c080e7          	jalr	364(ra) # 80000d2a <acquire>
  ticks++;
    80002bc6:	00006517          	auipc	a0,0x6
    80002bca:	e6a50513          	addi	a0,a0,-406 # 80008a30 <ticks>
    80002bce:	411c                	lw	a5,0(a0)
    80002bd0:	2785                	addiw	a5,a5,1
    80002bd2:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002bd4:	00000097          	auipc	ra,0x0
    80002bd8:	854080e7          	jalr	-1964(ra) # 80002428 <wakeup>
  release(&tickslock);
    80002bdc:	8526                	mv	a0,s1
    80002bde:	ffffe097          	auipc	ra,0xffffe
    80002be2:	200080e7          	jalr	512(ra) # 80000dde <release>
}
    80002be6:	60e2                	ld	ra,24(sp)
    80002be8:	6442                	ld	s0,16(sp)
    80002bea:	64a2                	ld	s1,8(sp)
    80002bec:	6105                	addi	sp,sp,32
    80002bee:	8082                	ret

0000000080002bf0 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bf0:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002bf4:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002bf6:	0807df63          	bgez	a5,80002c94 <devintr+0xa4>
{
    80002bfa:	1101                	addi	sp,sp,-32
    80002bfc:	ec06                	sd	ra,24(sp)
    80002bfe:	e822                	sd	s0,16(sp)
    80002c00:	e426                	sd	s1,8(sp)
    80002c02:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    80002c04:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002c08:	46a5                	li	a3,9
    80002c0a:	00d70d63          	beq	a4,a3,80002c24 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002c0e:	577d                	li	a4,-1
    80002c10:	177e                	slli	a4,a4,0x3f
    80002c12:	0705                	addi	a4,a4,1
    return 0;
    80002c14:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002c16:	04e78e63          	beq	a5,a4,80002c72 <devintr+0x82>
  }
}
    80002c1a:	60e2                	ld	ra,24(sp)
    80002c1c:	6442                	ld	s0,16(sp)
    80002c1e:	64a2                	ld	s1,8(sp)
    80002c20:	6105                	addi	sp,sp,32
    80002c22:	8082                	ret
    int irq = plic_claim();
    80002c24:	00003097          	auipc	ra,0x3
    80002c28:	5b4080e7          	jalr	1460(ra) # 800061d8 <plic_claim>
    80002c2c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002c2e:	47a9                	li	a5,10
    80002c30:	02f50763          	beq	a0,a5,80002c5e <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002c34:	4785                	li	a5,1
    80002c36:	02f50963          	beq	a0,a5,80002c68 <devintr+0x78>
    return 1;
    80002c3a:	4505                	li	a0,1
    } else if(irq){
    80002c3c:	dcf9                	beqz	s1,80002c1a <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c3e:	85a6                	mv	a1,s1
    80002c40:	00005517          	auipc	a0,0x5
    80002c44:	7c850513          	addi	a0,a0,1992 # 80008408 <states.0+0x38>
    80002c48:	ffffe097          	auipc	ra,0xffffe
    80002c4c:	950080e7          	jalr	-1712(ra) # 80000598 <printf>
      plic_complete(irq);
    80002c50:	8526                	mv	a0,s1
    80002c52:	00003097          	auipc	ra,0x3
    80002c56:	5aa080e7          	jalr	1450(ra) # 800061fc <plic_complete>
    return 1;
    80002c5a:	4505                	li	a0,1
    80002c5c:	bf7d                	j	80002c1a <devintr+0x2a>
      uartintr();
    80002c5e:	ffffe097          	auipc	ra,0xffffe
    80002c62:	d48080e7          	jalr	-696(ra) # 800009a6 <uartintr>
    if(irq)
    80002c66:	b7ed                	j	80002c50 <devintr+0x60>
      virtio_disk_intr();
    80002c68:	00004097          	auipc	ra,0x4
    80002c6c:	a5a080e7          	jalr	-1446(ra) # 800066c2 <virtio_disk_intr>
    if(irq)
    80002c70:	b7c5                	j	80002c50 <devintr+0x60>
    if(cpuid() == 0){
    80002c72:	fffff097          	auipc	ra,0xfffff
    80002c76:	fbe080e7          	jalr	-66(ra) # 80001c30 <cpuid>
    80002c7a:	c901                	beqz	a0,80002c8a <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c7c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c80:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c82:	14479073          	csrw	sip,a5
    return 2;
    80002c86:	4509                	li	a0,2
    80002c88:	bf49                	j	80002c1a <devintr+0x2a>
      clockintr();
    80002c8a:	00000097          	auipc	ra,0x0
    80002c8e:	f20080e7          	jalr	-224(ra) # 80002baa <clockintr>
    80002c92:	b7ed                	j	80002c7c <devintr+0x8c>
}
    80002c94:	8082                	ret

0000000080002c96 <usertrap>:
{
    80002c96:	1101                	addi	sp,sp,-32
    80002c98:	ec06                	sd	ra,24(sp)
    80002c9a:	e822                	sd	s0,16(sp)
    80002c9c:	e426                	sd	s1,8(sp)
    80002c9e:	e04a                	sd	s2,0(sp)
    80002ca0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ca2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ca6:	1007f793          	andi	a5,a5,256
    80002caa:	e7b9                	bnez	a5,80002cf8 <usertrap+0x62>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cac:	00003797          	auipc	a5,0x3
    80002cb0:	42478793          	addi	a5,a5,1060 # 800060d0 <kernelvec>
    80002cb4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002cb8:	fffff097          	auipc	ra,0xfffff
    80002cbc:	fa4080e7          	jalr	-92(ra) # 80001c5c <myproc>
    80002cc0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002cc2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cc4:	14102773          	csrr	a4,sepc
    80002cc8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cca:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002cce:	47a1                	li	a5,8
    80002cd0:	02f70c63          	beq	a4,a5,80002d08 <usertrap+0x72>
    80002cd4:	14202773          	csrr	a4,scause
  } else if (r_scause() == 15) {
    80002cd8:	47bd                	li	a5,15
    80002cda:	08f70063          	beq	a4,a5,80002d5a <usertrap+0xc4>
  } else if((which_dev = devintr()) != 0){
    80002cde:	00000097          	auipc	ra,0x0
    80002ce2:	f12080e7          	jalr	-238(ra) # 80002bf0 <devintr>
    80002ce6:	892a                	mv	s2,a0
    80002ce8:	c549                	beqz	a0,80002d72 <usertrap+0xdc>
  if(killed(p))
    80002cea:	8526                	mv	a0,s1
    80002cec:	00000097          	auipc	ra,0x0
    80002cf0:	980080e7          	jalr	-1664(ra) # 8000266c <killed>
    80002cf4:	c171                	beqz	a0,80002db8 <usertrap+0x122>
    80002cf6:	a865                	j	80002dae <usertrap+0x118>
    panic("usertrap: not from user mode");
    80002cf8:	00005517          	auipc	a0,0x5
    80002cfc:	73050513          	addi	a0,a0,1840 # 80008428 <states.0+0x58>
    80002d00:	ffffe097          	auipc	ra,0xffffe
    80002d04:	83c080e7          	jalr	-1988(ra) # 8000053c <panic>
    if(killed(p))
    80002d08:	00000097          	auipc	ra,0x0
    80002d0c:	964080e7          	jalr	-1692(ra) # 8000266c <killed>
    80002d10:	ed1d                	bnez	a0,80002d4e <usertrap+0xb8>
    p->trapframe->epc += 4;
    80002d12:	6cb8                	ld	a4,88(s1)
    80002d14:	6f1c                	ld	a5,24(a4)
    80002d16:	0791                	addi	a5,a5,4
    80002d18:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d1a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d1e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d22:	10079073          	csrw	sstatus,a5
    syscall();
    80002d26:	00000097          	auipc	ra,0x0
    80002d2a:	2ec080e7          	jalr	748(ra) # 80003012 <syscall>
  if(killed(p))
    80002d2e:	8526                	mv	a0,s1
    80002d30:	00000097          	auipc	ra,0x0
    80002d34:	93c080e7          	jalr	-1732(ra) # 8000266c <killed>
    80002d38:	e935                	bnez	a0,80002dac <usertrap+0x116>
  usertrapret();
    80002d3a:	00000097          	auipc	ra,0x0
    80002d3e:	dda080e7          	jalr	-550(ra) # 80002b14 <usertrapret>
}
    80002d42:	60e2                	ld	ra,24(sp)
    80002d44:	6442                	ld	s0,16(sp)
    80002d46:	64a2                	ld	s1,8(sp)
    80002d48:	6902                	ld	s2,0(sp)
    80002d4a:	6105                	addi	sp,sp,32
    80002d4c:	8082                	ret
      exit(-1);
    80002d4e:	557d                	li	a0,-1
    80002d50:	fffff097          	auipc	ra,0xfffff
    80002d54:	7a8080e7          	jalr	1960(ra) # 800024f8 <exit>
    80002d58:	bf6d                	j	80002d12 <usertrap+0x7c>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d5a:	143025f3          	csrr	a1,stval
    if ((cowfault(p->pagetable, r_stval())) < 0) {
    80002d5e:	6928                	ld	a0,80(a0)
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	c0e080e7          	jalr	-1010(ra) # 8000196e <cowfault>
    80002d68:	fc0553e3          	bgez	a0,80002d2e <usertrap+0x98>
      p->killed = 1;
    80002d6c:	4785                	li	a5,1
    80002d6e:	d49c                	sw	a5,40(s1)
    80002d70:	bf7d                	j	80002d2e <usertrap+0x98>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d72:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002d76:	5890                	lw	a2,48(s1)
    80002d78:	00005517          	auipc	a0,0x5
    80002d7c:	6d050513          	addi	a0,a0,1744 # 80008448 <states.0+0x78>
    80002d80:	ffffe097          	auipc	ra,0xffffe
    80002d84:	818080e7          	jalr	-2024(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d88:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d8c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d90:	00005517          	auipc	a0,0x5
    80002d94:	6e850513          	addi	a0,a0,1768 # 80008478 <states.0+0xa8>
    80002d98:	ffffe097          	auipc	ra,0xffffe
    80002d9c:	800080e7          	jalr	-2048(ra) # 80000598 <printf>
    setkilled(p);
    80002da0:	8526                	mv	a0,s1
    80002da2:	00000097          	auipc	ra,0x0
    80002da6:	89e080e7          	jalr	-1890(ra) # 80002640 <setkilled>
    80002daa:	b751                	j	80002d2e <usertrap+0x98>
  if(killed(p))
    80002dac:	4901                	li	s2,0
    exit(-1);
    80002dae:	557d                	li	a0,-1
    80002db0:	fffff097          	auipc	ra,0xfffff
    80002db4:	748080e7          	jalr	1864(ra) # 800024f8 <exit>
  if(which_dev == 2)
    80002db8:	4789                	li	a5,2
    80002dba:	f8f910e3          	bne	s2,a5,80002d3a <usertrap+0xa4>
    yield();
    80002dbe:	fffff097          	auipc	ra,0xfffff
    80002dc2:	5ca080e7          	jalr	1482(ra) # 80002388 <yield>
    80002dc6:	bf95                	j	80002d3a <usertrap+0xa4>

0000000080002dc8 <kerneltrap>:
{
    80002dc8:	7179                	addi	sp,sp,-48
    80002dca:	f406                	sd	ra,40(sp)
    80002dcc:	f022                	sd	s0,32(sp)
    80002dce:	ec26                	sd	s1,24(sp)
    80002dd0:	e84a                	sd	s2,16(sp)
    80002dd2:	e44e                	sd	s3,8(sp)
    80002dd4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dd6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dda:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dde:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002de2:	1004f793          	andi	a5,s1,256
    80002de6:	cb85                	beqz	a5,80002e16 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002de8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002dec:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002dee:	ef85                	bnez	a5,80002e26 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002df0:	00000097          	auipc	ra,0x0
    80002df4:	e00080e7          	jalr	-512(ra) # 80002bf0 <devintr>
    80002df8:	cd1d                	beqz	a0,80002e36 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002dfa:	4789                	li	a5,2
    80002dfc:	06f50a63          	beq	a0,a5,80002e70 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e00:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e04:	10049073          	csrw	sstatus,s1
}
    80002e08:	70a2                	ld	ra,40(sp)
    80002e0a:	7402                	ld	s0,32(sp)
    80002e0c:	64e2                	ld	s1,24(sp)
    80002e0e:	6942                	ld	s2,16(sp)
    80002e10:	69a2                	ld	s3,8(sp)
    80002e12:	6145                	addi	sp,sp,48
    80002e14:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e16:	00005517          	auipc	a0,0x5
    80002e1a:	68250513          	addi	a0,a0,1666 # 80008498 <states.0+0xc8>
    80002e1e:	ffffd097          	auipc	ra,0xffffd
    80002e22:	71e080e7          	jalr	1822(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002e26:	00005517          	auipc	a0,0x5
    80002e2a:	69a50513          	addi	a0,a0,1690 # 800084c0 <states.0+0xf0>
    80002e2e:	ffffd097          	auipc	ra,0xffffd
    80002e32:	70e080e7          	jalr	1806(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002e36:	85ce                	mv	a1,s3
    80002e38:	00005517          	auipc	a0,0x5
    80002e3c:	6a850513          	addi	a0,a0,1704 # 800084e0 <states.0+0x110>
    80002e40:	ffffd097          	auipc	ra,0xffffd
    80002e44:	758080e7          	jalr	1880(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e48:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e4c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e50:	00005517          	auipc	a0,0x5
    80002e54:	6a050513          	addi	a0,a0,1696 # 800084f0 <states.0+0x120>
    80002e58:	ffffd097          	auipc	ra,0xffffd
    80002e5c:	740080e7          	jalr	1856(ra) # 80000598 <printf>
    panic("kerneltrap");
    80002e60:	00005517          	auipc	a0,0x5
    80002e64:	6a850513          	addi	a0,a0,1704 # 80008508 <states.0+0x138>
    80002e68:	ffffd097          	auipc	ra,0xffffd
    80002e6c:	6d4080e7          	jalr	1748(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e70:	fffff097          	auipc	ra,0xfffff
    80002e74:	dec080e7          	jalr	-532(ra) # 80001c5c <myproc>
    80002e78:	d541                	beqz	a0,80002e00 <kerneltrap+0x38>
    80002e7a:	fffff097          	auipc	ra,0xfffff
    80002e7e:	de2080e7          	jalr	-542(ra) # 80001c5c <myproc>
    80002e82:	4d18                	lw	a4,24(a0)
    80002e84:	4791                	li	a5,4
    80002e86:	f6f71de3          	bne	a4,a5,80002e00 <kerneltrap+0x38>
    yield();
    80002e8a:	fffff097          	auipc	ra,0xfffff
    80002e8e:	4fe080e7          	jalr	1278(ra) # 80002388 <yield>
    80002e92:	b7bd                	j	80002e00 <kerneltrap+0x38>

0000000080002e94 <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e94:	1101                	addi	sp,sp,-32
    80002e96:	ec06                	sd	ra,24(sp)
    80002e98:	e822                	sd	s0,16(sp)
    80002e9a:	e426                	sd	s1,8(sp)
    80002e9c:	1000                	addi	s0,sp,32
    80002e9e:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002ea0:	fffff097          	auipc	ra,0xfffff
    80002ea4:	dbc080e7          	jalr	-580(ra) # 80001c5c <myproc>
    switch (n)
    80002ea8:	4795                	li	a5,5
    80002eaa:	0497e163          	bltu	a5,s1,80002eec <argraw+0x58>
    80002eae:	048a                	slli	s1,s1,0x2
    80002eb0:	00005717          	auipc	a4,0x5
    80002eb4:	69070713          	addi	a4,a4,1680 # 80008540 <states.0+0x170>
    80002eb8:	94ba                	add	s1,s1,a4
    80002eba:	409c                	lw	a5,0(s1)
    80002ebc:	97ba                	add	a5,a5,a4
    80002ebe:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002ec0:	6d3c                	ld	a5,88(a0)
    80002ec2:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002ec4:	60e2                	ld	ra,24(sp)
    80002ec6:	6442                	ld	s0,16(sp)
    80002ec8:	64a2                	ld	s1,8(sp)
    80002eca:	6105                	addi	sp,sp,32
    80002ecc:	8082                	ret
        return p->trapframe->a1;
    80002ece:	6d3c                	ld	a5,88(a0)
    80002ed0:	7fa8                	ld	a0,120(a5)
    80002ed2:	bfcd                	j	80002ec4 <argraw+0x30>
        return p->trapframe->a2;
    80002ed4:	6d3c                	ld	a5,88(a0)
    80002ed6:	63c8                	ld	a0,128(a5)
    80002ed8:	b7f5                	j	80002ec4 <argraw+0x30>
        return p->trapframe->a3;
    80002eda:	6d3c                	ld	a5,88(a0)
    80002edc:	67c8                	ld	a0,136(a5)
    80002ede:	b7dd                	j	80002ec4 <argraw+0x30>
        return p->trapframe->a4;
    80002ee0:	6d3c                	ld	a5,88(a0)
    80002ee2:	6bc8                	ld	a0,144(a5)
    80002ee4:	b7c5                	j	80002ec4 <argraw+0x30>
        return p->trapframe->a5;
    80002ee6:	6d3c                	ld	a5,88(a0)
    80002ee8:	6fc8                	ld	a0,152(a5)
    80002eea:	bfe9                	j	80002ec4 <argraw+0x30>
    panic("argraw");
    80002eec:	00005517          	auipc	a0,0x5
    80002ef0:	62c50513          	addi	a0,a0,1580 # 80008518 <states.0+0x148>
    80002ef4:	ffffd097          	auipc	ra,0xffffd
    80002ef8:	648080e7          	jalr	1608(ra) # 8000053c <panic>

0000000080002efc <fetchaddr>:
{
    80002efc:	1101                	addi	sp,sp,-32
    80002efe:	ec06                	sd	ra,24(sp)
    80002f00:	e822                	sd	s0,16(sp)
    80002f02:	e426                	sd	s1,8(sp)
    80002f04:	e04a                	sd	s2,0(sp)
    80002f06:	1000                	addi	s0,sp,32
    80002f08:	84aa                	mv	s1,a0
    80002f0a:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002f0c:	fffff097          	auipc	ra,0xfffff
    80002f10:	d50080e7          	jalr	-688(ra) # 80001c5c <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002f14:	653c                	ld	a5,72(a0)
    80002f16:	02f4f863          	bgeu	s1,a5,80002f46 <fetchaddr+0x4a>
    80002f1a:	00848713          	addi	a4,s1,8
    80002f1e:	02e7e663          	bltu	a5,a4,80002f4a <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f22:	46a1                	li	a3,8
    80002f24:	8626                	mv	a2,s1
    80002f26:	85ca                	mv	a1,s2
    80002f28:	6928                	ld	a0,80(a0)
    80002f2a:	fffff097          	auipc	ra,0xfffff
    80002f2e:	906080e7          	jalr	-1786(ra) # 80001830 <copyin>
    80002f32:	00a03533          	snez	a0,a0
    80002f36:	40a00533          	neg	a0,a0
}
    80002f3a:	60e2                	ld	ra,24(sp)
    80002f3c:	6442                	ld	s0,16(sp)
    80002f3e:	64a2                	ld	s1,8(sp)
    80002f40:	6902                	ld	s2,0(sp)
    80002f42:	6105                	addi	sp,sp,32
    80002f44:	8082                	ret
        return -1;
    80002f46:	557d                	li	a0,-1
    80002f48:	bfcd                	j	80002f3a <fetchaddr+0x3e>
    80002f4a:	557d                	li	a0,-1
    80002f4c:	b7fd                	j	80002f3a <fetchaddr+0x3e>

0000000080002f4e <fetchstr>:
{
    80002f4e:	7179                	addi	sp,sp,-48
    80002f50:	f406                	sd	ra,40(sp)
    80002f52:	f022                	sd	s0,32(sp)
    80002f54:	ec26                	sd	s1,24(sp)
    80002f56:	e84a                	sd	s2,16(sp)
    80002f58:	e44e                	sd	s3,8(sp)
    80002f5a:	1800                	addi	s0,sp,48
    80002f5c:	892a                	mv	s2,a0
    80002f5e:	84ae                	mv	s1,a1
    80002f60:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002f62:	fffff097          	auipc	ra,0xfffff
    80002f66:	cfa080e7          	jalr	-774(ra) # 80001c5c <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002f6a:	86ce                	mv	a3,s3
    80002f6c:	864a                	mv	a2,s2
    80002f6e:	85a6                	mv	a1,s1
    80002f70:	6928                	ld	a0,80(a0)
    80002f72:	fffff097          	auipc	ra,0xfffff
    80002f76:	94c080e7          	jalr	-1716(ra) # 800018be <copyinstr>
    80002f7a:	00054e63          	bltz	a0,80002f96 <fetchstr+0x48>
    return strlen(buf);
    80002f7e:	8526                	mv	a0,s1
    80002f80:	ffffe097          	auipc	ra,0xffffe
    80002f84:	020080e7          	jalr	32(ra) # 80000fa0 <strlen>
}
    80002f88:	70a2                	ld	ra,40(sp)
    80002f8a:	7402                	ld	s0,32(sp)
    80002f8c:	64e2                	ld	s1,24(sp)
    80002f8e:	6942                	ld	s2,16(sp)
    80002f90:	69a2                	ld	s3,8(sp)
    80002f92:	6145                	addi	sp,sp,48
    80002f94:	8082                	ret
        return -1;
    80002f96:	557d                	li	a0,-1
    80002f98:	bfc5                	j	80002f88 <fetchstr+0x3a>

0000000080002f9a <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002f9a:	1101                	addi	sp,sp,-32
    80002f9c:	ec06                	sd	ra,24(sp)
    80002f9e:	e822                	sd	s0,16(sp)
    80002fa0:	e426                	sd	s1,8(sp)
    80002fa2:	1000                	addi	s0,sp,32
    80002fa4:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002fa6:	00000097          	auipc	ra,0x0
    80002faa:	eee080e7          	jalr	-274(ra) # 80002e94 <argraw>
    80002fae:	c088                	sw	a0,0(s1)
}
    80002fb0:	60e2                	ld	ra,24(sp)
    80002fb2:	6442                	ld	s0,16(sp)
    80002fb4:	64a2                	ld	s1,8(sp)
    80002fb6:	6105                	addi	sp,sp,32
    80002fb8:	8082                	ret

0000000080002fba <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002fba:	1101                	addi	sp,sp,-32
    80002fbc:	ec06                	sd	ra,24(sp)
    80002fbe:	e822                	sd	s0,16(sp)
    80002fc0:	e426                	sd	s1,8(sp)
    80002fc2:	1000                	addi	s0,sp,32
    80002fc4:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002fc6:	00000097          	auipc	ra,0x0
    80002fca:	ece080e7          	jalr	-306(ra) # 80002e94 <argraw>
    80002fce:	e088                	sd	a0,0(s1)
}
    80002fd0:	60e2                	ld	ra,24(sp)
    80002fd2:	6442                	ld	s0,16(sp)
    80002fd4:	64a2                	ld	s1,8(sp)
    80002fd6:	6105                	addi	sp,sp,32
    80002fd8:	8082                	ret

0000000080002fda <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002fda:	7179                	addi	sp,sp,-48
    80002fdc:	f406                	sd	ra,40(sp)
    80002fde:	f022                	sd	s0,32(sp)
    80002fe0:	ec26                	sd	s1,24(sp)
    80002fe2:	e84a                	sd	s2,16(sp)
    80002fe4:	1800                	addi	s0,sp,48
    80002fe6:	84ae                	mv	s1,a1
    80002fe8:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    80002fea:	fd840593          	addi	a1,s0,-40
    80002fee:	00000097          	auipc	ra,0x0
    80002ff2:	fcc080e7          	jalr	-52(ra) # 80002fba <argaddr>
    return fetchstr(addr, buf, max);
    80002ff6:	864a                	mv	a2,s2
    80002ff8:	85a6                	mv	a1,s1
    80002ffa:	fd843503          	ld	a0,-40(s0)
    80002ffe:	00000097          	auipc	ra,0x0
    80003002:	f50080e7          	jalr	-176(ra) # 80002f4e <fetchstr>
}
    80003006:	70a2                	ld	ra,40(sp)
    80003008:	7402                	ld	s0,32(sp)
    8000300a:	64e2                	ld	s1,24(sp)
    8000300c:	6942                	ld	s2,16(sp)
    8000300e:	6145                	addi	sp,sp,48
    80003010:	8082                	ret

0000000080003012 <syscall>:
    [SYS_pfreepages] sys_pfreepages,
    [SYS_va2pa] sys_va2pa,
};

void syscall(void)
{
    80003012:	1101                	addi	sp,sp,-32
    80003014:	ec06                	sd	ra,24(sp)
    80003016:	e822                	sd	s0,16(sp)
    80003018:	e426                	sd	s1,8(sp)
    8000301a:	e04a                	sd	s2,0(sp)
    8000301c:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    8000301e:	fffff097          	auipc	ra,0xfffff
    80003022:	c3e080e7          	jalr	-962(ra) # 80001c5c <myproc>
    80003026:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    80003028:	05853903          	ld	s2,88(a0)
    8000302c:	0a893783          	ld	a5,168(s2)
    80003030:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80003034:	37fd                	addiw	a5,a5,-1
    80003036:	4765                	li	a4,25
    80003038:	00f76f63          	bltu	a4,a5,80003056 <syscall+0x44>
    8000303c:	00369713          	slli	a4,a3,0x3
    80003040:	00005797          	auipc	a5,0x5
    80003044:	51878793          	addi	a5,a5,1304 # 80008558 <syscalls>
    80003048:	97ba                	add	a5,a5,a4
    8000304a:	639c                	ld	a5,0(a5)
    8000304c:	c789                	beqz	a5,80003056 <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    8000304e:	9782                	jalr	a5
    80003050:	06a93823          	sd	a0,112(s2)
    80003054:	a839                	j	80003072 <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    80003056:	15848613          	addi	a2,s1,344
    8000305a:	588c                	lw	a1,48(s1)
    8000305c:	00005517          	auipc	a0,0x5
    80003060:	4c450513          	addi	a0,a0,1220 # 80008520 <states.0+0x150>
    80003064:	ffffd097          	auipc	ra,0xffffd
    80003068:	534080e7          	jalr	1332(ra) # 80000598 <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    8000306c:	6cbc                	ld	a5,88(s1)
    8000306e:	577d                	li	a4,-1
    80003070:	fbb8                	sd	a4,112(a5)
    }
}
    80003072:	60e2                	ld	ra,24(sp)
    80003074:	6442                	ld	s0,16(sp)
    80003076:	64a2                	ld	s1,8(sp)
    80003078:	6902                	ld	s2,0(sp)
    8000307a:	6105                	addi	sp,sp,32
    8000307c:	8082                	ret

000000008000307e <sys_exit>:
extern uint64 FREE_PAGES; // kalloc.c keeps track of those
extern struct proc proc[];

uint64
sys_exit(void)
{
    8000307e:	1101                	addi	sp,sp,-32
    80003080:	ec06                	sd	ra,24(sp)
    80003082:	e822                	sd	s0,16(sp)
    80003084:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    80003086:	fec40593          	addi	a1,s0,-20
    8000308a:	4501                	li	a0,0
    8000308c:	00000097          	auipc	ra,0x0
    80003090:	f0e080e7          	jalr	-242(ra) # 80002f9a <argint>
    exit(n);
    80003094:	fec42503          	lw	a0,-20(s0)
    80003098:	fffff097          	auipc	ra,0xfffff
    8000309c:	460080e7          	jalr	1120(ra) # 800024f8 <exit>
    return 0; // not reached
}
    800030a0:	4501                	li	a0,0
    800030a2:	60e2                	ld	ra,24(sp)
    800030a4:	6442                	ld	s0,16(sp)
    800030a6:	6105                	addi	sp,sp,32
    800030a8:	8082                	ret

00000000800030aa <sys_getpid>:

uint64
sys_getpid(void)
{
    800030aa:	1141                	addi	sp,sp,-16
    800030ac:	e406                	sd	ra,8(sp)
    800030ae:	e022                	sd	s0,0(sp)
    800030b0:	0800                	addi	s0,sp,16
    return myproc()->pid;
    800030b2:	fffff097          	auipc	ra,0xfffff
    800030b6:	baa080e7          	jalr	-1110(ra) # 80001c5c <myproc>
}
    800030ba:	5908                	lw	a0,48(a0)
    800030bc:	60a2                	ld	ra,8(sp)
    800030be:	6402                	ld	s0,0(sp)
    800030c0:	0141                	addi	sp,sp,16
    800030c2:	8082                	ret

00000000800030c4 <sys_fork>:

uint64
sys_fork(void)
{
    800030c4:	1141                	addi	sp,sp,-16
    800030c6:	e406                	sd	ra,8(sp)
    800030c8:	e022                	sd	s0,0(sp)
    800030ca:	0800                	addi	s0,sp,16
    return fork();
    800030cc:	fffff097          	auipc	ra,0xfffff
    800030d0:	096080e7          	jalr	150(ra) # 80002162 <fork>
}
    800030d4:	60a2                	ld	ra,8(sp)
    800030d6:	6402                	ld	s0,0(sp)
    800030d8:	0141                	addi	sp,sp,16
    800030da:	8082                	ret

00000000800030dc <sys_wait>:

uint64
sys_wait(void)
{
    800030dc:	1101                	addi	sp,sp,-32
    800030de:	ec06                	sd	ra,24(sp)
    800030e0:	e822                	sd	s0,16(sp)
    800030e2:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    800030e4:	fe840593          	addi	a1,s0,-24
    800030e8:	4501                	li	a0,0
    800030ea:	00000097          	auipc	ra,0x0
    800030ee:	ed0080e7          	jalr	-304(ra) # 80002fba <argaddr>
    return wait(p);
    800030f2:	fe843503          	ld	a0,-24(s0)
    800030f6:	fffff097          	auipc	ra,0xfffff
    800030fa:	5a8080e7          	jalr	1448(ra) # 8000269e <wait>
}
    800030fe:	60e2                	ld	ra,24(sp)
    80003100:	6442                	ld	s0,16(sp)
    80003102:	6105                	addi	sp,sp,32
    80003104:	8082                	ret

0000000080003106 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003106:	7179                	addi	sp,sp,-48
    80003108:	f406                	sd	ra,40(sp)
    8000310a:	f022                	sd	s0,32(sp)
    8000310c:	ec26                	sd	s1,24(sp)
    8000310e:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    80003110:	fdc40593          	addi	a1,s0,-36
    80003114:	4501                	li	a0,0
    80003116:	00000097          	auipc	ra,0x0
    8000311a:	e84080e7          	jalr	-380(ra) # 80002f9a <argint>
    addr = myproc()->sz;
    8000311e:	fffff097          	auipc	ra,0xfffff
    80003122:	b3e080e7          	jalr	-1218(ra) # 80001c5c <myproc>
    80003126:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    80003128:	fdc42503          	lw	a0,-36(s0)
    8000312c:	fffff097          	auipc	ra,0xfffff
    80003130:	e8a080e7          	jalr	-374(ra) # 80001fb6 <growproc>
    80003134:	00054863          	bltz	a0,80003144 <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    80003138:	8526                	mv	a0,s1
    8000313a:	70a2                	ld	ra,40(sp)
    8000313c:	7402                	ld	s0,32(sp)
    8000313e:	64e2                	ld	s1,24(sp)
    80003140:	6145                	addi	sp,sp,48
    80003142:	8082                	ret
        return -1;
    80003144:	54fd                	li	s1,-1
    80003146:	bfcd                	j	80003138 <sys_sbrk+0x32>

0000000080003148 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003148:	7139                	addi	sp,sp,-64
    8000314a:	fc06                	sd	ra,56(sp)
    8000314c:	f822                	sd	s0,48(sp)
    8000314e:	f426                	sd	s1,40(sp)
    80003150:	f04a                	sd	s2,32(sp)
    80003152:	ec4e                	sd	s3,24(sp)
    80003154:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    80003156:	fcc40593          	addi	a1,s0,-52
    8000315a:	4501                	li	a0,0
    8000315c:	00000097          	auipc	ra,0x0
    80003160:	e3e080e7          	jalr	-450(ra) # 80002f9a <argint>
    acquire(&tickslock);
    80003164:	00234517          	auipc	a0,0x234
    80003168:	96c50513          	addi	a0,a0,-1684 # 80236ad0 <tickslock>
    8000316c:	ffffe097          	auipc	ra,0xffffe
    80003170:	bbe080e7          	jalr	-1090(ra) # 80000d2a <acquire>
    ticks0 = ticks;
    80003174:	00006917          	auipc	s2,0x6
    80003178:	8bc92903          	lw	s2,-1860(s2) # 80008a30 <ticks>
    while (ticks - ticks0 < n)
    8000317c:	fcc42783          	lw	a5,-52(s0)
    80003180:	cf9d                	beqz	a5,800031be <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    80003182:	00234997          	auipc	s3,0x234
    80003186:	94e98993          	addi	s3,s3,-1714 # 80236ad0 <tickslock>
    8000318a:	00006497          	auipc	s1,0x6
    8000318e:	8a648493          	addi	s1,s1,-1882 # 80008a30 <ticks>
        if (killed(myproc()))
    80003192:	fffff097          	auipc	ra,0xfffff
    80003196:	aca080e7          	jalr	-1334(ra) # 80001c5c <myproc>
    8000319a:	fffff097          	auipc	ra,0xfffff
    8000319e:	4d2080e7          	jalr	1234(ra) # 8000266c <killed>
    800031a2:	ed15                	bnez	a0,800031de <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    800031a4:	85ce                	mv	a1,s3
    800031a6:	8526                	mv	a0,s1
    800031a8:	fffff097          	auipc	ra,0xfffff
    800031ac:	21c080e7          	jalr	540(ra) # 800023c4 <sleep>
    while (ticks - ticks0 < n)
    800031b0:	409c                	lw	a5,0(s1)
    800031b2:	412787bb          	subw	a5,a5,s2
    800031b6:	fcc42703          	lw	a4,-52(s0)
    800031ba:	fce7ece3          	bltu	a5,a4,80003192 <sys_sleep+0x4a>
    }
    release(&tickslock);
    800031be:	00234517          	auipc	a0,0x234
    800031c2:	91250513          	addi	a0,a0,-1774 # 80236ad0 <tickslock>
    800031c6:	ffffe097          	auipc	ra,0xffffe
    800031ca:	c18080e7          	jalr	-1000(ra) # 80000dde <release>
    return 0;
    800031ce:	4501                	li	a0,0
}
    800031d0:	70e2                	ld	ra,56(sp)
    800031d2:	7442                	ld	s0,48(sp)
    800031d4:	74a2                	ld	s1,40(sp)
    800031d6:	7902                	ld	s2,32(sp)
    800031d8:	69e2                	ld	s3,24(sp)
    800031da:	6121                	addi	sp,sp,64
    800031dc:	8082                	ret
            release(&tickslock);
    800031de:	00234517          	auipc	a0,0x234
    800031e2:	8f250513          	addi	a0,a0,-1806 # 80236ad0 <tickslock>
    800031e6:	ffffe097          	auipc	ra,0xffffe
    800031ea:	bf8080e7          	jalr	-1032(ra) # 80000dde <release>
            return -1;
    800031ee:	557d                	li	a0,-1
    800031f0:	b7c5                	j	800031d0 <sys_sleep+0x88>

00000000800031f2 <sys_kill>:

uint64
sys_kill(void)
{
    800031f2:	1101                	addi	sp,sp,-32
    800031f4:	ec06                	sd	ra,24(sp)
    800031f6:	e822                	sd	s0,16(sp)
    800031f8:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    800031fa:	fec40593          	addi	a1,s0,-20
    800031fe:	4501                	li	a0,0
    80003200:	00000097          	auipc	ra,0x0
    80003204:	d9a080e7          	jalr	-614(ra) # 80002f9a <argint>
    return kill(pid);
    80003208:	fec42503          	lw	a0,-20(s0)
    8000320c:	fffff097          	auipc	ra,0xfffff
    80003210:	3c2080e7          	jalr	962(ra) # 800025ce <kill>
}
    80003214:	60e2                	ld	ra,24(sp)
    80003216:	6442                	ld	s0,16(sp)
    80003218:	6105                	addi	sp,sp,32
    8000321a:	8082                	ret

000000008000321c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000321c:	1101                	addi	sp,sp,-32
    8000321e:	ec06                	sd	ra,24(sp)
    80003220:	e822                	sd	s0,16(sp)
    80003222:	e426                	sd	s1,8(sp)
    80003224:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    80003226:	00234517          	auipc	a0,0x234
    8000322a:	8aa50513          	addi	a0,a0,-1878 # 80236ad0 <tickslock>
    8000322e:	ffffe097          	auipc	ra,0xffffe
    80003232:	afc080e7          	jalr	-1284(ra) # 80000d2a <acquire>
    xticks = ticks;
    80003236:	00005497          	auipc	s1,0x5
    8000323a:	7fa4a483          	lw	s1,2042(s1) # 80008a30 <ticks>
    release(&tickslock);
    8000323e:	00234517          	auipc	a0,0x234
    80003242:	89250513          	addi	a0,a0,-1902 # 80236ad0 <tickslock>
    80003246:	ffffe097          	auipc	ra,0xffffe
    8000324a:	b98080e7          	jalr	-1128(ra) # 80000dde <release>
    return xticks;
}
    8000324e:	02049513          	slli	a0,s1,0x20
    80003252:	9101                	srli	a0,a0,0x20
    80003254:	60e2                	ld	ra,24(sp)
    80003256:	6442                	ld	s0,16(sp)
    80003258:	64a2                	ld	s1,8(sp)
    8000325a:	6105                	addi	sp,sp,32
    8000325c:	8082                	ret

000000008000325e <sys_ps>:

void *
sys_ps(void)
{
    8000325e:	1101                	addi	sp,sp,-32
    80003260:	ec06                	sd	ra,24(sp)
    80003262:	e822                	sd	s0,16(sp)
    80003264:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    80003266:	fe042623          	sw	zero,-20(s0)
    8000326a:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    8000326e:	fec40593          	addi	a1,s0,-20
    80003272:	4501                	li	a0,0
    80003274:	00000097          	auipc	ra,0x0
    80003278:	d26080e7          	jalr	-730(ra) # 80002f9a <argint>
    argint(1, &count);
    8000327c:	fe840593          	addi	a1,s0,-24
    80003280:	4505                	li	a0,1
    80003282:	00000097          	auipc	ra,0x0
    80003286:	d18080e7          	jalr	-744(ra) # 80002f9a <argint>
    return ps((uint8)start, (uint8)count);
    8000328a:	fe844583          	lbu	a1,-24(s0)
    8000328e:	fec44503          	lbu	a0,-20(s0)
    80003292:	fffff097          	auipc	ra,0xfffff
    80003296:	d80080e7          	jalr	-640(ra) # 80002012 <ps>
}
    8000329a:	60e2                	ld	ra,24(sp)
    8000329c:	6442                	ld	s0,16(sp)
    8000329e:	6105                	addi	sp,sp,32
    800032a0:	8082                	ret

00000000800032a2 <sys_schedls>:

uint64 sys_schedls(void)
{
    800032a2:	1141                	addi	sp,sp,-16
    800032a4:	e406                	sd	ra,8(sp)
    800032a6:	e022                	sd	s0,0(sp)
    800032a8:	0800                	addi	s0,sp,16
    schedls();
    800032aa:	fffff097          	auipc	ra,0xfffff
    800032ae:	67e080e7          	jalr	1662(ra) # 80002928 <schedls>
    return 0;
}
    800032b2:	4501                	li	a0,0
    800032b4:	60a2                	ld	ra,8(sp)
    800032b6:	6402                	ld	s0,0(sp)
    800032b8:	0141                	addi	sp,sp,16
    800032ba:	8082                	ret

00000000800032bc <sys_schedset>:

uint64 sys_schedset(void)
{
    800032bc:	1101                	addi	sp,sp,-32
    800032be:	ec06                	sd	ra,24(sp)
    800032c0:	e822                	sd	s0,16(sp)
    800032c2:	1000                	addi	s0,sp,32
    int id = 0;
    800032c4:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    800032c8:	fec40593          	addi	a1,s0,-20
    800032cc:	4501                	li	a0,0
    800032ce:	00000097          	auipc	ra,0x0
    800032d2:	ccc080e7          	jalr	-820(ra) # 80002f9a <argint>
    schedset(id - 1);
    800032d6:	fec42503          	lw	a0,-20(s0)
    800032da:	357d                	addiw	a0,a0,-1
    800032dc:	fffff097          	auipc	ra,0xfffff
    800032e0:	6e2080e7          	jalr	1762(ra) # 800029be <schedset>
    return 0;
}
    800032e4:	4501                	li	a0,0
    800032e6:	60e2                	ld	ra,24(sp)
    800032e8:	6442                	ld	s0,16(sp)
    800032ea:	6105                	addi	sp,sp,32
    800032ec:	8082                	ret

00000000800032ee <sys_va2pa>:

uint64 sys_va2pa(uint64 addr, int pid) {
    800032ee:	1101                	addi	sp,sp,-32
    800032f0:	ec06                	sd	ra,24(sp)
    800032f2:	e822                	sd	s0,16(sp)
    800032f4:	1000                	addi	s0,sp,32
    800032f6:	fea43423          	sd	a0,-24(s0)
    800032fa:	feb42223          	sw	a1,-28(s0)
    argaddr(0, &addr);
    800032fe:	fe840593          	addi	a1,s0,-24
    80003302:	4501                	li	a0,0
    80003304:	00000097          	auipc	ra,0x0
    80003308:	cb6080e7          	jalr	-842(ra) # 80002fba <argaddr>
    argint(1, &pid);
    8000330c:	fe440593          	addi	a1,s0,-28
    80003310:	4505                	li	a0,1
    80003312:	00000097          	auipc	ra,0x0
    80003316:	c88080e7          	jalr	-888(ra) # 80002f9a <argint>

    if (!pid) {
    8000331a:	fe442783          	lw	a5,-28(s0)
    8000331e:	c785                	beqz	a5,80003346 <sys_va2pa+0x58>

    // Check if the provided pid is valid
    int pidIsValid = 0;
    struct proc *p;
    for (p = proc; p < &proc[NPROC]; p++) {
        if (p->pid == pid) {
    80003320:	fe442503          	lw	a0,-28(s0)
    for (p = proc; p < &proc[NPROC]; p++) {
    80003324:	0022e797          	auipc	a5,0x22e
    80003328:	dac78793          	addi	a5,a5,-596 # 802310d0 <proc>
    8000332c:	00233697          	auipc	a3,0x233
    80003330:	7a468693          	addi	a3,a3,1956 # 80236ad0 <tickslock>
        if (p->pid == pid) {
    80003334:	5b98                	lw	a4,48(a5)
    80003336:	02a70063          	beq	a4,a0,80003356 <sys_va2pa+0x68>
    for (p = proc; p < &proc[NPROC]; p++) {
    8000333a:	16878793          	addi	a5,a5,360
    8000333e:	fed79be3          	bne	a5,a3,80003334 <sys_va2pa+0x46>
            pidIsValid = 1;
            break;
        }
    }
    if (!pidIsValid) { //Return 0 if pid is not valid
        return pidIsValid;
    80003342:	4501                	li	a0,0
    80003344:	a025                	j	8000336c <sys_va2pa+0x7e>
        pid = myproc()->pid;
    80003346:	fffff097          	auipc	ra,0xfffff
    8000334a:	916080e7          	jalr	-1770(ra) # 80001c5c <myproc>
    8000334e:	591c                	lw	a5,48(a0)
    80003350:	fef42223          	sw	a5,-28(s0)
    80003354:	b7f1                	j	80003320 <sys_va2pa+0x32>
    } else {
    struct proc *p1 = getProc(pid);
    80003356:	fffff097          	auipc	ra,0xfffff
    8000335a:	6b4080e7          	jalr	1716(ra) # 80002a0a <getProc>
    return walkaddr(p1->pagetable, addr); //Return physical address
    8000335e:	fe843583          	ld	a1,-24(s0)
    80003362:	6928                	ld	a0,80(a0)
    80003364:	ffffe097          	auipc	ra,0xffffe
    80003368:	e4a080e7          	jalr	-438(ra) # 800011ae <walkaddr>
    }
}
    8000336c:	60e2                	ld	ra,24(sp)
    8000336e:	6442                	ld	s0,16(sp)
    80003370:	6105                	addi	sp,sp,32
    80003372:	8082                	ret

0000000080003374 <sys_pfreepages>:

uint64 sys_pfreepages(void)
{
    80003374:	1141                	addi	sp,sp,-16
    80003376:	e406                	sd	ra,8(sp)
    80003378:	e022                	sd	s0,0(sp)
    8000337a:	0800                	addi	s0,sp,16
    printf("%d\n", FREE_PAGES);
    8000337c:	00005597          	auipc	a1,0x5
    80003380:	68c5b583          	ld	a1,1676(a1) # 80008a08 <FREE_PAGES>
    80003384:	00005517          	auipc	a0,0x5
    80003388:	1b450513          	addi	a0,a0,436 # 80008538 <states.0+0x168>
    8000338c:	ffffd097          	auipc	ra,0xffffd
    80003390:	20c080e7          	jalr	524(ra) # 80000598 <printf>
    return 0;
    80003394:	4501                	li	a0,0
    80003396:	60a2                	ld	ra,8(sp)
    80003398:	6402                	ld	s0,0(sp)
    8000339a:	0141                	addi	sp,sp,16
    8000339c:	8082                	ret

000000008000339e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000339e:	7179                	addi	sp,sp,-48
    800033a0:	f406                	sd	ra,40(sp)
    800033a2:	f022                	sd	s0,32(sp)
    800033a4:	ec26                	sd	s1,24(sp)
    800033a6:	e84a                	sd	s2,16(sp)
    800033a8:	e44e                	sd	s3,8(sp)
    800033aa:	e052                	sd	s4,0(sp)
    800033ac:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800033ae:	00005597          	auipc	a1,0x5
    800033b2:	28258593          	addi	a1,a1,642 # 80008630 <syscalls+0xd8>
    800033b6:	00233517          	auipc	a0,0x233
    800033ba:	73250513          	addi	a0,a0,1842 # 80236ae8 <bcache>
    800033be:	ffffe097          	auipc	ra,0xffffe
    800033c2:	8dc080e7          	jalr	-1828(ra) # 80000c9a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033c6:	0023b797          	auipc	a5,0x23b
    800033ca:	72278793          	addi	a5,a5,1826 # 8023eae8 <bcache+0x8000>
    800033ce:	0023c717          	auipc	a4,0x23c
    800033d2:	98270713          	addi	a4,a4,-1662 # 8023ed50 <bcache+0x8268>
    800033d6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800033da:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033de:	00233497          	auipc	s1,0x233
    800033e2:	72248493          	addi	s1,s1,1826 # 80236b00 <bcache+0x18>
    b->next = bcache.head.next;
    800033e6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033e8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033ea:	00005a17          	auipc	s4,0x5
    800033ee:	24ea0a13          	addi	s4,s4,590 # 80008638 <syscalls+0xe0>
    b->next = bcache.head.next;
    800033f2:	2b893783          	ld	a5,696(s2)
    800033f6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800033f8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800033fc:	85d2                	mv	a1,s4
    800033fe:	01048513          	addi	a0,s1,16
    80003402:	00001097          	auipc	ra,0x1
    80003406:	496080e7          	jalr	1174(ra) # 80004898 <initsleeplock>
    bcache.head.next->prev = b;
    8000340a:	2b893783          	ld	a5,696(s2)
    8000340e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003410:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003414:	45848493          	addi	s1,s1,1112
    80003418:	fd349de3          	bne	s1,s3,800033f2 <binit+0x54>
  }
}
    8000341c:	70a2                	ld	ra,40(sp)
    8000341e:	7402                	ld	s0,32(sp)
    80003420:	64e2                	ld	s1,24(sp)
    80003422:	6942                	ld	s2,16(sp)
    80003424:	69a2                	ld	s3,8(sp)
    80003426:	6a02                	ld	s4,0(sp)
    80003428:	6145                	addi	sp,sp,48
    8000342a:	8082                	ret

000000008000342c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000342c:	7179                	addi	sp,sp,-48
    8000342e:	f406                	sd	ra,40(sp)
    80003430:	f022                	sd	s0,32(sp)
    80003432:	ec26                	sd	s1,24(sp)
    80003434:	e84a                	sd	s2,16(sp)
    80003436:	e44e                	sd	s3,8(sp)
    80003438:	1800                	addi	s0,sp,48
    8000343a:	892a                	mv	s2,a0
    8000343c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000343e:	00233517          	auipc	a0,0x233
    80003442:	6aa50513          	addi	a0,a0,1706 # 80236ae8 <bcache>
    80003446:	ffffe097          	auipc	ra,0xffffe
    8000344a:	8e4080e7          	jalr	-1820(ra) # 80000d2a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000344e:	0023c497          	auipc	s1,0x23c
    80003452:	9524b483          	ld	s1,-1710(s1) # 8023eda0 <bcache+0x82b8>
    80003456:	0023c797          	auipc	a5,0x23c
    8000345a:	8fa78793          	addi	a5,a5,-1798 # 8023ed50 <bcache+0x8268>
    8000345e:	02f48f63          	beq	s1,a5,8000349c <bread+0x70>
    80003462:	873e                	mv	a4,a5
    80003464:	a021                	j	8000346c <bread+0x40>
    80003466:	68a4                	ld	s1,80(s1)
    80003468:	02e48a63          	beq	s1,a4,8000349c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000346c:	449c                	lw	a5,8(s1)
    8000346e:	ff279ce3          	bne	a5,s2,80003466 <bread+0x3a>
    80003472:	44dc                	lw	a5,12(s1)
    80003474:	ff3799e3          	bne	a5,s3,80003466 <bread+0x3a>
      b->refcnt++;
    80003478:	40bc                	lw	a5,64(s1)
    8000347a:	2785                	addiw	a5,a5,1
    8000347c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000347e:	00233517          	auipc	a0,0x233
    80003482:	66a50513          	addi	a0,a0,1642 # 80236ae8 <bcache>
    80003486:	ffffe097          	auipc	ra,0xffffe
    8000348a:	958080e7          	jalr	-1704(ra) # 80000dde <release>
      acquiresleep(&b->lock);
    8000348e:	01048513          	addi	a0,s1,16
    80003492:	00001097          	auipc	ra,0x1
    80003496:	440080e7          	jalr	1088(ra) # 800048d2 <acquiresleep>
      return b;
    8000349a:	a8b9                	j	800034f8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000349c:	0023c497          	auipc	s1,0x23c
    800034a0:	8fc4b483          	ld	s1,-1796(s1) # 8023ed98 <bcache+0x82b0>
    800034a4:	0023c797          	auipc	a5,0x23c
    800034a8:	8ac78793          	addi	a5,a5,-1876 # 8023ed50 <bcache+0x8268>
    800034ac:	00f48863          	beq	s1,a5,800034bc <bread+0x90>
    800034b0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800034b2:	40bc                	lw	a5,64(s1)
    800034b4:	cf81                	beqz	a5,800034cc <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034b6:	64a4                	ld	s1,72(s1)
    800034b8:	fee49de3          	bne	s1,a4,800034b2 <bread+0x86>
  panic("bget: no buffers");
    800034bc:	00005517          	auipc	a0,0x5
    800034c0:	18450513          	addi	a0,a0,388 # 80008640 <syscalls+0xe8>
    800034c4:	ffffd097          	auipc	ra,0xffffd
    800034c8:	078080e7          	jalr	120(ra) # 8000053c <panic>
      b->dev = dev;
    800034cc:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800034d0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800034d4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800034d8:	4785                	li	a5,1
    800034da:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034dc:	00233517          	auipc	a0,0x233
    800034e0:	60c50513          	addi	a0,a0,1548 # 80236ae8 <bcache>
    800034e4:	ffffe097          	auipc	ra,0xffffe
    800034e8:	8fa080e7          	jalr	-1798(ra) # 80000dde <release>
      acquiresleep(&b->lock);
    800034ec:	01048513          	addi	a0,s1,16
    800034f0:	00001097          	auipc	ra,0x1
    800034f4:	3e2080e7          	jalr	994(ra) # 800048d2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800034f8:	409c                	lw	a5,0(s1)
    800034fa:	cb89                	beqz	a5,8000350c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800034fc:	8526                	mv	a0,s1
    800034fe:	70a2                	ld	ra,40(sp)
    80003500:	7402                	ld	s0,32(sp)
    80003502:	64e2                	ld	s1,24(sp)
    80003504:	6942                	ld	s2,16(sp)
    80003506:	69a2                	ld	s3,8(sp)
    80003508:	6145                	addi	sp,sp,48
    8000350a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000350c:	4581                	li	a1,0
    8000350e:	8526                	mv	a0,s1
    80003510:	00003097          	auipc	ra,0x3
    80003514:	f82080e7          	jalr	-126(ra) # 80006492 <virtio_disk_rw>
    b->valid = 1;
    80003518:	4785                	li	a5,1
    8000351a:	c09c                	sw	a5,0(s1)
  return b;
    8000351c:	b7c5                	j	800034fc <bread+0xd0>

000000008000351e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000351e:	1101                	addi	sp,sp,-32
    80003520:	ec06                	sd	ra,24(sp)
    80003522:	e822                	sd	s0,16(sp)
    80003524:	e426                	sd	s1,8(sp)
    80003526:	1000                	addi	s0,sp,32
    80003528:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000352a:	0541                	addi	a0,a0,16
    8000352c:	00001097          	auipc	ra,0x1
    80003530:	440080e7          	jalr	1088(ra) # 8000496c <holdingsleep>
    80003534:	cd01                	beqz	a0,8000354c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003536:	4585                	li	a1,1
    80003538:	8526                	mv	a0,s1
    8000353a:	00003097          	auipc	ra,0x3
    8000353e:	f58080e7          	jalr	-168(ra) # 80006492 <virtio_disk_rw>
}
    80003542:	60e2                	ld	ra,24(sp)
    80003544:	6442                	ld	s0,16(sp)
    80003546:	64a2                	ld	s1,8(sp)
    80003548:	6105                	addi	sp,sp,32
    8000354a:	8082                	ret
    panic("bwrite");
    8000354c:	00005517          	auipc	a0,0x5
    80003550:	10c50513          	addi	a0,a0,268 # 80008658 <syscalls+0x100>
    80003554:	ffffd097          	auipc	ra,0xffffd
    80003558:	fe8080e7          	jalr	-24(ra) # 8000053c <panic>

000000008000355c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000355c:	1101                	addi	sp,sp,-32
    8000355e:	ec06                	sd	ra,24(sp)
    80003560:	e822                	sd	s0,16(sp)
    80003562:	e426                	sd	s1,8(sp)
    80003564:	e04a                	sd	s2,0(sp)
    80003566:	1000                	addi	s0,sp,32
    80003568:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000356a:	01050913          	addi	s2,a0,16
    8000356e:	854a                	mv	a0,s2
    80003570:	00001097          	auipc	ra,0x1
    80003574:	3fc080e7          	jalr	1020(ra) # 8000496c <holdingsleep>
    80003578:	c925                	beqz	a0,800035e8 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    8000357a:	854a                	mv	a0,s2
    8000357c:	00001097          	auipc	ra,0x1
    80003580:	3ac080e7          	jalr	940(ra) # 80004928 <releasesleep>

  acquire(&bcache.lock);
    80003584:	00233517          	auipc	a0,0x233
    80003588:	56450513          	addi	a0,a0,1380 # 80236ae8 <bcache>
    8000358c:	ffffd097          	auipc	ra,0xffffd
    80003590:	79e080e7          	jalr	1950(ra) # 80000d2a <acquire>
  b->refcnt--;
    80003594:	40bc                	lw	a5,64(s1)
    80003596:	37fd                	addiw	a5,a5,-1
    80003598:	0007871b          	sext.w	a4,a5
    8000359c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000359e:	e71d                	bnez	a4,800035cc <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800035a0:	68b8                	ld	a4,80(s1)
    800035a2:	64bc                	ld	a5,72(s1)
    800035a4:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800035a6:	68b8                	ld	a4,80(s1)
    800035a8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800035aa:	0023b797          	auipc	a5,0x23b
    800035ae:	53e78793          	addi	a5,a5,1342 # 8023eae8 <bcache+0x8000>
    800035b2:	2b87b703          	ld	a4,696(a5)
    800035b6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800035b8:	0023b717          	auipc	a4,0x23b
    800035bc:	79870713          	addi	a4,a4,1944 # 8023ed50 <bcache+0x8268>
    800035c0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035c2:	2b87b703          	ld	a4,696(a5)
    800035c6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800035c8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800035cc:	00233517          	auipc	a0,0x233
    800035d0:	51c50513          	addi	a0,a0,1308 # 80236ae8 <bcache>
    800035d4:	ffffe097          	auipc	ra,0xffffe
    800035d8:	80a080e7          	jalr	-2038(ra) # 80000dde <release>
}
    800035dc:	60e2                	ld	ra,24(sp)
    800035de:	6442                	ld	s0,16(sp)
    800035e0:	64a2                	ld	s1,8(sp)
    800035e2:	6902                	ld	s2,0(sp)
    800035e4:	6105                	addi	sp,sp,32
    800035e6:	8082                	ret
    panic("brelse");
    800035e8:	00005517          	auipc	a0,0x5
    800035ec:	07850513          	addi	a0,a0,120 # 80008660 <syscalls+0x108>
    800035f0:	ffffd097          	auipc	ra,0xffffd
    800035f4:	f4c080e7          	jalr	-180(ra) # 8000053c <panic>

00000000800035f8 <bpin>:

void
bpin(struct buf *b) {
    800035f8:	1101                	addi	sp,sp,-32
    800035fa:	ec06                	sd	ra,24(sp)
    800035fc:	e822                	sd	s0,16(sp)
    800035fe:	e426                	sd	s1,8(sp)
    80003600:	1000                	addi	s0,sp,32
    80003602:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003604:	00233517          	auipc	a0,0x233
    80003608:	4e450513          	addi	a0,a0,1252 # 80236ae8 <bcache>
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	71e080e7          	jalr	1822(ra) # 80000d2a <acquire>
  b->refcnt++;
    80003614:	40bc                	lw	a5,64(s1)
    80003616:	2785                	addiw	a5,a5,1
    80003618:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000361a:	00233517          	auipc	a0,0x233
    8000361e:	4ce50513          	addi	a0,a0,1230 # 80236ae8 <bcache>
    80003622:	ffffd097          	auipc	ra,0xffffd
    80003626:	7bc080e7          	jalr	1980(ra) # 80000dde <release>
}
    8000362a:	60e2                	ld	ra,24(sp)
    8000362c:	6442                	ld	s0,16(sp)
    8000362e:	64a2                	ld	s1,8(sp)
    80003630:	6105                	addi	sp,sp,32
    80003632:	8082                	ret

0000000080003634 <bunpin>:

void
bunpin(struct buf *b) {
    80003634:	1101                	addi	sp,sp,-32
    80003636:	ec06                	sd	ra,24(sp)
    80003638:	e822                	sd	s0,16(sp)
    8000363a:	e426                	sd	s1,8(sp)
    8000363c:	1000                	addi	s0,sp,32
    8000363e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003640:	00233517          	auipc	a0,0x233
    80003644:	4a850513          	addi	a0,a0,1192 # 80236ae8 <bcache>
    80003648:	ffffd097          	auipc	ra,0xffffd
    8000364c:	6e2080e7          	jalr	1762(ra) # 80000d2a <acquire>
  b->refcnt--;
    80003650:	40bc                	lw	a5,64(s1)
    80003652:	37fd                	addiw	a5,a5,-1
    80003654:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003656:	00233517          	auipc	a0,0x233
    8000365a:	49250513          	addi	a0,a0,1170 # 80236ae8 <bcache>
    8000365e:	ffffd097          	auipc	ra,0xffffd
    80003662:	780080e7          	jalr	1920(ra) # 80000dde <release>
}
    80003666:	60e2                	ld	ra,24(sp)
    80003668:	6442                	ld	s0,16(sp)
    8000366a:	64a2                	ld	s1,8(sp)
    8000366c:	6105                	addi	sp,sp,32
    8000366e:	8082                	ret

0000000080003670 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003670:	1101                	addi	sp,sp,-32
    80003672:	ec06                	sd	ra,24(sp)
    80003674:	e822                	sd	s0,16(sp)
    80003676:	e426                	sd	s1,8(sp)
    80003678:	e04a                	sd	s2,0(sp)
    8000367a:	1000                	addi	s0,sp,32
    8000367c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000367e:	00d5d59b          	srliw	a1,a1,0xd
    80003682:	0023c797          	auipc	a5,0x23c
    80003686:	b427a783          	lw	a5,-1214(a5) # 8023f1c4 <sb+0x1c>
    8000368a:	9dbd                	addw	a1,a1,a5
    8000368c:	00000097          	auipc	ra,0x0
    80003690:	da0080e7          	jalr	-608(ra) # 8000342c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003694:	0074f713          	andi	a4,s1,7
    80003698:	4785                	li	a5,1
    8000369a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000369e:	14ce                	slli	s1,s1,0x33
    800036a0:	90d9                	srli	s1,s1,0x36
    800036a2:	00950733          	add	a4,a0,s1
    800036a6:	05874703          	lbu	a4,88(a4)
    800036aa:	00e7f6b3          	and	a3,a5,a4
    800036ae:	c69d                	beqz	a3,800036dc <bfree+0x6c>
    800036b0:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800036b2:	94aa                	add	s1,s1,a0
    800036b4:	fff7c793          	not	a5,a5
    800036b8:	8f7d                	and	a4,a4,a5
    800036ba:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800036be:	00001097          	auipc	ra,0x1
    800036c2:	0f6080e7          	jalr	246(ra) # 800047b4 <log_write>
  brelse(bp);
    800036c6:	854a                	mv	a0,s2
    800036c8:	00000097          	auipc	ra,0x0
    800036cc:	e94080e7          	jalr	-364(ra) # 8000355c <brelse>
}
    800036d0:	60e2                	ld	ra,24(sp)
    800036d2:	6442                	ld	s0,16(sp)
    800036d4:	64a2                	ld	s1,8(sp)
    800036d6:	6902                	ld	s2,0(sp)
    800036d8:	6105                	addi	sp,sp,32
    800036da:	8082                	ret
    panic("freeing free block");
    800036dc:	00005517          	auipc	a0,0x5
    800036e0:	f8c50513          	addi	a0,a0,-116 # 80008668 <syscalls+0x110>
    800036e4:	ffffd097          	auipc	ra,0xffffd
    800036e8:	e58080e7          	jalr	-424(ra) # 8000053c <panic>

00000000800036ec <balloc>:
{
    800036ec:	711d                	addi	sp,sp,-96
    800036ee:	ec86                	sd	ra,88(sp)
    800036f0:	e8a2                	sd	s0,80(sp)
    800036f2:	e4a6                	sd	s1,72(sp)
    800036f4:	e0ca                	sd	s2,64(sp)
    800036f6:	fc4e                	sd	s3,56(sp)
    800036f8:	f852                	sd	s4,48(sp)
    800036fa:	f456                	sd	s5,40(sp)
    800036fc:	f05a                	sd	s6,32(sp)
    800036fe:	ec5e                	sd	s7,24(sp)
    80003700:	e862                	sd	s8,16(sp)
    80003702:	e466                	sd	s9,8(sp)
    80003704:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003706:	0023c797          	auipc	a5,0x23c
    8000370a:	aa67a783          	lw	a5,-1370(a5) # 8023f1ac <sb+0x4>
    8000370e:	cff5                	beqz	a5,8000380a <balloc+0x11e>
    80003710:	8baa                	mv	s7,a0
    80003712:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003714:	0023cb17          	auipc	s6,0x23c
    80003718:	a94b0b13          	addi	s6,s6,-1388 # 8023f1a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000371c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000371e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003720:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003722:	6c89                	lui	s9,0x2
    80003724:	a061                	j	800037ac <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003726:	97ca                	add	a5,a5,s2
    80003728:	8e55                	or	a2,a2,a3
    8000372a:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000372e:	854a                	mv	a0,s2
    80003730:	00001097          	auipc	ra,0x1
    80003734:	084080e7          	jalr	132(ra) # 800047b4 <log_write>
        brelse(bp);
    80003738:	854a                	mv	a0,s2
    8000373a:	00000097          	auipc	ra,0x0
    8000373e:	e22080e7          	jalr	-478(ra) # 8000355c <brelse>
  bp = bread(dev, bno);
    80003742:	85a6                	mv	a1,s1
    80003744:	855e                	mv	a0,s7
    80003746:	00000097          	auipc	ra,0x0
    8000374a:	ce6080e7          	jalr	-794(ra) # 8000342c <bread>
    8000374e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003750:	40000613          	li	a2,1024
    80003754:	4581                	li	a1,0
    80003756:	05850513          	addi	a0,a0,88
    8000375a:	ffffd097          	auipc	ra,0xffffd
    8000375e:	6cc080e7          	jalr	1740(ra) # 80000e26 <memset>
  log_write(bp);
    80003762:	854a                	mv	a0,s2
    80003764:	00001097          	auipc	ra,0x1
    80003768:	050080e7          	jalr	80(ra) # 800047b4 <log_write>
  brelse(bp);
    8000376c:	854a                	mv	a0,s2
    8000376e:	00000097          	auipc	ra,0x0
    80003772:	dee080e7          	jalr	-530(ra) # 8000355c <brelse>
}
    80003776:	8526                	mv	a0,s1
    80003778:	60e6                	ld	ra,88(sp)
    8000377a:	6446                	ld	s0,80(sp)
    8000377c:	64a6                	ld	s1,72(sp)
    8000377e:	6906                	ld	s2,64(sp)
    80003780:	79e2                	ld	s3,56(sp)
    80003782:	7a42                	ld	s4,48(sp)
    80003784:	7aa2                	ld	s5,40(sp)
    80003786:	7b02                	ld	s6,32(sp)
    80003788:	6be2                	ld	s7,24(sp)
    8000378a:	6c42                	ld	s8,16(sp)
    8000378c:	6ca2                	ld	s9,8(sp)
    8000378e:	6125                	addi	sp,sp,96
    80003790:	8082                	ret
    brelse(bp);
    80003792:	854a                	mv	a0,s2
    80003794:	00000097          	auipc	ra,0x0
    80003798:	dc8080e7          	jalr	-568(ra) # 8000355c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000379c:	015c87bb          	addw	a5,s9,s5
    800037a0:	00078a9b          	sext.w	s5,a5
    800037a4:	004b2703          	lw	a4,4(s6)
    800037a8:	06eaf163          	bgeu	s5,a4,8000380a <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800037ac:	41fad79b          	sraiw	a5,s5,0x1f
    800037b0:	0137d79b          	srliw	a5,a5,0x13
    800037b4:	015787bb          	addw	a5,a5,s5
    800037b8:	40d7d79b          	sraiw	a5,a5,0xd
    800037bc:	01cb2583          	lw	a1,28(s6)
    800037c0:	9dbd                	addw	a1,a1,a5
    800037c2:	855e                	mv	a0,s7
    800037c4:	00000097          	auipc	ra,0x0
    800037c8:	c68080e7          	jalr	-920(ra) # 8000342c <bread>
    800037cc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037ce:	004b2503          	lw	a0,4(s6)
    800037d2:	000a849b          	sext.w	s1,s5
    800037d6:	8762                	mv	a4,s8
    800037d8:	faa4fde3          	bgeu	s1,a0,80003792 <balloc+0xa6>
      m = 1 << (bi % 8);
    800037dc:	00777693          	andi	a3,a4,7
    800037e0:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800037e4:	41f7579b          	sraiw	a5,a4,0x1f
    800037e8:	01d7d79b          	srliw	a5,a5,0x1d
    800037ec:	9fb9                	addw	a5,a5,a4
    800037ee:	4037d79b          	sraiw	a5,a5,0x3
    800037f2:	00f90633          	add	a2,s2,a5
    800037f6:	05864603          	lbu	a2,88(a2)
    800037fa:	00c6f5b3          	and	a1,a3,a2
    800037fe:	d585                	beqz	a1,80003726 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003800:	2705                	addiw	a4,a4,1
    80003802:	2485                	addiw	s1,s1,1
    80003804:	fd471ae3          	bne	a4,s4,800037d8 <balloc+0xec>
    80003808:	b769                	j	80003792 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000380a:	00005517          	auipc	a0,0x5
    8000380e:	e7650513          	addi	a0,a0,-394 # 80008680 <syscalls+0x128>
    80003812:	ffffd097          	auipc	ra,0xffffd
    80003816:	d86080e7          	jalr	-634(ra) # 80000598 <printf>
  return 0;
    8000381a:	4481                	li	s1,0
    8000381c:	bfa9                	j	80003776 <balloc+0x8a>

000000008000381e <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000381e:	7179                	addi	sp,sp,-48
    80003820:	f406                	sd	ra,40(sp)
    80003822:	f022                	sd	s0,32(sp)
    80003824:	ec26                	sd	s1,24(sp)
    80003826:	e84a                	sd	s2,16(sp)
    80003828:	e44e                	sd	s3,8(sp)
    8000382a:	e052                	sd	s4,0(sp)
    8000382c:	1800                	addi	s0,sp,48
    8000382e:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003830:	47ad                	li	a5,11
    80003832:	02b7e863          	bltu	a5,a1,80003862 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003836:	02059793          	slli	a5,a1,0x20
    8000383a:	01e7d593          	srli	a1,a5,0x1e
    8000383e:	00b504b3          	add	s1,a0,a1
    80003842:	0504a903          	lw	s2,80(s1)
    80003846:	06091e63          	bnez	s2,800038c2 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000384a:	4108                	lw	a0,0(a0)
    8000384c:	00000097          	auipc	ra,0x0
    80003850:	ea0080e7          	jalr	-352(ra) # 800036ec <balloc>
    80003854:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003858:	06090563          	beqz	s2,800038c2 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000385c:	0524a823          	sw	s2,80(s1)
    80003860:	a08d                	j	800038c2 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003862:	ff45849b          	addiw	s1,a1,-12
    80003866:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000386a:	0ff00793          	li	a5,255
    8000386e:	08e7e563          	bltu	a5,a4,800038f8 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003872:	08052903          	lw	s2,128(a0)
    80003876:	00091d63          	bnez	s2,80003890 <bmap+0x72>
      addr = balloc(ip->dev);
    8000387a:	4108                	lw	a0,0(a0)
    8000387c:	00000097          	auipc	ra,0x0
    80003880:	e70080e7          	jalr	-400(ra) # 800036ec <balloc>
    80003884:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003888:	02090d63          	beqz	s2,800038c2 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000388c:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003890:	85ca                	mv	a1,s2
    80003892:	0009a503          	lw	a0,0(s3)
    80003896:	00000097          	auipc	ra,0x0
    8000389a:	b96080e7          	jalr	-1130(ra) # 8000342c <bread>
    8000389e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800038a0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800038a4:	02049713          	slli	a4,s1,0x20
    800038a8:	01e75593          	srli	a1,a4,0x1e
    800038ac:	00b784b3          	add	s1,a5,a1
    800038b0:	0004a903          	lw	s2,0(s1)
    800038b4:	02090063          	beqz	s2,800038d4 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800038b8:	8552                	mv	a0,s4
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	ca2080e7          	jalr	-862(ra) # 8000355c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800038c2:	854a                	mv	a0,s2
    800038c4:	70a2                	ld	ra,40(sp)
    800038c6:	7402                	ld	s0,32(sp)
    800038c8:	64e2                	ld	s1,24(sp)
    800038ca:	6942                	ld	s2,16(sp)
    800038cc:	69a2                	ld	s3,8(sp)
    800038ce:	6a02                	ld	s4,0(sp)
    800038d0:	6145                	addi	sp,sp,48
    800038d2:	8082                	ret
      addr = balloc(ip->dev);
    800038d4:	0009a503          	lw	a0,0(s3)
    800038d8:	00000097          	auipc	ra,0x0
    800038dc:	e14080e7          	jalr	-492(ra) # 800036ec <balloc>
    800038e0:	0005091b          	sext.w	s2,a0
      if(addr){
    800038e4:	fc090ae3          	beqz	s2,800038b8 <bmap+0x9a>
        a[bn] = addr;
    800038e8:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800038ec:	8552                	mv	a0,s4
    800038ee:	00001097          	auipc	ra,0x1
    800038f2:	ec6080e7          	jalr	-314(ra) # 800047b4 <log_write>
    800038f6:	b7c9                	j	800038b8 <bmap+0x9a>
  panic("bmap: out of range");
    800038f8:	00005517          	auipc	a0,0x5
    800038fc:	da050513          	addi	a0,a0,-608 # 80008698 <syscalls+0x140>
    80003900:	ffffd097          	auipc	ra,0xffffd
    80003904:	c3c080e7          	jalr	-964(ra) # 8000053c <panic>

0000000080003908 <iget>:
{
    80003908:	7179                	addi	sp,sp,-48
    8000390a:	f406                	sd	ra,40(sp)
    8000390c:	f022                	sd	s0,32(sp)
    8000390e:	ec26                	sd	s1,24(sp)
    80003910:	e84a                	sd	s2,16(sp)
    80003912:	e44e                	sd	s3,8(sp)
    80003914:	e052                	sd	s4,0(sp)
    80003916:	1800                	addi	s0,sp,48
    80003918:	89aa                	mv	s3,a0
    8000391a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000391c:	0023c517          	auipc	a0,0x23c
    80003920:	8ac50513          	addi	a0,a0,-1876 # 8023f1c8 <itable>
    80003924:	ffffd097          	auipc	ra,0xffffd
    80003928:	406080e7          	jalr	1030(ra) # 80000d2a <acquire>
  empty = 0;
    8000392c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000392e:	0023c497          	auipc	s1,0x23c
    80003932:	8b248493          	addi	s1,s1,-1870 # 8023f1e0 <itable+0x18>
    80003936:	0023d697          	auipc	a3,0x23d
    8000393a:	33a68693          	addi	a3,a3,826 # 80240c70 <log>
    8000393e:	a039                	j	8000394c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003940:	02090b63          	beqz	s2,80003976 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003944:	08848493          	addi	s1,s1,136
    80003948:	02d48a63          	beq	s1,a3,8000397c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000394c:	449c                	lw	a5,8(s1)
    8000394e:	fef059e3          	blez	a5,80003940 <iget+0x38>
    80003952:	4098                	lw	a4,0(s1)
    80003954:	ff3716e3          	bne	a4,s3,80003940 <iget+0x38>
    80003958:	40d8                	lw	a4,4(s1)
    8000395a:	ff4713e3          	bne	a4,s4,80003940 <iget+0x38>
      ip->ref++;
    8000395e:	2785                	addiw	a5,a5,1
    80003960:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003962:	0023c517          	auipc	a0,0x23c
    80003966:	86650513          	addi	a0,a0,-1946 # 8023f1c8 <itable>
    8000396a:	ffffd097          	auipc	ra,0xffffd
    8000396e:	474080e7          	jalr	1140(ra) # 80000dde <release>
      return ip;
    80003972:	8926                	mv	s2,s1
    80003974:	a03d                	j	800039a2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003976:	f7f9                	bnez	a5,80003944 <iget+0x3c>
    80003978:	8926                	mv	s2,s1
    8000397a:	b7e9                	j	80003944 <iget+0x3c>
  if(empty == 0)
    8000397c:	02090c63          	beqz	s2,800039b4 <iget+0xac>
  ip->dev = dev;
    80003980:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003984:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003988:	4785                	li	a5,1
    8000398a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000398e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003992:	0023c517          	auipc	a0,0x23c
    80003996:	83650513          	addi	a0,a0,-1994 # 8023f1c8 <itable>
    8000399a:	ffffd097          	auipc	ra,0xffffd
    8000399e:	444080e7          	jalr	1092(ra) # 80000dde <release>
}
    800039a2:	854a                	mv	a0,s2
    800039a4:	70a2                	ld	ra,40(sp)
    800039a6:	7402                	ld	s0,32(sp)
    800039a8:	64e2                	ld	s1,24(sp)
    800039aa:	6942                	ld	s2,16(sp)
    800039ac:	69a2                	ld	s3,8(sp)
    800039ae:	6a02                	ld	s4,0(sp)
    800039b0:	6145                	addi	sp,sp,48
    800039b2:	8082                	ret
    panic("iget: no inodes");
    800039b4:	00005517          	auipc	a0,0x5
    800039b8:	cfc50513          	addi	a0,a0,-772 # 800086b0 <syscalls+0x158>
    800039bc:	ffffd097          	auipc	ra,0xffffd
    800039c0:	b80080e7          	jalr	-1152(ra) # 8000053c <panic>

00000000800039c4 <fsinit>:
fsinit(int dev) {
    800039c4:	7179                	addi	sp,sp,-48
    800039c6:	f406                	sd	ra,40(sp)
    800039c8:	f022                	sd	s0,32(sp)
    800039ca:	ec26                	sd	s1,24(sp)
    800039cc:	e84a                	sd	s2,16(sp)
    800039ce:	e44e                	sd	s3,8(sp)
    800039d0:	1800                	addi	s0,sp,48
    800039d2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039d4:	4585                	li	a1,1
    800039d6:	00000097          	auipc	ra,0x0
    800039da:	a56080e7          	jalr	-1450(ra) # 8000342c <bread>
    800039de:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800039e0:	0023b997          	auipc	s3,0x23b
    800039e4:	7c898993          	addi	s3,s3,1992 # 8023f1a8 <sb>
    800039e8:	02000613          	li	a2,32
    800039ec:	05850593          	addi	a1,a0,88
    800039f0:	854e                	mv	a0,s3
    800039f2:	ffffd097          	auipc	ra,0xffffd
    800039f6:	490080e7          	jalr	1168(ra) # 80000e82 <memmove>
  brelse(bp);
    800039fa:	8526                	mv	a0,s1
    800039fc:	00000097          	auipc	ra,0x0
    80003a00:	b60080e7          	jalr	-1184(ra) # 8000355c <brelse>
  if(sb.magic != FSMAGIC)
    80003a04:	0009a703          	lw	a4,0(s3)
    80003a08:	102037b7          	lui	a5,0x10203
    80003a0c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a10:	02f71263          	bne	a4,a5,80003a34 <fsinit+0x70>
  initlog(dev, &sb);
    80003a14:	0023b597          	auipc	a1,0x23b
    80003a18:	79458593          	addi	a1,a1,1940 # 8023f1a8 <sb>
    80003a1c:	854a                	mv	a0,s2
    80003a1e:	00001097          	auipc	ra,0x1
    80003a22:	b2c080e7          	jalr	-1236(ra) # 8000454a <initlog>
}
    80003a26:	70a2                	ld	ra,40(sp)
    80003a28:	7402                	ld	s0,32(sp)
    80003a2a:	64e2                	ld	s1,24(sp)
    80003a2c:	6942                	ld	s2,16(sp)
    80003a2e:	69a2                	ld	s3,8(sp)
    80003a30:	6145                	addi	sp,sp,48
    80003a32:	8082                	ret
    panic("invalid file system");
    80003a34:	00005517          	auipc	a0,0x5
    80003a38:	c8c50513          	addi	a0,a0,-884 # 800086c0 <syscalls+0x168>
    80003a3c:	ffffd097          	auipc	ra,0xffffd
    80003a40:	b00080e7          	jalr	-1280(ra) # 8000053c <panic>

0000000080003a44 <iinit>:
{
    80003a44:	7179                	addi	sp,sp,-48
    80003a46:	f406                	sd	ra,40(sp)
    80003a48:	f022                	sd	s0,32(sp)
    80003a4a:	ec26                	sd	s1,24(sp)
    80003a4c:	e84a                	sd	s2,16(sp)
    80003a4e:	e44e                	sd	s3,8(sp)
    80003a50:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a52:	00005597          	auipc	a1,0x5
    80003a56:	c8658593          	addi	a1,a1,-890 # 800086d8 <syscalls+0x180>
    80003a5a:	0023b517          	auipc	a0,0x23b
    80003a5e:	76e50513          	addi	a0,a0,1902 # 8023f1c8 <itable>
    80003a62:	ffffd097          	auipc	ra,0xffffd
    80003a66:	238080e7          	jalr	568(ra) # 80000c9a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a6a:	0023b497          	auipc	s1,0x23b
    80003a6e:	78648493          	addi	s1,s1,1926 # 8023f1f0 <itable+0x28>
    80003a72:	0023d997          	auipc	s3,0x23d
    80003a76:	20e98993          	addi	s3,s3,526 # 80240c80 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a7a:	00005917          	auipc	s2,0x5
    80003a7e:	c6690913          	addi	s2,s2,-922 # 800086e0 <syscalls+0x188>
    80003a82:	85ca                	mv	a1,s2
    80003a84:	8526                	mv	a0,s1
    80003a86:	00001097          	auipc	ra,0x1
    80003a8a:	e12080e7          	jalr	-494(ra) # 80004898 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a8e:	08848493          	addi	s1,s1,136
    80003a92:	ff3498e3          	bne	s1,s3,80003a82 <iinit+0x3e>
}
    80003a96:	70a2                	ld	ra,40(sp)
    80003a98:	7402                	ld	s0,32(sp)
    80003a9a:	64e2                	ld	s1,24(sp)
    80003a9c:	6942                	ld	s2,16(sp)
    80003a9e:	69a2                	ld	s3,8(sp)
    80003aa0:	6145                	addi	sp,sp,48
    80003aa2:	8082                	ret

0000000080003aa4 <ialloc>:
{
    80003aa4:	7139                	addi	sp,sp,-64
    80003aa6:	fc06                	sd	ra,56(sp)
    80003aa8:	f822                	sd	s0,48(sp)
    80003aaa:	f426                	sd	s1,40(sp)
    80003aac:	f04a                	sd	s2,32(sp)
    80003aae:	ec4e                	sd	s3,24(sp)
    80003ab0:	e852                	sd	s4,16(sp)
    80003ab2:	e456                	sd	s5,8(sp)
    80003ab4:	e05a                	sd	s6,0(sp)
    80003ab6:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ab8:	0023b717          	auipc	a4,0x23b
    80003abc:	6fc72703          	lw	a4,1788(a4) # 8023f1b4 <sb+0xc>
    80003ac0:	4785                	li	a5,1
    80003ac2:	04e7f863          	bgeu	a5,a4,80003b12 <ialloc+0x6e>
    80003ac6:	8aaa                	mv	s5,a0
    80003ac8:	8b2e                	mv	s6,a1
    80003aca:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003acc:	0023ba17          	auipc	s4,0x23b
    80003ad0:	6dca0a13          	addi	s4,s4,1756 # 8023f1a8 <sb>
    80003ad4:	00495593          	srli	a1,s2,0x4
    80003ad8:	018a2783          	lw	a5,24(s4)
    80003adc:	9dbd                	addw	a1,a1,a5
    80003ade:	8556                	mv	a0,s5
    80003ae0:	00000097          	auipc	ra,0x0
    80003ae4:	94c080e7          	jalr	-1716(ra) # 8000342c <bread>
    80003ae8:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003aea:	05850993          	addi	s3,a0,88
    80003aee:	00f97793          	andi	a5,s2,15
    80003af2:	079a                	slli	a5,a5,0x6
    80003af4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003af6:	00099783          	lh	a5,0(s3)
    80003afa:	cf9d                	beqz	a5,80003b38 <ialloc+0x94>
    brelse(bp);
    80003afc:	00000097          	auipc	ra,0x0
    80003b00:	a60080e7          	jalr	-1440(ra) # 8000355c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b04:	0905                	addi	s2,s2,1
    80003b06:	00ca2703          	lw	a4,12(s4)
    80003b0a:	0009079b          	sext.w	a5,s2
    80003b0e:	fce7e3e3          	bltu	a5,a4,80003ad4 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003b12:	00005517          	auipc	a0,0x5
    80003b16:	bd650513          	addi	a0,a0,-1066 # 800086e8 <syscalls+0x190>
    80003b1a:	ffffd097          	auipc	ra,0xffffd
    80003b1e:	a7e080e7          	jalr	-1410(ra) # 80000598 <printf>
  return 0;
    80003b22:	4501                	li	a0,0
}
    80003b24:	70e2                	ld	ra,56(sp)
    80003b26:	7442                	ld	s0,48(sp)
    80003b28:	74a2                	ld	s1,40(sp)
    80003b2a:	7902                	ld	s2,32(sp)
    80003b2c:	69e2                	ld	s3,24(sp)
    80003b2e:	6a42                	ld	s4,16(sp)
    80003b30:	6aa2                	ld	s5,8(sp)
    80003b32:	6b02                	ld	s6,0(sp)
    80003b34:	6121                	addi	sp,sp,64
    80003b36:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003b38:	04000613          	li	a2,64
    80003b3c:	4581                	li	a1,0
    80003b3e:	854e                	mv	a0,s3
    80003b40:	ffffd097          	auipc	ra,0xffffd
    80003b44:	2e6080e7          	jalr	742(ra) # 80000e26 <memset>
      dip->type = type;
    80003b48:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b4c:	8526                	mv	a0,s1
    80003b4e:	00001097          	auipc	ra,0x1
    80003b52:	c66080e7          	jalr	-922(ra) # 800047b4 <log_write>
      brelse(bp);
    80003b56:	8526                	mv	a0,s1
    80003b58:	00000097          	auipc	ra,0x0
    80003b5c:	a04080e7          	jalr	-1532(ra) # 8000355c <brelse>
      return iget(dev, inum);
    80003b60:	0009059b          	sext.w	a1,s2
    80003b64:	8556                	mv	a0,s5
    80003b66:	00000097          	auipc	ra,0x0
    80003b6a:	da2080e7          	jalr	-606(ra) # 80003908 <iget>
    80003b6e:	bf5d                	j	80003b24 <ialloc+0x80>

0000000080003b70 <iupdate>:
{
    80003b70:	1101                	addi	sp,sp,-32
    80003b72:	ec06                	sd	ra,24(sp)
    80003b74:	e822                	sd	s0,16(sp)
    80003b76:	e426                	sd	s1,8(sp)
    80003b78:	e04a                	sd	s2,0(sp)
    80003b7a:	1000                	addi	s0,sp,32
    80003b7c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b7e:	415c                	lw	a5,4(a0)
    80003b80:	0047d79b          	srliw	a5,a5,0x4
    80003b84:	0023b597          	auipc	a1,0x23b
    80003b88:	63c5a583          	lw	a1,1596(a1) # 8023f1c0 <sb+0x18>
    80003b8c:	9dbd                	addw	a1,a1,a5
    80003b8e:	4108                	lw	a0,0(a0)
    80003b90:	00000097          	auipc	ra,0x0
    80003b94:	89c080e7          	jalr	-1892(ra) # 8000342c <bread>
    80003b98:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b9a:	05850793          	addi	a5,a0,88
    80003b9e:	40d8                	lw	a4,4(s1)
    80003ba0:	8b3d                	andi	a4,a4,15
    80003ba2:	071a                	slli	a4,a4,0x6
    80003ba4:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003ba6:	04449703          	lh	a4,68(s1)
    80003baa:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003bae:	04649703          	lh	a4,70(s1)
    80003bb2:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003bb6:	04849703          	lh	a4,72(s1)
    80003bba:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003bbe:	04a49703          	lh	a4,74(s1)
    80003bc2:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003bc6:	44f8                	lw	a4,76(s1)
    80003bc8:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003bca:	03400613          	li	a2,52
    80003bce:	05048593          	addi	a1,s1,80
    80003bd2:	00c78513          	addi	a0,a5,12
    80003bd6:	ffffd097          	auipc	ra,0xffffd
    80003bda:	2ac080e7          	jalr	684(ra) # 80000e82 <memmove>
  log_write(bp);
    80003bde:	854a                	mv	a0,s2
    80003be0:	00001097          	auipc	ra,0x1
    80003be4:	bd4080e7          	jalr	-1068(ra) # 800047b4 <log_write>
  brelse(bp);
    80003be8:	854a                	mv	a0,s2
    80003bea:	00000097          	auipc	ra,0x0
    80003bee:	972080e7          	jalr	-1678(ra) # 8000355c <brelse>
}
    80003bf2:	60e2                	ld	ra,24(sp)
    80003bf4:	6442                	ld	s0,16(sp)
    80003bf6:	64a2                	ld	s1,8(sp)
    80003bf8:	6902                	ld	s2,0(sp)
    80003bfa:	6105                	addi	sp,sp,32
    80003bfc:	8082                	ret

0000000080003bfe <idup>:
{
    80003bfe:	1101                	addi	sp,sp,-32
    80003c00:	ec06                	sd	ra,24(sp)
    80003c02:	e822                	sd	s0,16(sp)
    80003c04:	e426                	sd	s1,8(sp)
    80003c06:	1000                	addi	s0,sp,32
    80003c08:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c0a:	0023b517          	auipc	a0,0x23b
    80003c0e:	5be50513          	addi	a0,a0,1470 # 8023f1c8 <itable>
    80003c12:	ffffd097          	auipc	ra,0xffffd
    80003c16:	118080e7          	jalr	280(ra) # 80000d2a <acquire>
  ip->ref++;
    80003c1a:	449c                	lw	a5,8(s1)
    80003c1c:	2785                	addiw	a5,a5,1
    80003c1e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c20:	0023b517          	auipc	a0,0x23b
    80003c24:	5a850513          	addi	a0,a0,1448 # 8023f1c8 <itable>
    80003c28:	ffffd097          	auipc	ra,0xffffd
    80003c2c:	1b6080e7          	jalr	438(ra) # 80000dde <release>
}
    80003c30:	8526                	mv	a0,s1
    80003c32:	60e2                	ld	ra,24(sp)
    80003c34:	6442                	ld	s0,16(sp)
    80003c36:	64a2                	ld	s1,8(sp)
    80003c38:	6105                	addi	sp,sp,32
    80003c3a:	8082                	ret

0000000080003c3c <ilock>:
{
    80003c3c:	1101                	addi	sp,sp,-32
    80003c3e:	ec06                	sd	ra,24(sp)
    80003c40:	e822                	sd	s0,16(sp)
    80003c42:	e426                	sd	s1,8(sp)
    80003c44:	e04a                	sd	s2,0(sp)
    80003c46:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c48:	c115                	beqz	a0,80003c6c <ilock+0x30>
    80003c4a:	84aa                	mv	s1,a0
    80003c4c:	451c                	lw	a5,8(a0)
    80003c4e:	00f05f63          	blez	a5,80003c6c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c52:	0541                	addi	a0,a0,16
    80003c54:	00001097          	auipc	ra,0x1
    80003c58:	c7e080e7          	jalr	-898(ra) # 800048d2 <acquiresleep>
  if(ip->valid == 0){
    80003c5c:	40bc                	lw	a5,64(s1)
    80003c5e:	cf99                	beqz	a5,80003c7c <ilock+0x40>
}
    80003c60:	60e2                	ld	ra,24(sp)
    80003c62:	6442                	ld	s0,16(sp)
    80003c64:	64a2                	ld	s1,8(sp)
    80003c66:	6902                	ld	s2,0(sp)
    80003c68:	6105                	addi	sp,sp,32
    80003c6a:	8082                	ret
    panic("ilock");
    80003c6c:	00005517          	auipc	a0,0x5
    80003c70:	a9450513          	addi	a0,a0,-1388 # 80008700 <syscalls+0x1a8>
    80003c74:	ffffd097          	auipc	ra,0xffffd
    80003c78:	8c8080e7          	jalr	-1848(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c7c:	40dc                	lw	a5,4(s1)
    80003c7e:	0047d79b          	srliw	a5,a5,0x4
    80003c82:	0023b597          	auipc	a1,0x23b
    80003c86:	53e5a583          	lw	a1,1342(a1) # 8023f1c0 <sb+0x18>
    80003c8a:	9dbd                	addw	a1,a1,a5
    80003c8c:	4088                	lw	a0,0(s1)
    80003c8e:	fffff097          	auipc	ra,0xfffff
    80003c92:	79e080e7          	jalr	1950(ra) # 8000342c <bread>
    80003c96:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c98:	05850593          	addi	a1,a0,88
    80003c9c:	40dc                	lw	a5,4(s1)
    80003c9e:	8bbd                	andi	a5,a5,15
    80003ca0:	079a                	slli	a5,a5,0x6
    80003ca2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ca4:	00059783          	lh	a5,0(a1)
    80003ca8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003cac:	00259783          	lh	a5,2(a1)
    80003cb0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003cb4:	00459783          	lh	a5,4(a1)
    80003cb8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003cbc:	00659783          	lh	a5,6(a1)
    80003cc0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003cc4:	459c                	lw	a5,8(a1)
    80003cc6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003cc8:	03400613          	li	a2,52
    80003ccc:	05b1                	addi	a1,a1,12
    80003cce:	05048513          	addi	a0,s1,80
    80003cd2:	ffffd097          	auipc	ra,0xffffd
    80003cd6:	1b0080e7          	jalr	432(ra) # 80000e82 <memmove>
    brelse(bp);
    80003cda:	854a                	mv	a0,s2
    80003cdc:	00000097          	auipc	ra,0x0
    80003ce0:	880080e7          	jalr	-1920(ra) # 8000355c <brelse>
    ip->valid = 1;
    80003ce4:	4785                	li	a5,1
    80003ce6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ce8:	04449783          	lh	a5,68(s1)
    80003cec:	fbb5                	bnez	a5,80003c60 <ilock+0x24>
      panic("ilock: no type");
    80003cee:	00005517          	auipc	a0,0x5
    80003cf2:	a1a50513          	addi	a0,a0,-1510 # 80008708 <syscalls+0x1b0>
    80003cf6:	ffffd097          	auipc	ra,0xffffd
    80003cfa:	846080e7          	jalr	-1978(ra) # 8000053c <panic>

0000000080003cfe <iunlock>:
{
    80003cfe:	1101                	addi	sp,sp,-32
    80003d00:	ec06                	sd	ra,24(sp)
    80003d02:	e822                	sd	s0,16(sp)
    80003d04:	e426                	sd	s1,8(sp)
    80003d06:	e04a                	sd	s2,0(sp)
    80003d08:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d0a:	c905                	beqz	a0,80003d3a <iunlock+0x3c>
    80003d0c:	84aa                	mv	s1,a0
    80003d0e:	01050913          	addi	s2,a0,16
    80003d12:	854a                	mv	a0,s2
    80003d14:	00001097          	auipc	ra,0x1
    80003d18:	c58080e7          	jalr	-936(ra) # 8000496c <holdingsleep>
    80003d1c:	cd19                	beqz	a0,80003d3a <iunlock+0x3c>
    80003d1e:	449c                	lw	a5,8(s1)
    80003d20:	00f05d63          	blez	a5,80003d3a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d24:	854a                	mv	a0,s2
    80003d26:	00001097          	auipc	ra,0x1
    80003d2a:	c02080e7          	jalr	-1022(ra) # 80004928 <releasesleep>
}
    80003d2e:	60e2                	ld	ra,24(sp)
    80003d30:	6442                	ld	s0,16(sp)
    80003d32:	64a2                	ld	s1,8(sp)
    80003d34:	6902                	ld	s2,0(sp)
    80003d36:	6105                	addi	sp,sp,32
    80003d38:	8082                	ret
    panic("iunlock");
    80003d3a:	00005517          	auipc	a0,0x5
    80003d3e:	9de50513          	addi	a0,a0,-1570 # 80008718 <syscalls+0x1c0>
    80003d42:	ffffc097          	auipc	ra,0xffffc
    80003d46:	7fa080e7          	jalr	2042(ra) # 8000053c <panic>

0000000080003d4a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d4a:	7179                	addi	sp,sp,-48
    80003d4c:	f406                	sd	ra,40(sp)
    80003d4e:	f022                	sd	s0,32(sp)
    80003d50:	ec26                	sd	s1,24(sp)
    80003d52:	e84a                	sd	s2,16(sp)
    80003d54:	e44e                	sd	s3,8(sp)
    80003d56:	e052                	sd	s4,0(sp)
    80003d58:	1800                	addi	s0,sp,48
    80003d5a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d5c:	05050493          	addi	s1,a0,80
    80003d60:	08050913          	addi	s2,a0,128
    80003d64:	a021                	j	80003d6c <itrunc+0x22>
    80003d66:	0491                	addi	s1,s1,4
    80003d68:	01248d63          	beq	s1,s2,80003d82 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d6c:	408c                	lw	a1,0(s1)
    80003d6e:	dde5                	beqz	a1,80003d66 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d70:	0009a503          	lw	a0,0(s3)
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	8fc080e7          	jalr	-1796(ra) # 80003670 <bfree>
      ip->addrs[i] = 0;
    80003d7c:	0004a023          	sw	zero,0(s1)
    80003d80:	b7dd                	j	80003d66 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d82:	0809a583          	lw	a1,128(s3)
    80003d86:	e185                	bnez	a1,80003da6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d88:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d8c:	854e                	mv	a0,s3
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	de2080e7          	jalr	-542(ra) # 80003b70 <iupdate>
}
    80003d96:	70a2                	ld	ra,40(sp)
    80003d98:	7402                	ld	s0,32(sp)
    80003d9a:	64e2                	ld	s1,24(sp)
    80003d9c:	6942                	ld	s2,16(sp)
    80003d9e:	69a2                	ld	s3,8(sp)
    80003da0:	6a02                	ld	s4,0(sp)
    80003da2:	6145                	addi	sp,sp,48
    80003da4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003da6:	0009a503          	lw	a0,0(s3)
    80003daa:	fffff097          	auipc	ra,0xfffff
    80003dae:	682080e7          	jalr	1666(ra) # 8000342c <bread>
    80003db2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003db4:	05850493          	addi	s1,a0,88
    80003db8:	45850913          	addi	s2,a0,1112
    80003dbc:	a021                	j	80003dc4 <itrunc+0x7a>
    80003dbe:	0491                	addi	s1,s1,4
    80003dc0:	01248b63          	beq	s1,s2,80003dd6 <itrunc+0x8c>
      if(a[j])
    80003dc4:	408c                	lw	a1,0(s1)
    80003dc6:	dde5                	beqz	a1,80003dbe <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003dc8:	0009a503          	lw	a0,0(s3)
    80003dcc:	00000097          	auipc	ra,0x0
    80003dd0:	8a4080e7          	jalr	-1884(ra) # 80003670 <bfree>
    80003dd4:	b7ed                	j	80003dbe <itrunc+0x74>
    brelse(bp);
    80003dd6:	8552                	mv	a0,s4
    80003dd8:	fffff097          	auipc	ra,0xfffff
    80003ddc:	784080e7          	jalr	1924(ra) # 8000355c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003de0:	0809a583          	lw	a1,128(s3)
    80003de4:	0009a503          	lw	a0,0(s3)
    80003de8:	00000097          	auipc	ra,0x0
    80003dec:	888080e7          	jalr	-1912(ra) # 80003670 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003df0:	0809a023          	sw	zero,128(s3)
    80003df4:	bf51                	j	80003d88 <itrunc+0x3e>

0000000080003df6 <iput>:
{
    80003df6:	1101                	addi	sp,sp,-32
    80003df8:	ec06                	sd	ra,24(sp)
    80003dfa:	e822                	sd	s0,16(sp)
    80003dfc:	e426                	sd	s1,8(sp)
    80003dfe:	e04a                	sd	s2,0(sp)
    80003e00:	1000                	addi	s0,sp,32
    80003e02:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e04:	0023b517          	auipc	a0,0x23b
    80003e08:	3c450513          	addi	a0,a0,964 # 8023f1c8 <itable>
    80003e0c:	ffffd097          	auipc	ra,0xffffd
    80003e10:	f1e080e7          	jalr	-226(ra) # 80000d2a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e14:	4498                	lw	a4,8(s1)
    80003e16:	4785                	li	a5,1
    80003e18:	02f70363          	beq	a4,a5,80003e3e <iput+0x48>
  ip->ref--;
    80003e1c:	449c                	lw	a5,8(s1)
    80003e1e:	37fd                	addiw	a5,a5,-1
    80003e20:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e22:	0023b517          	auipc	a0,0x23b
    80003e26:	3a650513          	addi	a0,a0,934 # 8023f1c8 <itable>
    80003e2a:	ffffd097          	auipc	ra,0xffffd
    80003e2e:	fb4080e7          	jalr	-76(ra) # 80000dde <release>
}
    80003e32:	60e2                	ld	ra,24(sp)
    80003e34:	6442                	ld	s0,16(sp)
    80003e36:	64a2                	ld	s1,8(sp)
    80003e38:	6902                	ld	s2,0(sp)
    80003e3a:	6105                	addi	sp,sp,32
    80003e3c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e3e:	40bc                	lw	a5,64(s1)
    80003e40:	dff1                	beqz	a5,80003e1c <iput+0x26>
    80003e42:	04a49783          	lh	a5,74(s1)
    80003e46:	fbf9                	bnez	a5,80003e1c <iput+0x26>
    acquiresleep(&ip->lock);
    80003e48:	01048913          	addi	s2,s1,16
    80003e4c:	854a                	mv	a0,s2
    80003e4e:	00001097          	auipc	ra,0x1
    80003e52:	a84080e7          	jalr	-1404(ra) # 800048d2 <acquiresleep>
    release(&itable.lock);
    80003e56:	0023b517          	auipc	a0,0x23b
    80003e5a:	37250513          	addi	a0,a0,882 # 8023f1c8 <itable>
    80003e5e:	ffffd097          	auipc	ra,0xffffd
    80003e62:	f80080e7          	jalr	-128(ra) # 80000dde <release>
    itrunc(ip);
    80003e66:	8526                	mv	a0,s1
    80003e68:	00000097          	auipc	ra,0x0
    80003e6c:	ee2080e7          	jalr	-286(ra) # 80003d4a <itrunc>
    ip->type = 0;
    80003e70:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e74:	8526                	mv	a0,s1
    80003e76:	00000097          	auipc	ra,0x0
    80003e7a:	cfa080e7          	jalr	-774(ra) # 80003b70 <iupdate>
    ip->valid = 0;
    80003e7e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e82:	854a                	mv	a0,s2
    80003e84:	00001097          	auipc	ra,0x1
    80003e88:	aa4080e7          	jalr	-1372(ra) # 80004928 <releasesleep>
    acquire(&itable.lock);
    80003e8c:	0023b517          	auipc	a0,0x23b
    80003e90:	33c50513          	addi	a0,a0,828 # 8023f1c8 <itable>
    80003e94:	ffffd097          	auipc	ra,0xffffd
    80003e98:	e96080e7          	jalr	-362(ra) # 80000d2a <acquire>
    80003e9c:	b741                	j	80003e1c <iput+0x26>

0000000080003e9e <iunlockput>:
{
    80003e9e:	1101                	addi	sp,sp,-32
    80003ea0:	ec06                	sd	ra,24(sp)
    80003ea2:	e822                	sd	s0,16(sp)
    80003ea4:	e426                	sd	s1,8(sp)
    80003ea6:	1000                	addi	s0,sp,32
    80003ea8:	84aa                	mv	s1,a0
  iunlock(ip);
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	e54080e7          	jalr	-428(ra) # 80003cfe <iunlock>
  iput(ip);
    80003eb2:	8526                	mv	a0,s1
    80003eb4:	00000097          	auipc	ra,0x0
    80003eb8:	f42080e7          	jalr	-190(ra) # 80003df6 <iput>
}
    80003ebc:	60e2                	ld	ra,24(sp)
    80003ebe:	6442                	ld	s0,16(sp)
    80003ec0:	64a2                	ld	s1,8(sp)
    80003ec2:	6105                	addi	sp,sp,32
    80003ec4:	8082                	ret

0000000080003ec6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ec6:	1141                	addi	sp,sp,-16
    80003ec8:	e422                	sd	s0,8(sp)
    80003eca:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ecc:	411c                	lw	a5,0(a0)
    80003ece:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ed0:	415c                	lw	a5,4(a0)
    80003ed2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ed4:	04451783          	lh	a5,68(a0)
    80003ed8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003edc:	04a51783          	lh	a5,74(a0)
    80003ee0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ee4:	04c56783          	lwu	a5,76(a0)
    80003ee8:	e99c                	sd	a5,16(a1)
}
    80003eea:	6422                	ld	s0,8(sp)
    80003eec:	0141                	addi	sp,sp,16
    80003eee:	8082                	ret

0000000080003ef0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ef0:	457c                	lw	a5,76(a0)
    80003ef2:	0ed7e963          	bltu	a5,a3,80003fe4 <readi+0xf4>
{
    80003ef6:	7159                	addi	sp,sp,-112
    80003ef8:	f486                	sd	ra,104(sp)
    80003efa:	f0a2                	sd	s0,96(sp)
    80003efc:	eca6                	sd	s1,88(sp)
    80003efe:	e8ca                	sd	s2,80(sp)
    80003f00:	e4ce                	sd	s3,72(sp)
    80003f02:	e0d2                	sd	s4,64(sp)
    80003f04:	fc56                	sd	s5,56(sp)
    80003f06:	f85a                	sd	s6,48(sp)
    80003f08:	f45e                	sd	s7,40(sp)
    80003f0a:	f062                	sd	s8,32(sp)
    80003f0c:	ec66                	sd	s9,24(sp)
    80003f0e:	e86a                	sd	s10,16(sp)
    80003f10:	e46e                	sd	s11,8(sp)
    80003f12:	1880                	addi	s0,sp,112
    80003f14:	8b2a                	mv	s6,a0
    80003f16:	8bae                	mv	s7,a1
    80003f18:	8a32                	mv	s4,a2
    80003f1a:	84b6                	mv	s1,a3
    80003f1c:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003f1e:	9f35                	addw	a4,a4,a3
    return 0;
    80003f20:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f22:	0ad76063          	bltu	a4,a3,80003fc2 <readi+0xd2>
  if(off + n > ip->size)
    80003f26:	00e7f463          	bgeu	a5,a4,80003f2e <readi+0x3e>
    n = ip->size - off;
    80003f2a:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f2e:	0a0a8963          	beqz	s5,80003fe0 <readi+0xf0>
    80003f32:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f34:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f38:	5c7d                	li	s8,-1
    80003f3a:	a82d                	j	80003f74 <readi+0x84>
    80003f3c:	020d1d93          	slli	s11,s10,0x20
    80003f40:	020ddd93          	srli	s11,s11,0x20
    80003f44:	05890613          	addi	a2,s2,88
    80003f48:	86ee                	mv	a3,s11
    80003f4a:	963a                	add	a2,a2,a4
    80003f4c:	85d2                	mv	a1,s4
    80003f4e:	855e                	mv	a0,s7
    80003f50:	fffff097          	auipc	ra,0xfffff
    80003f54:	87c080e7          	jalr	-1924(ra) # 800027cc <either_copyout>
    80003f58:	05850d63          	beq	a0,s8,80003fb2 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f5c:	854a                	mv	a0,s2
    80003f5e:	fffff097          	auipc	ra,0xfffff
    80003f62:	5fe080e7          	jalr	1534(ra) # 8000355c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f66:	013d09bb          	addw	s3,s10,s3
    80003f6a:	009d04bb          	addw	s1,s10,s1
    80003f6e:	9a6e                	add	s4,s4,s11
    80003f70:	0559f763          	bgeu	s3,s5,80003fbe <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003f74:	00a4d59b          	srliw	a1,s1,0xa
    80003f78:	855a                	mv	a0,s6
    80003f7a:	00000097          	auipc	ra,0x0
    80003f7e:	8a4080e7          	jalr	-1884(ra) # 8000381e <bmap>
    80003f82:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f86:	cd85                	beqz	a1,80003fbe <readi+0xce>
    bp = bread(ip->dev, addr);
    80003f88:	000b2503          	lw	a0,0(s6)
    80003f8c:	fffff097          	auipc	ra,0xfffff
    80003f90:	4a0080e7          	jalr	1184(ra) # 8000342c <bread>
    80003f94:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f96:	3ff4f713          	andi	a4,s1,1023
    80003f9a:	40ec87bb          	subw	a5,s9,a4
    80003f9e:	413a86bb          	subw	a3,s5,s3
    80003fa2:	8d3e                	mv	s10,a5
    80003fa4:	2781                	sext.w	a5,a5
    80003fa6:	0006861b          	sext.w	a2,a3
    80003faa:	f8f679e3          	bgeu	a2,a5,80003f3c <readi+0x4c>
    80003fae:	8d36                	mv	s10,a3
    80003fb0:	b771                	j	80003f3c <readi+0x4c>
      brelse(bp);
    80003fb2:	854a                	mv	a0,s2
    80003fb4:	fffff097          	auipc	ra,0xfffff
    80003fb8:	5a8080e7          	jalr	1448(ra) # 8000355c <brelse>
      tot = -1;
    80003fbc:	59fd                	li	s3,-1
  }
  return tot;
    80003fbe:	0009851b          	sext.w	a0,s3
}
    80003fc2:	70a6                	ld	ra,104(sp)
    80003fc4:	7406                	ld	s0,96(sp)
    80003fc6:	64e6                	ld	s1,88(sp)
    80003fc8:	6946                	ld	s2,80(sp)
    80003fca:	69a6                	ld	s3,72(sp)
    80003fcc:	6a06                	ld	s4,64(sp)
    80003fce:	7ae2                	ld	s5,56(sp)
    80003fd0:	7b42                	ld	s6,48(sp)
    80003fd2:	7ba2                	ld	s7,40(sp)
    80003fd4:	7c02                	ld	s8,32(sp)
    80003fd6:	6ce2                	ld	s9,24(sp)
    80003fd8:	6d42                	ld	s10,16(sp)
    80003fda:	6da2                	ld	s11,8(sp)
    80003fdc:	6165                	addi	sp,sp,112
    80003fde:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fe0:	89d6                	mv	s3,s5
    80003fe2:	bff1                	j	80003fbe <readi+0xce>
    return 0;
    80003fe4:	4501                	li	a0,0
}
    80003fe6:	8082                	ret

0000000080003fe8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fe8:	457c                	lw	a5,76(a0)
    80003fea:	10d7e863          	bltu	a5,a3,800040fa <writei+0x112>
{
    80003fee:	7159                	addi	sp,sp,-112
    80003ff0:	f486                	sd	ra,104(sp)
    80003ff2:	f0a2                	sd	s0,96(sp)
    80003ff4:	eca6                	sd	s1,88(sp)
    80003ff6:	e8ca                	sd	s2,80(sp)
    80003ff8:	e4ce                	sd	s3,72(sp)
    80003ffa:	e0d2                	sd	s4,64(sp)
    80003ffc:	fc56                	sd	s5,56(sp)
    80003ffe:	f85a                	sd	s6,48(sp)
    80004000:	f45e                	sd	s7,40(sp)
    80004002:	f062                	sd	s8,32(sp)
    80004004:	ec66                	sd	s9,24(sp)
    80004006:	e86a                	sd	s10,16(sp)
    80004008:	e46e                	sd	s11,8(sp)
    8000400a:	1880                	addi	s0,sp,112
    8000400c:	8aaa                	mv	s5,a0
    8000400e:	8bae                	mv	s7,a1
    80004010:	8a32                	mv	s4,a2
    80004012:	8936                	mv	s2,a3
    80004014:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004016:	00e687bb          	addw	a5,a3,a4
    8000401a:	0ed7e263          	bltu	a5,a3,800040fe <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000401e:	00043737          	lui	a4,0x43
    80004022:	0ef76063          	bltu	a4,a5,80004102 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004026:	0c0b0863          	beqz	s6,800040f6 <writei+0x10e>
    8000402a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000402c:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004030:	5c7d                	li	s8,-1
    80004032:	a091                	j	80004076 <writei+0x8e>
    80004034:	020d1d93          	slli	s11,s10,0x20
    80004038:	020ddd93          	srli	s11,s11,0x20
    8000403c:	05848513          	addi	a0,s1,88
    80004040:	86ee                	mv	a3,s11
    80004042:	8652                	mv	a2,s4
    80004044:	85de                	mv	a1,s7
    80004046:	953a                	add	a0,a0,a4
    80004048:	ffffe097          	auipc	ra,0xffffe
    8000404c:	7da080e7          	jalr	2010(ra) # 80002822 <either_copyin>
    80004050:	07850263          	beq	a0,s8,800040b4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004054:	8526                	mv	a0,s1
    80004056:	00000097          	auipc	ra,0x0
    8000405a:	75e080e7          	jalr	1886(ra) # 800047b4 <log_write>
    brelse(bp);
    8000405e:	8526                	mv	a0,s1
    80004060:	fffff097          	auipc	ra,0xfffff
    80004064:	4fc080e7          	jalr	1276(ra) # 8000355c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004068:	013d09bb          	addw	s3,s10,s3
    8000406c:	012d093b          	addw	s2,s10,s2
    80004070:	9a6e                	add	s4,s4,s11
    80004072:	0569f663          	bgeu	s3,s6,800040be <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004076:	00a9559b          	srliw	a1,s2,0xa
    8000407a:	8556                	mv	a0,s5
    8000407c:	fffff097          	auipc	ra,0xfffff
    80004080:	7a2080e7          	jalr	1954(ra) # 8000381e <bmap>
    80004084:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004088:	c99d                	beqz	a1,800040be <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000408a:	000aa503          	lw	a0,0(s5)
    8000408e:	fffff097          	auipc	ra,0xfffff
    80004092:	39e080e7          	jalr	926(ra) # 8000342c <bread>
    80004096:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004098:	3ff97713          	andi	a4,s2,1023
    8000409c:	40ec87bb          	subw	a5,s9,a4
    800040a0:	413b06bb          	subw	a3,s6,s3
    800040a4:	8d3e                	mv	s10,a5
    800040a6:	2781                	sext.w	a5,a5
    800040a8:	0006861b          	sext.w	a2,a3
    800040ac:	f8f674e3          	bgeu	a2,a5,80004034 <writei+0x4c>
    800040b0:	8d36                	mv	s10,a3
    800040b2:	b749                	j	80004034 <writei+0x4c>
      brelse(bp);
    800040b4:	8526                	mv	a0,s1
    800040b6:	fffff097          	auipc	ra,0xfffff
    800040ba:	4a6080e7          	jalr	1190(ra) # 8000355c <brelse>
  }

  if(off > ip->size)
    800040be:	04caa783          	lw	a5,76(s5)
    800040c2:	0127f463          	bgeu	a5,s2,800040ca <writei+0xe2>
    ip->size = off;
    800040c6:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800040ca:	8556                	mv	a0,s5
    800040cc:	00000097          	auipc	ra,0x0
    800040d0:	aa4080e7          	jalr	-1372(ra) # 80003b70 <iupdate>

  return tot;
    800040d4:	0009851b          	sext.w	a0,s3
}
    800040d8:	70a6                	ld	ra,104(sp)
    800040da:	7406                	ld	s0,96(sp)
    800040dc:	64e6                	ld	s1,88(sp)
    800040de:	6946                	ld	s2,80(sp)
    800040e0:	69a6                	ld	s3,72(sp)
    800040e2:	6a06                	ld	s4,64(sp)
    800040e4:	7ae2                	ld	s5,56(sp)
    800040e6:	7b42                	ld	s6,48(sp)
    800040e8:	7ba2                	ld	s7,40(sp)
    800040ea:	7c02                	ld	s8,32(sp)
    800040ec:	6ce2                	ld	s9,24(sp)
    800040ee:	6d42                	ld	s10,16(sp)
    800040f0:	6da2                	ld	s11,8(sp)
    800040f2:	6165                	addi	sp,sp,112
    800040f4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040f6:	89da                	mv	s3,s6
    800040f8:	bfc9                	j	800040ca <writei+0xe2>
    return -1;
    800040fa:	557d                	li	a0,-1
}
    800040fc:	8082                	ret
    return -1;
    800040fe:	557d                	li	a0,-1
    80004100:	bfe1                	j	800040d8 <writei+0xf0>
    return -1;
    80004102:	557d                	li	a0,-1
    80004104:	bfd1                	j	800040d8 <writei+0xf0>

0000000080004106 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004106:	1141                	addi	sp,sp,-16
    80004108:	e406                	sd	ra,8(sp)
    8000410a:	e022                	sd	s0,0(sp)
    8000410c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000410e:	4639                	li	a2,14
    80004110:	ffffd097          	auipc	ra,0xffffd
    80004114:	de6080e7          	jalr	-538(ra) # 80000ef6 <strncmp>
}
    80004118:	60a2                	ld	ra,8(sp)
    8000411a:	6402                	ld	s0,0(sp)
    8000411c:	0141                	addi	sp,sp,16
    8000411e:	8082                	ret

0000000080004120 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004120:	7139                	addi	sp,sp,-64
    80004122:	fc06                	sd	ra,56(sp)
    80004124:	f822                	sd	s0,48(sp)
    80004126:	f426                	sd	s1,40(sp)
    80004128:	f04a                	sd	s2,32(sp)
    8000412a:	ec4e                	sd	s3,24(sp)
    8000412c:	e852                	sd	s4,16(sp)
    8000412e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004130:	04451703          	lh	a4,68(a0)
    80004134:	4785                	li	a5,1
    80004136:	00f71a63          	bne	a4,a5,8000414a <dirlookup+0x2a>
    8000413a:	892a                	mv	s2,a0
    8000413c:	89ae                	mv	s3,a1
    8000413e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004140:	457c                	lw	a5,76(a0)
    80004142:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004144:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004146:	e79d                	bnez	a5,80004174 <dirlookup+0x54>
    80004148:	a8a5                	j	800041c0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000414a:	00004517          	auipc	a0,0x4
    8000414e:	5d650513          	addi	a0,a0,1494 # 80008720 <syscalls+0x1c8>
    80004152:	ffffc097          	auipc	ra,0xffffc
    80004156:	3ea080e7          	jalr	1002(ra) # 8000053c <panic>
      panic("dirlookup read");
    8000415a:	00004517          	auipc	a0,0x4
    8000415e:	5de50513          	addi	a0,a0,1502 # 80008738 <syscalls+0x1e0>
    80004162:	ffffc097          	auipc	ra,0xffffc
    80004166:	3da080e7          	jalr	986(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000416a:	24c1                	addiw	s1,s1,16
    8000416c:	04c92783          	lw	a5,76(s2)
    80004170:	04f4f763          	bgeu	s1,a5,800041be <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004174:	4741                	li	a4,16
    80004176:	86a6                	mv	a3,s1
    80004178:	fc040613          	addi	a2,s0,-64
    8000417c:	4581                	li	a1,0
    8000417e:	854a                	mv	a0,s2
    80004180:	00000097          	auipc	ra,0x0
    80004184:	d70080e7          	jalr	-656(ra) # 80003ef0 <readi>
    80004188:	47c1                	li	a5,16
    8000418a:	fcf518e3          	bne	a0,a5,8000415a <dirlookup+0x3a>
    if(de.inum == 0)
    8000418e:	fc045783          	lhu	a5,-64(s0)
    80004192:	dfe1                	beqz	a5,8000416a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004194:	fc240593          	addi	a1,s0,-62
    80004198:	854e                	mv	a0,s3
    8000419a:	00000097          	auipc	ra,0x0
    8000419e:	f6c080e7          	jalr	-148(ra) # 80004106 <namecmp>
    800041a2:	f561                	bnez	a0,8000416a <dirlookup+0x4a>
      if(poff)
    800041a4:	000a0463          	beqz	s4,800041ac <dirlookup+0x8c>
        *poff = off;
    800041a8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041ac:	fc045583          	lhu	a1,-64(s0)
    800041b0:	00092503          	lw	a0,0(s2)
    800041b4:	fffff097          	auipc	ra,0xfffff
    800041b8:	754080e7          	jalr	1876(ra) # 80003908 <iget>
    800041bc:	a011                	j	800041c0 <dirlookup+0xa0>
  return 0;
    800041be:	4501                	li	a0,0
}
    800041c0:	70e2                	ld	ra,56(sp)
    800041c2:	7442                	ld	s0,48(sp)
    800041c4:	74a2                	ld	s1,40(sp)
    800041c6:	7902                	ld	s2,32(sp)
    800041c8:	69e2                	ld	s3,24(sp)
    800041ca:	6a42                	ld	s4,16(sp)
    800041cc:	6121                	addi	sp,sp,64
    800041ce:	8082                	ret

00000000800041d0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800041d0:	711d                	addi	sp,sp,-96
    800041d2:	ec86                	sd	ra,88(sp)
    800041d4:	e8a2                	sd	s0,80(sp)
    800041d6:	e4a6                	sd	s1,72(sp)
    800041d8:	e0ca                	sd	s2,64(sp)
    800041da:	fc4e                	sd	s3,56(sp)
    800041dc:	f852                	sd	s4,48(sp)
    800041de:	f456                	sd	s5,40(sp)
    800041e0:	f05a                	sd	s6,32(sp)
    800041e2:	ec5e                	sd	s7,24(sp)
    800041e4:	e862                	sd	s8,16(sp)
    800041e6:	e466                	sd	s9,8(sp)
    800041e8:	1080                	addi	s0,sp,96
    800041ea:	84aa                	mv	s1,a0
    800041ec:	8b2e                	mv	s6,a1
    800041ee:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041f0:	00054703          	lbu	a4,0(a0)
    800041f4:	02f00793          	li	a5,47
    800041f8:	02f70263          	beq	a4,a5,8000421c <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041fc:	ffffe097          	auipc	ra,0xffffe
    80004200:	a60080e7          	jalr	-1440(ra) # 80001c5c <myproc>
    80004204:	15053503          	ld	a0,336(a0)
    80004208:	00000097          	auipc	ra,0x0
    8000420c:	9f6080e7          	jalr	-1546(ra) # 80003bfe <idup>
    80004210:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004212:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004216:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004218:	4b85                	li	s7,1
    8000421a:	a875                	j	800042d6 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    8000421c:	4585                	li	a1,1
    8000421e:	4505                	li	a0,1
    80004220:	fffff097          	auipc	ra,0xfffff
    80004224:	6e8080e7          	jalr	1768(ra) # 80003908 <iget>
    80004228:	8a2a                	mv	s4,a0
    8000422a:	b7e5                	j	80004212 <namex+0x42>
      iunlockput(ip);
    8000422c:	8552                	mv	a0,s4
    8000422e:	00000097          	auipc	ra,0x0
    80004232:	c70080e7          	jalr	-912(ra) # 80003e9e <iunlockput>
      return 0;
    80004236:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004238:	8552                	mv	a0,s4
    8000423a:	60e6                	ld	ra,88(sp)
    8000423c:	6446                	ld	s0,80(sp)
    8000423e:	64a6                	ld	s1,72(sp)
    80004240:	6906                	ld	s2,64(sp)
    80004242:	79e2                	ld	s3,56(sp)
    80004244:	7a42                	ld	s4,48(sp)
    80004246:	7aa2                	ld	s5,40(sp)
    80004248:	7b02                	ld	s6,32(sp)
    8000424a:	6be2                	ld	s7,24(sp)
    8000424c:	6c42                	ld	s8,16(sp)
    8000424e:	6ca2                	ld	s9,8(sp)
    80004250:	6125                	addi	sp,sp,96
    80004252:	8082                	ret
      iunlock(ip);
    80004254:	8552                	mv	a0,s4
    80004256:	00000097          	auipc	ra,0x0
    8000425a:	aa8080e7          	jalr	-1368(ra) # 80003cfe <iunlock>
      return ip;
    8000425e:	bfe9                	j	80004238 <namex+0x68>
      iunlockput(ip);
    80004260:	8552                	mv	a0,s4
    80004262:	00000097          	auipc	ra,0x0
    80004266:	c3c080e7          	jalr	-964(ra) # 80003e9e <iunlockput>
      return 0;
    8000426a:	8a4e                	mv	s4,s3
    8000426c:	b7f1                	j	80004238 <namex+0x68>
  len = path - s;
    8000426e:	40998633          	sub	a2,s3,s1
    80004272:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004276:	099c5863          	bge	s8,s9,80004306 <namex+0x136>
    memmove(name, s, DIRSIZ);
    8000427a:	4639                	li	a2,14
    8000427c:	85a6                	mv	a1,s1
    8000427e:	8556                	mv	a0,s5
    80004280:	ffffd097          	auipc	ra,0xffffd
    80004284:	c02080e7          	jalr	-1022(ra) # 80000e82 <memmove>
    80004288:	84ce                	mv	s1,s3
  while(*path == '/')
    8000428a:	0004c783          	lbu	a5,0(s1)
    8000428e:	01279763          	bne	a5,s2,8000429c <namex+0xcc>
    path++;
    80004292:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004294:	0004c783          	lbu	a5,0(s1)
    80004298:	ff278de3          	beq	a5,s2,80004292 <namex+0xc2>
    ilock(ip);
    8000429c:	8552                	mv	a0,s4
    8000429e:	00000097          	auipc	ra,0x0
    800042a2:	99e080e7          	jalr	-1634(ra) # 80003c3c <ilock>
    if(ip->type != T_DIR){
    800042a6:	044a1783          	lh	a5,68(s4)
    800042aa:	f97791e3          	bne	a5,s7,8000422c <namex+0x5c>
    if(nameiparent && *path == '\0'){
    800042ae:	000b0563          	beqz	s6,800042b8 <namex+0xe8>
    800042b2:	0004c783          	lbu	a5,0(s1)
    800042b6:	dfd9                	beqz	a5,80004254 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042b8:	4601                	li	a2,0
    800042ba:	85d6                	mv	a1,s5
    800042bc:	8552                	mv	a0,s4
    800042be:	00000097          	auipc	ra,0x0
    800042c2:	e62080e7          	jalr	-414(ra) # 80004120 <dirlookup>
    800042c6:	89aa                	mv	s3,a0
    800042c8:	dd41                	beqz	a0,80004260 <namex+0x90>
    iunlockput(ip);
    800042ca:	8552                	mv	a0,s4
    800042cc:	00000097          	auipc	ra,0x0
    800042d0:	bd2080e7          	jalr	-1070(ra) # 80003e9e <iunlockput>
    ip = next;
    800042d4:	8a4e                	mv	s4,s3
  while(*path == '/')
    800042d6:	0004c783          	lbu	a5,0(s1)
    800042da:	01279763          	bne	a5,s2,800042e8 <namex+0x118>
    path++;
    800042de:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042e0:	0004c783          	lbu	a5,0(s1)
    800042e4:	ff278de3          	beq	a5,s2,800042de <namex+0x10e>
  if(*path == 0)
    800042e8:	cb9d                	beqz	a5,8000431e <namex+0x14e>
  while(*path != '/' && *path != 0)
    800042ea:	0004c783          	lbu	a5,0(s1)
    800042ee:	89a6                	mv	s3,s1
  len = path - s;
    800042f0:	4c81                	li	s9,0
    800042f2:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    800042f4:	01278963          	beq	a5,s2,80004306 <namex+0x136>
    800042f8:	dbbd                	beqz	a5,8000426e <namex+0x9e>
    path++;
    800042fa:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800042fc:	0009c783          	lbu	a5,0(s3)
    80004300:	ff279ce3          	bne	a5,s2,800042f8 <namex+0x128>
    80004304:	b7ad                	j	8000426e <namex+0x9e>
    memmove(name, s, len);
    80004306:	2601                	sext.w	a2,a2
    80004308:	85a6                	mv	a1,s1
    8000430a:	8556                	mv	a0,s5
    8000430c:	ffffd097          	auipc	ra,0xffffd
    80004310:	b76080e7          	jalr	-1162(ra) # 80000e82 <memmove>
    name[len] = 0;
    80004314:	9cd6                	add	s9,s9,s5
    80004316:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000431a:	84ce                	mv	s1,s3
    8000431c:	b7bd                	j	8000428a <namex+0xba>
  if(nameiparent){
    8000431e:	f00b0de3          	beqz	s6,80004238 <namex+0x68>
    iput(ip);
    80004322:	8552                	mv	a0,s4
    80004324:	00000097          	auipc	ra,0x0
    80004328:	ad2080e7          	jalr	-1326(ra) # 80003df6 <iput>
    return 0;
    8000432c:	4a01                	li	s4,0
    8000432e:	b729                	j	80004238 <namex+0x68>

0000000080004330 <dirlink>:
{
    80004330:	7139                	addi	sp,sp,-64
    80004332:	fc06                	sd	ra,56(sp)
    80004334:	f822                	sd	s0,48(sp)
    80004336:	f426                	sd	s1,40(sp)
    80004338:	f04a                	sd	s2,32(sp)
    8000433a:	ec4e                	sd	s3,24(sp)
    8000433c:	e852                	sd	s4,16(sp)
    8000433e:	0080                	addi	s0,sp,64
    80004340:	892a                	mv	s2,a0
    80004342:	8a2e                	mv	s4,a1
    80004344:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004346:	4601                	li	a2,0
    80004348:	00000097          	auipc	ra,0x0
    8000434c:	dd8080e7          	jalr	-552(ra) # 80004120 <dirlookup>
    80004350:	e93d                	bnez	a0,800043c6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004352:	04c92483          	lw	s1,76(s2)
    80004356:	c49d                	beqz	s1,80004384 <dirlink+0x54>
    80004358:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000435a:	4741                	li	a4,16
    8000435c:	86a6                	mv	a3,s1
    8000435e:	fc040613          	addi	a2,s0,-64
    80004362:	4581                	li	a1,0
    80004364:	854a                	mv	a0,s2
    80004366:	00000097          	auipc	ra,0x0
    8000436a:	b8a080e7          	jalr	-1142(ra) # 80003ef0 <readi>
    8000436e:	47c1                	li	a5,16
    80004370:	06f51163          	bne	a0,a5,800043d2 <dirlink+0xa2>
    if(de.inum == 0)
    80004374:	fc045783          	lhu	a5,-64(s0)
    80004378:	c791                	beqz	a5,80004384 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000437a:	24c1                	addiw	s1,s1,16
    8000437c:	04c92783          	lw	a5,76(s2)
    80004380:	fcf4ede3          	bltu	s1,a5,8000435a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004384:	4639                	li	a2,14
    80004386:	85d2                	mv	a1,s4
    80004388:	fc240513          	addi	a0,s0,-62
    8000438c:	ffffd097          	auipc	ra,0xffffd
    80004390:	ba6080e7          	jalr	-1114(ra) # 80000f32 <strncpy>
  de.inum = inum;
    80004394:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004398:	4741                	li	a4,16
    8000439a:	86a6                	mv	a3,s1
    8000439c:	fc040613          	addi	a2,s0,-64
    800043a0:	4581                	li	a1,0
    800043a2:	854a                	mv	a0,s2
    800043a4:	00000097          	auipc	ra,0x0
    800043a8:	c44080e7          	jalr	-956(ra) # 80003fe8 <writei>
    800043ac:	1541                	addi	a0,a0,-16
    800043ae:	00a03533          	snez	a0,a0
    800043b2:	40a00533          	neg	a0,a0
}
    800043b6:	70e2                	ld	ra,56(sp)
    800043b8:	7442                	ld	s0,48(sp)
    800043ba:	74a2                	ld	s1,40(sp)
    800043bc:	7902                	ld	s2,32(sp)
    800043be:	69e2                	ld	s3,24(sp)
    800043c0:	6a42                	ld	s4,16(sp)
    800043c2:	6121                	addi	sp,sp,64
    800043c4:	8082                	ret
    iput(ip);
    800043c6:	00000097          	auipc	ra,0x0
    800043ca:	a30080e7          	jalr	-1488(ra) # 80003df6 <iput>
    return -1;
    800043ce:	557d                	li	a0,-1
    800043d0:	b7dd                	j	800043b6 <dirlink+0x86>
      panic("dirlink read");
    800043d2:	00004517          	auipc	a0,0x4
    800043d6:	37650513          	addi	a0,a0,886 # 80008748 <syscalls+0x1f0>
    800043da:	ffffc097          	auipc	ra,0xffffc
    800043de:	162080e7          	jalr	354(ra) # 8000053c <panic>

00000000800043e2 <namei>:

struct inode*
namei(char *path)
{
    800043e2:	1101                	addi	sp,sp,-32
    800043e4:	ec06                	sd	ra,24(sp)
    800043e6:	e822                	sd	s0,16(sp)
    800043e8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043ea:	fe040613          	addi	a2,s0,-32
    800043ee:	4581                	li	a1,0
    800043f0:	00000097          	auipc	ra,0x0
    800043f4:	de0080e7          	jalr	-544(ra) # 800041d0 <namex>
}
    800043f8:	60e2                	ld	ra,24(sp)
    800043fa:	6442                	ld	s0,16(sp)
    800043fc:	6105                	addi	sp,sp,32
    800043fe:	8082                	ret

0000000080004400 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004400:	1141                	addi	sp,sp,-16
    80004402:	e406                	sd	ra,8(sp)
    80004404:	e022                	sd	s0,0(sp)
    80004406:	0800                	addi	s0,sp,16
    80004408:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000440a:	4585                	li	a1,1
    8000440c:	00000097          	auipc	ra,0x0
    80004410:	dc4080e7          	jalr	-572(ra) # 800041d0 <namex>
}
    80004414:	60a2                	ld	ra,8(sp)
    80004416:	6402                	ld	s0,0(sp)
    80004418:	0141                	addi	sp,sp,16
    8000441a:	8082                	ret

000000008000441c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000441c:	1101                	addi	sp,sp,-32
    8000441e:	ec06                	sd	ra,24(sp)
    80004420:	e822                	sd	s0,16(sp)
    80004422:	e426                	sd	s1,8(sp)
    80004424:	e04a                	sd	s2,0(sp)
    80004426:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004428:	0023d917          	auipc	s2,0x23d
    8000442c:	84890913          	addi	s2,s2,-1976 # 80240c70 <log>
    80004430:	01892583          	lw	a1,24(s2)
    80004434:	02892503          	lw	a0,40(s2)
    80004438:	fffff097          	auipc	ra,0xfffff
    8000443c:	ff4080e7          	jalr	-12(ra) # 8000342c <bread>
    80004440:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004442:	02c92603          	lw	a2,44(s2)
    80004446:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004448:	00c05f63          	blez	a2,80004466 <write_head+0x4a>
    8000444c:	0023d717          	auipc	a4,0x23d
    80004450:	85470713          	addi	a4,a4,-1964 # 80240ca0 <log+0x30>
    80004454:	87aa                	mv	a5,a0
    80004456:	060a                	slli	a2,a2,0x2
    80004458:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    8000445a:	4314                	lw	a3,0(a4)
    8000445c:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    8000445e:	0711                	addi	a4,a4,4
    80004460:	0791                	addi	a5,a5,4
    80004462:	fec79ce3          	bne	a5,a2,8000445a <write_head+0x3e>
  }
  bwrite(buf);
    80004466:	8526                	mv	a0,s1
    80004468:	fffff097          	auipc	ra,0xfffff
    8000446c:	0b6080e7          	jalr	182(ra) # 8000351e <bwrite>
  brelse(buf);
    80004470:	8526                	mv	a0,s1
    80004472:	fffff097          	auipc	ra,0xfffff
    80004476:	0ea080e7          	jalr	234(ra) # 8000355c <brelse>
}
    8000447a:	60e2                	ld	ra,24(sp)
    8000447c:	6442                	ld	s0,16(sp)
    8000447e:	64a2                	ld	s1,8(sp)
    80004480:	6902                	ld	s2,0(sp)
    80004482:	6105                	addi	sp,sp,32
    80004484:	8082                	ret

0000000080004486 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004486:	0023d797          	auipc	a5,0x23d
    8000448a:	8167a783          	lw	a5,-2026(a5) # 80240c9c <log+0x2c>
    8000448e:	0af05d63          	blez	a5,80004548 <install_trans+0xc2>
{
    80004492:	7139                	addi	sp,sp,-64
    80004494:	fc06                	sd	ra,56(sp)
    80004496:	f822                	sd	s0,48(sp)
    80004498:	f426                	sd	s1,40(sp)
    8000449a:	f04a                	sd	s2,32(sp)
    8000449c:	ec4e                	sd	s3,24(sp)
    8000449e:	e852                	sd	s4,16(sp)
    800044a0:	e456                	sd	s5,8(sp)
    800044a2:	e05a                	sd	s6,0(sp)
    800044a4:	0080                	addi	s0,sp,64
    800044a6:	8b2a                	mv	s6,a0
    800044a8:	0023ca97          	auipc	s5,0x23c
    800044ac:	7f8a8a93          	addi	s5,s5,2040 # 80240ca0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044b0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044b2:	0023c997          	auipc	s3,0x23c
    800044b6:	7be98993          	addi	s3,s3,1982 # 80240c70 <log>
    800044ba:	a00d                	j	800044dc <install_trans+0x56>
    brelse(lbuf);
    800044bc:	854a                	mv	a0,s2
    800044be:	fffff097          	auipc	ra,0xfffff
    800044c2:	09e080e7          	jalr	158(ra) # 8000355c <brelse>
    brelse(dbuf);
    800044c6:	8526                	mv	a0,s1
    800044c8:	fffff097          	auipc	ra,0xfffff
    800044cc:	094080e7          	jalr	148(ra) # 8000355c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044d0:	2a05                	addiw	s4,s4,1
    800044d2:	0a91                	addi	s5,s5,4
    800044d4:	02c9a783          	lw	a5,44(s3)
    800044d8:	04fa5e63          	bge	s4,a5,80004534 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044dc:	0189a583          	lw	a1,24(s3)
    800044e0:	014585bb          	addw	a1,a1,s4
    800044e4:	2585                	addiw	a1,a1,1
    800044e6:	0289a503          	lw	a0,40(s3)
    800044ea:	fffff097          	auipc	ra,0xfffff
    800044ee:	f42080e7          	jalr	-190(ra) # 8000342c <bread>
    800044f2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800044f4:	000aa583          	lw	a1,0(s5)
    800044f8:	0289a503          	lw	a0,40(s3)
    800044fc:	fffff097          	auipc	ra,0xfffff
    80004500:	f30080e7          	jalr	-208(ra) # 8000342c <bread>
    80004504:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004506:	40000613          	li	a2,1024
    8000450a:	05890593          	addi	a1,s2,88
    8000450e:	05850513          	addi	a0,a0,88
    80004512:	ffffd097          	auipc	ra,0xffffd
    80004516:	970080e7          	jalr	-1680(ra) # 80000e82 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000451a:	8526                	mv	a0,s1
    8000451c:	fffff097          	auipc	ra,0xfffff
    80004520:	002080e7          	jalr	2(ra) # 8000351e <bwrite>
    if(recovering == 0)
    80004524:	f80b1ce3          	bnez	s6,800044bc <install_trans+0x36>
      bunpin(dbuf);
    80004528:	8526                	mv	a0,s1
    8000452a:	fffff097          	auipc	ra,0xfffff
    8000452e:	10a080e7          	jalr	266(ra) # 80003634 <bunpin>
    80004532:	b769                	j	800044bc <install_trans+0x36>
}
    80004534:	70e2                	ld	ra,56(sp)
    80004536:	7442                	ld	s0,48(sp)
    80004538:	74a2                	ld	s1,40(sp)
    8000453a:	7902                	ld	s2,32(sp)
    8000453c:	69e2                	ld	s3,24(sp)
    8000453e:	6a42                	ld	s4,16(sp)
    80004540:	6aa2                	ld	s5,8(sp)
    80004542:	6b02                	ld	s6,0(sp)
    80004544:	6121                	addi	sp,sp,64
    80004546:	8082                	ret
    80004548:	8082                	ret

000000008000454a <initlog>:
{
    8000454a:	7179                	addi	sp,sp,-48
    8000454c:	f406                	sd	ra,40(sp)
    8000454e:	f022                	sd	s0,32(sp)
    80004550:	ec26                	sd	s1,24(sp)
    80004552:	e84a                	sd	s2,16(sp)
    80004554:	e44e                	sd	s3,8(sp)
    80004556:	1800                	addi	s0,sp,48
    80004558:	892a                	mv	s2,a0
    8000455a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000455c:	0023c497          	auipc	s1,0x23c
    80004560:	71448493          	addi	s1,s1,1812 # 80240c70 <log>
    80004564:	00004597          	auipc	a1,0x4
    80004568:	1f458593          	addi	a1,a1,500 # 80008758 <syscalls+0x200>
    8000456c:	8526                	mv	a0,s1
    8000456e:	ffffc097          	auipc	ra,0xffffc
    80004572:	72c080e7          	jalr	1836(ra) # 80000c9a <initlock>
  log.start = sb->logstart;
    80004576:	0149a583          	lw	a1,20(s3)
    8000457a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000457c:	0109a783          	lw	a5,16(s3)
    80004580:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004582:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004586:	854a                	mv	a0,s2
    80004588:	fffff097          	auipc	ra,0xfffff
    8000458c:	ea4080e7          	jalr	-348(ra) # 8000342c <bread>
  log.lh.n = lh->n;
    80004590:	4d30                	lw	a2,88(a0)
    80004592:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004594:	00c05f63          	blez	a2,800045b2 <initlog+0x68>
    80004598:	87aa                	mv	a5,a0
    8000459a:	0023c717          	auipc	a4,0x23c
    8000459e:	70670713          	addi	a4,a4,1798 # 80240ca0 <log+0x30>
    800045a2:	060a                	slli	a2,a2,0x2
    800045a4:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800045a6:	4ff4                	lw	a3,92(a5)
    800045a8:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800045aa:	0791                	addi	a5,a5,4
    800045ac:	0711                	addi	a4,a4,4
    800045ae:	fec79ce3          	bne	a5,a2,800045a6 <initlog+0x5c>
  brelse(buf);
    800045b2:	fffff097          	auipc	ra,0xfffff
    800045b6:	faa080e7          	jalr	-86(ra) # 8000355c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800045ba:	4505                	li	a0,1
    800045bc:	00000097          	auipc	ra,0x0
    800045c0:	eca080e7          	jalr	-310(ra) # 80004486 <install_trans>
  log.lh.n = 0;
    800045c4:	0023c797          	auipc	a5,0x23c
    800045c8:	6c07ac23          	sw	zero,1752(a5) # 80240c9c <log+0x2c>
  write_head(); // clear the log
    800045cc:	00000097          	auipc	ra,0x0
    800045d0:	e50080e7          	jalr	-432(ra) # 8000441c <write_head>
}
    800045d4:	70a2                	ld	ra,40(sp)
    800045d6:	7402                	ld	s0,32(sp)
    800045d8:	64e2                	ld	s1,24(sp)
    800045da:	6942                	ld	s2,16(sp)
    800045dc:	69a2                	ld	s3,8(sp)
    800045de:	6145                	addi	sp,sp,48
    800045e0:	8082                	ret

00000000800045e2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045e2:	1101                	addi	sp,sp,-32
    800045e4:	ec06                	sd	ra,24(sp)
    800045e6:	e822                	sd	s0,16(sp)
    800045e8:	e426                	sd	s1,8(sp)
    800045ea:	e04a                	sd	s2,0(sp)
    800045ec:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800045ee:	0023c517          	auipc	a0,0x23c
    800045f2:	68250513          	addi	a0,a0,1666 # 80240c70 <log>
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	734080e7          	jalr	1844(ra) # 80000d2a <acquire>
  while(1){
    if(log.committing){
    800045fe:	0023c497          	auipc	s1,0x23c
    80004602:	67248493          	addi	s1,s1,1650 # 80240c70 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004606:	4979                	li	s2,30
    80004608:	a039                	j	80004616 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000460a:	85a6                	mv	a1,s1
    8000460c:	8526                	mv	a0,s1
    8000460e:	ffffe097          	auipc	ra,0xffffe
    80004612:	db6080e7          	jalr	-586(ra) # 800023c4 <sleep>
    if(log.committing){
    80004616:	50dc                	lw	a5,36(s1)
    80004618:	fbed                	bnez	a5,8000460a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000461a:	5098                	lw	a4,32(s1)
    8000461c:	2705                	addiw	a4,a4,1
    8000461e:	0027179b          	slliw	a5,a4,0x2
    80004622:	9fb9                	addw	a5,a5,a4
    80004624:	0017979b          	slliw	a5,a5,0x1
    80004628:	54d4                	lw	a3,44(s1)
    8000462a:	9fb5                	addw	a5,a5,a3
    8000462c:	00f95963          	bge	s2,a5,8000463e <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004630:	85a6                	mv	a1,s1
    80004632:	8526                	mv	a0,s1
    80004634:	ffffe097          	auipc	ra,0xffffe
    80004638:	d90080e7          	jalr	-624(ra) # 800023c4 <sleep>
    8000463c:	bfe9                	j	80004616 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000463e:	0023c517          	auipc	a0,0x23c
    80004642:	63250513          	addi	a0,a0,1586 # 80240c70 <log>
    80004646:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	796080e7          	jalr	1942(ra) # 80000dde <release>
      break;
    }
  }
}
    80004650:	60e2                	ld	ra,24(sp)
    80004652:	6442                	ld	s0,16(sp)
    80004654:	64a2                	ld	s1,8(sp)
    80004656:	6902                	ld	s2,0(sp)
    80004658:	6105                	addi	sp,sp,32
    8000465a:	8082                	ret

000000008000465c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000465c:	7139                	addi	sp,sp,-64
    8000465e:	fc06                	sd	ra,56(sp)
    80004660:	f822                	sd	s0,48(sp)
    80004662:	f426                	sd	s1,40(sp)
    80004664:	f04a                	sd	s2,32(sp)
    80004666:	ec4e                	sd	s3,24(sp)
    80004668:	e852                	sd	s4,16(sp)
    8000466a:	e456                	sd	s5,8(sp)
    8000466c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000466e:	0023c497          	auipc	s1,0x23c
    80004672:	60248493          	addi	s1,s1,1538 # 80240c70 <log>
    80004676:	8526                	mv	a0,s1
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	6b2080e7          	jalr	1714(ra) # 80000d2a <acquire>
  log.outstanding -= 1;
    80004680:	509c                	lw	a5,32(s1)
    80004682:	37fd                	addiw	a5,a5,-1
    80004684:	0007891b          	sext.w	s2,a5
    80004688:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000468a:	50dc                	lw	a5,36(s1)
    8000468c:	e7b9                	bnez	a5,800046da <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000468e:	04091e63          	bnez	s2,800046ea <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004692:	0023c497          	auipc	s1,0x23c
    80004696:	5de48493          	addi	s1,s1,1502 # 80240c70 <log>
    8000469a:	4785                	li	a5,1
    8000469c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000469e:	8526                	mv	a0,s1
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	73e080e7          	jalr	1854(ra) # 80000dde <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800046a8:	54dc                	lw	a5,44(s1)
    800046aa:	06f04763          	bgtz	a5,80004718 <end_op+0xbc>
    acquire(&log.lock);
    800046ae:	0023c497          	auipc	s1,0x23c
    800046b2:	5c248493          	addi	s1,s1,1474 # 80240c70 <log>
    800046b6:	8526                	mv	a0,s1
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	672080e7          	jalr	1650(ra) # 80000d2a <acquire>
    log.committing = 0;
    800046c0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800046c4:	8526                	mv	a0,s1
    800046c6:	ffffe097          	auipc	ra,0xffffe
    800046ca:	d62080e7          	jalr	-670(ra) # 80002428 <wakeup>
    release(&log.lock);
    800046ce:	8526                	mv	a0,s1
    800046d0:	ffffc097          	auipc	ra,0xffffc
    800046d4:	70e080e7          	jalr	1806(ra) # 80000dde <release>
}
    800046d8:	a03d                	j	80004706 <end_op+0xaa>
    panic("log.committing");
    800046da:	00004517          	auipc	a0,0x4
    800046de:	08650513          	addi	a0,a0,134 # 80008760 <syscalls+0x208>
    800046e2:	ffffc097          	auipc	ra,0xffffc
    800046e6:	e5a080e7          	jalr	-422(ra) # 8000053c <panic>
    wakeup(&log);
    800046ea:	0023c497          	auipc	s1,0x23c
    800046ee:	58648493          	addi	s1,s1,1414 # 80240c70 <log>
    800046f2:	8526                	mv	a0,s1
    800046f4:	ffffe097          	auipc	ra,0xffffe
    800046f8:	d34080e7          	jalr	-716(ra) # 80002428 <wakeup>
  release(&log.lock);
    800046fc:	8526                	mv	a0,s1
    800046fe:	ffffc097          	auipc	ra,0xffffc
    80004702:	6e0080e7          	jalr	1760(ra) # 80000dde <release>
}
    80004706:	70e2                	ld	ra,56(sp)
    80004708:	7442                	ld	s0,48(sp)
    8000470a:	74a2                	ld	s1,40(sp)
    8000470c:	7902                	ld	s2,32(sp)
    8000470e:	69e2                	ld	s3,24(sp)
    80004710:	6a42                	ld	s4,16(sp)
    80004712:	6aa2                	ld	s5,8(sp)
    80004714:	6121                	addi	sp,sp,64
    80004716:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004718:	0023ca97          	auipc	s5,0x23c
    8000471c:	588a8a93          	addi	s5,s5,1416 # 80240ca0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004720:	0023ca17          	auipc	s4,0x23c
    80004724:	550a0a13          	addi	s4,s4,1360 # 80240c70 <log>
    80004728:	018a2583          	lw	a1,24(s4)
    8000472c:	012585bb          	addw	a1,a1,s2
    80004730:	2585                	addiw	a1,a1,1
    80004732:	028a2503          	lw	a0,40(s4)
    80004736:	fffff097          	auipc	ra,0xfffff
    8000473a:	cf6080e7          	jalr	-778(ra) # 8000342c <bread>
    8000473e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004740:	000aa583          	lw	a1,0(s5)
    80004744:	028a2503          	lw	a0,40(s4)
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	ce4080e7          	jalr	-796(ra) # 8000342c <bread>
    80004750:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004752:	40000613          	li	a2,1024
    80004756:	05850593          	addi	a1,a0,88
    8000475a:	05848513          	addi	a0,s1,88
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	724080e7          	jalr	1828(ra) # 80000e82 <memmove>
    bwrite(to);  // write the log
    80004766:	8526                	mv	a0,s1
    80004768:	fffff097          	auipc	ra,0xfffff
    8000476c:	db6080e7          	jalr	-586(ra) # 8000351e <bwrite>
    brelse(from);
    80004770:	854e                	mv	a0,s3
    80004772:	fffff097          	auipc	ra,0xfffff
    80004776:	dea080e7          	jalr	-534(ra) # 8000355c <brelse>
    brelse(to);
    8000477a:	8526                	mv	a0,s1
    8000477c:	fffff097          	auipc	ra,0xfffff
    80004780:	de0080e7          	jalr	-544(ra) # 8000355c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004784:	2905                	addiw	s2,s2,1
    80004786:	0a91                	addi	s5,s5,4
    80004788:	02ca2783          	lw	a5,44(s4)
    8000478c:	f8f94ee3          	blt	s2,a5,80004728 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004790:	00000097          	auipc	ra,0x0
    80004794:	c8c080e7          	jalr	-884(ra) # 8000441c <write_head>
    install_trans(0); // Now install writes to home locations
    80004798:	4501                	li	a0,0
    8000479a:	00000097          	auipc	ra,0x0
    8000479e:	cec080e7          	jalr	-788(ra) # 80004486 <install_trans>
    log.lh.n = 0;
    800047a2:	0023c797          	auipc	a5,0x23c
    800047a6:	4e07ad23          	sw	zero,1274(a5) # 80240c9c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800047aa:	00000097          	auipc	ra,0x0
    800047ae:	c72080e7          	jalr	-910(ra) # 8000441c <write_head>
    800047b2:	bdf5                	j	800046ae <end_op+0x52>

00000000800047b4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800047b4:	1101                	addi	sp,sp,-32
    800047b6:	ec06                	sd	ra,24(sp)
    800047b8:	e822                	sd	s0,16(sp)
    800047ba:	e426                	sd	s1,8(sp)
    800047bc:	e04a                	sd	s2,0(sp)
    800047be:	1000                	addi	s0,sp,32
    800047c0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800047c2:	0023c917          	auipc	s2,0x23c
    800047c6:	4ae90913          	addi	s2,s2,1198 # 80240c70 <log>
    800047ca:	854a                	mv	a0,s2
    800047cc:	ffffc097          	auipc	ra,0xffffc
    800047d0:	55e080e7          	jalr	1374(ra) # 80000d2a <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800047d4:	02c92603          	lw	a2,44(s2)
    800047d8:	47f5                	li	a5,29
    800047da:	06c7c563          	blt	a5,a2,80004844 <log_write+0x90>
    800047de:	0023c797          	auipc	a5,0x23c
    800047e2:	4ae7a783          	lw	a5,1198(a5) # 80240c8c <log+0x1c>
    800047e6:	37fd                	addiw	a5,a5,-1
    800047e8:	04f65e63          	bge	a2,a5,80004844 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800047ec:	0023c797          	auipc	a5,0x23c
    800047f0:	4a47a783          	lw	a5,1188(a5) # 80240c90 <log+0x20>
    800047f4:	06f05063          	blez	a5,80004854 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800047f8:	4781                	li	a5,0
    800047fa:	06c05563          	blez	a2,80004864 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047fe:	44cc                	lw	a1,12(s1)
    80004800:	0023c717          	auipc	a4,0x23c
    80004804:	4a070713          	addi	a4,a4,1184 # 80240ca0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004808:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000480a:	4314                	lw	a3,0(a4)
    8000480c:	04b68c63          	beq	a3,a1,80004864 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004810:	2785                	addiw	a5,a5,1
    80004812:	0711                	addi	a4,a4,4
    80004814:	fef61be3          	bne	a2,a5,8000480a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004818:	0621                	addi	a2,a2,8
    8000481a:	060a                	slli	a2,a2,0x2
    8000481c:	0023c797          	auipc	a5,0x23c
    80004820:	45478793          	addi	a5,a5,1108 # 80240c70 <log>
    80004824:	97b2                	add	a5,a5,a2
    80004826:	44d8                	lw	a4,12(s1)
    80004828:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000482a:	8526                	mv	a0,s1
    8000482c:	fffff097          	auipc	ra,0xfffff
    80004830:	dcc080e7          	jalr	-564(ra) # 800035f8 <bpin>
    log.lh.n++;
    80004834:	0023c717          	auipc	a4,0x23c
    80004838:	43c70713          	addi	a4,a4,1084 # 80240c70 <log>
    8000483c:	575c                	lw	a5,44(a4)
    8000483e:	2785                	addiw	a5,a5,1
    80004840:	d75c                	sw	a5,44(a4)
    80004842:	a82d                	j	8000487c <log_write+0xc8>
    panic("too big a transaction");
    80004844:	00004517          	auipc	a0,0x4
    80004848:	f2c50513          	addi	a0,a0,-212 # 80008770 <syscalls+0x218>
    8000484c:	ffffc097          	auipc	ra,0xffffc
    80004850:	cf0080e7          	jalr	-784(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004854:	00004517          	auipc	a0,0x4
    80004858:	f3450513          	addi	a0,a0,-204 # 80008788 <syscalls+0x230>
    8000485c:	ffffc097          	auipc	ra,0xffffc
    80004860:	ce0080e7          	jalr	-800(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004864:	00878693          	addi	a3,a5,8
    80004868:	068a                	slli	a3,a3,0x2
    8000486a:	0023c717          	auipc	a4,0x23c
    8000486e:	40670713          	addi	a4,a4,1030 # 80240c70 <log>
    80004872:	9736                	add	a4,a4,a3
    80004874:	44d4                	lw	a3,12(s1)
    80004876:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004878:	faf609e3          	beq	a2,a5,8000482a <log_write+0x76>
  }
  release(&log.lock);
    8000487c:	0023c517          	auipc	a0,0x23c
    80004880:	3f450513          	addi	a0,a0,1012 # 80240c70 <log>
    80004884:	ffffc097          	auipc	ra,0xffffc
    80004888:	55a080e7          	jalr	1370(ra) # 80000dde <release>
}
    8000488c:	60e2                	ld	ra,24(sp)
    8000488e:	6442                	ld	s0,16(sp)
    80004890:	64a2                	ld	s1,8(sp)
    80004892:	6902                	ld	s2,0(sp)
    80004894:	6105                	addi	sp,sp,32
    80004896:	8082                	ret

0000000080004898 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004898:	1101                	addi	sp,sp,-32
    8000489a:	ec06                	sd	ra,24(sp)
    8000489c:	e822                	sd	s0,16(sp)
    8000489e:	e426                	sd	s1,8(sp)
    800048a0:	e04a                	sd	s2,0(sp)
    800048a2:	1000                	addi	s0,sp,32
    800048a4:	84aa                	mv	s1,a0
    800048a6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800048a8:	00004597          	auipc	a1,0x4
    800048ac:	f0058593          	addi	a1,a1,-256 # 800087a8 <syscalls+0x250>
    800048b0:	0521                	addi	a0,a0,8
    800048b2:	ffffc097          	auipc	ra,0xffffc
    800048b6:	3e8080e7          	jalr	1000(ra) # 80000c9a <initlock>
  lk->name = name;
    800048ba:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800048be:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048c2:	0204a423          	sw	zero,40(s1)
}
    800048c6:	60e2                	ld	ra,24(sp)
    800048c8:	6442                	ld	s0,16(sp)
    800048ca:	64a2                	ld	s1,8(sp)
    800048cc:	6902                	ld	s2,0(sp)
    800048ce:	6105                	addi	sp,sp,32
    800048d0:	8082                	ret

00000000800048d2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800048d2:	1101                	addi	sp,sp,-32
    800048d4:	ec06                	sd	ra,24(sp)
    800048d6:	e822                	sd	s0,16(sp)
    800048d8:	e426                	sd	s1,8(sp)
    800048da:	e04a                	sd	s2,0(sp)
    800048dc:	1000                	addi	s0,sp,32
    800048de:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048e0:	00850913          	addi	s2,a0,8
    800048e4:	854a                	mv	a0,s2
    800048e6:	ffffc097          	auipc	ra,0xffffc
    800048ea:	444080e7          	jalr	1092(ra) # 80000d2a <acquire>
  while (lk->locked) {
    800048ee:	409c                	lw	a5,0(s1)
    800048f0:	cb89                	beqz	a5,80004902 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800048f2:	85ca                	mv	a1,s2
    800048f4:	8526                	mv	a0,s1
    800048f6:	ffffe097          	auipc	ra,0xffffe
    800048fa:	ace080e7          	jalr	-1330(ra) # 800023c4 <sleep>
  while (lk->locked) {
    800048fe:	409c                	lw	a5,0(s1)
    80004900:	fbed                	bnez	a5,800048f2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004902:	4785                	li	a5,1
    80004904:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004906:	ffffd097          	auipc	ra,0xffffd
    8000490a:	356080e7          	jalr	854(ra) # 80001c5c <myproc>
    8000490e:	591c                	lw	a5,48(a0)
    80004910:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004912:	854a                	mv	a0,s2
    80004914:	ffffc097          	auipc	ra,0xffffc
    80004918:	4ca080e7          	jalr	1226(ra) # 80000dde <release>
}
    8000491c:	60e2                	ld	ra,24(sp)
    8000491e:	6442                	ld	s0,16(sp)
    80004920:	64a2                	ld	s1,8(sp)
    80004922:	6902                	ld	s2,0(sp)
    80004924:	6105                	addi	sp,sp,32
    80004926:	8082                	ret

0000000080004928 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004928:	1101                	addi	sp,sp,-32
    8000492a:	ec06                	sd	ra,24(sp)
    8000492c:	e822                	sd	s0,16(sp)
    8000492e:	e426                	sd	s1,8(sp)
    80004930:	e04a                	sd	s2,0(sp)
    80004932:	1000                	addi	s0,sp,32
    80004934:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004936:	00850913          	addi	s2,a0,8
    8000493a:	854a                	mv	a0,s2
    8000493c:	ffffc097          	auipc	ra,0xffffc
    80004940:	3ee080e7          	jalr	1006(ra) # 80000d2a <acquire>
  lk->locked = 0;
    80004944:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004948:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000494c:	8526                	mv	a0,s1
    8000494e:	ffffe097          	auipc	ra,0xffffe
    80004952:	ada080e7          	jalr	-1318(ra) # 80002428 <wakeup>
  release(&lk->lk);
    80004956:	854a                	mv	a0,s2
    80004958:	ffffc097          	auipc	ra,0xffffc
    8000495c:	486080e7          	jalr	1158(ra) # 80000dde <release>
}
    80004960:	60e2                	ld	ra,24(sp)
    80004962:	6442                	ld	s0,16(sp)
    80004964:	64a2                	ld	s1,8(sp)
    80004966:	6902                	ld	s2,0(sp)
    80004968:	6105                	addi	sp,sp,32
    8000496a:	8082                	ret

000000008000496c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000496c:	7179                	addi	sp,sp,-48
    8000496e:	f406                	sd	ra,40(sp)
    80004970:	f022                	sd	s0,32(sp)
    80004972:	ec26                	sd	s1,24(sp)
    80004974:	e84a                	sd	s2,16(sp)
    80004976:	e44e                	sd	s3,8(sp)
    80004978:	1800                	addi	s0,sp,48
    8000497a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000497c:	00850913          	addi	s2,a0,8
    80004980:	854a                	mv	a0,s2
    80004982:	ffffc097          	auipc	ra,0xffffc
    80004986:	3a8080e7          	jalr	936(ra) # 80000d2a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000498a:	409c                	lw	a5,0(s1)
    8000498c:	ef99                	bnez	a5,800049aa <holdingsleep+0x3e>
    8000498e:	4481                	li	s1,0
  release(&lk->lk);
    80004990:	854a                	mv	a0,s2
    80004992:	ffffc097          	auipc	ra,0xffffc
    80004996:	44c080e7          	jalr	1100(ra) # 80000dde <release>
  return r;
}
    8000499a:	8526                	mv	a0,s1
    8000499c:	70a2                	ld	ra,40(sp)
    8000499e:	7402                	ld	s0,32(sp)
    800049a0:	64e2                	ld	s1,24(sp)
    800049a2:	6942                	ld	s2,16(sp)
    800049a4:	69a2                	ld	s3,8(sp)
    800049a6:	6145                	addi	sp,sp,48
    800049a8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800049aa:	0284a983          	lw	s3,40(s1)
    800049ae:	ffffd097          	auipc	ra,0xffffd
    800049b2:	2ae080e7          	jalr	686(ra) # 80001c5c <myproc>
    800049b6:	5904                	lw	s1,48(a0)
    800049b8:	413484b3          	sub	s1,s1,s3
    800049bc:	0014b493          	seqz	s1,s1
    800049c0:	bfc1                	j	80004990 <holdingsleep+0x24>

00000000800049c2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800049c2:	1141                	addi	sp,sp,-16
    800049c4:	e406                	sd	ra,8(sp)
    800049c6:	e022                	sd	s0,0(sp)
    800049c8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049ca:	00004597          	auipc	a1,0x4
    800049ce:	dee58593          	addi	a1,a1,-530 # 800087b8 <syscalls+0x260>
    800049d2:	0023c517          	auipc	a0,0x23c
    800049d6:	3e650513          	addi	a0,a0,998 # 80240db8 <ftable>
    800049da:	ffffc097          	auipc	ra,0xffffc
    800049de:	2c0080e7          	jalr	704(ra) # 80000c9a <initlock>
}
    800049e2:	60a2                	ld	ra,8(sp)
    800049e4:	6402                	ld	s0,0(sp)
    800049e6:	0141                	addi	sp,sp,16
    800049e8:	8082                	ret

00000000800049ea <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800049ea:	1101                	addi	sp,sp,-32
    800049ec:	ec06                	sd	ra,24(sp)
    800049ee:	e822                	sd	s0,16(sp)
    800049f0:	e426                	sd	s1,8(sp)
    800049f2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800049f4:	0023c517          	auipc	a0,0x23c
    800049f8:	3c450513          	addi	a0,a0,964 # 80240db8 <ftable>
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	32e080e7          	jalr	814(ra) # 80000d2a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a04:	0023c497          	auipc	s1,0x23c
    80004a08:	3cc48493          	addi	s1,s1,972 # 80240dd0 <ftable+0x18>
    80004a0c:	0023d717          	auipc	a4,0x23d
    80004a10:	36470713          	addi	a4,a4,868 # 80241d70 <disk>
    if(f->ref == 0){
    80004a14:	40dc                	lw	a5,4(s1)
    80004a16:	cf99                	beqz	a5,80004a34 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a18:	02848493          	addi	s1,s1,40
    80004a1c:	fee49ce3          	bne	s1,a4,80004a14 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a20:	0023c517          	auipc	a0,0x23c
    80004a24:	39850513          	addi	a0,a0,920 # 80240db8 <ftable>
    80004a28:	ffffc097          	auipc	ra,0xffffc
    80004a2c:	3b6080e7          	jalr	950(ra) # 80000dde <release>
  return 0;
    80004a30:	4481                	li	s1,0
    80004a32:	a819                	j	80004a48 <filealloc+0x5e>
      f->ref = 1;
    80004a34:	4785                	li	a5,1
    80004a36:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a38:	0023c517          	auipc	a0,0x23c
    80004a3c:	38050513          	addi	a0,a0,896 # 80240db8 <ftable>
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	39e080e7          	jalr	926(ra) # 80000dde <release>
}
    80004a48:	8526                	mv	a0,s1
    80004a4a:	60e2                	ld	ra,24(sp)
    80004a4c:	6442                	ld	s0,16(sp)
    80004a4e:	64a2                	ld	s1,8(sp)
    80004a50:	6105                	addi	sp,sp,32
    80004a52:	8082                	ret

0000000080004a54 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a54:	1101                	addi	sp,sp,-32
    80004a56:	ec06                	sd	ra,24(sp)
    80004a58:	e822                	sd	s0,16(sp)
    80004a5a:	e426                	sd	s1,8(sp)
    80004a5c:	1000                	addi	s0,sp,32
    80004a5e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a60:	0023c517          	auipc	a0,0x23c
    80004a64:	35850513          	addi	a0,a0,856 # 80240db8 <ftable>
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	2c2080e7          	jalr	706(ra) # 80000d2a <acquire>
  if(f->ref < 1)
    80004a70:	40dc                	lw	a5,4(s1)
    80004a72:	02f05263          	blez	a5,80004a96 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a76:	2785                	addiw	a5,a5,1
    80004a78:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a7a:	0023c517          	auipc	a0,0x23c
    80004a7e:	33e50513          	addi	a0,a0,830 # 80240db8 <ftable>
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	35c080e7          	jalr	860(ra) # 80000dde <release>
  return f;
}
    80004a8a:	8526                	mv	a0,s1
    80004a8c:	60e2                	ld	ra,24(sp)
    80004a8e:	6442                	ld	s0,16(sp)
    80004a90:	64a2                	ld	s1,8(sp)
    80004a92:	6105                	addi	sp,sp,32
    80004a94:	8082                	ret
    panic("filedup");
    80004a96:	00004517          	auipc	a0,0x4
    80004a9a:	d2a50513          	addi	a0,a0,-726 # 800087c0 <syscalls+0x268>
    80004a9e:	ffffc097          	auipc	ra,0xffffc
    80004aa2:	a9e080e7          	jalr	-1378(ra) # 8000053c <panic>

0000000080004aa6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004aa6:	7139                	addi	sp,sp,-64
    80004aa8:	fc06                	sd	ra,56(sp)
    80004aaa:	f822                	sd	s0,48(sp)
    80004aac:	f426                	sd	s1,40(sp)
    80004aae:	f04a                	sd	s2,32(sp)
    80004ab0:	ec4e                	sd	s3,24(sp)
    80004ab2:	e852                	sd	s4,16(sp)
    80004ab4:	e456                	sd	s5,8(sp)
    80004ab6:	0080                	addi	s0,sp,64
    80004ab8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004aba:	0023c517          	auipc	a0,0x23c
    80004abe:	2fe50513          	addi	a0,a0,766 # 80240db8 <ftable>
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	268080e7          	jalr	616(ra) # 80000d2a <acquire>
  if(f->ref < 1)
    80004aca:	40dc                	lw	a5,4(s1)
    80004acc:	06f05163          	blez	a5,80004b2e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004ad0:	37fd                	addiw	a5,a5,-1
    80004ad2:	0007871b          	sext.w	a4,a5
    80004ad6:	c0dc                	sw	a5,4(s1)
    80004ad8:	06e04363          	bgtz	a4,80004b3e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004adc:	0004a903          	lw	s2,0(s1)
    80004ae0:	0094ca83          	lbu	s5,9(s1)
    80004ae4:	0104ba03          	ld	s4,16(s1)
    80004ae8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004aec:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004af0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004af4:	0023c517          	auipc	a0,0x23c
    80004af8:	2c450513          	addi	a0,a0,708 # 80240db8 <ftable>
    80004afc:	ffffc097          	auipc	ra,0xffffc
    80004b00:	2e2080e7          	jalr	738(ra) # 80000dde <release>

  if(ff.type == FD_PIPE){
    80004b04:	4785                	li	a5,1
    80004b06:	04f90d63          	beq	s2,a5,80004b60 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b0a:	3979                	addiw	s2,s2,-2
    80004b0c:	4785                	li	a5,1
    80004b0e:	0527e063          	bltu	a5,s2,80004b4e <fileclose+0xa8>
    begin_op();
    80004b12:	00000097          	auipc	ra,0x0
    80004b16:	ad0080e7          	jalr	-1328(ra) # 800045e2 <begin_op>
    iput(ff.ip);
    80004b1a:	854e                	mv	a0,s3
    80004b1c:	fffff097          	auipc	ra,0xfffff
    80004b20:	2da080e7          	jalr	730(ra) # 80003df6 <iput>
    end_op();
    80004b24:	00000097          	auipc	ra,0x0
    80004b28:	b38080e7          	jalr	-1224(ra) # 8000465c <end_op>
    80004b2c:	a00d                	j	80004b4e <fileclose+0xa8>
    panic("fileclose");
    80004b2e:	00004517          	auipc	a0,0x4
    80004b32:	c9a50513          	addi	a0,a0,-870 # 800087c8 <syscalls+0x270>
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	a06080e7          	jalr	-1530(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004b3e:	0023c517          	auipc	a0,0x23c
    80004b42:	27a50513          	addi	a0,a0,634 # 80240db8 <ftable>
    80004b46:	ffffc097          	auipc	ra,0xffffc
    80004b4a:	298080e7          	jalr	664(ra) # 80000dde <release>
  }
}
    80004b4e:	70e2                	ld	ra,56(sp)
    80004b50:	7442                	ld	s0,48(sp)
    80004b52:	74a2                	ld	s1,40(sp)
    80004b54:	7902                	ld	s2,32(sp)
    80004b56:	69e2                	ld	s3,24(sp)
    80004b58:	6a42                	ld	s4,16(sp)
    80004b5a:	6aa2                	ld	s5,8(sp)
    80004b5c:	6121                	addi	sp,sp,64
    80004b5e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b60:	85d6                	mv	a1,s5
    80004b62:	8552                	mv	a0,s4
    80004b64:	00000097          	auipc	ra,0x0
    80004b68:	348080e7          	jalr	840(ra) # 80004eac <pipeclose>
    80004b6c:	b7cd                	j	80004b4e <fileclose+0xa8>

0000000080004b6e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b6e:	715d                	addi	sp,sp,-80
    80004b70:	e486                	sd	ra,72(sp)
    80004b72:	e0a2                	sd	s0,64(sp)
    80004b74:	fc26                	sd	s1,56(sp)
    80004b76:	f84a                	sd	s2,48(sp)
    80004b78:	f44e                	sd	s3,40(sp)
    80004b7a:	0880                	addi	s0,sp,80
    80004b7c:	84aa                	mv	s1,a0
    80004b7e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b80:	ffffd097          	auipc	ra,0xffffd
    80004b84:	0dc080e7          	jalr	220(ra) # 80001c5c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b88:	409c                	lw	a5,0(s1)
    80004b8a:	37f9                	addiw	a5,a5,-2
    80004b8c:	4705                	li	a4,1
    80004b8e:	04f76763          	bltu	a4,a5,80004bdc <filestat+0x6e>
    80004b92:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b94:	6c88                	ld	a0,24(s1)
    80004b96:	fffff097          	auipc	ra,0xfffff
    80004b9a:	0a6080e7          	jalr	166(ra) # 80003c3c <ilock>
    stati(f->ip, &st);
    80004b9e:	fb840593          	addi	a1,s0,-72
    80004ba2:	6c88                	ld	a0,24(s1)
    80004ba4:	fffff097          	auipc	ra,0xfffff
    80004ba8:	322080e7          	jalr	802(ra) # 80003ec6 <stati>
    iunlock(f->ip);
    80004bac:	6c88                	ld	a0,24(s1)
    80004bae:	fffff097          	auipc	ra,0xfffff
    80004bb2:	150080e7          	jalr	336(ra) # 80003cfe <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004bb6:	46e1                	li	a3,24
    80004bb8:	fb840613          	addi	a2,s0,-72
    80004bbc:	85ce                	mv	a1,s3
    80004bbe:	05093503          	ld	a0,80(s2)
    80004bc2:	ffffd097          	auipc	ra,0xffffd
    80004bc6:	be2080e7          	jalr	-1054(ra) # 800017a4 <copyout>
    80004bca:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004bce:	60a6                	ld	ra,72(sp)
    80004bd0:	6406                	ld	s0,64(sp)
    80004bd2:	74e2                	ld	s1,56(sp)
    80004bd4:	7942                	ld	s2,48(sp)
    80004bd6:	79a2                	ld	s3,40(sp)
    80004bd8:	6161                	addi	sp,sp,80
    80004bda:	8082                	ret
  return -1;
    80004bdc:	557d                	li	a0,-1
    80004bde:	bfc5                	j	80004bce <filestat+0x60>

0000000080004be0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004be0:	7179                	addi	sp,sp,-48
    80004be2:	f406                	sd	ra,40(sp)
    80004be4:	f022                	sd	s0,32(sp)
    80004be6:	ec26                	sd	s1,24(sp)
    80004be8:	e84a                	sd	s2,16(sp)
    80004bea:	e44e                	sd	s3,8(sp)
    80004bec:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004bee:	00854783          	lbu	a5,8(a0)
    80004bf2:	c3d5                	beqz	a5,80004c96 <fileread+0xb6>
    80004bf4:	84aa                	mv	s1,a0
    80004bf6:	89ae                	mv	s3,a1
    80004bf8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bfa:	411c                	lw	a5,0(a0)
    80004bfc:	4705                	li	a4,1
    80004bfe:	04e78963          	beq	a5,a4,80004c50 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c02:	470d                	li	a4,3
    80004c04:	04e78d63          	beq	a5,a4,80004c5e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c08:	4709                	li	a4,2
    80004c0a:	06e79e63          	bne	a5,a4,80004c86 <fileread+0xa6>
    ilock(f->ip);
    80004c0e:	6d08                	ld	a0,24(a0)
    80004c10:	fffff097          	auipc	ra,0xfffff
    80004c14:	02c080e7          	jalr	44(ra) # 80003c3c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c18:	874a                	mv	a4,s2
    80004c1a:	5094                	lw	a3,32(s1)
    80004c1c:	864e                	mv	a2,s3
    80004c1e:	4585                	li	a1,1
    80004c20:	6c88                	ld	a0,24(s1)
    80004c22:	fffff097          	auipc	ra,0xfffff
    80004c26:	2ce080e7          	jalr	718(ra) # 80003ef0 <readi>
    80004c2a:	892a                	mv	s2,a0
    80004c2c:	00a05563          	blez	a0,80004c36 <fileread+0x56>
      f->off += r;
    80004c30:	509c                	lw	a5,32(s1)
    80004c32:	9fa9                	addw	a5,a5,a0
    80004c34:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c36:	6c88                	ld	a0,24(s1)
    80004c38:	fffff097          	auipc	ra,0xfffff
    80004c3c:	0c6080e7          	jalr	198(ra) # 80003cfe <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c40:	854a                	mv	a0,s2
    80004c42:	70a2                	ld	ra,40(sp)
    80004c44:	7402                	ld	s0,32(sp)
    80004c46:	64e2                	ld	s1,24(sp)
    80004c48:	6942                	ld	s2,16(sp)
    80004c4a:	69a2                	ld	s3,8(sp)
    80004c4c:	6145                	addi	sp,sp,48
    80004c4e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c50:	6908                	ld	a0,16(a0)
    80004c52:	00000097          	auipc	ra,0x0
    80004c56:	3c2080e7          	jalr	962(ra) # 80005014 <piperead>
    80004c5a:	892a                	mv	s2,a0
    80004c5c:	b7d5                	j	80004c40 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c5e:	02451783          	lh	a5,36(a0)
    80004c62:	03079693          	slli	a3,a5,0x30
    80004c66:	92c1                	srli	a3,a3,0x30
    80004c68:	4725                	li	a4,9
    80004c6a:	02d76863          	bltu	a4,a3,80004c9a <fileread+0xba>
    80004c6e:	0792                	slli	a5,a5,0x4
    80004c70:	0023c717          	auipc	a4,0x23c
    80004c74:	0a870713          	addi	a4,a4,168 # 80240d18 <devsw>
    80004c78:	97ba                	add	a5,a5,a4
    80004c7a:	639c                	ld	a5,0(a5)
    80004c7c:	c38d                	beqz	a5,80004c9e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c7e:	4505                	li	a0,1
    80004c80:	9782                	jalr	a5
    80004c82:	892a                	mv	s2,a0
    80004c84:	bf75                	j	80004c40 <fileread+0x60>
    panic("fileread");
    80004c86:	00004517          	auipc	a0,0x4
    80004c8a:	b5250513          	addi	a0,a0,-1198 # 800087d8 <syscalls+0x280>
    80004c8e:	ffffc097          	auipc	ra,0xffffc
    80004c92:	8ae080e7          	jalr	-1874(ra) # 8000053c <panic>
    return -1;
    80004c96:	597d                	li	s2,-1
    80004c98:	b765                	j	80004c40 <fileread+0x60>
      return -1;
    80004c9a:	597d                	li	s2,-1
    80004c9c:	b755                	j	80004c40 <fileread+0x60>
    80004c9e:	597d                	li	s2,-1
    80004ca0:	b745                	j	80004c40 <fileread+0x60>

0000000080004ca2 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004ca2:	00954783          	lbu	a5,9(a0)
    80004ca6:	10078e63          	beqz	a5,80004dc2 <filewrite+0x120>
{
    80004caa:	715d                	addi	sp,sp,-80
    80004cac:	e486                	sd	ra,72(sp)
    80004cae:	e0a2                	sd	s0,64(sp)
    80004cb0:	fc26                	sd	s1,56(sp)
    80004cb2:	f84a                	sd	s2,48(sp)
    80004cb4:	f44e                	sd	s3,40(sp)
    80004cb6:	f052                	sd	s4,32(sp)
    80004cb8:	ec56                	sd	s5,24(sp)
    80004cba:	e85a                	sd	s6,16(sp)
    80004cbc:	e45e                	sd	s7,8(sp)
    80004cbe:	e062                	sd	s8,0(sp)
    80004cc0:	0880                	addi	s0,sp,80
    80004cc2:	892a                	mv	s2,a0
    80004cc4:	8b2e                	mv	s6,a1
    80004cc6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cc8:	411c                	lw	a5,0(a0)
    80004cca:	4705                	li	a4,1
    80004ccc:	02e78263          	beq	a5,a4,80004cf0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cd0:	470d                	li	a4,3
    80004cd2:	02e78563          	beq	a5,a4,80004cfc <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cd6:	4709                	li	a4,2
    80004cd8:	0ce79d63          	bne	a5,a4,80004db2 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004cdc:	0ac05b63          	blez	a2,80004d92 <filewrite+0xf0>
    int i = 0;
    80004ce0:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004ce2:	6b85                	lui	s7,0x1
    80004ce4:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004ce8:	6c05                	lui	s8,0x1
    80004cea:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004cee:	a851                	j	80004d82 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004cf0:	6908                	ld	a0,16(a0)
    80004cf2:	00000097          	auipc	ra,0x0
    80004cf6:	22a080e7          	jalr	554(ra) # 80004f1c <pipewrite>
    80004cfa:	a045                	j	80004d9a <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004cfc:	02451783          	lh	a5,36(a0)
    80004d00:	03079693          	slli	a3,a5,0x30
    80004d04:	92c1                	srli	a3,a3,0x30
    80004d06:	4725                	li	a4,9
    80004d08:	0ad76f63          	bltu	a4,a3,80004dc6 <filewrite+0x124>
    80004d0c:	0792                	slli	a5,a5,0x4
    80004d0e:	0023c717          	auipc	a4,0x23c
    80004d12:	00a70713          	addi	a4,a4,10 # 80240d18 <devsw>
    80004d16:	97ba                	add	a5,a5,a4
    80004d18:	679c                	ld	a5,8(a5)
    80004d1a:	cbc5                	beqz	a5,80004dca <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004d1c:	4505                	li	a0,1
    80004d1e:	9782                	jalr	a5
    80004d20:	a8ad                	j	80004d9a <filewrite+0xf8>
      if(n1 > max)
    80004d22:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004d26:	00000097          	auipc	ra,0x0
    80004d2a:	8bc080e7          	jalr	-1860(ra) # 800045e2 <begin_op>
      ilock(f->ip);
    80004d2e:	01893503          	ld	a0,24(s2)
    80004d32:	fffff097          	auipc	ra,0xfffff
    80004d36:	f0a080e7          	jalr	-246(ra) # 80003c3c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d3a:	8756                	mv	a4,s5
    80004d3c:	02092683          	lw	a3,32(s2)
    80004d40:	01698633          	add	a2,s3,s6
    80004d44:	4585                	li	a1,1
    80004d46:	01893503          	ld	a0,24(s2)
    80004d4a:	fffff097          	auipc	ra,0xfffff
    80004d4e:	29e080e7          	jalr	670(ra) # 80003fe8 <writei>
    80004d52:	84aa                	mv	s1,a0
    80004d54:	00a05763          	blez	a0,80004d62 <filewrite+0xc0>
        f->off += r;
    80004d58:	02092783          	lw	a5,32(s2)
    80004d5c:	9fa9                	addw	a5,a5,a0
    80004d5e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d62:	01893503          	ld	a0,24(s2)
    80004d66:	fffff097          	auipc	ra,0xfffff
    80004d6a:	f98080e7          	jalr	-104(ra) # 80003cfe <iunlock>
      end_op();
    80004d6e:	00000097          	auipc	ra,0x0
    80004d72:	8ee080e7          	jalr	-1810(ra) # 8000465c <end_op>

      if(r != n1){
    80004d76:	009a9f63          	bne	s5,s1,80004d94 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004d7a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d7e:	0149db63          	bge	s3,s4,80004d94 <filewrite+0xf2>
      int n1 = n - i;
    80004d82:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004d86:	0004879b          	sext.w	a5,s1
    80004d8a:	f8fbdce3          	bge	s7,a5,80004d22 <filewrite+0x80>
    80004d8e:	84e2                	mv	s1,s8
    80004d90:	bf49                	j	80004d22 <filewrite+0x80>
    int i = 0;
    80004d92:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d94:	033a1d63          	bne	s4,s3,80004dce <filewrite+0x12c>
    80004d98:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d9a:	60a6                	ld	ra,72(sp)
    80004d9c:	6406                	ld	s0,64(sp)
    80004d9e:	74e2                	ld	s1,56(sp)
    80004da0:	7942                	ld	s2,48(sp)
    80004da2:	79a2                	ld	s3,40(sp)
    80004da4:	7a02                	ld	s4,32(sp)
    80004da6:	6ae2                	ld	s5,24(sp)
    80004da8:	6b42                	ld	s6,16(sp)
    80004daa:	6ba2                	ld	s7,8(sp)
    80004dac:	6c02                	ld	s8,0(sp)
    80004dae:	6161                	addi	sp,sp,80
    80004db0:	8082                	ret
    panic("filewrite");
    80004db2:	00004517          	auipc	a0,0x4
    80004db6:	a3650513          	addi	a0,a0,-1482 # 800087e8 <syscalls+0x290>
    80004dba:	ffffb097          	auipc	ra,0xffffb
    80004dbe:	782080e7          	jalr	1922(ra) # 8000053c <panic>
    return -1;
    80004dc2:	557d                	li	a0,-1
}
    80004dc4:	8082                	ret
      return -1;
    80004dc6:	557d                	li	a0,-1
    80004dc8:	bfc9                	j	80004d9a <filewrite+0xf8>
    80004dca:	557d                	li	a0,-1
    80004dcc:	b7f9                	j	80004d9a <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004dce:	557d                	li	a0,-1
    80004dd0:	b7e9                	j	80004d9a <filewrite+0xf8>

0000000080004dd2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004dd2:	7179                	addi	sp,sp,-48
    80004dd4:	f406                	sd	ra,40(sp)
    80004dd6:	f022                	sd	s0,32(sp)
    80004dd8:	ec26                	sd	s1,24(sp)
    80004dda:	e84a                	sd	s2,16(sp)
    80004ddc:	e44e                	sd	s3,8(sp)
    80004dde:	e052                	sd	s4,0(sp)
    80004de0:	1800                	addi	s0,sp,48
    80004de2:	84aa                	mv	s1,a0
    80004de4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004de6:	0005b023          	sd	zero,0(a1)
    80004dea:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004dee:	00000097          	auipc	ra,0x0
    80004df2:	bfc080e7          	jalr	-1028(ra) # 800049ea <filealloc>
    80004df6:	e088                	sd	a0,0(s1)
    80004df8:	c551                	beqz	a0,80004e84 <pipealloc+0xb2>
    80004dfa:	00000097          	auipc	ra,0x0
    80004dfe:	bf0080e7          	jalr	-1040(ra) # 800049ea <filealloc>
    80004e02:	00aa3023          	sd	a0,0(s4)
    80004e06:	c92d                	beqz	a0,80004e78 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e08:	ffffc097          	auipc	ra,0xffffc
    80004e0c:	d82080e7          	jalr	-638(ra) # 80000b8a <kalloc>
    80004e10:	892a                	mv	s2,a0
    80004e12:	c125                	beqz	a0,80004e72 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e14:	4985                	li	s3,1
    80004e16:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e1a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e1e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e22:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e26:	00004597          	auipc	a1,0x4
    80004e2a:	9d258593          	addi	a1,a1,-1582 # 800087f8 <syscalls+0x2a0>
    80004e2e:	ffffc097          	auipc	ra,0xffffc
    80004e32:	e6c080e7          	jalr	-404(ra) # 80000c9a <initlock>
  (*f0)->type = FD_PIPE;
    80004e36:	609c                	ld	a5,0(s1)
    80004e38:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e3c:	609c                	ld	a5,0(s1)
    80004e3e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e42:	609c                	ld	a5,0(s1)
    80004e44:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e48:	609c                	ld	a5,0(s1)
    80004e4a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e4e:	000a3783          	ld	a5,0(s4)
    80004e52:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e56:	000a3783          	ld	a5,0(s4)
    80004e5a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e5e:	000a3783          	ld	a5,0(s4)
    80004e62:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e66:	000a3783          	ld	a5,0(s4)
    80004e6a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e6e:	4501                	li	a0,0
    80004e70:	a025                	j	80004e98 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e72:	6088                	ld	a0,0(s1)
    80004e74:	e501                	bnez	a0,80004e7c <pipealloc+0xaa>
    80004e76:	a039                	j	80004e84 <pipealloc+0xb2>
    80004e78:	6088                	ld	a0,0(s1)
    80004e7a:	c51d                	beqz	a0,80004ea8 <pipealloc+0xd6>
    fileclose(*f0);
    80004e7c:	00000097          	auipc	ra,0x0
    80004e80:	c2a080e7          	jalr	-982(ra) # 80004aa6 <fileclose>
  if(*f1)
    80004e84:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e88:	557d                	li	a0,-1
  if(*f1)
    80004e8a:	c799                	beqz	a5,80004e98 <pipealloc+0xc6>
    fileclose(*f1);
    80004e8c:	853e                	mv	a0,a5
    80004e8e:	00000097          	auipc	ra,0x0
    80004e92:	c18080e7          	jalr	-1000(ra) # 80004aa6 <fileclose>
  return -1;
    80004e96:	557d                	li	a0,-1
}
    80004e98:	70a2                	ld	ra,40(sp)
    80004e9a:	7402                	ld	s0,32(sp)
    80004e9c:	64e2                	ld	s1,24(sp)
    80004e9e:	6942                	ld	s2,16(sp)
    80004ea0:	69a2                	ld	s3,8(sp)
    80004ea2:	6a02                	ld	s4,0(sp)
    80004ea4:	6145                	addi	sp,sp,48
    80004ea6:	8082                	ret
  return -1;
    80004ea8:	557d                	li	a0,-1
    80004eaa:	b7fd                	j	80004e98 <pipealloc+0xc6>

0000000080004eac <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004eac:	1101                	addi	sp,sp,-32
    80004eae:	ec06                	sd	ra,24(sp)
    80004eb0:	e822                	sd	s0,16(sp)
    80004eb2:	e426                	sd	s1,8(sp)
    80004eb4:	e04a                	sd	s2,0(sp)
    80004eb6:	1000                	addi	s0,sp,32
    80004eb8:	84aa                	mv	s1,a0
    80004eba:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ebc:	ffffc097          	auipc	ra,0xffffc
    80004ec0:	e6e080e7          	jalr	-402(ra) # 80000d2a <acquire>
  if(writable){
    80004ec4:	02090d63          	beqz	s2,80004efe <pipeclose+0x52>
    pi->writeopen = 0;
    80004ec8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ecc:	21848513          	addi	a0,s1,536
    80004ed0:	ffffd097          	auipc	ra,0xffffd
    80004ed4:	558080e7          	jalr	1368(ra) # 80002428 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ed8:	2204b783          	ld	a5,544(s1)
    80004edc:	eb95                	bnez	a5,80004f10 <pipeclose+0x64>
    release(&pi->lock);
    80004ede:	8526                	mv	a0,s1
    80004ee0:	ffffc097          	auipc	ra,0xffffc
    80004ee4:	efe080e7          	jalr	-258(ra) # 80000dde <release>
    kfree((char*)pi);
    80004ee8:	8526                	mv	a0,s1
    80004eea:	ffffc097          	auipc	ra,0xffffc
    80004eee:	b0c080e7          	jalr	-1268(ra) # 800009f6 <kfree>
  } else
    release(&pi->lock);
}
    80004ef2:	60e2                	ld	ra,24(sp)
    80004ef4:	6442                	ld	s0,16(sp)
    80004ef6:	64a2                	ld	s1,8(sp)
    80004ef8:	6902                	ld	s2,0(sp)
    80004efa:	6105                	addi	sp,sp,32
    80004efc:	8082                	ret
    pi->readopen = 0;
    80004efe:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f02:	21c48513          	addi	a0,s1,540
    80004f06:	ffffd097          	auipc	ra,0xffffd
    80004f0a:	522080e7          	jalr	1314(ra) # 80002428 <wakeup>
    80004f0e:	b7e9                	j	80004ed8 <pipeclose+0x2c>
    release(&pi->lock);
    80004f10:	8526                	mv	a0,s1
    80004f12:	ffffc097          	auipc	ra,0xffffc
    80004f16:	ecc080e7          	jalr	-308(ra) # 80000dde <release>
}
    80004f1a:	bfe1                	j	80004ef2 <pipeclose+0x46>

0000000080004f1c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f1c:	711d                	addi	sp,sp,-96
    80004f1e:	ec86                	sd	ra,88(sp)
    80004f20:	e8a2                	sd	s0,80(sp)
    80004f22:	e4a6                	sd	s1,72(sp)
    80004f24:	e0ca                	sd	s2,64(sp)
    80004f26:	fc4e                	sd	s3,56(sp)
    80004f28:	f852                	sd	s4,48(sp)
    80004f2a:	f456                	sd	s5,40(sp)
    80004f2c:	f05a                	sd	s6,32(sp)
    80004f2e:	ec5e                	sd	s7,24(sp)
    80004f30:	e862                	sd	s8,16(sp)
    80004f32:	1080                	addi	s0,sp,96
    80004f34:	84aa                	mv	s1,a0
    80004f36:	8aae                	mv	s5,a1
    80004f38:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f3a:	ffffd097          	auipc	ra,0xffffd
    80004f3e:	d22080e7          	jalr	-734(ra) # 80001c5c <myproc>
    80004f42:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f44:	8526                	mv	a0,s1
    80004f46:	ffffc097          	auipc	ra,0xffffc
    80004f4a:	de4080e7          	jalr	-540(ra) # 80000d2a <acquire>
  while(i < n){
    80004f4e:	0b405663          	blez	s4,80004ffa <pipewrite+0xde>
  int i = 0;
    80004f52:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f54:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f56:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f5a:	21c48b93          	addi	s7,s1,540
    80004f5e:	a089                	j	80004fa0 <pipewrite+0x84>
      release(&pi->lock);
    80004f60:	8526                	mv	a0,s1
    80004f62:	ffffc097          	auipc	ra,0xffffc
    80004f66:	e7c080e7          	jalr	-388(ra) # 80000dde <release>
      return -1;
    80004f6a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f6c:	854a                	mv	a0,s2
    80004f6e:	60e6                	ld	ra,88(sp)
    80004f70:	6446                	ld	s0,80(sp)
    80004f72:	64a6                	ld	s1,72(sp)
    80004f74:	6906                	ld	s2,64(sp)
    80004f76:	79e2                	ld	s3,56(sp)
    80004f78:	7a42                	ld	s4,48(sp)
    80004f7a:	7aa2                	ld	s5,40(sp)
    80004f7c:	7b02                	ld	s6,32(sp)
    80004f7e:	6be2                	ld	s7,24(sp)
    80004f80:	6c42                	ld	s8,16(sp)
    80004f82:	6125                	addi	sp,sp,96
    80004f84:	8082                	ret
      wakeup(&pi->nread);
    80004f86:	8562                	mv	a0,s8
    80004f88:	ffffd097          	auipc	ra,0xffffd
    80004f8c:	4a0080e7          	jalr	1184(ra) # 80002428 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f90:	85a6                	mv	a1,s1
    80004f92:	855e                	mv	a0,s7
    80004f94:	ffffd097          	auipc	ra,0xffffd
    80004f98:	430080e7          	jalr	1072(ra) # 800023c4 <sleep>
  while(i < n){
    80004f9c:	07495063          	bge	s2,s4,80004ffc <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004fa0:	2204a783          	lw	a5,544(s1)
    80004fa4:	dfd5                	beqz	a5,80004f60 <pipewrite+0x44>
    80004fa6:	854e                	mv	a0,s3
    80004fa8:	ffffd097          	auipc	ra,0xffffd
    80004fac:	6c4080e7          	jalr	1732(ra) # 8000266c <killed>
    80004fb0:	f945                	bnez	a0,80004f60 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004fb2:	2184a783          	lw	a5,536(s1)
    80004fb6:	21c4a703          	lw	a4,540(s1)
    80004fba:	2007879b          	addiw	a5,a5,512
    80004fbe:	fcf704e3          	beq	a4,a5,80004f86 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fc2:	4685                	li	a3,1
    80004fc4:	01590633          	add	a2,s2,s5
    80004fc8:	faf40593          	addi	a1,s0,-81
    80004fcc:	0509b503          	ld	a0,80(s3)
    80004fd0:	ffffd097          	auipc	ra,0xffffd
    80004fd4:	860080e7          	jalr	-1952(ra) # 80001830 <copyin>
    80004fd8:	03650263          	beq	a0,s6,80004ffc <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004fdc:	21c4a783          	lw	a5,540(s1)
    80004fe0:	0017871b          	addiw	a4,a5,1
    80004fe4:	20e4ae23          	sw	a4,540(s1)
    80004fe8:	1ff7f793          	andi	a5,a5,511
    80004fec:	97a6                	add	a5,a5,s1
    80004fee:	faf44703          	lbu	a4,-81(s0)
    80004ff2:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ff6:	2905                	addiw	s2,s2,1
    80004ff8:	b755                	j	80004f9c <pipewrite+0x80>
  int i = 0;
    80004ffa:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ffc:	21848513          	addi	a0,s1,536
    80005000:	ffffd097          	auipc	ra,0xffffd
    80005004:	428080e7          	jalr	1064(ra) # 80002428 <wakeup>
  release(&pi->lock);
    80005008:	8526                	mv	a0,s1
    8000500a:	ffffc097          	auipc	ra,0xffffc
    8000500e:	dd4080e7          	jalr	-556(ra) # 80000dde <release>
  return i;
    80005012:	bfa9                	j	80004f6c <pipewrite+0x50>

0000000080005014 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005014:	715d                	addi	sp,sp,-80
    80005016:	e486                	sd	ra,72(sp)
    80005018:	e0a2                	sd	s0,64(sp)
    8000501a:	fc26                	sd	s1,56(sp)
    8000501c:	f84a                	sd	s2,48(sp)
    8000501e:	f44e                	sd	s3,40(sp)
    80005020:	f052                	sd	s4,32(sp)
    80005022:	ec56                	sd	s5,24(sp)
    80005024:	e85a                	sd	s6,16(sp)
    80005026:	0880                	addi	s0,sp,80
    80005028:	84aa                	mv	s1,a0
    8000502a:	892e                	mv	s2,a1
    8000502c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000502e:	ffffd097          	auipc	ra,0xffffd
    80005032:	c2e080e7          	jalr	-978(ra) # 80001c5c <myproc>
    80005036:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005038:	8526                	mv	a0,s1
    8000503a:	ffffc097          	auipc	ra,0xffffc
    8000503e:	cf0080e7          	jalr	-784(ra) # 80000d2a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005042:	2184a703          	lw	a4,536(s1)
    80005046:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000504a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000504e:	02f71763          	bne	a4,a5,8000507c <piperead+0x68>
    80005052:	2244a783          	lw	a5,548(s1)
    80005056:	c39d                	beqz	a5,8000507c <piperead+0x68>
    if(killed(pr)){
    80005058:	8552                	mv	a0,s4
    8000505a:	ffffd097          	auipc	ra,0xffffd
    8000505e:	612080e7          	jalr	1554(ra) # 8000266c <killed>
    80005062:	e949                	bnez	a0,800050f4 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005064:	85a6                	mv	a1,s1
    80005066:	854e                	mv	a0,s3
    80005068:	ffffd097          	auipc	ra,0xffffd
    8000506c:	35c080e7          	jalr	860(ra) # 800023c4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005070:	2184a703          	lw	a4,536(s1)
    80005074:	21c4a783          	lw	a5,540(s1)
    80005078:	fcf70de3          	beq	a4,a5,80005052 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000507c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000507e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005080:	05505463          	blez	s5,800050c8 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005084:	2184a783          	lw	a5,536(s1)
    80005088:	21c4a703          	lw	a4,540(s1)
    8000508c:	02f70e63          	beq	a4,a5,800050c8 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005090:	0017871b          	addiw	a4,a5,1
    80005094:	20e4ac23          	sw	a4,536(s1)
    80005098:	1ff7f793          	andi	a5,a5,511
    8000509c:	97a6                	add	a5,a5,s1
    8000509e:	0187c783          	lbu	a5,24(a5)
    800050a2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050a6:	4685                	li	a3,1
    800050a8:	fbf40613          	addi	a2,s0,-65
    800050ac:	85ca                	mv	a1,s2
    800050ae:	050a3503          	ld	a0,80(s4)
    800050b2:	ffffc097          	auipc	ra,0xffffc
    800050b6:	6f2080e7          	jalr	1778(ra) # 800017a4 <copyout>
    800050ba:	01650763          	beq	a0,s6,800050c8 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050be:	2985                	addiw	s3,s3,1
    800050c0:	0905                	addi	s2,s2,1
    800050c2:	fd3a91e3          	bne	s5,s3,80005084 <piperead+0x70>
    800050c6:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050c8:	21c48513          	addi	a0,s1,540
    800050cc:	ffffd097          	auipc	ra,0xffffd
    800050d0:	35c080e7          	jalr	860(ra) # 80002428 <wakeup>
  release(&pi->lock);
    800050d4:	8526                	mv	a0,s1
    800050d6:	ffffc097          	auipc	ra,0xffffc
    800050da:	d08080e7          	jalr	-760(ra) # 80000dde <release>
  return i;
}
    800050de:	854e                	mv	a0,s3
    800050e0:	60a6                	ld	ra,72(sp)
    800050e2:	6406                	ld	s0,64(sp)
    800050e4:	74e2                	ld	s1,56(sp)
    800050e6:	7942                	ld	s2,48(sp)
    800050e8:	79a2                	ld	s3,40(sp)
    800050ea:	7a02                	ld	s4,32(sp)
    800050ec:	6ae2                	ld	s5,24(sp)
    800050ee:	6b42                	ld	s6,16(sp)
    800050f0:	6161                	addi	sp,sp,80
    800050f2:	8082                	ret
      release(&pi->lock);
    800050f4:	8526                	mv	a0,s1
    800050f6:	ffffc097          	auipc	ra,0xffffc
    800050fa:	ce8080e7          	jalr	-792(ra) # 80000dde <release>
      return -1;
    800050fe:	59fd                	li	s3,-1
    80005100:	bff9                	j	800050de <piperead+0xca>

0000000080005102 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005102:	1141                	addi	sp,sp,-16
    80005104:	e422                	sd	s0,8(sp)
    80005106:	0800                	addi	s0,sp,16
    80005108:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000510a:	8905                	andi	a0,a0,1
    8000510c:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000510e:	8b89                	andi	a5,a5,2
    80005110:	c399                	beqz	a5,80005116 <flags2perm+0x14>
      perm |= PTE_W;
    80005112:	00456513          	ori	a0,a0,4
    return perm;
}
    80005116:	6422                	ld	s0,8(sp)
    80005118:	0141                	addi	sp,sp,16
    8000511a:	8082                	ret

000000008000511c <exec>:

int
exec(char *path, char **argv)
{
    8000511c:	df010113          	addi	sp,sp,-528
    80005120:	20113423          	sd	ra,520(sp)
    80005124:	20813023          	sd	s0,512(sp)
    80005128:	ffa6                	sd	s1,504(sp)
    8000512a:	fbca                	sd	s2,496(sp)
    8000512c:	f7ce                	sd	s3,488(sp)
    8000512e:	f3d2                	sd	s4,480(sp)
    80005130:	efd6                	sd	s5,472(sp)
    80005132:	ebda                	sd	s6,464(sp)
    80005134:	e7de                	sd	s7,456(sp)
    80005136:	e3e2                	sd	s8,448(sp)
    80005138:	ff66                	sd	s9,440(sp)
    8000513a:	fb6a                	sd	s10,432(sp)
    8000513c:	f76e                	sd	s11,424(sp)
    8000513e:	0c00                	addi	s0,sp,528
    80005140:	892a                	mv	s2,a0
    80005142:	dea43c23          	sd	a0,-520(s0)
    80005146:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000514a:	ffffd097          	auipc	ra,0xffffd
    8000514e:	b12080e7          	jalr	-1262(ra) # 80001c5c <myproc>
    80005152:	84aa                	mv	s1,a0

  begin_op();
    80005154:	fffff097          	auipc	ra,0xfffff
    80005158:	48e080e7          	jalr	1166(ra) # 800045e2 <begin_op>

  if((ip = namei(path)) == 0){
    8000515c:	854a                	mv	a0,s2
    8000515e:	fffff097          	auipc	ra,0xfffff
    80005162:	284080e7          	jalr	644(ra) # 800043e2 <namei>
    80005166:	c92d                	beqz	a0,800051d8 <exec+0xbc>
    80005168:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000516a:	fffff097          	auipc	ra,0xfffff
    8000516e:	ad2080e7          	jalr	-1326(ra) # 80003c3c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005172:	04000713          	li	a4,64
    80005176:	4681                	li	a3,0
    80005178:	e5040613          	addi	a2,s0,-432
    8000517c:	4581                	li	a1,0
    8000517e:	8552                	mv	a0,s4
    80005180:	fffff097          	auipc	ra,0xfffff
    80005184:	d70080e7          	jalr	-656(ra) # 80003ef0 <readi>
    80005188:	04000793          	li	a5,64
    8000518c:	00f51a63          	bne	a0,a5,800051a0 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005190:	e5042703          	lw	a4,-432(s0)
    80005194:	464c47b7          	lui	a5,0x464c4
    80005198:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000519c:	04f70463          	beq	a4,a5,800051e4 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800051a0:	8552                	mv	a0,s4
    800051a2:	fffff097          	auipc	ra,0xfffff
    800051a6:	cfc080e7          	jalr	-772(ra) # 80003e9e <iunlockput>
    end_op();
    800051aa:	fffff097          	auipc	ra,0xfffff
    800051ae:	4b2080e7          	jalr	1202(ra) # 8000465c <end_op>
  }
  return -1;
    800051b2:	557d                	li	a0,-1
}
    800051b4:	20813083          	ld	ra,520(sp)
    800051b8:	20013403          	ld	s0,512(sp)
    800051bc:	74fe                	ld	s1,504(sp)
    800051be:	795e                	ld	s2,496(sp)
    800051c0:	79be                	ld	s3,488(sp)
    800051c2:	7a1e                	ld	s4,480(sp)
    800051c4:	6afe                	ld	s5,472(sp)
    800051c6:	6b5e                	ld	s6,464(sp)
    800051c8:	6bbe                	ld	s7,456(sp)
    800051ca:	6c1e                	ld	s8,448(sp)
    800051cc:	7cfa                	ld	s9,440(sp)
    800051ce:	7d5a                	ld	s10,432(sp)
    800051d0:	7dba                	ld	s11,424(sp)
    800051d2:	21010113          	addi	sp,sp,528
    800051d6:	8082                	ret
    end_op();
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	484080e7          	jalr	1156(ra) # 8000465c <end_op>
    return -1;
    800051e0:	557d                	li	a0,-1
    800051e2:	bfc9                	j	800051b4 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800051e4:	8526                	mv	a0,s1
    800051e6:	ffffd097          	auipc	ra,0xffffd
    800051ea:	b3a080e7          	jalr	-1222(ra) # 80001d20 <proc_pagetable>
    800051ee:	8b2a                	mv	s6,a0
    800051f0:	d945                	beqz	a0,800051a0 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051f2:	e7042d03          	lw	s10,-400(s0)
    800051f6:	e8845783          	lhu	a5,-376(s0)
    800051fa:	10078463          	beqz	a5,80005302 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051fe:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005200:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005202:	6c85                	lui	s9,0x1
    80005204:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005208:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    8000520c:	6a85                	lui	s5,0x1
    8000520e:	a0b5                	j	8000527a <exec+0x15e>
      panic("loadseg: address should exist");
    80005210:	00003517          	auipc	a0,0x3
    80005214:	5f050513          	addi	a0,a0,1520 # 80008800 <syscalls+0x2a8>
    80005218:	ffffb097          	auipc	ra,0xffffb
    8000521c:	324080e7          	jalr	804(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80005220:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005222:	8726                	mv	a4,s1
    80005224:	012c06bb          	addw	a3,s8,s2
    80005228:	4581                	li	a1,0
    8000522a:	8552                	mv	a0,s4
    8000522c:	fffff097          	auipc	ra,0xfffff
    80005230:	cc4080e7          	jalr	-828(ra) # 80003ef0 <readi>
    80005234:	2501                	sext.w	a0,a0
    80005236:	24a49863          	bne	s1,a0,80005486 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    8000523a:	012a893b          	addw	s2,s5,s2
    8000523e:	03397563          	bgeu	s2,s3,80005268 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80005242:	02091593          	slli	a1,s2,0x20
    80005246:	9181                	srli	a1,a1,0x20
    80005248:	95de                	add	a1,a1,s7
    8000524a:	855a                	mv	a0,s6
    8000524c:	ffffc097          	auipc	ra,0xffffc
    80005250:	f62080e7          	jalr	-158(ra) # 800011ae <walkaddr>
    80005254:	862a                	mv	a2,a0
    if(pa == 0)
    80005256:	dd4d                	beqz	a0,80005210 <exec+0xf4>
    if(sz - i < PGSIZE)
    80005258:	412984bb          	subw	s1,s3,s2
    8000525c:	0004879b          	sext.w	a5,s1
    80005260:	fcfcf0e3          	bgeu	s9,a5,80005220 <exec+0x104>
    80005264:	84d6                	mv	s1,s5
    80005266:	bf6d                	j	80005220 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005268:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000526c:	2d85                	addiw	s11,s11,1
    8000526e:	038d0d1b          	addiw	s10,s10,56
    80005272:	e8845783          	lhu	a5,-376(s0)
    80005276:	08fdd763          	bge	s11,a5,80005304 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000527a:	2d01                	sext.w	s10,s10
    8000527c:	03800713          	li	a4,56
    80005280:	86ea                	mv	a3,s10
    80005282:	e1840613          	addi	a2,s0,-488
    80005286:	4581                	li	a1,0
    80005288:	8552                	mv	a0,s4
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	c66080e7          	jalr	-922(ra) # 80003ef0 <readi>
    80005292:	03800793          	li	a5,56
    80005296:	1ef51663          	bne	a0,a5,80005482 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    8000529a:	e1842783          	lw	a5,-488(s0)
    8000529e:	4705                	li	a4,1
    800052a0:	fce796e3          	bne	a5,a4,8000526c <exec+0x150>
    if(ph.memsz < ph.filesz)
    800052a4:	e4043483          	ld	s1,-448(s0)
    800052a8:	e3843783          	ld	a5,-456(s0)
    800052ac:	1ef4e863          	bltu	s1,a5,8000549c <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800052b0:	e2843783          	ld	a5,-472(s0)
    800052b4:	94be                	add	s1,s1,a5
    800052b6:	1ef4e663          	bltu	s1,a5,800054a2 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    800052ba:	df043703          	ld	a4,-528(s0)
    800052be:	8ff9                	and	a5,a5,a4
    800052c0:	1e079463          	bnez	a5,800054a8 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800052c4:	e1c42503          	lw	a0,-484(s0)
    800052c8:	00000097          	auipc	ra,0x0
    800052cc:	e3a080e7          	jalr	-454(ra) # 80005102 <flags2perm>
    800052d0:	86aa                	mv	a3,a0
    800052d2:	8626                	mv	a2,s1
    800052d4:	85ca                	mv	a1,s2
    800052d6:	855a                	mv	a0,s6
    800052d8:	ffffc097          	auipc	ra,0xffffc
    800052dc:	28a080e7          	jalr	650(ra) # 80001562 <uvmalloc>
    800052e0:	e0a43423          	sd	a0,-504(s0)
    800052e4:	1c050563          	beqz	a0,800054ae <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800052e8:	e2843b83          	ld	s7,-472(s0)
    800052ec:	e2042c03          	lw	s8,-480(s0)
    800052f0:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800052f4:	00098463          	beqz	s3,800052fc <exec+0x1e0>
    800052f8:	4901                	li	s2,0
    800052fa:	b7a1                	j	80005242 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800052fc:	e0843903          	ld	s2,-504(s0)
    80005300:	b7b5                	j	8000526c <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005302:	4901                	li	s2,0
  iunlockput(ip);
    80005304:	8552                	mv	a0,s4
    80005306:	fffff097          	auipc	ra,0xfffff
    8000530a:	b98080e7          	jalr	-1128(ra) # 80003e9e <iunlockput>
  end_op();
    8000530e:	fffff097          	auipc	ra,0xfffff
    80005312:	34e080e7          	jalr	846(ra) # 8000465c <end_op>
  p = myproc();
    80005316:	ffffd097          	auipc	ra,0xffffd
    8000531a:	946080e7          	jalr	-1722(ra) # 80001c5c <myproc>
    8000531e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005320:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005324:	6985                	lui	s3,0x1
    80005326:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80005328:	99ca                	add	s3,s3,s2
    8000532a:	77fd                	lui	a5,0xfffff
    8000532c:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005330:	4691                	li	a3,4
    80005332:	6609                	lui	a2,0x2
    80005334:	964e                	add	a2,a2,s3
    80005336:	85ce                	mv	a1,s3
    80005338:	855a                	mv	a0,s6
    8000533a:	ffffc097          	auipc	ra,0xffffc
    8000533e:	228080e7          	jalr	552(ra) # 80001562 <uvmalloc>
    80005342:	892a                	mv	s2,a0
    80005344:	e0a43423          	sd	a0,-504(s0)
    80005348:	e509                	bnez	a0,80005352 <exec+0x236>
  if(pagetable)
    8000534a:	e1343423          	sd	s3,-504(s0)
    8000534e:	4a01                	li	s4,0
    80005350:	aa1d                	j	80005486 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005352:	75f9                	lui	a1,0xffffe
    80005354:	95aa                	add	a1,a1,a0
    80005356:	855a                	mv	a0,s6
    80005358:	ffffc097          	auipc	ra,0xffffc
    8000535c:	41a080e7          	jalr	1050(ra) # 80001772 <uvmclear>
  stackbase = sp - PGSIZE;
    80005360:	7bfd                	lui	s7,0xfffff
    80005362:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80005364:	e0043783          	ld	a5,-512(s0)
    80005368:	6388                	ld	a0,0(a5)
    8000536a:	c52d                	beqz	a0,800053d4 <exec+0x2b8>
    8000536c:	e9040993          	addi	s3,s0,-368
    80005370:	f9040c13          	addi	s8,s0,-112
    80005374:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005376:	ffffc097          	auipc	ra,0xffffc
    8000537a:	c2a080e7          	jalr	-982(ra) # 80000fa0 <strlen>
    8000537e:	0015079b          	addiw	a5,a0,1
    80005382:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005386:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    8000538a:	13796563          	bltu	s2,s7,800054b4 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000538e:	e0043d03          	ld	s10,-512(s0)
    80005392:	000d3a03          	ld	s4,0(s10)
    80005396:	8552                	mv	a0,s4
    80005398:	ffffc097          	auipc	ra,0xffffc
    8000539c:	c08080e7          	jalr	-1016(ra) # 80000fa0 <strlen>
    800053a0:	0015069b          	addiw	a3,a0,1
    800053a4:	8652                	mv	a2,s4
    800053a6:	85ca                	mv	a1,s2
    800053a8:	855a                	mv	a0,s6
    800053aa:	ffffc097          	auipc	ra,0xffffc
    800053ae:	3fa080e7          	jalr	1018(ra) # 800017a4 <copyout>
    800053b2:	10054363          	bltz	a0,800054b8 <exec+0x39c>
    ustack[argc] = sp;
    800053b6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800053ba:	0485                	addi	s1,s1,1
    800053bc:	008d0793          	addi	a5,s10,8
    800053c0:	e0f43023          	sd	a5,-512(s0)
    800053c4:	008d3503          	ld	a0,8(s10)
    800053c8:	c909                	beqz	a0,800053da <exec+0x2be>
    if(argc >= MAXARG)
    800053ca:	09a1                	addi	s3,s3,8
    800053cc:	fb8995e3          	bne	s3,s8,80005376 <exec+0x25a>
  ip = 0;
    800053d0:	4a01                	li	s4,0
    800053d2:	a855                	j	80005486 <exec+0x36a>
  sp = sz;
    800053d4:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    800053d8:	4481                	li	s1,0
  ustack[argc] = 0;
    800053da:	00349793          	slli	a5,s1,0x3
    800053de:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7fdbd0e0>
    800053e2:	97a2                	add	a5,a5,s0
    800053e4:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800053e8:	00148693          	addi	a3,s1,1
    800053ec:	068e                	slli	a3,a3,0x3
    800053ee:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800053f2:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    800053f6:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    800053fa:	f57968e3          	bltu	s2,s7,8000534a <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800053fe:	e9040613          	addi	a2,s0,-368
    80005402:	85ca                	mv	a1,s2
    80005404:	855a                	mv	a0,s6
    80005406:	ffffc097          	auipc	ra,0xffffc
    8000540a:	39e080e7          	jalr	926(ra) # 800017a4 <copyout>
    8000540e:	0a054763          	bltz	a0,800054bc <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005412:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80005416:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000541a:	df843783          	ld	a5,-520(s0)
    8000541e:	0007c703          	lbu	a4,0(a5)
    80005422:	cf11                	beqz	a4,8000543e <exec+0x322>
    80005424:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005426:	02f00693          	li	a3,47
    8000542a:	a039                	j	80005438 <exec+0x31c>
      last = s+1;
    8000542c:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005430:	0785                	addi	a5,a5,1
    80005432:	fff7c703          	lbu	a4,-1(a5)
    80005436:	c701                	beqz	a4,8000543e <exec+0x322>
    if(*s == '/')
    80005438:	fed71ce3          	bne	a4,a3,80005430 <exec+0x314>
    8000543c:	bfc5                	j	8000542c <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    8000543e:	4641                	li	a2,16
    80005440:	df843583          	ld	a1,-520(s0)
    80005444:	158a8513          	addi	a0,s5,344
    80005448:	ffffc097          	auipc	ra,0xffffc
    8000544c:	b26080e7          	jalr	-1242(ra) # 80000f6e <safestrcpy>
  oldpagetable = p->pagetable;
    80005450:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005454:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80005458:	e0843783          	ld	a5,-504(s0)
    8000545c:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005460:	058ab783          	ld	a5,88(s5)
    80005464:	e6843703          	ld	a4,-408(s0)
    80005468:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000546a:	058ab783          	ld	a5,88(s5)
    8000546e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005472:	85e6                	mv	a1,s9
    80005474:	ffffd097          	auipc	ra,0xffffd
    80005478:	948080e7          	jalr	-1720(ra) # 80001dbc <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000547c:	0004851b          	sext.w	a0,s1
    80005480:	bb15                	j	800051b4 <exec+0x98>
    80005482:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005486:	e0843583          	ld	a1,-504(s0)
    8000548a:	855a                	mv	a0,s6
    8000548c:	ffffd097          	auipc	ra,0xffffd
    80005490:	930080e7          	jalr	-1744(ra) # 80001dbc <proc_freepagetable>
  return -1;
    80005494:	557d                	li	a0,-1
  if(ip){
    80005496:	d00a0fe3          	beqz	s4,800051b4 <exec+0x98>
    8000549a:	b319                	j	800051a0 <exec+0x84>
    8000549c:	e1243423          	sd	s2,-504(s0)
    800054a0:	b7dd                	j	80005486 <exec+0x36a>
    800054a2:	e1243423          	sd	s2,-504(s0)
    800054a6:	b7c5                	j	80005486 <exec+0x36a>
    800054a8:	e1243423          	sd	s2,-504(s0)
    800054ac:	bfe9                	j	80005486 <exec+0x36a>
    800054ae:	e1243423          	sd	s2,-504(s0)
    800054b2:	bfd1                	j	80005486 <exec+0x36a>
  ip = 0;
    800054b4:	4a01                	li	s4,0
    800054b6:	bfc1                	j	80005486 <exec+0x36a>
    800054b8:	4a01                	li	s4,0
  if(pagetable)
    800054ba:	b7f1                	j	80005486 <exec+0x36a>
  sz = sz1;
    800054bc:	e0843983          	ld	s3,-504(s0)
    800054c0:	b569                	j	8000534a <exec+0x22e>

00000000800054c2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800054c2:	7179                	addi	sp,sp,-48
    800054c4:	f406                	sd	ra,40(sp)
    800054c6:	f022                	sd	s0,32(sp)
    800054c8:	ec26                	sd	s1,24(sp)
    800054ca:	e84a                	sd	s2,16(sp)
    800054cc:	1800                	addi	s0,sp,48
    800054ce:	892e                	mv	s2,a1
    800054d0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800054d2:	fdc40593          	addi	a1,s0,-36
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	ac4080e7          	jalr	-1340(ra) # 80002f9a <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800054de:	fdc42703          	lw	a4,-36(s0)
    800054e2:	47bd                	li	a5,15
    800054e4:	02e7eb63          	bltu	a5,a4,8000551a <argfd+0x58>
    800054e8:	ffffc097          	auipc	ra,0xffffc
    800054ec:	774080e7          	jalr	1908(ra) # 80001c5c <myproc>
    800054f0:	fdc42703          	lw	a4,-36(s0)
    800054f4:	01a70793          	addi	a5,a4,26
    800054f8:	078e                	slli	a5,a5,0x3
    800054fa:	953e                	add	a0,a0,a5
    800054fc:	611c                	ld	a5,0(a0)
    800054fe:	c385                	beqz	a5,8000551e <argfd+0x5c>
    return -1;
  if(pfd)
    80005500:	00090463          	beqz	s2,80005508 <argfd+0x46>
    *pfd = fd;
    80005504:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005508:	4501                	li	a0,0
  if(pf)
    8000550a:	c091                	beqz	s1,8000550e <argfd+0x4c>
    *pf = f;
    8000550c:	e09c                	sd	a5,0(s1)
}
    8000550e:	70a2                	ld	ra,40(sp)
    80005510:	7402                	ld	s0,32(sp)
    80005512:	64e2                	ld	s1,24(sp)
    80005514:	6942                	ld	s2,16(sp)
    80005516:	6145                	addi	sp,sp,48
    80005518:	8082                	ret
    return -1;
    8000551a:	557d                	li	a0,-1
    8000551c:	bfcd                	j	8000550e <argfd+0x4c>
    8000551e:	557d                	li	a0,-1
    80005520:	b7fd                	j	8000550e <argfd+0x4c>

0000000080005522 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005522:	1101                	addi	sp,sp,-32
    80005524:	ec06                	sd	ra,24(sp)
    80005526:	e822                	sd	s0,16(sp)
    80005528:	e426                	sd	s1,8(sp)
    8000552a:	1000                	addi	s0,sp,32
    8000552c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000552e:	ffffc097          	auipc	ra,0xffffc
    80005532:	72e080e7          	jalr	1838(ra) # 80001c5c <myproc>
    80005536:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005538:	0d050793          	addi	a5,a0,208
    8000553c:	4501                	li	a0,0
    8000553e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005540:	6398                	ld	a4,0(a5)
    80005542:	cb19                	beqz	a4,80005558 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005544:	2505                	addiw	a0,a0,1
    80005546:	07a1                	addi	a5,a5,8
    80005548:	fed51ce3          	bne	a0,a3,80005540 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000554c:	557d                	li	a0,-1
}
    8000554e:	60e2                	ld	ra,24(sp)
    80005550:	6442                	ld	s0,16(sp)
    80005552:	64a2                	ld	s1,8(sp)
    80005554:	6105                	addi	sp,sp,32
    80005556:	8082                	ret
      p->ofile[fd] = f;
    80005558:	01a50793          	addi	a5,a0,26
    8000555c:	078e                	slli	a5,a5,0x3
    8000555e:	963e                	add	a2,a2,a5
    80005560:	e204                	sd	s1,0(a2)
      return fd;
    80005562:	b7f5                	j	8000554e <fdalloc+0x2c>

0000000080005564 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005564:	715d                	addi	sp,sp,-80
    80005566:	e486                	sd	ra,72(sp)
    80005568:	e0a2                	sd	s0,64(sp)
    8000556a:	fc26                	sd	s1,56(sp)
    8000556c:	f84a                	sd	s2,48(sp)
    8000556e:	f44e                	sd	s3,40(sp)
    80005570:	f052                	sd	s4,32(sp)
    80005572:	ec56                	sd	s5,24(sp)
    80005574:	e85a                	sd	s6,16(sp)
    80005576:	0880                	addi	s0,sp,80
    80005578:	8b2e                	mv	s6,a1
    8000557a:	89b2                	mv	s3,a2
    8000557c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000557e:	fb040593          	addi	a1,s0,-80
    80005582:	fffff097          	auipc	ra,0xfffff
    80005586:	e7e080e7          	jalr	-386(ra) # 80004400 <nameiparent>
    8000558a:	84aa                	mv	s1,a0
    8000558c:	14050b63          	beqz	a0,800056e2 <create+0x17e>
    return 0;

  ilock(dp);
    80005590:	ffffe097          	auipc	ra,0xffffe
    80005594:	6ac080e7          	jalr	1708(ra) # 80003c3c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005598:	4601                	li	a2,0
    8000559a:	fb040593          	addi	a1,s0,-80
    8000559e:	8526                	mv	a0,s1
    800055a0:	fffff097          	auipc	ra,0xfffff
    800055a4:	b80080e7          	jalr	-1152(ra) # 80004120 <dirlookup>
    800055a8:	8aaa                	mv	s5,a0
    800055aa:	c921                	beqz	a0,800055fa <create+0x96>
    iunlockput(dp);
    800055ac:	8526                	mv	a0,s1
    800055ae:	fffff097          	auipc	ra,0xfffff
    800055b2:	8f0080e7          	jalr	-1808(ra) # 80003e9e <iunlockput>
    ilock(ip);
    800055b6:	8556                	mv	a0,s5
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	684080e7          	jalr	1668(ra) # 80003c3c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800055c0:	4789                	li	a5,2
    800055c2:	02fb1563          	bne	s6,a5,800055ec <create+0x88>
    800055c6:	044ad783          	lhu	a5,68(s5)
    800055ca:	37f9                	addiw	a5,a5,-2
    800055cc:	17c2                	slli	a5,a5,0x30
    800055ce:	93c1                	srli	a5,a5,0x30
    800055d0:	4705                	li	a4,1
    800055d2:	00f76d63          	bltu	a4,a5,800055ec <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800055d6:	8556                	mv	a0,s5
    800055d8:	60a6                	ld	ra,72(sp)
    800055da:	6406                	ld	s0,64(sp)
    800055dc:	74e2                	ld	s1,56(sp)
    800055de:	7942                	ld	s2,48(sp)
    800055e0:	79a2                	ld	s3,40(sp)
    800055e2:	7a02                	ld	s4,32(sp)
    800055e4:	6ae2                	ld	s5,24(sp)
    800055e6:	6b42                	ld	s6,16(sp)
    800055e8:	6161                	addi	sp,sp,80
    800055ea:	8082                	ret
    iunlockput(ip);
    800055ec:	8556                	mv	a0,s5
    800055ee:	fffff097          	auipc	ra,0xfffff
    800055f2:	8b0080e7          	jalr	-1872(ra) # 80003e9e <iunlockput>
    return 0;
    800055f6:	4a81                	li	s5,0
    800055f8:	bff9                	j	800055d6 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    800055fa:	85da                	mv	a1,s6
    800055fc:	4088                	lw	a0,0(s1)
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	4a6080e7          	jalr	1190(ra) # 80003aa4 <ialloc>
    80005606:	8a2a                	mv	s4,a0
    80005608:	c529                	beqz	a0,80005652 <create+0xee>
  ilock(ip);
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	632080e7          	jalr	1586(ra) # 80003c3c <ilock>
  ip->major = major;
    80005612:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005616:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000561a:	4905                	li	s2,1
    8000561c:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005620:	8552                	mv	a0,s4
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	54e080e7          	jalr	1358(ra) # 80003b70 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000562a:	032b0b63          	beq	s6,s2,80005660 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000562e:	004a2603          	lw	a2,4(s4)
    80005632:	fb040593          	addi	a1,s0,-80
    80005636:	8526                	mv	a0,s1
    80005638:	fffff097          	auipc	ra,0xfffff
    8000563c:	cf8080e7          	jalr	-776(ra) # 80004330 <dirlink>
    80005640:	06054f63          	bltz	a0,800056be <create+0x15a>
  iunlockput(dp);
    80005644:	8526                	mv	a0,s1
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	858080e7          	jalr	-1960(ra) # 80003e9e <iunlockput>
  return ip;
    8000564e:	8ad2                	mv	s5,s4
    80005650:	b759                	j	800055d6 <create+0x72>
    iunlockput(dp);
    80005652:	8526                	mv	a0,s1
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	84a080e7          	jalr	-1974(ra) # 80003e9e <iunlockput>
    return 0;
    8000565c:	8ad2                	mv	s5,s4
    8000565e:	bfa5                	j	800055d6 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005660:	004a2603          	lw	a2,4(s4)
    80005664:	00003597          	auipc	a1,0x3
    80005668:	1bc58593          	addi	a1,a1,444 # 80008820 <syscalls+0x2c8>
    8000566c:	8552                	mv	a0,s4
    8000566e:	fffff097          	auipc	ra,0xfffff
    80005672:	cc2080e7          	jalr	-830(ra) # 80004330 <dirlink>
    80005676:	04054463          	bltz	a0,800056be <create+0x15a>
    8000567a:	40d0                	lw	a2,4(s1)
    8000567c:	00003597          	auipc	a1,0x3
    80005680:	1ac58593          	addi	a1,a1,428 # 80008828 <syscalls+0x2d0>
    80005684:	8552                	mv	a0,s4
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	caa080e7          	jalr	-854(ra) # 80004330 <dirlink>
    8000568e:	02054863          	bltz	a0,800056be <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005692:	004a2603          	lw	a2,4(s4)
    80005696:	fb040593          	addi	a1,s0,-80
    8000569a:	8526                	mv	a0,s1
    8000569c:	fffff097          	auipc	ra,0xfffff
    800056a0:	c94080e7          	jalr	-876(ra) # 80004330 <dirlink>
    800056a4:	00054d63          	bltz	a0,800056be <create+0x15a>
    dp->nlink++;  // for ".."
    800056a8:	04a4d783          	lhu	a5,74(s1)
    800056ac:	2785                	addiw	a5,a5,1
    800056ae:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056b2:	8526                	mv	a0,s1
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	4bc080e7          	jalr	1212(ra) # 80003b70 <iupdate>
    800056bc:	b761                	j	80005644 <create+0xe0>
  ip->nlink = 0;
    800056be:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800056c2:	8552                	mv	a0,s4
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	4ac080e7          	jalr	1196(ra) # 80003b70 <iupdate>
  iunlockput(ip);
    800056cc:	8552                	mv	a0,s4
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	7d0080e7          	jalr	2000(ra) # 80003e9e <iunlockput>
  iunlockput(dp);
    800056d6:	8526                	mv	a0,s1
    800056d8:	ffffe097          	auipc	ra,0xffffe
    800056dc:	7c6080e7          	jalr	1990(ra) # 80003e9e <iunlockput>
  return 0;
    800056e0:	bddd                	j	800055d6 <create+0x72>
    return 0;
    800056e2:	8aaa                	mv	s5,a0
    800056e4:	bdcd                	j	800055d6 <create+0x72>

00000000800056e6 <sys_dup>:
{
    800056e6:	7179                	addi	sp,sp,-48
    800056e8:	f406                	sd	ra,40(sp)
    800056ea:	f022                	sd	s0,32(sp)
    800056ec:	ec26                	sd	s1,24(sp)
    800056ee:	e84a                	sd	s2,16(sp)
    800056f0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800056f2:	fd840613          	addi	a2,s0,-40
    800056f6:	4581                	li	a1,0
    800056f8:	4501                	li	a0,0
    800056fa:	00000097          	auipc	ra,0x0
    800056fe:	dc8080e7          	jalr	-568(ra) # 800054c2 <argfd>
    return -1;
    80005702:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005704:	02054363          	bltz	a0,8000572a <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005708:	fd843903          	ld	s2,-40(s0)
    8000570c:	854a                	mv	a0,s2
    8000570e:	00000097          	auipc	ra,0x0
    80005712:	e14080e7          	jalr	-492(ra) # 80005522 <fdalloc>
    80005716:	84aa                	mv	s1,a0
    return -1;
    80005718:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000571a:	00054863          	bltz	a0,8000572a <sys_dup+0x44>
  filedup(f);
    8000571e:	854a                	mv	a0,s2
    80005720:	fffff097          	auipc	ra,0xfffff
    80005724:	334080e7          	jalr	820(ra) # 80004a54 <filedup>
  return fd;
    80005728:	87a6                	mv	a5,s1
}
    8000572a:	853e                	mv	a0,a5
    8000572c:	70a2                	ld	ra,40(sp)
    8000572e:	7402                	ld	s0,32(sp)
    80005730:	64e2                	ld	s1,24(sp)
    80005732:	6942                	ld	s2,16(sp)
    80005734:	6145                	addi	sp,sp,48
    80005736:	8082                	ret

0000000080005738 <sys_read>:
{
    80005738:	7179                	addi	sp,sp,-48
    8000573a:	f406                	sd	ra,40(sp)
    8000573c:	f022                	sd	s0,32(sp)
    8000573e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005740:	fd840593          	addi	a1,s0,-40
    80005744:	4505                	li	a0,1
    80005746:	ffffe097          	auipc	ra,0xffffe
    8000574a:	874080e7          	jalr	-1932(ra) # 80002fba <argaddr>
  argint(2, &n);
    8000574e:	fe440593          	addi	a1,s0,-28
    80005752:	4509                	li	a0,2
    80005754:	ffffe097          	auipc	ra,0xffffe
    80005758:	846080e7          	jalr	-1978(ra) # 80002f9a <argint>
  if(argfd(0, 0, &f) < 0)
    8000575c:	fe840613          	addi	a2,s0,-24
    80005760:	4581                	li	a1,0
    80005762:	4501                	li	a0,0
    80005764:	00000097          	auipc	ra,0x0
    80005768:	d5e080e7          	jalr	-674(ra) # 800054c2 <argfd>
    8000576c:	87aa                	mv	a5,a0
    return -1;
    8000576e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005770:	0007cc63          	bltz	a5,80005788 <sys_read+0x50>
  return fileread(f, p, n);
    80005774:	fe442603          	lw	a2,-28(s0)
    80005778:	fd843583          	ld	a1,-40(s0)
    8000577c:	fe843503          	ld	a0,-24(s0)
    80005780:	fffff097          	auipc	ra,0xfffff
    80005784:	460080e7          	jalr	1120(ra) # 80004be0 <fileread>
}
    80005788:	70a2                	ld	ra,40(sp)
    8000578a:	7402                	ld	s0,32(sp)
    8000578c:	6145                	addi	sp,sp,48
    8000578e:	8082                	ret

0000000080005790 <sys_write>:
{
    80005790:	7179                	addi	sp,sp,-48
    80005792:	f406                	sd	ra,40(sp)
    80005794:	f022                	sd	s0,32(sp)
    80005796:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005798:	fd840593          	addi	a1,s0,-40
    8000579c:	4505                	li	a0,1
    8000579e:	ffffe097          	auipc	ra,0xffffe
    800057a2:	81c080e7          	jalr	-2020(ra) # 80002fba <argaddr>
  argint(2, &n);
    800057a6:	fe440593          	addi	a1,s0,-28
    800057aa:	4509                	li	a0,2
    800057ac:	ffffd097          	auipc	ra,0xffffd
    800057b0:	7ee080e7          	jalr	2030(ra) # 80002f9a <argint>
  if(argfd(0, 0, &f) < 0)
    800057b4:	fe840613          	addi	a2,s0,-24
    800057b8:	4581                	li	a1,0
    800057ba:	4501                	li	a0,0
    800057bc:	00000097          	auipc	ra,0x0
    800057c0:	d06080e7          	jalr	-762(ra) # 800054c2 <argfd>
    800057c4:	87aa                	mv	a5,a0
    return -1;
    800057c6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057c8:	0007cc63          	bltz	a5,800057e0 <sys_write+0x50>
  return filewrite(f, p, n);
    800057cc:	fe442603          	lw	a2,-28(s0)
    800057d0:	fd843583          	ld	a1,-40(s0)
    800057d4:	fe843503          	ld	a0,-24(s0)
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	4ca080e7          	jalr	1226(ra) # 80004ca2 <filewrite>
}
    800057e0:	70a2                	ld	ra,40(sp)
    800057e2:	7402                	ld	s0,32(sp)
    800057e4:	6145                	addi	sp,sp,48
    800057e6:	8082                	ret

00000000800057e8 <sys_close>:
{
    800057e8:	1101                	addi	sp,sp,-32
    800057ea:	ec06                	sd	ra,24(sp)
    800057ec:	e822                	sd	s0,16(sp)
    800057ee:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800057f0:	fe040613          	addi	a2,s0,-32
    800057f4:	fec40593          	addi	a1,s0,-20
    800057f8:	4501                	li	a0,0
    800057fa:	00000097          	auipc	ra,0x0
    800057fe:	cc8080e7          	jalr	-824(ra) # 800054c2 <argfd>
    return -1;
    80005802:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005804:	02054463          	bltz	a0,8000582c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005808:	ffffc097          	auipc	ra,0xffffc
    8000580c:	454080e7          	jalr	1108(ra) # 80001c5c <myproc>
    80005810:	fec42783          	lw	a5,-20(s0)
    80005814:	07e9                	addi	a5,a5,26
    80005816:	078e                	slli	a5,a5,0x3
    80005818:	953e                	add	a0,a0,a5
    8000581a:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000581e:	fe043503          	ld	a0,-32(s0)
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	284080e7          	jalr	644(ra) # 80004aa6 <fileclose>
  return 0;
    8000582a:	4781                	li	a5,0
}
    8000582c:	853e                	mv	a0,a5
    8000582e:	60e2                	ld	ra,24(sp)
    80005830:	6442                	ld	s0,16(sp)
    80005832:	6105                	addi	sp,sp,32
    80005834:	8082                	ret

0000000080005836 <sys_fstat>:
{
    80005836:	1101                	addi	sp,sp,-32
    80005838:	ec06                	sd	ra,24(sp)
    8000583a:	e822                	sd	s0,16(sp)
    8000583c:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000583e:	fe040593          	addi	a1,s0,-32
    80005842:	4505                	li	a0,1
    80005844:	ffffd097          	auipc	ra,0xffffd
    80005848:	776080e7          	jalr	1910(ra) # 80002fba <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000584c:	fe840613          	addi	a2,s0,-24
    80005850:	4581                	li	a1,0
    80005852:	4501                	li	a0,0
    80005854:	00000097          	auipc	ra,0x0
    80005858:	c6e080e7          	jalr	-914(ra) # 800054c2 <argfd>
    8000585c:	87aa                	mv	a5,a0
    return -1;
    8000585e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005860:	0007ca63          	bltz	a5,80005874 <sys_fstat+0x3e>
  return filestat(f, st);
    80005864:	fe043583          	ld	a1,-32(s0)
    80005868:	fe843503          	ld	a0,-24(s0)
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	302080e7          	jalr	770(ra) # 80004b6e <filestat>
}
    80005874:	60e2                	ld	ra,24(sp)
    80005876:	6442                	ld	s0,16(sp)
    80005878:	6105                	addi	sp,sp,32
    8000587a:	8082                	ret

000000008000587c <sys_link>:
{
    8000587c:	7169                	addi	sp,sp,-304
    8000587e:	f606                	sd	ra,296(sp)
    80005880:	f222                	sd	s0,288(sp)
    80005882:	ee26                	sd	s1,280(sp)
    80005884:	ea4a                	sd	s2,272(sp)
    80005886:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005888:	08000613          	li	a2,128
    8000588c:	ed040593          	addi	a1,s0,-304
    80005890:	4501                	li	a0,0
    80005892:	ffffd097          	auipc	ra,0xffffd
    80005896:	748080e7          	jalr	1864(ra) # 80002fda <argstr>
    return -1;
    8000589a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000589c:	10054e63          	bltz	a0,800059b8 <sys_link+0x13c>
    800058a0:	08000613          	li	a2,128
    800058a4:	f5040593          	addi	a1,s0,-176
    800058a8:	4505                	li	a0,1
    800058aa:	ffffd097          	auipc	ra,0xffffd
    800058ae:	730080e7          	jalr	1840(ra) # 80002fda <argstr>
    return -1;
    800058b2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058b4:	10054263          	bltz	a0,800059b8 <sys_link+0x13c>
  begin_op();
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	d2a080e7          	jalr	-726(ra) # 800045e2 <begin_op>
  if((ip = namei(old)) == 0){
    800058c0:	ed040513          	addi	a0,s0,-304
    800058c4:	fffff097          	auipc	ra,0xfffff
    800058c8:	b1e080e7          	jalr	-1250(ra) # 800043e2 <namei>
    800058cc:	84aa                	mv	s1,a0
    800058ce:	c551                	beqz	a0,8000595a <sys_link+0xde>
  ilock(ip);
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	36c080e7          	jalr	876(ra) # 80003c3c <ilock>
  if(ip->type == T_DIR){
    800058d8:	04449703          	lh	a4,68(s1)
    800058dc:	4785                	li	a5,1
    800058de:	08f70463          	beq	a4,a5,80005966 <sys_link+0xea>
  ip->nlink++;
    800058e2:	04a4d783          	lhu	a5,74(s1)
    800058e6:	2785                	addiw	a5,a5,1
    800058e8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058ec:	8526                	mv	a0,s1
    800058ee:	ffffe097          	auipc	ra,0xffffe
    800058f2:	282080e7          	jalr	642(ra) # 80003b70 <iupdate>
  iunlock(ip);
    800058f6:	8526                	mv	a0,s1
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	406080e7          	jalr	1030(ra) # 80003cfe <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005900:	fd040593          	addi	a1,s0,-48
    80005904:	f5040513          	addi	a0,s0,-176
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	af8080e7          	jalr	-1288(ra) # 80004400 <nameiparent>
    80005910:	892a                	mv	s2,a0
    80005912:	c935                	beqz	a0,80005986 <sys_link+0x10a>
  ilock(dp);
    80005914:	ffffe097          	auipc	ra,0xffffe
    80005918:	328080e7          	jalr	808(ra) # 80003c3c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000591c:	00092703          	lw	a4,0(s2)
    80005920:	409c                	lw	a5,0(s1)
    80005922:	04f71d63          	bne	a4,a5,8000597c <sys_link+0x100>
    80005926:	40d0                	lw	a2,4(s1)
    80005928:	fd040593          	addi	a1,s0,-48
    8000592c:	854a                	mv	a0,s2
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	a02080e7          	jalr	-1534(ra) # 80004330 <dirlink>
    80005936:	04054363          	bltz	a0,8000597c <sys_link+0x100>
  iunlockput(dp);
    8000593a:	854a                	mv	a0,s2
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	562080e7          	jalr	1378(ra) # 80003e9e <iunlockput>
  iput(ip);
    80005944:	8526                	mv	a0,s1
    80005946:	ffffe097          	auipc	ra,0xffffe
    8000594a:	4b0080e7          	jalr	1200(ra) # 80003df6 <iput>
  end_op();
    8000594e:	fffff097          	auipc	ra,0xfffff
    80005952:	d0e080e7          	jalr	-754(ra) # 8000465c <end_op>
  return 0;
    80005956:	4781                	li	a5,0
    80005958:	a085                	j	800059b8 <sys_link+0x13c>
    end_op();
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	d02080e7          	jalr	-766(ra) # 8000465c <end_op>
    return -1;
    80005962:	57fd                	li	a5,-1
    80005964:	a891                	j	800059b8 <sys_link+0x13c>
    iunlockput(ip);
    80005966:	8526                	mv	a0,s1
    80005968:	ffffe097          	auipc	ra,0xffffe
    8000596c:	536080e7          	jalr	1334(ra) # 80003e9e <iunlockput>
    end_op();
    80005970:	fffff097          	auipc	ra,0xfffff
    80005974:	cec080e7          	jalr	-788(ra) # 8000465c <end_op>
    return -1;
    80005978:	57fd                	li	a5,-1
    8000597a:	a83d                	j	800059b8 <sys_link+0x13c>
    iunlockput(dp);
    8000597c:	854a                	mv	a0,s2
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	520080e7          	jalr	1312(ra) # 80003e9e <iunlockput>
  ilock(ip);
    80005986:	8526                	mv	a0,s1
    80005988:	ffffe097          	auipc	ra,0xffffe
    8000598c:	2b4080e7          	jalr	692(ra) # 80003c3c <ilock>
  ip->nlink--;
    80005990:	04a4d783          	lhu	a5,74(s1)
    80005994:	37fd                	addiw	a5,a5,-1
    80005996:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000599a:	8526                	mv	a0,s1
    8000599c:	ffffe097          	auipc	ra,0xffffe
    800059a0:	1d4080e7          	jalr	468(ra) # 80003b70 <iupdate>
  iunlockput(ip);
    800059a4:	8526                	mv	a0,s1
    800059a6:	ffffe097          	auipc	ra,0xffffe
    800059aa:	4f8080e7          	jalr	1272(ra) # 80003e9e <iunlockput>
  end_op();
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	cae080e7          	jalr	-850(ra) # 8000465c <end_op>
  return -1;
    800059b6:	57fd                	li	a5,-1
}
    800059b8:	853e                	mv	a0,a5
    800059ba:	70b2                	ld	ra,296(sp)
    800059bc:	7412                	ld	s0,288(sp)
    800059be:	64f2                	ld	s1,280(sp)
    800059c0:	6952                	ld	s2,272(sp)
    800059c2:	6155                	addi	sp,sp,304
    800059c4:	8082                	ret

00000000800059c6 <sys_unlink>:
{
    800059c6:	7151                	addi	sp,sp,-240
    800059c8:	f586                	sd	ra,232(sp)
    800059ca:	f1a2                	sd	s0,224(sp)
    800059cc:	eda6                	sd	s1,216(sp)
    800059ce:	e9ca                	sd	s2,208(sp)
    800059d0:	e5ce                	sd	s3,200(sp)
    800059d2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800059d4:	08000613          	li	a2,128
    800059d8:	f3040593          	addi	a1,s0,-208
    800059dc:	4501                	li	a0,0
    800059de:	ffffd097          	auipc	ra,0xffffd
    800059e2:	5fc080e7          	jalr	1532(ra) # 80002fda <argstr>
    800059e6:	18054163          	bltz	a0,80005b68 <sys_unlink+0x1a2>
  begin_op();
    800059ea:	fffff097          	auipc	ra,0xfffff
    800059ee:	bf8080e7          	jalr	-1032(ra) # 800045e2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800059f2:	fb040593          	addi	a1,s0,-80
    800059f6:	f3040513          	addi	a0,s0,-208
    800059fa:	fffff097          	auipc	ra,0xfffff
    800059fe:	a06080e7          	jalr	-1530(ra) # 80004400 <nameiparent>
    80005a02:	84aa                	mv	s1,a0
    80005a04:	c979                	beqz	a0,80005ada <sys_unlink+0x114>
  ilock(dp);
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	236080e7          	jalr	566(ra) # 80003c3c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a0e:	00003597          	auipc	a1,0x3
    80005a12:	e1258593          	addi	a1,a1,-494 # 80008820 <syscalls+0x2c8>
    80005a16:	fb040513          	addi	a0,s0,-80
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	6ec080e7          	jalr	1772(ra) # 80004106 <namecmp>
    80005a22:	14050a63          	beqz	a0,80005b76 <sys_unlink+0x1b0>
    80005a26:	00003597          	auipc	a1,0x3
    80005a2a:	e0258593          	addi	a1,a1,-510 # 80008828 <syscalls+0x2d0>
    80005a2e:	fb040513          	addi	a0,s0,-80
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	6d4080e7          	jalr	1748(ra) # 80004106 <namecmp>
    80005a3a:	12050e63          	beqz	a0,80005b76 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a3e:	f2c40613          	addi	a2,s0,-212
    80005a42:	fb040593          	addi	a1,s0,-80
    80005a46:	8526                	mv	a0,s1
    80005a48:	ffffe097          	auipc	ra,0xffffe
    80005a4c:	6d8080e7          	jalr	1752(ra) # 80004120 <dirlookup>
    80005a50:	892a                	mv	s2,a0
    80005a52:	12050263          	beqz	a0,80005b76 <sys_unlink+0x1b0>
  ilock(ip);
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	1e6080e7          	jalr	486(ra) # 80003c3c <ilock>
  if(ip->nlink < 1)
    80005a5e:	04a91783          	lh	a5,74(s2)
    80005a62:	08f05263          	blez	a5,80005ae6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a66:	04491703          	lh	a4,68(s2)
    80005a6a:	4785                	li	a5,1
    80005a6c:	08f70563          	beq	a4,a5,80005af6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a70:	4641                	li	a2,16
    80005a72:	4581                	li	a1,0
    80005a74:	fc040513          	addi	a0,s0,-64
    80005a78:	ffffb097          	auipc	ra,0xffffb
    80005a7c:	3ae080e7          	jalr	942(ra) # 80000e26 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a80:	4741                	li	a4,16
    80005a82:	f2c42683          	lw	a3,-212(s0)
    80005a86:	fc040613          	addi	a2,s0,-64
    80005a8a:	4581                	li	a1,0
    80005a8c:	8526                	mv	a0,s1
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	55a080e7          	jalr	1370(ra) # 80003fe8 <writei>
    80005a96:	47c1                	li	a5,16
    80005a98:	0af51563          	bne	a0,a5,80005b42 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a9c:	04491703          	lh	a4,68(s2)
    80005aa0:	4785                	li	a5,1
    80005aa2:	0af70863          	beq	a4,a5,80005b52 <sys_unlink+0x18c>
  iunlockput(dp);
    80005aa6:	8526                	mv	a0,s1
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	3f6080e7          	jalr	1014(ra) # 80003e9e <iunlockput>
  ip->nlink--;
    80005ab0:	04a95783          	lhu	a5,74(s2)
    80005ab4:	37fd                	addiw	a5,a5,-1
    80005ab6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005aba:	854a                	mv	a0,s2
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	0b4080e7          	jalr	180(ra) # 80003b70 <iupdate>
  iunlockput(ip);
    80005ac4:	854a                	mv	a0,s2
    80005ac6:	ffffe097          	auipc	ra,0xffffe
    80005aca:	3d8080e7          	jalr	984(ra) # 80003e9e <iunlockput>
  end_op();
    80005ace:	fffff097          	auipc	ra,0xfffff
    80005ad2:	b8e080e7          	jalr	-1138(ra) # 8000465c <end_op>
  return 0;
    80005ad6:	4501                	li	a0,0
    80005ad8:	a84d                	j	80005b8a <sys_unlink+0x1c4>
    end_op();
    80005ada:	fffff097          	auipc	ra,0xfffff
    80005ade:	b82080e7          	jalr	-1150(ra) # 8000465c <end_op>
    return -1;
    80005ae2:	557d                	li	a0,-1
    80005ae4:	a05d                	j	80005b8a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005ae6:	00003517          	auipc	a0,0x3
    80005aea:	d4a50513          	addi	a0,a0,-694 # 80008830 <syscalls+0x2d8>
    80005aee:	ffffb097          	auipc	ra,0xffffb
    80005af2:	a4e080e7          	jalr	-1458(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005af6:	04c92703          	lw	a4,76(s2)
    80005afa:	02000793          	li	a5,32
    80005afe:	f6e7f9e3          	bgeu	a5,a4,80005a70 <sys_unlink+0xaa>
    80005b02:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b06:	4741                	li	a4,16
    80005b08:	86ce                	mv	a3,s3
    80005b0a:	f1840613          	addi	a2,s0,-232
    80005b0e:	4581                	li	a1,0
    80005b10:	854a                	mv	a0,s2
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	3de080e7          	jalr	990(ra) # 80003ef0 <readi>
    80005b1a:	47c1                	li	a5,16
    80005b1c:	00f51b63          	bne	a0,a5,80005b32 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b20:	f1845783          	lhu	a5,-232(s0)
    80005b24:	e7a1                	bnez	a5,80005b6c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b26:	29c1                	addiw	s3,s3,16
    80005b28:	04c92783          	lw	a5,76(s2)
    80005b2c:	fcf9ede3          	bltu	s3,a5,80005b06 <sys_unlink+0x140>
    80005b30:	b781                	j	80005a70 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b32:	00003517          	auipc	a0,0x3
    80005b36:	d1650513          	addi	a0,a0,-746 # 80008848 <syscalls+0x2f0>
    80005b3a:	ffffb097          	auipc	ra,0xffffb
    80005b3e:	a02080e7          	jalr	-1534(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005b42:	00003517          	auipc	a0,0x3
    80005b46:	d1e50513          	addi	a0,a0,-738 # 80008860 <syscalls+0x308>
    80005b4a:	ffffb097          	auipc	ra,0xffffb
    80005b4e:	9f2080e7          	jalr	-1550(ra) # 8000053c <panic>
    dp->nlink--;
    80005b52:	04a4d783          	lhu	a5,74(s1)
    80005b56:	37fd                	addiw	a5,a5,-1
    80005b58:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b5c:	8526                	mv	a0,s1
    80005b5e:	ffffe097          	auipc	ra,0xffffe
    80005b62:	012080e7          	jalr	18(ra) # 80003b70 <iupdate>
    80005b66:	b781                	j	80005aa6 <sys_unlink+0xe0>
    return -1;
    80005b68:	557d                	li	a0,-1
    80005b6a:	a005                	j	80005b8a <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b6c:	854a                	mv	a0,s2
    80005b6e:	ffffe097          	auipc	ra,0xffffe
    80005b72:	330080e7          	jalr	816(ra) # 80003e9e <iunlockput>
  iunlockput(dp);
    80005b76:	8526                	mv	a0,s1
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	326080e7          	jalr	806(ra) # 80003e9e <iunlockput>
  end_op();
    80005b80:	fffff097          	auipc	ra,0xfffff
    80005b84:	adc080e7          	jalr	-1316(ra) # 8000465c <end_op>
  return -1;
    80005b88:	557d                	li	a0,-1
}
    80005b8a:	70ae                	ld	ra,232(sp)
    80005b8c:	740e                	ld	s0,224(sp)
    80005b8e:	64ee                	ld	s1,216(sp)
    80005b90:	694e                	ld	s2,208(sp)
    80005b92:	69ae                	ld	s3,200(sp)
    80005b94:	616d                	addi	sp,sp,240
    80005b96:	8082                	ret

0000000080005b98 <sys_open>:

uint64
sys_open(void)
{
    80005b98:	7131                	addi	sp,sp,-192
    80005b9a:	fd06                	sd	ra,184(sp)
    80005b9c:	f922                	sd	s0,176(sp)
    80005b9e:	f526                	sd	s1,168(sp)
    80005ba0:	f14a                	sd	s2,160(sp)
    80005ba2:	ed4e                	sd	s3,152(sp)
    80005ba4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005ba6:	f4c40593          	addi	a1,s0,-180
    80005baa:	4505                	li	a0,1
    80005bac:	ffffd097          	auipc	ra,0xffffd
    80005bb0:	3ee080e7          	jalr	1006(ra) # 80002f9a <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005bb4:	08000613          	li	a2,128
    80005bb8:	f5040593          	addi	a1,s0,-176
    80005bbc:	4501                	li	a0,0
    80005bbe:	ffffd097          	auipc	ra,0xffffd
    80005bc2:	41c080e7          	jalr	1052(ra) # 80002fda <argstr>
    80005bc6:	87aa                	mv	a5,a0
    return -1;
    80005bc8:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005bca:	0a07c863          	bltz	a5,80005c7a <sys_open+0xe2>

  begin_op();
    80005bce:	fffff097          	auipc	ra,0xfffff
    80005bd2:	a14080e7          	jalr	-1516(ra) # 800045e2 <begin_op>

  if(omode & O_CREATE){
    80005bd6:	f4c42783          	lw	a5,-180(s0)
    80005bda:	2007f793          	andi	a5,a5,512
    80005bde:	cbdd                	beqz	a5,80005c94 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005be0:	4681                	li	a3,0
    80005be2:	4601                	li	a2,0
    80005be4:	4589                	li	a1,2
    80005be6:	f5040513          	addi	a0,s0,-176
    80005bea:	00000097          	auipc	ra,0x0
    80005bee:	97a080e7          	jalr	-1670(ra) # 80005564 <create>
    80005bf2:	84aa                	mv	s1,a0
    if(ip == 0){
    80005bf4:	c951                	beqz	a0,80005c88 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005bf6:	04449703          	lh	a4,68(s1)
    80005bfa:	478d                	li	a5,3
    80005bfc:	00f71763          	bne	a4,a5,80005c0a <sys_open+0x72>
    80005c00:	0464d703          	lhu	a4,70(s1)
    80005c04:	47a5                	li	a5,9
    80005c06:	0ce7ec63          	bltu	a5,a4,80005cde <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	de0080e7          	jalr	-544(ra) # 800049ea <filealloc>
    80005c12:	892a                	mv	s2,a0
    80005c14:	c56d                	beqz	a0,80005cfe <sys_open+0x166>
    80005c16:	00000097          	auipc	ra,0x0
    80005c1a:	90c080e7          	jalr	-1780(ra) # 80005522 <fdalloc>
    80005c1e:	89aa                	mv	s3,a0
    80005c20:	0c054a63          	bltz	a0,80005cf4 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c24:	04449703          	lh	a4,68(s1)
    80005c28:	478d                	li	a5,3
    80005c2a:	0ef70563          	beq	a4,a5,80005d14 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c2e:	4789                	li	a5,2
    80005c30:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005c34:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005c38:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005c3c:	f4c42783          	lw	a5,-180(s0)
    80005c40:	0017c713          	xori	a4,a5,1
    80005c44:	8b05                	andi	a4,a4,1
    80005c46:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c4a:	0037f713          	andi	a4,a5,3
    80005c4e:	00e03733          	snez	a4,a4
    80005c52:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c56:	4007f793          	andi	a5,a5,1024
    80005c5a:	c791                	beqz	a5,80005c66 <sys_open+0xce>
    80005c5c:	04449703          	lh	a4,68(s1)
    80005c60:	4789                	li	a5,2
    80005c62:	0cf70063          	beq	a4,a5,80005d22 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005c66:	8526                	mv	a0,s1
    80005c68:	ffffe097          	auipc	ra,0xffffe
    80005c6c:	096080e7          	jalr	150(ra) # 80003cfe <iunlock>
  end_op();
    80005c70:	fffff097          	auipc	ra,0xfffff
    80005c74:	9ec080e7          	jalr	-1556(ra) # 8000465c <end_op>

  return fd;
    80005c78:	854e                	mv	a0,s3
}
    80005c7a:	70ea                	ld	ra,184(sp)
    80005c7c:	744a                	ld	s0,176(sp)
    80005c7e:	74aa                	ld	s1,168(sp)
    80005c80:	790a                	ld	s2,160(sp)
    80005c82:	69ea                	ld	s3,152(sp)
    80005c84:	6129                	addi	sp,sp,192
    80005c86:	8082                	ret
      end_op();
    80005c88:	fffff097          	auipc	ra,0xfffff
    80005c8c:	9d4080e7          	jalr	-1580(ra) # 8000465c <end_op>
      return -1;
    80005c90:	557d                	li	a0,-1
    80005c92:	b7e5                	j	80005c7a <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005c94:	f5040513          	addi	a0,s0,-176
    80005c98:	ffffe097          	auipc	ra,0xffffe
    80005c9c:	74a080e7          	jalr	1866(ra) # 800043e2 <namei>
    80005ca0:	84aa                	mv	s1,a0
    80005ca2:	c905                	beqz	a0,80005cd2 <sys_open+0x13a>
    ilock(ip);
    80005ca4:	ffffe097          	auipc	ra,0xffffe
    80005ca8:	f98080e7          	jalr	-104(ra) # 80003c3c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005cac:	04449703          	lh	a4,68(s1)
    80005cb0:	4785                	li	a5,1
    80005cb2:	f4f712e3          	bne	a4,a5,80005bf6 <sys_open+0x5e>
    80005cb6:	f4c42783          	lw	a5,-180(s0)
    80005cba:	dba1                	beqz	a5,80005c0a <sys_open+0x72>
      iunlockput(ip);
    80005cbc:	8526                	mv	a0,s1
    80005cbe:	ffffe097          	auipc	ra,0xffffe
    80005cc2:	1e0080e7          	jalr	480(ra) # 80003e9e <iunlockput>
      end_op();
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	996080e7          	jalr	-1642(ra) # 8000465c <end_op>
      return -1;
    80005cce:	557d                	li	a0,-1
    80005cd0:	b76d                	j	80005c7a <sys_open+0xe2>
      end_op();
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	98a080e7          	jalr	-1654(ra) # 8000465c <end_op>
      return -1;
    80005cda:	557d                	li	a0,-1
    80005cdc:	bf79                	j	80005c7a <sys_open+0xe2>
    iunlockput(ip);
    80005cde:	8526                	mv	a0,s1
    80005ce0:	ffffe097          	auipc	ra,0xffffe
    80005ce4:	1be080e7          	jalr	446(ra) # 80003e9e <iunlockput>
    end_op();
    80005ce8:	fffff097          	auipc	ra,0xfffff
    80005cec:	974080e7          	jalr	-1676(ra) # 8000465c <end_op>
    return -1;
    80005cf0:	557d                	li	a0,-1
    80005cf2:	b761                	j	80005c7a <sys_open+0xe2>
      fileclose(f);
    80005cf4:	854a                	mv	a0,s2
    80005cf6:	fffff097          	auipc	ra,0xfffff
    80005cfa:	db0080e7          	jalr	-592(ra) # 80004aa6 <fileclose>
    iunlockput(ip);
    80005cfe:	8526                	mv	a0,s1
    80005d00:	ffffe097          	auipc	ra,0xffffe
    80005d04:	19e080e7          	jalr	414(ra) # 80003e9e <iunlockput>
    end_op();
    80005d08:	fffff097          	auipc	ra,0xfffff
    80005d0c:	954080e7          	jalr	-1708(ra) # 8000465c <end_op>
    return -1;
    80005d10:	557d                	li	a0,-1
    80005d12:	b7a5                	j	80005c7a <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005d14:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005d18:	04649783          	lh	a5,70(s1)
    80005d1c:	02f91223          	sh	a5,36(s2)
    80005d20:	bf21                	j	80005c38 <sys_open+0xa0>
    itrunc(ip);
    80005d22:	8526                	mv	a0,s1
    80005d24:	ffffe097          	auipc	ra,0xffffe
    80005d28:	026080e7          	jalr	38(ra) # 80003d4a <itrunc>
    80005d2c:	bf2d                	j	80005c66 <sys_open+0xce>

0000000080005d2e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d2e:	7175                	addi	sp,sp,-144
    80005d30:	e506                	sd	ra,136(sp)
    80005d32:	e122                	sd	s0,128(sp)
    80005d34:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d36:	fffff097          	auipc	ra,0xfffff
    80005d3a:	8ac080e7          	jalr	-1876(ra) # 800045e2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d3e:	08000613          	li	a2,128
    80005d42:	f7040593          	addi	a1,s0,-144
    80005d46:	4501                	li	a0,0
    80005d48:	ffffd097          	auipc	ra,0xffffd
    80005d4c:	292080e7          	jalr	658(ra) # 80002fda <argstr>
    80005d50:	02054963          	bltz	a0,80005d82 <sys_mkdir+0x54>
    80005d54:	4681                	li	a3,0
    80005d56:	4601                	li	a2,0
    80005d58:	4585                	li	a1,1
    80005d5a:	f7040513          	addi	a0,s0,-144
    80005d5e:	00000097          	auipc	ra,0x0
    80005d62:	806080e7          	jalr	-2042(ra) # 80005564 <create>
    80005d66:	cd11                	beqz	a0,80005d82 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d68:	ffffe097          	auipc	ra,0xffffe
    80005d6c:	136080e7          	jalr	310(ra) # 80003e9e <iunlockput>
  end_op();
    80005d70:	fffff097          	auipc	ra,0xfffff
    80005d74:	8ec080e7          	jalr	-1812(ra) # 8000465c <end_op>
  return 0;
    80005d78:	4501                	li	a0,0
}
    80005d7a:	60aa                	ld	ra,136(sp)
    80005d7c:	640a                	ld	s0,128(sp)
    80005d7e:	6149                	addi	sp,sp,144
    80005d80:	8082                	ret
    end_op();
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	8da080e7          	jalr	-1830(ra) # 8000465c <end_op>
    return -1;
    80005d8a:	557d                	li	a0,-1
    80005d8c:	b7fd                	j	80005d7a <sys_mkdir+0x4c>

0000000080005d8e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d8e:	7135                	addi	sp,sp,-160
    80005d90:	ed06                	sd	ra,152(sp)
    80005d92:	e922                	sd	s0,144(sp)
    80005d94:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d96:	fffff097          	auipc	ra,0xfffff
    80005d9a:	84c080e7          	jalr	-1972(ra) # 800045e2 <begin_op>
  argint(1, &major);
    80005d9e:	f6c40593          	addi	a1,s0,-148
    80005da2:	4505                	li	a0,1
    80005da4:	ffffd097          	auipc	ra,0xffffd
    80005da8:	1f6080e7          	jalr	502(ra) # 80002f9a <argint>
  argint(2, &minor);
    80005dac:	f6840593          	addi	a1,s0,-152
    80005db0:	4509                	li	a0,2
    80005db2:	ffffd097          	auipc	ra,0xffffd
    80005db6:	1e8080e7          	jalr	488(ra) # 80002f9a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005dba:	08000613          	li	a2,128
    80005dbe:	f7040593          	addi	a1,s0,-144
    80005dc2:	4501                	li	a0,0
    80005dc4:	ffffd097          	auipc	ra,0xffffd
    80005dc8:	216080e7          	jalr	534(ra) # 80002fda <argstr>
    80005dcc:	02054b63          	bltz	a0,80005e02 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005dd0:	f6841683          	lh	a3,-152(s0)
    80005dd4:	f6c41603          	lh	a2,-148(s0)
    80005dd8:	458d                	li	a1,3
    80005dda:	f7040513          	addi	a0,s0,-144
    80005dde:	fffff097          	auipc	ra,0xfffff
    80005de2:	786080e7          	jalr	1926(ra) # 80005564 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005de6:	cd11                	beqz	a0,80005e02 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005de8:	ffffe097          	auipc	ra,0xffffe
    80005dec:	0b6080e7          	jalr	182(ra) # 80003e9e <iunlockput>
  end_op();
    80005df0:	fffff097          	auipc	ra,0xfffff
    80005df4:	86c080e7          	jalr	-1940(ra) # 8000465c <end_op>
  return 0;
    80005df8:	4501                	li	a0,0
}
    80005dfa:	60ea                	ld	ra,152(sp)
    80005dfc:	644a                	ld	s0,144(sp)
    80005dfe:	610d                	addi	sp,sp,160
    80005e00:	8082                	ret
    end_op();
    80005e02:	fffff097          	auipc	ra,0xfffff
    80005e06:	85a080e7          	jalr	-1958(ra) # 8000465c <end_op>
    return -1;
    80005e0a:	557d                	li	a0,-1
    80005e0c:	b7fd                	j	80005dfa <sys_mknod+0x6c>

0000000080005e0e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e0e:	7135                	addi	sp,sp,-160
    80005e10:	ed06                	sd	ra,152(sp)
    80005e12:	e922                	sd	s0,144(sp)
    80005e14:	e526                	sd	s1,136(sp)
    80005e16:	e14a                	sd	s2,128(sp)
    80005e18:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e1a:	ffffc097          	auipc	ra,0xffffc
    80005e1e:	e42080e7          	jalr	-446(ra) # 80001c5c <myproc>
    80005e22:	892a                	mv	s2,a0
  
  begin_op();
    80005e24:	ffffe097          	auipc	ra,0xffffe
    80005e28:	7be080e7          	jalr	1982(ra) # 800045e2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e2c:	08000613          	li	a2,128
    80005e30:	f6040593          	addi	a1,s0,-160
    80005e34:	4501                	li	a0,0
    80005e36:	ffffd097          	auipc	ra,0xffffd
    80005e3a:	1a4080e7          	jalr	420(ra) # 80002fda <argstr>
    80005e3e:	04054b63          	bltz	a0,80005e94 <sys_chdir+0x86>
    80005e42:	f6040513          	addi	a0,s0,-160
    80005e46:	ffffe097          	auipc	ra,0xffffe
    80005e4a:	59c080e7          	jalr	1436(ra) # 800043e2 <namei>
    80005e4e:	84aa                	mv	s1,a0
    80005e50:	c131                	beqz	a0,80005e94 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e52:	ffffe097          	auipc	ra,0xffffe
    80005e56:	dea080e7          	jalr	-534(ra) # 80003c3c <ilock>
  if(ip->type != T_DIR){
    80005e5a:	04449703          	lh	a4,68(s1)
    80005e5e:	4785                	li	a5,1
    80005e60:	04f71063          	bne	a4,a5,80005ea0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e64:	8526                	mv	a0,s1
    80005e66:	ffffe097          	auipc	ra,0xffffe
    80005e6a:	e98080e7          	jalr	-360(ra) # 80003cfe <iunlock>
  iput(p->cwd);
    80005e6e:	15093503          	ld	a0,336(s2)
    80005e72:	ffffe097          	auipc	ra,0xffffe
    80005e76:	f84080e7          	jalr	-124(ra) # 80003df6 <iput>
  end_op();
    80005e7a:	ffffe097          	auipc	ra,0xffffe
    80005e7e:	7e2080e7          	jalr	2018(ra) # 8000465c <end_op>
  p->cwd = ip;
    80005e82:	14993823          	sd	s1,336(s2)
  return 0;
    80005e86:	4501                	li	a0,0
}
    80005e88:	60ea                	ld	ra,152(sp)
    80005e8a:	644a                	ld	s0,144(sp)
    80005e8c:	64aa                	ld	s1,136(sp)
    80005e8e:	690a                	ld	s2,128(sp)
    80005e90:	610d                	addi	sp,sp,160
    80005e92:	8082                	ret
    end_op();
    80005e94:	ffffe097          	auipc	ra,0xffffe
    80005e98:	7c8080e7          	jalr	1992(ra) # 8000465c <end_op>
    return -1;
    80005e9c:	557d                	li	a0,-1
    80005e9e:	b7ed                	j	80005e88 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ea0:	8526                	mv	a0,s1
    80005ea2:	ffffe097          	auipc	ra,0xffffe
    80005ea6:	ffc080e7          	jalr	-4(ra) # 80003e9e <iunlockput>
    end_op();
    80005eaa:	ffffe097          	auipc	ra,0xffffe
    80005eae:	7b2080e7          	jalr	1970(ra) # 8000465c <end_op>
    return -1;
    80005eb2:	557d                	li	a0,-1
    80005eb4:	bfd1                	j	80005e88 <sys_chdir+0x7a>

0000000080005eb6 <sys_exec>:

uint64
sys_exec(void)
{
    80005eb6:	7121                	addi	sp,sp,-448
    80005eb8:	ff06                	sd	ra,440(sp)
    80005eba:	fb22                	sd	s0,432(sp)
    80005ebc:	f726                	sd	s1,424(sp)
    80005ebe:	f34a                	sd	s2,416(sp)
    80005ec0:	ef4e                	sd	s3,408(sp)
    80005ec2:	eb52                	sd	s4,400(sp)
    80005ec4:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005ec6:	e4840593          	addi	a1,s0,-440
    80005eca:	4505                	li	a0,1
    80005ecc:	ffffd097          	auipc	ra,0xffffd
    80005ed0:	0ee080e7          	jalr	238(ra) # 80002fba <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005ed4:	08000613          	li	a2,128
    80005ed8:	f5040593          	addi	a1,s0,-176
    80005edc:	4501                	li	a0,0
    80005ede:	ffffd097          	auipc	ra,0xffffd
    80005ee2:	0fc080e7          	jalr	252(ra) # 80002fda <argstr>
    80005ee6:	87aa                	mv	a5,a0
    return -1;
    80005ee8:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005eea:	0c07c263          	bltz	a5,80005fae <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005eee:	10000613          	li	a2,256
    80005ef2:	4581                	li	a1,0
    80005ef4:	e5040513          	addi	a0,s0,-432
    80005ef8:	ffffb097          	auipc	ra,0xffffb
    80005efc:	f2e080e7          	jalr	-210(ra) # 80000e26 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f00:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005f04:	89a6                	mv	s3,s1
    80005f06:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f08:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f0c:	00391513          	slli	a0,s2,0x3
    80005f10:	e4040593          	addi	a1,s0,-448
    80005f14:	e4843783          	ld	a5,-440(s0)
    80005f18:	953e                	add	a0,a0,a5
    80005f1a:	ffffd097          	auipc	ra,0xffffd
    80005f1e:	fe2080e7          	jalr	-30(ra) # 80002efc <fetchaddr>
    80005f22:	02054a63          	bltz	a0,80005f56 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005f26:	e4043783          	ld	a5,-448(s0)
    80005f2a:	c3b9                	beqz	a5,80005f70 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f2c:	ffffb097          	auipc	ra,0xffffb
    80005f30:	c5e080e7          	jalr	-930(ra) # 80000b8a <kalloc>
    80005f34:	85aa                	mv	a1,a0
    80005f36:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f3a:	cd11                	beqz	a0,80005f56 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f3c:	6605                	lui	a2,0x1
    80005f3e:	e4043503          	ld	a0,-448(s0)
    80005f42:	ffffd097          	auipc	ra,0xffffd
    80005f46:	00c080e7          	jalr	12(ra) # 80002f4e <fetchstr>
    80005f4a:	00054663          	bltz	a0,80005f56 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005f4e:	0905                	addi	s2,s2,1
    80005f50:	09a1                	addi	s3,s3,8
    80005f52:	fb491de3          	bne	s2,s4,80005f0c <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f56:	f5040913          	addi	s2,s0,-176
    80005f5a:	6088                	ld	a0,0(s1)
    80005f5c:	c921                	beqz	a0,80005fac <sys_exec+0xf6>
    kfree(argv[i]);
    80005f5e:	ffffb097          	auipc	ra,0xffffb
    80005f62:	a98080e7          	jalr	-1384(ra) # 800009f6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f66:	04a1                	addi	s1,s1,8
    80005f68:	ff2499e3          	bne	s1,s2,80005f5a <sys_exec+0xa4>
  return -1;
    80005f6c:	557d                	li	a0,-1
    80005f6e:	a081                	j	80005fae <sys_exec+0xf8>
      argv[i] = 0;
    80005f70:	0009079b          	sext.w	a5,s2
    80005f74:	078e                	slli	a5,a5,0x3
    80005f76:	fd078793          	addi	a5,a5,-48
    80005f7a:	97a2                	add	a5,a5,s0
    80005f7c:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005f80:	e5040593          	addi	a1,s0,-432
    80005f84:	f5040513          	addi	a0,s0,-176
    80005f88:	fffff097          	auipc	ra,0xfffff
    80005f8c:	194080e7          	jalr	404(ra) # 8000511c <exec>
    80005f90:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f92:	f5040993          	addi	s3,s0,-176
    80005f96:	6088                	ld	a0,0(s1)
    80005f98:	c901                	beqz	a0,80005fa8 <sys_exec+0xf2>
    kfree(argv[i]);
    80005f9a:	ffffb097          	auipc	ra,0xffffb
    80005f9e:	a5c080e7          	jalr	-1444(ra) # 800009f6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fa2:	04a1                	addi	s1,s1,8
    80005fa4:	ff3499e3          	bne	s1,s3,80005f96 <sys_exec+0xe0>
  return ret;
    80005fa8:	854a                	mv	a0,s2
    80005faa:	a011                	j	80005fae <sys_exec+0xf8>
  return -1;
    80005fac:	557d                	li	a0,-1
}
    80005fae:	70fa                	ld	ra,440(sp)
    80005fb0:	745a                	ld	s0,432(sp)
    80005fb2:	74ba                	ld	s1,424(sp)
    80005fb4:	791a                	ld	s2,416(sp)
    80005fb6:	69fa                	ld	s3,408(sp)
    80005fb8:	6a5a                	ld	s4,400(sp)
    80005fba:	6139                	addi	sp,sp,448
    80005fbc:	8082                	ret

0000000080005fbe <sys_pipe>:

uint64
sys_pipe(void)
{
    80005fbe:	7139                	addi	sp,sp,-64
    80005fc0:	fc06                	sd	ra,56(sp)
    80005fc2:	f822                	sd	s0,48(sp)
    80005fc4:	f426                	sd	s1,40(sp)
    80005fc6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005fc8:	ffffc097          	auipc	ra,0xffffc
    80005fcc:	c94080e7          	jalr	-876(ra) # 80001c5c <myproc>
    80005fd0:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005fd2:	fd840593          	addi	a1,s0,-40
    80005fd6:	4501                	li	a0,0
    80005fd8:	ffffd097          	auipc	ra,0xffffd
    80005fdc:	fe2080e7          	jalr	-30(ra) # 80002fba <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005fe0:	fc840593          	addi	a1,s0,-56
    80005fe4:	fd040513          	addi	a0,s0,-48
    80005fe8:	fffff097          	auipc	ra,0xfffff
    80005fec:	dea080e7          	jalr	-534(ra) # 80004dd2 <pipealloc>
    return -1;
    80005ff0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ff2:	0c054463          	bltz	a0,800060ba <sys_pipe+0xfc>
  fd0 = -1;
    80005ff6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ffa:	fd043503          	ld	a0,-48(s0)
    80005ffe:	fffff097          	auipc	ra,0xfffff
    80006002:	524080e7          	jalr	1316(ra) # 80005522 <fdalloc>
    80006006:	fca42223          	sw	a0,-60(s0)
    8000600a:	08054b63          	bltz	a0,800060a0 <sys_pipe+0xe2>
    8000600e:	fc843503          	ld	a0,-56(s0)
    80006012:	fffff097          	auipc	ra,0xfffff
    80006016:	510080e7          	jalr	1296(ra) # 80005522 <fdalloc>
    8000601a:	fca42023          	sw	a0,-64(s0)
    8000601e:	06054863          	bltz	a0,8000608e <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006022:	4691                	li	a3,4
    80006024:	fc440613          	addi	a2,s0,-60
    80006028:	fd843583          	ld	a1,-40(s0)
    8000602c:	68a8                	ld	a0,80(s1)
    8000602e:	ffffb097          	auipc	ra,0xffffb
    80006032:	776080e7          	jalr	1910(ra) # 800017a4 <copyout>
    80006036:	02054063          	bltz	a0,80006056 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000603a:	4691                	li	a3,4
    8000603c:	fc040613          	addi	a2,s0,-64
    80006040:	fd843583          	ld	a1,-40(s0)
    80006044:	0591                	addi	a1,a1,4
    80006046:	68a8                	ld	a0,80(s1)
    80006048:	ffffb097          	auipc	ra,0xffffb
    8000604c:	75c080e7          	jalr	1884(ra) # 800017a4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006050:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006052:	06055463          	bgez	a0,800060ba <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006056:	fc442783          	lw	a5,-60(s0)
    8000605a:	07e9                	addi	a5,a5,26
    8000605c:	078e                	slli	a5,a5,0x3
    8000605e:	97a6                	add	a5,a5,s1
    80006060:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006064:	fc042783          	lw	a5,-64(s0)
    80006068:	07e9                	addi	a5,a5,26
    8000606a:	078e                	slli	a5,a5,0x3
    8000606c:	94be                	add	s1,s1,a5
    8000606e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006072:	fd043503          	ld	a0,-48(s0)
    80006076:	fffff097          	auipc	ra,0xfffff
    8000607a:	a30080e7          	jalr	-1488(ra) # 80004aa6 <fileclose>
    fileclose(wf);
    8000607e:	fc843503          	ld	a0,-56(s0)
    80006082:	fffff097          	auipc	ra,0xfffff
    80006086:	a24080e7          	jalr	-1500(ra) # 80004aa6 <fileclose>
    return -1;
    8000608a:	57fd                	li	a5,-1
    8000608c:	a03d                	j	800060ba <sys_pipe+0xfc>
    if(fd0 >= 0)
    8000608e:	fc442783          	lw	a5,-60(s0)
    80006092:	0007c763          	bltz	a5,800060a0 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006096:	07e9                	addi	a5,a5,26
    80006098:	078e                	slli	a5,a5,0x3
    8000609a:	97a6                	add	a5,a5,s1
    8000609c:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800060a0:	fd043503          	ld	a0,-48(s0)
    800060a4:	fffff097          	auipc	ra,0xfffff
    800060a8:	a02080e7          	jalr	-1534(ra) # 80004aa6 <fileclose>
    fileclose(wf);
    800060ac:	fc843503          	ld	a0,-56(s0)
    800060b0:	fffff097          	auipc	ra,0xfffff
    800060b4:	9f6080e7          	jalr	-1546(ra) # 80004aa6 <fileclose>
    return -1;
    800060b8:	57fd                	li	a5,-1
}
    800060ba:	853e                	mv	a0,a5
    800060bc:	70e2                	ld	ra,56(sp)
    800060be:	7442                	ld	s0,48(sp)
    800060c0:	74a2                	ld	s1,40(sp)
    800060c2:	6121                	addi	sp,sp,64
    800060c4:	8082                	ret
	...

00000000800060d0 <kernelvec>:
    800060d0:	7111                	addi	sp,sp,-256
    800060d2:	e006                	sd	ra,0(sp)
    800060d4:	e40a                	sd	sp,8(sp)
    800060d6:	e80e                	sd	gp,16(sp)
    800060d8:	ec12                	sd	tp,24(sp)
    800060da:	f016                	sd	t0,32(sp)
    800060dc:	f41a                	sd	t1,40(sp)
    800060de:	f81e                	sd	t2,48(sp)
    800060e0:	fc22                	sd	s0,56(sp)
    800060e2:	e0a6                	sd	s1,64(sp)
    800060e4:	e4aa                	sd	a0,72(sp)
    800060e6:	e8ae                	sd	a1,80(sp)
    800060e8:	ecb2                	sd	a2,88(sp)
    800060ea:	f0b6                	sd	a3,96(sp)
    800060ec:	f4ba                	sd	a4,104(sp)
    800060ee:	f8be                	sd	a5,112(sp)
    800060f0:	fcc2                	sd	a6,120(sp)
    800060f2:	e146                	sd	a7,128(sp)
    800060f4:	e54a                	sd	s2,136(sp)
    800060f6:	e94e                	sd	s3,144(sp)
    800060f8:	ed52                	sd	s4,152(sp)
    800060fa:	f156                	sd	s5,160(sp)
    800060fc:	f55a                	sd	s6,168(sp)
    800060fe:	f95e                	sd	s7,176(sp)
    80006100:	fd62                	sd	s8,184(sp)
    80006102:	e1e6                	sd	s9,192(sp)
    80006104:	e5ea                	sd	s10,200(sp)
    80006106:	e9ee                	sd	s11,208(sp)
    80006108:	edf2                	sd	t3,216(sp)
    8000610a:	f1f6                	sd	t4,224(sp)
    8000610c:	f5fa                	sd	t5,232(sp)
    8000610e:	f9fe                	sd	t6,240(sp)
    80006110:	cb9fc0ef          	jal	ra,80002dc8 <kerneltrap>
    80006114:	6082                	ld	ra,0(sp)
    80006116:	6122                	ld	sp,8(sp)
    80006118:	61c2                	ld	gp,16(sp)
    8000611a:	7282                	ld	t0,32(sp)
    8000611c:	7322                	ld	t1,40(sp)
    8000611e:	73c2                	ld	t2,48(sp)
    80006120:	7462                	ld	s0,56(sp)
    80006122:	6486                	ld	s1,64(sp)
    80006124:	6526                	ld	a0,72(sp)
    80006126:	65c6                	ld	a1,80(sp)
    80006128:	6666                	ld	a2,88(sp)
    8000612a:	7686                	ld	a3,96(sp)
    8000612c:	7726                	ld	a4,104(sp)
    8000612e:	77c6                	ld	a5,112(sp)
    80006130:	7866                	ld	a6,120(sp)
    80006132:	688a                	ld	a7,128(sp)
    80006134:	692a                	ld	s2,136(sp)
    80006136:	69ca                	ld	s3,144(sp)
    80006138:	6a6a                	ld	s4,152(sp)
    8000613a:	7a8a                	ld	s5,160(sp)
    8000613c:	7b2a                	ld	s6,168(sp)
    8000613e:	7bca                	ld	s7,176(sp)
    80006140:	7c6a                	ld	s8,184(sp)
    80006142:	6c8e                	ld	s9,192(sp)
    80006144:	6d2e                	ld	s10,200(sp)
    80006146:	6dce                	ld	s11,208(sp)
    80006148:	6e6e                	ld	t3,216(sp)
    8000614a:	7e8e                	ld	t4,224(sp)
    8000614c:	7f2e                	ld	t5,232(sp)
    8000614e:	7fce                	ld	t6,240(sp)
    80006150:	6111                	addi	sp,sp,256
    80006152:	10200073          	sret
    80006156:	00000013          	nop
    8000615a:	00000013          	nop
    8000615e:	0001                	nop

0000000080006160 <timervec>:
    80006160:	34051573          	csrrw	a0,mscratch,a0
    80006164:	e10c                	sd	a1,0(a0)
    80006166:	e510                	sd	a2,8(a0)
    80006168:	e914                	sd	a3,16(a0)
    8000616a:	6d0c                	ld	a1,24(a0)
    8000616c:	7110                	ld	a2,32(a0)
    8000616e:	6194                	ld	a3,0(a1)
    80006170:	96b2                	add	a3,a3,a2
    80006172:	e194                	sd	a3,0(a1)
    80006174:	4589                	li	a1,2
    80006176:	14459073          	csrw	sip,a1
    8000617a:	6914                	ld	a3,16(a0)
    8000617c:	6510                	ld	a2,8(a0)
    8000617e:	610c                	ld	a1,0(a0)
    80006180:	34051573          	csrrw	a0,mscratch,a0
    80006184:	30200073          	mret
	...

000000008000618a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000618a:	1141                	addi	sp,sp,-16
    8000618c:	e422                	sd	s0,8(sp)
    8000618e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006190:	0c0007b7          	lui	a5,0xc000
    80006194:	4705                	li	a4,1
    80006196:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006198:	c3d8                	sw	a4,4(a5)
}
    8000619a:	6422                	ld	s0,8(sp)
    8000619c:	0141                	addi	sp,sp,16
    8000619e:	8082                	ret

00000000800061a0 <plicinithart>:

void
plicinithart(void)
{
    800061a0:	1141                	addi	sp,sp,-16
    800061a2:	e406                	sd	ra,8(sp)
    800061a4:	e022                	sd	s0,0(sp)
    800061a6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061a8:	ffffc097          	auipc	ra,0xffffc
    800061ac:	a88080e7          	jalr	-1400(ra) # 80001c30 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800061b0:	0085171b          	slliw	a4,a0,0x8
    800061b4:	0c0027b7          	lui	a5,0xc002
    800061b8:	97ba                	add	a5,a5,a4
    800061ba:	40200713          	li	a4,1026
    800061be:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800061c2:	00d5151b          	slliw	a0,a0,0xd
    800061c6:	0c2017b7          	lui	a5,0xc201
    800061ca:	97aa                	add	a5,a5,a0
    800061cc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800061d0:	60a2                	ld	ra,8(sp)
    800061d2:	6402                	ld	s0,0(sp)
    800061d4:	0141                	addi	sp,sp,16
    800061d6:	8082                	ret

00000000800061d8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800061d8:	1141                	addi	sp,sp,-16
    800061da:	e406                	sd	ra,8(sp)
    800061dc:	e022                	sd	s0,0(sp)
    800061de:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061e0:	ffffc097          	auipc	ra,0xffffc
    800061e4:	a50080e7          	jalr	-1456(ra) # 80001c30 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800061e8:	00d5151b          	slliw	a0,a0,0xd
    800061ec:	0c2017b7          	lui	a5,0xc201
    800061f0:	97aa                	add	a5,a5,a0
  return irq;
}
    800061f2:	43c8                	lw	a0,4(a5)
    800061f4:	60a2                	ld	ra,8(sp)
    800061f6:	6402                	ld	s0,0(sp)
    800061f8:	0141                	addi	sp,sp,16
    800061fa:	8082                	ret

00000000800061fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061fc:	1101                	addi	sp,sp,-32
    800061fe:	ec06                	sd	ra,24(sp)
    80006200:	e822                	sd	s0,16(sp)
    80006202:	e426                	sd	s1,8(sp)
    80006204:	1000                	addi	s0,sp,32
    80006206:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006208:	ffffc097          	auipc	ra,0xffffc
    8000620c:	a28080e7          	jalr	-1496(ra) # 80001c30 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006210:	00d5151b          	slliw	a0,a0,0xd
    80006214:	0c2017b7          	lui	a5,0xc201
    80006218:	97aa                	add	a5,a5,a0
    8000621a:	c3c4                	sw	s1,4(a5)
}
    8000621c:	60e2                	ld	ra,24(sp)
    8000621e:	6442                	ld	s0,16(sp)
    80006220:	64a2                	ld	s1,8(sp)
    80006222:	6105                	addi	sp,sp,32
    80006224:	8082                	ret

0000000080006226 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006226:	1141                	addi	sp,sp,-16
    80006228:	e406                	sd	ra,8(sp)
    8000622a:	e022                	sd	s0,0(sp)
    8000622c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000622e:	479d                	li	a5,7
    80006230:	04a7cc63          	blt	a5,a0,80006288 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006234:	0023c797          	auipc	a5,0x23c
    80006238:	b3c78793          	addi	a5,a5,-1220 # 80241d70 <disk>
    8000623c:	97aa                	add	a5,a5,a0
    8000623e:	0187c783          	lbu	a5,24(a5)
    80006242:	ebb9                	bnez	a5,80006298 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006244:	00451693          	slli	a3,a0,0x4
    80006248:	0023c797          	auipc	a5,0x23c
    8000624c:	b2878793          	addi	a5,a5,-1240 # 80241d70 <disk>
    80006250:	6398                	ld	a4,0(a5)
    80006252:	9736                	add	a4,a4,a3
    80006254:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006258:	6398                	ld	a4,0(a5)
    8000625a:	9736                	add	a4,a4,a3
    8000625c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006260:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006264:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006268:	97aa                	add	a5,a5,a0
    8000626a:	4705                	li	a4,1
    8000626c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006270:	0023c517          	auipc	a0,0x23c
    80006274:	b1850513          	addi	a0,a0,-1256 # 80241d88 <disk+0x18>
    80006278:	ffffc097          	auipc	ra,0xffffc
    8000627c:	1b0080e7          	jalr	432(ra) # 80002428 <wakeup>
}
    80006280:	60a2                	ld	ra,8(sp)
    80006282:	6402                	ld	s0,0(sp)
    80006284:	0141                	addi	sp,sp,16
    80006286:	8082                	ret
    panic("free_desc 1");
    80006288:	00002517          	auipc	a0,0x2
    8000628c:	5e850513          	addi	a0,a0,1512 # 80008870 <syscalls+0x318>
    80006290:	ffffa097          	auipc	ra,0xffffa
    80006294:	2ac080e7          	jalr	684(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006298:	00002517          	auipc	a0,0x2
    8000629c:	5e850513          	addi	a0,a0,1512 # 80008880 <syscalls+0x328>
    800062a0:	ffffa097          	auipc	ra,0xffffa
    800062a4:	29c080e7          	jalr	668(ra) # 8000053c <panic>

00000000800062a8 <virtio_disk_init>:
{
    800062a8:	1101                	addi	sp,sp,-32
    800062aa:	ec06                	sd	ra,24(sp)
    800062ac:	e822                	sd	s0,16(sp)
    800062ae:	e426                	sd	s1,8(sp)
    800062b0:	e04a                	sd	s2,0(sp)
    800062b2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800062b4:	00002597          	auipc	a1,0x2
    800062b8:	5dc58593          	addi	a1,a1,1500 # 80008890 <syscalls+0x338>
    800062bc:	0023c517          	auipc	a0,0x23c
    800062c0:	bdc50513          	addi	a0,a0,-1060 # 80241e98 <disk+0x128>
    800062c4:	ffffb097          	auipc	ra,0xffffb
    800062c8:	9d6080e7          	jalr	-1578(ra) # 80000c9a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062cc:	100017b7          	lui	a5,0x10001
    800062d0:	4398                	lw	a4,0(a5)
    800062d2:	2701                	sext.w	a4,a4
    800062d4:	747277b7          	lui	a5,0x74727
    800062d8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800062dc:	14f71b63          	bne	a4,a5,80006432 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800062e0:	100017b7          	lui	a5,0x10001
    800062e4:	43dc                	lw	a5,4(a5)
    800062e6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062e8:	4709                	li	a4,2
    800062ea:	14e79463          	bne	a5,a4,80006432 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062ee:	100017b7          	lui	a5,0x10001
    800062f2:	479c                	lw	a5,8(a5)
    800062f4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800062f6:	12e79e63          	bne	a5,a4,80006432 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800062fa:	100017b7          	lui	a5,0x10001
    800062fe:	47d8                	lw	a4,12(a5)
    80006300:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006302:	554d47b7          	lui	a5,0x554d4
    80006306:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000630a:	12f71463          	bne	a4,a5,80006432 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000630e:	100017b7          	lui	a5,0x10001
    80006312:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006316:	4705                	li	a4,1
    80006318:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000631a:	470d                	li	a4,3
    8000631c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000631e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006320:	c7ffe6b7          	lui	a3,0xc7ffe
    80006324:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47dbc8af>
    80006328:	8f75                	and	a4,a4,a3
    8000632a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000632c:	472d                	li	a4,11
    8000632e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006330:	5bbc                	lw	a5,112(a5)
    80006332:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006336:	8ba1                	andi	a5,a5,8
    80006338:	10078563          	beqz	a5,80006442 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000633c:	100017b7          	lui	a5,0x10001
    80006340:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006344:	43fc                	lw	a5,68(a5)
    80006346:	2781                	sext.w	a5,a5
    80006348:	10079563          	bnez	a5,80006452 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000634c:	100017b7          	lui	a5,0x10001
    80006350:	5bdc                	lw	a5,52(a5)
    80006352:	2781                	sext.w	a5,a5
  if(max == 0)
    80006354:	10078763          	beqz	a5,80006462 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006358:	471d                	li	a4,7
    8000635a:	10f77c63          	bgeu	a4,a5,80006472 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000635e:	ffffb097          	auipc	ra,0xffffb
    80006362:	82c080e7          	jalr	-2004(ra) # 80000b8a <kalloc>
    80006366:	0023c497          	auipc	s1,0x23c
    8000636a:	a0a48493          	addi	s1,s1,-1526 # 80241d70 <disk>
    8000636e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006370:	ffffb097          	auipc	ra,0xffffb
    80006374:	81a080e7          	jalr	-2022(ra) # 80000b8a <kalloc>
    80006378:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000637a:	ffffb097          	auipc	ra,0xffffb
    8000637e:	810080e7          	jalr	-2032(ra) # 80000b8a <kalloc>
    80006382:	87aa                	mv	a5,a0
    80006384:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006386:	6088                	ld	a0,0(s1)
    80006388:	cd6d                	beqz	a0,80006482 <virtio_disk_init+0x1da>
    8000638a:	0023c717          	auipc	a4,0x23c
    8000638e:	9ee73703          	ld	a4,-1554(a4) # 80241d78 <disk+0x8>
    80006392:	cb65                	beqz	a4,80006482 <virtio_disk_init+0x1da>
    80006394:	c7fd                	beqz	a5,80006482 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006396:	6605                	lui	a2,0x1
    80006398:	4581                	li	a1,0
    8000639a:	ffffb097          	auipc	ra,0xffffb
    8000639e:	a8c080e7          	jalr	-1396(ra) # 80000e26 <memset>
  memset(disk.avail, 0, PGSIZE);
    800063a2:	0023c497          	auipc	s1,0x23c
    800063a6:	9ce48493          	addi	s1,s1,-1586 # 80241d70 <disk>
    800063aa:	6605                	lui	a2,0x1
    800063ac:	4581                	li	a1,0
    800063ae:	6488                	ld	a0,8(s1)
    800063b0:	ffffb097          	auipc	ra,0xffffb
    800063b4:	a76080e7          	jalr	-1418(ra) # 80000e26 <memset>
  memset(disk.used, 0, PGSIZE);
    800063b8:	6605                	lui	a2,0x1
    800063ba:	4581                	li	a1,0
    800063bc:	6888                	ld	a0,16(s1)
    800063be:	ffffb097          	auipc	ra,0xffffb
    800063c2:	a68080e7          	jalr	-1432(ra) # 80000e26 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800063c6:	100017b7          	lui	a5,0x10001
    800063ca:	4721                	li	a4,8
    800063cc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800063ce:	4098                	lw	a4,0(s1)
    800063d0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800063d4:	40d8                	lw	a4,4(s1)
    800063d6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800063da:	6498                	ld	a4,8(s1)
    800063dc:	0007069b          	sext.w	a3,a4
    800063e0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800063e4:	9701                	srai	a4,a4,0x20
    800063e6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800063ea:	6898                	ld	a4,16(s1)
    800063ec:	0007069b          	sext.w	a3,a4
    800063f0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800063f4:	9701                	srai	a4,a4,0x20
    800063f6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800063fa:	4705                	li	a4,1
    800063fc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800063fe:	00e48c23          	sb	a4,24(s1)
    80006402:	00e48ca3          	sb	a4,25(s1)
    80006406:	00e48d23          	sb	a4,26(s1)
    8000640a:	00e48da3          	sb	a4,27(s1)
    8000640e:	00e48e23          	sb	a4,28(s1)
    80006412:	00e48ea3          	sb	a4,29(s1)
    80006416:	00e48f23          	sb	a4,30(s1)
    8000641a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000641e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006422:	0727a823          	sw	s2,112(a5)
}
    80006426:	60e2                	ld	ra,24(sp)
    80006428:	6442                	ld	s0,16(sp)
    8000642a:	64a2                	ld	s1,8(sp)
    8000642c:	6902                	ld	s2,0(sp)
    8000642e:	6105                	addi	sp,sp,32
    80006430:	8082                	ret
    panic("could not find virtio disk");
    80006432:	00002517          	auipc	a0,0x2
    80006436:	46e50513          	addi	a0,a0,1134 # 800088a0 <syscalls+0x348>
    8000643a:	ffffa097          	auipc	ra,0xffffa
    8000643e:	102080e7          	jalr	258(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80006442:	00002517          	auipc	a0,0x2
    80006446:	47e50513          	addi	a0,a0,1150 # 800088c0 <syscalls+0x368>
    8000644a:	ffffa097          	auipc	ra,0xffffa
    8000644e:	0f2080e7          	jalr	242(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006452:	00002517          	auipc	a0,0x2
    80006456:	48e50513          	addi	a0,a0,1166 # 800088e0 <syscalls+0x388>
    8000645a:	ffffa097          	auipc	ra,0xffffa
    8000645e:	0e2080e7          	jalr	226(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006462:	00002517          	auipc	a0,0x2
    80006466:	49e50513          	addi	a0,a0,1182 # 80008900 <syscalls+0x3a8>
    8000646a:	ffffa097          	auipc	ra,0xffffa
    8000646e:	0d2080e7          	jalr	210(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006472:	00002517          	auipc	a0,0x2
    80006476:	4ae50513          	addi	a0,a0,1198 # 80008920 <syscalls+0x3c8>
    8000647a:	ffffa097          	auipc	ra,0xffffa
    8000647e:	0c2080e7          	jalr	194(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006482:	00002517          	auipc	a0,0x2
    80006486:	4be50513          	addi	a0,a0,1214 # 80008940 <syscalls+0x3e8>
    8000648a:	ffffa097          	auipc	ra,0xffffa
    8000648e:	0b2080e7          	jalr	178(ra) # 8000053c <panic>

0000000080006492 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006492:	7159                	addi	sp,sp,-112
    80006494:	f486                	sd	ra,104(sp)
    80006496:	f0a2                	sd	s0,96(sp)
    80006498:	eca6                	sd	s1,88(sp)
    8000649a:	e8ca                	sd	s2,80(sp)
    8000649c:	e4ce                	sd	s3,72(sp)
    8000649e:	e0d2                	sd	s4,64(sp)
    800064a0:	fc56                	sd	s5,56(sp)
    800064a2:	f85a                	sd	s6,48(sp)
    800064a4:	f45e                	sd	s7,40(sp)
    800064a6:	f062                	sd	s8,32(sp)
    800064a8:	ec66                	sd	s9,24(sp)
    800064aa:	e86a                	sd	s10,16(sp)
    800064ac:	1880                	addi	s0,sp,112
    800064ae:	8a2a                	mv	s4,a0
    800064b0:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800064b2:	00c52c83          	lw	s9,12(a0)
    800064b6:	001c9c9b          	slliw	s9,s9,0x1
    800064ba:	1c82                	slli	s9,s9,0x20
    800064bc:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800064c0:	0023c517          	auipc	a0,0x23c
    800064c4:	9d850513          	addi	a0,a0,-1576 # 80241e98 <disk+0x128>
    800064c8:	ffffb097          	auipc	ra,0xffffb
    800064cc:	862080e7          	jalr	-1950(ra) # 80000d2a <acquire>
  for(int i = 0; i < 3; i++){
    800064d0:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    800064d2:	44a1                	li	s1,8
      disk.free[i] = 0;
    800064d4:	0023cb17          	auipc	s6,0x23c
    800064d8:	89cb0b13          	addi	s6,s6,-1892 # 80241d70 <disk>
  for(int i = 0; i < 3; i++){
    800064dc:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064de:	0023cc17          	auipc	s8,0x23c
    800064e2:	9bac0c13          	addi	s8,s8,-1606 # 80241e98 <disk+0x128>
    800064e6:	a095                	j	8000654a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800064e8:	00fb0733          	add	a4,s6,a5
    800064ec:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800064f0:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    800064f2:	0207c563          	bltz	a5,8000651c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    800064f6:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    800064f8:	0591                	addi	a1,a1,4
    800064fa:	05560d63          	beq	a2,s5,80006554 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800064fe:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006500:	0023c717          	auipc	a4,0x23c
    80006504:	87070713          	addi	a4,a4,-1936 # 80241d70 <disk>
    80006508:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000650a:	01874683          	lbu	a3,24(a4)
    8000650e:	fee9                	bnez	a3,800064e8 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006510:	2785                	addiw	a5,a5,1
    80006512:	0705                	addi	a4,a4,1
    80006514:	fe979be3          	bne	a5,s1,8000650a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006518:	57fd                	li	a5,-1
    8000651a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000651c:	00c05e63          	blez	a2,80006538 <virtio_disk_rw+0xa6>
    80006520:	060a                	slli	a2,a2,0x2
    80006522:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006526:	0009a503          	lw	a0,0(s3)
    8000652a:	00000097          	auipc	ra,0x0
    8000652e:	cfc080e7          	jalr	-772(ra) # 80006226 <free_desc>
      for(int j = 0; j < i; j++)
    80006532:	0991                	addi	s3,s3,4
    80006534:	ffa999e3          	bne	s3,s10,80006526 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006538:	85e2                	mv	a1,s8
    8000653a:	0023c517          	auipc	a0,0x23c
    8000653e:	84e50513          	addi	a0,a0,-1970 # 80241d88 <disk+0x18>
    80006542:	ffffc097          	auipc	ra,0xffffc
    80006546:	e82080e7          	jalr	-382(ra) # 800023c4 <sleep>
  for(int i = 0; i < 3; i++){
    8000654a:	f9040993          	addi	s3,s0,-112
{
    8000654e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006550:	864a                	mv	a2,s2
    80006552:	b775                	j	800064fe <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006554:	f9042503          	lw	a0,-112(s0)
    80006558:	00a50713          	addi	a4,a0,10
    8000655c:	0712                	slli	a4,a4,0x4

  if(write)
    8000655e:	0023c797          	auipc	a5,0x23c
    80006562:	81278793          	addi	a5,a5,-2030 # 80241d70 <disk>
    80006566:	00e786b3          	add	a3,a5,a4
    8000656a:	01703633          	snez	a2,s7
    8000656e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006570:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006574:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006578:	f6070613          	addi	a2,a4,-160
    8000657c:	6394                	ld	a3,0(a5)
    8000657e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006580:	00870593          	addi	a1,a4,8
    80006584:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006586:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006588:	0007b803          	ld	a6,0(a5)
    8000658c:	9642                	add	a2,a2,a6
    8000658e:	46c1                	li	a3,16
    80006590:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006592:	4585                	li	a1,1
    80006594:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006598:	f9442683          	lw	a3,-108(s0)
    8000659c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800065a0:	0692                	slli	a3,a3,0x4
    800065a2:	9836                	add	a6,a6,a3
    800065a4:	058a0613          	addi	a2,s4,88
    800065a8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800065ac:	0007b803          	ld	a6,0(a5)
    800065b0:	96c2                	add	a3,a3,a6
    800065b2:	40000613          	li	a2,1024
    800065b6:	c690                	sw	a2,8(a3)
  if(write)
    800065b8:	001bb613          	seqz	a2,s7
    800065bc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800065c0:	00166613          	ori	a2,a2,1
    800065c4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800065c8:	f9842603          	lw	a2,-104(s0)
    800065cc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800065d0:	00250693          	addi	a3,a0,2
    800065d4:	0692                	slli	a3,a3,0x4
    800065d6:	96be                	add	a3,a3,a5
    800065d8:	58fd                	li	a7,-1
    800065da:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800065de:	0612                	slli	a2,a2,0x4
    800065e0:	9832                	add	a6,a6,a2
    800065e2:	f9070713          	addi	a4,a4,-112
    800065e6:	973e                	add	a4,a4,a5
    800065e8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800065ec:	6398                	ld	a4,0(a5)
    800065ee:	9732                	add	a4,a4,a2
    800065f0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800065f2:	4609                	li	a2,2
    800065f4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800065f8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800065fc:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006600:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006604:	6794                	ld	a3,8(a5)
    80006606:	0026d703          	lhu	a4,2(a3)
    8000660a:	8b1d                	andi	a4,a4,7
    8000660c:	0706                	slli	a4,a4,0x1
    8000660e:	96ba                	add	a3,a3,a4
    80006610:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006614:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006618:	6798                	ld	a4,8(a5)
    8000661a:	00275783          	lhu	a5,2(a4)
    8000661e:	2785                	addiw	a5,a5,1
    80006620:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006624:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006628:	100017b7          	lui	a5,0x10001
    8000662c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006630:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006634:	0023c917          	auipc	s2,0x23c
    80006638:	86490913          	addi	s2,s2,-1948 # 80241e98 <disk+0x128>
  while(b->disk == 1) {
    8000663c:	4485                	li	s1,1
    8000663e:	00b79c63          	bne	a5,a1,80006656 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006642:	85ca                	mv	a1,s2
    80006644:	8552                	mv	a0,s4
    80006646:	ffffc097          	auipc	ra,0xffffc
    8000664a:	d7e080e7          	jalr	-642(ra) # 800023c4 <sleep>
  while(b->disk == 1) {
    8000664e:	004a2783          	lw	a5,4(s4)
    80006652:	fe9788e3          	beq	a5,s1,80006642 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006656:	f9042903          	lw	s2,-112(s0)
    8000665a:	00290713          	addi	a4,s2,2
    8000665e:	0712                	slli	a4,a4,0x4
    80006660:	0023b797          	auipc	a5,0x23b
    80006664:	71078793          	addi	a5,a5,1808 # 80241d70 <disk>
    80006668:	97ba                	add	a5,a5,a4
    8000666a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000666e:	0023b997          	auipc	s3,0x23b
    80006672:	70298993          	addi	s3,s3,1794 # 80241d70 <disk>
    80006676:	00491713          	slli	a4,s2,0x4
    8000667a:	0009b783          	ld	a5,0(s3)
    8000667e:	97ba                	add	a5,a5,a4
    80006680:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006684:	854a                	mv	a0,s2
    80006686:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000668a:	00000097          	auipc	ra,0x0
    8000668e:	b9c080e7          	jalr	-1124(ra) # 80006226 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006692:	8885                	andi	s1,s1,1
    80006694:	f0ed                	bnez	s1,80006676 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006696:	0023c517          	auipc	a0,0x23c
    8000669a:	80250513          	addi	a0,a0,-2046 # 80241e98 <disk+0x128>
    8000669e:	ffffa097          	auipc	ra,0xffffa
    800066a2:	740080e7          	jalr	1856(ra) # 80000dde <release>
}
    800066a6:	70a6                	ld	ra,104(sp)
    800066a8:	7406                	ld	s0,96(sp)
    800066aa:	64e6                	ld	s1,88(sp)
    800066ac:	6946                	ld	s2,80(sp)
    800066ae:	69a6                	ld	s3,72(sp)
    800066b0:	6a06                	ld	s4,64(sp)
    800066b2:	7ae2                	ld	s5,56(sp)
    800066b4:	7b42                	ld	s6,48(sp)
    800066b6:	7ba2                	ld	s7,40(sp)
    800066b8:	7c02                	ld	s8,32(sp)
    800066ba:	6ce2                	ld	s9,24(sp)
    800066bc:	6d42                	ld	s10,16(sp)
    800066be:	6165                	addi	sp,sp,112
    800066c0:	8082                	ret

00000000800066c2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800066c2:	1101                	addi	sp,sp,-32
    800066c4:	ec06                	sd	ra,24(sp)
    800066c6:	e822                	sd	s0,16(sp)
    800066c8:	e426                	sd	s1,8(sp)
    800066ca:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800066cc:	0023b497          	auipc	s1,0x23b
    800066d0:	6a448493          	addi	s1,s1,1700 # 80241d70 <disk>
    800066d4:	0023b517          	auipc	a0,0x23b
    800066d8:	7c450513          	addi	a0,a0,1988 # 80241e98 <disk+0x128>
    800066dc:	ffffa097          	auipc	ra,0xffffa
    800066e0:	64e080e7          	jalr	1614(ra) # 80000d2a <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800066e4:	10001737          	lui	a4,0x10001
    800066e8:	533c                	lw	a5,96(a4)
    800066ea:	8b8d                	andi	a5,a5,3
    800066ec:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800066ee:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800066f2:	689c                	ld	a5,16(s1)
    800066f4:	0204d703          	lhu	a4,32(s1)
    800066f8:	0027d783          	lhu	a5,2(a5)
    800066fc:	04f70863          	beq	a4,a5,8000674c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006700:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006704:	6898                	ld	a4,16(s1)
    80006706:	0204d783          	lhu	a5,32(s1)
    8000670a:	8b9d                	andi	a5,a5,7
    8000670c:	078e                	slli	a5,a5,0x3
    8000670e:	97ba                	add	a5,a5,a4
    80006710:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006712:	00278713          	addi	a4,a5,2
    80006716:	0712                	slli	a4,a4,0x4
    80006718:	9726                	add	a4,a4,s1
    8000671a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000671e:	e721                	bnez	a4,80006766 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006720:	0789                	addi	a5,a5,2
    80006722:	0792                	slli	a5,a5,0x4
    80006724:	97a6                	add	a5,a5,s1
    80006726:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006728:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000672c:	ffffc097          	auipc	ra,0xffffc
    80006730:	cfc080e7          	jalr	-772(ra) # 80002428 <wakeup>

    disk.used_idx += 1;
    80006734:	0204d783          	lhu	a5,32(s1)
    80006738:	2785                	addiw	a5,a5,1
    8000673a:	17c2                	slli	a5,a5,0x30
    8000673c:	93c1                	srli	a5,a5,0x30
    8000673e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006742:	6898                	ld	a4,16(s1)
    80006744:	00275703          	lhu	a4,2(a4)
    80006748:	faf71ce3          	bne	a4,a5,80006700 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000674c:	0023b517          	auipc	a0,0x23b
    80006750:	74c50513          	addi	a0,a0,1868 # 80241e98 <disk+0x128>
    80006754:	ffffa097          	auipc	ra,0xffffa
    80006758:	68a080e7          	jalr	1674(ra) # 80000dde <release>
}
    8000675c:	60e2                	ld	ra,24(sp)
    8000675e:	6442                	ld	s0,16(sp)
    80006760:	64a2                	ld	s1,8(sp)
    80006762:	6105                	addi	sp,sp,32
    80006764:	8082                	ret
      panic("virtio_disk_intr status");
    80006766:	00002517          	auipc	a0,0x2
    8000676a:	1f250513          	addi	a0,a0,498 # 80008958 <syscalls+0x400>
    8000676e:	ffffa097          	auipc	ra,0xffffa
    80006772:	dce080e7          	jalr	-562(ra) # 8000053c <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
