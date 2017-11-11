function [f,h] = MinFun(x, cmg, Pdemand, Pmin, Pmax, B, Sb, TE, n, ng,nl)
% 
%     for i = 1:ng
%         Pg(i) = x(i);
%     end
%     v = ng + 1;
%     
% %     for i = 1:n
% %         if BUSDATA(i, 2) == 1 % si es slack su angulo es fijo
% %             th(i) = 0;
% %         else
% %             th(i) = x(v);
% %             v = v + 1;
% %         end
% %     end
%     f = 0;
%     for i = 1:ng
%         f = f + cmg(i)*Pg(i);
%     end
%     
%     h(1) = -Pdemand;
%     for i = 1:ng
%         h(1) = h(1) + Pg(i); 
%     end
%     
%     v = 2;
%     % limites de gen
%     for i = 1:ng
%         h(v) = Pg(i) - Pmax(i)*Sb*TE;          % superior
%         v = v + 1;
%     end
%     
%     for i = 1:ng
%         h(v) = -Pg(i);          % superior
%         v = v + 1;
%     end
    x12 = 0.1;
    x13 =0.1;
    x23 = 0.1;
    gen1 = x(1);
    gen2 = x(2);
    gen3 = x(3);
    th2 = x(4);
    th3 = x(5);
    th1 = 0;
    fa = x(6);
    fb = x(7);
    fc = x(8);
    f = 8*gen1 + 12*gen2 + 15*gen3;
    
    h(1) = fb+fc+gen3-8928;
    h(2) = gen1-10*744;
    h(3) = gen2-5*744;
    h(4) = gen3-20*744;
    h(5) = -gen1;
    h(6) = -gen2;
    h(7) = -gen3;
    
    h(8) = fa - (th1-th2)/x12;
    h(9) = fb - (th1-th3)/x13;
    h(10) = fc - (th2-th3)/x23;
    h(11) = gen1-fa-fb;
    h(12) = gen2+fa-fc;

end