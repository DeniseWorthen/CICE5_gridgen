CDF=/apps/netcdf/4.7.0/intel/18.0.5.274
#####################################################################
# compiler options
#####################################################################
FOPT = -C
#FOPT = -C -warn
# adding -g produces ~10-16 differences in angle w/ grid file that is 
# currently being used but which was generated on Theia. Without -g,
# the differences are ~10-11. Differences are seen ONLY in variable 
# angle. All other variables are exact between grid file produced on
# Hera and previous Theia version, regardless of FOPT setting
#FOPT = -C -g

F90 = ifort
#F90 = ifort -warn

opt1 = -Doutput_grid_qdeg
#opt1 = -Doutput_grid_hdeg

opt2 = -Ddebug_output

optall = $(opt1) $(opt2)

#####################################################################
# 
#####################################################################
OBJS = param.o charstrings.o physcon.o icedefs.o grdvars.o find_angq.o gen_cicegrid.o write_cdf.o 

gengrid: $(OBJS)
	$(F90) $(FOPT) -o gengrid $(OBJS) -L$(CDF)/lib -lnetcdff -lnetcdf 

%.o: %.F90
	$(F90) $(FOPT) $(optall) -c -I$(CDF)/include $<
	cpp $(optall) -I$(CDF)/include $*.F90>$*.i

clean:
	/bin/rm -f gengrid *.o *.i *.mod
