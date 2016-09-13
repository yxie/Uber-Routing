function [on_move, path, path_time, between, between_time, wait, S] = move_or_wait(G, S, avg_E, time, Pre, cur_time, on_move, path, path_time, between, between_time, wait, car_status, neighbor_type, r, save_file)

fw = fopen(save_file, 'a');

if ~car_status(1,1) && ~on_move
    if ~wait
        switch neighbor_type 
            case 1
                % method 1: the car can only move to an adjacent node 
                neighbor = find(G(S(1),:) ~= -1); 
            case 2
                % method 2: the car can move to a node within a certain radius 
                neighbor = find(time(S(1),:) <= r);
            otherwise
                display('No such type!\n');
                return;
        end
        
        [max_neighbor_value, max_neighbor_id] = max(avg_E(neighbor));
    
        if max_neighbor_value > avg_E(S(1))
            on_move = 1; 
            [path, path_time] = get_path(S(1), neighbor(max_neighbor_id), neighbor(max_neighbor_id), time, Pre, cur_time);
            between = [path(1), path(2)];
            between_time = [path_time(1), path_time(2)];
        else
            wait = wait + 1; 
            path = [];
            path_time = [];
            between = [];
            between_time = [];
        end
    else
        wait = wait + 1; 
    end
elseif ~car_status(1,1) && on_move
    event = find(path_time == cur_time);
    if ~isempty(event)
        fprintf(fw, '(%d, %d, %d)\n', path(event-1), path(event), path_time(event)-path_time(event-1));
    end
    if event == length(path)
        S(1) = path(end);
        on_move = 0;
    end
end

fclose(fw);
    

