function [L, P] = floyd_algo(G)
% this algorithm uses Floyd's Algorithm to find the pair-wise shortes path
% and the routes 

% pre-process the G matrix 
nG = size(G, 1);
LARGE = 10000;
for i = 1 : nG
    G(i,i) = 0;
end
G(G == -1) = LARGE; 

% generate L and P
L = G; 
P = repmat(1:nG, [nG, 1]);
for i = 1 : nG
    P(i,i) = 0;
end

for iter = 1 : nG
    L_n = L; 
    P_n = P; 
    
    for i = 1 : nG
        for j = 1 : nG
            if L(i,iter)+L(iter,j) < L(i,j)
                L_n(i,j) = L(i,iter)+L(iter,j);
                P_n(i,j) = iter; 
            end
        end
    end
    
    L = L_n;
    P = P_n;
end




