OBJS=lex.yy.o y.tab.o
LIBES=-ll
CFLAGS=-O -DDEBUG=1

PROGS=at

all: $(PROGS)

clean:
	rm -f $(OBJS) $(PROGS) lex.yy.c y.tab.c y.tab.h

test: at tests
	./at < tests

at: $(OBJS)
	$(CC) $(CFLAGS) -o at $(OBJS) $(LIBES)

lex.yy.c: at.l
	$(LEX) -s -i at.l

at.l: y.tab.h

y.tab.h y.tab.c: at.y
	$(YACC) -d at.y
