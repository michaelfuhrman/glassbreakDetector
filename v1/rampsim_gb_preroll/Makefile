# Make file for rampSim
# To use, run "make" at the command line
# To clear out all compiled files, run "make clean"

# Implicit variables
  # Compiler command
CXX = g++
  # source to object flags
CXXFLAGS = -DSPLINES_DO_NOT_USE_GENERIC_CONTAINER -O3 -g3 -Wall -c -fmessage-length=0 -std=c++11 \
           -I"C:\Program Files\Mega-Nerd\libsndfile\bin"  -I"C:\Program Files\Mega-Nerd\libsndfile\include" -I"C:\msys64\mingw64\include"
  # object to exe flags
LDFLAGS = -static-libgcc -static-libstdc++ -L"C:\Program Files\Mega-Nerd\libsndfile\lib" -l:libsndfile-1.lib -static

# Define the source and target object files
ccsrc  = $(wildcard src/Spline/*.cc)
obj = $(ccsrc:.cc=.o)

# Compile rampSim.exe
bin/rampSim.exe: src/rampSim.o $(obj)
	$(CXX) -o $@ $^ $(LDFLAGS)
# First it makes any *.o files that need to be updated using "$(CXX) $(CXXFLAGS) -o *.o *.cpp"
#   Note that this is an implicit command that is built from the CXX and CXXFLAGS variables created above but the format is not explicitly stated
# After building the *.o files, it builds the target we gave above using "$(CXX) -o $(exeTarget) *.o $(LDFLAGS)"

# Command to clean up when "make clean" is run, it removes the *.o files and teh compilation target
.PHONY: clean
clean:
	rm $(obj) bin/rampSim.exe src/rampSim.o
