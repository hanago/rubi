CFLAGS = -Wall -m32 -mstackrealign -std=gnu99 -O2
C = $(CC) $(CFLAGS)

rubi: engine.o codegen.o
	$(C) -o $@ $^

luajit-2.0/src/host/minilua.c:
	git clone https://github.com/LuaDist/luajit
	mv ./luajit ./luajit-2.0

minilua: luajit-2.0/src/host/minilua.c
	$(CC) -Wall -std=gnu99 -O2 -o $@ $< -lm

engine.o: engine.c rubi.h
	$(C) -o $@ -c engine.c

codegen.o: parser.h parser.c expr.c stdlib.c minilua
	cat parser.c expr.c stdlib.c | ./minilua luajit-2.0/dynasm/dynasm.lua -o codegen.c -
	$(C) -o $@ -c codegen.c

run: rubi
	@ echo "fib(30):"
	@perf stat --repeat 5 -e cycles,instructions,cache-misses ./rubi ./progs/fib.rb
	@ echo "primetable:"
	@perf stat --repeat 5 -e cycles,instructions,cache-misses ./rubi ./progs/primetable.rb
	@ echo "pi:"
	@perf stat --repeat 5 -e cycles,instructions,cache-misses ./rubi ./progs/pi.rb

clean:
	$(RM) a.out rubi minilua *.o *~ text codegen.c
