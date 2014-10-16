SelfSimSR
=========

Exploiting Self-Similarities for Single Frame Super-Resolution (ACCV 2010)

Chih-Yuan Yang
Email address: cyang35 [at] ucmerced [dot] edu
11/11/2010 v1.0 first release
02/23/2013 v1.1 The files are reorganized and the modified sample.cpp file is included.
09/22/2013 v1.2 The ann_sample.exe is rebuilt containing static linked MFC library.
I encounter a problem that some machines do not have the libarary so that our MATLAB
code fails on calling the external ann_sample.exe file. I also updated the Visual Studio
2010 project file sample.vcxproj in the folder Lib\ann_1.1.1\MS_Win32\sample. The
rebuilt ann_sample.exe in the folder Lib\ann_1.1.1\MS_Win32\bin has been copied to
the folder used by our MATLAB code: Lib\ann_1.1.1\ANN_Windows

==================================================
How to start
==================================================
The Test_SanityTest.m file works as a sanity test. The results are
saved at the folder TempFolder\SanityTest with the file name
SanityTest_Iter(X).png.
The resolution of SanityTest_input.png is 30x30. On a machine
with a CPU as Intel i7 2.67GHz, the algroithm takes 5 miniutes
to generate the first output image.
The computational load of the algorithm increases exponentially
due to the resolution of the input image. For example, the 
resolution of Child_input.png is 128x128 pixels. To run the 
Test_Child.m file on a machine with a Intel i7 3.6GHz CPU, 
the algorithm needs 10 hours to generate the first output image, 
and additional 7 hours to generate the next image. The most time
consuming step is the computation of the group sparse coefficients 
for many groups.

==================================================
Tested platforms
==================================================
This package is tested on two machines.
Machine 1
OS: Windows 7 64 bits
MATLAB version: MATLAB 2012b
CPU: Intel i7 920 2.67GHz
Memory: 24GB

Machine 2
OS: Ubuntu 12.04 64 bits
MATLAB version: MATLAB 2012b
CPU: Intel i7-3820 3.6GHz
Memory: 32GB

==================================================
About the scaling factor
==================================================
v1.1 only supports scaling factors 3 and 4 as I hard-coded some
variables.

==================================================
About the libraries
==================================================
1. Ann package
The Ann library used in this package is v1.1.1 originally
download from http://www.cs.umd.edu/~mount/ANN. I modified
the original ann_sample.cpp to dump ann results to be 
loaded by the MATLAB.
The modified ann_sample.cpp is in the folder
ModifiedLibraryFiles

2. K-SVD package
This package is written by M. Aharon, M. Elad, and A.M. Bruckstein,
and there is a Readme.txt in the package folder.

3. spgl1-1.7 package
The Spectral Projected Gradient for L1 minimization package contains
a Readme in its own folder.
