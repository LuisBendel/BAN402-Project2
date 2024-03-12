############################## SETS ##################################

set J; #crude oils
set B; #components
set P; #final products
set D; #depots
set K; #markets
set T; #days
set I; #CDUs
set BP; #products that require blending

############################ PARAMETER ###################################

param A{J,B,I}; #Refining Parameter: 1 unit of crude oil j is turned into A units of component b at CDU i
param R{B,BP}; #Blending Parameter: 1 unit of product p requires R units of b
param E{J}; #Amount of crude oil j (fixed)
param minR; #minimum output of CDU if operational 
param maxR; #maximum output of CDU if operational 
param Cref{J,I}; #cost of refining 1 unit of crude oil j at CDU i
param Cprod{BP}; #cost at blending department
param CMain; #Cost of maintainance at a CDU
param CTra1; #Transport Cost from refining (CDUs) to blending
param CTra2{D}; #Transport Cost of lowqfuel from refining directly to depot d
param CTra3{D}; #Transport Cost from blending to depot d
param CTra4{D,K}; #Transport Cost from depot d to market k
param delta{P,K,T}; #Demand limit for product p in market k on day t
param S{P}; #Price for product p
param CINVJ; #Inventory costs at refining department
param CINVB; #Inventory costs at blending department
param CINVP{D}; #Inventory costs at depot d
param Izero{P,D}; #Initial Stock of product p at depot d
param Ifinal{P,D}; #Minimun final Stock of product p at depot d
#other initial values

########################### VARIABLES ####################################

var z{J,I,T}>=0; # Amount of crude oil j refined at CDU i on day t
var u{B,T}>=0; # Amount of component b obtained on day t and sent to blending
var w{BP,T}>=0; # Amount of product bp produced at the blending department on day t
var f{BP,D,T}>=0;# Amount of blended product bp sent to depot d on day t
var fl{D,T}>=0; # Amount of lowqfuel sent to depot d on day t
var v{P,D,K,T}>=0; # Amount of Product p sold from depot d to market k on day t

var IO{J,T}>=0; # Inventory of oil j at refining department on day t
var IC{B,T}>=0; # Inventory of component b at blending department on day t
var IP{P,D,T}>=0; # Inventory of product p at depot d on day t
var x{I,T} binary; # binary variable, 1 if CDU i operates at day t
var y{I,T} binary; # binary variable, 1 if CDU i is mantained at day t

#var a1{T} binary; # auxiliary variable
#var a2{I,T} binary; # auxiliary variable
var a1{T} binary;
var a2{T} binary;
var a3{T} binary;

########################## OBJECTIVE FUNCTION ##############################
maximize profit:
	# revenue
	sum{p in P, d in D, k in K, t in T:12>t>0}S[p] * v[p,d,k,t]
		# refining costs
		-sum{j in J, i in I, t in T:t>0}z[j,i,t] * Cref[j,i]
		# blending costs for blended products
		-sum{bp in BP, t in T:t>0} w[bp,t] * Cprod[bp]
		# transporting cost of components from refinery to blending
		-sum{b in B, t in T:t>0 and b<>'lowqfuel'} u[b,t] * CTra1
		# transportation cost of lowqfuel from refining to depots
		-sum{d in D, t in T:t>0}fl[d,t] * CTra2[d]
		# transportation cost from blending to depots
		-sum{bp in BP, d in D, t in T:t>0}f[bp,d,t] * CTra3[d]
		# transportation cost from depots to markets
		-sum{p in P, d in D, k in K, t in T:t>0} v[p,d,k,t] * CTra4[d,k]
		#  maintenance cost
		-sum{i in I, t in T:t>0}y[i,t] * CMain
		# inventory cost for storing Crude at refinery
		-sum{j in J, t in T:t>0}CINVJ * IO[j,t]
		# inventory cost for storing components at blending
        -sum{b in B, t in T:t>0}CINVB * IC[b,t]
        # inventory cost for storing products at depots
        -sum{p in P, d in D, t in T:t>0}CINVP[d] * IP[p,d,t]
        # fixed cost if only CDU1 is running
        -sum{t in T:t>0}60000*a1[t]
        # fixed cost if only CDU2 is running
        -sum{t in T:t>0}120000*a2[t]
        # fixed cost if both CDUs are running
        -sum{t in T:t>0}135000*a3[t]
        ;
        
################################# CONSTRAINTS ###############################
subject to
############### Binary Constraints for Operation and Maintanance of CDUs ##########
Maintanance{i in I}: #maintanance at least once after the 6th day
	sum{t in T:t>6}y[i,t] >= 1;	
	
CDUoperation{t in T:t>0}: #at least one CDU has to be operational at all times
	sum{i in I}x[i,t] >= 1;
	
MainOper{i in I, t in T:t>0}: #if CDU i is maintained it cannot operate -> y and x cannot be 1 at the same time
	y[i,t] + x[i,t] <= 1;

######################### Operational Constraints ########################

DemandLimit{p in P, k in K, t in T:t>0}: #amount sold cannot exceed demand limit
	sum{d in D}v[p,d,k,t-1] <= delta[p,k,t];

CDUBoundaries1{i in I, t in T:t>0}: #CDU has to operate within boundaries
	sum{j in J}z[j,i,t] <= maxR * x[i,t];
	
