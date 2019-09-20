# makefile for getpos example

all: getpos movebox

getpos:	getpos.c
	cc -I/usr/realtime/include getpos.c -o getpos

movebox: movebox.c
	cc -I/usr/realtime/include movebox.c -o movebox

clean:
	rm -f getpos.o getpos movebox.o movebox
