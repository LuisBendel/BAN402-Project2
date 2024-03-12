# Define Sets
set C; # Cities
set S within C; # Cities where operation centers can be installed
set K; # Trucks, to make sure there are four independent subtours
set N; # place in which city is visited
set I; # instances for which the model should be solved

# define Parameters
param E{C,N}; # emergency score for visiting city i in nth place
param TDist{C,C}; # time between cities
param TLoad{S}; # loading time in operation center
param EScoreMin; # minimum required emergency score

# decision variables
var x{S,K,N} binary; # 1 if Truck k is placed in city S (means operation center in S, n will be 1), 0 otherwise
var y{K,C,C,N} binary; # 1 if Truck k travels from city i to city j on his nth trip, 0 otherwise
var u{C,K,N} binary; # 1 if Truck k visits city i in nth place, 0 otherwise
var t{K} >= 0; # Time that Truck k needs for his route

# objective function, we are now minimizing the maximum travel time again
minimize tmin:
	max{k in K}t[k];
	
# constraints
subject to

# only one trip of ONE Truck FROM city i to ANY city j in place n
incoming_trips{i in C}:
	sum{k in K, j in C, n in N:j<>i}y[k,i,j,n] = 1;	

# only one trip of ONE truck FROM ANY city i to city j
outgoing_trips{j in C}:
	sum{k in K, i in C, n in N:i<>j}y[k,i,j,n] = 1;
	
# every Truck must visit 4 cities and make exactly 4 trips
trips{k in K}:
	sum{i in C, j in C, n in N:j<>i}y[k,i,j,n] = 4;
	
# every cluster contains exactly ONE operation center which must be in the first place
truck_cluster{k in K}:
	sum{i in S, n in N:n=1}x[i,k,n] = 1;	

# if operation center is placed in i, then k has to start from there
start{k in K, i in S}:
	u[i,k,1] = x[i,k,1];
	
last_trip{k in K, i in S}:
	x[i,k,1] = sum{j in C:j<>i}y[k,j,i,4];

# cities must be visited in a sequence
sequence1{k in K, i in C, n in N}:
	sum{j in C:j<>i}y[k,i,j,n] = u[i,k,n];
	
sequence2{k in K, i in C, n in N:n>1}:
	sum{j in C:j<>i}y[k,j,i,n-1] = u[i,k,n];
	
# eliminate subsets within the trips of each truck
# cannot go back and forth between 2 cities
eliminate_subsets{k in K, i in C, j in C, n in N:n<4 and j<>i}:
 	y[k,i,j,n] + y[k,j,i,n+1] <= 1;
	
# set value for t (total time of trip for truck k)
# the maximum value of t for any truck is minimized in the objective function
maximum_traveltime{k in K}:
	t[k] =
		sum{i in C, j in C, n in N:j<>i}y[k,i,j,n]*TDist[i,j]
		+ sum{i in S, n in N}x[i,k,n]*TLoad[i];

# requirement to meet at least a% of optimal emergency score from task 2
minimum_escore:
	sum{k in K,i in C, n in N}u[i,k,n]*E[i,n] >= EScoreMin;




	