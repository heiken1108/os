
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	be010113          	addi	sp,sp,-1056 # 80008be0 <stack0>
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
    80000054:	a5070713          	addi	a4,a4,-1456 # 80008aa0 <timer_scratch>
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
    80000066:	f2e78793          	addi	a5,a5,-210 # 80005f90 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc8ef>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	e8e78793          	addi	a5,a5,-370 # 80000f3a <main>
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
    8000012e:	5fe080e7          	jalr	1534(ra) # 80002728 <either_copyin>
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
    80000188:	a5c50513          	addi	a0,a0,-1444 # 80010be0 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	b0e080e7          	jalr	-1266(ra) # 80000c9a <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    80000194:	00011497          	auipc	s1,0x11
    80000198:	a4c48493          	addi	s1,s1,-1460 # 80010be0 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	adc90913          	addi	s2,s2,-1316 # 80010c78 <cons+0x98>
    while (n > 0)
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
        while (cons.r == cons.w)
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
            if (killed(myproc()))
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	9ae080e7          	jalr	-1618(ra) # 80001b62 <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	3b6080e7          	jalr	950(ra) # 80002572 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
            sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	100080e7          	jalr	256(ra) # 800022ca <sleep>
        while (cons.r == cons.w)
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	a0270713          	addi	a4,a4,-1534 # 80010be0 <cons>
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
    80000214:	4c2080e7          	jalr	1218(ra) # 800026d2 <either_copyout>
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
    8000022c:	9b850513          	addi	a0,a0,-1608 # 80010be0 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	b1e080e7          	jalr	-1250(ra) # 80000d4e <release>

    return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
                release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	9a250513          	addi	a0,a0,-1630 # 80010be0 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	b08080e7          	jalr	-1272(ra) # 80000d4e <release>
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
    80000272:	a0f72523          	sw	a5,-1526(a4) # 80010c78 <cons+0x98>
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
    800002cc:	91850513          	addi	a0,a0,-1768 # 80010be0 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	9ca080e7          	jalr	-1590(ra) # 80000c9a <acquire>

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
    800002f2:	490080e7          	jalr	1168(ra) # 8000277e <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002f6:	00011517          	auipc	a0,0x11
    800002fa:	8ea50513          	addi	a0,a0,-1814 # 80010be0 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	a50080e7          	jalr	-1456(ra) # 80000d4e <release>
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
    8000031e:	8c670713          	addi	a4,a4,-1850 # 80010be0 <cons>
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
    80000348:	89c78793          	addi	a5,a5,-1892 # 80010be0 <cons>
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
    80000376:	9067a783          	lw	a5,-1786(a5) # 80010c78 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
        while (cons.e != cons.w &&
    80000386:	00011717          	auipc	a4,0x11
    8000038a:	85a70713          	addi	a4,a4,-1958 # 80010be0 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    80000396:	00011497          	auipc	s1,0x11
    8000039a:	84a48493          	addi	s1,s1,-1974 # 80010be0 <cons>
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
    800003d2:	00011717          	auipc	a4,0x11
    800003d6:	80e70713          	addi	a4,a4,-2034 # 80010be0 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
            cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	88f72c23          	sw	a5,-1896(a4) # 80010c80 <cons+0xa0>
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
    80000412:	7d278793          	addi	a5,a5,2002 # 80010be0 <cons>
    80000416:	0a07a703          	lw	a4,160(a5)
    8000041a:	0017069b          	addiw	a3,a4,1
    8000041e:	0006861b          	sext.w	a2,a3
    80000422:	0ad7a023          	sw	a3,160(a5)
    80000426:	07f77713          	andi	a4,a4,127
    8000042a:	97ba                	add	a5,a5,a4
    8000042c:	4729                	li	a4,10
    8000042e:	00e78c23          	sb	a4,24(a5)
                cons.w = cons.e;
    80000432:	00011797          	auipc	a5,0x11
    80000436:	84c7a523          	sw	a2,-1974(a5) # 80010c7c <cons+0x9c>
                wakeup(&cons.r);
    8000043a:	00011517          	auipc	a0,0x11
    8000043e:	83e50513          	addi	a0,a0,-1986 # 80010c78 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	eec080e7          	jalr	-276(ra) # 8000232e <wakeup>
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
    80000458:	bcc58593          	addi	a1,a1,-1076 # 80008020 <__func__.1+0x18>
    8000045c:	00010517          	auipc	a0,0x10
    80000460:	78450513          	addi	a0,a0,1924 # 80010be0 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	7a6080e7          	jalr	1958(ra) # 80000c0a <initlock>

    uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	33e080e7          	jalr	830(ra) # 800007aa <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000474:	00021797          	auipc	a5,0x21
    80000478:	90478793          	addi	a5,a5,-1788 # 80020d78 <devsw>
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
    800004ba:	b9a60613          	addi	a2,a2,-1126 # 80008050 <digits>
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
    8000055e:	7407a323          	sw	zero,1862(a5) # 80010ca0 <pr+0x18>
    printf("panic: ");
    80000562:	00008517          	auipc	a0,0x8
    80000566:	ac650513          	addi	a0,a0,-1338 # 80008028 <__func__.1+0x20>
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	02e080e7          	jalr	46(ra) # 80000598 <printf>
    printf(s);
    80000572:	8526                	mv	a0,s1
    80000574:	00000097          	auipc	ra,0x0
    80000578:	024080e7          	jalr	36(ra) # 80000598 <printf>
    printf("\n");
    8000057c:	00008517          	auipc	a0,0x8
    80000580:	b0c50513          	addi	a0,a0,-1268 # 80008088 <digits+0x38>
    80000584:	00000097          	auipc	ra,0x0
    80000588:	014080e7          	jalr	20(ra) # 80000598 <printf>
    panicked = 1; // freeze uart output from other CPUs
    8000058c:	4785                	li	a5,1
    8000058e:	00008717          	auipc	a4,0x8
    80000592:	4cf72123          	sw	a5,1218(a4) # 80008a50 <panicked>
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
    800005ce:	6d6dad83          	lw	s11,1750(s11) # 80010ca0 <pr+0x18>
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
    800005fa:	a5ab0b13          	addi	s6,s6,-1446 # 80008050 <digits>
        switch (c)
    800005fe:	07300c93          	li	s9,115
    80000602:	06400c13          	li	s8,100
    80000606:	a82d                	j	80000640 <printf+0xa8>
        acquire(&pr.lock);
    80000608:	00010517          	auipc	a0,0x10
    8000060c:	68050513          	addi	a0,a0,1664 # 80010c88 <pr>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	68a080e7          	jalr	1674(ra) # 80000c9a <acquire>
    80000618:	bf7d                	j	800005d6 <printf+0x3e>
        panic("null fmt");
    8000061a:	00008517          	auipc	a0,0x8
    8000061e:	a1e50513          	addi	a0,a0,-1506 # 80008038 <__func__.1+0x30>
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
    80000718:	91c48493          	addi	s1,s1,-1764 # 80008030 <__func__.1+0x28>
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
    8000076a:	52250513          	addi	a0,a0,1314 # 80010c88 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	5e0080e7          	jalr	1504(ra) # 80000d4e <release>
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
    80000786:	50648493          	addi	s1,s1,1286 # 80010c88 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8be58593          	addi	a1,a1,-1858 # 80008048 <__func__.1+0x40>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	476080e7          	jalr	1142(ra) # 80000c0a <initlock>
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
    800007de:	88e58593          	addi	a1,a1,-1906 # 80008068 <digits+0x18>
    800007e2:	00010517          	auipc	a0,0x10
    800007e6:	4c650513          	addi	a0,a0,1222 # 80010ca8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	420080e7          	jalr	1056(ra) # 80000c0a <initlock>
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
    8000080a:	448080e7          	jalr	1096(ra) # 80000c4e <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	2427a783          	lw	a5,578(a5) # 80008a50 <panicked>
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
    80000838:	4ba080e7          	jalr	1210(ra) # 80000cee <pop_off>
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
    8000084a:	2127b783          	ld	a5,530(a5) # 80008a58 <uart_tx_r>
    8000084e:	00008717          	auipc	a4,0x8
    80000852:	21273703          	ld	a4,530(a4) # 80008a60 <uart_tx_w>
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
    80000874:	438a0a13          	addi	s4,s4,1080 # 80010ca8 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	1e048493          	addi	s1,s1,480 # 80008a58 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	1e098993          	addi	s3,s3,480 # 80008a60 <uart_tx_w>
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
    800008a6:	a8c080e7          	jalr	-1396(ra) # 8000232e <wakeup>
    
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
    800008e2:	3ca50513          	addi	a0,a0,970 # 80010ca8 <uart_tx_lock>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	3b4080e7          	jalr	948(ra) # 80000c9a <acquire>
  if(panicked){
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	1627a783          	lw	a5,354(a5) # 80008a50 <panicked>
    800008f6:	e7c9                	bnez	a5,80000980 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008717          	auipc	a4,0x8
    800008fc:	16873703          	ld	a4,360(a4) # 80008a60 <uart_tx_w>
    80000900:	00008797          	auipc	a5,0x8
    80000904:	1587b783          	ld	a5,344(a5) # 80008a58 <uart_tx_r>
    80000908:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    8000090c:	00010997          	auipc	s3,0x10
    80000910:	39c98993          	addi	s3,s3,924 # 80010ca8 <uart_tx_lock>
    80000914:	00008497          	auipc	s1,0x8
    80000918:	14448493          	addi	s1,s1,324 # 80008a58 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000091c:	00008917          	auipc	s2,0x8
    80000920:	14490913          	addi	s2,s2,324 # 80008a60 <uart_tx_w>
    80000924:	00e79f63          	bne	a5,a4,80000942 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85ce                	mv	a1,s3
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	99e080e7          	jalr	-1634(ra) # 800022ca <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093703          	ld	a4,0(s2)
    80000938:	609c                	ld	a5,0(s1)
    8000093a:	02078793          	addi	a5,a5,32
    8000093e:	fee785e3          	beq	a5,a4,80000928 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00010497          	auipc	s1,0x10
    80000946:	36648493          	addi	s1,s1,870 # 80010ca8 <uart_tx_lock>
    8000094a:	01f77793          	andi	a5,a4,31
    8000094e:	97a6                	add	a5,a5,s1
    80000950:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000954:	0705                	addi	a4,a4,1
    80000956:	00008797          	auipc	a5,0x8
    8000095a:	10e7b523          	sd	a4,266(a5) # 80008a60 <uart_tx_w>
  uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee8080e7          	jalr	-280(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	3e6080e7          	jalr	998(ra) # 80000d4e <release>
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
    800009cc:	2e048493          	addi	s1,s1,736 # 80010ca8 <uart_tx_lock>
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	2c8080e7          	jalr	712(ra) # 80000c9a <acquire>
  uartstart();
    800009da:	00000097          	auipc	ra,0x0
    800009de:	e6c080e7          	jalr	-404(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009e2:	8526                	mv	a0,s1
    800009e4:	00000097          	auipc	ra,0x0
    800009e8:	36a080e7          	jalr	874(ra) # 80000d4e <release>
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
    80000a02:	84aa                	mv	s1,a0
    if (MAX_PAGES != 0)
    80000a04:	00008797          	auipc	a5,0x8
    80000a08:	06c7b783          	ld	a5,108(a5) # 80008a70 <MAX_PAGES>
    80000a0c:	c799                	beqz	a5,80000a1a <kfree+0x24>
        assert(FREE_PAGES < MAX_PAGES);
    80000a0e:	00008717          	auipc	a4,0x8
    80000a12:	05a73703          	ld	a4,90(a4) # 80008a68 <FREE_PAGES>
    80000a16:	06f77663          	bgeu	a4,a5,80000a82 <kfree+0x8c>
    struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    80000a1a:	03449793          	slli	a5,s1,0x34
    80000a1e:	efc1                	bnez	a5,80000ab6 <kfree+0xc0>
    80000a20:	00021797          	auipc	a5,0x21
    80000a24:	4f078793          	addi	a5,a5,1264 # 80021f10 <end>
    80000a28:	08f4e763          	bltu	s1,a5,80000ab6 <kfree+0xc0>
    80000a2c:	47c5                	li	a5,17
    80000a2e:	07ee                	slli	a5,a5,0x1b
    80000a30:	08f4f363          	bgeu	s1,a5,80000ab6 <kfree+0xc0>
        panic("kfree");

    // Fill with junk to catch dangling refs.
    memset(pa, 1, PGSIZE);
    80000a34:	6605                	lui	a2,0x1
    80000a36:	4585                	li	a1,1
    80000a38:	8526                	mv	a0,s1
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	35c080e7          	jalr	860(ra) # 80000d96 <memset>

    r = (struct run *)pa;

    acquire(&kmem.lock);
    80000a42:	00010917          	auipc	s2,0x10
    80000a46:	29e90913          	addi	s2,s2,670 # 80010ce0 <kmem>
    80000a4a:	854a                	mv	a0,s2
    80000a4c:	00000097          	auipc	ra,0x0
    80000a50:	24e080e7          	jalr	590(ra) # 80000c9a <acquire>
    r->next = kmem.freelist;
    80000a54:	01893783          	ld	a5,24(s2)
    80000a58:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000a5a:	00993c23          	sd	s1,24(s2)
    FREE_PAGES++;
    80000a5e:	00008717          	auipc	a4,0x8
    80000a62:	00a70713          	addi	a4,a4,10 # 80008a68 <FREE_PAGES>
    80000a66:	631c                	ld	a5,0(a4)
    80000a68:	0785                	addi	a5,a5,1
    80000a6a:	e31c                	sd	a5,0(a4)
    release(&kmem.lock);
    80000a6c:	854a                	mv	a0,s2
    80000a6e:	00000097          	auipc	ra,0x0
    80000a72:	2e0080e7          	jalr	736(ra) # 80000d4e <release>
}
    80000a76:	60e2                	ld	ra,24(sp)
    80000a78:	6442                	ld	s0,16(sp)
    80000a7a:	64a2                	ld	s1,8(sp)
    80000a7c:	6902                	ld	s2,0(sp)
    80000a7e:	6105                	addi	sp,sp,32
    80000a80:	8082                	ret
        assert(FREE_PAGES < MAX_PAGES);
    80000a82:	03700693          	li	a3,55
    80000a86:	00007617          	auipc	a2,0x7
    80000a8a:	58260613          	addi	a2,a2,1410 # 80008008 <__func__.1>
    80000a8e:	00007597          	auipc	a1,0x7
    80000a92:	5e258593          	addi	a1,a1,1506 # 80008070 <digits+0x20>
    80000a96:	00007517          	auipc	a0,0x7
    80000a9a:	5ea50513          	addi	a0,a0,1514 # 80008080 <digits+0x30>
    80000a9e:	00000097          	auipc	ra,0x0
    80000aa2:	afa080e7          	jalr	-1286(ra) # 80000598 <printf>
    80000aa6:	00007517          	auipc	a0,0x7
    80000aaa:	5ea50513          	addi	a0,a0,1514 # 80008090 <digits+0x40>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	a8e080e7          	jalr	-1394(ra) # 8000053c <panic>
        panic("kfree");
    80000ab6:	00007517          	auipc	a0,0x7
    80000aba:	5ea50513          	addi	a0,a0,1514 # 800080a0 <digits+0x50>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	a7e080e7          	jalr	-1410(ra) # 8000053c <panic>

0000000080000ac6 <freerange>:
{
    80000ac6:	7179                	addi	sp,sp,-48
    80000ac8:	f406                	sd	ra,40(sp)
    80000aca:	f022                	sd	s0,32(sp)
    80000acc:	ec26                	sd	s1,24(sp)
    80000ace:	e84a                	sd	s2,16(sp)
    80000ad0:	e44e                	sd	s3,8(sp)
    80000ad2:	e052                	sd	s4,0(sp)
    80000ad4:	1800                	addi	s0,sp,48
    p = (char *)PGROUNDUP((uint64)pa_start);
    80000ad6:	6785                	lui	a5,0x1
    80000ad8:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000adc:	00e504b3          	add	s1,a0,a4
    80000ae0:	777d                	lui	a4,0xfffff
    80000ae2:	8cf9                	and	s1,s1,a4
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000ae4:	94be                	add	s1,s1,a5
    80000ae6:	0095ee63          	bltu	a1,s1,80000b02 <freerange+0x3c>
    80000aea:	892e                	mv	s2,a1
        kfree(p);
    80000aec:	7a7d                	lui	s4,0xfffff
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000aee:	6985                	lui	s3,0x1
        kfree(p);
    80000af0:	01448533          	add	a0,s1,s4
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	f02080e7          	jalr	-254(ra) # 800009f6 <kfree>
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000afc:	94ce                	add	s1,s1,s3
    80000afe:	fe9979e3          	bgeu	s2,s1,80000af0 <freerange+0x2a>
}
    80000b02:	70a2                	ld	ra,40(sp)
    80000b04:	7402                	ld	s0,32(sp)
    80000b06:	64e2                	ld	s1,24(sp)
    80000b08:	6942                	ld	s2,16(sp)
    80000b0a:	69a2                	ld	s3,8(sp)
    80000b0c:	6a02                	ld	s4,0(sp)
    80000b0e:	6145                	addi	sp,sp,48
    80000b10:	8082                	ret

0000000080000b12 <kinit>:
{
    80000b12:	1141                	addi	sp,sp,-16
    80000b14:	e406                	sd	ra,8(sp)
    80000b16:	e022                	sd	s0,0(sp)
    80000b18:	0800                	addi	s0,sp,16
    initlock(&kmem.lock, "kmem");
    80000b1a:	00007597          	auipc	a1,0x7
    80000b1e:	58e58593          	addi	a1,a1,1422 # 800080a8 <digits+0x58>
    80000b22:	00010517          	auipc	a0,0x10
    80000b26:	1be50513          	addi	a0,a0,446 # 80010ce0 <kmem>
    80000b2a:	00000097          	auipc	ra,0x0
    80000b2e:	0e0080e7          	jalr	224(ra) # 80000c0a <initlock>
    freerange(end, (void *)PHYSTOP);
    80000b32:	45c5                	li	a1,17
    80000b34:	05ee                	slli	a1,a1,0x1b
    80000b36:	00021517          	auipc	a0,0x21
    80000b3a:	3da50513          	addi	a0,a0,986 # 80021f10 <end>
    80000b3e:	00000097          	auipc	ra,0x0
    80000b42:	f88080e7          	jalr	-120(ra) # 80000ac6 <freerange>
    MAX_PAGES = FREE_PAGES;
    80000b46:	00008797          	auipc	a5,0x8
    80000b4a:	f227b783          	ld	a5,-222(a5) # 80008a68 <FREE_PAGES>
    80000b4e:	00008717          	auipc	a4,0x8
    80000b52:	f2f73123          	sd	a5,-222(a4) # 80008a70 <MAX_PAGES>
}
    80000b56:	60a2                	ld	ra,8(sp)
    80000b58:	6402                	ld	s0,0(sp)
    80000b5a:	0141                	addi	sp,sp,16
    80000b5c:	8082                	ret

0000000080000b5e <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b5e:	1101                	addi	sp,sp,-32
    80000b60:	ec06                	sd	ra,24(sp)
    80000b62:	e822                	sd	s0,16(sp)
    80000b64:	e426                	sd	s1,8(sp)
    80000b66:	1000                	addi	s0,sp,32
    assert(FREE_PAGES > 0);
    80000b68:	00008797          	auipc	a5,0x8
    80000b6c:	f007b783          	ld	a5,-256(a5) # 80008a68 <FREE_PAGES>
    80000b70:	cbb1                	beqz	a5,80000bc4 <kalloc+0x66>
    struct run *r;

    acquire(&kmem.lock);
    80000b72:	00010497          	auipc	s1,0x10
    80000b76:	16e48493          	addi	s1,s1,366 # 80010ce0 <kmem>
    80000b7a:	8526                	mv	a0,s1
    80000b7c:	00000097          	auipc	ra,0x0
    80000b80:	11e080e7          	jalr	286(ra) # 80000c9a <acquire>
    r = kmem.freelist;
    80000b84:	6c84                	ld	s1,24(s1)
    if (r)
    80000b86:	c8ad                	beqz	s1,80000bf8 <kalloc+0x9a>
        kmem.freelist = r->next;
    80000b88:	609c                	ld	a5,0(s1)
    80000b8a:	00010517          	auipc	a0,0x10
    80000b8e:	15650513          	addi	a0,a0,342 # 80010ce0 <kmem>
    80000b92:	ed1c                	sd	a5,24(a0)
    release(&kmem.lock);
    80000b94:	00000097          	auipc	ra,0x0
    80000b98:	1ba080e7          	jalr	442(ra) # 80000d4e <release>

    if (r)
        memset((char *)r, 5, PGSIZE); // fill with junk
    80000b9c:	6605                	lui	a2,0x1
    80000b9e:	4595                	li	a1,5
    80000ba0:	8526                	mv	a0,s1
    80000ba2:	00000097          	auipc	ra,0x0
    80000ba6:	1f4080e7          	jalr	500(ra) # 80000d96 <memset>
    FREE_PAGES--;
    80000baa:	00008717          	auipc	a4,0x8
    80000bae:	ebe70713          	addi	a4,a4,-322 # 80008a68 <FREE_PAGES>
    80000bb2:	631c                	ld	a5,0(a4)
    80000bb4:	17fd                	addi	a5,a5,-1
    80000bb6:	e31c                	sd	a5,0(a4)
    return (void *)r;
}
    80000bb8:	8526                	mv	a0,s1
    80000bba:	60e2                	ld	ra,24(sp)
    80000bbc:	6442                	ld	s0,16(sp)
    80000bbe:	64a2                	ld	s1,8(sp)
    80000bc0:	6105                	addi	sp,sp,32
    80000bc2:	8082                	ret
    assert(FREE_PAGES > 0);
    80000bc4:	04f00693          	li	a3,79
    80000bc8:	00007617          	auipc	a2,0x7
    80000bcc:	43860613          	addi	a2,a2,1080 # 80008000 <etext>
    80000bd0:	00007597          	auipc	a1,0x7
    80000bd4:	4a058593          	addi	a1,a1,1184 # 80008070 <digits+0x20>
    80000bd8:	00007517          	auipc	a0,0x7
    80000bdc:	4a850513          	addi	a0,a0,1192 # 80008080 <digits+0x30>
    80000be0:	00000097          	auipc	ra,0x0
    80000be4:	9b8080e7          	jalr	-1608(ra) # 80000598 <printf>
    80000be8:	00007517          	auipc	a0,0x7
    80000bec:	4a850513          	addi	a0,a0,1192 # 80008090 <digits+0x40>
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	94c080e7          	jalr	-1716(ra) # 8000053c <panic>
    release(&kmem.lock);
    80000bf8:	00010517          	auipc	a0,0x10
    80000bfc:	0e850513          	addi	a0,a0,232 # 80010ce0 <kmem>
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	14e080e7          	jalr	334(ra) # 80000d4e <release>
    if (r)
    80000c08:	b74d                	j	80000baa <kalloc+0x4c>

0000000080000c0a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c0a:	1141                	addi	sp,sp,-16
    80000c0c:	e422                	sd	s0,8(sp)
    80000c0e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c10:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c12:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c16:	00053823          	sd	zero,16(a0)
}
    80000c1a:	6422                	ld	s0,8(sp)
    80000c1c:	0141                	addi	sp,sp,16
    80000c1e:	8082                	ret

0000000080000c20 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c20:	411c                	lw	a5,0(a0)
    80000c22:	e399                	bnez	a5,80000c28 <holding+0x8>
    80000c24:	4501                	li	a0,0
  return r;
}
    80000c26:	8082                	ret
{
    80000c28:	1101                	addi	sp,sp,-32
    80000c2a:	ec06                	sd	ra,24(sp)
    80000c2c:	e822                	sd	s0,16(sp)
    80000c2e:	e426                	sd	s1,8(sp)
    80000c30:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c32:	6904                	ld	s1,16(a0)
    80000c34:	00001097          	auipc	ra,0x1
    80000c38:	f12080e7          	jalr	-238(ra) # 80001b46 <mycpu>
    80000c3c:	40a48533          	sub	a0,s1,a0
    80000c40:	00153513          	seqz	a0,a0
}
    80000c44:	60e2                	ld	ra,24(sp)
    80000c46:	6442                	ld	s0,16(sp)
    80000c48:	64a2                	ld	s1,8(sp)
    80000c4a:	6105                	addi	sp,sp,32
    80000c4c:	8082                	ret

0000000080000c4e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c4e:	1101                	addi	sp,sp,-32
    80000c50:	ec06                	sd	ra,24(sp)
    80000c52:	e822                	sd	s0,16(sp)
    80000c54:	e426                	sd	s1,8(sp)
    80000c56:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c58:	100024f3          	csrr	s1,sstatus
    80000c5c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c60:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c62:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c66:	00001097          	auipc	ra,0x1
    80000c6a:	ee0080e7          	jalr	-288(ra) # 80001b46 <mycpu>
    80000c6e:	5d3c                	lw	a5,120(a0)
    80000c70:	cf89                	beqz	a5,80000c8a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c72:	00001097          	auipc	ra,0x1
    80000c76:	ed4080e7          	jalr	-300(ra) # 80001b46 <mycpu>
    80000c7a:	5d3c                	lw	a5,120(a0)
    80000c7c:	2785                	addiw	a5,a5,1
    80000c7e:	dd3c                	sw	a5,120(a0)
}
    80000c80:	60e2                	ld	ra,24(sp)
    80000c82:	6442                	ld	s0,16(sp)
    80000c84:	64a2                	ld	s1,8(sp)
    80000c86:	6105                	addi	sp,sp,32
    80000c88:	8082                	ret
    mycpu()->intena = old;
    80000c8a:	00001097          	auipc	ra,0x1
    80000c8e:	ebc080e7          	jalr	-324(ra) # 80001b46 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c92:	8085                	srli	s1,s1,0x1
    80000c94:	8885                	andi	s1,s1,1
    80000c96:	dd64                	sw	s1,124(a0)
    80000c98:	bfe9                	j	80000c72 <push_off+0x24>

0000000080000c9a <acquire>:
{
    80000c9a:	1101                	addi	sp,sp,-32
    80000c9c:	ec06                	sd	ra,24(sp)
    80000c9e:	e822                	sd	s0,16(sp)
    80000ca0:	e426                	sd	s1,8(sp)
    80000ca2:	1000                	addi	s0,sp,32
    80000ca4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000ca6:	00000097          	auipc	ra,0x0
    80000caa:	fa8080e7          	jalr	-88(ra) # 80000c4e <push_off>
  if(holding(lk))
    80000cae:	8526                	mv	a0,s1
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f70080e7          	jalr	-144(ra) # 80000c20 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cb8:	4705                	li	a4,1
  if(holding(lk))
    80000cba:	e115                	bnez	a0,80000cde <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cbc:	87ba                	mv	a5,a4
    80000cbe:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000cc2:	2781                	sext.w	a5,a5
    80000cc4:	ffe5                	bnez	a5,80000cbc <acquire+0x22>
  __sync_synchronize();
    80000cc6:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000cca:	00001097          	auipc	ra,0x1
    80000cce:	e7c080e7          	jalr	-388(ra) # 80001b46 <mycpu>
    80000cd2:	e888                	sd	a0,16(s1)
}
    80000cd4:	60e2                	ld	ra,24(sp)
    80000cd6:	6442                	ld	s0,16(sp)
    80000cd8:	64a2                	ld	s1,8(sp)
    80000cda:	6105                	addi	sp,sp,32
    80000cdc:	8082                	ret
    panic("acquire");
    80000cde:	00007517          	auipc	a0,0x7
    80000ce2:	3d250513          	addi	a0,a0,978 # 800080b0 <digits+0x60>
    80000ce6:	00000097          	auipc	ra,0x0
    80000cea:	856080e7          	jalr	-1962(ra) # 8000053c <panic>

0000000080000cee <pop_off>:

void
pop_off(void)
{
    80000cee:	1141                	addi	sp,sp,-16
    80000cf0:	e406                	sd	ra,8(sp)
    80000cf2:	e022                	sd	s0,0(sp)
    80000cf4:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cf6:	00001097          	auipc	ra,0x1
    80000cfa:	e50080e7          	jalr	-432(ra) # 80001b46 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cfe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d02:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d04:	e78d                	bnez	a5,80000d2e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d06:	5d3c                	lw	a5,120(a0)
    80000d08:	02f05b63          	blez	a5,80000d3e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d0c:	37fd                	addiw	a5,a5,-1
    80000d0e:	0007871b          	sext.w	a4,a5
    80000d12:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d14:	eb09                	bnez	a4,80000d26 <pop_off+0x38>
    80000d16:	5d7c                	lw	a5,124(a0)
    80000d18:	c799                	beqz	a5,80000d26 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d1a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d1e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d22:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d26:	60a2                	ld	ra,8(sp)
    80000d28:	6402                	ld	s0,0(sp)
    80000d2a:	0141                	addi	sp,sp,16
    80000d2c:	8082                	ret
    panic("pop_off - interruptible");
    80000d2e:	00007517          	auipc	a0,0x7
    80000d32:	38a50513          	addi	a0,a0,906 # 800080b8 <digits+0x68>
    80000d36:	00000097          	auipc	ra,0x0
    80000d3a:	806080e7          	jalr	-2042(ra) # 8000053c <panic>
    panic("pop_off");
    80000d3e:	00007517          	auipc	a0,0x7
    80000d42:	39250513          	addi	a0,a0,914 # 800080d0 <digits+0x80>
    80000d46:	fffff097          	auipc	ra,0xfffff
    80000d4a:	7f6080e7          	jalr	2038(ra) # 8000053c <panic>

0000000080000d4e <release>:
{
    80000d4e:	1101                	addi	sp,sp,-32
    80000d50:	ec06                	sd	ra,24(sp)
    80000d52:	e822                	sd	s0,16(sp)
    80000d54:	e426                	sd	s1,8(sp)
    80000d56:	1000                	addi	s0,sp,32
    80000d58:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d5a:	00000097          	auipc	ra,0x0
    80000d5e:	ec6080e7          	jalr	-314(ra) # 80000c20 <holding>
    80000d62:	c115                	beqz	a0,80000d86 <release+0x38>
  lk->cpu = 0;
    80000d64:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d68:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d6c:	0f50000f          	fence	iorw,ow
    80000d70:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d74:	00000097          	auipc	ra,0x0
    80000d78:	f7a080e7          	jalr	-134(ra) # 80000cee <pop_off>
}
    80000d7c:	60e2                	ld	ra,24(sp)
    80000d7e:	6442                	ld	s0,16(sp)
    80000d80:	64a2                	ld	s1,8(sp)
    80000d82:	6105                	addi	sp,sp,32
    80000d84:	8082                	ret
    panic("release");
    80000d86:	00007517          	auipc	a0,0x7
    80000d8a:	35250513          	addi	a0,a0,850 # 800080d8 <digits+0x88>
    80000d8e:	fffff097          	auipc	ra,0xfffff
    80000d92:	7ae080e7          	jalr	1966(ra) # 8000053c <panic>

0000000080000d96 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e422                	sd	s0,8(sp)
    80000d9a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d9c:	ca19                	beqz	a2,80000db2 <memset+0x1c>
    80000d9e:	87aa                	mv	a5,a0
    80000da0:	1602                	slli	a2,a2,0x20
    80000da2:	9201                	srli	a2,a2,0x20
    80000da4:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000da8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000dac:	0785                	addi	a5,a5,1
    80000dae:	fee79de3          	bne	a5,a4,80000da8 <memset+0x12>
  }
  return dst;
}
    80000db2:	6422                	ld	s0,8(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000dbe:	ca05                	beqz	a2,80000dee <memcmp+0x36>
    80000dc0:	fff6069b          	addiw	a3,a2,-1
    80000dc4:	1682                	slli	a3,a3,0x20
    80000dc6:	9281                	srli	a3,a3,0x20
    80000dc8:	0685                	addi	a3,a3,1
    80000dca:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000dcc:	00054783          	lbu	a5,0(a0)
    80000dd0:	0005c703          	lbu	a4,0(a1)
    80000dd4:	00e79863          	bne	a5,a4,80000de4 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000dd8:	0505                	addi	a0,a0,1
    80000dda:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ddc:	fed518e3          	bne	a0,a3,80000dcc <memcmp+0x14>
  }

  return 0;
    80000de0:	4501                	li	a0,0
    80000de2:	a019                	j	80000de8 <memcmp+0x30>
      return *s1 - *s2;
    80000de4:	40e7853b          	subw	a0,a5,a4
}
    80000de8:	6422                	ld	s0,8(sp)
    80000dea:	0141                	addi	sp,sp,16
    80000dec:	8082                	ret
  return 0;
    80000dee:	4501                	li	a0,0
    80000df0:	bfe5                	j	80000de8 <memcmp+0x30>

0000000080000df2 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000df2:	1141                	addi	sp,sp,-16
    80000df4:	e422                	sd	s0,8(sp)
    80000df6:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000df8:	c205                	beqz	a2,80000e18 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dfa:	02a5e263          	bltu	a1,a0,80000e1e <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dfe:	1602                	slli	a2,a2,0x20
    80000e00:	9201                	srli	a2,a2,0x20
    80000e02:	00c587b3          	add	a5,a1,a2
{
    80000e06:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e08:	0585                	addi	a1,a1,1
    80000e0a:	0705                	addi	a4,a4,1
    80000e0c:	fff5c683          	lbu	a3,-1(a1)
    80000e10:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e14:	fef59ae3          	bne	a1,a5,80000e08 <memmove+0x16>

  return dst;
}
    80000e18:	6422                	ld	s0,8(sp)
    80000e1a:	0141                	addi	sp,sp,16
    80000e1c:	8082                	ret
  if(s < d && s + n > d){
    80000e1e:	02061693          	slli	a3,a2,0x20
    80000e22:	9281                	srli	a3,a3,0x20
    80000e24:	00d58733          	add	a4,a1,a3
    80000e28:	fce57be3          	bgeu	a0,a4,80000dfe <memmove+0xc>
    d += n;
    80000e2c:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e2e:	fff6079b          	addiw	a5,a2,-1
    80000e32:	1782                	slli	a5,a5,0x20
    80000e34:	9381                	srli	a5,a5,0x20
    80000e36:	fff7c793          	not	a5,a5
    80000e3a:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e3c:	177d                	addi	a4,a4,-1
    80000e3e:	16fd                	addi	a3,a3,-1
    80000e40:	00074603          	lbu	a2,0(a4)
    80000e44:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000e48:	fee79ae3          	bne	a5,a4,80000e3c <memmove+0x4a>
    80000e4c:	b7f1                	j	80000e18 <memmove+0x26>

0000000080000e4e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e406                	sd	ra,8(sp)
    80000e52:	e022                	sd	s0,0(sp)
    80000e54:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e56:	00000097          	auipc	ra,0x0
    80000e5a:	f9c080e7          	jalr	-100(ra) # 80000df2 <memmove>
}
    80000e5e:	60a2                	ld	ra,8(sp)
    80000e60:	6402                	ld	s0,0(sp)
    80000e62:	0141                	addi	sp,sp,16
    80000e64:	8082                	ret

0000000080000e66 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e66:	1141                	addi	sp,sp,-16
    80000e68:	e422                	sd	s0,8(sp)
    80000e6a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e6c:	ce11                	beqz	a2,80000e88 <strncmp+0x22>
    80000e6e:	00054783          	lbu	a5,0(a0)
    80000e72:	cf89                	beqz	a5,80000e8c <strncmp+0x26>
    80000e74:	0005c703          	lbu	a4,0(a1)
    80000e78:	00f71a63          	bne	a4,a5,80000e8c <strncmp+0x26>
    n--, p++, q++;
    80000e7c:	367d                	addiw	a2,a2,-1
    80000e7e:	0505                	addi	a0,a0,1
    80000e80:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e82:	f675                	bnez	a2,80000e6e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e84:	4501                	li	a0,0
    80000e86:	a809                	j	80000e98 <strncmp+0x32>
    80000e88:	4501                	li	a0,0
    80000e8a:	a039                	j	80000e98 <strncmp+0x32>
  if(n == 0)
    80000e8c:	ca09                	beqz	a2,80000e9e <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e8e:	00054503          	lbu	a0,0(a0)
    80000e92:	0005c783          	lbu	a5,0(a1)
    80000e96:	9d1d                	subw	a0,a0,a5
}
    80000e98:	6422                	ld	s0,8(sp)
    80000e9a:	0141                	addi	sp,sp,16
    80000e9c:	8082                	ret
    return 0;
    80000e9e:	4501                	li	a0,0
    80000ea0:	bfe5                	j	80000e98 <strncmp+0x32>

0000000080000ea2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000ea2:	1141                	addi	sp,sp,-16
    80000ea4:	e422                	sd	s0,8(sp)
    80000ea6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000ea8:	87aa                	mv	a5,a0
    80000eaa:	86b2                	mv	a3,a2
    80000eac:	367d                	addiw	a2,a2,-1
    80000eae:	00d05963          	blez	a3,80000ec0 <strncpy+0x1e>
    80000eb2:	0785                	addi	a5,a5,1
    80000eb4:	0005c703          	lbu	a4,0(a1)
    80000eb8:	fee78fa3          	sb	a4,-1(a5)
    80000ebc:	0585                	addi	a1,a1,1
    80000ebe:	f775                	bnez	a4,80000eaa <strncpy+0x8>
    ;
  while(n-- > 0)
    80000ec0:	873e                	mv	a4,a5
    80000ec2:	9fb5                	addw	a5,a5,a3
    80000ec4:	37fd                	addiw	a5,a5,-1
    80000ec6:	00c05963          	blez	a2,80000ed8 <strncpy+0x36>
    *s++ = 0;
    80000eca:	0705                	addi	a4,a4,1
    80000ecc:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000ed0:	40e786bb          	subw	a3,a5,a4
    80000ed4:	fed04be3          	bgtz	a3,80000eca <strncpy+0x28>
  return os;
}
    80000ed8:	6422                	ld	s0,8(sp)
    80000eda:	0141                	addi	sp,sp,16
    80000edc:	8082                	ret

0000000080000ede <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ede:	1141                	addi	sp,sp,-16
    80000ee0:	e422                	sd	s0,8(sp)
    80000ee2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000ee4:	02c05363          	blez	a2,80000f0a <safestrcpy+0x2c>
    80000ee8:	fff6069b          	addiw	a3,a2,-1
    80000eec:	1682                	slli	a3,a3,0x20
    80000eee:	9281                	srli	a3,a3,0x20
    80000ef0:	96ae                	add	a3,a3,a1
    80000ef2:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ef4:	00d58963          	beq	a1,a3,80000f06 <safestrcpy+0x28>
    80000ef8:	0585                	addi	a1,a1,1
    80000efa:	0785                	addi	a5,a5,1
    80000efc:	fff5c703          	lbu	a4,-1(a1)
    80000f00:	fee78fa3          	sb	a4,-1(a5)
    80000f04:	fb65                	bnez	a4,80000ef4 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f06:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f0a:	6422                	ld	s0,8(sp)
    80000f0c:	0141                	addi	sp,sp,16
    80000f0e:	8082                	ret

0000000080000f10 <strlen>:

int
strlen(const char *s)
{
    80000f10:	1141                	addi	sp,sp,-16
    80000f12:	e422                	sd	s0,8(sp)
    80000f14:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f16:	00054783          	lbu	a5,0(a0)
    80000f1a:	cf91                	beqz	a5,80000f36 <strlen+0x26>
    80000f1c:	0505                	addi	a0,a0,1
    80000f1e:	87aa                	mv	a5,a0
    80000f20:	86be                	mv	a3,a5
    80000f22:	0785                	addi	a5,a5,1
    80000f24:	fff7c703          	lbu	a4,-1(a5)
    80000f28:	ff65                	bnez	a4,80000f20 <strlen+0x10>
    80000f2a:	40a6853b          	subw	a0,a3,a0
    80000f2e:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000f30:	6422                	ld	s0,8(sp)
    80000f32:	0141                	addi	sp,sp,16
    80000f34:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f36:	4501                	li	a0,0
    80000f38:	bfe5                	j	80000f30 <strlen+0x20>

0000000080000f3a <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f3a:	1141                	addi	sp,sp,-16
    80000f3c:	e406                	sd	ra,8(sp)
    80000f3e:	e022                	sd	s0,0(sp)
    80000f40:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f42:	00001097          	auipc	ra,0x1
    80000f46:	bf4080e7          	jalr	-1036(ra) # 80001b36 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f4a:	00008717          	auipc	a4,0x8
    80000f4e:	b2e70713          	addi	a4,a4,-1234 # 80008a78 <started>
  if(cpuid() == 0){
    80000f52:	c139                	beqz	a0,80000f98 <main+0x5e>
    while(started == 0)
    80000f54:	431c                	lw	a5,0(a4)
    80000f56:	2781                	sext.w	a5,a5
    80000f58:	dff5                	beqz	a5,80000f54 <main+0x1a>
      ;
    __sync_synchronize();
    80000f5a:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f5e:	00001097          	auipc	ra,0x1
    80000f62:	bd8080e7          	jalr	-1064(ra) # 80001b36 <cpuid>
    80000f66:	85aa                	mv	a1,a0
    80000f68:	00007517          	auipc	a0,0x7
    80000f6c:	19050513          	addi	a0,a0,400 # 800080f8 <digits+0xa8>
    80000f70:	fffff097          	auipc	ra,0xfffff
    80000f74:	628080e7          	jalr	1576(ra) # 80000598 <printf>
    kvminithart();    // turn on paging
    80000f78:	00000097          	auipc	ra,0x0
    80000f7c:	0d8080e7          	jalr	216(ra) # 80001050 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f80:	00002097          	auipc	ra,0x2
    80000f84:	a22080e7          	jalr	-1502(ra) # 800029a2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f88:	00005097          	auipc	ra,0x5
    80000f8c:	048080e7          	jalr	72(ra) # 80005fd0 <plicinithart>
  }

  scheduler();        
    80000f90:	00001097          	auipc	ra,0x1
    80000f94:	218080e7          	jalr	536(ra) # 800021a8 <scheduler>
    consoleinit();
    80000f98:	fffff097          	auipc	ra,0xfffff
    80000f9c:	4b4080e7          	jalr	1204(ra) # 8000044c <consoleinit>
    printfinit();
    80000fa0:	fffff097          	auipc	ra,0xfffff
    80000fa4:	7d8080e7          	jalr	2008(ra) # 80000778 <printfinit>
    printf("\n");
    80000fa8:	00007517          	auipc	a0,0x7
    80000fac:	0e050513          	addi	a0,a0,224 # 80008088 <digits+0x38>
    80000fb0:	fffff097          	auipc	ra,0xfffff
    80000fb4:	5e8080e7          	jalr	1512(ra) # 80000598 <printf>
    printf("xv6 kernel is booting\n");
    80000fb8:	00007517          	auipc	a0,0x7
    80000fbc:	12850513          	addi	a0,a0,296 # 800080e0 <digits+0x90>
    80000fc0:	fffff097          	auipc	ra,0xfffff
    80000fc4:	5d8080e7          	jalr	1496(ra) # 80000598 <printf>
    printf("\n");
    80000fc8:	00007517          	auipc	a0,0x7
    80000fcc:	0c050513          	addi	a0,a0,192 # 80008088 <digits+0x38>
    80000fd0:	fffff097          	auipc	ra,0xfffff
    80000fd4:	5c8080e7          	jalr	1480(ra) # 80000598 <printf>
    kinit();         // physical page allocator
    80000fd8:	00000097          	auipc	ra,0x0
    80000fdc:	b3a080e7          	jalr	-1222(ra) # 80000b12 <kinit>
    kvminit();       // create kernel page table
    80000fe0:	00000097          	auipc	ra,0x0
    80000fe4:	326080e7          	jalr	806(ra) # 80001306 <kvminit>
    kvminithart();   // turn on paging
    80000fe8:	00000097          	auipc	ra,0x0
    80000fec:	068080e7          	jalr	104(ra) # 80001050 <kvminithart>
    procinit();      // process table
    80000ff0:	00001097          	auipc	ra,0x1
    80000ff4:	a6e080e7          	jalr	-1426(ra) # 80001a5e <procinit>
    trapinit();      // trap vectors
    80000ff8:	00002097          	auipc	ra,0x2
    80000ffc:	982080e7          	jalr	-1662(ra) # 8000297a <trapinit>
    trapinithart();  // install kernel trap vector
    80001000:	00002097          	auipc	ra,0x2
    80001004:	9a2080e7          	jalr	-1630(ra) # 800029a2 <trapinithart>
    plicinit();      // set up interrupt controller
    80001008:	00005097          	auipc	ra,0x5
    8000100c:	fb2080e7          	jalr	-78(ra) # 80005fba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001010:	00005097          	auipc	ra,0x5
    80001014:	fc0080e7          	jalr	-64(ra) # 80005fd0 <plicinithart>
    binit();         // buffer cache
    80001018:	00002097          	auipc	ra,0x2
    8000101c:	1ba080e7          	jalr	442(ra) # 800031d2 <binit>
    iinit();         // inode table
    80001020:	00003097          	auipc	ra,0x3
    80001024:	858080e7          	jalr	-1960(ra) # 80003878 <iinit>
    fileinit();      // file table
    80001028:	00003097          	auipc	ra,0x3
    8000102c:	7ce080e7          	jalr	1998(ra) # 800047f6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001030:	00005097          	auipc	ra,0x5
    80001034:	0a8080e7          	jalr	168(ra) # 800060d8 <virtio_disk_init>
    userinit();      // first user process
    80001038:	00001097          	auipc	ra,0x1
    8000103c:	e02080e7          	jalr	-510(ra) # 80001e3a <userinit>
    __sync_synchronize();
    80001040:	0ff0000f          	fence
    started = 1;
    80001044:	4785                	li	a5,1
    80001046:	00008717          	auipc	a4,0x8
    8000104a:	a2f72923          	sw	a5,-1486(a4) # 80008a78 <started>
    8000104e:	b789                	j	80000f90 <main+0x56>

0000000080001050 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001050:	1141                	addi	sp,sp,-16
    80001052:	e422                	sd	s0,8(sp)
    80001054:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001056:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    8000105a:	00008797          	auipc	a5,0x8
    8000105e:	a267b783          	ld	a5,-1498(a5) # 80008a80 <kernel_pagetable>
    80001062:	83b1                	srli	a5,a5,0xc
    80001064:	577d                	li	a4,-1
    80001066:	177e                	slli	a4,a4,0x3f
    80001068:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000106a:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000106e:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001072:	6422                	ld	s0,8(sp)
    80001074:	0141                	addi	sp,sp,16
    80001076:	8082                	ret

0000000080001078 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001078:	7139                	addi	sp,sp,-64
    8000107a:	fc06                	sd	ra,56(sp)
    8000107c:	f822                	sd	s0,48(sp)
    8000107e:	f426                	sd	s1,40(sp)
    80001080:	f04a                	sd	s2,32(sp)
    80001082:	ec4e                	sd	s3,24(sp)
    80001084:	e852                	sd	s4,16(sp)
    80001086:	e456                	sd	s5,8(sp)
    80001088:	e05a                	sd	s6,0(sp)
    8000108a:	0080                	addi	s0,sp,64
    8000108c:	84aa                	mv	s1,a0
    8000108e:	89ae                	mv	s3,a1
    80001090:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001092:	57fd                	li	a5,-1
    80001094:	83e9                	srli	a5,a5,0x1a
    80001096:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001098:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000109a:	04b7f263          	bgeu	a5,a1,800010de <walk+0x66>
    panic("walk");
    8000109e:	00007517          	auipc	a0,0x7
    800010a2:	07250513          	addi	a0,a0,114 # 80008110 <digits+0xc0>
    800010a6:	fffff097          	auipc	ra,0xfffff
    800010aa:	496080e7          	jalr	1174(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010ae:	060a8663          	beqz	s5,8000111a <walk+0xa2>
    800010b2:	00000097          	auipc	ra,0x0
    800010b6:	aac080e7          	jalr	-1364(ra) # 80000b5e <kalloc>
    800010ba:	84aa                	mv	s1,a0
    800010bc:	c529                	beqz	a0,80001106 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010be:	6605                	lui	a2,0x1
    800010c0:	4581                	li	a1,0
    800010c2:	00000097          	auipc	ra,0x0
    800010c6:	cd4080e7          	jalr	-812(ra) # 80000d96 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010ca:	00c4d793          	srli	a5,s1,0xc
    800010ce:	07aa                	slli	a5,a5,0xa
    800010d0:	0017e793          	ori	a5,a5,1
    800010d4:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010d8:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd0e7>
    800010da:	036a0063          	beq	s4,s6,800010fa <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010de:	0149d933          	srl	s2,s3,s4
    800010e2:	1ff97913          	andi	s2,s2,511
    800010e6:	090e                	slli	s2,s2,0x3
    800010e8:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010ea:	00093483          	ld	s1,0(s2)
    800010ee:	0014f793          	andi	a5,s1,1
    800010f2:	dfd5                	beqz	a5,800010ae <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010f4:	80a9                	srli	s1,s1,0xa
    800010f6:	04b2                	slli	s1,s1,0xc
    800010f8:	b7c5                	j	800010d8 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010fa:	00c9d513          	srli	a0,s3,0xc
    800010fe:	1ff57513          	andi	a0,a0,511
    80001102:	050e                	slli	a0,a0,0x3
    80001104:	9526                	add	a0,a0,s1
}
    80001106:	70e2                	ld	ra,56(sp)
    80001108:	7442                	ld	s0,48(sp)
    8000110a:	74a2                	ld	s1,40(sp)
    8000110c:	7902                	ld	s2,32(sp)
    8000110e:	69e2                	ld	s3,24(sp)
    80001110:	6a42                	ld	s4,16(sp)
    80001112:	6aa2                	ld	s5,8(sp)
    80001114:	6b02                	ld	s6,0(sp)
    80001116:	6121                	addi	sp,sp,64
    80001118:	8082                	ret
        return 0;
    8000111a:	4501                	li	a0,0
    8000111c:	b7ed                	j	80001106 <walk+0x8e>

000000008000111e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000111e:	57fd                	li	a5,-1
    80001120:	83e9                	srli	a5,a5,0x1a
    80001122:	00b7f463          	bgeu	a5,a1,8000112a <walkaddr+0xc>
    return 0;
    80001126:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001128:	8082                	ret
{
    8000112a:	1141                	addi	sp,sp,-16
    8000112c:	e406                	sd	ra,8(sp)
    8000112e:	e022                	sd	s0,0(sp)
    80001130:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001132:	4601                	li	a2,0
    80001134:	00000097          	auipc	ra,0x0
    80001138:	f44080e7          	jalr	-188(ra) # 80001078 <walk>
  if(pte == 0)
    8000113c:	c105                	beqz	a0,8000115c <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000113e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001140:	0117f693          	andi	a3,a5,17
    80001144:	4745                	li	a4,17
    return 0;
    80001146:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001148:	00e68663          	beq	a3,a4,80001154 <walkaddr+0x36>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
  pa = PTE2PA(*pte);
    80001154:	83a9                	srli	a5,a5,0xa
    80001156:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000115a:	bfcd                	j	8000114c <walkaddr+0x2e>
    return 0;
    8000115c:	4501                	li	a0,0
    8000115e:	b7fd                	j	8000114c <walkaddr+0x2e>

0000000080001160 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001160:	715d                	addi	sp,sp,-80
    80001162:	e486                	sd	ra,72(sp)
    80001164:	e0a2                	sd	s0,64(sp)
    80001166:	fc26                	sd	s1,56(sp)
    80001168:	f84a                	sd	s2,48(sp)
    8000116a:	f44e                	sd	s3,40(sp)
    8000116c:	f052                	sd	s4,32(sp)
    8000116e:	ec56                	sd	s5,24(sp)
    80001170:	e85a                	sd	s6,16(sp)
    80001172:	e45e                	sd	s7,8(sp)
    80001174:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001176:	c639                	beqz	a2,800011c4 <mappages+0x64>
    80001178:	8aaa                	mv	s5,a0
    8000117a:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    8000117c:	777d                	lui	a4,0xfffff
    8000117e:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001182:	fff58993          	addi	s3,a1,-1
    80001186:	99b2                	add	s3,s3,a2
    80001188:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000118c:	893e                	mv	s2,a5
    8000118e:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001192:	6b85                	lui	s7,0x1
    80001194:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001198:	4605                	li	a2,1
    8000119a:	85ca                	mv	a1,s2
    8000119c:	8556                	mv	a0,s5
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	eda080e7          	jalr	-294(ra) # 80001078 <walk>
    800011a6:	cd1d                	beqz	a0,800011e4 <mappages+0x84>
    if(*pte & PTE_V)
    800011a8:	611c                	ld	a5,0(a0)
    800011aa:	8b85                	andi	a5,a5,1
    800011ac:	e785                	bnez	a5,800011d4 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011ae:	80b1                	srli	s1,s1,0xc
    800011b0:	04aa                	slli	s1,s1,0xa
    800011b2:	0164e4b3          	or	s1,s1,s6
    800011b6:	0014e493          	ori	s1,s1,1
    800011ba:	e104                	sd	s1,0(a0)
    if(a == last)
    800011bc:	05390063          	beq	s2,s3,800011fc <mappages+0x9c>
    a += PGSIZE;
    800011c0:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011c2:	bfc9                	j	80001194 <mappages+0x34>
    panic("mappages: size");
    800011c4:	00007517          	auipc	a0,0x7
    800011c8:	f5450513          	addi	a0,a0,-172 # 80008118 <digits+0xc8>
    800011cc:	fffff097          	auipc	ra,0xfffff
    800011d0:	370080e7          	jalr	880(ra) # 8000053c <panic>
      panic("mappages: remap");
    800011d4:	00007517          	auipc	a0,0x7
    800011d8:	f5450513          	addi	a0,a0,-172 # 80008128 <digits+0xd8>
    800011dc:	fffff097          	auipc	ra,0xfffff
    800011e0:	360080e7          	jalr	864(ra) # 8000053c <panic>
      return -1;
    800011e4:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011e6:	60a6                	ld	ra,72(sp)
    800011e8:	6406                	ld	s0,64(sp)
    800011ea:	74e2                	ld	s1,56(sp)
    800011ec:	7942                	ld	s2,48(sp)
    800011ee:	79a2                	ld	s3,40(sp)
    800011f0:	7a02                	ld	s4,32(sp)
    800011f2:	6ae2                	ld	s5,24(sp)
    800011f4:	6b42                	ld	s6,16(sp)
    800011f6:	6ba2                	ld	s7,8(sp)
    800011f8:	6161                	addi	sp,sp,80
    800011fa:	8082                	ret
  return 0;
    800011fc:	4501                	li	a0,0
    800011fe:	b7e5                	j	800011e6 <mappages+0x86>

0000000080001200 <kvmmap>:
{
    80001200:	1141                	addi	sp,sp,-16
    80001202:	e406                	sd	ra,8(sp)
    80001204:	e022                	sd	s0,0(sp)
    80001206:	0800                	addi	s0,sp,16
    80001208:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000120a:	86b2                	mv	a3,a2
    8000120c:	863e                	mv	a2,a5
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	f52080e7          	jalr	-174(ra) # 80001160 <mappages>
    80001216:	e509                	bnez	a0,80001220 <kvmmap+0x20>
}
    80001218:	60a2                	ld	ra,8(sp)
    8000121a:	6402                	ld	s0,0(sp)
    8000121c:	0141                	addi	sp,sp,16
    8000121e:	8082                	ret
    panic("kvmmap");
    80001220:	00007517          	auipc	a0,0x7
    80001224:	f1850513          	addi	a0,a0,-232 # 80008138 <digits+0xe8>
    80001228:	fffff097          	auipc	ra,0xfffff
    8000122c:	314080e7          	jalr	788(ra) # 8000053c <panic>

0000000080001230 <kvmmake>:
{
    80001230:	1101                	addi	sp,sp,-32
    80001232:	ec06                	sd	ra,24(sp)
    80001234:	e822                	sd	s0,16(sp)
    80001236:	e426                	sd	s1,8(sp)
    80001238:	e04a                	sd	s2,0(sp)
    8000123a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000123c:	00000097          	auipc	ra,0x0
    80001240:	922080e7          	jalr	-1758(ra) # 80000b5e <kalloc>
    80001244:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001246:	6605                	lui	a2,0x1
    80001248:	4581                	li	a1,0
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	b4c080e7          	jalr	-1204(ra) # 80000d96 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001252:	4719                	li	a4,6
    80001254:	6685                	lui	a3,0x1
    80001256:	10000637          	lui	a2,0x10000
    8000125a:	100005b7          	lui	a1,0x10000
    8000125e:	8526                	mv	a0,s1
    80001260:	00000097          	auipc	ra,0x0
    80001264:	fa0080e7          	jalr	-96(ra) # 80001200 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001268:	4719                	li	a4,6
    8000126a:	6685                	lui	a3,0x1
    8000126c:	10001637          	lui	a2,0x10001
    80001270:	100015b7          	lui	a1,0x10001
    80001274:	8526                	mv	a0,s1
    80001276:	00000097          	auipc	ra,0x0
    8000127a:	f8a080e7          	jalr	-118(ra) # 80001200 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000127e:	4719                	li	a4,6
    80001280:	004006b7          	lui	a3,0x400
    80001284:	0c000637          	lui	a2,0xc000
    80001288:	0c0005b7          	lui	a1,0xc000
    8000128c:	8526                	mv	a0,s1
    8000128e:	00000097          	auipc	ra,0x0
    80001292:	f72080e7          	jalr	-142(ra) # 80001200 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001296:	00007917          	auipc	s2,0x7
    8000129a:	d6a90913          	addi	s2,s2,-662 # 80008000 <etext>
    8000129e:	4729                	li	a4,10
    800012a0:	80007697          	auipc	a3,0x80007
    800012a4:	d6068693          	addi	a3,a3,-672 # 8000 <_entry-0x7fff8000>
    800012a8:	4605                	li	a2,1
    800012aa:	067e                	slli	a2,a2,0x1f
    800012ac:	85b2                	mv	a1,a2
    800012ae:	8526                	mv	a0,s1
    800012b0:	00000097          	auipc	ra,0x0
    800012b4:	f50080e7          	jalr	-176(ra) # 80001200 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012b8:	4719                	li	a4,6
    800012ba:	46c5                	li	a3,17
    800012bc:	06ee                	slli	a3,a3,0x1b
    800012be:	412686b3          	sub	a3,a3,s2
    800012c2:	864a                	mv	a2,s2
    800012c4:	85ca                	mv	a1,s2
    800012c6:	8526                	mv	a0,s1
    800012c8:	00000097          	auipc	ra,0x0
    800012cc:	f38080e7          	jalr	-200(ra) # 80001200 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012d0:	4729                	li	a4,10
    800012d2:	6685                	lui	a3,0x1
    800012d4:	00006617          	auipc	a2,0x6
    800012d8:	d2c60613          	addi	a2,a2,-724 # 80007000 <_trampoline>
    800012dc:	040005b7          	lui	a1,0x4000
    800012e0:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800012e2:	05b2                	slli	a1,a1,0xc
    800012e4:	8526                	mv	a0,s1
    800012e6:	00000097          	auipc	ra,0x0
    800012ea:	f1a080e7          	jalr	-230(ra) # 80001200 <kvmmap>
  proc_mapstacks(kpgtbl);
    800012ee:	8526                	mv	a0,s1
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	6d8080e7          	jalr	1752(ra) # 800019c8 <proc_mapstacks>
}
    800012f8:	8526                	mv	a0,s1
    800012fa:	60e2                	ld	ra,24(sp)
    800012fc:	6442                	ld	s0,16(sp)
    800012fe:	64a2                	ld	s1,8(sp)
    80001300:	6902                	ld	s2,0(sp)
    80001302:	6105                	addi	sp,sp,32
    80001304:	8082                	ret

0000000080001306 <kvminit>:
{
    80001306:	1141                	addi	sp,sp,-16
    80001308:	e406                	sd	ra,8(sp)
    8000130a:	e022                	sd	s0,0(sp)
    8000130c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000130e:	00000097          	auipc	ra,0x0
    80001312:	f22080e7          	jalr	-222(ra) # 80001230 <kvmmake>
    80001316:	00007797          	auipc	a5,0x7
    8000131a:	76a7b523          	sd	a0,1898(a5) # 80008a80 <kernel_pagetable>
}
    8000131e:	60a2                	ld	ra,8(sp)
    80001320:	6402                	ld	s0,0(sp)
    80001322:	0141                	addi	sp,sp,16
    80001324:	8082                	ret

0000000080001326 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001326:	715d                	addi	sp,sp,-80
    80001328:	e486                	sd	ra,72(sp)
    8000132a:	e0a2                	sd	s0,64(sp)
    8000132c:	fc26                	sd	s1,56(sp)
    8000132e:	f84a                	sd	s2,48(sp)
    80001330:	f44e                	sd	s3,40(sp)
    80001332:	f052                	sd	s4,32(sp)
    80001334:	ec56                	sd	s5,24(sp)
    80001336:	e85a                	sd	s6,16(sp)
    80001338:	e45e                	sd	s7,8(sp)
    8000133a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000133c:	03459793          	slli	a5,a1,0x34
    80001340:	e795                	bnez	a5,8000136c <uvmunmap+0x46>
    80001342:	8a2a                	mv	s4,a0
    80001344:	892e                	mv	s2,a1
    80001346:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001348:	0632                	slli	a2,a2,0xc
    8000134a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000134e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001350:	6b05                	lui	s6,0x1
    80001352:	0735e263          	bltu	a1,s3,800013b6 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001356:	60a6                	ld	ra,72(sp)
    80001358:	6406                	ld	s0,64(sp)
    8000135a:	74e2                	ld	s1,56(sp)
    8000135c:	7942                	ld	s2,48(sp)
    8000135e:	79a2                	ld	s3,40(sp)
    80001360:	7a02                	ld	s4,32(sp)
    80001362:	6ae2                	ld	s5,24(sp)
    80001364:	6b42                	ld	s6,16(sp)
    80001366:	6ba2                	ld	s7,8(sp)
    80001368:	6161                	addi	sp,sp,80
    8000136a:	8082                	ret
    panic("uvmunmap: not aligned");
    8000136c:	00007517          	auipc	a0,0x7
    80001370:	dd450513          	addi	a0,a0,-556 # 80008140 <digits+0xf0>
    80001374:	fffff097          	auipc	ra,0xfffff
    80001378:	1c8080e7          	jalr	456(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    8000137c:	00007517          	auipc	a0,0x7
    80001380:	ddc50513          	addi	a0,a0,-548 # 80008158 <digits+0x108>
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	1b8080e7          	jalr	440(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    8000138c:	00007517          	auipc	a0,0x7
    80001390:	ddc50513          	addi	a0,a0,-548 # 80008168 <digits+0x118>
    80001394:	fffff097          	auipc	ra,0xfffff
    80001398:	1a8080e7          	jalr	424(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    8000139c:	00007517          	auipc	a0,0x7
    800013a0:	de450513          	addi	a0,a0,-540 # 80008180 <digits+0x130>
    800013a4:	fffff097          	auipc	ra,0xfffff
    800013a8:	198080e7          	jalr	408(ra) # 8000053c <panic>
    *pte = 0;
    800013ac:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013b0:	995a                	add	s2,s2,s6
    800013b2:	fb3972e3          	bgeu	s2,s3,80001356 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013b6:	4601                	li	a2,0
    800013b8:	85ca                	mv	a1,s2
    800013ba:	8552                	mv	a0,s4
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	cbc080e7          	jalr	-836(ra) # 80001078 <walk>
    800013c4:	84aa                	mv	s1,a0
    800013c6:	d95d                	beqz	a0,8000137c <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013c8:	6108                	ld	a0,0(a0)
    800013ca:	00157793          	andi	a5,a0,1
    800013ce:	dfdd                	beqz	a5,8000138c <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013d0:	3ff57793          	andi	a5,a0,1023
    800013d4:	fd7784e3          	beq	a5,s7,8000139c <uvmunmap+0x76>
    if(do_free){
    800013d8:	fc0a8ae3          	beqz	s5,800013ac <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800013dc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013de:	0532                	slli	a0,a0,0xc
    800013e0:	fffff097          	auipc	ra,0xfffff
    800013e4:	616080e7          	jalr	1558(ra) # 800009f6 <kfree>
    800013e8:	b7d1                	j	800013ac <uvmunmap+0x86>

00000000800013ea <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013ea:	1101                	addi	sp,sp,-32
    800013ec:	ec06                	sd	ra,24(sp)
    800013ee:	e822                	sd	s0,16(sp)
    800013f0:	e426                	sd	s1,8(sp)
    800013f2:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013f4:	fffff097          	auipc	ra,0xfffff
    800013f8:	76a080e7          	jalr	1898(ra) # 80000b5e <kalloc>
    800013fc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013fe:	c519                	beqz	a0,8000140c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001400:	6605                	lui	a2,0x1
    80001402:	4581                	li	a1,0
    80001404:	00000097          	auipc	ra,0x0
    80001408:	992080e7          	jalr	-1646(ra) # 80000d96 <memset>
  return pagetable;
}
    8000140c:	8526                	mv	a0,s1
    8000140e:	60e2                	ld	ra,24(sp)
    80001410:	6442                	ld	s0,16(sp)
    80001412:	64a2                	ld	s1,8(sp)
    80001414:	6105                	addi	sp,sp,32
    80001416:	8082                	ret

0000000080001418 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001418:	7179                	addi	sp,sp,-48
    8000141a:	f406                	sd	ra,40(sp)
    8000141c:	f022                	sd	s0,32(sp)
    8000141e:	ec26                	sd	s1,24(sp)
    80001420:	e84a                	sd	s2,16(sp)
    80001422:	e44e                	sd	s3,8(sp)
    80001424:	e052                	sd	s4,0(sp)
    80001426:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001428:	6785                	lui	a5,0x1
    8000142a:	04f67863          	bgeu	a2,a5,8000147a <uvmfirst+0x62>
    8000142e:	8a2a                	mv	s4,a0
    80001430:	89ae                	mv	s3,a1
    80001432:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001434:	fffff097          	auipc	ra,0xfffff
    80001438:	72a080e7          	jalr	1834(ra) # 80000b5e <kalloc>
    8000143c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	954080e7          	jalr	-1708(ra) # 80000d96 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000144a:	4779                	li	a4,30
    8000144c:	86ca                	mv	a3,s2
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	8552                	mv	a0,s4
    80001454:	00000097          	auipc	ra,0x0
    80001458:	d0c080e7          	jalr	-756(ra) # 80001160 <mappages>
  memmove(mem, src, sz);
    8000145c:	8626                	mv	a2,s1
    8000145e:	85ce                	mv	a1,s3
    80001460:	854a                	mv	a0,s2
    80001462:	00000097          	auipc	ra,0x0
    80001466:	990080e7          	jalr	-1648(ra) # 80000df2 <memmove>
}
    8000146a:	70a2                	ld	ra,40(sp)
    8000146c:	7402                	ld	s0,32(sp)
    8000146e:	64e2                	ld	s1,24(sp)
    80001470:	6942                	ld	s2,16(sp)
    80001472:	69a2                	ld	s3,8(sp)
    80001474:	6a02                	ld	s4,0(sp)
    80001476:	6145                	addi	sp,sp,48
    80001478:	8082                	ret
    panic("uvmfirst: more than a page");
    8000147a:	00007517          	auipc	a0,0x7
    8000147e:	d1e50513          	addi	a0,a0,-738 # 80008198 <digits+0x148>
    80001482:	fffff097          	auipc	ra,0xfffff
    80001486:	0ba080e7          	jalr	186(ra) # 8000053c <panic>

000000008000148a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000148a:	1101                	addi	sp,sp,-32
    8000148c:	ec06                	sd	ra,24(sp)
    8000148e:	e822                	sd	s0,16(sp)
    80001490:	e426                	sd	s1,8(sp)
    80001492:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001494:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001496:	00b67d63          	bgeu	a2,a1,800014b0 <uvmdealloc+0x26>
    8000149a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000149c:	6785                	lui	a5,0x1
    8000149e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014a0:	00f60733          	add	a4,a2,a5
    800014a4:	76fd                	lui	a3,0xfffff
    800014a6:	8f75                	and	a4,a4,a3
    800014a8:	97ae                	add	a5,a5,a1
    800014aa:	8ff5                	and	a5,a5,a3
    800014ac:	00f76863          	bltu	a4,a5,800014bc <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014b0:	8526                	mv	a0,s1
    800014b2:	60e2                	ld	ra,24(sp)
    800014b4:	6442                	ld	s0,16(sp)
    800014b6:	64a2                	ld	s1,8(sp)
    800014b8:	6105                	addi	sp,sp,32
    800014ba:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014bc:	8f99                	sub	a5,a5,a4
    800014be:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014c0:	4685                	li	a3,1
    800014c2:	0007861b          	sext.w	a2,a5
    800014c6:	85ba                	mv	a1,a4
    800014c8:	00000097          	auipc	ra,0x0
    800014cc:	e5e080e7          	jalr	-418(ra) # 80001326 <uvmunmap>
    800014d0:	b7c5                	j	800014b0 <uvmdealloc+0x26>

00000000800014d2 <uvmalloc>:
  if(newsz < oldsz)
    800014d2:	0ab66563          	bltu	a2,a1,8000157c <uvmalloc+0xaa>
{
    800014d6:	7139                	addi	sp,sp,-64
    800014d8:	fc06                	sd	ra,56(sp)
    800014da:	f822                	sd	s0,48(sp)
    800014dc:	f426                	sd	s1,40(sp)
    800014de:	f04a                	sd	s2,32(sp)
    800014e0:	ec4e                	sd	s3,24(sp)
    800014e2:	e852                	sd	s4,16(sp)
    800014e4:	e456                	sd	s5,8(sp)
    800014e6:	e05a                	sd	s6,0(sp)
    800014e8:	0080                	addi	s0,sp,64
    800014ea:	8aaa                	mv	s5,a0
    800014ec:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014ee:	6785                	lui	a5,0x1
    800014f0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014f2:	95be                	add	a1,a1,a5
    800014f4:	77fd                	lui	a5,0xfffff
    800014f6:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014fa:	08c9f363          	bgeu	s3,a2,80001580 <uvmalloc+0xae>
    800014fe:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001500:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	65a080e7          	jalr	1626(ra) # 80000b5e <kalloc>
    8000150c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000150e:	c51d                	beqz	a0,8000153c <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001510:	6605                	lui	a2,0x1
    80001512:	4581                	li	a1,0
    80001514:	00000097          	auipc	ra,0x0
    80001518:	882080e7          	jalr	-1918(ra) # 80000d96 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000151c:	875a                	mv	a4,s6
    8000151e:	86a6                	mv	a3,s1
    80001520:	6605                	lui	a2,0x1
    80001522:	85ca                	mv	a1,s2
    80001524:	8556                	mv	a0,s5
    80001526:	00000097          	auipc	ra,0x0
    8000152a:	c3a080e7          	jalr	-966(ra) # 80001160 <mappages>
    8000152e:	e90d                	bnez	a0,80001560 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001530:	6785                	lui	a5,0x1
    80001532:	993e                	add	s2,s2,a5
    80001534:	fd4968e3          	bltu	s2,s4,80001504 <uvmalloc+0x32>
  return newsz;
    80001538:	8552                	mv	a0,s4
    8000153a:	a809                	j	8000154c <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000153c:	864e                	mv	a2,s3
    8000153e:	85ca                	mv	a1,s2
    80001540:	8556                	mv	a0,s5
    80001542:	00000097          	auipc	ra,0x0
    80001546:	f48080e7          	jalr	-184(ra) # 8000148a <uvmdealloc>
      return 0;
    8000154a:	4501                	li	a0,0
}
    8000154c:	70e2                	ld	ra,56(sp)
    8000154e:	7442                	ld	s0,48(sp)
    80001550:	74a2                	ld	s1,40(sp)
    80001552:	7902                	ld	s2,32(sp)
    80001554:	69e2                	ld	s3,24(sp)
    80001556:	6a42                	ld	s4,16(sp)
    80001558:	6aa2                	ld	s5,8(sp)
    8000155a:	6b02                	ld	s6,0(sp)
    8000155c:	6121                	addi	sp,sp,64
    8000155e:	8082                	ret
      kfree(mem);
    80001560:	8526                	mv	a0,s1
    80001562:	fffff097          	auipc	ra,0xfffff
    80001566:	494080e7          	jalr	1172(ra) # 800009f6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000156a:	864e                	mv	a2,s3
    8000156c:	85ca                	mv	a1,s2
    8000156e:	8556                	mv	a0,s5
    80001570:	00000097          	auipc	ra,0x0
    80001574:	f1a080e7          	jalr	-230(ra) # 8000148a <uvmdealloc>
      return 0;
    80001578:	4501                	li	a0,0
    8000157a:	bfc9                	j	8000154c <uvmalloc+0x7a>
    return oldsz;
    8000157c:	852e                	mv	a0,a1
}
    8000157e:	8082                	ret
  return newsz;
    80001580:	8532                	mv	a0,a2
    80001582:	b7e9                	j	8000154c <uvmalloc+0x7a>

0000000080001584 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001584:	7179                	addi	sp,sp,-48
    80001586:	f406                	sd	ra,40(sp)
    80001588:	f022                	sd	s0,32(sp)
    8000158a:	ec26                	sd	s1,24(sp)
    8000158c:	e84a                	sd	s2,16(sp)
    8000158e:	e44e                	sd	s3,8(sp)
    80001590:	e052                	sd	s4,0(sp)
    80001592:	1800                	addi	s0,sp,48
    80001594:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001596:	84aa                	mv	s1,a0
    80001598:	6905                	lui	s2,0x1
    8000159a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000159c:	4985                	li	s3,1
    8000159e:	a829                	j	800015b8 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015a0:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800015a2:	00c79513          	slli	a0,a5,0xc
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	fde080e7          	jalr	-34(ra) # 80001584 <freewalk>
      pagetable[i] = 0;
    800015ae:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015b2:	04a1                	addi	s1,s1,8
    800015b4:	03248163          	beq	s1,s2,800015d6 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800015b8:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015ba:	00f7f713          	andi	a4,a5,15
    800015be:	ff3701e3          	beq	a4,s3,800015a0 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015c2:	8b85                	andi	a5,a5,1
    800015c4:	d7fd                	beqz	a5,800015b2 <freewalk+0x2e>
      panic("freewalk: leaf");
    800015c6:	00007517          	auipc	a0,0x7
    800015ca:	bf250513          	addi	a0,a0,-1038 # 800081b8 <digits+0x168>
    800015ce:	fffff097          	auipc	ra,0xfffff
    800015d2:	f6e080e7          	jalr	-146(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    800015d6:	8552                	mv	a0,s4
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	41e080e7          	jalr	1054(ra) # 800009f6 <kfree>
}
    800015e0:	70a2                	ld	ra,40(sp)
    800015e2:	7402                	ld	s0,32(sp)
    800015e4:	64e2                	ld	s1,24(sp)
    800015e6:	6942                	ld	s2,16(sp)
    800015e8:	69a2                	ld	s3,8(sp)
    800015ea:	6a02                	ld	s4,0(sp)
    800015ec:	6145                	addi	sp,sp,48
    800015ee:	8082                	ret

00000000800015f0 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015f0:	1101                	addi	sp,sp,-32
    800015f2:	ec06                	sd	ra,24(sp)
    800015f4:	e822                	sd	s0,16(sp)
    800015f6:	e426                	sd	s1,8(sp)
    800015f8:	1000                	addi	s0,sp,32
    800015fa:	84aa                	mv	s1,a0
  if(sz > 0)
    800015fc:	e999                	bnez	a1,80001612 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015fe:	8526                	mv	a0,s1
    80001600:	00000097          	auipc	ra,0x0
    80001604:	f84080e7          	jalr	-124(ra) # 80001584 <freewalk>
}
    80001608:	60e2                	ld	ra,24(sp)
    8000160a:	6442                	ld	s0,16(sp)
    8000160c:	64a2                	ld	s1,8(sp)
    8000160e:	6105                	addi	sp,sp,32
    80001610:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001612:	6785                	lui	a5,0x1
    80001614:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001616:	95be                	add	a1,a1,a5
    80001618:	4685                	li	a3,1
    8000161a:	00c5d613          	srli	a2,a1,0xc
    8000161e:	4581                	li	a1,0
    80001620:	00000097          	auipc	ra,0x0
    80001624:	d06080e7          	jalr	-762(ra) # 80001326 <uvmunmap>
    80001628:	bfd9                	j	800015fe <uvmfree+0xe>

000000008000162a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000162a:	c679                	beqz	a2,800016f8 <uvmcopy+0xce>
{
    8000162c:	715d                	addi	sp,sp,-80
    8000162e:	e486                	sd	ra,72(sp)
    80001630:	e0a2                	sd	s0,64(sp)
    80001632:	fc26                	sd	s1,56(sp)
    80001634:	f84a                	sd	s2,48(sp)
    80001636:	f44e                	sd	s3,40(sp)
    80001638:	f052                	sd	s4,32(sp)
    8000163a:	ec56                	sd	s5,24(sp)
    8000163c:	e85a                	sd	s6,16(sp)
    8000163e:	e45e                	sd	s7,8(sp)
    80001640:	0880                	addi	s0,sp,80
    80001642:	8b2a                	mv	s6,a0
    80001644:	8aae                	mv	s5,a1
    80001646:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001648:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000164a:	4601                	li	a2,0
    8000164c:	85ce                	mv	a1,s3
    8000164e:	855a                	mv	a0,s6
    80001650:	00000097          	auipc	ra,0x0
    80001654:	a28080e7          	jalr	-1496(ra) # 80001078 <walk>
    80001658:	c531                	beqz	a0,800016a4 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000165a:	6118                	ld	a4,0(a0)
    8000165c:	00177793          	andi	a5,a4,1
    80001660:	cbb1                	beqz	a5,800016b4 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001662:	00a75593          	srli	a1,a4,0xa
    80001666:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000166a:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000166e:	fffff097          	auipc	ra,0xfffff
    80001672:	4f0080e7          	jalr	1264(ra) # 80000b5e <kalloc>
    80001676:	892a                	mv	s2,a0
    80001678:	c939                	beqz	a0,800016ce <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000167a:	6605                	lui	a2,0x1
    8000167c:	85de                	mv	a1,s7
    8000167e:	fffff097          	auipc	ra,0xfffff
    80001682:	774080e7          	jalr	1908(ra) # 80000df2 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001686:	8726                	mv	a4,s1
    80001688:	86ca                	mv	a3,s2
    8000168a:	6605                	lui	a2,0x1
    8000168c:	85ce                	mv	a1,s3
    8000168e:	8556                	mv	a0,s5
    80001690:	00000097          	auipc	ra,0x0
    80001694:	ad0080e7          	jalr	-1328(ra) # 80001160 <mappages>
    80001698:	e515                	bnez	a0,800016c4 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000169a:	6785                	lui	a5,0x1
    8000169c:	99be                	add	s3,s3,a5
    8000169e:	fb49e6e3          	bltu	s3,s4,8000164a <uvmcopy+0x20>
    800016a2:	a081                	j	800016e2 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016a4:	00007517          	auipc	a0,0x7
    800016a8:	b2450513          	addi	a0,a0,-1244 # 800081c8 <digits+0x178>
    800016ac:	fffff097          	auipc	ra,0xfffff
    800016b0:	e90080e7          	jalr	-368(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    800016b4:	00007517          	auipc	a0,0x7
    800016b8:	b3450513          	addi	a0,a0,-1228 # 800081e8 <digits+0x198>
    800016bc:	fffff097          	auipc	ra,0xfffff
    800016c0:	e80080e7          	jalr	-384(ra) # 8000053c <panic>
      kfree(mem);
    800016c4:	854a                	mv	a0,s2
    800016c6:	fffff097          	auipc	ra,0xfffff
    800016ca:	330080e7          	jalr	816(ra) # 800009f6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016ce:	4685                	li	a3,1
    800016d0:	00c9d613          	srli	a2,s3,0xc
    800016d4:	4581                	li	a1,0
    800016d6:	8556                	mv	a0,s5
    800016d8:	00000097          	auipc	ra,0x0
    800016dc:	c4e080e7          	jalr	-946(ra) # 80001326 <uvmunmap>
  return -1;
    800016e0:	557d                	li	a0,-1
}
    800016e2:	60a6                	ld	ra,72(sp)
    800016e4:	6406                	ld	s0,64(sp)
    800016e6:	74e2                	ld	s1,56(sp)
    800016e8:	7942                	ld	s2,48(sp)
    800016ea:	79a2                	ld	s3,40(sp)
    800016ec:	7a02                	ld	s4,32(sp)
    800016ee:	6ae2                	ld	s5,24(sp)
    800016f0:	6b42                	ld	s6,16(sp)
    800016f2:	6ba2                	ld	s7,8(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret
  return 0;
    800016f8:	4501                	li	a0,0
}
    800016fa:	8082                	ret

00000000800016fc <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016fc:	1141                	addi	sp,sp,-16
    800016fe:	e406                	sd	ra,8(sp)
    80001700:	e022                	sd	s0,0(sp)
    80001702:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001704:	4601                	li	a2,0
    80001706:	00000097          	auipc	ra,0x0
    8000170a:	972080e7          	jalr	-1678(ra) # 80001078 <walk>
  if(pte == 0)
    8000170e:	c901                	beqz	a0,8000171e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001710:	611c                	ld	a5,0(a0)
    80001712:	9bbd                	andi	a5,a5,-17
    80001714:	e11c                	sd	a5,0(a0)
}
    80001716:	60a2                	ld	ra,8(sp)
    80001718:	6402                	ld	s0,0(sp)
    8000171a:	0141                	addi	sp,sp,16
    8000171c:	8082                	ret
    panic("uvmclear");
    8000171e:	00007517          	auipc	a0,0x7
    80001722:	aea50513          	addi	a0,a0,-1302 # 80008208 <digits+0x1b8>
    80001726:	fffff097          	auipc	ra,0xfffff
    8000172a:	e16080e7          	jalr	-490(ra) # 8000053c <panic>

000000008000172e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000172e:	c6bd                	beqz	a3,8000179c <copyout+0x6e>
{
    80001730:	715d                	addi	sp,sp,-80
    80001732:	e486                	sd	ra,72(sp)
    80001734:	e0a2                	sd	s0,64(sp)
    80001736:	fc26                	sd	s1,56(sp)
    80001738:	f84a                	sd	s2,48(sp)
    8000173a:	f44e                	sd	s3,40(sp)
    8000173c:	f052                	sd	s4,32(sp)
    8000173e:	ec56                	sd	s5,24(sp)
    80001740:	e85a                	sd	s6,16(sp)
    80001742:	e45e                	sd	s7,8(sp)
    80001744:	e062                	sd	s8,0(sp)
    80001746:	0880                	addi	s0,sp,80
    80001748:	8b2a                	mv	s6,a0
    8000174a:	8c2e                	mv	s8,a1
    8000174c:	8a32                	mv	s4,a2
    8000174e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001750:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001752:	6a85                	lui	s5,0x1
    80001754:	a015                	j	80001778 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001756:	9562                	add	a0,a0,s8
    80001758:	0004861b          	sext.w	a2,s1
    8000175c:	85d2                	mv	a1,s4
    8000175e:	41250533          	sub	a0,a0,s2
    80001762:	fffff097          	auipc	ra,0xfffff
    80001766:	690080e7          	jalr	1680(ra) # 80000df2 <memmove>

    len -= n;
    8000176a:	409989b3          	sub	s3,s3,s1
    src += n;
    8000176e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001770:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001774:	02098263          	beqz	s3,80001798 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001778:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000177c:	85ca                	mv	a1,s2
    8000177e:	855a                	mv	a0,s6
    80001780:	00000097          	auipc	ra,0x0
    80001784:	99e080e7          	jalr	-1634(ra) # 8000111e <walkaddr>
    if(pa0 == 0)
    80001788:	cd01                	beqz	a0,800017a0 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000178a:	418904b3          	sub	s1,s2,s8
    8000178e:	94d6                	add	s1,s1,s5
    80001790:	fc99f3e3          	bgeu	s3,s1,80001756 <copyout+0x28>
    80001794:	84ce                	mv	s1,s3
    80001796:	b7c1                	j	80001756 <copyout+0x28>
  }
  return 0;
    80001798:	4501                	li	a0,0
    8000179a:	a021                	j	800017a2 <copyout+0x74>
    8000179c:	4501                	li	a0,0
}
    8000179e:	8082                	ret
      return -1;
    800017a0:	557d                	li	a0,-1
}
    800017a2:	60a6                	ld	ra,72(sp)
    800017a4:	6406                	ld	s0,64(sp)
    800017a6:	74e2                	ld	s1,56(sp)
    800017a8:	7942                	ld	s2,48(sp)
    800017aa:	79a2                	ld	s3,40(sp)
    800017ac:	7a02                	ld	s4,32(sp)
    800017ae:	6ae2                	ld	s5,24(sp)
    800017b0:	6b42                	ld	s6,16(sp)
    800017b2:	6ba2                	ld	s7,8(sp)
    800017b4:	6c02                	ld	s8,0(sp)
    800017b6:	6161                	addi	sp,sp,80
    800017b8:	8082                	ret

00000000800017ba <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017ba:	caa5                	beqz	a3,8000182a <copyin+0x70>
{
    800017bc:	715d                	addi	sp,sp,-80
    800017be:	e486                	sd	ra,72(sp)
    800017c0:	e0a2                	sd	s0,64(sp)
    800017c2:	fc26                	sd	s1,56(sp)
    800017c4:	f84a                	sd	s2,48(sp)
    800017c6:	f44e                	sd	s3,40(sp)
    800017c8:	f052                	sd	s4,32(sp)
    800017ca:	ec56                	sd	s5,24(sp)
    800017cc:	e85a                	sd	s6,16(sp)
    800017ce:	e45e                	sd	s7,8(sp)
    800017d0:	e062                	sd	s8,0(sp)
    800017d2:	0880                	addi	s0,sp,80
    800017d4:	8b2a                	mv	s6,a0
    800017d6:	8a2e                	mv	s4,a1
    800017d8:	8c32                	mv	s8,a2
    800017da:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017dc:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017de:	6a85                	lui	s5,0x1
    800017e0:	a01d                	j	80001806 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017e2:	018505b3          	add	a1,a0,s8
    800017e6:	0004861b          	sext.w	a2,s1
    800017ea:	412585b3          	sub	a1,a1,s2
    800017ee:	8552                	mv	a0,s4
    800017f0:	fffff097          	auipc	ra,0xfffff
    800017f4:	602080e7          	jalr	1538(ra) # 80000df2 <memmove>

    len -= n;
    800017f8:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017fc:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017fe:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001802:	02098263          	beqz	s3,80001826 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001806:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000180a:	85ca                	mv	a1,s2
    8000180c:	855a                	mv	a0,s6
    8000180e:	00000097          	auipc	ra,0x0
    80001812:	910080e7          	jalr	-1776(ra) # 8000111e <walkaddr>
    if(pa0 == 0)
    80001816:	cd01                	beqz	a0,8000182e <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001818:	418904b3          	sub	s1,s2,s8
    8000181c:	94d6                	add	s1,s1,s5
    8000181e:	fc99f2e3          	bgeu	s3,s1,800017e2 <copyin+0x28>
    80001822:	84ce                	mv	s1,s3
    80001824:	bf7d                	j	800017e2 <copyin+0x28>
  }
  return 0;
    80001826:	4501                	li	a0,0
    80001828:	a021                	j	80001830 <copyin+0x76>
    8000182a:	4501                	li	a0,0
}
    8000182c:	8082                	ret
      return -1;
    8000182e:	557d                	li	a0,-1
}
    80001830:	60a6                	ld	ra,72(sp)
    80001832:	6406                	ld	s0,64(sp)
    80001834:	74e2                	ld	s1,56(sp)
    80001836:	7942                	ld	s2,48(sp)
    80001838:	79a2                	ld	s3,40(sp)
    8000183a:	7a02                	ld	s4,32(sp)
    8000183c:	6ae2                	ld	s5,24(sp)
    8000183e:	6b42                	ld	s6,16(sp)
    80001840:	6ba2                	ld	s7,8(sp)
    80001842:	6c02                	ld	s8,0(sp)
    80001844:	6161                	addi	sp,sp,80
    80001846:	8082                	ret

0000000080001848 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001848:	c2dd                	beqz	a3,800018ee <copyinstr+0xa6>
{
    8000184a:	715d                	addi	sp,sp,-80
    8000184c:	e486                	sd	ra,72(sp)
    8000184e:	e0a2                	sd	s0,64(sp)
    80001850:	fc26                	sd	s1,56(sp)
    80001852:	f84a                	sd	s2,48(sp)
    80001854:	f44e                	sd	s3,40(sp)
    80001856:	f052                	sd	s4,32(sp)
    80001858:	ec56                	sd	s5,24(sp)
    8000185a:	e85a                	sd	s6,16(sp)
    8000185c:	e45e                	sd	s7,8(sp)
    8000185e:	0880                	addi	s0,sp,80
    80001860:	8a2a                	mv	s4,a0
    80001862:	8b2e                	mv	s6,a1
    80001864:	8bb2                	mv	s7,a2
    80001866:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001868:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000186a:	6985                	lui	s3,0x1
    8000186c:	a02d                	j	80001896 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000186e:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001872:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001874:	37fd                	addiw	a5,a5,-1
    80001876:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000187a:	60a6                	ld	ra,72(sp)
    8000187c:	6406                	ld	s0,64(sp)
    8000187e:	74e2                	ld	s1,56(sp)
    80001880:	7942                	ld	s2,48(sp)
    80001882:	79a2                	ld	s3,40(sp)
    80001884:	7a02                	ld	s4,32(sp)
    80001886:	6ae2                	ld	s5,24(sp)
    80001888:	6b42                	ld	s6,16(sp)
    8000188a:	6ba2                	ld	s7,8(sp)
    8000188c:	6161                	addi	sp,sp,80
    8000188e:	8082                	ret
    srcva = va0 + PGSIZE;
    80001890:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001894:	c8a9                	beqz	s1,800018e6 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001896:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000189a:	85ca                	mv	a1,s2
    8000189c:	8552                	mv	a0,s4
    8000189e:	00000097          	auipc	ra,0x0
    800018a2:	880080e7          	jalr	-1920(ra) # 8000111e <walkaddr>
    if(pa0 == 0)
    800018a6:	c131                	beqz	a0,800018ea <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800018a8:	417906b3          	sub	a3,s2,s7
    800018ac:	96ce                	add	a3,a3,s3
    800018ae:	00d4f363          	bgeu	s1,a3,800018b4 <copyinstr+0x6c>
    800018b2:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018b4:	955e                	add	a0,a0,s7
    800018b6:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018ba:	daf9                	beqz	a3,80001890 <copyinstr+0x48>
    800018bc:	87da                	mv	a5,s6
    800018be:	885a                	mv	a6,s6
      if(*p == '\0'){
    800018c0:	41650633          	sub	a2,a0,s6
    while(n > 0){
    800018c4:	96da                	add	a3,a3,s6
    800018c6:	85be                	mv	a1,a5
      if(*p == '\0'){
    800018c8:	00f60733          	add	a4,a2,a5
    800018cc:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd0f0>
    800018d0:	df59                	beqz	a4,8000186e <copyinstr+0x26>
        *dst = *p;
    800018d2:	00e78023          	sb	a4,0(a5)
      dst++;
    800018d6:	0785                	addi	a5,a5,1
    while(n > 0){
    800018d8:	fed797e3          	bne	a5,a3,800018c6 <copyinstr+0x7e>
    800018dc:	14fd                	addi	s1,s1,-1
    800018de:	94c2                	add	s1,s1,a6
      --max;
    800018e0:	8c8d                	sub	s1,s1,a1
      dst++;
    800018e2:	8b3e                	mv	s6,a5
    800018e4:	b775                	j	80001890 <copyinstr+0x48>
    800018e6:	4781                	li	a5,0
    800018e8:	b771                	j	80001874 <copyinstr+0x2c>
      return -1;
    800018ea:	557d                	li	a0,-1
    800018ec:	b779                	j	8000187a <copyinstr+0x32>
  int got_null = 0;
    800018ee:	4781                	li	a5,0
  if(got_null){
    800018f0:	37fd                	addiw	a5,a5,-1
    800018f2:	0007851b          	sext.w	a0,a5
}
    800018f6:	8082                	ret

00000000800018f8 <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    800018f8:	715d                	addi	sp,sp,-80
    800018fa:	e486                	sd	ra,72(sp)
    800018fc:	e0a2                	sd	s0,64(sp)
    800018fe:	fc26                	sd	s1,56(sp)
    80001900:	f84a                	sd	s2,48(sp)
    80001902:	f44e                	sd	s3,40(sp)
    80001904:	f052                	sd	s4,32(sp)
    80001906:	ec56                	sd	s5,24(sp)
    80001908:	e85a                	sd	s6,16(sp)
    8000190a:	e45e                	sd	s7,8(sp)
    8000190c:	e062                	sd	s8,0(sp)
    8000190e:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    80001910:	8792                	mv	a5,tp
    int id = r_tp();
    80001912:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    80001914:	0000fa97          	auipc	s5,0xf
    80001918:	3eca8a93          	addi	s5,s5,1004 # 80010d00 <cpus>
    8000191c:	00779713          	slli	a4,a5,0x7
    80001920:	00ea86b3          	add	a3,s5,a4
    80001924:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7ffdd0f0>
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
    80001928:	0721                	addi	a4,a4,8
    8000192a:	9aba                	add	s5,s5,a4
                c->proc = p;
    8000192c:	8936                	mv	s2,a3
                // check if we are still the right scheduler (or if schedset changed)
                if (sched_pointer != &rr_scheduler)
    8000192e:	00007c17          	auipc	s8,0x7
    80001932:	0aac0c13          	addi	s8,s8,170 # 800089d8 <sched_pointer>
    80001936:	00000b97          	auipc	s7,0x0
    8000193a:	fc2b8b93          	addi	s7,s7,-62 # 800018f8 <rr_scheduler>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000193e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001942:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001946:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++)
    8000194a:	0000f497          	auipc	s1,0xf
    8000194e:	7e648493          	addi	s1,s1,2022 # 80011130 <proc>
            if (p->state == RUNNABLE)
    80001952:	498d                	li	s3,3
                p->state = RUNNING;
    80001954:	4b11                	li	s6,4
        for (p = proc; p < &proc[NPROC]; p++)
    80001956:	00015a17          	auipc	s4,0x15
    8000195a:	1daa0a13          	addi	s4,s4,474 # 80016b30 <tickslock>
    8000195e:	a81d                	j	80001994 <rr_scheduler+0x9c>
                {
                    release(&p->lock);
    80001960:	8526                	mv	a0,s1
    80001962:	fffff097          	auipc	ra,0xfffff
    80001966:	3ec080e7          	jalr	1004(ra) # 80000d4e <release>
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
}
    8000196a:	60a6                	ld	ra,72(sp)
    8000196c:	6406                	ld	s0,64(sp)
    8000196e:	74e2                	ld	s1,56(sp)
    80001970:	7942                	ld	s2,48(sp)
    80001972:	79a2                	ld	s3,40(sp)
    80001974:	7a02                	ld	s4,32(sp)
    80001976:	6ae2                	ld	s5,24(sp)
    80001978:	6b42                	ld	s6,16(sp)
    8000197a:	6ba2                	ld	s7,8(sp)
    8000197c:	6c02                	ld	s8,0(sp)
    8000197e:	6161                	addi	sp,sp,80
    80001980:	8082                	ret
            release(&p->lock);
    80001982:	8526                	mv	a0,s1
    80001984:	fffff097          	auipc	ra,0xfffff
    80001988:	3ca080e7          	jalr	970(ra) # 80000d4e <release>
        for (p = proc; p < &proc[NPROC]; p++)
    8000198c:	16848493          	addi	s1,s1,360
    80001990:	fb4487e3          	beq	s1,s4,8000193e <rr_scheduler+0x46>
            acquire(&p->lock);
    80001994:	8526                	mv	a0,s1
    80001996:	fffff097          	auipc	ra,0xfffff
    8000199a:	304080e7          	jalr	772(ra) # 80000c9a <acquire>
            if (p->state == RUNNABLE)
    8000199e:	4c9c                	lw	a5,24(s1)
    800019a0:	ff3791e3          	bne	a5,s3,80001982 <rr_scheduler+0x8a>
                p->state = RUNNING;
    800019a4:	0164ac23          	sw	s6,24(s1)
                c->proc = p;
    800019a8:	00993023          	sd	s1,0(s2) # 1000 <_entry-0x7ffff000>
                swtch(&c->context, &p->context);
    800019ac:	06048593          	addi	a1,s1,96
    800019b0:	8556                	mv	a0,s5
    800019b2:	00001097          	auipc	ra,0x1
    800019b6:	f5e080e7          	jalr	-162(ra) # 80002910 <swtch>
                if (sched_pointer != &rr_scheduler)
    800019ba:	000c3783          	ld	a5,0(s8)
    800019be:	fb7791e3          	bne	a5,s7,80001960 <rr_scheduler+0x68>
                c->proc = 0;
    800019c2:	00093023          	sd	zero,0(s2)
    800019c6:	bf75                	j	80001982 <rr_scheduler+0x8a>

00000000800019c8 <proc_mapstacks>:
{
    800019c8:	7139                	addi	sp,sp,-64
    800019ca:	fc06                	sd	ra,56(sp)
    800019cc:	f822                	sd	s0,48(sp)
    800019ce:	f426                	sd	s1,40(sp)
    800019d0:	f04a                	sd	s2,32(sp)
    800019d2:	ec4e                	sd	s3,24(sp)
    800019d4:	e852                	sd	s4,16(sp)
    800019d6:	e456                	sd	s5,8(sp)
    800019d8:	e05a                	sd	s6,0(sp)
    800019da:	0080                	addi	s0,sp,64
    800019dc:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    800019de:	0000f497          	auipc	s1,0xf
    800019e2:	75248493          	addi	s1,s1,1874 # 80011130 <proc>
        uint64 va = KSTACK((int)(p - proc));
    800019e6:	8b26                	mv	s6,s1
    800019e8:	00006a97          	auipc	s5,0x6
    800019ec:	628a8a93          	addi	s5,s5,1576 # 80008010 <__func__.1+0x8>
    800019f0:	04000937          	lui	s2,0x4000
    800019f4:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019f6:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    800019f8:	00015a17          	auipc	s4,0x15
    800019fc:	138a0a13          	addi	s4,s4,312 # 80016b30 <tickslock>
        char *pa = kalloc();
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	15e080e7          	jalr	350(ra) # 80000b5e <kalloc>
    80001a08:	862a                	mv	a2,a0
        if (pa == 0)
    80001a0a:	c131                	beqz	a0,80001a4e <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001a0c:	416485b3          	sub	a1,s1,s6
    80001a10:	858d                	srai	a1,a1,0x3
    80001a12:	000ab783          	ld	a5,0(s5)
    80001a16:	02f585b3          	mul	a1,a1,a5
    80001a1a:	2585                	addiw	a1,a1,1
    80001a1c:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a20:	4719                	li	a4,6
    80001a22:	6685                	lui	a3,0x1
    80001a24:	40b905b3          	sub	a1,s2,a1
    80001a28:	854e                	mv	a0,s3
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	7d6080e7          	jalr	2006(ra) # 80001200 <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001a32:	16848493          	addi	s1,s1,360
    80001a36:	fd4495e3          	bne	s1,s4,80001a00 <proc_mapstacks+0x38>
}
    80001a3a:	70e2                	ld	ra,56(sp)
    80001a3c:	7442                	ld	s0,48(sp)
    80001a3e:	74a2                	ld	s1,40(sp)
    80001a40:	7902                	ld	s2,32(sp)
    80001a42:	69e2                	ld	s3,24(sp)
    80001a44:	6a42                	ld	s4,16(sp)
    80001a46:	6aa2                	ld	s5,8(sp)
    80001a48:	6b02                	ld	s6,0(sp)
    80001a4a:	6121                	addi	sp,sp,64
    80001a4c:	8082                	ret
            panic("kalloc");
    80001a4e:	00006517          	auipc	a0,0x6
    80001a52:	7ca50513          	addi	a0,a0,1994 # 80008218 <digits+0x1c8>
    80001a56:	fffff097          	auipc	ra,0xfffff
    80001a5a:	ae6080e7          	jalr	-1306(ra) # 8000053c <panic>

0000000080001a5e <procinit>:
{
    80001a5e:	7139                	addi	sp,sp,-64
    80001a60:	fc06                	sd	ra,56(sp)
    80001a62:	f822                	sd	s0,48(sp)
    80001a64:	f426                	sd	s1,40(sp)
    80001a66:	f04a                	sd	s2,32(sp)
    80001a68:	ec4e                	sd	s3,24(sp)
    80001a6a:	e852                	sd	s4,16(sp)
    80001a6c:	e456                	sd	s5,8(sp)
    80001a6e:	e05a                	sd	s6,0(sp)
    80001a70:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001a72:	00006597          	auipc	a1,0x6
    80001a76:	7ae58593          	addi	a1,a1,1966 # 80008220 <digits+0x1d0>
    80001a7a:	0000f517          	auipc	a0,0xf
    80001a7e:	68650513          	addi	a0,a0,1670 # 80011100 <pid_lock>
    80001a82:	fffff097          	auipc	ra,0xfffff
    80001a86:	188080e7          	jalr	392(ra) # 80000c0a <initlock>
    initlock(&wait_lock, "wait_lock");
    80001a8a:	00006597          	auipc	a1,0x6
    80001a8e:	79e58593          	addi	a1,a1,1950 # 80008228 <digits+0x1d8>
    80001a92:	0000f517          	auipc	a0,0xf
    80001a96:	68650513          	addi	a0,a0,1670 # 80011118 <wait_lock>
    80001a9a:	fffff097          	auipc	ra,0xfffff
    80001a9e:	170080e7          	jalr	368(ra) # 80000c0a <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001aa2:	0000f497          	auipc	s1,0xf
    80001aa6:	68e48493          	addi	s1,s1,1678 # 80011130 <proc>
        initlock(&p->lock, "proc");
    80001aaa:	00006b17          	auipc	s6,0x6
    80001aae:	78eb0b13          	addi	s6,s6,1934 # 80008238 <digits+0x1e8>
        p->kstack = KSTACK((int)(p - proc));
    80001ab2:	8aa6                	mv	s5,s1
    80001ab4:	00006a17          	auipc	s4,0x6
    80001ab8:	55ca0a13          	addi	s4,s4,1372 # 80008010 <__func__.1+0x8>
    80001abc:	04000937          	lui	s2,0x4000
    80001ac0:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001ac2:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001ac4:	00015997          	auipc	s3,0x15
    80001ac8:	06c98993          	addi	s3,s3,108 # 80016b30 <tickslock>
        initlock(&p->lock, "proc");
    80001acc:	85da                	mv	a1,s6
    80001ace:	8526                	mv	a0,s1
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	13a080e7          	jalr	314(ra) # 80000c0a <initlock>
        p->state = UNUSED;
    80001ad8:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001adc:	415487b3          	sub	a5,s1,s5
    80001ae0:	878d                	srai	a5,a5,0x3
    80001ae2:	000a3703          	ld	a4,0(s4)
    80001ae6:	02e787b3          	mul	a5,a5,a4
    80001aea:	2785                	addiw	a5,a5,1
    80001aec:	00d7979b          	slliw	a5,a5,0xd
    80001af0:	40f907b3          	sub	a5,s2,a5
    80001af4:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001af6:	16848493          	addi	s1,s1,360
    80001afa:	fd3499e3          	bne	s1,s3,80001acc <procinit+0x6e>
}
    80001afe:	70e2                	ld	ra,56(sp)
    80001b00:	7442                	ld	s0,48(sp)
    80001b02:	74a2                	ld	s1,40(sp)
    80001b04:	7902                	ld	s2,32(sp)
    80001b06:	69e2                	ld	s3,24(sp)
    80001b08:	6a42                	ld	s4,16(sp)
    80001b0a:	6aa2                	ld	s5,8(sp)
    80001b0c:	6b02                	ld	s6,0(sp)
    80001b0e:	6121                	addi	sp,sp,64
    80001b10:	8082                	ret

0000000080001b12 <copy_array>:
{
    80001b12:	1141                	addi	sp,sp,-16
    80001b14:	e422                	sd	s0,8(sp)
    80001b16:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001b18:	00c05c63          	blez	a2,80001b30 <copy_array+0x1e>
    80001b1c:	87aa                	mv	a5,a0
    80001b1e:	9532                	add	a0,a0,a2
        dst[i] = src[i];
    80001b20:	0007c703          	lbu	a4,0(a5)
    80001b24:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001b28:	0785                	addi	a5,a5,1
    80001b2a:	0585                	addi	a1,a1,1
    80001b2c:	fea79ae3          	bne	a5,a0,80001b20 <copy_array+0xe>
}
    80001b30:	6422                	ld	s0,8(sp)
    80001b32:	0141                	addi	sp,sp,16
    80001b34:	8082                	ret

0000000080001b36 <cpuid>:
{
    80001b36:	1141                	addi	sp,sp,-16
    80001b38:	e422                	sd	s0,8(sp)
    80001b3a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b3c:	8512                	mv	a0,tp
}
    80001b3e:	2501                	sext.w	a0,a0
    80001b40:	6422                	ld	s0,8(sp)
    80001b42:	0141                	addi	sp,sp,16
    80001b44:	8082                	ret

0000000080001b46 <mycpu>:
{
    80001b46:	1141                	addi	sp,sp,-16
    80001b48:	e422                	sd	s0,8(sp)
    80001b4a:	0800                	addi	s0,sp,16
    80001b4c:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001b4e:	2781                	sext.w	a5,a5
    80001b50:	079e                	slli	a5,a5,0x7
}
    80001b52:	0000f517          	auipc	a0,0xf
    80001b56:	1ae50513          	addi	a0,a0,430 # 80010d00 <cpus>
    80001b5a:	953e                	add	a0,a0,a5
    80001b5c:	6422                	ld	s0,8(sp)
    80001b5e:	0141                	addi	sp,sp,16
    80001b60:	8082                	ret

0000000080001b62 <myproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
    push_off();
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	0e2080e7          	jalr	226(ra) # 80000c4e <push_off>
    80001b74:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001b76:	2781                	sext.w	a5,a5
    80001b78:	079e                	slli	a5,a5,0x7
    80001b7a:	0000f717          	auipc	a4,0xf
    80001b7e:	18670713          	addi	a4,a4,390 # 80010d00 <cpus>
    80001b82:	97ba                	add	a5,a5,a4
    80001b84:	6384                	ld	s1,0(a5)
    pop_off();
    80001b86:	fffff097          	auipc	ra,0xfffff
    80001b8a:	168080e7          	jalr	360(ra) # 80000cee <pop_off>
}
    80001b8e:	8526                	mv	a0,s1
    80001b90:	60e2                	ld	ra,24(sp)
    80001b92:	6442                	ld	s0,16(sp)
    80001b94:	64a2                	ld	s1,8(sp)
    80001b96:	6105                	addi	sp,sp,32
    80001b98:	8082                	ret

0000000080001b9a <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001b9a:	1141                	addi	sp,sp,-16
    80001b9c:	e406                	sd	ra,8(sp)
    80001b9e:	e022                	sd	s0,0(sp)
    80001ba0:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001ba2:	00000097          	auipc	ra,0x0
    80001ba6:	fc0080e7          	jalr	-64(ra) # 80001b62 <myproc>
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	1a4080e7          	jalr	420(ra) # 80000d4e <release>

    if (first)
    80001bb2:	00007797          	auipc	a5,0x7
    80001bb6:	e1e7a783          	lw	a5,-482(a5) # 800089d0 <first.1>
    80001bba:	eb89                	bnez	a5,80001bcc <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001bbc:	00001097          	auipc	ra,0x1
    80001bc0:	dfe080e7          	jalr	-514(ra) # 800029ba <usertrapret>
}
    80001bc4:	60a2                	ld	ra,8(sp)
    80001bc6:	6402                	ld	s0,0(sp)
    80001bc8:	0141                	addi	sp,sp,16
    80001bca:	8082                	ret
        first = 0;
    80001bcc:	00007797          	auipc	a5,0x7
    80001bd0:	e007a223          	sw	zero,-508(a5) # 800089d0 <first.1>
        fsinit(ROOTDEV);
    80001bd4:	4505                	li	a0,1
    80001bd6:	00002097          	auipc	ra,0x2
    80001bda:	c22080e7          	jalr	-990(ra) # 800037f8 <fsinit>
    80001bde:	bff9                	j	80001bbc <forkret+0x22>

0000000080001be0 <allocpid>:
{
    80001be0:	1101                	addi	sp,sp,-32
    80001be2:	ec06                	sd	ra,24(sp)
    80001be4:	e822                	sd	s0,16(sp)
    80001be6:	e426                	sd	s1,8(sp)
    80001be8:	e04a                	sd	s2,0(sp)
    80001bea:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001bec:	0000f917          	auipc	s2,0xf
    80001bf0:	51490913          	addi	s2,s2,1300 # 80011100 <pid_lock>
    80001bf4:	854a                	mv	a0,s2
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	0a4080e7          	jalr	164(ra) # 80000c9a <acquire>
    pid = nextpid;
    80001bfe:	00007797          	auipc	a5,0x7
    80001c02:	de278793          	addi	a5,a5,-542 # 800089e0 <nextpid>
    80001c06:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001c08:	0014871b          	addiw	a4,s1,1
    80001c0c:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001c0e:	854a                	mv	a0,s2
    80001c10:	fffff097          	auipc	ra,0xfffff
    80001c14:	13e080e7          	jalr	318(ra) # 80000d4e <release>
}
    80001c18:	8526                	mv	a0,s1
    80001c1a:	60e2                	ld	ra,24(sp)
    80001c1c:	6442                	ld	s0,16(sp)
    80001c1e:	64a2                	ld	s1,8(sp)
    80001c20:	6902                	ld	s2,0(sp)
    80001c22:	6105                	addi	sp,sp,32
    80001c24:	8082                	ret

0000000080001c26 <proc_pagetable>:
{
    80001c26:	1101                	addi	sp,sp,-32
    80001c28:	ec06                	sd	ra,24(sp)
    80001c2a:	e822                	sd	s0,16(sp)
    80001c2c:	e426                	sd	s1,8(sp)
    80001c2e:	e04a                	sd	s2,0(sp)
    80001c30:	1000                	addi	s0,sp,32
    80001c32:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	7b6080e7          	jalr	1974(ra) # 800013ea <uvmcreate>
    80001c3c:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001c3e:	c121                	beqz	a0,80001c7e <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c40:	4729                	li	a4,10
    80001c42:	00005697          	auipc	a3,0x5
    80001c46:	3be68693          	addi	a3,a3,958 # 80007000 <_trampoline>
    80001c4a:	6605                	lui	a2,0x1
    80001c4c:	040005b7          	lui	a1,0x4000
    80001c50:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c52:	05b2                	slli	a1,a1,0xc
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	50c080e7          	jalr	1292(ra) # 80001160 <mappages>
    80001c5c:	02054863          	bltz	a0,80001c8c <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c60:	4719                	li	a4,6
    80001c62:	05893683          	ld	a3,88(s2)
    80001c66:	6605                	lui	a2,0x1
    80001c68:	020005b7          	lui	a1,0x2000
    80001c6c:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c6e:	05b6                	slli	a1,a1,0xd
    80001c70:	8526                	mv	a0,s1
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	4ee080e7          	jalr	1262(ra) # 80001160 <mappages>
    80001c7a:	02054163          	bltz	a0,80001c9c <proc_pagetable+0x76>
}
    80001c7e:	8526                	mv	a0,s1
    80001c80:	60e2                	ld	ra,24(sp)
    80001c82:	6442                	ld	s0,16(sp)
    80001c84:	64a2                	ld	s1,8(sp)
    80001c86:	6902                	ld	s2,0(sp)
    80001c88:	6105                	addi	sp,sp,32
    80001c8a:	8082                	ret
        uvmfree(pagetable, 0);
    80001c8c:	4581                	li	a1,0
    80001c8e:	8526                	mv	a0,s1
    80001c90:	00000097          	auipc	ra,0x0
    80001c94:	960080e7          	jalr	-1696(ra) # 800015f0 <uvmfree>
        return 0;
    80001c98:	4481                	li	s1,0
    80001c9a:	b7d5                	j	80001c7e <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c9c:	4681                	li	a3,0
    80001c9e:	4605                	li	a2,1
    80001ca0:	040005b7          	lui	a1,0x4000
    80001ca4:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ca6:	05b2                	slli	a1,a1,0xc
    80001ca8:	8526                	mv	a0,s1
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	67c080e7          	jalr	1660(ra) # 80001326 <uvmunmap>
        uvmfree(pagetable, 0);
    80001cb2:	4581                	li	a1,0
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	93a080e7          	jalr	-1734(ra) # 800015f0 <uvmfree>
        return 0;
    80001cbe:	4481                	li	s1,0
    80001cc0:	bf7d                	j	80001c7e <proc_pagetable+0x58>

0000000080001cc2 <proc_freepagetable>:
{
    80001cc2:	1101                	addi	sp,sp,-32
    80001cc4:	ec06                	sd	ra,24(sp)
    80001cc6:	e822                	sd	s0,16(sp)
    80001cc8:	e426                	sd	s1,8(sp)
    80001cca:	e04a                	sd	s2,0(sp)
    80001ccc:	1000                	addi	s0,sp,32
    80001cce:	84aa                	mv	s1,a0
    80001cd0:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cd2:	4681                	li	a3,0
    80001cd4:	4605                	li	a2,1
    80001cd6:	040005b7          	lui	a1,0x4000
    80001cda:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cdc:	05b2                	slli	a1,a1,0xc
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	648080e7          	jalr	1608(ra) # 80001326 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ce6:	4681                	li	a3,0
    80001ce8:	4605                	li	a2,1
    80001cea:	020005b7          	lui	a1,0x2000
    80001cee:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001cf0:	05b6                	slli	a1,a1,0xd
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	632080e7          	jalr	1586(ra) # 80001326 <uvmunmap>
    uvmfree(pagetable, sz);
    80001cfc:	85ca                	mv	a1,s2
    80001cfe:	8526                	mv	a0,s1
    80001d00:	00000097          	auipc	ra,0x0
    80001d04:	8f0080e7          	jalr	-1808(ra) # 800015f0 <uvmfree>
}
    80001d08:	60e2                	ld	ra,24(sp)
    80001d0a:	6442                	ld	s0,16(sp)
    80001d0c:	64a2                	ld	s1,8(sp)
    80001d0e:	6902                	ld	s2,0(sp)
    80001d10:	6105                	addi	sp,sp,32
    80001d12:	8082                	ret

0000000080001d14 <freeproc>:
{
    80001d14:	1101                	addi	sp,sp,-32
    80001d16:	ec06                	sd	ra,24(sp)
    80001d18:	e822                	sd	s0,16(sp)
    80001d1a:	e426                	sd	s1,8(sp)
    80001d1c:	1000                	addi	s0,sp,32
    80001d1e:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001d20:	6d28                	ld	a0,88(a0)
    80001d22:	c509                	beqz	a0,80001d2c <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	cd2080e7          	jalr	-814(ra) # 800009f6 <kfree>
    p->trapframe = 0;
    80001d2c:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001d30:	68a8                	ld	a0,80(s1)
    80001d32:	c511                	beqz	a0,80001d3e <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001d34:	64ac                	ld	a1,72(s1)
    80001d36:	00000097          	auipc	ra,0x0
    80001d3a:	f8c080e7          	jalr	-116(ra) # 80001cc2 <proc_freepagetable>
    p->pagetable = 0;
    80001d3e:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001d42:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001d46:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001d4a:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001d4e:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001d52:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001d56:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001d5a:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001d5e:	0004ac23          	sw	zero,24(s1)
}
    80001d62:	60e2                	ld	ra,24(sp)
    80001d64:	6442                	ld	s0,16(sp)
    80001d66:	64a2                	ld	s1,8(sp)
    80001d68:	6105                	addi	sp,sp,32
    80001d6a:	8082                	ret

0000000080001d6c <allocproc>:
{
    80001d6c:	1101                	addi	sp,sp,-32
    80001d6e:	ec06                	sd	ra,24(sp)
    80001d70:	e822                	sd	s0,16(sp)
    80001d72:	e426                	sd	s1,8(sp)
    80001d74:	e04a                	sd	s2,0(sp)
    80001d76:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001d78:	0000f497          	auipc	s1,0xf
    80001d7c:	3b848493          	addi	s1,s1,952 # 80011130 <proc>
    80001d80:	00015917          	auipc	s2,0x15
    80001d84:	db090913          	addi	s2,s2,-592 # 80016b30 <tickslock>
        acquire(&p->lock);
    80001d88:	8526                	mv	a0,s1
    80001d8a:	fffff097          	auipc	ra,0xfffff
    80001d8e:	f10080e7          	jalr	-240(ra) # 80000c9a <acquire>
        if (p->state == UNUSED)
    80001d92:	4c9c                	lw	a5,24(s1)
    80001d94:	cf81                	beqz	a5,80001dac <allocproc+0x40>
            release(&p->lock);
    80001d96:	8526                	mv	a0,s1
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	fb6080e7          	jalr	-74(ra) # 80000d4e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001da0:	16848493          	addi	s1,s1,360
    80001da4:	ff2492e3          	bne	s1,s2,80001d88 <allocproc+0x1c>
    return 0;
    80001da8:	4481                	li	s1,0
    80001daa:	a889                	j	80001dfc <allocproc+0x90>
    p->pid = allocpid();
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	e34080e7          	jalr	-460(ra) # 80001be0 <allocpid>
    80001db4:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001db6:	4785                	li	a5,1
    80001db8:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001dba:	fffff097          	auipc	ra,0xfffff
    80001dbe:	da4080e7          	jalr	-604(ra) # 80000b5e <kalloc>
    80001dc2:	892a                	mv	s2,a0
    80001dc4:	eca8                	sd	a0,88(s1)
    80001dc6:	c131                	beqz	a0,80001e0a <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001dc8:	8526                	mv	a0,s1
    80001dca:	00000097          	auipc	ra,0x0
    80001dce:	e5c080e7          	jalr	-420(ra) # 80001c26 <proc_pagetable>
    80001dd2:	892a                	mv	s2,a0
    80001dd4:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001dd6:	c531                	beqz	a0,80001e22 <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001dd8:	07000613          	li	a2,112
    80001ddc:	4581                	li	a1,0
    80001dde:	06048513          	addi	a0,s1,96
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	fb4080e7          	jalr	-76(ra) # 80000d96 <memset>
    p->context.ra = (uint64)forkret;
    80001dea:	00000797          	auipc	a5,0x0
    80001dee:	db078793          	addi	a5,a5,-592 # 80001b9a <forkret>
    80001df2:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001df4:	60bc                	ld	a5,64(s1)
    80001df6:	6705                	lui	a4,0x1
    80001df8:	97ba                	add	a5,a5,a4
    80001dfa:	f4bc                	sd	a5,104(s1)
}
    80001dfc:	8526                	mv	a0,s1
    80001dfe:	60e2                	ld	ra,24(sp)
    80001e00:	6442                	ld	s0,16(sp)
    80001e02:	64a2                	ld	s1,8(sp)
    80001e04:	6902                	ld	s2,0(sp)
    80001e06:	6105                	addi	sp,sp,32
    80001e08:	8082                	ret
        freeproc(p);
    80001e0a:	8526                	mv	a0,s1
    80001e0c:	00000097          	auipc	ra,0x0
    80001e10:	f08080e7          	jalr	-248(ra) # 80001d14 <freeproc>
        release(&p->lock);
    80001e14:	8526                	mv	a0,s1
    80001e16:	fffff097          	auipc	ra,0xfffff
    80001e1a:	f38080e7          	jalr	-200(ra) # 80000d4e <release>
        return 0;
    80001e1e:	84ca                	mv	s1,s2
    80001e20:	bff1                	j	80001dfc <allocproc+0x90>
        freeproc(p);
    80001e22:	8526                	mv	a0,s1
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	ef0080e7          	jalr	-272(ra) # 80001d14 <freeproc>
        release(&p->lock);
    80001e2c:	8526                	mv	a0,s1
    80001e2e:	fffff097          	auipc	ra,0xfffff
    80001e32:	f20080e7          	jalr	-224(ra) # 80000d4e <release>
        return 0;
    80001e36:	84ca                	mv	s1,s2
    80001e38:	b7d1                	j	80001dfc <allocproc+0x90>

0000000080001e3a <userinit>:
{
    80001e3a:	1101                	addi	sp,sp,-32
    80001e3c:	ec06                	sd	ra,24(sp)
    80001e3e:	e822                	sd	s0,16(sp)
    80001e40:	e426                	sd	s1,8(sp)
    80001e42:	1000                	addi	s0,sp,32
    p = allocproc();
    80001e44:	00000097          	auipc	ra,0x0
    80001e48:	f28080e7          	jalr	-216(ra) # 80001d6c <allocproc>
    80001e4c:	84aa                	mv	s1,a0
    initproc = p;
    80001e4e:	00007797          	auipc	a5,0x7
    80001e52:	c2a7bd23          	sd	a0,-966(a5) # 80008a88 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e56:	03400613          	li	a2,52
    80001e5a:	00007597          	auipc	a1,0x7
    80001e5e:	b9658593          	addi	a1,a1,-1130 # 800089f0 <initcode>
    80001e62:	6928                	ld	a0,80(a0)
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	5b4080e7          	jalr	1460(ra) # 80001418 <uvmfirst>
    p->sz = PGSIZE;
    80001e6c:	6785                	lui	a5,0x1
    80001e6e:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80001e70:	6cb8                	ld	a4,88(s1)
    80001e72:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001e76:	6cb8                	ld	a4,88(s1)
    80001e78:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e7a:	4641                	li	a2,16
    80001e7c:	00006597          	auipc	a1,0x6
    80001e80:	3c458593          	addi	a1,a1,964 # 80008240 <digits+0x1f0>
    80001e84:	15848513          	addi	a0,s1,344
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	056080e7          	jalr	86(ra) # 80000ede <safestrcpy>
    p->cwd = namei("/");
    80001e90:	00006517          	auipc	a0,0x6
    80001e94:	3c050513          	addi	a0,a0,960 # 80008250 <digits+0x200>
    80001e98:	00002097          	auipc	ra,0x2
    80001e9c:	37e080e7          	jalr	894(ra) # 80004216 <namei>
    80001ea0:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    80001ea4:	478d                	li	a5,3
    80001ea6:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001ea8:	8526                	mv	a0,s1
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	ea4080e7          	jalr	-348(ra) # 80000d4e <release>
}
    80001eb2:	60e2                	ld	ra,24(sp)
    80001eb4:	6442                	ld	s0,16(sp)
    80001eb6:	64a2                	ld	s1,8(sp)
    80001eb8:	6105                	addi	sp,sp,32
    80001eba:	8082                	ret

0000000080001ebc <growproc>:
{
    80001ebc:	1101                	addi	sp,sp,-32
    80001ebe:	ec06                	sd	ra,24(sp)
    80001ec0:	e822                	sd	s0,16(sp)
    80001ec2:	e426                	sd	s1,8(sp)
    80001ec4:	e04a                	sd	s2,0(sp)
    80001ec6:	1000                	addi	s0,sp,32
    80001ec8:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001eca:	00000097          	auipc	ra,0x0
    80001ece:	c98080e7          	jalr	-872(ra) # 80001b62 <myproc>
    80001ed2:	84aa                	mv	s1,a0
    sz = p->sz;
    80001ed4:	652c                	ld	a1,72(a0)
    if (n > 0)
    80001ed6:	01204c63          	bgtz	s2,80001eee <growproc+0x32>
    else if (n < 0)
    80001eda:	02094663          	bltz	s2,80001f06 <growproc+0x4a>
    p->sz = sz;
    80001ede:	e4ac                	sd	a1,72(s1)
    return 0;
    80001ee0:	4501                	li	a0,0
}
    80001ee2:	60e2                	ld	ra,24(sp)
    80001ee4:	6442                	ld	s0,16(sp)
    80001ee6:	64a2                	ld	s1,8(sp)
    80001ee8:	6902                	ld	s2,0(sp)
    80001eea:	6105                	addi	sp,sp,32
    80001eec:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001eee:	4691                	li	a3,4
    80001ef0:	00b90633          	add	a2,s2,a1
    80001ef4:	6928                	ld	a0,80(a0)
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	5dc080e7          	jalr	1500(ra) # 800014d2 <uvmalloc>
    80001efe:	85aa                	mv	a1,a0
    80001f00:	fd79                	bnez	a0,80001ede <growproc+0x22>
            return -1;
    80001f02:	557d                	li	a0,-1
    80001f04:	bff9                	j	80001ee2 <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f06:	00b90633          	add	a2,s2,a1
    80001f0a:	6928                	ld	a0,80(a0)
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	57e080e7          	jalr	1406(ra) # 8000148a <uvmdealloc>
    80001f14:	85aa                	mv	a1,a0
    80001f16:	b7e1                	j	80001ede <growproc+0x22>

0000000080001f18 <ps>:
{
    80001f18:	715d                	addi	sp,sp,-80
    80001f1a:	e486                	sd	ra,72(sp)
    80001f1c:	e0a2                	sd	s0,64(sp)
    80001f1e:	fc26                	sd	s1,56(sp)
    80001f20:	f84a                	sd	s2,48(sp)
    80001f22:	f44e                	sd	s3,40(sp)
    80001f24:	f052                	sd	s4,32(sp)
    80001f26:	ec56                	sd	s5,24(sp)
    80001f28:	e85a                	sd	s6,16(sp)
    80001f2a:	e45e                	sd	s7,8(sp)
    80001f2c:	e062                	sd	s8,0(sp)
    80001f2e:	0880                	addi	s0,sp,80
    80001f30:	84aa                	mv	s1,a0
    80001f32:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    80001f34:	00000097          	auipc	ra,0x0
    80001f38:	c2e080e7          	jalr	-978(ra) # 80001b62 <myproc>
    if (count == 0)
    80001f3c:	120b8063          	beqz	s7,8000205c <ps+0x144>
    void *result = (void *)myproc()->sz;
    80001f40:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    80001f44:	003b951b          	slliw	a0,s7,0x3
    80001f48:	0175053b          	addw	a0,a0,s7
    80001f4c:	0025151b          	slliw	a0,a0,0x2
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	f6c080e7          	jalr	-148(ra) # 80001ebc <growproc>
    80001f58:	10054463          	bltz	a0,80002060 <ps+0x148>
    struct user_proc loc_result[count];
    80001f5c:	003b9a13          	slli	s4,s7,0x3
    80001f60:	9a5e                	add	s4,s4,s7
    80001f62:	0a0a                	slli	s4,s4,0x2
    80001f64:	00fa0793          	addi	a5,s4,15
    80001f68:	8391                	srli	a5,a5,0x4
    80001f6a:	0792                	slli	a5,a5,0x4
    80001f6c:	40f10133          	sub	sp,sp,a5
    80001f70:	8a8a                	mv	s5,sp
    struct proc *p = proc + (start * sizeof(proc));
    80001f72:	007e97b7          	lui	a5,0x7e9
    80001f76:	02f484b3          	mul	s1,s1,a5
    80001f7a:	0000f797          	auipc	a5,0xf
    80001f7e:	1b678793          	addi	a5,a5,438 # 80011130 <proc>
    80001f82:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    80001f84:	00015797          	auipc	a5,0x15
    80001f88:	bac78793          	addi	a5,a5,-1108 # 80016b30 <tickslock>
    80001f8c:	0cf4fc63          	bgeu	s1,a5,80002064 <ps+0x14c>
        if (localCount == count)
    80001f90:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    80001f94:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    80001f96:	8c3e                	mv	s8,a5
    80001f98:	a069                	j	80002022 <ps+0x10a>
            loc_result[localCount].state = UNUSED;
    80001f9a:	00399793          	slli	a5,s3,0x3
    80001f9e:	97ce                	add	a5,a5,s3
    80001fa0:	078a                	slli	a5,a5,0x2
    80001fa2:	97d6                	add	a5,a5,s5
    80001fa4:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    80001fa8:	8526                	mv	a0,s1
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	da4080e7          	jalr	-604(ra) # 80000d4e <release>
    if (localCount < count)
    80001fb2:	0179f963          	bgeu	s3,s7,80001fc4 <ps+0xac>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    80001fb6:	00399793          	slli	a5,s3,0x3
    80001fba:	97ce                	add	a5,a5,s3
    80001fbc:	078a                	slli	a5,a5,0x2
    80001fbe:	97d6                	add	a5,a5,s5
    80001fc0:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    80001fc4:	84da                	mv	s1,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    80001fc6:	00000097          	auipc	ra,0x0
    80001fca:	b9c080e7          	jalr	-1124(ra) # 80001b62 <myproc>
    80001fce:	86d2                	mv	a3,s4
    80001fd0:	8656                	mv	a2,s5
    80001fd2:	85da                	mv	a1,s6
    80001fd4:	6928                	ld	a0,80(a0)
    80001fd6:	fffff097          	auipc	ra,0xfffff
    80001fda:	758080e7          	jalr	1880(ra) # 8000172e <copyout>
}
    80001fde:	8526                	mv	a0,s1
    80001fe0:	fb040113          	addi	sp,s0,-80
    80001fe4:	60a6                	ld	ra,72(sp)
    80001fe6:	6406                	ld	s0,64(sp)
    80001fe8:	74e2                	ld	s1,56(sp)
    80001fea:	7942                	ld	s2,48(sp)
    80001fec:	79a2                	ld	s3,40(sp)
    80001fee:	7a02                	ld	s4,32(sp)
    80001ff0:	6ae2                	ld	s5,24(sp)
    80001ff2:	6b42                	ld	s6,16(sp)
    80001ff4:	6ba2                	ld	s7,8(sp)
    80001ff6:	6c02                	ld	s8,0(sp)
    80001ff8:	6161                	addi	sp,sp,80
    80001ffa:	8082                	ret
            loc_result[localCount].parent_id = p->parent->pid;
    80001ffc:	5b9c                	lw	a5,48(a5)
    80001ffe:	fef92e23          	sw	a5,-4(s2)
        release(&p->lock);
    80002002:	8526                	mv	a0,s1
    80002004:	fffff097          	auipc	ra,0xfffff
    80002008:	d4a080e7          	jalr	-694(ra) # 80000d4e <release>
        localCount++;
    8000200c:	2985                	addiw	s3,s3,1
    8000200e:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    80002012:	16848493          	addi	s1,s1,360
    80002016:	f984fee3          	bgeu	s1,s8,80001fb2 <ps+0x9a>
        if (localCount == count)
    8000201a:	02490913          	addi	s2,s2,36
    8000201e:	fb3b83e3          	beq	s7,s3,80001fc4 <ps+0xac>
        acquire(&p->lock);
    80002022:	8526                	mv	a0,s1
    80002024:	fffff097          	auipc	ra,0xfffff
    80002028:	c76080e7          	jalr	-906(ra) # 80000c9a <acquire>
        if (p->state == UNUSED)
    8000202c:	4c9c                	lw	a5,24(s1)
    8000202e:	d7b5                	beqz	a5,80001f9a <ps+0x82>
        loc_result[localCount].state = p->state;
    80002030:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    80002034:	549c                	lw	a5,40(s1)
    80002036:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    8000203a:	54dc                	lw	a5,44(s1)
    8000203c:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    80002040:	589c                	lw	a5,48(s1)
    80002042:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    80002046:	4641                	li	a2,16
    80002048:	85ca                	mv	a1,s2
    8000204a:	15848513          	addi	a0,s1,344
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	ac4080e7          	jalr	-1340(ra) # 80001b12 <copy_array>
        if (p->parent != 0) // init
    80002056:	7c9c                	ld	a5,56(s1)
    80002058:	f3d5                	bnez	a5,80001ffc <ps+0xe4>
    8000205a:	b765                	j	80002002 <ps+0xea>
        return result;
    8000205c:	4481                	li	s1,0
    8000205e:	b741                	j	80001fde <ps+0xc6>
        return result;
    80002060:	4481                	li	s1,0
    80002062:	bfb5                	j	80001fde <ps+0xc6>
        return result;
    80002064:	4481                	li	s1,0
    80002066:	bfa5                	j	80001fde <ps+0xc6>

0000000080002068 <fork>:
{
    80002068:	7139                	addi	sp,sp,-64
    8000206a:	fc06                	sd	ra,56(sp)
    8000206c:	f822                	sd	s0,48(sp)
    8000206e:	f426                	sd	s1,40(sp)
    80002070:	f04a                	sd	s2,32(sp)
    80002072:	ec4e                	sd	s3,24(sp)
    80002074:	e852                	sd	s4,16(sp)
    80002076:	e456                	sd	s5,8(sp)
    80002078:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    8000207a:	00000097          	auipc	ra,0x0
    8000207e:	ae8080e7          	jalr	-1304(ra) # 80001b62 <myproc>
    80002082:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    80002084:	00000097          	auipc	ra,0x0
    80002088:	ce8080e7          	jalr	-792(ra) # 80001d6c <allocproc>
    8000208c:	10050c63          	beqz	a0,800021a4 <fork+0x13c>
    80002090:	8a2a                	mv	s4,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80002092:	048ab603          	ld	a2,72(s5)
    80002096:	692c                	ld	a1,80(a0)
    80002098:	050ab503          	ld	a0,80(s5)
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	58e080e7          	jalr	1422(ra) # 8000162a <uvmcopy>
    800020a4:	04054863          	bltz	a0,800020f4 <fork+0x8c>
    np->sz = p->sz;
    800020a8:	048ab783          	ld	a5,72(s5)
    800020ac:	04fa3423          	sd	a5,72(s4)
    *(np->trapframe) = *(p->trapframe);
    800020b0:	058ab683          	ld	a3,88(s5)
    800020b4:	87b6                	mv	a5,a3
    800020b6:	058a3703          	ld	a4,88(s4)
    800020ba:	12068693          	addi	a3,a3,288
    800020be:	0007b803          	ld	a6,0(a5)
    800020c2:	6788                	ld	a0,8(a5)
    800020c4:	6b8c                	ld	a1,16(a5)
    800020c6:	6f90                	ld	a2,24(a5)
    800020c8:	01073023          	sd	a6,0(a4)
    800020cc:	e708                	sd	a0,8(a4)
    800020ce:	eb0c                	sd	a1,16(a4)
    800020d0:	ef10                	sd	a2,24(a4)
    800020d2:	02078793          	addi	a5,a5,32
    800020d6:	02070713          	addi	a4,a4,32
    800020da:	fed792e3          	bne	a5,a3,800020be <fork+0x56>
    np->trapframe->a0 = 0;
    800020de:	058a3783          	ld	a5,88(s4)
    800020e2:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    800020e6:	0d0a8493          	addi	s1,s5,208
    800020ea:	0d0a0913          	addi	s2,s4,208
    800020ee:	150a8993          	addi	s3,s5,336
    800020f2:	a00d                	j	80002114 <fork+0xac>
        freeproc(np);
    800020f4:	8552                	mv	a0,s4
    800020f6:	00000097          	auipc	ra,0x0
    800020fa:	c1e080e7          	jalr	-994(ra) # 80001d14 <freeproc>
        release(&np->lock);
    800020fe:	8552                	mv	a0,s4
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	c4e080e7          	jalr	-946(ra) # 80000d4e <release>
        return -1;
    80002108:	597d                	li	s2,-1
    8000210a:	a059                	j	80002190 <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    8000210c:	04a1                	addi	s1,s1,8
    8000210e:	0921                	addi	s2,s2,8
    80002110:	01348b63          	beq	s1,s3,80002126 <fork+0xbe>
        if (p->ofile[i])
    80002114:	6088                	ld	a0,0(s1)
    80002116:	d97d                	beqz	a0,8000210c <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    80002118:	00002097          	auipc	ra,0x2
    8000211c:	770080e7          	jalr	1904(ra) # 80004888 <filedup>
    80002120:	00a93023          	sd	a0,0(s2)
    80002124:	b7e5                	j	8000210c <fork+0xa4>
    np->cwd = idup(p->cwd);
    80002126:	150ab503          	ld	a0,336(s5)
    8000212a:	00002097          	auipc	ra,0x2
    8000212e:	908080e7          	jalr	-1784(ra) # 80003a32 <idup>
    80002132:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    80002136:	4641                	li	a2,16
    80002138:	158a8593          	addi	a1,s5,344
    8000213c:	158a0513          	addi	a0,s4,344
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	d9e080e7          	jalr	-610(ra) # 80000ede <safestrcpy>
    pid = np->pid;
    80002148:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    8000214c:	8552                	mv	a0,s4
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	c00080e7          	jalr	-1024(ra) # 80000d4e <release>
    acquire(&wait_lock);
    80002156:	0000f497          	auipc	s1,0xf
    8000215a:	fc248493          	addi	s1,s1,-62 # 80011118 <wait_lock>
    8000215e:	8526                	mv	a0,s1
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	b3a080e7          	jalr	-1222(ra) # 80000c9a <acquire>
    np->parent = p;
    80002168:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    8000216c:	8526                	mv	a0,s1
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	be0080e7          	jalr	-1056(ra) # 80000d4e <release>
    acquire(&np->lock);
    80002176:	8552                	mv	a0,s4
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	b22080e7          	jalr	-1246(ra) # 80000c9a <acquire>
    np->state = RUNNABLE;
    80002180:	478d                	li	a5,3
    80002182:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    80002186:	8552                	mv	a0,s4
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	bc6080e7          	jalr	-1082(ra) # 80000d4e <release>
}
    80002190:	854a                	mv	a0,s2
    80002192:	70e2                	ld	ra,56(sp)
    80002194:	7442                	ld	s0,48(sp)
    80002196:	74a2                	ld	s1,40(sp)
    80002198:	7902                	ld	s2,32(sp)
    8000219a:	69e2                	ld	s3,24(sp)
    8000219c:	6a42                	ld	s4,16(sp)
    8000219e:	6aa2                	ld	s5,8(sp)
    800021a0:	6121                	addi	sp,sp,64
    800021a2:	8082                	ret
        return -1;
    800021a4:	597d                	li	s2,-1
    800021a6:	b7ed                	j	80002190 <fork+0x128>

00000000800021a8 <scheduler>:
{
    800021a8:	1101                	addi	sp,sp,-32
    800021aa:	ec06                	sd	ra,24(sp)
    800021ac:	e822                	sd	s0,16(sp)
    800021ae:	e426                	sd	s1,8(sp)
    800021b0:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    800021b2:	00007497          	auipc	s1,0x7
    800021b6:	82648493          	addi	s1,s1,-2010 # 800089d8 <sched_pointer>
    800021ba:	609c                	ld	a5,0(s1)
    800021bc:	9782                	jalr	a5
    while (1)
    800021be:	bff5                	j	800021ba <scheduler+0x12>

00000000800021c0 <sched>:
{
    800021c0:	7179                	addi	sp,sp,-48
    800021c2:	f406                	sd	ra,40(sp)
    800021c4:	f022                	sd	s0,32(sp)
    800021c6:	ec26                	sd	s1,24(sp)
    800021c8:	e84a                	sd	s2,16(sp)
    800021ca:	e44e                	sd	s3,8(sp)
    800021cc:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    800021ce:	00000097          	auipc	ra,0x0
    800021d2:	994080e7          	jalr	-1644(ra) # 80001b62 <myproc>
    800021d6:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	a48080e7          	jalr	-1464(ra) # 80000c20 <holding>
    800021e0:	c53d                	beqz	a0,8000224e <sched+0x8e>
    800021e2:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    800021e4:	2781                	sext.w	a5,a5
    800021e6:	079e                	slli	a5,a5,0x7
    800021e8:	0000f717          	auipc	a4,0xf
    800021ec:	b1870713          	addi	a4,a4,-1256 # 80010d00 <cpus>
    800021f0:	97ba                	add	a5,a5,a4
    800021f2:	5fb8                	lw	a4,120(a5)
    800021f4:	4785                	li	a5,1
    800021f6:	06f71463          	bne	a4,a5,8000225e <sched+0x9e>
    if (p->state == RUNNING)
    800021fa:	4c98                	lw	a4,24(s1)
    800021fc:	4791                	li	a5,4
    800021fe:	06f70863          	beq	a4,a5,8000226e <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002202:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002206:	8b89                	andi	a5,a5,2
    if (intr_get())
    80002208:	ebbd                	bnez	a5,8000227e <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000220a:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    8000220c:	0000f917          	auipc	s2,0xf
    80002210:	af490913          	addi	s2,s2,-1292 # 80010d00 <cpus>
    80002214:	2781                	sext.w	a5,a5
    80002216:	079e                	slli	a5,a5,0x7
    80002218:	97ca                	add	a5,a5,s2
    8000221a:	07c7a983          	lw	s3,124(a5)
    8000221e:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    80002220:	2581                	sext.w	a1,a1
    80002222:	059e                	slli	a1,a1,0x7
    80002224:	05a1                	addi	a1,a1,8
    80002226:	95ca                	add	a1,a1,s2
    80002228:	06048513          	addi	a0,s1,96
    8000222c:	00000097          	auipc	ra,0x0
    80002230:	6e4080e7          	jalr	1764(ra) # 80002910 <swtch>
    80002234:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    80002236:	2781                	sext.w	a5,a5
    80002238:	079e                	slli	a5,a5,0x7
    8000223a:	993e                	add	s2,s2,a5
    8000223c:	07392e23          	sw	s3,124(s2)
}
    80002240:	70a2                	ld	ra,40(sp)
    80002242:	7402                	ld	s0,32(sp)
    80002244:	64e2                	ld	s1,24(sp)
    80002246:	6942                	ld	s2,16(sp)
    80002248:	69a2                	ld	s3,8(sp)
    8000224a:	6145                	addi	sp,sp,48
    8000224c:	8082                	ret
        panic("sched p->lock");
    8000224e:	00006517          	auipc	a0,0x6
    80002252:	00a50513          	addi	a0,a0,10 # 80008258 <digits+0x208>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	2e6080e7          	jalr	742(ra) # 8000053c <panic>
        panic("sched locks");
    8000225e:	00006517          	auipc	a0,0x6
    80002262:	00a50513          	addi	a0,a0,10 # 80008268 <digits+0x218>
    80002266:	ffffe097          	auipc	ra,0xffffe
    8000226a:	2d6080e7          	jalr	726(ra) # 8000053c <panic>
        panic("sched running");
    8000226e:	00006517          	auipc	a0,0x6
    80002272:	00a50513          	addi	a0,a0,10 # 80008278 <digits+0x228>
    80002276:	ffffe097          	auipc	ra,0xffffe
    8000227a:	2c6080e7          	jalr	710(ra) # 8000053c <panic>
        panic("sched interruptible");
    8000227e:	00006517          	auipc	a0,0x6
    80002282:	00a50513          	addi	a0,a0,10 # 80008288 <digits+0x238>
    80002286:	ffffe097          	auipc	ra,0xffffe
    8000228a:	2b6080e7          	jalr	694(ra) # 8000053c <panic>

000000008000228e <yield>:
{
    8000228e:	1101                	addi	sp,sp,-32
    80002290:	ec06                	sd	ra,24(sp)
    80002292:	e822                	sd	s0,16(sp)
    80002294:	e426                	sd	s1,8(sp)
    80002296:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80002298:	00000097          	auipc	ra,0x0
    8000229c:	8ca080e7          	jalr	-1846(ra) # 80001b62 <myproc>
    800022a0:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	9f8080e7          	jalr	-1544(ra) # 80000c9a <acquire>
    p->state = RUNNABLE;
    800022aa:	478d                	li	a5,3
    800022ac:	cc9c                	sw	a5,24(s1)
    sched();
    800022ae:	00000097          	auipc	ra,0x0
    800022b2:	f12080e7          	jalr	-238(ra) # 800021c0 <sched>
    release(&p->lock);
    800022b6:	8526                	mv	a0,s1
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	a96080e7          	jalr	-1386(ra) # 80000d4e <release>
}
    800022c0:	60e2                	ld	ra,24(sp)
    800022c2:	6442                	ld	s0,16(sp)
    800022c4:	64a2                	ld	s1,8(sp)
    800022c6:	6105                	addi	sp,sp,32
    800022c8:	8082                	ret

00000000800022ca <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800022ca:	7179                	addi	sp,sp,-48
    800022cc:	f406                	sd	ra,40(sp)
    800022ce:	f022                	sd	s0,32(sp)
    800022d0:	ec26                	sd	s1,24(sp)
    800022d2:	e84a                	sd	s2,16(sp)
    800022d4:	e44e                	sd	s3,8(sp)
    800022d6:	1800                	addi	s0,sp,48
    800022d8:	89aa                	mv	s3,a0
    800022da:	892e                	mv	s2,a1
    struct proc *p = myproc();
    800022dc:	00000097          	auipc	ra,0x0
    800022e0:	886080e7          	jalr	-1914(ra) # 80001b62 <myproc>
    800022e4:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	9b4080e7          	jalr	-1612(ra) # 80000c9a <acquire>
    release(lk);
    800022ee:	854a                	mv	a0,s2
    800022f0:	fffff097          	auipc	ra,0xfffff
    800022f4:	a5e080e7          	jalr	-1442(ra) # 80000d4e <release>

    // Go to sleep.
    p->chan = chan;
    800022f8:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    800022fc:	4789                	li	a5,2
    800022fe:	cc9c                	sw	a5,24(s1)

    sched();
    80002300:	00000097          	auipc	ra,0x0
    80002304:	ec0080e7          	jalr	-320(ra) # 800021c0 <sched>

    // Tidy up.
    p->chan = 0;
    80002308:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    8000230c:	8526                	mv	a0,s1
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	a40080e7          	jalr	-1472(ra) # 80000d4e <release>
    acquire(lk);
    80002316:	854a                	mv	a0,s2
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	982080e7          	jalr	-1662(ra) # 80000c9a <acquire>
}
    80002320:	70a2                	ld	ra,40(sp)
    80002322:	7402                	ld	s0,32(sp)
    80002324:	64e2                	ld	s1,24(sp)
    80002326:	6942                	ld	s2,16(sp)
    80002328:	69a2                	ld	s3,8(sp)
    8000232a:	6145                	addi	sp,sp,48
    8000232c:	8082                	ret

000000008000232e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000232e:	7139                	addi	sp,sp,-64
    80002330:	fc06                	sd	ra,56(sp)
    80002332:	f822                	sd	s0,48(sp)
    80002334:	f426                	sd	s1,40(sp)
    80002336:	f04a                	sd	s2,32(sp)
    80002338:	ec4e                	sd	s3,24(sp)
    8000233a:	e852                	sd	s4,16(sp)
    8000233c:	e456                	sd	s5,8(sp)
    8000233e:	0080                	addi	s0,sp,64
    80002340:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002342:	0000f497          	auipc	s1,0xf
    80002346:	dee48493          	addi	s1,s1,-530 # 80011130 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    8000234a:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    8000234c:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    8000234e:	00014917          	auipc	s2,0x14
    80002352:	7e290913          	addi	s2,s2,2018 # 80016b30 <tickslock>
    80002356:	a811                	j	8000236a <wakeup+0x3c>
            }
            release(&p->lock);
    80002358:	8526                	mv	a0,s1
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	9f4080e7          	jalr	-1548(ra) # 80000d4e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002362:	16848493          	addi	s1,s1,360
    80002366:	03248663          	beq	s1,s2,80002392 <wakeup+0x64>
        if (p != myproc())
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	7f8080e7          	jalr	2040(ra) # 80001b62 <myproc>
    80002372:	fea488e3          	beq	s1,a0,80002362 <wakeup+0x34>
            acquire(&p->lock);
    80002376:	8526                	mv	a0,s1
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	922080e7          	jalr	-1758(ra) # 80000c9a <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    80002380:	4c9c                	lw	a5,24(s1)
    80002382:	fd379be3          	bne	a5,s3,80002358 <wakeup+0x2a>
    80002386:	709c                	ld	a5,32(s1)
    80002388:	fd4798e3          	bne	a5,s4,80002358 <wakeup+0x2a>
                p->state = RUNNABLE;
    8000238c:	0154ac23          	sw	s5,24(s1)
    80002390:	b7e1                	j	80002358 <wakeup+0x2a>
        }
    }
}
    80002392:	70e2                	ld	ra,56(sp)
    80002394:	7442                	ld	s0,48(sp)
    80002396:	74a2                	ld	s1,40(sp)
    80002398:	7902                	ld	s2,32(sp)
    8000239a:	69e2                	ld	s3,24(sp)
    8000239c:	6a42                	ld	s4,16(sp)
    8000239e:	6aa2                	ld	s5,8(sp)
    800023a0:	6121                	addi	sp,sp,64
    800023a2:	8082                	ret

00000000800023a4 <reparent>:
{
    800023a4:	7179                	addi	sp,sp,-48
    800023a6:	f406                	sd	ra,40(sp)
    800023a8:	f022                	sd	s0,32(sp)
    800023aa:	ec26                	sd	s1,24(sp)
    800023ac:	e84a                	sd	s2,16(sp)
    800023ae:	e44e                	sd	s3,8(sp)
    800023b0:	e052                	sd	s4,0(sp)
    800023b2:	1800                	addi	s0,sp,48
    800023b4:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023b6:	0000f497          	auipc	s1,0xf
    800023ba:	d7a48493          	addi	s1,s1,-646 # 80011130 <proc>
            pp->parent = initproc;
    800023be:	00006a17          	auipc	s4,0x6
    800023c2:	6caa0a13          	addi	s4,s4,1738 # 80008a88 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023c6:	00014997          	auipc	s3,0x14
    800023ca:	76a98993          	addi	s3,s3,1898 # 80016b30 <tickslock>
    800023ce:	a029                	j	800023d8 <reparent+0x34>
    800023d0:	16848493          	addi	s1,s1,360
    800023d4:	01348d63          	beq	s1,s3,800023ee <reparent+0x4a>
        if (pp->parent == p)
    800023d8:	7c9c                	ld	a5,56(s1)
    800023da:	ff279be3          	bne	a5,s2,800023d0 <reparent+0x2c>
            pp->parent = initproc;
    800023de:	000a3503          	ld	a0,0(s4)
    800023e2:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    800023e4:	00000097          	auipc	ra,0x0
    800023e8:	f4a080e7          	jalr	-182(ra) # 8000232e <wakeup>
    800023ec:	b7d5                	j	800023d0 <reparent+0x2c>
}
    800023ee:	70a2                	ld	ra,40(sp)
    800023f0:	7402                	ld	s0,32(sp)
    800023f2:	64e2                	ld	s1,24(sp)
    800023f4:	6942                	ld	s2,16(sp)
    800023f6:	69a2                	ld	s3,8(sp)
    800023f8:	6a02                	ld	s4,0(sp)
    800023fa:	6145                	addi	sp,sp,48
    800023fc:	8082                	ret

00000000800023fe <exit>:
{
    800023fe:	7179                	addi	sp,sp,-48
    80002400:	f406                	sd	ra,40(sp)
    80002402:	f022                	sd	s0,32(sp)
    80002404:	ec26                	sd	s1,24(sp)
    80002406:	e84a                	sd	s2,16(sp)
    80002408:	e44e                	sd	s3,8(sp)
    8000240a:	e052                	sd	s4,0(sp)
    8000240c:	1800                	addi	s0,sp,48
    8000240e:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	752080e7          	jalr	1874(ra) # 80001b62 <myproc>
    80002418:	89aa                	mv	s3,a0
    if (p == initproc)
    8000241a:	00006797          	auipc	a5,0x6
    8000241e:	66e7b783          	ld	a5,1646(a5) # 80008a88 <initproc>
    80002422:	0d050493          	addi	s1,a0,208
    80002426:	15050913          	addi	s2,a0,336
    8000242a:	02a79363          	bne	a5,a0,80002450 <exit+0x52>
        panic("init exiting");
    8000242e:	00006517          	auipc	a0,0x6
    80002432:	e7250513          	addi	a0,a0,-398 # 800082a0 <digits+0x250>
    80002436:	ffffe097          	auipc	ra,0xffffe
    8000243a:	106080e7          	jalr	262(ra) # 8000053c <panic>
            fileclose(f);
    8000243e:	00002097          	auipc	ra,0x2
    80002442:	49c080e7          	jalr	1180(ra) # 800048da <fileclose>
            p->ofile[fd] = 0;
    80002446:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    8000244a:	04a1                	addi	s1,s1,8
    8000244c:	01248563          	beq	s1,s2,80002456 <exit+0x58>
        if (p->ofile[fd])
    80002450:	6088                	ld	a0,0(s1)
    80002452:	f575                	bnez	a0,8000243e <exit+0x40>
    80002454:	bfdd                	j	8000244a <exit+0x4c>
    begin_op();
    80002456:	00002097          	auipc	ra,0x2
    8000245a:	fc0080e7          	jalr	-64(ra) # 80004416 <begin_op>
    iput(p->cwd);
    8000245e:	1509b503          	ld	a0,336(s3)
    80002462:	00001097          	auipc	ra,0x1
    80002466:	7c8080e7          	jalr	1992(ra) # 80003c2a <iput>
    end_op();
    8000246a:	00002097          	auipc	ra,0x2
    8000246e:	026080e7          	jalr	38(ra) # 80004490 <end_op>
    p->cwd = 0;
    80002472:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    80002476:	0000f497          	auipc	s1,0xf
    8000247a:	ca248493          	addi	s1,s1,-862 # 80011118 <wait_lock>
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	81a080e7          	jalr	-2022(ra) # 80000c9a <acquire>
    reparent(p);
    80002488:	854e                	mv	a0,s3
    8000248a:	00000097          	auipc	ra,0x0
    8000248e:	f1a080e7          	jalr	-230(ra) # 800023a4 <reparent>
    wakeup(p->parent);
    80002492:	0389b503          	ld	a0,56(s3)
    80002496:	00000097          	auipc	ra,0x0
    8000249a:	e98080e7          	jalr	-360(ra) # 8000232e <wakeup>
    acquire(&p->lock);
    8000249e:	854e                	mv	a0,s3
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	7fa080e7          	jalr	2042(ra) # 80000c9a <acquire>
    p->xstate = status;
    800024a8:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    800024ac:	4795                	li	a5,5
    800024ae:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    800024b2:	8526                	mv	a0,s1
    800024b4:	fffff097          	auipc	ra,0xfffff
    800024b8:	89a080e7          	jalr	-1894(ra) # 80000d4e <release>
    sched();
    800024bc:	00000097          	auipc	ra,0x0
    800024c0:	d04080e7          	jalr	-764(ra) # 800021c0 <sched>
    panic("zombie exit");
    800024c4:	00006517          	auipc	a0,0x6
    800024c8:	dec50513          	addi	a0,a0,-532 # 800082b0 <digits+0x260>
    800024cc:	ffffe097          	auipc	ra,0xffffe
    800024d0:	070080e7          	jalr	112(ra) # 8000053c <panic>

00000000800024d4 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800024d4:	7179                	addi	sp,sp,-48
    800024d6:	f406                	sd	ra,40(sp)
    800024d8:	f022                	sd	s0,32(sp)
    800024da:	ec26                	sd	s1,24(sp)
    800024dc:	e84a                	sd	s2,16(sp)
    800024de:	e44e                	sd	s3,8(sp)
    800024e0:	1800                	addi	s0,sp,48
    800024e2:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800024e4:	0000f497          	auipc	s1,0xf
    800024e8:	c4c48493          	addi	s1,s1,-948 # 80011130 <proc>
    800024ec:	00014997          	auipc	s3,0x14
    800024f0:	64498993          	addi	s3,s3,1604 # 80016b30 <tickslock>
    {
        acquire(&p->lock);
    800024f4:	8526                	mv	a0,s1
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	7a4080e7          	jalr	1956(ra) # 80000c9a <acquire>
        if (p->pid == pid)
    800024fe:	589c                	lw	a5,48(s1)
    80002500:	01278d63          	beq	a5,s2,8000251a <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    80002504:	8526                	mv	a0,s1
    80002506:	fffff097          	auipc	ra,0xfffff
    8000250a:	848080e7          	jalr	-1976(ra) # 80000d4e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000250e:	16848493          	addi	s1,s1,360
    80002512:	ff3491e3          	bne	s1,s3,800024f4 <kill+0x20>
    }
    return -1;
    80002516:	557d                	li	a0,-1
    80002518:	a829                	j	80002532 <kill+0x5e>
            p->killed = 1;
    8000251a:	4785                	li	a5,1
    8000251c:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    8000251e:	4c98                	lw	a4,24(s1)
    80002520:	4789                	li	a5,2
    80002522:	00f70f63          	beq	a4,a5,80002540 <kill+0x6c>
            release(&p->lock);
    80002526:	8526                	mv	a0,s1
    80002528:	fffff097          	auipc	ra,0xfffff
    8000252c:	826080e7          	jalr	-2010(ra) # 80000d4e <release>
            return 0;
    80002530:	4501                	li	a0,0
}
    80002532:	70a2                	ld	ra,40(sp)
    80002534:	7402                	ld	s0,32(sp)
    80002536:	64e2                	ld	s1,24(sp)
    80002538:	6942                	ld	s2,16(sp)
    8000253a:	69a2                	ld	s3,8(sp)
    8000253c:	6145                	addi	sp,sp,48
    8000253e:	8082                	ret
                p->state = RUNNABLE;
    80002540:	478d                	li	a5,3
    80002542:	cc9c                	sw	a5,24(s1)
    80002544:	b7cd                	j	80002526 <kill+0x52>

0000000080002546 <setkilled>:

void setkilled(struct proc *p)
{
    80002546:	1101                	addi	sp,sp,-32
    80002548:	ec06                	sd	ra,24(sp)
    8000254a:	e822                	sd	s0,16(sp)
    8000254c:	e426                	sd	s1,8(sp)
    8000254e:	1000                	addi	s0,sp,32
    80002550:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002552:	ffffe097          	auipc	ra,0xffffe
    80002556:	748080e7          	jalr	1864(ra) # 80000c9a <acquire>
    p->killed = 1;
    8000255a:	4785                	li	a5,1
    8000255c:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    8000255e:	8526                	mv	a0,s1
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	7ee080e7          	jalr	2030(ra) # 80000d4e <release>
}
    80002568:	60e2                	ld	ra,24(sp)
    8000256a:	6442                	ld	s0,16(sp)
    8000256c:	64a2                	ld	s1,8(sp)
    8000256e:	6105                	addi	sp,sp,32
    80002570:	8082                	ret

0000000080002572 <killed>:

int killed(struct proc *p)
{
    80002572:	1101                	addi	sp,sp,-32
    80002574:	ec06                	sd	ra,24(sp)
    80002576:	e822                	sd	s0,16(sp)
    80002578:	e426                	sd	s1,8(sp)
    8000257a:	e04a                	sd	s2,0(sp)
    8000257c:	1000                	addi	s0,sp,32
    8000257e:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	71a080e7          	jalr	1818(ra) # 80000c9a <acquire>
    k = p->killed;
    80002588:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    8000258c:	8526                	mv	a0,s1
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	7c0080e7          	jalr	1984(ra) # 80000d4e <release>
    return k;
}
    80002596:	854a                	mv	a0,s2
    80002598:	60e2                	ld	ra,24(sp)
    8000259a:	6442                	ld	s0,16(sp)
    8000259c:	64a2                	ld	s1,8(sp)
    8000259e:	6902                	ld	s2,0(sp)
    800025a0:	6105                	addi	sp,sp,32
    800025a2:	8082                	ret

00000000800025a4 <wait>:
{
    800025a4:	715d                	addi	sp,sp,-80
    800025a6:	e486                	sd	ra,72(sp)
    800025a8:	e0a2                	sd	s0,64(sp)
    800025aa:	fc26                	sd	s1,56(sp)
    800025ac:	f84a                	sd	s2,48(sp)
    800025ae:	f44e                	sd	s3,40(sp)
    800025b0:	f052                	sd	s4,32(sp)
    800025b2:	ec56                	sd	s5,24(sp)
    800025b4:	e85a                	sd	s6,16(sp)
    800025b6:	e45e                	sd	s7,8(sp)
    800025b8:	e062                	sd	s8,0(sp)
    800025ba:	0880                	addi	s0,sp,80
    800025bc:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    800025be:	fffff097          	auipc	ra,0xfffff
    800025c2:	5a4080e7          	jalr	1444(ra) # 80001b62 <myproc>
    800025c6:	892a                	mv	s2,a0
    acquire(&wait_lock);
    800025c8:	0000f517          	auipc	a0,0xf
    800025cc:	b5050513          	addi	a0,a0,-1200 # 80011118 <wait_lock>
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	6ca080e7          	jalr	1738(ra) # 80000c9a <acquire>
        havekids = 0;
    800025d8:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    800025da:	4a15                	li	s4,5
                havekids = 1;
    800025dc:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800025de:	00014997          	auipc	s3,0x14
    800025e2:	55298993          	addi	s3,s3,1362 # 80016b30 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    800025e6:	0000fc17          	auipc	s8,0xf
    800025ea:	b32c0c13          	addi	s8,s8,-1230 # 80011118 <wait_lock>
    800025ee:	a0d1                	j	800026b2 <wait+0x10e>
                    pid = pp->pid;
    800025f0:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800025f4:	000b0e63          	beqz	s6,80002610 <wait+0x6c>
    800025f8:	4691                	li	a3,4
    800025fa:	02c48613          	addi	a2,s1,44
    800025fe:	85da                	mv	a1,s6
    80002600:	05093503          	ld	a0,80(s2)
    80002604:	fffff097          	auipc	ra,0xfffff
    80002608:	12a080e7          	jalr	298(ra) # 8000172e <copyout>
    8000260c:	04054163          	bltz	a0,8000264e <wait+0xaa>
                    freeproc(pp);
    80002610:	8526                	mv	a0,s1
    80002612:	fffff097          	auipc	ra,0xfffff
    80002616:	702080e7          	jalr	1794(ra) # 80001d14 <freeproc>
                    release(&pp->lock);
    8000261a:	8526                	mv	a0,s1
    8000261c:	ffffe097          	auipc	ra,0xffffe
    80002620:	732080e7          	jalr	1842(ra) # 80000d4e <release>
                    release(&wait_lock);
    80002624:	0000f517          	auipc	a0,0xf
    80002628:	af450513          	addi	a0,a0,-1292 # 80011118 <wait_lock>
    8000262c:	ffffe097          	auipc	ra,0xffffe
    80002630:	722080e7          	jalr	1826(ra) # 80000d4e <release>
}
    80002634:	854e                	mv	a0,s3
    80002636:	60a6                	ld	ra,72(sp)
    80002638:	6406                	ld	s0,64(sp)
    8000263a:	74e2                	ld	s1,56(sp)
    8000263c:	7942                	ld	s2,48(sp)
    8000263e:	79a2                	ld	s3,40(sp)
    80002640:	7a02                	ld	s4,32(sp)
    80002642:	6ae2                	ld	s5,24(sp)
    80002644:	6b42                	ld	s6,16(sp)
    80002646:	6ba2                	ld	s7,8(sp)
    80002648:	6c02                	ld	s8,0(sp)
    8000264a:	6161                	addi	sp,sp,80
    8000264c:	8082                	ret
                        release(&pp->lock);
    8000264e:	8526                	mv	a0,s1
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	6fe080e7          	jalr	1790(ra) # 80000d4e <release>
                        release(&wait_lock);
    80002658:	0000f517          	auipc	a0,0xf
    8000265c:	ac050513          	addi	a0,a0,-1344 # 80011118 <wait_lock>
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	6ee080e7          	jalr	1774(ra) # 80000d4e <release>
                        return -1;
    80002668:	59fd                	li	s3,-1
    8000266a:	b7e9                	j	80002634 <wait+0x90>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    8000266c:	16848493          	addi	s1,s1,360
    80002670:	03348463          	beq	s1,s3,80002698 <wait+0xf4>
            if (pp->parent == p)
    80002674:	7c9c                	ld	a5,56(s1)
    80002676:	ff279be3          	bne	a5,s2,8000266c <wait+0xc8>
                acquire(&pp->lock);
    8000267a:	8526                	mv	a0,s1
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	61e080e7          	jalr	1566(ra) # 80000c9a <acquire>
                if (pp->state == ZOMBIE)
    80002684:	4c9c                	lw	a5,24(s1)
    80002686:	f74785e3          	beq	a5,s4,800025f0 <wait+0x4c>
                release(&pp->lock);
    8000268a:	8526                	mv	a0,s1
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	6c2080e7          	jalr	1730(ra) # 80000d4e <release>
                havekids = 1;
    80002694:	8756                	mv	a4,s5
    80002696:	bfd9                	j	8000266c <wait+0xc8>
        if (!havekids || killed(p))
    80002698:	c31d                	beqz	a4,800026be <wait+0x11a>
    8000269a:	854a                	mv	a0,s2
    8000269c:	00000097          	auipc	ra,0x0
    800026a0:	ed6080e7          	jalr	-298(ra) # 80002572 <killed>
    800026a4:	ed09                	bnez	a0,800026be <wait+0x11a>
        sleep(p, &wait_lock); // DOC: wait-sleep
    800026a6:	85e2                	mv	a1,s8
    800026a8:	854a                	mv	a0,s2
    800026aa:	00000097          	auipc	ra,0x0
    800026ae:	c20080e7          	jalr	-992(ra) # 800022ca <sleep>
        havekids = 0;
    800026b2:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800026b4:	0000f497          	auipc	s1,0xf
    800026b8:	a7c48493          	addi	s1,s1,-1412 # 80011130 <proc>
    800026bc:	bf65                	j	80002674 <wait+0xd0>
            release(&wait_lock);
    800026be:	0000f517          	auipc	a0,0xf
    800026c2:	a5a50513          	addi	a0,a0,-1446 # 80011118 <wait_lock>
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	688080e7          	jalr	1672(ra) # 80000d4e <release>
            return -1;
    800026ce:	59fd                	li	s3,-1
    800026d0:	b795                	j	80002634 <wait+0x90>

00000000800026d2 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026d2:	7179                	addi	sp,sp,-48
    800026d4:	f406                	sd	ra,40(sp)
    800026d6:	f022                	sd	s0,32(sp)
    800026d8:	ec26                	sd	s1,24(sp)
    800026da:	e84a                	sd	s2,16(sp)
    800026dc:	e44e                	sd	s3,8(sp)
    800026de:	e052                	sd	s4,0(sp)
    800026e0:	1800                	addi	s0,sp,48
    800026e2:	84aa                	mv	s1,a0
    800026e4:	892e                	mv	s2,a1
    800026e6:	89b2                	mv	s3,a2
    800026e8:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800026ea:	fffff097          	auipc	ra,0xfffff
    800026ee:	478080e7          	jalr	1144(ra) # 80001b62 <myproc>
    if (user_dst)
    800026f2:	c08d                	beqz	s1,80002714 <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    800026f4:	86d2                	mv	a3,s4
    800026f6:	864e                	mv	a2,s3
    800026f8:	85ca                	mv	a1,s2
    800026fa:	6928                	ld	a0,80(a0)
    800026fc:	fffff097          	auipc	ra,0xfffff
    80002700:	032080e7          	jalr	50(ra) # 8000172e <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    80002704:	70a2                	ld	ra,40(sp)
    80002706:	7402                	ld	s0,32(sp)
    80002708:	64e2                	ld	s1,24(sp)
    8000270a:	6942                	ld	s2,16(sp)
    8000270c:	69a2                	ld	s3,8(sp)
    8000270e:	6a02                	ld	s4,0(sp)
    80002710:	6145                	addi	sp,sp,48
    80002712:	8082                	ret
        memmove((char *)dst, src, len);
    80002714:	000a061b          	sext.w	a2,s4
    80002718:	85ce                	mv	a1,s3
    8000271a:	854a                	mv	a0,s2
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	6d6080e7          	jalr	1750(ra) # 80000df2 <memmove>
        return 0;
    80002724:	8526                	mv	a0,s1
    80002726:	bff9                	j	80002704 <either_copyout+0x32>

0000000080002728 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002728:	7179                	addi	sp,sp,-48
    8000272a:	f406                	sd	ra,40(sp)
    8000272c:	f022                	sd	s0,32(sp)
    8000272e:	ec26                	sd	s1,24(sp)
    80002730:	e84a                	sd	s2,16(sp)
    80002732:	e44e                	sd	s3,8(sp)
    80002734:	e052                	sd	s4,0(sp)
    80002736:	1800                	addi	s0,sp,48
    80002738:	892a                	mv	s2,a0
    8000273a:	84ae                	mv	s1,a1
    8000273c:	89b2                	mv	s3,a2
    8000273e:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002740:	fffff097          	auipc	ra,0xfffff
    80002744:	422080e7          	jalr	1058(ra) # 80001b62 <myproc>
    if (user_src)
    80002748:	c08d                	beqz	s1,8000276a <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    8000274a:	86d2                	mv	a3,s4
    8000274c:	864e                	mv	a2,s3
    8000274e:	85ca                	mv	a1,s2
    80002750:	6928                	ld	a0,80(a0)
    80002752:	fffff097          	auipc	ra,0xfffff
    80002756:	068080e7          	jalr	104(ra) # 800017ba <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    8000275a:	70a2                	ld	ra,40(sp)
    8000275c:	7402                	ld	s0,32(sp)
    8000275e:	64e2                	ld	s1,24(sp)
    80002760:	6942                	ld	s2,16(sp)
    80002762:	69a2                	ld	s3,8(sp)
    80002764:	6a02                	ld	s4,0(sp)
    80002766:	6145                	addi	sp,sp,48
    80002768:	8082                	ret
        memmove(dst, (char *)src, len);
    8000276a:	000a061b          	sext.w	a2,s4
    8000276e:	85ce                	mv	a1,s3
    80002770:	854a                	mv	a0,s2
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	680080e7          	jalr	1664(ra) # 80000df2 <memmove>
        return 0;
    8000277a:	8526                	mv	a0,s1
    8000277c:	bff9                	j	8000275a <either_copyin+0x32>

000000008000277e <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000277e:	715d                	addi	sp,sp,-80
    80002780:	e486                	sd	ra,72(sp)
    80002782:	e0a2                	sd	s0,64(sp)
    80002784:	fc26                	sd	s1,56(sp)
    80002786:	f84a                	sd	s2,48(sp)
    80002788:	f44e                	sd	s3,40(sp)
    8000278a:	f052                	sd	s4,32(sp)
    8000278c:	ec56                	sd	s5,24(sp)
    8000278e:	e85a                	sd	s6,16(sp)
    80002790:	e45e                	sd	s7,8(sp)
    80002792:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    80002794:	00006517          	auipc	a0,0x6
    80002798:	8f450513          	addi	a0,a0,-1804 # 80008088 <digits+0x38>
    8000279c:	ffffe097          	auipc	ra,0xffffe
    800027a0:	dfc080e7          	jalr	-516(ra) # 80000598 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800027a4:	0000f497          	auipc	s1,0xf
    800027a8:	ae448493          	addi	s1,s1,-1308 # 80011288 <proc+0x158>
    800027ac:	00014917          	auipc	s2,0x14
    800027b0:	4dc90913          	addi	s2,s2,1244 # 80016c88 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027b4:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    800027b6:	00006997          	auipc	s3,0x6
    800027ba:	b0a98993          	addi	s3,s3,-1270 # 800082c0 <digits+0x270>
        printf("%d <%s %s", p->pid, state, p->name);
    800027be:	00006a97          	auipc	s5,0x6
    800027c2:	b0aa8a93          	addi	s5,s5,-1270 # 800082c8 <digits+0x278>
        printf("\n");
    800027c6:	00006a17          	auipc	s4,0x6
    800027ca:	8c2a0a13          	addi	s4,s4,-1854 # 80008088 <digits+0x38>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027ce:	00006b97          	auipc	s7,0x6
    800027d2:	c0ab8b93          	addi	s7,s7,-1014 # 800083d8 <states.0>
    800027d6:	a00d                	j	800027f8 <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    800027d8:	ed86a583          	lw	a1,-296(a3)
    800027dc:	8556                	mv	a0,s5
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	dba080e7          	jalr	-582(ra) # 80000598 <printf>
        printf("\n");
    800027e6:	8552                	mv	a0,s4
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	db0080e7          	jalr	-592(ra) # 80000598 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800027f0:	16848493          	addi	s1,s1,360
    800027f4:	03248263          	beq	s1,s2,80002818 <procdump+0x9a>
        if (p->state == UNUSED)
    800027f8:	86a6                	mv	a3,s1
    800027fa:	ec04a783          	lw	a5,-320(s1)
    800027fe:	dbed                	beqz	a5,800027f0 <procdump+0x72>
            state = "???";
    80002800:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002802:	fcfb6be3          	bltu	s6,a5,800027d8 <procdump+0x5a>
    80002806:	02079713          	slli	a4,a5,0x20
    8000280a:	01d75793          	srli	a5,a4,0x1d
    8000280e:	97de                	add	a5,a5,s7
    80002810:	6390                	ld	a2,0(a5)
    80002812:	f279                	bnez	a2,800027d8 <procdump+0x5a>
            state = "???";
    80002814:	864e                	mv	a2,s3
    80002816:	b7c9                	j	800027d8 <procdump+0x5a>
    }
}
    80002818:	60a6                	ld	ra,72(sp)
    8000281a:	6406                	ld	s0,64(sp)
    8000281c:	74e2                	ld	s1,56(sp)
    8000281e:	7942                	ld	s2,48(sp)
    80002820:	79a2                	ld	s3,40(sp)
    80002822:	7a02                	ld	s4,32(sp)
    80002824:	6ae2                	ld	s5,24(sp)
    80002826:	6b42                	ld	s6,16(sp)
    80002828:	6ba2                	ld	s7,8(sp)
    8000282a:	6161                	addi	sp,sp,80
    8000282c:	8082                	ret

000000008000282e <schedls>:

void schedls()
{
    8000282e:	1141                	addi	sp,sp,-16
    80002830:	e406                	sd	ra,8(sp)
    80002832:	e022                	sd	s0,0(sp)
    80002834:	0800                	addi	s0,sp,16
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    80002836:	00006517          	auipc	a0,0x6
    8000283a:	aa250513          	addi	a0,a0,-1374 # 800082d8 <digits+0x288>
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	d5a080e7          	jalr	-678(ra) # 80000598 <printf>
    printf("====================================\n");
    80002846:	00006517          	auipc	a0,0x6
    8000284a:	aba50513          	addi	a0,a0,-1350 # 80008300 <digits+0x2b0>
    8000284e:	ffffe097          	auipc	ra,0xffffe
    80002852:	d4a080e7          	jalr	-694(ra) # 80000598 <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    80002856:	00006717          	auipc	a4,0x6
    8000285a:	1e273703          	ld	a4,482(a4) # 80008a38 <available_schedulers+0x10>
    8000285e:	00006797          	auipc	a5,0x6
    80002862:	17a7b783          	ld	a5,378(a5) # 800089d8 <sched_pointer>
    80002866:	04f70663          	beq	a4,a5,800028b2 <schedls+0x84>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    8000286a:	00006517          	auipc	a0,0x6
    8000286e:	ac650513          	addi	a0,a0,-1338 # 80008330 <digits+0x2e0>
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	d26080e7          	jalr	-730(ra) # 80000598 <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    8000287a:	00006617          	auipc	a2,0x6
    8000287e:	1c662603          	lw	a2,454(a2) # 80008a40 <available_schedulers+0x18>
    80002882:	00006597          	auipc	a1,0x6
    80002886:	1a658593          	addi	a1,a1,422 # 80008a28 <available_schedulers>
    8000288a:	00006517          	auipc	a0,0x6
    8000288e:	aae50513          	addi	a0,a0,-1362 # 80008338 <digits+0x2e8>
    80002892:	ffffe097          	auipc	ra,0xffffe
    80002896:	d06080e7          	jalr	-762(ra) # 80000598 <printf>
    }
    printf("\n*: current scheduler\n\n");
    8000289a:	00006517          	auipc	a0,0x6
    8000289e:	aa650513          	addi	a0,a0,-1370 # 80008340 <digits+0x2f0>
    800028a2:	ffffe097          	auipc	ra,0xffffe
    800028a6:	cf6080e7          	jalr	-778(ra) # 80000598 <printf>
}
    800028aa:	60a2                	ld	ra,8(sp)
    800028ac:	6402                	ld	s0,0(sp)
    800028ae:	0141                	addi	sp,sp,16
    800028b0:	8082                	ret
            printf("[*]\t");
    800028b2:	00006517          	auipc	a0,0x6
    800028b6:	a7650513          	addi	a0,a0,-1418 # 80008328 <digits+0x2d8>
    800028ba:	ffffe097          	auipc	ra,0xffffe
    800028be:	cde080e7          	jalr	-802(ra) # 80000598 <printf>
    800028c2:	bf65                	j	8000287a <schedls+0x4c>

00000000800028c4 <schedset>:

void schedset(int id)
{
    800028c4:	1141                	addi	sp,sp,-16
    800028c6:	e406                	sd	ra,8(sp)
    800028c8:	e022                	sd	s0,0(sp)
    800028ca:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    800028cc:	e90d                	bnez	a0,800028fe <schedset+0x3a>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    800028ce:	00006797          	auipc	a5,0x6
    800028d2:	16a7b783          	ld	a5,362(a5) # 80008a38 <available_schedulers+0x10>
    800028d6:	00006717          	auipc	a4,0x6
    800028da:	10f73123          	sd	a5,258(a4) # 800089d8 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    800028de:	00006597          	auipc	a1,0x6
    800028e2:	14a58593          	addi	a1,a1,330 # 80008a28 <available_schedulers>
    800028e6:	00006517          	auipc	a0,0x6
    800028ea:	a9a50513          	addi	a0,a0,-1382 # 80008380 <digits+0x330>
    800028ee:	ffffe097          	auipc	ra,0xffffe
    800028f2:	caa080e7          	jalr	-854(ra) # 80000598 <printf>
    800028f6:	60a2                	ld	ra,8(sp)
    800028f8:	6402                	ld	s0,0(sp)
    800028fa:	0141                	addi	sp,sp,16
    800028fc:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    800028fe:	00006517          	auipc	a0,0x6
    80002902:	a5a50513          	addi	a0,a0,-1446 # 80008358 <digits+0x308>
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	c92080e7          	jalr	-878(ra) # 80000598 <printf>
        return;
    8000290e:	b7e5                	j	800028f6 <schedset+0x32>

0000000080002910 <swtch>:
    80002910:	00153023          	sd	ra,0(a0)
    80002914:	00253423          	sd	sp,8(a0)
    80002918:	e900                	sd	s0,16(a0)
    8000291a:	ed04                	sd	s1,24(a0)
    8000291c:	03253023          	sd	s2,32(a0)
    80002920:	03353423          	sd	s3,40(a0)
    80002924:	03453823          	sd	s4,48(a0)
    80002928:	03553c23          	sd	s5,56(a0)
    8000292c:	05653023          	sd	s6,64(a0)
    80002930:	05753423          	sd	s7,72(a0)
    80002934:	05853823          	sd	s8,80(a0)
    80002938:	05953c23          	sd	s9,88(a0)
    8000293c:	07a53023          	sd	s10,96(a0)
    80002940:	07b53423          	sd	s11,104(a0)
    80002944:	0005b083          	ld	ra,0(a1)
    80002948:	0085b103          	ld	sp,8(a1)
    8000294c:	6980                	ld	s0,16(a1)
    8000294e:	6d84                	ld	s1,24(a1)
    80002950:	0205b903          	ld	s2,32(a1)
    80002954:	0285b983          	ld	s3,40(a1)
    80002958:	0305ba03          	ld	s4,48(a1)
    8000295c:	0385ba83          	ld	s5,56(a1)
    80002960:	0405bb03          	ld	s6,64(a1)
    80002964:	0485bb83          	ld	s7,72(a1)
    80002968:	0505bc03          	ld	s8,80(a1)
    8000296c:	0585bc83          	ld	s9,88(a1)
    80002970:	0605bd03          	ld	s10,96(a1)
    80002974:	0685bd83          	ld	s11,104(a1)
    80002978:	8082                	ret

000000008000297a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000297a:	1141                	addi	sp,sp,-16
    8000297c:	e406                	sd	ra,8(sp)
    8000297e:	e022                	sd	s0,0(sp)
    80002980:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002982:	00006597          	auipc	a1,0x6
    80002986:	a8658593          	addi	a1,a1,-1402 # 80008408 <states.0+0x30>
    8000298a:	00014517          	auipc	a0,0x14
    8000298e:	1a650513          	addi	a0,a0,422 # 80016b30 <tickslock>
    80002992:	ffffe097          	auipc	ra,0xffffe
    80002996:	278080e7          	jalr	632(ra) # 80000c0a <initlock>
}
    8000299a:	60a2                	ld	ra,8(sp)
    8000299c:	6402                	ld	s0,0(sp)
    8000299e:	0141                	addi	sp,sp,16
    800029a0:	8082                	ret

00000000800029a2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800029a2:	1141                	addi	sp,sp,-16
    800029a4:	e422                	sd	s0,8(sp)
    800029a6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029a8:	00003797          	auipc	a5,0x3
    800029ac:	55878793          	addi	a5,a5,1368 # 80005f00 <kernelvec>
    800029b0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029b4:	6422                	ld	s0,8(sp)
    800029b6:	0141                	addi	sp,sp,16
    800029b8:	8082                	ret

00000000800029ba <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029ba:	1141                	addi	sp,sp,-16
    800029bc:	e406                	sd	ra,8(sp)
    800029be:	e022                	sd	s0,0(sp)
    800029c0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029c2:	fffff097          	auipc	ra,0xfffff
    800029c6:	1a0080e7          	jalr	416(ra) # 80001b62 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029ce:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029d0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800029d4:	00004697          	auipc	a3,0x4
    800029d8:	62c68693          	addi	a3,a3,1580 # 80007000 <_trampoline>
    800029dc:	00004717          	auipc	a4,0x4
    800029e0:	62470713          	addi	a4,a4,1572 # 80007000 <_trampoline>
    800029e4:	8f15                	sub	a4,a4,a3
    800029e6:	040007b7          	lui	a5,0x4000
    800029ea:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800029ec:	07b2                	slli	a5,a5,0xc
    800029ee:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029f0:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029f4:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029f6:	18002673          	csrr	a2,satp
    800029fa:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029fc:	6d30                	ld	a2,88(a0)
    800029fe:	6138                	ld	a4,64(a0)
    80002a00:	6585                	lui	a1,0x1
    80002a02:	972e                	add	a4,a4,a1
    80002a04:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a06:	6d38                	ld	a4,88(a0)
    80002a08:	00000617          	auipc	a2,0x0
    80002a0c:	13460613          	addi	a2,a2,308 # 80002b3c <usertrap>
    80002a10:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a12:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a14:	8612                	mv	a2,tp
    80002a16:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a18:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a1c:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a20:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a24:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a28:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a2a:	6f18                	ld	a4,24(a4)
    80002a2c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a30:	6928                	ld	a0,80(a0)
    80002a32:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002a34:	00004717          	auipc	a4,0x4
    80002a38:	66870713          	addi	a4,a4,1640 # 8000709c <userret>
    80002a3c:	8f15                	sub	a4,a4,a3
    80002a3e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002a40:	577d                	li	a4,-1
    80002a42:	177e                	slli	a4,a4,0x3f
    80002a44:	8d59                	or	a0,a0,a4
    80002a46:	9782                	jalr	a5
}
    80002a48:	60a2                	ld	ra,8(sp)
    80002a4a:	6402                	ld	s0,0(sp)
    80002a4c:	0141                	addi	sp,sp,16
    80002a4e:	8082                	ret

0000000080002a50 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a50:	1101                	addi	sp,sp,-32
    80002a52:	ec06                	sd	ra,24(sp)
    80002a54:	e822                	sd	s0,16(sp)
    80002a56:	e426                	sd	s1,8(sp)
    80002a58:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a5a:	00014497          	auipc	s1,0x14
    80002a5e:	0d648493          	addi	s1,s1,214 # 80016b30 <tickslock>
    80002a62:	8526                	mv	a0,s1
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	236080e7          	jalr	566(ra) # 80000c9a <acquire>
  ticks++;
    80002a6c:	00006517          	auipc	a0,0x6
    80002a70:	02450513          	addi	a0,a0,36 # 80008a90 <ticks>
    80002a74:	411c                	lw	a5,0(a0)
    80002a76:	2785                	addiw	a5,a5,1
    80002a78:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a7a:	00000097          	auipc	ra,0x0
    80002a7e:	8b4080e7          	jalr	-1868(ra) # 8000232e <wakeup>
  release(&tickslock);
    80002a82:	8526                	mv	a0,s1
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	2ca080e7          	jalr	714(ra) # 80000d4e <release>
}
    80002a8c:	60e2                	ld	ra,24(sp)
    80002a8e:	6442                	ld	s0,16(sp)
    80002a90:	64a2                	ld	s1,8(sp)
    80002a92:	6105                	addi	sp,sp,32
    80002a94:	8082                	ret

0000000080002a96 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a96:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a9a:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002a9c:	0807df63          	bgez	a5,80002b3a <devintr+0xa4>
{
    80002aa0:	1101                	addi	sp,sp,-32
    80002aa2:	ec06                	sd	ra,24(sp)
    80002aa4:	e822                	sd	s0,16(sp)
    80002aa6:	e426                	sd	s1,8(sp)
    80002aa8:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    80002aaa:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002aae:	46a5                	li	a3,9
    80002ab0:	00d70d63          	beq	a4,a3,80002aca <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002ab4:	577d                	li	a4,-1
    80002ab6:	177e                	slli	a4,a4,0x3f
    80002ab8:	0705                	addi	a4,a4,1
    return 0;
    80002aba:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002abc:	04e78e63          	beq	a5,a4,80002b18 <devintr+0x82>
  }
}
    80002ac0:	60e2                	ld	ra,24(sp)
    80002ac2:	6442                	ld	s0,16(sp)
    80002ac4:	64a2                	ld	s1,8(sp)
    80002ac6:	6105                	addi	sp,sp,32
    80002ac8:	8082                	ret
    int irq = plic_claim();
    80002aca:	00003097          	auipc	ra,0x3
    80002ace:	53e080e7          	jalr	1342(ra) # 80006008 <plic_claim>
    80002ad2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ad4:	47a9                	li	a5,10
    80002ad6:	02f50763          	beq	a0,a5,80002b04 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002ada:	4785                	li	a5,1
    80002adc:	02f50963          	beq	a0,a5,80002b0e <devintr+0x78>
    return 1;
    80002ae0:	4505                	li	a0,1
    } else if(irq){
    80002ae2:	dcf9                	beqz	s1,80002ac0 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ae4:	85a6                	mv	a1,s1
    80002ae6:	00006517          	auipc	a0,0x6
    80002aea:	92a50513          	addi	a0,a0,-1750 # 80008410 <states.0+0x38>
    80002aee:	ffffe097          	auipc	ra,0xffffe
    80002af2:	aaa080e7          	jalr	-1366(ra) # 80000598 <printf>
      plic_complete(irq);
    80002af6:	8526                	mv	a0,s1
    80002af8:	00003097          	auipc	ra,0x3
    80002afc:	534080e7          	jalr	1332(ra) # 8000602c <plic_complete>
    return 1;
    80002b00:	4505                	li	a0,1
    80002b02:	bf7d                	j	80002ac0 <devintr+0x2a>
      uartintr();
    80002b04:	ffffe097          	auipc	ra,0xffffe
    80002b08:	ea2080e7          	jalr	-350(ra) # 800009a6 <uartintr>
    if(irq)
    80002b0c:	b7ed                	j	80002af6 <devintr+0x60>
      virtio_disk_intr();
    80002b0e:	00004097          	auipc	ra,0x4
    80002b12:	9e4080e7          	jalr	-1564(ra) # 800064f2 <virtio_disk_intr>
    if(irq)
    80002b16:	b7c5                	j	80002af6 <devintr+0x60>
    if(cpuid() == 0){
    80002b18:	fffff097          	auipc	ra,0xfffff
    80002b1c:	01e080e7          	jalr	30(ra) # 80001b36 <cpuid>
    80002b20:	c901                	beqz	a0,80002b30 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b22:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b26:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b28:	14479073          	csrw	sip,a5
    return 2;
    80002b2c:	4509                	li	a0,2
    80002b2e:	bf49                	j	80002ac0 <devintr+0x2a>
      clockintr();
    80002b30:	00000097          	auipc	ra,0x0
    80002b34:	f20080e7          	jalr	-224(ra) # 80002a50 <clockintr>
    80002b38:	b7ed                	j	80002b22 <devintr+0x8c>
}
    80002b3a:	8082                	ret

0000000080002b3c <usertrap>:
{
    80002b3c:	1101                	addi	sp,sp,-32
    80002b3e:	ec06                	sd	ra,24(sp)
    80002b40:	e822                	sd	s0,16(sp)
    80002b42:	e426                	sd	s1,8(sp)
    80002b44:	e04a                	sd	s2,0(sp)
    80002b46:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b48:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b4c:	1007f793          	andi	a5,a5,256
    80002b50:	e3b1                	bnez	a5,80002b94 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b52:	00003797          	auipc	a5,0x3
    80002b56:	3ae78793          	addi	a5,a5,942 # 80005f00 <kernelvec>
    80002b5a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b5e:	fffff097          	auipc	ra,0xfffff
    80002b62:	004080e7          	jalr	4(ra) # 80001b62 <myproc>
    80002b66:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b68:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b6a:	14102773          	csrr	a4,sepc
    80002b6e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b70:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b74:	47a1                	li	a5,8
    80002b76:	02f70763          	beq	a4,a5,80002ba4 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002b7a:	00000097          	auipc	ra,0x0
    80002b7e:	f1c080e7          	jalr	-228(ra) # 80002a96 <devintr>
    80002b82:	892a                	mv	s2,a0
    80002b84:	c151                	beqz	a0,80002c08 <usertrap+0xcc>
  if(killed(p))
    80002b86:	8526                	mv	a0,s1
    80002b88:	00000097          	auipc	ra,0x0
    80002b8c:	9ea080e7          	jalr	-1558(ra) # 80002572 <killed>
    80002b90:	c929                	beqz	a0,80002be2 <usertrap+0xa6>
    80002b92:	a099                	j	80002bd8 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002b94:	00006517          	auipc	a0,0x6
    80002b98:	89c50513          	addi	a0,a0,-1892 # 80008430 <states.0+0x58>
    80002b9c:	ffffe097          	auipc	ra,0xffffe
    80002ba0:	9a0080e7          	jalr	-1632(ra) # 8000053c <panic>
    if(killed(p))
    80002ba4:	00000097          	auipc	ra,0x0
    80002ba8:	9ce080e7          	jalr	-1586(ra) # 80002572 <killed>
    80002bac:	e921                	bnez	a0,80002bfc <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002bae:	6cb8                	ld	a4,88(s1)
    80002bb0:	6f1c                	ld	a5,24(a4)
    80002bb2:	0791                	addi	a5,a5,4
    80002bb4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bb6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bba:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bbe:	10079073          	csrw	sstatus,a5
    syscall();
    80002bc2:	00000097          	auipc	ra,0x0
    80002bc6:	2d4080e7          	jalr	724(ra) # 80002e96 <syscall>
  if(killed(p))
    80002bca:	8526                	mv	a0,s1
    80002bcc:	00000097          	auipc	ra,0x0
    80002bd0:	9a6080e7          	jalr	-1626(ra) # 80002572 <killed>
    80002bd4:	c911                	beqz	a0,80002be8 <usertrap+0xac>
    80002bd6:	4901                	li	s2,0
    exit(-1);
    80002bd8:	557d                	li	a0,-1
    80002bda:	00000097          	auipc	ra,0x0
    80002bde:	824080e7          	jalr	-2012(ra) # 800023fe <exit>
  if(which_dev == 2)
    80002be2:	4789                	li	a5,2
    80002be4:	04f90f63          	beq	s2,a5,80002c42 <usertrap+0x106>
  usertrapret();
    80002be8:	00000097          	auipc	ra,0x0
    80002bec:	dd2080e7          	jalr	-558(ra) # 800029ba <usertrapret>
}
    80002bf0:	60e2                	ld	ra,24(sp)
    80002bf2:	6442                	ld	s0,16(sp)
    80002bf4:	64a2                	ld	s1,8(sp)
    80002bf6:	6902                	ld	s2,0(sp)
    80002bf8:	6105                	addi	sp,sp,32
    80002bfa:	8082                	ret
      exit(-1);
    80002bfc:	557d                	li	a0,-1
    80002bfe:	00000097          	auipc	ra,0x0
    80002c02:	800080e7          	jalr	-2048(ra) # 800023fe <exit>
    80002c06:	b765                	j	80002bae <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c08:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c0c:	5890                	lw	a2,48(s1)
    80002c0e:	00006517          	auipc	a0,0x6
    80002c12:	84250513          	addi	a0,a0,-1982 # 80008450 <states.0+0x78>
    80002c16:	ffffe097          	auipc	ra,0xffffe
    80002c1a:	982080e7          	jalr	-1662(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c1e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c22:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c26:	00006517          	auipc	a0,0x6
    80002c2a:	85a50513          	addi	a0,a0,-1958 # 80008480 <states.0+0xa8>
    80002c2e:	ffffe097          	auipc	ra,0xffffe
    80002c32:	96a080e7          	jalr	-1686(ra) # 80000598 <printf>
    setkilled(p);
    80002c36:	8526                	mv	a0,s1
    80002c38:	00000097          	auipc	ra,0x0
    80002c3c:	90e080e7          	jalr	-1778(ra) # 80002546 <setkilled>
    80002c40:	b769                	j	80002bca <usertrap+0x8e>
    yield();
    80002c42:	fffff097          	auipc	ra,0xfffff
    80002c46:	64c080e7          	jalr	1612(ra) # 8000228e <yield>
    80002c4a:	bf79                	j	80002be8 <usertrap+0xac>

0000000080002c4c <kerneltrap>:
{
    80002c4c:	7179                	addi	sp,sp,-48
    80002c4e:	f406                	sd	ra,40(sp)
    80002c50:	f022                	sd	s0,32(sp)
    80002c52:	ec26                	sd	s1,24(sp)
    80002c54:	e84a                	sd	s2,16(sp)
    80002c56:	e44e                	sd	s3,8(sp)
    80002c58:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c5a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c5e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c62:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c66:	1004f793          	andi	a5,s1,256
    80002c6a:	cb85                	beqz	a5,80002c9a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c6c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c70:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c72:	ef85                	bnez	a5,80002caa <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c74:	00000097          	auipc	ra,0x0
    80002c78:	e22080e7          	jalr	-478(ra) # 80002a96 <devintr>
    80002c7c:	cd1d                	beqz	a0,80002cba <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c7e:	4789                	li	a5,2
    80002c80:	06f50a63          	beq	a0,a5,80002cf4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c84:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c88:	10049073          	csrw	sstatus,s1
}
    80002c8c:	70a2                	ld	ra,40(sp)
    80002c8e:	7402                	ld	s0,32(sp)
    80002c90:	64e2                	ld	s1,24(sp)
    80002c92:	6942                	ld	s2,16(sp)
    80002c94:	69a2                	ld	s3,8(sp)
    80002c96:	6145                	addi	sp,sp,48
    80002c98:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c9a:	00006517          	auipc	a0,0x6
    80002c9e:	80650513          	addi	a0,a0,-2042 # 800084a0 <states.0+0xc8>
    80002ca2:	ffffe097          	auipc	ra,0xffffe
    80002ca6:	89a080e7          	jalr	-1894(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002caa:	00006517          	auipc	a0,0x6
    80002cae:	81e50513          	addi	a0,a0,-2018 # 800084c8 <states.0+0xf0>
    80002cb2:	ffffe097          	auipc	ra,0xffffe
    80002cb6:	88a080e7          	jalr	-1910(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002cba:	85ce                	mv	a1,s3
    80002cbc:	00006517          	auipc	a0,0x6
    80002cc0:	82c50513          	addi	a0,a0,-2004 # 800084e8 <states.0+0x110>
    80002cc4:	ffffe097          	auipc	ra,0xffffe
    80002cc8:	8d4080e7          	jalr	-1836(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ccc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cd0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cd4:	00006517          	auipc	a0,0x6
    80002cd8:	82450513          	addi	a0,a0,-2012 # 800084f8 <states.0+0x120>
    80002cdc:	ffffe097          	auipc	ra,0xffffe
    80002ce0:	8bc080e7          	jalr	-1860(ra) # 80000598 <printf>
    panic("kerneltrap");
    80002ce4:	00006517          	auipc	a0,0x6
    80002ce8:	82c50513          	addi	a0,a0,-2004 # 80008510 <states.0+0x138>
    80002cec:	ffffe097          	auipc	ra,0xffffe
    80002cf0:	850080e7          	jalr	-1968(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	e6e080e7          	jalr	-402(ra) # 80001b62 <myproc>
    80002cfc:	d541                	beqz	a0,80002c84 <kerneltrap+0x38>
    80002cfe:	fffff097          	auipc	ra,0xfffff
    80002d02:	e64080e7          	jalr	-412(ra) # 80001b62 <myproc>
    80002d06:	4d18                	lw	a4,24(a0)
    80002d08:	4791                	li	a5,4
    80002d0a:	f6f71de3          	bne	a4,a5,80002c84 <kerneltrap+0x38>
    yield();
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	580080e7          	jalr	1408(ra) # 8000228e <yield>
    80002d16:	b7bd                	j	80002c84 <kerneltrap+0x38>

0000000080002d18 <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d18:	1101                	addi	sp,sp,-32
    80002d1a:	ec06                	sd	ra,24(sp)
    80002d1c:	e822                	sd	s0,16(sp)
    80002d1e:	e426                	sd	s1,8(sp)
    80002d20:	1000                	addi	s0,sp,32
    80002d22:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002d24:	fffff097          	auipc	ra,0xfffff
    80002d28:	e3e080e7          	jalr	-450(ra) # 80001b62 <myproc>
    switch (n)
    80002d2c:	4795                	li	a5,5
    80002d2e:	0497e163          	bltu	a5,s1,80002d70 <argraw+0x58>
    80002d32:	048a                	slli	s1,s1,0x2
    80002d34:	00006717          	auipc	a4,0x6
    80002d38:	81470713          	addi	a4,a4,-2028 # 80008548 <states.0+0x170>
    80002d3c:	94ba                	add	s1,s1,a4
    80002d3e:	409c                	lw	a5,0(s1)
    80002d40:	97ba                	add	a5,a5,a4
    80002d42:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002d44:	6d3c                	ld	a5,88(a0)
    80002d46:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002d48:	60e2                	ld	ra,24(sp)
    80002d4a:	6442                	ld	s0,16(sp)
    80002d4c:	64a2                	ld	s1,8(sp)
    80002d4e:	6105                	addi	sp,sp,32
    80002d50:	8082                	ret
        return p->trapframe->a1;
    80002d52:	6d3c                	ld	a5,88(a0)
    80002d54:	7fa8                	ld	a0,120(a5)
    80002d56:	bfcd                	j	80002d48 <argraw+0x30>
        return p->trapframe->a2;
    80002d58:	6d3c                	ld	a5,88(a0)
    80002d5a:	63c8                	ld	a0,128(a5)
    80002d5c:	b7f5                	j	80002d48 <argraw+0x30>
        return p->trapframe->a3;
    80002d5e:	6d3c                	ld	a5,88(a0)
    80002d60:	67c8                	ld	a0,136(a5)
    80002d62:	b7dd                	j	80002d48 <argraw+0x30>
        return p->trapframe->a4;
    80002d64:	6d3c                	ld	a5,88(a0)
    80002d66:	6bc8                	ld	a0,144(a5)
    80002d68:	b7c5                	j	80002d48 <argraw+0x30>
        return p->trapframe->a5;
    80002d6a:	6d3c                	ld	a5,88(a0)
    80002d6c:	6fc8                	ld	a0,152(a5)
    80002d6e:	bfe9                	j	80002d48 <argraw+0x30>
    panic("argraw");
    80002d70:	00005517          	auipc	a0,0x5
    80002d74:	7b050513          	addi	a0,a0,1968 # 80008520 <states.0+0x148>
    80002d78:	ffffd097          	auipc	ra,0xffffd
    80002d7c:	7c4080e7          	jalr	1988(ra) # 8000053c <panic>

0000000080002d80 <fetchaddr>:
{
    80002d80:	1101                	addi	sp,sp,-32
    80002d82:	ec06                	sd	ra,24(sp)
    80002d84:	e822                	sd	s0,16(sp)
    80002d86:	e426                	sd	s1,8(sp)
    80002d88:	e04a                	sd	s2,0(sp)
    80002d8a:	1000                	addi	s0,sp,32
    80002d8c:	84aa                	mv	s1,a0
    80002d8e:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002d90:	fffff097          	auipc	ra,0xfffff
    80002d94:	dd2080e7          	jalr	-558(ra) # 80001b62 <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002d98:	653c                	ld	a5,72(a0)
    80002d9a:	02f4f863          	bgeu	s1,a5,80002dca <fetchaddr+0x4a>
    80002d9e:	00848713          	addi	a4,s1,8
    80002da2:	02e7e663          	bltu	a5,a4,80002dce <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002da6:	46a1                	li	a3,8
    80002da8:	8626                	mv	a2,s1
    80002daa:	85ca                	mv	a1,s2
    80002dac:	6928                	ld	a0,80(a0)
    80002dae:	fffff097          	auipc	ra,0xfffff
    80002db2:	a0c080e7          	jalr	-1524(ra) # 800017ba <copyin>
    80002db6:	00a03533          	snez	a0,a0
    80002dba:	40a00533          	neg	a0,a0
}
    80002dbe:	60e2                	ld	ra,24(sp)
    80002dc0:	6442                	ld	s0,16(sp)
    80002dc2:	64a2                	ld	s1,8(sp)
    80002dc4:	6902                	ld	s2,0(sp)
    80002dc6:	6105                	addi	sp,sp,32
    80002dc8:	8082                	ret
        return -1;
    80002dca:	557d                	li	a0,-1
    80002dcc:	bfcd                	j	80002dbe <fetchaddr+0x3e>
    80002dce:	557d                	li	a0,-1
    80002dd0:	b7fd                	j	80002dbe <fetchaddr+0x3e>

0000000080002dd2 <fetchstr>:
{
    80002dd2:	7179                	addi	sp,sp,-48
    80002dd4:	f406                	sd	ra,40(sp)
    80002dd6:	f022                	sd	s0,32(sp)
    80002dd8:	ec26                	sd	s1,24(sp)
    80002dda:	e84a                	sd	s2,16(sp)
    80002ddc:	e44e                	sd	s3,8(sp)
    80002dde:	1800                	addi	s0,sp,48
    80002de0:	892a                	mv	s2,a0
    80002de2:	84ae                	mv	s1,a1
    80002de4:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002de6:	fffff097          	auipc	ra,0xfffff
    80002dea:	d7c080e7          	jalr	-644(ra) # 80001b62 <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002dee:	86ce                	mv	a3,s3
    80002df0:	864a                	mv	a2,s2
    80002df2:	85a6                	mv	a1,s1
    80002df4:	6928                	ld	a0,80(a0)
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	a52080e7          	jalr	-1454(ra) # 80001848 <copyinstr>
    80002dfe:	00054e63          	bltz	a0,80002e1a <fetchstr+0x48>
    return strlen(buf);
    80002e02:	8526                	mv	a0,s1
    80002e04:	ffffe097          	auipc	ra,0xffffe
    80002e08:	10c080e7          	jalr	268(ra) # 80000f10 <strlen>
}
    80002e0c:	70a2                	ld	ra,40(sp)
    80002e0e:	7402                	ld	s0,32(sp)
    80002e10:	64e2                	ld	s1,24(sp)
    80002e12:	6942                	ld	s2,16(sp)
    80002e14:	69a2                	ld	s3,8(sp)
    80002e16:	6145                	addi	sp,sp,48
    80002e18:	8082                	ret
        return -1;
    80002e1a:	557d                	li	a0,-1
    80002e1c:	bfc5                	j	80002e0c <fetchstr+0x3a>

0000000080002e1e <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002e1e:	1101                	addi	sp,sp,-32
    80002e20:	ec06                	sd	ra,24(sp)
    80002e22:	e822                	sd	s0,16(sp)
    80002e24:	e426                	sd	s1,8(sp)
    80002e26:	1000                	addi	s0,sp,32
    80002e28:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002e2a:	00000097          	auipc	ra,0x0
    80002e2e:	eee080e7          	jalr	-274(ra) # 80002d18 <argraw>
    80002e32:	c088                	sw	a0,0(s1)
}
    80002e34:	60e2                	ld	ra,24(sp)
    80002e36:	6442                	ld	s0,16(sp)
    80002e38:	64a2                	ld	s1,8(sp)
    80002e3a:	6105                	addi	sp,sp,32
    80002e3c:	8082                	ret

0000000080002e3e <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002e3e:	1101                	addi	sp,sp,-32
    80002e40:	ec06                	sd	ra,24(sp)
    80002e42:	e822                	sd	s0,16(sp)
    80002e44:	e426                	sd	s1,8(sp)
    80002e46:	1000                	addi	s0,sp,32
    80002e48:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002e4a:	00000097          	auipc	ra,0x0
    80002e4e:	ece080e7          	jalr	-306(ra) # 80002d18 <argraw>
    80002e52:	e088                	sd	a0,0(s1)
}
    80002e54:	60e2                	ld	ra,24(sp)
    80002e56:	6442                	ld	s0,16(sp)
    80002e58:	64a2                	ld	s1,8(sp)
    80002e5a:	6105                	addi	sp,sp,32
    80002e5c:	8082                	ret

0000000080002e5e <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002e5e:	7179                	addi	sp,sp,-48
    80002e60:	f406                	sd	ra,40(sp)
    80002e62:	f022                	sd	s0,32(sp)
    80002e64:	ec26                	sd	s1,24(sp)
    80002e66:	e84a                	sd	s2,16(sp)
    80002e68:	1800                	addi	s0,sp,48
    80002e6a:	84ae                	mv	s1,a1
    80002e6c:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    80002e6e:	fd840593          	addi	a1,s0,-40
    80002e72:	00000097          	auipc	ra,0x0
    80002e76:	fcc080e7          	jalr	-52(ra) # 80002e3e <argaddr>
    return fetchstr(addr, buf, max);
    80002e7a:	864a                	mv	a2,s2
    80002e7c:	85a6                	mv	a1,s1
    80002e7e:	fd843503          	ld	a0,-40(s0)
    80002e82:	00000097          	auipc	ra,0x0
    80002e86:	f50080e7          	jalr	-176(ra) # 80002dd2 <fetchstr>
}
    80002e8a:	70a2                	ld	ra,40(sp)
    80002e8c:	7402                	ld	s0,32(sp)
    80002e8e:	64e2                	ld	s1,24(sp)
    80002e90:	6942                	ld	s2,16(sp)
    80002e92:	6145                	addi	sp,sp,48
    80002e94:	8082                	ret

0000000080002e96 <syscall>:
    [SYS_pfreepages] sys_pfreepages,
    [SYS_va2pa] sys_va2pa,
};

void syscall(void)
{
    80002e96:	1101                	addi	sp,sp,-32
    80002e98:	ec06                	sd	ra,24(sp)
    80002e9a:	e822                	sd	s0,16(sp)
    80002e9c:	e426                	sd	s1,8(sp)
    80002e9e:	e04a                	sd	s2,0(sp)
    80002ea0:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    80002ea2:	fffff097          	auipc	ra,0xfffff
    80002ea6:	cc0080e7          	jalr	-832(ra) # 80001b62 <myproc>
    80002eaa:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    80002eac:	05853903          	ld	s2,88(a0)
    80002eb0:	0a893783          	ld	a5,168(s2)
    80002eb4:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002eb8:	37fd                	addiw	a5,a5,-1
    80002eba:	4765                	li	a4,25
    80002ebc:	00f76f63          	bltu	a4,a5,80002eda <syscall+0x44>
    80002ec0:	00369713          	slli	a4,a3,0x3
    80002ec4:	00005797          	auipc	a5,0x5
    80002ec8:	69c78793          	addi	a5,a5,1692 # 80008560 <syscalls>
    80002ecc:	97ba                	add	a5,a5,a4
    80002ece:	639c                	ld	a5,0(a5)
    80002ed0:	c789                	beqz	a5,80002eda <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    80002ed2:	9782                	jalr	a5
    80002ed4:	06a93823          	sd	a0,112(s2)
    80002ed8:	a839                	j	80002ef6 <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    80002eda:	15848613          	addi	a2,s1,344
    80002ede:	588c                	lw	a1,48(s1)
    80002ee0:	00005517          	auipc	a0,0x5
    80002ee4:	64850513          	addi	a0,a0,1608 # 80008528 <states.0+0x150>
    80002ee8:	ffffd097          	auipc	ra,0xffffd
    80002eec:	6b0080e7          	jalr	1712(ra) # 80000598 <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    80002ef0:	6cbc                	ld	a5,88(s1)
    80002ef2:	577d                	li	a4,-1
    80002ef4:	fbb8                	sd	a4,112(a5)
    }
}
    80002ef6:	60e2                	ld	ra,24(sp)
    80002ef8:	6442                	ld	s0,16(sp)
    80002efa:	64a2                	ld	s1,8(sp)
    80002efc:	6902                	ld	s2,0(sp)
    80002efe:	6105                	addi	sp,sp,32
    80002f00:	8082                	ret

0000000080002f02 <sys_exit>:

extern uint64 FREE_PAGES; // kalloc.c keeps track of those

uint64
sys_exit(void)
{
    80002f02:	1101                	addi	sp,sp,-32
    80002f04:	ec06                	sd	ra,24(sp)
    80002f06:	e822                	sd	s0,16(sp)
    80002f08:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    80002f0a:	fec40593          	addi	a1,s0,-20
    80002f0e:	4501                	li	a0,0
    80002f10:	00000097          	auipc	ra,0x0
    80002f14:	f0e080e7          	jalr	-242(ra) # 80002e1e <argint>
    exit(n);
    80002f18:	fec42503          	lw	a0,-20(s0)
    80002f1c:	fffff097          	auipc	ra,0xfffff
    80002f20:	4e2080e7          	jalr	1250(ra) # 800023fe <exit>
    return 0; // not reached
}
    80002f24:	4501                	li	a0,0
    80002f26:	60e2                	ld	ra,24(sp)
    80002f28:	6442                	ld	s0,16(sp)
    80002f2a:	6105                	addi	sp,sp,32
    80002f2c:	8082                	ret

0000000080002f2e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f2e:	1141                	addi	sp,sp,-16
    80002f30:	e406                	sd	ra,8(sp)
    80002f32:	e022                	sd	s0,0(sp)
    80002f34:	0800                	addi	s0,sp,16
    return myproc()->pid;
    80002f36:	fffff097          	auipc	ra,0xfffff
    80002f3a:	c2c080e7          	jalr	-980(ra) # 80001b62 <myproc>
}
    80002f3e:	5908                	lw	a0,48(a0)
    80002f40:	60a2                	ld	ra,8(sp)
    80002f42:	6402                	ld	s0,0(sp)
    80002f44:	0141                	addi	sp,sp,16
    80002f46:	8082                	ret

0000000080002f48 <sys_fork>:

uint64
sys_fork(void)
{
    80002f48:	1141                	addi	sp,sp,-16
    80002f4a:	e406                	sd	ra,8(sp)
    80002f4c:	e022                	sd	s0,0(sp)
    80002f4e:	0800                	addi	s0,sp,16
    return fork();
    80002f50:	fffff097          	auipc	ra,0xfffff
    80002f54:	118080e7          	jalr	280(ra) # 80002068 <fork>
}
    80002f58:	60a2                	ld	ra,8(sp)
    80002f5a:	6402                	ld	s0,0(sp)
    80002f5c:	0141                	addi	sp,sp,16
    80002f5e:	8082                	ret

0000000080002f60 <sys_wait>:

uint64
sys_wait(void)
{
    80002f60:	1101                	addi	sp,sp,-32
    80002f62:	ec06                	sd	ra,24(sp)
    80002f64:	e822                	sd	s0,16(sp)
    80002f66:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    80002f68:	fe840593          	addi	a1,s0,-24
    80002f6c:	4501                	li	a0,0
    80002f6e:	00000097          	auipc	ra,0x0
    80002f72:	ed0080e7          	jalr	-304(ra) # 80002e3e <argaddr>
    return wait(p);
    80002f76:	fe843503          	ld	a0,-24(s0)
    80002f7a:	fffff097          	auipc	ra,0xfffff
    80002f7e:	62a080e7          	jalr	1578(ra) # 800025a4 <wait>
}
    80002f82:	60e2                	ld	ra,24(sp)
    80002f84:	6442                	ld	s0,16(sp)
    80002f86:	6105                	addi	sp,sp,32
    80002f88:	8082                	ret

0000000080002f8a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f8a:	7179                	addi	sp,sp,-48
    80002f8c:	f406                	sd	ra,40(sp)
    80002f8e:	f022                	sd	s0,32(sp)
    80002f90:	ec26                	sd	s1,24(sp)
    80002f92:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    80002f94:	fdc40593          	addi	a1,s0,-36
    80002f98:	4501                	li	a0,0
    80002f9a:	00000097          	auipc	ra,0x0
    80002f9e:	e84080e7          	jalr	-380(ra) # 80002e1e <argint>
    addr = myproc()->sz;
    80002fa2:	fffff097          	auipc	ra,0xfffff
    80002fa6:	bc0080e7          	jalr	-1088(ra) # 80001b62 <myproc>
    80002faa:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    80002fac:	fdc42503          	lw	a0,-36(s0)
    80002fb0:	fffff097          	auipc	ra,0xfffff
    80002fb4:	f0c080e7          	jalr	-244(ra) # 80001ebc <growproc>
    80002fb8:	00054863          	bltz	a0,80002fc8 <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    80002fbc:	8526                	mv	a0,s1
    80002fbe:	70a2                	ld	ra,40(sp)
    80002fc0:	7402                	ld	s0,32(sp)
    80002fc2:	64e2                	ld	s1,24(sp)
    80002fc4:	6145                	addi	sp,sp,48
    80002fc6:	8082                	ret
        return -1;
    80002fc8:	54fd                	li	s1,-1
    80002fca:	bfcd                	j	80002fbc <sys_sbrk+0x32>

0000000080002fcc <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fcc:	7139                	addi	sp,sp,-64
    80002fce:	fc06                	sd	ra,56(sp)
    80002fd0:	f822                	sd	s0,48(sp)
    80002fd2:	f426                	sd	s1,40(sp)
    80002fd4:	f04a                	sd	s2,32(sp)
    80002fd6:	ec4e                	sd	s3,24(sp)
    80002fd8:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    80002fda:	fcc40593          	addi	a1,s0,-52
    80002fde:	4501                	li	a0,0
    80002fe0:	00000097          	auipc	ra,0x0
    80002fe4:	e3e080e7          	jalr	-450(ra) # 80002e1e <argint>
    acquire(&tickslock);
    80002fe8:	00014517          	auipc	a0,0x14
    80002fec:	b4850513          	addi	a0,a0,-1208 # 80016b30 <tickslock>
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	caa080e7          	jalr	-854(ra) # 80000c9a <acquire>
    ticks0 = ticks;
    80002ff8:	00006917          	auipc	s2,0x6
    80002ffc:	a9892903          	lw	s2,-1384(s2) # 80008a90 <ticks>
    while (ticks - ticks0 < n)
    80003000:	fcc42783          	lw	a5,-52(s0)
    80003004:	cf9d                	beqz	a5,80003042 <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    80003006:	00014997          	auipc	s3,0x14
    8000300a:	b2a98993          	addi	s3,s3,-1238 # 80016b30 <tickslock>
    8000300e:	00006497          	auipc	s1,0x6
    80003012:	a8248493          	addi	s1,s1,-1406 # 80008a90 <ticks>
        if (killed(myproc()))
    80003016:	fffff097          	auipc	ra,0xfffff
    8000301a:	b4c080e7          	jalr	-1204(ra) # 80001b62 <myproc>
    8000301e:	fffff097          	auipc	ra,0xfffff
    80003022:	554080e7          	jalr	1364(ra) # 80002572 <killed>
    80003026:	ed15                	bnez	a0,80003062 <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    80003028:	85ce                	mv	a1,s3
    8000302a:	8526                	mv	a0,s1
    8000302c:	fffff097          	auipc	ra,0xfffff
    80003030:	29e080e7          	jalr	670(ra) # 800022ca <sleep>
    while (ticks - ticks0 < n)
    80003034:	409c                	lw	a5,0(s1)
    80003036:	412787bb          	subw	a5,a5,s2
    8000303a:	fcc42703          	lw	a4,-52(s0)
    8000303e:	fce7ece3          	bltu	a5,a4,80003016 <sys_sleep+0x4a>
    }
    release(&tickslock);
    80003042:	00014517          	auipc	a0,0x14
    80003046:	aee50513          	addi	a0,a0,-1298 # 80016b30 <tickslock>
    8000304a:	ffffe097          	auipc	ra,0xffffe
    8000304e:	d04080e7          	jalr	-764(ra) # 80000d4e <release>
    return 0;
    80003052:	4501                	li	a0,0
}
    80003054:	70e2                	ld	ra,56(sp)
    80003056:	7442                	ld	s0,48(sp)
    80003058:	74a2                	ld	s1,40(sp)
    8000305a:	7902                	ld	s2,32(sp)
    8000305c:	69e2                	ld	s3,24(sp)
    8000305e:	6121                	addi	sp,sp,64
    80003060:	8082                	ret
            release(&tickslock);
    80003062:	00014517          	auipc	a0,0x14
    80003066:	ace50513          	addi	a0,a0,-1330 # 80016b30 <tickslock>
    8000306a:	ffffe097          	auipc	ra,0xffffe
    8000306e:	ce4080e7          	jalr	-796(ra) # 80000d4e <release>
            return -1;
    80003072:	557d                	li	a0,-1
    80003074:	b7c5                	j	80003054 <sys_sleep+0x88>

0000000080003076 <sys_kill>:

uint64
sys_kill(void)
{
    80003076:	1101                	addi	sp,sp,-32
    80003078:	ec06                	sd	ra,24(sp)
    8000307a:	e822                	sd	s0,16(sp)
    8000307c:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    8000307e:	fec40593          	addi	a1,s0,-20
    80003082:	4501                	li	a0,0
    80003084:	00000097          	auipc	ra,0x0
    80003088:	d9a080e7          	jalr	-614(ra) # 80002e1e <argint>
    return kill(pid);
    8000308c:	fec42503          	lw	a0,-20(s0)
    80003090:	fffff097          	auipc	ra,0xfffff
    80003094:	444080e7          	jalr	1092(ra) # 800024d4 <kill>
}
    80003098:	60e2                	ld	ra,24(sp)
    8000309a:	6442                	ld	s0,16(sp)
    8000309c:	6105                	addi	sp,sp,32
    8000309e:	8082                	ret

00000000800030a0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030a0:	1101                	addi	sp,sp,-32
    800030a2:	ec06                	sd	ra,24(sp)
    800030a4:	e822                	sd	s0,16(sp)
    800030a6:	e426                	sd	s1,8(sp)
    800030a8:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    800030aa:	00014517          	auipc	a0,0x14
    800030ae:	a8650513          	addi	a0,a0,-1402 # 80016b30 <tickslock>
    800030b2:	ffffe097          	auipc	ra,0xffffe
    800030b6:	be8080e7          	jalr	-1048(ra) # 80000c9a <acquire>
    xticks = ticks;
    800030ba:	00006497          	auipc	s1,0x6
    800030be:	9d64a483          	lw	s1,-1578(s1) # 80008a90 <ticks>
    release(&tickslock);
    800030c2:	00014517          	auipc	a0,0x14
    800030c6:	a6e50513          	addi	a0,a0,-1426 # 80016b30 <tickslock>
    800030ca:	ffffe097          	auipc	ra,0xffffe
    800030ce:	c84080e7          	jalr	-892(ra) # 80000d4e <release>
    return xticks;
}
    800030d2:	02049513          	slli	a0,s1,0x20
    800030d6:	9101                	srli	a0,a0,0x20
    800030d8:	60e2                	ld	ra,24(sp)
    800030da:	6442                	ld	s0,16(sp)
    800030dc:	64a2                	ld	s1,8(sp)
    800030de:	6105                	addi	sp,sp,32
    800030e0:	8082                	ret

00000000800030e2 <sys_ps>:

void *
sys_ps(void)
{
    800030e2:	1101                	addi	sp,sp,-32
    800030e4:	ec06                	sd	ra,24(sp)
    800030e6:	e822                	sd	s0,16(sp)
    800030e8:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    800030ea:	fe042623          	sw	zero,-20(s0)
    800030ee:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    800030f2:	fec40593          	addi	a1,s0,-20
    800030f6:	4501                	li	a0,0
    800030f8:	00000097          	auipc	ra,0x0
    800030fc:	d26080e7          	jalr	-730(ra) # 80002e1e <argint>
    argint(1, &count);
    80003100:	fe840593          	addi	a1,s0,-24
    80003104:	4505                	li	a0,1
    80003106:	00000097          	auipc	ra,0x0
    8000310a:	d18080e7          	jalr	-744(ra) # 80002e1e <argint>
    return ps((uint8)start, (uint8)count);
    8000310e:	fe844583          	lbu	a1,-24(s0)
    80003112:	fec44503          	lbu	a0,-20(s0)
    80003116:	fffff097          	auipc	ra,0xfffff
    8000311a:	e02080e7          	jalr	-510(ra) # 80001f18 <ps>
}
    8000311e:	60e2                	ld	ra,24(sp)
    80003120:	6442                	ld	s0,16(sp)
    80003122:	6105                	addi	sp,sp,32
    80003124:	8082                	ret

0000000080003126 <sys_schedls>:

uint64 sys_schedls(void)
{
    80003126:	1141                	addi	sp,sp,-16
    80003128:	e406                	sd	ra,8(sp)
    8000312a:	e022                	sd	s0,0(sp)
    8000312c:	0800                	addi	s0,sp,16
    schedls();
    8000312e:	fffff097          	auipc	ra,0xfffff
    80003132:	700080e7          	jalr	1792(ra) # 8000282e <schedls>
    return 0;
}
    80003136:	4501                	li	a0,0
    80003138:	60a2                	ld	ra,8(sp)
    8000313a:	6402                	ld	s0,0(sp)
    8000313c:	0141                	addi	sp,sp,16
    8000313e:	8082                	ret

0000000080003140 <sys_schedset>:

uint64 sys_schedset(void)
{
    80003140:	1101                	addi	sp,sp,-32
    80003142:	ec06                	sd	ra,24(sp)
    80003144:	e822                	sd	s0,16(sp)
    80003146:	1000                	addi	s0,sp,32
    int id = 0;
    80003148:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    8000314c:	fec40593          	addi	a1,s0,-20
    80003150:	4501                	li	a0,0
    80003152:	00000097          	auipc	ra,0x0
    80003156:	ccc080e7          	jalr	-820(ra) # 80002e1e <argint>
    schedset(id - 1);
    8000315a:	fec42503          	lw	a0,-20(s0)
    8000315e:	357d                	addiw	a0,a0,-1
    80003160:	fffff097          	auipc	ra,0xfffff
    80003164:	764080e7          	jalr	1892(ra) # 800028c4 <schedset>
    return 0;
}
    80003168:	4501                	li	a0,0
    8000316a:	60e2                	ld	ra,24(sp)
    8000316c:	6442                	ld	s0,16(sp)
    8000316e:	6105                	addi	sp,sp,32
    80003170:	8082                	ret

0000000080003172 <sys_va2pa>:

uint64 sys_va2pa(void)
{
    80003172:	1141                	addi	sp,sp,-16
    80003174:	e406                	sd	ra,8(sp)
    80003176:	e022                	sd	s0,0(sp)
    80003178:	0800                	addi	s0,sp,16
    printf("TODO: IMPLEMENT ME [%s@%s (line %d)]", __func__, __FILE__, __LINE__);
    8000317a:	07a00693          	li	a3,122
    8000317e:	00005617          	auipc	a2,0x5
    80003182:	4ba60613          	addi	a2,a2,1210 # 80008638 <syscalls+0xd8>
    80003186:	00005597          	auipc	a1,0x5
    8000318a:	4f258593          	addi	a1,a1,1266 # 80008678 <__func__.0>
    8000318e:	00005517          	auipc	a0,0x5
    80003192:	4c250513          	addi	a0,a0,1218 # 80008650 <syscalls+0xf0>
    80003196:	ffffd097          	auipc	ra,0xffffd
    8000319a:	402080e7          	jalr	1026(ra) # 80000598 <printf>
    return 0;
}
    8000319e:	4501                	li	a0,0
    800031a0:	60a2                	ld	ra,8(sp)
    800031a2:	6402                	ld	s0,0(sp)
    800031a4:	0141                	addi	sp,sp,16
    800031a6:	8082                	ret

00000000800031a8 <sys_pfreepages>:

uint64 sys_pfreepages(void)
{
    800031a8:	1141                	addi	sp,sp,-16
    800031aa:	e406                	sd	ra,8(sp)
    800031ac:	e022                	sd	s0,0(sp)
    800031ae:	0800                	addi	s0,sp,16
    printf("%d\n", FREE_PAGES);
    800031b0:	00006597          	auipc	a1,0x6
    800031b4:	8b85b583          	ld	a1,-1864(a1) # 80008a68 <FREE_PAGES>
    800031b8:	00005517          	auipc	a0,0x5
    800031bc:	38850513          	addi	a0,a0,904 # 80008540 <states.0+0x168>
    800031c0:	ffffd097          	auipc	ra,0xffffd
    800031c4:	3d8080e7          	jalr	984(ra) # 80000598 <printf>
    return 0;
    800031c8:	4501                	li	a0,0
    800031ca:	60a2                	ld	ra,8(sp)
    800031cc:	6402                	ld	s0,0(sp)
    800031ce:	0141                	addi	sp,sp,16
    800031d0:	8082                	ret

00000000800031d2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800031d2:	7179                	addi	sp,sp,-48
    800031d4:	f406                	sd	ra,40(sp)
    800031d6:	f022                	sd	s0,32(sp)
    800031d8:	ec26                	sd	s1,24(sp)
    800031da:	e84a                	sd	s2,16(sp)
    800031dc:	e44e                	sd	s3,8(sp)
    800031de:	e052                	sd	s4,0(sp)
    800031e0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800031e2:	00005597          	auipc	a1,0x5
    800031e6:	4a658593          	addi	a1,a1,1190 # 80008688 <__func__.0+0x10>
    800031ea:	00014517          	auipc	a0,0x14
    800031ee:	95e50513          	addi	a0,a0,-1698 # 80016b48 <bcache>
    800031f2:	ffffe097          	auipc	ra,0xffffe
    800031f6:	a18080e7          	jalr	-1512(ra) # 80000c0a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800031fa:	0001c797          	auipc	a5,0x1c
    800031fe:	94e78793          	addi	a5,a5,-1714 # 8001eb48 <bcache+0x8000>
    80003202:	0001c717          	auipc	a4,0x1c
    80003206:	bae70713          	addi	a4,a4,-1106 # 8001edb0 <bcache+0x8268>
    8000320a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000320e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003212:	00014497          	auipc	s1,0x14
    80003216:	94e48493          	addi	s1,s1,-1714 # 80016b60 <bcache+0x18>
    b->next = bcache.head.next;
    8000321a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000321c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000321e:	00005a17          	auipc	s4,0x5
    80003222:	472a0a13          	addi	s4,s4,1138 # 80008690 <__func__.0+0x18>
    b->next = bcache.head.next;
    80003226:	2b893783          	ld	a5,696(s2)
    8000322a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000322c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003230:	85d2                	mv	a1,s4
    80003232:	01048513          	addi	a0,s1,16
    80003236:	00001097          	auipc	ra,0x1
    8000323a:	496080e7          	jalr	1174(ra) # 800046cc <initsleeplock>
    bcache.head.next->prev = b;
    8000323e:	2b893783          	ld	a5,696(s2)
    80003242:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003244:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003248:	45848493          	addi	s1,s1,1112
    8000324c:	fd349de3          	bne	s1,s3,80003226 <binit+0x54>
  }
}
    80003250:	70a2                	ld	ra,40(sp)
    80003252:	7402                	ld	s0,32(sp)
    80003254:	64e2                	ld	s1,24(sp)
    80003256:	6942                	ld	s2,16(sp)
    80003258:	69a2                	ld	s3,8(sp)
    8000325a:	6a02                	ld	s4,0(sp)
    8000325c:	6145                	addi	sp,sp,48
    8000325e:	8082                	ret

0000000080003260 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003260:	7179                	addi	sp,sp,-48
    80003262:	f406                	sd	ra,40(sp)
    80003264:	f022                	sd	s0,32(sp)
    80003266:	ec26                	sd	s1,24(sp)
    80003268:	e84a                	sd	s2,16(sp)
    8000326a:	e44e                	sd	s3,8(sp)
    8000326c:	1800                	addi	s0,sp,48
    8000326e:	892a                	mv	s2,a0
    80003270:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003272:	00014517          	auipc	a0,0x14
    80003276:	8d650513          	addi	a0,a0,-1834 # 80016b48 <bcache>
    8000327a:	ffffe097          	auipc	ra,0xffffe
    8000327e:	a20080e7          	jalr	-1504(ra) # 80000c9a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003282:	0001c497          	auipc	s1,0x1c
    80003286:	b7e4b483          	ld	s1,-1154(s1) # 8001ee00 <bcache+0x82b8>
    8000328a:	0001c797          	auipc	a5,0x1c
    8000328e:	b2678793          	addi	a5,a5,-1242 # 8001edb0 <bcache+0x8268>
    80003292:	02f48f63          	beq	s1,a5,800032d0 <bread+0x70>
    80003296:	873e                	mv	a4,a5
    80003298:	a021                	j	800032a0 <bread+0x40>
    8000329a:	68a4                	ld	s1,80(s1)
    8000329c:	02e48a63          	beq	s1,a4,800032d0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800032a0:	449c                	lw	a5,8(s1)
    800032a2:	ff279ce3          	bne	a5,s2,8000329a <bread+0x3a>
    800032a6:	44dc                	lw	a5,12(s1)
    800032a8:	ff3799e3          	bne	a5,s3,8000329a <bread+0x3a>
      b->refcnt++;
    800032ac:	40bc                	lw	a5,64(s1)
    800032ae:	2785                	addiw	a5,a5,1
    800032b0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032b2:	00014517          	auipc	a0,0x14
    800032b6:	89650513          	addi	a0,a0,-1898 # 80016b48 <bcache>
    800032ba:	ffffe097          	auipc	ra,0xffffe
    800032be:	a94080e7          	jalr	-1388(ra) # 80000d4e <release>
      acquiresleep(&b->lock);
    800032c2:	01048513          	addi	a0,s1,16
    800032c6:	00001097          	auipc	ra,0x1
    800032ca:	440080e7          	jalr	1088(ra) # 80004706 <acquiresleep>
      return b;
    800032ce:	a8b9                	j	8000332c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032d0:	0001c497          	auipc	s1,0x1c
    800032d4:	b284b483          	ld	s1,-1240(s1) # 8001edf8 <bcache+0x82b0>
    800032d8:	0001c797          	auipc	a5,0x1c
    800032dc:	ad878793          	addi	a5,a5,-1320 # 8001edb0 <bcache+0x8268>
    800032e0:	00f48863          	beq	s1,a5,800032f0 <bread+0x90>
    800032e4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800032e6:	40bc                	lw	a5,64(s1)
    800032e8:	cf81                	beqz	a5,80003300 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032ea:	64a4                	ld	s1,72(s1)
    800032ec:	fee49de3          	bne	s1,a4,800032e6 <bread+0x86>
  panic("bget: no buffers");
    800032f0:	00005517          	auipc	a0,0x5
    800032f4:	3a850513          	addi	a0,a0,936 # 80008698 <__func__.0+0x20>
    800032f8:	ffffd097          	auipc	ra,0xffffd
    800032fc:	244080e7          	jalr	580(ra) # 8000053c <panic>
      b->dev = dev;
    80003300:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003304:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003308:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000330c:	4785                	li	a5,1
    8000330e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003310:	00014517          	auipc	a0,0x14
    80003314:	83850513          	addi	a0,a0,-1992 # 80016b48 <bcache>
    80003318:	ffffe097          	auipc	ra,0xffffe
    8000331c:	a36080e7          	jalr	-1482(ra) # 80000d4e <release>
      acquiresleep(&b->lock);
    80003320:	01048513          	addi	a0,s1,16
    80003324:	00001097          	auipc	ra,0x1
    80003328:	3e2080e7          	jalr	994(ra) # 80004706 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000332c:	409c                	lw	a5,0(s1)
    8000332e:	cb89                	beqz	a5,80003340 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003330:	8526                	mv	a0,s1
    80003332:	70a2                	ld	ra,40(sp)
    80003334:	7402                	ld	s0,32(sp)
    80003336:	64e2                	ld	s1,24(sp)
    80003338:	6942                	ld	s2,16(sp)
    8000333a:	69a2                	ld	s3,8(sp)
    8000333c:	6145                	addi	sp,sp,48
    8000333e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003340:	4581                	li	a1,0
    80003342:	8526                	mv	a0,s1
    80003344:	00003097          	auipc	ra,0x3
    80003348:	f7e080e7          	jalr	-130(ra) # 800062c2 <virtio_disk_rw>
    b->valid = 1;
    8000334c:	4785                	li	a5,1
    8000334e:	c09c                	sw	a5,0(s1)
  return b;
    80003350:	b7c5                	j	80003330 <bread+0xd0>

0000000080003352 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003352:	1101                	addi	sp,sp,-32
    80003354:	ec06                	sd	ra,24(sp)
    80003356:	e822                	sd	s0,16(sp)
    80003358:	e426                	sd	s1,8(sp)
    8000335a:	1000                	addi	s0,sp,32
    8000335c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000335e:	0541                	addi	a0,a0,16
    80003360:	00001097          	auipc	ra,0x1
    80003364:	440080e7          	jalr	1088(ra) # 800047a0 <holdingsleep>
    80003368:	cd01                	beqz	a0,80003380 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000336a:	4585                	li	a1,1
    8000336c:	8526                	mv	a0,s1
    8000336e:	00003097          	auipc	ra,0x3
    80003372:	f54080e7          	jalr	-172(ra) # 800062c2 <virtio_disk_rw>
}
    80003376:	60e2                	ld	ra,24(sp)
    80003378:	6442                	ld	s0,16(sp)
    8000337a:	64a2                	ld	s1,8(sp)
    8000337c:	6105                	addi	sp,sp,32
    8000337e:	8082                	ret
    panic("bwrite");
    80003380:	00005517          	auipc	a0,0x5
    80003384:	33050513          	addi	a0,a0,816 # 800086b0 <__func__.0+0x38>
    80003388:	ffffd097          	auipc	ra,0xffffd
    8000338c:	1b4080e7          	jalr	436(ra) # 8000053c <panic>

0000000080003390 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003390:	1101                	addi	sp,sp,-32
    80003392:	ec06                	sd	ra,24(sp)
    80003394:	e822                	sd	s0,16(sp)
    80003396:	e426                	sd	s1,8(sp)
    80003398:	e04a                	sd	s2,0(sp)
    8000339a:	1000                	addi	s0,sp,32
    8000339c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000339e:	01050913          	addi	s2,a0,16
    800033a2:	854a                	mv	a0,s2
    800033a4:	00001097          	auipc	ra,0x1
    800033a8:	3fc080e7          	jalr	1020(ra) # 800047a0 <holdingsleep>
    800033ac:	c925                	beqz	a0,8000341c <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800033ae:	854a                	mv	a0,s2
    800033b0:	00001097          	auipc	ra,0x1
    800033b4:	3ac080e7          	jalr	940(ra) # 8000475c <releasesleep>

  acquire(&bcache.lock);
    800033b8:	00013517          	auipc	a0,0x13
    800033bc:	79050513          	addi	a0,a0,1936 # 80016b48 <bcache>
    800033c0:	ffffe097          	auipc	ra,0xffffe
    800033c4:	8da080e7          	jalr	-1830(ra) # 80000c9a <acquire>
  b->refcnt--;
    800033c8:	40bc                	lw	a5,64(s1)
    800033ca:	37fd                	addiw	a5,a5,-1
    800033cc:	0007871b          	sext.w	a4,a5
    800033d0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800033d2:	e71d                	bnez	a4,80003400 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800033d4:	68b8                	ld	a4,80(s1)
    800033d6:	64bc                	ld	a5,72(s1)
    800033d8:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800033da:	68b8                	ld	a4,80(s1)
    800033dc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800033de:	0001b797          	auipc	a5,0x1b
    800033e2:	76a78793          	addi	a5,a5,1898 # 8001eb48 <bcache+0x8000>
    800033e6:	2b87b703          	ld	a4,696(a5)
    800033ea:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800033ec:	0001c717          	auipc	a4,0x1c
    800033f0:	9c470713          	addi	a4,a4,-1596 # 8001edb0 <bcache+0x8268>
    800033f4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800033f6:	2b87b703          	ld	a4,696(a5)
    800033fa:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800033fc:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003400:	00013517          	auipc	a0,0x13
    80003404:	74850513          	addi	a0,a0,1864 # 80016b48 <bcache>
    80003408:	ffffe097          	auipc	ra,0xffffe
    8000340c:	946080e7          	jalr	-1722(ra) # 80000d4e <release>
}
    80003410:	60e2                	ld	ra,24(sp)
    80003412:	6442                	ld	s0,16(sp)
    80003414:	64a2                	ld	s1,8(sp)
    80003416:	6902                	ld	s2,0(sp)
    80003418:	6105                	addi	sp,sp,32
    8000341a:	8082                	ret
    panic("brelse");
    8000341c:	00005517          	auipc	a0,0x5
    80003420:	29c50513          	addi	a0,a0,668 # 800086b8 <__func__.0+0x40>
    80003424:	ffffd097          	auipc	ra,0xffffd
    80003428:	118080e7          	jalr	280(ra) # 8000053c <panic>

000000008000342c <bpin>:

void
bpin(struct buf *b) {
    8000342c:	1101                	addi	sp,sp,-32
    8000342e:	ec06                	sd	ra,24(sp)
    80003430:	e822                	sd	s0,16(sp)
    80003432:	e426                	sd	s1,8(sp)
    80003434:	1000                	addi	s0,sp,32
    80003436:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003438:	00013517          	auipc	a0,0x13
    8000343c:	71050513          	addi	a0,a0,1808 # 80016b48 <bcache>
    80003440:	ffffe097          	auipc	ra,0xffffe
    80003444:	85a080e7          	jalr	-1958(ra) # 80000c9a <acquire>
  b->refcnt++;
    80003448:	40bc                	lw	a5,64(s1)
    8000344a:	2785                	addiw	a5,a5,1
    8000344c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000344e:	00013517          	auipc	a0,0x13
    80003452:	6fa50513          	addi	a0,a0,1786 # 80016b48 <bcache>
    80003456:	ffffe097          	auipc	ra,0xffffe
    8000345a:	8f8080e7          	jalr	-1800(ra) # 80000d4e <release>
}
    8000345e:	60e2                	ld	ra,24(sp)
    80003460:	6442                	ld	s0,16(sp)
    80003462:	64a2                	ld	s1,8(sp)
    80003464:	6105                	addi	sp,sp,32
    80003466:	8082                	ret

0000000080003468 <bunpin>:

void
bunpin(struct buf *b) {
    80003468:	1101                	addi	sp,sp,-32
    8000346a:	ec06                	sd	ra,24(sp)
    8000346c:	e822                	sd	s0,16(sp)
    8000346e:	e426                	sd	s1,8(sp)
    80003470:	1000                	addi	s0,sp,32
    80003472:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003474:	00013517          	auipc	a0,0x13
    80003478:	6d450513          	addi	a0,a0,1748 # 80016b48 <bcache>
    8000347c:	ffffe097          	auipc	ra,0xffffe
    80003480:	81e080e7          	jalr	-2018(ra) # 80000c9a <acquire>
  b->refcnt--;
    80003484:	40bc                	lw	a5,64(s1)
    80003486:	37fd                	addiw	a5,a5,-1
    80003488:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000348a:	00013517          	auipc	a0,0x13
    8000348e:	6be50513          	addi	a0,a0,1726 # 80016b48 <bcache>
    80003492:	ffffe097          	auipc	ra,0xffffe
    80003496:	8bc080e7          	jalr	-1860(ra) # 80000d4e <release>
}
    8000349a:	60e2                	ld	ra,24(sp)
    8000349c:	6442                	ld	s0,16(sp)
    8000349e:	64a2                	ld	s1,8(sp)
    800034a0:	6105                	addi	sp,sp,32
    800034a2:	8082                	ret

00000000800034a4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800034a4:	1101                	addi	sp,sp,-32
    800034a6:	ec06                	sd	ra,24(sp)
    800034a8:	e822                	sd	s0,16(sp)
    800034aa:	e426                	sd	s1,8(sp)
    800034ac:	e04a                	sd	s2,0(sp)
    800034ae:	1000                	addi	s0,sp,32
    800034b0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800034b2:	00d5d59b          	srliw	a1,a1,0xd
    800034b6:	0001c797          	auipc	a5,0x1c
    800034ba:	d6e7a783          	lw	a5,-658(a5) # 8001f224 <sb+0x1c>
    800034be:	9dbd                	addw	a1,a1,a5
    800034c0:	00000097          	auipc	ra,0x0
    800034c4:	da0080e7          	jalr	-608(ra) # 80003260 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800034c8:	0074f713          	andi	a4,s1,7
    800034cc:	4785                	li	a5,1
    800034ce:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800034d2:	14ce                	slli	s1,s1,0x33
    800034d4:	90d9                	srli	s1,s1,0x36
    800034d6:	00950733          	add	a4,a0,s1
    800034da:	05874703          	lbu	a4,88(a4)
    800034de:	00e7f6b3          	and	a3,a5,a4
    800034e2:	c69d                	beqz	a3,80003510 <bfree+0x6c>
    800034e4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800034e6:	94aa                	add	s1,s1,a0
    800034e8:	fff7c793          	not	a5,a5
    800034ec:	8f7d                	and	a4,a4,a5
    800034ee:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800034f2:	00001097          	auipc	ra,0x1
    800034f6:	0f6080e7          	jalr	246(ra) # 800045e8 <log_write>
  brelse(bp);
    800034fa:	854a                	mv	a0,s2
    800034fc:	00000097          	auipc	ra,0x0
    80003500:	e94080e7          	jalr	-364(ra) # 80003390 <brelse>
}
    80003504:	60e2                	ld	ra,24(sp)
    80003506:	6442                	ld	s0,16(sp)
    80003508:	64a2                	ld	s1,8(sp)
    8000350a:	6902                	ld	s2,0(sp)
    8000350c:	6105                	addi	sp,sp,32
    8000350e:	8082                	ret
    panic("freeing free block");
    80003510:	00005517          	auipc	a0,0x5
    80003514:	1b050513          	addi	a0,a0,432 # 800086c0 <__func__.0+0x48>
    80003518:	ffffd097          	auipc	ra,0xffffd
    8000351c:	024080e7          	jalr	36(ra) # 8000053c <panic>

0000000080003520 <balloc>:
{
    80003520:	711d                	addi	sp,sp,-96
    80003522:	ec86                	sd	ra,88(sp)
    80003524:	e8a2                	sd	s0,80(sp)
    80003526:	e4a6                	sd	s1,72(sp)
    80003528:	e0ca                	sd	s2,64(sp)
    8000352a:	fc4e                	sd	s3,56(sp)
    8000352c:	f852                	sd	s4,48(sp)
    8000352e:	f456                	sd	s5,40(sp)
    80003530:	f05a                	sd	s6,32(sp)
    80003532:	ec5e                	sd	s7,24(sp)
    80003534:	e862                	sd	s8,16(sp)
    80003536:	e466                	sd	s9,8(sp)
    80003538:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000353a:	0001c797          	auipc	a5,0x1c
    8000353e:	cd27a783          	lw	a5,-814(a5) # 8001f20c <sb+0x4>
    80003542:	cff5                	beqz	a5,8000363e <balloc+0x11e>
    80003544:	8baa                	mv	s7,a0
    80003546:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003548:	0001cb17          	auipc	s6,0x1c
    8000354c:	cc0b0b13          	addi	s6,s6,-832 # 8001f208 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003550:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003552:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003554:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003556:	6c89                	lui	s9,0x2
    80003558:	a061                	j	800035e0 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000355a:	97ca                	add	a5,a5,s2
    8000355c:	8e55                	or	a2,a2,a3
    8000355e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003562:	854a                	mv	a0,s2
    80003564:	00001097          	auipc	ra,0x1
    80003568:	084080e7          	jalr	132(ra) # 800045e8 <log_write>
        brelse(bp);
    8000356c:	854a                	mv	a0,s2
    8000356e:	00000097          	auipc	ra,0x0
    80003572:	e22080e7          	jalr	-478(ra) # 80003390 <brelse>
  bp = bread(dev, bno);
    80003576:	85a6                	mv	a1,s1
    80003578:	855e                	mv	a0,s7
    8000357a:	00000097          	auipc	ra,0x0
    8000357e:	ce6080e7          	jalr	-794(ra) # 80003260 <bread>
    80003582:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003584:	40000613          	li	a2,1024
    80003588:	4581                	li	a1,0
    8000358a:	05850513          	addi	a0,a0,88
    8000358e:	ffffe097          	auipc	ra,0xffffe
    80003592:	808080e7          	jalr	-2040(ra) # 80000d96 <memset>
  log_write(bp);
    80003596:	854a                	mv	a0,s2
    80003598:	00001097          	auipc	ra,0x1
    8000359c:	050080e7          	jalr	80(ra) # 800045e8 <log_write>
  brelse(bp);
    800035a0:	854a                	mv	a0,s2
    800035a2:	00000097          	auipc	ra,0x0
    800035a6:	dee080e7          	jalr	-530(ra) # 80003390 <brelse>
}
    800035aa:	8526                	mv	a0,s1
    800035ac:	60e6                	ld	ra,88(sp)
    800035ae:	6446                	ld	s0,80(sp)
    800035b0:	64a6                	ld	s1,72(sp)
    800035b2:	6906                	ld	s2,64(sp)
    800035b4:	79e2                	ld	s3,56(sp)
    800035b6:	7a42                	ld	s4,48(sp)
    800035b8:	7aa2                	ld	s5,40(sp)
    800035ba:	7b02                	ld	s6,32(sp)
    800035bc:	6be2                	ld	s7,24(sp)
    800035be:	6c42                	ld	s8,16(sp)
    800035c0:	6ca2                	ld	s9,8(sp)
    800035c2:	6125                	addi	sp,sp,96
    800035c4:	8082                	ret
    brelse(bp);
    800035c6:	854a                	mv	a0,s2
    800035c8:	00000097          	auipc	ra,0x0
    800035cc:	dc8080e7          	jalr	-568(ra) # 80003390 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800035d0:	015c87bb          	addw	a5,s9,s5
    800035d4:	00078a9b          	sext.w	s5,a5
    800035d8:	004b2703          	lw	a4,4(s6)
    800035dc:	06eaf163          	bgeu	s5,a4,8000363e <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800035e0:	41fad79b          	sraiw	a5,s5,0x1f
    800035e4:	0137d79b          	srliw	a5,a5,0x13
    800035e8:	015787bb          	addw	a5,a5,s5
    800035ec:	40d7d79b          	sraiw	a5,a5,0xd
    800035f0:	01cb2583          	lw	a1,28(s6)
    800035f4:	9dbd                	addw	a1,a1,a5
    800035f6:	855e                	mv	a0,s7
    800035f8:	00000097          	auipc	ra,0x0
    800035fc:	c68080e7          	jalr	-920(ra) # 80003260 <bread>
    80003600:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003602:	004b2503          	lw	a0,4(s6)
    80003606:	000a849b          	sext.w	s1,s5
    8000360a:	8762                	mv	a4,s8
    8000360c:	faa4fde3          	bgeu	s1,a0,800035c6 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003610:	00777693          	andi	a3,a4,7
    80003614:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003618:	41f7579b          	sraiw	a5,a4,0x1f
    8000361c:	01d7d79b          	srliw	a5,a5,0x1d
    80003620:	9fb9                	addw	a5,a5,a4
    80003622:	4037d79b          	sraiw	a5,a5,0x3
    80003626:	00f90633          	add	a2,s2,a5
    8000362a:	05864603          	lbu	a2,88(a2)
    8000362e:	00c6f5b3          	and	a1,a3,a2
    80003632:	d585                	beqz	a1,8000355a <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003634:	2705                	addiw	a4,a4,1
    80003636:	2485                	addiw	s1,s1,1
    80003638:	fd471ae3          	bne	a4,s4,8000360c <balloc+0xec>
    8000363c:	b769                	j	800035c6 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000363e:	00005517          	auipc	a0,0x5
    80003642:	09a50513          	addi	a0,a0,154 # 800086d8 <__func__.0+0x60>
    80003646:	ffffd097          	auipc	ra,0xffffd
    8000364a:	f52080e7          	jalr	-174(ra) # 80000598 <printf>
  return 0;
    8000364e:	4481                	li	s1,0
    80003650:	bfa9                	j	800035aa <balloc+0x8a>

0000000080003652 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003652:	7179                	addi	sp,sp,-48
    80003654:	f406                	sd	ra,40(sp)
    80003656:	f022                	sd	s0,32(sp)
    80003658:	ec26                	sd	s1,24(sp)
    8000365a:	e84a                	sd	s2,16(sp)
    8000365c:	e44e                	sd	s3,8(sp)
    8000365e:	e052                	sd	s4,0(sp)
    80003660:	1800                	addi	s0,sp,48
    80003662:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003664:	47ad                	li	a5,11
    80003666:	02b7e863          	bltu	a5,a1,80003696 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000366a:	02059793          	slli	a5,a1,0x20
    8000366e:	01e7d593          	srli	a1,a5,0x1e
    80003672:	00b504b3          	add	s1,a0,a1
    80003676:	0504a903          	lw	s2,80(s1)
    8000367a:	06091e63          	bnez	s2,800036f6 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000367e:	4108                	lw	a0,0(a0)
    80003680:	00000097          	auipc	ra,0x0
    80003684:	ea0080e7          	jalr	-352(ra) # 80003520 <balloc>
    80003688:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000368c:	06090563          	beqz	s2,800036f6 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003690:	0524a823          	sw	s2,80(s1)
    80003694:	a08d                	j	800036f6 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003696:	ff45849b          	addiw	s1,a1,-12
    8000369a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000369e:	0ff00793          	li	a5,255
    800036a2:	08e7e563          	bltu	a5,a4,8000372c <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800036a6:	08052903          	lw	s2,128(a0)
    800036aa:	00091d63          	bnez	s2,800036c4 <bmap+0x72>
      addr = balloc(ip->dev);
    800036ae:	4108                	lw	a0,0(a0)
    800036b0:	00000097          	auipc	ra,0x0
    800036b4:	e70080e7          	jalr	-400(ra) # 80003520 <balloc>
    800036b8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800036bc:	02090d63          	beqz	s2,800036f6 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800036c0:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800036c4:	85ca                	mv	a1,s2
    800036c6:	0009a503          	lw	a0,0(s3)
    800036ca:	00000097          	auipc	ra,0x0
    800036ce:	b96080e7          	jalr	-1130(ra) # 80003260 <bread>
    800036d2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800036d4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800036d8:	02049713          	slli	a4,s1,0x20
    800036dc:	01e75593          	srli	a1,a4,0x1e
    800036e0:	00b784b3          	add	s1,a5,a1
    800036e4:	0004a903          	lw	s2,0(s1)
    800036e8:	02090063          	beqz	s2,80003708 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800036ec:	8552                	mv	a0,s4
    800036ee:	00000097          	auipc	ra,0x0
    800036f2:	ca2080e7          	jalr	-862(ra) # 80003390 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800036f6:	854a                	mv	a0,s2
    800036f8:	70a2                	ld	ra,40(sp)
    800036fa:	7402                	ld	s0,32(sp)
    800036fc:	64e2                	ld	s1,24(sp)
    800036fe:	6942                	ld	s2,16(sp)
    80003700:	69a2                	ld	s3,8(sp)
    80003702:	6a02                	ld	s4,0(sp)
    80003704:	6145                	addi	sp,sp,48
    80003706:	8082                	ret
      addr = balloc(ip->dev);
    80003708:	0009a503          	lw	a0,0(s3)
    8000370c:	00000097          	auipc	ra,0x0
    80003710:	e14080e7          	jalr	-492(ra) # 80003520 <balloc>
    80003714:	0005091b          	sext.w	s2,a0
      if(addr){
    80003718:	fc090ae3          	beqz	s2,800036ec <bmap+0x9a>
        a[bn] = addr;
    8000371c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003720:	8552                	mv	a0,s4
    80003722:	00001097          	auipc	ra,0x1
    80003726:	ec6080e7          	jalr	-314(ra) # 800045e8 <log_write>
    8000372a:	b7c9                	j	800036ec <bmap+0x9a>
  panic("bmap: out of range");
    8000372c:	00005517          	auipc	a0,0x5
    80003730:	fc450513          	addi	a0,a0,-60 # 800086f0 <__func__.0+0x78>
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	e08080e7          	jalr	-504(ra) # 8000053c <panic>

000000008000373c <iget>:
{
    8000373c:	7179                	addi	sp,sp,-48
    8000373e:	f406                	sd	ra,40(sp)
    80003740:	f022                	sd	s0,32(sp)
    80003742:	ec26                	sd	s1,24(sp)
    80003744:	e84a                	sd	s2,16(sp)
    80003746:	e44e                	sd	s3,8(sp)
    80003748:	e052                	sd	s4,0(sp)
    8000374a:	1800                	addi	s0,sp,48
    8000374c:	89aa                	mv	s3,a0
    8000374e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003750:	0001c517          	auipc	a0,0x1c
    80003754:	ad850513          	addi	a0,a0,-1320 # 8001f228 <itable>
    80003758:	ffffd097          	auipc	ra,0xffffd
    8000375c:	542080e7          	jalr	1346(ra) # 80000c9a <acquire>
  empty = 0;
    80003760:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003762:	0001c497          	auipc	s1,0x1c
    80003766:	ade48493          	addi	s1,s1,-1314 # 8001f240 <itable+0x18>
    8000376a:	0001d697          	auipc	a3,0x1d
    8000376e:	56668693          	addi	a3,a3,1382 # 80020cd0 <log>
    80003772:	a039                	j	80003780 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003774:	02090b63          	beqz	s2,800037aa <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003778:	08848493          	addi	s1,s1,136
    8000377c:	02d48a63          	beq	s1,a3,800037b0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003780:	449c                	lw	a5,8(s1)
    80003782:	fef059e3          	blez	a5,80003774 <iget+0x38>
    80003786:	4098                	lw	a4,0(s1)
    80003788:	ff3716e3          	bne	a4,s3,80003774 <iget+0x38>
    8000378c:	40d8                	lw	a4,4(s1)
    8000378e:	ff4713e3          	bne	a4,s4,80003774 <iget+0x38>
      ip->ref++;
    80003792:	2785                	addiw	a5,a5,1
    80003794:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003796:	0001c517          	auipc	a0,0x1c
    8000379a:	a9250513          	addi	a0,a0,-1390 # 8001f228 <itable>
    8000379e:	ffffd097          	auipc	ra,0xffffd
    800037a2:	5b0080e7          	jalr	1456(ra) # 80000d4e <release>
      return ip;
    800037a6:	8926                	mv	s2,s1
    800037a8:	a03d                	j	800037d6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037aa:	f7f9                	bnez	a5,80003778 <iget+0x3c>
    800037ac:	8926                	mv	s2,s1
    800037ae:	b7e9                	j	80003778 <iget+0x3c>
  if(empty == 0)
    800037b0:	02090c63          	beqz	s2,800037e8 <iget+0xac>
  ip->dev = dev;
    800037b4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800037b8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800037bc:	4785                	li	a5,1
    800037be:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800037c2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800037c6:	0001c517          	auipc	a0,0x1c
    800037ca:	a6250513          	addi	a0,a0,-1438 # 8001f228 <itable>
    800037ce:	ffffd097          	auipc	ra,0xffffd
    800037d2:	580080e7          	jalr	1408(ra) # 80000d4e <release>
}
    800037d6:	854a                	mv	a0,s2
    800037d8:	70a2                	ld	ra,40(sp)
    800037da:	7402                	ld	s0,32(sp)
    800037dc:	64e2                	ld	s1,24(sp)
    800037de:	6942                	ld	s2,16(sp)
    800037e0:	69a2                	ld	s3,8(sp)
    800037e2:	6a02                	ld	s4,0(sp)
    800037e4:	6145                	addi	sp,sp,48
    800037e6:	8082                	ret
    panic("iget: no inodes");
    800037e8:	00005517          	auipc	a0,0x5
    800037ec:	f2050513          	addi	a0,a0,-224 # 80008708 <__func__.0+0x90>
    800037f0:	ffffd097          	auipc	ra,0xffffd
    800037f4:	d4c080e7          	jalr	-692(ra) # 8000053c <panic>

00000000800037f8 <fsinit>:
fsinit(int dev) {
    800037f8:	7179                	addi	sp,sp,-48
    800037fa:	f406                	sd	ra,40(sp)
    800037fc:	f022                	sd	s0,32(sp)
    800037fe:	ec26                	sd	s1,24(sp)
    80003800:	e84a                	sd	s2,16(sp)
    80003802:	e44e                	sd	s3,8(sp)
    80003804:	1800                	addi	s0,sp,48
    80003806:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003808:	4585                	li	a1,1
    8000380a:	00000097          	auipc	ra,0x0
    8000380e:	a56080e7          	jalr	-1450(ra) # 80003260 <bread>
    80003812:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003814:	0001c997          	auipc	s3,0x1c
    80003818:	9f498993          	addi	s3,s3,-1548 # 8001f208 <sb>
    8000381c:	02000613          	li	a2,32
    80003820:	05850593          	addi	a1,a0,88
    80003824:	854e                	mv	a0,s3
    80003826:	ffffd097          	auipc	ra,0xffffd
    8000382a:	5cc080e7          	jalr	1484(ra) # 80000df2 <memmove>
  brelse(bp);
    8000382e:	8526                	mv	a0,s1
    80003830:	00000097          	auipc	ra,0x0
    80003834:	b60080e7          	jalr	-1184(ra) # 80003390 <brelse>
  if(sb.magic != FSMAGIC)
    80003838:	0009a703          	lw	a4,0(s3)
    8000383c:	102037b7          	lui	a5,0x10203
    80003840:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003844:	02f71263          	bne	a4,a5,80003868 <fsinit+0x70>
  initlog(dev, &sb);
    80003848:	0001c597          	auipc	a1,0x1c
    8000384c:	9c058593          	addi	a1,a1,-1600 # 8001f208 <sb>
    80003850:	854a                	mv	a0,s2
    80003852:	00001097          	auipc	ra,0x1
    80003856:	b2c080e7          	jalr	-1236(ra) # 8000437e <initlog>
}
    8000385a:	70a2                	ld	ra,40(sp)
    8000385c:	7402                	ld	s0,32(sp)
    8000385e:	64e2                	ld	s1,24(sp)
    80003860:	6942                	ld	s2,16(sp)
    80003862:	69a2                	ld	s3,8(sp)
    80003864:	6145                	addi	sp,sp,48
    80003866:	8082                	ret
    panic("invalid file system");
    80003868:	00005517          	auipc	a0,0x5
    8000386c:	eb050513          	addi	a0,a0,-336 # 80008718 <__func__.0+0xa0>
    80003870:	ffffd097          	auipc	ra,0xffffd
    80003874:	ccc080e7          	jalr	-820(ra) # 8000053c <panic>

0000000080003878 <iinit>:
{
    80003878:	7179                	addi	sp,sp,-48
    8000387a:	f406                	sd	ra,40(sp)
    8000387c:	f022                	sd	s0,32(sp)
    8000387e:	ec26                	sd	s1,24(sp)
    80003880:	e84a                	sd	s2,16(sp)
    80003882:	e44e                	sd	s3,8(sp)
    80003884:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003886:	00005597          	auipc	a1,0x5
    8000388a:	eaa58593          	addi	a1,a1,-342 # 80008730 <__func__.0+0xb8>
    8000388e:	0001c517          	auipc	a0,0x1c
    80003892:	99a50513          	addi	a0,a0,-1638 # 8001f228 <itable>
    80003896:	ffffd097          	auipc	ra,0xffffd
    8000389a:	374080e7          	jalr	884(ra) # 80000c0a <initlock>
  for(i = 0; i < NINODE; i++) {
    8000389e:	0001c497          	auipc	s1,0x1c
    800038a2:	9b248493          	addi	s1,s1,-1614 # 8001f250 <itable+0x28>
    800038a6:	0001d997          	auipc	s3,0x1d
    800038aa:	43a98993          	addi	s3,s3,1082 # 80020ce0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800038ae:	00005917          	auipc	s2,0x5
    800038b2:	e8a90913          	addi	s2,s2,-374 # 80008738 <__func__.0+0xc0>
    800038b6:	85ca                	mv	a1,s2
    800038b8:	8526                	mv	a0,s1
    800038ba:	00001097          	auipc	ra,0x1
    800038be:	e12080e7          	jalr	-494(ra) # 800046cc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800038c2:	08848493          	addi	s1,s1,136
    800038c6:	ff3498e3          	bne	s1,s3,800038b6 <iinit+0x3e>
}
    800038ca:	70a2                	ld	ra,40(sp)
    800038cc:	7402                	ld	s0,32(sp)
    800038ce:	64e2                	ld	s1,24(sp)
    800038d0:	6942                	ld	s2,16(sp)
    800038d2:	69a2                	ld	s3,8(sp)
    800038d4:	6145                	addi	sp,sp,48
    800038d6:	8082                	ret

00000000800038d8 <ialloc>:
{
    800038d8:	7139                	addi	sp,sp,-64
    800038da:	fc06                	sd	ra,56(sp)
    800038dc:	f822                	sd	s0,48(sp)
    800038de:	f426                	sd	s1,40(sp)
    800038e0:	f04a                	sd	s2,32(sp)
    800038e2:	ec4e                	sd	s3,24(sp)
    800038e4:	e852                	sd	s4,16(sp)
    800038e6:	e456                	sd	s5,8(sp)
    800038e8:	e05a                	sd	s6,0(sp)
    800038ea:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800038ec:	0001c717          	auipc	a4,0x1c
    800038f0:	92872703          	lw	a4,-1752(a4) # 8001f214 <sb+0xc>
    800038f4:	4785                	li	a5,1
    800038f6:	04e7f863          	bgeu	a5,a4,80003946 <ialloc+0x6e>
    800038fa:	8aaa                	mv	s5,a0
    800038fc:	8b2e                	mv	s6,a1
    800038fe:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003900:	0001ca17          	auipc	s4,0x1c
    80003904:	908a0a13          	addi	s4,s4,-1784 # 8001f208 <sb>
    80003908:	00495593          	srli	a1,s2,0x4
    8000390c:	018a2783          	lw	a5,24(s4)
    80003910:	9dbd                	addw	a1,a1,a5
    80003912:	8556                	mv	a0,s5
    80003914:	00000097          	auipc	ra,0x0
    80003918:	94c080e7          	jalr	-1716(ra) # 80003260 <bread>
    8000391c:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000391e:	05850993          	addi	s3,a0,88
    80003922:	00f97793          	andi	a5,s2,15
    80003926:	079a                	slli	a5,a5,0x6
    80003928:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000392a:	00099783          	lh	a5,0(s3)
    8000392e:	cf9d                	beqz	a5,8000396c <ialloc+0x94>
    brelse(bp);
    80003930:	00000097          	auipc	ra,0x0
    80003934:	a60080e7          	jalr	-1440(ra) # 80003390 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003938:	0905                	addi	s2,s2,1
    8000393a:	00ca2703          	lw	a4,12(s4)
    8000393e:	0009079b          	sext.w	a5,s2
    80003942:	fce7e3e3          	bltu	a5,a4,80003908 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003946:	00005517          	auipc	a0,0x5
    8000394a:	dfa50513          	addi	a0,a0,-518 # 80008740 <__func__.0+0xc8>
    8000394e:	ffffd097          	auipc	ra,0xffffd
    80003952:	c4a080e7          	jalr	-950(ra) # 80000598 <printf>
  return 0;
    80003956:	4501                	li	a0,0
}
    80003958:	70e2                	ld	ra,56(sp)
    8000395a:	7442                	ld	s0,48(sp)
    8000395c:	74a2                	ld	s1,40(sp)
    8000395e:	7902                	ld	s2,32(sp)
    80003960:	69e2                	ld	s3,24(sp)
    80003962:	6a42                	ld	s4,16(sp)
    80003964:	6aa2                	ld	s5,8(sp)
    80003966:	6b02                	ld	s6,0(sp)
    80003968:	6121                	addi	sp,sp,64
    8000396a:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000396c:	04000613          	li	a2,64
    80003970:	4581                	li	a1,0
    80003972:	854e                	mv	a0,s3
    80003974:	ffffd097          	auipc	ra,0xffffd
    80003978:	422080e7          	jalr	1058(ra) # 80000d96 <memset>
      dip->type = type;
    8000397c:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003980:	8526                	mv	a0,s1
    80003982:	00001097          	auipc	ra,0x1
    80003986:	c66080e7          	jalr	-922(ra) # 800045e8 <log_write>
      brelse(bp);
    8000398a:	8526                	mv	a0,s1
    8000398c:	00000097          	auipc	ra,0x0
    80003990:	a04080e7          	jalr	-1532(ra) # 80003390 <brelse>
      return iget(dev, inum);
    80003994:	0009059b          	sext.w	a1,s2
    80003998:	8556                	mv	a0,s5
    8000399a:	00000097          	auipc	ra,0x0
    8000399e:	da2080e7          	jalr	-606(ra) # 8000373c <iget>
    800039a2:	bf5d                	j	80003958 <ialloc+0x80>

00000000800039a4 <iupdate>:
{
    800039a4:	1101                	addi	sp,sp,-32
    800039a6:	ec06                	sd	ra,24(sp)
    800039a8:	e822                	sd	s0,16(sp)
    800039aa:	e426                	sd	s1,8(sp)
    800039ac:	e04a                	sd	s2,0(sp)
    800039ae:	1000                	addi	s0,sp,32
    800039b0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039b2:	415c                	lw	a5,4(a0)
    800039b4:	0047d79b          	srliw	a5,a5,0x4
    800039b8:	0001c597          	auipc	a1,0x1c
    800039bc:	8685a583          	lw	a1,-1944(a1) # 8001f220 <sb+0x18>
    800039c0:	9dbd                	addw	a1,a1,a5
    800039c2:	4108                	lw	a0,0(a0)
    800039c4:	00000097          	auipc	ra,0x0
    800039c8:	89c080e7          	jalr	-1892(ra) # 80003260 <bread>
    800039cc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039ce:	05850793          	addi	a5,a0,88
    800039d2:	40d8                	lw	a4,4(s1)
    800039d4:	8b3d                	andi	a4,a4,15
    800039d6:	071a                	slli	a4,a4,0x6
    800039d8:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800039da:	04449703          	lh	a4,68(s1)
    800039de:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800039e2:	04649703          	lh	a4,70(s1)
    800039e6:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800039ea:	04849703          	lh	a4,72(s1)
    800039ee:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800039f2:	04a49703          	lh	a4,74(s1)
    800039f6:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800039fa:	44f8                	lw	a4,76(s1)
    800039fc:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800039fe:	03400613          	li	a2,52
    80003a02:	05048593          	addi	a1,s1,80
    80003a06:	00c78513          	addi	a0,a5,12
    80003a0a:	ffffd097          	auipc	ra,0xffffd
    80003a0e:	3e8080e7          	jalr	1000(ra) # 80000df2 <memmove>
  log_write(bp);
    80003a12:	854a                	mv	a0,s2
    80003a14:	00001097          	auipc	ra,0x1
    80003a18:	bd4080e7          	jalr	-1068(ra) # 800045e8 <log_write>
  brelse(bp);
    80003a1c:	854a                	mv	a0,s2
    80003a1e:	00000097          	auipc	ra,0x0
    80003a22:	972080e7          	jalr	-1678(ra) # 80003390 <brelse>
}
    80003a26:	60e2                	ld	ra,24(sp)
    80003a28:	6442                	ld	s0,16(sp)
    80003a2a:	64a2                	ld	s1,8(sp)
    80003a2c:	6902                	ld	s2,0(sp)
    80003a2e:	6105                	addi	sp,sp,32
    80003a30:	8082                	ret

0000000080003a32 <idup>:
{
    80003a32:	1101                	addi	sp,sp,-32
    80003a34:	ec06                	sd	ra,24(sp)
    80003a36:	e822                	sd	s0,16(sp)
    80003a38:	e426                	sd	s1,8(sp)
    80003a3a:	1000                	addi	s0,sp,32
    80003a3c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a3e:	0001b517          	auipc	a0,0x1b
    80003a42:	7ea50513          	addi	a0,a0,2026 # 8001f228 <itable>
    80003a46:	ffffd097          	auipc	ra,0xffffd
    80003a4a:	254080e7          	jalr	596(ra) # 80000c9a <acquire>
  ip->ref++;
    80003a4e:	449c                	lw	a5,8(s1)
    80003a50:	2785                	addiw	a5,a5,1
    80003a52:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a54:	0001b517          	auipc	a0,0x1b
    80003a58:	7d450513          	addi	a0,a0,2004 # 8001f228 <itable>
    80003a5c:	ffffd097          	auipc	ra,0xffffd
    80003a60:	2f2080e7          	jalr	754(ra) # 80000d4e <release>
}
    80003a64:	8526                	mv	a0,s1
    80003a66:	60e2                	ld	ra,24(sp)
    80003a68:	6442                	ld	s0,16(sp)
    80003a6a:	64a2                	ld	s1,8(sp)
    80003a6c:	6105                	addi	sp,sp,32
    80003a6e:	8082                	ret

0000000080003a70 <ilock>:
{
    80003a70:	1101                	addi	sp,sp,-32
    80003a72:	ec06                	sd	ra,24(sp)
    80003a74:	e822                	sd	s0,16(sp)
    80003a76:	e426                	sd	s1,8(sp)
    80003a78:	e04a                	sd	s2,0(sp)
    80003a7a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a7c:	c115                	beqz	a0,80003aa0 <ilock+0x30>
    80003a7e:	84aa                	mv	s1,a0
    80003a80:	451c                	lw	a5,8(a0)
    80003a82:	00f05f63          	blez	a5,80003aa0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a86:	0541                	addi	a0,a0,16
    80003a88:	00001097          	auipc	ra,0x1
    80003a8c:	c7e080e7          	jalr	-898(ra) # 80004706 <acquiresleep>
  if(ip->valid == 0){
    80003a90:	40bc                	lw	a5,64(s1)
    80003a92:	cf99                	beqz	a5,80003ab0 <ilock+0x40>
}
    80003a94:	60e2                	ld	ra,24(sp)
    80003a96:	6442                	ld	s0,16(sp)
    80003a98:	64a2                	ld	s1,8(sp)
    80003a9a:	6902                	ld	s2,0(sp)
    80003a9c:	6105                	addi	sp,sp,32
    80003a9e:	8082                	ret
    panic("ilock");
    80003aa0:	00005517          	auipc	a0,0x5
    80003aa4:	cb850513          	addi	a0,a0,-840 # 80008758 <__func__.0+0xe0>
    80003aa8:	ffffd097          	auipc	ra,0xffffd
    80003aac:	a94080e7          	jalr	-1388(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ab0:	40dc                	lw	a5,4(s1)
    80003ab2:	0047d79b          	srliw	a5,a5,0x4
    80003ab6:	0001b597          	auipc	a1,0x1b
    80003aba:	76a5a583          	lw	a1,1898(a1) # 8001f220 <sb+0x18>
    80003abe:	9dbd                	addw	a1,a1,a5
    80003ac0:	4088                	lw	a0,0(s1)
    80003ac2:	fffff097          	auipc	ra,0xfffff
    80003ac6:	79e080e7          	jalr	1950(ra) # 80003260 <bread>
    80003aca:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003acc:	05850593          	addi	a1,a0,88
    80003ad0:	40dc                	lw	a5,4(s1)
    80003ad2:	8bbd                	andi	a5,a5,15
    80003ad4:	079a                	slli	a5,a5,0x6
    80003ad6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ad8:	00059783          	lh	a5,0(a1)
    80003adc:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ae0:	00259783          	lh	a5,2(a1)
    80003ae4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003ae8:	00459783          	lh	a5,4(a1)
    80003aec:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003af0:	00659783          	lh	a5,6(a1)
    80003af4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003af8:	459c                	lw	a5,8(a1)
    80003afa:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003afc:	03400613          	li	a2,52
    80003b00:	05b1                	addi	a1,a1,12
    80003b02:	05048513          	addi	a0,s1,80
    80003b06:	ffffd097          	auipc	ra,0xffffd
    80003b0a:	2ec080e7          	jalr	748(ra) # 80000df2 <memmove>
    brelse(bp);
    80003b0e:	854a                	mv	a0,s2
    80003b10:	00000097          	auipc	ra,0x0
    80003b14:	880080e7          	jalr	-1920(ra) # 80003390 <brelse>
    ip->valid = 1;
    80003b18:	4785                	li	a5,1
    80003b1a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003b1c:	04449783          	lh	a5,68(s1)
    80003b20:	fbb5                	bnez	a5,80003a94 <ilock+0x24>
      panic("ilock: no type");
    80003b22:	00005517          	auipc	a0,0x5
    80003b26:	c3e50513          	addi	a0,a0,-962 # 80008760 <__func__.0+0xe8>
    80003b2a:	ffffd097          	auipc	ra,0xffffd
    80003b2e:	a12080e7          	jalr	-1518(ra) # 8000053c <panic>

0000000080003b32 <iunlock>:
{
    80003b32:	1101                	addi	sp,sp,-32
    80003b34:	ec06                	sd	ra,24(sp)
    80003b36:	e822                	sd	s0,16(sp)
    80003b38:	e426                	sd	s1,8(sp)
    80003b3a:	e04a                	sd	s2,0(sp)
    80003b3c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b3e:	c905                	beqz	a0,80003b6e <iunlock+0x3c>
    80003b40:	84aa                	mv	s1,a0
    80003b42:	01050913          	addi	s2,a0,16
    80003b46:	854a                	mv	a0,s2
    80003b48:	00001097          	auipc	ra,0x1
    80003b4c:	c58080e7          	jalr	-936(ra) # 800047a0 <holdingsleep>
    80003b50:	cd19                	beqz	a0,80003b6e <iunlock+0x3c>
    80003b52:	449c                	lw	a5,8(s1)
    80003b54:	00f05d63          	blez	a5,80003b6e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b58:	854a                	mv	a0,s2
    80003b5a:	00001097          	auipc	ra,0x1
    80003b5e:	c02080e7          	jalr	-1022(ra) # 8000475c <releasesleep>
}
    80003b62:	60e2                	ld	ra,24(sp)
    80003b64:	6442                	ld	s0,16(sp)
    80003b66:	64a2                	ld	s1,8(sp)
    80003b68:	6902                	ld	s2,0(sp)
    80003b6a:	6105                	addi	sp,sp,32
    80003b6c:	8082                	ret
    panic("iunlock");
    80003b6e:	00005517          	auipc	a0,0x5
    80003b72:	c0250513          	addi	a0,a0,-1022 # 80008770 <__func__.0+0xf8>
    80003b76:	ffffd097          	auipc	ra,0xffffd
    80003b7a:	9c6080e7          	jalr	-1594(ra) # 8000053c <panic>

0000000080003b7e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b7e:	7179                	addi	sp,sp,-48
    80003b80:	f406                	sd	ra,40(sp)
    80003b82:	f022                	sd	s0,32(sp)
    80003b84:	ec26                	sd	s1,24(sp)
    80003b86:	e84a                	sd	s2,16(sp)
    80003b88:	e44e                	sd	s3,8(sp)
    80003b8a:	e052                	sd	s4,0(sp)
    80003b8c:	1800                	addi	s0,sp,48
    80003b8e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b90:	05050493          	addi	s1,a0,80
    80003b94:	08050913          	addi	s2,a0,128
    80003b98:	a021                	j	80003ba0 <itrunc+0x22>
    80003b9a:	0491                	addi	s1,s1,4
    80003b9c:	01248d63          	beq	s1,s2,80003bb6 <itrunc+0x38>
    if(ip->addrs[i]){
    80003ba0:	408c                	lw	a1,0(s1)
    80003ba2:	dde5                	beqz	a1,80003b9a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ba4:	0009a503          	lw	a0,0(s3)
    80003ba8:	00000097          	auipc	ra,0x0
    80003bac:	8fc080e7          	jalr	-1796(ra) # 800034a4 <bfree>
      ip->addrs[i] = 0;
    80003bb0:	0004a023          	sw	zero,0(s1)
    80003bb4:	b7dd                	j	80003b9a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003bb6:	0809a583          	lw	a1,128(s3)
    80003bba:	e185                	bnez	a1,80003bda <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003bbc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003bc0:	854e                	mv	a0,s3
    80003bc2:	00000097          	auipc	ra,0x0
    80003bc6:	de2080e7          	jalr	-542(ra) # 800039a4 <iupdate>
}
    80003bca:	70a2                	ld	ra,40(sp)
    80003bcc:	7402                	ld	s0,32(sp)
    80003bce:	64e2                	ld	s1,24(sp)
    80003bd0:	6942                	ld	s2,16(sp)
    80003bd2:	69a2                	ld	s3,8(sp)
    80003bd4:	6a02                	ld	s4,0(sp)
    80003bd6:	6145                	addi	sp,sp,48
    80003bd8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003bda:	0009a503          	lw	a0,0(s3)
    80003bde:	fffff097          	auipc	ra,0xfffff
    80003be2:	682080e7          	jalr	1666(ra) # 80003260 <bread>
    80003be6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003be8:	05850493          	addi	s1,a0,88
    80003bec:	45850913          	addi	s2,a0,1112
    80003bf0:	a021                	j	80003bf8 <itrunc+0x7a>
    80003bf2:	0491                	addi	s1,s1,4
    80003bf4:	01248b63          	beq	s1,s2,80003c0a <itrunc+0x8c>
      if(a[j])
    80003bf8:	408c                	lw	a1,0(s1)
    80003bfa:	dde5                	beqz	a1,80003bf2 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003bfc:	0009a503          	lw	a0,0(s3)
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	8a4080e7          	jalr	-1884(ra) # 800034a4 <bfree>
    80003c08:	b7ed                	j	80003bf2 <itrunc+0x74>
    brelse(bp);
    80003c0a:	8552                	mv	a0,s4
    80003c0c:	fffff097          	auipc	ra,0xfffff
    80003c10:	784080e7          	jalr	1924(ra) # 80003390 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c14:	0809a583          	lw	a1,128(s3)
    80003c18:	0009a503          	lw	a0,0(s3)
    80003c1c:	00000097          	auipc	ra,0x0
    80003c20:	888080e7          	jalr	-1912(ra) # 800034a4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c24:	0809a023          	sw	zero,128(s3)
    80003c28:	bf51                	j	80003bbc <itrunc+0x3e>

0000000080003c2a <iput>:
{
    80003c2a:	1101                	addi	sp,sp,-32
    80003c2c:	ec06                	sd	ra,24(sp)
    80003c2e:	e822                	sd	s0,16(sp)
    80003c30:	e426                	sd	s1,8(sp)
    80003c32:	e04a                	sd	s2,0(sp)
    80003c34:	1000                	addi	s0,sp,32
    80003c36:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c38:	0001b517          	auipc	a0,0x1b
    80003c3c:	5f050513          	addi	a0,a0,1520 # 8001f228 <itable>
    80003c40:	ffffd097          	auipc	ra,0xffffd
    80003c44:	05a080e7          	jalr	90(ra) # 80000c9a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c48:	4498                	lw	a4,8(s1)
    80003c4a:	4785                	li	a5,1
    80003c4c:	02f70363          	beq	a4,a5,80003c72 <iput+0x48>
  ip->ref--;
    80003c50:	449c                	lw	a5,8(s1)
    80003c52:	37fd                	addiw	a5,a5,-1
    80003c54:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c56:	0001b517          	auipc	a0,0x1b
    80003c5a:	5d250513          	addi	a0,a0,1490 # 8001f228 <itable>
    80003c5e:	ffffd097          	auipc	ra,0xffffd
    80003c62:	0f0080e7          	jalr	240(ra) # 80000d4e <release>
}
    80003c66:	60e2                	ld	ra,24(sp)
    80003c68:	6442                	ld	s0,16(sp)
    80003c6a:	64a2                	ld	s1,8(sp)
    80003c6c:	6902                	ld	s2,0(sp)
    80003c6e:	6105                	addi	sp,sp,32
    80003c70:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c72:	40bc                	lw	a5,64(s1)
    80003c74:	dff1                	beqz	a5,80003c50 <iput+0x26>
    80003c76:	04a49783          	lh	a5,74(s1)
    80003c7a:	fbf9                	bnez	a5,80003c50 <iput+0x26>
    acquiresleep(&ip->lock);
    80003c7c:	01048913          	addi	s2,s1,16
    80003c80:	854a                	mv	a0,s2
    80003c82:	00001097          	auipc	ra,0x1
    80003c86:	a84080e7          	jalr	-1404(ra) # 80004706 <acquiresleep>
    release(&itable.lock);
    80003c8a:	0001b517          	auipc	a0,0x1b
    80003c8e:	59e50513          	addi	a0,a0,1438 # 8001f228 <itable>
    80003c92:	ffffd097          	auipc	ra,0xffffd
    80003c96:	0bc080e7          	jalr	188(ra) # 80000d4e <release>
    itrunc(ip);
    80003c9a:	8526                	mv	a0,s1
    80003c9c:	00000097          	auipc	ra,0x0
    80003ca0:	ee2080e7          	jalr	-286(ra) # 80003b7e <itrunc>
    ip->type = 0;
    80003ca4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ca8:	8526                	mv	a0,s1
    80003caa:	00000097          	auipc	ra,0x0
    80003cae:	cfa080e7          	jalr	-774(ra) # 800039a4 <iupdate>
    ip->valid = 0;
    80003cb2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003cb6:	854a                	mv	a0,s2
    80003cb8:	00001097          	auipc	ra,0x1
    80003cbc:	aa4080e7          	jalr	-1372(ra) # 8000475c <releasesleep>
    acquire(&itable.lock);
    80003cc0:	0001b517          	auipc	a0,0x1b
    80003cc4:	56850513          	addi	a0,a0,1384 # 8001f228 <itable>
    80003cc8:	ffffd097          	auipc	ra,0xffffd
    80003ccc:	fd2080e7          	jalr	-46(ra) # 80000c9a <acquire>
    80003cd0:	b741                	j	80003c50 <iput+0x26>

0000000080003cd2 <iunlockput>:
{
    80003cd2:	1101                	addi	sp,sp,-32
    80003cd4:	ec06                	sd	ra,24(sp)
    80003cd6:	e822                	sd	s0,16(sp)
    80003cd8:	e426                	sd	s1,8(sp)
    80003cda:	1000                	addi	s0,sp,32
    80003cdc:	84aa                	mv	s1,a0
  iunlock(ip);
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	e54080e7          	jalr	-428(ra) # 80003b32 <iunlock>
  iput(ip);
    80003ce6:	8526                	mv	a0,s1
    80003ce8:	00000097          	auipc	ra,0x0
    80003cec:	f42080e7          	jalr	-190(ra) # 80003c2a <iput>
}
    80003cf0:	60e2                	ld	ra,24(sp)
    80003cf2:	6442                	ld	s0,16(sp)
    80003cf4:	64a2                	ld	s1,8(sp)
    80003cf6:	6105                	addi	sp,sp,32
    80003cf8:	8082                	ret

0000000080003cfa <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003cfa:	1141                	addi	sp,sp,-16
    80003cfc:	e422                	sd	s0,8(sp)
    80003cfe:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d00:	411c                	lw	a5,0(a0)
    80003d02:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d04:	415c                	lw	a5,4(a0)
    80003d06:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d08:	04451783          	lh	a5,68(a0)
    80003d0c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d10:	04a51783          	lh	a5,74(a0)
    80003d14:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d18:	04c56783          	lwu	a5,76(a0)
    80003d1c:	e99c                	sd	a5,16(a1)
}
    80003d1e:	6422                	ld	s0,8(sp)
    80003d20:	0141                	addi	sp,sp,16
    80003d22:	8082                	ret

0000000080003d24 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d24:	457c                	lw	a5,76(a0)
    80003d26:	0ed7e963          	bltu	a5,a3,80003e18 <readi+0xf4>
{
    80003d2a:	7159                	addi	sp,sp,-112
    80003d2c:	f486                	sd	ra,104(sp)
    80003d2e:	f0a2                	sd	s0,96(sp)
    80003d30:	eca6                	sd	s1,88(sp)
    80003d32:	e8ca                	sd	s2,80(sp)
    80003d34:	e4ce                	sd	s3,72(sp)
    80003d36:	e0d2                	sd	s4,64(sp)
    80003d38:	fc56                	sd	s5,56(sp)
    80003d3a:	f85a                	sd	s6,48(sp)
    80003d3c:	f45e                	sd	s7,40(sp)
    80003d3e:	f062                	sd	s8,32(sp)
    80003d40:	ec66                	sd	s9,24(sp)
    80003d42:	e86a                	sd	s10,16(sp)
    80003d44:	e46e                	sd	s11,8(sp)
    80003d46:	1880                	addi	s0,sp,112
    80003d48:	8b2a                	mv	s6,a0
    80003d4a:	8bae                	mv	s7,a1
    80003d4c:	8a32                	mv	s4,a2
    80003d4e:	84b6                	mv	s1,a3
    80003d50:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003d52:	9f35                	addw	a4,a4,a3
    return 0;
    80003d54:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d56:	0ad76063          	bltu	a4,a3,80003df6 <readi+0xd2>
  if(off + n > ip->size)
    80003d5a:	00e7f463          	bgeu	a5,a4,80003d62 <readi+0x3e>
    n = ip->size - off;
    80003d5e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d62:	0a0a8963          	beqz	s5,80003e14 <readi+0xf0>
    80003d66:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d68:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d6c:	5c7d                	li	s8,-1
    80003d6e:	a82d                	j	80003da8 <readi+0x84>
    80003d70:	020d1d93          	slli	s11,s10,0x20
    80003d74:	020ddd93          	srli	s11,s11,0x20
    80003d78:	05890613          	addi	a2,s2,88
    80003d7c:	86ee                	mv	a3,s11
    80003d7e:	963a                	add	a2,a2,a4
    80003d80:	85d2                	mv	a1,s4
    80003d82:	855e                	mv	a0,s7
    80003d84:	fffff097          	auipc	ra,0xfffff
    80003d88:	94e080e7          	jalr	-1714(ra) # 800026d2 <either_copyout>
    80003d8c:	05850d63          	beq	a0,s8,80003de6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d90:	854a                	mv	a0,s2
    80003d92:	fffff097          	auipc	ra,0xfffff
    80003d96:	5fe080e7          	jalr	1534(ra) # 80003390 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d9a:	013d09bb          	addw	s3,s10,s3
    80003d9e:	009d04bb          	addw	s1,s10,s1
    80003da2:	9a6e                	add	s4,s4,s11
    80003da4:	0559f763          	bgeu	s3,s5,80003df2 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003da8:	00a4d59b          	srliw	a1,s1,0xa
    80003dac:	855a                	mv	a0,s6
    80003dae:	00000097          	auipc	ra,0x0
    80003db2:	8a4080e7          	jalr	-1884(ra) # 80003652 <bmap>
    80003db6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003dba:	cd85                	beqz	a1,80003df2 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003dbc:	000b2503          	lw	a0,0(s6)
    80003dc0:	fffff097          	auipc	ra,0xfffff
    80003dc4:	4a0080e7          	jalr	1184(ra) # 80003260 <bread>
    80003dc8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dca:	3ff4f713          	andi	a4,s1,1023
    80003dce:	40ec87bb          	subw	a5,s9,a4
    80003dd2:	413a86bb          	subw	a3,s5,s3
    80003dd6:	8d3e                	mv	s10,a5
    80003dd8:	2781                	sext.w	a5,a5
    80003dda:	0006861b          	sext.w	a2,a3
    80003dde:	f8f679e3          	bgeu	a2,a5,80003d70 <readi+0x4c>
    80003de2:	8d36                	mv	s10,a3
    80003de4:	b771                	j	80003d70 <readi+0x4c>
      brelse(bp);
    80003de6:	854a                	mv	a0,s2
    80003de8:	fffff097          	auipc	ra,0xfffff
    80003dec:	5a8080e7          	jalr	1448(ra) # 80003390 <brelse>
      tot = -1;
    80003df0:	59fd                	li	s3,-1
  }
  return tot;
    80003df2:	0009851b          	sext.w	a0,s3
}
    80003df6:	70a6                	ld	ra,104(sp)
    80003df8:	7406                	ld	s0,96(sp)
    80003dfa:	64e6                	ld	s1,88(sp)
    80003dfc:	6946                	ld	s2,80(sp)
    80003dfe:	69a6                	ld	s3,72(sp)
    80003e00:	6a06                	ld	s4,64(sp)
    80003e02:	7ae2                	ld	s5,56(sp)
    80003e04:	7b42                	ld	s6,48(sp)
    80003e06:	7ba2                	ld	s7,40(sp)
    80003e08:	7c02                	ld	s8,32(sp)
    80003e0a:	6ce2                	ld	s9,24(sp)
    80003e0c:	6d42                	ld	s10,16(sp)
    80003e0e:	6da2                	ld	s11,8(sp)
    80003e10:	6165                	addi	sp,sp,112
    80003e12:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e14:	89d6                	mv	s3,s5
    80003e16:	bff1                	j	80003df2 <readi+0xce>
    return 0;
    80003e18:	4501                	li	a0,0
}
    80003e1a:	8082                	ret

0000000080003e1c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e1c:	457c                	lw	a5,76(a0)
    80003e1e:	10d7e863          	bltu	a5,a3,80003f2e <writei+0x112>
{
    80003e22:	7159                	addi	sp,sp,-112
    80003e24:	f486                	sd	ra,104(sp)
    80003e26:	f0a2                	sd	s0,96(sp)
    80003e28:	eca6                	sd	s1,88(sp)
    80003e2a:	e8ca                	sd	s2,80(sp)
    80003e2c:	e4ce                	sd	s3,72(sp)
    80003e2e:	e0d2                	sd	s4,64(sp)
    80003e30:	fc56                	sd	s5,56(sp)
    80003e32:	f85a                	sd	s6,48(sp)
    80003e34:	f45e                	sd	s7,40(sp)
    80003e36:	f062                	sd	s8,32(sp)
    80003e38:	ec66                	sd	s9,24(sp)
    80003e3a:	e86a                	sd	s10,16(sp)
    80003e3c:	e46e                	sd	s11,8(sp)
    80003e3e:	1880                	addi	s0,sp,112
    80003e40:	8aaa                	mv	s5,a0
    80003e42:	8bae                	mv	s7,a1
    80003e44:	8a32                	mv	s4,a2
    80003e46:	8936                	mv	s2,a3
    80003e48:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e4a:	00e687bb          	addw	a5,a3,a4
    80003e4e:	0ed7e263          	bltu	a5,a3,80003f32 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e52:	00043737          	lui	a4,0x43
    80003e56:	0ef76063          	bltu	a4,a5,80003f36 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e5a:	0c0b0863          	beqz	s6,80003f2a <writei+0x10e>
    80003e5e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e60:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e64:	5c7d                	li	s8,-1
    80003e66:	a091                	j	80003eaa <writei+0x8e>
    80003e68:	020d1d93          	slli	s11,s10,0x20
    80003e6c:	020ddd93          	srli	s11,s11,0x20
    80003e70:	05848513          	addi	a0,s1,88
    80003e74:	86ee                	mv	a3,s11
    80003e76:	8652                	mv	a2,s4
    80003e78:	85de                	mv	a1,s7
    80003e7a:	953a                	add	a0,a0,a4
    80003e7c:	fffff097          	auipc	ra,0xfffff
    80003e80:	8ac080e7          	jalr	-1876(ra) # 80002728 <either_copyin>
    80003e84:	07850263          	beq	a0,s8,80003ee8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e88:	8526                	mv	a0,s1
    80003e8a:	00000097          	auipc	ra,0x0
    80003e8e:	75e080e7          	jalr	1886(ra) # 800045e8 <log_write>
    brelse(bp);
    80003e92:	8526                	mv	a0,s1
    80003e94:	fffff097          	auipc	ra,0xfffff
    80003e98:	4fc080e7          	jalr	1276(ra) # 80003390 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e9c:	013d09bb          	addw	s3,s10,s3
    80003ea0:	012d093b          	addw	s2,s10,s2
    80003ea4:	9a6e                	add	s4,s4,s11
    80003ea6:	0569f663          	bgeu	s3,s6,80003ef2 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003eaa:	00a9559b          	srliw	a1,s2,0xa
    80003eae:	8556                	mv	a0,s5
    80003eb0:	fffff097          	auipc	ra,0xfffff
    80003eb4:	7a2080e7          	jalr	1954(ra) # 80003652 <bmap>
    80003eb8:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003ebc:	c99d                	beqz	a1,80003ef2 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003ebe:	000aa503          	lw	a0,0(s5)
    80003ec2:	fffff097          	auipc	ra,0xfffff
    80003ec6:	39e080e7          	jalr	926(ra) # 80003260 <bread>
    80003eca:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ecc:	3ff97713          	andi	a4,s2,1023
    80003ed0:	40ec87bb          	subw	a5,s9,a4
    80003ed4:	413b06bb          	subw	a3,s6,s3
    80003ed8:	8d3e                	mv	s10,a5
    80003eda:	2781                	sext.w	a5,a5
    80003edc:	0006861b          	sext.w	a2,a3
    80003ee0:	f8f674e3          	bgeu	a2,a5,80003e68 <writei+0x4c>
    80003ee4:	8d36                	mv	s10,a3
    80003ee6:	b749                	j	80003e68 <writei+0x4c>
      brelse(bp);
    80003ee8:	8526                	mv	a0,s1
    80003eea:	fffff097          	auipc	ra,0xfffff
    80003eee:	4a6080e7          	jalr	1190(ra) # 80003390 <brelse>
  }

  if(off > ip->size)
    80003ef2:	04caa783          	lw	a5,76(s5)
    80003ef6:	0127f463          	bgeu	a5,s2,80003efe <writei+0xe2>
    ip->size = off;
    80003efa:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003efe:	8556                	mv	a0,s5
    80003f00:	00000097          	auipc	ra,0x0
    80003f04:	aa4080e7          	jalr	-1372(ra) # 800039a4 <iupdate>

  return tot;
    80003f08:	0009851b          	sext.w	a0,s3
}
    80003f0c:	70a6                	ld	ra,104(sp)
    80003f0e:	7406                	ld	s0,96(sp)
    80003f10:	64e6                	ld	s1,88(sp)
    80003f12:	6946                	ld	s2,80(sp)
    80003f14:	69a6                	ld	s3,72(sp)
    80003f16:	6a06                	ld	s4,64(sp)
    80003f18:	7ae2                	ld	s5,56(sp)
    80003f1a:	7b42                	ld	s6,48(sp)
    80003f1c:	7ba2                	ld	s7,40(sp)
    80003f1e:	7c02                	ld	s8,32(sp)
    80003f20:	6ce2                	ld	s9,24(sp)
    80003f22:	6d42                	ld	s10,16(sp)
    80003f24:	6da2                	ld	s11,8(sp)
    80003f26:	6165                	addi	sp,sp,112
    80003f28:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f2a:	89da                	mv	s3,s6
    80003f2c:	bfc9                	j	80003efe <writei+0xe2>
    return -1;
    80003f2e:	557d                	li	a0,-1
}
    80003f30:	8082                	ret
    return -1;
    80003f32:	557d                	li	a0,-1
    80003f34:	bfe1                	j	80003f0c <writei+0xf0>
    return -1;
    80003f36:	557d                	li	a0,-1
    80003f38:	bfd1                	j	80003f0c <writei+0xf0>

0000000080003f3a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f3a:	1141                	addi	sp,sp,-16
    80003f3c:	e406                	sd	ra,8(sp)
    80003f3e:	e022                	sd	s0,0(sp)
    80003f40:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f42:	4639                	li	a2,14
    80003f44:	ffffd097          	auipc	ra,0xffffd
    80003f48:	f22080e7          	jalr	-222(ra) # 80000e66 <strncmp>
}
    80003f4c:	60a2                	ld	ra,8(sp)
    80003f4e:	6402                	ld	s0,0(sp)
    80003f50:	0141                	addi	sp,sp,16
    80003f52:	8082                	ret

0000000080003f54 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f54:	7139                	addi	sp,sp,-64
    80003f56:	fc06                	sd	ra,56(sp)
    80003f58:	f822                	sd	s0,48(sp)
    80003f5a:	f426                	sd	s1,40(sp)
    80003f5c:	f04a                	sd	s2,32(sp)
    80003f5e:	ec4e                	sd	s3,24(sp)
    80003f60:	e852                	sd	s4,16(sp)
    80003f62:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f64:	04451703          	lh	a4,68(a0)
    80003f68:	4785                	li	a5,1
    80003f6a:	00f71a63          	bne	a4,a5,80003f7e <dirlookup+0x2a>
    80003f6e:	892a                	mv	s2,a0
    80003f70:	89ae                	mv	s3,a1
    80003f72:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f74:	457c                	lw	a5,76(a0)
    80003f76:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f78:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f7a:	e79d                	bnez	a5,80003fa8 <dirlookup+0x54>
    80003f7c:	a8a5                	j	80003ff4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f7e:	00004517          	auipc	a0,0x4
    80003f82:	7fa50513          	addi	a0,a0,2042 # 80008778 <__func__.0+0x100>
    80003f86:	ffffc097          	auipc	ra,0xffffc
    80003f8a:	5b6080e7          	jalr	1462(ra) # 8000053c <panic>
      panic("dirlookup read");
    80003f8e:	00005517          	auipc	a0,0x5
    80003f92:	80250513          	addi	a0,a0,-2046 # 80008790 <__func__.0+0x118>
    80003f96:	ffffc097          	auipc	ra,0xffffc
    80003f9a:	5a6080e7          	jalr	1446(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f9e:	24c1                	addiw	s1,s1,16
    80003fa0:	04c92783          	lw	a5,76(s2)
    80003fa4:	04f4f763          	bgeu	s1,a5,80003ff2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fa8:	4741                	li	a4,16
    80003faa:	86a6                	mv	a3,s1
    80003fac:	fc040613          	addi	a2,s0,-64
    80003fb0:	4581                	li	a1,0
    80003fb2:	854a                	mv	a0,s2
    80003fb4:	00000097          	auipc	ra,0x0
    80003fb8:	d70080e7          	jalr	-656(ra) # 80003d24 <readi>
    80003fbc:	47c1                	li	a5,16
    80003fbe:	fcf518e3          	bne	a0,a5,80003f8e <dirlookup+0x3a>
    if(de.inum == 0)
    80003fc2:	fc045783          	lhu	a5,-64(s0)
    80003fc6:	dfe1                	beqz	a5,80003f9e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003fc8:	fc240593          	addi	a1,s0,-62
    80003fcc:	854e                	mv	a0,s3
    80003fce:	00000097          	auipc	ra,0x0
    80003fd2:	f6c080e7          	jalr	-148(ra) # 80003f3a <namecmp>
    80003fd6:	f561                	bnez	a0,80003f9e <dirlookup+0x4a>
      if(poff)
    80003fd8:	000a0463          	beqz	s4,80003fe0 <dirlookup+0x8c>
        *poff = off;
    80003fdc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003fe0:	fc045583          	lhu	a1,-64(s0)
    80003fe4:	00092503          	lw	a0,0(s2)
    80003fe8:	fffff097          	auipc	ra,0xfffff
    80003fec:	754080e7          	jalr	1876(ra) # 8000373c <iget>
    80003ff0:	a011                	j	80003ff4 <dirlookup+0xa0>
  return 0;
    80003ff2:	4501                	li	a0,0
}
    80003ff4:	70e2                	ld	ra,56(sp)
    80003ff6:	7442                	ld	s0,48(sp)
    80003ff8:	74a2                	ld	s1,40(sp)
    80003ffa:	7902                	ld	s2,32(sp)
    80003ffc:	69e2                	ld	s3,24(sp)
    80003ffe:	6a42                	ld	s4,16(sp)
    80004000:	6121                	addi	sp,sp,64
    80004002:	8082                	ret

0000000080004004 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004004:	711d                	addi	sp,sp,-96
    80004006:	ec86                	sd	ra,88(sp)
    80004008:	e8a2                	sd	s0,80(sp)
    8000400a:	e4a6                	sd	s1,72(sp)
    8000400c:	e0ca                	sd	s2,64(sp)
    8000400e:	fc4e                	sd	s3,56(sp)
    80004010:	f852                	sd	s4,48(sp)
    80004012:	f456                	sd	s5,40(sp)
    80004014:	f05a                	sd	s6,32(sp)
    80004016:	ec5e                	sd	s7,24(sp)
    80004018:	e862                	sd	s8,16(sp)
    8000401a:	e466                	sd	s9,8(sp)
    8000401c:	1080                	addi	s0,sp,96
    8000401e:	84aa                	mv	s1,a0
    80004020:	8b2e                	mv	s6,a1
    80004022:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004024:	00054703          	lbu	a4,0(a0)
    80004028:	02f00793          	li	a5,47
    8000402c:	02f70263          	beq	a4,a5,80004050 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004030:	ffffe097          	auipc	ra,0xffffe
    80004034:	b32080e7          	jalr	-1230(ra) # 80001b62 <myproc>
    80004038:	15053503          	ld	a0,336(a0)
    8000403c:	00000097          	auipc	ra,0x0
    80004040:	9f6080e7          	jalr	-1546(ra) # 80003a32 <idup>
    80004044:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004046:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    8000404a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000404c:	4b85                	li	s7,1
    8000404e:	a875                	j	8000410a <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80004050:	4585                	li	a1,1
    80004052:	4505                	li	a0,1
    80004054:	fffff097          	auipc	ra,0xfffff
    80004058:	6e8080e7          	jalr	1768(ra) # 8000373c <iget>
    8000405c:	8a2a                	mv	s4,a0
    8000405e:	b7e5                	j	80004046 <namex+0x42>
      iunlockput(ip);
    80004060:	8552                	mv	a0,s4
    80004062:	00000097          	auipc	ra,0x0
    80004066:	c70080e7          	jalr	-912(ra) # 80003cd2 <iunlockput>
      return 0;
    8000406a:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000406c:	8552                	mv	a0,s4
    8000406e:	60e6                	ld	ra,88(sp)
    80004070:	6446                	ld	s0,80(sp)
    80004072:	64a6                	ld	s1,72(sp)
    80004074:	6906                	ld	s2,64(sp)
    80004076:	79e2                	ld	s3,56(sp)
    80004078:	7a42                	ld	s4,48(sp)
    8000407a:	7aa2                	ld	s5,40(sp)
    8000407c:	7b02                	ld	s6,32(sp)
    8000407e:	6be2                	ld	s7,24(sp)
    80004080:	6c42                	ld	s8,16(sp)
    80004082:	6ca2                	ld	s9,8(sp)
    80004084:	6125                	addi	sp,sp,96
    80004086:	8082                	ret
      iunlock(ip);
    80004088:	8552                	mv	a0,s4
    8000408a:	00000097          	auipc	ra,0x0
    8000408e:	aa8080e7          	jalr	-1368(ra) # 80003b32 <iunlock>
      return ip;
    80004092:	bfe9                	j	8000406c <namex+0x68>
      iunlockput(ip);
    80004094:	8552                	mv	a0,s4
    80004096:	00000097          	auipc	ra,0x0
    8000409a:	c3c080e7          	jalr	-964(ra) # 80003cd2 <iunlockput>
      return 0;
    8000409e:	8a4e                	mv	s4,s3
    800040a0:	b7f1                	j	8000406c <namex+0x68>
  len = path - s;
    800040a2:	40998633          	sub	a2,s3,s1
    800040a6:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800040aa:	099c5863          	bge	s8,s9,8000413a <namex+0x136>
    memmove(name, s, DIRSIZ);
    800040ae:	4639                	li	a2,14
    800040b0:	85a6                	mv	a1,s1
    800040b2:	8556                	mv	a0,s5
    800040b4:	ffffd097          	auipc	ra,0xffffd
    800040b8:	d3e080e7          	jalr	-706(ra) # 80000df2 <memmove>
    800040bc:	84ce                	mv	s1,s3
  while(*path == '/')
    800040be:	0004c783          	lbu	a5,0(s1)
    800040c2:	01279763          	bne	a5,s2,800040d0 <namex+0xcc>
    path++;
    800040c6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040c8:	0004c783          	lbu	a5,0(s1)
    800040cc:	ff278de3          	beq	a5,s2,800040c6 <namex+0xc2>
    ilock(ip);
    800040d0:	8552                	mv	a0,s4
    800040d2:	00000097          	auipc	ra,0x0
    800040d6:	99e080e7          	jalr	-1634(ra) # 80003a70 <ilock>
    if(ip->type != T_DIR){
    800040da:	044a1783          	lh	a5,68(s4)
    800040de:	f97791e3          	bne	a5,s7,80004060 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    800040e2:	000b0563          	beqz	s6,800040ec <namex+0xe8>
    800040e6:	0004c783          	lbu	a5,0(s1)
    800040ea:	dfd9                	beqz	a5,80004088 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    800040ec:	4601                	li	a2,0
    800040ee:	85d6                	mv	a1,s5
    800040f0:	8552                	mv	a0,s4
    800040f2:	00000097          	auipc	ra,0x0
    800040f6:	e62080e7          	jalr	-414(ra) # 80003f54 <dirlookup>
    800040fa:	89aa                	mv	s3,a0
    800040fc:	dd41                	beqz	a0,80004094 <namex+0x90>
    iunlockput(ip);
    800040fe:	8552                	mv	a0,s4
    80004100:	00000097          	auipc	ra,0x0
    80004104:	bd2080e7          	jalr	-1070(ra) # 80003cd2 <iunlockput>
    ip = next;
    80004108:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000410a:	0004c783          	lbu	a5,0(s1)
    8000410e:	01279763          	bne	a5,s2,8000411c <namex+0x118>
    path++;
    80004112:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004114:	0004c783          	lbu	a5,0(s1)
    80004118:	ff278de3          	beq	a5,s2,80004112 <namex+0x10e>
  if(*path == 0)
    8000411c:	cb9d                	beqz	a5,80004152 <namex+0x14e>
  while(*path != '/' && *path != 0)
    8000411e:	0004c783          	lbu	a5,0(s1)
    80004122:	89a6                	mv	s3,s1
  len = path - s;
    80004124:	4c81                	li	s9,0
    80004126:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004128:	01278963          	beq	a5,s2,8000413a <namex+0x136>
    8000412c:	dbbd                	beqz	a5,800040a2 <namex+0x9e>
    path++;
    8000412e:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004130:	0009c783          	lbu	a5,0(s3)
    80004134:	ff279ce3          	bne	a5,s2,8000412c <namex+0x128>
    80004138:	b7ad                	j	800040a2 <namex+0x9e>
    memmove(name, s, len);
    8000413a:	2601                	sext.w	a2,a2
    8000413c:	85a6                	mv	a1,s1
    8000413e:	8556                	mv	a0,s5
    80004140:	ffffd097          	auipc	ra,0xffffd
    80004144:	cb2080e7          	jalr	-846(ra) # 80000df2 <memmove>
    name[len] = 0;
    80004148:	9cd6                	add	s9,s9,s5
    8000414a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000414e:	84ce                	mv	s1,s3
    80004150:	b7bd                	j	800040be <namex+0xba>
  if(nameiparent){
    80004152:	f00b0de3          	beqz	s6,8000406c <namex+0x68>
    iput(ip);
    80004156:	8552                	mv	a0,s4
    80004158:	00000097          	auipc	ra,0x0
    8000415c:	ad2080e7          	jalr	-1326(ra) # 80003c2a <iput>
    return 0;
    80004160:	4a01                	li	s4,0
    80004162:	b729                	j	8000406c <namex+0x68>

0000000080004164 <dirlink>:
{
    80004164:	7139                	addi	sp,sp,-64
    80004166:	fc06                	sd	ra,56(sp)
    80004168:	f822                	sd	s0,48(sp)
    8000416a:	f426                	sd	s1,40(sp)
    8000416c:	f04a                	sd	s2,32(sp)
    8000416e:	ec4e                	sd	s3,24(sp)
    80004170:	e852                	sd	s4,16(sp)
    80004172:	0080                	addi	s0,sp,64
    80004174:	892a                	mv	s2,a0
    80004176:	8a2e                	mv	s4,a1
    80004178:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000417a:	4601                	li	a2,0
    8000417c:	00000097          	auipc	ra,0x0
    80004180:	dd8080e7          	jalr	-552(ra) # 80003f54 <dirlookup>
    80004184:	e93d                	bnez	a0,800041fa <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004186:	04c92483          	lw	s1,76(s2)
    8000418a:	c49d                	beqz	s1,800041b8 <dirlink+0x54>
    8000418c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000418e:	4741                	li	a4,16
    80004190:	86a6                	mv	a3,s1
    80004192:	fc040613          	addi	a2,s0,-64
    80004196:	4581                	li	a1,0
    80004198:	854a                	mv	a0,s2
    8000419a:	00000097          	auipc	ra,0x0
    8000419e:	b8a080e7          	jalr	-1142(ra) # 80003d24 <readi>
    800041a2:	47c1                	li	a5,16
    800041a4:	06f51163          	bne	a0,a5,80004206 <dirlink+0xa2>
    if(de.inum == 0)
    800041a8:	fc045783          	lhu	a5,-64(s0)
    800041ac:	c791                	beqz	a5,800041b8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041ae:	24c1                	addiw	s1,s1,16
    800041b0:	04c92783          	lw	a5,76(s2)
    800041b4:	fcf4ede3          	bltu	s1,a5,8000418e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800041b8:	4639                	li	a2,14
    800041ba:	85d2                	mv	a1,s4
    800041bc:	fc240513          	addi	a0,s0,-62
    800041c0:	ffffd097          	auipc	ra,0xffffd
    800041c4:	ce2080e7          	jalr	-798(ra) # 80000ea2 <strncpy>
  de.inum = inum;
    800041c8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041cc:	4741                	li	a4,16
    800041ce:	86a6                	mv	a3,s1
    800041d0:	fc040613          	addi	a2,s0,-64
    800041d4:	4581                	li	a1,0
    800041d6:	854a                	mv	a0,s2
    800041d8:	00000097          	auipc	ra,0x0
    800041dc:	c44080e7          	jalr	-956(ra) # 80003e1c <writei>
    800041e0:	1541                	addi	a0,a0,-16
    800041e2:	00a03533          	snez	a0,a0
    800041e6:	40a00533          	neg	a0,a0
}
    800041ea:	70e2                	ld	ra,56(sp)
    800041ec:	7442                	ld	s0,48(sp)
    800041ee:	74a2                	ld	s1,40(sp)
    800041f0:	7902                	ld	s2,32(sp)
    800041f2:	69e2                	ld	s3,24(sp)
    800041f4:	6a42                	ld	s4,16(sp)
    800041f6:	6121                	addi	sp,sp,64
    800041f8:	8082                	ret
    iput(ip);
    800041fa:	00000097          	auipc	ra,0x0
    800041fe:	a30080e7          	jalr	-1488(ra) # 80003c2a <iput>
    return -1;
    80004202:	557d                	li	a0,-1
    80004204:	b7dd                	j	800041ea <dirlink+0x86>
      panic("dirlink read");
    80004206:	00004517          	auipc	a0,0x4
    8000420a:	59a50513          	addi	a0,a0,1434 # 800087a0 <__func__.0+0x128>
    8000420e:	ffffc097          	auipc	ra,0xffffc
    80004212:	32e080e7          	jalr	814(ra) # 8000053c <panic>

0000000080004216 <namei>:

struct inode*
namei(char *path)
{
    80004216:	1101                	addi	sp,sp,-32
    80004218:	ec06                	sd	ra,24(sp)
    8000421a:	e822                	sd	s0,16(sp)
    8000421c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000421e:	fe040613          	addi	a2,s0,-32
    80004222:	4581                	li	a1,0
    80004224:	00000097          	auipc	ra,0x0
    80004228:	de0080e7          	jalr	-544(ra) # 80004004 <namex>
}
    8000422c:	60e2                	ld	ra,24(sp)
    8000422e:	6442                	ld	s0,16(sp)
    80004230:	6105                	addi	sp,sp,32
    80004232:	8082                	ret

0000000080004234 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004234:	1141                	addi	sp,sp,-16
    80004236:	e406                	sd	ra,8(sp)
    80004238:	e022                	sd	s0,0(sp)
    8000423a:	0800                	addi	s0,sp,16
    8000423c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000423e:	4585                	li	a1,1
    80004240:	00000097          	auipc	ra,0x0
    80004244:	dc4080e7          	jalr	-572(ra) # 80004004 <namex>
}
    80004248:	60a2                	ld	ra,8(sp)
    8000424a:	6402                	ld	s0,0(sp)
    8000424c:	0141                	addi	sp,sp,16
    8000424e:	8082                	ret

0000000080004250 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004250:	1101                	addi	sp,sp,-32
    80004252:	ec06                	sd	ra,24(sp)
    80004254:	e822                	sd	s0,16(sp)
    80004256:	e426                	sd	s1,8(sp)
    80004258:	e04a                	sd	s2,0(sp)
    8000425a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000425c:	0001d917          	auipc	s2,0x1d
    80004260:	a7490913          	addi	s2,s2,-1420 # 80020cd0 <log>
    80004264:	01892583          	lw	a1,24(s2)
    80004268:	02892503          	lw	a0,40(s2)
    8000426c:	fffff097          	auipc	ra,0xfffff
    80004270:	ff4080e7          	jalr	-12(ra) # 80003260 <bread>
    80004274:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004276:	02c92603          	lw	a2,44(s2)
    8000427a:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000427c:	00c05f63          	blez	a2,8000429a <write_head+0x4a>
    80004280:	0001d717          	auipc	a4,0x1d
    80004284:	a8070713          	addi	a4,a4,-1408 # 80020d00 <log+0x30>
    80004288:	87aa                	mv	a5,a0
    8000428a:	060a                	slli	a2,a2,0x2
    8000428c:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    8000428e:	4314                	lw	a3,0(a4)
    80004290:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004292:	0711                	addi	a4,a4,4
    80004294:	0791                	addi	a5,a5,4
    80004296:	fec79ce3          	bne	a5,a2,8000428e <write_head+0x3e>
  }
  bwrite(buf);
    8000429a:	8526                	mv	a0,s1
    8000429c:	fffff097          	auipc	ra,0xfffff
    800042a0:	0b6080e7          	jalr	182(ra) # 80003352 <bwrite>
  brelse(buf);
    800042a4:	8526                	mv	a0,s1
    800042a6:	fffff097          	auipc	ra,0xfffff
    800042aa:	0ea080e7          	jalr	234(ra) # 80003390 <brelse>
}
    800042ae:	60e2                	ld	ra,24(sp)
    800042b0:	6442                	ld	s0,16(sp)
    800042b2:	64a2                	ld	s1,8(sp)
    800042b4:	6902                	ld	s2,0(sp)
    800042b6:	6105                	addi	sp,sp,32
    800042b8:	8082                	ret

00000000800042ba <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ba:	0001d797          	auipc	a5,0x1d
    800042be:	a427a783          	lw	a5,-1470(a5) # 80020cfc <log+0x2c>
    800042c2:	0af05d63          	blez	a5,8000437c <install_trans+0xc2>
{
    800042c6:	7139                	addi	sp,sp,-64
    800042c8:	fc06                	sd	ra,56(sp)
    800042ca:	f822                	sd	s0,48(sp)
    800042cc:	f426                	sd	s1,40(sp)
    800042ce:	f04a                	sd	s2,32(sp)
    800042d0:	ec4e                	sd	s3,24(sp)
    800042d2:	e852                	sd	s4,16(sp)
    800042d4:	e456                	sd	s5,8(sp)
    800042d6:	e05a                	sd	s6,0(sp)
    800042d8:	0080                	addi	s0,sp,64
    800042da:	8b2a                	mv	s6,a0
    800042dc:	0001da97          	auipc	s5,0x1d
    800042e0:	a24a8a93          	addi	s5,s5,-1500 # 80020d00 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042e4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042e6:	0001d997          	auipc	s3,0x1d
    800042ea:	9ea98993          	addi	s3,s3,-1558 # 80020cd0 <log>
    800042ee:	a00d                	j	80004310 <install_trans+0x56>
    brelse(lbuf);
    800042f0:	854a                	mv	a0,s2
    800042f2:	fffff097          	auipc	ra,0xfffff
    800042f6:	09e080e7          	jalr	158(ra) # 80003390 <brelse>
    brelse(dbuf);
    800042fa:	8526                	mv	a0,s1
    800042fc:	fffff097          	auipc	ra,0xfffff
    80004300:	094080e7          	jalr	148(ra) # 80003390 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004304:	2a05                	addiw	s4,s4,1
    80004306:	0a91                	addi	s5,s5,4
    80004308:	02c9a783          	lw	a5,44(s3)
    8000430c:	04fa5e63          	bge	s4,a5,80004368 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004310:	0189a583          	lw	a1,24(s3)
    80004314:	014585bb          	addw	a1,a1,s4
    80004318:	2585                	addiw	a1,a1,1
    8000431a:	0289a503          	lw	a0,40(s3)
    8000431e:	fffff097          	auipc	ra,0xfffff
    80004322:	f42080e7          	jalr	-190(ra) # 80003260 <bread>
    80004326:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004328:	000aa583          	lw	a1,0(s5)
    8000432c:	0289a503          	lw	a0,40(s3)
    80004330:	fffff097          	auipc	ra,0xfffff
    80004334:	f30080e7          	jalr	-208(ra) # 80003260 <bread>
    80004338:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000433a:	40000613          	li	a2,1024
    8000433e:	05890593          	addi	a1,s2,88
    80004342:	05850513          	addi	a0,a0,88
    80004346:	ffffd097          	auipc	ra,0xffffd
    8000434a:	aac080e7          	jalr	-1364(ra) # 80000df2 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000434e:	8526                	mv	a0,s1
    80004350:	fffff097          	auipc	ra,0xfffff
    80004354:	002080e7          	jalr	2(ra) # 80003352 <bwrite>
    if(recovering == 0)
    80004358:	f80b1ce3          	bnez	s6,800042f0 <install_trans+0x36>
      bunpin(dbuf);
    8000435c:	8526                	mv	a0,s1
    8000435e:	fffff097          	auipc	ra,0xfffff
    80004362:	10a080e7          	jalr	266(ra) # 80003468 <bunpin>
    80004366:	b769                	j	800042f0 <install_trans+0x36>
}
    80004368:	70e2                	ld	ra,56(sp)
    8000436a:	7442                	ld	s0,48(sp)
    8000436c:	74a2                	ld	s1,40(sp)
    8000436e:	7902                	ld	s2,32(sp)
    80004370:	69e2                	ld	s3,24(sp)
    80004372:	6a42                	ld	s4,16(sp)
    80004374:	6aa2                	ld	s5,8(sp)
    80004376:	6b02                	ld	s6,0(sp)
    80004378:	6121                	addi	sp,sp,64
    8000437a:	8082                	ret
    8000437c:	8082                	ret

000000008000437e <initlog>:
{
    8000437e:	7179                	addi	sp,sp,-48
    80004380:	f406                	sd	ra,40(sp)
    80004382:	f022                	sd	s0,32(sp)
    80004384:	ec26                	sd	s1,24(sp)
    80004386:	e84a                	sd	s2,16(sp)
    80004388:	e44e                	sd	s3,8(sp)
    8000438a:	1800                	addi	s0,sp,48
    8000438c:	892a                	mv	s2,a0
    8000438e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004390:	0001d497          	auipc	s1,0x1d
    80004394:	94048493          	addi	s1,s1,-1728 # 80020cd0 <log>
    80004398:	00004597          	auipc	a1,0x4
    8000439c:	41858593          	addi	a1,a1,1048 # 800087b0 <__func__.0+0x138>
    800043a0:	8526                	mv	a0,s1
    800043a2:	ffffd097          	auipc	ra,0xffffd
    800043a6:	868080e7          	jalr	-1944(ra) # 80000c0a <initlock>
  log.start = sb->logstart;
    800043aa:	0149a583          	lw	a1,20(s3)
    800043ae:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800043b0:	0109a783          	lw	a5,16(s3)
    800043b4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800043b6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800043ba:	854a                	mv	a0,s2
    800043bc:	fffff097          	auipc	ra,0xfffff
    800043c0:	ea4080e7          	jalr	-348(ra) # 80003260 <bread>
  log.lh.n = lh->n;
    800043c4:	4d30                	lw	a2,88(a0)
    800043c6:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800043c8:	00c05f63          	blez	a2,800043e6 <initlog+0x68>
    800043cc:	87aa                	mv	a5,a0
    800043ce:	0001d717          	auipc	a4,0x1d
    800043d2:	93270713          	addi	a4,a4,-1742 # 80020d00 <log+0x30>
    800043d6:	060a                	slli	a2,a2,0x2
    800043d8:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800043da:	4ff4                	lw	a3,92(a5)
    800043dc:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043de:	0791                	addi	a5,a5,4
    800043e0:	0711                	addi	a4,a4,4
    800043e2:	fec79ce3          	bne	a5,a2,800043da <initlog+0x5c>
  brelse(buf);
    800043e6:	fffff097          	auipc	ra,0xfffff
    800043ea:	faa080e7          	jalr	-86(ra) # 80003390 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800043ee:	4505                	li	a0,1
    800043f0:	00000097          	auipc	ra,0x0
    800043f4:	eca080e7          	jalr	-310(ra) # 800042ba <install_trans>
  log.lh.n = 0;
    800043f8:	0001d797          	auipc	a5,0x1d
    800043fc:	9007a223          	sw	zero,-1788(a5) # 80020cfc <log+0x2c>
  write_head(); // clear the log
    80004400:	00000097          	auipc	ra,0x0
    80004404:	e50080e7          	jalr	-432(ra) # 80004250 <write_head>
}
    80004408:	70a2                	ld	ra,40(sp)
    8000440a:	7402                	ld	s0,32(sp)
    8000440c:	64e2                	ld	s1,24(sp)
    8000440e:	6942                	ld	s2,16(sp)
    80004410:	69a2                	ld	s3,8(sp)
    80004412:	6145                	addi	sp,sp,48
    80004414:	8082                	ret

0000000080004416 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004416:	1101                	addi	sp,sp,-32
    80004418:	ec06                	sd	ra,24(sp)
    8000441a:	e822                	sd	s0,16(sp)
    8000441c:	e426                	sd	s1,8(sp)
    8000441e:	e04a                	sd	s2,0(sp)
    80004420:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004422:	0001d517          	auipc	a0,0x1d
    80004426:	8ae50513          	addi	a0,a0,-1874 # 80020cd0 <log>
    8000442a:	ffffd097          	auipc	ra,0xffffd
    8000442e:	870080e7          	jalr	-1936(ra) # 80000c9a <acquire>
  while(1){
    if(log.committing){
    80004432:	0001d497          	auipc	s1,0x1d
    80004436:	89e48493          	addi	s1,s1,-1890 # 80020cd0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000443a:	4979                	li	s2,30
    8000443c:	a039                	j	8000444a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000443e:	85a6                	mv	a1,s1
    80004440:	8526                	mv	a0,s1
    80004442:	ffffe097          	auipc	ra,0xffffe
    80004446:	e88080e7          	jalr	-376(ra) # 800022ca <sleep>
    if(log.committing){
    8000444a:	50dc                	lw	a5,36(s1)
    8000444c:	fbed                	bnez	a5,8000443e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000444e:	5098                	lw	a4,32(s1)
    80004450:	2705                	addiw	a4,a4,1
    80004452:	0027179b          	slliw	a5,a4,0x2
    80004456:	9fb9                	addw	a5,a5,a4
    80004458:	0017979b          	slliw	a5,a5,0x1
    8000445c:	54d4                	lw	a3,44(s1)
    8000445e:	9fb5                	addw	a5,a5,a3
    80004460:	00f95963          	bge	s2,a5,80004472 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004464:	85a6                	mv	a1,s1
    80004466:	8526                	mv	a0,s1
    80004468:	ffffe097          	auipc	ra,0xffffe
    8000446c:	e62080e7          	jalr	-414(ra) # 800022ca <sleep>
    80004470:	bfe9                	j	8000444a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004472:	0001d517          	auipc	a0,0x1d
    80004476:	85e50513          	addi	a0,a0,-1954 # 80020cd0 <log>
    8000447a:	d118                	sw	a4,32(a0)
      release(&log.lock);
    8000447c:	ffffd097          	auipc	ra,0xffffd
    80004480:	8d2080e7          	jalr	-1838(ra) # 80000d4e <release>
      break;
    }
  }
}
    80004484:	60e2                	ld	ra,24(sp)
    80004486:	6442                	ld	s0,16(sp)
    80004488:	64a2                	ld	s1,8(sp)
    8000448a:	6902                	ld	s2,0(sp)
    8000448c:	6105                	addi	sp,sp,32
    8000448e:	8082                	ret

0000000080004490 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004490:	7139                	addi	sp,sp,-64
    80004492:	fc06                	sd	ra,56(sp)
    80004494:	f822                	sd	s0,48(sp)
    80004496:	f426                	sd	s1,40(sp)
    80004498:	f04a                	sd	s2,32(sp)
    8000449a:	ec4e                	sd	s3,24(sp)
    8000449c:	e852                	sd	s4,16(sp)
    8000449e:	e456                	sd	s5,8(sp)
    800044a0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800044a2:	0001d497          	auipc	s1,0x1d
    800044a6:	82e48493          	addi	s1,s1,-2002 # 80020cd0 <log>
    800044aa:	8526                	mv	a0,s1
    800044ac:	ffffc097          	auipc	ra,0xffffc
    800044b0:	7ee080e7          	jalr	2030(ra) # 80000c9a <acquire>
  log.outstanding -= 1;
    800044b4:	509c                	lw	a5,32(s1)
    800044b6:	37fd                	addiw	a5,a5,-1
    800044b8:	0007891b          	sext.w	s2,a5
    800044bc:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800044be:	50dc                	lw	a5,36(s1)
    800044c0:	e7b9                	bnez	a5,8000450e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800044c2:	04091e63          	bnez	s2,8000451e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800044c6:	0001d497          	auipc	s1,0x1d
    800044ca:	80a48493          	addi	s1,s1,-2038 # 80020cd0 <log>
    800044ce:	4785                	li	a5,1
    800044d0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800044d2:	8526                	mv	a0,s1
    800044d4:	ffffd097          	auipc	ra,0xffffd
    800044d8:	87a080e7          	jalr	-1926(ra) # 80000d4e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800044dc:	54dc                	lw	a5,44(s1)
    800044de:	06f04763          	bgtz	a5,8000454c <end_op+0xbc>
    acquire(&log.lock);
    800044e2:	0001c497          	auipc	s1,0x1c
    800044e6:	7ee48493          	addi	s1,s1,2030 # 80020cd0 <log>
    800044ea:	8526                	mv	a0,s1
    800044ec:	ffffc097          	auipc	ra,0xffffc
    800044f0:	7ae080e7          	jalr	1966(ra) # 80000c9a <acquire>
    log.committing = 0;
    800044f4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800044f8:	8526                	mv	a0,s1
    800044fa:	ffffe097          	auipc	ra,0xffffe
    800044fe:	e34080e7          	jalr	-460(ra) # 8000232e <wakeup>
    release(&log.lock);
    80004502:	8526                	mv	a0,s1
    80004504:	ffffd097          	auipc	ra,0xffffd
    80004508:	84a080e7          	jalr	-1974(ra) # 80000d4e <release>
}
    8000450c:	a03d                	j	8000453a <end_op+0xaa>
    panic("log.committing");
    8000450e:	00004517          	auipc	a0,0x4
    80004512:	2aa50513          	addi	a0,a0,682 # 800087b8 <__func__.0+0x140>
    80004516:	ffffc097          	auipc	ra,0xffffc
    8000451a:	026080e7          	jalr	38(ra) # 8000053c <panic>
    wakeup(&log);
    8000451e:	0001c497          	auipc	s1,0x1c
    80004522:	7b248493          	addi	s1,s1,1970 # 80020cd0 <log>
    80004526:	8526                	mv	a0,s1
    80004528:	ffffe097          	auipc	ra,0xffffe
    8000452c:	e06080e7          	jalr	-506(ra) # 8000232e <wakeup>
  release(&log.lock);
    80004530:	8526                	mv	a0,s1
    80004532:	ffffd097          	auipc	ra,0xffffd
    80004536:	81c080e7          	jalr	-2020(ra) # 80000d4e <release>
}
    8000453a:	70e2                	ld	ra,56(sp)
    8000453c:	7442                	ld	s0,48(sp)
    8000453e:	74a2                	ld	s1,40(sp)
    80004540:	7902                	ld	s2,32(sp)
    80004542:	69e2                	ld	s3,24(sp)
    80004544:	6a42                	ld	s4,16(sp)
    80004546:	6aa2                	ld	s5,8(sp)
    80004548:	6121                	addi	sp,sp,64
    8000454a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000454c:	0001ca97          	auipc	s5,0x1c
    80004550:	7b4a8a93          	addi	s5,s5,1972 # 80020d00 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004554:	0001ca17          	auipc	s4,0x1c
    80004558:	77ca0a13          	addi	s4,s4,1916 # 80020cd0 <log>
    8000455c:	018a2583          	lw	a1,24(s4)
    80004560:	012585bb          	addw	a1,a1,s2
    80004564:	2585                	addiw	a1,a1,1
    80004566:	028a2503          	lw	a0,40(s4)
    8000456a:	fffff097          	auipc	ra,0xfffff
    8000456e:	cf6080e7          	jalr	-778(ra) # 80003260 <bread>
    80004572:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004574:	000aa583          	lw	a1,0(s5)
    80004578:	028a2503          	lw	a0,40(s4)
    8000457c:	fffff097          	auipc	ra,0xfffff
    80004580:	ce4080e7          	jalr	-796(ra) # 80003260 <bread>
    80004584:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004586:	40000613          	li	a2,1024
    8000458a:	05850593          	addi	a1,a0,88
    8000458e:	05848513          	addi	a0,s1,88
    80004592:	ffffd097          	auipc	ra,0xffffd
    80004596:	860080e7          	jalr	-1952(ra) # 80000df2 <memmove>
    bwrite(to);  // write the log
    8000459a:	8526                	mv	a0,s1
    8000459c:	fffff097          	auipc	ra,0xfffff
    800045a0:	db6080e7          	jalr	-586(ra) # 80003352 <bwrite>
    brelse(from);
    800045a4:	854e                	mv	a0,s3
    800045a6:	fffff097          	auipc	ra,0xfffff
    800045aa:	dea080e7          	jalr	-534(ra) # 80003390 <brelse>
    brelse(to);
    800045ae:	8526                	mv	a0,s1
    800045b0:	fffff097          	auipc	ra,0xfffff
    800045b4:	de0080e7          	jalr	-544(ra) # 80003390 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045b8:	2905                	addiw	s2,s2,1
    800045ba:	0a91                	addi	s5,s5,4
    800045bc:	02ca2783          	lw	a5,44(s4)
    800045c0:	f8f94ee3          	blt	s2,a5,8000455c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800045c4:	00000097          	auipc	ra,0x0
    800045c8:	c8c080e7          	jalr	-884(ra) # 80004250 <write_head>
    install_trans(0); // Now install writes to home locations
    800045cc:	4501                	li	a0,0
    800045ce:	00000097          	auipc	ra,0x0
    800045d2:	cec080e7          	jalr	-788(ra) # 800042ba <install_trans>
    log.lh.n = 0;
    800045d6:	0001c797          	auipc	a5,0x1c
    800045da:	7207a323          	sw	zero,1830(a5) # 80020cfc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800045de:	00000097          	auipc	ra,0x0
    800045e2:	c72080e7          	jalr	-910(ra) # 80004250 <write_head>
    800045e6:	bdf5                	j	800044e2 <end_op+0x52>

00000000800045e8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800045e8:	1101                	addi	sp,sp,-32
    800045ea:	ec06                	sd	ra,24(sp)
    800045ec:	e822                	sd	s0,16(sp)
    800045ee:	e426                	sd	s1,8(sp)
    800045f0:	e04a                	sd	s2,0(sp)
    800045f2:	1000                	addi	s0,sp,32
    800045f4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800045f6:	0001c917          	auipc	s2,0x1c
    800045fa:	6da90913          	addi	s2,s2,1754 # 80020cd0 <log>
    800045fe:	854a                	mv	a0,s2
    80004600:	ffffc097          	auipc	ra,0xffffc
    80004604:	69a080e7          	jalr	1690(ra) # 80000c9a <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004608:	02c92603          	lw	a2,44(s2)
    8000460c:	47f5                	li	a5,29
    8000460e:	06c7c563          	blt	a5,a2,80004678 <log_write+0x90>
    80004612:	0001c797          	auipc	a5,0x1c
    80004616:	6da7a783          	lw	a5,1754(a5) # 80020cec <log+0x1c>
    8000461a:	37fd                	addiw	a5,a5,-1
    8000461c:	04f65e63          	bge	a2,a5,80004678 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004620:	0001c797          	auipc	a5,0x1c
    80004624:	6d07a783          	lw	a5,1744(a5) # 80020cf0 <log+0x20>
    80004628:	06f05063          	blez	a5,80004688 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000462c:	4781                	li	a5,0
    8000462e:	06c05563          	blez	a2,80004698 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004632:	44cc                	lw	a1,12(s1)
    80004634:	0001c717          	auipc	a4,0x1c
    80004638:	6cc70713          	addi	a4,a4,1740 # 80020d00 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000463c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000463e:	4314                	lw	a3,0(a4)
    80004640:	04b68c63          	beq	a3,a1,80004698 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004644:	2785                	addiw	a5,a5,1
    80004646:	0711                	addi	a4,a4,4
    80004648:	fef61be3          	bne	a2,a5,8000463e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000464c:	0621                	addi	a2,a2,8
    8000464e:	060a                	slli	a2,a2,0x2
    80004650:	0001c797          	auipc	a5,0x1c
    80004654:	68078793          	addi	a5,a5,1664 # 80020cd0 <log>
    80004658:	97b2                	add	a5,a5,a2
    8000465a:	44d8                	lw	a4,12(s1)
    8000465c:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000465e:	8526                	mv	a0,s1
    80004660:	fffff097          	auipc	ra,0xfffff
    80004664:	dcc080e7          	jalr	-564(ra) # 8000342c <bpin>
    log.lh.n++;
    80004668:	0001c717          	auipc	a4,0x1c
    8000466c:	66870713          	addi	a4,a4,1640 # 80020cd0 <log>
    80004670:	575c                	lw	a5,44(a4)
    80004672:	2785                	addiw	a5,a5,1
    80004674:	d75c                	sw	a5,44(a4)
    80004676:	a82d                	j	800046b0 <log_write+0xc8>
    panic("too big a transaction");
    80004678:	00004517          	auipc	a0,0x4
    8000467c:	15050513          	addi	a0,a0,336 # 800087c8 <__func__.0+0x150>
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	ebc080e7          	jalr	-324(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004688:	00004517          	auipc	a0,0x4
    8000468c:	15850513          	addi	a0,a0,344 # 800087e0 <__func__.0+0x168>
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	eac080e7          	jalr	-340(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004698:	00878693          	addi	a3,a5,8
    8000469c:	068a                	slli	a3,a3,0x2
    8000469e:	0001c717          	auipc	a4,0x1c
    800046a2:	63270713          	addi	a4,a4,1586 # 80020cd0 <log>
    800046a6:	9736                	add	a4,a4,a3
    800046a8:	44d4                	lw	a3,12(s1)
    800046aa:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800046ac:	faf609e3          	beq	a2,a5,8000465e <log_write+0x76>
  }
  release(&log.lock);
    800046b0:	0001c517          	auipc	a0,0x1c
    800046b4:	62050513          	addi	a0,a0,1568 # 80020cd0 <log>
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	696080e7          	jalr	1686(ra) # 80000d4e <release>
}
    800046c0:	60e2                	ld	ra,24(sp)
    800046c2:	6442                	ld	s0,16(sp)
    800046c4:	64a2                	ld	s1,8(sp)
    800046c6:	6902                	ld	s2,0(sp)
    800046c8:	6105                	addi	sp,sp,32
    800046ca:	8082                	ret

00000000800046cc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800046cc:	1101                	addi	sp,sp,-32
    800046ce:	ec06                	sd	ra,24(sp)
    800046d0:	e822                	sd	s0,16(sp)
    800046d2:	e426                	sd	s1,8(sp)
    800046d4:	e04a                	sd	s2,0(sp)
    800046d6:	1000                	addi	s0,sp,32
    800046d8:	84aa                	mv	s1,a0
    800046da:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800046dc:	00004597          	auipc	a1,0x4
    800046e0:	12458593          	addi	a1,a1,292 # 80008800 <__func__.0+0x188>
    800046e4:	0521                	addi	a0,a0,8
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	524080e7          	jalr	1316(ra) # 80000c0a <initlock>
  lk->name = name;
    800046ee:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800046f2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046f6:	0204a423          	sw	zero,40(s1)
}
    800046fa:	60e2                	ld	ra,24(sp)
    800046fc:	6442                	ld	s0,16(sp)
    800046fe:	64a2                	ld	s1,8(sp)
    80004700:	6902                	ld	s2,0(sp)
    80004702:	6105                	addi	sp,sp,32
    80004704:	8082                	ret

0000000080004706 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004706:	1101                	addi	sp,sp,-32
    80004708:	ec06                	sd	ra,24(sp)
    8000470a:	e822                	sd	s0,16(sp)
    8000470c:	e426                	sd	s1,8(sp)
    8000470e:	e04a                	sd	s2,0(sp)
    80004710:	1000                	addi	s0,sp,32
    80004712:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004714:	00850913          	addi	s2,a0,8
    80004718:	854a                	mv	a0,s2
    8000471a:	ffffc097          	auipc	ra,0xffffc
    8000471e:	580080e7          	jalr	1408(ra) # 80000c9a <acquire>
  while (lk->locked) {
    80004722:	409c                	lw	a5,0(s1)
    80004724:	cb89                	beqz	a5,80004736 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004726:	85ca                	mv	a1,s2
    80004728:	8526                	mv	a0,s1
    8000472a:	ffffe097          	auipc	ra,0xffffe
    8000472e:	ba0080e7          	jalr	-1120(ra) # 800022ca <sleep>
  while (lk->locked) {
    80004732:	409c                	lw	a5,0(s1)
    80004734:	fbed                	bnez	a5,80004726 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004736:	4785                	li	a5,1
    80004738:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000473a:	ffffd097          	auipc	ra,0xffffd
    8000473e:	428080e7          	jalr	1064(ra) # 80001b62 <myproc>
    80004742:	591c                	lw	a5,48(a0)
    80004744:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004746:	854a                	mv	a0,s2
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	606080e7          	jalr	1542(ra) # 80000d4e <release>
}
    80004750:	60e2                	ld	ra,24(sp)
    80004752:	6442                	ld	s0,16(sp)
    80004754:	64a2                	ld	s1,8(sp)
    80004756:	6902                	ld	s2,0(sp)
    80004758:	6105                	addi	sp,sp,32
    8000475a:	8082                	ret

000000008000475c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000475c:	1101                	addi	sp,sp,-32
    8000475e:	ec06                	sd	ra,24(sp)
    80004760:	e822                	sd	s0,16(sp)
    80004762:	e426                	sd	s1,8(sp)
    80004764:	e04a                	sd	s2,0(sp)
    80004766:	1000                	addi	s0,sp,32
    80004768:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000476a:	00850913          	addi	s2,a0,8
    8000476e:	854a                	mv	a0,s2
    80004770:	ffffc097          	auipc	ra,0xffffc
    80004774:	52a080e7          	jalr	1322(ra) # 80000c9a <acquire>
  lk->locked = 0;
    80004778:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000477c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004780:	8526                	mv	a0,s1
    80004782:	ffffe097          	auipc	ra,0xffffe
    80004786:	bac080e7          	jalr	-1108(ra) # 8000232e <wakeup>
  release(&lk->lk);
    8000478a:	854a                	mv	a0,s2
    8000478c:	ffffc097          	auipc	ra,0xffffc
    80004790:	5c2080e7          	jalr	1474(ra) # 80000d4e <release>
}
    80004794:	60e2                	ld	ra,24(sp)
    80004796:	6442                	ld	s0,16(sp)
    80004798:	64a2                	ld	s1,8(sp)
    8000479a:	6902                	ld	s2,0(sp)
    8000479c:	6105                	addi	sp,sp,32
    8000479e:	8082                	ret

00000000800047a0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800047a0:	7179                	addi	sp,sp,-48
    800047a2:	f406                	sd	ra,40(sp)
    800047a4:	f022                	sd	s0,32(sp)
    800047a6:	ec26                	sd	s1,24(sp)
    800047a8:	e84a                	sd	s2,16(sp)
    800047aa:	e44e                	sd	s3,8(sp)
    800047ac:	1800                	addi	s0,sp,48
    800047ae:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800047b0:	00850913          	addi	s2,a0,8
    800047b4:	854a                	mv	a0,s2
    800047b6:	ffffc097          	auipc	ra,0xffffc
    800047ba:	4e4080e7          	jalr	1252(ra) # 80000c9a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800047be:	409c                	lw	a5,0(s1)
    800047c0:	ef99                	bnez	a5,800047de <holdingsleep+0x3e>
    800047c2:	4481                	li	s1,0
  release(&lk->lk);
    800047c4:	854a                	mv	a0,s2
    800047c6:	ffffc097          	auipc	ra,0xffffc
    800047ca:	588080e7          	jalr	1416(ra) # 80000d4e <release>
  return r;
}
    800047ce:	8526                	mv	a0,s1
    800047d0:	70a2                	ld	ra,40(sp)
    800047d2:	7402                	ld	s0,32(sp)
    800047d4:	64e2                	ld	s1,24(sp)
    800047d6:	6942                	ld	s2,16(sp)
    800047d8:	69a2                	ld	s3,8(sp)
    800047da:	6145                	addi	sp,sp,48
    800047dc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800047de:	0284a983          	lw	s3,40(s1)
    800047e2:	ffffd097          	auipc	ra,0xffffd
    800047e6:	380080e7          	jalr	896(ra) # 80001b62 <myproc>
    800047ea:	5904                	lw	s1,48(a0)
    800047ec:	413484b3          	sub	s1,s1,s3
    800047f0:	0014b493          	seqz	s1,s1
    800047f4:	bfc1                	j	800047c4 <holdingsleep+0x24>

00000000800047f6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800047f6:	1141                	addi	sp,sp,-16
    800047f8:	e406                	sd	ra,8(sp)
    800047fa:	e022                	sd	s0,0(sp)
    800047fc:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800047fe:	00004597          	auipc	a1,0x4
    80004802:	01258593          	addi	a1,a1,18 # 80008810 <__func__.0+0x198>
    80004806:	0001c517          	auipc	a0,0x1c
    8000480a:	61250513          	addi	a0,a0,1554 # 80020e18 <ftable>
    8000480e:	ffffc097          	auipc	ra,0xffffc
    80004812:	3fc080e7          	jalr	1020(ra) # 80000c0a <initlock>
}
    80004816:	60a2                	ld	ra,8(sp)
    80004818:	6402                	ld	s0,0(sp)
    8000481a:	0141                	addi	sp,sp,16
    8000481c:	8082                	ret

000000008000481e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000481e:	1101                	addi	sp,sp,-32
    80004820:	ec06                	sd	ra,24(sp)
    80004822:	e822                	sd	s0,16(sp)
    80004824:	e426                	sd	s1,8(sp)
    80004826:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004828:	0001c517          	auipc	a0,0x1c
    8000482c:	5f050513          	addi	a0,a0,1520 # 80020e18 <ftable>
    80004830:	ffffc097          	auipc	ra,0xffffc
    80004834:	46a080e7          	jalr	1130(ra) # 80000c9a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004838:	0001c497          	auipc	s1,0x1c
    8000483c:	5f848493          	addi	s1,s1,1528 # 80020e30 <ftable+0x18>
    80004840:	0001d717          	auipc	a4,0x1d
    80004844:	59070713          	addi	a4,a4,1424 # 80021dd0 <disk>
    if(f->ref == 0){
    80004848:	40dc                	lw	a5,4(s1)
    8000484a:	cf99                	beqz	a5,80004868 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000484c:	02848493          	addi	s1,s1,40
    80004850:	fee49ce3          	bne	s1,a4,80004848 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004854:	0001c517          	auipc	a0,0x1c
    80004858:	5c450513          	addi	a0,a0,1476 # 80020e18 <ftable>
    8000485c:	ffffc097          	auipc	ra,0xffffc
    80004860:	4f2080e7          	jalr	1266(ra) # 80000d4e <release>
  return 0;
    80004864:	4481                	li	s1,0
    80004866:	a819                	j	8000487c <filealloc+0x5e>
      f->ref = 1;
    80004868:	4785                	li	a5,1
    8000486a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000486c:	0001c517          	auipc	a0,0x1c
    80004870:	5ac50513          	addi	a0,a0,1452 # 80020e18 <ftable>
    80004874:	ffffc097          	auipc	ra,0xffffc
    80004878:	4da080e7          	jalr	1242(ra) # 80000d4e <release>
}
    8000487c:	8526                	mv	a0,s1
    8000487e:	60e2                	ld	ra,24(sp)
    80004880:	6442                	ld	s0,16(sp)
    80004882:	64a2                	ld	s1,8(sp)
    80004884:	6105                	addi	sp,sp,32
    80004886:	8082                	ret

0000000080004888 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004888:	1101                	addi	sp,sp,-32
    8000488a:	ec06                	sd	ra,24(sp)
    8000488c:	e822                	sd	s0,16(sp)
    8000488e:	e426                	sd	s1,8(sp)
    80004890:	1000                	addi	s0,sp,32
    80004892:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004894:	0001c517          	auipc	a0,0x1c
    80004898:	58450513          	addi	a0,a0,1412 # 80020e18 <ftable>
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	3fe080e7          	jalr	1022(ra) # 80000c9a <acquire>
  if(f->ref < 1)
    800048a4:	40dc                	lw	a5,4(s1)
    800048a6:	02f05263          	blez	a5,800048ca <filedup+0x42>
    panic("filedup");
  f->ref++;
    800048aa:	2785                	addiw	a5,a5,1
    800048ac:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800048ae:	0001c517          	auipc	a0,0x1c
    800048b2:	56a50513          	addi	a0,a0,1386 # 80020e18 <ftable>
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	498080e7          	jalr	1176(ra) # 80000d4e <release>
  return f;
}
    800048be:	8526                	mv	a0,s1
    800048c0:	60e2                	ld	ra,24(sp)
    800048c2:	6442                	ld	s0,16(sp)
    800048c4:	64a2                	ld	s1,8(sp)
    800048c6:	6105                	addi	sp,sp,32
    800048c8:	8082                	ret
    panic("filedup");
    800048ca:	00004517          	auipc	a0,0x4
    800048ce:	f4e50513          	addi	a0,a0,-178 # 80008818 <__func__.0+0x1a0>
    800048d2:	ffffc097          	auipc	ra,0xffffc
    800048d6:	c6a080e7          	jalr	-918(ra) # 8000053c <panic>

00000000800048da <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800048da:	7139                	addi	sp,sp,-64
    800048dc:	fc06                	sd	ra,56(sp)
    800048de:	f822                	sd	s0,48(sp)
    800048e0:	f426                	sd	s1,40(sp)
    800048e2:	f04a                	sd	s2,32(sp)
    800048e4:	ec4e                	sd	s3,24(sp)
    800048e6:	e852                	sd	s4,16(sp)
    800048e8:	e456                	sd	s5,8(sp)
    800048ea:	0080                	addi	s0,sp,64
    800048ec:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800048ee:	0001c517          	auipc	a0,0x1c
    800048f2:	52a50513          	addi	a0,a0,1322 # 80020e18 <ftable>
    800048f6:	ffffc097          	auipc	ra,0xffffc
    800048fa:	3a4080e7          	jalr	932(ra) # 80000c9a <acquire>
  if(f->ref < 1)
    800048fe:	40dc                	lw	a5,4(s1)
    80004900:	06f05163          	blez	a5,80004962 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004904:	37fd                	addiw	a5,a5,-1
    80004906:	0007871b          	sext.w	a4,a5
    8000490a:	c0dc                	sw	a5,4(s1)
    8000490c:	06e04363          	bgtz	a4,80004972 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004910:	0004a903          	lw	s2,0(s1)
    80004914:	0094ca83          	lbu	s5,9(s1)
    80004918:	0104ba03          	ld	s4,16(s1)
    8000491c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004920:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004924:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004928:	0001c517          	auipc	a0,0x1c
    8000492c:	4f050513          	addi	a0,a0,1264 # 80020e18 <ftable>
    80004930:	ffffc097          	auipc	ra,0xffffc
    80004934:	41e080e7          	jalr	1054(ra) # 80000d4e <release>

  if(ff.type == FD_PIPE){
    80004938:	4785                	li	a5,1
    8000493a:	04f90d63          	beq	s2,a5,80004994 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000493e:	3979                	addiw	s2,s2,-2
    80004940:	4785                	li	a5,1
    80004942:	0527e063          	bltu	a5,s2,80004982 <fileclose+0xa8>
    begin_op();
    80004946:	00000097          	auipc	ra,0x0
    8000494a:	ad0080e7          	jalr	-1328(ra) # 80004416 <begin_op>
    iput(ff.ip);
    8000494e:	854e                	mv	a0,s3
    80004950:	fffff097          	auipc	ra,0xfffff
    80004954:	2da080e7          	jalr	730(ra) # 80003c2a <iput>
    end_op();
    80004958:	00000097          	auipc	ra,0x0
    8000495c:	b38080e7          	jalr	-1224(ra) # 80004490 <end_op>
    80004960:	a00d                	j	80004982 <fileclose+0xa8>
    panic("fileclose");
    80004962:	00004517          	auipc	a0,0x4
    80004966:	ebe50513          	addi	a0,a0,-322 # 80008820 <__func__.0+0x1a8>
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	bd2080e7          	jalr	-1070(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004972:	0001c517          	auipc	a0,0x1c
    80004976:	4a650513          	addi	a0,a0,1190 # 80020e18 <ftable>
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	3d4080e7          	jalr	980(ra) # 80000d4e <release>
  }
}
    80004982:	70e2                	ld	ra,56(sp)
    80004984:	7442                	ld	s0,48(sp)
    80004986:	74a2                	ld	s1,40(sp)
    80004988:	7902                	ld	s2,32(sp)
    8000498a:	69e2                	ld	s3,24(sp)
    8000498c:	6a42                	ld	s4,16(sp)
    8000498e:	6aa2                	ld	s5,8(sp)
    80004990:	6121                	addi	sp,sp,64
    80004992:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004994:	85d6                	mv	a1,s5
    80004996:	8552                	mv	a0,s4
    80004998:	00000097          	auipc	ra,0x0
    8000499c:	348080e7          	jalr	840(ra) # 80004ce0 <pipeclose>
    800049a0:	b7cd                	j	80004982 <fileclose+0xa8>

00000000800049a2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800049a2:	715d                	addi	sp,sp,-80
    800049a4:	e486                	sd	ra,72(sp)
    800049a6:	e0a2                	sd	s0,64(sp)
    800049a8:	fc26                	sd	s1,56(sp)
    800049aa:	f84a                	sd	s2,48(sp)
    800049ac:	f44e                	sd	s3,40(sp)
    800049ae:	0880                	addi	s0,sp,80
    800049b0:	84aa                	mv	s1,a0
    800049b2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800049b4:	ffffd097          	auipc	ra,0xffffd
    800049b8:	1ae080e7          	jalr	430(ra) # 80001b62 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800049bc:	409c                	lw	a5,0(s1)
    800049be:	37f9                	addiw	a5,a5,-2
    800049c0:	4705                	li	a4,1
    800049c2:	04f76763          	bltu	a4,a5,80004a10 <filestat+0x6e>
    800049c6:	892a                	mv	s2,a0
    ilock(f->ip);
    800049c8:	6c88                	ld	a0,24(s1)
    800049ca:	fffff097          	auipc	ra,0xfffff
    800049ce:	0a6080e7          	jalr	166(ra) # 80003a70 <ilock>
    stati(f->ip, &st);
    800049d2:	fb840593          	addi	a1,s0,-72
    800049d6:	6c88                	ld	a0,24(s1)
    800049d8:	fffff097          	auipc	ra,0xfffff
    800049dc:	322080e7          	jalr	802(ra) # 80003cfa <stati>
    iunlock(f->ip);
    800049e0:	6c88                	ld	a0,24(s1)
    800049e2:	fffff097          	auipc	ra,0xfffff
    800049e6:	150080e7          	jalr	336(ra) # 80003b32 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800049ea:	46e1                	li	a3,24
    800049ec:	fb840613          	addi	a2,s0,-72
    800049f0:	85ce                	mv	a1,s3
    800049f2:	05093503          	ld	a0,80(s2)
    800049f6:	ffffd097          	auipc	ra,0xffffd
    800049fa:	d38080e7          	jalr	-712(ra) # 8000172e <copyout>
    800049fe:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a02:	60a6                	ld	ra,72(sp)
    80004a04:	6406                	ld	s0,64(sp)
    80004a06:	74e2                	ld	s1,56(sp)
    80004a08:	7942                	ld	s2,48(sp)
    80004a0a:	79a2                	ld	s3,40(sp)
    80004a0c:	6161                	addi	sp,sp,80
    80004a0e:	8082                	ret
  return -1;
    80004a10:	557d                	li	a0,-1
    80004a12:	bfc5                	j	80004a02 <filestat+0x60>

0000000080004a14 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a14:	7179                	addi	sp,sp,-48
    80004a16:	f406                	sd	ra,40(sp)
    80004a18:	f022                	sd	s0,32(sp)
    80004a1a:	ec26                	sd	s1,24(sp)
    80004a1c:	e84a                	sd	s2,16(sp)
    80004a1e:	e44e                	sd	s3,8(sp)
    80004a20:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a22:	00854783          	lbu	a5,8(a0)
    80004a26:	c3d5                	beqz	a5,80004aca <fileread+0xb6>
    80004a28:	84aa                	mv	s1,a0
    80004a2a:	89ae                	mv	s3,a1
    80004a2c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a2e:	411c                	lw	a5,0(a0)
    80004a30:	4705                	li	a4,1
    80004a32:	04e78963          	beq	a5,a4,80004a84 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a36:	470d                	li	a4,3
    80004a38:	04e78d63          	beq	a5,a4,80004a92 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a3c:	4709                	li	a4,2
    80004a3e:	06e79e63          	bne	a5,a4,80004aba <fileread+0xa6>
    ilock(f->ip);
    80004a42:	6d08                	ld	a0,24(a0)
    80004a44:	fffff097          	auipc	ra,0xfffff
    80004a48:	02c080e7          	jalr	44(ra) # 80003a70 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a4c:	874a                	mv	a4,s2
    80004a4e:	5094                	lw	a3,32(s1)
    80004a50:	864e                	mv	a2,s3
    80004a52:	4585                	li	a1,1
    80004a54:	6c88                	ld	a0,24(s1)
    80004a56:	fffff097          	auipc	ra,0xfffff
    80004a5a:	2ce080e7          	jalr	718(ra) # 80003d24 <readi>
    80004a5e:	892a                	mv	s2,a0
    80004a60:	00a05563          	blez	a0,80004a6a <fileread+0x56>
      f->off += r;
    80004a64:	509c                	lw	a5,32(s1)
    80004a66:	9fa9                	addw	a5,a5,a0
    80004a68:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a6a:	6c88                	ld	a0,24(s1)
    80004a6c:	fffff097          	auipc	ra,0xfffff
    80004a70:	0c6080e7          	jalr	198(ra) # 80003b32 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a74:	854a                	mv	a0,s2
    80004a76:	70a2                	ld	ra,40(sp)
    80004a78:	7402                	ld	s0,32(sp)
    80004a7a:	64e2                	ld	s1,24(sp)
    80004a7c:	6942                	ld	s2,16(sp)
    80004a7e:	69a2                	ld	s3,8(sp)
    80004a80:	6145                	addi	sp,sp,48
    80004a82:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a84:	6908                	ld	a0,16(a0)
    80004a86:	00000097          	auipc	ra,0x0
    80004a8a:	3c2080e7          	jalr	962(ra) # 80004e48 <piperead>
    80004a8e:	892a                	mv	s2,a0
    80004a90:	b7d5                	j	80004a74 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a92:	02451783          	lh	a5,36(a0)
    80004a96:	03079693          	slli	a3,a5,0x30
    80004a9a:	92c1                	srli	a3,a3,0x30
    80004a9c:	4725                	li	a4,9
    80004a9e:	02d76863          	bltu	a4,a3,80004ace <fileread+0xba>
    80004aa2:	0792                	slli	a5,a5,0x4
    80004aa4:	0001c717          	auipc	a4,0x1c
    80004aa8:	2d470713          	addi	a4,a4,724 # 80020d78 <devsw>
    80004aac:	97ba                	add	a5,a5,a4
    80004aae:	639c                	ld	a5,0(a5)
    80004ab0:	c38d                	beqz	a5,80004ad2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ab2:	4505                	li	a0,1
    80004ab4:	9782                	jalr	a5
    80004ab6:	892a                	mv	s2,a0
    80004ab8:	bf75                	j	80004a74 <fileread+0x60>
    panic("fileread");
    80004aba:	00004517          	auipc	a0,0x4
    80004abe:	d7650513          	addi	a0,a0,-650 # 80008830 <__func__.0+0x1b8>
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	a7a080e7          	jalr	-1414(ra) # 8000053c <panic>
    return -1;
    80004aca:	597d                	li	s2,-1
    80004acc:	b765                	j	80004a74 <fileread+0x60>
      return -1;
    80004ace:	597d                	li	s2,-1
    80004ad0:	b755                	j	80004a74 <fileread+0x60>
    80004ad2:	597d                	li	s2,-1
    80004ad4:	b745                	j	80004a74 <fileread+0x60>

0000000080004ad6 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004ad6:	00954783          	lbu	a5,9(a0)
    80004ada:	10078e63          	beqz	a5,80004bf6 <filewrite+0x120>
{
    80004ade:	715d                	addi	sp,sp,-80
    80004ae0:	e486                	sd	ra,72(sp)
    80004ae2:	e0a2                	sd	s0,64(sp)
    80004ae4:	fc26                	sd	s1,56(sp)
    80004ae6:	f84a                	sd	s2,48(sp)
    80004ae8:	f44e                	sd	s3,40(sp)
    80004aea:	f052                	sd	s4,32(sp)
    80004aec:	ec56                	sd	s5,24(sp)
    80004aee:	e85a                	sd	s6,16(sp)
    80004af0:	e45e                	sd	s7,8(sp)
    80004af2:	e062                	sd	s8,0(sp)
    80004af4:	0880                	addi	s0,sp,80
    80004af6:	892a                	mv	s2,a0
    80004af8:	8b2e                	mv	s6,a1
    80004afa:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004afc:	411c                	lw	a5,0(a0)
    80004afe:	4705                	li	a4,1
    80004b00:	02e78263          	beq	a5,a4,80004b24 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b04:	470d                	li	a4,3
    80004b06:	02e78563          	beq	a5,a4,80004b30 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b0a:	4709                	li	a4,2
    80004b0c:	0ce79d63          	bne	a5,a4,80004be6 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b10:	0ac05b63          	blez	a2,80004bc6 <filewrite+0xf0>
    int i = 0;
    80004b14:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004b16:	6b85                	lui	s7,0x1
    80004b18:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004b1c:	6c05                	lui	s8,0x1
    80004b1e:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004b22:	a851                	j	80004bb6 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004b24:	6908                	ld	a0,16(a0)
    80004b26:	00000097          	auipc	ra,0x0
    80004b2a:	22a080e7          	jalr	554(ra) # 80004d50 <pipewrite>
    80004b2e:	a045                	j	80004bce <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004b30:	02451783          	lh	a5,36(a0)
    80004b34:	03079693          	slli	a3,a5,0x30
    80004b38:	92c1                	srli	a3,a3,0x30
    80004b3a:	4725                	li	a4,9
    80004b3c:	0ad76f63          	bltu	a4,a3,80004bfa <filewrite+0x124>
    80004b40:	0792                	slli	a5,a5,0x4
    80004b42:	0001c717          	auipc	a4,0x1c
    80004b46:	23670713          	addi	a4,a4,566 # 80020d78 <devsw>
    80004b4a:	97ba                	add	a5,a5,a4
    80004b4c:	679c                	ld	a5,8(a5)
    80004b4e:	cbc5                	beqz	a5,80004bfe <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004b50:	4505                	li	a0,1
    80004b52:	9782                	jalr	a5
    80004b54:	a8ad                	j	80004bce <filewrite+0xf8>
      if(n1 > max)
    80004b56:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004b5a:	00000097          	auipc	ra,0x0
    80004b5e:	8bc080e7          	jalr	-1860(ra) # 80004416 <begin_op>
      ilock(f->ip);
    80004b62:	01893503          	ld	a0,24(s2)
    80004b66:	fffff097          	auipc	ra,0xfffff
    80004b6a:	f0a080e7          	jalr	-246(ra) # 80003a70 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b6e:	8756                	mv	a4,s5
    80004b70:	02092683          	lw	a3,32(s2)
    80004b74:	01698633          	add	a2,s3,s6
    80004b78:	4585                	li	a1,1
    80004b7a:	01893503          	ld	a0,24(s2)
    80004b7e:	fffff097          	auipc	ra,0xfffff
    80004b82:	29e080e7          	jalr	670(ra) # 80003e1c <writei>
    80004b86:	84aa                	mv	s1,a0
    80004b88:	00a05763          	blez	a0,80004b96 <filewrite+0xc0>
        f->off += r;
    80004b8c:	02092783          	lw	a5,32(s2)
    80004b90:	9fa9                	addw	a5,a5,a0
    80004b92:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b96:	01893503          	ld	a0,24(s2)
    80004b9a:	fffff097          	auipc	ra,0xfffff
    80004b9e:	f98080e7          	jalr	-104(ra) # 80003b32 <iunlock>
      end_op();
    80004ba2:	00000097          	auipc	ra,0x0
    80004ba6:	8ee080e7          	jalr	-1810(ra) # 80004490 <end_op>

      if(r != n1){
    80004baa:	009a9f63          	bne	s5,s1,80004bc8 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004bae:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004bb2:	0149db63          	bge	s3,s4,80004bc8 <filewrite+0xf2>
      int n1 = n - i;
    80004bb6:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004bba:	0004879b          	sext.w	a5,s1
    80004bbe:	f8fbdce3          	bge	s7,a5,80004b56 <filewrite+0x80>
    80004bc2:	84e2                	mv	s1,s8
    80004bc4:	bf49                	j	80004b56 <filewrite+0x80>
    int i = 0;
    80004bc6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004bc8:	033a1d63          	bne	s4,s3,80004c02 <filewrite+0x12c>
    80004bcc:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004bce:	60a6                	ld	ra,72(sp)
    80004bd0:	6406                	ld	s0,64(sp)
    80004bd2:	74e2                	ld	s1,56(sp)
    80004bd4:	7942                	ld	s2,48(sp)
    80004bd6:	79a2                	ld	s3,40(sp)
    80004bd8:	7a02                	ld	s4,32(sp)
    80004bda:	6ae2                	ld	s5,24(sp)
    80004bdc:	6b42                	ld	s6,16(sp)
    80004bde:	6ba2                	ld	s7,8(sp)
    80004be0:	6c02                	ld	s8,0(sp)
    80004be2:	6161                	addi	sp,sp,80
    80004be4:	8082                	ret
    panic("filewrite");
    80004be6:	00004517          	auipc	a0,0x4
    80004bea:	c5a50513          	addi	a0,a0,-934 # 80008840 <__func__.0+0x1c8>
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	94e080e7          	jalr	-1714(ra) # 8000053c <panic>
    return -1;
    80004bf6:	557d                	li	a0,-1
}
    80004bf8:	8082                	ret
      return -1;
    80004bfa:	557d                	li	a0,-1
    80004bfc:	bfc9                	j	80004bce <filewrite+0xf8>
    80004bfe:	557d                	li	a0,-1
    80004c00:	b7f9                	j	80004bce <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004c02:	557d                	li	a0,-1
    80004c04:	b7e9                	j	80004bce <filewrite+0xf8>

0000000080004c06 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c06:	7179                	addi	sp,sp,-48
    80004c08:	f406                	sd	ra,40(sp)
    80004c0a:	f022                	sd	s0,32(sp)
    80004c0c:	ec26                	sd	s1,24(sp)
    80004c0e:	e84a                	sd	s2,16(sp)
    80004c10:	e44e                	sd	s3,8(sp)
    80004c12:	e052                	sd	s4,0(sp)
    80004c14:	1800                	addi	s0,sp,48
    80004c16:	84aa                	mv	s1,a0
    80004c18:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c1a:	0005b023          	sd	zero,0(a1)
    80004c1e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c22:	00000097          	auipc	ra,0x0
    80004c26:	bfc080e7          	jalr	-1028(ra) # 8000481e <filealloc>
    80004c2a:	e088                	sd	a0,0(s1)
    80004c2c:	c551                	beqz	a0,80004cb8 <pipealloc+0xb2>
    80004c2e:	00000097          	auipc	ra,0x0
    80004c32:	bf0080e7          	jalr	-1040(ra) # 8000481e <filealloc>
    80004c36:	00aa3023          	sd	a0,0(s4)
    80004c3a:	c92d                	beqz	a0,80004cac <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c3c:	ffffc097          	auipc	ra,0xffffc
    80004c40:	f22080e7          	jalr	-222(ra) # 80000b5e <kalloc>
    80004c44:	892a                	mv	s2,a0
    80004c46:	c125                	beqz	a0,80004ca6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c48:	4985                	li	s3,1
    80004c4a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c4e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c52:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c56:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c5a:	00004597          	auipc	a1,0x4
    80004c5e:	bf658593          	addi	a1,a1,-1034 # 80008850 <__func__.0+0x1d8>
    80004c62:	ffffc097          	auipc	ra,0xffffc
    80004c66:	fa8080e7          	jalr	-88(ra) # 80000c0a <initlock>
  (*f0)->type = FD_PIPE;
    80004c6a:	609c                	ld	a5,0(s1)
    80004c6c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c70:	609c                	ld	a5,0(s1)
    80004c72:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c76:	609c                	ld	a5,0(s1)
    80004c78:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c7c:	609c                	ld	a5,0(s1)
    80004c7e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c82:	000a3783          	ld	a5,0(s4)
    80004c86:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c8a:	000a3783          	ld	a5,0(s4)
    80004c8e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c92:	000a3783          	ld	a5,0(s4)
    80004c96:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c9a:	000a3783          	ld	a5,0(s4)
    80004c9e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ca2:	4501                	li	a0,0
    80004ca4:	a025                	j	80004ccc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ca6:	6088                	ld	a0,0(s1)
    80004ca8:	e501                	bnez	a0,80004cb0 <pipealloc+0xaa>
    80004caa:	a039                	j	80004cb8 <pipealloc+0xb2>
    80004cac:	6088                	ld	a0,0(s1)
    80004cae:	c51d                	beqz	a0,80004cdc <pipealloc+0xd6>
    fileclose(*f0);
    80004cb0:	00000097          	auipc	ra,0x0
    80004cb4:	c2a080e7          	jalr	-982(ra) # 800048da <fileclose>
  if(*f1)
    80004cb8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004cbc:	557d                	li	a0,-1
  if(*f1)
    80004cbe:	c799                	beqz	a5,80004ccc <pipealloc+0xc6>
    fileclose(*f1);
    80004cc0:	853e                	mv	a0,a5
    80004cc2:	00000097          	auipc	ra,0x0
    80004cc6:	c18080e7          	jalr	-1000(ra) # 800048da <fileclose>
  return -1;
    80004cca:	557d                	li	a0,-1
}
    80004ccc:	70a2                	ld	ra,40(sp)
    80004cce:	7402                	ld	s0,32(sp)
    80004cd0:	64e2                	ld	s1,24(sp)
    80004cd2:	6942                	ld	s2,16(sp)
    80004cd4:	69a2                	ld	s3,8(sp)
    80004cd6:	6a02                	ld	s4,0(sp)
    80004cd8:	6145                	addi	sp,sp,48
    80004cda:	8082                	ret
  return -1;
    80004cdc:	557d                	li	a0,-1
    80004cde:	b7fd                	j	80004ccc <pipealloc+0xc6>

0000000080004ce0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ce0:	1101                	addi	sp,sp,-32
    80004ce2:	ec06                	sd	ra,24(sp)
    80004ce4:	e822                	sd	s0,16(sp)
    80004ce6:	e426                	sd	s1,8(sp)
    80004ce8:	e04a                	sd	s2,0(sp)
    80004cea:	1000                	addi	s0,sp,32
    80004cec:	84aa                	mv	s1,a0
    80004cee:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004cf0:	ffffc097          	auipc	ra,0xffffc
    80004cf4:	faa080e7          	jalr	-86(ra) # 80000c9a <acquire>
  if(writable){
    80004cf8:	02090d63          	beqz	s2,80004d32 <pipeclose+0x52>
    pi->writeopen = 0;
    80004cfc:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d00:	21848513          	addi	a0,s1,536
    80004d04:	ffffd097          	auipc	ra,0xffffd
    80004d08:	62a080e7          	jalr	1578(ra) # 8000232e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004d0c:	2204b783          	ld	a5,544(s1)
    80004d10:	eb95                	bnez	a5,80004d44 <pipeclose+0x64>
    release(&pi->lock);
    80004d12:	8526                	mv	a0,s1
    80004d14:	ffffc097          	auipc	ra,0xffffc
    80004d18:	03a080e7          	jalr	58(ra) # 80000d4e <release>
    kfree((char*)pi);
    80004d1c:	8526                	mv	a0,s1
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	cd8080e7          	jalr	-808(ra) # 800009f6 <kfree>
  } else
    release(&pi->lock);
}
    80004d26:	60e2                	ld	ra,24(sp)
    80004d28:	6442                	ld	s0,16(sp)
    80004d2a:	64a2                	ld	s1,8(sp)
    80004d2c:	6902                	ld	s2,0(sp)
    80004d2e:	6105                	addi	sp,sp,32
    80004d30:	8082                	ret
    pi->readopen = 0;
    80004d32:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d36:	21c48513          	addi	a0,s1,540
    80004d3a:	ffffd097          	auipc	ra,0xffffd
    80004d3e:	5f4080e7          	jalr	1524(ra) # 8000232e <wakeup>
    80004d42:	b7e9                	j	80004d0c <pipeclose+0x2c>
    release(&pi->lock);
    80004d44:	8526                	mv	a0,s1
    80004d46:	ffffc097          	auipc	ra,0xffffc
    80004d4a:	008080e7          	jalr	8(ra) # 80000d4e <release>
}
    80004d4e:	bfe1                	j	80004d26 <pipeclose+0x46>

0000000080004d50 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d50:	711d                	addi	sp,sp,-96
    80004d52:	ec86                	sd	ra,88(sp)
    80004d54:	e8a2                	sd	s0,80(sp)
    80004d56:	e4a6                	sd	s1,72(sp)
    80004d58:	e0ca                	sd	s2,64(sp)
    80004d5a:	fc4e                	sd	s3,56(sp)
    80004d5c:	f852                	sd	s4,48(sp)
    80004d5e:	f456                	sd	s5,40(sp)
    80004d60:	f05a                	sd	s6,32(sp)
    80004d62:	ec5e                	sd	s7,24(sp)
    80004d64:	e862                	sd	s8,16(sp)
    80004d66:	1080                	addi	s0,sp,96
    80004d68:	84aa                	mv	s1,a0
    80004d6a:	8aae                	mv	s5,a1
    80004d6c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d6e:	ffffd097          	auipc	ra,0xffffd
    80004d72:	df4080e7          	jalr	-524(ra) # 80001b62 <myproc>
    80004d76:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d78:	8526                	mv	a0,s1
    80004d7a:	ffffc097          	auipc	ra,0xffffc
    80004d7e:	f20080e7          	jalr	-224(ra) # 80000c9a <acquire>
  while(i < n){
    80004d82:	0b405663          	blez	s4,80004e2e <pipewrite+0xde>
  int i = 0;
    80004d86:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d88:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d8a:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d8e:	21c48b93          	addi	s7,s1,540
    80004d92:	a089                	j	80004dd4 <pipewrite+0x84>
      release(&pi->lock);
    80004d94:	8526                	mv	a0,s1
    80004d96:	ffffc097          	auipc	ra,0xffffc
    80004d9a:	fb8080e7          	jalr	-72(ra) # 80000d4e <release>
      return -1;
    80004d9e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004da0:	854a                	mv	a0,s2
    80004da2:	60e6                	ld	ra,88(sp)
    80004da4:	6446                	ld	s0,80(sp)
    80004da6:	64a6                	ld	s1,72(sp)
    80004da8:	6906                	ld	s2,64(sp)
    80004daa:	79e2                	ld	s3,56(sp)
    80004dac:	7a42                	ld	s4,48(sp)
    80004dae:	7aa2                	ld	s5,40(sp)
    80004db0:	7b02                	ld	s6,32(sp)
    80004db2:	6be2                	ld	s7,24(sp)
    80004db4:	6c42                	ld	s8,16(sp)
    80004db6:	6125                	addi	sp,sp,96
    80004db8:	8082                	ret
      wakeup(&pi->nread);
    80004dba:	8562                	mv	a0,s8
    80004dbc:	ffffd097          	auipc	ra,0xffffd
    80004dc0:	572080e7          	jalr	1394(ra) # 8000232e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004dc4:	85a6                	mv	a1,s1
    80004dc6:	855e                	mv	a0,s7
    80004dc8:	ffffd097          	auipc	ra,0xffffd
    80004dcc:	502080e7          	jalr	1282(ra) # 800022ca <sleep>
  while(i < n){
    80004dd0:	07495063          	bge	s2,s4,80004e30 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004dd4:	2204a783          	lw	a5,544(s1)
    80004dd8:	dfd5                	beqz	a5,80004d94 <pipewrite+0x44>
    80004dda:	854e                	mv	a0,s3
    80004ddc:	ffffd097          	auipc	ra,0xffffd
    80004de0:	796080e7          	jalr	1942(ra) # 80002572 <killed>
    80004de4:	f945                	bnez	a0,80004d94 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004de6:	2184a783          	lw	a5,536(s1)
    80004dea:	21c4a703          	lw	a4,540(s1)
    80004dee:	2007879b          	addiw	a5,a5,512
    80004df2:	fcf704e3          	beq	a4,a5,80004dba <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004df6:	4685                	li	a3,1
    80004df8:	01590633          	add	a2,s2,s5
    80004dfc:	faf40593          	addi	a1,s0,-81
    80004e00:	0509b503          	ld	a0,80(s3)
    80004e04:	ffffd097          	auipc	ra,0xffffd
    80004e08:	9b6080e7          	jalr	-1610(ra) # 800017ba <copyin>
    80004e0c:	03650263          	beq	a0,s6,80004e30 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e10:	21c4a783          	lw	a5,540(s1)
    80004e14:	0017871b          	addiw	a4,a5,1
    80004e18:	20e4ae23          	sw	a4,540(s1)
    80004e1c:	1ff7f793          	andi	a5,a5,511
    80004e20:	97a6                	add	a5,a5,s1
    80004e22:	faf44703          	lbu	a4,-81(s0)
    80004e26:	00e78c23          	sb	a4,24(a5)
      i++;
    80004e2a:	2905                	addiw	s2,s2,1
    80004e2c:	b755                	j	80004dd0 <pipewrite+0x80>
  int i = 0;
    80004e2e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004e30:	21848513          	addi	a0,s1,536
    80004e34:	ffffd097          	auipc	ra,0xffffd
    80004e38:	4fa080e7          	jalr	1274(ra) # 8000232e <wakeup>
  release(&pi->lock);
    80004e3c:	8526                	mv	a0,s1
    80004e3e:	ffffc097          	auipc	ra,0xffffc
    80004e42:	f10080e7          	jalr	-240(ra) # 80000d4e <release>
  return i;
    80004e46:	bfa9                	j	80004da0 <pipewrite+0x50>

0000000080004e48 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e48:	715d                	addi	sp,sp,-80
    80004e4a:	e486                	sd	ra,72(sp)
    80004e4c:	e0a2                	sd	s0,64(sp)
    80004e4e:	fc26                	sd	s1,56(sp)
    80004e50:	f84a                	sd	s2,48(sp)
    80004e52:	f44e                	sd	s3,40(sp)
    80004e54:	f052                	sd	s4,32(sp)
    80004e56:	ec56                	sd	s5,24(sp)
    80004e58:	e85a                	sd	s6,16(sp)
    80004e5a:	0880                	addi	s0,sp,80
    80004e5c:	84aa                	mv	s1,a0
    80004e5e:	892e                	mv	s2,a1
    80004e60:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e62:	ffffd097          	auipc	ra,0xffffd
    80004e66:	d00080e7          	jalr	-768(ra) # 80001b62 <myproc>
    80004e6a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e6c:	8526                	mv	a0,s1
    80004e6e:	ffffc097          	auipc	ra,0xffffc
    80004e72:	e2c080e7          	jalr	-468(ra) # 80000c9a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e76:	2184a703          	lw	a4,536(s1)
    80004e7a:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e7e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e82:	02f71763          	bne	a4,a5,80004eb0 <piperead+0x68>
    80004e86:	2244a783          	lw	a5,548(s1)
    80004e8a:	c39d                	beqz	a5,80004eb0 <piperead+0x68>
    if(killed(pr)){
    80004e8c:	8552                	mv	a0,s4
    80004e8e:	ffffd097          	auipc	ra,0xffffd
    80004e92:	6e4080e7          	jalr	1764(ra) # 80002572 <killed>
    80004e96:	e949                	bnez	a0,80004f28 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e98:	85a6                	mv	a1,s1
    80004e9a:	854e                	mv	a0,s3
    80004e9c:	ffffd097          	auipc	ra,0xffffd
    80004ea0:	42e080e7          	jalr	1070(ra) # 800022ca <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ea4:	2184a703          	lw	a4,536(s1)
    80004ea8:	21c4a783          	lw	a5,540(s1)
    80004eac:	fcf70de3          	beq	a4,a5,80004e86 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004eb0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004eb2:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004eb4:	05505463          	blez	s5,80004efc <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004eb8:	2184a783          	lw	a5,536(s1)
    80004ebc:	21c4a703          	lw	a4,540(s1)
    80004ec0:	02f70e63          	beq	a4,a5,80004efc <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ec4:	0017871b          	addiw	a4,a5,1
    80004ec8:	20e4ac23          	sw	a4,536(s1)
    80004ecc:	1ff7f793          	andi	a5,a5,511
    80004ed0:	97a6                	add	a5,a5,s1
    80004ed2:	0187c783          	lbu	a5,24(a5)
    80004ed6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004eda:	4685                	li	a3,1
    80004edc:	fbf40613          	addi	a2,s0,-65
    80004ee0:	85ca                	mv	a1,s2
    80004ee2:	050a3503          	ld	a0,80(s4)
    80004ee6:	ffffd097          	auipc	ra,0xffffd
    80004eea:	848080e7          	jalr	-1976(ra) # 8000172e <copyout>
    80004eee:	01650763          	beq	a0,s6,80004efc <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ef2:	2985                	addiw	s3,s3,1
    80004ef4:	0905                	addi	s2,s2,1
    80004ef6:	fd3a91e3          	bne	s5,s3,80004eb8 <piperead+0x70>
    80004efa:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004efc:	21c48513          	addi	a0,s1,540
    80004f00:	ffffd097          	auipc	ra,0xffffd
    80004f04:	42e080e7          	jalr	1070(ra) # 8000232e <wakeup>
  release(&pi->lock);
    80004f08:	8526                	mv	a0,s1
    80004f0a:	ffffc097          	auipc	ra,0xffffc
    80004f0e:	e44080e7          	jalr	-444(ra) # 80000d4e <release>
  return i;
}
    80004f12:	854e                	mv	a0,s3
    80004f14:	60a6                	ld	ra,72(sp)
    80004f16:	6406                	ld	s0,64(sp)
    80004f18:	74e2                	ld	s1,56(sp)
    80004f1a:	7942                	ld	s2,48(sp)
    80004f1c:	79a2                	ld	s3,40(sp)
    80004f1e:	7a02                	ld	s4,32(sp)
    80004f20:	6ae2                	ld	s5,24(sp)
    80004f22:	6b42                	ld	s6,16(sp)
    80004f24:	6161                	addi	sp,sp,80
    80004f26:	8082                	ret
      release(&pi->lock);
    80004f28:	8526                	mv	a0,s1
    80004f2a:	ffffc097          	auipc	ra,0xffffc
    80004f2e:	e24080e7          	jalr	-476(ra) # 80000d4e <release>
      return -1;
    80004f32:	59fd                	li	s3,-1
    80004f34:	bff9                	j	80004f12 <piperead+0xca>

0000000080004f36 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004f36:	1141                	addi	sp,sp,-16
    80004f38:	e422                	sd	s0,8(sp)
    80004f3a:	0800                	addi	s0,sp,16
    80004f3c:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004f3e:	8905                	andi	a0,a0,1
    80004f40:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004f42:	8b89                	andi	a5,a5,2
    80004f44:	c399                	beqz	a5,80004f4a <flags2perm+0x14>
      perm |= PTE_W;
    80004f46:	00456513          	ori	a0,a0,4
    return perm;
}
    80004f4a:	6422                	ld	s0,8(sp)
    80004f4c:	0141                	addi	sp,sp,16
    80004f4e:	8082                	ret

0000000080004f50 <exec>:

int
exec(char *path, char **argv)
{
    80004f50:	df010113          	addi	sp,sp,-528
    80004f54:	20113423          	sd	ra,520(sp)
    80004f58:	20813023          	sd	s0,512(sp)
    80004f5c:	ffa6                	sd	s1,504(sp)
    80004f5e:	fbca                	sd	s2,496(sp)
    80004f60:	f7ce                	sd	s3,488(sp)
    80004f62:	f3d2                	sd	s4,480(sp)
    80004f64:	efd6                	sd	s5,472(sp)
    80004f66:	ebda                	sd	s6,464(sp)
    80004f68:	e7de                	sd	s7,456(sp)
    80004f6a:	e3e2                	sd	s8,448(sp)
    80004f6c:	ff66                	sd	s9,440(sp)
    80004f6e:	fb6a                	sd	s10,432(sp)
    80004f70:	f76e                	sd	s11,424(sp)
    80004f72:	0c00                	addi	s0,sp,528
    80004f74:	892a                	mv	s2,a0
    80004f76:	dea43c23          	sd	a0,-520(s0)
    80004f7a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f7e:	ffffd097          	auipc	ra,0xffffd
    80004f82:	be4080e7          	jalr	-1052(ra) # 80001b62 <myproc>
    80004f86:	84aa                	mv	s1,a0

  begin_op();
    80004f88:	fffff097          	auipc	ra,0xfffff
    80004f8c:	48e080e7          	jalr	1166(ra) # 80004416 <begin_op>

  if((ip = namei(path)) == 0){
    80004f90:	854a                	mv	a0,s2
    80004f92:	fffff097          	auipc	ra,0xfffff
    80004f96:	284080e7          	jalr	644(ra) # 80004216 <namei>
    80004f9a:	c92d                	beqz	a0,8000500c <exec+0xbc>
    80004f9c:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f9e:	fffff097          	auipc	ra,0xfffff
    80004fa2:	ad2080e7          	jalr	-1326(ra) # 80003a70 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004fa6:	04000713          	li	a4,64
    80004faa:	4681                	li	a3,0
    80004fac:	e5040613          	addi	a2,s0,-432
    80004fb0:	4581                	li	a1,0
    80004fb2:	8552                	mv	a0,s4
    80004fb4:	fffff097          	auipc	ra,0xfffff
    80004fb8:	d70080e7          	jalr	-656(ra) # 80003d24 <readi>
    80004fbc:	04000793          	li	a5,64
    80004fc0:	00f51a63          	bne	a0,a5,80004fd4 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004fc4:	e5042703          	lw	a4,-432(s0)
    80004fc8:	464c47b7          	lui	a5,0x464c4
    80004fcc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004fd0:	04f70463          	beq	a4,a5,80005018 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004fd4:	8552                	mv	a0,s4
    80004fd6:	fffff097          	auipc	ra,0xfffff
    80004fda:	cfc080e7          	jalr	-772(ra) # 80003cd2 <iunlockput>
    end_op();
    80004fde:	fffff097          	auipc	ra,0xfffff
    80004fe2:	4b2080e7          	jalr	1202(ra) # 80004490 <end_op>
  }
  return -1;
    80004fe6:	557d                	li	a0,-1
}
    80004fe8:	20813083          	ld	ra,520(sp)
    80004fec:	20013403          	ld	s0,512(sp)
    80004ff0:	74fe                	ld	s1,504(sp)
    80004ff2:	795e                	ld	s2,496(sp)
    80004ff4:	79be                	ld	s3,488(sp)
    80004ff6:	7a1e                	ld	s4,480(sp)
    80004ff8:	6afe                	ld	s5,472(sp)
    80004ffa:	6b5e                	ld	s6,464(sp)
    80004ffc:	6bbe                	ld	s7,456(sp)
    80004ffe:	6c1e                	ld	s8,448(sp)
    80005000:	7cfa                	ld	s9,440(sp)
    80005002:	7d5a                	ld	s10,432(sp)
    80005004:	7dba                	ld	s11,424(sp)
    80005006:	21010113          	addi	sp,sp,528
    8000500a:	8082                	ret
    end_op();
    8000500c:	fffff097          	auipc	ra,0xfffff
    80005010:	484080e7          	jalr	1156(ra) # 80004490 <end_op>
    return -1;
    80005014:	557d                	li	a0,-1
    80005016:	bfc9                	j	80004fe8 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005018:	8526                	mv	a0,s1
    8000501a:	ffffd097          	auipc	ra,0xffffd
    8000501e:	c0c080e7          	jalr	-1012(ra) # 80001c26 <proc_pagetable>
    80005022:	8b2a                	mv	s6,a0
    80005024:	d945                	beqz	a0,80004fd4 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005026:	e7042d03          	lw	s10,-400(s0)
    8000502a:	e8845783          	lhu	a5,-376(s0)
    8000502e:	10078463          	beqz	a5,80005136 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005032:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005034:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005036:	6c85                	lui	s9,0x1
    80005038:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000503c:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80005040:	6a85                	lui	s5,0x1
    80005042:	a0b5                	j	800050ae <exec+0x15e>
      panic("loadseg: address should exist");
    80005044:	00004517          	auipc	a0,0x4
    80005048:	81450513          	addi	a0,a0,-2028 # 80008858 <__func__.0+0x1e0>
    8000504c:	ffffb097          	auipc	ra,0xffffb
    80005050:	4f0080e7          	jalr	1264(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80005054:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005056:	8726                	mv	a4,s1
    80005058:	012c06bb          	addw	a3,s8,s2
    8000505c:	4581                	li	a1,0
    8000505e:	8552                	mv	a0,s4
    80005060:	fffff097          	auipc	ra,0xfffff
    80005064:	cc4080e7          	jalr	-828(ra) # 80003d24 <readi>
    80005068:	2501                	sext.w	a0,a0
    8000506a:	24a49863          	bne	s1,a0,800052ba <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    8000506e:	012a893b          	addw	s2,s5,s2
    80005072:	03397563          	bgeu	s2,s3,8000509c <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80005076:	02091593          	slli	a1,s2,0x20
    8000507a:	9181                	srli	a1,a1,0x20
    8000507c:	95de                	add	a1,a1,s7
    8000507e:	855a                	mv	a0,s6
    80005080:	ffffc097          	auipc	ra,0xffffc
    80005084:	09e080e7          	jalr	158(ra) # 8000111e <walkaddr>
    80005088:	862a                	mv	a2,a0
    if(pa == 0)
    8000508a:	dd4d                	beqz	a0,80005044 <exec+0xf4>
    if(sz - i < PGSIZE)
    8000508c:	412984bb          	subw	s1,s3,s2
    80005090:	0004879b          	sext.w	a5,s1
    80005094:	fcfcf0e3          	bgeu	s9,a5,80005054 <exec+0x104>
    80005098:	84d6                	mv	s1,s5
    8000509a:	bf6d                	j	80005054 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000509c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050a0:	2d85                	addiw	s11,s11,1
    800050a2:	038d0d1b          	addiw	s10,s10,56
    800050a6:	e8845783          	lhu	a5,-376(s0)
    800050aa:	08fdd763          	bge	s11,a5,80005138 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050ae:	2d01                	sext.w	s10,s10
    800050b0:	03800713          	li	a4,56
    800050b4:	86ea                	mv	a3,s10
    800050b6:	e1840613          	addi	a2,s0,-488
    800050ba:	4581                	li	a1,0
    800050bc:	8552                	mv	a0,s4
    800050be:	fffff097          	auipc	ra,0xfffff
    800050c2:	c66080e7          	jalr	-922(ra) # 80003d24 <readi>
    800050c6:	03800793          	li	a5,56
    800050ca:	1ef51663          	bne	a0,a5,800052b6 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    800050ce:	e1842783          	lw	a5,-488(s0)
    800050d2:	4705                	li	a4,1
    800050d4:	fce796e3          	bne	a5,a4,800050a0 <exec+0x150>
    if(ph.memsz < ph.filesz)
    800050d8:	e4043483          	ld	s1,-448(s0)
    800050dc:	e3843783          	ld	a5,-456(s0)
    800050e0:	1ef4e863          	bltu	s1,a5,800052d0 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050e4:	e2843783          	ld	a5,-472(s0)
    800050e8:	94be                	add	s1,s1,a5
    800050ea:	1ef4e663          	bltu	s1,a5,800052d6 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    800050ee:	df043703          	ld	a4,-528(s0)
    800050f2:	8ff9                	and	a5,a5,a4
    800050f4:	1e079463          	bnez	a5,800052dc <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050f8:	e1c42503          	lw	a0,-484(s0)
    800050fc:	00000097          	auipc	ra,0x0
    80005100:	e3a080e7          	jalr	-454(ra) # 80004f36 <flags2perm>
    80005104:	86aa                	mv	a3,a0
    80005106:	8626                	mv	a2,s1
    80005108:	85ca                	mv	a1,s2
    8000510a:	855a                	mv	a0,s6
    8000510c:	ffffc097          	auipc	ra,0xffffc
    80005110:	3c6080e7          	jalr	966(ra) # 800014d2 <uvmalloc>
    80005114:	e0a43423          	sd	a0,-504(s0)
    80005118:	1c050563          	beqz	a0,800052e2 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000511c:	e2843b83          	ld	s7,-472(s0)
    80005120:	e2042c03          	lw	s8,-480(s0)
    80005124:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005128:	00098463          	beqz	s3,80005130 <exec+0x1e0>
    8000512c:	4901                	li	s2,0
    8000512e:	b7a1                	j	80005076 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005130:	e0843903          	ld	s2,-504(s0)
    80005134:	b7b5                	j	800050a0 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005136:	4901                	li	s2,0
  iunlockput(ip);
    80005138:	8552                	mv	a0,s4
    8000513a:	fffff097          	auipc	ra,0xfffff
    8000513e:	b98080e7          	jalr	-1128(ra) # 80003cd2 <iunlockput>
  end_op();
    80005142:	fffff097          	auipc	ra,0xfffff
    80005146:	34e080e7          	jalr	846(ra) # 80004490 <end_op>
  p = myproc();
    8000514a:	ffffd097          	auipc	ra,0xffffd
    8000514e:	a18080e7          	jalr	-1512(ra) # 80001b62 <myproc>
    80005152:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005154:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005158:	6985                	lui	s3,0x1
    8000515a:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    8000515c:	99ca                	add	s3,s3,s2
    8000515e:	77fd                	lui	a5,0xfffff
    80005160:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005164:	4691                	li	a3,4
    80005166:	6609                	lui	a2,0x2
    80005168:	964e                	add	a2,a2,s3
    8000516a:	85ce                	mv	a1,s3
    8000516c:	855a                	mv	a0,s6
    8000516e:	ffffc097          	auipc	ra,0xffffc
    80005172:	364080e7          	jalr	868(ra) # 800014d2 <uvmalloc>
    80005176:	892a                	mv	s2,a0
    80005178:	e0a43423          	sd	a0,-504(s0)
    8000517c:	e509                	bnez	a0,80005186 <exec+0x236>
  if(pagetable)
    8000517e:	e1343423          	sd	s3,-504(s0)
    80005182:	4a01                	li	s4,0
    80005184:	aa1d                	j	800052ba <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005186:	75f9                	lui	a1,0xffffe
    80005188:	95aa                	add	a1,a1,a0
    8000518a:	855a                	mv	a0,s6
    8000518c:	ffffc097          	auipc	ra,0xffffc
    80005190:	570080e7          	jalr	1392(ra) # 800016fc <uvmclear>
  stackbase = sp - PGSIZE;
    80005194:	7bfd                	lui	s7,0xfffff
    80005196:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80005198:	e0043783          	ld	a5,-512(s0)
    8000519c:	6388                	ld	a0,0(a5)
    8000519e:	c52d                	beqz	a0,80005208 <exec+0x2b8>
    800051a0:	e9040993          	addi	s3,s0,-368
    800051a4:	f9040c13          	addi	s8,s0,-112
    800051a8:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800051aa:	ffffc097          	auipc	ra,0xffffc
    800051ae:	d66080e7          	jalr	-666(ra) # 80000f10 <strlen>
    800051b2:	0015079b          	addiw	a5,a0,1
    800051b6:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051ba:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800051be:	13796563          	bltu	s2,s7,800052e8 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051c2:	e0043d03          	ld	s10,-512(s0)
    800051c6:	000d3a03          	ld	s4,0(s10)
    800051ca:	8552                	mv	a0,s4
    800051cc:	ffffc097          	auipc	ra,0xffffc
    800051d0:	d44080e7          	jalr	-700(ra) # 80000f10 <strlen>
    800051d4:	0015069b          	addiw	a3,a0,1
    800051d8:	8652                	mv	a2,s4
    800051da:	85ca                	mv	a1,s2
    800051dc:	855a                	mv	a0,s6
    800051de:	ffffc097          	auipc	ra,0xffffc
    800051e2:	550080e7          	jalr	1360(ra) # 8000172e <copyout>
    800051e6:	10054363          	bltz	a0,800052ec <exec+0x39c>
    ustack[argc] = sp;
    800051ea:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051ee:	0485                	addi	s1,s1,1
    800051f0:	008d0793          	addi	a5,s10,8
    800051f4:	e0f43023          	sd	a5,-512(s0)
    800051f8:	008d3503          	ld	a0,8(s10)
    800051fc:	c909                	beqz	a0,8000520e <exec+0x2be>
    if(argc >= MAXARG)
    800051fe:	09a1                	addi	s3,s3,8
    80005200:	fb8995e3          	bne	s3,s8,800051aa <exec+0x25a>
  ip = 0;
    80005204:	4a01                	li	s4,0
    80005206:	a855                	j	800052ba <exec+0x36a>
  sp = sz;
    80005208:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    8000520c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000520e:	00349793          	slli	a5,s1,0x3
    80005212:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdd080>
    80005216:	97a2                	add	a5,a5,s0
    80005218:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000521c:	00148693          	addi	a3,s1,1
    80005220:	068e                	slli	a3,a3,0x3
    80005222:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005226:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    8000522a:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    8000522e:	f57968e3          	bltu	s2,s7,8000517e <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005232:	e9040613          	addi	a2,s0,-368
    80005236:	85ca                	mv	a1,s2
    80005238:	855a                	mv	a0,s6
    8000523a:	ffffc097          	auipc	ra,0xffffc
    8000523e:	4f4080e7          	jalr	1268(ra) # 8000172e <copyout>
    80005242:	0a054763          	bltz	a0,800052f0 <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005246:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    8000524a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000524e:	df843783          	ld	a5,-520(s0)
    80005252:	0007c703          	lbu	a4,0(a5)
    80005256:	cf11                	beqz	a4,80005272 <exec+0x322>
    80005258:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000525a:	02f00693          	li	a3,47
    8000525e:	a039                	j	8000526c <exec+0x31c>
      last = s+1;
    80005260:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005264:	0785                	addi	a5,a5,1
    80005266:	fff7c703          	lbu	a4,-1(a5)
    8000526a:	c701                	beqz	a4,80005272 <exec+0x322>
    if(*s == '/')
    8000526c:	fed71ce3          	bne	a4,a3,80005264 <exec+0x314>
    80005270:	bfc5                	j	80005260 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80005272:	4641                	li	a2,16
    80005274:	df843583          	ld	a1,-520(s0)
    80005278:	158a8513          	addi	a0,s5,344
    8000527c:	ffffc097          	auipc	ra,0xffffc
    80005280:	c62080e7          	jalr	-926(ra) # 80000ede <safestrcpy>
  oldpagetable = p->pagetable;
    80005284:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005288:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    8000528c:	e0843783          	ld	a5,-504(s0)
    80005290:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005294:	058ab783          	ld	a5,88(s5)
    80005298:	e6843703          	ld	a4,-408(s0)
    8000529c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000529e:	058ab783          	ld	a5,88(s5)
    800052a2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800052a6:	85e6                	mv	a1,s9
    800052a8:	ffffd097          	auipc	ra,0xffffd
    800052ac:	a1a080e7          	jalr	-1510(ra) # 80001cc2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800052b0:	0004851b          	sext.w	a0,s1
    800052b4:	bb15                	j	80004fe8 <exec+0x98>
    800052b6:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800052ba:	e0843583          	ld	a1,-504(s0)
    800052be:	855a                	mv	a0,s6
    800052c0:	ffffd097          	auipc	ra,0xffffd
    800052c4:	a02080e7          	jalr	-1534(ra) # 80001cc2 <proc_freepagetable>
  return -1;
    800052c8:	557d                	li	a0,-1
  if(ip){
    800052ca:	d00a0fe3          	beqz	s4,80004fe8 <exec+0x98>
    800052ce:	b319                	j	80004fd4 <exec+0x84>
    800052d0:	e1243423          	sd	s2,-504(s0)
    800052d4:	b7dd                	j	800052ba <exec+0x36a>
    800052d6:	e1243423          	sd	s2,-504(s0)
    800052da:	b7c5                	j	800052ba <exec+0x36a>
    800052dc:	e1243423          	sd	s2,-504(s0)
    800052e0:	bfe9                	j	800052ba <exec+0x36a>
    800052e2:	e1243423          	sd	s2,-504(s0)
    800052e6:	bfd1                	j	800052ba <exec+0x36a>
  ip = 0;
    800052e8:	4a01                	li	s4,0
    800052ea:	bfc1                	j	800052ba <exec+0x36a>
    800052ec:	4a01                	li	s4,0
  if(pagetable)
    800052ee:	b7f1                	j	800052ba <exec+0x36a>
  sz = sz1;
    800052f0:	e0843983          	ld	s3,-504(s0)
    800052f4:	b569                	j	8000517e <exec+0x22e>

00000000800052f6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052f6:	7179                	addi	sp,sp,-48
    800052f8:	f406                	sd	ra,40(sp)
    800052fa:	f022                	sd	s0,32(sp)
    800052fc:	ec26                	sd	s1,24(sp)
    800052fe:	e84a                	sd	s2,16(sp)
    80005300:	1800                	addi	s0,sp,48
    80005302:	892e                	mv	s2,a1
    80005304:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005306:	fdc40593          	addi	a1,s0,-36
    8000530a:	ffffe097          	auipc	ra,0xffffe
    8000530e:	b14080e7          	jalr	-1260(ra) # 80002e1e <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005312:	fdc42703          	lw	a4,-36(s0)
    80005316:	47bd                	li	a5,15
    80005318:	02e7eb63          	bltu	a5,a4,8000534e <argfd+0x58>
    8000531c:	ffffd097          	auipc	ra,0xffffd
    80005320:	846080e7          	jalr	-1978(ra) # 80001b62 <myproc>
    80005324:	fdc42703          	lw	a4,-36(s0)
    80005328:	01a70793          	addi	a5,a4,26
    8000532c:	078e                	slli	a5,a5,0x3
    8000532e:	953e                	add	a0,a0,a5
    80005330:	611c                	ld	a5,0(a0)
    80005332:	c385                	beqz	a5,80005352 <argfd+0x5c>
    return -1;
  if(pfd)
    80005334:	00090463          	beqz	s2,8000533c <argfd+0x46>
    *pfd = fd;
    80005338:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000533c:	4501                	li	a0,0
  if(pf)
    8000533e:	c091                	beqz	s1,80005342 <argfd+0x4c>
    *pf = f;
    80005340:	e09c                	sd	a5,0(s1)
}
    80005342:	70a2                	ld	ra,40(sp)
    80005344:	7402                	ld	s0,32(sp)
    80005346:	64e2                	ld	s1,24(sp)
    80005348:	6942                	ld	s2,16(sp)
    8000534a:	6145                	addi	sp,sp,48
    8000534c:	8082                	ret
    return -1;
    8000534e:	557d                	li	a0,-1
    80005350:	bfcd                	j	80005342 <argfd+0x4c>
    80005352:	557d                	li	a0,-1
    80005354:	b7fd                	j	80005342 <argfd+0x4c>

0000000080005356 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005356:	1101                	addi	sp,sp,-32
    80005358:	ec06                	sd	ra,24(sp)
    8000535a:	e822                	sd	s0,16(sp)
    8000535c:	e426                	sd	s1,8(sp)
    8000535e:	1000                	addi	s0,sp,32
    80005360:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005362:	ffffd097          	auipc	ra,0xffffd
    80005366:	800080e7          	jalr	-2048(ra) # 80001b62 <myproc>
    8000536a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000536c:	0d050793          	addi	a5,a0,208
    80005370:	4501                	li	a0,0
    80005372:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005374:	6398                	ld	a4,0(a5)
    80005376:	cb19                	beqz	a4,8000538c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005378:	2505                	addiw	a0,a0,1
    8000537a:	07a1                	addi	a5,a5,8
    8000537c:	fed51ce3          	bne	a0,a3,80005374 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005380:	557d                	li	a0,-1
}
    80005382:	60e2                	ld	ra,24(sp)
    80005384:	6442                	ld	s0,16(sp)
    80005386:	64a2                	ld	s1,8(sp)
    80005388:	6105                	addi	sp,sp,32
    8000538a:	8082                	ret
      p->ofile[fd] = f;
    8000538c:	01a50793          	addi	a5,a0,26
    80005390:	078e                	slli	a5,a5,0x3
    80005392:	963e                	add	a2,a2,a5
    80005394:	e204                	sd	s1,0(a2)
      return fd;
    80005396:	b7f5                	j	80005382 <fdalloc+0x2c>

0000000080005398 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005398:	715d                	addi	sp,sp,-80
    8000539a:	e486                	sd	ra,72(sp)
    8000539c:	e0a2                	sd	s0,64(sp)
    8000539e:	fc26                	sd	s1,56(sp)
    800053a0:	f84a                	sd	s2,48(sp)
    800053a2:	f44e                	sd	s3,40(sp)
    800053a4:	f052                	sd	s4,32(sp)
    800053a6:	ec56                	sd	s5,24(sp)
    800053a8:	e85a                	sd	s6,16(sp)
    800053aa:	0880                	addi	s0,sp,80
    800053ac:	8b2e                	mv	s6,a1
    800053ae:	89b2                	mv	s3,a2
    800053b0:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800053b2:	fb040593          	addi	a1,s0,-80
    800053b6:	fffff097          	auipc	ra,0xfffff
    800053ba:	e7e080e7          	jalr	-386(ra) # 80004234 <nameiparent>
    800053be:	84aa                	mv	s1,a0
    800053c0:	14050b63          	beqz	a0,80005516 <create+0x17e>
    return 0;

  ilock(dp);
    800053c4:	ffffe097          	auipc	ra,0xffffe
    800053c8:	6ac080e7          	jalr	1708(ra) # 80003a70 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800053cc:	4601                	li	a2,0
    800053ce:	fb040593          	addi	a1,s0,-80
    800053d2:	8526                	mv	a0,s1
    800053d4:	fffff097          	auipc	ra,0xfffff
    800053d8:	b80080e7          	jalr	-1152(ra) # 80003f54 <dirlookup>
    800053dc:	8aaa                	mv	s5,a0
    800053de:	c921                	beqz	a0,8000542e <create+0x96>
    iunlockput(dp);
    800053e0:	8526                	mv	a0,s1
    800053e2:	fffff097          	auipc	ra,0xfffff
    800053e6:	8f0080e7          	jalr	-1808(ra) # 80003cd2 <iunlockput>
    ilock(ip);
    800053ea:	8556                	mv	a0,s5
    800053ec:	ffffe097          	auipc	ra,0xffffe
    800053f0:	684080e7          	jalr	1668(ra) # 80003a70 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053f4:	4789                	li	a5,2
    800053f6:	02fb1563          	bne	s6,a5,80005420 <create+0x88>
    800053fa:	044ad783          	lhu	a5,68(s5)
    800053fe:	37f9                	addiw	a5,a5,-2
    80005400:	17c2                	slli	a5,a5,0x30
    80005402:	93c1                	srli	a5,a5,0x30
    80005404:	4705                	li	a4,1
    80005406:	00f76d63          	bltu	a4,a5,80005420 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000540a:	8556                	mv	a0,s5
    8000540c:	60a6                	ld	ra,72(sp)
    8000540e:	6406                	ld	s0,64(sp)
    80005410:	74e2                	ld	s1,56(sp)
    80005412:	7942                	ld	s2,48(sp)
    80005414:	79a2                	ld	s3,40(sp)
    80005416:	7a02                	ld	s4,32(sp)
    80005418:	6ae2                	ld	s5,24(sp)
    8000541a:	6b42                	ld	s6,16(sp)
    8000541c:	6161                	addi	sp,sp,80
    8000541e:	8082                	ret
    iunlockput(ip);
    80005420:	8556                	mv	a0,s5
    80005422:	fffff097          	auipc	ra,0xfffff
    80005426:	8b0080e7          	jalr	-1872(ra) # 80003cd2 <iunlockput>
    return 0;
    8000542a:	4a81                	li	s5,0
    8000542c:	bff9                	j	8000540a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000542e:	85da                	mv	a1,s6
    80005430:	4088                	lw	a0,0(s1)
    80005432:	ffffe097          	auipc	ra,0xffffe
    80005436:	4a6080e7          	jalr	1190(ra) # 800038d8 <ialloc>
    8000543a:	8a2a                	mv	s4,a0
    8000543c:	c529                	beqz	a0,80005486 <create+0xee>
  ilock(ip);
    8000543e:	ffffe097          	auipc	ra,0xffffe
    80005442:	632080e7          	jalr	1586(ra) # 80003a70 <ilock>
  ip->major = major;
    80005446:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000544a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000544e:	4905                	li	s2,1
    80005450:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005454:	8552                	mv	a0,s4
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	54e080e7          	jalr	1358(ra) # 800039a4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000545e:	032b0b63          	beq	s6,s2,80005494 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005462:	004a2603          	lw	a2,4(s4)
    80005466:	fb040593          	addi	a1,s0,-80
    8000546a:	8526                	mv	a0,s1
    8000546c:	fffff097          	auipc	ra,0xfffff
    80005470:	cf8080e7          	jalr	-776(ra) # 80004164 <dirlink>
    80005474:	06054f63          	bltz	a0,800054f2 <create+0x15a>
  iunlockput(dp);
    80005478:	8526                	mv	a0,s1
    8000547a:	fffff097          	auipc	ra,0xfffff
    8000547e:	858080e7          	jalr	-1960(ra) # 80003cd2 <iunlockput>
  return ip;
    80005482:	8ad2                	mv	s5,s4
    80005484:	b759                	j	8000540a <create+0x72>
    iunlockput(dp);
    80005486:	8526                	mv	a0,s1
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	84a080e7          	jalr	-1974(ra) # 80003cd2 <iunlockput>
    return 0;
    80005490:	8ad2                	mv	s5,s4
    80005492:	bfa5                	j	8000540a <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005494:	004a2603          	lw	a2,4(s4)
    80005498:	00003597          	auipc	a1,0x3
    8000549c:	3e058593          	addi	a1,a1,992 # 80008878 <__func__.0+0x200>
    800054a0:	8552                	mv	a0,s4
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	cc2080e7          	jalr	-830(ra) # 80004164 <dirlink>
    800054aa:	04054463          	bltz	a0,800054f2 <create+0x15a>
    800054ae:	40d0                	lw	a2,4(s1)
    800054b0:	00003597          	auipc	a1,0x3
    800054b4:	3d058593          	addi	a1,a1,976 # 80008880 <__func__.0+0x208>
    800054b8:	8552                	mv	a0,s4
    800054ba:	fffff097          	auipc	ra,0xfffff
    800054be:	caa080e7          	jalr	-854(ra) # 80004164 <dirlink>
    800054c2:	02054863          	bltz	a0,800054f2 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    800054c6:	004a2603          	lw	a2,4(s4)
    800054ca:	fb040593          	addi	a1,s0,-80
    800054ce:	8526                	mv	a0,s1
    800054d0:	fffff097          	auipc	ra,0xfffff
    800054d4:	c94080e7          	jalr	-876(ra) # 80004164 <dirlink>
    800054d8:	00054d63          	bltz	a0,800054f2 <create+0x15a>
    dp->nlink++;  // for ".."
    800054dc:	04a4d783          	lhu	a5,74(s1)
    800054e0:	2785                	addiw	a5,a5,1
    800054e2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800054e6:	8526                	mv	a0,s1
    800054e8:	ffffe097          	auipc	ra,0xffffe
    800054ec:	4bc080e7          	jalr	1212(ra) # 800039a4 <iupdate>
    800054f0:	b761                	j	80005478 <create+0xe0>
  ip->nlink = 0;
    800054f2:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800054f6:	8552                	mv	a0,s4
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	4ac080e7          	jalr	1196(ra) # 800039a4 <iupdate>
  iunlockput(ip);
    80005500:	8552                	mv	a0,s4
    80005502:	ffffe097          	auipc	ra,0xffffe
    80005506:	7d0080e7          	jalr	2000(ra) # 80003cd2 <iunlockput>
  iunlockput(dp);
    8000550a:	8526                	mv	a0,s1
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	7c6080e7          	jalr	1990(ra) # 80003cd2 <iunlockput>
  return 0;
    80005514:	bddd                	j	8000540a <create+0x72>
    return 0;
    80005516:	8aaa                	mv	s5,a0
    80005518:	bdcd                	j	8000540a <create+0x72>

000000008000551a <sys_dup>:
{
    8000551a:	7179                	addi	sp,sp,-48
    8000551c:	f406                	sd	ra,40(sp)
    8000551e:	f022                	sd	s0,32(sp)
    80005520:	ec26                	sd	s1,24(sp)
    80005522:	e84a                	sd	s2,16(sp)
    80005524:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005526:	fd840613          	addi	a2,s0,-40
    8000552a:	4581                	li	a1,0
    8000552c:	4501                	li	a0,0
    8000552e:	00000097          	auipc	ra,0x0
    80005532:	dc8080e7          	jalr	-568(ra) # 800052f6 <argfd>
    return -1;
    80005536:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005538:	02054363          	bltz	a0,8000555e <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000553c:	fd843903          	ld	s2,-40(s0)
    80005540:	854a                	mv	a0,s2
    80005542:	00000097          	auipc	ra,0x0
    80005546:	e14080e7          	jalr	-492(ra) # 80005356 <fdalloc>
    8000554a:	84aa                	mv	s1,a0
    return -1;
    8000554c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000554e:	00054863          	bltz	a0,8000555e <sys_dup+0x44>
  filedup(f);
    80005552:	854a                	mv	a0,s2
    80005554:	fffff097          	auipc	ra,0xfffff
    80005558:	334080e7          	jalr	820(ra) # 80004888 <filedup>
  return fd;
    8000555c:	87a6                	mv	a5,s1
}
    8000555e:	853e                	mv	a0,a5
    80005560:	70a2                	ld	ra,40(sp)
    80005562:	7402                	ld	s0,32(sp)
    80005564:	64e2                	ld	s1,24(sp)
    80005566:	6942                	ld	s2,16(sp)
    80005568:	6145                	addi	sp,sp,48
    8000556a:	8082                	ret

000000008000556c <sys_read>:
{
    8000556c:	7179                	addi	sp,sp,-48
    8000556e:	f406                	sd	ra,40(sp)
    80005570:	f022                	sd	s0,32(sp)
    80005572:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005574:	fd840593          	addi	a1,s0,-40
    80005578:	4505                	li	a0,1
    8000557a:	ffffe097          	auipc	ra,0xffffe
    8000557e:	8c4080e7          	jalr	-1852(ra) # 80002e3e <argaddr>
  argint(2, &n);
    80005582:	fe440593          	addi	a1,s0,-28
    80005586:	4509                	li	a0,2
    80005588:	ffffe097          	auipc	ra,0xffffe
    8000558c:	896080e7          	jalr	-1898(ra) # 80002e1e <argint>
  if(argfd(0, 0, &f) < 0)
    80005590:	fe840613          	addi	a2,s0,-24
    80005594:	4581                	li	a1,0
    80005596:	4501                	li	a0,0
    80005598:	00000097          	auipc	ra,0x0
    8000559c:	d5e080e7          	jalr	-674(ra) # 800052f6 <argfd>
    800055a0:	87aa                	mv	a5,a0
    return -1;
    800055a2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055a4:	0007cc63          	bltz	a5,800055bc <sys_read+0x50>
  return fileread(f, p, n);
    800055a8:	fe442603          	lw	a2,-28(s0)
    800055ac:	fd843583          	ld	a1,-40(s0)
    800055b0:	fe843503          	ld	a0,-24(s0)
    800055b4:	fffff097          	auipc	ra,0xfffff
    800055b8:	460080e7          	jalr	1120(ra) # 80004a14 <fileread>
}
    800055bc:	70a2                	ld	ra,40(sp)
    800055be:	7402                	ld	s0,32(sp)
    800055c0:	6145                	addi	sp,sp,48
    800055c2:	8082                	ret

00000000800055c4 <sys_write>:
{
    800055c4:	7179                	addi	sp,sp,-48
    800055c6:	f406                	sd	ra,40(sp)
    800055c8:	f022                	sd	s0,32(sp)
    800055ca:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800055cc:	fd840593          	addi	a1,s0,-40
    800055d0:	4505                	li	a0,1
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	86c080e7          	jalr	-1940(ra) # 80002e3e <argaddr>
  argint(2, &n);
    800055da:	fe440593          	addi	a1,s0,-28
    800055de:	4509                	li	a0,2
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	83e080e7          	jalr	-1986(ra) # 80002e1e <argint>
  if(argfd(0, 0, &f) < 0)
    800055e8:	fe840613          	addi	a2,s0,-24
    800055ec:	4581                	li	a1,0
    800055ee:	4501                	li	a0,0
    800055f0:	00000097          	auipc	ra,0x0
    800055f4:	d06080e7          	jalr	-762(ra) # 800052f6 <argfd>
    800055f8:	87aa                	mv	a5,a0
    return -1;
    800055fa:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055fc:	0007cc63          	bltz	a5,80005614 <sys_write+0x50>
  return filewrite(f, p, n);
    80005600:	fe442603          	lw	a2,-28(s0)
    80005604:	fd843583          	ld	a1,-40(s0)
    80005608:	fe843503          	ld	a0,-24(s0)
    8000560c:	fffff097          	auipc	ra,0xfffff
    80005610:	4ca080e7          	jalr	1226(ra) # 80004ad6 <filewrite>
}
    80005614:	70a2                	ld	ra,40(sp)
    80005616:	7402                	ld	s0,32(sp)
    80005618:	6145                	addi	sp,sp,48
    8000561a:	8082                	ret

000000008000561c <sys_close>:
{
    8000561c:	1101                	addi	sp,sp,-32
    8000561e:	ec06                	sd	ra,24(sp)
    80005620:	e822                	sd	s0,16(sp)
    80005622:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005624:	fe040613          	addi	a2,s0,-32
    80005628:	fec40593          	addi	a1,s0,-20
    8000562c:	4501                	li	a0,0
    8000562e:	00000097          	auipc	ra,0x0
    80005632:	cc8080e7          	jalr	-824(ra) # 800052f6 <argfd>
    return -1;
    80005636:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005638:	02054463          	bltz	a0,80005660 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000563c:	ffffc097          	auipc	ra,0xffffc
    80005640:	526080e7          	jalr	1318(ra) # 80001b62 <myproc>
    80005644:	fec42783          	lw	a5,-20(s0)
    80005648:	07e9                	addi	a5,a5,26
    8000564a:	078e                	slli	a5,a5,0x3
    8000564c:	953e                	add	a0,a0,a5
    8000564e:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005652:	fe043503          	ld	a0,-32(s0)
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	284080e7          	jalr	644(ra) # 800048da <fileclose>
  return 0;
    8000565e:	4781                	li	a5,0
}
    80005660:	853e                	mv	a0,a5
    80005662:	60e2                	ld	ra,24(sp)
    80005664:	6442                	ld	s0,16(sp)
    80005666:	6105                	addi	sp,sp,32
    80005668:	8082                	ret

000000008000566a <sys_fstat>:
{
    8000566a:	1101                	addi	sp,sp,-32
    8000566c:	ec06                	sd	ra,24(sp)
    8000566e:	e822                	sd	s0,16(sp)
    80005670:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005672:	fe040593          	addi	a1,s0,-32
    80005676:	4505                	li	a0,1
    80005678:	ffffd097          	auipc	ra,0xffffd
    8000567c:	7c6080e7          	jalr	1990(ra) # 80002e3e <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005680:	fe840613          	addi	a2,s0,-24
    80005684:	4581                	li	a1,0
    80005686:	4501                	li	a0,0
    80005688:	00000097          	auipc	ra,0x0
    8000568c:	c6e080e7          	jalr	-914(ra) # 800052f6 <argfd>
    80005690:	87aa                	mv	a5,a0
    return -1;
    80005692:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005694:	0007ca63          	bltz	a5,800056a8 <sys_fstat+0x3e>
  return filestat(f, st);
    80005698:	fe043583          	ld	a1,-32(s0)
    8000569c:	fe843503          	ld	a0,-24(s0)
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	302080e7          	jalr	770(ra) # 800049a2 <filestat>
}
    800056a8:	60e2                	ld	ra,24(sp)
    800056aa:	6442                	ld	s0,16(sp)
    800056ac:	6105                	addi	sp,sp,32
    800056ae:	8082                	ret

00000000800056b0 <sys_link>:
{
    800056b0:	7169                	addi	sp,sp,-304
    800056b2:	f606                	sd	ra,296(sp)
    800056b4:	f222                	sd	s0,288(sp)
    800056b6:	ee26                	sd	s1,280(sp)
    800056b8:	ea4a                	sd	s2,272(sp)
    800056ba:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056bc:	08000613          	li	a2,128
    800056c0:	ed040593          	addi	a1,s0,-304
    800056c4:	4501                	li	a0,0
    800056c6:	ffffd097          	auipc	ra,0xffffd
    800056ca:	798080e7          	jalr	1944(ra) # 80002e5e <argstr>
    return -1;
    800056ce:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056d0:	10054e63          	bltz	a0,800057ec <sys_link+0x13c>
    800056d4:	08000613          	li	a2,128
    800056d8:	f5040593          	addi	a1,s0,-176
    800056dc:	4505                	li	a0,1
    800056de:	ffffd097          	auipc	ra,0xffffd
    800056e2:	780080e7          	jalr	1920(ra) # 80002e5e <argstr>
    return -1;
    800056e6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056e8:	10054263          	bltz	a0,800057ec <sys_link+0x13c>
  begin_op();
    800056ec:	fffff097          	auipc	ra,0xfffff
    800056f0:	d2a080e7          	jalr	-726(ra) # 80004416 <begin_op>
  if((ip = namei(old)) == 0){
    800056f4:	ed040513          	addi	a0,s0,-304
    800056f8:	fffff097          	auipc	ra,0xfffff
    800056fc:	b1e080e7          	jalr	-1250(ra) # 80004216 <namei>
    80005700:	84aa                	mv	s1,a0
    80005702:	c551                	beqz	a0,8000578e <sys_link+0xde>
  ilock(ip);
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	36c080e7          	jalr	876(ra) # 80003a70 <ilock>
  if(ip->type == T_DIR){
    8000570c:	04449703          	lh	a4,68(s1)
    80005710:	4785                	li	a5,1
    80005712:	08f70463          	beq	a4,a5,8000579a <sys_link+0xea>
  ip->nlink++;
    80005716:	04a4d783          	lhu	a5,74(s1)
    8000571a:	2785                	addiw	a5,a5,1
    8000571c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005720:	8526                	mv	a0,s1
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	282080e7          	jalr	642(ra) # 800039a4 <iupdate>
  iunlock(ip);
    8000572a:	8526                	mv	a0,s1
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	406080e7          	jalr	1030(ra) # 80003b32 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005734:	fd040593          	addi	a1,s0,-48
    80005738:	f5040513          	addi	a0,s0,-176
    8000573c:	fffff097          	auipc	ra,0xfffff
    80005740:	af8080e7          	jalr	-1288(ra) # 80004234 <nameiparent>
    80005744:	892a                	mv	s2,a0
    80005746:	c935                	beqz	a0,800057ba <sys_link+0x10a>
  ilock(dp);
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	328080e7          	jalr	808(ra) # 80003a70 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005750:	00092703          	lw	a4,0(s2)
    80005754:	409c                	lw	a5,0(s1)
    80005756:	04f71d63          	bne	a4,a5,800057b0 <sys_link+0x100>
    8000575a:	40d0                	lw	a2,4(s1)
    8000575c:	fd040593          	addi	a1,s0,-48
    80005760:	854a                	mv	a0,s2
    80005762:	fffff097          	auipc	ra,0xfffff
    80005766:	a02080e7          	jalr	-1534(ra) # 80004164 <dirlink>
    8000576a:	04054363          	bltz	a0,800057b0 <sys_link+0x100>
  iunlockput(dp);
    8000576e:	854a                	mv	a0,s2
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	562080e7          	jalr	1378(ra) # 80003cd2 <iunlockput>
  iput(ip);
    80005778:	8526                	mv	a0,s1
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	4b0080e7          	jalr	1200(ra) # 80003c2a <iput>
  end_op();
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	d0e080e7          	jalr	-754(ra) # 80004490 <end_op>
  return 0;
    8000578a:	4781                	li	a5,0
    8000578c:	a085                	j	800057ec <sys_link+0x13c>
    end_op();
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	d02080e7          	jalr	-766(ra) # 80004490 <end_op>
    return -1;
    80005796:	57fd                	li	a5,-1
    80005798:	a891                	j	800057ec <sys_link+0x13c>
    iunlockput(ip);
    8000579a:	8526                	mv	a0,s1
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	536080e7          	jalr	1334(ra) # 80003cd2 <iunlockput>
    end_op();
    800057a4:	fffff097          	auipc	ra,0xfffff
    800057a8:	cec080e7          	jalr	-788(ra) # 80004490 <end_op>
    return -1;
    800057ac:	57fd                	li	a5,-1
    800057ae:	a83d                	j	800057ec <sys_link+0x13c>
    iunlockput(dp);
    800057b0:	854a                	mv	a0,s2
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	520080e7          	jalr	1312(ra) # 80003cd2 <iunlockput>
  ilock(ip);
    800057ba:	8526                	mv	a0,s1
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	2b4080e7          	jalr	692(ra) # 80003a70 <ilock>
  ip->nlink--;
    800057c4:	04a4d783          	lhu	a5,74(s1)
    800057c8:	37fd                	addiw	a5,a5,-1
    800057ca:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057ce:	8526                	mv	a0,s1
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	1d4080e7          	jalr	468(ra) # 800039a4 <iupdate>
  iunlockput(ip);
    800057d8:	8526                	mv	a0,s1
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	4f8080e7          	jalr	1272(ra) # 80003cd2 <iunlockput>
  end_op();
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	cae080e7          	jalr	-850(ra) # 80004490 <end_op>
  return -1;
    800057ea:	57fd                	li	a5,-1
}
    800057ec:	853e                	mv	a0,a5
    800057ee:	70b2                	ld	ra,296(sp)
    800057f0:	7412                	ld	s0,288(sp)
    800057f2:	64f2                	ld	s1,280(sp)
    800057f4:	6952                	ld	s2,272(sp)
    800057f6:	6155                	addi	sp,sp,304
    800057f8:	8082                	ret

00000000800057fa <sys_unlink>:
{
    800057fa:	7151                	addi	sp,sp,-240
    800057fc:	f586                	sd	ra,232(sp)
    800057fe:	f1a2                	sd	s0,224(sp)
    80005800:	eda6                	sd	s1,216(sp)
    80005802:	e9ca                	sd	s2,208(sp)
    80005804:	e5ce                	sd	s3,200(sp)
    80005806:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005808:	08000613          	li	a2,128
    8000580c:	f3040593          	addi	a1,s0,-208
    80005810:	4501                	li	a0,0
    80005812:	ffffd097          	auipc	ra,0xffffd
    80005816:	64c080e7          	jalr	1612(ra) # 80002e5e <argstr>
    8000581a:	18054163          	bltz	a0,8000599c <sys_unlink+0x1a2>
  begin_op();
    8000581e:	fffff097          	auipc	ra,0xfffff
    80005822:	bf8080e7          	jalr	-1032(ra) # 80004416 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005826:	fb040593          	addi	a1,s0,-80
    8000582a:	f3040513          	addi	a0,s0,-208
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	a06080e7          	jalr	-1530(ra) # 80004234 <nameiparent>
    80005836:	84aa                	mv	s1,a0
    80005838:	c979                	beqz	a0,8000590e <sys_unlink+0x114>
  ilock(dp);
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	236080e7          	jalr	566(ra) # 80003a70 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005842:	00003597          	auipc	a1,0x3
    80005846:	03658593          	addi	a1,a1,54 # 80008878 <__func__.0+0x200>
    8000584a:	fb040513          	addi	a0,s0,-80
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	6ec080e7          	jalr	1772(ra) # 80003f3a <namecmp>
    80005856:	14050a63          	beqz	a0,800059aa <sys_unlink+0x1b0>
    8000585a:	00003597          	auipc	a1,0x3
    8000585e:	02658593          	addi	a1,a1,38 # 80008880 <__func__.0+0x208>
    80005862:	fb040513          	addi	a0,s0,-80
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	6d4080e7          	jalr	1748(ra) # 80003f3a <namecmp>
    8000586e:	12050e63          	beqz	a0,800059aa <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005872:	f2c40613          	addi	a2,s0,-212
    80005876:	fb040593          	addi	a1,s0,-80
    8000587a:	8526                	mv	a0,s1
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	6d8080e7          	jalr	1752(ra) # 80003f54 <dirlookup>
    80005884:	892a                	mv	s2,a0
    80005886:	12050263          	beqz	a0,800059aa <sys_unlink+0x1b0>
  ilock(ip);
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	1e6080e7          	jalr	486(ra) # 80003a70 <ilock>
  if(ip->nlink < 1)
    80005892:	04a91783          	lh	a5,74(s2)
    80005896:	08f05263          	blez	a5,8000591a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000589a:	04491703          	lh	a4,68(s2)
    8000589e:	4785                	li	a5,1
    800058a0:	08f70563          	beq	a4,a5,8000592a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800058a4:	4641                	li	a2,16
    800058a6:	4581                	li	a1,0
    800058a8:	fc040513          	addi	a0,s0,-64
    800058ac:	ffffb097          	auipc	ra,0xffffb
    800058b0:	4ea080e7          	jalr	1258(ra) # 80000d96 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058b4:	4741                	li	a4,16
    800058b6:	f2c42683          	lw	a3,-212(s0)
    800058ba:	fc040613          	addi	a2,s0,-64
    800058be:	4581                	li	a1,0
    800058c0:	8526                	mv	a0,s1
    800058c2:	ffffe097          	auipc	ra,0xffffe
    800058c6:	55a080e7          	jalr	1370(ra) # 80003e1c <writei>
    800058ca:	47c1                	li	a5,16
    800058cc:	0af51563          	bne	a0,a5,80005976 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800058d0:	04491703          	lh	a4,68(s2)
    800058d4:	4785                	li	a5,1
    800058d6:	0af70863          	beq	a4,a5,80005986 <sys_unlink+0x18c>
  iunlockput(dp);
    800058da:	8526                	mv	a0,s1
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	3f6080e7          	jalr	1014(ra) # 80003cd2 <iunlockput>
  ip->nlink--;
    800058e4:	04a95783          	lhu	a5,74(s2)
    800058e8:	37fd                	addiw	a5,a5,-1
    800058ea:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058ee:	854a                	mv	a0,s2
    800058f0:	ffffe097          	auipc	ra,0xffffe
    800058f4:	0b4080e7          	jalr	180(ra) # 800039a4 <iupdate>
  iunlockput(ip);
    800058f8:	854a                	mv	a0,s2
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	3d8080e7          	jalr	984(ra) # 80003cd2 <iunlockput>
  end_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	b8e080e7          	jalr	-1138(ra) # 80004490 <end_op>
  return 0;
    8000590a:	4501                	li	a0,0
    8000590c:	a84d                	j	800059be <sys_unlink+0x1c4>
    end_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	b82080e7          	jalr	-1150(ra) # 80004490 <end_op>
    return -1;
    80005916:	557d                	li	a0,-1
    80005918:	a05d                	j	800059be <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000591a:	00003517          	auipc	a0,0x3
    8000591e:	f6e50513          	addi	a0,a0,-146 # 80008888 <__func__.0+0x210>
    80005922:	ffffb097          	auipc	ra,0xffffb
    80005926:	c1a080e7          	jalr	-998(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000592a:	04c92703          	lw	a4,76(s2)
    8000592e:	02000793          	li	a5,32
    80005932:	f6e7f9e3          	bgeu	a5,a4,800058a4 <sys_unlink+0xaa>
    80005936:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000593a:	4741                	li	a4,16
    8000593c:	86ce                	mv	a3,s3
    8000593e:	f1840613          	addi	a2,s0,-232
    80005942:	4581                	li	a1,0
    80005944:	854a                	mv	a0,s2
    80005946:	ffffe097          	auipc	ra,0xffffe
    8000594a:	3de080e7          	jalr	990(ra) # 80003d24 <readi>
    8000594e:	47c1                	li	a5,16
    80005950:	00f51b63          	bne	a0,a5,80005966 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005954:	f1845783          	lhu	a5,-232(s0)
    80005958:	e7a1                	bnez	a5,800059a0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000595a:	29c1                	addiw	s3,s3,16
    8000595c:	04c92783          	lw	a5,76(s2)
    80005960:	fcf9ede3          	bltu	s3,a5,8000593a <sys_unlink+0x140>
    80005964:	b781                	j	800058a4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005966:	00003517          	auipc	a0,0x3
    8000596a:	f3a50513          	addi	a0,a0,-198 # 800088a0 <__func__.0+0x228>
    8000596e:	ffffb097          	auipc	ra,0xffffb
    80005972:	bce080e7          	jalr	-1074(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005976:	00003517          	auipc	a0,0x3
    8000597a:	f4250513          	addi	a0,a0,-190 # 800088b8 <__func__.0+0x240>
    8000597e:	ffffb097          	auipc	ra,0xffffb
    80005982:	bbe080e7          	jalr	-1090(ra) # 8000053c <panic>
    dp->nlink--;
    80005986:	04a4d783          	lhu	a5,74(s1)
    8000598a:	37fd                	addiw	a5,a5,-1
    8000598c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005990:	8526                	mv	a0,s1
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	012080e7          	jalr	18(ra) # 800039a4 <iupdate>
    8000599a:	b781                	j	800058da <sys_unlink+0xe0>
    return -1;
    8000599c:	557d                	li	a0,-1
    8000599e:	a005                	j	800059be <sys_unlink+0x1c4>
    iunlockput(ip);
    800059a0:	854a                	mv	a0,s2
    800059a2:	ffffe097          	auipc	ra,0xffffe
    800059a6:	330080e7          	jalr	816(ra) # 80003cd2 <iunlockput>
  iunlockput(dp);
    800059aa:	8526                	mv	a0,s1
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	326080e7          	jalr	806(ra) # 80003cd2 <iunlockput>
  end_op();
    800059b4:	fffff097          	auipc	ra,0xfffff
    800059b8:	adc080e7          	jalr	-1316(ra) # 80004490 <end_op>
  return -1;
    800059bc:	557d                	li	a0,-1
}
    800059be:	70ae                	ld	ra,232(sp)
    800059c0:	740e                	ld	s0,224(sp)
    800059c2:	64ee                	ld	s1,216(sp)
    800059c4:	694e                	ld	s2,208(sp)
    800059c6:	69ae                	ld	s3,200(sp)
    800059c8:	616d                	addi	sp,sp,240
    800059ca:	8082                	ret

00000000800059cc <sys_open>:

uint64
sys_open(void)
{
    800059cc:	7131                	addi	sp,sp,-192
    800059ce:	fd06                	sd	ra,184(sp)
    800059d0:	f922                	sd	s0,176(sp)
    800059d2:	f526                	sd	s1,168(sp)
    800059d4:	f14a                	sd	s2,160(sp)
    800059d6:	ed4e                	sd	s3,152(sp)
    800059d8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800059da:	f4c40593          	addi	a1,s0,-180
    800059de:	4505                	li	a0,1
    800059e0:	ffffd097          	auipc	ra,0xffffd
    800059e4:	43e080e7          	jalr	1086(ra) # 80002e1e <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059e8:	08000613          	li	a2,128
    800059ec:	f5040593          	addi	a1,s0,-176
    800059f0:	4501                	li	a0,0
    800059f2:	ffffd097          	auipc	ra,0xffffd
    800059f6:	46c080e7          	jalr	1132(ra) # 80002e5e <argstr>
    800059fa:	87aa                	mv	a5,a0
    return -1;
    800059fc:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059fe:	0a07c863          	bltz	a5,80005aae <sys_open+0xe2>

  begin_op();
    80005a02:	fffff097          	auipc	ra,0xfffff
    80005a06:	a14080e7          	jalr	-1516(ra) # 80004416 <begin_op>

  if(omode & O_CREATE){
    80005a0a:	f4c42783          	lw	a5,-180(s0)
    80005a0e:	2007f793          	andi	a5,a5,512
    80005a12:	cbdd                	beqz	a5,80005ac8 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005a14:	4681                	li	a3,0
    80005a16:	4601                	li	a2,0
    80005a18:	4589                	li	a1,2
    80005a1a:	f5040513          	addi	a0,s0,-176
    80005a1e:	00000097          	auipc	ra,0x0
    80005a22:	97a080e7          	jalr	-1670(ra) # 80005398 <create>
    80005a26:	84aa                	mv	s1,a0
    if(ip == 0){
    80005a28:	c951                	beqz	a0,80005abc <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a2a:	04449703          	lh	a4,68(s1)
    80005a2e:	478d                	li	a5,3
    80005a30:	00f71763          	bne	a4,a5,80005a3e <sys_open+0x72>
    80005a34:	0464d703          	lhu	a4,70(s1)
    80005a38:	47a5                	li	a5,9
    80005a3a:	0ce7ec63          	bltu	a5,a4,80005b12 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a3e:	fffff097          	auipc	ra,0xfffff
    80005a42:	de0080e7          	jalr	-544(ra) # 8000481e <filealloc>
    80005a46:	892a                	mv	s2,a0
    80005a48:	c56d                	beqz	a0,80005b32 <sys_open+0x166>
    80005a4a:	00000097          	auipc	ra,0x0
    80005a4e:	90c080e7          	jalr	-1780(ra) # 80005356 <fdalloc>
    80005a52:	89aa                	mv	s3,a0
    80005a54:	0c054a63          	bltz	a0,80005b28 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a58:	04449703          	lh	a4,68(s1)
    80005a5c:	478d                	li	a5,3
    80005a5e:	0ef70563          	beq	a4,a5,80005b48 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a62:	4789                	li	a5,2
    80005a64:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005a68:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005a6c:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005a70:	f4c42783          	lw	a5,-180(s0)
    80005a74:	0017c713          	xori	a4,a5,1
    80005a78:	8b05                	andi	a4,a4,1
    80005a7a:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a7e:	0037f713          	andi	a4,a5,3
    80005a82:	00e03733          	snez	a4,a4
    80005a86:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a8a:	4007f793          	andi	a5,a5,1024
    80005a8e:	c791                	beqz	a5,80005a9a <sys_open+0xce>
    80005a90:	04449703          	lh	a4,68(s1)
    80005a94:	4789                	li	a5,2
    80005a96:	0cf70063          	beq	a4,a5,80005b56 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005a9a:	8526                	mv	a0,s1
    80005a9c:	ffffe097          	auipc	ra,0xffffe
    80005aa0:	096080e7          	jalr	150(ra) # 80003b32 <iunlock>
  end_op();
    80005aa4:	fffff097          	auipc	ra,0xfffff
    80005aa8:	9ec080e7          	jalr	-1556(ra) # 80004490 <end_op>

  return fd;
    80005aac:	854e                	mv	a0,s3
}
    80005aae:	70ea                	ld	ra,184(sp)
    80005ab0:	744a                	ld	s0,176(sp)
    80005ab2:	74aa                	ld	s1,168(sp)
    80005ab4:	790a                	ld	s2,160(sp)
    80005ab6:	69ea                	ld	s3,152(sp)
    80005ab8:	6129                	addi	sp,sp,192
    80005aba:	8082                	ret
      end_op();
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	9d4080e7          	jalr	-1580(ra) # 80004490 <end_op>
      return -1;
    80005ac4:	557d                	li	a0,-1
    80005ac6:	b7e5                	j	80005aae <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005ac8:	f5040513          	addi	a0,s0,-176
    80005acc:	ffffe097          	auipc	ra,0xffffe
    80005ad0:	74a080e7          	jalr	1866(ra) # 80004216 <namei>
    80005ad4:	84aa                	mv	s1,a0
    80005ad6:	c905                	beqz	a0,80005b06 <sys_open+0x13a>
    ilock(ip);
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	f98080e7          	jalr	-104(ra) # 80003a70 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ae0:	04449703          	lh	a4,68(s1)
    80005ae4:	4785                	li	a5,1
    80005ae6:	f4f712e3          	bne	a4,a5,80005a2a <sys_open+0x5e>
    80005aea:	f4c42783          	lw	a5,-180(s0)
    80005aee:	dba1                	beqz	a5,80005a3e <sys_open+0x72>
      iunlockput(ip);
    80005af0:	8526                	mv	a0,s1
    80005af2:	ffffe097          	auipc	ra,0xffffe
    80005af6:	1e0080e7          	jalr	480(ra) # 80003cd2 <iunlockput>
      end_op();
    80005afa:	fffff097          	auipc	ra,0xfffff
    80005afe:	996080e7          	jalr	-1642(ra) # 80004490 <end_op>
      return -1;
    80005b02:	557d                	li	a0,-1
    80005b04:	b76d                	j	80005aae <sys_open+0xe2>
      end_op();
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	98a080e7          	jalr	-1654(ra) # 80004490 <end_op>
      return -1;
    80005b0e:	557d                	li	a0,-1
    80005b10:	bf79                	j	80005aae <sys_open+0xe2>
    iunlockput(ip);
    80005b12:	8526                	mv	a0,s1
    80005b14:	ffffe097          	auipc	ra,0xffffe
    80005b18:	1be080e7          	jalr	446(ra) # 80003cd2 <iunlockput>
    end_op();
    80005b1c:	fffff097          	auipc	ra,0xfffff
    80005b20:	974080e7          	jalr	-1676(ra) # 80004490 <end_op>
    return -1;
    80005b24:	557d                	li	a0,-1
    80005b26:	b761                	j	80005aae <sys_open+0xe2>
      fileclose(f);
    80005b28:	854a                	mv	a0,s2
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	db0080e7          	jalr	-592(ra) # 800048da <fileclose>
    iunlockput(ip);
    80005b32:	8526                	mv	a0,s1
    80005b34:	ffffe097          	auipc	ra,0xffffe
    80005b38:	19e080e7          	jalr	414(ra) # 80003cd2 <iunlockput>
    end_op();
    80005b3c:	fffff097          	auipc	ra,0xfffff
    80005b40:	954080e7          	jalr	-1708(ra) # 80004490 <end_op>
    return -1;
    80005b44:	557d                	li	a0,-1
    80005b46:	b7a5                	j	80005aae <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005b48:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005b4c:	04649783          	lh	a5,70(s1)
    80005b50:	02f91223          	sh	a5,36(s2)
    80005b54:	bf21                	j	80005a6c <sys_open+0xa0>
    itrunc(ip);
    80005b56:	8526                	mv	a0,s1
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	026080e7          	jalr	38(ra) # 80003b7e <itrunc>
    80005b60:	bf2d                	j	80005a9a <sys_open+0xce>

0000000080005b62 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b62:	7175                	addi	sp,sp,-144
    80005b64:	e506                	sd	ra,136(sp)
    80005b66:	e122                	sd	s0,128(sp)
    80005b68:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	8ac080e7          	jalr	-1876(ra) # 80004416 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b72:	08000613          	li	a2,128
    80005b76:	f7040593          	addi	a1,s0,-144
    80005b7a:	4501                	li	a0,0
    80005b7c:	ffffd097          	auipc	ra,0xffffd
    80005b80:	2e2080e7          	jalr	738(ra) # 80002e5e <argstr>
    80005b84:	02054963          	bltz	a0,80005bb6 <sys_mkdir+0x54>
    80005b88:	4681                	li	a3,0
    80005b8a:	4601                	li	a2,0
    80005b8c:	4585                	li	a1,1
    80005b8e:	f7040513          	addi	a0,s0,-144
    80005b92:	00000097          	auipc	ra,0x0
    80005b96:	806080e7          	jalr	-2042(ra) # 80005398 <create>
    80005b9a:	cd11                	beqz	a0,80005bb6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b9c:	ffffe097          	auipc	ra,0xffffe
    80005ba0:	136080e7          	jalr	310(ra) # 80003cd2 <iunlockput>
  end_op();
    80005ba4:	fffff097          	auipc	ra,0xfffff
    80005ba8:	8ec080e7          	jalr	-1812(ra) # 80004490 <end_op>
  return 0;
    80005bac:	4501                	li	a0,0
}
    80005bae:	60aa                	ld	ra,136(sp)
    80005bb0:	640a                	ld	s0,128(sp)
    80005bb2:	6149                	addi	sp,sp,144
    80005bb4:	8082                	ret
    end_op();
    80005bb6:	fffff097          	auipc	ra,0xfffff
    80005bba:	8da080e7          	jalr	-1830(ra) # 80004490 <end_op>
    return -1;
    80005bbe:	557d                	li	a0,-1
    80005bc0:	b7fd                	j	80005bae <sys_mkdir+0x4c>

0000000080005bc2 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005bc2:	7135                	addi	sp,sp,-160
    80005bc4:	ed06                	sd	ra,152(sp)
    80005bc6:	e922                	sd	s0,144(sp)
    80005bc8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	84c080e7          	jalr	-1972(ra) # 80004416 <begin_op>
  argint(1, &major);
    80005bd2:	f6c40593          	addi	a1,s0,-148
    80005bd6:	4505                	li	a0,1
    80005bd8:	ffffd097          	auipc	ra,0xffffd
    80005bdc:	246080e7          	jalr	582(ra) # 80002e1e <argint>
  argint(2, &minor);
    80005be0:	f6840593          	addi	a1,s0,-152
    80005be4:	4509                	li	a0,2
    80005be6:	ffffd097          	auipc	ra,0xffffd
    80005bea:	238080e7          	jalr	568(ra) # 80002e1e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bee:	08000613          	li	a2,128
    80005bf2:	f7040593          	addi	a1,s0,-144
    80005bf6:	4501                	li	a0,0
    80005bf8:	ffffd097          	auipc	ra,0xffffd
    80005bfc:	266080e7          	jalr	614(ra) # 80002e5e <argstr>
    80005c00:	02054b63          	bltz	a0,80005c36 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c04:	f6841683          	lh	a3,-152(s0)
    80005c08:	f6c41603          	lh	a2,-148(s0)
    80005c0c:	458d                	li	a1,3
    80005c0e:	f7040513          	addi	a0,s0,-144
    80005c12:	fffff097          	auipc	ra,0xfffff
    80005c16:	786080e7          	jalr	1926(ra) # 80005398 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c1a:	cd11                	beqz	a0,80005c36 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c1c:	ffffe097          	auipc	ra,0xffffe
    80005c20:	0b6080e7          	jalr	182(ra) # 80003cd2 <iunlockput>
  end_op();
    80005c24:	fffff097          	auipc	ra,0xfffff
    80005c28:	86c080e7          	jalr	-1940(ra) # 80004490 <end_op>
  return 0;
    80005c2c:	4501                	li	a0,0
}
    80005c2e:	60ea                	ld	ra,152(sp)
    80005c30:	644a                	ld	s0,144(sp)
    80005c32:	610d                	addi	sp,sp,160
    80005c34:	8082                	ret
    end_op();
    80005c36:	fffff097          	auipc	ra,0xfffff
    80005c3a:	85a080e7          	jalr	-1958(ra) # 80004490 <end_op>
    return -1;
    80005c3e:	557d                	li	a0,-1
    80005c40:	b7fd                	j	80005c2e <sys_mknod+0x6c>

0000000080005c42 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c42:	7135                	addi	sp,sp,-160
    80005c44:	ed06                	sd	ra,152(sp)
    80005c46:	e922                	sd	s0,144(sp)
    80005c48:	e526                	sd	s1,136(sp)
    80005c4a:	e14a                	sd	s2,128(sp)
    80005c4c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c4e:	ffffc097          	auipc	ra,0xffffc
    80005c52:	f14080e7          	jalr	-236(ra) # 80001b62 <myproc>
    80005c56:	892a                	mv	s2,a0
  
  begin_op();
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	7be080e7          	jalr	1982(ra) # 80004416 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c60:	08000613          	li	a2,128
    80005c64:	f6040593          	addi	a1,s0,-160
    80005c68:	4501                	li	a0,0
    80005c6a:	ffffd097          	auipc	ra,0xffffd
    80005c6e:	1f4080e7          	jalr	500(ra) # 80002e5e <argstr>
    80005c72:	04054b63          	bltz	a0,80005cc8 <sys_chdir+0x86>
    80005c76:	f6040513          	addi	a0,s0,-160
    80005c7a:	ffffe097          	auipc	ra,0xffffe
    80005c7e:	59c080e7          	jalr	1436(ra) # 80004216 <namei>
    80005c82:	84aa                	mv	s1,a0
    80005c84:	c131                	beqz	a0,80005cc8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c86:	ffffe097          	auipc	ra,0xffffe
    80005c8a:	dea080e7          	jalr	-534(ra) # 80003a70 <ilock>
  if(ip->type != T_DIR){
    80005c8e:	04449703          	lh	a4,68(s1)
    80005c92:	4785                	li	a5,1
    80005c94:	04f71063          	bne	a4,a5,80005cd4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c98:	8526                	mv	a0,s1
    80005c9a:	ffffe097          	auipc	ra,0xffffe
    80005c9e:	e98080e7          	jalr	-360(ra) # 80003b32 <iunlock>
  iput(p->cwd);
    80005ca2:	15093503          	ld	a0,336(s2)
    80005ca6:	ffffe097          	auipc	ra,0xffffe
    80005caa:	f84080e7          	jalr	-124(ra) # 80003c2a <iput>
  end_op();
    80005cae:	ffffe097          	auipc	ra,0xffffe
    80005cb2:	7e2080e7          	jalr	2018(ra) # 80004490 <end_op>
  p->cwd = ip;
    80005cb6:	14993823          	sd	s1,336(s2)
  return 0;
    80005cba:	4501                	li	a0,0
}
    80005cbc:	60ea                	ld	ra,152(sp)
    80005cbe:	644a                	ld	s0,144(sp)
    80005cc0:	64aa                	ld	s1,136(sp)
    80005cc2:	690a                	ld	s2,128(sp)
    80005cc4:	610d                	addi	sp,sp,160
    80005cc6:	8082                	ret
    end_op();
    80005cc8:	ffffe097          	auipc	ra,0xffffe
    80005ccc:	7c8080e7          	jalr	1992(ra) # 80004490 <end_op>
    return -1;
    80005cd0:	557d                	li	a0,-1
    80005cd2:	b7ed                	j	80005cbc <sys_chdir+0x7a>
    iunlockput(ip);
    80005cd4:	8526                	mv	a0,s1
    80005cd6:	ffffe097          	auipc	ra,0xffffe
    80005cda:	ffc080e7          	jalr	-4(ra) # 80003cd2 <iunlockput>
    end_op();
    80005cde:	ffffe097          	auipc	ra,0xffffe
    80005ce2:	7b2080e7          	jalr	1970(ra) # 80004490 <end_op>
    return -1;
    80005ce6:	557d                	li	a0,-1
    80005ce8:	bfd1                	j	80005cbc <sys_chdir+0x7a>

0000000080005cea <sys_exec>:

uint64
sys_exec(void)
{
    80005cea:	7121                	addi	sp,sp,-448
    80005cec:	ff06                	sd	ra,440(sp)
    80005cee:	fb22                	sd	s0,432(sp)
    80005cf0:	f726                	sd	s1,424(sp)
    80005cf2:	f34a                	sd	s2,416(sp)
    80005cf4:	ef4e                	sd	s3,408(sp)
    80005cf6:	eb52                	sd	s4,400(sp)
    80005cf8:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005cfa:	e4840593          	addi	a1,s0,-440
    80005cfe:	4505                	li	a0,1
    80005d00:	ffffd097          	auipc	ra,0xffffd
    80005d04:	13e080e7          	jalr	318(ra) # 80002e3e <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005d08:	08000613          	li	a2,128
    80005d0c:	f5040593          	addi	a1,s0,-176
    80005d10:	4501                	li	a0,0
    80005d12:	ffffd097          	auipc	ra,0xffffd
    80005d16:	14c080e7          	jalr	332(ra) # 80002e5e <argstr>
    80005d1a:	87aa                	mv	a5,a0
    return -1;
    80005d1c:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005d1e:	0c07c263          	bltz	a5,80005de2 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005d22:	10000613          	li	a2,256
    80005d26:	4581                	li	a1,0
    80005d28:	e5040513          	addi	a0,s0,-432
    80005d2c:	ffffb097          	auipc	ra,0xffffb
    80005d30:	06a080e7          	jalr	106(ra) # 80000d96 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d34:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005d38:	89a6                	mv	s3,s1
    80005d3a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d3c:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d40:	00391513          	slli	a0,s2,0x3
    80005d44:	e4040593          	addi	a1,s0,-448
    80005d48:	e4843783          	ld	a5,-440(s0)
    80005d4c:	953e                	add	a0,a0,a5
    80005d4e:	ffffd097          	auipc	ra,0xffffd
    80005d52:	032080e7          	jalr	50(ra) # 80002d80 <fetchaddr>
    80005d56:	02054a63          	bltz	a0,80005d8a <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005d5a:	e4043783          	ld	a5,-448(s0)
    80005d5e:	c3b9                	beqz	a5,80005da4 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d60:	ffffb097          	auipc	ra,0xffffb
    80005d64:	dfe080e7          	jalr	-514(ra) # 80000b5e <kalloc>
    80005d68:	85aa                	mv	a1,a0
    80005d6a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d6e:	cd11                	beqz	a0,80005d8a <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d70:	6605                	lui	a2,0x1
    80005d72:	e4043503          	ld	a0,-448(s0)
    80005d76:	ffffd097          	auipc	ra,0xffffd
    80005d7a:	05c080e7          	jalr	92(ra) # 80002dd2 <fetchstr>
    80005d7e:	00054663          	bltz	a0,80005d8a <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005d82:	0905                	addi	s2,s2,1
    80005d84:	09a1                	addi	s3,s3,8
    80005d86:	fb491de3          	bne	s2,s4,80005d40 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d8a:	f5040913          	addi	s2,s0,-176
    80005d8e:	6088                	ld	a0,0(s1)
    80005d90:	c921                	beqz	a0,80005de0 <sys_exec+0xf6>
    kfree(argv[i]);
    80005d92:	ffffb097          	auipc	ra,0xffffb
    80005d96:	c64080e7          	jalr	-924(ra) # 800009f6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d9a:	04a1                	addi	s1,s1,8
    80005d9c:	ff2499e3          	bne	s1,s2,80005d8e <sys_exec+0xa4>
  return -1;
    80005da0:	557d                	li	a0,-1
    80005da2:	a081                	j	80005de2 <sys_exec+0xf8>
      argv[i] = 0;
    80005da4:	0009079b          	sext.w	a5,s2
    80005da8:	078e                	slli	a5,a5,0x3
    80005daa:	fd078793          	addi	a5,a5,-48
    80005dae:	97a2                	add	a5,a5,s0
    80005db0:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005db4:	e5040593          	addi	a1,s0,-432
    80005db8:	f5040513          	addi	a0,s0,-176
    80005dbc:	fffff097          	auipc	ra,0xfffff
    80005dc0:	194080e7          	jalr	404(ra) # 80004f50 <exec>
    80005dc4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dc6:	f5040993          	addi	s3,s0,-176
    80005dca:	6088                	ld	a0,0(s1)
    80005dcc:	c901                	beqz	a0,80005ddc <sys_exec+0xf2>
    kfree(argv[i]);
    80005dce:	ffffb097          	auipc	ra,0xffffb
    80005dd2:	c28080e7          	jalr	-984(ra) # 800009f6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dd6:	04a1                	addi	s1,s1,8
    80005dd8:	ff3499e3          	bne	s1,s3,80005dca <sys_exec+0xe0>
  return ret;
    80005ddc:	854a                	mv	a0,s2
    80005dde:	a011                	j	80005de2 <sys_exec+0xf8>
  return -1;
    80005de0:	557d                	li	a0,-1
}
    80005de2:	70fa                	ld	ra,440(sp)
    80005de4:	745a                	ld	s0,432(sp)
    80005de6:	74ba                	ld	s1,424(sp)
    80005de8:	791a                	ld	s2,416(sp)
    80005dea:	69fa                	ld	s3,408(sp)
    80005dec:	6a5a                	ld	s4,400(sp)
    80005dee:	6139                	addi	sp,sp,448
    80005df0:	8082                	ret

0000000080005df2 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005df2:	7139                	addi	sp,sp,-64
    80005df4:	fc06                	sd	ra,56(sp)
    80005df6:	f822                	sd	s0,48(sp)
    80005df8:	f426                	sd	s1,40(sp)
    80005dfa:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005dfc:	ffffc097          	auipc	ra,0xffffc
    80005e00:	d66080e7          	jalr	-666(ra) # 80001b62 <myproc>
    80005e04:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005e06:	fd840593          	addi	a1,s0,-40
    80005e0a:	4501                	li	a0,0
    80005e0c:	ffffd097          	auipc	ra,0xffffd
    80005e10:	032080e7          	jalr	50(ra) # 80002e3e <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005e14:	fc840593          	addi	a1,s0,-56
    80005e18:	fd040513          	addi	a0,s0,-48
    80005e1c:	fffff097          	auipc	ra,0xfffff
    80005e20:	dea080e7          	jalr	-534(ra) # 80004c06 <pipealloc>
    return -1;
    80005e24:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e26:	0c054463          	bltz	a0,80005eee <sys_pipe+0xfc>
  fd0 = -1;
    80005e2a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e2e:	fd043503          	ld	a0,-48(s0)
    80005e32:	fffff097          	auipc	ra,0xfffff
    80005e36:	524080e7          	jalr	1316(ra) # 80005356 <fdalloc>
    80005e3a:	fca42223          	sw	a0,-60(s0)
    80005e3e:	08054b63          	bltz	a0,80005ed4 <sys_pipe+0xe2>
    80005e42:	fc843503          	ld	a0,-56(s0)
    80005e46:	fffff097          	auipc	ra,0xfffff
    80005e4a:	510080e7          	jalr	1296(ra) # 80005356 <fdalloc>
    80005e4e:	fca42023          	sw	a0,-64(s0)
    80005e52:	06054863          	bltz	a0,80005ec2 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e56:	4691                	li	a3,4
    80005e58:	fc440613          	addi	a2,s0,-60
    80005e5c:	fd843583          	ld	a1,-40(s0)
    80005e60:	68a8                	ld	a0,80(s1)
    80005e62:	ffffc097          	auipc	ra,0xffffc
    80005e66:	8cc080e7          	jalr	-1844(ra) # 8000172e <copyout>
    80005e6a:	02054063          	bltz	a0,80005e8a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e6e:	4691                	li	a3,4
    80005e70:	fc040613          	addi	a2,s0,-64
    80005e74:	fd843583          	ld	a1,-40(s0)
    80005e78:	0591                	addi	a1,a1,4
    80005e7a:	68a8                	ld	a0,80(s1)
    80005e7c:	ffffc097          	auipc	ra,0xffffc
    80005e80:	8b2080e7          	jalr	-1870(ra) # 8000172e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e84:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e86:	06055463          	bgez	a0,80005eee <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005e8a:	fc442783          	lw	a5,-60(s0)
    80005e8e:	07e9                	addi	a5,a5,26
    80005e90:	078e                	slli	a5,a5,0x3
    80005e92:	97a6                	add	a5,a5,s1
    80005e94:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e98:	fc042783          	lw	a5,-64(s0)
    80005e9c:	07e9                	addi	a5,a5,26
    80005e9e:	078e                	slli	a5,a5,0x3
    80005ea0:	94be                	add	s1,s1,a5
    80005ea2:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005ea6:	fd043503          	ld	a0,-48(s0)
    80005eaa:	fffff097          	auipc	ra,0xfffff
    80005eae:	a30080e7          	jalr	-1488(ra) # 800048da <fileclose>
    fileclose(wf);
    80005eb2:	fc843503          	ld	a0,-56(s0)
    80005eb6:	fffff097          	auipc	ra,0xfffff
    80005eba:	a24080e7          	jalr	-1500(ra) # 800048da <fileclose>
    return -1;
    80005ebe:	57fd                	li	a5,-1
    80005ec0:	a03d                	j	80005eee <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005ec2:	fc442783          	lw	a5,-60(s0)
    80005ec6:	0007c763          	bltz	a5,80005ed4 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005eca:	07e9                	addi	a5,a5,26
    80005ecc:	078e                	slli	a5,a5,0x3
    80005ece:	97a6                	add	a5,a5,s1
    80005ed0:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005ed4:	fd043503          	ld	a0,-48(s0)
    80005ed8:	fffff097          	auipc	ra,0xfffff
    80005edc:	a02080e7          	jalr	-1534(ra) # 800048da <fileclose>
    fileclose(wf);
    80005ee0:	fc843503          	ld	a0,-56(s0)
    80005ee4:	fffff097          	auipc	ra,0xfffff
    80005ee8:	9f6080e7          	jalr	-1546(ra) # 800048da <fileclose>
    return -1;
    80005eec:	57fd                	li	a5,-1
}
    80005eee:	853e                	mv	a0,a5
    80005ef0:	70e2                	ld	ra,56(sp)
    80005ef2:	7442                	ld	s0,48(sp)
    80005ef4:	74a2                	ld	s1,40(sp)
    80005ef6:	6121                	addi	sp,sp,64
    80005ef8:	8082                	ret
    80005efa:	0000                	unimp
    80005efc:	0000                	unimp
	...

0000000080005f00 <kernelvec>:
    80005f00:	7111                	addi	sp,sp,-256
    80005f02:	e006                	sd	ra,0(sp)
    80005f04:	e40a                	sd	sp,8(sp)
    80005f06:	e80e                	sd	gp,16(sp)
    80005f08:	ec12                	sd	tp,24(sp)
    80005f0a:	f016                	sd	t0,32(sp)
    80005f0c:	f41a                	sd	t1,40(sp)
    80005f0e:	f81e                	sd	t2,48(sp)
    80005f10:	fc22                	sd	s0,56(sp)
    80005f12:	e0a6                	sd	s1,64(sp)
    80005f14:	e4aa                	sd	a0,72(sp)
    80005f16:	e8ae                	sd	a1,80(sp)
    80005f18:	ecb2                	sd	a2,88(sp)
    80005f1a:	f0b6                	sd	a3,96(sp)
    80005f1c:	f4ba                	sd	a4,104(sp)
    80005f1e:	f8be                	sd	a5,112(sp)
    80005f20:	fcc2                	sd	a6,120(sp)
    80005f22:	e146                	sd	a7,128(sp)
    80005f24:	e54a                	sd	s2,136(sp)
    80005f26:	e94e                	sd	s3,144(sp)
    80005f28:	ed52                	sd	s4,152(sp)
    80005f2a:	f156                	sd	s5,160(sp)
    80005f2c:	f55a                	sd	s6,168(sp)
    80005f2e:	f95e                	sd	s7,176(sp)
    80005f30:	fd62                	sd	s8,184(sp)
    80005f32:	e1e6                	sd	s9,192(sp)
    80005f34:	e5ea                	sd	s10,200(sp)
    80005f36:	e9ee                	sd	s11,208(sp)
    80005f38:	edf2                	sd	t3,216(sp)
    80005f3a:	f1f6                	sd	t4,224(sp)
    80005f3c:	f5fa                	sd	t5,232(sp)
    80005f3e:	f9fe                	sd	t6,240(sp)
    80005f40:	d0dfc0ef          	jal	ra,80002c4c <kerneltrap>
    80005f44:	6082                	ld	ra,0(sp)
    80005f46:	6122                	ld	sp,8(sp)
    80005f48:	61c2                	ld	gp,16(sp)
    80005f4a:	7282                	ld	t0,32(sp)
    80005f4c:	7322                	ld	t1,40(sp)
    80005f4e:	73c2                	ld	t2,48(sp)
    80005f50:	7462                	ld	s0,56(sp)
    80005f52:	6486                	ld	s1,64(sp)
    80005f54:	6526                	ld	a0,72(sp)
    80005f56:	65c6                	ld	a1,80(sp)
    80005f58:	6666                	ld	a2,88(sp)
    80005f5a:	7686                	ld	a3,96(sp)
    80005f5c:	7726                	ld	a4,104(sp)
    80005f5e:	77c6                	ld	a5,112(sp)
    80005f60:	7866                	ld	a6,120(sp)
    80005f62:	688a                	ld	a7,128(sp)
    80005f64:	692a                	ld	s2,136(sp)
    80005f66:	69ca                	ld	s3,144(sp)
    80005f68:	6a6a                	ld	s4,152(sp)
    80005f6a:	7a8a                	ld	s5,160(sp)
    80005f6c:	7b2a                	ld	s6,168(sp)
    80005f6e:	7bca                	ld	s7,176(sp)
    80005f70:	7c6a                	ld	s8,184(sp)
    80005f72:	6c8e                	ld	s9,192(sp)
    80005f74:	6d2e                	ld	s10,200(sp)
    80005f76:	6dce                	ld	s11,208(sp)
    80005f78:	6e6e                	ld	t3,216(sp)
    80005f7a:	7e8e                	ld	t4,224(sp)
    80005f7c:	7f2e                	ld	t5,232(sp)
    80005f7e:	7fce                	ld	t6,240(sp)
    80005f80:	6111                	addi	sp,sp,256
    80005f82:	10200073          	sret
    80005f86:	00000013          	nop
    80005f8a:	00000013          	nop
    80005f8e:	0001                	nop

0000000080005f90 <timervec>:
    80005f90:	34051573          	csrrw	a0,mscratch,a0
    80005f94:	e10c                	sd	a1,0(a0)
    80005f96:	e510                	sd	a2,8(a0)
    80005f98:	e914                	sd	a3,16(a0)
    80005f9a:	6d0c                	ld	a1,24(a0)
    80005f9c:	7110                	ld	a2,32(a0)
    80005f9e:	6194                	ld	a3,0(a1)
    80005fa0:	96b2                	add	a3,a3,a2
    80005fa2:	e194                	sd	a3,0(a1)
    80005fa4:	4589                	li	a1,2
    80005fa6:	14459073          	csrw	sip,a1
    80005faa:	6914                	ld	a3,16(a0)
    80005fac:	6510                	ld	a2,8(a0)
    80005fae:	610c                	ld	a1,0(a0)
    80005fb0:	34051573          	csrrw	a0,mscratch,a0
    80005fb4:	30200073          	mret
	...

0000000080005fba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005fba:	1141                	addi	sp,sp,-16
    80005fbc:	e422                	sd	s0,8(sp)
    80005fbe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005fc0:	0c0007b7          	lui	a5,0xc000
    80005fc4:	4705                	li	a4,1
    80005fc6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005fc8:	c3d8                	sw	a4,4(a5)
}
    80005fca:	6422                	ld	s0,8(sp)
    80005fcc:	0141                	addi	sp,sp,16
    80005fce:	8082                	ret

0000000080005fd0 <plicinithart>:

void
plicinithart(void)
{
    80005fd0:	1141                	addi	sp,sp,-16
    80005fd2:	e406                	sd	ra,8(sp)
    80005fd4:	e022                	sd	s0,0(sp)
    80005fd6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fd8:	ffffc097          	auipc	ra,0xffffc
    80005fdc:	b5e080e7          	jalr	-1186(ra) # 80001b36 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fe0:	0085171b          	slliw	a4,a0,0x8
    80005fe4:	0c0027b7          	lui	a5,0xc002
    80005fe8:	97ba                	add	a5,a5,a4
    80005fea:	40200713          	li	a4,1026
    80005fee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ff2:	00d5151b          	slliw	a0,a0,0xd
    80005ff6:	0c2017b7          	lui	a5,0xc201
    80005ffa:	97aa                	add	a5,a5,a0
    80005ffc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006000:	60a2                	ld	ra,8(sp)
    80006002:	6402                	ld	s0,0(sp)
    80006004:	0141                	addi	sp,sp,16
    80006006:	8082                	ret

0000000080006008 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006008:	1141                	addi	sp,sp,-16
    8000600a:	e406                	sd	ra,8(sp)
    8000600c:	e022                	sd	s0,0(sp)
    8000600e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006010:	ffffc097          	auipc	ra,0xffffc
    80006014:	b26080e7          	jalr	-1242(ra) # 80001b36 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006018:	00d5151b          	slliw	a0,a0,0xd
    8000601c:	0c2017b7          	lui	a5,0xc201
    80006020:	97aa                	add	a5,a5,a0
  return irq;
}
    80006022:	43c8                	lw	a0,4(a5)
    80006024:	60a2                	ld	ra,8(sp)
    80006026:	6402                	ld	s0,0(sp)
    80006028:	0141                	addi	sp,sp,16
    8000602a:	8082                	ret

000000008000602c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000602c:	1101                	addi	sp,sp,-32
    8000602e:	ec06                	sd	ra,24(sp)
    80006030:	e822                	sd	s0,16(sp)
    80006032:	e426                	sd	s1,8(sp)
    80006034:	1000                	addi	s0,sp,32
    80006036:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006038:	ffffc097          	auipc	ra,0xffffc
    8000603c:	afe080e7          	jalr	-1282(ra) # 80001b36 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006040:	00d5151b          	slliw	a0,a0,0xd
    80006044:	0c2017b7          	lui	a5,0xc201
    80006048:	97aa                	add	a5,a5,a0
    8000604a:	c3c4                	sw	s1,4(a5)
}
    8000604c:	60e2                	ld	ra,24(sp)
    8000604e:	6442                	ld	s0,16(sp)
    80006050:	64a2                	ld	s1,8(sp)
    80006052:	6105                	addi	sp,sp,32
    80006054:	8082                	ret

0000000080006056 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006056:	1141                	addi	sp,sp,-16
    80006058:	e406                	sd	ra,8(sp)
    8000605a:	e022                	sd	s0,0(sp)
    8000605c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000605e:	479d                	li	a5,7
    80006060:	04a7cc63          	blt	a5,a0,800060b8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006064:	0001c797          	auipc	a5,0x1c
    80006068:	d6c78793          	addi	a5,a5,-660 # 80021dd0 <disk>
    8000606c:	97aa                	add	a5,a5,a0
    8000606e:	0187c783          	lbu	a5,24(a5)
    80006072:	ebb9                	bnez	a5,800060c8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006074:	00451693          	slli	a3,a0,0x4
    80006078:	0001c797          	auipc	a5,0x1c
    8000607c:	d5878793          	addi	a5,a5,-680 # 80021dd0 <disk>
    80006080:	6398                	ld	a4,0(a5)
    80006082:	9736                	add	a4,a4,a3
    80006084:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006088:	6398                	ld	a4,0(a5)
    8000608a:	9736                	add	a4,a4,a3
    8000608c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006090:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006094:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006098:	97aa                	add	a5,a5,a0
    8000609a:	4705                	li	a4,1
    8000609c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800060a0:	0001c517          	auipc	a0,0x1c
    800060a4:	d4850513          	addi	a0,a0,-696 # 80021de8 <disk+0x18>
    800060a8:	ffffc097          	auipc	ra,0xffffc
    800060ac:	286080e7          	jalr	646(ra) # 8000232e <wakeup>
}
    800060b0:	60a2                	ld	ra,8(sp)
    800060b2:	6402                	ld	s0,0(sp)
    800060b4:	0141                	addi	sp,sp,16
    800060b6:	8082                	ret
    panic("free_desc 1");
    800060b8:	00003517          	auipc	a0,0x3
    800060bc:	81050513          	addi	a0,a0,-2032 # 800088c8 <__func__.0+0x250>
    800060c0:	ffffa097          	auipc	ra,0xffffa
    800060c4:	47c080e7          	jalr	1148(ra) # 8000053c <panic>
    panic("free_desc 2");
    800060c8:	00003517          	auipc	a0,0x3
    800060cc:	81050513          	addi	a0,a0,-2032 # 800088d8 <__func__.0+0x260>
    800060d0:	ffffa097          	auipc	ra,0xffffa
    800060d4:	46c080e7          	jalr	1132(ra) # 8000053c <panic>

00000000800060d8 <virtio_disk_init>:
{
    800060d8:	1101                	addi	sp,sp,-32
    800060da:	ec06                	sd	ra,24(sp)
    800060dc:	e822                	sd	s0,16(sp)
    800060de:	e426                	sd	s1,8(sp)
    800060e0:	e04a                	sd	s2,0(sp)
    800060e2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060e4:	00003597          	auipc	a1,0x3
    800060e8:	80458593          	addi	a1,a1,-2044 # 800088e8 <__func__.0+0x270>
    800060ec:	0001c517          	auipc	a0,0x1c
    800060f0:	e0c50513          	addi	a0,a0,-500 # 80021ef8 <disk+0x128>
    800060f4:	ffffb097          	auipc	ra,0xffffb
    800060f8:	b16080e7          	jalr	-1258(ra) # 80000c0a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060fc:	100017b7          	lui	a5,0x10001
    80006100:	4398                	lw	a4,0(a5)
    80006102:	2701                	sext.w	a4,a4
    80006104:	747277b7          	lui	a5,0x74727
    80006108:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000610c:	14f71b63          	bne	a4,a5,80006262 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006110:	100017b7          	lui	a5,0x10001
    80006114:	43dc                	lw	a5,4(a5)
    80006116:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006118:	4709                	li	a4,2
    8000611a:	14e79463          	bne	a5,a4,80006262 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000611e:	100017b7          	lui	a5,0x10001
    80006122:	479c                	lw	a5,8(a5)
    80006124:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006126:	12e79e63          	bne	a5,a4,80006262 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000612a:	100017b7          	lui	a5,0x10001
    8000612e:	47d8                	lw	a4,12(a5)
    80006130:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006132:	554d47b7          	lui	a5,0x554d4
    80006136:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000613a:	12f71463          	bne	a4,a5,80006262 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000613e:	100017b7          	lui	a5,0x10001
    80006142:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006146:	4705                	li	a4,1
    80006148:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000614a:	470d                	li	a4,3
    8000614c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000614e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006150:	c7ffe6b7          	lui	a3,0xc7ffe
    80006154:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc84f>
    80006158:	8f75                	and	a4,a4,a3
    8000615a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000615c:	472d                	li	a4,11
    8000615e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006160:	5bbc                	lw	a5,112(a5)
    80006162:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006166:	8ba1                	andi	a5,a5,8
    80006168:	10078563          	beqz	a5,80006272 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000616c:	100017b7          	lui	a5,0x10001
    80006170:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006174:	43fc                	lw	a5,68(a5)
    80006176:	2781                	sext.w	a5,a5
    80006178:	10079563          	bnez	a5,80006282 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000617c:	100017b7          	lui	a5,0x10001
    80006180:	5bdc                	lw	a5,52(a5)
    80006182:	2781                	sext.w	a5,a5
  if(max == 0)
    80006184:	10078763          	beqz	a5,80006292 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006188:	471d                	li	a4,7
    8000618a:	10f77c63          	bgeu	a4,a5,800062a2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000618e:	ffffb097          	auipc	ra,0xffffb
    80006192:	9d0080e7          	jalr	-1584(ra) # 80000b5e <kalloc>
    80006196:	0001c497          	auipc	s1,0x1c
    8000619a:	c3a48493          	addi	s1,s1,-966 # 80021dd0 <disk>
    8000619e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800061a0:	ffffb097          	auipc	ra,0xffffb
    800061a4:	9be080e7          	jalr	-1602(ra) # 80000b5e <kalloc>
    800061a8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800061aa:	ffffb097          	auipc	ra,0xffffb
    800061ae:	9b4080e7          	jalr	-1612(ra) # 80000b5e <kalloc>
    800061b2:	87aa                	mv	a5,a0
    800061b4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800061b6:	6088                	ld	a0,0(s1)
    800061b8:	cd6d                	beqz	a0,800062b2 <virtio_disk_init+0x1da>
    800061ba:	0001c717          	auipc	a4,0x1c
    800061be:	c1e73703          	ld	a4,-994(a4) # 80021dd8 <disk+0x8>
    800061c2:	cb65                	beqz	a4,800062b2 <virtio_disk_init+0x1da>
    800061c4:	c7fd                	beqz	a5,800062b2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800061c6:	6605                	lui	a2,0x1
    800061c8:	4581                	li	a1,0
    800061ca:	ffffb097          	auipc	ra,0xffffb
    800061ce:	bcc080e7          	jalr	-1076(ra) # 80000d96 <memset>
  memset(disk.avail, 0, PGSIZE);
    800061d2:	0001c497          	auipc	s1,0x1c
    800061d6:	bfe48493          	addi	s1,s1,-1026 # 80021dd0 <disk>
    800061da:	6605                	lui	a2,0x1
    800061dc:	4581                	li	a1,0
    800061de:	6488                	ld	a0,8(s1)
    800061e0:	ffffb097          	auipc	ra,0xffffb
    800061e4:	bb6080e7          	jalr	-1098(ra) # 80000d96 <memset>
  memset(disk.used, 0, PGSIZE);
    800061e8:	6605                	lui	a2,0x1
    800061ea:	4581                	li	a1,0
    800061ec:	6888                	ld	a0,16(s1)
    800061ee:	ffffb097          	auipc	ra,0xffffb
    800061f2:	ba8080e7          	jalr	-1112(ra) # 80000d96 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800061f6:	100017b7          	lui	a5,0x10001
    800061fa:	4721                	li	a4,8
    800061fc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800061fe:	4098                	lw	a4,0(s1)
    80006200:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006204:	40d8                	lw	a4,4(s1)
    80006206:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000620a:	6498                	ld	a4,8(s1)
    8000620c:	0007069b          	sext.w	a3,a4
    80006210:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006214:	9701                	srai	a4,a4,0x20
    80006216:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000621a:	6898                	ld	a4,16(s1)
    8000621c:	0007069b          	sext.w	a3,a4
    80006220:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006224:	9701                	srai	a4,a4,0x20
    80006226:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000622a:	4705                	li	a4,1
    8000622c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000622e:	00e48c23          	sb	a4,24(s1)
    80006232:	00e48ca3          	sb	a4,25(s1)
    80006236:	00e48d23          	sb	a4,26(s1)
    8000623a:	00e48da3          	sb	a4,27(s1)
    8000623e:	00e48e23          	sb	a4,28(s1)
    80006242:	00e48ea3          	sb	a4,29(s1)
    80006246:	00e48f23          	sb	a4,30(s1)
    8000624a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000624e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006252:	0727a823          	sw	s2,112(a5)
}
    80006256:	60e2                	ld	ra,24(sp)
    80006258:	6442                	ld	s0,16(sp)
    8000625a:	64a2                	ld	s1,8(sp)
    8000625c:	6902                	ld	s2,0(sp)
    8000625e:	6105                	addi	sp,sp,32
    80006260:	8082                	ret
    panic("could not find virtio disk");
    80006262:	00002517          	auipc	a0,0x2
    80006266:	69650513          	addi	a0,a0,1686 # 800088f8 <__func__.0+0x280>
    8000626a:	ffffa097          	auipc	ra,0xffffa
    8000626e:	2d2080e7          	jalr	722(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80006272:	00002517          	auipc	a0,0x2
    80006276:	6a650513          	addi	a0,a0,1702 # 80008918 <__func__.0+0x2a0>
    8000627a:	ffffa097          	auipc	ra,0xffffa
    8000627e:	2c2080e7          	jalr	706(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006282:	00002517          	auipc	a0,0x2
    80006286:	6b650513          	addi	a0,a0,1718 # 80008938 <__func__.0+0x2c0>
    8000628a:	ffffa097          	auipc	ra,0xffffa
    8000628e:	2b2080e7          	jalr	690(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006292:	00002517          	auipc	a0,0x2
    80006296:	6c650513          	addi	a0,a0,1734 # 80008958 <__func__.0+0x2e0>
    8000629a:	ffffa097          	auipc	ra,0xffffa
    8000629e:	2a2080e7          	jalr	674(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    800062a2:	00002517          	auipc	a0,0x2
    800062a6:	6d650513          	addi	a0,a0,1750 # 80008978 <__func__.0+0x300>
    800062aa:	ffffa097          	auipc	ra,0xffffa
    800062ae:	292080e7          	jalr	658(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    800062b2:	00002517          	auipc	a0,0x2
    800062b6:	6e650513          	addi	a0,a0,1766 # 80008998 <__func__.0+0x320>
    800062ba:	ffffa097          	auipc	ra,0xffffa
    800062be:	282080e7          	jalr	642(ra) # 8000053c <panic>

00000000800062c2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062c2:	7159                	addi	sp,sp,-112
    800062c4:	f486                	sd	ra,104(sp)
    800062c6:	f0a2                	sd	s0,96(sp)
    800062c8:	eca6                	sd	s1,88(sp)
    800062ca:	e8ca                	sd	s2,80(sp)
    800062cc:	e4ce                	sd	s3,72(sp)
    800062ce:	e0d2                	sd	s4,64(sp)
    800062d0:	fc56                	sd	s5,56(sp)
    800062d2:	f85a                	sd	s6,48(sp)
    800062d4:	f45e                	sd	s7,40(sp)
    800062d6:	f062                	sd	s8,32(sp)
    800062d8:	ec66                	sd	s9,24(sp)
    800062da:	e86a                	sd	s10,16(sp)
    800062dc:	1880                	addi	s0,sp,112
    800062de:	8a2a                	mv	s4,a0
    800062e0:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062e2:	00c52c83          	lw	s9,12(a0)
    800062e6:	001c9c9b          	slliw	s9,s9,0x1
    800062ea:	1c82                	slli	s9,s9,0x20
    800062ec:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800062f0:	0001c517          	auipc	a0,0x1c
    800062f4:	c0850513          	addi	a0,a0,-1016 # 80021ef8 <disk+0x128>
    800062f8:	ffffb097          	auipc	ra,0xffffb
    800062fc:	9a2080e7          	jalr	-1630(ra) # 80000c9a <acquire>
  for(int i = 0; i < 3; i++){
    80006300:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006302:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006304:	0001cb17          	auipc	s6,0x1c
    80006308:	accb0b13          	addi	s6,s6,-1332 # 80021dd0 <disk>
  for(int i = 0; i < 3; i++){
    8000630c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000630e:	0001cc17          	auipc	s8,0x1c
    80006312:	beac0c13          	addi	s8,s8,-1046 # 80021ef8 <disk+0x128>
    80006316:	a095                	j	8000637a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006318:	00fb0733          	add	a4,s6,a5
    8000631c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006320:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006322:	0207c563          	bltz	a5,8000634c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006326:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006328:	0591                	addi	a1,a1,4
    8000632a:	05560d63          	beq	a2,s5,80006384 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000632e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006330:	0001c717          	auipc	a4,0x1c
    80006334:	aa070713          	addi	a4,a4,-1376 # 80021dd0 <disk>
    80006338:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000633a:	01874683          	lbu	a3,24(a4)
    8000633e:	fee9                	bnez	a3,80006318 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006340:	2785                	addiw	a5,a5,1
    80006342:	0705                	addi	a4,a4,1
    80006344:	fe979be3          	bne	a5,s1,8000633a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006348:	57fd                	li	a5,-1
    8000634a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000634c:	00c05e63          	blez	a2,80006368 <virtio_disk_rw+0xa6>
    80006350:	060a                	slli	a2,a2,0x2
    80006352:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006356:	0009a503          	lw	a0,0(s3)
    8000635a:	00000097          	auipc	ra,0x0
    8000635e:	cfc080e7          	jalr	-772(ra) # 80006056 <free_desc>
      for(int j = 0; j < i; j++)
    80006362:	0991                	addi	s3,s3,4
    80006364:	ffa999e3          	bne	s3,s10,80006356 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006368:	85e2                	mv	a1,s8
    8000636a:	0001c517          	auipc	a0,0x1c
    8000636e:	a7e50513          	addi	a0,a0,-1410 # 80021de8 <disk+0x18>
    80006372:	ffffc097          	auipc	ra,0xffffc
    80006376:	f58080e7          	jalr	-168(ra) # 800022ca <sleep>
  for(int i = 0; i < 3; i++){
    8000637a:	f9040993          	addi	s3,s0,-112
{
    8000637e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006380:	864a                	mv	a2,s2
    80006382:	b775                	j	8000632e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006384:	f9042503          	lw	a0,-112(s0)
    80006388:	00a50713          	addi	a4,a0,10
    8000638c:	0712                	slli	a4,a4,0x4

  if(write)
    8000638e:	0001c797          	auipc	a5,0x1c
    80006392:	a4278793          	addi	a5,a5,-1470 # 80021dd0 <disk>
    80006396:	00e786b3          	add	a3,a5,a4
    8000639a:	01703633          	snez	a2,s7
    8000639e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800063a0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800063a4:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800063a8:	f6070613          	addi	a2,a4,-160
    800063ac:	6394                	ld	a3,0(a5)
    800063ae:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063b0:	00870593          	addi	a1,a4,8
    800063b4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800063b6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800063b8:	0007b803          	ld	a6,0(a5)
    800063bc:	9642                	add	a2,a2,a6
    800063be:	46c1                	li	a3,16
    800063c0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063c2:	4585                	li	a1,1
    800063c4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800063c8:	f9442683          	lw	a3,-108(s0)
    800063cc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800063d0:	0692                	slli	a3,a3,0x4
    800063d2:	9836                	add	a6,a6,a3
    800063d4:	058a0613          	addi	a2,s4,88
    800063d8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800063dc:	0007b803          	ld	a6,0(a5)
    800063e0:	96c2                	add	a3,a3,a6
    800063e2:	40000613          	li	a2,1024
    800063e6:	c690                	sw	a2,8(a3)
  if(write)
    800063e8:	001bb613          	seqz	a2,s7
    800063ec:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800063f0:	00166613          	ori	a2,a2,1
    800063f4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800063f8:	f9842603          	lw	a2,-104(s0)
    800063fc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006400:	00250693          	addi	a3,a0,2
    80006404:	0692                	slli	a3,a3,0x4
    80006406:	96be                	add	a3,a3,a5
    80006408:	58fd                	li	a7,-1
    8000640a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000640e:	0612                	slli	a2,a2,0x4
    80006410:	9832                	add	a6,a6,a2
    80006412:	f9070713          	addi	a4,a4,-112
    80006416:	973e                	add	a4,a4,a5
    80006418:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000641c:	6398                	ld	a4,0(a5)
    8000641e:	9732                	add	a4,a4,a2
    80006420:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006422:	4609                	li	a2,2
    80006424:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006428:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000642c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006430:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006434:	6794                	ld	a3,8(a5)
    80006436:	0026d703          	lhu	a4,2(a3)
    8000643a:	8b1d                	andi	a4,a4,7
    8000643c:	0706                	slli	a4,a4,0x1
    8000643e:	96ba                	add	a3,a3,a4
    80006440:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006444:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006448:	6798                	ld	a4,8(a5)
    8000644a:	00275783          	lhu	a5,2(a4)
    8000644e:	2785                	addiw	a5,a5,1
    80006450:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006454:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006458:	100017b7          	lui	a5,0x10001
    8000645c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006460:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006464:	0001c917          	auipc	s2,0x1c
    80006468:	a9490913          	addi	s2,s2,-1388 # 80021ef8 <disk+0x128>
  while(b->disk == 1) {
    8000646c:	4485                	li	s1,1
    8000646e:	00b79c63          	bne	a5,a1,80006486 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006472:	85ca                	mv	a1,s2
    80006474:	8552                	mv	a0,s4
    80006476:	ffffc097          	auipc	ra,0xffffc
    8000647a:	e54080e7          	jalr	-428(ra) # 800022ca <sleep>
  while(b->disk == 1) {
    8000647e:	004a2783          	lw	a5,4(s4)
    80006482:	fe9788e3          	beq	a5,s1,80006472 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006486:	f9042903          	lw	s2,-112(s0)
    8000648a:	00290713          	addi	a4,s2,2
    8000648e:	0712                	slli	a4,a4,0x4
    80006490:	0001c797          	auipc	a5,0x1c
    80006494:	94078793          	addi	a5,a5,-1728 # 80021dd0 <disk>
    80006498:	97ba                	add	a5,a5,a4
    8000649a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000649e:	0001c997          	auipc	s3,0x1c
    800064a2:	93298993          	addi	s3,s3,-1742 # 80021dd0 <disk>
    800064a6:	00491713          	slli	a4,s2,0x4
    800064aa:	0009b783          	ld	a5,0(s3)
    800064ae:	97ba                	add	a5,a5,a4
    800064b0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800064b4:	854a                	mv	a0,s2
    800064b6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800064ba:	00000097          	auipc	ra,0x0
    800064be:	b9c080e7          	jalr	-1124(ra) # 80006056 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800064c2:	8885                	andi	s1,s1,1
    800064c4:	f0ed                	bnez	s1,800064a6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800064c6:	0001c517          	auipc	a0,0x1c
    800064ca:	a3250513          	addi	a0,a0,-1486 # 80021ef8 <disk+0x128>
    800064ce:	ffffb097          	auipc	ra,0xffffb
    800064d2:	880080e7          	jalr	-1920(ra) # 80000d4e <release>
}
    800064d6:	70a6                	ld	ra,104(sp)
    800064d8:	7406                	ld	s0,96(sp)
    800064da:	64e6                	ld	s1,88(sp)
    800064dc:	6946                	ld	s2,80(sp)
    800064de:	69a6                	ld	s3,72(sp)
    800064e0:	6a06                	ld	s4,64(sp)
    800064e2:	7ae2                	ld	s5,56(sp)
    800064e4:	7b42                	ld	s6,48(sp)
    800064e6:	7ba2                	ld	s7,40(sp)
    800064e8:	7c02                	ld	s8,32(sp)
    800064ea:	6ce2                	ld	s9,24(sp)
    800064ec:	6d42                	ld	s10,16(sp)
    800064ee:	6165                	addi	sp,sp,112
    800064f0:	8082                	ret

00000000800064f2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800064f2:	1101                	addi	sp,sp,-32
    800064f4:	ec06                	sd	ra,24(sp)
    800064f6:	e822                	sd	s0,16(sp)
    800064f8:	e426                	sd	s1,8(sp)
    800064fa:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800064fc:	0001c497          	auipc	s1,0x1c
    80006500:	8d448493          	addi	s1,s1,-1836 # 80021dd0 <disk>
    80006504:	0001c517          	auipc	a0,0x1c
    80006508:	9f450513          	addi	a0,a0,-1548 # 80021ef8 <disk+0x128>
    8000650c:	ffffa097          	auipc	ra,0xffffa
    80006510:	78e080e7          	jalr	1934(ra) # 80000c9a <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006514:	10001737          	lui	a4,0x10001
    80006518:	533c                	lw	a5,96(a4)
    8000651a:	8b8d                	andi	a5,a5,3
    8000651c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000651e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006522:	689c                	ld	a5,16(s1)
    80006524:	0204d703          	lhu	a4,32(s1)
    80006528:	0027d783          	lhu	a5,2(a5)
    8000652c:	04f70863          	beq	a4,a5,8000657c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006530:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006534:	6898                	ld	a4,16(s1)
    80006536:	0204d783          	lhu	a5,32(s1)
    8000653a:	8b9d                	andi	a5,a5,7
    8000653c:	078e                	slli	a5,a5,0x3
    8000653e:	97ba                	add	a5,a5,a4
    80006540:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006542:	00278713          	addi	a4,a5,2
    80006546:	0712                	slli	a4,a4,0x4
    80006548:	9726                	add	a4,a4,s1
    8000654a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000654e:	e721                	bnez	a4,80006596 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006550:	0789                	addi	a5,a5,2
    80006552:	0792                	slli	a5,a5,0x4
    80006554:	97a6                	add	a5,a5,s1
    80006556:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006558:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000655c:	ffffc097          	auipc	ra,0xffffc
    80006560:	dd2080e7          	jalr	-558(ra) # 8000232e <wakeup>

    disk.used_idx += 1;
    80006564:	0204d783          	lhu	a5,32(s1)
    80006568:	2785                	addiw	a5,a5,1
    8000656a:	17c2                	slli	a5,a5,0x30
    8000656c:	93c1                	srli	a5,a5,0x30
    8000656e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006572:	6898                	ld	a4,16(s1)
    80006574:	00275703          	lhu	a4,2(a4)
    80006578:	faf71ce3          	bne	a4,a5,80006530 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000657c:	0001c517          	auipc	a0,0x1c
    80006580:	97c50513          	addi	a0,a0,-1668 # 80021ef8 <disk+0x128>
    80006584:	ffffa097          	auipc	ra,0xffffa
    80006588:	7ca080e7          	jalr	1994(ra) # 80000d4e <release>
}
    8000658c:	60e2                	ld	ra,24(sp)
    8000658e:	6442                	ld	s0,16(sp)
    80006590:	64a2                	ld	s1,8(sp)
    80006592:	6105                	addi	sp,sp,32
    80006594:	8082                	ret
      panic("virtio_disk_intr status");
    80006596:	00002517          	auipc	a0,0x2
    8000659a:	41a50513          	addi	a0,a0,1050 # 800089b0 <__func__.0+0x338>
    8000659e:	ffffa097          	auipc	ra,0xffffa
    800065a2:	f9e080e7          	jalr	-98(ra) # 8000053c <panic>
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
