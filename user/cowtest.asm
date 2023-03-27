
user/_cowtest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <testcase4>:

int global_array[16777216] = {0};
int global_var = 0;

void testcase4()
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	e04a                	sd	s2,0(sp)
   a:	1000                	addi	s0,sp,32
    int pid;

    printf("\n----- Test case 4 -----\n");
   c:	00001517          	auipc	a0,0x1
  10:	d2450513          	addi	a0,a0,-732 # d30 <malloc+0xee>
  14:	00001097          	auipc	ra,0x1
  18:	b76080e7          	jalr	-1162(ra) # b8a <printf>
    printf("[prnt] v1 --> ");
  1c:	00001517          	auipc	a0,0x1
  20:	d3450513          	addi	a0,a0,-716 # d50 <malloc+0x10e>
  24:	00001097          	auipc	ra,0x1
  28:	b66080e7          	jalr	-1178(ra) # b8a <printf>
    print_free_frame_cnt();
  2c:	00001097          	auipc	ra,0x1
  30:	88e080e7          	jalr	-1906(ra) # 8ba <pfreepages>

    if ((pid = fork()) == 0)
  34:	00000097          	auipc	ra,0x0
  38:	7be080e7          	jalr	1982(ra) # 7f2 <fork>
  3c:	c545                	beqz	a0,e4 <testcase4+0xe4>
  3e:	84aa                	mv	s1,a0
        exit(0);
    }
    else
    {
        // parent
        printf("[prnt] v2 --> ");
  40:	00001517          	auipc	a0,0x1
  44:	e1050513          	addi	a0,a0,-496 # e50 <malloc+0x20e>
  48:	00001097          	auipc	ra,0x1
  4c:	b42080e7          	jalr	-1214(ra) # b8a <printf>
        print_free_frame_cnt();
  50:	00001097          	auipc	ra,0x1
  54:	86a080e7          	jalr	-1942(ra) # 8ba <pfreepages>

        global_array[0] = 111;
  58:	00002917          	auipc	s2,0x2
  5c:	fb890913          	addi	s2,s2,-72 # 2010 <global_array>
  60:	06f00793          	li	a5,111
  64:	00f92023          	sw	a5,0(s2)
        printf("[prnt] modified one element in the 1st page, global_array[0]=%d\n", global_array[0]);
  68:	06f00593          	li	a1,111
  6c:	00001517          	auipc	a0,0x1
  70:	df450513          	addi	a0,a0,-524 # e60 <malloc+0x21e>
  74:	00001097          	auipc	ra,0x1
  78:	b16080e7          	jalr	-1258(ra) # b8a <printf>

        printf("[prnt] v3 --> ");
  7c:	00001517          	auipc	a0,0x1
  80:	e2c50513          	addi	a0,a0,-468 # ea8 <malloc+0x266>
  84:	00001097          	auipc	ra,0x1
  88:	b06080e7          	jalr	-1274(ra) # b8a <printf>
        print_free_frame_cnt();
  8c:	00001097          	auipc	ra,0x1
  90:	82e080e7          	jalr	-2002(ra) # 8ba <pfreepages>
        printf("[prnt] pa3 --> 0x%x\n", va2pa((uint64)&global_array[0], 0));
  94:	4581                	li	a1,0
  96:	854a                	mv	a0,s2
  98:	00001097          	auipc	ra,0x1
  9c:	81a080e7          	jalr	-2022(ra) # 8b2 <va2pa>
  a0:	85aa                	mv	a1,a0
  a2:	00001517          	auipc	a0,0x1
  a6:	e1650513          	addi	a0,a0,-490 # eb8 <malloc+0x276>
  aa:	00001097          	auipc	ra,0x1
  ae:	ae0080e7          	jalr	-1312(ra) # b8a <printf>
    }

    if (wait(0) != pid)
  b2:	4501                	li	a0,0
  b4:	00000097          	auipc	ra,0x0
  b8:	74e080e7          	jalr	1870(ra) # 802 <wait>
  bc:	10951263          	bne	a0,s1,1c0 <testcase4+0x1c0>
    {
        printf("wait() error!");
        exit(1);
    }

    printf("[prnt] v7 --> ");
  c0:	00001517          	auipc	a0,0x1
  c4:	e2050513          	addi	a0,a0,-480 # ee0 <malloc+0x29e>
  c8:	00001097          	auipc	ra,0x1
  cc:	ac2080e7          	jalr	-1342(ra) # b8a <printf>
    print_free_frame_cnt();
  d0:	00000097          	auipc	ra,0x0
  d4:	7ea080e7          	jalr	2026(ra) # 8ba <pfreepages>
}
  d8:	60e2                	ld	ra,24(sp)
  da:	6442                	ld	s0,16(sp)
  dc:	64a2                	ld	s1,8(sp)
  de:	6902                	ld	s2,0(sp)
  e0:	6105                	addi	sp,sp,32
  e2:	8082                	ret
        sleep(50);
  e4:	03200513          	li	a0,50
  e8:	00000097          	auipc	ra,0x0
  ec:	7a2080e7          	jalr	1954(ra) # 88a <sleep>
        printf("[chld] pa1 --> 0x%x\n", va2pa((uint64)&global_array[0], 0));
  f0:	00002497          	auipc	s1,0x2
  f4:	f2048493          	addi	s1,s1,-224 # 2010 <global_array>
  f8:	4581                	li	a1,0
  fa:	8526                	mv	a0,s1
  fc:	00000097          	auipc	ra,0x0
 100:	7b6080e7          	jalr	1974(ra) # 8b2 <va2pa>
 104:	85aa                	mv	a1,a0
 106:	00001517          	auipc	a0,0x1
 10a:	c5a50513          	addi	a0,a0,-934 # d60 <malloc+0x11e>
 10e:	00001097          	auipc	ra,0x1
 112:	a7c080e7          	jalr	-1412(ra) # b8a <printf>
        printf("[chld] v4 --> ");
 116:	00001517          	auipc	a0,0x1
 11a:	c6250513          	addi	a0,a0,-926 # d78 <malloc+0x136>
 11e:	00001097          	auipc	ra,0x1
 122:	a6c080e7          	jalr	-1428(ra) # b8a <printf>
        print_free_frame_cnt();
 126:	00000097          	auipc	ra,0x0
 12a:	794080e7          	jalr	1940(ra) # 8ba <pfreepages>
        global_array[0] = 222;
 12e:	0de00793          	li	a5,222
 132:	c09c                	sw	a5,0(s1)
        printf("[chld] modified one element in the 1st page, global_array[0]=%d\n", global_array[0]);
 134:	0de00593          	li	a1,222
 138:	00001517          	auipc	a0,0x1
 13c:	c5050513          	addi	a0,a0,-944 # d88 <malloc+0x146>
 140:	00001097          	auipc	ra,0x1
 144:	a4a080e7          	jalr	-1462(ra) # b8a <printf>
        printf("[chld] pa2 --> 0x%x\n", va2pa((uint64)&global_array[0], 0));
 148:	4581                	li	a1,0
 14a:	8526                	mv	a0,s1
 14c:	00000097          	auipc	ra,0x0
 150:	766080e7          	jalr	1894(ra) # 8b2 <va2pa>
 154:	85aa                	mv	a1,a0
 156:	00001517          	auipc	a0,0x1
 15a:	c7a50513          	addi	a0,a0,-902 # dd0 <malloc+0x18e>
 15e:	00001097          	auipc	ra,0x1
 162:	a2c080e7          	jalr	-1492(ra) # b8a <printf>
        printf("[chld] v5 --> ");
 166:	00001517          	auipc	a0,0x1
 16a:	c8250513          	addi	a0,a0,-894 # de8 <malloc+0x1a6>
 16e:	00001097          	auipc	ra,0x1
 172:	a1c080e7          	jalr	-1508(ra) # b8a <printf>
        print_free_frame_cnt();
 176:	00000097          	auipc	ra,0x0
 17a:	744080e7          	jalr	1860(ra) # 8ba <pfreepages>
        global_array[2047] = 333;
 17e:	14d00793          	li	a5,333
 182:	00004717          	auipc	a4,0x4
 186:	e8f72523          	sw	a5,-374(a4) # 400c <global_array+0x1ffc>
        printf("[chld] modified two elements in the 2nd page, global_array[2047]=%d\n", global_array[2047]);
 18a:	14d00593          	li	a1,333
 18e:	00001517          	auipc	a0,0x1
 192:	c6a50513          	addi	a0,a0,-918 # df8 <malloc+0x1b6>
 196:	00001097          	auipc	ra,0x1
 19a:	9f4080e7          	jalr	-1548(ra) # b8a <printf>
        printf("[chld] v6 --> ");
 19e:	00001517          	auipc	a0,0x1
 1a2:	ca250513          	addi	a0,a0,-862 # e40 <malloc+0x1fe>
 1a6:	00001097          	auipc	ra,0x1
 1aa:	9e4080e7          	jalr	-1564(ra) # b8a <printf>
        print_free_frame_cnt();
 1ae:	00000097          	auipc	ra,0x0
 1b2:	70c080e7          	jalr	1804(ra) # 8ba <pfreepages>
        exit(0);
 1b6:	4501                	li	a0,0
 1b8:	00000097          	auipc	ra,0x0
 1bc:	642080e7          	jalr	1602(ra) # 7fa <exit>
        printf("wait() error!");
 1c0:	00001517          	auipc	a0,0x1
 1c4:	d1050513          	addi	a0,a0,-752 # ed0 <malloc+0x28e>
 1c8:	00001097          	auipc	ra,0x1
 1cc:	9c2080e7          	jalr	-1598(ra) # b8a <printf>
        exit(1);
 1d0:	4505                	li	a0,1
 1d2:	00000097          	auipc	ra,0x0
 1d6:	628080e7          	jalr	1576(ra) # 7fa <exit>

