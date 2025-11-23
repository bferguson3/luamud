function arr_remove(input, remove)
    local n=#input
    for i=1,n do
        if input[i]==remove then
            input[i]=nil
        end
    end
    local j=0
    for i=1,n do
        if input[i]~=nil then
            j=j+1
            input[j]=input[i]
        end
    end
    for i=j+1,n do
        input[i]=nil
    end
end

function arr_remove_i(input, idx)
    local n = #input 
    input[idx] = nil
    local j=0 -- reshape 
    for i=1,n do
        if input[i]~=nil then
            j=j+1
            input[j]=input[i]
        end
    end
    for i=j+1,n do
        input[i]=nil
    end
end