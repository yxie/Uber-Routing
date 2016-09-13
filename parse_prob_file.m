function [flag, G, P, k, S, num] = parse_prob_file(prob_file)

flag = 0; 

fid = fopen(prob_file); 

while ~feof(fid)
    % read the dimension of G
    num_line = fgets(fid);
    num = str2num(num_line); 
    
    % generate G
    G = zeros(num);
    for l = 1 : num
        line = fgets(fid);
        comma = find(line == ','); 
        if length(comma) ~= num-1
            fprintf('Error: G matrix dimension mismatch!\n');
            return
        end
        for i = 1 : length(comma)+1
            if i == 1
                sp = 1;
            else
                sp = comma(i-1)+1; 
            end
            
            if i == length(comma)+1
                ep = length(line);
            else
                ep = comma(i)-1;
            end
            
            G(l, i) = str2num(line(sp:ep));
        end
    end
    
    % generate P: probability vector
    Pline = fgets(fid);
    comma = find(Pline == ',');
    if length(comma) ~= num-1
        fprintf('Error: P vector dimension mismatch!\n');
        return
    end
    P = zeros(1, num);
    for i = 1 : length(comma)+1
        if i == 1
            sp = 1;
        else
            sp = comma(i-1)+1;
        end
            
        if i == length(comma)+1
            ep = length(Pline);
        else
            ep = comma(i)-1;
        end
        
        P(i) = str2double(Pline(sp:ep));
    end
    
    % generate number of competitors 
    kline = fgets(fid);
    k = str2num(kline);
    
    % generate S: initial position vector
    S = zeros(1, k+1);
    Sline = fgets(fid);
    comma = find(Sline == ',');
    if length(comma) ~= k
        fprintf('Error: S vector dimension mismatch!\n');
        return
    end
    for i = 1 : length(comma)+1
        if i == 1
            sp = 1;
        else
            sp = comma(i-1)+1;
        end
            
        if i == length(comma)+1
            ep = length(Sline);
        else
            ep = comma(i)-1;
        end
        
        S(i) = str2double(Sline(sp:ep));
    end
    
    % finish the read of all the information 
    flag = 1; 
end
    