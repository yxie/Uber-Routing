function [car_status, car_earn, wait, on_move, between, between_time, empty_path, empty_path_time] =  takeCustomer_mov(instance, i, time, Pre, S, k, car_status, car_earn, wait, on_move, between, between_time, empty_path, empty_path_time, r_graph, P, Ii, save_file)
    % 1. If there are new customers, find the closest car for each customer. 
    % 2. If a competitor is closest to a customer, it will take the customer
    % and not be considered for the following customers. 
    % 3. If my car is closest to a customer, the customer is saved. We will
    % continue check if my car is closet to other customers. I will take
    % the order who provides the highest price. 
    
    fw = fopen(save_file, 'a');

	new_inst_ID = find(instance(:,4) == i);
	num_inst = length(new_inst_ID);        
	new_inst = instance(new_inst_ID, :); 
    near_node = zeros(1, num_inst); % record the closest node to my car if my car is on an edge
    
    
    dist = zeros(k+1, num_inst);
	for j = 1 : num_inst
        for car = 1 : k+1
            if car_status(car, 1)
                dist(car, j) = 100000; % large number for occupied car
            else
                if car == 1 && on_move
                    dist1 = time(between(1), new_inst(j,1)) + (i-between_time(1));
                    dist2 = time(between(2), new_inst(j,1)) + (between_time(2)-i);
                    [dist(car,j), near_node(j)] = min([dist1, dist2]); 
                else
                   dist(car, j) = time(S(car), new_inst(j,1));
                end
            end
        end
	end
    
     
        for car = 1:k+1
            % find best order for every empty car
            % low id car has higher priority
            [~, nearest_car] = min(dist);
            my_order = find(nearest_car == car);
            %fprintf('car %d, my_order %d\n', car, my_order);
            
            if car == 1 && on_move
                start_node = between(near_node(j));
            else
                start_node = S(car);
            end
            
            % rejection policy, added by yang, 05/01/16
            
%             rej = zeros(length(my_order), 1);
%             if car == 1
%                for order_id = 1 : length(my_order);
%                   if time(start_node, new_inst(my_order(order_id),1)) > r_graph
%                      rej(order_id) = 1; 
%                   end
%                end
%             end
%             my_order = my_order(rej == 0);


%           rejection policy, added by zyyang, 05/05/16
          rej = zeros(length(my_order),1);
          if car == 1
              for order_id = 1 : length(my_order);
                  dt = time(start_node, new_inst(my_order(order_id),1));
                  node_in_dt = find(time(start_node, :) <= dt); 
                  dI = 0; 
                  for nid = 1 : length(node_in_dt)
                      dI = dI + ...
                          (1 - (1-P(node_in_dt(nid)))^(dt-time(start_node, node_in_dt(nid)))) * Ii(node_in_dt(nid));
                  end
                  % simple rejection policy 
                  if dI >= new_inst(my_order(order_id),3)
                      rej(order_id) = 1;
                  end
                  
                          
              end
          end
          my_order = my_order(rej == 0);
            

                        
            if isempty(my_order) % this car is not nearest to any customer
                continue;
            end
            
            % choose the best customer if more than 1
            if car == 1
                average_price = zeros(1, length(my_order));
                for j = 1 : length(my_order)
                    average_price(j) = new_inst(my_order(j), 3) / (time(start_node,new_inst(my_order(j),1))+...
                    time(new_inst(my_order(j),1),new_inst(my_order(j),2)));
                end
                [~, best_order] = max(average_price);
                j = my_order(best_order);
            else
                [~, j] = min(time(S(car),new_inst(my_order,1)));
%                 j = my_order(1);
            end
            
            
            % update distance between unoccupied cars and customers 
            % yzy, 4/29/2016
            for l = 1 : num_inst
                if l ~= j 
                    dist(car, l) = 100000; 
                    % if 'car' takes j's order, it cannot take other
                    % customers' order 
                end
            end
            

            
            % update car status
            car_status(car,1) = 1; 
            car_status(car,2) = new_inst(j,2);
            car_status(car,3) = i+time(start_node,new_inst(j,1))+time(new_inst(j,1), new_inst(j,2));
            car_status(car,4) = new_inst(j,3);         
            car_earn(car) = car_earn(car) + new_inst(j,3);
            
            
            if car == 1
                [path, path_time] = get_path(start_node, new_inst(j,1), new_inst(j,2), time, Pre, i);
                
%                 fprintf('Pickup at time step %d\n', i);
                fprintf(fw, 'ACCEPT(%d, %d)\n', new_inst(j,1), new_inst(j,2));
                if on_move  
                    if start_node == between(2)
                        fprintf(fw, '(%d, %d, %d)\n', between(1), between(2), time(between(1),between(2)));
                    else
                        fprintf(fw, '(%d, %d, %d)\n', between(1), between(2), i-between_time(1));
                        fprintf(fw, '(%d, %d, %d)\n', between(2), between(1), i-between_time(1));
                    end
                else
                    if wait
                        fprintf(fw, 'WAIT %d\n', wait);
                        wait = 0;
                    end
                end
                    
                    
                on_move = 0;
                between = [];
                between_time = [];
                empty_path = [];
                empty_path_time = [];
                
                if path(1) == new_inst(j,1)
                    fprintf(fw, 'PICKUP\n');
                end
                for index = 2:length(path);
                    fprintf(fw, '(%d, %d, %d)\n', path(index-1), path(index), path_time(index)-path_time(index-1));
                    if path(index) == new_inst(j,1)
                        fprintf(fw, 'PICKUP\n');
                    end
                end
                fprintf(fw, 'DROPOFF AND MONEY %.2f\n', new_inst(j,3));
            end
               
        end
        
        fclose(fw);
        
   
end