# Define Sets
set C; # Cities
set S within C; # Cities where operation centers can be installed
set K; # Trucks, to make sure there are four independent subtours

# define Parameters
param TDist{C,C}; # time between cities
param TLoad{S}; # loading time in operation center

# decision variables
var x{S,K} binary; # 1 if Truck k is placed in city S (means operation center in S), 0 otherwise
var y{K,C,C} binary; # 1 if Truck k travels from city i to city j, 0 otherwise
var u{C,K} binary; # 1 if Truck k visits city i, 0 otherwise
var t{K}; # Time that Truck k needs for his route

# objective function
minimize tmin:
	max{k in K}t[k];
	
# constraints
subject to

# only one trip of ONE truck FROM ANY city i to city j
incoming_trips{i in C}:
	sum{k in K, j in C:j<>i}y[k,j,i] = 1;

# only one trip of ONE Truck FROM city i to ANY city j
outgoing_trips{i in C}:
	sum{k in K, j in C:j<>i}y[k,i,j] = 1;	
	
# every Truck must visit 4 cities and make exactly 4 trips
trips{k in K}:
	sum{i in C, j in C:j<>i}y[k,i,j] = 4;
	
# every truck cluster (route) contains exactly ONE operation center
truck_cluster{k in K}:
	sum{i in S}x[i,k] = 1;
	
# if Truck k is placed in Operation center i, then there must be a link
# from this operation center and to this operation center for truck k
opcenter1{k in K, i in S}:
	sum{j in C:j<>i}y[k,i,j] >= x[i,k];
	
opcenter2{k in K, i in S}:
	sum{j in C:j<>i}y[k,j,i] >= x[i,k];	

# if Truck k visits city i, he must leave from there as well
# and drive to this city
sequence1{k in K, i in C}:
	sum{j in C:j<>i}y[k,i,j] = u[i,k];
	
sequence2{k in K, i in C}:
	sum{j in C:j<>i}y[k,j,i] = u[i,k];
	
# eliminate subsets within the trips of each truck
# cannot go back and forth between 2 cities
eliminate_subsets{k in K, i in C, j in C:j<>i}:
	y[k,i,j] + y[k,j,i] <= 1;
	
# set value for t (total time of trip for truck k)
# the maximum value of t for any truck is minimized in the objective function
maximum_traveltime{k in K}:
	t[k] =
		sum{i in C, j in C:j<>i}y[k,i,j]*TDist[i,j]
		+ sum{i in S}x[i,k]*TLoad[i];

	