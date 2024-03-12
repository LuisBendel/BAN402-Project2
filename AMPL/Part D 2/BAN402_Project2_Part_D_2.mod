# Define Sets
set C; # Cities
set S within C; # Cities where operation centers can be installed
set K; # Trucks, to make sure there are four independent subtours
set N; # place in which city is visited

# define Parameters
param E{C,N}; # emergency score for visiting city i in nth place

# decision variables
var x{S,K,N} binary; # 1 if Truck k is placed in city S (means operation center in S, n will be 1), 0 otherwise
var y{K,C,C,N} binary; # 1 if Truck k travels from city i to city j on his nth trip, 0 otherwise
var u{C,K,N} binary; # 1 if Truck k visits city i in nth place, 0 otherwise

# objective function
maximize EScore:
	sum{k in K,i in C, n in N}u[i,k,n]*E[i,n];
	
# constraints
subject to

# only one trip of ONE truck FROM ANY city i to city j
incoming_trips{i in C}:
	sum{k in K, j in C, n in N:j<>i}y[k,j,i,n] = 1;
	
# only one trip of ONE Truck FROM city i to ANY city j in place n
outgoing_trips{i in C}:
	sum{k in K, j in C, n in N:j<>i}y[k,i,j,n] = 1;		
	
# every Truck must visit 4 cities and make exactly 4 trips
trips{k in K}:
	sum{i in C, j in C, n in N:j<>i}y[k,i,j,n] = 4;
	
# every cluster contains exactly ONE operation center which must be in the first place
truck_cluster{k in K}:
	sum{i in S, n in N:n=1}x[i,k,n] = 1;

start{k in K, i in S}:
	u[i,k,1] = x[i,k,1];
	
last_trip{k in K, i in S}:
	sum{j in C:j<>i}y[k,j,i,4] = x[i,k,1];		
	
# cities must be visited in a sequence
sequence1{k in K, i in C, n in N}:
	sum{j in C:j<>i}y[k,i,j,n] = u[i,k,n];
	
sequence2{k in K, i in C, n in N:n>1}:
	sum{j in C:j<>i}y[k,j,i,n-1] = u[i,k,n];		
	
# eliminate subsets within the trips of each truck
# cannot go back and forth between 2 cities
eliminate_subsets{k in K, i in C, j in C, n in N:n<4 and j<>i}:
 	y[k,i,j,n] + y[k,j,i,n+1] <= 1;
	
	






	