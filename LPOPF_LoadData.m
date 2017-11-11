%% Carga de datos de barras, lineas y gen desde archivo excel


function [BUSDATA, LINEDATA, GENDATA, Pmin, Pmax, Plmin, Plmax] = LPOPF_LoadData(DATAFILE, Sb)
    BUSDATA = xlsread(DATAFILE, 1);
    LINEDATA = xlsread(DATAFILE, 2);
    GENDATA = xlsread(DATAFILE, 3);
    
    %% Cargalos los limites de generadores y lineas a vectores
    Pmin = GENDATA(1:size(GENDATA, 1), 5)./Sb;
    Pmax = GENDATA(1:size(GENDATA, 1), 6)./Sb;
    
    Plmin = LINEDATA(1:size(LINEDATA, 1), 7)./Sb;
    Plmax = LINEDATA(1:size(LINEDATA, 1), 8)./Sb;
end