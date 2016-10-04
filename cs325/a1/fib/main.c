#include <stdio.h>
#include <unistd.h>
#include <time.h>

int fib (n) {
  if (n <= 0) {
    return 0;
  } else if (n == 1) {
    return 1;
  } else {
    return fib(n-1) + fib(n-2);
  }
}

int main(int argc, char **argv) {
  int sizes[] = {1, 10, 20, 30, 40, 45};
  time_t start_time, end_time, delta_time;

  for(int i = 0; i < 4; i++) {
    start_time = time(NULL);
    fib(sizes[i]);
    end_time = time(NULL);
    delta_time = end_time - start_time;
    printf("time: %d\n", delta_time);
    sleep(1);
  }
}