CDUBoundaries2{i in I, t in T:t>0}: #CDU has to operate within boundaries
	sum{j in J}z[j,i,t] >= minR * x[i,t];	

# the Amount of crude j refinde in both refineries
# cannot exceed the amount available plus inventory at this day
Refining{j in J, t in T:t>0}: #There is a fixed supply due to agreements with suppliers
	sum{i in I}z[j,i,t]  <= E[j] + IO[j,t-1];

# Amount of components obtained and sent on day t equals the amount
# of crude oil refined times the refining factor A in all refinieries
# Components{b in B, t in T:t>0}:
#	 u[b,t] = sum{j in J, i in I}z[j,i,t] * A[j,b,i];	

# Amount of components sent to blending must equal to the amount
# of components (not lowqfuel) obtained in refinin
RefiningToBlending{b in B, t in T:t>0 and b<>'lowqfuel'}:
	u[b,t] = sum{j in J, i in I}z[j,i,t] * A[j,b,i];

# Amount of blended products sent to depots on day t
# must be equal to what is produced on day t
bp_to_depot{bp in BP, t in T:t>0}:
	sum{d in D}f[bp,d,t] = w[bp,t];

# lowqfuel sent do depots on day t must equal the amount of lowqfuel
# obtained in refinery on this day	
lq_to_depot{t in T:t>0}:
	 sum{d in D}fl[d,t] = sum{j in J, i in I}z[j,i,t] * A[j,'lowqfuel',i];		

# sales for all blended products from depots on day t
# must be smaller or equal than the amount of blended products
# sent on day t-1 plus inventory on day t
Sales{bp in BP, d in D, t in T:t>0}:
	sum{k in K}v[bp,d,k,t] <= f[bp,d,t-1] + IP[bp,d,t-1];

# sales for lowqfuel from the depots on day t
# must be smaller or equal to what arrives on day t plus Inventory on day t
Sales2{d in D, t in T:t>0}:
	sum{k in K}v['lowqfuel',d,k,t] <= fl[d,t-1] + IP['lowqfuel',d,t-1];	

# if CDU i is not operating on day t (x[it] = 0), z[j,i,t] has to be 0
# using the big M parameter
CDUShutdown{i in I, t in T:t>0}:
	sum{j in J}z[j,i,t] <= 100000000000*x[i,t];
	
########################### Balance Constraints ##############################

BalanceOil{j in J, t in T:t>0}: #Balance of Crude Oil at Refining
	IO[j,t] = IO[j,t-1] + E[j] - sum{i in I}z[j,i,t];
	
BalanceComp{b in {b in B: b <> 'lowqfuel'}, t in T:t>0}: #Balance of Components at Blending Department
	IC[b,t] = IC[b,t-1] + u[b,t-1] - sum{bp in BP}w[bp,t] * R[b,bp];

BalanceProd1{bp in BP, d in D, t in T:t>0}:
	IP[bp,d,t] = IP[bp,d,t-1] + f[bp,d,t-1] - sum{k in K}v[bp,d,k,t];
	
BalanceProd2{d in D, t in T:t>0}:
	IP['lowqfuel',d,t] = IP['lowqfuel',d,t-1] + fl[d,t-1] - sum{k in K}v['lowqfuel',d,k,t];	

	
########################### Inventory Constraints ######################################	

FinalInv{d in D, p in P}: #Minimal final inventory has to be fulfilled
		IP[p,d,12] >= Ifinal[p,d];

InventoryInitial_p{p in P, d in D}: # initial inventory of products
     	IP[p,d,0] = Izero[p,d];     

InventoryInitial_b{b in B}:  # initial inventory of components
     	IC[b,0] = 0;

InventoryInitial_j{j in J}:  # initial inventory of Crude Oil
     	IO[j,0] = 0;

############################### Initial flows ####################################

InitialRefining{j in J, i in I}: 
     	z[j,i,0] = 0;
     	
InitialComponents{b in B}:
     	u[b,0] = 0; 	
		
InitialProduction{bp in BP}:
		w[bp,0] = 0;	

InitialToDepots1{bp in BP, d in D}: 
     	f[bp,d,0] = 0;
     	
InitialToDepots2{d in D}: 
 		fl[d,0] = 0; 	
     	
InitialToMarkets{p in P, d in D, k in K}: 
     	v[p,d,k,0] = 0;  
     	

############################### fixed costs for CDUs ####################################	

#fixed_cost1{t in T:t>0}:
#	a1[t] = sum{i in I}x[i,t];
	
#fixed_cost2{i in I, t in T:t>0}:
#	a2[i,t] + a1[t] = x[i,t] + 1;
	
fixed_cost1{t in T:t>0}:
	a1[t] <= x['CDU1',t];
	
fixed_cost2{t in T:t>0}:
	a1[t] = 1-x['CDU2',t];
	
fixed_cost3{t in T:t>0}:
	a2[t] <= x['CDU2',t];
	
fixed_cost4{t in T:t>0}:
	a2[t] = 1-x['CDU1',t];
	
fixed_cost5{t in T:t>0}:
	a3[t] + 1 >= sum{i in I}x[i,t];
	
