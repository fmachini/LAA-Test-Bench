%%%%%%%%%%%%%%%%  Bench Altitude Control %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% Author: Felipe Machini %%%%%%%%%%%%%%%%%%
%%%%% Bench altitude control using LQR technique %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%  attitude error removed  %%%%%%%%%%%%%%%%%%

clear all; close all; clc;

% Test Bench Properties
a = 0.0187;
b = 0.0495;
c = 0.6925;
Iyy2 = 0.289;
m2 = 0.154;
m3 = 0.115;
m4 = 0.600; % bicopter mass
l3 = 0.173;
l2 = 0.595;
L1 = 0.225;
L2 = 0.225;

den1 = Iyy2 + 1/4 * l3^2* m2 + l2^2*(m2+m3+m4);
% Linear State Space Model
% x = [Theta2 Theta4 Theta2_dot Theta4_dot]
% expanded state vector (including error) z = [(x1ref-x1) (x2ref-x2) x_dot]

A= [0 0 1 0;
    0 0 0 1;
    0 0 0 0;
    0 -c/a 0 -b/a];

b1 = l2/den1;

B= [0 0;
    0 0;
    b1 b1;
    (L1)/(a), -(L2)/(a)];

Cc = [1 0 0 0];
Aa = [zeros(1,1) Cc;
      zeros(4,1) A];

Bb = [zeros(1,2);B];
%  B= [0;
%      (L1+L2)/a]; % considerando apenas uma entrada: forca f aplicada + no motor 1 e - no motor 2
D = 0;
sysC = ss(Aa,Bb,eye(size(Aa)),D);

% Discrete time state space model
T = 0.02;%(s)
sysD = c2d(sysC,T);
A = sysD.A;
B = sysD.B;
C = sysD.C;
D = sysD.D;

% Designing LQR tracking Controler

Qr = diag([1,0.02, 5,0.08,2]);
Rr = diag([0.5 0.5]) ;

Kc = dlqr(A,B,Qr,Rr);
Kp = Kc(:,1);
Kx = Kc(:, 2:end);

% Simulation
Ad = A(2:end,2:end);
Bd = B(2:end,:);
xref = 10*pi/180; %reference position (rad)
dt = 0.02; %sampling time
numit = 500;
x = zeros(4,numit);
x(:,1) = [0 5 0 0]*pi/180;
u = zeros(2,numit);
duty = u;
int_e=0;
trimForce = 0.0917*40 - 1.39;
for i = 1:numit
    
    e = xref - Cc*x(:,i);
    int_e = int_e + e*dt;
    u(:,i) = Kp*int_e - Kx*x(:,i);
    
    x(:,i+1) = Ad*x(:,i) + Bd*u(:,i);
    
    
    duty(:,i) = 1000000 + (u(:,i) + 1.39 + trimForce)*10000/0.0917;
end

figure
subplot(2,2,1)
plot(x(1,:))
ylabel('\theta_2(k)');
subplot(2,2,2)
plot(x(2,:))
ylabel('\theta_4(k)');
subplot(2,2,3)
plot(x(3,:))
ylabel('dot{\theta_2(k)}');
subplot(2,2,4)
plot(x(4,:))
ylabel('dot{\theta_4(k)}');
figure;plot(duty(1,:));hold on;plot(duty(2,:))
ylabel('PWM')