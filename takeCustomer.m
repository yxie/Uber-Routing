function [car_status, car_earn, wait] =  takeCustomer(instance, i, time, Pre, S, k, car_status, car_earn, wait)
    % 1. If there are new customers, find the closest car for each customer. 
    % 2. If a competitor is closest to a customer, it will take the customer
    % and not be considered for the following customers. 
    % 3. If my car is closest to a customer, the customer is saved. We will
    % continue check if my car is closet to other customers. I will take
    % the order who provides the highest price. 


	new_inst_ID = find(instance(:,4) == i);
	num_inst = length(new_inst_ID);        
	new_inst = instance(new_inst_ID, :); 
    
    
    dist = zeros(k+1, num_inst);
	for j = 1 : num_inst
        for car = 1 : k+1
            if car_status(car, 1)
                dist(car, j) = 100000; % large number for occupied car
            else
                dist(car, j) = time(S(car), new_inst(j,1));
            end
        end
	end
    
     
        for car = 1:k+1
            % find best order for every empty car
            % low id car has higher priority
            [~, nearest_car] = min(dist);
            my_order = find(nearest_car == car);
            %fprintf('car %d, my_order %d\n', car, my_order);
            
            if isempty(my_order) % this car is not nearest to any customer
                continue;
            end
            
            % choose the best customer if more than 1
            if car == 1
                average_price = zeros(1, length(my_order));
                for j = 1 : length(my_order)
                    average_price(j) = new_inst(my_order(j), 3) / (time(S(car),new_inst(my_order(j),1))+...
                    time(new_inst(my_order(j),1),new_inst(my_order(j),2)));
                end
                [~, best_order] = max(average_price);
                j = my_order(best_order);
            else
                j = my_order(1);
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
%             for car_id = 1 : k+1
%                 if car_id ~= car
%                     dist(car_id, j) = 100000; % large number
%                 end
%             end
            
            % update car status
            car_status(car,1) = 1; 
            car_status(car,2) = new_inst(j,2);
            car_status(car,3) = i+time(S(car),new_inst(j,1))+time(new_inst(j,1), new_inst(j,2));
            car_status(car,4) = new_inst(j,3);         
            car_earn(car) = car_earn(car) + new_inst(j,3);
            
            if car == 1
                [path, path_time] = get_path(S(1), new_inst(j,1), new_inst(j,2), time, Pre, i);
                fprintf('WAIT %d\n', wait);
                wait = 0;
                
                if path(1) == new_inst(j,1)
                    fprintf('Pickup at time step %d\n', path_time(1));
                end
                for index = 2:length(path);
                    fprintf('(%d, %d, %d)\n', path(index-1), path(index), path_time(index)-path_time(index-1));
                    if path(index) == new_inst(j,1)
                        fprintf('Pickup at time step %d\n', path_time(index));
                    end
                end
                fprintf('DROPOFF AND MONEY %.2f\n', new_inst(j,3));
            end
               
        end
        
   
end