00000000000001da <testcase3>:

void testcase3()
{
 1da:	1101                	addi	sp,sp,-32
 1dc:	ec06                	sd	ra,24(sp)
 1de:	e822                	sd	s0,16(sp)
 1e0:	e426                	sd	s1,8(sp)
 1e2:	1000                	addi	s0,sp,32
    int pid;

    printf("\n----- Test case 3 -----\n");
 1e4:	00001517          	auipc	a0,0x1
 1e8:	d0c50513          	addi	a0,a0,-756 # ef0 <malloc+0x2ae>
 1ec:	00001097          	auipc	ra,0x1
 1f0:	99e080e7          	jalr	-1634(ra) # b8a <printf>
    printf("[prnt] v1 --> ");
 1f4:	00001517          	auipc	a0,0x1
 1f8:	b5c50513          	addi	a0,a0,-1188 # d50 <malloc+0x10e>
 1fc:	00001097          	auipc	ra,0x1
 200:	98e080e7          	jalr	-1650(ra) # b8a <printf>
    print_free_frame_cnt();
 204:	00000097          	auipc	ra,0x0
 208:	6b6080e7          	jalr	1718(ra) # 8ba <pfreepages>

    if ((pid = fork()) == 0)
 20c:	00000097          	auipc	ra,0x0
 210:	5e6080e7          	jalr	1510(ra) # 7f2 <fork>
 214:	cd35                	beqz	a0,290 <testcase3+0xb6>
 216:	84aa                	mv	s1,a0
        exit(0);
    }
    else
    {
        // parent
        printf("[prnt] v2 --> ");
 218:	00001517          	auipc	a0,0x1
 21c:	c3850513          	addi	a0,a0,-968 # e50 <malloc+0x20e>
 220:	00001097          	auipc	ra,0x1
 224:	96a080e7          	jalr	-1686(ra) # b8a <printf>
        print_free_frame_cnt();
 228:	00000097          	auipc	ra,0x0
 22c:	692080e7          	jalr	1682(ra) # 8ba <pfreepages>

        printf("[prnt] read global_var, global_var=%d\n", global_var);
 230:	00002597          	auipc	a1,0x2
 234:	dd05a583          	lw	a1,-560(a1) # 2000 <global_var>
 238:	00001517          	auipc	a0,0x1
 23c:	d0850513          	addi	a0,a0,-760 # f40 <malloc+0x2fe>
 240:	00001097          	auipc	ra,0x1
 244:	94a080e7          	jalr	-1718(ra) # b8a <printf>

        printf("[prnt] v3 --> ");
 248:	00001517          	auipc	a0,0x1
 24c:	c6050513          	addi	a0,a0,-928 # ea8 <malloc+0x266>
 250:	00001097          	auipc	ra,0x1
 254:	93a080e7          	jalr	-1734(ra) # b8a <printf>
        print_free_frame_cnt();
 258:	00000097          	auipc	ra,0x0
 25c:	662080e7          	jalr	1634(ra) # 8ba <pfreepages>
    }

    if (wait(0) != pid)
 260:	4501                	li	a0,0
 262:	00000097          	auipc	ra,0x0
 266:	5a0080e7          	jalr	1440(ra) # 802 <wait>
 26a:	08951663          	bne	a0,s1,2f6 <testcase3+0x11c>
    {
        printf("wait() error!");
        exit(1);
    }

    printf("[prnt] v6 --> ");
 26e:	00001517          	auipc	a0,0x1
 272:	cfa50513          	addi	a0,a0,-774 # f68 <malloc+0x326>
 276:	00001097          	auipc	ra,0x1
 27a:	914080e7          	jalr	-1772(ra) # b8a <printf>
    print_free_frame_cnt();
 27e:	00000097          	auipc	ra,0x0
 282:	63c080e7          	jalr	1596(ra) # 8ba <pfreepages>
}
 286:	60e2                	ld	ra,24(sp)
 288:	6442                	ld	s0,16(sp)
 28a:	64a2                	ld	s1,8(sp)
 28c:	6105                	addi	sp,sp,32
 28e:	8082                	ret
        sleep(50);
 290:	03200513          	li	a0,50
 294:	00000097          	auipc	ra,0x0
 298:	5f6080e7          	jalr	1526(ra) # 88a <sleep>
        printf("[chld] v4 --> ");
 29c:	00001517          	auipc	a0,0x1
 2a0:	adc50513          	addi	a0,a0,-1316 # d78 <malloc+0x136>
 2a4:	00001097          	auipc	ra,0x1
 2a8:	8e6080e7          	jalr	-1818(ra) # b8a <printf>
        print_free_frame_cnt();
 2ac:	00000097          	auipc	ra,0x0
 2b0:	60e080e7          	jalr	1550(ra) # 8ba <pfreepages>
        global_var = 100;
 2b4:	06400793          	li	a5,100
 2b8:	00002717          	auipc	a4,0x2
 2bc:	d4f72423          	sw	a5,-696(a4) # 2000 <global_var>
        printf("[chld] modified global_var, global_var=%d\n", global_var);
 2c0:	06400593          	li	a1,100
 2c4:	00001517          	auipc	a0,0x1
 2c8:	c4c50513          	addi	a0,a0,-948 # f10 <malloc+0x2ce>
 2cc:	00001097          	auipc	ra,0x1
 2d0:	8be080e7          	jalr	-1858(ra) # b8a <printf>
        printf("[chld] v5 --> ");
 2d4:	00001517          	auipc	a0,0x1
 2d8:	b1450513          	addi	a0,a0,-1260 # de8 <malloc+0x1a6>
 2dc:	00001097          	auipc	ra,0x1
 2e0:	8ae080e7          	jalr	-1874(ra) # b8a <printf>
        print_free_frame_cnt();
 2e4:	00000097          	auipc	ra,0x0
 2e8:	5d6080e7          	jalr	1494(ra) # 8ba <pfreepages>
        exit(0);
 2ec:	4501                	li	a0,0
 2ee:	00000097          	auipc	ra,0x0
 2f2:	50c080e7          	jalr	1292(ra) # 7fa <exit>
        printf("wait() error!");
 2f6:	00001517          	auipc	a0,0x1
 2fa:	bda50513          	addi	a0,a0,-1062 # ed0 <malloc+0x28e>
 2fe:	00001097          	auipc	ra,0x1
 302:	88c080e7          	jalr	-1908(ra) # b8a <printf>
        exit(1);
 306:	4505                	li	a0,1
 308:	00000097          	auipc	ra,0x0
 30c:	4f2080e7          	jalr	1266(ra) # 7fa <exit>

0000000000000310 <testcase2>:

