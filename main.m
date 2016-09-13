close all 
clear
clc

%========= File Directory and Name ============
prob = 5;
insti = 7;
root = './Instances/Uber/';
probname = ['Uber_problem_' num2str(prob) '.txt'];


save_root = './Results/'; 
if ~exist(save_root, 'dir')
    mkdir(save_root);
end
save_file = [save_root 'problem' num2str(prob) '_instance' num2str(insti) '_output.txt'];
fw = fopen(save_file, 'w');
fclose(fw); 

%========== Read Input Files ==================
instance = csvread([root probname '_random_instance_' num2str(insti) '.csv']);
prob_file = [root probname];
% parse the problem file
[flag, G, P, k, S0, n_node] = parse_prob_file(prob_file);

if ~flag 
    fprintf('Fail to parse the prob_file\n');
    return
else
    fprintf('Input files are successfully read!\n');
end

fprintf('Number of Nodes: %d\n', n_node);


%=========== Preparing The Data Used For Simulation =========
tic
B = 0.5; % expectation of B~U(0,1)
F = 5; 

% find the pair-wise shortest path 
[L , Pre] = floyd_algo(G);

% generate the price matrix 
M = F + L * (B + 1); 

% generate the desitination probability 
D = zeros(n_node, n_node);
for i = 1 : n_node
    for j = 1 : n_node 
        if i ~= j
            D(i,j) = P(j) / (sum(P) - P(i));
        end
    end
end

% generate the income expectation for each node 
kk = 5;
E = zeros(n_node, kk);
E(:,1) = P' .* diag(D * M');
for i = 2 : kk 
    E(:,i) = P' .* (diag(D * M') + D * E(:,i-1));
end

% check the convergence of the expectation 
dE = zeros(kk-1, 1);
for i = 2 : kk
    dE(i-1) = sum(abs(E(:,i)-E(:,i-1)).^2);
end

E0 = E(:,kk); % initial expectation of each node 

% calcualte the everage expectation within a ratius (no considering the competitors)
G2 = G; 
G2(G2 == -1) = []; 
r = mean(reshape(G2, [], 1))*2;
% display(r);
avg_E = zeros(n_node, 1);
for i = 1 : n_node
    nlist = [];
    for j = 1 : n_node
        if L(i,j)<=r
            nlist = [nlist, j];
        end
    end
    avg_E(i) = sum(E0(nlist)) / 1;
end

time = L; % let the car speed be 1


%========= Main Simulation ===================
% There are two sub-routines in this part: 
% takeCustomer_move: include the policy taking the order
% move_or_wait: include the policy prepositioning the car
% ============================================

car_status = zeros(k+1, 4); 
% for each car, store if the car is occupied (car_status(i,1) = 1)
% if the car is occupied, store the next location and time when it shows up
% the price of this order is also stored (car_status(i,4))
car_earn = zeros(k+1, 1);
% total income of a car

% the most naive method: stay and see 
total_time = max(instance(:,4));
S = S0; 
wait = 0;
on_move = 0; 
between = [];
between_time = []; 
% between and between_time store the two nodes and the time stamp of the
% two nodes if my car is on the edge ended by the two nodes 
path = [];
path_time = []; 
% path stores the path of my car when it moves with no customer 

% move type when my car is empty
neighbor_type = 1; 
% 1 : move to an adjacent node 
% 2 : move to a node within a ceratin distance 
radius = r * 1; % if neighbor_type = 2

for i = 0 : total_time 
    % start from time 0 to determine the status for the first time interval
    
    % ============== process old instances ==============
    % drop customer
    for j = 1 : k+1
        if car_status(j, 1) && car_status(j, 3) == i %arrived destination
            if j == 1
%                 fprintf('notice\n');
            end
            S(j) = car_status(j,2); 
            car_status(j,:) = 0; 
        end
    end
    
    
    %=============== process new instances ==============
    % take customer
    new_inst_ID = find(instance(:,4) == i);
	occu_car = find(car_status(:,1) == 1);
    if ~isempty(new_inst_ID) && length(occu_car) < k+1  %has new customer & there is empty car
        % Our policy
        [car_status, car_earn, wait, on_move, between, between_time, path, path_time] =  takeCustomer_mov(instance, i, time, Pre, S, k, car_status, car_earn, wait, on_move, between, between_time, path, path_time, [], P, diag(D * M'), save_file);  
        % Baseline
%         [car_status, car_earn, wait] =  takeCustomer(instance, i, time, Pre, S, k, car_status, car_earn, wait); 
    end
    
    % =============== determine whether to move to wait ==
%     % if let the car wait after reaching one point (Baseline)
%     if ~car_status(1,1) && ~on_move
%         wait = wait + 1; 
%     end
    % if let the car move when empty (Our Policy)
    [on_move, path, path_time, between, between_time, wait, S] = move_or_wait(G, S, avg_E, time, Pre, i, on_move, path, path_time, between, between_time, wait, car_status, neighbor_type, radius,save_file);

    
end

run_time = toc; 

fprintf('Total money I earned is %.2f\n', car_earn(1));
fprintf('Runtime is %.3f s\n', run_time);

close all



