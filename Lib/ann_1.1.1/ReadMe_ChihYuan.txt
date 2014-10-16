Chih-Yuan Yang
10/15/12

**** For Windows 7 64bit
The original version in the package can not run in Windows 7 64 bit due to
the incompatible C++ runtime components. This problem can be easily solved
by rebuild the solution in the MS_W32 folder.

**** For Ubuntu 12.04
Due to the version change of g++, some header files do not work.
To compile the source files of package ann_1.1.1, add some #include statements
in those files to make exit(1) and strcmp() work.

src/ANN.cpp
#include <cstdlib>

src/kd_dump.cpp
#include <cstdlib>
#include <cstring>

test/ann_test.cpp
#include <cstdlib>
#include <cstring>

sample/ann_sample.cpp
09/18/13 Chih-Yuan: When I use the Release mode, I found the fopen_s() is defined already.
so I have to remove the function definition.
The fopen_s and fprintf_s are Microsoft extended c functions, which are not defined in g++.
add a define statement and a function to replace them
#define fprintf_s fprintf
int fopen_s(FILE **f, const char *name, const char *mode) {
    *f = fopen(name, mode);
    return 0;
}

In addition, change line 63 from
char			SaveFileName[80]
to
char			SaveFileName[300]
beause we use full path to write the txt file, which is long than 80 chararcters and produces
buffer overflow.

ann2fig/ann2fig.cpp
#include <cstdlib>
#include <cstring>

