%% Eduardo Montilva 12-10089
% Script el cual tiene como funcion armar la Ybus del sistema, incluyendo
% los shunts conectados a las barras

% global n nl ns Ybus

function [Ybus, G, B, g, b] = ACPW_Ybus(BUSDATA, LINEDATA, FDCType, n)

    Ybus = zeros(n,n);          % Se inicializa como una matriz de ceros

    g = zeros(n, n);
    b = zeros(n, n);
    
    nl = size(LINEDATA, 1);

    % Se agregan las impedancias de las lineas
    for i = 1:nl 
        from = LINEDATA(i, 1);                      % Barra de inicio de la linea
        to = LINEDATA(i, 2);                        % Barra de fin de la linea
        Zl = LINEDATA(i, 3) + 1i*LINEDATA(i, 4);    % Impedancia de la linea
        if(FDCType == 0)
            Zl = 1i*LINEDATA(i, 4);                 % Si el FDC es DC, no se toma en cuenta R
        end
        a = LINEDATA(i, 6);                         % Tap del transformador
        Bl = 1i*LINEDATA(i, 5);                     % Shunt x2 de la linea

        Ybus(from, from) = Ybus(from, from) + (1/Zl)/(a^2);
        if(from ~= to)
            Ybus(to, to) = Ybus(to, to) + (1/Zl)/(a^2);
            Ybus(from, to) = Ybus(from, to) - (1/Zl)/a;
            Ybus(to, from) = Ybus(to, from) - (1/Zl)/a;
        end

        % Se agregan los shunts de las lineas
        Ybus(from, from) = Ybus(from, from) + Bl/2;

        if(from ~= to)
            Ybus(to, to) = Ybus(to, to) + Bl/2;
            g(from, to) = real(Bl/2);
            g(to, from) = real(Bl/2);

            b(from, to) = imag(Bl/2);
            b(to, from) = imag(Bl/2);
        end
    end

    G = real(Ybus);
    B = imag(Ybus);
end