%% Eduardo Montilva 12-10089
%% Flujo de Carga 

clc, clear all;

Vb = 115;         % Voltaje base (kV)
Sb = 100;         % Potencia base (MVA)


%% Tipos de barras

ShowUnits = 0;    % Mostrar resultados en unidades? (MW, kV, MVAr) (1 = SI, 0 = NO) Si elige NO, se muestran en p.u

PrintResults = 1; % Imprimir?

%% Carga de los datos desde archivo Excel
% DATAFILE = 'BUSDATA.xlsx';
DATAFILE = 'Datos6Barras_Wollenberg.xlsx';
%% Ejecucion del FDC
[BUSDATA, LINEDATA] = DCPW_LoadData(DATAFILE);
n = size(BUSDATA, 1);
[Ybus, G, B, g, b] = DCPW_Ybus(BUSDATA, LINEDATA, n);

[V, theta, Pgen, Qgen, Pneta, Qneta, Sshunt, Pflow, Pflow_bus, Qflow, Qflow_bus, Ploss, Qloss] = DCPW_ExecPW(BUSDATA, LINEDATA, G, B, g, b, n);

if(PrintResults)
    DCPW_Print;
end