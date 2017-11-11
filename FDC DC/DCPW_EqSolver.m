function F = DCPW_EqSolver(x, LINEDATA, bustype, V, th, Ki, Pload, Qload, Pconsig, Qconsig, G, B, g, b, Pdesbalance)
    
    n = size(V, 1);
    nl = size(LINEDATA, 1);
    
    Pflow = zeros(n,n);
    
    
    Ploss_bus = zeros(n,1);
    
    Pflow_bus = zeros(n,1);
    
    Qshunt = zeros(n, 1);
    
    %% Primero vamos a calcular los flujos de potencia para cada barra (Lo que sale/entra por las lineas)
    for i = 1:n
        thi = th(i);
        
        if bustype(i) == 2                
            thi = x(2*i-1);                  % En barra PV el angulo varia
        elseif bustype(i) == 0
            thi = x(2*i-1);                  % En barra PQ el angulo varia
        end
        
        for k = 1:n
            thk = th(k);
            if bustype(k) == 2             
                thk = x(2*k-1);              % En barra PV el angulo varia
            elseif bustype(k) == 0
                thk = x(2*k-1);              % En barra PQ el angulo varia
            end
            
            if i ~= k
                Pflow(i,k) = B(i,k)*(thi - thk);
            end
        end
        Pflow_bus(i) = sum(Pflow(i,1:size(Pflow, 2)));
    end

    %% Ahora, calculamos las perdidas totales en el sistema
    for i = 1:n
        for k = 1:n
            if i ~= k
                Ploss(i,k) = Pflow(i,k) + Pflow(k,i);
            end
        end
    end

    for i = 1:n
        for k = 1:n
            if k > i
                Ploss_bus(i) = Ploss_bus(i) + Ploss(i,k);
            end
        end
    end
    
    Ploss_tot = sum(Ploss_bus);             % Perdidas totales en el sistema
    
    %% Ahora vamos a calcular la potencia demandada/inyectada por los shunts
    for i = 1:nl
        from = LINEDATA(i, 1);
        to = LINEDATA(i, 2);
        if(from == to)          % es shunt
            b = from;
            z = 1i*LINEDATA(i, 4);             % impedancia

            Vbus = V(b);
            if bustype(b) == 0
                Vbus = x(2*b);                  
            end

            Qshunt(b) = imag(conj(z)\Vbus^2);
        end
    end
    
    %% A este punto, ya tenemos flujos de lineas, potencia de shunts y perdidas totales, ademas de P/Q de cargas
    % Por tanto ya podemos agregar las ecuaciones de potencia para cada
    % barra
    
    %%  Vamos a definir las variables que utilizaremos en las ecuaciones de flujo de carga
        % Se definen las variables con sus valores asignados, pero si es
        % una variable de estado debera asignarse el valor del vector de
        % salida del FSOLVE
    
        % Las variables vienen definidas en el siguiente orden
        % Si la barra es SLACK/REF
            % P (consigna + k perdidas + k desbalance)
            % Q
        % Si la barra es PV
            % P (consigna + k perdidas + k desbalance)
            % d
            % Q
        % Si la barra es PQ
            % d
            % V
    for i = 1:n
        Pgi = Pconsig(i);                 % Potencia activa generada, declarada como consigna
        if bustype(i) == 1
            Pgi = x(2*i-1);
        end
        
        %% Las ecuaciones de P y Q vendran de la siguiente forma
        %  Pgen = Pload + Ki*Ploss_tot - Ki*Punb
        %  Qgen = Qload + Qflow_bus + Qshunt;
        
        %% El orden de las ecuaciones sera
            % P
            % Q

        if bustype(i) == 1
            F(2*i-1) = Pgi - Pconsig(i) - abs(Pload(i)) - Ki(i)*Ploss_tot + Ki(i)*Pdesbalance;
        else
            F(2*i-1) = Pgi - abs(Pload(i)) - Pflow_bus(i);
        end
    end
end