OBJS=lex.yy.o y.tab.o main.o maketime.o
LIBES=-ll
CFLAGS=-O -g

PROGS=at

all: $(PROGS)

clean:
	rm -f $(OBJS) $(PROGS) lex.yy.c y.tab.c y.tab.h

test: at tests runtests
	@sh ./runtests < tests

at: $(OBJS)
	$(CC) $(CFLAGS) -o at $(OBJS) $(LIBES)

lex.yy.c: at.l
	$(LEX) -i at.l

at.l: y.tab.h

y.tab.h y.tab.c: at.y
	$(YACC) -d at.y
