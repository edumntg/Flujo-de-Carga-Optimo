%% Eduardo Montilva 12-10089
% Script para la solucion del flujo de carga, mediante fsolve

function [V, th, Pgen, Qgen, Pneta, Qneta, Sshunt, Pflow, Pflow_bus, Qflow, Qflow_bus, Ploss, Ploss_total, Qloss, Qloss_total, Ploadabs, Qloadabs] = ACPF_PF(BUSDATA, LINEDATA, G, B, g, b, n)

    nl = size(LINEDATA, 1);

    bustype = zeros(n, 1);                          % Usado para obtener el tipo de barra (SLACK/REF/PV/PQ)
    Pneta = zeros(n, 1);                            % Potencia activa neta de cada barra
    Qneta = zeros(n, 1);                            % Potencia reactiva neta de cada barra
    theta = zeros(n, 1);                            % Angulo del voltaje de cada barra (especificado)
    Vabs = zeros(n, 1);                             % Voltaje de cada barra (especificado)
    Ki = zeros(n, 1);                               % Factor de distribucion de cada barra

    Sgen = zeros(n, 1);                             
    Sload = zeros(n, 1);
    Vrect = zeros(n, 1);

    Pgen = zeros(n, 1);
    Qgen = zeros(n, 1);

    Pconsig = zeros(n, 1);
    Qconsig = zeros(n, 1);

    Pflow = zeros(n, n);
    Qflow = zeros(n, n);

    Pflow_bus = zeros(n, 1);
    Qflow_bus = zeros(n, 1);

    Ploss = zeros(n,n);
    Qloss = zeros(n,n);
    Ploss_total = 0;
    Qloss_total = 0;
    Pload = zeros(n, 1);
    Qload = zeros(n, 1);
    Sshunt = zeros(n, 1);

    X0 = zeros(2*n, 1);
    for i = 1:n 

        %% Se crean variables que seran de utilidad durante el flujo de carga

        bustype(i) = BUSDATA(i, 2); %PV, PQ o Slack
        Vabs(i) = BUSDATA(i, 3);
        theta(i) = BUSDATA(i, 4);

        %% Calculamos la potencia neta por barra

        Pload(i) = -BUSDATA(i, 5);
        Qload(i) = -BUSDATA(i, 6);

        Pconsig(i) = BUSDATA(i, 7);
        Qconsig(i) = BUSDATA(i, 8);

        %% Factor de distribucion
        Ki(i) = BUSDATA(i, 9);

        Pneta(i) = Pconsig(i)-Pload(i);
        Qneta(i) = Qconsig(i)-Qload(i);
    end

    Pdesbalance = sum(Pconsig) - abs(sum(Pload));

    V = Vabs;
    th = theta;

    for i = 1:n
        if bustype(i) == 1 % incognitas: P y Q
            X0(2*i-1) = Pconsig(i);
            X0(2*i) = Qconsig(i);
        elseif bustype(i) == 2 % incognitas: delta y Q
            X0(2*i-1) = th(i);
            X0(2*i) = Qconsig(i);
        elseif bustype(i) == 0 %incognitas: V y delta
            X0(2*i-1) = th(i);
            X0(2*i) = V(i);
        end
    end

    %% Ejecucion del fsolve (iteraciones)
    options = optimset('Display','off');
    
    X = fsolve(@(x)ACPF_EqSolver(x, LINEDATA, bustype, V, th, Ki, Pload, Qload, Pconsig, Qconsig, G, B, g, b, Pdesbalance, n), X0, options);

    %% Una vez terminadas las iteraciones, se obtienen las variables de salida y se recalculan potencias
    for i = 1:n
        if bustype(i) == 1 % incognitas: P y Q
            Pgen(i) = X(2*i-1);
            Qgen(i) = X(2*i);
        elseif bustype(i) == 2 % incognitas: delta y Q
            th(i) = X(2*i-1);
            Qgen(i) = X(2*i);
        elseif bustype(i) == 0 %incognitas: V y delta
            th(i) = X(2*i-1);
            V(i) = X(2*i);
        end
    end

    %% Calculo de flujos en lineas y perdidas
    for i = 1:n
        for k = 1:n
            if i ~= k
                Pflow(i,k) = (-G(i,k) + g(i,k))*V(i)^2 + V(i)*V(k)*(G(i,k)*cos(th(i) - th(k)) + B(i,k)*sin(th(i) - th(k)));
                Qflow(i,k) = (B(i,k) - b(i,k))*V(i)^2 + V(i)*V(k)*(-B(i,k)*cos(th(i) - th(k)) + G(i,k)*sin(th(i) - th(k)));
            end
        end
        Pflow_bus(i) = sum(Pflow(i, 1:size(Pflow, 2)));
        Qflow_bus(i) = sum(Qflow(i, 1:size(Qflow, 2)));
    end

    %% Calculo de las perdidas
    for i = 1:n
        for k = 1:n
            %% Calculo de perdidas
            if i ~= k
                Ploss(i,k) = Pflow(i,k) + Pflow(k,i);
                Qloss(i,k) = Qflow(i,k) + Qflow(k,i);

                if k > i
                    Ploss_total = Ploss_total + Ploss(i,k);
                    Qloss_total = Qloss_total + Qloss(i,k);
                end
            end
        end
    end

    for i = 1:nl
        from = LINEDATA(i, 1);
        to = LINEDATA(i, 2);
        if(from == to)                      % es un shunt
            bus = from;
            z = 1i*LINEDATA(i, 4);
            Sshunt(bus) = conj(z)\V(bus)^2;
            Qneta(bus) = Qneta(bus) - imag(Sshunt(bus));
        end
    end

    for i = 1:n
        Pgen(i) = 0;
        Qgen(i) = 0;
        if bustype(i) ~= 0
            Pgen(i) = abs(Pload(i)) + Pflow_bus(i);
            Qgen(i) = abs(Qload(i)) + Qflow_bus(i) + imag(Sshunt(i));
        end
    end

    for i = 1:n
        Pneta(i) = Pgen(i) - abs(Pload(i));
        Qneta(i) = Qgen(i) - abs(Qload(i)) - imag(Sshunt(i));
    end

    Pdesbalance = Pdesbalance + Ploss_total;
    
    Ploadabs = sum(abs(Pload));
    Qloadabs = sum(abs(Qload));

    %% VARIABLES PARA GARANTIZAR EL BUEN FUNCIONAMIENTO DEL PROGRAMA
    % La P de salida en cada barra debe ser igual a la P neta de la misma
    fprintf('Diferencia entre Pneta y Psalida para cada barra: %s\n', mat2str(Pgen - abs(Pload) - Pflow_bus));
    fprintf('Diferencia entre Qneta y Qsalida para cada barra: %s\n', mat2str(Qgen - imag(Sshunt) - abs(Qload) - Qflow_bus));
    Pdesbalance_result = sum(Pgen) - abs(sum(Pload));
    fprintf('Desbalance inicial en el sistema: %s\n', num2str(Pdesbalance));
    fprintf('Desbalance final en el sistema: %s\n\n', num2str(Pdesbalance_result));
end