void testcase2()
{
 310:	1101                	addi	sp,sp,-32
 312:	ec06                	sd	ra,24(sp)
 314:	e822                	sd	s0,16(sp)
 316:	e426                	sd	s1,8(sp)
 318:	1000                	addi	s0,sp,32
    int pid;

    printf("\n----- Test case 2 -----\n");
 31a:	00001517          	auipc	a0,0x1
 31e:	c5e50513          	addi	a0,a0,-930 # f78 <malloc+0x336>
 322:	00001097          	auipc	ra,0x1
 326:	868080e7          	jalr	-1944(ra) # b8a <printf>
    printf("[prnt] v1 --> ");
 32a:	00001517          	auipc	a0,0x1
 32e:	a2650513          	addi	a0,a0,-1498 # d50 <malloc+0x10e>
 332:	00001097          	auipc	ra,0x1
 336:	858080e7          	jalr	-1960(ra) # b8a <printf>
    print_free_frame_cnt();
 33a:	00000097          	auipc	ra,0x0
 33e:	580080e7          	jalr	1408(ra) # 8ba <pfreepages>

    if ((pid = fork()) == 0)
 342:	00000097          	auipc	ra,0x0
 346:	4b0080e7          	jalr	1200(ra) # 7f2 <fork>
 34a:	c531                	beqz	a0,396 <testcase2+0x86>
 34c:	84aa                	mv	s1,a0
        exit(0);
    }
    else
    {
        // parent
        printf("[prnt] v2 --> ");
 34e:	00001517          	auipc	a0,0x1
 352:	b0250513          	addi	a0,a0,-1278 # e50 <malloc+0x20e>
 356:	00001097          	auipc	ra,0x1
 35a:	834080e7          	jalr	-1996(ra) # b8a <printf>
        print_free_frame_cnt();
 35e:	00000097          	auipc	ra,0x0
 362:	55c080e7          	jalr	1372(ra) # 8ba <pfreepages>
    }

    if (wait(0) != pid)
 366:	4501                	li	a0,0
 368:	00000097          	auipc	ra,0x0
 36c:	49a080e7          	jalr	1178(ra) # 802 <wait>
 370:	08951263          	bne	a0,s1,3f4 <testcase2+0xe4>
    {
        printf("wait() error!");
        exit(1);
    }

    printf("[prnt] v5 --> ");
 374:	00001517          	auipc	a0,0x1
 378:	c5c50513          	addi	a0,a0,-932 # fd0 <malloc+0x38e>
 37c:	00001097          	auipc	ra,0x1
 380:	80e080e7          	jalr	-2034(ra) # b8a <printf>
    print_free_frame_cnt();
 384:	00000097          	auipc	ra,0x0
 388:	536080e7          	jalr	1334(ra) # 8ba <pfreepages>
}
 38c:	60e2                	ld	ra,24(sp)
 38e:	6442                	ld	s0,16(sp)
 390:	64a2                	ld	s1,8(sp)
 392:	6105                	addi	sp,sp,32
 394:	8082                	ret
        sleep(50);
 396:	03200513          	li	a0,50
 39a:	00000097          	auipc	ra,0x0
 39e:	4f0080e7          	jalr	1264(ra) # 88a <sleep>
        printf("[chld] v3 --> ");
 3a2:	00001517          	auipc	a0,0x1
 3a6:	bf650513          	addi	a0,a0,-1034 # f98 <malloc+0x356>
 3aa:	00000097          	auipc	ra,0x0
 3ae:	7e0080e7          	jalr	2016(ra) # b8a <printf>
        print_free_frame_cnt();
 3b2:	00000097          	auipc	ra,0x0
 3b6:	508080e7          	jalr	1288(ra) # 8ba <pfreepages>
        printf("[chld] read global_var, global_var=%d\n", global_var);
 3ba:	00002597          	auipc	a1,0x2
 3be:	c465a583          	lw	a1,-954(a1) # 2000 <global_var>
 3c2:	00001517          	auipc	a0,0x1
 3c6:	be650513          	addi	a0,a0,-1050 # fa8 <malloc+0x366>
 3ca:	00000097          	auipc	ra,0x0
 3ce:	7c0080e7          	jalr	1984(ra) # b8a <printf>
        printf("[chld] v4 --> ");
 3d2:	00001517          	auipc	a0,0x1
 3d6:	9a650513          	addi	a0,a0,-1626 # d78 <malloc+0x136>
 3da:	00000097          	auipc	ra,0x0
 3de:	7b0080e7          	jalr	1968(ra) # b8a <printf>
        print_free_frame_cnt();
 3e2:	00000097          	auipc	ra,0x0
 3e6:	4d8080e7          	jalr	1240(ra) # 8ba <pfreepages>
        exit(0);
 3ea:	4501                	li	a0,0
 3ec:	00000097          	auipc	ra,0x0
 3f0:	40e080e7          	jalr	1038(ra) # 7fa <exit>
        printf("wait() error!");
 3f4:	00001517          	auipc	a0,0x1
 3f8:	adc50513          	addi	a0,a0,-1316 # ed0 <malloc+0x28e>
 3fc:	00000097          	auipc	ra,0x0
 400:	78e080e7          	jalr	1934(ra) # b8a <printf>
        exit(1);
 404:	4505                	li	a0,1
 406:	00000097          	auipc	ra,0x0
 40a:	3f4080e7          	jalr	1012(ra) # 7fa <exit>

000000000000040e <testcase1>:

void testcase1()
{
 40e:	1101                	addi	sp,sp,-32
 410:	ec06                	sd	ra,24(sp)
 412:	e822                	sd	s0,16(sp)
 414:	e426                	sd	s1,8(sp)
 416:	1000                	addi	s0,sp,32
    int pid;

    printf("\n----- Test case 1 -----\n");
 418:	00001517          	auipc	a0,0x1
 41c:	bc850513          	addi	a0,a0,-1080 # fe0 <malloc+0x39e>
 420:	00000097          	auipc	ra,0x0
 424:	76a080e7          	jalr	1898(ra) # b8a <printf>
    printf("[prnt] v1 --> ");
 428:	00001517          	auipc	a0,0x1
 42c:	92850513          	addi	a0,a0,-1752 # d50 <malloc+0x10e>
 430:	00000097          	auipc	ra,0x0
 434:	75a080e7          	jalr	1882(ra) # b8a <printf>
    print_free_frame_cnt();
 438:	00000097          	auipc	ra,0x0
 43c:	482080e7          	jalr	1154(ra) # 8ba <pfreepages>

    if ((pid = fork()) == 0)
 440:	00000097          	auipc	ra,0x0
 444:	3b2080e7          	jalr	946(ra) # 7f2 <fork>
 448:	c531                	beqz	a0,494 <testcase1+0x86>
 44a:	84aa                	mv	s1,a0
        exit(0);
    }
    else
    {
        // parent
        printf("[prnt] v3 --> ");
 44c:	00001517          	auipc	a0,0x1
 450:	a5c50513          	addi	a0,a0,-1444 # ea8 <malloc+0x266>
 454:	00000097          	auipc	ra,0x0
 458:	736080e7          	jalr	1846(ra) # b8a <printf>
        print_free_frame_cnt();
 45c:	00000097          	auipc	ra,0x0
 460:	45e080e7          	jalr	1118(ra) # 8ba <pfreepages>
    }

    if (wait(0) != pid)
 464:	4501                	li	a0,0
 466:	00000097          	auipc	ra,0x0
 46a:	39c080e7          	jalr	924(ra) # 802 <wait>
 46e:	04951a63          	bne	a0,s1,4c2 <testcase1+0xb4>
    {
        printf("wait() error!");
        exit(1);
    }

    printf("[prnt] v4 --> ");
 472:	00001517          	auipc	a0,0x1
 476:	b9e50513          	addi	a0,a0,-1122 # 1010 <malloc+0x3ce>
 47a:	00000097          	auipc	ra,0x0
 47e:	710080e7          	jalr	1808(ra) # b8a <printf>
    print_free_frame_cnt();
 482:	00000097          	auipc	ra,0x0
 486:	438080e7          	jalr	1080(ra) # 8ba <pfreepages>
}
 48a:	60e2                	ld	ra,24(sp)
 48c:	6442                	ld	s0,16(sp)
 48e:	64a2                	ld	s1,8(sp)
 490:	6105                	addi	sp,sp,32
 492:	8082                	ret
        sleep(50);
 494:	03200513          	li	a0,50
 498:	00000097          	auipc	ra,0x0
 49c:	3f2080e7          	jalr	1010(ra) # 88a <sleep>
        printf("[chld] v2 --> ");
 4a0:	00001517          	auipc	a0,0x1
 4a4:	b6050513          	addi	a0,a0,-1184 # 1000 <malloc+0x3be>
 4a8:	00000097          	auipc	ra,0x0
 4ac:	6e2080e7          	jalr	1762(ra) # b8a <printf>
        print_free_frame_cnt();
 4b0:	00000097          	auipc	ra,0x0
 4b4:	40a080e7          	jalr	1034(ra) # 8ba <pfreepages>
        exit(0);
 4b8:	4501                	li	a0,0
 4ba:	00000097          	auipc	ra,0x0
 4be:	340080e7          	jalr	832(ra) # 7fa <exit>
        printf("wait() error!");
 4c2:	00001517          	auipc	a0,0x1
 4c6:	a0e50513          	addi	a0,a0,-1522 # ed0 <malloc+0x28e>
 4ca:	00000097          	auipc	ra,0x0
 4ce:	6c0080e7          	jalr	1728(ra) # b8a <printf>
        exit(1);
 4d2:	4505                	li	a0,1
 4d4:	00000097          	auipc	ra,0x0
 4d8:	326080e7          	jalr	806(ra) # 7fa <exit>

00000000000004dc <main>:

