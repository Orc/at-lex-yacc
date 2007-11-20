OBJS=lex.yy.o y.tab.o main.o
LIBES=-ll
CFLAGS=-O -g

PROGS=at

all: $(PROGS)

clean:
	rm -f $(OBJS) $(PROGS) lex.yy.c y.tab.c y.tab.h

test: at tests
	@grep -v '^#' tests | while IFS= read line; do \
	    if [ ! -z "$$line" ]; then \
		printf '%-35s ... ' "$$line"  ; \
		DEBUG_AT=1 ./at $$line && echo "ok" || true ; \
	    fi; \
	done 1>&2; exit 0

at: $(OBJS)
	$(CC) $(CFLAGS) -o at $(OBJS) $(LIBES)

lex.yy.c: at.l
	$(LEX) -i at.l

at.l: y.tab.h

y.tab.h y.tab.c: at.y
	$(YACC) -d at.y
