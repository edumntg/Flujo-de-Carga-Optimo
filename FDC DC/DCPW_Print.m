%% Eduardo Montilva 12-10089
% Script el cual tiene como funcion armar imprimir los resultados del flujo
% de carga

if ShowUnits == 1
    head = ['    Bus  Voltage  Angle    ------Load------    ---Generation---    ---P y Q Netos---   Injected'
            '    No.  Mag.      Rad      MW       Mvar       MW       Mvar        MW       Mvar       Mvar  '
            '                                                                                               '];
else
    head = ['    Bus  Voltage  Angle    ------Load------    ---Generation---    ---P y Q Netos---   Injected'
            '    No.  Mag.      Rad      (p.u)   (p.u)       (p.u)    (p.u)       (p.u)    (p.u)     (p.u)  '
            '                                                                                               '];
end
disp(head)

Vbp = Vb^ShowUnits;
Sbp = Sb^ShowUnits;

Vu = V.*Vbp;
for i = 1:n
    Ploadu(i) = BUSDATA(i, 5)*Sbp;
    Qloadu(i) = BUSDATA(i, 6)*Sbp;
end
Pgenu = Pgen.*Sbp;
Qgenu = Qgen.*Sbp;
Pnetau = Pneta.*Sbp;
Qnetau = Qneta.*Sbp;
Sshuntu = Sshunt.*Sbp;

Ploss_total = 0;
Qloss_total = 0;
for i = 1:n
    for k = 1:n
        %% Calculo de perdidas
        if(i ~= k)
            if k > i
                Ploss_total = Ploss_total + Ploss(i,k);
                Qloss_total = Qloss_total + Qloss(i,k);
            end
        end
    end
end

Ploss_totalu = Ploss_total*Sbp;
Qloss_totalu = Qloss_total*Sbp;

for i = 1:n
     fprintf(' %5g', i), fprintf(' %7.4f', Vu(i)), fprintf(' %8.4f', theta(i)), fprintf(' %9.4f', abs(Ploadu(i))), fprintf(' %9.4f', abs(Qloadu(i))), fprintf(' %9.4f', Pgenu(i)), fprintf(' %9.4f ', Qgenu(i)), fprintf(' %9.4f', Pnetau(i)), fprintf(' %9.4f', Qnetau(i)), fprintf(' %8.4f\n', imag(Sshuntu(i)))
end
    fprintf('      \n'), fprintf('    Total              '), fprintf(' %9.4f', abs(sum(Ploadu))), fprintf(' %9.4f', abs(sum(Qloadu))), fprintf(' %9.4f', sum(Pgenu)), fprintf(' %9.4f', sum(Qgenu)), fprintf(' %9.4f', sum(Pnetau)), fprintf(' %9.4f', sum(Qnetau)), fprintf(' %9.4f\n\n', sum(imag(Sshuntu)))
    fprintf('    Total loss:           '), fprintf(' P: %9.4f ', Ploss_totalu), fprintf(' Q: %9.4f', Qloss_totalu)
    fprintf('\n');