int main(int argc, char *argv[])
{
 4dc:	1101                	addi	sp,sp,-32
 4de:	ec06                	sd	ra,24(sp)
 4e0:	e822                	sd	s0,16(sp)
 4e2:	e426                	sd	s1,8(sp)
 4e4:	1000                	addi	s0,sp,32
 4e6:	84ae                	mv	s1,a1
    if (argc < 2)
 4e8:	4785                	li	a5,1
 4ea:	02a7d863          	bge	a5,a0,51a <main+0x3e>
    {
        printf("Usage: cowtest test_id");
    }
    switch (atoi(argv[1]))
 4ee:	6488                	ld	a0,8(s1)
 4f0:	00000097          	auipc	ra,0x0
 4f4:	210080e7          	jalr	528(ra) # 700 <atoi>
 4f8:	478d                	li	a5,3
 4fa:	04f50c63          	beq	a0,a5,552 <main+0x76>
 4fe:	02a7c763          	blt	a5,a0,52c <main+0x50>
 502:	4785                	li	a5,1
 504:	02f50d63          	beq	a0,a5,53e <main+0x62>
 508:	4789                	li	a5,2
 50a:	04f51a63          	bne	a0,a5,55e <main+0x82>
    case 1:
        testcase1();
        break;

    case 2:
        testcase2();
 50e:	00000097          	auipc	ra,0x0
 512:	e02080e7          	jalr	-510(ra) # 310 <testcase2>

    default:
        printf("Error: No test with index %s", argv[1]);
        return 1;
    }
    return 0;
 516:	4501                	li	a0,0
        break;
 518:	a805                	j	548 <main+0x6c>
        printf("Usage: cowtest test_id");
 51a:	00001517          	auipc	a0,0x1
 51e:	b0650513          	addi	a0,a0,-1274 # 1020 <malloc+0x3de>
 522:	00000097          	auipc	ra,0x0
 526:	668080e7          	jalr	1640(ra) # b8a <printf>
 52a:	b7d1                	j	4ee <main+0x12>
    switch (atoi(argv[1]))
 52c:	4791                	li	a5,4
 52e:	02f51863          	bne	a0,a5,55e <main+0x82>
        testcase4();
 532:	00000097          	auipc	ra,0x0
 536:	ace080e7          	jalr	-1330(ra) # 0 <testcase4>
    return 0;
 53a:	4501                	li	a0,0
        break;
 53c:	a031                	j	548 <main+0x6c>
        testcase1();
 53e:	00000097          	auipc	ra,0x0
 542:	ed0080e7          	jalr	-304(ra) # 40e <testcase1>
    return 0;
 546:	4501                	li	a0,0
 548:	60e2                	ld	ra,24(sp)
 54a:	6442                	ld	s0,16(sp)
 54c:	64a2                	ld	s1,8(sp)
 54e:	6105                	addi	sp,sp,32
 550:	8082                	ret
        testcase3();
 552:	00000097          	auipc	ra,0x0
 556:	c88080e7          	jalr	-888(ra) # 1da <testcase3>
    return 0;
 55a:	4501                	li	a0,0
        break;
 55c:	b7f5                	j	548 <main+0x6c>
        printf("Error: No test with index %s", argv[1]);
 55e:	648c                	ld	a1,8(s1)
 560:	00001517          	auipc	a0,0x1
 564:	ad850513          	addi	a0,a0,-1320 # 1038 <malloc+0x3f6>
 568:	00000097          	auipc	ra,0x0
 56c:	622080e7          	jalr	1570(ra) # b8a <printf>
        return 1;
 570:	4505                	li	a0,1
 572:	bfd9                	j	548 <main+0x6c>

0000000000000574 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 574:	1141                	addi	sp,sp,-16
 576:	e406                	sd	ra,8(sp)
 578:	e022                	sd	s0,0(sp)
 57a:	0800                	addi	s0,sp,16
  extern int main();
  main();
 57c:	00000097          	auipc	ra,0x0
 580:	f60080e7          	jalr	-160(ra) # 4dc <main>
  exit(0);
 584:	4501                	li	a0,0
 586:	00000097          	auipc	ra,0x0
 58a:	274080e7          	jalr	628(ra) # 7fa <exit>

000000000000058e <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 58e:	1141                	addi	sp,sp,-16
 590:	e422                	sd	s0,8(sp)
 592:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 594:	87aa                	mv	a5,a0
 596:	0585                	addi	a1,a1,1
 598:	0785                	addi	a5,a5,1
 59a:	fff5c703          	lbu	a4,-1(a1)
 59e:	fee78fa3          	sb	a4,-1(a5)
 5a2:	fb75                	bnez	a4,596 <strcpy+0x8>
    ;
  return os;
}
 5a4:	6422                	ld	s0,8(sp)
 5a6:	0141                	addi	sp,sp,16
 5a8:	8082                	ret

00000000000005aa <strcmp>:

int
strcmp(const char *p, const char *q)
{
 5aa:	1141                	addi	sp,sp,-16
 5ac:	e422                	sd	s0,8(sp)
 5ae:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 5b0:	00054783          	lbu	a5,0(a0)
 5b4:	cb91                	beqz	a5,5c8 <strcmp+0x1e>
 5b6:	0005c703          	lbu	a4,0(a1)
 5ba:	00f71763          	bne	a4,a5,5c8 <strcmp+0x1e>
    p++, q++;
 5be:	0505                	addi	a0,a0,1
 5c0:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 5c2:	00054783          	lbu	a5,0(a0)
 5c6:	fbe5                	bnez	a5,5b6 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 5c8:	0005c503          	lbu	a0,0(a1)
}
 5cc:	40a7853b          	subw	a0,a5,a0
 5d0:	6422                	ld	s0,8(sp)
 5d2:	0141                	addi	sp,sp,16
 5d4:	8082                	ret

00000000000005d6 <strlen>:

uint
strlen(const char *s)
{
 5d6:	1141                	addi	sp,sp,-16
 5d8:	e422                	sd	s0,8(sp)
 5da:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 5dc:	00054783          	lbu	a5,0(a0)
 5e0:	cf91                	beqz	a5,5fc <strlen+0x26>
 5e2:	0505                	addi	a0,a0,1
 5e4:	87aa                	mv	a5,a0
 5e6:	86be                	mv	a3,a5
 5e8:	0785                	addi	a5,a5,1
 5ea:	fff7c703          	lbu	a4,-1(a5)
 5ee:	ff65                	bnez	a4,5e6 <strlen+0x10>
 5f0:	40a6853b          	subw	a0,a3,a0
 5f4:	2505                	addiw	a0,a0,1
    ;
  return n;
}
 5f6:	6422                	ld	s0,8(sp)
 5f8:	0141                	addi	sp,sp,16
 5fa:	8082                	ret
  for(n = 0; s[n]; n++)
 5fc:	4501                	li	a0,0
 5fe:	bfe5                	j	5f6 <strlen+0x20>

0000000000000600 <memset>:

void*
memset(void *dst, int c, uint n)
{
 600:	1141                	addi	sp,sp,-16
 602:	e422                	sd	s0,8(sp)
 604:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 606:	ca19                	beqz	a2,61c <memset+0x1c>
 608:	87aa                	mv	a5,a0
 60a:	1602                	slli	a2,a2,0x20
 60c:	9201                	srli	a2,a2,0x20
 60e:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 612:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 616:	0785                	addi	a5,a5,1
 618:	fee79de3          	bne	a5,a4,612 <memset+0x12>
  }
  return dst;
}
 61c:	6422                	ld	s0,8(sp)
 61e:	0141                	addi	sp,sp,16
 620:	8082                	ret

0000000000000622 <strchr>:

char*
strchr(const char *s, char c)
{
 622:	1141                	addi	sp,sp,-16
 624:	e422                	sd	s0,8(sp)
 626:	0800                	addi	s0,sp,16
  for(; *s; s++)
 628:	00054783          	lbu	a5,0(a0)
 62c:	cb99                	beqz	a5,642 <strchr+0x20>
    if(*s == c)
 62e:	00f58763          	beq	a1,a5,63c <strchr+0x1a>
  for(; *s; s++)
 632:	0505                	addi	a0,a0,1
 634:	00054783          	lbu	a5,0(a0)
 638:	fbfd                	bnez	a5,62e <strchr+0xc>
      return (char*)s;
  return 0;
 63a:	4501                	li	a0,0
}
 63c:	6422                	ld	s0,8(sp)
 63e:	0141                	addi	sp,sp,16
 640:	8082                	ret
  return 0;
 642:	4501                	li	a0,0
 644:	bfe5                	j	63c <strchr+0x1a>

0000000000000646 <gets>:

