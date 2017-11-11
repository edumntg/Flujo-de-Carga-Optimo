%% Carga de datos de barras y lineas desde archivo excel


function [BUSDATA, LINEDATA] = ACPW_LoadData(DATAFILE)
    BUSDATA = xlsread(DATAFILE, 1);
    LINEDATA = xlsread(DATAFILE, 2);
end