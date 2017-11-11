%% Eduardo Montilva 12-10089
%% FLUJO DE CARGA OPTIMO MEDIANTE PROGRAMACION LINEAL (linprog)

clc, clear all;

Vb = 115;         % Voltaje base (kV)
Sb = 100;         % Potencia base (MVA)
TE = 31*24;       % Tiempo de estudio

ShowUnits = 1;    % Mostrar resultados en unidades? (MW, kV, MVAr) (1 = SI, 0 = NO) Si elige NO, se muestran en p.u
PrintResults = 1; % Imprimir?
FDCType = 1;      % (0: DCPF, 1: ACPF)

%% Carga de los datos desde archivo Excel
% DATAFILE = 'DatosCasoPrueba.xlsx';
% DATAFILE = 'DatosMarioPereira.xlsx';
DATAFILE = 'Datos6Barras_Wollenberg.xlsx';

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Ejecucion del FDC
[BUSDATA, LINEDATA, GENDATA, Pmin, Pmax, Plmin, Plmax] = LPOPF_LoadData(DATAFILE, Sb);

n = size(BUSDATA, 1);    % Numero de barras

np = 0; % numero de barras pv o pq
for i = 1:n
    if(BUSDATA(i, 2) ~= 1) % es pv o pq
        np = np + 1;
    end
end

ng = size(GENDATA, 1);   % Numero de maquinas
nl = size(LINEDATA, 1);  % Numero de lineas

ccc =  GENDATA(1:size(GENDATA, 1), 2);
cmg =  GENDATA(1:size(GENDATA, 1), 3);  % COSTO MARGINAL
acc =  GENDATA(1:size(GENDATA, 1), 4);

[Ybus, G, B, g, b] = LPOPF_Ybus(BUSDATA, LINEDATA, FDCType, n);

%% Se ejecuta el FDC
if(FDCType == 1)    %FDC AC
    [V, theta, Pgen, Qgen, Pneta, Qneta, Sshunt, Pflow, Pflow_bus, Qflow, Qflow_bus, Ploss, Ploss_total, Qloss, Qloss_total, Pload, Qload] = ACPF_PF(BUSDATA, LINEDATA, G, B, g, b, n);
else
    [V, theta, Pgen, Qgen, Pneta, Qneta, Sshunt, Pflow, Pflow_bus, Qflow, Qflow_bus, Ploss, Ploss_total, Qloss, Qloss_total, Pload, Qload] = DCPF_PF(BUSDATA, LINEDATA, G, B, g, b, n);
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%% A partir de este punto se empieza con el LPOPF

Pdemand = Pload*Sb*TE;  % Demanda en MWh

%% Se tendran las siguientes variables
   % Potencias generadas
   % Flujos en lineas
   % Angulos de barras no SLACK

%%  Se procede a armar el vector f correspondiente a la funcion que se va a minimizar

%   Este vector contendra las variables correspondientes a las potencias
%   generadas, multiplicadas por los costos marginales de c/u

f = zeros(1, ng+np+nl);
for i = 1:ng
    f(i) = cmg(i);
end

%%  Ahora se procede a armar las matrices Aeq y beq (Aeq*x = beq)

%   Primero agregamos las ecuaciones de flujos de cada barra

beq = zeros(ng+nl, 1);

Amq = eye(ng);
ABmq = zeros(ng, np);
Bmq = zeros(ng, nl);

Cmq = zeros(nl, ng);
CDmq = zeros(nl, np);
Dmq = eye(nl);

for i = 1:ng
    for l = 1:nl
        from = LINEDATA(l, 1);
        to = LINEDATA(l, 2);
        if i == from
            Bmq(i,l) = -1;
        elseif i == to
            Bmq(i,l) = 1;
        end
    end
end

for l = 1:nl
    from = LINEDATA(l, 1);
    to = LINEDATA(l, 2);
    if BUSDATA(from, 1) ~= 1    %No es SLACK
        CDmq(l,from-1) = -B(from, to);
    end
    if BUSDATA(to, 1) ~= 1      %No es SLACK
        CDmq(l,to-1) = B(from, to);
    end
end

Aeq = [Amq ABmq Bmq
       Cmq CDmq Dmq];

%%  Si en el sistema existe una barra sin maquina conectada, se debe agregar una ecuacion adicional
%   La cual corresponde a los flujos entrantes a esa barra igual a la carga
%   conectada