char*
gets(char *buf, int max)
{
 646:	711d                	addi	sp,sp,-96
 648:	ec86                	sd	ra,88(sp)
 64a:	e8a2                	sd	s0,80(sp)
 64c:	e4a6                	sd	s1,72(sp)
 64e:	e0ca                	sd	s2,64(sp)
 650:	fc4e                	sd	s3,56(sp)
 652:	f852                	sd	s4,48(sp)
 654:	f456                	sd	s5,40(sp)
 656:	f05a                	sd	s6,32(sp)
 658:	ec5e                	sd	s7,24(sp)
 65a:	1080                	addi	s0,sp,96
 65c:	8baa                	mv	s7,a0
 65e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 660:	892a                	mv	s2,a0
 662:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 664:	4aa9                	li	s5,10
 666:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 668:	89a6                	mv	s3,s1
 66a:	2485                	addiw	s1,s1,1
 66c:	0344d863          	bge	s1,s4,69c <gets+0x56>
    cc = read(0, &c, 1);
 670:	4605                	li	a2,1
 672:	faf40593          	addi	a1,s0,-81
 676:	4501                	li	a0,0
 678:	00000097          	auipc	ra,0x0
 67c:	19a080e7          	jalr	410(ra) # 812 <read>
    if(cc < 1)
 680:	00a05e63          	blez	a0,69c <gets+0x56>
    buf[i++] = c;
 684:	faf44783          	lbu	a5,-81(s0)
 688:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 68c:	01578763          	beq	a5,s5,69a <gets+0x54>
 690:	0905                	addi	s2,s2,1
 692:	fd679be3          	bne	a5,s6,668 <gets+0x22>
  for(i=0; i+1 < max; ){
 696:	89a6                	mv	s3,s1
 698:	a011                	j	69c <gets+0x56>
 69a:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 69c:	99de                	add	s3,s3,s7
 69e:	00098023          	sb	zero,0(s3)
  return buf;
}
 6a2:	855e                	mv	a0,s7
 6a4:	60e6                	ld	ra,88(sp)
 6a6:	6446                	ld	s0,80(sp)
 6a8:	64a6                	ld	s1,72(sp)
 6aa:	6906                	ld	s2,64(sp)
 6ac:	79e2                	ld	s3,56(sp)
 6ae:	7a42                	ld	s4,48(sp)
 6b0:	7aa2                	ld	s5,40(sp)
 6b2:	7b02                	ld	s6,32(sp)
 6b4:	6be2                	ld	s7,24(sp)
 6b6:	6125                	addi	sp,sp,96
 6b8:	8082                	ret

00000000000006ba <stat>:

int
stat(const char *n, struct stat *st)
{
 6ba:	1101                	addi	sp,sp,-32
 6bc:	ec06                	sd	ra,24(sp)
 6be:	e822                	sd	s0,16(sp)
 6c0:	e426                	sd	s1,8(sp)
 6c2:	e04a                	sd	s2,0(sp)
 6c4:	1000                	addi	s0,sp,32
 6c6:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 6c8:	4581                	li	a1,0
 6ca:	00000097          	auipc	ra,0x0
 6ce:	170080e7          	jalr	368(ra) # 83a <open>
  if(fd < 0)
 6d2:	02054563          	bltz	a0,6fc <stat+0x42>
 6d6:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 6d8:	85ca                	mv	a1,s2
 6da:	00000097          	auipc	ra,0x0
 6de:	178080e7          	jalr	376(ra) # 852 <fstat>
 6e2:	892a                	mv	s2,a0
  close(fd);
 6e4:	8526                	mv	a0,s1
 6e6:	00000097          	auipc	ra,0x0
 6ea:	13c080e7          	jalr	316(ra) # 822 <close>
  return r;
}
 6ee:	854a                	mv	a0,s2
 6f0:	60e2                	ld	ra,24(sp)
 6f2:	6442                	ld	s0,16(sp)
 6f4:	64a2                	ld	s1,8(sp)
 6f6:	6902                	ld	s2,0(sp)
 6f8:	6105                	addi	sp,sp,32
 6fa:	8082                	ret
    return -1;
 6fc:	597d                	li	s2,-1
 6fe:	bfc5                	j	6ee <stat+0x34>

0000000000000700 <atoi>:

int
atoi(const char *s)
{
 700:	1141                	addi	sp,sp,-16
 702:	e422                	sd	s0,8(sp)
 704:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 706:	00054683          	lbu	a3,0(a0)
 70a:	fd06879b          	addiw	a5,a3,-48
 70e:	0ff7f793          	zext.b	a5,a5
 712:	4625                	li	a2,9
 714:	02f66863          	bltu	a2,a5,744 <atoi+0x44>
 718:	872a                	mv	a4,a0
  n = 0;
 71a:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 71c:	0705                	addi	a4,a4,1
 71e:	0025179b          	slliw	a5,a0,0x2
 722:	9fa9                	addw	a5,a5,a0
 724:	0017979b          	slliw	a5,a5,0x1
 728:	9fb5                	addw	a5,a5,a3
 72a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 72e:	00074683          	lbu	a3,0(a4)
 732:	fd06879b          	addiw	a5,a3,-48
 736:	0ff7f793          	zext.b	a5,a5
 73a:	fef671e3          	bgeu	a2,a5,71c <atoi+0x1c>
  return n;
}
 73e:	6422                	ld	s0,8(sp)
 740:	0141                	addi	sp,sp,16
 742:	8082                	ret
  n = 0;
 744:	4501                	li	a0,0
 746:	bfe5                	j	73e <atoi+0x3e>

0000000000000748 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 748:	1141                	addi	sp,sp,-16
 74a:	e422                	sd	s0,8(sp)
 74c:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 74e:	02b57463          	bgeu	a0,a1,776 <memmove+0x2e>
    while(n-- > 0)
 752:	00c05f63          	blez	a2,770 <memmove+0x28>
 756:	1602                	slli	a2,a2,0x20
 758:	9201                	srli	a2,a2,0x20
 75a:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 75e:	872a                	mv	a4,a0
      *dst++ = *src++;
 760:	0585                	addi	a1,a1,1
 762:	0705                	addi	a4,a4,1
 764:	fff5c683          	lbu	a3,-1(a1)
 768:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 76c:	fee79ae3          	bne	a5,a4,760 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 770:	6422                	ld	s0,8(sp)
 772:	0141                	addi	sp,sp,16
 774:	8082                	ret
    dst += n;
 776:	00c50733          	add	a4,a0,a2
    src += n;
 77a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 77c:	fec05ae3          	blez	a2,770 <memmove+0x28>
 780:	fff6079b          	addiw	a5,a2,-1
 784:	1782                	slli	a5,a5,0x20
 786:	9381                	srli	a5,a5,0x20
 788:	fff7c793          	not	a5,a5
 78c:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 78e:	15fd                	addi	a1,a1,-1
 790:	177d                	addi	a4,a4,-1
 792:	0005c683          	lbu	a3,0(a1)
 796:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 79a:	fee79ae3          	bne	a5,a4,78e <memmove+0x46>
 79e:	bfc9                	j	770 <memmove+0x28>

00000000000007a0 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 7a0:	1141                	addi	sp,sp,-16
 7a2:	e422                	sd	s0,8(sp)
 7a4:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 7a6:	ca05                	beqz	a2,7d6 <memcmp+0x36>
 7a8:	fff6069b          	addiw	a3,a2,-1
 7ac:	1682                	slli	a3,a3,0x20
 7ae:	9281                	srli	a3,a3,0x20
 7b0:	0685                	addi	a3,a3,1
 7b2:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 7b4:	00054783          	lbu	a5,0(a0)
 7b8:	0005c703          	lbu	a4,0(a1)
 7bc:	00e79863          	bne	a5,a4,7cc <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 7c0:	0505                	addi	a0,a0,1
    p2++;
 7c2:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 7c4:	fed518e3          	bne	a0,a3,7b4 <memcmp+0x14>
  }
  return 0;
 7c8:	4501                	li	a0,0
 7ca:	a019                	j	7d0 <memcmp+0x30>
      return *p1 - *p2;
 7cc:	40e7853b          	subw	a0,a5,a4
}
 7d0:	6422                	ld	s0,8(sp)
 7d2:	0141                	addi	sp,sp,16
 7d4:	8082                	ret
  return 0;
 7d6:	4501                	li	a0,0
 7d8:	bfe5                	j	7d0 <memcmp+0x30>

00000000000007da <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 7da:	1141                	addi	sp,sp,-16
 7dc:	e406                	sd	ra,8(sp)
 7de:	e022                	sd	s0,0(sp)
 7e0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 7e2:	00000097          	auipc	ra,0x0
 7e6:	f66080e7          	jalr	-154(ra) # 748 <memmove>
}
 7ea:	60a2                	ld	ra,8(sp)
 7ec:	6402                	ld	s0,0(sp)
 7ee:	0141                	addi	sp,sp,16
 7f0:	8082                	ret

00000000000007f2 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 7f2:	4885                	li	a7,1
 ecall
 7f4:	00000073          	ecall
 ret
 7f8:	8082                	ret

00000000000007fa <exit>:
.global exit
exit:
 li a7, SYS_exit
 7fa:	4889                	li	a7,2
 ecall
 7fc:	00000073          	ecall
 ret
 800:	8082                	ret

0000000000000802 <wait>:
.global wait
wait:
 li a7, SYS_wait
 802:	488d                	li	a7,3
 ecall
 804:	00000073          	ecall
 ret
 808:	8082                	ret

000000000000080a <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 80a:	4891                	li	a7,4
 ecall
 80c:	00000073          	ecall
 ret
 810:	8082                	ret

0000000000000812 <read>:
.global read
read:
 li a7, SYS_read
 812:	4895                	li	a7,5
 ecall
 814:	00000073          	ecall
 ret
 818:	8082                	ret

