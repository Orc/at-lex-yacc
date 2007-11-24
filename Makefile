OBJS=main.o libmaketime.a
LOBJS=lex.yy.o y.tab.o maketime.o
LIBES=-ll
CFLAGS=-O -g
AR=ar
RANLIB=ranlib

PROGS=at

all: $(PROGS)

clean:
	rm -f $(OBJS) $(PROGS) lex.yy.c y.tab.c y.tab.h

test: at tests runtests
	@sh ./runtests < tests

at: $(OBJS)
	$(CC) $(CFLAGS) -o at $(OBJS) $(LIBES)

libmaketime.a: $(LOBJS)
	$(AR) rv libmaketime.a $(LOBJS)
	$(RANLIB) libmaketime.a

lex.yy.c: at.l
	$(LEX) -i at.l

at.l: y.tab.h

y.tab.h y.tab.c: at.y
	$(YACC) -d at.y

main.o: main.c y.tab.h at.h
maketime.o: maketime.c y.tab.h at.h
