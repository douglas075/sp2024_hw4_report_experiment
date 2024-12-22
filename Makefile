all:
	gcc gen.c -o gen
clean:
	rm -rf gen testcase runtime_record run_count*