000000000000081a <write>:
.global write
write:
 li a7, SYS_write
 81a:	48c1                	li	a7,16
 ecall
 81c:	00000073          	ecall
 ret
 820:	8082                	ret

0000000000000822 <close>:
.global close
close:
 li a7, SYS_close
 822:	48d5                	li	a7,21
 ecall
 824:	00000073          	ecall
 ret
 828:	8082                	ret

000000000000082a <kill>:
.global kill
kill:
 li a7, SYS_kill
 82a:	4899                	li	a7,6
 ecall
 82c:	00000073          	ecall
 ret
 830:	8082                	ret

0000000000000832 <exec>:
.global exec
exec:
 li a7, SYS_exec
 832:	489d                	li	a7,7
 ecall
 834:	00000073          	ecall
 ret
 838:	8082                	ret

000000000000083a <open>:
.global open
open:
 li a7, SYS_open
 83a:	48bd                	li	a7,15
 ecall
 83c:	00000073          	ecall
 ret
 840:	8082                	ret

0000000000000842 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 842:	48c5                	li	a7,17
 ecall
 844:	00000073          	ecall
 ret
 848:	8082                	ret

000000000000084a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 84a:	48c9                	li	a7,18
 ecall
 84c:	00000073          	ecall
 ret
 850:	8082                	ret

0000000000000852 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 852:	48a1                	li	a7,8
 ecall
 854:	00000073          	ecall
 ret
 858:	8082                	ret

000000000000085a <link>:
.global link
link:
 li a7, SYS_link
 85a:	48cd                	li	a7,19
 ecall
 85c:	00000073          	ecall
 ret
 860:	8082                	ret

0000000000000862 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 862:	48d1                	li	a7,20
 ecall
 864:	00000073          	ecall
 ret
 868:	8082                	ret

000000000000086a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 86a:	48a5                	li	a7,9
 ecall
 86c:	00000073          	ecall
 ret
 870:	8082                	ret

0000000000000872 <dup>:
.global dup
dup:
 li a7, SYS_dup
 872:	48a9                	li	a7,10
 ecall
 874:	00000073          	ecall
 ret
 878:	8082                	ret

000000000000087a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 87a:	48ad                	li	a7,11
 ecall
 87c:	00000073          	ecall
 ret
 880:	8082                	ret

0000000000000882 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 882:	48b1                	li	a7,12
 ecall
 884:	00000073          	ecall
 ret
 888:	8082                	ret

000000000000088a <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 88a:	48b5                	li	a7,13
 ecall
 88c:	00000073          	ecall
 ret
 890:	8082                	ret

0000000000000892 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 892:	48b9                	li	a7,14
 ecall
 894:	00000073          	ecall
 ret
 898:	8082                	ret

000000000000089a <ps>:
.global ps
ps:
 li a7, SYS_ps
 89a:	48d9                	li	a7,22
 ecall
 89c:	00000073          	ecall
 ret
 8a0:	8082                	ret

00000000000008a2 <schedls>:
.global schedls
schedls:
 li a7, SYS_schedls
 8a2:	48dd                	li	a7,23
 ecall
 8a4:	00000073          	ecall
 ret
 8a8:	8082                	ret

00000000000008aa <schedset>:
.global schedset
schedset:
 li a7, SYS_schedset
 8aa:	48e1                	li	a7,24
 ecall
 8ac:	00000073          	ecall
 ret
 8b0:	8082                	ret

00000000000008b2 <va2pa>:
.global va2pa
va2pa:
 li a7, SYS_va2pa
 8b2:	48e9                	li	a7,26
 ecall
 8b4:	00000073          	ecall
 ret
 8b8:	8082                	ret

00000000000008ba <pfreepages>:
.global pfreepages
pfreepages:
 li a7, SYS_pfreepages
 8ba:	48e5                	li	a7,25
 ecall
 8bc:	00000073          	ecall
 ret
 8c0:	8082                	ret

00000000000008c2 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 8c2:	1101                	addi	sp,sp,-32
 8c4:	ec06                	sd	ra,24(sp)
 8c6:	e822                	sd	s0,16(sp)
 8c8:	1000                	addi	s0,sp,32
 8ca:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 8ce:	4605                	li	a2,1
 8d0:	fef40593          	addi	a1,s0,-17
 8d4:	00000097          	auipc	ra,0x0
 8d8:	f46080e7          	jalr	-186(ra) # 81a <write>
}
 8dc:	60e2                	ld	ra,24(sp)
 8de:	6442                	ld	s0,16(sp)
 8e0:	6105                	addi	sp,sp,32
 8e2:	8082                	ret

00000000000008e4 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 8e4:	7139                	addi	sp,sp,-64
 8e6:	fc06                	sd	ra,56(sp)
 8e8:	f822                	sd	s0,48(sp)
 8ea:	f426                	sd	s1,40(sp)
 8ec:	f04a                	sd	s2,32(sp)
 8ee:	ec4e                	sd	s3,24(sp)
 8f0:	0080                	addi	s0,sp,64
 8f2:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 8f4:	c299                	beqz	a3,8fa <printint+0x16>
 8f6:	0805c963          	bltz	a1,988 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 8fa:	2581                	sext.w	a1,a1
  neg = 0;
 8fc:	4881                	li	a7,0
 8fe:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 902:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 904:	2601                	sext.w	a2,a2
 906:	00000517          	auipc	a0,0x0
 90a:	7b250513          	addi	a0,a0,1970 # 10b8 <digits>
 90e:	883a                	mv	a6,a4
 910:	2705                	addiw	a4,a4,1
 912:	02c5f7bb          	remuw	a5,a1,a2
 916:	1782                	slli	a5,a5,0x20
 918:	9381                	srli	a5,a5,0x20
 91a:	97aa                	add	a5,a5,a0
 91c:	0007c783          	lbu	a5,0(a5)
 920:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 924:	0005879b          	sext.w	a5,a1
 928:	02c5d5bb          	divuw	a1,a1,a2
 92c:	0685                	addi	a3,a3,1
 92e:	fec7f0e3          	bgeu	a5,a2,90e <printint+0x2a>
  if(neg)
 932:	00088c63          	beqz	a7,94a <printint+0x66>
    buf[i++] = '-';
 936:	fd070793          	addi	a5,a4,-48
 93a:	00878733          	add	a4,a5,s0
 93e:	02d00793          	li	a5,45
 942:	fef70823          	sb	a5,-16(a4)
 946:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 94a:	02e05863          	blez	a4,97a <printint+0x96>
 94e:	fc040793          	addi	a5,s0,-64
 952:	00e78933          	add	s2,a5,a4
 956:	fff78993          	addi	s3,a5,-1
 95a:	99ba                	add	s3,s3,a4
 95c:	377d                	addiw	a4,a4,-1
 95e:	1702                	slli	a4,a4,0x20
 960:	9301                	srli	a4,a4,0x20
 962:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 966:	fff94583          	lbu	a1,-1(s2)
 96a:	8526                	mv	a0,s1
 96c:	00000097          	auipc	ra,0x0
 970:	f56080e7          	jalr	-170(ra) # 8c2 <putc>
  while(--i >= 0)
 974:	197d                	addi	s2,s2,-1
 976:	ff3918e3          	bne	s2,s3,966 <printint+0x82>
}
 97a:	70e2                	ld	ra,56(sp)
 97c:	7442                	ld	s0,48(sp)
 97e:	74a2                	ld	s1,40(sp)
 980:	7902                	ld	s2,32(sp)
 982:	69e2                	ld	s3,24(sp)
 984:	6121                	addi	sp,sp,64
 986:	8082                	ret
    x = -xx;
 988:	40b005bb          	negw	a1,a1
    neg = 1;
 98c:	4885                	li	a7,1
    x = -xx;
 98e:	bf85                	j	8fe <printint+0x1a>

