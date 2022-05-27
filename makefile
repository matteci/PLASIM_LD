most.x: most.c
	gcc -o most.x most.c -I/usr/lib/X11/include -lm -L/usr/lib/X11 -lX11
clean:
	rm -f *.o *.x F90* most_*
