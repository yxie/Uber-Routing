function [Path, T] = get_path(n1, n2, n3, time, Pre, ini_T)

Path = n1; 
i = 1; 

if n2 ~= n1
while Pre(Path(i), n2) ~= n2
    i = i + 1; 
    Path(i) = Pre(Path(i-1),n2);
end
i = i + 1; 
Path(i) = n2; 
end

if n3 ~= n2
while Pre(Path(i), n3) ~= n3
    i = i + 1; 
    Path(i) = Pre(Path(i-1), n3);
end
i = i + 1; 
Path(i) = n3; 
end

T = zeros(1, length(Path));
T(1) = ini_T; 
for i = 2 : length(T)
    T(i) = time(Path(i-1), Path(i))+T(i-1);
end