0000000000000990 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 990:	715d                	addi	sp,sp,-80
 992:	e486                	sd	ra,72(sp)
 994:	e0a2                	sd	s0,64(sp)
 996:	fc26                	sd	s1,56(sp)
 998:	f84a                	sd	s2,48(sp)
 99a:	f44e                	sd	s3,40(sp)
 99c:	f052                	sd	s4,32(sp)
 99e:	ec56                	sd	s5,24(sp)
 9a0:	e85a                	sd	s6,16(sp)
 9a2:	e45e                	sd	s7,8(sp)
 9a4:	e062                	sd	s8,0(sp)
 9a6:	0880                	addi	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 9a8:	0005c903          	lbu	s2,0(a1)
 9ac:	18090c63          	beqz	s2,b44 <vprintf+0x1b4>
 9b0:	8aaa                	mv	s5,a0
 9b2:	8bb2                	mv	s7,a2
 9b4:	00158493          	addi	s1,a1,1
  state = 0;
 9b8:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 9ba:	02500a13          	li	s4,37
 9be:	4b55                	li	s6,21
 9c0:	a839                	j	9de <vprintf+0x4e>
        putc(fd, c);
 9c2:	85ca                	mv	a1,s2
 9c4:	8556                	mv	a0,s5
 9c6:	00000097          	auipc	ra,0x0
 9ca:	efc080e7          	jalr	-260(ra) # 8c2 <putc>
 9ce:	a019                	j	9d4 <vprintf+0x44>
    } else if(state == '%'){
 9d0:	01498d63          	beq	s3,s4,9ea <vprintf+0x5a>
  for(i = 0; fmt[i]; i++){
 9d4:	0485                	addi	s1,s1,1
 9d6:	fff4c903          	lbu	s2,-1(s1)
 9da:	16090563          	beqz	s2,b44 <vprintf+0x1b4>
    if(state == 0){
 9de:	fe0999e3          	bnez	s3,9d0 <vprintf+0x40>
      if(c == '%'){
 9e2:	ff4910e3          	bne	s2,s4,9c2 <vprintf+0x32>
        state = '%';
 9e6:	89d2                	mv	s3,s4
 9e8:	b7f5                	j	9d4 <vprintf+0x44>
      if(c == 'd'){
 9ea:	13490263          	beq	s2,s4,b0e <vprintf+0x17e>
 9ee:	f9d9079b          	addiw	a5,s2,-99
 9f2:	0ff7f793          	zext.b	a5,a5
 9f6:	12fb6563          	bltu	s6,a5,b20 <vprintf+0x190>
 9fa:	f9d9079b          	addiw	a5,s2,-99
 9fe:	0ff7f713          	zext.b	a4,a5
 a02:	10eb6f63          	bltu	s6,a4,b20 <vprintf+0x190>
 a06:	00271793          	slli	a5,a4,0x2
 a0a:	00000717          	auipc	a4,0x0
 a0e:	65670713          	addi	a4,a4,1622 # 1060 <malloc+0x41e>
 a12:	97ba                	add	a5,a5,a4
 a14:	439c                	lw	a5,0(a5)
 a16:	97ba                	add	a5,a5,a4
 a18:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 a1a:	008b8913          	addi	s2,s7,8
 a1e:	4685                	li	a3,1
 a20:	4629                	li	a2,10
 a22:	000ba583          	lw	a1,0(s7)
 a26:	8556                	mv	a0,s5
 a28:	00000097          	auipc	ra,0x0
 a2c:	ebc080e7          	jalr	-324(ra) # 8e4 <printint>
 a30:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 a32:	4981                	li	s3,0
 a34:	b745                	j	9d4 <vprintf+0x44>
        printint(fd, va_arg(ap, uint64), 10, 0);
 a36:	008b8913          	addi	s2,s7,8
 a3a:	4681                	li	a3,0
 a3c:	4629                	li	a2,10
 a3e:	000ba583          	lw	a1,0(s7)
 a42:	8556                	mv	a0,s5
 a44:	00000097          	auipc	ra,0x0
 a48:	ea0080e7          	jalr	-352(ra) # 8e4 <printint>
 a4c:	8bca                	mv	s7,s2
      state = 0;
 a4e:	4981                	li	s3,0
 a50:	b751                	j	9d4 <vprintf+0x44>
        printint(fd, va_arg(ap, int), 16, 0);
 a52:	008b8913          	addi	s2,s7,8
 a56:	4681                	li	a3,0
 a58:	4641                	li	a2,16
 a5a:	000ba583          	lw	a1,0(s7)
 a5e:	8556                	mv	a0,s5
 a60:	00000097          	auipc	ra,0x0
 a64:	e84080e7          	jalr	-380(ra) # 8e4 <printint>
 a68:	8bca                	mv	s7,s2
      state = 0;
 a6a:	4981                	li	s3,0
 a6c:	b7a5                	j	9d4 <vprintf+0x44>
        printptr(fd, va_arg(ap, uint64));
 a6e:	008b8c13          	addi	s8,s7,8
 a72:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 a76:	03000593          	li	a1,48
 a7a:	8556                	mv	a0,s5
 a7c:	00000097          	auipc	ra,0x0
 a80:	e46080e7          	jalr	-442(ra) # 8c2 <putc>
  putc(fd, 'x');
 a84:	07800593          	li	a1,120
 a88:	8556                	mv	a0,s5
 a8a:	00000097          	auipc	ra,0x0
 a8e:	e38080e7          	jalr	-456(ra) # 8c2 <putc>
 a92:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 a94:	00000b97          	auipc	s7,0x0
 a98:	624b8b93          	addi	s7,s7,1572 # 10b8 <digits>
 a9c:	03c9d793          	srli	a5,s3,0x3c
 aa0:	97de                	add	a5,a5,s7
 aa2:	0007c583          	lbu	a1,0(a5)
 aa6:	8556                	mv	a0,s5
 aa8:	00000097          	auipc	ra,0x0
 aac:	e1a080e7          	jalr	-486(ra) # 8c2 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 ab0:	0992                	slli	s3,s3,0x4
 ab2:	397d                	addiw	s2,s2,-1
 ab4:	fe0914e3          	bnez	s2,a9c <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 ab8:	8be2                	mv	s7,s8
      state = 0;
 aba:	4981                	li	s3,0
 abc:	bf21                	j	9d4 <vprintf+0x44>
        s = va_arg(ap, char*);
 abe:	008b8993          	addi	s3,s7,8
 ac2:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 ac6:	02090163          	beqz	s2,ae8 <vprintf+0x158>
        while(*s != 0){
 aca:	00094583          	lbu	a1,0(s2)
 ace:	c9a5                	beqz	a1,b3e <vprintf+0x1ae>
          putc(fd, *s);
 ad0:	8556                	mv	a0,s5
 ad2:	00000097          	auipc	ra,0x0
 ad6:	df0080e7          	jalr	-528(ra) # 8c2 <putc>
          s++;
 ada:	0905                	addi	s2,s2,1
        while(*s != 0){
 adc:	00094583          	lbu	a1,0(s2)
 ae0:	f9e5                	bnez	a1,ad0 <vprintf+0x140>
        s = va_arg(ap, char*);
 ae2:	8bce                	mv	s7,s3
      state = 0;
 ae4:	4981                	li	s3,0
 ae6:	b5fd                	j	9d4 <vprintf+0x44>
          s = "(null)";
 ae8:	00000917          	auipc	s2,0x0
 aec:	57090913          	addi	s2,s2,1392 # 1058 <malloc+0x416>
        while(*s != 0){
 af0:	02800593          	li	a1,40
 af4:	bff1                	j	ad0 <vprintf+0x140>
        putc(fd, va_arg(ap, uint));
 af6:	008b8913          	addi	s2,s7,8
 afa:	000bc583          	lbu	a1,0(s7)
 afe:	8556                	mv	a0,s5
 b00:	00000097          	auipc	ra,0x0
 b04:	dc2080e7          	jalr	-574(ra) # 8c2 <putc>
 b08:	8bca                	mv	s7,s2
      state = 0;
 b0a:	4981                	li	s3,0
 b0c:	b5e1                	j	9d4 <vprintf+0x44>
        putc(fd, c);
 b0e:	02500593          	li	a1,37
 b12:	8556                	mv	a0,s5
 b14:	00000097          	auipc	ra,0x0
 b18:	dae080e7          	jalr	-594(ra) # 8c2 <putc>
      state = 0;
 b1c:	4981                	li	s3,0
 b1e:	bd5d                	j	9d4 <vprintf+0x44>
        putc(fd, '%');
 b20:	02500593          	li	a1,37
 b24:	8556                	mv	a0,s5
 b26:	00000097          	auipc	ra,0x0
 b2a:	d9c080e7          	jalr	-612(ra) # 8c2 <putc>
        putc(fd, c);
 b2e:	85ca                	mv	a1,s2
 b30:	8556                	mv	a0,s5
 b32:	00000097          	auipc	ra,0x0
 b36:	d90080e7          	jalr	-624(ra) # 8c2 <putc>
      state = 0;
 b3a:	4981                	li	s3,0
 b3c:	bd61                	j	9d4 <vprintf+0x44>
        s = va_arg(ap, char*);
 b3e:	8bce                	mv	s7,s3
      state = 0;
 b40:	4981                	li	s3,0
 b42:	bd49                	j	9d4 <vprintf+0x44>
    }
  }
}
 b44:	60a6                	ld	ra,72(sp)
 b46:	6406                	ld	s0,64(sp)
 b48:	74e2                	ld	s1,56(sp)
 b4a:	7942                	ld	s2,48(sp)
 b4c:	79a2                	ld	s3,40(sp)
 b4e:	7a02                	ld	s4,32(sp)
 b50:	6ae2                	ld	s5,24(sp)
 b52:	6b42                	ld	s6,16(sp)
 b54:	6ba2                	ld	s7,8(sp)
 b56:	6c02                	ld	s8,0(sp)
 b58:	6161                	addi	sp,sp,80
 b5a:	8082                	ret

0000000000000b5c <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 b5c:	715d                	addi	sp,sp,-80
 b5e:	ec06                	sd	ra,24(sp)
 b60:	e822                	sd	s0,16(sp)
 b62:	1000                	addi	s0,sp,32
 b64:	e010                	sd	a2,0(s0)
 b66:	e414                	sd	a3,8(s0)
 b68:	e818                	sd	a4,16(s0)
 b6a:	ec1c                	sd	a5,24(s0)
 b6c:	03043023          	sd	a6,32(s0)
 b70:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 b74:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 b78:	8622                	mv	a2,s0
 b7a:	00000097          	auipc	ra,0x0
 b7e:	e16080e7          	jalr	-490(ra) # 990 <vprintf>
}
 b82:	60e2                	ld	ra,24(sp)
 b84:	6442                	ld	s0,16(sp)
 b86:	6161                	addi	sp,sp,80
 b88:	8082                	ret

0000000000000b8a <printf>:

void
printf(const char *fmt, ...)
{
 b8a:	711d                	addi	sp,sp,-96
 b8c:	ec06                	sd	ra,24(sp)
 b8e:	e822                	sd	s0,16(sp)
 b90:	1000                	addi	s0,sp,32
 b92:	e40c                	sd	a1,8(s0)
 b94:	e810                	sd	a2,16(s0)
 b96:	ec14                	sd	a3,24(s0)
 b98:	f018                	sd	a4,32(s0)
 b9a:	f41c                	sd	a5,40(s0)
 b9c:	03043823          	sd	a6,48(s0)
 ba0:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 ba4:	00840613          	addi	a2,s0,8
 ba8:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 bac:	85aa                	mv	a1,a0
 bae:	4505                	li	a0,1
 bb0:	00000097          	auipc	ra,0x0
 bb4:	de0080e7          	jalr	-544(ra) # 990 <vprintf>
}
 bb8:	60e2                	ld	ra,24(sp)
 bba:	6442                	ld	s0,16(sp)
 bbc:	6125                	addi	sp,sp,96
 bbe:	8082                	ret

0000000000000bc0 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 bc0:	1141                	addi	sp,sp,-16
 bc2:	e422                	sd	s0,8(sp)
 bc4:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 bc6:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 bca:	00001797          	auipc	a5,0x1
 bce:	43e7b783          	ld	a5,1086(a5) # 2008 <freep>
 bd2:	a02d                	j	bfc <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 bd4:	4618                	lw	a4,8(a2)
 bd6:	9f2d                	addw	a4,a4,a1
 bd8:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 bdc:	6398                	ld	a4,0(a5)
 bde:	6310                	ld	a2,0(a4)
 be0:	a83d                	j	c1e <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 be2:	ff852703          	lw	a4,-8(a0)
 be6:	9f31                	addw	a4,a4,a2
 be8:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 bea:	ff053683          	ld	a3,-16(a0)
 bee:	a091                	j	c32 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 bf0:	6398                	ld	a4,0(a5)
 bf2:	00e7e463          	bltu	a5,a4,bfa <free+0x3a>
 bf6:	00e6ea63          	bltu	a3,a4,c0a <free+0x4a>
{
 bfa:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 bfc:	fed7fae3          	bgeu	a5,a3,bf0 <free+0x30>
 c00:	6398                	ld	a4,0(a5)
 c02:	00e6e463          	bltu	a3,a4,c0a <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 c06:	fee7eae3          	bltu	a5,a4,bfa <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 c0a:	ff852583          	lw	a1,-8(a0)
 c0e:	6390                	ld	a2,0(a5)
 c10:	02059813          	slli	a6,a1,0x20
 c14:	01c85713          	srli	a4,a6,0x1c
 c18:	9736                	add	a4,a4,a3
 c1a:	fae60de3          	beq	a2,a4,bd4 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 c1e:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 c22:	4790                	lw	a2,8(a5)
 c24:	02061593          	slli	a1,a2,0x20
 c28:	01c5d713          	srli	a4,a1,0x1c
 c2c:	973e                	add	a4,a4,a5
 c2e:	fae68ae3          	beq	a3,a4,be2 <free+0x22>
    p->s.ptr = bp->s.ptr;
 c32:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 c34:	00001717          	auipc	a4,0x1
 c38:	3cf73a23          	sd	a5,980(a4) # 2008 <freep>
}
 c3c:	6422                	ld	s0,8(sp)
 c3e:	0141                	addi	sp,sp,16
 c40:	8082                	ret

0000000000000c42 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 c42:	7139                	addi	sp,sp,-64
 c44:	fc06                	sd	ra,56(sp)
 c46:	f822                	sd	s0,48(sp)
 c48:	f426                	sd	s1,40(sp)
 c4a:	f04a                	sd	s2,32(sp)
 c4c:	ec4e                	sd	s3,24(sp)
 c4e:	e852                	sd	s4,16(sp)
 c50:	e456                	sd	s5,8(sp)
 c52:	e05a                	sd	s6,0(sp)
 c54:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 c56:	02051493          	slli	s1,a0,0x20
 c5a:	9081                	srli	s1,s1,0x20
 c5c:	04bd                	addi	s1,s1,15
 c5e:	8091                	srli	s1,s1,0x4
 c60:	0014899b          	addiw	s3,s1,1
 c64:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 c66:	00001517          	auipc	a0,0x1
 c6a:	3a253503          	ld	a0,930(a0) # 2008 <freep>
 c6e:	c515                	beqz	a0,c9a <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 c70:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 c72:	4798                	lw	a4,8(a5)
 c74:	02977f63          	bgeu	a4,s1,cb2 <malloc+0x70>
  if(nu < 4096)
 c78:	8a4e                	mv	s4,s3
 c7a:	0009871b          	sext.w	a4,s3
 c7e:	6685                	lui	a3,0x1
 c80:	00d77363          	bgeu	a4,a3,c86 <malloc+0x44>
 c84:	6a05                	lui	s4,0x1
 c86:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 c8a:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 c8e:	00001917          	auipc	s2,0x1
 c92:	37a90913          	addi	s2,s2,890 # 2008 <freep>
  if(p == (char*)-1)
 c96:	5afd                	li	s5,-1
 c98:	a895                	j	d0c <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 c9a:	04001797          	auipc	a5,0x4001
 c9e:	37678793          	addi	a5,a5,886 # 4002010 <base>
 ca2:	00001717          	auipc	a4,0x1
 ca6:	36f73323          	sd	a5,870(a4) # 2008 <freep>
 caa:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 cac:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 cb0:	b7e1                	j	c78 <malloc+0x36>
      if(p->s.size == nunits)
 cb2:	02e48c63          	beq	s1,a4,cea <malloc+0xa8>
        p->s.size -= nunits;
 cb6:	4137073b          	subw	a4,a4,s3
 cba:	c798                	sw	a4,8(a5)
        p += p->s.size;
 cbc:	02071693          	slli	a3,a4,0x20
 cc0:	01c6d713          	srli	a4,a3,0x1c
 cc4:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 cc6:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 cca:	00001717          	auipc	a4,0x1
 cce:	32a73f23          	sd	a0,830(a4) # 2008 <freep>
      return (void*)(p + 1);
 cd2:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 cd6:	70e2                	ld	ra,56(sp)
 cd8:	7442                	ld	s0,48(sp)
 cda:	74a2                	ld	s1,40(sp)
 cdc:	7902                	ld	s2,32(sp)
 cde:	69e2                	ld	s3,24(sp)
 ce0:	6a42                	ld	s4,16(sp)
 ce2:	6aa2                	ld	s5,8(sp)
 ce4:	6b02                	ld	s6,0(sp)
 ce6:	6121                	addi	sp,sp,64
 ce8:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 cea:	6398                	ld	a4,0(a5)
 cec:	e118                	sd	a4,0(a0)
 cee:	bff1                	j	cca <malloc+0x88>
  hp->s.size = nu;
 cf0:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 cf4:	0541                	addi	a0,a0,16
 cf6:	00000097          	auipc	ra,0x0
 cfa:	eca080e7          	jalr	-310(ra) # bc0 <free>
  return freep;
 cfe:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 d02:	d971                	beqz	a0,cd6 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 d04:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 d06:	4798                	lw	a4,8(a5)
 d08:	fa9775e3          	bgeu	a4,s1,cb2 <malloc+0x70>
    if(p == freep)
 d0c:	00093703          	ld	a4,0(s2)
 d10:	853e                	mv	a0,a5
 d12:	fef719e3          	bne	a4,a5,d04 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 d16:	8552                	mv	a0,s4
 d18:	00000097          	auipc	ra,0x0
 d1c:	b6a080e7          	jalr	-1174(ra) # 882 <sbrk>
  if(p == (char*)-1)
 d20:	fd5518e3          	bne	a0,s5,cf0 <malloc+0xae>
        return 0;
 d24:	4501                	li	a0,0
 d26:	bf45                	j	cd6 <malloc+0x94>