for i = 1:n
    found = 0;
    for j = 1:ng
        if BUSDATA(j, 1) == i   % Existe un gen en la barra i
            found = 1;
            break;
        end
    end
    
    if found == 0   % No se encontro gen en la barra i
        Aeq_vec = zeros(1, ng+np+nl);
        for j = 1:nl
            from = LINEDATA(j, 1);
            to = LINEDATA(j, 2);
            if from == i
                % La linea empieza donde esta la barra de interes
                % Por tanto el flujo sera negativo
                
                Aeq_vec(1, np+ng+j) = -1;
            end
            if to == i
                % La linea termina donde esta la barra de interes
                % Por tanto el flujo sera positivo
                
                Aeq_vec(1, np+ng+j) = 1;
            end
        end
        Aeq(size(Aeq, 1)+1, 1:size(Aeq, 2)) = Aeq_vec;
    end
end


for i = 1:ng
    beq(i, 1) = BUSDATA(i, 5)*Sb*TE; % Carga en la barra i
end
v = 1 + ng;

for i = 1:nl
    from = LINEDATA(i, 1);
    to = LINEDATA(i, 2);
    beq(v, 1) = 0;
    if BUSDATA(from, 2) == 1
        beq(v, 1) = B(from, to)*BUSDATA(from, 4);
        v = v + 1;
    end
end

%   Para beq tambien hay que agregar la igualdad para las barras que no
%   tienen gen conectado
beq_vec = 0;
for i = 1:n
    found = 0;
    for j = 1:ng
        if BUSDATA(j, 1) == i   % Existe un gen en la barra i
            found = 1;
            break;
        end
    end
    
    if found == 0   % No se encontro gen en la barra i
        beq_vec = BUSDATA(i, 5).*Sb.*TE;
        beq(size(beq, 1)+1) = beq_vec;
    end
end

%%	Se arma la matriz A y el vector b, A*x <= b

%   En este segmento se fijan los limites minimos de los generadores
%   La generacion debera ser mayor o igual a los valores minimos

%   -Pgen <= -Pmin

Am = -eye(ng);
Bm = zeros(ng, np+nl);
Cm = zeros(nl, ng);
Dm = zeros(nl, np+nl);

%   En Dm iran las restricciones de lineas, estas corresponden siempre a las
%   ultimas variables
for i = 1:nl
    Dm(i, np+i) = 1;
end

A = [Am Bm
     Cm Dm];

b = [-Pmin.*Sb.*TE
     Plmax.*Sb.*TE];

%%  Finalmente, los limites inferiores y superiores para las variables de f
lb = Pmin.*Sb.*TE;
v = ng;

%   Los limites inferiores de los angulos se establencen en -pi
for i = 1:np
    lb(v+i) = -Inf;
end

%   Se agregan los limites inferiores de flujos en lineas
lb = vertcat(lb, Plmin.*Sb.*TE);

%%  Vector de limites superiores
ub = Pmax.*Sb.*TE;
v = ng;

%   Los limites superiores de los angulos se establecen en pi
for i = 1:np
    ub(v+i) = Inf;
end

%   Se agregan los limites superiores de flujos en lineas
ub = vertcat(ub, Plmax.*Sb.*TE);
% x02 = [3000 3000 3000 0 0 2000 2000 2000];
% Aeq = [0 0 0 B(1,2) 0 1 0 0
%        0 0 0 0 B(1,3) 0 1 0
%        0 0 0 -B(2,3) B(2,3) 0 0 1
%        1 0 0 0 0 -1 -1 0
%        0 1 0 0 0 1 0 -1
%        0 0 1 0 0 0 1 1];
% beq = [0;0;0;0;0;Pdemand];
% A = [-1 0 0 0 0 0 0 0
%      0 -1 0 0 0 0 0 0
%      0 0 -1 0 0 0 0 0];
% b = [0;0;0];
% lb = Pmin.*Sb.*TE;
% ub = Pmax.*Sb.*TE;
% [x,fval,exitflag,output,lambda] = fmincon(@(x)MinFun(x, cmg, Pdemand, Pmin, Pmax, B, Sb, TE, n, ng, nl), x0, A, b, Aeq, beq, lb, ub);
% f = [8 12 15 0 0 0 0 0];
[x,fval,exitflag,output,lambda] = linprog(f, A, b, Aeq, beq, lb, ub);
x
lambda.ineqlin
lambda.eqlin
lambda.upper
lambda.lower

